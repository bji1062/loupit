"""가이드 B편 「복지를 연봉에 더해 보는 법」 `/guide/total-compensation` 계약 (SP-GUIDE-10, 2026-10-13, 리드 판정 (90)(91)).

① 렌더 HTML 의 숫자 = 예시 JSON(`generator/data/guide/total-compensation.json`) 값 ② 막대 합 = 총 차이 ③ 상수 = calc.js · 만료 규칙
④ content 모듈에 숫자 리터럴 · 수량어 없음 ⑤ 금액 종류 라벨 = 사이트 정본 ⑥ 계산기 화면 낱말 = 계산기 JS 에 글자 그대로
⑦ /guide 카드 순서 B → A → D · 탭 · sitemap · 무광고 · canonical ⑧ 빌드 시각 · ctx 와 무관 ⑨ 결론 방향이 어긋나면 BuildError ⑩ 계산기 푸터 「계산 방식」 링크.
JSON 의 `output` · `K` 가 지금 calc.js 와 같은지는 프런트 테스트 `web/test/guide-total-comp.test.js` 가 지킨다.
"""
from __future__ import annotations

import ast
import copy
import json
import re
from datetime import datetime
from pathlib import Path

import pytest

from generator.config import CFG
from generator.content import about_data as D
from generator.content import guide_total_comp as T
from generator.content import guides as G
from generator.content.policy import _RETENTION
from generator.context import build_context
from generator.pages import about_data, guide_index, guide_total_comp as P
from generator.pages.company import LENS_BUCKETS
from generator.render import make_env
from generator.slug import BuildError

REPO_ROOT = Path(__file__).resolve().parents[2]
JS_DIR = REPO_ROOT / "web" / "assets" / "js"
MINUS = "−"


