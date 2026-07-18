"""SP-SEED-9 — 시드 오케스트레이터 (단일 엔트리포인트).

실행 순서(SP-SEED-3, 멱등): schema → company_types+benefit_presets →
95개 복지 SQL(회사 자기등록 포함) → company_meta 적용(별칭·근무형태) → DEC-2 백필.

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
    """시드 적재 결과 실카운트(하한 스모크 검증용) — 백필까지 끝난 커밋 직전 동일 트랜잭션에서 조회."""
    counts: dict = {}
    for key, table in (
        ("companies", "TCOMPANY"),
        ("benefits", "TCOMPANY_BENEFIT"),
        ("presets", "TBENEFIT_PRESET"),
        ("types", "TCOMPANY_TYPE"),
    ):
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        counts[key] = cur.fetchone()[0]
    return counts


# 하한 상수 — 현재 시드 실측(2026-07: 회사 95·복지 1317·프리셋 28·유형 6·승격/프로버넌스 각 1317)에서
# 보수적으로 잡은 값. 정상 데이터는 여유 있게 상회하고, 부분 적재·빈 테이블 같은 사고만 걸러낸다.
_MIN_COMPANIES = 90   # 실측 95 (run_tests.sh 재시드 검증 하한과 동일)
_MIN_BENEFITS = 1200  # 실측 1317 (test_SD4 하한과 동일: 1330-모비스13)
_MIN_PRESETS = 24     # 실측 28
_MIN_TYPES = 6        # 큐레이션 상수 6종(고정)


def verify_counts(stats: dict, counts: dict | None = None) -> None:
    """하한 assert(방어적 스모크) — 미달 시 AssertionError 로 비0 종료. 상세 검증은 pytest 스위트가 담당.

    두 축을 본다: (1) 백필 통계(stats) — 승격·프로버넌스 단계가 기대 볼륨을 처리했는지,
    (2) 실적재 카운트(counts) — 회사·복지·프리셋·유형 행이 시드 하한을 채웠는지.
    옛 판본은 `promoted is not None` 만 확인해 사실상 무검증이었다(low #14).
    """
    # (1) 백필 통계 — 승격·프로버넌스 볼륨(단계5가 전량을 처리했는지)
    promoted = stats.get("promoted")
    assert promoted is not None, "backfill 통계 누락(promoted)"
    assert promoted >= _MIN_BENEFITS, f"복지 official 승격행 부족: {promoted} < {_MIN_BENEFITS}"
    verified = stats.get("verified")
    assert verified is not None and verified >= _MIN_BENEFITS, \
        f"복지 프로버넌스 적용행 부족: {verified} < {_MIN_BENEFITS}"
    amt = stats.get("amt_source") or {}
    assert {"stated", "estimated", "none"} <= set(amt), f"amt_source 키 누락: {sorted(amt)}"
    assert sum(amt.values()) >= _MIN_BENEFITS, \
        f"amt_source 합계 부족: {sum(amt.values())} < {_MIN_BENEFITS}"

    # (2) 실적재 카운트 — 회사·복지·프리셋·유형(커넥션이 열려 있을 때 main 이 수집해 전달)
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
            stats = backfill(cur)  # 5: DEC-2 백필(official 승격·amt_source·출처·만료)
            counts = _gather_counts(cur)  # 하한 스모크용 실카운트(커밋 직전, 동일 트랜잭션)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    verify_counts(stats, counts)
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
