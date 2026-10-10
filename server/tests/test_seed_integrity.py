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


# ── SI-4: eng↔복지 정합 — 고아 0, eng-상이 12건(SP-SEED-2.2 표 전부)도 복지 정상 연결 ──
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


def test_SI4_eng_mismatch_companies_have_benefits(seeded_db):
    """SP-SEED-2.2 eng-상이 12건 전부 — 복지 정상 연결 확인(정식명 조인 경로).

    lg(LG 지주) · ls(LS 지주)는 2026-10-01 등록 해제됐다(공식 복지 원문 없음 · 구본은 LG유플러스 사본 · KLT 데이터) — 표에서 뺐다(14 → 12).
    표본을 고르지 않고 표 전부를 본다 — 등록 해제 때마다 표본만 줄어 검사가 약해지던 것을 막는다(LS 검토 LOW-1)."""
    sample_engs = [
        "wgames", "doosan_enerbility", "lino", "bh", "samsung_ct", "isens",
        "ifamilysc", "ecopro_bm", "eugenetech", "jusung", "hanwha", "hanwha_aerospace",
    ]
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
    allowed_keys = {"remote", "flex", "unlimitedPTO", "refreshLeave", "overtime", "cond"}
    rows = _rows(seeded_db, "SELECT WORK_STYLE_VAL FROM TCOMPANY WHERE WORK_STYLE_VAL IS NOT NULL")
    assert rows, "WORK_STYLE_VAL 시드 결과 없음"
    for (raw,) in rows:
        val = json.loads(raw) if isinstance(raw, str) else raw
        assert set(val.keys()) <= allowed_keys, f"허용 외 키: {set(val.keys()) - allowed_keys}"
        for bkey in ("remote", "flex", "unlimitedPTO"):
            if bkey in val:
                assert isinstance(val[bkey], bool), f"{bkey} 불리언 아님: {val[bkey]!r}"
        # 조건 칩(6c) — cond 는 {remote|flex|refreshLeave: 비지 않은 문자열 목록} · 비면 키를 쓰지 않는다 · 조건 있는 키는 false/null
        cond = val.get("cond")
        if cond is not None:
            assert isinstance(cond, dict) and cond, f"cond 가 비었거나 dict 가 아님: {cond!r}"
            assert set(cond) <= {"remote", "flex", "refreshLeave"}, f"cond 키: {set(cond)}"
            for k, labels in cond.items():
                assert isinstance(labels, list) and labels and all(isinstance(x, str) and x for x in labels), (k, labels)
                assert not val.get(k), f"불변식 k ∈ cond ⇒ !ws[k] 위반: {k}={val.get(k)!r}"


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
    assert count == 160  # 138 + 확장 웨이브 4 12개사(2026-09-20) − LG · LS 지주 · HPSP 등록 해제(2026-10-01 · 2026-10-02) + 확장 웨이브 5 13개사(2026-10-10)
    assert count != 200


# ── SI-M5: note 명시 금액 ↔ BENEFIT_AMT 정합성 회귀(2026-07-12 검증 M-5) ──


def test_SI_M5_stated_amount_matches_note(seeded_db):
    """M-5 회귀: note에 명시된 만원 금액과 BENEFIT_AMT(연간 환산 만원) 정합성 —
    화면 노출값과 calc 합산값 불일치 방지. 컴투스 복지카드 250.
    (크래프톤 운동비 연 120 은 2026-09-28 재수집(R-3)에서 공식 원문에 금액이 없어 비웠다 — 검사에서 뺀다.
    파크시스템스는 2026-10-01 R-3 묶음 3 에서 공식 원문에 금액이 없어 비웠다.)"""
    com2us = _scalar(
        seeded_db,
        "SELECT b.BENEFIT_AMT FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON b.COMP_ID=c.COMP_ID "
        "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s",
        ("com2us", "welfare_point"),
    )
    assert com2us == 250, f"컴투스 복지카드 250(만원) 기대(현재 {com2us})"


