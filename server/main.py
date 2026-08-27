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
    console,
    employment,
    health,
    mail_webhook,
    member,
    post,
    reference,
    report,
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


async def _purge_sessions_safe(m9_enabled: bool) -> None:
    """만료·폐기 세션 + 만료·소비 코드 퍼지 1회 — DB 장애가 앱을 죽이지 않도록 삼킨다(SP-AUTH-4).

    참여 테이블(TSESSION·TAUTH_CODE)이 비어 있으면 무영향(no-op). `session_service` 를 모듈
    참조로 호출한다(monkeypatch 테스트 가능성).

    M9 OFF 면 아예 호출하지 않는다 — OFF 스키마엔 두 테이블이 **없어서** 매 주기 예외가 잡히고
    journalctl 에 스택이 쌓인다. 삼켜지므로 무해하지만, 실제 DB 장애 신호를 상시 노이즈로 덮는
    쪽이 더 나쁘다(test_m9_gate M9G5·M9G6)."""
    if not m9_enabled:
        return
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
        await _purge_sessions_safe(settings.m9_enabled)
        await asyncio.sleep(settings.compare_log_purge_interval_seconds)


_VALID_MAILER_MODES = ("console", "smtp")


def validate_mail_config(settings: Settings) -> None:
    """메일 설정을 **기동 시점**에 검증한다 — 오설정은 배포에서 죽고, 요청에서 조용히 죽지 않는다.

    적대검토 2026-07-27이 잡은 수정 상호작용 결함: `send_code_safe`(발송 예외를 삼켜 균일 204 유지)
    가 `get_mailer()` 의 fail-closed RuntimeError 까지 삼켰다. 결과는 fail-closed 가 막으려던 바로
    그 상태 — 기동 성공·응답 204·**메일 0통**·로그 한 줄. 5개 렌즈 중 4개가 독립 수렴했다.

    **설정 오류와 일시적 발송 실패는 다른 종류다.** 전자는 배포 시점에 크게 실패해야 하고, 후자만
    삼켜야 한다. `get_settings()` 가 lru_cache 라 런타임 중 설정이 바뀔 수 없으므로, 기동 시 1회
    검증하면 이후 `get_mailer()` 는 사실상 던지지 않는다 — 삼킴은 그때부터 순수하게 '일시적 실패'만
    덮는다.

    M9 OFF 배포(현 프로덕션)는 메일을 아예 안 보내므로 검증 대상이 아니다."""
    if not settings.m9_enabled:
        return
    if settings.mailer_mode not in _VALID_MAILER_MODES:
        # 구 판본은 `== "smtp"` 만 봐서 `SMTP`·`stmp`·`smtp `(공백) 가 전부 else 로 떨어져
        # ConsoleMailer 가 됐다. 그건 **인증 코드와 수신 이메일을 평문으로 journald 에 적재**한다는
        # 뜻이다(NFR31 위반) — 운영에서 가장 조용하고 가장 나쁜 실패라 명시적으로 거부한다.
        raise RuntimeError(
            f"mailer_mode={settings.mailer_mode!r} 는 알 수 없는 값 — {_VALID_MAILER_MODES} 중 하나여야 "
            "한다. 오타는 조용히 ConsoleMailer 로 떨어져 인증 코드가 평문 로그에 남는다(NFR31)."
        )
    if settings.mailer_mode == "smtp":
        from server.mailer import resolve_sender

        # 전달받은 settings 를 그대로 검증한다 — get_mailer() 는 lru_cache 된 전역을 읽으므로
        # 인자를 무시하는 불일치가 생겼었다(테스트 MG-1 이 잡음). 규칙은 resolve_sender 가 소유.
        resolve_sender(settings)


@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    validate_mail_config(s)
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
    #
    # **M9 게이트(기본 OFF)**: 서빙 스키마에 참여 7테이블이 없는 배포에서 이 라우트가 켜지면
    # 쓰기 표면이 500 을 뿜으며 노출된다. 우발적 재시작이 기능을 켜지 못하게 설정으로 막는다
    # (config.m9_enabled 주석·test_m9_gate). OFF 표면 = SC14 이전 익명 계약과 정확히 동일.
    # 임포트는 무조건 유지한다 — 등록만 조건부라서 라우터 모듈 자체의 임포트 오류는 OFF
    # 배포에서도 즉시 드러난다(조용한 부패 방지).
    if s.m9_enabled:
        app.include_router(member.router, prefix=p)
        app.include_router(employment.router, prefix=p)
        app.include_router(benefit_edit.router, prefix=p)
        # SC15 커뮤니티(SP-COMM-1, 2026-08-27) — 같은 게이트 안. 4테이블(SP-DB-18)의 FK 가 TMEMBER 라
        # OFF 스키마엔 테이블도 없다: 표면과 스키마가 설정 하나로 함께 움직인다(test_m9_gate CM-8).
        app.include_router(post.router, prefix=p)
        app.include_router(report.router, prefix=p)

    # 메일 배달 웹훅(SP-AUTH-16) — **M9 게이트 밖**이고 시크릿이 있을 때만 등록한다.
    #
    # M9 밖인 이유: 수신 호스트는 prod(M9 OFF)다. 지금 실발송하는 것은 beta 지만 발신 도메인·
    # 무료 티어를 공유하므로 억제 목록은 한 곳에 모여야 하고, prod 는 항상 떠 있다.
    #
    # 시크릿 조건인 이유(fail-closed): 이 엔드포인트는 바운스를 받으면 그 주소의 발송을 막는다.
    # 검증 불가 상태로 열려 있으면 위조 이벤트 하나로 **임의 주소의 로그인을 영구 차단**할 수
    # 있다(표적 잠금). 부수 효과로, 시크릿을 넣기 전까지 익명 표면(INV-1)은 그대로다 —
    # 표면 변화가 **명시적 설정**에만 따라오게 만든 것이다(test_m9_gate M9G2 와 정합).
    if s.resend_webhook_secret:
        app.include_router(mail_webhook.router, prefix=p)

    # SSH 터널 전용 운영 콘솔(SP-AUTH-19) — **M9 + 화이트리스트 둘 다** 있어야 등록한다.
    #
    # M9 조건: 콘솔이 다루는 큐 2종(재직 수동 승인·회사 등록 요청)이 참여 테이블이다.
    # 화이트리스트 조건(fail-closed): `OPERATOR_EMAILS` 가 비면 아무도 통과하지 못하므로
    #   라우터가 있어 봐야 404 만 낸다. 그럴 바엔 **표면에 아예 없는 것**이 낫다 — 웹훅
    #   시크릿과 같은 규약으로, 표면 변화가 명시적 설정에만 따라오게 한다(INV-1).
    #
    # ⚠ 노출 범위는 이 조건이 아니라 `deps.require_loopback` 가 지킨다. 설정을 켠 것과
    #   인터넷에 연 것은 다른 사건이고, 후자는 nginx 를 거친 요청을 404 로 끊어 막는다.
    if s.m9_enabled and s.operator_emails.strip():
        app.include_router(console.router, prefix=p)
    return app


app = create_app()
