"""SP-API-3 DB 접근 계층 — aiomysql 풀 + 원시 SQL(%s 바인딩).

읽기 헬퍼(fetch_all/fetch_one)만 제공한다. execute/commit/rollback 등 쓰기
헬퍼는 두지 않는다(INV-1·NFR20) — 본 서버는 SELECT 전용.
"""
from __future__ import annotations

import aiomysql

from server.config import get_settings

_pool: aiomysql.Pool | None = None


async def init_pool() -> aiomysql.Pool:
    global _pool
    s = get_settings()
    _pool = await aiomysql.create_pool(
        host=s.db_host,
        port=s.db_port,
        user=s.db_user,
        password=s.db_password,
        db=s.db_name,
        minsize=s.db_pool_min,
        maxsize=s.db_pool_max,
        connect_timeout=s.db_connect_timeout,
        charset="utf8mb4",
        autocommit=True,  # 읽기 전용 → 명시 트랜잭션 불필요
        cursorclass=aiomysql.DictCursor,
    )
    return _pool


async def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        await _pool.wait_closed()
        _pool = None


def get_pool() -> aiomysql.Pool:
    assert _pool is not None, "pool not initialized (lifespan 미기동)"
    return _pool


async def fetch_all(sql: str, params: tuple = ()) -> list[dict]:
    async with get_pool().acquire() as conn:
        async with conn.cursor() as cur:  # DictCursor
            await cur.execute(sql, params)  # %s 바인딩
            return await cur.fetchall()


async def fetch_one(sql: str, params: tuple = ()) -> dict | None:
    async with get_pool().acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(sql, params)
            return await cur.fetchone()


async def ping() -> bool:
    """DB 가용성 확인 — health 레디니스 확장(선택, DG-4 미채택으로 현재 미사용)용."""
    try:
        row = await fetch_one("SELECT 1 AS ok", ())
        return bool(row and row.get("ok") == 1)
    except Exception:
        return False
