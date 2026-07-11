"""SP-SEED-11.1 카운트 테스트 (SD-1~SD-7).

근거: SPEC/03 SP-SEED-11.1 · TASK/03 T-03.2.1·T-03.2.2·T-03.3.4·T-03.3.5·T-03.4.1.
`seeded_db`(conftest, load.main(fresh=True))가 스키마→시드→백필 전체를 적용한 뒤
검증한다.
"""

from __future__ import annotations

import pytest

TYPE_CODES_5_NONFREELANCE = {"large", "mid", "public", "startup", "foreign"}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


# ── SD-1: 기업유형 6종 ──
def test_SD1_company_type_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_TYPE") == 6


# ── SD-2: 프리셋 28행 ──
def test_SD2_benefit_preset_total_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_PRESET") == 28


# ── SD-3: 회사 95 (Tier-0) ──
def test_SD3_company_count_is_95(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY") == 95


# ── SD-4: 복지 총행 1317(=1330-모비스13행), 하한 1200 방어 ──
def test_SD4_benefit_total_row_count(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT")
    assert count == 1317, f"복지 총행 불일치: {count} (기대 1317 = 1330-모비스13)"
    assert count >= 1200


# ── SD-5: 회사별 복지 ≥1 (복지 0개 회사 수 = 0) ──
def test_SD5_every_company_has_benefit(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_BENEFIT b ON b.COMP_ID = c.COMP_ID
        WHERE b.BENEFIT_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-6: 회사별 별칭 ≥1 (별칭 0개 회사 수 = 0) ──
def test_SD6_every_company_has_alias(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
        WHERE a.ALIAS_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-7: 프리셋 유형 커버 (freelance 제외 5유형 ≥1행, freelance=0행) ──
@pytest.mark.parametrize("type_cd", sorted(TYPE_CODES_5_NONFREELANCE))
def test_SD7_preset_covers_non_freelance_types(seeded_db, type_cd):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = %s
        """,
        (type_cd,),
    )
    assert count >= 1, f"{type_cd} 유형 프리셋 0행"


def test_SD7_freelance_has_zero_presets(seeded_db):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = 'freelance'
        """,
    )
    assert count == 0
