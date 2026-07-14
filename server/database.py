"""SP-API-3 DB 접근 계층 — aiomysql 풀 + 원시 SQL(%s 바인딩).

읽기 헬퍼(fetch_all/fetch_one)를 제공하고, 범용 쓰기 헬퍼(execute/commit/
rollback)는 두지 않는다(INV-1·NFR20). 유일한 예외는 `insert_compare_log` —
INV-1 개정(2026-07-14, "실시간 비교 TOP 10")으로 허용된 익명 비교 로그 단일
INSERT다. 그 외 쓰기 경로를 추가하려면 INV-1 재개정이 선행돼야 한다.
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


_SQL_INSERT_COMPARE_LOG = "INSERT INTO TCOMPARE_LOG (A_COMP_ID, B_COMP_ID) VALUES (%s, %s)"


async def insert_compare_log(a_comp_id: int, b_comp_id: int) -> None:
    """익명 비교 로그 1행 INSERT — 본 모듈의 유일한 쓰기(모듈 docstring 참조).

    풀이 autocommit=True라 별도 커밋 불필요. 쌍 comp_id 외 어떤 값도 받지
    않는다(사용자 식별자·입력값 저장 금지 계약을 시그니처로 강제)."""
    async with get_pool().acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_INSERT_COMPARE_LOG, (a_comp_id, b_comp_id))


async def ping() -> bool:
    """DB 가용성 확인 — health 레디니스 확장(선택, DG-4 미채택으로 현재 미사용)용."""
    try:
        row = await fetch_one("SELECT 1 AS ok", ())
        return bool(row and row.get("ok") == 1)
    except Exception:
        return False
