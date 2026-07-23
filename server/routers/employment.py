"""SP-AUTH-7·8 재직 인증 라우터 — 코드 발송·인증·수동 승인 요청 (FR-105~107).

회사 도메인 화이트리스트로 자동 인증(도메인 미등록 회사는 수동 승인 폴백). 세션은 미들웨어가
아니라 `deps.require_member`(Depends)로만 주입한다(INV-9, AU-2). 복지 편집 권한 게이트
`require_employment`은 이 인증 결과(active_verification)를 소비한다.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response

from server.deps import require_csrf, require_member
from server.models.employment import EmployRequestIn, EmployVerifyCodeIn, EmployVerifyIn
from server.services import employment
from server.services.auth_code import CodeResult

router = APIRouter(tags=["employment"])


@router.post("/employment/verify-code", status_code=204)
async def request_employ_code(
    body: EmployVerifyCodeIn,
    _csrf: None = Depends(require_csrf), member: dict = Depends(require_member),
) -> Response:
    """회사 이메일로 인증 코드 발송 (AE-1·2, FR-105).

    등록 도메인 일치 → 204. 도메인 미등록 회사 → 409 manual_required(수동 승인 유도).
    도메인 불일치 → 422."""
    status = await employment.domain_status(body.comp_id, body.company_email)
    if status == employment.DomainStatus.NO_DOMAINS:
        raise HTTPException(status_code=409, detail="manual_required")
    if status == employment.DomainStatus.MISMATCH:
        raise HTTPException(status_code=422, detail="회사 이메일 도메인이 일치하지 않습니다.")
    await employment.issue_employ_code(body.comp_id, member["MBR_ID"], body.company_email)
    return Response(status_code=204, headers={"Cache-Control": "no-store"})


@router.post("/employment/verify", status_code=201)
async def verify_employment(
    body: EmployVerifyIn, response: Response,
    _csrf: None = Depends(require_csrf), member: dict = Depends(require_member),
) -> dict:
    """코드 검증 → 재직 인증(domain) 생성 (AE-3·4, FR-106).

    실패: 불일치 401 / 만료 410 / 시도 상한 429. 이미 인증됨·회사 이메일 중복 → 409."""
    result = await employment.verify_employ_code(body.comp_id, body.company_email, body.code)
    if result == CodeResult.EXPIRED:
        raise HTTPException(status_code=410, detail="코드가 만료되었습니다.")
    if result == CodeResult.TOO_MANY:
        raise HTTPException(status_code=429, detail="시도 횟수를 초과했습니다.")
    if result != CodeResult.OK:
        raise HTTPException(status_code=401, detail="코드가 일치하지 않습니다.")

    outcome = await employment.create_domain_verification(member["MBR_ID"], body.comp_id, body.company_email)
    if outcome == "already_verified":
        raise HTTPException(status_code=409, detail="이미 인증된 회사입니다.")
    if outcome == "hmac_dup":
        raise HTTPException(status_code=409, detail="이미 사용된 회사 이메일입니다.")
    response.headers["Cache-Control"] = "no-store"
    return {"comp_id": body.comp_id, "method": "domain"}


@router.post("/employment/requests", status_code=202)
async def submit_request(
    body: EmployRequestIn, response: Response,
    _csrf: None = Depends(require_csrf), member: dict = Depends(require_member),
) -> dict:
    """수동 승인 요청(도메인 미등록 회사 폴백) → 202 pending (AE-5, FR-107). 동일 회사 pending 중복 → 409."""
    outcome = await employment.submit_manual_request(member["MBR_ID"], body.comp_id, body.evidence)
    if outcome == "dup":
        raise HTTPException(status_code=409, detail="이미 대기 중인 요청이 있습니다.")
    response.headers["Cache-Control"] = "no-store"
    return {"status": "pending"}
