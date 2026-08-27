"""SP-COMM-6 신고 라우터 — `POST /reports` 접수 (FR-130).

접수는 대상을 바꾸지 않는다(자동 숨김 없음) — 처리는 운영 콘솔(`console.py`, FR-131)이 한다.
`require_csrf` → `require_member` 순서. 202 는 "받았고 나중에 사람이 본다"는 뜻이다.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from server.deps import require_csrf, require_member
from server.models.post import ReportIn
from server.services import report as report_svc

router = APIRouter(tags=["report"])


@router.post("/reports", status_code=202)
async def create_report(
    body: ReportIn,
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> JSONResponse:
    """신고 접수 → 202 `{report_id}`. 대상 부재·비활성 404 · 같은 (회원, 대상) 중복 409 · 일일 상한 429."""
    result = await report_svc.create_report(member["MBR_ID"], body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="오늘 신고 한도를 초과했습니다.")
    if result["result"] == "target_not_found":
        raise HTTPException(status_code=404, detail="신고 대상을 찾을 수 없습니다.")
    if result["result"] == "duplicate":
        raise HTTPException(status_code=409, detail="이미 신고한 대상입니다.")
    return JSONResponse(status_code=202, content={"report_id": result["report_id"]},
                        headers={"Cache-Control": "no-store"})
