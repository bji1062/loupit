"""SP-AUTH-7·8 재직 인증 라우터 — 코드 발송·인증·수동 승인 요청 (FR-105~107).

회사 도메인 화이트리스트로 자동 인증(도메인 미등록 회사는 수동 승인 폴백). 세션은 미들웨어가
아니라 `deps.require_member`(Depends)로만 주입한다(INV-9, AU-2). 복지 편집 권한 게이트
`require_employment`은 이 인증 결과(active_verification)를 소비한다.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response

from server.deps import require_csrf, require_member
from server.models.employment import (
    CompanyRequestIn, EmployRequestIn, EmployVerifyCodeIn, EmployVerifyIn,
)
from server.services import auth_code, company_request, employment
from server.services.auth_code import CodeResult

router = APIRouter(tags=["employment"])


@router.post("/employment/verify-code", status_code=204)
async def request_employ_code(
    body: EmployVerifyCodeIn,
    _csrf: None = Depends(require_csrf), member: dict = Depends(require_member),
) -> Response:
    """회사 이메일로 인증 코드 발송 (AE-1·2, FR-105).

    등록 도메인 일치 → 204. 도메인 미등록 회사 → 409 manual_required(수동 승인 유도).
    도메인 불일치 → 422. **반송 이력 주소 → 409 mail_suppressed**(SP-AUTH-16).

    ⚠ 두 409 는 **`detail` 로만 구분된다**. 프론트(`verify.js sendOutcome`)가 409 를 전부
    manual_required 로 단정하면, 사용자는 오지 않을 수동 승인을 기다리게 된다.

    ⚠ 422 는 **막다른 길이 아니어야 한다**(2026-07-29). 회사에 도메인이 하나라도 등록되면
    그 회사는 `no_domains` 폴백을 잃는다 — 계열사·자회사 주소를 쓰는 재직자가 그 순간
    갈 곳이 없어진다. 그래서 `detail` 에 **등록 도메인 목록을 실어** 프론트가 "현재 도메인은
    …" 을 보여주고 수동 승인으로 이어가게 한다. 도메인 커버리지를 넓힐수록 이 경로가
    넓어지므로, 문자열이 아니라 **기계가 읽는 구조**로 보낸다(FastAPI 자체 검증 422 와
    구분해야 하므로 `code` 를 함께 싣는다 — 그쪽 `detail` 은 리스트다)."""
    status = await employment.domain_status(body.comp_id, body.company_email)
    if status == employment.DomainStatus.NO_DOMAINS:
        raise HTTPException(status_code=409, detail="manual_required")
    if status == employment.DomainStatus.MISMATCH:
        raise HTTPException(
            status_code=422,
            detail={
                "code": "domain_mismatch",
                "domains": await employment.registered_domains(body.comp_id),
            },
        )
    issued = await employment.issue_employ_code(body.comp_id, member["MBR_ID"], body.company_email)
    if issued == auth_code.SUPPRESSED:
        raise HTTPException(status_code=409, detail="mail_suppressed")
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


@router.post("/employment/company-requests", status_code=202)
async def submit_company_request(
    body: CompanyRequestIn, response: Response,
    _csrf: None = Depends(require_csrf), member: dict = Depends(require_member),
) -> dict:
    """회사 등록 요청 — **검색에 없는 회사**의 출구 (SP-AUTH-17, FR-107 확장).

    위 `/employment/requests` 와 형제지만 결정적으로 다르다: 저쪽은 회사가 **있고** 도메인만
    없을 때, 이쪽은 회사가 **아예 없을 때**다. 그래서 `comp_id` 를 받지 않는다.

    ⚠ 이 요청은 **회사를 만들지 않는다**. 등록은 전적으로 운영자 판단이다(사용자 결정) —
    자동 생성하면 복지 0건짜리 빈 회사가 비교 서비스에 쌓인다.

    202 접수 / 409 같은 회사 pending 중복 / 429 회원당 pending 상한 초과.
    """
    try:
        outcome = await company_request.submit(member["MBR_ID"], body.comp_nm, body.ref_url)
    except ValueError as exc:
        # 정규화·스킴 검증 실패(빈 이름·비 http 스킴 등). 사유를 그대로 노출해도 안전하다 —
        # 사용자가 방금 입력한 값에 대한 형식 안내이고 서버 내부 정보가 없다.
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    if outcome == "dup":
        raise HTTPException(status_code=409, detail="이미 같은 회사로 요청하셨어요.")
    if outcome == "too_many":
        raise HTTPException(
            status_code=429,
            detail=f"처리 대기 중인 요청이 {company_request.MAX_PENDING_PER_MEMBER}건이에요. "
                   "먼저 처리된 뒤에 다시 요청해주세요.",
        )
    response.headers["Cache-Control"] = "no-store"
    return {"status": "pending"}
