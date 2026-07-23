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
