"""데이터 안내 `/about/data` 계약 (가이드 D편, SP-GUIDE, 2026-10-06) — `generator/pages/about_data.py`.

숫자 정의 하나하나 · 0 처리 · 코드 정본과의 대조(calc.js 밴드 · 만료 18개월) · 빌드 날짜 무관 · 문안 규율 ·
대문 집계와 같은 값 · 탭 활성 · sitemap · 무광고.
"""
from __future__ import annotations

import ast
import copy
import re
from datetime import datetime
from pathlib import Path

import pytest

from generator import marks
from generator.config import CFG
from generator.content import about_data as T
from generator.context import build_context
from generator.pages import about_data, home
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER, LENS_BUCKETS
from generator.render import make_env
from generator.slug import BuildError

REPO_ROOT = Path(__file__).resolve().parents[2]


def _row(cd="meal", nm="식대", amt=100, src="stated", qual=False, ctgr="perks", verified="2026-05-01",
         badge_src="scrape_official", badge="official"):
    return {"benefit_cd": cd, "benefit_nm": nm, "benefit_amt": amt, "benefit_ctgr_cd": ctgr, "badge_cd": badge,
            "amt_source": src, "qual_yn": qual, "qual_desc_ctnt": None, "note_ctnt": None,
            "verified_dtm": verified, "expires_dtm": "2099-12-31", "badge_src_cd": badge_src,
            "badge_src_url_ctnt": None, "sort_order_no": 0}


def _bundle(fake_bundle, companies):
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    b["companies"] = [dict(base, comp_id=i + 1, comp_eng_nm=eng, comp_nm=eng, aliases=[eng], **extra, benefits=rows)
                      for i, (eng, extra, rows) in enumerate(companies)]
    return b


@pytest.fixture
def synth(fake_bundle, fake_now):
    """회사 3곳 — 숫자 정의를 하나씩 겨냥한 합성 데이터."""
    b = _bundle(fake_bundle, [
        ("aa", {"careers_benefit_url": "https://ex.com/aa"}, [
            _row("meal", "식대", 100, "stated", verified="2026-03-31"),
            _row("resort", "휴양소 지원", 50, "estimated", verified="2026-10-05"),
            _row("health_check", "건강검진", None, "estimated", qual=True, ctgr="health"),
        ]),
        ("bb", {"careers_benefit_url": "https://ex.com/bb"}, [
            _row("resort", "휴양소 지원", 50, "estimated"),
            _row("resort", "PC-OFF", None, "none"),
            _row("resort", "pc-off", None, "none"),
            _row("meal", "식대", 100, "estimated"),
        ]),
        ("cc", {"careers_benefit_url": None}, [
            _row("resort", "콘도", None, "none", badge_src="ai_parse", verified="2030-01-01"),
        ]),
    ])
    return build_context(b, now=fake_now)


# ── ① 숫자 정의 하나하나 ──────────────────────────────────────────────────────


def test_counts_follow_the_definitions(synth):
    n = about_data.counts(synth)
    assert n["N"] == 3
    assert n["url_comp"] == 2
    assert (n["summary_comp"], n["summary_rows"]) == (1, 1)
    assert n["summary_all_no_amount"] is True
    assert n["rows"] == 8
    assert (n["st"], n["es"], n["no"]) == (1, 3, 4)  # none = 정성 1 + 금액 빈 행 3
    assert n["rows"] == n["st"] + n["es"] + n["no"]
    assert n["codes"] == 3  # meal · resort · health_check
    assert n["names"] == 5  # 식대 · 휴양소 지원 · 건강검진 · pc-off(대소문자 무시로 한 이름) · 콘도
    assert (n["resort_comp"], n["resort_names"]) == (3, 3)
    # 빈도순(같으면 이름순) — 2회 · 2회(대소문자만 다른 PC-OFF 둘) · 1회. 칩은 처음 본 표기를 쓴다.
    assert n["resort_chips"] == ["PC-OFF", "휴양소 지원", "콘도"]
    assert n["cats"] == len(CATEGORY_ORDER) == 9
    assert n["asof"] == "2026-10-05"  # 확인일 범위와 같은 집합(검색 요약 행의 2030 요약 기준일은 뺀다)의 최댓값 — 빌드 날짜가 아니다
    assert (n["qual"], n["blank"]) == (1, 3) and n["no"] == n["qual"] + n["blank"]
    assert (n["vmin"], n["vmax"]) == ("2026-03-31", "2026-10-05")  # 확인일 범위는 검색 요약 행의 요약 기준일을 뺀다
    assert (n["fin"], n["emp"]) == (0, 0) and n["fy_min"] is None


