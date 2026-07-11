"""generator/bundle.py — 번들 단일 소스 소비 (SP-GEN-1.2).

런타임 API(`server/routers/reference.py`)와 **동일 함수**
`build_reference_bundle`을 호출한다(SP-API-7 단일 소스, 재정의 금지).
시그니처는 async이므로 빌드타임은 `asyncio.run`으로 구동한다. 테스트는
`load_bundle_json`으로 dict를 직접 주입한다(DB 무경유).
"""
from __future__ import annotations

import asyncio
import json

from server.config import get_settings
from server.services.reference import build_reference_bundle


async def _load_async() -> dict:
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
        return await build_reference_bundle(conn)  # 최상위 3키(INV-2)
    finally:
        conn.close()


def load_bundle() -> dict:
    """빌드타임 진입(DB 조회). 반환 = {company_types[], benefit_presets{}, companies[…]}."""
    return asyncio.run(_load_async())


def load_bundle_json(path: str) -> dict:
    """사전 덤프된 번들 JSON 로드 — DB 없이 렌더(CI·오프라인·재현)."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)