def test_SI_B2_monthly_amount_annualized(seeded_db):
    """B-2 회귀(2026-07-12): note가 '월 N만원'인데 BENEFIT_AMT가 월값으로 저장된
    월→연 환산 누락 방지. 95개 시드 SQL 전수 스윕+적대검증으로 확정된 유일 실버그 —
    카카오뱅크 영유아지원금 '월 10만원' → 연 120(만원). (크래프톤·파크는 M-5에서 처리,
    LS 체력단련비 30은 청구주기 서술일 뿐 이미 연값이라 대상 아님.)

    2026-09-28 재수집(R-3)으로 그 행은 금액이 없어졌다(공식 원문에 「월 10만원」이 없다) — 한 행을
    못 박던 검사를 **전수 검사**로 바꾼다: 비고에 「월 N만원」이 있는데 금액이 N 그대로인 행이 없어야 한다."""
    rows = _rows(seeded_db, """
        SELECT C.COMP_ENG_NM, B.BENEFIT_CD, B.BENEFIT_AMT, B.NOTE_CTNT
          FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
         WHERE B.BENEFIT_AMT IS NOT NULL AND B.NOTE_CTNT IS NOT NULL""")
    monthly = _re.compile(r"월\s*(\d+)\s*만\s*원")
    bad = [(eng, cd, amt) for eng, cd, amt, note in rows
           if (m := monthly.search(note)) and int(m.group(1)) == int(amt)]
    assert not bad, f"월액을 연으로 바꾸지 않은 금액: {bad}"
    assert monthly.search("월 10만원 지원"), "검사식이 옛 결함 문장을 못 잡는다"


# ── SI-M4: 금액출처는 DG-2 판별 하나로만 정한다 — M-4 앵커 강등 폐기(2026-09-28 사용자 결정) ──


def test_SI_M4_amt_source_follows_dg2_only_no_anchor_demotion(seeded_db):
    """M-4(무관 회사 간 같은 (코드·금액)이 3개사 이상이면 stated→estimated)는 폐기했다 — 「당연히 겹칠 수도
    있지」(사용자, 2026-09-28). 공식 원문에 적힌 금액(CJ 6사 복지포인트 100 · 명절 60 3사 등)까지 추정치로
    내리고 있었다. 이제 모든 공식 행의 금액출처 = DG-2 판별(`derive_amt_source`) 그대로여야 한다 — 다른 단계가
    값을 바꾸면(앵커 강등이 되살아나면) 여기서 걸린다. 겹치는 명시 금액이 실제로 stated 로 남는지도 함께 본다."""
    from db.seed.backfill_dec2 import derive_amt_source
    rows = _rows(seeded_db, """
        SELECT B.BENEFIT_ID, B.BENEFIT_AMT, B.QUAL_YN, B.NOTE_CTNT, B.AMT_SOURCE_CD
          FROM TCOMPANY_BENEFIT B WHERE B.BADGE_CD <> 'verified'""")
    bad = [(bid, src, derive_amt_source(amt, bool(q), note)) for bid, amt, q, note, src in rows
           if src != derive_amt_source(amt, bool(q), note)]
    assert not bad, f"DG-2 판별과 다른 금액출처(앵커 강등 부활?): {bad[:10]}"
    shared = _rows(seeded_db, """
        SELECT BENEFIT_CD, BENEFIT_AMT, COUNT(DISTINCT COMP_ID) AS c
          FROM TCOMPANY_BENEFIT
         WHERE AMT_SOURCE_CD='stated' AND BENEFIT_AMT IS NOT NULL
         GROUP BY BENEFIT_CD, BENEFIT_AMT
        HAVING c >= 3""")
    assert shared, "3개사 이상이 같은 금액을 명시한 공식 행이 stated 로 남아 있어야 한다(CJ 복지포인트 100 등)"


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


