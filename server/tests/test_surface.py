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
    """Tier-0: 익명 표면 = GET 5종 + 쓰기(익명 비교 로그 + M9 로그인 흐름, 현행 실제 등록분).

    익명 비교 로그(POST /comparisons/log)는 회사쌍 comp_id + 시각만 저장한다(사용자 식별자·
    입력값 무저장, test_schema_load TCOMPARE_LOG 컬럼 계약이 프라이버시 가드). SC14 참여 쓰기는
    라우트 본체가 착지하며 점증하므로, 본 베이스 게이트는 **현재 실제 등록된 쓰기 표면**을
    정확일치로 고정한다(계획 밖 쓰기가 끼면 깨짐 — INV-1). 전체 목표 집합(쓰기 11·GET 7)은
    아래 test_TS1_sc14(AU-1)가 소유하며, 참여 라우트가 전부 착지하면 두 게이트가 수렴한다."""
    write_methods = {"POST", "PUT", "PATCH", "DELETE"}
    seen_paths_methods: set[tuple[str, str]] = set()
    write_routes: set[tuple[str, str]] = set()

    for route in app_instance.routes:
        if not isinstance(route, APIRoute):
            continue
        for method in route.methods:
            if method in write_methods:
                write_routes.add((route.path, method))
            seen_paths_methods.add((route.path, method))

    assert write_routes == {
        ("/api/v1/comparisons/log", "POST"),     # 익명(INV-1)
        ("/api/v1/members/login-code", "POST"),  # FR-102 로그인 코드 발송
        ("/api/v1/members/login", "POST"),       # FR-103 코드 검증·세션 발급
        ("/api/v1/members/logout", "POST"),      # FR-104 로그아웃
        ("/api/v1/members/me", "PUT"),           # FR-104 닉네임 변경
        ("/api/v1/members/me", "DELETE"),        # FR-104 탈퇴
    }, f"현행 쓰기 표면 불일치(계획 밖 쓰기 금지): {write_routes}"

    expected_get_paths = {
        "/api/v1/health",
        "/api/v1/reference/all",
        "/api/v1/companies/search",
        "/api/v1/companies/{comp_id}",
        "/api/v1/comparisons/trending",
        "/api/v1/members/me",                    # FR-104 마이페이지(세션)
    }
    get_paths = {path for (path, method) in seen_paths_methods if method == "GET"}
    assert get_paths == expected_get_paths


def test_TS2_middleware_is_cors_only_no_auth_no_session(app_instance):
    """Tier-0: 미들웨어 = CORS 1종·무인증·무세션 (INV-1).

    **SC14 불변(§C: TS-2 어서션 원문 유지)**: 참여 세션·재직 검증은 미들웨어가 아니라
    라우트 의존성(`require_member`/`require_employment`)이라 SC14 후에도 이 어서션은 그대로
    참이다(INV-9 = `app.user_middleware == ['CORSMiddleware']`). 그래서 sc14 마커 없이 상시."""
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
    # SC14 후에도 그대로: 참여 쓰기(PUT/DELETE)는 동일 오리진(nginx 프록시)이라 preflight 불요이며,
    # CORS 는 의도적으로 PUT/DELETE 를 광고하지 않는다(SP-AUTH-12: 크로스오리진 쓰기는 preflight
    # 실패로 차단 = CSRF 방어). 따라서 이 집합은 sc14 마커 없이 상시 그린이다.
    assert allowed == {"GET", "HEAD", "OPTIONS", "POST"}


@pytest.mark.sc14
def test_TS1_sc14_participation_surface(app_instance):
    """AU-1(SC14): API 표면 = 익명(GET 5 + 로그 POST 1)에 SC14 참여 라우트를 더한 정확 집합
    (§C item3 — TS-1 확장). 쓰기는 익명 로그 + 참여 쓰기(POST/PUT/DELETE), 공개 GET 에 me·edits.

    구현(M9) 전엔 참여 라우트 부재라 RED → @pytest.mark.sc14 로 베이스 게이트 제외. base TS-1 은
    현 익명 표면(GET 5 + 로그 POST 1)을 지키며, M9 구현 시 본 집합으로 갱신·통합된다."""
    write_methods = {"POST", "PUT", "PATCH", "DELETE"}
    seen: set[tuple[str, str]] = set()
    writes: list[tuple[str, str]] = []
    for route in app_instance.routes:
        if not isinstance(route, APIRoute):
            continue
        for method in route.methods:
            if method in write_methods:
                writes.append((route.path, method))
            seen.add((route.path, method))

    expected_writes = {
        ("/api/v1/comparisons/log", "POST"),                          # 익명(INV-1)
        ("/api/v1/members/login-code", "POST"),                       # FR-102
        ("/api/v1/members/login", "POST"),                            # FR-103
        ("/api/v1/members/logout", "POST"),                           # FR-104
        ("/api/v1/members/me", "PUT"),                                # FR-104
        ("/api/v1/members/me", "DELETE"),                             # FR-104
        ("/api/v1/employment/verify-code", "POST"),                   # FR-105
        ("/api/v1/employment/verify", "POST"),                        # FR-106
        ("/api/v1/employment/requests", "POST"),                      # FR-107
        ("/api/v1/companies/{comp_id}/benefits", "POST"),             # FR-108
        ("/api/v1/companies/{comp_id}/benefits/{benefit_id}", "PUT"), # FR-109
    }
    assert set(writes) == expected_writes, f"SC14 쓰기 표면 불일치: {set(writes) ^ expected_writes}"

    expected_get = {
        "/api/v1/health",
        "/api/v1/reference/all",
        "/api/v1/companies/search",
        "/api/v1/companies/{comp_id}",
        "/api/v1/comparisons/trending",
        "/api/v1/members/me",                        # FR-104(세션)
        "/api/v1/companies/{comp_id}/edits",         # FR-110 공개 열람
    }
    gets = {path for (path, method) in seen if method == "GET"}
    assert gets == expected_get, f"SC14 GET 표면 불일치: {gets ^ expected_get}"
