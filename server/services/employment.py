"""SP-AUTH-7·8 재직 인증 서비스 — 회사 도메인 화이트리스트 매칭·HMAC·원문 파기·인증/요청.

회사 이메일 원문은 저장하지 않는다 — 코드 발송 시점에만 쓰고, 인증 성공 시 HMAC
(COMP_EMAIL_HASH_VAL)만 남긴다(INV-8·NFR30·T9). 코드 발급·검증은 로그인과 동일한 해시·원자
소비 규약(auth_code)을 재사용하되 purpose='employ_verify' + COMP_ID 로 스코프한다.
신규 의존성 0(stdlib hmac·hashlib).
"""
from __future__ import annotations

import hashlib
import hmac

from pymysql.err import IntegrityError

from server import database
from server.config import get_settings
from server.services import auth_code
from server.services.auth_code import CodeResult

_PURPOSE = "employ_verify"


class DomainStatus:
    OK = "ok"                  # 등록 도메인 일치 → 코드 발송
    MISMATCH = "mismatch"      # 등록 도메인과 불일치 → 422
    NO_DOMAINS = "no_domains"  # 회사에 등록 도메인 없음 → 409 manual_required


def _normalize_domain(email: str) -> str:
    return email.rsplit("@", 1)[-1].strip().lower()


def _hmac_email(email: str) -> str:
    """회사 이메일 HMAC(중복 인증 차단 조회키, 원문 무저장). comp_email_hmac_pepper 운영 필수(NFR30)."""
    key = get_settings().comp_email_hmac_pepper.encode()
    return hmac.new(key, email.strip().lower().encode(), hashlib.sha256).hexdigest()


async def domain_status(comp_id: int, email: str) -> str:
    """회사 등록 도메인 대비 입력 이메일 도메인 상태 → DomainStatus(ok|mismatch|no_domains)."""
    rows = await database.fetch_all(
        "SELECT EMAIL_DOMAIN_NM FROM TCOMPANY_EMAIL_DOMAIN WHERE COMP_ID=%s AND ACTIVE_YN=TRUE",
        (comp_id,),
    )
    if not rows:
        return DomainStatus.NO_DOMAINS
    registered = {r["EMAIL_DOMAIN_NM"].strip().lower() for r in rows}
    return DomainStatus.OK if _normalize_domain(email) in registered else DomainStatus.MISMATCH


async def active_verification(mbr_id: int, comp_id: int) -> dict | None:
    """활성(미폐기·미만료) 재직 인증 1건 → deps.require_employment·중복 인증 검사용(없으면 None)."""
    return await database.fetch_one(
        "SELECT EMPLOY_VRF_ID, COMP_ID FROM TEMPLOY_VERIFICATION "
        "WHERE MBR_ID=%s AND COMP_ID=%s AND REVOKED_DTM IS NULL "
        "AND (EXPIRES_DTM IS NULL OR EXPIRES_DTM > UTC_TIMESTAMP()) LIMIT 1",
        (mbr_id, comp_id),
    )


async def issue_employ_code(comp_id: int, mbr_id: int, company_email: str) -> None:
    """재직 인증 코드 발급 — 해시만 저장(+login_code_ttl_min), 회사 이메일로 발송. 원문 무저장."""
    from server import mailer  # 지연 import(조립 순서 무관)

    s = get_settings()
    norm = auth_code._normalize_email(company_email)
    target_hash = auth_code._hash_target(norm)
    if await auth_code.recent_unconsumed_exists(target_hash, _PURPOSE, comp_id):
        return  # 재전송 쿨다운 중 — 무발송(회사 이메일 폭탄 완화, 호출측 204 유지)
    code = auth_code._gen_code()
    await database.execute(
        "INSERT INTO TAUTH_CODE (PURPOSE_CD, CODE_HASH_VAL, TARGET_HASH_VAL, COMP_ID, MBR_ID, EXPIRES_DTM, ATTEMPT_CNT) "
        "VALUES (%s, %s, %s, %s, %s, UTC_TIMESTAMP() + INTERVAL %s MINUTE, 0)",
        (_PURPOSE, auth_code._hash_code(code, norm), target_hash, comp_id, mbr_id, s.login_code_ttl_min),
    )
    await mailer.get_mailer().send_employ_code(norm, code)  # 원문은 여기서 소멸


