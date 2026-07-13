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
from server.services.reference import build_reference_bundle

router = APIRouter(tags=["reference"])
_CACHE_KEY = "reference_all"


@router.api_route("/reference/all", methods=["GET", "HEAD"], response_model=ReferenceBundle)
async def reference_all(request: Request) -> Response:
    cache = request.app.state.reference_cache
    body: bytes | None = cache.get(_CACHE_KEY)
    if body is None:  # 캐시 미스 → 조립
        async with get_pool().acquire() as conn:
            bundle = await build_reference_bundle(conn)
        # H-1: raw Response 반환이라 response_model(위 데코레이터)이 런타임 미적용 →
        # 여기서 ReferenceBundle로 조립 결과를 명시 검증한다. 계약 위반(필드 누락·타입
        # 불일치)은 예외로 전파돼 전역 핸들러가 500(no-store)으로 처리 — 잘못된 형태를
        # 200으로 조용히 내보내던 사각지대(과거 Decimal 500과 동형)를 닫는다.
        ReferenceBundle.model_validate(bundle)
        body = json.dumps(bundle, ensure_ascii=False).encode("utf-8")
        cache.set(_CACHE_KEY, body)
    return Response(
        content=body,
        # Starlette는 text/* 미디어타입에만 charset을 자동 부착한다 — application/json은
        # 명시하지 않으면 charset 누락(FR-92 TR-2 요구: "application/json; charset=utf-8").
        media_type="application/json; charset=utf-8",
        headers={"Cache-Control": get_settings().reference_cache_control},
    )
