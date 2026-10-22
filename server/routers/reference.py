"""SP-API-9 GET /reference/all — 부팅 단일 소스 + 인메모리 캐시(SP-API-4).

캐시 미스 시 DB 조립(build_reference_bundle) → JSON 직렬화 → 캐시 저장.
캐시 히트 시 저장된 바이트를 그대로 반환(요청당 재직렬화 비용 제거).
"""
from __future__ import annotations

import json

from fastapi import APIRouter, Request, Response

from server.config import get_settings
from server.database import get_pool
from server.models.reference import ReferenceBundle  # OpenAPI 문서 + 런타임 계약 검증(H-1)
from server.services import benefit_codes
from server.services.reference import build_reference_bundle

router = APIRouter(tags=["reference"])
_CACHE_KEY = "reference_all"


async def _build_reference_body() -> bytes:
    """DB 조립 → 계약 검증 → JSON 바이트. 캐시 미스(dogpile 락 하) 1회만 실행."""
    async with get_pool().acquire() as conn:
        bundle = await build_reference_bundle(conn)
    # H-1: raw Response 반환이라 response_model(라우트 데코레이터)이 런타임 미적용 →
    # 여기서 ReferenceBundle로 조립 결과를 검증하고 **검증된 모델의 덤프**를 직렬화한다.
    # 검증만 하고 원시 dict를 직렬화하면(과거 방식, low#1) DB 컬럼 추가·타입 드리프트로
    # 생긴 계약 밖 필드가 검증을 통과한 채 그대로 새어 나갔다 — model_dump로 직렬화하면
    # 계약에 정의된 필드만 남아 비계약 형태가 캐시·CDN까지 전파되지 못한다. 계약 위반
    # (필드 누락·타입 불일치)은 model_validate가 예외로 전파 → 전역 핸들러 500(no-store).
    # (현행 스키마/시드 기준 model_dump 직렬화는 원시 dict 직렬화와 바이트 동일 — 라이브
    #  reference/all 606,531B 실측 확인. Decimal→float 정규화는 단일 소스 조립기가 이미 수행.)
    validated = ReferenceBundle.model_validate(bundle)
    return json.dumps(validated.model_dump(), ensure_ascii=False).encode("utf-8")


@router.api_route("/reference/all", methods=["GET", "HEAD"], response_model=ReferenceBundle)
async def reference_all(request: Request) -> Response:
    cache = request.app.state.reference_cache
    # 캐시 히트면 저장 바이트 즉시 반환, 미스면 asyncio.Lock 이중검사로 재조립 1회만
    # 수행한다(만료 경계 dogpile 억제, low#2). build 예외는 락 해제 후 전파 → 전역 500.
    body: bytes = await cache.get_or_set(_CACHE_KEY, _build_reference_body)
    return Response(
        content=body,
        # Starlette는 text/* 미디어타입에만 charset을 자동 부착한다 — application/json은
        # 명시하지 않으면 charset 누락(FR-92 TR-2 요구: "application/json; charset=utf-8").
        media_type="application/json; charset=utf-8",
        headers={"Cache-Control": get_settings().reference_cache_control},
    )


#: 코드 목록은 참조 번들에서 파생되고 하루에 한두 번 바뀔까 하는 값이다 — 짧게 공개 캐시한다(프록시 5분).
_CODES_CACHE_CONTROL = "public, max-age=300"


@router.get("/benefit-codes")
async def benefit_codes_list(request: Request) -> Response:
    """표준 복지 코드 목록 `[{code, label, ctgr, aliases}]` — 세션 불필요(2026-10-21).

    회원 편집 화면의 「어떤 복지인가요?」 검색 고르기가 쓴다. 이름을 부르는 규칙은 /find 와 같은
    `generator/benefit_codes.py` 하나다. 인메모리 캐시는 참조 번들 캐시와 함께 비워진다."""
    codes = await benefit_codes.get_codes(getattr(request.app.state, "reference_cache", None))
    return Response(
        content=json.dumps({"codes": codes}, ensure_ascii=False).encode("utf-8"),
        media_type="application/json; charset=utf-8",
        headers={"Cache-Control": _CODES_CACHE_CONTROL},
    )