async def verify_employ_code(comp_id: int, company_email: str, code: str) -> str:
    """재직 코드 검증·소비 → CodeResult. 로그인과 동일한 원자·섀도잉 내성 규약, purpose+comp_id 스코프."""
    norm = auth_code._normalize_email(company_email)
    s = get_settings()
    target_hash = auth_code._hash_target(norm)
    code_hash = auth_code._hash_code(code, norm)

    consumed = await database.execute(
        "UPDATE TAUTH_CODE SET CONSUMED_DTM = UTC_TIMESTAMP() "
        "WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD=%s AND COMP_ID=%s AND CODE_HASH_VAL=%s "
        "AND CONSUMED_DTM IS NULL AND EXPIRES_DTM > UTC_TIMESTAMP() AND ATTEMPT_CNT < %s",
        (target_hash, _PURPOSE, comp_id, code_hash, s.code_max_attempts),
    )
    if consumed:
        return CodeResult.OK

    row = await database.fetch_one(
        "SELECT AUTH_CODE_ID, ATTEMPT_CNT, (EXPIRES_DTM <= UTC_TIMESTAMP()) AS is_expired "
        "FROM TAUTH_CODE WHERE TARGET_HASH_VAL=%s AND PURPOSE_CD=%s AND COMP_ID=%s AND CONSUMED_DTM IS NULL "
        "ORDER BY AUTH_CODE_ID DESC LIMIT 1",
        (target_hash, _PURPOSE, comp_id),
    )
    if row is None:
        return CodeResult.MISMATCH
    if row["is_expired"]:
        return CodeResult.EXPIRED
    if row["ATTEMPT_CNT"] >= s.code_max_attempts:
        return CodeResult.TOO_MANY
    await database.execute(
        "UPDATE TAUTH_CODE SET ATTEMPT_CNT = ATTEMPT_CNT + 1 WHERE AUTH_CODE_ID=%s AND ATTEMPT_CNT < %s",
        (row["AUTH_CODE_ID"], s.code_max_attempts),
    )
    return CodeResult.MISMATCH


async def create_domain_verification(mbr_id: int, comp_id: int, company_email: str) -> str:
    """재직 인증(domain) 생성 → 'ok'|'already_verified'|'hmac_dup'. 회사 이메일 원문 파기·HMAC만."""
    if await active_verification(mbr_id, comp_id):
        return "already_verified"
    s = get_settings()
    try:
        await database.execute(
            "INSERT INTO TEMPLOY_VERIFICATION "
            "(MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM, INS_ID) "
            "VALUES (%s, %s, 'domain', %s, UTC_TIMESTAMP() + INTERVAL %s DAY, %s)",
            (mbr_id, comp_id, _hmac_email(company_email), s.employ_vrf_ttl_days, mbr_id),
        )
        return "ok"
    except IntegrityError:  # COMP_EMAIL_HASH_VAL UNIQUE — 이 회사 이메일이 타 계정에 기인증(한 회사이메일 1계정)
        return "hmac_dup"


async def submit_manual_request(mbr_id: int, comp_id: int, evidence: str) -> str:
    """수동 승인 요청 생성(pending) → 'ok'|'dup'. 동일 회사 pending 중복 방지.

    evidence 는 파라미터 바인딩으로 저장(SQLi 안전)하고, HTML 이스케이프는 표시 계층(SP-FE·CLI 터미널)이 담당한다."""
    existing = await database.fetch_one(
        "SELECT VRF_REQUEST_ID FROM TEMPLOY_VRF_REQUEST "
        "WHERE MBR_ID=%s AND COMP_ID=%s AND STATUS_CD='pending' LIMIT 1",
        (mbr_id, comp_id),
    )
    if existing:
        return "dup"
    await database.execute(
        "INSERT INTO TEMPLOY_VRF_REQUEST (MBR_ID, COMP_ID, STATUS_CD, EVIDENCE_CTNT, INS_ID) "
        "VALUES (%s, %s, 'pending', %s, %s)",
        (mbr_id, comp_id, evidence, mbr_id),
    )
    return "ok"
