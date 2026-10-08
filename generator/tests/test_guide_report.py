"""가이드 A편 「복지 공개 현황」 고정판 + `/guide` 목록 계약 (SP-GUIDE-7·8, 2026-10-08, 리드 판정 (86)).

① 스냅숏 sha256 고정 + 리드 실측 기대값 ② `report_facts` 정의(합성 ctx) ③ 페이지가 JSON 만 읽는다
④ 문안의 숫자 = 스냅숏 ⑤ gap 라벨 · 「성과급」 없음 ⑥ /guide 목록 = 글 튜플 · 탭 · sitemap · 무광고 ⑦ 추정치 정의 문구 ⑧ 문안 규율 · nginx.
"""
from __future__ import annotations

import ast
import copy
import hashlib
import json
import re
from pathlib import Path

import pytest

from generator import guide_report as GR
from generator import marks
from generator.config import CFG
from generator.content import about_data as D
from generator.content import guide_report as T
from generator.content import guides as G
from generator.content.nav import GNB_TABS
from generator.context import build_context
from generator.pages import guide_index, guide_report
from generator.pages.company import LENS_BUCKETS
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
EDITION = "2026-10"

# 판을 바꾸려면 새 파일 = 새 판이다 — 이 해시를 고치지 않는다(리드 판정 (86)). 운영 번들 2026-10-08 05:00 UTC 스냅숏.
SNAPSHOT_SHA256 = "730a2ff065b94d3934b6fa2201627dfb04561cb3f0e841cf6ff2d78efeebfa6f"


def _snap() -> dict:
    return GR.load_snapshot(EDITION)


# ── ① 스냅숏 고정 ───────────────────────────────────────────────────────────


def test_snapshot_file_is_pinned():
    raw = GR.snapshot_path(EDITION).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == SNAPSHOT_SHA256, "이 판의 숫자는 바꾸지 않는다 — 바꾸려면 새 파일 = 새 판"
    assert raw.decode("utf-8") == GR.dumps(json.loads(raw)), "직렬화가 결정적이어야 한다(생성 시각 없음 · 끝 줄바꿈 하나)"


def test_snapshot_matches_the_leads_measurements():
    """리드 실측(_LEAD.md · facts_a.json) — 계약 §2 기대값."""
    s = _snap()
    assert (s["edition"], s["edition_ko"], s["asof"]) == ("2026-10", "2026년 10월", "2026-10-08")
    assert (s["N"], s["large"], s["mid"]) == (147, 86, 61)
    assert (s["rows"], s["counted"], s["codes"], s["names"]) == (3179, 3173, 89, 2096)
    assert s["marks"]["legal"] == {"rows": 3, "comps": 3} and s["marks"]["work_edu"] == {"rows": 3, "comps": 3}
    assert s["marks"]["summary"] == {"rows": 34, "comps": 3}
    assert (s["vmin"], s["vmax"]) == ("2026-03-31", "2026-10-05")
    assert s["url_comps"] == 144 and s["child_edu_slug"] == "child-edu"
    assert len(s["half"]) == 17 and len(s["top"]) == 89
    assert [(e["label"], e["comps"], e["pct"]) for e in s["top"][:3]] == [
        ("건강검진", 134, 91.2), ("경조사 지원", 130, 88.4), ("콘도·휴양시설 지원", 124, 84.4)]
    a = s["amount"]
    assert (a["stated"], a["estimated"], a["none"]) == (
        {"n": 64, "pct": 2.0}, {"n": 389, "pct": 12.3}, {"n": 2720, "pct": 85.7})
    assert (a["zero_comps"], a["stated_comps"]) == (38, 39)
    assert a["stated_top"] == {"code": "welfare_point", "label": "복지포인트", "n": 28}
    g = s["gap"]
    assert (g["min_comps"], g["median_large"], g["median_mid"]) == (15, 24, 18)
    assert [e["code"] for e in g["mid_more"]] == ["meal", "snack_bar", "holiday_gift", "excellence_award", "lounge"]
    assert [e["code"] for e in g["large_more"]] == ["childcare", "mental", "medical", "housing_loan", "parenting"]
    assert [(e["large_pct"], e["mid_pct"]) for e in g["mid_more"]] == [
        (55.8, 83.6), (31.4, 57.4), (29.1, 54.1), (23.3, 47.5), (17.4, 32.8)]
    assert [(e["large_pct"], e["mid_pct"]) for e in g["large_more"]] == [
        (84.9, 18.0), (81.4, 19.7), (73.3, 19.7), (69.8, 26.2), (75.6, 34.4)]
    assert s["meal_large_pct"] == 55.8


