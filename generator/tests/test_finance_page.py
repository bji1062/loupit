"""회사 상세 '실적' 섹션 렌더 — FN-5 (SP-FIN-5, T-15.2.2).

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-5 · DEC-B(사실만).

계약:
  - 섹션은 복지표 **뒤**, CTA **앞**(복지가 이 사이트의 본체다).
  - 기준(연결/별도)·출처(접수번호 아웃링크)·고지 한 줄은 수치가 있을 때 **항상** 함께 나온다 —
    기준을 안 적으면 그 자체가 부정확한 주장이다(LG 연결 9,122억 vs 별도 5,971억).
  - 금융 세트는 **세 번째 열이 다르다**(매출 자리에 자산총계, SP-MET-2). 열을 고르는 것은
    `finance.metric_columns` 하나이고 템플릿은 그대로 그린다 — 표가 스스로 판정하면 같은 페이지의
    카드와 갈라진다. 없는 회사는 "공시 데이터 없음"을 **말한다**.
  - 재무가 아예 주입되지 않은 빌드(`finance=None`)는 기존 페이지와 100% 같다 — 수집 전 릴리스가
    102개사 전부에 "미제출"이라는 거짓말을 찍지 않게 하는 경계다.
"""
from __future__ import annotations

import copy
import json
import re

from generator import build as build_module
from generator.context import build_context
from generator.pages import company
from generator.render import make_env
from generator.tests.fixtures import FAKE_BUNDLE, FAKE_FINANCE, make_sibling_fixture

NOTICE = "공시 수치이며 평가나 전망이 아닙니다"
NONE_TEXT = "공시 데이터 없음(비상장 또는 미제출)"
FINANCIAL_TEXT = "금융업은 단일 매출 계정을 공시하지 않아 그 자리에 자산총계를 싣습니다"


def _pages(bundle, finance, now):
    env = make_env()
    ctx = build_context(bundle, now=now, finance=finance)
    return {p.path: p.html for p in company.render_all(env, ctx)}


def _section(html: str) -> str:
    start = html.index('<section class="finance"')
    return html[start: html.index("</section>", start)]


def _rows(section: str) -> list[list[str]]:
    """tbody 의 행 → 셀 텍스트 목록(th/td 순서 그대로)."""
    body = section[section.index("<tbody>"): section.index("</tbody>")]
    return [re.findall(r"<t[hd][^>]*>(.*?)</t[hd]>", tr, re.S) for tr in re.findall(r"<tr>(.*?)</tr>", body, re.S)]


# ── 위치·존재 ─────────────────────────────────────────────────────────────────

def test_FN5_every_company_page_has_finance_section_when_finance_loaded(fake_bundle, fake_finance, fake_now):
    for path, html in _pages(fake_bundle, fake_finance, fake_now).items():
        assert '<section class="finance"' in html, path
        assert "<h2>실적</h2>" in _section(html), path


def test_FN5_section_sits_after_benefit_table_and_before_cta(fake_bundle, fake_finance, fake_now):
    html = _pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"]
    assert html.index('class="benefit-table"') < html.index('<section class="finance"') < html.index('class="cta"')


# ── 일반 세트: 표·기준·출처·고지 ─────────────────────────────────────────────

def test_FN5_general_table_newest_first_with_eok_amounts_and_deltas(fake_bundle, fake_finance, fake_now):
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"])
    assert "<caption" in sec  # 속성(id)이 붙을 수 있다 — 여는 태그로 본다
    for th in ("연도", "매출", "영업이익", "순이익", "전년 대비"):
        assert f'<th scope="col">{th}</th>' in sec, th
    rows = _rows(sec)
    assert [r[0] for r in rows] == ["2025", "2024", "2023", "2022", "2021"], "최신 연도가 먼저"
    assert rows[0] == ["2025", "3,300,000", "+10.0%", "400,000", "+25.0%", "350,000", "+2.9%"]
    assert rows[-1][2] == "—", "첫 해는 전년이 없다 — 빈칸이 아니라 '—'"
    assert '<th scope="row">2025</th>' in sec


