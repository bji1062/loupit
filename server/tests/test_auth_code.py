"""SP-AUTH-5 인증 코드 — 생성·해시·발급·검증·소비 (T-13.6.1).

무 DB — database.execute/fetch_one 을 monkeypatch 해 SQL·파라미터·원문 미저장·결과 코드만
검증한다. 코드/이메일 원문이 저장 파라미터에 새지 않음(INV-8·T9)이 핵심 게이트.
"""
from __future__ import annotations

import pytest

from server.services import auth_code
from server.services.auth_code import CodeResult


def test_gen_code_is_six_digits():
    for _ in range(50):
        c = auth_code._gen_code()
        assert len(c) == 6 and c.isdigit()


def test_hash_code_scoped_by_target():
    assert auth_code._hash_code("123456", "a@x.com") != auth_code._hash_code("123456", "b@x.com")
    assert auth_code._hash_code("123456", "a@x.com") == auth_code._hash_code("123456", "a@x.com")
    assert len(auth_code._hash_code("123456", "a@x.com")) == 64


def test_hash_target_normalizes_email():
    assert auth_code._hash_target("  A@X.COM ") == auth_code._hash_target("a@x.com")


@pytest.mark.asyncio
async def test_issue_login_code_stores_hash_not_plaintext(monkeypatch):
    """발급은 코드·이메일 해시만 저장하고 원문은 메일로만 — INSERT 파라미터에 원문 부재(INV-8)."""
    calls = []

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    sent = {}

    class _M:
        async def send_login_code(self, email, code):
            sent["email"], sent["code"] = email, code

    async def _fetch_one(sql, params=()):
        return None  # 재전송 쿨다운 체크: 미소비 최근 코드 없음 → 발급 진행

    monkeypatch.setattr(auth_code.database, "execute", _exec)
    monkeypatch.setattr(auth_code.database, "fetch_one", _fetch_one)
    import server.mailer as mailer

    monkeypatch.setattr(mailer, "get_mailer", lambda: _M())

    await auth_code.issue_login_code("User@X.com")

    sql, params = calls[-1]
    assert "INSERT INTO TAUTH_CODE" in sql and "'login'" in sql
    assert "User@X.com" not in str(params) and "user@x.com" not in str(params)  # 이메일 원문 미저장
    assert sent["code"] not in str(params)                                      # 코드 원문 미저장
    assert all(len(p) == 64 for p in params[:2])                                # 해시 2종(코드·대상)
    assert sent["email"] == "user@x.com"                                        # 정규화 이메일로 발송


async def _stub(monkeypatch, *, consume_rc, row=None, log=None):
    """verify_login_code 무 DB 스텁 — path1 소비 UPDATE 는 consume_rc(rowcount)로, path2 상태 조회는 row 로."""
    async def _fetch_one(sql, params=()):
        return row

    async def _exec(sql, params=()):
        if log is not None:
            log.append((sql, params))
        if "SET CONSUMED_DTM" in sql:  # path1 원자 소비 UPDATE
            return consume_rc
        return 1  # path2 ATTEMPT_CNT 증가

    monkeypatch.setattr(auth_code.database, "fetch_one", _fetch_one)
    monkeypatch.setattr(auth_code.database, "execute", _exec)


@pytest.mark.asyncio
async def test_verify_correct_code_ok_atomic_consume(monkeypatch):
    """정답 경로: 해시 일치 코드를 원자 소비(rowcount>=1) → OK. 소비 UPDATE 가 CODE_HASH_VAL·
    CONSUMED_DTM IS NULL·ATTEMPT_CNT 가드를 포함(원자성·섀도잉 내성·1코드→1세션)."""
    log = []
    await _stub(monkeypatch, consume_rc=1, log=log)
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.OK
    consume_sql = [s for s, _ in log if "SET CONSUMED_DTM" in s][0]
    assert "CODE_HASH_VAL=%s" in consume_sql
    assert "CONSUMED_DTM IS NULL" in consume_sql
    assert "ATTEMPT_CNT < %s" in consume_sql
    assert not any("ATTEMPT_CNT = ATTEMPT_CNT + 1" in s for s, _ in log)  # 성공 시 증가 없음


@pytest.mark.asyncio
async def test_verify_no_live_code_is_mismatch(monkeypatch):
    await _stub(monkeypatch, consume_rc=0, row=None)
    assert await auth_code.verify_login_code("a@x.com", "000000") == CodeResult.MISMATCH


@pytest.mark.asyncio
async def test_verify_expired(monkeypatch):
    await _stub(monkeypatch, consume_rc=0, row={"AUTH_CODE_ID": 1, "ATTEMPT_CNT": 0, "is_expired": 1})
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.EXPIRED


@pytest.mark.asyncio
async def test_verify_too_many_attempts(monkeypatch):
    await _stub(monkeypatch, consume_rc=0, row={"AUTH_CODE_ID": 1, "ATTEMPT_CNT": 999, "is_expired": 0})
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.TOO_MANY


@pytest.mark.asyncio
async def test_verify_wrong_code_mismatch_and_increments_atomically(monkeypatch):
    log = []
    await _stub(monkeypatch, consume_rc=0, row={"AUTH_CODE_ID": 7, "ATTEMPT_CNT": 0, "is_expired": 0}, log=log)
    assert await auth_code.verify_login_code("a@x.com", "999999") == CodeResult.MISMATCH
    incr = [s for s, _ in log if "ATTEMPT_CNT = ATTEMPT_CNT + 1" in s]
    assert incr and "ATTEMPT_CNT < %s" in incr[0]  # 시도 증가는 원자 가드(동시 상한 우회 방지)