# ── SI-9: 식대 기준 금액 = 1끼 단가 x 하루 끼니 x 연 240일 (리드 판정 (82), 2026-10-06) ──
#
# 옛 규칙(meal 432 = 일 18,000원 x 240일 앵커 · 3식 명시일 때만)은 1끼 12,000원 규칙으로 바뀌었다.
# 1끼 단가는 회사가 밝히면 그 값, 아니면 12,000원 -> 한 끼 288 · 두 끼 576 · 세 끼 864(만원).
# 계산 근거는 메모 꼬리에 공개한다: 「(하루 N끼 x 1끼 U원 x 연 240일 추정 ...」 · 「(점심 1끼 U원 x 연 240일 추정 ...」 ·
# 「(하루 U원 x 연 240일 추정 ...」. 이 테스트는 꼬리가 있는 행의 금액이 식 그대로인지 지킨다.
# 이력: 2026-09-18 옛 규칙 강제(db/migrations/20260918_meal_anchor_to_qual.sql) -> 2026-10-06 새 규칙(db/migrations/20261006_meal_unit_12000.sql).

import re as _re

_FORMULA_DAYS = _re.compile(r"\(하루 (\d)끼 × 1끼 ([\d,]+)원 × 연 240일 추정")
_FORMULA_LUNCH = _re.compile(r"\(점심 1끼 ([\d,]+)원 × 연 240일 추정")
_FORMULA_DAY = _re.compile(r"\(하루 ([\d,]+)원 × 연 240일 추정")


def _formula_amount(note: str):
    """꼬리 식에서 기대 금액(만원). 꼬리가 없으면 None."""
    m = _FORMULA_DAYS.search(note or "")
    if m:
        return int(m.group(1)) * int(m.group(2).replace(",", "")) * 240 // 10000
    m = _FORMULA_LUNCH.search(note or "")
    if m:
        return int(m.group(1).replace(",", "")) * 240 // 10000
    m = _FORMULA_DAY.search(note or "")
    if m:
        return int(m.group(1).replace(",", "")) * 240 // 10000
    return None


# 꼬리 없이 meal 추정 금액을 갖는 행은 회사가 월액 · 포인트를 밝힌 5사와 엠씨넥스(끼니 없이 288, 사용자 「그대로」)뿐이다.
_MEAL_NO_TAIL_OK = {"voronoi", "apr", "kakao_games", "netmarble", "wemade", "mcnex"}
_TAIL_START = _re.compile(r" \((?:하루|점심) [^()]*연 240일 추정")
_M_BREAKFAST = _re.compile(r"조식|아침")
_M_LUNCH = _re.compile(r"중식|점심")
_M_DINNER = _re.compile(r"석식|저녁")
_M_THREE = _re.compile(r"삼시\s*세?끼|세\s*끼|3\s*끼|3\s*식|조\s*[·/,]\s*중\s*[·/,]\s*석")
_M_TWO = _re.compile(r"1일 2식|하루 두 끼|2\s*끼|2\s*식|중\s*[·/]?\s*석식|중석식")


def _meals_in_text(name: str, note: str) -> int:
    """이름 + 본문(끝의 계산 꼬리 제외)에서 센 끼니 수. 상한 3."""
    m = _TAIL_START.search(note)
    body = note[: m.start()] if m else note
    t = f"{name} {body}"
    kinds = sum(1 for p in (_M_BREAKFAST, _M_LUNCH, _M_DINNER) if p.search(t))
    if _M_THREE.search(t):
        kinds = max(kinds, 3)
    elif _M_TWO.search(t):
        kinds = max(kinds, 2)
    return min(kinds, 3)


