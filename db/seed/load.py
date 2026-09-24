"""SP-SEED-9 — 시드 오케스트레이터 (단일 엔트리포인트).

실행 순서(SP-SEED-3, 멱등): schema → company_types+benefit_presets →
95개 복지 SQL(회사 자기등록 포함) → company_meta 적용(별칭·근무형태) → DEC-2 백필 →
DART 법인 매핑(load_corp, SP-FIN-2 — **마지막**이어야 한다: --fresh 가 TCOMPANY 를 재생성해
COMP_ID 를 다시 배정한 뒤에 이름으로 다시 잇는다).

CLI: `python3 db/seed/load.py [--fresh]`
  (기본)  : 멱등 재적용(운영 재시드 — **시드 변경은 이것으로 반영한다**). schema.sql 은
            idempotent(CREATE TABLE IF NOT EXISTS)이고 재직자 행은 건드리지 않는다(아래).
  --fresh : DROP(FK 역순)+CREATE 후 전체 재시드(테스트/클린 재빌드). 재직자 데이터가 있으면 거부.

🚨 SP-SEED-12 재직자 행 보존(2026-09-24) — **시드·백필은 재직자 행(`BADGE_CD='verified'`)을 쓰지 않는다.**
  재직자 행 = 편집 서비스(`server/services/benefit_edit.py`)가 등록·수정한 행. `verified` 는 그
  서비스만 쓰는 값이다(시드는 'est', 백필은 'official'). 데이터 정정 마이그레이션도 `BADGE_CD='official'`
  가드로 재직자 행을 비켜 가는 것이 규약이다(선례 db/migrations/20260918_meal_anchor_to_qual.sql).

  사고(2026-09-20 06:17:36 UTC, 웨이브 4 멱등 적재): 복지 SQL 의 `ON DUPLICATE KEY UPDATE` 가 행을
  가리지 않고 덮어 운영의 재직자 수정 2행(BENEFIT_ID 971·1400)이 시드 값·'est' 로 돌아갔고, 백필이
  'official' 로 올리며 출처·신선도까지 시드 것으로 바꿨다. `MOD_ID` 는 재직자로 남아 편집 이력에서
  파생하는 「공식·재직자 수정」 배지가 시드 값 위에 달렸다(허위 표시). 되살리기는
  db/migrations/20260924_restore_member_edits.sql.

  150개 시드 파일을 고치지 않고 로더가 막는다(한 트랜잭션 안에서):
    ① 기준점 — 편집 이력 (행 수, 최대 ID)을 잰다.
    ② 스냅숏 — 복지 SQL 직전, 재직자 행 **전 컬럼**을 세션 임시 테이블에 뜬다.
    ③ 복원 — 복지 SQL 직후 전 컬럼을 그대로 되돌린다(MOD_DTM 까지 명시 대입 — ON UPDATE 자동
       갱신이 끼지 않는다). 컬럼 목록은 information_schema 에서 읽어 새 컬럼도 저절로 덮는다.
       백필 **앞**에서 되돌리는 이유: 백필이 그 행을 재직자 행으로 보고 건너뛰어야 앵커 판정에서도
       빠진다 — 백필 뒤에 되돌리면 백필 동안 그 행은 시드 값·official 이라 판정에 끼어든다.
    ④ 백필은 재직자 행을 읽지도 쓰지도 않는다(backfill_dec2.py).
    ⑤ 대조 — 커밋 직전 스냅숏과 전 컬럼을 다시 맞춰 보고, 사라졌거나 다르면 예외 → 롤백.
    ⑥ 경합 — ①의 기준점이 커밋 직전에 달라졌으면(적재 도중 다른 커넥션에서 재직자 편집이 커밋됐으면)
       예외 → 롤백. 스냅숏 뒤에 생긴 재직자 행은 시드가 덮었을 수 있기 때문이다. 다시 실행하면 된다.
       (READ COMMITTED 인 운영에서는 적재가 행을 미리 잠그지 않으므로 이 대조가 유일한 방어다.
        대조는 잠금 읽기라 격리 수준과 무관하게 커밋된 최신 이력을 본다.)

  `--fresh` 는 재직자 데이터(편집 이력 1건 이상 또는 재직자 행)가 있으면 **거부**한다(종료 코드 2).
  TCOMPANY_BENEFIT 을 DROP 하면 재직자 행이 사라지고, AUTO_INCREMENT 로 다시 매겨진 BENEFIT_ID
  때문에 남은 편집 이력이 **엉뚱한 행**을 가리켜 그 행에 재직자 배지가 붙는다. 편집 이력은
  append-only 라 지워지지 않으므로 운영에서는 이 거부가 사실상 상시다 — 시드 변경은 멱등 재적용으로.
  폐기 허용(`main(discard_member_edits=True)`, CLI 는 명령줄 환경의 `LOUPIT_DISCARD_MEMBER_EDITS=1` —
  server/.env 에 적어도 무시한다)은 **일회용 격리 DB(테스트) 전용**이다. 허용하면 편집 이력도 함께
  비운다(엉뚱한 행을 가리키지 않게).
  운영 문서·스크립트에는 이 신호를 쓰지 않는다(server/tests/test_seed_member_rows.py SK-7 이 강제).

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

from backfill_dec2 import MEMBER_BADGE_CD  # noqa: E402  # SP-SEED-12 재직자 행 표지('verified')

# SP-SEED-12: 적재 트랜잭션 수명의 세션 임시 테이블(재직자 행 스냅숏). 임시 테이블 CREATE/DROP 은
# 암묵 커밋을 일으키지 않아 복지 SQL·백필과 한 트랜잭션에 묶인다.
_MEMBER_SNAPSHOT = "TMP_MEMBER_BENEFIT"


class FreshRefusedError(RuntimeError):
    """`--fresh` 거부 — 재직자 데이터가 있고 폐기 허용이 없다(아무것도 지우기 전에 멈춘다)."""


class MemberRowGuardError(RuntimeError):
    """재직자 행 보존 실패 또는 적재 중 재직자 편집 커밋 — 적재를 되돌렸다(커밋 안 함)."""


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


# ── SP-SEED-12 재직자 행 보존 (모듈 머리말 ①~⑥) ────────────────────────────────────

def _member_data_counts(cur) -> tuple[int, int]:
    """(편집 이력 행 수, 재직자 행 수). DROP 전에 부르므로 표 존재부터 본다 — 최초 적재면 (0, 0)."""
    cur.execute(
        "SELECT TABLE_NAME FROM information_schema.TABLES "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('TBENEFIT_EDIT_LOG', 'TCOMPANY_BENEFIT')"
    )
    present = {r[0] for r in cur.fetchall()}
    n_log = n_member = 0
    if "TBENEFIT_EDIT_LOG" in present:
        cur.execute("SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG")
        n_log = cur.fetchone()[0]
    if "TCOMPANY_BENEFIT" in present:
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD = %s", (MEMBER_BADGE_CD,))
        n_member = cur.fetchone()[0]
    return int(n_log), int(n_member)


def _refuse_fresh_over_member_data(cur, discard_member_edits: bool) -> None:
    """--fresh 가드 — 재직자 데이터가 있고 폐기 허용이 없으면 **DROP 전에** 멈춘다(아무것도 안 지운다).

    편집 이력만 있어도 거부한다: 2026-09-24 운영이 바로 그 상태다(재직자 행은 웨이브 4 적재로 되돌아갔고
    이력 2건만 남았다). 그 상태로 --fresh 가 돌면 다시 매겨진 BENEFIT_ID 에 이력이 붙어 엉뚱한 행이
    「공식·재직자 수정」으로 뜬다."""
    n_log, n_member = _member_data_counts(cur)
    if (n_log or n_member) and not discard_member_edits:
        raise FreshRefusedError(
            f"--fresh 는 대상 [{_target_desc()}] 의 재직자 데이터(편집 이력 {n_log}건 · 재직자 행 "
            f"{n_member}건)를 파괴한다.\n"
            "      TCOMPANY_BENEFIT 을 DROP 하면 재직자가 등록·수정한 행이 사라지고, AUTO_INCREMENT 로 다시\n"
            "      매겨진 BENEFIT_ID 때문에 남은 편집 이력이 엉뚱한 행을 가리켜 그 행에 재직자 배지가 붙는다.\n"
            "      시드 변경은 --fresh 없이 `python3 db/seed/load.py` 로 반영하라"
            "(멱등 재적용 — 재직자 행은 그대로 둔다, SP-SEED-12)."
        )


def _clear_edit_log(cur) -> None:
    """--fresh 전용 — 폐기를 허용한 편집 이력을 비운다. DROP 뒤 BENEFIT_ID·COMP_ID 가 다시 매겨지므로
    남은 이력은 엉뚱한 행에 재직자 배지를 붙이고 공개 편집 이력을 다른 회사 밑에 보인다(#15 TCOMPARE_LOG
    와 같은 뿌리). 폐기 허용이 없으면 _refuse_fresh_over_member_data 가 이미 멈췄으므로 여기 올 때 이력은
    비어 있거나 폐기가 허용된 것이다. TRUNCATE 가 아니라 DELETE — 이 표를 가리키는 FK 가 생겨도 깨지지 않게."""
    cur.execute("DELETE FROM TBENEFIT_EDIT_LOG")


def _benefit_columns(cur) -> list[str]:
    """TCOMPANY_BENEFIT 의 되돌릴 컬럼 — 조인 키(BENEFIT_ID)와 생성 컬럼을 뺀 **전부**.

    information_schema 에서 읽는다: 컬럼이 늘면 보존 대상도 저절로 는다. 하드코딩 목록은 새 컬럼을
    조용히 흘린다(Pydantic·화이트리스트 정규화가 필드를 떨군 것과 같은 모양)."""
    cur.execute(
        "SELECT COLUMN_NAME FROM information_schema.COLUMNS "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TCOMPANY_BENEFIT' "
        "  AND COLUMN_NAME <> 'BENEFIT_ID' "
        "  AND (GENERATION_EXPRESSION IS NULL OR GENERATION_EXPRESSION = '') "
        "ORDER BY ORDINAL_POSITION"
    )
    cols = [r[0] for r in cur.fetchall()]
    if "BADGE_CD" not in cols or "MOD_DTM" not in cols:
        raise MemberRowGuardError(f"TCOMPANY_BENEFIT 컬럼 목록을 읽지 못했다: {cols}")
    return cols


def _edit_log_mark(cur, *, locking: bool = False) -> tuple[int, int]:
    """① 편집 이력 기준점 = (행 수, 최대 EDIT_LOG_ID). 이력은 append-only 라 새 편집이 커밋되면 행 수가 는다
    (AUTO_INCREMENT 는 커밋 순서가 아니라 할당 순서라 최대 ID 만 보면 늦게 커밋된 작은 ID 를 놓친다).
    locking=True 는 잠금 읽기(FOR SHARE) — REPEATABLE READ 스냅숏과 무관하게 커밋된 최신 이력을 본다."""
    cur.execute(
        "SELECT COUNT(*), COALESCE(MAX(EDIT_LOG_ID), 0) FROM TBENEFIT_EDIT_LOG"
        + (" FOR SHARE" if locking else "")
    )
    n, top = cur.fetchone()
    return int(n), int(top)


def _snapshot_member_rows(cur, cols: list[str]) -> int:
    """② 재직자 행 전 컬럼을 세션 임시 테이블에 뜬다. 반환: 재직자 행 수."""
    col_sql = ", ".join(f"`{c}`" for c in ["BENEFIT_ID", *cols])
    cur.execute(f"DROP TEMPORARY TABLE IF EXISTS {_MEMBER_SNAPSHOT}")
    cur.execute(f"CREATE TEMPORARY TABLE {_MEMBER_SNAPSHOT} LIKE TCOMPANY_BENEFIT")
    cur.execute(
        f"INSERT INTO {_MEMBER_SNAPSHOT} ({col_sql}) "
        f"SELECT {col_sql} FROM TCOMPANY_BENEFIT WHERE BADGE_CD = %s",
        (MEMBER_BADGE_CD,),
    )
    return cur.rowcount


def _restore_member_rows(cur, cols: list[str]) -> int:
    """③ 복지 SQL 이 덮은 재직자 행을 스냅숏 값으로 되돌린다. 반환: 실제로 되돌린(= 시드가 덮었던) 행 수.

    MOD_DTM 도 명시 대입한다 — `ON UPDATE CURRENT_TIMESTAMP` 는 명시 대입된 컬럼에는 끼지 않는다."""
    sets = ", ".join(f"b.`{c}` = m.`{c}`" for c in cols)
    cur.execute(
        f"UPDATE TCOMPANY_BENEFIT b JOIN {_MEMBER_SNAPSHOT} m ON m.BENEFIT_ID = b.BENEFIT_ID SET {sets}"
    )
    return cur.rowcount


def _assert_member_rows_intact(cur, cols: list[str]) -> None:
    """⑤ 커밋 직전 대조 — 스냅숏의 재직자 행이 전 컬럼 그대로(NULL-안전 비교) 남아 있어야 한다."""
    same = " AND ".join(f"b.`{c}` <=> m.`{c}`" for c in cols)
    cur.execute(
        f"SELECT m.BENEFIT_ID FROM {_MEMBER_SNAPSHOT} m "
        f"LEFT JOIN TCOMPANY_BENEFIT b ON b.BENEFIT_ID = m.BENEFIT_ID "
        f"WHERE b.BENEFIT_ID IS NULL OR NOT ({same}) ORDER BY m.BENEFIT_ID"
    )
    broken = [r[0] for r in cur.fetchall()]
    if broken:
        raise MemberRowGuardError(
            f"재직자 행 보존 실패 — BENEFIT_ID {broken} 가 적재 전과 다르다(사라졌거나 값이 바뀌었다). "
            "적재를 되돌렸다(커밋 안 함). 어느 단계가 재직자 행을 썼는지 찾아 고쳐라(SP-SEED-12)."
        )


def _assert_no_member_edit_during_load(cur, mark: tuple[int, int]) -> None:
    """⑥ 적재 도중 다른 커넥션에서 재직자 편집이 커밋됐으면 되돌린다 — 스냅숏 뒤에 생긴 재직자 행은
    보존 대상에 없어 시드가 덮었을 수 있다. 드문 경합이라 다시 실행하면 된다."""
    now = _edit_log_mark(cur, locking=True)
    if now != mark:
        raise MemberRowGuardError(
            f"적재 도중 재직자 편집이 커밋됐다(편집 이력 {mark[0]}건 → {now[0]}건). 그 편집을 시드가 덮었을 수 "
            "있어 적재를 되돌렸다(커밋 안 함) — 다시 실행하라."
        )


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
    # amt_source 는 재직자 행을 뺀 전량 재계산이라(SP-SEED-12) 모드와 무관하게 총량이 나온다.
    # 재직자 행은 한 줌이라 하한(1200)은 그대로 둔다 — 느슨하게 할 이유가 없다.
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


def main(fresh: bool = False, discard_member_edits: bool = False) -> dict:
    """fresh=True: DROP+CREATE 후 전체 재시드. fresh=False: 멱등 재적용(기본 — 운영 재시드).

    discard_member_edits: fresh 에서 재직자 데이터(편집 이력·재직자 행) 폐기를 허용한다 — **일회용 격리 DB
    (테스트) 전용**. 거짓(기본)이면 재직자 데이터 앞에서 FreshRefusedError 로 멈춘다(SP-SEED-12).
    멱등 재적용에는 영향이 없다 — 그 경로는 재직자 행을 원래 건드리지 않는다."""
    from backfill_dec2 import backfill
    from companies import apply_company_meta
    from company_meta import build_company_meta
    from load_corp import apply as apply_corp_map, read_map as read_corp_map

    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            if fresh:
                _refuse_fresh_over_member_data(cur, discard_member_edits)  # SP-SEED-12: DROP 전에 거부
                _drop_all_tables(cur)
            run_sql_file(cur, SCHEMA_SQL)  # 1: schema (idempotent CREATE TABLE IF NOT EXISTS)
            if fresh:
                _truncate_compare_log(cur)  # #15: 스키마 보장 후 비움 — 옛 COMP_ID 오귀속 차단
                _clear_edit_log(cur)  # SP-SEED-12: 다시 매겨질 BENEFIT_ID 를 가리킬 이력을 남기지 않는다
            run_sql_file(cur, COMPANY_TYPES_SQL)  # 2a: 기업유형 6종
            run_sql_file(cur, BENEFIT_PRESETS_SQL)  # 2b: 프리셋 28행(full-refresh)
            # ── SP-SEED-12: 여기부터 커밋까지 한 트랜잭션(DDL 없음 — 임시 테이블은 암묵 커밋 없음) ──
            benefit_cols = _benefit_columns(cur)
            edit_mark = _edit_log_mark(cur)  # ① 기준점 — 스냅숏보다 먼저 잰다
            member_rows = _snapshot_member_rows(cur, benefit_cols)  # ② 재직자 행 전 컬럼 스냅숏
            for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):  # 3: 복지 SQL(회사 자기등록 포함)
                run_sql_file(cur, f)
            member_restored = _restore_member_rows(cur, benefit_cols)  # ③ 업서트가 덮은 재직자 행 복원
            meta = build_company_meta()
            apply_company_meta(cur, meta)  # 4: 별칭·근무형태 보강
            run_sql_file(cur, COMPANY_EMAIL_DOMAIN_SQL)  # 4b: 회사↔이메일 도메인 화이트리스트(재직 인증, DG-5)
            stats = backfill(cur)  # 5: DEC-2 백필(official 승격·amt_source·출처·만료) — ④ 재직자 행 제외
            # 6: DART 법인 매핑(SP-FIN-2). 참조 5테이블 재생성 뒤 COMP_ID 가 바뀌므로 **여기(마지막)**서
            #    이름으로 다시 잇는다 — 안 하면 재시드 한 번에 실적 섹션이 에러 없이 사라진다(함정 (57)).
            #    TCORP·TCOMPANY_CORP 는 --fresh 의 DROP 대상이 아니라 upsert + CSV 밖 잔존 행 제거로 맞춘다.
            corp_stats = apply_corp_map(cur, read_corp_map())
            stats["corp_mapped"] = corp_stats["mapped"]
            stats["corp_unmatched"] = corp_stats["unmatched"]
            _assert_member_rows_intact(cur, benefit_cols)  # ⑤ 전 컬럼 대조 — 어긋나면 예외 → 롤백
            _assert_no_member_edit_during_load(cur, edit_mark)  # ⑥ 적재 중 재직자 편집 커밋 → 롤백
            stats["member_rows"] = member_rows  # 보존한 재직자 행 수
            stats["member_restored"] = member_restored  # 그중 시드 업서트가 덮어 되돌린 행 수
            counts = _gather_counts(cur)  # 하한 스모크용 실카운트(커밋 직전, 동일 트랜잭션)
            cur.execute(f"DROP TEMPORARY TABLE IF EXISTS {_MEMBER_SNAPSHOT}")
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
    # SP-SEED-12: 재직자 데이터 폐기 허용 — 일회용 격리 DB 전용 신호(모듈 머리말). 운영에 쓰지 않는다.
    # dotenv 를 읽기 **전에** 잡는다: 아래 _target_desc()·connect() 가 server/.env 를 os.environ 에
    # 싣는데, 누가 그 파일에 이 신호를 적어 두어도 --fresh 거부가 조용히 풀리지 않게 명령줄 환경만 본다.
    discard_member_edits_flag = os.environ.get("LOUPIT_DISCARD_MEMBER_EDITS") == "1"
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
                "      시드 변경 반영이라면 --fresh 가 아니라 `python3 db/seed/load.py`(멱등 재적용)다.\n"
                "      의도한 실행이면 LOUPIT_ALLOW_FRESH=1 환경변수 또는 --yes 플래그를 붙여라.",
                file=sys.stderr,
            )
            sys.exit(2)
        # (b) 파괴 작업 직전 대상 명시 — 어느 host/db 를 비우는지 로그에 남긴다.
        print(
            f"[load --fresh] 대상 [{_target}] — 재직자 데이터 확인 후 참조 5테이블 DROP/재시드 + "
            "TCOMPARE_LOG TRUNCATE",
            file=sys.stderr,
        )
    try:
        result_stats = main(fresh=fresh_flag, discard_member_edits=discard_member_edits_flag)
    except FreshRefusedError as exc:  # DROP 전에 멈췄다 — 위 LOUPIT_ALLOW_FRESH 거부와 같은 종료 코드
        print(f"거부: {exc}", file=sys.stderr)
        sys.exit(2)
    except Exception as exc:  # noqa: BLE001 — CLI 최종 경계, 비0 종료로 전파
        print(f"seed failed: {exc}", file=sys.stderr)
        sys.exit(1)
    print(f"seed done: {result_stats}")
