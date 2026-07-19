"""T-09.9.3~9.9.6·T-09.7.1·T-09.8.1 정책 생성물 검증 (PC-3·4·7·8·9·10·12).

SP-GEN(07) 렌더 파이프라인 착지(M5) 소비 — `generator.pages.policy`가
`generator.content.policy`(SP-POL) 문안을 `policy.html`로 감싸 렌더한
**실제 HTML**을 검증한다. 콘텐츠 소스 자체(PC-1·2·6·11·13)는
`test_policy_content.py`가 이미 검증했으므로 여기서는 렌더·SEO·게시·
sitemap·정정 경로·무광고·시크릿 부재만 다룬다(SP-POL-9.2 위임 검증).
"""
from __future__ import annotations

import dataclasses
import json
import re

import pytest

from generator import build as build_module
from generator.config import CFG, GenConfig
from generator.context import build_context
from generator.pages import policy as policy_module
from generator.pages import sitemap as sitemap_module
from generator.render import make_env

POLICY_FILES = ("privacy.html", "terms.html", "disclaimer.html", "ads.html")
POLICY_ROUTES = ("/privacy", "/terms", "/disclaimer", "/ads")


def _build_full_site(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    """PC-3(게시)·PC-8(sitemap)은 실 `web/dist`(임시본)와 sitemap을 요구한다."""
    out_dir = tmp_path / "dist"
    rc = build_module.run(str(out_dir), fake_bundle, lastmod="2026-07-11")
    assert rc == 0
    return out_dir


def _render_policy_pages(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return {p.path: p for p in policy_module.render_all(env, ctx)}


# ── PC-3: 정책 4종 게시(web/dist 4파일 존재, 누락·404=0) ────────────────────


def test_pc3_four_policy_files_exist_in_dist(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    out_dir = _build_full_site(fake_bundle, fake_now, fake_combinations_path, tmp_path)
    for fname in POLICY_FILES:
        assert (out_dir / fname).exists(), f"{fname} 누락"
        assert (out_dir / fname).stat().st_size > 0


# ── PC-8: sitemap.xml에 정책 4종 <loc> 포함(https·canonical 일치) ──────────


def test_pc8_sitemap_includes_all_four_policy_routes(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    out_dir = _build_full_site(fake_bundle, fake_now, fake_combinations_path, tmp_path)
    sitemap_xml = (out_dir / "sitemap.xml").read_text(encoding="utf-8")
    locs = set(re.findall(r"<loc>([^<]+)</loc>", sitemap_xml))
    for route in POLICY_ROUTES:
        expected = f"{CFG.site_origin}{route}"
        assert expected in locs, f"{route} sitemap 누락"
        assert expected.startswith("https://")


def test_pc8_policy_canonical_matches_sitemap_loc(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    out_dir = _build_full_site(fake_bundle, fake_now, fake_combinations_path, tmp_path)
    for fname, route in zip(POLICY_FILES, POLICY_ROUTES):
        html = (out_dir / fname).read_text(encoding="utf-8")
        canonical = re.search(r'<link rel="canonical" href="([^"]+)">', html).group(1)
        assert canonical == f"{CFG.site_origin}{route}"


# ── PC-4: 단일 h1·lang=ko·charset utf-8·고유 title/desc·중복 0 ─────────────


def test_pc4_each_policy_page_has_single_h1_and_lang_charset(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        html = pages[path].html
        h1s = re.findall(r"<h1>(.*?)</h1>", html)
        assert len(h1s) == 1, f"{path}: h1 개수={len(h1s)}"
        assert '<html lang="ko">' in html
        assert '<meta charset="utf-8">' in html


def test_pc4_titles_have_site_suffix_and_are_unique(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    titles = [pages[f].title for f in POLICY_FILES]
    assert all(t.endswith(" | jobcho.wiki") for t in titles)
    assert len(titles) == len(set(titles))


def test_pc4_descriptions_are_unique_across_four_docs(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    descs = [pages[f].description for f in POLICY_FILES]
    assert len(descs) == len(set(descs))


# ── PC-7: 무광고 — .ad-slot 0·"광고 없음" 표식·AdSense script/client id 부재 ─


def test_pc7_no_ad_slot_elements_on_policy_pages(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        assert pages[path].html.count('class="ad-slot"') == 0


def test_pc7_ads_none_marker_shown(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        assert "이 페이지에는 광고가 없습니다" in pages[path].html


def test_pc7_no_adsense_script_or_real_client_id(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        html = pages[path].html
        assert "pagead2.googlesyndication" not in html
        assert "adsbygoogle" not in html
        # placeholder id는 노출 가능하나 "ca-pub-XXXX" 외 실 숫자 client id 패턴 없음
        assert not re.search(r"ca-pub-\d{10,}", html)


# ── PC-9: 정정·문의 경로·SLA·서버 무쓰기(form/action/fetch/XHR 부재) ────────


def test_pc9_correction_section_present_with_sla_text(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert 'id="correction"' in html
    assert "접수" in html and "검토" in html and "다음 빌드" in html
    assert "즉시 반영되지" in html


def test_pc9_no_form_action_or_client_mutation_calls(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        html = pages[path].html
        assert "<form" not in html.lower()
        assert " action=" not in html.lower()
        assert "fetch(" not in html
        assert "XMLHttpRequest" not in html


def test_pc9_nonlinkable_contact_renders_as_plain_text_without_link(fake_bundle, fake_now, monkeypatch):
    """스킴·'@' 없는 연락처(플레이스홀더 등)는 링크 없이 평문으로 렌더된다(PC-12와 접점).

    기본값은 실 이메일(발견 #8)이라 이 평문 분기는 명시적으로 비링크 값을 주입해 검증한다.
    """
    custom_cfg = dataclasses.replace(CFG, policy_contact="{운영자 정정·문의 연락처}")
    monkeypatch.setattr(policy_module, "CFG", custom_cfg)
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert "{운영자 정정·문의 연락처}" in html
    correction_start = html.index('id="correction"')
    correction_html = html[correction_start : html.index("</section>", correction_start)]
    assert "<a href=" not in correction_html


def test_pc9_email_contact_renders_as_mailto_link_with_nofollow(fake_bundle, fake_now, monkeypatch):
    custom_cfg = dataclasses.replace(CFG, policy_contact="ops@jobcho.wiki")
    monkeypatch.setattr(policy_module, "CFG", custom_cfg)
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert 'href="mailto:ops@jobcho.wiki" rel="nofollow"' in html


def test_pc9_https_contact_renders_as_direct_link(fake_bundle, fake_now, monkeypatch):
    custom_cfg = dataclasses.replace(CFG, policy_contact="https://jobcho.wiki/contact")
    monkeypatch.setattr(policy_module, "CFG", custom_cfg)
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert 'href="https://jobcho.wiki/contact" rel="nofollow"' in html


# ── PC-10: 동의 배너↔정책 단일 진실(링크 대상 존재·도달, 사실 일치) ────────


def test_pc10_banner_target_routes_privacy_and_ads_exist_and_reachable(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    assert "privacy.html" in pages
    assert "ads.html" in pages
    assert pages["privacy.html"].html  # 렌더됨(비공백)
    assert pages["ads.html"].html


def test_pc10_privacy_and_ads_share_same_consent_facts(fake_bundle, fake_now):
    """P3·P4·P5(쿠키·제3자 Google·개인화 동의/거부) ≡ A-4(제3자 광고 쿠키·개인화
    동의) — 배너가 참조할 사실이 두 문서에서 동일하게 존재해야 한다(PC-10)."""
    pages = _render_policy_pages(fake_bundle, fake_now)
    privacy_html = pages["privacy.html"].html
    ads_html = pages["ads.html"].html
    for keyword in ("쿠키", "Google", "동의"):
        assert keyword in privacy_html, f"privacy.html에 '{keyword}' 부재"
        assert keyword in ads_html, f"ads.html에 '{keyword}' 부재"
    assert "거부" in privacy_html  # P5: 거부해도 이용 가능


def test_pc10_privacy_cross_links_to_ads_and_vice_versa(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    assert 'href="/ads"' in pages["privacy.html"].html  # P4 cross_route
    assert 'href="/privacy"' in pages["ads.html"].html  # A-4 cross_route


# ── PC-12: 시크릿 부재(4 HTML·콘텐츠 모듈) ──────────────────────────────


def test_pc12_no_secrets_in_rendered_policy_html(fake_bundle, fake_now):
    pages = _render_policy_pages(fake_bundle, fake_now)
    for path in POLICY_FILES:
        html = pages[path].html
        assert "DB_PASSWORD" not in html
        assert "mysql://" not in html
        assert not re.search(r"ca-pub-\d{10,}", html)


def test_pc12_content_and_config_modules_have_no_real_secrets():
    import inspect

    from generator import config as config_module
    from generator.content import policy as policy_content_module

    for mod in (config_module, policy_content_module):
        src = inspect.getsource(mod)
        assert "mysql://" not in src
        assert not re.search(r"ca-pub-\d{10,}", src)
        assert "BEGIN PRIVATE KEY" not in src


def test_pc12_policy_contact_env_unset_yields_real_email_default(monkeypatch):
    """env 미주입 시 기본 연락처는 실 이메일(발견 #8) — mailto 링크가 생성된다."""
    monkeypatch.delenv("POLICY_CONTACT", raising=False)
    cfg = GenConfig()
    assert cfg.policy_contact == "bji1062@gmail.com"
    assert policy_module._correction_href(cfg.policy_contact) == "mailto:bji1062@gmail.com"


def test_pc12_default_policy_values_leave_no_placeholder_braces(fake_bundle, fake_now):
    """발견 #8: 기본 CFG 렌더 시 중괄호 플레이스홀더가 남지 않는다(연락처·최종수정일)."""
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert "bji1062@gmail.com" in html
    assert "최종 수정일: 2026-07-19" in html
    assert "{운영자 정정·문의 연락처}" not in html
    assert "{게시 시 운영자 확정}" not in html


# ── GC-24: 정책 페이지 정적 광고·동의 배선(SP-ADS-9, 2026-07-19) ────────────


def test_gc24_policy_static_wiring_no_ads_but_consent(fake_bundle, fake_now):
    """정책 페이지: page_type=policy(무광고 게이팅)·광고 호스트 0. 동의 배너와
    static-ads.js는 base 공통 — 개인정보처리방침이 약속한 동의 선택 경로를
    모든 정적 페이지에서 제공한다(감사 #12 후속). render_all이 함께 렌더하는
    404.html은 page_type 미선언(→ ads.js 'default' 무광고)이 설계 의도."""
    for path, p in _render_policy_pages(fake_bundle, fake_now).items():
        if path == "404.html":
            assert "data-page-type" not in p.html, path    # 미선언 = default 무광고
        else:
            assert '<body data-page-type="policy">' in p.html, path
        assert 'id="consent-banner"' in p.html, path
        assert "/assets/v2/js/static-ads.js" in p.html, path
        assert "data-ad-position" not in p.html, path      # 무광고: 호스트 자체 미방출
        assert 'class="ad-slot"' not in p.html, path


# ── PC-14: 확정 게시(초안 배너 해제) + 옵트아웃 외부 링크 (2026-07-19 사용자 결정) ──


def test_pc14_default_render_has_no_draft_banner(fake_bundle, fake_now):
    """기본 CFG(legal_reviewed=True)에서 정책 4종·404 어디에도 초안 배너가 없다.
    배너 메커니즘 자체는 유지(PC-11) — env POLICY_LEGAL_REVIEWED=false로 재점등 가능."""
    for path, p in _render_policy_pages(fake_bundle, fake_now).items():
        assert "본 문서는 초안입니다" not in p.html, path
        assert 'class="policy-draft"' not in p.html, path


def test_pc14_privacy_and_ads_have_opt_out_links(fake_bundle, fake_now):
    """개인화 광고 옵트아웃 외부 링크 3종이 /privacy(P4)·/ads(A-4)에 렌더된다 —
    '거부할 수 있다' 안내만 있고 관리 경로가 0건이던 갭 해소(애드센스 심사 대비)."""
    pages = _render_policy_pages(fake_bundle, fake_now)
    for fname in ("privacy.html", "ads.html"):
        html = pages[fname].html
        for url in (
            "https://adssettings.google.com",
            "https://policies.google.com/technologies/partner-sites",
            "https://optout.aboutads.info",
        ):
            assert f'href="{url}"' in html, f"{fname}: {url} 부재"
        assert html.count('rel="noopener nofollow" target="_blank"') >= 3, fname
    # 무관 문서에는 미방출
    assert "adssettings.google.com" not in pages["terms.html"].html