def test_snapshot_is_internally_consistent():
    s = _snap()
    a = s["amount"]
    assert a["stated"]["n"] + a["estimated"]["n"] + a["none"]["n"] == s["counted"]
    assert s["rows"] - s["marks"]["legal"]["rows"] - s["marks"]["work_edu"]["rows"] == s["counted"]
    assert s["large"] + s["mid"] <= s["N"]
    assert all(e["comps"] * 2 >= s["N"] for e in s["half"]) and {e["code"] for e in s["half"]} == {
        e["code"] for e in s["top"] if e["comps"] * 2 >= s["N"]}
    assert [e["comps"] for e in s["top"]] == sorted((e["comps"] for e in s["top"]), reverse=True)
    for e in s["gap"]["mid_more"] + s["gap"]["large_more"]:
        assert e["comps"] >= s["gap"]["min_comps"]


# ── ② report_facts 정의(합성 ctx) ───────────────────────────────────────────


def _row(cd, nm=None, amt=None, src="none", qual=False, badge_src="scrape_official", verified="2026-05-01"):
    return {"benefit_cd": cd, "benefit_nm": nm or cd, "benefit_amt": amt, "benefit_ctgr_cd": "perks", "badge_cd": "official",
            "amt_source": src, "qual_yn": qual, "qual_desc_ctnt": None, "note_ctnt": None,
            "verified_dtm": verified, "expires_dtm": "2099-12-31", "badge_src_cd": badge_src,
            "badge_src_url_ctnt": None, "sort_order_no": 0}


@pytest.fixture
def synth(fake_bundle, fake_now):
    """대기업 20 · 중견 20 + 유형 없는 1곳. 코드: x_all(전부) · x_large(대기업 20) · x_mid(중견 20) · x_few(대기업 10 — 15곳 문턱 미달) · meal(대기업 10)."""
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    mk = marks.rows()[0]  # 표시 행(법정) — 이 회사의 이 코드 · 이름만 셈에서 빠진다
    comps = []
    for i in range(1, 42):
        eng = mk["comp_eng_nm"] if i == 1 else f"co{i}"
        tp = "large" if i <= 20 else "mid" if i <= 40 else "unlisted"
        rows = [_row("x_all")]
        if tp == "large":
            rows.append(_row("x_large"))
            if i <= 10:
                rows += [_row("x_few"), _row("meal")]
        if tp == "mid":
            rows.append(_row("x_mid"))
        if i == 1:
            rows += [_row("pt", amt=100, src="stated"), _row(mk["benefit_cd"], mk["benefit_nm"], amt=1, src="stated"),
                     _row("sm", badge_src="ai_parse", verified="2030-01-01")]
        if i == 2:
            rows += [_row("pt", amt=50, src="estimated"), _row("q", qual=True)]
        comps.append(dict(base, comp_id=i, comp_eng_nm=eng, comp_nm=eng, aliases=[eng], comp_tp_cd=tp,
                          careers_benefit_url="https://ex.com" if i % 2 else None, benefits=rows))
    b["companies"] = comps
    return build_context(b, now=fake_now)