def test_SI9_meal_estimate_equals_its_formula_tail(seeded_db):
    rows = _rows(seeded_db, """
        SELECT C.COMP_ENG_NM, B.BENEFIT_NM, B.BENEFIT_AMT, B.NOTE_CTNT
          FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
         WHERE B.BENEFIT_CD = 'meal' AND B.AMT_SOURCE_CD = 'estimated' AND B.BENEFIT_AMT IS NOT NULL""")
    with_tail = [(eng, nm, amt, note) for eng, nm, amt, note in rows if _formula_amount(note) is not None]
    assert len(with_tail) >= 54, f"식 꼬리가 있는 meal 추정 행이 {len(with_tail)}개뿐이다(기대 54)"
    # ① 금액 = 식 그대로
    bad = [f"{eng}: {amt} != {_formula_amount(note)}" for eng, nm, amt, note in with_tail if amt != _formula_amount(note)]
    assert not bad, f"금액이 꼬리 식과 다른 meal 행: {bad}"
    # ② 꼬리 없는 추정 금액은 허용 목록뿐
    no_tail = {eng for eng, nm, amt, note in rows if _formula_amount(note) is None}
    assert no_tail <= _MEAL_NO_TAIL_OK, f"꼬리 없이 meal 추정 금액을 가진 행: {sorted(no_tail - _MEAL_NO_TAIL_OK)}"
    # ③ 「하루 N끼 x 1끼 U원」이면 U = 12,000(기준 단가)
    bad = [eng for eng, nm, amt, note in with_tail
           if (m := _FORMULA_DAYS.search(note)) and int(m.group(2).replace(",", "")) != 12000]
    assert not bad, f"1끼 단가가 12,000원이 아닌 「하루 N끼」 꼬리: {bad}"
    # ④ 꼬리의 N <= 이름 + 본문에서 센 끼니
    bad = [f"{eng}: N={m.group(1)} > {_meals_in_text(nm, note)}" for eng, nm, amt, note in with_tail
           if (m := _FORMULA_DAYS.search(note)) and int(m.group(1)) > _meals_in_text(nm, note)]
    assert not bad, f"꼬리의 끼니 수가 이름·본문에서 센 끼니보다 많은 meal 행: {bad}"


def test_SI9_meals_in_text_counts_the_name_and_body_only():
    assert _meals_in_text("조·중·석식 제공", "조/중/석식 제공 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)") == 3
    assert _meals_in_text("사내식당", "삼시세끼 무료 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)") == 3
    assert _meals_in_text("구내식당 (중식·석식)", "구내식당 운영 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)") == 2
    assert _meals_in_text("사내식당", "점심 제공 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)") == 1
    assert _meals_in_text("사내식당", "식사 제공 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)") == 0


def test_SI9_old_anchor_phrases_are_gone(seeded_db):
    rows = _rows(seeded_db, """
        SELECT C.COMP_ENG_NM FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
         WHERE B.BENEFIT_CD = 'meal'
           AND (CONCAT(COALESCE(B.NOTE_CTNT,''), COALESCE(B.QUAL_DESC_CTNT,'')) REGEXP 'x 240일 환산|연 432만원 환산')""")
    assert not rows, f"옛 앵커 문구가 남은 meal 행: {[r[0] for r in rows]}"


def test_SI9_search_summary_rows_carry_no_amount(seeded_db):
    rows = _rows(seeded_db, """
        SELECT C.COMP_ENG_NM, B.BENEFIT_CD FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
         WHERE B.BADGE_SRC_CD = 'ai_parse' AND B.BENEFIT_AMT IS NOT NULL""")
    assert not rows, f"검색 요약 행에 금액이 있다: {rows}"


def test_SI9_rainbow_robotics_meal_row_kept_with_estimate(seeded_db):
    """정성이던 행이 끼니 1(중식)로 288 추정이 됐다 — 행은 그대로 하나, 사실 서술은 남는다."""
    rows = _rows(seeded_db, """
        SELECT B.QUAL_YN, B.BENEFIT_AMT, B.NOTE_CTNT
          FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
         WHERE C.COMP_ENG_NM = 'rainbow_robotics' AND B.BENEFIT_CD = 'meal'""")
    assert len(rows) == 1, "행 자체를 지우면 안 된다"
    qual, amt, note = rows[0]
    assert not qual and amt == 288 and note.startswith("중식 제공")


