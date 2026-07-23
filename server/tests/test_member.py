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
        if "SET CONSUMED_DTM" in sql and "CODE_HASH_VAL" in sql:  # path1 원자 소비(해시 직접 매칭)
            thash, chash, maxa = params[0], params[1], params[2]
            for c in store["codes"]:
                if (c["TARGET_HASH_VAL"] == thash and c["CODE_HASH_VAL"] == chash
                        and not c["CONSUMED"] and not c["EXPIRED"] and c["ATTEMPT_CNT"] < maxa):
                    c["CONSUMED"] = True
                    return 1
            return 0
        if "SET ATTEMPT_CNT" in sql:  # path2 원자 시도 증가(ATTEMPT_CNT < 상한 가드)
            cid, maxa = params[0], params[1]
            for c in store["codes"]:
                if c["AUTH_CODE_ID"] == cid and c["ATTEMPT_CNT"] < maxa:
                    c["ATTEMPT_CNT"] += 1
                    return 1
            return 0
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


@pytest.mark.asyncio
async def test_AL_shadow_code_does_not_block_real_login(member_env):
    """[보안 Fix2] 제3자가 피해자 이메일로 코드를 재발급(섀도잉)해도, 피해자의 진짜 코드로 로그인된다.

    구 '최신 1건' 매칭이면 공격자의 신규 코드가 정답을 밀어내 401이 됐다 — 해시 직접 매칭으로 방어."""
    c, store, cap = member_env
    await _issue(c, "victim@x.com")   # 코드 A (피해자가 메일로 받음)
    victim_code = cap["code"]
    await _issue(c, "victim@x.com")   # 코드 B (공격자 섀도잉, 더 최신) — cap 은 이제 코드 B
    assert len(store["codes"]) == 2
    r = await c.post("/api/v1/members/login", json={"email": "victim@x.com", "code": victim_code})
    assert r.status_code == 200        # 최신(B)에 밀리지 않고 A 해시로 매칭


@pytest.mark.asyncio
async def test_AL_invalid_body_422_does_not_echo_email_or_code(member_env):
    """[보안 Fix6] 형식 불량 422 응답이 제출한 이메일·코드 원문을 반향하지 않는다(NFR31)."""
    c, store, cap = member_env
    r = await c.post("/api/v1/members/login", json={"email": "leaked-plaintext-xyz", "code": "9z9z9z"})
    assert r.status_code == 422
    assert "leaked-plaintext-xyz" not in r.text  # 이메일 원문 미반향
    assert "9z9z9z" not in r.text                 # 코드 원문 미반향
    detail = r.json()["detail"]
    assert isinstance(detail, list) and all("input" not in e for e in detail)  # input 키 제거


@pytest.mark.asyncio
async def test_get_or_create_member_email_race_absorbs_no_500(monkeypatch):
    """[보안 Fix5] 동일 이메일 동시 첫 로그인(버튼 더블클릭)의 이메일 UNIQUE 충돌은 500이 아니라
    이미 만들어진 계정 재조회로 흡수(is_new=False)한다 — 닉네임 충돌로 오인해 5회 헛시도 후 500 나던 버그."""
    from server import database
    from server.routers import member as member_router

    state = {"inserts": 0, "active_selects": 0}

    async def _execute(sql, params=()):
        if "INSERT INTO TMEMBER" in sql:
            state["inserts"] += 1
            raise RuntimeError("Duplicate entry 'race@x.com' for key 'uq_member_email'")
        return 1

    async def _fetch_one(sql, params=()):
        if "STATUS_CD='active'" in sql:
            state["active_selects"] += 1
            # 1회차: 신규(없음) → INSERT 시도. 2회차(예외 후 재조회): 동시 요청이 만든 계정 존재.
            return None if state["active_selects"] == 1 else {"MBR_ID": 55, "NICKNAME_NM": "직장인-000055"}
        return None

    monkeypatch.setattr(database, "execute", _execute)
    monkeypatch.setattr(database, "fetch_one", _fetch_one)

    row, is_new = await member_router._get_or_create_member("Race@x.com")
    assert row["MBR_ID"] == 55 and is_new is False
    assert state["inserts"] == 1  # 이메일 충돌을 재조회로 흡수(닉네임 재시도로 반복 INSERT 안 함)


