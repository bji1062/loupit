"""SP-AUTH-7·8 재직 인증 라우터 — 재직 코드·재직 인증·수동 승인 요청 (FR-105~107).

M9 표면 세그먼트(T-13.1.1): 앱 조립 표면(라우터 파일·`include_router` 등록)만 확보한다.
라우트 본체(회사 도메인 매칭·코드 발송·HMAC 인증·수동 승인 큐)는 T-13.8·T-13.9 가
채운다(DG-5 회사 도메인 화이트리스트 확정 후 착수).

- 재직 검증은 미들웨어가 아니라 `deps.require_member`/`require_employment`(Depends)로만
  주입한다(INV-9) — 본 라우터 등록이 미들웨어 표면을 바꾸지 않는다(AU-2).
"""
from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(tags=["employment"])