def test_report_facts_follow_the_definitions(synth):
    f = GR.report_facts(synth, edition="2026-10", asof="2026-10-08")
    assert (f["N"], f["large"], f["mid"]) == (41, 20, 20)
    all_rows = sum(len(c["benefits"]) for c in synth.companies)
    assert f["rows"] == all_rows
    # 표시 행(법정 1행)은 셈 대상에서 빠진다 — 그 코드(parenting)는 `top` 에도 없다
    assert f["counted"] == all_rows - 1 and f["marks"]["legal"] == {"rows": 1, "comps": 1}
    assert marks.rows()[0]["benefit_cd"] not in {e["code"] for e in f["top"]}
    # 비율의 분모는 N(41) · half = 회사 수×2 ≥ N
    by = {e["code"]: e for e in f["top"]}
    assert by["x_all"]["comps"] == 41 and by["x_all"]["pct"] == 100.0
    assert by["x_large"]["comps"] == 20 and by["x_large"]["pct"] == round(20 / 41 * 100, 1)
    assert [e["code"] for e in f["half"]] == [e["code"] for e in f["top"] if e["comps"] * 2 >= 41] == ["x_all"]
    assert [e["comps"] for e in f["top"]] == sorted((e["comps"] for e in f["top"]), reverse=True)
    # 금액: 표시 행의 stated 는 빠지고, 검색 요약(sm)은 금액 없음으로 셈에 든다
    a = f["amount"]
    assert (a["stated"]["n"], a["estimated"]["n"]) == (1, 1) and a["none"]["n"] == f["counted"] - 2
    assert a["stated"]["pct"] == round(1 / f["counted"] * 100, 1)
    assert (a["zero_comps"], a["stated_comps"]) == (41 - 2, 1)
    assert a["stated_top"] == {"code": "pt", "label": "pt", "n": 1}
    assert f["marks"]["summary"] == {"rows": 1, "comps": 1}
    assert f["names"] == len({n for c in synth.companies for n in [b["benefit_nm"] for b in c["benefits"]]})
    assert (f["vmin"], f["vmax"]) == ("2026-05-01", "2026-05-01")  # 검색 요약 행의 요약 기준일(2030)은 확인일이 아니다
    assert f["url_comps"] == 21 and f["meal_large_pct"] == 50.0


def test_gap_selection_uses_the_15_company_floor_and_five_per_side(synth):
    g = GR.report_facts(synth, edition="2026-10", asof="2026-10-08")["gap"]
    assert g["min_comps"] == GR.GAP_MIN_COMPANIES == 15
    large_codes = [e["code"] for e in g["large_more"]]
    mid_codes = [e["code"] for e in g["mid_more"]]
    assert large_codes[0] == "x_large" and mid_codes[0] == "x_mid"  # 대기업 쪽 최상위 · 중견 쪽 최상위
    # x_few(공개 10곳)·meal(10곳)은 차이가 커도 문턱 미달이라 후보가 아니다
    assert "x_few" not in large_codes + mid_codes and "meal" not in large_codes + mid_codes
    # 후보는 x_all · x_large · x_mid 셋뿐 — 한쪽에 최대 다섯, 모자라면 있는 만큼
    assert len(large_codes) == len(mid_codes) == 3 and large_codes == ["x_large", "x_all", "x_mid"]
    assert (g["large_more"][0]["large_pct"], g["large_more"][0]["mid_pct"]) == (100.0, 0.0)
    assert (g["median_large"], g["median_mid"]) == (3, 2)  # 대기업 20곳 중 10곳은 4항목(x_all x_large x_few meal) · 10곳은 2항목 → 3 / 중견 2항목
    per = {c["comp_id"]: len({b["benefit_cd"] for b in marks.countable(c)}) for c in synth.companies}
    import statistics
    assert g["median_large"] == statistics.median(per[i] for i in range(1, 21))
    assert g["median_mid"] == statistics.median(per[i] for i in range(21, 41))


def test_gap_takes_top_five_of_many(fake_bundle, fake_now):
    """후보가 열 개 넘을 때 대기업 쪽 상위 다섯 · 중견 쪽 상위 다섯, 겹치지 않는다."""
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    comps = []
    for i in range(1, 41):
        tp = "large" if i <= 20 else "mid"
        rows = []
        for k in range(1, 13):  # 코드 k: 대기업 쪽은 k 가 클수록 더 많은 회사, 중견은 반대(공개 15곳 이상 유지)
            n_large = 8 + k          # 9~20
            n_mid = 21 - k           # 20~9
            idx = i if tp == "large" else i - 20
            if (tp == "large" and idx <= n_large) or (tp == "mid" and idx <= n_mid):
                rows.append(_row(f"k{k:02d}"))
        comps.append(dict(base, comp_id=i, comp_eng_nm=f"co{i}", comp_nm=f"co{i}", aliases=[f"co{i}"], comp_tp_cd=tp, benefits=rows))
    b["companies"] = comps
    g = GR.report_facts(build_context(b, now=fake_now), edition="2026-10", asof="2026-10-08")["gap"]
    assert [e["code"] for e in g["large_more"]] == ["k12", "k11", "k10", "k09", "k08"]
    assert [e["code"] for e in g["mid_more"]] == ["k01", "k02", "k03", "k04", "k05"]
    assert len(g["large_more"]) == len(g["mid_more"]) == 5
    assert not {e["code"] for e in g["large_more"]} & {e["code"] for e in g["mid_more"]}
    assert all(e["comps"] >= 15 for e in g["large_more"] + g["mid_more"])


