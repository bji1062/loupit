"""SP-AUTH-5 인증 코드 — 6자리 코드 생성·해시·발급·검증·소비.

코드·이메일 원문 무저장(SHA-256 해시만, T9·INV-8). 코드 해시는 대상 이메일로 스코프해
교차 대입을 막고, 대상 해시는 조회키로만 쓴다. **신규 의존성 0**(stdlib `secrets`·`hashlib`).
검증은 시도 상한(`code_max_attempts`) → 만료 → 해시 대조(constant-time) → 소비 순이며,
결과는 라우트(member.py)가 상태코드로 매핑한다(불일치 401 / 만료 410 / 시도초과 429).
"""
from __future__ import annotations

import hashlib
import hmac
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
    """코드 해시 — 정규화 이메일 target 으로 스코프 + 서버 pepper HMAC(NFR30, 보안점검 2026-07-23).

    6자리 코드는 저엔트로피(10^6)라 무키 해시는 DB 유출 시 오프라인 무차별로 원문 복원된다.
    login_code_hmac_pepper(운영 필수)로 HMAC 해, pepper 를 모르는 DB-읽기 공격자는 후보 해시를
    계산할 수 없다. pepper 미설정(개발) 시 무키 폴백이나 운영에선 반드시 주입한다."""
    pepper = get_settings().login_code_hmac_pepper.encode()
    return hmac.new(pepper, f"{target}:{code}".encode(), hashlib.sha256).hexdigest()


def _hash_target(target: str) -> str:
    """대상 이메일 조회키 해시(원문 무저장, T9)."""
    return hashlib.sha256(_normalize_email(target).encode()).hexdigest()


async def recent_unconsumed_exists(target_hash: str, purpose: str, comp_id: int | None = None) -> bool:
    """재전송 쿨다운(FR-112) — `mail_resend_cooldown_sec` 창 안에 미소비 코드가 있으면 True.

    메일 폭탄·섀도잉(제3자가 피해자 이메일로 반복 코드 발급) 완화용. 쿨다운 중 재요청은 발송을
    억제하되 응답은 **균일 204 유지**(계정 열거 방지, NFR31). purpose+대상(+회사)로 스코프."""
    cooldown = get_settings().mail_resend_cooldown_sec
    if cooldown <= 0:
        return False
    if comp_id is None:
        row = await database.fetch_one(
            "SELECT 1 AS x FROM TAUTH_CODE WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD=%s "
            "AND CONSUMED_DTM IS NULL AND INS_DTM > UTC_TIMESTAMP() - INTERVAL %s SECOND LIMIT 1",
            (target_hash, purpose, cooldown),
        )
    else:
        row = await database.fetch_one(
            "SELECT 1 AS x FROM TAUTH_CODE WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD=%s AND COMP_ID=%s "
            "AND CONSUMED_DTM IS NULL AND INS_DTM > UTC_TIMESTAMP() - INTERVAL %s SECOND LIMIT 1",
            (target_hash, purpose, comp_id, cooldown),
        )
    return row is not None


async def issue_login_code(email: str) -> None:
    """로그인 코드 발급 — 해시만 저장(+login_code_ttl_min), 원문은 메일로만(무저장).

    계정 유무와 무관하게 항상 균일 204(호출측 member.py, 계정 열거 방지). 단 재전송 쿨다운 창 안에
    미소비 코드가 있으면 **무발송**(메일 폭탄·섀도잉 완화) — 응답은 여전히 204라 열거 단서가 없다."""
    from server import mailer  # 지연 import(라우트 조립 순서 무관)

    s = get_settings()
    norm = _normalize_email(email)
    target_hash = _hash_target(norm)
    if await recent_unconsumed_exists(target_hash, "login"):
        return  # 쿨다운 중 — 무발송(균일 204 유지)
    code = _gen_code()
    await database.execute(
        "INSERT INTO TAUTH_CODE (PURPOSE_CD, CODE_HASH_VAL, TARGET_HASH_VAL, EXPIRES_DTM, ATTEMPT_CNT) "
        "VALUES ('login', %s, %s, UTC_TIMESTAMP() + INTERVAL %s MINUTE, 0)",
        (_hash_code(code, norm), target_hash, s.login_code_ttl_min),
    )
    await mailer.get_mailer().send_login_code(norm, code)  # 원문은 여기서 소멸(무저장)


async def verify_login_code(email: str, code: str) -> str:
    """로그인 코드 검증·소비 → CodeResult(ok|mismatch|expired|too_many).

    원자적·섀도잉 내성 설계(보안점검 2026-07-23):
    (1) 정답 경로 — 제출 코드 해시(CODE_HASH_VAL)와 정확히 일치하는 live·미소비·시도상한 내 코드를
        **조건부 UPDATE 로 원자 소비**한다. 해시 직접 매칭이라 제3자가 발급시킨 최신 코드가 정당한
        코드를 밀어내지 못하고(섀도잉 내성), `CONSUMED_DTM IS NULL` 조건이 동시 성공 시에도 1코드→1세션을
        보장한다(락·트랜잭션 불필요).
    (2) 실패 경로 — 대상의 최신 미소비 코드로 상태(만료·상한)를 판정하고, 틀린 추측이면 시도를
        `AND ATTEMPT_CNT < 상한` 가드로 **원자 증가**해 동시요청으로도 code_max_attempts 를 못 넘게 한다.
    코드가 없으면 불일치(균일 401, 계정 열거 방지)."""
    norm = _normalize_email(email)
    s = get_settings()
    target_hash = _hash_target(norm)
    code_hash = _hash_code(code, norm)

    # (1) 정답 경로 — 해시 일치 live 코드를 원자 소비. rowcount>=1 → 성공.
    consumed = await database.execute(
        "UPDATE TAUTH_CODE SET CONSUMED_DTM = UTC_TIMESTAMP() "
        "WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD='login' AND CODE_HASH_VAL=%s "
        "AND CONSUMED_DTM IS NULL AND EXPIRES_DTM > UTC_TIMESTAMP() AND ATTEMPT_CNT < %s",
        (target_hash, code_hash, s.code_max_attempts),
    )
    if consumed:
        return CodeResult.OK

    # (2) 실패 경로 — 최신 미소비 코드로 상태 판정 + 틀린 추측 시 시도 원자 증가.
    row = await database.fetch_one(
        "SELECT AUTH_CODE_ID, ATTEMPT_CNT, (EXPIRES_DTM <= UTC_TIMESTAMP()) AS is_expired "
        "FROM TAUTH_CODE "
        "WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD='login' AND CONSUMED_DTM IS NULL "
        "ORDER BY AUTH_CODE_ID DESC LIMIT 1",
        (target_hash,),
    )
    if row is None:
        return CodeResult.MISMATCH
    if row["is_expired"]:
        return CodeResult.EXPIRED
    if row["ATTEMPT_CNT"] >= s.code_max_attempts:
        return CodeResult.TOO_MANY
    await database.execute(
        "UPDATE TAUTH_CODE SET ATTEMPT_CNT = ATTEMPT_CNT + 1 "
        "WHERE AUTH_CODE_ID=%s AND ATTEMPT_CNT < %s",
        (row["AUTH_CODE_ID"], s.code_max_attempts),
    )
    return CodeResult.MISMATCH
