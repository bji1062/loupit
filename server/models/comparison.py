"""비교 로그·트렌딩 응답 모델 (INV-1 개정 2026-07-14).

CompareLogIn은 익명 회사쌍만 받는다 — 사용자 식별자·연봉 등 입력값 필드를
절대 추가하지 않는다(FR-07 예외 한정 원칙).
"""
from __future__ import annotations

from pydantic import BaseModel, Field, model_validator


class CompareLogIn(BaseModel):
    """POST /comparisons/log 요청 본문 — comp_id 쌍뿐."""

    a: int = Field(..., ge=1, description="현재 직장(A) comp_id")
    b: int = Field(..., ge=1, description="이직 후보(B) comp_id")

    @model_validator(mode="after")
    def _distinct_pair(self):
        if self.a == self.b:
            raise ValueError("a와 b는 서로 다른 회사여야 합니다.")
        return self


class TrendingItem(BaseModel):
    """트렌딩 1행 — 쌍 표시명 + 최근 윈도우 비교 횟수."""

    a_comp_id: int
    a_comp_nm: str
    b_comp_id: int
    b_comp_nm: str
    cnt: int


class TrendingResponse(BaseModel):
    items: list[TrendingItem]
