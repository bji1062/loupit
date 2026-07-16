"""T-04.5.* API 표면·미들웨어·CORS·라우팅 테스트 (SP-API-5·13, INV-1·INV-7).

TS-1·TS-2는 Tier-0 회귀 게이트(00 §5, #7·#8) — 어떤 경우에도 깨지면 안 됨.
"""
from __future__ import annotations

import pytest
from fastapi.routing import APIRoute


@pytest.fixture
def app_instance():
    """앱 표면 검사 전용 — fake_data/client 픽스처 불필요(라우트/미들웨어 구조만 본다)."""
    from server.main import create_app

    return create_app()


def test_TS1_get_five_endpoints_plus_single_anonymous_log_post(app_instance):
    """Tier-0: API 표면 = GET 5종 + 익명 비교 로그 POST 정확히 1종 (INV-1 개정 2026-07-14).

    "실시간 비교 TOP 10" 위젯을 위해 POST /comparisons/log 하나만 허용한다 —
    저장은 회사쌍 comp_id + 시각뿐(사용자 식별자·입력값 무저장, test_schema_load
    TCOMPARE_LOG 컬럼 계약이 프라이버시 가드). 그 외 쓰기 라우트가 늘어나면
    본 게이트가 깨진다 — 추가하려면 INV-1 재개정이 선행돼야 한다."""
    write_methods = {"POST", "PUT", "PATCH", "DELETE"}
    seen_paths_methods: set[tuple[str, str]] = set()
    write_routes = []

    for route in app_instance.routes:
        if not isinstance(route, APIRoute):
            continue
        for method in route.methods:
            if method in write_methods:
                write_routes.append((route.path, method))
            seen_paths_methods.add((route.path, method))

    assert write_routes == [("/api/v1/comparisons/log", "POST")], (
        f"허용된 쓰기 라우트는 익명 비교 로그 POST 1종뿐: {write_routes}"
    )

    expected_get_paths = {
        "/api/v1/health",
        "/api/v1/reference/all",
        "/api/v1/companies/search",
        "/api/v1/companies/{comp_id}",
        "/api/v1/comparisons/trending",
    }
    get_paths = {path for (path, method) in seen_paths_methods if method == "GET"}
    assert get_paths == expected_get_paths


def test_TS2_middleware_is_cors_only_no_auth_no_session(app_instance):
    """Tier-0: 미들웨어 = CORS 1종·무인증·무세션 (INV-1)."""
    middleware_names = [m.cls.__name__ for m in app_instance.user_middleware]

    forbidden_substrings = ("auth", "session")
    for name in middleware_names:
        lowered = name.lower()
        for bad in forbidden_substrings:
            assert bad not in lowered, f"인증/세션 미들웨어 발견 금지: {name}"

    assert "CORSMiddleware" in middleware_names
    assert middleware_names == ["CORSMiddleware"], f"CORS 외 미들웨어 발견: {middleware_names}"


@pytest.mark.asyncio
async def test_TM1_post_to_get_only_route_is_405_with_allow_header(client):
    resp = await client.post("/api/v1/companies/search")
    assert resp.status_code == 405
    assert "GET" in resp.headers.get("allow", "")


@pytest.mark.asyncio
async def test_TL1_head_allowed_on_get_routes(client):
    """L-1 회귀: GET 라우트는 HEAD도 허용(405 아님) — 헬스체크·스모크의 HEAD 요청이
    405로 실패하던 문제 방지. CORS preflight가 광고하는 GET/HEAD/OPTIONS(test_TCORS2)와
    실제 라우트 메서드를 일치시킨다. HEAD 응답은 본문 없이 200(ASGI가 바디 스트립).
    (/reference/all은 bundle_stub 필요 → test_reference.py::test_TR7에서 별도 검증.)"""
    for path in ("/api/v1/health", "/api/v1/companies/search?q=삼성", "/api/v1/companies/1"):
        resp = await client.head(path)
        assert resp.status_code == 200, f"HEAD {path} → {resp.status_code} (200 기대, 405 금지)"
        assert resp.content == b"", f"HEAD {path} 본문 비어야 함"


@pytest.mark.asyncio
async def test_TN1_unregistered_path_is_404(client):
    resp = await client.get("/api/v1/nonexistent")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_TCORS1_allowed_origin_echoed_not_wildcard(client):
    resp = await client.get("/api/v1/health", headers={"Origin": "https://jobcho.wiki"})
    assert resp.headers.get("access-control-allow-origin") == "https://jobcho.wiki"
    assert resp.headers.get("access-control-allow-origin") != "*"


@pytest.mark.asyncio
async def test_TCORS2_preflight_allows_get_head_options_post_only(client):
    """PUT/PATCH/DELETE 미광고 — POST는 익명 비교 로그 1종용(INV-1 개정 2026-07-14)."""
    resp = await client.options(
        "/api/v1/companies/search",
        headers={
            "Origin": "https://jobcho.wiki",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code in (200, 204)
    allow_methods = resp.headers.get("access-control-allow-methods", "")
    allowed = {m.strip() for m in allow_methods.split(",")}
    assert allowed == {"GET", "HEAD", "OPTIONS", "POST"}
