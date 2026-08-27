"""SP-SEED-9 — 시드 오케스트레이터 (단일 엔트리포인트).

실행 순서(SP-SEED-3, 멱등): schema → company_types+benefit_presets →
95개 복지 SQL(회사 자기등록 포함) → company_meta 적용(별칭·근무형태) → DEC-2 백필 →
DART 법인 매핑(load_corp, SP-FIN-2 — **마지막**이어야 한다: --fresh 가 TCOMPANY 를 재생성해
COMP_ID 를 다시 배정한 뒤에 이름으로 다시 잇는다).

CLI: `python3 db/seed/load.py [--fresh]`
  --fresh : DROP(FK 역순)+CREATE 후 전체 재시드(테스트/클린 재빌드)
  (기본)  : 멱등 재적용(운영 재시드) — schema.sql은 idempotent(CREATE TABLE IF NOT EXISTS)

접속 정보는 server/.env(dotenv)에서만 읽는다 — 비밀번호를 화면/로그/코드에
하드코딩하지 않는다(os.environ 경유).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pymysql
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_SQL = ROOT / "db" / "schema.sql"
SEED_DIR = Path(__file__).resolve().parent
COMPANY_TYPES_SQL = SEED_DIR / "company_types.sql"
BENEFIT_PRESETS_SQL = SEED_DIR / "benefit_presets.sql"
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"
COMPANY_EMAIL_DOMAIN_SQL = SEED_DIR / "company_email_domain.sql"  # SC14 재직 인증 도메인 화이트리스트(DG-5)

# 생성 순서(FK 부모→자식, SP-DB-8). DROP은 이 역순으로 수행한다.
TABLE_CREATE_ORDER = ["TCOMPANY_TYPE", "TCOMPANY", "TCOMPANY_ALIAS", "TCOMPANY_BENEFIT", "TBENEFIT_PRESET"]
TABLE_DROP_ORDER = list(reversed(TABLE_CREATE_ORDER))

if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))


def _split_sql_statements(sql_text: str) -> list[str]:
    """세미콜론 기준 다중 문장 분할 — 문자열 리터럴 내부 ';'는 보호한다."""
    statements: list[str] = []
    buf: list[str] = []
    in_string: str | None = None
    for ch in sql_text:
        if in_string:
            buf.append(ch)
            if ch == in_string:
                in_string = None
            continue
        if ch in ("'", '"'):
            in_string = ch
            buf.append(ch)
            continue
        if ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
            continue
        buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


def run_sql_file(cur, path: os.PathLike) -> None:
    """SQL 파일을 읽어 다중 문장을 순차 실행(`SET @var` 세션은 동일 커서에서 유지)."""
    text = Path(path).read_text(encoding="utf-8")
    for stmt in _split_sql_statements(text):
        cur.execute(stmt)


def connect() -> pymysql.connections.Connection:
    """동기 pymysql 커넥션(aiomysql 아님, 시드는 동기 경로)."""
    load_dotenv(ROOT / "server" / ".env")
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        autocommit=False,
    )


def _drop_all_tables(cur) -> None:
    cur.execute("SET FOREIGN_KEY_CHECKS=0")
    for t in TABLE_DROP_ORDER:
        cur.execute(f"DROP TABLE IF EXISTS {t}")
    cur.execute("SET FOREIGN_KEY_CHECKS=1")


def _truncate_compare_log(cur) -> None:
    """#15 방지 — --fresh 는 부모 TCOMPANY 를 DROP/재생성해 COMP_ID(AUTO_INCREMENT)를 1부터
    재배정하지만, TABLE_DROP_ORDER 에 없는 TCOMPARE_LOG 행은 옛 COMP_ID 를 그대로 보존한다.
    회사 파일(로스터) 추가·삭제·개명 후 --fresh 를 돌리면 살아남은 로그 쌍이 무결성 오류 없이
    다른 회사쌍으로 재해석돼 '실시간 비교 TOP 10'에 허위 데이터가 노출된다. 참조 로스터를 새로
    세우는 --fresh 시점에 로그를 비워 옛 COMP_ID 잔존을 원천 차단한다.

    (테스트 게이트 경유 시엔 run_tests.sh 가 pytest 이전에 원본 행을 mysqldump 로 백업했다가
    이 재시드 뒤 재주입하므로 서빙 로그는 보존된다 — 여기 TRUNCATE 는 그 사이의 빈 상태일 뿐이다.)
    호출 시점은 run_sql_file(SCHEMA_SQL) 직후라 TCOMPARE_LOG 존재가 보장된다(최초 로드 대비)."""
    cur.execute("TRUNCATE TABLE TCOMPARE_LOG")


def _gather_counts(cur) -> dict:
    """시드 적재 결과 실카운트(하한 스모크 검증용) — 백필까지 끝난 커밋 직전 동일 트랜잭션에서 조회.

    **상태**를 재는 값만 담는다(행 수·미완료 행 수). 백필이 돌려주는 `promoted`·`verified` 는
    "이번에 **바뀐** 행 수"라 재적용에서는 0에 가까워 모드에 따라 뜻이 달라진다 — verify_counts 가
    그 둘을 어떻게 다루는지는 그쪽 주석 참조.
    """
    counts: dict = {}
    for key, table in (
        ("companies", "TCOMPANY"),
        ("benefits", "TCOMPANY_BENEFIT"),
        ("presets", "TBENEFIT_PRESET"),
        ("types", "TCOMPANY_TYPE"),
    ):
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        counts[key] = cur.fetchone()[0]
    # 백필 완료 상태 — 모드와 무관하게 성립해야 하는 종료 조건.
    for key, where in (
        ("est_left", "BADGE_CD='est'"),
        ("verified_null", "VERIFIED_DTM IS NULL"),
        ("expires_null", "EXPIRES_DTM IS NULL"),
        ("amt_source_null", "AMT_SOURCE_CD IS NULL"),
    ):
        cur.execute(f"SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE {where}")
        counts[key] = cur.fetchone()[0]
    return counts


# 하한 상수 — 현재 시드 실측(2026-07: 회사 95·복지 1317·프리셋 28·유형 6·승격/프로버넌스 각 1317)에서
# 보수적으로 잡은 값. 정상 데이터는 여유 있게 상회하고, 부분 적재·빈 테이블 같은 사고만 걸러낸다.
_MIN_COMPANIES = 90   # 실측 95 (run_tests.sh 재시드 검증 하한과 동일)
_MIN_BENEFITS = 1200  # 실측 1317 (test_SD4 하한과 동일: 1330-모비스13)
_MIN_PRESETS = 24     # 실측 28
_MIN_TYPES = 6        # 큐레이션 상수 6종(고정)


def verify_counts(stats: dict, counts: dict | None = None, fresh: bool = True) -> None:
    """하한 assert(방어적 스모크) — 미달 시 AssertionError 로 비0 종료. 상세 검증은 pytest 스위트가 담당.

    🚨 **모드에 따라 뜻이 달라지는 값을 하한으로 재면 안 된다**(2026-07-30, prod 에서 실발현).
    백필의 `promoted`·`verified` 는 UPDATE 로 **실제 바뀐 행 수**다. MySQL 은 matched 가 아니라
    changed 를 돌려주므로, **멱등 재적용(fresh=False)에서는 이미 official·VERIFIED 인 기존 행이
    0으로 세어진다.** 그래서 이 검증은 프로젝트가 prod 용으로 문서화한 재적용 경로에서 **항상
    실패**했다(CJ 계열 7개사 추가 시 `verified: 148 < 1200`). 데이터는 정상이었고 어서션만 틀렸다 —
    커밋 이후에 실행되는 검증이라 "실패했는데 반영은 됐다"는 최악의 모양이 된다.

    → 볼륨(바뀐 행 수)은 **fresh 로드에서만** 재고, 재적용에서는 **종료 상태**를 잰다.
      상태 검사는 모드와 무관하게 성립하고, "얼마나 일했나"보다 "끝났나"를 직접 확인하므로 더 강하다.
    """
    # (1) 백필 완료 **상태** — 모드 무관. 이게 진짜 종료 조건이다.
    if counts is not None:
        for key, label in (("est_left", "미승격 est 잔존"), ("verified_null", "VERIFIED_DTM 미채움"),
                           ("expires_null", "EXPIRES_DTM 미채움"), ("amt_source_null", "amt_source 미채움")):
            if key in counts:
                assert counts[key] == 0, f"백필 미완료 — {label}: {counts[key]}행"

    # (2) 백필 볼륨 — **fresh 로드에서만** 의미가 있다(재적용은 바뀐 행이 적은 게 정상).
    promoted = stats.get("promoted")
    assert promoted is not None, "backfill 통계 누락(promoted)"
    if fresh:
        assert promoted >= _MIN_BENEFITS, f"복지 official 승격행 부족: {promoted} < {_MIN_BENEFITS}"
        verified = stats.get("verified")
        assert verified is not None and verified >= _MIN_BENEFITS, \
            f"복지 프로버넌스 적용행 부족: {verified} < {_MIN_BENEFITS}"
    else:
        assert stats.get("verified") is not None, "backfill 통계 누락(verified)"

    amt = stats.get("amt_source") or {}
    assert {"stated", "estimated", "none"} <= set(amt), f"amt_source 키 누락: {sorted(amt)}"
    # amt_source 는 전량 재계산이라 모드와 무관하게 총량이 나온다.
    assert sum(amt.values()) >= _MIN_BENEFITS, \
        f"amt_source 합계 부족: {sum(amt.values())} < {_MIN_BENEFITS}"

    # (3) 실적재 카운트 — 회사·복지·프리셋·유형(커넥션이 열려 있을 때 main 이 수집해 전달)
    if counts is not None:
        assert counts.get("companies", 0) >= _MIN_COMPANIES, \
            f"회사 수 부족: {counts.get('companies')} < {_MIN_COMPANIES}"
        assert counts.get("benefits", 0) >= _MIN_BENEFITS, \
            f"복지 행 수 부족: {counts.get('benefits')} < {_MIN_BENEFITS}"
        assert counts.get("presets", 0) >= _MIN_PRESETS, \
            f"프리셋 수 부족: {counts.get('presets')} < {_MIN_PRESETS}"
        assert counts.get("types", 0) >= _MIN_TYPES, \
            f"기업유형 수 부족: {counts.get('types')} < {_MIN_TYPES}"


def main(fresh: bool = False) -> dict:
    """fresh=True: DROP+CREATE 후 전체 재시드. fresh=False: 멱등 재적용(기본)."""
    from backfill_dec2 import backfill
    from companies import apply_company_meta
    from company_meta import build_company_meta
    from load_corp import apply as apply_corp_map, read_map as read_corp_map

    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            if fresh:
                _drop_all_tables(cur)
            run_sql_file(cur, SCHEMA_SQL)  # 1: schema (idempotent CREATE TABLE IF NOT EXISTS)
            if fresh:
                _truncate_compare_log(cur)  # #15: 스키마 보장 후 비움 — 옛 COMP_ID 오귀속 차단
            run_sql_file(cur, COMPANY_TYPES_SQL)  # 2a: 기업유형 6종
            run_sql_file(cur, BENEFIT_PRESETS_SQL)  # 2b: 프리셋 28행(full-refresh)
            for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):  # 3: 95개 복지 SQL(회사 자기등록 포함)
                run_sql_file(cur, f)
            meta = build_company_meta()
            apply_company_meta(cur, meta)  # 4: 별칭·근무형태 보강
            run_sql_file(cur, COMPANY_EMAIL_DOMAIN_SQL)  # 4b: 회사↔이메일 도메인 화이트리스트(재직 인증, DG-5)
            stats = backfill(cur)  # 5: DEC-2 백필(official 승격·amt_source·출처·만료)
            # 6: DART 법인 매핑(SP-FIN-2). 참조 5테이블 재생성 뒤 COMP_ID 가 바뀌므로 **여기(마지막)**서
            #    이름으로 다시 잇는다 — 안 하면 재시드 한 번에 실적 섹션이 에러 없이 사라진다(함정 (57)).
            #    TCORP·TCOMPANY_CORP 는 --fresh 의 DROP 대상이 아니라 upsert + CSV 밖 잔존 행 제거로 맞춘다.
            corp_stats = apply_corp_map(cur, read_corp_map())
            stats["corp_mapped"] = corp_stats["mapped"]
            stats["corp_unmatched"] = corp_stats["unmatched"]
            counts = _gather_counts(cur)  # 하한 스모크용 실카운트(커밋 직전, 동일 트랜잭션)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    # ⚠ 이 검증은 **커밋 이후**에 돈다. 그래서 어서션이 틀리면 "실패했는데 반영은 됐다"가 된다 —
    #    모드에 맞는 기준을 쓰는 것이 그만큼 중요하다(verify_counts 주석 참조).
    verify_counts(stats, counts, fresh=fresh)
    return stats


def _target_desc() -> str:
    """접속 대상 요약(user@host:port/db, 비밀번호 제외) — 파괴 작업 전 명시 출력용."""
    load_dotenv(ROOT / "server" / ".env")
    return (
        f"{os.environ.get('DB_USER', '?')}@{os.environ.get('DB_HOST', '?')}"
        f":{os.environ.get('DB_PORT', '3306')}/{os.environ.get('DB_NAME', '?')}"
    )


if __name__ == "__main__":
    _argv = sys.argv[1:]
    fresh_flag = "--fresh" in _argv
    if fresh_flag:
        # #14: --fresh 는 서빙 참조 5테이블 DROP + TCOMPARE_LOG TRUNCATE 로 데이터를 파괴한다.
        # 환경변수 LOUPIT_ALLOW_FRESH=1 또는 CLI --yes 없이는 거부한다(셸 히스토리 재실행·오타 방어).
        # run_tests.sh 등 복원 책임을 지는 래퍼는 LOUPIT_ALLOW_FRESH=1 을 전달해 통과한다.
        _target = _target_desc()
        if os.environ.get("LOUPIT_ALLOW_FRESH") != "1" and "--yes" not in _argv:
            print(
                f"거부: --fresh 는 대상 [{_target}] 의 참조 5테이블(TCOMPANY_TYPE·TCOMPANY·"
                "TCOMPANY_ALIAS·TCOMPANY_BENEFIT·TBENEFIT_PRESET)을 DROP 하고 TCOMPARE_LOG 를 "
                "TRUNCATE 한다.\n"
                "      의도한 실행이면 LOUPIT_ALLOW_FRESH=1 환경변수 또는 --yes 플래그를 붙여라.",
                file=sys.stderr,
            )
            sys.exit(2)
        # (b) 파괴 작업 직전 대상 명시 — 어느 host/db 를 비우는지 로그에 남긴다.
        print(
            f"[load --fresh] 대상 [{_target}] — 참조 5테이블 DROP/재시드 + TCOMPARE_LOG TRUNCATE 진행",
            file=sys.stderr,
        )
    try:
        result_stats = main(fresh=fresh_flag)
    except Exception as exc:  # noqa: BLE001 — CLI 최종 경계, 비0 종료로 전파
        print(f"seed failed: {exc}", file=sys.stderr)
        sys.exit(1)
    print(f"seed done: {result_stats}")
