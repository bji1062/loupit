"""SP-API-8 GET /health — 라이브니스(프로세스 생존)만 표현한다.

DB 조회 없음. 레디니스 503 확장(T-04.6.2)은 DG-4 미채택(2026-07-11 확정)으로
구현하지 않는다 — MVP는 라이브니스 전용.
"""
from __future__ import annotations

from fastapi import APIRouter, Response

from server.models.common import HealthResponse

router = APIRouter(tags=["health"])


@router.api_route("/health", methods=["GET", "HEAD"], response_model=HealthResponse)
async def health(response: Response) -> HealthResponse:
    response.headers["Cache-Control"] = "no-store"
    return HealthResponse(status="ok")
