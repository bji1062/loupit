"""SP-COMM-7 커뮤니티 요청·응답 모델 — 입력 신뢰 경계 (FR-124~130·132).

**서버는 HTML 을 만들지 않는다.** 저장은 파라미터 바인딩, 표시 이스케이프는 클라이언트
`textContent`(NFR21). 여기서 하는 일은 셋뿐이다 — ① strip 후 빈 문자열 거부(422) ② 제어문자
제거 ③ 값집합·길이·URL 개수(스팸) 검사. 값집합은 ENUM 이 아니라 여기서 강제한다(SP-DB-18.5).
신규 의존성 0(stdlib `re`).
"""
from __future__ import annotations

import re
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

# 값 집합(SP-DB-18.5) — 그 외 값 → 422.
CATEGORIES = frozenset({"notice", "free", "career", "suggestion"})
SORTS = frozenset({"latest", "comments", "likes"})
REPORT_TARGET_TYPES = frozenset({"post", "comment"})
REPORT_REASONS = frozenset({"spam", "abuse", "privacy", "other"})
DECIDE_ACTIONS = frozenset({"hide", "dismiss"})

BODY_URL_MAX = 3  # 본문 URL(`https?://`) 초과 시 422 — 스팸 1차 방어(FR-132)

# 제어문자 — 탭(\x09)·줄바꿈(\x0a)·캐리지리턴(\x0d)은 남긴다(본문은 줄바꿈만 허용하는 서식이다).
_CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
_URL_RE = re.compile(r"https?://", re.IGNORECASE)


def clean_text(value: str | None) -> str:
    """제어문자 제거 + strip. None 은 빈 문자열."""
    if value is None:
        return ""
    return _CONTROL_RE.sub("", value).strip()


def _require_nonempty(value: str, label: str, max_len: int) -> str:
    cleaned = clean_text(value)
    if not cleaned:  # 공백-only 는 min_length 를 통과하나 strip 후 빈 문자열 → 422
        raise ValueError(f"{label}은(는) 공백일 수 없습니다.")
    if len(cleaned) > max_len:
        raise ValueError(f"{label}은(는) {max_len}자 이하여야 합니다.")
    return cleaned


def _check_url_count(body: str) -> None:
    if len(_URL_RE.findall(body)) > BODY_URL_MAX:
        raise ValueError(f"본문에 링크는 {BODY_URL_MAX}개까지만 넣을 수 있습니다.")


class PostCreateIn(BaseModel):
    """POST /posts — 글 작성(FR-124). `category=notice` 권한은 라우터가 본다(403)."""

    category: str = Field(..., max_length=12)
    title: str = Field(..., max_length=200)   # 1차 상한(strip 전). 실제 100자 계약은 아래 검증
    body: str = Field(..., max_length=6000)   # 1차 상한(strip 전). 실제 5,000자 계약은 아래 검증
    comp_id: int | None = Field(default=None, ge=1)

    @model_validator(mode="after")
    def _validate(self) -> "PostCreateIn":
        if self.category not in CATEGORIES:
            raise ValueError("카테고리가 올바르지 않습니다.")
        self.title = _require_nonempty(self.title, "제목", 100)
        self.body = _require_nonempty(self.body, "본문", 5000)
        _check_url_count(self.body)
        return self


class PostUpdateIn(BaseModel):
    """PUT /posts/{post_id} — 글 수정(FR-125). **`category` 는 받지 않는다**(공지 승격 경로 차단)."""

    title: str = Field(..., max_length=200)
    body: str = Field(..., max_length=6000)
    comp_id: int | None = Field(default=None, ge=1)

    @model_validator(mode="after")
    def _validate(self) -> "PostUpdateIn":
        self.title = _require_nonempty(self.title, "제목", 100)
        self.body = _require_nonempty(self.body, "본문", 5000)
        _check_url_count(self.body)
        return self


class CommentIn(BaseModel):
    """POST /posts/{post_id}/comments — 댓글 작성(FR-127)."""

    body: str = Field(..., max_length=1200)

    @model_validator(mode="after")
    def _validate(self) -> "CommentIn":
        self.body = _require_nonempty(self.body, "댓글", 1000)
        _check_url_count(self.body)
        return self


class ReportIn(BaseModel):
    """POST /reports — 신고 접수(FR-130)."""

    target_type: str = Field(..., max_length=8)
    target_id: int = Field(..., ge=1)
    reason: str = Field(..., max_length=12)
    detail: str | None = Field(default=None, max_length=400)

    @model_validator(mode="after")
    def _validate(self) -> "ReportIn":
        if self.target_type not in REPORT_TARGET_TYPES:
            raise ValueError("신고 대상 유형이 올바르지 않습니다.")
        if self.reason not in REPORT_REASONS:
            raise ValueError("신고 사유가 올바르지 않습니다.")
        detail = clean_text(self.detail)
        if len(detail) > 300:
            raise ValueError("상세는 300자 이하여야 합니다.")
        self.detail = detail or None
        return self


# ── 응답 모델 — 작성자 식별은 **닉네임만**(이메일·MBR_ID 미노출, INV-8) ──────────────

class CompanyTag(BaseModel):
    """회사 태그 — 회사 페이지로 잇는 최소 정보. `slug` 는 생성기와 같은 규칙(FR-51)."""

    comp_id: int
    comp_nm: str
    slug: str


class PostListItem(BaseModel):
    post_id: int
    category: str
    title: str
    nickname: str
    verified_comp_nm: str | None = None  # 작성자의 활성 재직 인증 회사명(배지용). 없으면 null
    comp: CompanyTag | None = None
    like_cnt: int
    comment_cnt: int
    created_at: datetime
    edited: bool


class PostListOut(BaseModel):
    items: list[PostListItem]
    next_before: int | None = None  # 다음 페이지 커서(`?before=`). 더 없으면 null


class PostDetailOut(PostListItem):
    body: str
    updated_at: datetime | None = None
    is_mine: bool = False  # 세션 쿠키가 있을 때만 참일 수 있다(optional_member)
    liked: bool = False


class CommentItem(BaseModel):
    comment_id: int
    nickname: str
    verified_comp_nm: str | None = None
    body: str | None = None  # 삭제·숨김 댓글은 null(자리만)
    deleted: bool = False
    is_mine: bool = False
    created_at: datetime


class CommentListOut(BaseModel):
    items: list[CommentItem]
    next_after: int | None = None  # 다음 페이지 커서(`?after=`) — 댓글은 아래로 자란다
