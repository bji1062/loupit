"""SP-AUTH-5·6 회원 요청·응답 모델 — 무비밀번호 로그인.

이메일 검증은 stdlib `re` 만 쓴다(**신규 의존성 0** — EmailStr/email-validator 미사용, SP-AUTH).
코드는 6자리 숫자 문자열(앞자리 0 보존이라 int 금지).
"""
from __future__ import annotations

import re
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

# 로컬@도메인.tld 최소 형식 — 공백·@ 없음, 점 포함 도메인. RFC 완전검증 아님(발송으로 검증).
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class LoginCodeIn(BaseModel):
    """POST /members/login-code 요청 본문 — 이메일뿐."""

    email: str = Field(..., max_length=255)

    @field_validator("email")
    @classmethod
    def _valid_email(cls, v: str) -> str:
        v = v.strip()
        if not _EMAIL_RE.match(v):
            raise ValueError("이메일 형식이 올바르지 않습니다.")
        return v


class LoginIn(LoginCodeIn):
    """POST /members/login 요청 본문 — 이메일 + 6자리 코드."""

    code: str = Field(..., min_length=6, max_length=6)

    @field_validator("code")
    @classmethod
    def _valid_code(cls, v: str) -> str:
        if not v.isdigit():
            raise ValueError("코드는 6자리 숫자입니다.")
        return v


class LoginResult(BaseModel):
    """POST /members/login 성공 응답 — 닉네임 + 신규 가입 여부."""

    nickname: str
    is_new: bool


# 닉네임 제약(SP-AUTH-6.4, NFR21) — 본 문서 소유. 저장은 파라미터 바인딩, 표시 이스케이프는 SP-FE.
_NICK_RE = re.compile(r"^[0-9A-Za-z가-힣_\- ]{2,20}$")  # 한글·영숫자·_-·공백, 2~20자
_BANNED_NICK = ("관리자", "운영자", "운영진", "admin", "administrator", "loupit", "루핏")


class NicknameUpdateIn(BaseModel):
    """PUT /members/me 요청 본문 — 닉네임 변경."""

    nickname: str = Field(..., max_length=30)

    @field_validator("nickname")
    @classmethod
    def _valid_nickname(cls, v: str) -> str:
        v = v.strip()
        if not _NICK_RE.match(v):
            raise ValueError("닉네임은 2~20자의 한글·영문·숫자·_- 만 가능합니다.")
        low = v.lower().replace(" ", "")
        if any(bad in low for bad in _BANNED_NICK):
            raise ValueError("사용할 수 없는 닉네임입니다.")
        return v


class VerificationItem(BaseModel):
    """재직 인증 1건(마이페이지 표시용)."""

    comp_id: int
    comp_nm: str
    expires_dtm: datetime | None = None


class MeResponse(BaseModel):
    """GET/PUT /members/me 응답 — 닉네임·상태·활성 재직 인증 목록(회사 이메일·MBR_ID 미노출, INV-8)."""

    nickname: str
    status: str
    verifications: list[VerificationItem] = []
