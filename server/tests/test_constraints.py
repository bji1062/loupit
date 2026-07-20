"""SP-DB-16.2 제약 검증 테스트 (CN-1~CN-10).

근거: SPEC/02 SP-DB-16.2 · TASK/02 T-02.2.1~T-02.2.5.
`clean_tx` 픽스처(schema_db 위) — 테스트 중 삽입/삭제는 커밋하지 않고
테스트 종료 후 롤백해 후속 테스트에 영향이 없도록 격리한다.
"""

from __future__ import annotations

import pymysql
import pytest


def _insert_type(conn, cd="large", nm="대기업"):
    # 성장률·성장문구·안정성 3컬럼은 브랜드 축 제거(2026-07-20 마이그레이션)로 드랍됐다.
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES (%s, %s)",
            (cd, nm),
        )
        return cur.lastrowid


def _insert_company(conn, comp_tp_id, eng="samsung_elec", nm="삼성전자"):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID)
            VALUES (%s, %s, %s)
            """,
            (eng, nm, comp_tp_id),
        )
        return cur.lastrowid


def _insert_benefit(conn, comp_id, cd="meal", nm="식대", ctgr="compensation", amt=200):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO TCOMPANY_BENEFIT (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_CTGR_CD, BENEFIT_AMT)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (comp_id, cd, nm, ctgr, amt),
        )
        return cur.lastrowid


def _insert_alias(conn, comp_id, alias_nm="삼성"):
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM) VALUES (%s, %s)",
            (comp_id, alias_nm),
        )
        return cur.lastrowid


# ── CN-1: UNIQUE COMP_TP_CD ──
def test_CN1_unique_comp_tp_cd(clean_tx):
    _insert_type(clean_tx, cd="large")
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_type(clean_tx, cd="large", nm="대기업2")


# ── CN-2: UNIQUE COMP_ENG_NM / COMP_NM ──
def test_CN2_unique_comp_eng_nm(clean_tx):
    tp_id = _insert_type(clean_tx)
    _insert_company(clean_tx, tp_id, eng="samsung_elec", nm="삼성전자")
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_company(clean_tx, tp_id, eng="samsung_elec", nm="다른이름")


def test_CN2_unique_comp_nm(clean_tx):
    tp_id = _insert_type(clean_tx)
    _insert_company(clean_tx, tp_id, eng="samsung_elec", nm="삼성전자")
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_company(clean_tx, tp_id, eng="다른영문", nm="삼성전자")


# ── CN-3: UNIQUE uq_comp_alias (동일회사 중복 금지, 타사 동일 별칭은 허용) ──
def test_CN3_unique_alias_within_company(clean_tx):
    tp_id = _insert_type(clean_tx)
    comp_id = _insert_company(clean_tx, tp_id)
    _insert_alias(clean_tx, comp_id, "삼성")
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_alias(clean_tx, comp_id, "삼성")


def test_CN3_same_alias_different_company_allowed(clean_tx):
    tp_id = _insert_type(clean_tx)
    comp1 = _insert_company(clean_tx, tp_id, eng="comp_a", nm="A회사")
    comp2 = _insert_company(clean_tx, tp_id, eng="comp_b", nm="B회사")
    _insert_alias(clean_tx, comp1, "공통별칭")
    _insert_alias(clean_tx, comp2, "공통별칭")  # 예외 없이 성공해야 함


# ── CN-4: UNIQUE uq_comp_benefit (중복 삽입 실패, ON DUPLICATE KEY UPDATE는 성공) ──
def test_CN4_unique_comp_benefit(clean_tx):
    tp_id = _insert_type(clean_tx)
    comp_id = _insert_company(clean_tx, tp_id)
    _insert_benefit(clean_tx, comp_id, cd="meal")
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_benefit(clean_tx, comp_id, cd="meal")


def test_CN4_on_duplicate_key_update_succeeds(clean_tx):
    tp_id = _insert_type(clean_tx)
    comp_id = _insert_company(clean_tx, tp_id)
    _insert_benefit(clean_tx, comp_id, cd="meal", amt=200)
    with clean_tx.cursor() as cur:
        cur.execute(
            """
            INSERT INTO TCOMPANY_BENEFIT (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_CTGR_CD, BENEFIT_AMT)
            VALUES (%s, 'meal', '식대', 'compensation', 300)
            ON DUPLICATE KEY UPDATE BENEFIT_AMT = VALUES(BENEFIT_AMT)
            """,
            (comp_id,),
        )
        cur.execute(
            "SELECT BENEFIT_AMT FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD='meal'",
            (comp_id,),
        )
        assert cur.fetchone()[0] == 300


# ── CN-5: FK 회사→유형 ──
def test_CN5_fk_company_to_type(clean_tx):
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_company(clean_tx, comp_tp_id=999999)


# ── CN-6: FK 별칭/복지→회사 ──
def test_CN6_fk_alias_to_company(clean_tx):
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_alias(clean_tx, comp_id=999999)


def test_CN6_fk_benefit_to_company(clean_tx):
    with pytest.raises(pymysql.err.IntegrityError):
        _insert_benefit(clean_tx, comp_id=999999)


# ── CN-7: ON DELETE CASCADE ──
def test_CN7_cascade_delete_company(clean_tx):
    tp_id = _insert_type(clean_tx)
    comp_id = _insert_company(clean_tx, tp_id)
    _insert_alias(clean_tx, comp_id)
    _insert_benefit(clean_tx, comp_id)
    with clean_tx.cursor() as cur:
        cur.execute("DELETE FROM TCOMPANY WHERE COMP_ID=%s", (comp_id,))
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_ALIAS WHERE COMP_ID=%s", (comp_id,))
        assert cur.fetchone()[0] == 0
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s", (comp_id,))
        assert cur.fetchone()[0] == 0


# ── CN-8: FK RESTRICT 유형(자식 존재 시 삭제 불가) ──
def test_CN8_restrict_delete_referenced_type(clean_tx):
    tp_id = _insert_type(clean_tx)
    _insert_company(clean_tx, tp_id)
    with pytest.raises(pymysql.err.IntegrityError):
        with clean_tx.cursor() as cur:
            cur.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_ID=%s", (tp_id,))


# ── CN-9: FULLTEXT idx_comp_nm 존재 ──
def test_CN9_fulltext_index_exists(schema_db, db_name):
    with schema_db.cursor() as cur:
        cur.execute(
            """
            SELECT INDEX_TYPE FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA=%s AND TABLE_NAME='TCOMPANY' AND INDEX_NAME='idx_comp_nm'
            """,
            (db_name,),
        )
        rows = cur.fetchall()
    assert rows, "idx_comp_nm 인덱스가 존재하지 않음"
    assert rows[0][0] == "FULLTEXT"


# ── CN-10: 보조 인덱스 존재 ──
@pytest.mark.parametrize(
    "table,index_name",
    [
        ("TCOMPANY_ALIAS", "idx_alias_nm"),
        ("TCOMPANY_BENEFIT", "idx_benefit_comp"),
        ("TBENEFIT_PRESET", "idx_preset_type"),
    ],
)
def test_CN10_secondary_indexes_exist(schema_db, db_name, table, index_name):
    with schema_db.cursor() as cur:
        cur.execute(
            """
            SELECT COUNT(*) FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s AND INDEX_NAME=%s
            """,
            (db_name, table, index_name),
        )
        count = cur.fetchone()[0]
    assert count > 0, f"{table}.{index_name} 인덱스가 존재하지 않음"
