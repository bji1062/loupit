"""generator/tests/fixtures.py — 소형 fake 번들 픽스처 (SP-GEN-12.1, T-07.11.1).

`FAKE_BUNDLE`(회사 3: samsung_elec·sk_hynix·naver) + XSS 변형 번들 +
조합 큐레이션 픽스처(FAKE_COMBINATIONS_RAW, 조합 2 유효 + 1 무효 스킵용).
필드명은 SP-API-6/7 계약(`server/services/reference.py::build_reference_bundle`)과
1:1이다. 실 DB 무경유(무 DB) — GC-1~GC-26 전 스위트가 이 dict를 직접 소비한다.
"""
from __future__ import annotations

import copy

COMPANY_TYPES = [
    {
        "comp_tp_cd": "large",
        "comp_tp_nm": "대기업",
        "growth_rate_val": 4.0,
        "growth_label_nm": "대기업 평균 4%",
        "stability_score_no": 90,
    },
]

BENEFIT_PRESETS = {"large": []}  # 회사페이지 미사용(참고, INV-6: 프리셋 폴백 없음)

_FAR_FUTURE = "2099-12-31"  # 만료 안 지남(시스템 시계 무관 안전)
_FAR_PAST = "2020-01-01"  # 항상 만료(만료·재확인 필요, stale)

COMPANIES = [
    {
        "comp_id": 1,
        "comp_eng_nm": "samsung_elec",
        "comp_nm": "삼성전자",
        "comp_tp_cd": "large",
        "industry_nm": "반도체",
        "logo_nm": "S",
        "work_style_val": {"remote": True, "flex": True, "overtime": True},
        "aliases": ["삼성전자", "삼성", "Samsung"],
        "benefits": [
            {
                "benefit_nm": "식대 지원",
                "benefit_amt": 240,
                "benefit_ctgr_cd": "perks",
                "badge_cd": "official",
                "amt_source": "estimated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-04-15",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "scrape_official",
                "badge_src_url_ctnt": "https://ex.com/samsung/perks",
                "sort_order_no": 0,
            },
            {
                "benefit_nm": "성과급 인센티브",
                "benefit_amt": 1200,
                "benefit_ctgr_cd": "compensation",
                "badge_cd": "official",
                "amt_source": "stated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-01-10",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "scrape_official",
                "badge_src_url_ctnt": "https://ex.com/samsung/comp",
                "sort_order_no": 0,
            },
            {
                # 만료 지난 표본(GC-13 stale) + javascript: 스킴 출처(GC-14 링크 차단)
                "benefit_nm": "건강검진 지원",
                "benefit_amt": None,
                "benefit_ctgr_cd": "health",
                "badge_cd": "est",
                "amt_source": "estimated",
                "qual_yn": True,
                "qual_desc_ctnt": "연 1회 정밀검진 지원",
                "note_ctnt": None,
                "verified_dtm": _FAR_PAST,
                "expires_dtm": _FAR_PAST,
                "badge_src_cd": "manual_estimate",
                "badge_src_url_ctnt": "javascript:alert(1)",
                "sort_order_no": 0,
            },
            {
                "benefit_nm": "리프레시 휴가",
                "benefit_amt": None,
                "benefit_ctgr_cd": "time_off",
                "badge_cd": "est",
                "amt_source": "estimated",
                "qual_yn": True,
                "qual_desc_ctnt": "3년 근속마다 2주 부여",
                "note_ctnt": "사용 시기는 부서 협의",
                "verified_dtm": "2026-02-01",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": None,
                "badge_src_url_ctnt": None,
                "sort_order_no": 1,
            },
        ],
    },
    {
        "comp_id": 2,
        "comp_eng_nm": "sk_hynix",
        "comp_nm": "SK하이닉스",
        "comp_tp_cd": "large",
        "industry_nm": "반도체",
        "logo_nm": "SK",
        "work_style_val": {"flex": True, "unlimitedPTO": True},
        "aliases": ["SK하이닉스", "하이닉스"],
        "benefits": [
            {
                "benefit_nm": "주택자금 대출 지원",
                "benefit_amt": 5000,
                "benefit_ctgr_cd": "compensation",
                "badge_cd": "official",
                "amt_source": "stated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-03-01",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "scrape_official",
                "badge_src_url_ctnt": "https://ex.com/skhynix/comp",
                "sort_order_no": 0,
            },
            {
                "benefit_nm": "동호회 지원",
                "benefit_amt": 30,
                "benefit_ctgr_cd": "leisure",
                "badge_cd": "est",
                "amt_source": "estimated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-05-01",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "manual_estimate",
                "badge_src_url_ctnt": None,
                "sort_order_no": 0,
            },
        ],
    },
    {
        "comp_id": 3,
        "comp_eng_nm": "naver",
        "comp_nm": "네이버",
        # comp_tp_cd가 company_types에 없는 표본 → 유형 지표(안정성·성장) 미보유 시
        # 생략(허위 표기 금지, UC-41 1a) 방어 경로를 실데이터로 구동.
        "comp_tp_cd": "unlisted",
        "industry_nm": "IT",
        "logo_nm": "N",
        "work_style_val": {"remote": True, "flex": True, "refreshLeave": True},
        "aliases": ["네이버", "NAVER"],
        "benefits": [
            {
                "benefit_nm": "육아휴직 지원",
                "benefit_amt": None,
                "benefit_ctgr_cd": "family",
                "badge_cd": "official",
                "amt_source": "stated",
                "qual_yn": True,
                "qual_desc_ctnt": "법정 기준 이상 지원",
                "note_ctnt": None,
                "verified_dtm": "2026-06-01",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "scrape_official",
                "badge_src_url_ctnt": "https://ex.com/naver/family",
                "sort_order_no": 0,
            },
            {
                "benefit_nm": "자기계발비 지원",
                "benefit_amt": 100,
                "benefit_ctgr_cd": "growth",
                "badge_cd": "est",
                "amt_source": "estimated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-05-20",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": "manual_estimate",
                "badge_src_url_ctnt": "https://ex.com/naver/growth",
                "sort_order_no": 0,
            },
        ],
    },
]

