"""SP-AUTH-9 복지 편집 요청 모델 — 등록(create)·수정(update) 입력 계약 (FR-108·109).

배지·금액출처(BADGE_CD·AMT_SOURCE_CD)는 **서버가 강제**하므로 입력에 없다(사용자가
official·stated 지정 불가). 정성(QUAL_YN) 불변식만 입력 단계에서 검증한다 —
정성인데 금액이 있으면 422(DC-9 위반, SP-AUTH-9 규칙4). 저장은 파라미터 바인딩,
표시 이스케이프는 표시 계층(SP-FE)이 담당한다(NFR21). 신규 의존성 0.
"""
from __future__ import annotations

import re
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

# 복지 카테고리 9종(SP-DB, test_data_contract.CATEGORIES_9와 동일). 그 외 값 → 422.
_CATEGORIES_9 = {
    "compensation", "flexibility", "work_env", "time_off",
    "health", "family", "growth", "leisure", "perks",
}
# 복지 코드 — 소문자 스네이크(예: meal, welfare_point). 회사 내 유니크(uq_comp_benefit).
_BENEFIT_CD_RE = re.compile(r"^[a-z][a-z0-9_]{1,29}$")


def _check_qual_invariant(qual_yn: bool, benefit_amt: int | None) -> None:
    """정성 불변식(DC-9) — 정성(QUAL_YN=true)이면 금액은 없어야 한다. 위반 → 422."""
    if qual_yn and benefit_amt is not None:
        raise ValueError("정성 복지는 금액을 가질 수 없습니다.")


class BenefitCreateIn(BaseModel):
    """POST /companies/{comp_id}/benefits — 복지 등록(FR-108). 배지·금액출처는 서버 강제라 입력 없음."""

    benefit_cd: str = Field(..., max_length=30)
    benefit_nm: str = Field(..., min_length=1, max_length=100)
    benefit_ctgr_cd: str = Field(..., max_length=20)
    benefit_amt: int | None = Field(default=None, ge=0)  # 만원. 정성이면 null
    qual_yn: bool = False
    note_ctnt: str | None = Field(default=None, max_length=200)
    edit_note: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def _validate(self) -> "BenefitCreateIn":
        self.benefit_cd = self.benefit_cd.strip().lower()
        if not _BENEFIT_CD_RE.match(self.benefit_cd):
            raise ValueError("복지 코드 형식이 올바르지 않습니다(소문자·숫자·_ 2~30자).")
        if self.benefit_ctgr_cd not in _CATEGORIES_9:
            raise ValueError("복지 카테고리가 올바르지 않습니다.")
        self.benefit_nm = self.benefit_nm.strip()
        if not self.benefit_nm:  # 공백-only 는 min_length=1 을 통과하나 strip 후 빈 이름 금지
            raise ValueError("복지 이름은 공백일 수 없습니다.")
        _check_qual_invariant(self.qual_yn, self.benefit_amt)
        return self


class BenefitUpdateIn(BaseModel):
    """PUT /companies/{comp_id}/benefits/{benefit_id} — 복지 수정(FR-109).

    `base_dtm`(읽은 행의 낙관적 동시성 토큰)은 필수 — 없으면 422(무조건 덮어쓰기 금지)."""

    base_dtm: str = Field(..., min_length=1, max_length=40)
    benefit_nm: str = Field(..., min_length=1, max_length=100)
    benefit_amt: int | None = Field(default=None, ge=0)
    qual_yn: bool = False
    note_ctnt: str | None = Field(default=None, max_length=200)
    edit_note: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def _validate(self) -> "BenefitUpdateIn":
        self.benefit_nm = self.benefit_nm.strip()
        if not self.benefit_nm:  # 공백-only 이름 금지(strip 후 빈 문자열)
            raise ValueError("복지 이름은 공백일 수 없습니다.")
        _check_qual_invariant(self.qual_yn, self.benefit_amt)
        return self


class EditLogItem(BaseModel):
    """GET /companies/{comp_id}/edits 응답 1건 — 공개 편집 이력(FR-110).

    편집자 식별은 **닉네임만**(이메일·MBR_ID 미노출, INV-8). before/after 는 스냅샷 JSON."""

    nickname: str
    edit_type: str            # ∈ {create, update, delete}
    before: dict | None = None
    after: dict | None = None
    edit_note: str | None = None
    dtm: datetime
