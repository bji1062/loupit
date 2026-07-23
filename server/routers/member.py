"""SP-AUTH-5·6 회원 라우터 — 로그인 코드·로그인·me·로그아웃·탈퇴 (FR-102~104).

M9 표면 세그먼트(T-13.1.1): 앱 조립 표면(라우터 파일·`include_router` 등록)만 확보한다.
라우트 본체(무비밀번호 로그인·세션·계정 관리·탈퇴)는 T-13.6·T-13.7 이 채운다.

- 파일명 `auth` 금지(레거시 잔재 방지, T10) — 로그인 라우터는 본 `member.py` 를 쓴다.
- 세션 검증은 미들웨어가 아니라 `deps.require_member`(Depends)로만 주입한다(INV-9).
  본 라우터 등록이 `app.user_middleware == ['CORSMiddleware']` 불변을 깨지 않는다(AU-2).
"""
from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(tags=["member"])