def test_median_half_and_zero_handling(fake_bundle, fake_now):
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    mk = lambda i, tp, rows: dict(base, comp_id=i, comp_eng_nm=f"co{i}", comp_nm=f"co{i}", aliases=[f"co{i}"], comp_tp_cd=tp, benefits=rows)  # noqa: E731
    b["companies"] = [mk(1, "large", [_row("a"), _row("b")]), mk(2, "large", [_row("a")]), mk(3, "mid", []), mk(4, "mid", [_row("a")])]
    f = GR.report_facts(build_context(b, now=fake_now), edition="2026-10", asof="2026-10-08")
    assert f["gap"]["median_large"] == 1.5 and f["gap"]["median_mid"] == 0.5  # 짝수 곳 중앙값은 .5, 항목 0개 회사도 센다
    assert [e["code"] for e in f["half"]] == ["a"]  # 3곳×2 ≥ 4
    assert f["amount"]["stated_top"] is None and f["amount"]["zero_comps"] == 4
    assert f["amount"]["stated"] == {"n": 0, "pct": 0.0}
    assert f["gap"]["mid_more"] == [] and f["gap"]["large_more"] == []  # 문턱 15곳 미달


def test_summary_rows_with_amounts_stop_the_snapshot(fake_bundle, fake_now):
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    b["companies"] = [dict(base, comp_id=1, comp_eng_nm="co1", comp_nm="co1", aliases=["co1"], comp_tp_cd="large",
                           benefits=[_row("a", amt=10, src="stated", badge_src="ai_parse")])]
    with pytest.raises(ValueError, match="검색 요약"):
        GR.report_facts(build_context(b, now=fake_now), edition="2026-10", asof="2026-10-08")


# ── ③ 페이지는 JSON 만 읽는다 ───────────────────────────────────────────────


def test_page_does_not_depend_on_the_build_context(fake_bundle, fake_now, synth):
    env = make_env()
    a = guide_report.render(env, build_context(fake_bundle, now=fake_now), CFG)
    b = guide_report.render(env, synth, CFG)
    c = guide_report.render(env, None, CFG)
    assert a.html == b.html == c.html
    from datetime import datetime
    assert a.html == guide_report.render(env, build_context(fake_bundle, now=datetime(2031, 1, 1)), CFG).html


def test_page_numbers_come_from_the_snapshot_file(monkeypatch):
    s = copy.deepcopy(_snap())
    s["N"] = 148
    s["top"][0]["comps"] = 135
    monkeypatch.setattr(guide_report, "facts_for", lambda ed: s)
    html = guide_report.render(make_env(), None, CFG).html
    assert "회사 148곳의 복지 공개 현황" in html and "135곳" in html


# ── ④ 문안의 숫자 = 스냅숏 ──────────────────────────────────────────────────


def _main_text(html: str) -> str:
    main = html[html.index("<main"):html.index("</main>")]
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", main)).replace(" ,", ",")


@pytest.fixture(scope="module")
def page():
    return guide_report.render(make_env(), None, CFG)


