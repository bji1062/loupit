"""SP-AUTH-7·8 재직 인증 — 도메인 매칭·HMAC·코드·수동 요청 (AE-*, T-13.8·T-13.9.1, DG-5).

서비스 유닛(무 DB monkeypatch) + 라우트 계약(httpx ASGITransport + 인메모리 참여 스토어).
회사 이메일 원문은 코드·인증 어디에도 저장되지 않고 해시/HMAC만 남는다(INV-8·NFR30).
"""
from __future__ import annotations

import httpx
import pytest
import pytest_asyncio

from server import deps
from server.services import auth_code, employment
from server.services.auth_code import CodeResult
from server.services.employment import DomainStatus


# ── 서비스 유닛 ──────────────────────────────────────────────────────────────
def test_normalize_domain():
    assert employment._normalize_domain("Hong@Samsung.COM") == "samsung.com"
    assert employment._normalize_domain(" a@b.co.kr ") == "b.co.kr"


def test_hmac_email_deterministic_and_normalized():
    assert employment._hmac_email("Hong@Samsung.com") == employment._hmac_email(" hong@samsung.com ")
    assert len(employment._hmac_email("a@b.com")) == 64


@pytest.mark.asyncio
async def test_domain_status_no_domains(monkeypatch):
    async def _fa(sql, params=()):
        return []

    monkeypatch.setattr(employment.database, "fetch_all", _fa)
    assert await employment.domain_status(20, "x@foo.com") == DomainStatus.NO_DOMAINS


@pytest.mark.asyncio
async def test_domain_status_ok_and_mismatch(monkeypatch):
    async def _fa(sql, params=()):
        return [{"EMAIL_DOMAIN_NM": "samsung.com"}]

    monkeypatch.setattr(employment.database, "fetch_all", _fa)
    assert await employment.domain_status(10, "hong@samsung.com") == DomainStatus.OK
    assert await employment.domain_status(10, "hong@gmail.com") == DomainStatus.MISMATCH


async def _stub_verify(monkeypatch, *, consume_rc, row=None):
    async def _fo(sql, params=()):
        return row

    async def _ex(sql, params=()):
        return consume_rc if "SET CONSUMED_DTM" in sql else 1

    monkeypatch.setattr(employment.database, "fetch_one", _fo)
    monkeypatch.setattr(employment.database, "execute", _ex)


@pytest.mark.asyncio
async def test_verify_employ_code_results(monkeypatch):
    await _stub_verify(monkeypatch, consume_rc=1)
    assert await employment.verify_employ_code(10, "a@x.com", "111111") == CodeResult.OK
    await _stub_verify(monkeypatch, consume_rc=0, row=None)
    assert await employment.verify_employ_code(10, "a@x.com", "111111") == CodeResult.MISMATCH
    await _stub_verify(monkeypatch, consume_rc=0, row={"AUTH_CODE_ID": 1, "ATTEMPT_CNT": 0, "is_expired": 1})
    assert await employment.verify_employ_code(10, "a@x.com", "111111") == CodeResult.EXPIRED
    await _stub_verify(monkeypatch, consume_rc=0, row={"AUTH_CODE_ID": 1, "ATTEMPT_CNT": 999, "is_expired": 0})
    assert await employment.verify_employ_code(10, "a@x.com", "111111") == CodeResult.TOO_MANY


@pytest.mark.asyncio
async def test_create_domain_verification_outcomes(monkeypatch):
    from pymysql.err import IntegrityError

    # already_verified
    async def _fo_active(sql, params=()):
        return {"EMPLOY_VRF_ID": 1, "COMP_ID": 10}

    monkeypatch.setattr(employment.database, "fetch_one", _fo_active)
    assert await employment.create_domain_verification(1, 10, "a@b.com") == "already_verified"

    # ok
    async def _fo_none(sql, params=()):
        return None

    async def _ex_ok(sql, params=()):
        return 1

    monkeypatch.setattr(employment.database, "fetch_one", _fo_none)
    monkeypatch.setattr(employment.database, "execute", _ex_ok)
    assert await employment.create_domain_verification(1, 10, "a@b.com") == "ok"

    # hmac_dup
    async def _ex_dup(sql, params=()):
        raise IntegrityError(1062, "Duplicate uq_employ_email")

    monkeypatch.setattr(employment.database, "execute", _ex_dup)
    assert await employment.create_domain_verification(1, 10, "a@b.com") == "hmac_dup"