# ── 계정 관리(마이페이지·로그아웃·탈퇴) — AM-* (T-13.5.2·T-13.7) ──────────────────────
_AUTH = {"Cookie": "loupit_sid=SESSIONRAW"}  # account_env 가 심은 유효 세션 원문


@pytest_asyncio.fixture
async def account_env(monkeypatch):
    """로그인된 회원(MBR_ID=1) + 유효 세션(SESSIONRAW)이 심긴 클라이언트. 계정 SQL 인메모리 스텁."""
    from server import database
    from server.main import create_app
    from server.services import session as session_svc

    store = {
        "members": [{"MBR_ID": 1, "LOGIN_EMAIL_NM": "me@x.com", "NICKNAME_NM": "직장인-000001", "STATUS_CD": "active"}],
        "sessions": [{"MBR_ID": 1, "TOKEN_HASH_VAL": session_svc._hash_token("SESSIONRAW"), "revoked": False}],
        "verifications": [],  # {MBR_ID, COMP_ID, COMP_NM, EXPIRES_DTM, revoked}
    }

    def _member(mid):
        return next((m for m in store["members"] if m["MBR_ID"] == mid), None)

    async def _fetch_one(sql, params=()):
        if "FROM TSESSION" in sql and "TOKEN_HASH_VAL" in sql:
            for s in store["sessions"]:
                if s["TOKEN_HASH_VAL"] == params[0] and not s["revoked"]:
                    return {"MBR_ID": s["MBR_ID"]}
            return None
        if "SELECT NICKNAME_NM, STATUS_CD FROM TMEMBER" in sql:
            m = _member(params[0])
            return {"NICKNAME_NM": m["NICKNAME_NM"], "STATUS_CD": m["STATUS_CD"]} if m else None
        raise AssertionError(f"account fake: unmatched fetch_one: {sql!r}")

    async def _fetch_all(sql, params=()):
        if "FROM TEMPLOY_VERIFICATION" in sql:
            return [
                {"comp_id": v["COMP_ID"], "comp_nm": v["COMP_NM"], "expires_dtm": v.get("EXPIRES_DTM")}
                for v in store["verifications"]
                if v["MBR_ID"] == params[0] and not v.get("revoked")
            ]
        raise AssertionError(f"account fake: unmatched fetch_all: {sql!r}")

    async def _execute(sql, params=()):
        if "UPDATE TMEMBER SET NICKNAME_NM" in sql:
            nick, mid = params[0], params[1]
            if any(m["NICKNAME_NM"] == nick and m["MBR_ID"] != mid for m in store["members"]):
                from pymysql.err import IntegrityError
                raise IntegrityError(1062, "Duplicate entry for key 'uq_member_nickname'")
            _member(mid)["NICKNAME_NM"] = nick
            return 1
        if "UPDATE TSESSION SET REVOKED_DTM" in sql and "TOKEN_HASH_VAL" in sql:
            for s in store["sessions"]:
                if s["TOKEN_HASH_VAL"] == params[0]:
                    s["revoked"] = True
            return 1
        raise AssertionError(f"account fake: unmatched execute: {sql!r}")

    class _Cur:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *e):
            return False

        async def execute(self, sql, params=()):
            if "UPDATE TMEMBER SET LOGIN_EMAIL_NM=NULL" in sql:
                m = _member(params[0])
                m["LOGIN_EMAIL_NM"] = None
                m["STATUS_CD"] = "withdrawn"
            elif "UPDATE TSESSION SET REVOKED_DTM" in sql and "MBR_ID" in sql:
                for s in store["sessions"]:
                    if s["MBR_ID"] == params[0]:
                        s["revoked"] = True
            elif "DELETE FROM TEMPLOY_VERIFICATION" in sql:
                store["verifications"][:] = [v for v in store["verifications"] if v["MBR_ID"] != params[0]]
            else:
                raise AssertionError(f"withdraw fake cursor: unmatched: {sql!r}")

    class _Conn:
        def cursor(self):
            return _Cur()

    class _Txn:
        async def __aenter__(self):
            return _Conn()

        async def __aexit__(self, *e):
            return False

    async def _noop():
        return None

    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    monkeypatch.setattr(database, "execute", _execute)
    monkeypatch.setattr(database, "transaction", lambda: _Txn())
    monkeypatch.setattr(database, "init_pool", _noop)
    monkeypatch.setattr(database, "close_pool", _noop)

    app = create_app()
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:
        yield c, store


