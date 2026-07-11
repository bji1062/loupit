"""SP-API-6.2 회사 검색 축소 투영 모델."""
from __future__ import annotations

from pydantic import BaseModel


class CompanySearchItem(BaseModel):  # FR-D6 (축소 투영 5필드)
    comp_id: int
    comp_nm: str
    comp_tp_cd: str
    industry_nm: str | None = None
    logo_nm: str | None = None
