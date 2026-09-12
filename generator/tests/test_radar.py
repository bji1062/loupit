"""generator/tests/test_radar.py — 9각형 레이더 + **쌍 레이더 골든 픽스처** (SP-CMP-4·10).

`radar.py` 머리 주석이 금지하던 것이 이번에 필요해졌다: 모드 A 「복지 비교」는 브라우저 도구라
좌표를 JS 로도 그린다(`web/assets/js/radar.js`). 렌더러가 둘이면 축 규칙·결측 처리가 두 언어로
갈라지고, 갈라진 판정은 **에러 없이** 어긋난다(배지 함정). 그래서 이 파일이 방어선이다:

  · 여기서 Python 산출물을 `data/radar_pair_cases.json` 에 **적어 두고**, 드리프트를 즉시 깬다.
  · `web/assets/js/radar.test.js` 가 **같은 파일**을 읽어 JS 산출물과 바이트 비교한다.

픽스처를 다시 뽑으려면(= Python 쪽 계약을 **의도적으로** 바꿨을 때만):

    RADAR_GOLDEN_WRITE=1 python3 -m pytest generator/tests/test_radar.py -q

그리고 반드시 `node --test web/assets/js/radar.test.js` 를 함께 돌려라 — 픽스처만 갱신하면
"두 렌더러가 다르다"가 "픽스처가 JS 를 따라갔다"로 조용히 바뀐다.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

from generator.radar import (
    BAND_DEFAULT,
    VIEWBOX_PAIR,
    _poly,
    _pt,
    _readout,
    _sector,
    fmt,
    radar_pair_svg,
    radar_svg,
)

CASES_PATH = Path(__file__).resolve().parent / "data" / "radar_pair_cases.json"
LABELS9 = ["보상", "유연성", "근무환경", "휴가", "건강", "가족", "성장", "여가", "복리후생"]

# ── 입력 정본 ────────────────────────────────────────────────────────────────
# 다섯 케이스는 각각 **다른 함정**을 잡는다. 수를 줄이지 마라.
CASE_INPUTS = [
    {
        # 2026-09-12 DB 실측(NAVER 23행·카카오 16행). 나비안 아티팩트의 목업과 같은 숫자다.
        "name": "naver_kakao",
        "why": "실측 쌍 — 한쪽 0·양쪽 0·동값이 한 그림에 다 들어 있다",
        "counts_a": [2, 1, 0, 3, 4, 3, 2, 2, 6],
        "counts_b": [0, 1, 0, 0, 2, 2, 2, 2, 7],
        "avgs": [1.03, 0.84, 0.65, 1.18, 2.82, 2.51, 1.56, 1.81, 3.73],
        "rmax": 8,
        "a_nm": "NAVER",
        "b_nm": "카카오",
    },
    {
        # rmax 가 0 으로 들어와도 1 로 올라가고, 고리·눈금이 통째로 빠진다(RINGS 최솟값 2 > 1).
        "name": "all_zero",
        "why": "양쪽 전 축 0 — 아홉 꼭짓점이 중심에 겹친다. 점 히트로는 못 짚어 부채꼴이 필요한 이유",
        "counts_a": [0] * 9,
        "counts_b": [0] * 9,
        "avgs": [0.0] * 9,
        "rmax": 0,
        "a_nm": "가나",
        "b_nm": "다라",
    },
    {
        "name": "all_tie",
        "why": "전 축 동값 — A 원이 전부 속 빈 링(rdp-tie)이어야 파랑 네모가 비친다",
        "counts_a": [4] * 9,
        "counts_b": [4] * 9,
        "avgs": [4.0] * 9,
        "rmax": 8,
        "a_nm": "쌍둥이A",
        "b_nm": "쌍둥이B",
    },
    {
        # 🚨 이 케이스가 이 파일의 존재 이유다. 좌표가 정확히 x.25 이면 파이썬 `.1f` 는 **짝수 쪽**
        # (151.25 → 151.2)으로, JS `toFixed(1)` 은 **위**(→ 151.3)로 반올림한다. 값 3·rmax 8 인
        # 축이 딱 그 자리(200 − 130×3/8 = 151.25)에 떨어지고, 평균 1.25 는 판독문에서 같은 일을 한다.
        "name": "quarter_rounding",
        "why": ".25 동점 — Python(짝수 반올림)과 JS(올림)가 갈리는 유일한 지점",
        "counts_a": [3, 1, 3, 1, 3, 1, 3, 1, 3],
        "counts_b": [1, 3, 1, 3, 1, 3, 1, 3, 1],
        "avgs": [1.25, 1.75, 2.25, 2.75, 3.25, 3.75, 0.25, 0.75, 2.0],
        "rmax": 8,
        "a_nm": "네자리",
        "b_nm": "동점사",
    },
    {
        # 회사명에 `&` 가 실제로 있다(삼성E&A). 두 렌더러의 이스케이프가 다르면 여기서 갈린다 —
        # 파이썬 `html.escape` 는 `'` 를 `&#x27;` 로 쓰고 dom.js `escapeHtml` 은 `&#39;` 로 쓴다.
        "name": "escape",
        "why": "& < > \" ' 이 두 언어에서 같은 바이트로 나가는가",
        "counts_a": [1, 2, 3, 0, 1, 2, 3, 0, 1],
        "counts_b": [3, 0, 1, 2, 3, 0, 1, 2, 3],
        "avgs": [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8],
        "rmax": 8,
        "a_nm": "삼성E&A",
        "b_nm": "<b>\"따옴표'\"</b>",
    },
]


def _build_case(inp: dict) -> dict:
    """입력 → 픽스처 한 칸. 여기 적히는 값이 **두 언어의 계약**이다."""
    n = len(inp["counts_a"])
    rmax = float(max(inp["rmax"], max(inp["counts_a"]), max(inp["counts_b"]), 1))
    return {
        **inp,
        "labels": LABELS9,
        # 정규화된 축 최댓값 — JS 도 같은 규칙으로 올려야 한다(0 이 들어와도 1).
        "rmax_effective": rmax,
        "viewbox": VIEWBOX_PAIR,
        "points": {
            "a": _poly(inp["counts_a"], rmax),
            "b": _poly(inp["counts_b"], rmax),
            "avg": _poly(inp["avgs"], rmax),
            "rings": [_poly([k] * n, rmax) for k in (2, 4, 6, 8) if k <= rmax],
            "axes": [
                [f"{_pt(i, rmax, n, rmax)[0]:.1f}", f"{_pt(i, rmax, n, rmax)[1]:.1f}"]
                for i in range(n)
            ],
            "sectors": [_sector(i, n) for i in range(n)],
        },
        "readouts": [
            _readout(LABELS9[i], inp["counts_a"][i], inp["counts_b"][i], inp["avgs"][i],
                     inp["a_nm"], inp["b_nm"])
            for i in range(n)
        ],
        # 전체 SVG 문자열. 두 렌더러가 **같은 바이트**를 내는 것이 계약이라 조각이 아니라 통째로 건다.
        "svg": radar_pair_svg(inp["counts_a"], inp["counts_b"], inp["avgs"], LABELS9,
                              inp["rmax"], inp["a_nm"], inp["b_nm"]),
    }


def _expected() -> dict:
    return {
        "note": (
            "generator/tests/test_radar.py 가 만들고 web/assets/js/radar.test.js 가 읽는다. "
            "손으로 고치지 마라 — RADAR_GOLDEN_WRITE=1 로 다시 뽑고, 뽑은 뒤에는 반드시 JS 테스트도 돌려라."
        ),
        "band_default": BAND_DEFAULT,
        "cases": [_build_case(c) for c in CASE_INPUTS],
    }


def test_pair_golden_fixture_matches_python_output():
    """픽스처가 지금의 Python 산출물과 같은가. 다르면 **둘 중 하나가 조용히 바뀐 것**이다."""
    built = _expected()
    if os.environ.get("RADAR_GOLDEN_WRITE") == "1":
        CASES_PATH.parent.mkdir(parents=True, exist_ok=True)
        CASES_PATH.write_text(json.dumps(built, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    assert CASES_PATH.is_file(), f"골든 픽스처가 없다: {CASES_PATH}"
    saved = json.loads(CASES_PATH.read_text(encoding="utf-8"))
    assert saved == built, (
        "쌍 레이더 산출물이 픽스처와 다르다. 의도한 변경이면 RADAR_GOLDEN_WRITE=1 로 다시 뽑고 "
        "node --test web/assets/js/radar.test.js 도 함께 돌려라(픽스처만 고치면 드리프트가 숨는다)."
    )


def test_pair_fixture_covers_the_five_traps():
    """케이스를 줄이면 잡던 것이 안 잡힌다 — 이름으로 못 박는다."""
    names = [c["name"] for c in json.loads(CASES_PATH.read_text(encoding="utf-8"))["cases"]]
    assert names == ["naver_kakao", "all_zero", "all_tie", "quarter_rounding", "escape"]


# ── 결측 표기: 0 은 어디서나 「등록 없음」 (SP-CMP-3) ────────────────────────


def test_zero_is_never_written_as_a_number():
    assert fmt(0) == "등록 없음"
    assert fmt(None) == "등록 없음"
    assert fmt(3) == "3항목"


def test_readout_says_both_missing_once_not_twice():
    assert _readout("근무환경", 0, 0, 0.65, "가", "나") == "근무환경 — 양쪽 등록 없음 · 평균 0.7"
    assert _readout("휴가", 3, 0, 1.18, "가", "나") == "휴가 — 가 3항목 · 나 등록 없음 · 평균 1.2"


def test_single_radar_uses_the_same_word_for_missing():
    """상세와 비교가 결측을 다르게 부르면 같은 회사가 두 화면에서 다른 말을 한다."""
    svg = radar_svg([0, 1, 2], [0.5, 0.5, 0.5], ["가", "나", "다"], 8, "회사")
    assert "등록 없음" in svg
    assert "0항목" not in svg


# ── 키보드 접근: 히트 아홉 개가 탭으로 닿는다 ──────────────────────────────


def test_pair_hits_are_reachable_and_named():
    svg = radar_pair_svg([1] * 9, [2] * 9, [1.0] * 9, LABELS9, 8, "가", "나")
    assert svg.count('class="rdp-hit" tabindex="0" role="img" aria-label="') == 9
    assert svg.count('class="rdp-hitc"') == 9


def test_single_radar_hits_are_reachable_and_named():
    svg = radar_svg([1, 2, 3], [1.0, 1.0, 1.0], ["가", "나", "다"], 8, "회사")
    assert svg.count('class="rd-hit" tabindex="0" role="img" aria-label="') == 3


def test_pair_band_default_is_guidance_not_a_scoreboard():
    """기본 띠에 「4 대 1」 같은 집계를 두면 항목 수가 점수판이 된다(D-6)."""
    svg = radar_pair_svg([4] * 9, [1] * 9, [1.0] * 9, LABELS9, 8, "가", "나")
    assert BAND_DEFAULT in svg
    for banned in ("우세", "더 낫다", "이김", "승"):
        assert banned not in svg


# ── 기하: 같은 자리·같은 눈금 ────────────────────────────────────────────────


def test_pair_keeps_the_same_geometry_as_the_detail_radar():
    """쌍 그림은 상세 그림을 **새로 발명하지 않는다** — 같은 입력이면 같은 좌표다."""
    counts = [2, 1, 0, 3, 4, 3, 2, 2, 6]
    one = radar_svg(counts, [1.0] * 9, LABELS9, 8, "회사")
    two = radar_pair_svg(counts, [0] * 9, [1.0] * 9, LABELS9, 8, "회사", "상대")
    mine = one.split('class="rd-you" points="')[1].split('"')[0]
    theirs = two.split('class="rdp-a" points="')[1].split('"')[0]
    assert mine == theirs


def test_pair_viewbox_only_grows_right_and_down():
    """오른쪽 +16(「근무환경」 라벨)·아래 +26(판독 띠). 원점·기하는 그대로다."""
    assert VIEWBOX_PAIR == "0 34 416 356"


def test_pair_refuses_mismatched_series():
    with pytest.raises(ValueError):
        radar_pair_svg([1, 2, 3], [1, 2], [0.5, 0.5, 0.5], ["가", "나", "다"], 8)


def test_pair_survives_rmax_zero():
    """전 회사 복지 0(빈 번들)도 죽지 않는다 — 고리·눈금이 빠지고 도형이 중심에 모인다."""
    svg = radar_pair_svg([0] * 9, [0] * 9, [0.0] * 9, LABELS9, 0, "가", "나")
    assert 'class="rdp-ring"' not in svg and 'class="rdp-tick"' not in svg
    assert svg.count('class="rdp-ax"') == 9


def test_tie_markers_are_hollow_rings():
    """꽉 찬 원(r5)이 네모(9×9)를 덮으면 색 외의 두 번째 채널이 겹칠 때마다 사라진다."""
    svg = radar_pair_svg([2, 3, 2], [2, 1, 2], [1.0] * 3, ["가", "나", "다"], 8, "A", "B")
    assert svg.count('class="rdp-da rdp-tie"') == 2
    assert svg.count('class="rdp-da"') == 1


def test_company_names_are_escaped():
    svg = radar_pair_svg([1] * 3, [1] * 3, [1.0] * 3, ["가", "나", "다"], 8, "삼성E&A", "<b>")
    assert "삼성E&amp;A" in svg and "&lt;b&gt;" in svg
    assert "<b>" not in svg.replace("<b", "", 0) or "&lt;b&gt;" in svg
