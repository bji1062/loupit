"""T-07.6·7.6·7.11.5 SEO head·JSON-LD·중복 검증 (GC-5·7·8·9·26)."""
from __future__ import annotations

import json
import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, policy
from generator.render import make_env

_TAG_COUNT_PATTERNS = {
    "title": re.compile(r"<title>"),
    "meta_description": re.compile(r'<meta name="description"'),
    "canonical": re.compile(r'<link rel="canonical"'),
    "og:title": re.compile(r'<meta property="og:title"'),
    "og:description": re.compile(r'<meta property="og:description"'),
    "og:type": re.compile(r'<meta property="og:type"'),
    "og:url": re.compile(r'<meta property="og:url"'),
    "og:image": re.compile(r'<meta property="og:image"'),
}


def _all_pages(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return company.render_all(env, ctx) + combo.render_all(env, ctx, CFG)


# ── GC-5: 필수 태그 각 정확히 1 ──────────────────────────────────────────


def test_gc5_company_page_has_each_seo_tag_exactly_once(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    for name, pattern in _TAG_COUNT_PATTERNS.items():
        assert len(pattern.findall(p.html)) == 1, f"{name} 개수 != 1"


def test_gc5_combo_page_has_each_seo_tag_exactly_once(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = combo.render_all(env, ctx, CFG)[0]
    for name, pattern in _TAG_COUNT_PATTERNS.items():
        assert len(pattern.findall(p.html)) == 1, f"{name} 개수 != 1"


# ── GC-7: 페이지 간 title·description 중복 0 ────────────────────────────


def test_gc7_titles_and_descriptions_are_unique_across_all_pages(fake_bundle, fake_now, fake_combinations_path):
    pages = _all_pages(fake_bundle, fake_now, fake_combinations_path)
    titles = [p.title for p in pages]
    descs = [p.description for p in pages]
    assert len(titles) == len(set(titles)), f"title 중복: {titles}"
    assert len(descs) == len(set(descs)), f"description 중복: {descs}"


# ── GC-8: canonical == og:url == 자기 URL ───────────────────────────────


def test_gc8_company_canonical_equals_og_url_equals_self_url(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    canonical = re.search(r'<link rel="canonical" href="([^"]+)">', p.html).group(1)
    og_url = re.search(r'<meta property="og:url" content="([^"]+)">', p.html).group(1)
    assert canonical == og_url == p.url


def test_gc8_combo_canonical_equals_og_url_equals_self_url(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = combo.render_all(env, ctx, CFG)[0]
    canonical = re.search(r'<link rel="canonical" href="([^"]+)">', p.html).group(1)
    og_url = re.search(r'<meta property="og:url" content="([^"]+)">', p.html).group(1)
    assert canonical == og_url == p.url == "https://jobcho.wiki/vs/samsung-elec-sk-hynix"


# ── GC-9: JSON-LD 파싱 오류 0·필드 정확·부재 키 확인 ────────────────────────


def test_gc9_company_jsonld_parses_and_has_organization_fields(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    m = re.search(r'<script type="application/ld\+json">(.*?)</script>', p.html, re.S)
    assert m, "JSON-LD <script> 미검출"
    data = json.loads(m.group(1))  # 파싱 오류 0
    assert data["@type"] == "Organization"
    assert data["name"] == "삼성전자"
    assert "samsung_elec" in data["alternateName"]
    for forbidden in ("logo", "image", "address", "telephone"):
        assert forbidden not in data


# ── GC-26: lang·charset·한글 무결성 ──────────────────────────────────────


def test_gc26_html_lang_ko_and_charset_utf8(fake_bundle, fake_now, fake_combinations_path):
    for p in _all_pages(fake_bundle, fake_now, fake_combinations_path):
        assert '<html lang="ko">' in p.html
        assert '<meta charset="utf-8">' in p.html


def test_gc26_korean_text_not_mangled(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    assert "삼성전자" in p.html
    assert "식대 지원" in p.html
