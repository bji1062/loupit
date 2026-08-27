"""generator/bundle.py — 번들 단일 소스 소비 (SP-GEN-1.2).

런타임 API(`server/routers/reference.py`)와 **동일 함수**
`build_reference_bundle`을 호출한다(SP-API-7 단일 소스, 재정의 금지).
시그니처는 async이므로 빌드타임은 `asyncio.run`으로 구동한다. 테스트는
`load_bundle_json`으로 dict를 직접 주입한다(DB 무경유).

재무(SP-FIN-4, 2026-08-27)는 **번들 dict 밖**에서 `generator/finance.py::load_finance` 로
같은 커넥션에서 함께 읽는다 — 번들에 키를 더하면 런타임 API 응답·Pydantic 화이트리스트·
클라이언트 정규화가 같이 움직인다(함정 (55)). `--bundle-json` 의 짝은 `--finance-json`.
"""
from __future__ import annotations

import asyncio
import json

from generator.finance import load_finance
from server.config import get_settings
from server.services.reference import build_reference_bundle


async def _load_async(with_finance: bool = False):
    import aiomysql  # 지연 import — DB 미경유 테스트 경로에서 불필요한 의존 회피

    s = get_settings()
    conn = await aiomysql.connect(
        host=s.db_host,
        port=s.db_port,
        user=s.db_user,
        password=s.db_password,
        db=s.db_name,
        charset="utf8mb4",
        cursorclass=aiomysql.DictCursor,
    )
    try:
        bundle = await build_reference_bundle(conn)  # 최상위 3키(INV-2)
        if not with_finance:
            return bundle
        finance = await load_finance(conn)  # 같은 커넥션 — 번들과 같은 시점의 DB 를 본다
        return bundle, finance
    finally:
        conn.close()


def load_bundle() -> dict:
    """빌드타임 진입(DB 조회). 반환 = {company_types[], benefit_presets{}, companies[…]}."""
    return asyncio.run(_load_async())


def load_bundle_with_finance() -> tuple[dict, dict]:
    """번들 + 회사별 재무(`{comp_id: FinanceView}`) — build.py 의 DB 경로. 번들 dict 는 위와 동일하다."""
    return asyncio.run(_load_async(with_finance=True))


def load_bundle_json(path: str) -> dict:
    """사전 덤프된 번들 JSON 로드 — DB 없이 렌더(CI·오프라인·재현)."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_finance_json(path: str) -> dict[int, dict]:
    """사전 덤프된 재무 JSON 로드(`--finance-json`). JSON 은 키를 문자열로 떨어뜨리므로 int 로 되돌린다."""
    with open(path, encoding="utf-8") as f:
        return {int(k): v for k, v in json.load(f).items()}
