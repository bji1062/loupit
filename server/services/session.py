"""SP-AUTH-4 세션 — 불투명 토큰 발급·검증·폐기 + 만료 퍼지.

발급은 불투명 랜덤 토큰(`secrets.token_urlsafe`)을 만들어 **DB엔 SHA-256 해시만** 저장하고,
원문은 쿠키로만 전달한다(원문 컬럼 부재, T9·INV-8). 검증은 미들웨어가 아니라
`deps.require_member`(Depends)로 주입한다(INV-9). **신규 의존성 0**(stdlib `secrets`·`hashlib`).
"""
from __future__ import annotations

import hashlib
import secrets

from server import database
from server.config import get_settings

COOKIE_NAME = "loupit_sid"  # FR-101
_COOKIE_PATH = "/api/v1"    # 쿠키 스코프(API 경로 한정, SP-AUTH-12)


def _hash_token(raw: str) -> str:
    """세션 토큰 DB 조회키 — pepper + SHA-256(CHAR(64)). 원문은 저장하지 않는다."""
    pepper = get_settings().session_hash_pepper.encode()
    return hashlib.sha256(pepper + raw.encode()).hexdigest()


async def issue_session(mbr_id: int) -> str:
    """불투명 토큰 발급 — DB엔 해시만 저장(+session_ttl_days), 원문 반환(쿠키 전용)."""
    raw = secrets.token_urlsafe(48)  # 원문(무저장)
    s = get_settings()
    await database.execute(
        "INSERT INTO TSESSION (MBR_ID, TOKEN_HASH_VAL, EXPIRES_DTM, INS_ID) "
        "VALUES (%s, %s, UTC_TIMESTAMP() + INTERVAL %s DAY, %s)",
        (mbr_id, _hash_token(raw), s.session_ttl_days, mbr_id),
    )
    return raw  # → Set-Cookie(set_session_cookie)


async def resolve_session(raw: str | None) -> dict | None:
    """유효 세션(미만료·미폐기)만 회원 dict({'MBR_ID':...}) 반환, 아니면 None."""
    if not raw:
        return None
    return await database.fetch_one(
        "SELECT MBR_ID FROM TSESSION "
        "WHERE TOKEN_HASH_VAL=%s AND REVOKED_DTM IS NULL AND EXPIRES_DTM > UTC_TIMESTAMP()",
        (_hash_token(raw),),
    )


async def revoke_session(raw: str) -> None:
    """세션 폐기(로그아웃, FR-104) — REVOKED_DTM 세팅."""
    await database.execute(
        "UPDATE TSESSION SET REVOKED_DTM = UTC_TIMESTAMP() WHERE TOKEN_HASH_VAL=%s",
        (_hash_token(raw),),
    )


async def purge_expired() -> int:
    """만료·폐기 세션 + 만료·소비 코드 퍼지(retention, FR-101). 반환=삭제 세션 행 수.

    lifespan 스케줄러가 주기 호출한다. 대상 테이블이 비어 있으면 무영향(no-op)."""
    deleted = await database.execute(
        "DELETE FROM TSESSION WHERE EXPIRES_DTM <= UTC_TIMESTAMP() OR REVOKED_DTM IS NOT NULL"
    )
    await database.execute(
        "DELETE FROM TAUTH_CODE WHERE EXPIRES_DTM <= UTC_TIMESTAMP() OR CONSUMED_DTM IS NOT NULL"
    )
    return deleted


def set_session_cookie(response, raw: str) -> None:
    """세션 쿠키 설정 — HttpOnly·Secure·SameSite=Lax·Path=/api/v1 (AS-1, SP-AUTH-12)."""
    response.set_cookie(
        key=COOKIE_NAME,
        value=raw,
        max_age=get_settings().session_ttl_days * 86400,
        httponly=True,
        secure=True,
        samesite="lax",
        path=_COOKIE_PATH,
    )


def clear_session_cookie(response) -> None:
    """세션 쿠키 삭제(로그아웃·탈퇴, FR-104) — 동일 Path 로 만료."""
    response.delete_cookie(key=COOKIE_NAME, path=_COOKIE_PATH)
