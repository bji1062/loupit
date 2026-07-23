"""SP-AUTH-4 require_member 의존성 — 세션 없음/무효 401, 유효 시 회원 반환 (T-13.5.2, AM-1)."""
from __future__ import annotations

import pytest
from fastapi import HTTPException

from server import deps


@pytest.mark.asyncio
async def test_require_member_no_cookie_401(monkeypatch):
    async def _resolve(raw):
        return None

    monkeypatch.setattr(deps.session, "resolve_session", _resolve)
    with pytest.raises(HTTPException) as ei:
        await deps.require_member(loupit_sid=None)
    assert ei.value.status_code == 401


@pytest.mark.asyncio
async def test_require_member_invalid_session_401(monkeypatch):
    async def _resolve(raw):
        return None  # 만료·폐기·위조 → resolve None

    monkeypatch.setattr(deps.session, "resolve_session", _resolve)
    with pytest.raises(HTTPException) as ei:
        await deps.require_member(loupit_sid="forged-or-expired")
    assert ei.value.status_code == 401


@pytest.mark.asyncio
async def test_require_member_valid_returns_member(monkeypatch):
    async def _resolve(raw):
        return {"MBR_ID": 7} if raw == "good" else None

    monkeypatch.setattr(deps.session, "resolve_session", _resolve)
    assert await deps.require_member(loupit_sid="good") == {"MBR_ID": 7}
