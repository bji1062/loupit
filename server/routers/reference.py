"""SP-API-9 GET /reference/all · /reference/index · /reference/companies/{id} — 부팅 단일 소스 + 인메모리 캐시(SP-API-4).

캐시 미스 시 DB 조립(build_reference_bundle) 1회 → 세 응답 바이트로 잘라 캐시 저장(services/reference_cut.py).
캐시 히트 시 저장된 바이트를 그대로 반환(요청당 재직렬화 비용 제거).
/all = 번들 전체(/find 용), /index + /companies/{id} = /compare 용(부팅은 가벼운 목록, 상세는 필요할 때 한 곳씩).
"""
from __future__ import annotations

import json

from fastapi import APIRouter, HTTPException, Path, Request, Response

from server.config import get_settings
from server.database import get_pool
from server.models.reference import Company, ReferenceBundle, ReferenceIndex  # OpenAPI 문서(응답 모델)
from server.services import benefit_codes
from server.services.reference import build_reference_bundle
from server.services.reference_cut import ReferenceCut, cut_bundle

router = APIRouter(tags=["reference"])
_CACHE_KEY = "reference_cut"  # 번들 한 번 조립 → /all · /index · /companies/{id} 세 가지를 함께 담는다


async def _build_reference_cut() -> ReferenceCut:
    """DB 조립 → 계약 검증 → 세 가지 응답 바이트. 캐시 미스(dogpile 락 하) 1회만 실행."""
    async with get_pool().acquire() as conn:
        bundle = await build_reference_bundle(conn)
    # H-1: raw Response 반환이라 response_model(라우트 데코레이터)이 런타임 미적용 →
    # `cut_bundle` 이 ReferenceBundle 로 조립 결과를 검증하고 **검증된 모델의 덤프**를 직렬화한다.
    # 검증만 하고 원시 dict를 직렬화하면(과거 방식, low#1) DB 컬럼 추가·타입 드리프트로
    # 생긴 계약 밖 필드가 검증을 통과한 채 그대로 새어 나갔다 — model_dump로 직렬화하면
    # 계약에 정의된 필드만 남아 비계약 형태가 캐시·CDN까지 전파되지 못한다. 계약 위반
    # (필드 누락·타입 불일치)은 model_validate가 예외로 전파 → 전역 핸들러 500(no-store).
    # (현행 스키마/시드 기준 model_dump 직렬화는 원시 dict 직렬화와 바이트 동일 — 라이브
    #  reference/all 606,531B 실측 확인. Decimal→float 정규화는 단일 소스 조립기가 이미 수행.)
    return cut_bundle(bundle)


async def _cut(request: Request) -> ReferenceCut:
    # 캐시 히트면 저장 바이트 즉시 반환, 미스면 asyncio.Lock 이중검사로 재조립 1회만
    # 수행한다(만료 경계 dogpile 억제, low#2). build 예외는 락 해제 후 전파 → 전역 500.
    return await request.app.state.reference_cache.get_or_set(_CACHE_KEY, _build_reference_cut)


def _json(body: bytes) -> Response:
    return Response(
        content=body,
        # Starlette는 text/* 미디어타입에만 charset을 자동 부착한다 — application/json은
        # 명시하지 않으면 charset 누락(FR-92 TR-2 요구: "application/json; charset=utf-8").
        media_type="application/json; charset=utf-8",
        headers={"Cache-Control": get_settings().reference_cache_control},
    )


@router.api_route("/reference/all", methods=["GET", "HEAD"], response_model=ReferenceBundle)
async def reference_all(request: Request) -> Response:
    """번들 전체 — /find(복지검색)가 쓴다. 비교 화면은 아래 두 길로 옮겼다(바이트는 예전과 같다)."""
    return _json((await _cut(request)).all_body)


@router.api_route("/reference/index", methods=["GET", "HEAD"], response_model=ReferenceIndex)
async def reference_index(request: Request) -> Response:
    """/compare 부팅용 가벼운 목록 — 회사 이름 · 별칭 · 업종 · 유형 · 복지 수 + 프리셋 + 눈금 통계(복지 행 없음)."""
    return _json((await _cut(request)).index_body)


@router.api_route("/reference/companies/{comp_id}", methods=["GET", "HEAD"], response_model=Company)
async def reference_company(request: Request, comp_id: int = Path(..., ge=1)) -> Response:  # 비정수·<1 → 422 (/companies/{id} 관례)
    """번들의 그 회사 객체 그대로(출처 계보 `edit_origin` 포함). `/companies/{id}` 는 계보를 파생하지 않아 쓰지 않는다."""
    body = (await _cut(request)).company_bodies.get(comp_id)
    if body is None:
        raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")
    return _json(body)


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
