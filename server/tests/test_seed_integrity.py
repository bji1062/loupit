"""SP-SEED-11.2 무결성·정규화 테스트 (SI-1~SI-8).

근거: SPEC/03 SP-SEED-11.2 · TASK/03 T-03.3.2·T-03.3.3·T-03.3.4·T-03.4.1~4.3.
"""

from __future__ import annotations

import json

CATEGORIES_9 = {
    "compensation", "flexibility", "work_env", "time_off",
    "health", "family", "growth", "leisure", "perks",
}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def _rows(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


# ── SI-1: CJ 예외 — CJ올리브네트웍스 1건, CJ그룹/CJ ENM 부재 ──
def test_SI1_cj_exception_registered_name(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ올리브네트웍스'") == 1
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ그룹'") == 0
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ ENM'") == 0


# ── SI-2: 엔씨소프트 예외 — 존재 + 별칭 ≥1 ──
def test_SI2_ncsoft_exception_registered(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_ENG_NM='ncsoft'") == 1
    alias_count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY_ALIAS a
        JOIN TCOMPANY c ON c.COMP_ID = a.COMP_ID
        WHERE c.COMP_ENG_NM='ncsoft'
        """,
    )
    assert alias_count >= 1


# ── SI-3: 모비스 중복 제거 — mobis 부재, hyundai_mobis 존재 + 별칭에 '모비스' 포함 ──
def test_SI3_mobis_duplicate_removed(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_ENG_NM='mobis'") == 0
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_ENG_NM='hyundai_mobis'") == 1
    alias_names = [
        r[0]
        for r in _rows(
            seeded_db,
            """
            SELECT ALIAS_NM FROM TCOMPANY_ALIAS a
            JOIN TCOMPANY c ON c.COMP_ID = a.COMP_ID
            WHERE c.COMP_ENG_NM='hyundai_mobis'
            """,
        )
    ]
    assert "모비스" in alias_names


# ── SI-4: eng↔복지 정합 — 고아 0, eng-상이 14건도 복지 정상 연결 ──
def test_SI4_no_orphan_benefit_rows(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT b
        LEFT JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
        WHERE c.COMP_ID IS NULL
        """,
    )
    assert bad == 0


def test_SI4_eng_mismatch_14_companies_have_benefits(seeded_db):
    """SP-SEED-2.2 eng-상이 14건 표본(LG·LS 등) — 복지 정상 연결 확인."""
    sample_engs = ["lg", "ls", "wgames", "doosan_enerbility", "lino", "bh", "samsung_ct"]
    for eng in sample_engs:
        count = _scalar(
            seeded_db,
            """
            SELECT COUNT(*) FROM TCOMPANY_BENEFIT b
            JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
            WHERE c.COMP_ENG_NM=%s
            """,
            (eng,),
        )
        assert count >= 1, f"eng={eng} 복지 미연결"


# ── SI-5: 카테고리 9종 (benefit·preset 양쪽) ──
def test_SI5_benefit_category_domain(seeded_db):
    fmt = ",".join(["%s"] * len(CATEGORIES_9))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BENEFIT_CTGR_CD NOT IN ({fmt})",
        tuple(CATEGORIES_9),
    )
    assert bad == 0


def test_SI5_preset_category_domain(seeded_db):
    fmt = ",".join(["%s"] * len(CATEGORIES_9))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TBENEFIT_PRESET WHERE BENEFIT_CTGR_CD NOT IN ({fmt})",
        tuple(CATEGORIES_9),
    )
    assert bad == 0


# ── SI-6: WORK_STYLE_VAL 키 부분집합 + 불리언 3키 타입 ──
def test_SI6_work_style_keys_and_types(seeded_db):
    allowed_keys = {"remote", "flex", "unlimitedPTO", "refreshLeave", "overtime"}
    rows = _rows(seeded_db, "SELECT WORK_STYLE_VAL FROM TCOMPANY WHERE WORK_STYLE_VAL IS NOT NULL")
    assert rows, "WORK_STYLE_VAL 시드 결과 없음"
    for (raw,) in rows:
        val = json.loads(raw) if isinstance(raw, str) else raw
        assert set(val.keys()) <= allowed_keys, f"허용 외 키: {set(val.keys()) - allowed_keys}"
        for bkey in ("remote", "flex", "unlimitedPTO"):
            if bkey in val:
                assert isinstance(val[bkey], bool), f"{bkey} 불리언 아님: {val[bkey]!r}"


# ── SI-7: 별칭 UNIQUE — 회사 내 중복 별칭 0 ──
def test_SI7_no_duplicate_alias_per_company(seeded_db):
    dupes = _rows(
        seeded_db,
        """
        SELECT COMP_ID, ALIAS_NM, COUNT(*) c FROM TCOMPANY_ALIAS
        GROUP BY COMP_ID, ALIAS_NM HAVING c > 1
        """,
    )
    assert dupes == ()


# ── SI-8: 200-seed 미등록 — 회사 수 = 95 (≠ 200) ──
def test_SI8_company_count_not_200(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY")
    assert count == 95
    assert count != 200


# ── SI-M5: note 명시 금액 ↔ BENEFIT_AMT 정합성 회귀(2026-07-12 검증 M-5) ──


def test_SI_M5_stated_amount_matches_note(seeded_db):
    """M-5 회귀: note에 명시된 만원 금액과 BENEFIT_AMT(연간 환산 만원) 정합성 —
    화면 노출값과 calc 합산값 불일치 방지. 파크시스템스 출산축하금 100, 크래프톤 운동비 연 120."""
    park = _scalar(
        seeded_db,
        "SELECT b.BENEFIT_AMT FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON b.COMP_ID=c.COMP_ID "
        "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s",
        ("park_systems", "fertility_support"),
    )
    assert park == 100, f"파크시스템스 출산축하금 100(만원) 기대(현재 {park})"
    kraft = _scalar(
        seeded_db,
        "SELECT b.BENEFIT_AMT FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON b.COMP_ID=c.COMP_ID "
        "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s",
        ("krafton", "fitness"),
    )
    assert kraft == 120, f"크래프톤 운동비 연환산 120(만원) 기대(현재 {kraft})"


# ── SI-M4: 앵커 추정값 stated 위장 방지 회귀(2026-07-12 검증 M-4) ──


def test_SI_M4_no_stated_anchor_across_companies(seeded_db):
    """M-4 회귀: 무관 회사 간 동일 (복지코드·금액)이 3개사 이상 반복되면 회사가 개별
    명시한 값이 아니라 표준 앵커/환산일 가능성이 높다 → stated(±5%)로 남기지 않고
    estimated(±20%)로 강등해야 한다(DEC-2 정직성, 근거없는 정밀도 방지)."""
    anchors = _rows(
        seeded_db,
        """
        SELECT BENEFIT_CD, BENEFIT_AMT, COUNT(DISTINCT COMP_ID) AS c
          FROM TCOMPANY_BENEFIT
         WHERE AMT_SOURCE_CD='stated' AND BENEFIT_AMT IS NOT NULL
         GROUP BY BENEFIT_CD, BENEFIT_AMT
        HAVING c >= 3
        """,
    )
    assert anchors == (), f"stated로 남은 앵커(3개사+ 동일값): {anchors}"