def test_SI9_formula_amount_reads_the_three_tails():
    assert _formula_amount("x (하루 3끼 × 1끼 12,000원 × 연 240일 추정)") == 864
    assert _formula_amount("x (하루 2끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)") == 576
    assert _formula_amount("x (점심 1끼 15,000원 × 연 240일 추정, 야근 시 저녁 제외)") == 360
    assert _formula_amount("x (하루 18,000원 × 연 240일 추정, 연장근로 추가분 제외)") == 432
    assert _formula_amount("구내식당 월 24만원 환산") is None


# ── SI-10: 무제한 휴가 파생은 휴가 행만 본다(2026-09-28) ──
# 정성 행 설명의 「무제한」을 카테고리 없이 보던 때, 「음료 무제한」(에이피알) · 「도서 구매 무제한」(카카오페이)이
# 회사 페이지와 이직 계산기에 「무제한 휴가」로 나갔고, 재수집한 NH투자증권의 「본인 의료비 무제한」도 걸릴 참이었다.
def _ws_row(code: str, ctgr: str, desc: str) -> str:
    return ("INSERT INTO TCOMPANY_BENEFIT (COMP_ID) VALUES\n"
            f"  (@comp_id, '{code}', '이름', NULL, '{ctgr}',\n   'est', NULL, TRUE, '{desc}', 10)\n"
            "ON DUPLICATE KEY UPDATE X = 1;")


def test_SI10_unlimited_pto_reads_time_off_rows_only():
    from db.seed.company_meta import derive_work_style
    assert derive_work_style(_ws_row("leave_general", "time_off", "자율 휴가제 운영"))["unlimitedPTO"] is True
    assert derive_work_style(_ws_row("leave_general", "time_off", "휴가 무제한 사용"))["unlimitedPTO"] is True
    assert derive_work_style(_ws_row("medical", "health", "본인 의료비 무제한"))["unlimitedPTO"] is False
    assert derive_work_style(_ws_row("snack_bar", "perks", "음료를 무제한 무료로 이용"))["unlimitedPTO"] is False


def test_SI10_unlimited_pto_real_companies(seeded_db):
    """휴가 아닌 행의 「무제한」에 걸리던 3사. 참 쪽(자율 휴가제)은 단위 시험이 맡는다 — 실데이터의 참 사례(하이브)는
    구본이 다른 회사 데이터라 재수집하면 뒤집힐 수 있어 여기 못 박지 않는다."""
    rows = dict(_rows(seeded_db, """
        SELECT COMP_ENG_NM, WORK_STYLE_VAL FROM TCOMPANY
         WHERE COMP_ENG_NM IN ('nh_invest', 'apr', 'kakao_pay')"""))
    got = {eng: (json.loads(v) if isinstance(v, str) else v).get("unlimitedPTO") for eng, v in rows.items()}
    assert got == {"nh_invest": False, "apr": False, "kakao_pay": False}, got


# ── SI-11: 「 — 」 꼬리 — 매칭 사본(benefit_rules.core_text)이 첫 「 — 」 뒤 원문 내용을 걷지 않는다 ──
def test_SI11_dash_tail_strips_only_the_collector_memo(seeded_db):
    """항목 페이지는 수집자 메모를 걷은 사본으로 센다. 꼬리는 **첫** 「 — 」부터 끝까지 걷히므로
    메모 꼬리는 맨 끝 「 — 」 하나여야 한다. 「 — 」가 둘 이상이면 그 사이 원문까지 걷혀 페이지가
    「원문에 안 나옴」으로 센다(R-3 묶음 7 검토 M1 · N-6 — 2026-10-04 29행 정리)."""
    import re

    from generator import benefit_rules as br

    sep = re.compile(r"\s+[—–]\s+")
    bad = []
    for comp, code, desc, note in _rows(
        seeded_db,
        """
        SELECT c.COMP_ENG_NM, b.BENEFIT_CD, b.QUAL_DESC_CTNT, b.NOTE_CTNT FROM TCOMPANY_BENEFIT b
        JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID WHERE b.BADGE_CD <> 'verified'
        """,
    ):
        for text in (desc, note):
            if not text:
                continue
            s = text
            while True:  # core_text 의 괄호 단계만 — 꼬리 단계 직전 모양
                t = br._PAREN.sub(br._drop_or_keep, s)
                if t == s:
                    break
                s = t
            m = br._TAIL.search(s)
            if m and br._META_TAIL.search(m.group(1)) and sep.search(m.group(1)):
                bad.append(f"{comp}/{code}: {text[:50]}")
    assert bad == [], f"「 — 」가 둘 이상이라 원문이 매칭 사본에서 걷히는 행 {len(bad)}: {bad[:5]}"