def test_rendered_numbers_equal_the_snapshot(page):
    s = _snap()
    t = _main_text(page.html)
    n = lambda v: f"{v:,}"  # noqa: E731
    must = [
        f"회사 {n(s['N'])}곳의 복지 공개 현황 — {s['edition_ko']} 판",
        f"데이터 기준일 2026년 10월 8일 · 회사 {n(s['N'])}곳 · 복지 {n(s['counted'])}건 · 표준 항목 {n(s['codes'])}종",
        f"복지 {n(s['rows'])}건 가운데", f"{n(s['counted'])}건을 2026년 10월 8일 데이터로 셌습니다",
        "법으로 모든 회사에 정해진 제도만 적힌 3건과 회사가 업무를 맡기려고 여는 교육만 적힌 3건을 뺀",
        "가장 흔한 복지 건강검진 147곳 중 134곳(91.2%)", "회사가 금액까지 밝힌 복지 2.0% 3,173건 중 64건",
        "등록된 금액이 하나도 없는 회사 38곳 147곳 중", "절반 넘는 회사가 공개한 복지 17가지",
        "건강검진은 147곳 가운데 134곳이 공개했습니다. 그다음은 경조사 지원(130곳)과 콘도·휴양시설 지원(124곳)입니다.",
        "금액까지 밝힌 복지는 2.0%", "회사가 금액을 직접 밝힌 것은 64건(2.0%)입니다. 389건(12.3%)은", "나머지 2,720건(85.7%)은",
        "등록된 금액이 하나도 없는 회사는 38곳이고, 회사가 밝힌 금액이 하나라도 있는 회사는 39곳입니다",
        "회사가 밝힌 금액이 가장 많이 나온 항목은 복지포인트(28건)입니다",
        "대기업 86곳과 중견기업 61곳으로 나눠", "공개한 회사가 15곳 이상인 항목",
        "공개한 복지 수는 대기업이 중앙값 24개, 중견기업이 18개입니다", "식대를 공개한 대기업이 55.8%라고",
        "항목 3건(3곳)과 업무 교육만 적힌 항목 3건(3곳)은 세지 않았습니다",
        "공식 원문을 찾지 못한 3곳은 검색 AI 요약을 근거로 한 34건이 들어 있습니다. 이 항목들에는 금액이 없습니다.",
        "(2026년 3월 31일 ~ 2026년 10월 5일)", "복지 이름 2,096가지를 표준 항목 89종으로 묶어 셌습니다",
        "147곳은 대기업 86곳과 중견기업 61곳입니다",
    ]
    for m in must:
        assert m in t, m
    # 그림 ①: 17줄 · 값 글자 · 그림 ②: 세 갈래 값 · 그림 ③: 열 줄 값
    assert page.html.count('class="gr-fill"') == 17
    for e in s["half"]:
        assert f"{e['pct']:.1f}% · {e['comps']:,}곳" in t
    for lab, key in (("회사 공식 수치", "stated"), ("추정치", "estimated"), ("금액 미등록", "none")):
        assert f"{lab} {s['amount'][key]['n']:,}건 · {s['amount'][key]['pct']:.1f}%" in t
    assert page.html.count('class="gr-dtrack"') == 10
    for e in s["gap"]["mid_more"] + s["gap"]["large_more"]:
        assert f"{e['label']} 대기업 {e['large_pct']:.1f}% · 중견 {e['mid_pct']:.1f}%" in t
    assert "대기업 86곳 중견기업 61곳" in t  # 범례(점 모양 + 글자)


def test_amount_bar_widths_and_dumbbell_positions_follow_the_snapshot(page):
    s = _snap()
    for k in ("stated", "estimated", "none"):
        assert f'style="width:{s["amount"][k]["pct"]}%"' in page.html
    e = s["gap"]["mid_more"][0]
    assert f'style="left:{e["large_pct"]}%"' in page.html and f'style="left:{e["mid_pct"]}%"' in page.html


def test_labels_come_from_the_canonical_sources(page):
    lens = {k: label for k, label, _ in LENS_BUCKETS}
    t = _main_text(page.html)
    assert lens["stated"] in t and lens["est"] in t and D.KIND_NONE_LABEL in t
    s = _snap()
    from generator import benefit_rules
    titles = {c: p["title"] for c, p in benefit_rules.load_pages().items()}
    for e in s["top"]:  # 항목 페이지가 있는 코드의 라벨은 그 제목이다
        if e["code"] in titles:
            assert e["label"] == titles[e["code"]]


# ── ⑤ gap 문장 ──────────────────────────────────────────────────────────────