FAKE_BUNDLE = {
    "company_types": COMPANY_TYPES,
    "benefit_presets": BENEFIT_PRESETS,
    "companies": COMPANIES,
}


def make_xss_bundle() -> dict:
    """comp_nm에 스크립트 태그를 주입한 변형 번들(GC-21, T-07.11.4).

    `FAKE_BUNDLE`을 깊은 복사해 원본을 오염시키지 않는다.
    """
    bundle = copy.deepcopy(FAKE_BUNDLE)
    bundle["companies"][0]["comp_nm"] = "<script>alert(1)</script>삼성"
    return bundle


FAKE_BUNDLE_XSS = make_xss_bundle()

# 인기 조합 큐레이션 픽스처 — 유효 2(samsung_elec-sk_hynix · naver-sk_hynix) +
# 무효 1(kakao 미등록, GC-23 스킵 소비). 실제 combinations.json 스키마와 동일.
FAKE_COMBINATIONS_RAW = {
    "combinations": [
        {"a": "samsung_elec", "b": "sk_hynix", "note": "반도체 경쟁사"},
        {"a": "naver", "b": "sk_hynix", "note": "이종 산업 비교"},
        {"a": "naver", "b": "kakao", "note": "미등록 회사 포함(GC-23 스킵 소비)"},
    ]
}


