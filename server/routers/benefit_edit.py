"""SP-AUTH-9·10 복지 편집 라우터 — 복지 등록·수정·편집 이력 공개 조회 (FR-108~110).

- 편집 쓰기(POST·PUT)는 `deps.require_employment(comp_id)` 로만 진입한다(INV-9, IDOR 방어).
  `require_member`(세션)를 함께 의존해 편집자 MBR_ID 를 얻는다(감사·이력 기록용).
- **POST·PUT 은 바로 반영하지 않고 운영자 확인 요청만 만든다(202)** — 반영은 운영 콘솔 승인(`routers/console.py`)이
  한다(2026-10-21 사용자 결정). 그래서 참조 번들 캐시도 여기서가 아니라 승인 때 비운다.
- 편집 이력 조회(GET /edits)는 **세션 불필요**(익명 공개, 나무위키식 이력, FR-110).
- 서버가 배지 시맨틱을 강제하고(사용자는 official·stated 지정 불가), 승인 때 본체+이력을 원자
  트랜잭션으로 처리한다(서비스 계층). calc.js 는 무변경 — 표시 계층만 확장한다(INV-5).
- 사용자 대면 DELETE 라우트는 두지 않는다(복지 삭제는 운영자 CLI 전용, FR-100·115).
- 쓰기(POST/PUT)는 `deps.require_csrf`(커스텀 헤더 `X-Loupit-Client` 부재 시 403, FR-113)를 세션·재직보다 먼저 통과해야 한다(T-13.13.1). GET /edits 는 비대상(익명 공개).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, Response
from fastapi.responses import JSONResponse

from server.deps import require_csrf, require_employment, require_member
from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn, EditLogItem
from server.services import benefit_codes, benefit_edit

router = APIRouter(tags=["benefit_edit"])


@router.post("/companies/{comp_id}/benefits", status_code=202)
async def create_benefit(
    body: BenefitCreateIn,
    request: Request,
    comp_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
    _employment: dict = Depends(require_employment),
) -> JSONResponse:
    """복지 등록 **확인 요청** (AB-*, FR-108) — 재직 인증 게이트 뒤에서 요청 한 줄만 만든다(202).

    본체·편집 이력은 건드리지 않는다. 운영자가 콘솔에서 승인해야 사이트에 반영된다(2026-10-21 사용자 결정).
    401(무세션)·403(재직 미보유)·409(그 회사에 이미 있는 코드 / 같은 대상 대기 중)·429(일일 상한)·
    422(정성 불변식·표준 코드 밖)."""
    codes = await benefit_codes.get_code_map(getattr(request.app.state, "reference_cache", None))
    result = await benefit_edit.create_request(comp_id, member["MBR_ID"], body, codes)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="일일 편집 한도를 초과했습니다.")
    if result["result"] == "unknown_code":
        raise HTTPException(status_code=422, detail="표준 복지 목록에 없는 코드입니다.")
    if result["result"] == "duplicate":
        raise HTTPException(status_code=409, detail="이미 있는 항목입니다. 목록에서 수정해 주세요.")
    if result["result"] == "pending_exists":
        raise HTTPException(status_code=409, detail="이미 확인 대기 중인 요청이 있습니다.")
    return JSONResponse(
        status_code=202,
        content={"request": result["request"]},
        headers={"Cache-Control": "no-store"},
    )


@router.put("/companies/{comp_id}/benefits/{benefit_id}", status_code=202)
async def update_benefit(
    body: BenefitUpdateIn,
    comp_id: int = Path(..., ge=1),
    benefit_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
    _employment: dict = Depends(require_employment),
) -> JSONResponse:
    """복지 수정 **확인 요청** (AB-3, FR-109) — base_dtm 낙관적 동시성 확인 뒤 요청 한 줄만 만든다(202).

    본체는 그대로다(승인 때 반영, 그때 토큰이 제출 때와 다르면 stale).
    404(미존재)·409(base_dtm 불일치 시 현재 행 동봉 / 이미 확인 대기 중)·429(일일 상한)·
    422(정성 불변식·base_dtm 누락)."""
    result = await benefit_edit.update_request(comp_id, benefit_id, member["MBR_ID"], body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="일일 편집 한도를 초과했습니다.")
    if result["result"] == "not_found":
        raise HTTPException(status_code=404, detail="복지 항목을 찾을 수 없습니다.")
    if result["result"] == "pending_exists":
        raise HTTPException(status_code=409, detail="이미 확인 대기 중인 요청이 있습니다.")
    if result["result"] == "conflict":  # 선점 수정 — 현재 행 동봉해 클라이언트 재조정(FR-109)
        return JSONResponse(
            status_code=409,
            content={"current_benefit": result["current_benefit"], "benefits": result["benefits"]},
            headers={"Cache-Control": "no-store"},
        )
    return JSONResponse(
        status_code=202,
        content={"request": result["request"]},
        headers={"Cache-Control": "no-store"},
    )


@router.get("/companies/{comp_id}/benefits")
async def list_benefits_for_edit(
    response: Response,
    comp_id: int = Path(..., ge=1),
    member: dict = Depends(require_member),
    _employment: dict = Depends(require_employment),
) -> JSONResponse:
    """편집용 복지 목록 (FR-109 부트스트랩) — 재직 인증자에게 각 복지의 `base_dtm`(낙관동시성 토큰) 동봉.

    기존(시드) 복지를 수정하려면 읽은 행의 base_dtm 이 필요한데, 공개 캐시 경로(GET /companies/{id})엔
    편집 토큰을 두지 않는다(캐시 stale→오탐 409 방지). 편집 폼은 이 인증·no-store 경로로 토큰을
    부트스트랩한다. 함께 **이 회원의 이 회사 요청**(대기 전부 + 최근 30일 결정분)을 싣는다 — 남의 요청은
    나가지 않는다. 세션 없음 401·해당 회사 재직 미보유 403. GET 이라 CSRF 비대상."""
    benefits = await benefit_edit.fetch_company_benefits(comp_id)
    requests = await benefit_edit.list_my_requests(comp_id, member["MBR_ID"])
    response.headers["Cache-Control"] = "no-store"
    return JSONResponse(content={"benefits": benefits, "requests": requests},
                        headers={"Cache-Control": "no-store"})


@router.get("/companies/{comp_id}/edits", response_model=list[EditLogItem])
async def list_edits(
    response: Response,
    comp_id: int = Path(..., ge=1),
    limit: int = Query(50, ge=1, le=200),
    before: int | None = Query(default=None, ge=1),  # 커서(EDIT_LOG_ID) — 이 값보다 오래된 이력
) -> list[EditLogItem]:
    """편집 이력 공개 조회 (AH-*, FR-110) — 익명 가능·최신순·닉네임만·no-store. 미존재 회사 404."""
    if not await benefit_edit.company_exists(comp_id):
        raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")
    response.headers["Cache-Control"] = "no-store"
    edits = await benefit_edit.list_edits(comp_id, limit, before)
    return [EditLogItem(**e) for e in edits]