@pytest.mark.asyncio
async def test_submit_manual_request_outcomes(monkeypatch):
    async def _fo_none(sql, params=()):
        return None

    async def _fo_dup(sql, params=()):
        return {"VRF_REQUEST_ID": 1}

    async def _ex(sql, params=()):
        return 1

    monkeypatch.setattr(employment.database, "execute", _ex)
    monkeypatch.setattr(employment.database, "fetch_one", _fo_none)
    assert await employment.submit_manual_request(1, 20, "명함 첨부") == "ok"
    monkeypatch.setattr(employment.database, "fetch_one", _fo_dup)
    assert await employment.submit_manual_request(1, 20, "명함 첨부") == "dup"


@pytest.mark.asyncio
async def test_require_employment_403_and_ok(monkeypatch):
    from fastapi import HTTPException

    async def _av_none(mbr, comp):
        return None

    monkeypatch.setattr(deps.employment, "active_verification", _av_none)
    with pytest.raises(HTTPException) as ei:
        await deps.require_employment(comp_id=10, member={"MBR_ID": 1})
    assert ei.value.status_code == 403

    async def _av_ok(mbr, comp):
        return {"EMPLOY_VRF_ID": 5, "COMP_ID": 10}

    monkeypatch.setattr(deps.employment, "active_verification", _av_ok)
    assert (await deps.require_employment(comp_id=10, member={"MBR_ID": 1}))["COMP_ID"] == 10


# ── 라우트 계약 (AE-*) ────────────────────────────────────────────────────────
_AUTH = {"Cookie": "loupit_sid=SESSIONRAW"}


