"""SP-AUTH-5 인증 코드 — 6자리 코드 생성·해시·발급·검증·소비.

코드·이메일 원문 무저장(SHA-256 해시만, T9·INV-8). 코드 해시는 대상 이메일로 스코프해
교차 대입을 막고, 대상 해시는 조회키로만 쓴다. **신규 의존성 0**(stdlib `secrets`·`hashlib`).
검증은 시도 상한(`code_max_attempts`) → 만료 → 해시 대조(constant-time) → 소비 순이며,
결과는 라우트(member.py)가 상태코드로 매핑한다(불일치 401 / 만료 410 / 시도초과 429).
"""
from __future__ import annotations

import hashlib
import hmac
import logging
import secrets

from server import database
from server.config import get_settings

logger = logging.getLogger(__name__)


async def send_code_safe(send, code: str, purpose: str) -> None:
    """메일 발송 1회 — 실패를 삼키고 서버 로그로만 남긴다(2026-07-27).

    **왜 삼키는가**: 코드 발송 응답은 계정 유무와 무관하게 **균일 204** 여야 한다(계정 열거 차단,
    NFR31). 메일 예외가 그대로 오르면 500 이 되어 그 계약이 깨지고, SMTP 장애 구간에서 응답 코드가
    갈리는 관측 채널이 생긴다. 코드 행은 이미 저장돼 있으므로 사용자는 재전송으로 복구할 수 있다.

    **로그 위생**: 예외 문자열에 수신 주소·코드가 실려 오는 제공자가 있어(예: "relay refused for
    <addr>") 예외 메시지를 그대로 찍지 않는다 — 예외 **타입명과 용도**만 남긴다(NFR31)."""
    try:
        await send()
    except Exception as exc:  # 제공자 장애·자격 오류·타임아웃 등 — 균일 204 유지
        logger.error(
            "인증 코드 메일 발송 실패(용도=%s, 예외=%s) — 응답은 균일 204 유지. "
            "SMTP 설정·제공자 상태를 확인하세요.",
            purpose, type(exc).__name__,
        )


class CodeResult:
    """verify_login_code 반환값 — 라우트가 상태코드로 매핑(AL-3)."""

    OK = "ok"            # → 200
    MISMATCH = "mismatch"  # → 401 (코드 없음/불일치 — 계정 열거 방지 균일)
    EXPIRED = "expired"  # → 410
    TOO_MANY = "too_many"  # → 429


def _normalize_email(email: str) -> str:
    """**계정 식별키** 정규화 — 공백 제거 + 소문자.

    이 값이 `TMEMBER.LOGIN_EMAIL_NM`(계정 동일성)과 `_hash_code` 의 스코프를 결정한다.
    `+태그`·도트는 **보존**한다 — `me+work@gmail.com` 을 별개 계정으로 쓰는 사용자가 있고,
    기존 회원 데이터의 식별자가 바뀌면 계정이 통째로 갈린다. 폭탄 방지용 수신함 접기는
    이 함수가 아니라 `_delivery_address` 가 따로 담당한다(2026-07-27)."""
    return email.strip().lower()


# ── 배달 주소(폭탄 방지 전용 키) ──────────────────────────────────────────────────
# 구글 계열은 로컬파트의 도트를 무시한다(`v.i.ctim@gmail.com` == `victim@gmail.com`).
# **전 도메인에 적용하면 안 된다** — 도트가 유의미한 제공자가 있어(네이버·다음·대다수 사내
# Exchange) 전역 도트 제거는 서로 다른 사람의 주소를 한 쿨다운 통에 묶는다. 그러면 제3자가
# `v.ictim@naver.com` 을 요청해 `victim@naver.com` 의 로그인 코드를 막는 **반대 방향 사고**가 된다.
_DOT_INSENSITIVE_DOMAINS = frozenset({"gmail.com", "googlemail.com"})
# 같은 물리 수신함을 가리키는 도메인 별칭(구글: googlemail.com == gmail.com).
_DOMAIN_ALIASES = {"googlemail.com": "gmail.com"}


