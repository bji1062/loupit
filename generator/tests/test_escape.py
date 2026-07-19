"""T-07.11.4 XSS 이스케이프 검증 (GC-21, Tier-0, NFR21).

`comp_nm="<script>alert(1)</script>삼성"` 주입 번들 렌더 시 출력에 실행
가능한 `<script>alert`가 부재해야 한다(autoescape). JSON-LD도 `<`로 안전.
구현측 담보 = `make_env` autoescape(T-07.4.1) + `jsonld_dumps`(T-07.4.4).
"""
from __future__ import annotations

from generator.context import build_context
from generator.pages import company
from generator.render import make_env


def _render_xss_company(fake_bundle_xss, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle_xss, now=fake_now)
    pages = company.render_all(env, ctx)
    return next(p for p in pages if p.path == "company/samsung-elec.html")


# ── GC-21 (Tier-0): 본문 XSS 이스케이프 ─────────────────────────────────


def test_gc21_script_tag_in_comp_nm_is_escaped_in_h1(fake_bundle_xss, fake_now):
    p = _render_xss_company(fake_bundle_xss, fake_now)
    assert "<script>alert" not in p.html
    assert "&lt;script&gt;alert(1)&lt;/script&gt;삼성" in p.html


def test_gc21_no_executable_script_alert_anywhere_in_page(fake_bundle_xss, fake_now):
    p = _render_xss_company(fake_bundle_xss, fake_now)
    # 허용 <script>는 두 가지 고정형뿐: JSON-LD와 base.html의 정적 광고·동의 진입점
    # (SP-ADS-9, 자체호스팅 고정 리터럴 — 사용자 데이터 비경유). 그 외는 전부 XSS 누수.
    import re

    static_ads_tag = '<script type="module" src="/assets/v2/js/static-ads.js" defer>'
    script_tags = re.findall(r"<script[^>]*>", p.html)
    assert all(
        'type="application/ld+json"' in tag or tag == static_ads_tag
        for tag in script_tags
    ), script_tags


def test_gc21_rendered_title_tag_content_is_escaped(fake_bundle_xss, fake_now):
    """`Page.title`은 순수 텍스트 메타데이터(중복 검증용, GC-7)이므로 이스케이프
    대상이 아니다 — 실제 HTML `<title>` 태그 **렌더 결과**가 안전해야 한다."""
    p = _render_xss_company(fake_bundle_xss, fake_now)
    assert "<script>alert" not in p.html[: p.html.index("</title>")]
    assert "&lt;script&gt;alert" in p.html[: p.html.index("</title>")]


# ── GC-21: JSON-LD도 안전(<로 이스케이프, breakout 차단) ────────────────────


def test_gc21_jsonld_script_breakout_is_escaped(fake_bundle_xss, fake_now):
    p = _render_xss_company(fake_bundle_xss, fake_now)
    ld_start = p.html.index('type="application/ld+json">') + len('type="application/ld+json">')
    ld_end = p.html.index("</script>", ld_start)
    ld_body = p.html[ld_start:ld_end]
    assert "<script>" not in ld_body
    assert "</script>" not in ld_body
    assert "\\u003c" in ld_body  # comp_nm의 "<"가 유니코드 이스케이프됨


def test_gc21_jsonld_still_parses_as_valid_json(fake_bundle_xss, fake_now):
    import json

    p = _render_xss_company(fake_bundle_xss, fake_now)
    ld_start = p.html.index('type="application/ld+json">') + len('type="application/ld+json">')
    ld_end = p.html.index("</script>", ld_start)
    data = json.loads(p.html[ld_start:ld_end])
    assert data["name"] == "<script>alert(1)</script>삼성"  # 파싱 후엔 원문과 동치


# ── autoescape 환경 자체의 구조적 보장(회귀 방지) ───────────────────────────


def test_gc21_make_env_has_autoescape_enabled():
    env = make_env()
    assert env.autoescape(".html") is True
    assert env.autoescape(".xml") is True


def test_gc21_make_env_uses_strict_undefined():
    import jinja2

    env = make_env()
    assert env.undefined is jinja2.StrictUndefined
