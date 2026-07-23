"""SP-AUTH-4·7 라우트 의존성 — 세션·재직 검증(미들웨어 아님, INV-9).

세션·재직 검증은 `app.add_middleware` 가 아니라 FastAPI `Depends` 로만 주입한다 —
`app.user_middleware == ['CORSMiddleware']` 불변(T2·T10, AU-2)을 지키기 위함이다.
익명 GET 라우터는 이 의존성을 쓰지 않는다(익명 표면 불변).
"""
from __future__ import annotations

from fastapi import Cookie, HTTPException

from server.services import session


async def require_member(loupit_sid: str | None = Cookie(default=None)) -> dict:
    """세션 쿠키(loupit_sid)를 검증해 회원 dict({'MBR_ID':...})를 반환, 없으면 401.

    쿠키 원문을 `resolve_session`(DB엔 해시만 조회)으로 검증한다 — 미들웨어가 아니라
    상태변경/계정 라우트가 `Depends(require_member)`로 개별 주입한다(FR-100·101, INV-9)."""
    member = await session.resolve_session(loupit_sid)
    if not member:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    return member


# require_employment(comp_id) 는 재직 인증(services/employment.active_verification) 의존이라
# 복지 편집(T-13.10)·재직(T-13.8) 착수 시 추가한다(현재 로그인/계정 경로는 미사용).