# ── SI-12: 레인 메모 낱말이 사용자 노출 칸에 새지 않는다 ──
def test_SI12_no_lane_memo_words_in_user_facing_fields(seeded_db):
    """수집 레인 보고서의 「제안 서술」 칸에는 통합자용 메모(「덧붙인 전문:」 · 「27~29 를 합친」 ·
    「#21 을 빼면」 · 「#숫자」)가 섞여 있다. 그대로 옮기면 회사 페이지 · 항목 페이지 · `/find` · API 로
    나간다(R-3 후속 정리 2 독립 검토 H1 — 4칸). SI-11 은 「 — 」 꼬리만 보므로 이 모양을 못 잡는다."""
    import re

    memo = re.compile(r"전문: |을 합친|를 합친|한 번에 합친|덧붙인|덧붙일|을 빼면|를 빼면|#\d+")
    bad = []
    for comp, code, nm, desc, note in _rows(
        seeded_db,
        """
        SELECT c.COMP_ENG_NM, b.BENEFIT_CD, b.BENEFIT_NM, b.QUAL_DESC_CTNT, b.NOTE_CTNT FROM TCOMPANY_BENEFIT b
        JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID WHERE b.BADGE_CD <> 'verified'
        """,
    ):
        for text in (nm, desc, note):
            if text and memo.search(text):
                bad.append(f"{comp}/{code}: {text[:50]}")
    assert bad == [], f"레인 메모 낱말이 사용자 노출 칸에 있는 행 {len(bad)}: {bad[:5]}"


# ── SI-13: 근무형태 칩 조건(6c, 2026-10-04) — 이름만 읽는다 ──
# 칩 = 조건 없는 단정 · 조건 있는 키는 false + `cond` 맵. DB 없이 시드 파일에서 바로 파생한다(실데이터 고정).
def test_SI13a_ws_conditions_name_forms():
    from db.seed.company_meta import ws_conditions as w
    assert w("육아기 재택근무") == ["육아기"]
    assert w("자녀돌봄 재택근무") == ["자녀돌봄"]
    assert w("재택근무 (필요 시)") == ["필요 시"]
    assert w("재택근무 (필요시)") == ["필요 시"]
    assert w("재택근무 (글로벌부문)") == ["글로벌부문"]
    assert w("유연근무제·자율출퇴근제 (패션부문)") == ["패션부문"]
    assert w("장기근속 휴가·휴가비 (건설·리조트부문)") == ["건설·리조트부문"]
    assert w("재택근무 (휴가는 건설부문)") == ["건설부문"]
    assert w("탄력근무 (자녀를 둔 부·모)") == ["자녀를 둔 부·모"]
    assert w("시차출퇴근제 (조건부)") == ["조건부"]       # ⚖11
    assert w("부서별 유연근무제") == ["부서별"]            # ⚖11
    # 한정으로 읽지 않는 꼴
    assert w("재택근무") == []
    assert w("원격근무제(재택근무 포함)") == []
    assert w("재택근무 (주 1회)") == []
    assert w("재택근무(WFA)") == []
    assert w("정기휴가 (글로벌부문)·Refresh 휴가") == []  # 끝이 아닌 중간 괄호
    assert w("육아기재택") == []                           # 붙여쓰기는 맨 칩으로 샌다(SI-13d 가드 + 수집 계약)
    assert w(None) == [] and w("") == []


def _row(code: str, name: str, desc: str = "서술") -> str:
    return f"  (@comp_id, '{code}', '{name}', NULL, 'flexibility',\n   'est', NULL, TRUE, '{desc}', 10)"


