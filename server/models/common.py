"""SP-API-6.3 공용 응답 모델 — health·오류 envelope(문서용)."""
from __future__ import annotations

from pydantic import BaseModel


class HealthResponse(BaseModel):  # FR-91
    status: str  # "ok" | "degraded"


class ErrorEnvelope(BaseModel):  # FR-95 문서용(FastAPI 기본 {"detail": ...})
    detail: str