@pytest_asyncio.fixture
async def employ_env(monkeypatch):
    """로그인된 회원(MBR_ID=1) + 재직 인증 SQL 인메모리 스텁. comp 10=samsung.com 등록, comp 20=미등록."""
    from server import database, mailer
    from server.main import create_app
    from server.services import session as session_svc

    store = {
        "sessions": [{"MBR_ID": 1, "TOKEN_HASH_VAL": session_svc._hash_token("SESSIONRAW"), "revoked": False}],
        "domains": {10: {"samsung.com"}, 20: set()},
        "codes": [], "verifications": [], "requests": [], "_seq": 0,
    }
    captured: dict = {}

    async def _fetch_one(sql, params=()):
        if "FROM TSESSION" in sql and "TOKEN_HASH_VAL" in sql:
            for s in store["sessions"]:
                if s["TOKEN_HASH_VAL"] == params[0] and not s["revoked"]:
                    return {"MBR_ID": s["MBR_ID"]}
            return None
        if "FROM TAUTH_CODE" in sql:  # verify path2: (target, purpose, comp)
            thash, comp = params[0], params[2]
            if "INS_DTM" in sql:  # 재전송 쿨다운 체크: 미소비 최근 코드 존재?
                exists = any(c["TARGET_HASH_VAL"] == thash and c["COMP_ID"] == comp and not c["CONSUMED"] for c in store["codes"])
                return {"x": 1} if exists else None
            cands = [c for c in store["codes"] if c["TARGET_HASH_VAL"] == thash and c["COMP_ID"] == comp and not c["CONSUMED"]]
            if not cands:
                return None
            c = max(cands, key=lambda x: x["AUTH_CODE_ID"])
            return {"AUTH_CODE_ID": c["AUTH_CODE_ID"], "ATTEMPT_CNT": c["ATTEMPT_CNT"], "is_expired": 1 if c["EXPIRED"] else 0}
        if "FROM TEMPLOY_VERIFICATION" in sql:  # active_verification: (mbr, comp)
            for v in store["verifications"]:
                if v["MBR_ID"] == params[0] and v["COMP_ID"] == params[1] and not v["revoked"]:
                    return {"EMPLOY_VRF_ID": 1, "COMP_ID": v["COMP_ID"]}
            return None
        if "FROM TEMPLOY_VRF_REQUEST" in sql:  # dup: (mbr, comp)
            for r in store["requests"]:
                if r["MBR_ID"] == params[0] and r["COMP_ID"] == params[1] and r["STATUS"] == "pending":
                    return {"VRF_REQUEST_ID": 1}
            return None
        raise AssertionError(f"employ fake: unmatched fetch_one: {sql!r}")

    async def _fetch_all(sql, params=()):
        if "FROM TCOMPANY_EMAIL_DOMAIN" in sql:
            return [{"EMAIL_DOMAIN_NM": d} for d in store["domains"].get(params[0], set())]
        raise AssertionError(f"employ fake: unmatched fetch_all: {sql!r}")

    async def _execute(sql, params=()):
        if "INSERT INTO TAUTH_CODE" in sql:  # (purpose, code_hash, target_hash, comp, mbr, ttl)
            store["_seq"] += 1
            store["codes"].append({"AUTH_CODE_ID": store["_seq"], "CODE_HASH_VAL": params[1],
                                   "TARGET_HASH_VAL": params[2], "COMP_ID": params[3],
                                   "ATTEMPT_CNT": 0, "CONSUMED": False, "EXPIRED": False})
            return 1
        if "SET CONSUMED_DTM" in sql and "CODE_HASH_VAL" in sql:  # (target, purpose, comp, code_hash, max)
            thash, comp, chash, maxa = params[0], params[2], params[3], params[4]
            for c in store["codes"]:
                if (c["TARGET_HASH_VAL"] == thash and c["COMP_ID"] == comp and c["CODE_HASH_VAL"] == chash
                        and not c["CONSUMED"] and not c["EXPIRED"] and c["ATTEMPT_CNT"] < maxa):
                    c["CONSUMED"] = True
                    return 1
            return 0
        if "SET ATTEMPT_CNT" in sql:  # (auth_code_id, max)
            for c in store["codes"]:
                if c["AUTH_CODE_ID"] == params[0] and c["ATTEMPT_CNT"] < params[1]:
                    c["ATTEMPT_CNT"] += 1
                    return 1
            return 0
        if "INSERT INTO TEMPLOY_VERIFICATION" in sql:  # (mbr, comp, hmac, ttl, ins_id)
            from pymysql.err import IntegrityError
            if any(v["COMP_EMAIL_HASH_VAL"] == params[2] for v in store["verifications"]):
                raise IntegrityError(1062, "Duplicate uq_employ_email")
            store["verifications"].append({"MBR_ID": params[0], "COMP_ID": params[1],
                                           "COMP_EMAIL_HASH_VAL": params[2], "revoked": False})
            return 1
        if "INSERT INTO TEMPLOY_VRF_REQUEST" in sql:  # (mbr, comp, evidence, ins_id)
            store["requests"].append({"MBR_ID": params[0], "COMP_ID": params[1], "STATUS": "pending", "EVIDENCE": params[2]})
            return 1
        raise AssertionError(f"employ fake: unmatched execute: {sql!r}")

    class _CaptureMailer:
        async def send_employ_code(self, email, code):
            captured["email"], captured["code"] = email, code

        async def send_login_code(self, email, code):
            captured["email"], captured["code"] = email, code

    async def _noop():
        return None

    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    monkeypatch.setattr(database, "execute", _execute)
    monkeypatch.setattr(database, "init_pool", _noop)
    monkeypatch.setattr(database, "close_pool", _noop)
    monkeypatch.setattr(mailer, "get_mailer", lambda: _CaptureMailer())

    app = create_app()
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t",
                                 headers={"X-Loupit-Client": "web"}) as c:  # CSRF 기본 통과
        yield c, store, captured


@pytest.mark.asyncio
async def test_verify_code_requires_session_401(employ_env):
    c, store, cap = employ_env
    r = await c.post("/api/v1/employment/verify-code", json={"comp_id": 10, "company_email": "hong@samsung.com"})
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_AE2_unregistered_domain_409_manual_required(employ_env):
    c, store, cap = employ_env
    r = await c.post("/api/v1/employment/verify-code",
                     json={"comp_id": 20, "company_email": "hong@nowhere.com"}, headers=_AUTH)
    assert r.status_code == 409
    assert r.json()["detail"] == "manual_required"