def _sql(*rows: str) -> str:
    """행 문자열들 → 한 INSERT(`_row_chunks` 는 첫 ON DUPLICATE 앞까지만 읽는다)."""
    return "INSERT INTO TCOMPANY_BENEFIT (COMP_ID) VALUES\n" + ",\n".join(rows) + "\nON DUPLICATE KEY UPDATE X = 1;"


def test_SI13b_plain_row_wins_and_conditions_merge_in_row_order():
    from db.seed.company_meta import derive_work_style as d
    plain_and_cond = d(_sql(_row("remote_work", "재택근무"), _row("telecommute", "육아기 재택근무")))
    assert plain_and_cond["remote"] is True and "cond" not in plain_and_cond, "맨 행이 하나라도 있으면 맨 칩"
    only_cond = d(_sql(_row("remote_work", "육아기 재택근무"), _row("wfh", "재택근무 (필요 시)"), _row("telecommute", "육아기 재택근무")))
    assert only_cond["remote"] is False and only_cond["cond"] == {"remote": ["육아기", "필요 시"]}, "행 순서 · 중복 제거"
    refresh = d(_sql(_row("refresh_leave", "리프레시 휴가 (건설부문)", "건설 서술"), _row("long_service_leave", "장기근속 휴가", "맨 행 서술")))
    assert refresh["refreshLeave"] == "맨 행 서술" and "cond" not in refresh, "refreshLeave 문구 = 조건 없는 행의 마지막 서술"
    refresh_cond = d(_sql(_row("refresh_leave", "리프레시 휴가 (건설부문)")))
    assert refresh_cond["refreshLeave"] is None and refresh_cond["cond"] == {"refreshLeave": ["건설부문"]}
    assert "cond" not in d(_sql(_row("flex_work", "유연근무제"))), "조건이 없으면 cond 키를 쓰지 않는다"


def _real_ws() -> dict:
    from db.seed.company_meta import build_company_meta
    return {eng: v["work_style"] for eng, v in build_company_meta().items()}


def test_SI13c_real_companies_cond_is_pinned():
    ws = _real_ws()
    got = {eng: v["cond"] for eng, v in ws.items() if "cond" in v}
    assert got == {
        "hanmi_pharm": {"remote": ["육아기"]},
        "krafton": {"remote": ["자녀돌봄"]},
        "posco_futurem": {"remote": ["육아기"]},
        "doosan_enerbility": {"remote": ["필요 시"]},
        "telechips": {"remote": ["필요 시"]},
        "hanwha": {"remote": ["글로벌부문"]},
        "hanwha_systems": {"remote": ["ICT부문"]},
        "samsung_ct": {"flex": ["패션부문"], "refreshLeave": ["건설·리조트부문"]},
        "pharma_research": {"flex": ["자녀를 둔 부·모"]},
        "rainbow_robotics": {"flex": ["조건부"]},
        "jeju_semi": {"flex": ["부서별"]},
        "orion": {"remote": ["조건부"]},
    }
    for eng in ("db_insurance", "hyundai_glovis"):
        assert ws[eng]["remote"] is True and "cond" not in ws[eng], f"{eng}: 「재택근무 포함」 · 신청형은 맨 칩 유지"
    assert ws["hanwha"]["flex"] is True and ws["hanwha"]["refreshLeave"] is not None, "㈜한화 flex · refreshLeave 는 맨 칩 유지"
    for eng, v in ws.items():
        for k in v.get("cond", {}):
            assert not v.get(k), f"{eng}: 불변식 k ∈ cond ⇒ !ws[k]"


