"""SP-AUTH-12 CSRF·전송 헤더 계약 (AC-*, T-13.13.1).

상태변경(POST/PUT/DELETE) 요청은 커스텀 헤더 `X-Loupit-Client` 필수 — 없으면 403(FR-113).
nginx Layer A 게이트에 더한 앱 레벨 이중 검사(미들웨어 아닌 Depends, INV-9). 익명 GET·
익명 비교 로그(sendBeacon, 커스텀 헤더 불가)는 대상 아님.
"""
from __future__ import annotations

import httpx
import pytest
import pytest_asyncio

_CSRF = {"X-Loupit-Client": "web"}


@pytest_asyncio.fixture
async def csrf_client(monkeypatch):
    """기본 헤더 없는 클라이언트 — CSRF 게이트만 검증(DB는 최소 스텁)."""
    from server import database
    from server.main import create_app

    async def _fetch_one(sql, params=()):
        return None  # 세션·회사 없음 → require_member 401 / company_exists 404

    async def _execute(sql, params=()):
        return 1  # issue_login_code INSERT 흡수

    async def _insert_compare_log(a, b):
        return None  # 익명 비교 로그(CSRF 비대상) 흡수

    async def _noop():
        return None

    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    monkeypatch.setattr(database, "execute", _execute)
    monkeypatch.setattr(database, "insert_compare_log", _insert_compare_log)
    monkeypatch.setattr(database, "init_pool", _noop)
    monkeypatch.setattr(database, "close_pool", _noop)

    app = create_app()
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:  # 기본 헤더 없음
        yield c


_BENEFIT = {"benefit_cd": "meal", "benefit_nm": "식대", "benefit_ctgr_cd": "compensation", "benefit_amt": 1}


@pytest.mark.asyncio
async def test_AC1_login_code_write_without_csrf_header_403(csrf_client):
    """세션 불필요 쓰기(login-code)도 CSRF 헤더 부재면 403(FR-113)."""
    r = await csrf_client.post("/api/v1/members/login-code", json={"email": "a@b.com"})
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_AC1_benefit_write_without_csrf_before_auth_403(csrf_client):
    """쓰기 CSRF 게이트가 인증(401/403)보다 먼저 — 무쿠키·무헤더 쓰기는 403(CSRF)."""
    r = await csrf_client.post("/api/v1/companies/10/benefits", json=_BENEFIT)
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_AC1_put_and_delete_without_csrf_403(csrf_client):
    r_put = await csrf_client.put("/api/v1/companies/10/benefits/1",
                                  json={"base_dtm": "x", "benefit_nm": "식대", "benefit_amt": 1})
    assert r_put.status_code == 403
    r_del = await csrf_client.delete("/api/v1/members/me")
    assert r_del.status_code == 403


@pytest.mark.asyncio
async def test_AC1_with_csrf_header_passes_gate(csrf_client):
    """헤더가 있으면 CSRF 게이트 통과 → 다음 단계 진행(login-code 균일 204)."""
    r = await csrf_client.post("/api/v1/members/login-code", json={"email": "a@b.com"}, headers=_CSRF)
    assert r.status_code == 204


@pytest.mark.asyncio
async def test_AC2_anonymous_get_edits_no_csrf_required(csrf_client):
    """익명 GET(편집 이력)은 CSRF 불요 — 미존재 회사라 404로 통과(403 아님)."""
    r = await csrf_client.get("/api/v1/companies/999/edits")
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_AC2_get_me_no_csrf_is_401_not_403(csrf_client):
    """세션 GET(me)도 CSRF 불요 — 무쿠키는 인증 401(CSRF 403 아님)."""
    r = await csrf_client.get("/api/v1/members/me")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_AC2_anonymous_compare_log_not_csrf_gated(csrf_client):
    """익명 비교 로그(POST /comparisons/log)는 sendBeacon(커스텀 헤더 불가)이라 CSRF 대상 아님 —
    헤더 없이도 403이 아니다(nginx = 블록 예외와 정합)."""
    r = await csrf_client.post("/api/v1/comparisons/log", json={"a": 1, "b": 2})
    assert r.status_code != 403