def test_gap_sentence_uses_the_snapshot_labels_and_not_the_dropped_item(page):
    s = _snap()
    t = _main_text(page.html)
    assert "성과급" not in t and "incentive" not in page.html
    mid = T.LABEL_JOIN.join(e["label"] for e in s["gap"]["mid_more"])
    large = T.LABEL_JOIN.join(e["label"] for e in s["gap"]["large_more"])
    assert f"중견기업은 {mid}처럼 날마다, 해마다 손에 잡히는 복지를 더 자주 공개했습니다." in t
    assert f"대기업은 {large}처럼 제도나 시설을 갖춰야 하는 복지를 더 자주 공개했습니다." in t
    assert "중견기업은 더 적게 공개하면서도 위 다섯 항목은 더 자주 적었습니다." in t
    # 해설 문장이 묘사하는 항목이 스냅숏에서 바뀌면 문안 판정이 필요하다 — 조용히 틀린 묘사를 싣지 않는다
    assert [e["code"] for e in s["gap"]["mid_more"]] == ["meal", "snack_bar", "holiday_gift", "excellence_award", "lounge"]
    assert [e["code"] for e in s["gap"]["large_more"]] == ["childcare", "mental", "medical", "housing_loan", "parenting"]


def test_links_only_to_generated_item_pages():
    env = make_env()
    none = guide_report.render(env, None, CFG).html
    assert "/benefit/" not in none and "자녀 학자금 원문 비교 →" not in none
    links = {"health_check": "/benefit/health-check", "child_edu": "/benefit/child-edu"}
    linked = guide_report.render(env, None, CFG, benefit_links=links).html
    assert '<a href="/benefit/health-check">건강검진</a>' in linked
    assert '<a href="/benefit/child-edu">자녀 학자금 원문 비교 →</a>' in linked
    assert linked.count('href="/benefit/') == 3  # 막대 둘(건강검진 · 자녀 학자금) + 본문 링크 하나
    assert f'<a href="{G.DATA_ROUTE}">금액 표시 기준 →</a>' in linked and f'<a href="{G.DATA_ROUTE}">데이터는 어떻게 만드나 →</a>' in linked


# ── ⑥ /guide 목록 · 탭 · sitemap · 무광고 ───────────────────────────────────


def test_report_page_is_active_tab_adless_and_indexable(page):
    s = _snap()
    assert page.path == "guide/report-2026-10.html" and page.url == CFG.site_origin + "/guide/report-2026-10" and page.in_sitemap
    assert page.title == f"회사 {s['N']}곳의 복지 공개 현황 — {s['edition_ko']} 판 | {CFG.site_name}"
    assert page.description.endswith(". 2026년 10월 판.") and len(page.description) <= CFG.desc_max
    assert page.description.startswith("회사들이 스스로 공개한 복지를 모아 같은 기준으로 다시 나눠 보면")
    assert '<a href="/guide" class="gnb-link" aria-current="page">가이드</a>' in page.html and page.html.count('aria-current="page"') == 1
    assert '<body data-page-type="policy">' in page.html and "data-ad-position" not in page.html
    assert f'<link rel="canonical" href="{page.url}">' in page.html and 'property="og:url"' in page.html
    assert '<p class="guide-crumb"><a href="/guide">가이드</a> › 복지 리포트</p>' in page.html
    assert "<script" not in page.html[page.html.index("<main"):page.html.index("</main>")]  # 그림은 CSS 뿐


def test_guide_index_lists_the_article_tuple_newest_first():
    p = guide_index.render(make_env(), None, CFG)
    assert p.path == "guide.html" and p.url == CFG.site_origin + "/guide" and p.in_sitemap
    assert p.title == f"가이드 | {CFG.site_name}"
    cards = guide_index.cards()
    assert [c["href"] for c in cards] == [G.report_route(e) for e in G.REPORT_EDITIONS] + [G.DATA_ROUTE]
    assert cards[0]["title"] == "회사 147곳의 복지 공개 현황 — 2026년 10월 판"
    assert cards[0]["desc"] == "2026년 10월 판 · 회사 147곳의 복지를 공개 비율 · 금액 공개 · 회사 규모별로 나눠 봅니다."
    assert cards[-1] == {"href": "/about/data", "title": D.H1, "desc": "어디서 가져오고, 어떻게 나누고, 언제 다시 확인하는지 적어 둡니다."}
    t = _main_text(p.html)
    assert "<h1>가이드</h1>" in p.html and "잡초위키 데이터로만 쓸 수 있는 글을 모아 둡니다." in t
    assert p.html.count('class="guide-card"') == len(cards)
    assert '<a href="/guide" class="gnb-link" aria-current="page">가이드</a>' in p.html and "data-ad-position" not in p.html
    assert '<body data-page-type="policy">' in p.html


