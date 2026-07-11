"""SP-SEED-11.3 배지·백필 테스트 (SB-1~SB-10).

근거: SPEC/03 SP-SEED-11.3 · TASK/03 T-03.5.1~T-03.5.5.
DG-1 확정(TASK/00 §4): 만료 TTL = 균일 18개월(카테고리 차등 폐기).
DG-2 확정: amt_source 판별 규칙(추정/환산 표기 또는 note 없음→estimated 등).
"""

from __future__ import annotations

BADGE_SRC_CODES_5 = {"scrape_official", "scrape_fallback", "ai_parse", "manual", "user_report"}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def _rows(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


# ── SB-1: official 승격 (Tier-0) — 백필 후 등록 복지 중 est=0 ──
def test_SB1_all_promoted_to_official(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
    assert count == 0


# ── SB-2: amt_source 값집합 ──
def test_SB2_amt_source_domain(seeded_db):
    bad = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD NOT IN ('stated','estimated','none')",
    )
    assert bad == 0


# ── SB-3: 정성 불변식 — QUAL_YN=TRUE ⇒ BENEFIT_AMT NULL & AMT_SOURCE_CD='none' ──
def test_SB3_qual_invariant(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT
         WHERE QUAL_YN = TRUE AND (BENEFIT_AMT IS NOT NULL OR AMT_SOURCE_CD <> 'none')
        """,
    )
    assert bad == 0


# ── SB-4: none 불변식 — AMT_SOURCE_CD='none' ⇒ BENEFIT_AMT NULL ──
def test_SB4_none_invariant(seeded_db):
    bad = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='none' AND BENEFIT_AMT IS NOT NULL",
    )
    assert bad == 0


# ── SB-5: estimated 행 ≥1 (앵커 추정 다수 실재) ──
def test_SB5_estimated_rows_exist(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='estimated'")
    assert count >= 1


# ── SB-6: DEC-2 디커플링 (Tier-0) — official × estimated 공존 ≥1 ──
def test_SB6_dec2_decoupling_exists(seeded_db):
    count = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='official' AND AMT_SOURCE_CD='estimated'",
    )
    assert count >= 1


# ── SB-7: amt_source 규칙 표본 (삼성전자 estimated · CJ stated) ──
def test_SB7_amt_source_rule_samples(seeded_db):
    samsung_rows = dict(
        _rows(
            seeded_db,
            """
            SELECT b.BENEFIT_CD, b.AMT_SOURCE_CD FROM TCOMPANY_BENEFIT b
            JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
            WHERE c.COMP_ENG_NM='samsung_elec' AND b.BENEFIT_CD IN ('health_check','meal')
            """,
        )
    )
    assert samsung_rows.get("health_check") == "estimated"  # note '(추정)'
    assert samsung_rows.get("meal") == "estimated"  # note '환산' 포함

    cj_amt_source = _scalar(
        seeded_db,
        """
        SELECT b.AMT_SOURCE_CD FROM TCOMPANY_BENEFIT b
        JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
        WHERE c.COMP_ENG_NM='cj' AND b.BENEFIT_CD='welfare_point'
        """,
    )
    assert cj_amt_source == "stated"  # 명시 금액, 추정표기 없음


# ── SB-8: VERIFIED_DTM 전량 존재 ──
def test_SB8_verified_dtm_never_null(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE VERIFIED_DTM IS NULL")
    assert count == 0


# ── SB-9: 만료 TTL — 균일 18개월(DG-1), EXPIRES > VERIFIED 전량 ──
def test_SB9_expires_uniform_18_months(seeded_db):
    mismatched = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT
         WHERE EXPIRES_DTM <> DATE_ADD(VERIFIED_DTM, INTERVAL 18 MONTH)
        """,
    )
    assert mismatched == 0, "DG-1 균일 18개월 TTL 위반 행 존재"


def test_SB9_expires_after_verified(seeded_db):
    bad = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE EXPIRES_DTM IS NOT NULL AND EXPIRES_DTM <= VERIFIED_DTM",
    )
    assert bad == 0


# ── SB-10: 출처 유형 — 실 URL 5건=scrape_official+URL, 그 외 ai_parse ──
def test_SB10_badge_src_cd_domain(seeded_db):
    fmt = ",".join(["%s"] * len(BADGE_SRC_CODES_5))
    bad = _scalar(
        seeded_db,
        f"""
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT
         WHERE BADGE_SRC_CD IS NOT NULL AND BADGE_SRC_CD NOT IN ({fmt})
        """,
        tuple(BADGE_SRC_CODES_5),
    )
    assert bad == 0


def test_SB10_scrape_official_companies_have_url(seeded_db):
    """실 http URL 헤더를 가진 5개 회사(KT·삼성전자·LG전자·코웨이·현대모비스)."""
    real_url_engs = {"kt", "samsung_elec", "lg_elec", "coway", "hyundai_mobis"}
    rows = _rows(
        seeded_db,
        """
        SELECT DISTINCT c.COMP_ENG_NM FROM TCOMPANY_BENEFIT b
        JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
        WHERE b.BADGE_SRC_CD='scrape_official'
        """,
    )
    scrape_official_engs = {r[0] for r in rows}
    assert len(scrape_official_engs) == 5
    assert scrape_official_engs & real_url_engs, "실 URL 회사 집합과 교집합 없음"

    url_null_count = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_SRC_CD='scrape_official' AND BADGE_SRC_URL_CTNT IS NULL",
    )
    assert url_null_count == 0


def test_SB10_ai_parse_has_no_url(seeded_db):
    count = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_SRC_CD='ai_parse' AND BADGE_SRC_URL_CTNT IS NOT NULL",
    )
    assert count == 0