def test_FN5_basis_badge_reads_cfs_or_ofs(fake_bundle, fake_finance, fake_now):
    pages = _pages(fake_bundle, fake_finance, fake_now)
    assert '<span class="badge finance-basis">연결 기준</span>' in _section(pages["company/samsung-elec.html"])
    assert '<span class="badge finance-basis">별도 기준</span>' in _section(pages["company/naver.html"])


def test_FN5_source_line_links_latest_receipt_on_dart(fake_bundle, fake_finance, fake_now):
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"])
    assert (
        '출처: 금융감독원 전자공시(DART) 사업보고서 · 접수번호 '
        '<a href="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260318000001" rel="noopener">20260318000001</a>'
    ) in sec


def test_FN5_notice_is_one_line_of_fact(fake_bundle, fake_finance, fake_now):
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"])
    assert f'<p class="finance-notice">{NOTICE}</p>' in sec


# ── 금융 세트·없음·형제 ──────────────────────────────────────────────────────

def test_FN5_financial_set_swaps_revenue_for_total_assets(fake_bundle, fake_finance, fake_now):
    """금융 세트도 열은 **3종**이다 — 자산총계·영업이익·순이익(SP-MET-2, 2026-08-28 DART 전수 실측).

    구 판본은 여기서 순이익 하나만 그리고 "금융업은 순이익만 표시합니다"라고 적었다. 그 문장은
    사실이 아니었다: 영업이익이 비어 보인 건 계정 ID 누락이었고 넣으면 7/7 이다. 진짜로 없는 것은
    단일 매출 계정 하나뿐이라, 그 자리에만 자산총계(7/7)가 들어간다.
    """
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/naver.html"])
    for th in ("자산총계", "영업이익", "순이익"):
        assert f'<th scope="col">{th}</th>' in sec, th
    assert '<th scope="col">매출</th>' not in sec, "금융에 없는 것은 매출 계정 하나뿐이다"
    assert "순이익만" not in sec, "거짓으로 판명된 구 문장이 남아 있다"
    assert FINANCIAL_TEXT in sec
    assert _rows(sec)[0] == ["2025", "330,000", "+10.0%", "9,000", "+12.5%", "24,515", "+11.4%"]
    assert NONE_TEXT not in sec


def test_FN5_column_set_is_decided_by_one_function_not_by_the_template(fake_bundle, fake_finance, fake_now):
    """표의 열 구성이 `finance.metric_columns` 와 **글자 그대로** 일치한다(SP-MET-2 단일 판정).

    이 테스트가 잡는 회귀는 '템플릿이 세트를 다시 판정하는 것'이다 — 그렇게 되면 같은 페이지에서
    표는 순이익만, 카드는 자산총계를 그리는 상태가 아무 에러 없이 성립한다.
    """
    from generator.finance import metric_columns

    pages = _pages(fake_bundle, fake_finance, fake_now)
    for path, acct_set in (("company/samsung-elec.html", "general"), ("company/naver.html", "financial")):
        sec = _section(pages[path])
        heads = [h for h in re.findall(r'<th scope="col">(.*?)</th>', sec) if h != "전년 대비"]
        assert heads == ["연도", *[n for _, n in metric_columns(acct_set)]], path


def test_FN5_company_without_data_says_so_and_keeps_section(fake_bundle, fake_finance, fake_now):
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/sk-hynix.html"])
    assert f'<p class="finance-none">{NONE_TEXT}</p>' in sec
    assert "<table" not in sec and "접수번호" not in sec and NOTICE not in sec


def test_FN5_siblings_get_same_figures_and_a_corporation_note(fake_now):
    bundle, finance = make_sibling_fixture()
    pages = _pages(bundle, finance, fake_now)
    ent, com = _section(pages["company/cj-enm-ent.html"]), _section(pages["company/cj-enm-com.html"])
    assert "법인 기준 공시 — CJ ENM 커머스부문과 같은 법인" in ent
    assert "법인 기준 공시 — CJ ENM 엔터테인먼트부문과 같은 법인" in com
    assert _rows(ent) == _rows(com)
    assert _rows(ent)[0][5] == "-500", "적자는 음수 그대로"
    assert "법인 기준 공시" not in _section(pages["company/samsung-elec.html"])