def _delivery_address(email: str) -> str:
    """**폭탄 방지 전용** '배달 주소' 정규화 — 같은 물리 수신함에 닿는 변형을 한 값으로 접는다.

    계정 식별키(`_normalize_email`)와 **분리된 개념**이다. 계정은 문자 그대로 구분하되,
    "이 수신함에 최근 메일을 보냈는가"를 묻는 쿨다운만 이 값으로 판정한다(적대검토 2026-07-27
    확증 결함: `victim@` / `victim+1@` / `v.i.ctim@` 이 같은 수신함인데 해시가 전부 달라
    쿨다운이 한 번도 발화하지 않았다 — 단일 IP 로 한 수신함에 4,320통/일).

    규칙 (1) 첫 `+` 이후 제거 — 서브어드레싱(RFC 5233)은 제공자 공통이라 도메인 무관 적용한다.
    `+`를 문자 그대로 쓰는 소수 제공자에선 서로 다른 주소가 한 통에 묶일 수 있으나, 그 대가는
    쿨다운 창(기본 60초)만큼의 발송 지연이고 반대쪽 대가는 무제한 메일 폭탄이다.
    (2) 도트 제거는 **구글 계열 한정**(위 `_DOT_INSENSITIVE_DOMAINS` 주석의 근거).
    (3) 접은 결과 로컬파트가 비면(`+a@x.com`·`...@gmail.com`) 원본 로컬파트를 유지한다 —
    `@x.com` 한 통으로 접히면 한 명이 그 도메인 전체의 코드 발송을 잠글 수 있다."""
    norm = _normalize_email(email)
    local, sep, domain = norm.rpartition("@")
    if not sep:  # 형식 이상(모델 검증을 통과하지 않은 경로) — 접지 않고 원문 그대로
        return norm
    domain = _DOMAIN_ALIASES.get(domain, domain)
    base = local.split("+", 1)[0]
    if domain in _DOT_INSENSITIVE_DOMAINS:
        base = base.replace(".", "")
    return f"{base or local}@{domain}"


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
    """대상 **수신함** 조회키 해시 = SHA-256(배달 주소)(원문 무저장, T9).

    `TAUTH_CODE.TARGET_HASH_VAL` 에 들어가는 값이며, 조회키 전용이다(계정 식별키 아님 —
    계정 스코프는 `_hash_code` 가 `_normalize_email` 로 유지한다). 2026-07-27 이전에는
    계정 식별키를 그대로 해시해 `+태그`/도트 변형이 쿨다운을 통째로 우회했다.

    **부수효과(의도된 것)**: 같은 수신함을 쓰는 별개 계정(`me@`·`me+work@`)의 코드 행이 한
    조회키를 공유한다. 코드 소비는 `CODE_HASH_VAL`(계정 스코프) 직접 매칭이라 서로의 코드를
    소비할 수 없고(섀도잉 내성 유지), 공유되는 것은 실패 경로의 상태 판정·시도 카운터뿐이다 —
    그 카운터는 원래도 평문 주소를 아는 제3자가 태울 수 있었으므로 새 공격면이 아니다."""
    return hashlib.sha256(_delivery_address(target).encode()).hexdigest()


async def recent_unconsumed_exists(target_hash: str, purpose: str, comp_id: int | None = None) -> bool:
    """재전송 쿨다운(FR-112) — `mail_resend_cooldown_sec` 창 안에 미소비 코드가 있으면 True.

    메일 폭탄·섀도잉(제3자가 피해자 이메일로 반복 코드 발급) 완화용. 쿨다운 중 재요청은 발송을
    억제하되 응답은 **균일 204 유지**(계정 열거 방지, NFR31). purpose+대상(+회사)로 스코프.

    `target_hash` 는 **배달 주소** 해시(`_hash_target`)여야 한다 — 계정 식별키를 그대로 해시하면
    `+태그`/도트 변형이 매번 다른 키가 돼 쿨다운이 한 번도 발화하지 않는다(적대검토 2026-07-27
    확증). 정확히 그 우회를 막는 것이 이 함수의 존재 이유다.

    **막지 못하는 것(정직한 상한)**: 쿨다운은 창당 1통을 허용하므로 한 수신함 기준
    `86400/mail_resend_cooldown_sec` 통/일(기본 60초 → 1,440통/일)은 여전히 가능하다. 절대 상한을
    낮추려면 쿨다운 값을 올리거나 배달 주소 기준 **일일 상한**이 따로 필요하다 — 후자는 만료·소비
    코드를 지우는 리텐션 퍼지(`session.purge_expired`) 때문에 TAUTH_CODE 행 카운트로는 셀 수 없어
    별도 저장이 든다(미구현, 상위 결정 대기)."""
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
    미소비 코드가 있으면 **무발송**(메일 폭탄·섀도잉 완화) — 응답은 여전히 204라 열거 단서가 없다.
    쿨다운 판정은 **배달 주소**(`_hash_target`) 기준이라 `+태그`/도트 변형으로 우회되지 않는다."""
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
    # 원문은 여기서 소멸(무저장). 발송 실패는 삼키고 로그만 — 균일 204 계약 유지(send_code_safe).
    await send_code_safe(lambda: mailer.get_mailer().send_login_code(norm, code), code, "login")


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
