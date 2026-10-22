"""표준 복지 코드 목록(94종) — 회원 편집 화면의 검색 고르기와 운영자 승인 큐의 고르기가 함께 쓴다 (2026-10-21).

이름을 부르는 규칙(대표 이름 = 빈도 → 길이 → 코드포인트, 같은 이름은 갈라 줌, 손으로 박은 `LABEL_OVERRIDE`)은
`generator/benefit_codes.py` 하나다 — /find 표·복지 항목 페이지·`find.js` 칩과 **같은 규칙**이어야 사람이 같은
항목을 같은 이름으로 만난다. 여기서 규칙을 다시 쓰지 않고 참조 번들 조립(`reference.build_reference_bundle`)이
만드는 회사·복지 dict 를 그 함수에 그대로 넣는다. `generator` 패키지는 API 가 저장소 루트를 작업 디렉터리로
기동하므로(`infra/systemd/loupit-api.service` WorkingDirectory) import 된다.

결과는 참조 번들 캐시(`app.state.reference_cache`)에 같은 키 규약으로 얹는다 — 편집이 반영돼 그 캐시를 비우면
이 목록도 함께 비워진다(승인 때 콘솔 라우터가 비운다).
"""
from __future__ import annotations

from server.database import get_pool
from server.services.reference import build_reference_bundle

from generator.benefit_codes import derive_codes

CACHE_KEY = "benefit_codes"

# 화면 순서 = 카테고리 9개(edit.js CATEGORY_ORDER 와 같다). 이 밖의 카테고리가 오면 맨 뒤.
CATEGORY_ORDER = (
    "compensation", "flexibility", "work_env", "time_off",
    "health", "family", "growth", "leisure", "perks",
)
ALIAS_MAX = 12  # 검색어로 쓸 다른 이름 — 한 코드가 수십 개 이름을 가져도 응답이 부풀지 않게 자른다


def build_code_list(companies: list[dict]) -> list[dict]:
    """회사·복지 dict(번들 모양) → `[{code, label, ctgr, aliases}]` — 카테고리 순, 같은 카테고리는 이름순.

    `aliases` 는 대표 이름이 아닌 다른 이름만(검색어용, 많이 쓰인 순 `ALIAS_MAX` 개까지)이다."""
    codes = derive_codes(companies)
    rank = {c: i for i, c in enumerate(CATEGORY_ORDER)}
    out = [
        {
            "code": info["code"],
            "label": info["label"],
            "ctgr": info["ctgr"],
            "aliases": [a for a in info["aliases"] if a and a != info["label"]][:ALIAS_MAX],
        }
        for info in codes.values()
    ]
    out.sort(key=lambda i: (rank.get(i["ctgr"], len(rank)), i["label"], i["code"]))
    return out


async def _build() -> list[dict]:
    async with get_pool().acquire() as conn:
        bundle = await build_reference_bundle(conn)
    return build_code_list(bundle["companies"])


async def get_codes(cache) -> list[dict]:
    """캐시 히트면 그대로, 미스면 번들 조립 1회. `cache` 는 `app.state.reference_cache`(TTLCache).

    캐시가 없으면(lifespan 없이 앱을 직접 두드리는 테스트 등) 캐시 없이 매번 조립한다."""
    if cache is None:
        return await _build()
    return await cache.get_or_set(CACHE_KEY, _build)


async def get_code_map(cache) -> dict[str, dict]:
    """`{code: 항목}` — 코드 안인지 판정하고 카테고리를 코드에서 정할 때 쓴다."""
    return {c["code"]: c for c in await get_codes(cache)}