def test_FN5_receipt_number_is_validated_before_becoming_a_link(fake_bundle, fake_finance, fake_now):
    """접수번호가 숫자가 아니면 링크를 만들지 않는다(URL 주입 경로 차단) — 이스케이프된 텍스트로만."""
    fin = copy.deepcopy(fake_finance)
    fin[1]["years"][-1]["rcept_no"] = '"><script>alert(1)</script>'
    sec = _section(_pages(fake_bundle, fin, fake_now)["company/samsung-elec.html"])
    assert "dart.fss.or.kr" not in sec
    assert "<script>" not in sec


# ── 무주입 = 무회귀 ──────────────────────────────────────────────────────────

def test_FN5_no_finance_means_no_section_at_all(fake_bundle, fake_now):
    """`finance=None` 과 `{}` 둘 다 — 섹션 자체가 없다. 기존 스위트가 이 경로를 그대로 재사용한다."""
    for fin in (None, {}):
        for path, html in _pages(copy.deepcopy(fake_bundle), fin, fake_now).items():
            assert 'class="finance"' not in html, (path, fin)
            assert NONE_TEXT not in html, (path, fin)


def test_FN5_dataset_without_any_figures_counts_as_not_loaded(fake_bundle, fake_finance, fake_now):
    """매핑은 있는데 수치가 0건(수집 전)이면 '없음' 문구도 내지 않는다 — 102개사 전부 '미제출' 은 거짓이다."""
    fin = {k: {**v, "years": []} for k, v in fake_finance.items()}
    for path, html in _pages(fake_bundle, fin, fake_now).items():
        assert 'class="finance"' not in html, path


# ── CLI: --finance-json ──────────────────────────────────────────────────────

def test_FN5_build_cli_renders_finance_from_json_dump(tmp_path, fake_combinations_path):
    b, f = tmp_path / "b.json", tmp_path / "f.json"
    b.write_text(json.dumps(FAKE_BUNDLE, ensure_ascii=False), encoding="utf-8")
    f.write_text(json.dumps(FAKE_FINANCE, ensure_ascii=False), encoding="utf-8")  # 키가 문자열로 떨어진다
    out = tmp_path / "dist"
    rc = build_module.main(["--bundle-json", str(b), "--finance-json", str(f), "--out", str(out), "--no-gzip"])
    assert rc == 0
    html = (out / "company" / "samsung-elec.html").read_text(encoding="utf-8")
    assert '<section class="finance"' in html and "3,300,000" in html
    assert NONE_TEXT in (out / "company" / "sk-hynix.html").read_text(encoding="utf-8")


def test_FN5_build_cli_without_finance_json_says_so_and_renders_legacy(tmp_path, fake_combinations_path, capsys):
    b = tmp_path / "b.json"
    b.write_text(json.dumps(FAKE_BUNDLE, ensure_ascii=False), encoding="utf-8")
    out = tmp_path / "dist"
    rc = build_module.main(["--bundle-json", str(b), "--out", str(out), "--no-gzip"])
    assert rc == 0
    assert 'class="finance"' not in (out / "company" / "samsung-elec.html").read_text(encoding="utf-8")
    assert "finance" in capsys.readouterr().err.lower(), "재무 미주입을 조용히 넘기면 안 된다"


# ── MD-4: 7열 표는 페이지가 아니라 표가 스크롤한다 (2026-09-05) ────────────────
# 실측(390px, iPhone Safari UA): 재무표가 있는 113 페이지 중 110 페이지에서
# documentElement.scrollWidth 가 뷰포트를 21~143px 넘겼다. html/body 에
# overflow-x:hidden 이 없어 **페이지 전체가 가로로 팬**됐다 — 헤더·본문·CTA 가 같이 밀린다.
# 넘침을 표 자신의 스크롤 상자에 가두는 것이 유일하게 열을 안 잘라먹는 해법이다
# (body{overflow-x:hidden} 은 오른쪽 열을 영원히 못 보게 만든다).


