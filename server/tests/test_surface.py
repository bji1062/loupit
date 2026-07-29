"""T-04.5.* API 표면·미들웨어·CORS·라우팅 테스트 (SP-API-5·13, INV-1·INV-7).

TS-1·TS-2는 Tier-0 회귀 게이트(00 §5, #7·#8) — 어떤 경우에도 깨지면 안 됨.
"""
from __future__ import annotations

import pytest
from fastapi.routing import APIRoute


@pytest.fixture
def app_instance(monkeypatch):
    """앱 표면 검사 전용 — fake_data/client 픽스처 불필요(라우트/미들웨어 구조만 본다).

    ⚠ **웹훅 시크릿을 고정한다**(2026-07-29). `mail_webhook` 라우터는 `RESEND_WEBHOOK_SECRET`
    유무로 등록이 갈리는데, conftest 가 `server/.env` 를 로드하므로 **운영 서버에서 돌리면 켜지고
    새 체크아웃에서는 꺼져** 같은 코드가 서로 다른 표면을 낸다. Tier-0 게이트가 환경에 따라
    흔들리면 안 되므로 여기서 ON 으로 못박고, 기대 집합에 웹훅을 **명시 선언**한다
    (= 이 라우트도 "계획 밖 쓰기 0" 감시망 안에 그대로 둔다). OFF 쪽 계약은 MW-1 이 소유한다."""
    from server.config import get_settings
    from server.main import create_app

    monkeypatch.setenv("RESEND_WEBHOOK_SECRET", "whsec_dGVzdC1zdXJmYWNlLWZpeGVk")
    get_settings.cache_clear()
    try:
        yield create_app()
    finally:
        get_settings.cache_clear()


def test_TS1_participation_surface_exact(app_instance):
    """Tier-0(AU-1): API 표면 = 익명(GET 5 + 익명 비교 로그 POST 1) + SC14 참여 라우트 정확 집합.

    M9 참여 라우트(로그인·재직·복지편집)가 전부 착지해 이 베이스 게이트가 구 test_TS1_sc14(AU-1)를
    **흡수·통합**했다(두 게이트 수렴, T-13.1.2). 쓰기 = 익명 비교 로그 + 참여 쓰기(POST/PUT/DELETE)뿐,
    그 외 쓰기 0(계획 밖 쓰기가 끼면 깨짐 — INV-1). 공개 GET 에 me(세션)·edits(공개 이력)를 포함한다.
    익명 비교 로그(POST /comparisons/log)는 회사쌍 comp_id + 시각만 저장한다(test_schema_load
    TCOMPARE_LOG 컬럼 계약이 프라이버시 가드)."""
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
        ("/api/v1/comparisons/log", "POST"),                          # 익명(INV-1)
        ("/api/v1/members/login-code", "POST"),                       # FR-102 로그인 코드 발송
        ("/api/v1/members/login", "POST"),                            # FR-103 코드 검증·세션 발급
        ("/api/v1/members/logout", "POST"),                           # FR-104 로그아웃
        ("/api/v1/members/me", "PUT"),                                # FR-104 닉네임 변경
        ("/api/v1/members/me", "DELETE"),                             # FR-104 탈퇴
        ("/api/v1/employment/verify-code", "POST"),                   # FR-105 재직 코드 발송
        ("/api/v1/employment/verify", "POST"),                        # FR-106 재직 인증
        ("/api/v1/employment/requests", "POST"),                      # FR-107 수동 승인 요청
        # SP-AUTH-17(2026-07-29): 회사 등록 요청. 위 requests 와 형제지만 `comp_id` 를 받지
        # 않는다 — 검색에 **없는** 회사가 대상이라 참조할 ID 가 아직 없다. 요청은 회사를
        # 만들지 않고 큐에만 들어간다(등록은 운영자 판단).
        ("/api/v1/employment/company-requests", "POST"),
        ("/api/v1/companies/{comp_id}/benefits", "POST"),             # FR-108 복지 등록
        ("/api/v1/companies/{comp_id}/benefits/{benefit_id}", "PUT"), # FR-109 복지 수정
        # P1-4(SP-AUTH-16): 제공자(Resend/Svix)가 호출하는 **공개 POST**. 참여 라우트가 아니고
        # M9 게이트 밖이며, `RESEND_WEBHOOK_SECRET` 이 있을 때만 등록된다(위 픽스처가 고정).
        # 인증은 세션·CSRF 헤더가 아니라 **HMAC 서명**이다 — 익명 쓰기가 하나 더 늘었다는 사실을
        # Tier-0 표면에 정직하게 선언해 둔다.
        ("/api/v1/webhooks/resend", "POST"),
    }, f"참여 쓰기 표면 불일치(계획 밖 쓰기 금지): {write_routes}"

    expected_get_paths = {
        "/api/v1/health",
        "/api/v1/reference/all",
        "/api/v1/companies/search",
        "/api/v1/companies/{comp_id}",
        "/api/v1/comparisons/trending",
        "/api/v1/members/me",                    # FR-104 마이페이지(세션)
        "/api/v1/companies/{comp_id}/edits",     # FR-110 편집 이력 공개 열람
        "/api/v1/companies/{comp_id}/benefits",  # FR-109 편집용 조회(재직 게이트·base_dtm 부트스트랩)
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
