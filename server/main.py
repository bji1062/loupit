"""SP-API-5 애플리케이션 조립 — FastAPI 앱·lifespan·라우터 등록·CORS.

인증·세션 미들웨어는 추가하지 않는다(INV-1). 전역 예외 핸들러(T-04.10.1)로
500 응답의 스택/SQL/내부경로 노출을 차단한다(SP-API-12).
"""
from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from server import database
from server.cache import TTLCache
from server.config import Settings, get_settings
from server.database import close_pool, init_pool
from server.routers import (
    benefit_edit,
    companies,
    employment,
    health,
    member,
    reference,
    trending,
)
from server.services import session as session_service

logger = logging.getLogger(__name__)


async def _purge_compare_log_safe(settings: Settings) -> None:
    """보존 퍼지 1회 — DB 장애가 앱을 죽이지 않도록 예외를 로깅 후 삼킨다(#7b).

    `database`를 모듈 참조로 호출한다(monkeypatch 테스트 가능성)."""
    try:
        deleted = await database.purge_compare_log(
            settings.compare_log_retention_days, settings.compare_log_purge_batch
        )
        if deleted:
            logger.info(
                "TCOMPARE_LOG 보존 퍼지: %d행 삭제(보존 %d일 초과분)",
                deleted, settings.compare_log_retention_days,
            )
    except Exception:  # DB 장애·권한 오류 등 — 앱 계속(다음 주기 재시도)
        logger.exception("TCOMPARE_LOG 보존 퍼지 실패 — 앱 계속")


async def _purge_sessions_safe() -> None:
    """만료·폐기 세션 + 만료·소비 코드 퍼지 1회 — DB 장애가 앱을 죽이지 않도록 삼킨다(SP-AUTH-4).

    참여 테이블(TSESSION·TAUTH_CODE)이 비어 있으면 무영향(no-op). `session_service` 를 모듈
    참조로 호출한다(monkeypatch 테스트 가능성)."""
    try:
        deleted = await session_service.purge_expired()
        if deleted:
            logger.info("세션 보존 퍼지: 만료·폐기 세션 %d행 삭제(만료 코드 동반 정리)", deleted)
    except Exception:  # DB 장애·참여 테이블 부재 등 — 앱 계속(다음 주기 재시도)
        logger.exception("세션 보존 퍼지 실패 — 앱 계속")


async def _retention_scheduler(settings: Settings) -> None:
    """일 1회 보존 퍼지 루프. lifespan 종료 시 task.cancel()로 취소된다(#7b·SP-AUTH-4)."""
    while True:
        await _purge_compare_log_safe(settings)
        await _purge_sessions_safe()
        await asyncio.sleep(settings.compare_log_purge_interval_seconds)


@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    await init_pool()
    app.state.reference_cache = TTLCache(s.reference_cache_ttl)
    app.state.trending_cache = TTLCache(s.trending_cache_ttl)  # 비교 트렌딩(60s)
    # #7b: TCOMPARE_LOG 보존 퍼지 백그라운드 스케줄러(일 1회). 실패는 안에서 삼켜
    # 앱을 죽이지 않는다. 종료 시 취소하고 CancelledError를 흡수한다.
    retention_task = asyncio.create_task(_retention_scheduler(s))
    try:
        yield
    finally:
        retention_task.cancel()
        with suppress(asyncio.CancelledError):
            await retention_task
        await close_pool()


def create_app() -> FastAPI:
    s = get_settings()
    app = FastAPI(title="loupit read-only API", version="1.0.0", lifespan=lifespan)

    # CORS: 허용목록만. 와일드카드+자격증명 금지. POST는 익명 비교 로그 1종에만
    # 사용된다(INV-1 개정 2026-07-14 — 그 외 쓰기 라우트 0은 TS-1이 고정, FR-96)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=s.cors_origin_list,
        allow_methods=["GET", "HEAD", "OPTIONS", "POST"],
        allow_headers=["*"],
        allow_credentials=False,
    )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        # 서버 로그에만 상세 기록(logging). 응답 본문은 일반 메시지만(스택/SQL/내부경로 미노출).
        logger.exception("unhandled exception on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=500,
            content={"detail": "일시적인 오류가 발생했습니다."},
            headers={"Cache-Control": "no-store"},
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        # 404(미존재 comp_id·미등록 경로)·405(Allow 헤더 보존) 공통 — no-store(SP-API-12).
        headers = dict(exc.headers or {})
        headers["Cache-Control"] = "no-store"
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail}, headers=headers)

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        # 422(q 검증·comp_id 검증·로그인 이메일/코드 검증) — no-store(SP-API-12).
        # 보안점검 2026-07-23: Pydantic v2 errors()의 `input`(및 ctx/url)은 제출 원본값을 담아
        # 로그인 이메일·코드 원문을 응답에 반향시킨다 → type·loc·msg 만 노출(NFR31).
        safe = [
            {"type": e.get("type"), "loc": e.get("loc"), "msg": e.get("msg")}
            for e in exc.errors()
        ]
        return JSONResponse(
            status_code=422,
            content={"detail": jsonable_encoder(safe)},
            headers={"Cache-Control": "no-store"},
        )

    p = s.api_prefix
    app.include_router(health.router, prefix=p)
    app.include_router(reference.router, prefix=p)
    app.include_router(companies.router, prefix=p)
    app.include_router(trending.router, prefix=p)
    # SC14 참여(로그인·재직·복지편집) 라우터 3종 등록(SP-AUTH-1). 미들웨어는 추가하지
    # 않는다 — 세션·재직 검증은 deps.require_member/require_employment(Depends)로만
    # 주입되어 app.user_middleware == ['CORSMiddleware'] 불변을 지킨다(AU-2, INV-9).
    app.include_router(member.router, prefix=p)
    app.include_router(employment.router, prefix=p)
    app.include_router(benefit_edit.router, prefix=p)
    return app


app = create_app()
