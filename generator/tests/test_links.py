"""T-07.7.5 내부 링크 404 없음 전역 검증 (GC-20).

전 생성 HTML(회사·조합·정책·404)의 내부 `href`(`/company/…`·`/vs/…`)가 실제
생성 파일 또는 허용 라우트(`/`·`/compare`·정책)에 매핑됨을 전역으로 검증한다
(FR-63 R1, 404 유입 방지).
"""
from __future__ import annotations

import re
from pathlib import Path

from generator.config import CFG
from generator.context import build_context
from generator.pages import about, combo, company, company_index, guide, policy
from generator.render import make_env

_ALLOWED_STATIC_ROUTES = {"/", "/compare", "/privacy", "/terms", "/disclaimer", "/ads"}
# /companies(회사 인덱스)는 생성 페이지이므로 허용 라우트가 아니라 `_build_all_pages`가
# 실제로 만들어 내는 페이지로 검증한다(존재하지 않으면 GC-20이 죽은 링크로 잡아야 한다).
_INTERNAL_HREF_RE = re.compile(r'href="(/[^"#][^"]*)"')


def _in_hidden_authnav_slot(html: str, href_pos: int) -> bool:
    """이 href 가 **숨겨진 로그인 진입점 슬롯**(SC14) 안에 있는지.

    GC-20 의 계약은 "**눌리는** 내부 링크에 죽은 것이 없음"이다. authnav 슬롯은 마크업에서
    `hidden` 이고 `authnav.js` 가 `/members/me` 프로브 결과로만 노출한다 — M9 가 꺼진 prod 에선
    영원히 숨겨진 채이고(그리고 그 경로는 nginx 가 의도적으로 404 로 막는다), 켜진 호스트에선
    비로소 실재하는 라우트가 된다. 즉 대상 유효성이 **환경 의존**이라 생성물 경로 집합으로
    판정할 수 없다. `/login` 을 `_ALLOWED_STATIC_ROUTES` 에 넣는 것은 "prod 에서도 해석된다"는
    **거짓 주장**이 되므로 택하지 않았다.

    대신 이 예외는 좁게 유지된다: "M9 링크는 **오직** 숨겨진 authnav 슬롯 안에만 존재해야 한다"를
    `test_authnav.py::test_no_visible_login_link_in_static_html` 이 반대 방향으로 강제한다.
    두 테스트를 합치면 GC-20 단독보다 강하다 — 노출된 M9 링크는 어느 쪽에서든 잡힌다.
    """
    start = html.rfind("<a", 0, href_pos)
    if start == -1:
        return False
    end = html.find(">", href_pos)
    if end == -1:
        return False
    tag = html[start:end + 1]
    return "data-authnav" in tag and "hidden" in tag


def _build_all_pages(fake_bundle, fake_now):
    """프로덕션(build.run)과 **동일 배선**으로 전 페이지를 만든다.

    combo_pairs를 넘기지 않으면 회사 페이지의 /vs/ 링크가 아예 방출되지 않아,
    죽은 조합 링크를 막으려고 만든 배선이 정작 이 404 가드의 사각지대에 남는다
    (2026-07-19 검수 반증). build.py와 같이 load_pairs 1회 → 양쪽 전달한다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    return (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + guide.render_all(env, ctx, CFG)  # 가이드 12+인덱스 (2026-07-29 신설)
        + about.render_all(env, ctx, CFG)  # 소개·문의 (2026-07-29 신설)
        + policy.render_all(env, ctx)
    )


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
        for m in _INTERNAL_HREF_RE.finditer(p.html):
            href = m.group(1)
            path_only = href.split("?", 1)[0].split("#", 1)[0]
            if path_only in _ALLOWED_STATIC_ROUTES:
                continue
            if path_only in generated_route_paths:
                continue
            if path_only.startswith("/assets/"):  # 정적 자산(css/font) 참조
                continue
            if _in_hidden_authnav_slot(p.html, m.start()):
                continue
            missing.append((p.path, href))

    assert not missing, f"미존재 링크(404 위험): {missing}"


def test_gc20_no_hrefs_point_to_404_page(fake_bundle, fake_now, fake_combinations_path):
    pages = _build_all_pages(fake_bundle, fake_now)
    for p in pages:
        for href in _INTERNAL_HREF_RE.findall(p.html):
            assert "/404" not in href


# ── GC-20b: 생성 라우트를 nginx 가 실제로 서빙하는가 (2026-07-29) ──────────────
# 클린 URL 은 nginx location 블록이 있어야만 해석된다. 새 페이지 타입을 만들고 conf 를
# 잊으면 사이트에는 링크가 보이는데 눌러 보면 404 인 상태가 된다 — 그리고 `release.sh` 는
# nginx conf 를 배포하지 않으므로(함정 ⑭) 이 실수는 배포 파이프라인이 잡아 주지 않는다.

NGINX_CONF = Path(__file__).resolve().parents[2] / "infra" / "nginx" / "loupit.conf"

# 정확일치 블록: `location = /guide {` / 접두 블록: `location ^~ /guide/ {`
_EXACT_LOC_RE = re.compile(r"location\s*=\s*(/\S*)")
_PREFIX_LOC_RE = re.compile(r"location\s*\^~\s*(/\S*?)\s*\{")


def _nginx_routes() -> tuple[set[str], list[str]]:
    conf = NGINX_CONF.read_text(encoding="utf-8")
    return set(_EXACT_LOC_RE.findall(conf)), _PREFIX_LOC_RE.findall(conf)


def test_gc20b_every_generated_route_has_an_nginx_location(fake_bundle, fake_now, fake_combinations_path):
    exact, prefixes = _nginx_routes()
    unserved = []
    for p in _build_all_pages(fake_bundle, fake_now):
        if not p.path.endswith(".html") or p.path == "404.html":
            continue
        route = "/" + p.path[: -len(".html")]
        if route in exact or any(route.startswith(pre) for pre in prefixes):
            continue
        unserved.append(route)
    assert not unserved, f"nginx location 없는 생성 라우트(클릭 시 404): {sorted(set(unserved))}"
