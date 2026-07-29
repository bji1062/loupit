"""SP-AUTH-7·8 재직 인증 요청 모델. 이메일 검증은 stdlib re 만(신규 의존성 0)."""
from __future__ import annotations

import re

from pydantic import BaseModel, Field, field_validator

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class EmployVerifyCodeIn(BaseModel):
    """POST /employment/verify-code — 회사 선택 + 회사 이메일."""

    comp_id: int = Field(..., ge=1)
    company_email: str = Field(..., max_length=255)

    @field_validator("company_email")
    @classmethod
    def _valid_email(cls, v: str) -> str:
        v = v.strip()
        if not _EMAIL_RE.match(v):
            raise ValueError("이메일 형식이 올바르지 않습니다.")
        return v


class EmployVerifyIn(EmployVerifyCodeIn):
    """POST /employment/verify — 회사 이메일 + 6자리 코드."""

    code: str = Field(..., min_length=6, max_length=6)

    @field_validator("code")
    @classmethod
    def _valid_code(cls, v: str) -> str:
        if not v.isdigit():
            raise ValueError("코드는 6자리 숫자입니다.")
        return v


class EmployRequestIn(BaseModel):
    """POST /employment/requests — 수동 승인 요청(회사 + 증빙 서술)."""

    comp_id: int = Field(..., ge=1)
    evidence: str = Field(..., min_length=1, max_length=1000)

    @field_validator("evidence")
    @classmethod
    def _strip_evidence(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("증빙 내용을 입력하세요.")
        return v


class CompanyRequestIn(BaseModel):
    """POST /employment/company-requests — 회사 등록 요청(SP-AUTH-17).

    검색에 없는 회사를 등록해 달라는 요청이다. `comp_id` 가 **없는 것이 핵심** —
    아직 존재하지 않는 회사라서 참조할 ID 가 없다(EmployRequestIn 과의 결정적 차이).

    `ref_url` 은 **선택**이다(사용자 결정). 있으면 운영자가 빨리 확인할 수 있을 뿐,
    없다고 요청을 막지 않는다 — 막으면 URL 을 못 찾는 사용자가 그냥 이탈한다.
    정규화·스킴 검증은 `services.company_request` 가 소유한다(모델은 형태만 본다).
    """

    comp_nm: str = Field(..., min_length=1, max_length=100)
    ref_url: str | None = Field(default=None, max_length=500)
