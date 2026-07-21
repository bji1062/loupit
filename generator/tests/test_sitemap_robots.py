"""T-07.9 sitemap.xml·robots.txt 테스트 (GC-18·19)."""
from __future__ import annotations

import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, policy, sitemap
from generator.render import make_env


def _build_all(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    company_pages = company.render_all(env, ctx)
    combo_pages = combo.render_all(env, ctx, CFG)
    policy_pages = policy.render_all(env, ctx)
    all_pages = company_pages + combo_pages + policy_pages
    site_urls = [p.url for p in all_pages if p.in_sitemap] + [
        CFG.site_origin + path for path in CFG.extra_sitemap_paths
    ]
    sitemap_page = sitemap.render_sitemap(env, site_urls, "2026-07-11", CFG)
    robots_page = sitemap.render_robots(CFG)
    return all_pages, sitemap_page, robots_page


# ── GC-18: sitemap 완전성·누락 0·/compare·404 부재·https·canonical 일치 ────


def test_gc18_sitemap_includes_all_company_combo_policy_and_landing(
    fake_bundle, fake_now, fake_combinations_path
):
    all_pages, sitemap_page, _ = _build_all(fake_bundle, fake_now)
    locs = set(re.findall(r"<loc>([^<]+)</loc>", sitemap_page.html))

    expected = {p.url for p in all_pages if p.in_sitemap}
    expected.add("https://jobcho.wiki/")
    assert locs == expected


def test_gc18_sitemap_excludes_compare_and_404(fake_bundle, fake_now, fake_combinations_path):
    _, sitemap_page, _ = _build_all(fake_bundle, fake_now)
    locs = re.findall(r"<loc>([^<]+)</loc>", sitemap_page.html)
    assert not any(loc.endswith("/compare") for loc in locs)
    assert not any(loc.endswith("/404") for loc in locs)


def test_gc18_sitemap_all_locs_are_https(fake_bundle, fake_now, fake_combinations_path):
    _, sitemap_page, _ = _build_all(fake_bundle, fake_now)
    locs = re.findall(r"<loc>([^<]+)</loc>", sitemap_page.html)
    assert locs, "sitemap에 URL이 없음"
    assert all(loc.startswith("https://") for loc in locs)


def test_gc18_sitemap_no_duplicate_locs(fake_bundle, fake_now, fake_combinations_path):
    _, sitemap_page, _ = _build_all(fake_bundle, fake_now)
    locs = re.findall(r"<loc>([^<]+)</loc>", sitemap_page.html)
    assert len(locs) == len(set(locs))


def test_gc18_sitemap_content_type_is_xml(fake_bundle, fake_now, fake_combinations_path):
    _, sitemap_page, _ = _build_all(fake_bundle, fake_now)
    assert sitemap_page.content_type == "application/xml; charset=utf-8"
    assert sitemap_page.in_sitemap is False


# ── GC-19: robots.txt Sitemap 라인 ──────────────────────────────────────


def test_gc19_robots_has_sitemap_line(fake_bundle, fake_now):
    _, _, robots_page = _build_all(fake_bundle, fake_now)
    assert "Sitemap: https://jobcho.wiki/sitemap.xml" in robots_page.html


def test_gc19_robots_allows_root_disallows_api(fake_bundle, fake_now):
    _, _, robots_page = _build_all(fake_bundle, fake_now)
    assert "User-agent: *" in robots_page.html
    assert "Allow: /" in robots_page.html
    assert "Disallow: /api/" in robots_page.html
    assert robots_page.content_type == "text/plain; charset=utf-8"


def test_ads_txt_format_and_pubid():
    """AdSense ads.txt(2026-07-21): google.com·DIRECT·인증기관 ID 고정, pub-id는 ca- 제거."""
    from generator.config import CFG
    page = sitemap.render_ads_txt(CFG)
    assert page.path == "ads.txt"
    assert page.content_type == "text/plain; charset=utf-8"
    line = page.html.strip()
    assert line.startswith("google.com, pub-"), line
    assert line.endswith("DIRECT, f08c47fec0942fa0"), line
    assert "ca-pub-" not in line, "ads.txt는 ca- 접두 없이 pub-만 써야 한다"
    assert CFG.adsense_client_id.replace("ca-", "", 1) in line


def test_robots_blocks_aggressive_scrapers_not_search_engines(fake_bundle, fake_now):
    """스크래핑 방어 Layer D(2026-07-21): 공격적 SEO 스크래퍼는 Disallow,
    검색·AdSense 크롤러는 규칙에 등장하지 않음(= 전체 규칙의 Allow 적용). 후자를 실수로
    Disallow하면 SEO·애드센스가 죽으므로 그 부재를 명시적으로 잠근다."""
    _, _, robots = _build_all(fake_bundle, fake_now)
    for bad in ("AhrefsBot", "SemrushBot", "MJ12bot"):
        assert f"User-agent: {bad}" in robots.html, f"{bad} 차단 규칙 누락"
    # 검색·AdSense 크롤러는 전용 Disallow 블록이 있으면 안 된다(있으면 SEO 사망).
    for good in ("Googlebot", "Mediapartners-Google", "AdsBot-Google", "Bingbot"):
        assert f"User-agent: {good}\nDisallow: /" not in robots.html, \
            f"{good}에 Disallow가 붙었다 — SEO/애드센스 차단 사고"
