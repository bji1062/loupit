"""SP-DB-16.1 스키마 로드 테스트 (SC-1~SC-6).

근거: SPEC/02 SP-DB-16.1 · TASK/02 T-02.2.1~T-02.2.6 · T-02.3.1~T-02.3.2.
"""

from __future__ import annotations

import pytest

from server.tests.conftest import REMOVED_TABLES, TABLE_CREATE_ORDER

EXPECTED_TABLES = set(TABLE_CREATE_ORDER)

# ── SC-3 컬럼 계약 (테이블별 핵심 컬럼: 이름, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT) ──
# COLUMN_DEFAULT는 information_schema 표기 그대로 비교(문자열/None).
EXPECTED_COLUMNS: dict[str, dict[str, dict]] = {
    "TCOMPANY_TYPE": {
        "COMP_TP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "COMP_TP_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "COMP_TP_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        # GROWTH_RATE_VAL/GROWTH_LABEL_NM/STABILITY_SCORE_NO는 브랜드 축 제거로 드랍됨
        # (db/migrations/20260720_drop_brand_axis_columns.sql, 2026-07-20).
    },
    "TCOMPANY": {
        "COMP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "COMP_ENG_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "COMP_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "COMP_TP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "INDUSTRY_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "LOGO_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "WORK_STYLE_VAL": {"DATA_TYPE": "json", "IS_NULLABLE": "YES"},
        "CAREERS_BENEFIT_URL": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
    },
    "TCOMPANY_ALIAS": {
        "ALIAS_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "COMP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "ALIAS_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
    },
    "TCOMPANY_BENEFIT": {
        "BENEFIT_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "COMP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "BENEFIT_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BENEFIT_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BENEFIT_AMT": {"DATA_TYPE": "int", "IS_NULLABLE": "YES", "COLUMN_DEFAULT": None},
        "BENEFIT_CTGR_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BADGE_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO", "COLUMN_DEFAULT": "est"},
        "AMT_SOURCE_CD": {
            "DATA_TYPE": "varchar",
            "IS_NULLABLE": "NO",
            "COLUMN_DEFAULT": "estimated",
            "CHARACTER_MAXIMUM_LENGTH": 10,
        },
        "BADGE_SRC_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "BADGE_SRC_URL_CTNT": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "VERIFIED_DTM": {"DATA_TYPE": "datetime", "IS_NULLABLE": "YES"},
        "EXPIRES_DTM": {"DATA_TYPE": "datetime", "IS_NULLABLE": "YES"},
        "NOTE_CTNT": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "QUAL_YN": {"DATA_TYPE": "tinyint", "IS_NULLABLE": "NO", "COLUMN_DEFAULT": "0"},
        "QUAL_DESC_CTNT": {"DATA_TYPE": "varchar", "IS_NULLABLE": "YES"},
        "SORT_ORDER_NO": {"DATA_TYPE": "smallint", "IS_NULLABLE": "YES", "COLUMN_DEFAULT": "0"},
    },
    "TBENEFIT_PRESET": {
        "PRESET_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "COMP_TP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "BENEFIT_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BENEFIT_NM": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BENEFIT_AMT": {"DATA_TYPE": "int", "IS_NULLABLE": "YES"},
        "BENEFIT_CTGR_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO"},
        "BADGE_CD": {"DATA_TYPE": "varchar", "IS_NULLABLE": "NO", "COLUMN_DEFAULT": "est"},
        "DEFAULT_CHECKED_YN": {"DATA_TYPE": "tinyint", "IS_NULLABLE": "NO", "COLUMN_DEFAULT": "1"},
        "SORT_ORDER_NO": {"DATA_TYPE": "smallint", "IS_NULLABLE": "YES", "COLUMN_DEFAULT": "0"},
    },
    # 익명 비교 로그(INV-1 개정 2026-07-14) — 쌍 comp_id + 시각 3컬럼뿐이어야 한다.
    # 사용자 식별자·입력값 컬럼이 추가되면 이 계약이 깨진다(프라이버시 가드).
    "TCOMPARE_LOG": {
        "CMP_LOG_ID": {"DATA_TYPE": "bigint", "IS_NULLABLE": "NO"},
        "A_COMP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "B_COMP_ID": {"DATA_TYPE": "int", "IS_NULLABLE": "NO"},
        "INS_DTM": {"DATA_TYPE": "timestamp", "IS_NULLABLE": "NO"},
    },
}

