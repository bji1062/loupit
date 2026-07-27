"""M9 활성화 게이트(`M9_ENABLED`) — 참여 라우터 등록·세션 퍼지의 조건부 배선.

**왜 필요한가(2026-07-27 발견)**: `server/main.py` 는 참여 라우터 3종(member·employment·
benefit_edit)을 **무조건** 등록했다. 프로덕션이 inert 했던 유일한 이유는 `loupit-api` 프로세스가
2026-07-20 기동 이후 재시작되지 않아 SC14 코드를 아직 로드하지 않았다는 것뿐이다 — prod 와 beta 는
같은 소스 트리(`WorkingDirectory=/home/ubuntu/loupit`)를 쓰며, 재시작한 beta 는 참여 라우트가 살아
있고(401/200) 재시작 안 한 prod 만 404 다.

즉 **재부팅·`systemctl restart`·release.sh 를 경유하지 않는 어떤 배포**든 서빙 스키마에 참여
테이블이 0/7 인 상태로 M9 API 표면(쓰기 라우트 포함)을 켜 버린다. `release.sh` 의 M9 활성화
가드는 릴리스 경로만 막지 이 경로를 막지 못한다.

**계약**: 설정 플래그 하나(`M9_ENABLED`, 기본 false)가 다음을 동시에 뒤집는다.
  (A) 참여 라우터 3종 등록      — 본 파일
  (B) 세션·코드 retention purge — 본 파일
  (C) 정책 페이지 문안(P7·T5)   — test_policy_m9 (로그인 배포와 문안 전환의 원자성)

OFF 일 때 표면은 **SC14 이전 익명 계약과 정확히 동일**해야 한다(INV-1: GET 5종 + 익명 비교 로그
POST 1종). ON 일 때는 test_surface.TS-1 이 소유하는 참여 포함 표면이 된다.

무 DB 테스트 — 앱 조립 구조만 본다.
"""
from __future__ import annotations

import pytest
from fastapi.routing import APIRoute

# SC14 이전 익명 계약(INV-1) — OFF 표면의 정본. test_surface.TS-1 의 ON 표면과 대비된다.
ANONYMOUS_GET_PATHS = {
    "/api/v1/health",
    "/api/v1/reference/all",
    "/api/v1/companies/search",
    "/api/v1/companies/{comp_id}",
    "/api/v1/comparisons/trending",
}
ANONYMOUS_WRITE_ROUTES = {("/api/v1/comparisons/log", "POST")}


def _surface(app) -> tuple[set[str], set[tuple[str, str]]]:
    """(GET 경로 집합, 쓰기 (경로,메서드) 집합)."""
    write_methods = {"POST", "PUT", "PATCH", "DELETE"}
    gets: set[str] = set()
    writes: set[tuple[str, str]] = set()
    for route in app.routes:
        if not isinstance(route, APIRoute):
            continue
        for method in route.methods:
            if method == "GET":
                gets.add(route.path)
            if method in write_methods:
                writes.add((route.path, method))
    return gets, writes


@pytest.fixture
def app_with_m9(monkeypatch):
    """`M9_ENABLED` 를 임의 값으로 고정한 앱을 만드는 팩토리.

    `get_settings` 가 `@lru_cache` 싱글턴이라 환경변수만 바꿔선 안 되고 캐시를 비워야 한다.
    teardown 에서 다시 비워, 이 테스트가 뒤 테스트의 설정을 오염시키지 않게 한다
    (conftest 가 세션 전역으로 `M9_ENABLED=1` 을 넣어두므로 복원 후 캐시만 비우면 된다)."""
    from server.config import get_settings
    from server.main import create_app

    def _make(value: str | None):
        if value is None:
            monkeypatch.delenv("M9_ENABLED", raising=False)
        else:
            monkeypatch.setenv("M9_ENABLED", value)
        get_settings.cache_clear()
        return create_app()

    yield _make
    get_settings.cache_clear()


def test_M9G1_default_is_off(monkeypatch):
    """기본값 = OFF. 프로덕션 `server/.env` 에 키가 없으므로 재시작해도 M9 는 안 켜진다.

    이 어서션이 깨지면(기본 true 로 바뀌면) 재시작 함정이 그대로 부활한다."""
    from server.config import Settings

    monkeypatch.delenv("M9_ENABLED", raising=False)
    s = Settings(_env_file=None)
    assert s.m9_enabled is False


def test_M9G2_off_surface_equals_anonymous_contract(app_with_m9):
    """OFF: 표면이 SC14 이전 익명 계약과 **정확히** 같다 — 참여 라우트 0개(INV-1)."""
    app = app_with_m9(None)
    gets, writes = _surface(app)

    assert writes == ANONYMOUS_WRITE_ROUTES, f"OFF 인데 참여 쓰기 라우트 노출: {writes}"
    assert gets == ANONYMOUS_GET_PATHS, f"OFF 인데 참여 GET 라우트 노출: {gets}"

    # 참여 경로 접두사가 어떤 메서드로도 등록되지 않았는지 직접 확인(위 정확일치의 이중 가드)
    all_paths = {r.path for r in app.routes if isinstance(r, APIRoute)}
    for marker in ("/members", "/employment", "/edits", "/benefits"):
        assert not any(marker in p for p in all_paths), f"OFF 인데 {marker} 경로 잔존: {all_paths}"


def test_M9G3_on_registers_participation_routes(app_with_m9):
    """ON: 참여 라우트가 등록된다(정확 집합은 test_surface.TS-1 이 소유)."""
    app = app_with_m9("1")
    gets, writes = _surface(app)

    assert ("/api/v1/members/login", "POST") in writes
    assert ("/api/v1/employment/verify", "POST") in writes
    assert ("/api/v1/companies/{comp_id}/benefits", "POST") in writes
    assert "/api/v1/members/me" in gets
    assert "/api/v1/companies/{comp_id}/edits" in gets


def test_M9G4_off_keeps_middleware_contract(app_with_m9):
    """OFF 여도 미들웨어 계약은 불변(INV-9) — 게이트가 미들웨어를 건드리지 않는다."""
    app = app_with_m9(None)
    assert [m.cls.__name__ for m in app.user_middleware] == ["CORSMiddleware"]


@pytest.mark.asyncio
async def test_M9G5_off_skips_session_purge(monkeypatch):
    """OFF: 세션 retention purge 를 **호출하지 않는다**.

    OFF 스키마엔 `TSESSION`·`TAUTH_CODE` 가 없어 호출하면 매 주기 예외가 로그를 오염시킨다
    (현행은 try/except 로 삼키지만 journalctl 에 일 1회 스택이 쌓인다)."""
    from server import main as main_mod

    called = False

    async def _spy() -> int:
        nonlocal called
        called = True
        return 0

    monkeypatch.setattr(main_mod.session_service, "purge_expired", _spy)
    await main_mod._purge_sessions_safe(m9_enabled=False)
    assert called is False, "OFF 인데 세션 퍼지를 호출했다"


@pytest.mark.asyncio
async def test_M9G6_on_runs_session_purge(monkeypatch):
    """ON: 세션 retention purge 를 호출한다(SP-AUTH-4 보존 계약 유지)."""
    from server import main as main_mod

    called = False

    async def _spy() -> int:
        nonlocal called
        called = True
        return 0

    monkeypatch.setattr(main_mod.session_service, "purge_expired", _spy)
    await main_mod._purge_sessions_safe(m9_enabled=True)
    assert called is True, "ON 인데 세션 퍼지를 건너뛰었다"