def test_fin_emp_and_fiscal_range_follow_company_page_rule(fake_bundle, fake_now, fake_finance, fake_employ):
    n = about_data.counts(build_context(fake_bundle, now=fake_now, finance=fake_finance, employ=fake_employ))
    assert (n["fin"], n["emp"]) == (2, 2)  # 삼성전자 · 네이버 (SK하이닉스는 키가 없다)
    assert (n["fy_min"], n["fy_max"]) == (2021, 2025)


def test_marked_rows_are_counted_from_the_registry(fake_bundle, fake_now):
    row = marks.rows()[0]
    b = _bundle(fake_bundle, [(row["comp_eng_nm"], {}, [_row(row["benefit_cd"], row["benefit_nm"])])])
    n = about_data.counts(build_context(b, now=fake_now))
    assert n[row["kind"]] == 1 and n["legal"] + n["work_edu"] == 1


def test_native_count():
    assert about_data.native_count(9) == "아홉" and about_data.native_count(3) == "세"
    assert about_data.native_count(11) == "11"


# ── ② 0 처리 — 문장째 뺀다 ───────────────────────────────────────────────────


def _text(ctx) -> str:
    v = about_data.build_view(ctx)
    return re.sub(r"\s+", " ", str(v))


def test_zero_summary_drops_the_summary_sentences(fake_bundle, fake_now):
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": "https://ex.com"}, [_row()])])
    s = _text(build_context(b, now=fake_now))
    assert "검색 AI 요약" not in s and "금액을 넣지 않습니다" not in s


def test_zero_marks_drop_the_clause_or_the_sentence(fake_bundle, fake_now):
    b = _bundle(fake_bundle, [("aa", {}, [_row()])])
    v = about_data.build_view(build_context(b, now=fake_now))
    assert "표시를 달고" not in v["group_b"] and "「법정」" not in v["group_b"]
    row = next(r for r in marks.rows() if r["kind"] == "legal")
    b = _bundle(fake_bundle, [(row["comp_eng_nm"], {}, [_row(row["benefit_cd"], row["benefit_nm"])])])
    v = about_data.build_view(build_context(b, now=fake_now))
    assert "「법정」 표시를 달고" in v["group_b"] and "「업무 교육」" not in v["group_b"]


def test_url_floor_stops_the_build_when_the_bundle_field_vanished(fake_bundle, fake_now):
    """회사가 있는데 근거 주소가 0곳이면 번들 필드가 조용히 떨어진 것이다(20번)."""
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": None}, [_row()])])
    with pytest.raises(BuildError, match="번들 필드 누락 의심"):
        about_data.build_view(build_context(b, now=fake_now))


def test_fin_emp_zero_clause_is_dropped_individually(fake_bundle, fake_now, fake_finance, fake_employ):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance, employ=fake_employ)
    assert "(재무 2곳 · 직원 2곳)" in _text(ctx)
    only_fin = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    t = _text(only_fin)
    assert "(재무 2곳)" in t and "직원 0곳" not in t
    only_emp = _text(build_context(fake_bundle, now=fake_now, employ=fake_employ))
    assert "(직원 2곳)" in only_emp and "재무 0곳" not in only_emp


def test_names_and_codes_skip_empty(fake_bundle, fake_now):
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": "https://ex.com"},
                               [_row("meal", "식대"), _row(None, "", None, "none"), _row("", None, None, "none")])])
    n = about_data.counts(build_context(b, now=fake_now))
    assert (n["names"], n["codes"]) == (1, 1)


def test_summary_row_with_amount_stops_the_build(fake_bundle, fake_now):
    """「이 항목들에는 금액을 넣지 않습니다」가 거짓이 되면 조용히 빼지 않고 빌드를 멈춘다."""
    b = _bundle(fake_bundle, [("aa", {}, [_row(badge_src="ai_parse", amt=300)])])
    with pytest.raises(BuildError, match="리드 판정 필요"):
        about_data.build_view(build_context(b, now=fake_now))