def test_every_edition_has_a_snapshot_and_the_tab_points_at_the_list():
    assert G.LIST_ROUTE == "/guide" and ("가이드", "/guide") in GNB_TABS and ("가이드", "/about/data") not in GNB_TABS
    for ed in G.REPORT_EDITIONS:
        assert GR.snapshot_path(ed).is_file()
        assert GR.load_snapshot(ed)["edition"] == ed
    from generator.pages import about_data
    assert about_data.GUIDE_LIST_ROUTE == G.LIST_ROUTE


def test_pipeline_emits_pages_and_sitemap_entries(fake_bundle, fake_combinations_path, tmp_path):
    from generator import build as build_module
    out = tmp_path / "dist"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-10-08") == 0
    assert (out / "guide.html").is_file() and (out / "guide" / "report-2026-10.html").is_file()
    sm = (out / "sitemap.xml").read_text(encoding="utf-8")
    assert f"<loc>{CFG.site_origin}/guide</loc>" in sm and f"<loc>{CFG.site_origin}/guide/report-2026-10</loc>" in sm


# ── ⑦ 추정치 정의 — D편 · 대문과 같은 뜻 ────────────────────────────────────


def test_estimate_definition_is_the_same_meaning_as_d_and_the_lens(page):
    t = _main_text(page.html)
    assert "공개된 조건으로 셀 수 있으면 그 조건으로, 셀 수 없으면 같은 종류 제도의 기준 금액으로 셌습니다" in t
    est = dict((k, d) for k, _, d in LENS_BUCKETS)["est"]
    d_est = D.KIND_ESTIMATED
    for needle in ("셀 수 있으면", "셀 수 없으면", "기준 금액"):
        assert needle in est and needle in d_est and needle in t
    assert "잡초위키가 붙인 어림값" in est and "잡초위키가 붙인 어림값" in t


# ── ⑧ 문안 규율 · nginx ─────────────────────────────────────────────────────

_QUANTIFIERS = ("대부분", "많은", "보통", "거의")


def test_human_sentences_carry_no_numbers_or_quantifiers():
    for mod in ("guide_report", "guides"):
        tree = ast.parse((REPO_ROOT / "generator" / "content" / f"{mod}.py").read_text(encoding="utf-8"))
        strings = [n.value for n in ast.walk(tree) if isinstance(n, ast.Constant) and isinstance(n.value, str)]
        strings = [x for x in strings if not x.startswith("generator/") and not re.fullmatch(r"\d{4}-\d{2}", x)]  # 모듈 설명 · 판 이름
        assert strings
        for x in strings:
            stripped = re.sub(r"\{[^}]*\}", "", x)  # 자리표시는 숫자 칸이다
            assert not re.search(r"\d", stripped), f"사람 문장에 숫자가 박혔다: {x!r}"
            assert not any(q in x for q in _QUANTIFIERS), f"수량어: {x!r}"


def test_rendered_page_has_no_quantifiers(page):
    assert not any(q in _main_text(page.html) for q in _QUANTIFIERS)


def test_nginx_has_the_guide_locations_and_no_direct_html():
    conf = (REPO_ROOT / "infra" / "nginx" / "loupit.conf").read_text(encoding="utf-8")
    assert re.search(r"location = /guide\s+\{[^}]*try_files /guide\.html =404;", conf)
    m = re.search(r"location \^~ /guide/\s+\{[^}]*\}", conf)
    assert m and "try_files $uri.html =404;" in m.group(0)  # `/guide/` → `/guide/.html` 404, `/guide/x.html` → `x.html.html` 404
    assert "loupit-security.conf" in m.group(0) and 'Cache-Control "public, max-age=300"' in m.group(0)
