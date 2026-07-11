"""SP-DB-16.3 데이터 계약·불변식 테스트 (DC-1~DC-17).

근거: SPEC/02 SP-DB-16.3 · TASK/02 T-02.4.1~T-02.4.3 · T-02.5.1~T-02.5.6.

이번 스코프(SP-DB, SP-SEED 착수 전)의 원칙: `db/seed/reference.sql`·
`db/seed/benefit/sql/*.sql`이 아직 없어(seeded_db는 schema+migration만
적용된 빈 테이블) **실제 시드 행 존재를 전제하는 케이스**는 지금 실행하면
빈 테이블에 대해 항상 실패(정확 카운트/존재 단언)하거나, 반대로 항상
공허하게 참(vacuously true, 위반행 0)이 되어버려 의미가 없다.

- 위반행 카운트=0 스타일의 **도메인/불변식 린트**(DC-5~11, DC-14, DC-17)는
  빈 테이블에서도 스키마·제약이 올바르면 legitimate하게 green이며, 시드
  적재 후에도 동일 쿼리가 계속 유효하다 — 그대로 구현·실행한다.
- **정확 카운트/존재 단언** 스타일(DC-1, DC-2, DC-12, DC-13, DC-15, DC-16)은
  실제 시드·백필 데이터가 있어야만 의미가 성립하므로, SP-SEED(다음 단계)
  완료 전까지 `@pytest.mark.skip`로 명시 보류한다(가짜 green 금지).
  이 중 DC-2·DC-12·DC-13은 Tier-0 게이트(T-02.5.2·T-02.4.2·T-02.4.1)다.
"""

from __future__ import annotations

import pytest

CATEGORIES_9 = {
    "compensation", "flexibility", "work_env", "time_off",
    "health", "family", "growth", "leisure", "perks",
}
BADGE_CODES = {"official", "est"}
AMT_SOURCE_CODES = {"stated", "estimated", "none"}
BADGE_SRC_CODES = {"scrape_official", "scrape_fallback", "ai_parse", "manual", "user_report"}
TYPE_CODES_6 = {"large", "startup", "mid", "foreign", "public", "freelance"}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


# ── DC-1: 유형 6종 (SP-SEED reference.sql 필요) ──
@pytest.mark.skip(reason="SP-SEED reference.sql(기업유형 6종 시드) 적용 후 해제")
def test_DC1_company_type_count_and_domain(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_TYPE") == 6
    fmt = ",".join(["%s"] * len(TYPE_CODES_6))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TCOMPANY_TYPE WHERE COMP_TP_CD NOT IN ({fmt})",
        tuple(TYPE_CODES_6),
    )
    assert bad == 0


# ── DC-2: 회사 ~96 (Tier-0, T-02.5.2) ──
@pytest.mark.skip(reason="SP-SEED 96개 복지 SQL 재이식 후 해제 — Tier-0(T-02.5.2)")
def test_DC2_company_count_approx_96(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY")
    assert count >= 90, f"회사 등록 수 하한 미달: {count} (기대 >=90, ~96)"


# ── DC-3: 회사별 복지 ≥1 (빈 테이블에서는 공허하게 참) ──
def test_DC3_every_company_has_benefit(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_BENEFIT b ON b.COMP_ID = c.COMP_ID
        WHERE b.BENEFIT_ID IS NULL
        """,
    )
    assert bad == 0


# ── DC-4: 회사별 별칭 ≥1 (빈 테이블에서는 공허하게 참) ──
def test_DC4_every_company_has_alias(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
        WHERE a.ALIAS_ID IS NULL
        """,
    )
    assert bad == 0


# ── DC-5: 카테고리 9종 (benefit·preset 양쪽) ──
def test_DC5_benefit_category_domain(seeded_db):
    fmt = ",".join(["%s"] * len(CATEGORIES_9))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BENEFIT_CTGR_CD NOT IN ({fmt})",
        tuple(CATEGORIES_9),
    )
    assert bad == 0


def test_DC5_preset_category_domain(seeded_db):
    fmt = ",".join(["%s"] * len(CATEGORIES_9))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TBENEFIT_PRESET WHERE BENEFIT_CTGR_CD NOT IN ({fmt})",
        tuple(CATEGORIES_9),
    )
    assert bad == 0


# ── DC-6: 배지 집합 ──
def test_DC6_badge_domain(seeded_db):
    fmt = ",".join(["%s"] * len(BADGE_CODES))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD NOT IN ({fmt})",
        tuple(BADGE_CODES),
    )
    assert bad == 0