# ── ③ 상수 = 코드 정본 ───────────────────────────────────────────────────────


def test_band_constants_match_calc_js():
    js = (REPO_ROOT / "web" / "assets" / "js" / "calc.js").read_text(encoding="utf-8")
    base = re.search(r"export const BAND_BASE\s*=\s*\{\s*stated:\s*([\d.]+),\s*estimated:\s*([\d.]+)", js)
    exp = re.search(r"export const BAND_EXPIRE\s*=\s*([\d.]+)", js)
    assert base and exp, "calc.js 의 밴드 상수를 못 찾았다 — 이 테스트의 정규식을 함께 고쳐라"
    assert round(float(base.group(1)) * 100) == about_data.BAND_STATED_PCT
    assert round(float(base.group(2)) * 100) == about_data.BAND_ESTIMATED_PCT
    assert round(float(exp.group(1)) * 100) == about_data.BAND_EXPIRE_PP


def test_expire_months_match_the_expiry_rule():
    src = (REPO_ROOT / "server" / "services" / "benefit_edit.py").read_text(encoding="utf-8")
    assert f"INTERVAL {about_data.EXPIRE_MONTHS} MONTH" in src


def test_labels_come_from_their_canonical_sources(fake_bundle, fake_now):
    v = about_data.build_view(build_context(fake_bundle, now=fake_now))
    lens = {k: label for k, label, _ in LENS_BUCKETS}
    assert [k["label"] for k in v["kinds"]] == [lens["stated"], lens["est"], T.KIND_NONE_LABEL]
    calc_js = (REPO_ROOT / "web" / "assets" / "js" / "calc.js").read_text(encoding="utf-8")
    assert T.KIND_NONE_LABEL in calc_js, "「금액 미등록」은 이직 계산기 낱말이라 남긴 것이다 — calc.js 에서 사라지면 이 라벨의 근거가 없다"
    # 문안 속에 직접 적힌 라벨(합계 문장)이 정본 라벨과 같다
    assert f"{lens['stated']}가 {{st}}건" in T.AMOUNT_TOTALS and f"{lens['est']}가 {{es}}건" in T.AMOUNT_TOTALS
    assert f"{T.KIND_NONE_LABEL}이 {{no}}건" in T.AMOUNT_TOTALS
    none_text = v["kinds"][2]["text"]
    assert f"「{lens['qual']}」과, " in none_text and f"「{lens['blank']}」로 나눠 보여 줍니다." in none_text
    assert [w["badge"]["label"] for w in v["who"]] == ["공식", "공식·재직자 수정", "재직자 등록"]  # badge.js 와 같은 글자
    assert v["timeline"]["stale"]["label"] == "만료·재확인 필요"
    badge_js = (REPO_ROOT / "web" / "assets" / "js" / "badge.js").read_text(encoding="utf-8")
    for w in v["who"] + [v["timeline"]["stale"]]:
        label = w["badge"]["label"] if "badge" in w else w["label"]
        assert f"'{label}'" in badge_js, f"badge.js 에 「{label}」 라벨이 없다"
    assert v["cats"] == [CATEGORY_LABEL[k] for k in CATEGORY_ORDER]


# ── ④ 빌드 날짜와 무관 ───────────────────────────────────────────────────────


def test_output_does_not_depend_on_build_time(fake_bundle, fake_now):
    env = make_env()
    a = about_data.render(env, build_context(fake_bundle, now=fake_now), CFG)
    b = about_data.render(env, build_context(fake_bundle, now=datetime(2031, 1, 1)), CFG)
    assert a.html == b.html


# ── ⑤ 문안 규율 ──────────────────────────────────────────────────────────────

_QUANTIFIERS = ("대부분", "많은", "보통", "거의")


def _content_strings() -> list[str]:
    tree = ast.parse((REPO_ROOT / "generator" / "content" / "about_data.py").read_text(encoding="utf-8"))
    return [n.value for n in ast.walk(tree) if isinstance(n, ast.Constant) and isinstance(n.value, str)]