def _doc() -> dict:
    return json.loads(G.TOTAL_DATA_PATH.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def page():
    return P.render(make_env())


def _main_text(html: str) -> str:
    main = html[html.index("<main"):html.index("</main>")]
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", main))


# ── ① 숫자 = 예시 JSON ───────────────────────────────────────────────────────


def test_example_json_matches_the_leads_measurements():
    """리드 실측(_IMPLEMENT-B.md §2) — 계산기 출력이 바뀌면 프런트 테스트가 먼저 실패한다."""
    o = _doc()["output"]
    a, b, d = o["a"], o["b"], o["deltas"]
    assert (a["sal"], a["net"], a["ot"], a["total"], a["band"], a["hours"], a["hourly"]) == (5000, 350, 777, 6127, 55, 45, 26184)
    assert (b["sal"], b["net"], b["ot"], b["total"], b["band"], b["hours"], b["hourly"]) == (5500, 100, 0, 5600, 20, 50, 21538)
    assert (d["salMid"], d["benDiff"], d["otDiff"], d["totalDiff"]) == (500, -250, -777, -527)
    assert o["range"] == [-602, -452] and o["monthly"] == -44 and round(o["hourlyPct"], 4) == -0.1774 and o["tier"] == "a"
    assert (o["breakeven"]["full"]["sal"], round(o["breakeven"]["full"]["rate"] * 100, 1)) == (6027, 20.5)
    assert (o["breakeven"]["noBenefit"]["sal"], round(o["breakeven"]["noBenefit"]["rate"] * 100, 1)) == (5777, 15.5)
    assert o["flip"] == {"key": "b_wage_flip", "result": "flip", "totalDiff": 1182}
    k = _doc()["K"]
    assert (k["MONTHLY_STD_HRS"], k["OT_MULT"], k["WEEKS_PER_MONTH"], k["WEEKS_PER_YEAR"], k["LEGAL_WEEK_HRS"], k["COMMUTE_WORKDAYS"]) == (209, 1.5, 4.33, 52, 40, 240)
    assert (k["BAND_BASE"]["stated"], k["BAND_BASE"]["estimated"], k["BAND_EXPIRE"]) == (0.05, 0.2, 0.15)


def test_rendered_page_carries_the_example_numbers(page):
    t = _main_text(page.html)
    for s in ("5,000만원", "5,500만원", "6,127만원", "5,600만원", "오차 ±55만원", "오차 ±20만원", "26,184원", "21,538원", "777만원",
              "연 527만원 줄어듭니다", f"오차 범위 {MINUS}602 ~ {MINUS}452만원", f"한 달로 치면 {MINUS}44만원", f"시간당 총보상 {MINUS}18%",
              "6,027만원(20.5% 인상)", "5,777만원(15.5% 인상)", "연 1,182만원 더 많아집니다", "이직 후보가 10% 올린 5,500만원"):
        assert s in t, s


_NUM_RE = re.compile(r"\d[\d,]*(?:\.\d+)?")


def test_every_number_on_the_page_comes_from_the_json_or_a_known_source(page):
    """본문의 모든 숫자가 JSON · 상수 · 정본에서 나온 값이다 — 손으로 박은 숫자가 없다."""
    doc = _doc()
    v = P.values(doc)
    allowed = {str(x) for x in v.values() if re.fullmatch(r"[\d,.]+", str(x))}
    o = doc["output"]
    for side in ("a", "b"):
        allowed |= {P._n(x) for x in o[side].values()}
    allowed |= {P._n(abs(x)) for x in o["deltas"].values() if isinstance(x, int)}
    allowed |= {str(h) for s in doc["input"]["work"].values() for h in [s.get("hours")] if h}
    allowed |= {P._n(x["amount"]) for s in doc["input"]["benefits"].values() for x in s if x["amount"]}
    allowed |= {P._n(abs(x)) for x in o["range"]} | {P._n(abs(o["monthly"])), str(round(abs(o["hourlyPct"]) * 100))}  # 부호 뗀 값(−602 · −44 · −18%)
    allowed |= {"0"}  # 야근수당 포괄 칸 「0원」 — 입력(포괄)에서 나온 값이고 빌드가 ot == 0 을 확인한다
    allowed |= {str(i) for i in range(1, 8)}  # 계산 순서 번호(ol)는 글자로 안 나오지만 안전하게
    t = _main_text(page.html)
    t = t.replace("4대 보험료", "")  # 고유 낱말
    for n in _NUM_RE.findall(t):
        assert n.rstrip(",.") in allowed, f"출처 없는 숫자 {n!r}"


# ── ② 막대 합 = 총 차이 ──────────────────────────────────────────────────────


def test_bars_sum_equals_total_diff():
    v = P.build_view(_doc())
    vals = [int(r["val"].replace(MINUS, "-").replace(",", "")) for r in v["bars"]["rows"]]
    assert vals[0] + vals[1] + vals[2] == vals[3] == _doc()["output"]["deltas"]["totalDiff"]
    assert [r["dir"] for r in v["bars"]["rows"]] == ["up", "down", "down", "down"]
    assert all(0 <= r["left"] <= 50 and 0 < r["w"] <= 50 for r in v["bars"]["rows"])  # 0 기준선은 가운데(50%)


def test_table_benefit_sums_equal_the_calculators_net():
    doc = _doc()
    for s in ("a", "b"):
        assert sum(x["amount"] or 0 for x in doc["input"]["benefits"][s]) == doc["output"][s]["net"]
        assert doc["output"][s]["sal"] + doc["output"][s]["net"] + doc["output"][s]["ot"] == doc["output"][s]["total"]


# ── ③ 상수 = 코드 정본 ───────────────────────────────────────────────────────


def _calc_js() -> str:
    return (JS_DIR / "calc.js").read_text(encoding="utf-8")


def _const(name: str) -> float:
    m = re.search(rf"export const {name}\s*=\s*([\d.]+)", _calc_js())
    assert m, f"calc.js 의 {name} 을 못 찾았다 — 이 테스트의 정규식을 함께 고쳐라"
    return float(m.group(1))


def test_constants_match_calc_js():
    k = _doc()["K"]
    for name in ("MONTHLY_STD_HRS", "OT_MULT", "WEEKS_PER_MONTH", "WEEKS_PER_YEAR", "LEGAL_WEEK_HRS", "COMMUTE_WORKDAYS", "BAND_EXPIRE"):
        assert _const(name) == k[name], name
    base = re.search(r"export const BAND_BASE\s*=\s*\{\s*stated:\s*([\d.]+),\s*estimated:\s*([\d.]+)", _calc_js())
    assert base and (float(base.group(1)), float(base.group(2))) == (k["BAND_BASE"]["stated"], k["BAND_BASE"]["estimated"])
    near = re.search(r"nearBandMult:\s*([\d.]+),\s*nearTotalPct:\s*([\d.]+)", _calc_js())
    assert near and (float(near.group(1)), float(near.group(2))) == (k["AXIS_THRESHOLDS"]["nearBandMult"], k["AXIS_THRESHOLDS"]["nearTotalPct"])
    # D편이 바로 쓰는 상수와도 같다(두 글이 같은 오차 범위를 말한다)
    assert (round(k["BAND_BASE"]["stated"] * 100), round(k["BAND_BASE"]["estimated"] * 100), round(k["BAND_EXPIRE"] * 100)) == (
        about_data.BAND_STATED_PCT, about_data.BAND_ESTIMATED_PCT, about_data.BAND_EXPIRE_PP)


def test_expire_months_and_retention_days_come_from_their_sources():
    src = (REPO_ROOT / "server" / "services" / "benefit_edit.py").read_text(encoding="utf-8")
    assert f"INTERVAL {about_data.EXPIRE_MONTHS} MONTH" in src
    v = P.values(_doc())
    assert v["exp_months"] == about_data.EXPIRE_MONTHS and v["compare_days"] == _RETENTION["compare_days"]
    cfg = (REPO_ROOT / "server" / "config.py").read_text(encoding="utf-8")
    assert f"compare_log_retention_days: int = {_RETENTION['compare_days']}" in cfg


def test_threshold_and_guard_rules_the_text_describes_exist_in_calc_js():
    js = _calc_js()
    assert "nearKind" in js and "Math.sign(guardD) !== Math.sign(diff)" in js and "Math.abs(diff) <= bd" in js  # 판정 순서(가드 → 오차 범위 → 가까움)
    assert "pairs.mixed" in js and "CAPPED_RE = /최대|한도|상한/" in js
    assert "wage !== 'separate'" in js  # 야근수당은 비포괄만


# ── ④ 문안 규율 ──────────────────────────────────────────────────────────────
# 사람 문장에 숫자 · 수량어 없음 (D · A 와 같은 검사). 숫자 예외는 숫자가 아닌 낱말 · 식의 일부뿐이다:
#   「4대 보험료」(고유 낱말) · 「(1 + 인상률)」(식) · 단독 「0」(없음 — 야근수당 0 · 0으로 계산 · 0원). 화면 인용 낱말은 SCREEN_LABELS 에만 있고 문장은 {lbl_…} 로 받는다.

_QUANTIFIERS = ("대부분", "많은", "보통", "거의")
_DIGIT_EXEMPT = ("4대 보험료", "(1 + 인상률)")


def _content_strings() -> list[str]:
    tree = ast.parse((REPO_ROOT / "generator" / "content" / "guide_total_comp.py").read_text(encoding="utf-8"))
    # SCREEN_LABELS 딕셔너리 값은 건너뛴다(화면 인용 낱말 — 「거의 같습니다」)
    skip: set[int] = set()
    for n in ast.walk(tree):
        if isinstance(n, ast.Assign) and any(getattr(t, "id", "") == "SCREEN_LABELS" for t in n.targets):
            skip |= {id(c) for c in ast.walk(n.value)}
    return [n.value for n in ast.walk(tree) if isinstance(n, ast.Constant) and isinstance(n.value, str) and id(n) not in skip]


def test_human_sentences_carry_no_numbers_or_quantifiers():
    strings = [s for s in _content_strings() if not s.startswith("generator/")]
    assert len(strings) > 30
    for s in strings:
        stripped = re.sub(r"\{[^}]*\}", "", s)  # 자리표시는 숫자 칸이다
        for ex in _DIGIT_EXEMPT:
            stripped = stripped.replace(ex, "")
        stripped = re.sub(r"(?<![\d.,])0(?![\d.,])", "", stripped)
        assert not re.search(r"\d", stripped), f"사람 문장에 숫자가 박혔다: {s!r}"
        for q in _QUANTIFIERS:
            assert not re.search(q + r"(?!지)", s), f"수량어: {s!r}"  # 「많은지」(어느 쪽이 많은지)는 서술어라 수량어가 아니다


def test_rendered_page_has_no_quantifiers_outside_screen_labels(page):
    t = _main_text(page.html)
    for lab in T.SCREEN_LABELS.values():
        t = t.replace(lab, "")
    for q in _QUANTIFIERS:
        assert not re.search(q + r"(?!지)", t), q
    assert all(q not in "".join(T.SCREEN_LABELS[k] for k in T.SCREEN_LABELS if k != "near_small") for q in _QUANTIFIERS)  # 화면 인용은 「거의 같습니다」 하나뿐


# ── ⑤ 라벨 = 사이트 정본 ─────────────────────────────────────────────────────


def test_amount_kind_labels_come_from_the_canonical_sources(page):
    lens = {k: label for k, label, _ in LENS_BUCKETS}
    v = P.values(_doc())
    assert (v["stated_label"], v["est_label"], v["none_label"]) == (lens["stated"], lens["est"], D.KIND_NONE_LABEL) == ("회사 공식 수치", "추정치", "금액 미등록")
    t = _main_text(page.html)
    assert "복지포인트 100만원 · 회사 공식 수치" in t and "자녀 학자금 250만원 · 추정치" in t and "복지포인트 100만원 · 추정치" in t
    assert "금액 미등록 복지" in t
    assert "회사 공식 수치는 ±5%, 추정치는 ±20%" in t  # 조사 은/는 — 받침 없는 「치」
    calc_js = _calc_js()
    assert D.KIND_NONE_LABEL in calc_js
    assert "회사가 밝힌 금액" not in t and "어림한 금액" not in t and "시간당 가치" not in t  # FACTCHECK §8 — 옛 낱말


# ── ⑥ 계산기 화면 낱말 = 계산기 JS 에 글자 그대로 ─────────────────────────────


def test_screen_labels_exist_verbatim_in_the_calculator_ui():
    corpus = "\n".join(p.read_text(encoding="utf-8") for p in sorted(JS_DIR.glob("*.js")) if not p.name.endswith(".test.js"))
    corpus += (REPO_ROOT / "web" / "compare" / "index.html").read_text(encoding="utf-8")
    for key, label in T.SCREEN_LABELS.items():
        assert label in corpus, f"계산기 화면에 「{label}」({key})가 없다 — 낱말이 바뀌었다면 글을 함께 고쳐라"


def test_table_names_and_chips_match_the_calculator():
    rc = (JS_DIR / "report-calc.js").read_text(encoding="utf-8")
    assert f"'{T.COL_A}'" in rc and f"'{T.COL_B}'" in rc  # 기본 회사 이름(makeCtx)
    ui = (JS_DIR / "ui.js").read_text(encoding="utf-8")
    assert "따로 받음(비포괄)" in ui and "연봉에 포함(포괄)" in ui and T.CELL_OT_SEPARATE.startswith("따로 받음(비포괄)") and T.CELL_OT_INCLUSIVE.startswith("연봉에 포함(포괄)")
    assert "−" in rc  # 음수는 U+2212 — 페이지의 MINUS 와 같은 글자
    assert P.MINUS == MINUS


# ── ⑦ 페이지 · /guide 카드 · 탭 · sitemap · 무광고 ────────────────────────────


def test_page_is_active_tab_adless_and_indexable(page):
    assert page.path == "guide/total-compensation.html" and page.url == CFG.site_origin + "/guide/total-compensation" and page.in_sitemap
    assert page.title == f"복지를 연봉에 더해 보는 법 | {CFG.site_name}"
    assert page.description == "연봉이 오르는 이직이 늘 이득은 아닙니다. 이직 계산기가 무엇을 더하고 빼는지 적어 둡니다." and len(page.description) <= CFG.desc_max
    assert '<a href="/guide" class="gnb-link" aria-current="page">가이드</a>' in page.html and page.html.count('aria-current="page"') == 1
    assert '<body data-page-type="policy">' in page.html and "data-ad-position" not in page.html
    assert f'<link rel="canonical" href="{page.url}">' in page.html and 'property="og:url"' in page.html
    assert '<p class="guide-crumb"><a href="/guide">가이드</a> › 이직 계산</p>' in page.html
    assert "<h1>복지를 연봉에 더해 보는 법</h1>" in page.html
    assert "<script" not in page.html[page.html.index("<main"):page.html.index("</main>")]  # 표 · 막대는 HTML/CSS 뿐
    assert f'href="{G.COMPARE_ROUTE}"' in page.html and 'href="/privacy"' in page.html and 'href="/about/data"' in page.html


def test_guide_index_lists_b_first_then_a_then_d():
    cards = guide_index.cards()
    assert [c["href"] for c in cards] == ["/guide/total-compensation"] + [G.report_route(e) for e in G.REPORT_EDITIONS] + [G.DATA_ROUTE]
    assert cards[0] == {"href": "/guide/total-compensation", "title": T.H1, "desc": T.CARD_DESC}
    assert cards[0]["desc"] == "연봉이 오르는 이직이 늘 이득은 아닙니다. 이직 계산기가 무엇을 더하고 빼는지 예시로 적어 둡니다."
    html = guide_index.render(make_env(), None, CFG).html
    assert html.index("/guide/total-compensation") < html.index("/guide/report-2026-10") < html.index("/about/data")


def test_pipeline_emits_page_and_sitemap_entry(fake_bundle, fake_combinations_path, tmp_path):
    from generator import build as build_module
    out = tmp_path / "dist"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-10-13") == 0
    assert (out / "guide" / "total-compensation.html").is_file()
    assert f"<loc>{CFG.site_origin}/guide/total-compensation</loc>" in (out / "sitemap.xml").read_text(encoding="utf-8")


# ── ⑧ 빌드 시각 · ctx 와 무관 ────────────────────────────────────────────────


def test_output_does_not_depend_on_build_time_or_ctx(fake_bundle, fake_now):
    env = make_env()
    a = P.render(env, build_context(fake_bundle, now=fake_now), CFG)
    b = P.render(env, build_context(fake_bundle, now=datetime(2031, 1, 1)), CFG)
    c = P.render(env)
    assert a.html == b.html == c.html


# ── ⑨ 결론 방향이 어긋나면 빌드가 멈춘다 ────────────────────────────────────


def _mutate(fn) -> dict:
    doc = copy.deepcopy(_doc())
    fn(doc["output"])
    return doc


@pytest.mark.parametrize("mutate", [
    lambda o: o["deltas"].update(salMid=-1),
    lambda o: o["deltas"].update(totalDiff=10),
    lambda o: o.update(range=[-5, 5]),
    lambda o: o.update(tier="b"),
    lambda o: o["flip"].update(result="same"),
    lambda o: o["flip"].update(totalDiff=-1),
    lambda o: o["breakeven"]["full"].update(bound="low"),
    lambda o: o["b"].update(sal=9999),
])
def test_conclusion_direction_change_stops_the_build(mutate):
    with pytest.raises(BuildError, match="예시 결론이 바뀌었다"):
        P.build_view(_mutate(mutate))


def test_identity_break_stops_the_build():
    with pytest.raises(BuildError):
        P.build_view(_mutate(lambda o: o["deltas"].update(otDiff=-700)))


# ── ⑩ 계산기 푸터 「계산 방식」 링크 ─────────────────────────────────────────


def test_calculator_footer_links_to_the_article_after_data_guide():
    html = (REPO_ROOT / "web" / "compare" / "index.html").read_text(encoding="utf-8")
    nav = re.search(r'<nav aria-label="사이트 탐색"[^>]*>(.*?)</nav>', html, re.S).group(1)
    links = re.findall(r'<a href="([^"]+)">([^<]*)</a>', nav)
    assert links[-2:] == [("/about/data", "데이터 안내"), ("/guide/total-compensation", "계산 방식")]
    # 생성 페이지 공통 푸터는 건드리지 않는다(전 페이지 lastmod 가 한꺼번에 갱신되는 것을 피함)
    partial = (REPO_ROOT / "generator" / "templates" / "partials" / "_footer.html").read_text(encoding="utf-8")
    assert "total-compensation" not in partial
