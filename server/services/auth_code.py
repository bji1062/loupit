"""SP-AUTH-5 인증 코드 — 6자리 코드 생성·해시·발급·검증·소비.

코드·이메일 원문 무저장(SHA-256 해시만, T9·INV-8). 코드 해시는 대상 이메일로 스코프해
교차 대입을 막고, 대상 해시는 조회키로만 쓴다. **신규 의존성 0**(stdlib `secrets`·`hashlib`).
검증은 시도 상한(`code_max_attempts`) → 만료 → 해시 대조(constant-time) → 소비 순이며,
결과는 라우트(member.py)가 상태코드로 매핑한다(불일치 401 / 만료 410 / 시도초과 429).
"""
from __future__ import annotations

import hashlib
import secrets

from server import database
from server.config import get_settings


class CodeResult:
    """verify_login_code 반환값 — 라우트가 상태코드로 매핑(AL-3)."""

    OK = "ok"            # → 200
    MISMATCH = "mismatch"  # → 401 (코드 없음/불일치 — 계정 열거 방지 균일)
    EXPIRED = "expired"  # → 410
    TOO_MANY = "too_many"  # → 429


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _gen_code() -> str:
    """6자리 코드(앞자리 0 보존) — 암호학적 난수."""
    return f"{secrets.randbelow(1_000_000):06d}"


def _hash_code(code: str, target: str) -> str:
    """코드 해시 — 정규화 이메일 target 으로 스코프(교차 대입 방어)."""
    return hashlib.sha256(f"{target}:{code}".encode()).hexdigest()


def _hash_target(target: str) -> str:
    """대상 이메일 조회키 해시(원문 무저장, T9)."""
    return hashlib.sha256(_normalize_email(target).encode()).hexdigest()


async def issue_login_code(email: str) -> None:
    """로그인 코드 발급 — 해시만 저장(+login_code_ttl_min), 원문은 메일로만(무저장).

    계정 유무와 무관하게 항상 발급·발송한다(호출측 member.py 는 균일 204, 계정 열거 방지)."""
    from server import mailer  # 지연 import(라우트 조립 순서 무관)

    s = get_settings()
    norm = _normalize_email(email)
    code = _gen_code()
    await database.execute(
        "INSERT INTO TAUTH_CODE (PURPOSE_CD, CODE_HASH_VAL, TARGET_HASH_VAL, EXPIRES_DTM, ATTEMPT_CNT) "
        "VALUES ('login', %s, %s, UTC_TIMESTAMP() + INTERVAL %s MINUTE, 0)",
        (_hash_code(code, norm), _hash_target(norm), s.login_code_ttl_min),
    )
    await mailer.get_mailer().send_login_code(norm, code)  # 원문은 여기서 소멸(무저장)


async def verify_login_code(email: str, code: str) -> str:
    """로그인 코드 검증·소비 → CodeResult(ok|mismatch|expired|too_many).

    최신 미소비 login 코드 1건을 대상 해시로 조회한다. 만료·시도상한을 먼저 걸러
    무차별 대입을 막고, 시도를 증가시킨 뒤 constant-time 해시 대조한다. 성공 시 소비
    (CONSUMED_DTM)해 재사용을 차단한다. 코드가 없으면 불일치(균일 401, 계정 열거 방지)."""
    norm = _normalize_email(email)
    row = await database.fetch_one(
        "SELECT AUTH_CODE_ID, CODE_HASH_VAL, ATTEMPT_CNT, "
        "       (EXPIRES_DTM <= UTC_TIMESTAMP()) AS is_expired "
        "FROM TAUTH_CODE "
        "WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD='login' AND CONSUMED_DTM IS NULL "
        "ORDER BY AUTH_CODE_ID DESC LIMIT 1",
        (_hash_target(norm),),
    )
    if row is None:
        return CodeResult.MISMATCH
    if row["is_expired"]:
        return CodeResult.EXPIRED
    if row["ATTEMPT_CNT"] >= get_settings().code_max_attempts:
        return CodeResult.TOO_MANY

    await database.execute(
        "UPDATE TAUTH_CODE SET ATTEMPT_CNT = ATTEMPT_CNT + 1 WHERE AUTH_CODE_ID=%s",
        (row["AUTH_CODE_ID"],),
    )
    if not secrets.compare_digest(row["CODE_HASH_VAL"], _hash_code(code, norm)):
        return CodeResult.MISMATCH

    await database.execute(
        "UPDATE TAUTH_CODE SET CONSUMED_DTM = UTC_TIMESTAMP() WHERE AUTH_CODE_ID=%s",
        (row["AUTH_CODE_ID"],),
    )
    return CodeResult.OK
