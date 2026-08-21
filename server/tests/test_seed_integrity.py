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


# ── SI-1: CJ 예외 — `eng='cj'` 는 CJ올리브네트웍스다(오라벨 금지) ──
def test_SI1_cj_exception_registered_name(seeded_db):
    """`CJ.sql`(eng='cj') 파일명은 "CJ"지만 안의 데이터는 **CJ올리브네트웍스**(비상장 계열사) 것이다.
    2026-07-09 결정(OI-1b)의 본뜻은 **"그 데이터를 CJ그룹/CJ ENM 으로 오라벨하지 마라"** 다.

    ⚠ 초판은 `COMP_NM='CJ ENM'` 부재만 검사했는데, 그 문구는 **의도보다 넓었다** — 자기 데이터를
    가진 CJ ENM 을 등록하는 것까지 금지했고, 2026-07-30 실제로 그 등록을 막았다(사용자 요청 #1).
    그래서 **eng 키를 축으로** 다시 쓴다: 지켜야 할 것은 "eng='cj' 행의 이름"이지 "CJ ENM 의 부재"가
    아니다. 함정 ㉗ 계열 — 가드의 문구가 의도와 어긋나면 옳은 변경을 막는다.
    """
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_ENG_NM='cj'") == 1
    cj_nm = _scalar(seeded_db, "SELECT COMP_NM FROM TCOMPANY WHERE COMP_ENG_NM='cj'")
    assert cj_nm == "CJ올리브네트웍스", f"eng='cj' 는 CJ올리브네트웍스여야 한다(현재 {cj_nm!r})"
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ그룹'") == 0
    # CJ ENM 은 2026-07-30 부터 **부문별**로 등록된다(엔터/커머스 — 재충전 제도·성과 포상·
    # 가족친화인증·채용 채널이 실제로 분리돼 있다). 부문 없는 단일 'CJ ENM' 은 여전히 금지 —
    # 그러면 엔터부문 지원자에게 커머스부문 정보를 주게 된다.
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM='CJ ENM'") == 0, \
        "부문 구분 없는 'CJ ENM' 단일 등록은 금지 — 엔터테인먼트/커머스로 나눈다"
    for div in ("CJ ENM 엔터테인먼트부문", "CJ ENM 커머스부문"):
        assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_NM=%s", (div,)) == 1, \
            f"{div} 미등록"


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
    assert count == 102  # 95 + CJ 계열 7개사(2026-07-30)
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


def test_SI_B2_monthly_amount_annualized(seeded_db):
    """B-2 회귀(2026-07-12): note가 '월 N만원'인데 BENEFIT_AMT가 월값으로 저장된
    월→연 환산 누락 방지. 95개 시드 SQL 전수 스윕+적대검증으로 확정된 유일 실버그 —
    카카오뱅크 영유아지원금 '월 10만원' → 연 120(만원). (크래프톤·파크는 M-5에서 처리,
    LS 체력단련비 30은 청구주기 서술일 뿐 이미 연값이라 대상 아님.)"""
    kakao = _scalar(
        seeded_db,
        "SELECT b.BENEFIT_AMT FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON b.COMP_ID=c.COMP_ID "
        "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s",
        ("kakao_bank", "child_edu"),
    )
    assert kakao == 120, f"카카오뱅크 영유아지원금 월10만원→연환산 120(만원) 기대(현재 {kakao})"


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


# ── SI-R1: 사명 변경 2건(2026-08-21) — 표시명은 새 이름, **옛 이름은 별칭에 보존** ──
# DART 개황 API 가 정본: LIG넥스원 → 엘아이지디펜스앤에어로스페이스(주)(2026-04-15 갱신),
# 엔씨소프트 → (주)엔씨(2026-05-04 갱신). 표시는 병기형으로 간다.
#
# 🚨 이 테스트의 요점은 새 이름이 아니라 **옛 이름의 생존**이다. 별칭은 사이트 내 검색과
# JSON-LD `alternateName`(검색엔진이 동일 대상임을 아는 근거) 양쪽에 쓰이는데,
# `company_meta.build_company_meta()` 는 200-seed 를 **COMP_NM 으로 조인**해 별칭을 승계한다
# (`by_name.get(comp_nm)`). 즉 표시명을 바꾸는 순간 그 조인이 깨져 fallback 으로 떨어지고
# **옛 별칭이 통째로 사라진다** — 유입이 최대 병목인 지금 그건 조용한 손실이다.
# 엔씨소프트는 NCSOFT_ALIASES override 가 막아주지만 LIG 는 override 가 없었다.
RENAMED = {
    "ncsoft": {
        "display": "엔씨소프트(NC)",
        "must_keep": ["엔씨소프트", "NC"],       # 압도적 다수가 옛 이름으로 검색한다
    },
    "lig_nex1": {
        "display": "LIG디펜스앤에어로스페이스(구 LIG넥스원)",
        "must_keep": ["LIG넥스원", "LIG디펜스앤에어로스페이스"],
    },
}


def test_SI_R1_renamed_companies_show_new_name(seeded_db):
    """표시명(COMP_NM)이 새 병기형이다 — title·h1·meta·JSON-LD name 에 그대로 나간다."""
    for eng, spec in RENAMED.items():
        nm = _scalar(seeded_db, "SELECT COMP_NM FROM TCOMPANY WHERE COMP_ENG_NM=%s", (eng,))
        assert nm == spec["display"], f"{eng} 표시명이 {nm!r} (기대 {spec['display']!r})"


def test_SI_R1_renamed_companies_keep_old_aliases(seeded_db):
    """🚨 옛 이름이 별칭에 살아 있다 — 사명 변경으로 검색 자산을 잃지 않는다."""
    for eng, spec in RENAMED.items():
        aliases = {
            r[0] for r in _rows(
                seeded_db,
                "SELECT a.ALIAS_NM FROM TCOMPANY_ALIAS a "
                "JOIN TCOMPANY c ON c.COMP_ID=a.COMP_ID WHERE c.COMP_ENG_NM=%s",
                (eng,),
            )
        }
        missing = [x for x in spec["must_keep"] if x not in aliases]
        assert not missing, (
            f"{eng} 별칭에서 사라진 이름: {missing} — 현재 {sorted(aliases)}. "
            "COMP_NM 을 바꾸면 200-seed 조인(by_name.get)이 깨져 별칭이 fallback 으로 "
            "떨어진다. company_meta.py 에 override 를 추가하라(ncsoft 패턴)"
        )


def test_SI_R1_url_slug_unchanged(seeded_db):
    """URL slug 은 그대로다 — 색인된 주소와 외부 링크 자산은 표시명과 무관하게 보존된다."""
    for eng in RENAMED:
        assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY WHERE COMP_ENG_NM=%s", (eng,)) == 1, \
            f"slug {eng} 이 사라졌다 — /company/{eng} 색인이 통째로 깨진다"
