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
    assert 'id="consent-banner"' in p.html
    assert "/assets/v2/js/static-ads.js" in p.html


def test_gc27_index_shows_industry_meta(fake_bundle, fake_now):
    """업종을 함께 표기해 목록이 단순 링크 나열로 보이지 않게 한다."""
    p = _render(fake_bundle, fake_now)
    assert "반도체" in p.html
