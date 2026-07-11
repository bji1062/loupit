"""SP-API-5 애플리케이션 조립 — FastAPI 앱·lifespan·라우터 등록·CORS.

인증·세션 미들웨어는 추가하지 않는다(INV-1). 전역 예외 핸들러(T-04.10.1)로
500 응답의 스택/SQL/내부경로 노출을 차단한다(SP-API-12).
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from server.cache import TTLCache
from server.config import get_settings
from server.database import close_pool, init_pool
from server.routers import companies, health, reference

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    await init_pool()
    app.state.reference_cache = TTLCache(s.reference_cache_ttl)
    yield
    await close_pool()


def create_app() -> FastAPI:
    s = get_settings()
    app = FastAPI(title="loupit read-only API", version="1.0.0", lifespan=lifespan)

    # CORS: 허용목록만. 와일드카드+자격증명 금지. 쓰기 메서드 미포함(FR-96)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=s.cors_origin_list,
        allow_methods=["GET", "HEAD", "OPTIONS"],
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
        # 422(q 검증·comp_id 검증) — no-store(SP-API-12).
        return JSONResponse(
            status_code=422,
            content={"detail": jsonable_encoder(exc.errors())},
            headers={"Cache-Control": "no-store"},
        )

    p = s.api_prefix
    app.include_router(health.router, prefix=p)
    app.include_router(reference.router, prefix=p)
    app.include_router(companies.router, prefix=p)
    return app


app = create_app()