def test_human_sentences_carry_no_numbers_or_quantifiers():
    strings = [s for s in _content_strings() if not s.startswith("generator/")]
    assert strings
    for s in strings:
        stripped = re.sub(r"\{[^}]*\}", "", s)  # 자리표시는 숫자 칸이다
        assert not re.search(r"\d", stripped), f"사람 문장에 숫자가 박혔다: {s!r}"
        assert not any(q in s for q in _QUANTIFIERS), f"수량어: {s!r}"


def test_rendered_page_has_no_quantifiers(fake_bundle, fake_now):
    page = about_data.render(make_env(), build_context(fake_bundle, now=fake_now), CFG)
    main = page.html[page.html.index("<main"):page.html.index("</main>")]
    text = re.sub(r"<[^>]+>", " ", main)
    assert not any(q in text for q in _QUANTIFIERS)


# ── ⑥ 대문 home-trust 와 같은 집계 ───────────────────────────────────────────


def test_amount_totals_equal_home_trust(synth, fake_bundle, fake_now):
    for ctx in (synth, build_context(fake_bundle, now=fake_now)):
        n = about_data.counts(ctx)
        t = home._trust(ctx)

        def num(x):
            return int(x.replace(",", "")) if x else 0

        assert n["rows"] == num(t["total"])
        assert n["st"] == num(t["stated"]) and n["es"] == num(t["estimated"])
        assert n["no"] == num(t["qual"]) + num(t["no_amount"])
        assert n["summary_rows"] == num(t["summary"]) and n["summary_comp"] == num(t["summary_companies"])


# ── ⑦ 탭 활성 · sitemap · 무광고 · SEO ───────────────────────────────────────


def test_page_is_active_tab_adless_and_indexable(fake_bundle, fake_now):
    page = about_data.render(make_env(), build_context(fake_bundle, now=fake_now), CFG)
    assert page.path == "about/data.html" and page.url == CFG.site_origin + "/about/data" and page.in_sitemap
    assert page.title == f"복지 데이터는 이렇게 만듭니다 | {CFG.site_name}"
    assert '<a href="/about/data" class="gnb-link" aria-current="page">가이드</a>' in page.html
    assert page.html.count('aria-current="page"') == 1
    assert '<body data-page-type="policy">' in page.html and "data-ad-position" not in page.html
    assert f'<link rel="canonical" href="{page.url}">' in page.html
    assert 'property="og:url"' in page.html and len(page.description) <= CFG.desc_max
    assert page.description.startswith("잡초위키는 회사가 스스로 공개한 자료를 모아")
    assert "<h1>잡초위키의 복지 데이터는 이렇게 만듭니다</h1>" in page.html


def test_pipeline_emits_page_and_sitemap_entry(fake_bundle, fake_combinations_path, tmp_path):
    from generator import build as build_module

    out = tmp_path / "dist"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-10-06") == 0
    assert (out / "about" / "data.html").is_file()
    assert f"<loc>{CFG.site_origin}/about/data</loc>" in (out / "sitemap.xml").read_text(encoding="utf-8")


# ── 검증 반영(리드 판정 (78)) ────────────────────────────────────────────────


def test_estimate_definition_matches_the_data(synth, fake_bundle, fake_now):
    """추정치는 「조건으로 계산」만이 아니라 「같은 종류 제도의 기준 금액」도 포함하고 재직자 입력도 든다(7번)."""
    est = about_data.build_view(synth)["kinds"][1]["text"]
    assert "어림값" in est and "조건(월액·횟수 등)으로 금액을 셀 수 있으면 그 조건으로 계산하고" in est
    assert "셀 수 없으면(한도나 비율만 있거나 조건이 없으면) 같은 종류 제도에 쓰는 기준 금액을 씁니다" in est and "재직자가 넣은 금액도 여기에 들어갑니다" in est
    assert "±20%" in est


def test_amount_totals_detail_and_zero_parts(synth, fake_bundle, fake_now):
    assert "금액 미등록이 4건(정성 1건 · 금액 미기재 3건)입니다." in about_data.build_view(synth)["totals"]
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": "https://ex.com"},
                               [_row(), _row("x", "y", None, "none", qual=True)])])
    t = about_data.build_view(build_context(b, now=fake_now))["totals"]
    assert "금액 미등록이 1건(정성 1건)입니다." in t and "금액 미기재" not in t
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": "https://ex.com"}, [_row()])])
    t = about_data.build_view(build_context(b, now=fake_now))["totals"]
    assert "금액 미등록이 0건입니다." in t and "(" not in t