def _tables_outside_scroll_wrapper(html: str) -> list[str]:
    """`.table-scroll` 래퍼에 들어 있지 않은 `<table>` 여는 태그 목록."""
    caged = re.sub(
        r'<div class="table-scroll"[^>]*>\s*<table[^>]*>.*?</table>\s*</div>',
        "", html, flags=re.S,
    )
    return re.findall(r"<table[^>]*>", caged)


def test_FN5_finance_table_scrolls_inside_its_own_container_not_the_page(fake_bundle, fake_finance, fake_now):
    """7열 표가 뷰포트를 넘겨도 **페이지**는 밀리지 않는다(SPEC 10 MD-4 '가로 스크롤 없음').

    무엇을 막는가: 표를 래퍼 밖으로 다시 꺼내는 회귀. 낱말이 아니라 **구조**를 단언한다 —
    섹션 안의 모든 `<table>` 이 스크롤 래퍼 안에 있어야 하고, 남은 것이 하나라도 있으면
    그 표가 390px 에서 페이지를 민다.
    """
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"])
    assert _tables_outside_scroll_wrapper(sec) == [], "스크롤 래퍼 밖의 표 — 페이지가 가로로 밀린다"
    wrap = re.search(
        r'<div class="table-scroll"([^>]*)>\s*(<table class="benefit-table finance-table">.*?</table>)\s*</div>',
        sec, re.S,
    )
    assert wrap, "재무표가 .table-scroll 래퍼의 직계 자식이 아니다"
    assert "<caption" in wrap.group(2), "caption 은 표 안에 남는다 — 표의 접근 가능한 이름이다"


def test_FN5_scroll_container_is_reachable_by_keyboard_with_a_name(fake_bundle, fake_finance, fake_now):
    """마우스가 없는 사람은 스크롤 영역에 **들어갈 수단이 없다**(axe scrollable-region-focusable).

    tabindex 로 탭 순서에 넣고, 이름 없는 포커스 정거장이 되지 않게 role+이름을 준다.
    포커스 링은 전역 :focus-visible 이 그린다.

    이름은 **caption 을 가리킨다**: `tabindex` 는 폭과 무관하게 늘 붙어 있어서, "가로로
    스크롤할 수 있습니다" 라고 적으면 표가 다 들어가는 폭(1280·640px 실측 clientWidth ==
    scrollWidth)에서 없는 스크롤을 있다고 말하게 되고, 그룹 이름 뒤에 caption 이 이어 읽혀
    같은 표가 두 번 소개된다. 한 이름을 그룹과 표가 나눠 쓰면 어느 폭에서도 참이다.
    """
    sec = _section(_pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"])
    attrs = re.search(r'<div class="table-scroll"([^>]*)>', sec).group(1)
    assert 'tabindex="0"' in attrs
    assert 'role="group"' in attrs, "이름 붙은 div 는 role 없이 그룹으로 노출되지 않는다"
    ref = re.search(r'aria-labelledby="([^"]+)"', attrs)
    assert ref, "포커스 정거장에 이름이 없다"
    cap = re.search(rf'<caption id="{ref.group(1)}">([^<]+)</caption>', sec)
    assert cap and cap.group(1).strip(), f"aria-labelledby 가 가리키는 caption 이 없다: {ref.group(1)}"


def test_FN5_every_company_page_cages_its_finance_table(fake_bundle, fake_finance, fake_now):
    """한 회사만 고친 것이 아니다 — 재무표를 그리는 모든 페이지가 같은 래퍼를 쓴다."""
    for path, html in _pages(fake_bundle, fake_finance, fake_now).items():
        sec = _section(html)
        if "<table" not in sec:
            continue  # 공시 없음 회사 — 표 자체가 없다
        assert _tables_outside_scroll_wrapper(sec) == [], path