# ── 재무(DART) 픽스처 — SP-FIN-4 로더 출력 형태(`generator/finance.py::assemble`)와 1:1 ──
# 회사 3곳 중 1곳 일반 5개년(삼성전자, 연결) · 1곳 금융(네이버 — 픽스처상 금융 세트, 별도 기준,
# 순이익만) · 1곳 없음(SK하이닉스 — 키 자체가 없다 = "공시 데이터 없음" 경로).
# 금액은 원 단위 정수. None 은 "그 계정이 없다"(금융업)이지 0 이 아니다.
FAKE_FINANCE = {
    1: {
        "corp_nm": "삼성전자",
        "stock_cd": "005930",
        "acct_set": "general",
        "fs_div": "CFS",
        "years": [
            {"year": 2021, "revenue": 279_600_000_000_000, "op_income": 51_630_000_000_000, "net_income": 39_900_000_000_000, "rcept_no": "20220308000001"},
            {"year": 2022, "revenue": 302_230_000_000_000, "op_income": 43_380_000_000_000, "net_income": 55_650_000_000_000, "rcept_no": "20230307000001"},
            {"year": 2023, "revenue": 258_940_000_000_000, "op_income": 6_570_000_000_000, "net_income": 15_490_000_000_000, "rcept_no": "20240312000001"},
            {"year": 2024, "revenue": 300_000_000_000_000, "op_income": 32_000_000_000_000, "net_income": 34_000_000_000_000, "rcept_no": "20250311000002"},
            {"year": 2025, "revenue": 330_000_000_000_000, "op_income": 40_000_000_000_000, "net_income": 35_000_000_000_000, "rcept_no": "20260318000001"},
        ],
        "siblings": [],
    },
    3: {
        "corp_nm": "네이버",
        "stock_cd": "035420",
        "acct_set": "financial",
        "fs_div": "OFS",
        "years": [
            {"year": 2024, "revenue": None, "op_income": None, "net_income": 2_200_000_000_000, "rcept_no": "20250325000004"},
            {"year": 2025, "revenue": None, "op_income": None, "net_income": 2_451_500_000_000, "rcept_no": "20260325000004"},
        ],
        "siblings": [],
    },
}


def _mk_cj_enm(comp_id: int, eng: str, nm: str) -> dict:
    return {
        "comp_id": comp_id,
        "comp_eng_nm": eng,
        "comp_nm": nm,
        "comp_tp_cd": "large",
        "industry_nm": "미디어",
        "logo_nm": "C",
        "work_style_val": {},
        "aliases": [nm],
        "benefits": [
            {
                "benefit_nm": "식대 지원",
                "benefit_amt": 200,
                "benefit_ctgr_cd": "perks",
                "badge_cd": "official",
                "amt_source": "stated",
                "qual_yn": False,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": "2026-01-01",
                "expires_dtm": _FAR_FUTURE,
                "badge_src_cd": None,
                "badge_src_url_ctnt": None,
                "sort_order_no": 0,
            }
        ],
    }


def make_sibling_fixture() -> tuple[dict, dict]:
    """형제 페이지 변형 — CJ ENM 두 부문이 **한 법인**(00265324)을 가리키는 실측 구조(함정 (69)).

    `FAKE_BUNDLE` 에 회사 2곳(98·99)을 더하고, 재무는 같은 연도 목록 + 서로를 `siblings` 로.
    원본은 깊은 복사로 보호한다. 순이익 음수(-500억)도 여기서 한 번 거친다.
    """
    bundle = copy.deepcopy(FAKE_BUNDLE)
    bundle["companies"] += [
        _mk_cj_enm(98, "cj_enm_ent", "CJ ENM 엔터테인먼트부문"),
        _mk_cj_enm(99, "cj_enm_com", "CJ ENM 커머스부문"),
    ]
    years = [
        {"year": 2024, "revenue": 4_500_000_000_000, "op_income": 100_000_000_000, "net_income": 30_000_000_000, "rcept_no": "20250320000008"},
        {"year": 2025, "revenue": 4_795_000_000_000, "op_income": 120_000_000_000, "net_income": -50_000_000_000, "rcept_no": "20260319000009"},
    ]
    finance = copy.deepcopy(FAKE_FINANCE)
    finance[98] = {"corp_nm": "씨제이이엔엠", "stock_cd": "035760", "acct_set": "general", "fs_div": "CFS", "years": copy.deepcopy(years), "siblings": [99]}
    finance[99] = {"corp_nm": "씨제이이엔엠", "stock_cd": "035760", "acct_set": "general", "fs_div": "CFS", "years": copy.deepcopy(years), "siblings": [98]}
    return bundle, finance
