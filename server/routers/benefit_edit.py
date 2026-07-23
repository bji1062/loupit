"""SP-AUTH-9·10 복지 편집 라우터 — 복지 등록·수정·편집 이력 공개 조회 (FR-108~110).

- 편집 쓰기(POST·PUT)는 `deps.require_employment(comp_id)` 로만 진입한다(INV-9, IDOR 방어).
  `require_member`(세션)를 함께 의존해 편집자 MBR_ID 를 얻는다(감사·이력 기록용).
- 편집 이력 조회(GET /edits)는 **세션 불필요**(익명 공개, 나무위키식 이력, FR-110).
- 서버가 배지 시맨틱을 강제하고(사용자는 official·stated 지정 불가), 본체+이력을 원자
  트랜잭션으로 처리한다(서비스 계층). calc.js 는 무변경 — 표시 계층만 확장한다(INV-5).
- 사용자 대면 DELETE 라우트는 두지 않는다(복지 삭제는 운영자 CLI 전용, FR-100·115).
- 쓰기(POST/PUT)는 `deps.require_csrf`(커스텀 헤더 `X-Loupit-Client` 부재 시 403, FR-113)를 세션·재직보다 먼저 통과해야 한다(T-13.13.1). GET /edits 는 비대상(익명 공개).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, Response
from fastapi.responses import JSONResponse

from server.deps import require_csrf, require_employment, require_member
from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn, EditLogItem
from server.services import benefit_edit

router = APIRouter(tags=["benefit_edit"])


def _invalidate_reference_cache(request: Request) -> None:
    """편집 반영 — 참조 번들 인메모리 캐시 무효화(다음 /reference/all 재조립). 미기동 시 no-op."""
    cache = getattr(request.app.state, "reference_cache", None)
    if cache is not None:
        cache.clear()


@router.post("/companies/{comp_id}/benefits", status_code=201)
async def create_benefit(
    body: BenefitCreateIn,
    request: Request,
    comp_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
    _employment: dict = Depends(require_employment),
) -> JSONResponse:
    """복지 등록 (AB-*, FR-108) — 재직 인증 게이트·배지 서버 강제·편집 이력 append.

    401(무세션)·403(재직 미보유)·409(동일 회사·코드 중복)·429(일일 상한)·422(정성 불변식)."""
    result = await benefit_edit.create_benefit(comp_id, member["MBR_ID"], body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="일일 편집 한도를 초과했습니다.")
    if result["result"] == "duplicate":
        raise HTTPException(status_code=409, detail="이미 등록된 복지 코드입니다.")
    _invalidate_reference_cache(request)
    return JSONResponse(
        status_code=201,
        content={"benefit": result["benefit"], "benefits": result["benefits"]},
        headers={"Cache-Control": "no-store"},
    )


@router.put("/companies/{comp_id}/benefits/{benefit_id}")
async def update_benefit(
    body: BenefitUpdateIn,
    request: Request,
    comp_id: int = Path(..., ge=1),
    benefit_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
    _employment: dict = Depends(require_employment),
) -> JSONResponse:
    """복지 수정 (AB-3, FR-109) — base_dtm 낙관적 동시성·official→verified 강등·이력 append.

    404(미존재)·409(base_dtm 불일치 시 현재 행 동봉)·429(일일 상한)·422(정성 불변식·base_dtm 누락)."""
    result = await benefit_edit.update_benefit(comp_id, benefit_id, member["MBR_ID"], body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="일일 편집 한도를 초과했습니다.")
    if result["result"] == "not_found":
        raise HTTPException(status_code=404, detail="복지 항목을 찾을 수 없습니다.")
    if result["result"] == "conflict":  # 선점 수정 — 현재 행 동봉해 클라이언트 재조정(FR-109)
        return JSONResponse(
            status_code=409,
            content={"current_benefit": result["current_benefit"], "benefits": result["benefits"]},
            headers={"Cache-Control": "no-store"},
        )
    _invalidate_reference_cache(request)
    return JSONResponse(
        status_code=200,
        content={"benefit": result["benefit"], "benefits": result["benefits"]},
        headers={"Cache-Control": "no-store"},
    )


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
