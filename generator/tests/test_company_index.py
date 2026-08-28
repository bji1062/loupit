"""T-07.5.x 회사 인덱스 페이지 (/companies) — GC-27.

배경(2026-07-19 검수 반증): 회사 95·조합 3 페이지끼리는 관련 링크로 잘 이어졌으나
**랜딩·비교툴 어디에서도 그 덩어리로 들어가는 정적 링크가 0건**이었다. 진입문이
sitemap.xml 뿐이면 크롤러의 발견·우선순위가 여전히 낮고, 사용자는 검색으로 직접
들어오는 것 말고는 회사 페이지에 닿을 수 없다. 이 인덱스가 그 문이다.
"""
from __future__ import annotations

import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import company_index
from generator.render import make_env


def _render(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return company_index.render(env, ctx, CFG)


def test_gc27_index_page_path_and_route(fake_bundle, fake_now):
    p = _render(fake_bundle, fake_now)
    assert p.path == "companies.html"
    assert p.url == f"{CFG.site_origin}/companies"
    assert p.in_sitemap is True


def test_gc27_index_links_every_company_exactly_once(fake_bundle, fake_now):
    """등록 회사 전량이 정확히 한 번씩 링크된다 — 크롤러 진입문의 완전성."""
    p = _render(fake_bundle, fake_now)
    hrefs = re.findall(r'href="(/company/[^"]+)"', p.html)
    assert len(hrefs) == len(fake_bundle["companies"])
    assert len(hrefs) == len(set(hrefs)), "중복 링크"
    ctx = build_context(fake_bundle, now=fake_now)
    expected = {f"/company/{s}" for s in ctx.slugs.values()}
    assert set(hrefs) == expected


def test_gc27_index_is_sorted_by_company_name(fake_bundle, fake_now):
    """가나다순 — 사용자가 훑기 쉽고 빌드 간 순서가 안정적이다."""
    p = _render(fake_bundle, fake_now)
    names = re.findall(r'href="/company/[^"]+">([^<]+)</a>', p.html)
    assert names == sorted(names, key=lambda s: s)


def test_gc27_index_has_single_h1_and_seo_head(fake_bundle, fake_now):
    p = _render(fake_bundle, fake_now)
    assert len(re.findall(r"<h1>", p.html)) == 1
    assert f'<link rel="canonical" href="{CFG.site_origin}/companies">' in p.html
    assert p.title and p.title.endswith(CFG.site_name)
    assert p.description


def test_gc27_index_is_policy_free_of_ads_but_has_consent_wiring(fake_bundle, fake_now):
    """인덱스는 목록 페이지라 광고 호스트를 두지 않는다(page_type 미선언=무광고).
    동의 배너·진입 스크립트는 base 공통이라 그대로 실린다."""
    p = _render(fake_bundle, fake_now)
    assert "data-ad-position" not in p.html
    assert 'class="ad-slot"' not in p.html
    assert 'id="consent-banner"' not in p.html   # 배너 제거(SP-ADS-7, 2026-08-28)
    assert "/assets/v2/js/static-ads.js" in p.html


def test_gc27_index_shows_industry_meta(fake_bundle, fake_now):
    """업종을 함께 표기해 목록이 단순 링크 나열로 보이지 않게 한다."""
    p = _render(fake_bundle, fake_now)
    assert "반도체" in p.html


# ── FN-7: 재무 열 + 일반/금융 섹션 (SP-FIN-5, 2026-08-27) ───────────────────
# 회사정보 탭의 착지. 지표 세트가 다른 금융업을 같은 표에 넣으면 빈칸 또는 다른 뜻의 숫자가
# 되므로 섹션을 가른다. 재무가 주입되지 않은 빌드는 위 GC-27 의 단순 목록 그대로다(무회귀).


def _render_fin(fake_bundle, finance, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now, finance=finance)
    return company_index.render(env, ctx, CFG)


def _section_html(html: str, acct_set: str) -> str:
    start = html.index(f'data-acct-set="{acct_set}"')
    return html[start: html.index("</section>", start)]


def _names_in(html: str) -> list[str]:
    return re.findall(r'href="/company/[^"]+">([^<]+)</a>', html)


def test_FN7_index_splits_general_and_financial_sections(fake_bundle, fake_finance, fake_now):
    p = _render_fin(fake_bundle, fake_finance, fake_now)
    assert "<h1>회사정보 — 등록 회사 3곳</h1>" in p.html
    general, financial = _section_html(p.html, "general"), _section_html(p.html, "financial")
    assert "<h2>일반</h2>" in general and "<h2>금융</h2>" in financial
    assert _names_in(general) == ["SK하이닉스", "삼성전자"]
    assert _names_in(financial) == ["네이버"]
    assert "금융업은 계정 체계가 달라 순이익만 표시" in financial


def test_FN7_index_rows_carry_latest_year_figures_and_basis(fake_bundle, fake_finance, fake_now):
    p = _render_fin(fake_bundle, fake_finance, fake_now)
    general = _section_html(p.html, "general")
    for th in ("회사", "업종", "연도", "매출(억원)", "영업이익(억원)", "순이익(억원)", "기준"):
        assert f'<th scope="col">{th}</th>' in general, th
    assert "<caption>" in general
    samsung = re.search(r"<tr>(?:(?!</tr>).)*?삼성전자.*?</tr>", general, re.S).group(0)
    for cell in ("2025", "3,300,000", "400,000", "350,000", "연결"):
        assert cell in samsung, cell
    sk = re.search(r"<tr>(?:(?!</tr>).)*?SK하이닉스.*?</tr>", general, re.S).group(0)
    assert sk.count("—") >= 4, "재무 없는 회사는 '—'"
    assert "반도체" in sk, "업종 열은 유지"
    financial = _section_html(p.html, "financial")
    assert '<th scope="col">순이익(억원)</th>' in financial
    assert "매출(억원)" not in financial and "영업이익(억원)" not in financial
    naver = re.search(r"<tr>(?:(?!</tr>).)*?네이버.*?</tr>", financial, re.S).group(0)
    assert "24,515" in naver and "별도" in naver


def test_FN7_index_each_section_sorted_and_every_company_once(fake_bundle, fake_finance, fake_now):
    """가나다 정렬(GC-27)은 **섹션 안에서** 성립한다 — 섹션을 갈랐으니 전역 순서가 아니라 섹션별이다."""
    p = _render_fin(fake_bundle, fake_finance, fake_now)
    for acct_set in ("general", "financial"):
        names = _names_in(_section_html(p.html, acct_set))
        assert names == sorted(names), acct_set
    hrefs = re.findall(r'href="(/company/[^"]+)"', p.html)
    assert len(hrefs) == len(set(hrefs)) == len(fake_bundle["companies"])


def test_FN7_financial_section_omitted_when_no_financial_company(fake_bundle, fake_finance, fake_now):
    fin = {1: fake_finance[1]}
    p = _render_fin(fake_bundle, fin, fake_now)
    assert 'data-acct-set="general"' in p.html
    assert 'data-acct-set="financial"' not in p.html and "<h2>금융</h2>" not in p.html
    assert len(_names_in(p.html)) == 3, "금융 섹션이 없어도 회사는 전량 일반 섹션에 실린다"


def test_FN7_index_without_finance_keeps_plain_list(fake_bundle, fake_now):
    p = _render(fake_bundle, fake_now)
    assert '<ul class="company-index-list">' in p.html
    assert "data-acct-set" not in p.html and "<table" not in p.html


def test_FN7_index_keeps_company_tab_current_and_no_ads(fake_bundle, fake_finance, fake_now):
    p = _render_fin(fake_bundle, fake_finance, fake_now)
    assert 'aria-current="page"' in p.html
    assert "data-ad-position" not in p.html