def test_who_and_not_sentences(fake_bundle, fake_now):
    v = about_data.build_view(build_context(fake_bundle, now=fake_now))
    assert v["who"][0]["text"].startswith("회사 공식 자료에서 확인한 항목입니다. 재직자가 고친 기록은 없습니다.")
    assert "위 금액 표시로 따로 봅니다" in v["who"][0]["text"]
    assert v["who_note"].startswith("잡초위키 운영자 말고 복지를 고치거나 더할 수 있는 사람은 그 회사 재직 인증")
    assert len(v["nots"]) == 2 and not any("금액을 지어" in x for x in v["nots"])


def test_resort_title_comes_from_item_page_config_and_links(fake_bundle, fake_now):
    from generator import benefit_rules
    title = benefit_rules.load_pages()["resort"]["title"]
    b = _bundle(fake_bundle, [("aa", {"careers_benefit_url": "https://ex.com"}, [_row("resort", "휴양소")])])
    ctx = build_context(b, now=fake_now)
    env = make_env()
    linked = about_data.render(env, ctx, CFG, benefit_links={"resort": "/benefit/resort-condo"})
    assert f'<a href="/benefit/resort-condo">{title}</a> 하나만 해도 1곳이 1가지 이름으로 부릅니다.' in linked.html
    assert f'aria-label="{title}을 부르는 이름"' in linked.html
    plain = about_data.render(env, ctx, CFG)
    assert f"{title} 하나만 해도" in plain.html and "/benefit/resort-condo" not in plain.html


def test_amount_marks_use_the_lens_chip_not_source_badges(fake_bundle, fake_now):
    html = about_data.render(make_env(), build_context(fake_bundle, now=fake_now), CFG).html
    amount = html[html.index("금액은 세 가지로"):html.index("언제 다시 확인하나")]
    assert amount.count('class="sc-lens-chip guide-lens"') == 3 and "badge-" not in amount
    who = html[html.index("누가 고칠 수 있나</h2>"):html.index("하지 않는 것</h2>")]
    assert "badge-official" in who and "badge-edited" in who and "badge-member" in who
    assert html.count('<span class="sr-only">: </span>') == 6  # 배지/칩과 설명 사이 스크린리더 구분


def test_company_lens_and_home_say_the_same_estimate_definition(fake_bundle, fake_now):
    from generator.pages.company import LENS_BUCKETS
    est = dict((k, d) for k, _, d in LENS_BUCKETS)["est"]
    assert "공개 정보로 환산" not in est and "잡초위키가 붙인 어림값" in est and "셀 수 없으면 같은 종류 제도의 기준 금액으로 셉니다" in est
    t = home._trust(build_context(fake_bundle, now=fake_now))
    html = (REPO_ROOT / "generator" / "templates" / "home.html").read_text(encoding="utf-8")
    assert "잡초위키가 붙인 추정치입니다. 공개된 조건으로 금액을 셀 수 있으면 그 조건으로 계산하고, 셀 수 없으면 같은 종류 제도의 기준 금액을 쓰며" in html
    assert "공개된 조건을 바탕으로 계산한 추정치" not in html and t


def test_verified_dates_are_written_in_korean_form(synth):
    assert "2026년 3월 31일 ~ 2026년 10월 5일" in about_data.build_view(synth)["reverify"]


def test_find_reading_guide_uses_the_same_estimate_definition(fake_bundle, fake_now):
    """복지검색 「읽는 법」의 추정 설명도 같은 정의다 — 옛 문구는 어느 생성 페이지에도 없다."""
    from generator.pages import find
    ctx = build_context(fake_bundle, now=fake_now)
    html = find.render(make_env(), ctx, CFG).html
    assert "「추정」은 잡초위키가 붙인 어림값입니다(공개된 조건으로 셀 수 있으면 그 조건으로, 셀 수 없으면 같은 종류 제도의 기준 금액으로 셉니다)." in html
    assert "공개 정보로 환산" not in html
    for tpl in (REPO_ROOT / "generator" / "templates").rglob("*.html"):
        assert "공개 정보로 환산" not in tpl.read_text(encoding="utf-8"), tpl.name
