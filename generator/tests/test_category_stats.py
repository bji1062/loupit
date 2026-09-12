"""generator/tests/test_category_stats.py — 눈금 기준(평균·축 최댓값)의 **두 언어 대조** (SP-CMP-4 ③).

9각형·나비차트의 눈금은 「등록 회사 전체」를 한 번 훑어야 나온다. 정적 페이지는 빌드 시점에
`generator/corpus.py::build` 로, 모드 A 도구는 런타임에 `web/assets/js/benefits.js::categoryStats`
로 센다 — **같은 셈이어야 한다**. 다르면 같은 회사가 상세와 비교에서 다른 크기로 그려지고, 아무도
에러를 못 본다.

여기서 파이썬 산출물을 `data/category_stats_cases.json` 에 적어 두고 `benefits.test.js` 가 같은
파일을 읽는다. 다시 뽑으려면(= 계약을 **의도적으로** 바꿨을 때만):

    CATEGORY_STATS_WRITE=1 python3 -m pytest generator/tests/test_category_stats.py -q
"""
from __future__ import annotations

import json
import os
from pathlib import Path

from generator import corpus as corpus_mod
from generator.pages.company import CATEGORY_ORDER

CASES_PATH = Path(__file__).resolve().parent / "data" / "category_stats_cases.json"


def _co(comp_id: int, cats: list[str]) -> dict:
    """비교에 필요한 최소 회사 모양 — `comp_id` 와 카테고리 코드가 붙은 복지 행."""
    return {
        "comp_id": comp_id,
        "benefits": [
            {"benefit_cd": f"b{comp_id}_{i}", "benefit_ctgr_cd": c, "qual_yn": True,
             "benefit_amt": None}
            for i, c in enumerate(cats)
        ],
    }


CASE_INPUTS = [
    {
        "name": "mixed_three",
        "why": "보통 쌍 — 회사마다 카테고리 분포가 다르고 빈 카테고리가 섞인다",
        "companies": [
            _co(1, ["perks", "perks", "health", "family", "growth"]),
            _co(2, ["perks", "health", "health", "time_off"]),
            _co(3, ["compensation", "flexibility", "perks", "perks", "perks", "leisure"]),
        ],
    },
    {
        # 🚨 8곳이면 평균이 정확히 .xx5 에 떨어진다(항목 1 / 8곳 = 0.125). 파이썬 round 는 짝수
        # 쪽(0.12), JS `Math.round` 는 위(0.13)로 간다 — 그 좌표가 9각형에 그대로 실린다.
        "name": "eight_companies_quarter_avg",
        "why": ".125 · .375 평균 — round(x, 2) 의 짝수 반올림이 JS 와 갈리는 유일한 지점",
        "companies": (
            [_co(10, ["compensation"])]                      # compensation 총 1 / 8곳 = 0.125
            + [_co(11, ["health", "health", "health"])]      # health 총 3 / 8곳 = 0.375
            + [_co(i, []) for i in range(12, 18)]  # 합쳐 8곳
        ),
    },
    {
        # 🚨 120곳이면 평균이 **비이진** 값 0.025 에 떨어진다(보상 합 3 / 120곳). 파이썬 round 는
        # 0.03 인데, JS 쪽이 `x*200` 으로 동점을 판정하면 이것을 동점으로 오판해 0.02 를 낸다
        # (2026-09-12 검증에서 잡힌 오답 — 회사 수 120·160·200·240 에서 좌표가 갈렸다).
        # 8의 배수 케이스(위)는 **정확한** 동점이고 이것은 **가짜** 동점이라, 둘이 함께 있어야
        # 양쪽 방향의 오답이 다 잡힌다.
        "name": "one_twenty_companies_fake_tie",
        "why": "0.025 = 비이진 값 — 동점으로 오판하면 안 된다(파이썬 0.03)",
        "companies": (
            [_co(20, ["compensation"]), _co(21, ["compensation"]), _co(22, ["compensation"])]
            + [_co(i, []) for i in range(23, 140)]  # 합쳐 120곳
        ),
    },
    {
        "name": "empty_bundle",
        "why": "회사 0곳(부팅 번들 실패 폴백)에서도 죽지 않고 rmax 는 1 로 선다",
        "companies": [],
    },
]


def _expected() -> dict:
    cases = []
    for inp in CASE_INPUTS:
        c = corpus_mod.build(inp["companies"], CATEGORY_ORDER)
        cases.append({
            **inp,
            # 회사 페이지가 레이더에 넘기는 값과 **같은 반올림**이다(`company.py::_card_view`).
            # 여기서 반올림하지 않으면 도형 좌표가 두 언어에서 미세하게 갈린다.
            "avgs": {k: round(c.avgs.get(k, 0.0), 2) for k in CATEGORY_ORDER},
            "rmax": c.rmax,
            "total": c.total,
        })
    return {
        "note": (
            "generator/tests/test_category_stats.py 가 만들고 web/assets/js/benefits.test.js 가 읽는다. "
            "손으로 고치지 마라 — CATEGORY_STATS_WRITE=1 로 다시 뽑고, 뽑은 뒤 JS 테스트도 돌려라."
        ),
        "category_order": CATEGORY_ORDER,
        "cases": cases,
    }


def test_category_stats_fixture_matches_corpus_build():
    built = _expected()
    if os.environ.get("CATEGORY_STATS_WRITE") == "1":
        CASES_PATH.parent.mkdir(parents=True, exist_ok=True)
        CASES_PATH.write_text(json.dumps(built, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    assert CASES_PATH.is_file(), f"픽스처가 없다: {CASES_PATH}"
    saved = json.loads(CASES_PATH.read_text(encoding="utf-8"))
    assert saved == built, (
        "눈금 기준이 픽스처와 다르다. 의도한 변경이면 CATEGORY_STATS_WRITE=1 로 다시 뽑고 "
        "node --test web/assets/js/benefits.test.js 도 함께 돌려라."
    )


def test_fixture_pins_both_directions_of_the_rounding_trap():
    """반올림 오답은 **양방향**이다 — 진짜 동점을 올리는 쪽과, 가짜 동점을 내리는 쪽.

    두 케이스가 함께 있어야 둘 다 잡힌다. 하나만 두면 다른 방향이 조용히 통과한다.
    """
    saved = json.loads(CASES_PATH.read_text(encoding="utf-8"))
    quarter = next(c for c in saved["cases"] if c["name"] == "eight_companies_quarter_avg")
    assert quarter["avgs"]["compensation"] == 0.12, "1/8 = 0.125(정확한 동점)은 짝수 쪽 0.12"
    assert quarter["avgs"]["health"] == 0.38, "3/8 = 0.375(정확한 동점)은 짝수 쪽 0.38"
    fake = next(c for c in saved["cases"] if c["name"] == "one_twenty_companies_fake_tie")
    assert fake["total"] == 120
    assert fake["avgs"]["compensation"] == 0.03, "3/120 = 0.025 는 비이진 값 — 동점이 아니라 0.03"


def test_empty_bundle_still_has_a_usable_axis_max():
    """회사 0곳에서 rmax 가 0 이면 모든 좌표가 중심으로 무너진다 — corpus 는 1 로 올린다."""
    saved = json.loads(CASES_PATH.read_text(encoding="utf-8"))
    empty = next(c for c in saved["cases"] if c["name"] == "empty_bundle")
    assert empty["rmax"] == 1 and empty["total"] == 0
    assert set(empty["avgs"].values()) == {0.0}
