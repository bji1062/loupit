"""SP-AUTH-5 무비밀번호 로그인 라우트 계약 (AL-*, T-13.6.2·3).

httpx ASGITransport + 인메모리 참여 스토어(무 실 DB). issue/verify/session 의 실제 해시
경로를 그대로 태우고(코드는 캡처 메일러로 회수), 라우트가 상태코드·쿠키·닉네임 자동생성을
올바로 매핑하는지 검증한다. 회사 SQL용 conftest.fake_data 와 독립(참여 SQL 전용 스텁).
"""
from __future__ import annotations

import httpx
import pytest
import pytest_asyncio


@pytest_asyncio.fixture
async def member_env(monkeypatch):
    from server import database, mailer
    from server.main import create_app

    store = {"codes": [], "members": [], "sessions": [], "_code_seq": 0, "_mbr_seq": 0}
    captured: dict = {}

    async def _fetch_one(sql, params=()):
        if "FROM TAUTH_CODE" in sql:
            target = params[0]
            cands = [c for c in store["codes"] if c["TARGET_HASH_VAL"] == target and not c["CONSUMED"]]
            if not cands:
                return None
            c = max(cands, key=lambda x: x["AUTH_CODE_ID"])
            return {"AUTH_CODE_ID": c["AUTH_CODE_ID"], "CODE_HASH_VAL": c["CODE_HASH_VAL"],
                    "ATTEMPT_CNT": c["ATTEMPT_CNT"], "is_expired": 1 if c["EXPIRED"] else 0}
        if "FROM TMEMBER" in sql:
            email = params[0]
            active_only = "STATUS_CD='active'" in sql
            for m in store["members"]:
                if m["LOGIN_EMAIL_NM"] == email and (not active_only or m["STATUS_CD"] == "active"):
                    return {"MBR_ID": m["MBR_ID"], "NICKNAME_NM": m["NICKNAME_NM"]}
            return None
        raise AssertionError(f"member fake: unmatched fetch_one: {sql!r}")

    async def _execute(sql, params=()):
        if "INSERT INTO TAUTH_CODE" in sql:
            store["_code_seq"] += 1
            store["codes"].append({"AUTH_CODE_ID": store["_code_seq"], "CODE_HASH_VAL": params[0],
                                   "TARGET_HASH_VAL": params[1], "ATTEMPT_CNT": 0,
                                   "CONSUMED": False, "EXPIRED": False})
            return 1
        if "UPDATE TAUTH_CODE SET ATTEMPT_CNT" in sql:
            for c in store["codes"]:
                if c["AUTH_CODE_ID"] == params[0]:
                    c["ATTEMPT_CNT"] += 1
            return 1
        if "UPDATE TAUTH_CODE SET CONSUMED_DTM" in sql:
            for c in store["codes"]:
                if c["AUTH_CODE_ID"] == params[0]:
                    c["CONSUMED"] = True
            return 1
        if "INSERT INTO TMEMBER" in sql:
            store["_mbr_seq"] += 1
            store["members"].append({"MBR_ID": store["_mbr_seq"], "LOGIN_EMAIL_NM": params[0],
                                     "NICKNAME_NM": params[1], "STATUS_CD": "active"})
            return 1
        if "INSERT INTO TSESSION" in sql:
            store["sessions"].append({"MBR_ID": params[0], "TOKEN_HASH_VAL": params[1]})
            return 1
        raise AssertionError(f"member fake: unmatched execute: {sql!r}")

    class _CaptureMailer:
        async def send_login_code(self, email, code):
            captured["email"], captured["code"] = email, code

        async def send_employ_code(self, email, code):
            captured["email"], captured["code"] = email, code

    async def _noop():
        return None

    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    monkeypatch.setattr(database, "execute", _execute)
    monkeypatch.setattr(database, "init_pool", _noop)
    monkeypatch.setattr(database, "close_pool", _noop)
    monkeypatch.setattr(mailer, "get_mailer", lambda: _CaptureMailer())

    app = create_app()
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:
        yield c, store, captured


async def _issue(c, email):
    r = await c.post("/api/v1/members/login-code", json={"email": email})
    assert r.status_code == 204
    return r


@pytest.mark.asyncio
async def test_AL1_login_code_uniform_204_no_code_in_body(member_env):
    """AL-1: 계정 유무 무관 균일 204, 본문·헤더에 코드 없음(계정 열거 차단)."""
    c, store, cap = member_env
    r = await c.post("/api/v1/members/login-code", json={"email": "new@x.com"})
    assert r.status_code == 204
    assert r.content == b""
    assert r.headers.get("cache-control") == "no-store"
    assert cap["code"] not in r.text
    assert len(store["codes"]) == 1


@pytest.mark.asyncio
async def test_AL1_invalid_email_422(member_env):
    c, store, cap = member_env
    r = await c.post("/api/v1/members/login-code", json={"email": "not-an-email"})
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_AL2_AL4_login_success_new_account_sets_cookie(member_env):
    """AL-2·AL-4: 코드 검증 성공 200 + is_new + 자동 닉네임 + Set-Cookie(AS-1 속성)."""
    c, store, cap = member_env
    await _issue(c, "new@x.com")
    r = await c.post("/api/v1/members/login", json={"email": "new@x.com", "code": cap["code"]})
    assert r.status_code == 200
    body = r.json()
    assert body["is_new"] is True
    assert body["nickname"].startswith("직장인-")
    assert r.headers.get("cache-control") == "no-store"

    setc = r.headers.get("set-cookie", "").lower()
    assert "loupit_sid=" in setc and "httponly" in setc and "secure" in setc
    assert "samesite=lax" in setc and "path=/api/v1" in setc
    assert len(store["sessions"]) == 1                       # 세션 발급
    assert cap["code"] not in setc                           # 세션 토큰 ≠ 코드


@pytest.mark.asyncio
async def test_AL2_login_existing_account_not_new(member_env):
    c, store, cap = member_env
    await _issue(c, "e@x.com")
    r1 = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": cap["code"]})
    assert r1.status_code == 200 and r1.json()["is_new"] is True
    nick = r1.json()["nickname"]

    await _issue(c, "e@x.com")
    r2 = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": cap["code"]})
    assert r2.status_code == 200
    assert r2.json()["is_new"] is False
    assert r2.json()["nickname"] == nick                     # 동일 계정·닉네임
    assert len(store["members"]) == 1


@pytest.mark.asyncio
async def test_AL3_wrong_code_401(member_env):
    c, store, cap = member_env
    await _issue(c, "e@x.com")
    wrong = "000000" if cap["code"] != "000000" else "111111"
    r = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": wrong})
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_AL3_expired_410(member_env):
    c, store, cap = member_env
    await _issue(c, "e@x.com")
    store["codes"][-1]["EXPIRED"] = True
    r = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": cap["code"]})
    assert r.status_code == 410


@pytest.mark.asyncio
async def test_AL3_too_many_429(member_env):
    c, store, cap = member_env
    await _issue(c, "e@x.com")
    store["codes"][-1]["ATTEMPT_CNT"] = 999
    r = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": cap["code"]})
    assert r.status_code == 429


@pytest.mark.asyncio
async def test_AL_login_code_consumed_not_reusable(member_env):
    """성공 소비 후 같은 코드 재사용 불가(mismatch — 미소비 코드 없음)."""
    c, store, cap = member_env
    await _issue(c, "e@x.com")
    code = cap["code"]
    ok = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": code})
    assert ok.status_code == 200
    again = await c.post("/api/v1/members/login", json={"email": "e@x.com", "code": code})
    assert again.status_code == 401