AUDIT_COLUMNS = {"INS_ID", "INS_DTM", "MOD_ID", "MOD_DTM"}


def _table_names(conn, db_name: str) -> set[str]:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s",
            (db_name,),
        )
        return {row[0] for row in cur.fetchall()}


def _columns(conn, db_name: str, table: str) -> dict[str, dict]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT,
                   COLUMN_COMMENT, CHARACTER_MAXIMUM_LENGTH
              FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s
            """,
            (db_name, table),
        )
        rows = cur.fetchall()
    return {
        r[0]: {
            "DATA_TYPE": r[1],
            "IS_NULLABLE": r[2],
            "COLUMN_DEFAULT": r[3],
            "COLUMN_COMMENT": r[4],
            "CHARACTER_MAXIMUM_LENGTH": r[5],
        }
        for r in rows
    }


# ── T-02.1.1 하네스 smoke: 커넥션 성립 + utf8mb4 세션 확인 (SC-1 전제) ──
def test_harness_connection_and_utf8mb4_session(db_conn, db_name):
    with db_conn.cursor() as cur:
        cur.execute("SELECT DATABASE()")
        assert cur.fetchone()[0] == db_name
        cur.execute("SHOW VARIABLES LIKE 'character_set_connection'")
        assert cur.fetchone()[1] == "utf8mb4"


# ── SC-1: 로드 성공 — 5개 테이블 존재 ──
def test_SC1_schema_load_creates_5_tables(schema_db, db_name):
    names = _table_names(schema_db, db_name)
    missing = EXPECTED_TABLES - names
    assert not missing, f"누락 테이블: {missing}"


def test_SC1_seeded_pipeline_tables_exist(seeded_db, db_name):
    """T-02.1.2 seeded 픽스처 smoke — 5개 테이블 존재(적용 오케스트레이션 검증)."""
    names = _table_names(seeded_db, db_name)
    missing = EXPECTED_TABLES - names
    assert not missing, f"누락 테이블: {missing}"


def test_SC1_seeded_pipeline_rows_loaded(seeded_db, db_name):
    """T-02.1.2 seeded 픽스처 — 시드 행 로드 확인(SP-SEED 완료 후 의미 있음)."""
    with seeded_db.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_TYPE")
        assert cur.fetchone()[0] > 0


# ── SC-2: 제거 테이블 부재 ──
def test_SC2_removed_tables_absent(schema_db, db_name):
    names = _table_names(schema_db, db_name)
    present = names & set(REMOVED_TABLES)
    assert not present, f"제거 대상 테이블이 존재함: {present}"


# ── SC-3: 컬럼·타입·NULL·DEFAULT·COMMENT ──
@pytest.mark.parametrize("table", sorted(EXPECTED_COLUMNS.keys()))
def test_SC3_columns_match_contract(schema_db, db_name, table):
    actual = _columns(schema_db, db_name, table)
    expected = EXPECTED_COLUMNS[table]
    missing = set(expected) - set(actual)
    assert not missing, f"{table} 누락 컬럼: {missing}"
    for col, spec in expected.items():
        info = actual[col]
        assert info["DATA_TYPE"] == spec["DATA_TYPE"], (
            f"{table}.{col} DATA_TYPE={info['DATA_TYPE']} 기대={spec['DATA_TYPE']}"
        )
        assert info["IS_NULLABLE"] == spec["IS_NULLABLE"], (
            f"{table}.{col} IS_NULLABLE={info['IS_NULLABLE']} 기대={spec['IS_NULLABLE']}"
        )
        if "COLUMN_DEFAULT" in spec:
            assert info["COLUMN_DEFAULT"] == spec["COLUMN_DEFAULT"], (
                f"{table}.{col} COLUMN_DEFAULT={info['COLUMN_DEFAULT']!r} 기대={spec['COLUMN_DEFAULT']!r}"
            )
        if "CHARACTER_MAXIMUM_LENGTH" in spec:
            assert info["CHARACTER_MAXIMUM_LENGTH"] == spec["CHARACTER_MAXIMUM_LENGTH"]


def test_SC3_all_columns_have_comment(schema_db, db_name):
    """SP-DB-1.7: 전 컬럼 한국어 COMMENT 필수 — 비어있지 않음만 검증."""
    empty = []
    for table in TABLE_CREATE_ORDER:
        cols = _columns(schema_db, db_name, table)
        for name, info in cols.items():
            if not info["COLUMN_COMMENT"]:
                empty.append(f"{table}.{name}")
    assert not empty, f"COMMENT 비어있는 컬럼: {empty}"


def test_SC3_amt_source_cd_contract(schema_db, db_name):
    """AMT_SOURCE_CD(DEC-2 신규) 존재·타입·NOT NULL·DEFAULT 'estimated'·COMMENT."""
    cols = _columns(schema_db, db_name, "TCOMPANY_BENEFIT")
    info = cols["AMT_SOURCE_CD"]
    assert info["DATA_TYPE"] == "varchar"
    assert info["CHARACTER_MAXIMUM_LENGTH"] == 10
    assert info["IS_NULLABLE"] == "NO"
    assert info["COLUMN_DEFAULT"] == "estimated"
    assert info["COLUMN_COMMENT"]


def test_SC3_verified_by_id_absent(schema_db, db_name):
    """SP-DB-12: VERIFIED_BY_ID(FK→TMEMBER) 컬럼 부재."""
    cols = _columns(schema_db, db_name, "TCOMPANY_BENEFIT")
    assert "VERIFIED_BY_ID" not in cols


# ── SC-4: 감사 4종 컬럼 ──
# TCOMPARE_LOG 면제: 익명 로그 설계(INV-1 개정 2026-07-14) — 사용자 식별 감사 컬럼(INS_ID·MOD_ID)을
# 두지 않고 append-only 라 MOD_DTM 도 없다. 익명 계약은 아래 SC-4b 가 적극 검증한다.
AUDIT_EXEMPT_TABLES = {"TCOMPARE_LOG"}


@pytest.mark.parametrize("table", [t for t in TABLE_CREATE_ORDER if t not in AUDIT_EXEMPT_TABLES])
def test_SC4_audit_columns_present(schema_db, db_name, table):
    cols = set(_columns(schema_db, db_name, table))
    missing = AUDIT_COLUMNS - cols
    assert not missing, f"{table} 감사 컬럼 누락: {missing}"


def test_SC4b_compare_log_anonymity_contract(schema_db, db_name):
    """TCOMPARE_LOG 익명 계약(INV-1·FR-07 예외 한정): 쌍+시각 외 컬럼이 늘어나면 실패.

    사용자 식별자·IP·세션·입력값 컬럼 추가를 스키마 수준에서 차단하는 가드.
    """
    cols = set(_columns(schema_db, db_name, "TCOMPARE_LOG"))
    assert cols == {"CMP_LOG_ID", "A_COMP_ID", "B_COMP_ID", "INS_DTM"}, (
        f"TCOMPARE_LOG 컬럼이 익명 계약과 다름: {sorted(cols)}"
    )


# ── SC-5: 문자셋/엔진 ──
@pytest.mark.parametrize("table", TABLE_CREATE_ORDER)
def test_SC5_engine_and_collation(schema_db, db_name, table):
    with schema_db.cursor() as cur:
        cur.execute(
            """
            SELECT ENGINE, TABLE_COLLATION FROM information_schema.TABLES
             WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s
            """,
            (db_name, table),
        )
        engine, collation = cur.fetchone()
    assert engine == "InnoDB"
    assert collation.startswith("utf8mb4")


# ── SC-6: FK→TMEMBER/프로파일러 부재 ──
def test_SC6_no_fk_to_removed_tables(schema_db, db_name):
    with schema_db.cursor() as cur:
        cur.execute(
            """
            SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA=%s AND REFERENCED_TABLE_NAME IN %s
            """,
            (db_name, tuple(REMOVED_TABLES)),
        )
        count = cur.fetchone()[0]
    assert count == 0