@pytest.mark.asyncio
async def test_AM1_me_requires_session_401(account_env):
    c, store = account_env
    r = await c.get("/api/v1/members/me")  # 쿠키 없음
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_AM1_me_returns_profile_no_store(account_env):
    c, store = account_env
    r = await c.get("/api/v1/members/me", headers=_AUTH)
    assert r.status_code == 200
    b = r.json()
    assert b["nickname"] == "직장인-000001"
    assert b["status"] == "active"
    assert b["verifications"] == []
    assert r.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_AM2_update_nickname_ok(account_env):
    c, store = account_env
    r = await c.put("/api/v1/members/me", json={"nickname": "새로운닉"}, headers=_AUTH)
    assert r.status_code == 200
    assert r.json()["nickname"] == "새로운닉"
    assert store["members"][0]["NICKNAME_NM"] == "새로운닉"


@pytest.mark.asyncio
async def test_AM2_update_nickname_duplicate_409(account_env):
    c, store = account_env
    store["members"].append({"MBR_ID": 2, "LOGIN_EMAIL_NM": "o@x.com", "NICKNAME_NM": "임자있음", "STATUS_CD": "active"})
    r = await c.put("/api/v1/members/me", json={"nickname": "임자있음"}, headers=_AUTH)
    assert r.status_code == 409


@pytest.mark.asyncio
async def test_AM2_update_nickname_banned_422(account_env):
    c, store = account_env
    r = await c.put("/api/v1/members/me", json={"nickname": "관리자"}, headers=_AUTH)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_AM3_logout_revokes_session_and_clears_cookie(account_env):
    c, store = account_env
    r = await c.post("/api/v1/members/logout", headers=_AUTH)
    assert r.status_code == 204
    assert store["sessions"][0]["revoked"] is True
    assert "loupit_sid=" in r.headers.get("set-cookie", "").lower()
    # 폐기 후 같은 쿠키로 me → 401
    r2 = await c.get("/api/v1/members/me", headers=_AUTH)
    assert r2.status_code == 401


@pytest.mark.asyncio
async def test_AM4_withdraw_nulls_email_keeps_nickname_and_history(account_env):
    c, store = account_env
    store["verifications"].append({"MBR_ID": 1, "COMP_ID": 3, "COMP_NM": "삼성", "revoked": False})
    r = await c.delete("/api/v1/members/me", headers=_AUTH)
    assert r.status_code == 204
    m = store["members"][0]
    assert m["LOGIN_EMAIL_NM"] is None            # 이메일 원문 파기
    assert m["STATUS_CD"] == "withdrawn"
    assert m["NICKNAME_NM"] == "직장인-000001"     # 닉네임 존치(공개 이력 무결성)
    assert store["sessions"][0]["revoked"] is True  # 전 세션 폐기
    assert store["verifications"] == []            # 재직 인증(회사 이메일 HMAC) 파기
    r2 = await c.get("/api/v1/members/me", headers=_AUTH)
    assert r2.status_code == 401                    # 세션 무효
