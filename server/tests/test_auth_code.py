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

    monkeypatch.setattr(auth_code.database, "execute", _exec)
    import server.mailer as mailer

    monkeypatch.setattr(mailer, "get_mailer", lambda: _M())

    await auth_code.issue_login_code("User@X.com")

    sql, params = calls[-1]
    assert "INSERT INTO TAUTH_CODE" in sql and "'login'" in sql
    assert "User@X.com" not in str(params) and "user@x.com" not in str(params)  # 이메일 원문 미저장
    assert sent["code"] not in str(params)                                      # 코드 원문 미저장
    assert all(len(p) == 64 for p in params[:2])                                # 해시 2종(코드·대상)
    assert sent["email"] == "user@x.com"                                        # 정규화 이메일로 발송


async def _stub_db(monkeypatch, code_row, exec_log):
    async def _fetch_one(sql, params=()):
        return code_row

    async def _exec(sql, params=()):
        exec_log.append((sql, params))
        return 1

    monkeypatch.setattr(auth_code.database, "fetch_one", _fetch_one)
    monkeypatch.setattr(auth_code.database, "execute", _exec)


@pytest.mark.asyncio
async def test_verify_no_row_is_mismatch(monkeypatch):
    await _stub_db(monkeypatch, None, [])
    assert await auth_code.verify_login_code("a@x.com", "000000") == CodeResult.MISMATCH


@pytest.mark.asyncio
async def test_verify_expired(monkeypatch):
    row = {"AUTH_CODE_ID": 1, "CODE_HASH_VAL": auth_code._hash_code("111111", "a@x.com"),
           "ATTEMPT_CNT": 0, "is_expired": 1}
    await _stub_db(monkeypatch, row, [])
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.EXPIRED


@pytest.mark.asyncio
async def test_verify_too_many_attempts(monkeypatch):
    row = {"AUTH_CODE_ID": 1, "CODE_HASH_VAL": auth_code._hash_code("111111", "a@x.com"),
           "ATTEMPT_CNT": 999, "is_expired": 0}  # 상한 초과(설정 무관)
    await _stub_db(monkeypatch, row, [])
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.TOO_MANY


@pytest.mark.asyncio
async def test_verify_wrong_code_mismatch_and_increments(monkeypatch):
    row = {"AUTH_CODE_ID": 7, "CODE_HASH_VAL": auth_code._hash_code("111111", "a@x.com"),
           "ATTEMPT_CNT": 0, "is_expired": 0}
    log = []
    await _stub_db(monkeypatch, row, log)
    assert await auth_code.verify_login_code("a@x.com", "999999") == CodeResult.MISMATCH
    assert any("ATTEMPT_CNT = ATTEMPT_CNT + 1" in s for s, _ in log)  # 시도 증가
    assert not any("CONSUMED_DTM" in s for s, _ in log)               # 미소비


@pytest.mark.asyncio
async def test_verify_correct_code_ok_and_consumes(monkeypatch):
    row = {"AUTH_CODE_ID": 7, "CODE_HASH_VAL": auth_code._hash_code("111111", "a@x.com"),
           "ATTEMPT_CNT": 0, "is_expired": 0}
    log = []
    await _stub_db(monkeypatch, row, log)
    assert await auth_code.verify_login_code("a@x.com", "111111") == CodeResult.OK
    assert any("CONSUMED_DTM" in s for s, _ in log)  # 소비(재사용 차단)
