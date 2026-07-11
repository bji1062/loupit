"""T-07.7.5 내부 링크 404 없음 전역 검증 (GC-20).

전 생성 HTML(회사·조합·정책·404)의 내부 `href`(`/company/…`·`/vs/…`)가 실제
생성 파일 또는 허용 라우트(`/`·`/compare`·정책)에 매핑됨을 전역으로 검증한다
(FR-63 R1, 404 유입 방지).
"""
from __future__ import annotations

import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, policy
from generator.render import make_env

_ALLOWED_STATIC_ROUTES = {"/", "/compare", "/privacy", "/terms", "/disclaimer", "/ads"}
_INTERNAL_HREF_RE = re.compile(r'href="(/[^"#][^"]*)"')


def _build_all_pages(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return company.render_all(env, ctx) + combo.render_all(env, ctx, CFG) + policy.render_all(env, ctx)


def test_gc20_all_internal_hrefs_resolve_to_generated_pages_or_allowed_routes(
    fake_bundle, fake_now, fake_combinations_path
):
    pages = _build_all_pages(fake_bundle, fake_now)
    # canonical path 형태(예: /company/samsung-elec)로 정규화한 실제 생성 경로 집합
    generated_route_paths = set()
    for p in pages:
        route = "/" + p.path[:-len(".html")] if p.path.endswith(".html") else None
        if route:
            generated_route_paths.add(route)

    missing = []
    for p in pages:
        for href in _INTERNAL_HREF_RE.findall(p.html):
            path_only = href.split("?", 1)[0].split("#", 1)[0]
            if path_only in _ALLOWED_STATIC_ROUTES:
                continue
            if path_only in generated_route_paths:
                continue
            if path_only.startswith("/assets/"):  # 정적 자산(css/font) 참조
                continue
            missing.append((p.path, href))

    assert not missing, f"미존재 링크(404 위험): {missing}"


def test_gc20_no_hrefs_point_to_404_page(fake_bundle, fake_now, fake_combinations_path):
    pages = _build_all_pages(fake_bundle, fake_now)
    for p in pages:
        for href in _INTERNAL_HREF_RE.findall(p.html):
            assert "/404" not in href
