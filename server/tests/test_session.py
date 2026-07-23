"""SP-AUTH-4 세션 — 발급(해시만)·검증·폐기·쿠키·퍼지 (T-13.5.1).

무 DB — database.execute/fetch_one 을 monkeypatch. 세션 토큰 원문이 저장 파라미터에 새지
않고 해시(CHAR64)만 저장됨(INV-8·AS-3), resolve 가 미만료·미폐기만 조회함(AS-2), 쿠키 속성
(AS-1)을 검증한다.
"""
from __future__ import annotations

import pytest
from fastapi import Response

from server.services import session


@pytest.mark.asyncio
async def test_issue_session_stores_hash_not_raw(monkeypatch):
    """AS-3: DB엔 토큰 SHA-256 해시만 — 원문 미저장."""
    calls = []

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    monkeypatch.setattr(session.database, "execute", _exec)
    raw = await session.issue_session(42)

    assert isinstance(raw, str) and len(raw) > 20
    sql, params = calls[-1]
    assert "INSERT INTO TSESSION" in sql
    assert raw not in str(params)                # 원문 미저장
    assert session._hash_token(raw) in params    # 해시 저장(CHAR64)
    assert 42 in params                          # mbr_id


@pytest.mark.asyncio
async def test_resolve_session_none_for_empty():
    assert await session.resolve_session(None) is None
    assert await session.resolve_session("") is None


@pytest.mark.asyncio
async def test_resolve_session_queries_active_only(monkeypatch):
    """AS-2: 미만료·미폐기 세션만 조회(SQL 조건으로 강제)."""
    captured = {}

    async def _fetch_one(sql, params=()):
        captured["sql"], captured["params"] = sql, params
        return {"MBR_ID": 9}

    monkeypatch.setattr(session.database, "fetch_one", _fetch_one)
    m = await session.resolve_session("raw-token")

    assert m == {"MBR_ID": 9}
    assert "REVOKED_DTM IS NULL" in captured["sql"]
    assert "EXPIRES_DTM > UTC_TIMESTAMP()" in captured["sql"]
    assert session._hash_token("raw-token") in captured["params"]  # 해시로 조회
    assert "raw-token" not in str(captured["params"])              # 원문 미사용


@pytest.mark.asyncio
async def test_revoke_session_sets_revoked(monkeypatch):
    calls = []

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    monkeypatch.setattr(session.database, "execute", _exec)
    await session.revoke_session("raw")
    sql, params = calls[-1]
    assert "UPDATE TSESSION SET REVOKED_DTM" in sql
    assert session._hash_token("raw") in params


@pytest.mark.asyncio
async def test_purge_expired_deletes_sessions_and_codes(monkeypatch):
    calls = []

    async def _exec(sql, params=()):
        calls.append(sql)
        return 3

    monkeypatch.setattr(session.database, "execute", _exec)
    n = await session.purge_expired()
    assert n == 3
    assert any("DELETE FROM TSESSION" in s for s in calls)
    assert any("DELETE FROM TAUTH_CODE" in s for s in calls)


def test_set_session_cookie_attributes():
    """AS-1: 세션 쿠키 = HttpOnly·Secure·SameSite=Lax·Path=/api/v1."""
    resp = Response()
    session.set_session_cookie(resp, "tok")
    cookie = resp.headers.get("set-cookie", "").lower()
    assert "loupit_sid=tok" in cookie
    assert "httponly" in cookie
    assert "secure" in cookie
    assert "samesite=lax" in cookie
    assert "path=/api/v1" in cookie


def test_clear_session_cookie_expires_same_path():
    resp = Response()
    session.clear_session_cookie(resp)
    cookie = resp.headers.get("set-cookie", "").lower()
    assert "loupit_sid=" in cookie
    assert "path=/api/v1" in cookie
