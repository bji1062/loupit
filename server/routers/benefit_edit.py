"""SP-AUTH-9·10 복지 편집 라우터 — 복지 등록·수정·편집 이력 공개 조회 (FR-108~110).

M9 표면 세그먼트(T-13.1.1): 앱 조립 표면(라우터 파일·`include_router` 등록)만 확보한다.
라우트 본체(배지 서버 강제·낙관적 동시성·본체+이력 원자 트랜잭션·익명 이력 조회)는
T-13.10·T-13.11 이 채운다. 사용자 대면 DELETE 라우트는 두지 않는다(복지 삭제는 CLI 전용,
FR-100·115). calc.js 는 무변경 — 표시 계층만 확장한다(INV-5).

- 편집 쓰기는 `deps.require_employment(comp_id)` + CSRF 로만 진입한다(INV-9).
"""
from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(tags=["benefit_edit"])
