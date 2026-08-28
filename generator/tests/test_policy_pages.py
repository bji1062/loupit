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
from generator.config import (
    CFG,
    POLICY_CONTACT_FALLBACK,
    POLICY_LAST_MODIFIED_FALLBACK,
    GenConfig,
)
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
    """P3·P4·P5 ≡ A-4 — 두 문서가 같은 사실을 말해야 한다(PC-10). 2026-08-28 부터 그 사실은
    "동의를 받는다"가 아니라 **"개인화를 요청하지 않는다"** 다 — 한쪽만 고치면 여기서 잡힌다."""
    pages = _render_policy_pages(fake_bundle, fake_now)
    privacy_html = pages["privacy.html"].html
    ads_html = pages["ads.html"].html
    for keyword in ("쿠키", "Google", "비개인화"):
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

    # 진짜 시크릿(DB URL·개인키)은 어느 모듈에도 없어야 한다.
    for mod in (config_module, policy_content_module):
        src = inspect.getsource(mod)
        assert "mysql://" not in src
        assert "BEGIN PRIVATE KEY" not in src

    # AdSense 게시자 ID(ca-pub-…)는 **공개값**이라 시크릿이 아니다 — ads.txt·모든 페이지 광고
    # 코드에 노출된다. 2026-07-21 애드센스 활성화로 config.py에 정당하게 존재한다(render_ads_txt
    # 소스). 단 정책 문안(policy content)에는 클라이언트 id가 들어갈 이유가 없으므로 거기선 여전히 금지.
    assert not re.search(r"ca-pub-\d{10,}", inspect.getsource(policy_content_module)), \
        "정책 문안에 광고 client id가 섞였다 — 문맥상 오류"


def test_pc12_policy_contact_fallback_is_a_real_email():
    """env 미주입 시 폴백 연락처는 실 이메일(발견 #8) — mailto 링크가 생성된다.

    ⚠ 이 테스트는 일부러 `GenConfig()` 를 보지 않는다. `policy_contact` 는 dataclass
    필드 기본값이라 **모듈 임포트 시점의 env 로 고정**되고, `monkeypatch.delenv` 는
    이미 고정된 값을 되돌리지 못한다. 구판은 그 사실을 모른 채 delenv 후
    `GenConfig().policy_contact == "bji1062@gmail.com"` 를 단정했고, 그래서
    POLICY_CONTACT 가 없는 CI 에서만 초록이고 운영 env 가 있는 배포 호스트에서는
    빨갰다(2026-08-27 릴리스가 [2/5] 에서 여기서 멈췄다). 폴백 계약은 폴백 상수로
    검증한다 — env 로 오염될 수 없는 유일한 지점이다. → 함정 0079
    """
    assert re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", POLICY_CONTACT_FALLBACK), (
        f"폴백 연락처가 실 이메일이 아니다: {POLICY_CONTACT_FALLBACK!r} — "
        "플레이스홀더가 라이브에 노출되던 발견 #8 의 재발"
    )
    assert "{" not in POLICY_CONTACT_FALLBACK and "}" not in POLICY_CONTACT_FALLBACK
    assert (
        policy_module._correction_href(POLICY_CONTACT_FALLBACK)
        == f"mailto:{POLICY_CONTACT_FALLBACK}"
    )
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", POLICY_LAST_MODIFIED_FALLBACK)


def test_pc12_rendered_policy_leaves_no_placeholder_braces(fake_bundle, fake_now):
    """발견 #8: 렌더 결과에 중괄호 플레이스홀더가 남지 않는다(연락처·최종수정일).

    단정은 **실효 설정값**(CFG)을 기준으로 한다 — 운영자가 POLICY_CONTACT 를 주입한
    호스트에서도 같은 계약이 성립해야 하기 때문이다. 특정 주소 리터럴을 박으면
    "운영자가 연락처를 바꾸면 테스트가 깨지는" 결합이 생긴다(그게 이 파일이 겪은 일이다).
    """
    pages = _render_policy_pages(fake_bundle, fake_now)
    html = pages["disclaimer.html"].html
    assert CFG.policy_contact in html, "실효 연락처가 렌더되지 않았다"
    assert f"최종 수정일: {CFG.policy_last_modified}" in html
    assert "{운영자 정정·문의 연락처}" not in html
    assert "{게시 시 운영자 확정}" not in html
    # 미치환 플레이스홀더 일반 검출 — 위 두 개만 막으면 새 플레이스홀더가 그대로 나간다.
    assert not re.search(r"\{[가-힣][^{}]*\}", html), (
        f"미치환 플레이스홀더 잔존: {re.findall(r'{[가-힣][^{}]*}', html)}"
    )


# ── GC-24: 정책 페이지 정적 광고·동의 배선(SP-ADS-9, 2026-07-19) ────────────


def test_gc24_policy_static_wiring_no_ads_no_consent_banner(fake_bundle, fake_now):
    """정책 페이지: page_type=policy(무광고 게이팅)·광고 호스트 0·**동의 배너 0**.

    배너는 2026-08-28 제거했다(SP-ADS-7): 광고를 항상 비개인화로 요청하므로 물을 것이 없고,
    자체 UI 는 구글 인증 CMP 가 아니라 EEA 요건도 못 채운다. 개인화 거부는 처리방침 P4·광고고지
    A-4 의 외부 옵트아웃 링크가 담당한다 — 배너 **부재**를 계약으로 못박는다(되살리면 그 문안과
    어긋난다). static-ads.js 는 광고 마운트용으로 남는다. 404.html 은 page_type 미선언(무광고)."""
    for path, p in _render_policy_pages(fake_bundle, fake_now).items():
        if path == "404.html":
            assert "data-page-type" not in p.html, path    # 미선언 = default 무광고
        else:
            assert '<body data-page-type="policy">' in p.html, path
        assert 'id="consent-banner"' not in p.html, path   # 배너 제거(SP-ADS-7, 2026-08-28)
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