@pytest.mark.asyncio
async def test_AE1_domain_mismatch_422(employ_env):
    c, store, cap = employ_env
    r = await c.post("/api/v1/employment/verify-code",
                     json={"comp_id": 10, "company_email": "hong@gmail.com"}, headers=_AUTH)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_verify_code_match_sends_and_204(employ_env):
    c, store, cap = employ_env
    r = await c.post("/api/v1/employment/verify-code",
                     json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    assert r.status_code == 204
    assert len(store["codes"]) == 1
    assert "hong@samsung.com" not in str(store["codes"][0])  # 원문 미저장(해시만)
    assert cap["code"] and cap["email"] == "hong@samsung.com"


@pytest.mark.asyncio
async def test_AE_resend_cooldown_suppresses_duplicate(employ_env):
    """[T-13.13.2] 재전송 쿨다운 — 회사 이메일에 미소비 코드가 있으면 재요청 무발송(204 유지)."""
    c, store, cap = employ_env
    r1 = await c.post("/api/v1/employment/verify-code",
                      json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    assert r1.status_code == 204 and len(store["codes"]) == 1
    r2 = await c.post("/api/v1/employment/verify-code",
                      json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    assert r2.status_code == 204 and len(store["codes"]) == 1  # 무발송(쿨다운)


@pytest.mark.asyncio
async def test_AE3_verify_creates_verification_201_hmac_only(employ_env):
    c, store, cap = employ_env
    await c.post("/api/v1/employment/verify-code",
                 json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    code = cap["code"]
    r = await c.post("/api/v1/employment/verify",
                     json={"comp_id": 10, "company_email": "hong@samsung.com", "code": code}, headers=_AUTH)
    assert r.status_code == 201
    assert r.json() == {"comp_id": 10, "method": "domain"}
    assert len(store["verifications"]) == 1
    v = store["verifications"][0]
    assert v["COMP_EMAIL_HASH_VAL"] == employment._hmac_email("hong@samsung.com")  # HMAC만
    assert "hong@samsung.com" not in str(v)                                        # 원문 부재
    # 재검증 → already_verified 409
    await c.post("/api/v1/employment/verify-code",
                 json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    again = await c.post("/api/v1/employment/verify",
                         json={"comp_id": 10, "company_email": "hong@samsung.com", "code": cap["code"]}, headers=_AUTH)
    assert again.status_code == 409


@pytest.mark.asyncio
async def test_AE4_hmac_duplicate_409(employ_env):
    c, store, cap = employ_env
    # 다른 계정이 이미 이 회사 이메일로 인증한 상태를 심음(같은 HMAC)
    store["verifications"].append({"MBR_ID": 99, "COMP_ID": 10,
                                   "COMP_EMAIL_HASH_VAL": employment._hmac_email("taken@samsung.com"), "revoked": False})
    await c.post("/api/v1/employment/verify-code",
                 json={"comp_id": 10, "company_email": "taken@samsung.com"}, headers=_AUTH)
    r = await c.post("/api/v1/employment/verify",
                     json={"comp_id": 10, "company_email": "taken@samsung.com", "code": cap["code"]}, headers=_AUTH)
    assert r.status_code == 409


@pytest.mark.asyncio
async def test_AE3_wrong_code_401(employ_env):
    c, store, cap = employ_env
    await c.post("/api/v1/employment/verify-code",
                 json={"comp_id": 10, "company_email": "hong@samsung.com"}, headers=_AUTH)
    wrong = "000000" if cap["code"] != "000000" else "111111"
    r = await c.post("/api/v1/employment/verify",
                     json={"comp_id": 10, "company_email": "hong@samsung.com", "code": wrong}, headers=_AUTH)
    assert r.status_code == 401
    assert len(store["verifications"]) == 0


@pytest.mark.asyncio
async def test_AE5_manual_request_202_and_duplicate_409(employ_env):
    c, store, cap = employ_env
    r = await c.post("/api/v1/employment/requests",
                     json={"comp_id": 20, "evidence": "재직증명서 링크"}, headers=_AUTH)
    assert r.status_code == 202
    assert r.json()["status"] == "pending"
    assert len(store["requests"]) == 1
    dup = await c.post("/api/v1/employment/requests",
                       json={"comp_id": 20, "evidence": "또 요청"}, headers=_AUTH)
    assert dup.status_code == 409