# ── DC-7: 금액출처 집합 ──
def test_DC7_amt_source_domain(seeded_db):
    fmt = ",".join(["%s"] * len(AMT_SOURCE_CODES))
    bad = _scalar(
        seeded_db,
        f"SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD NOT IN ({fmt})",
        tuple(AMT_SOURCE_CODES),
    )
    assert bad == 0


# ── DC-8: 출처유형 집합 (NULL 허용) ──
def test_DC8_badge_src_domain(seeded_db):
    fmt = ",".join(["%s"] * len(BADGE_SRC_CODES))
    bad = _scalar(
        seeded_db,
        f"""
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT
         WHERE BADGE_SRC_CD IS NOT NULL AND BADGE_SRC_CD NOT IN ({fmt})
        """,
        tuple(BADGE_SRC_CODES),
    )
    assert bad == 0


# ── DC-9: 정성 불변식 ──
def test_DC9_qual_invariant(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY_BENEFIT
         WHERE QUAL_YN = TRUE AND (BENEFIT_AMT IS NOT NULL OR AMT_SOURCE_CD <> 'none')
        """,
    )
    assert bad == 0


# ── DC-10: none 불변식 ──
def test_DC10_none_invariant(seeded_db):
    bad = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='none' AND BENEFIT_AMT IS NOT NULL",
    )
    assert bad == 0


# ── DC-11: 음수 금지 ──
def test_DC11_no_negative_amount(seeded_db):
    bad = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BENEFIT_AMT < 0")
    assert bad == 0


# ── DC-12: DEC-2 디커플링 존재 (Tier-0, T-02.4.2) ──
@pytest.mark.skip(reason="SP-SEED 시드·백필(20260710_backfill_dec2.sql) 실데이터 적용 후 해제 — Tier-0(T-02.4.2)")
def test_DC12_dec2_decoupling_exists(seeded_db):
    count = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='official' AND AMT_SOURCE_CD='estimated'",
    )
    assert count >= 1


# ── DC-13: 백필 official 전량 (Tier-0, T-02.4.1) ──
@pytest.mark.skip(reason="SP-SEED 시드·백필 실데이터 적용 후 해제 — Tier-0(T-02.4.1)")
def test_DC13_backfill_promotes_all_to_official(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
    assert count == 0


# ── DC-14: 만료 채움 (빈 테이블에서는 공허하게 참, 백필 SQL의 구조 검증) ──
def test_DC14_freshness_backfilled(seeded_db):
    null_verified = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE VERIFIED_DTM IS NULL")
    assert null_verified == 0
    bad_expiry = _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE EXPIRES_DTM IS NOT NULL AND EXPIRES_DTM <= VERIFIED_DTM",
    )
    assert bad_expiry == 0


# ── DC-15: CJ 등록명 (SP-SEED 96개 SQL 재이식 필요) ──
@pytest.mark.skip(reason="SP-SEED 96개 복지 SQL 재이식(CJ 교정 포함) 후 해제")
def test_DC15_cj_registered_name(seeded_db):
    cj_olive = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ올리브네트웍스'")
    assert cj_olive == 1
    cj_enm = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ ENM'")
    assert cj_enm == 0


# ── DC-16: 엔씨소프트 등록 (SP-SEED 회사 메타 보강 필요) ──
@pytest.mark.skip(reason="SP-SEED 회사 메타 보강(엔씨소프트 등록) 후 해제")
def test_DC16_ncsoft_registered(seeded_db):
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM LIKE %s", ("%엔씨소프트%",))
    assert count >= 1


# ── DC-17: 프로파일러 번들 부재 (정적 assert — 데이터 무관) ──
def test_DC17_profiler_bundle_source_absent(schema_db, db_name):
    """SP-DB-14: 프로파일러 소스 테이블 부재 → profiles/questions/job_groups
    번들 키 생성 불가(FR-D10). 정적으로 스키마에 해당 테이블이 없음을 확인."""
    profiler_tables = {
        "TPROFILE", "TPROFILE_JOB_FIT", "TJOB_GROUP", "TJOB",
        "TPROFILER_QUESTION", "TQUESTION_SCENARIO", "TPROFILER_RESULT",
    }
    with schema_db.cursor() as cur:
        cur.execute(
            "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s",
            (db_name,),
        )
        names = {row[0] for row in cur.fetchall()}
    assert not (names & profiler_tables)