def test_SI13d_guard_condition_looking_names_must_yield_a_condition():
    """근무형태 4코드 행 이름에 육아 · 자녀 · 부문 · 필요시가 보이는데 조건으로 못 읽으면 칩이 조용히 맨 칩으로 샌다(수집 계약 위반)."""
    import re
    from db.seed.company_meta import BENEFIT_SQL_DIR, _WS_CODE_KEY, _row_chunks, _row_info, ws_conditions
    looks = re.compile(r"육아|자녀|부문|필요\s*시")
    exceptions = {("hanwha", "정기휴가 (글로벌부문)·Refresh 휴가")}  # 중간 괄호 = 한정 아님(PR #98 이름)
    bad = []
    for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):
        text = f.read_text(encoding="utf-8")
        m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", text)
        eng = m.group(1) if m else f.stem
        for chunk in _row_chunks(text):
            code, _q, _d, _c, name = _row_info(chunk)
            if code in _WS_CODE_KEY and name and looks.search(name) and not ws_conditions(name) and (eng, name) not in exceptions:
                bad.append((eng, code, name))
    assert not bad, f"조건처럼 보이지만 읽히지 않는 근무형태 행 이름(수집 계약 「근무형태 칩 이름 규칙」 확인): {bad}"


# ── SI-12: 금액 표시 정정 8행 (리드 판정 (88), 2026-10-08) ──
# 삼성전자 3행은 원문에 금액이 없어 estimated, 한 번 받는 돈을 연 금액으로 적었던 5행은 금액 미등록(정성)이다.
# 그리고 「공식 수치(stated)」인 행의 서술에는 원 · 만원 숫자가 있어야 한다 — 없으면 앵커가 stated 로 새어 든 것이다.
_SI12_ESTIMATED = (("samsung_elec", "resort", 100), ("samsung_elec", "welfare_point", 200), ("samsung_elec", "commute_subsidy", 120))
_SI12_ONE_TIME = (("kai", "parenting"), ("cj_freshway", "long_service_bonus"), ("cj_enm_com", "long_service_bonus"),
                  ("cj_oliveyoung", "excellence_award"), ("cj_freshway", "event"))


def test_SI12_samsung_anchor_rows_are_estimated(seeded_db):
    for eng, code, amt in _SI12_ESTIMATED:
        rows = _rows(seeded_db, """
            SELECT B.BENEFIT_AMT, B.AMT_SOURCE_CD, B.NOTE_CTNT FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
             WHERE C.COMP_ENG_NM = %s AND B.BENEFIT_CD = %s""", (eng, code))
        assert len(rows) == 1 and rows[0][0] == amt and rows[0][1] == "estimated" and "(추정)" in rows[0][2], (eng, code, rows)


def test_SI12_one_time_payments_are_not_registered_as_yearly_amounts(seeded_db):
    for eng, code in _SI12_ONE_TIME:
        rows = _rows(seeded_db, """
            SELECT B.BENEFIT_AMT, B.AMT_SOURCE_CD, B.QUAL_YN, B.NOTE_CTNT, B.QUAL_DESC_CTNT
              FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID
             WHERE C.COMP_ENG_NM = %s AND B.BENEFIT_CD = %s""", (eng, code))
        assert len(rows) == 1, (eng, code, rows)
        amt, src, qual, note, desc = rows[0]
        assert amt is None and src == "none" and qual and note is None and desc, (eng, code, rows)
        assert "표기값은 상한" not in desc, (eng, code)


def test_SI12_stated_rows_show_a_won_figure_in_their_text(seeded_db):
    rows = _rows(seeded_db, """
        SELECT C.COMP_ENG_NM, B.BENEFIT_CD, COALESCE(B.NOTE_CTNT,''), COALESCE(B.QUAL_DESC_CTNT,'')
          FROM TCOMPANY_BENEFIT B JOIN TCOMPANY C ON C.COMP_ID = B.COMP_ID WHERE B.AMT_SOURCE_CD = 'stated'""")
    assert rows, "stated 행이 하나도 없다"
    pat = _re.compile(r"\d[\d,.]*\s*(만\s*원|원|만)")
    bad = [f"{eng}/{code}" for eng, code, note, desc in rows if not pat.search(f"{note} {desc}")]
    assert not bad, f"서술에 원 · 만원 숫자가 없는 stated 행: {bad}"
