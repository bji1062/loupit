"""SP-API-3 + SP-AUTH-4 DB 접근 계층 — aiomysql 풀 + 원시 SQL(%s 바인딩).

읽기 헬퍼(fetch_all/fetch_one)를 제공한다. 쓰기 진입점은 두 부류로 엄격히 열거된다:

**익명 표면(INV-1)** — 정확히 2종, 둘 다 익명 비교 로그(TCOMPARE_LOG) 전용:
  - `insert_compare_log` — INV-1 개정(2026-07-14, "실시간 비교 TOP 10")으로
    허용된 익명 비교 로그 단일 INSERT.
  - `purge_compare_log` — #7b 보존 퍼지. 무인증 POST가 무한 축적시키는 로그를
    보존기간 경과분 DELETE로 상한한다(트렌딩 소비 윈도우 밖 행만 삭제).

**참여(SC14) 기여 쓰기(INV-1 열거, SP-AUTH-4)** — 세션·재직 인증(Depends)을 통과한
기여 라우트 전용 범용 쓰기 진입점:
  - `execute` — 참여 쓰기 1문(INSERT/UPDATE/DELETE) 실행.
  - `transaction` — 본체+이력 다문 원자 트랜잭션 컨텍스트 매니저.

익명 표면에 새 쓰기 경로(다른 테이블·다른 DML)를 추가하려면 INV-1 재개정이 선행돼야
한다. write_symbols 회귀 게이트(test_database, AU-7)가 허용집합을 고정한다.
"""
from __future__ import annotations

from contextlib import asynccontextmanager

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


# INTERVAL·LIMIT은 %s 바인딩(원시 SQL 규약, SP-API-3). SQL 텍스트에 값 삽입 금지.
_SQL_PURGE_COMPARE_LOG = (
    "DELETE FROM TCOMPARE_LOG WHERE INS_DTM < NOW() - INTERVAL %s DAY LIMIT %s"
)


async def purge_compare_log(retention_days: int, batch_limit: int) -> int:
    """보존기간 경과 익명 비교 로그를 배치 삭제한다 — 모듈의 두 번째 허용 쓰기(#7b).

    무인증 POST /comparisons/log가 무한 축적시키는 TCOMPARE_LOG를 상한한다. 소비
    쿼리(trending.py)는 최근 trending_window_days(7일)만 읽으므로 retention_days
    (기본 30일)를 넘긴 행은 어떤 응답에도 쓰이지 않아 삭제해도 무영향이다.

    `LIMIT %s` 배치 루프로 1회 삭제 행 수를 제한해 장기 테이블 락을 피한다
    (풀 autocommit=True → 배치마다 즉시 커밋). 삭제 대상이 batch_limit 미만이
    되면(더 지울 행 없음) 종료한다. WHERE의 cutoff가 매 배치 대상 집합을 줄이므로
    반드시 종료한다. 반환값은 총 삭제 행 수(운영 로깅용)."""
    total = 0
    async with get_pool().acquire() as conn:
        async with conn.cursor() as cur:
            while True:
                await cur.execute(_SQL_PURGE_COMPARE_LOG, (retention_days, batch_limit))
                deleted = cur.rowcount or 0  # None → 0(안전). 음수/미상도 아래 < 비교로 종료.
                total += deleted
                if deleted < batch_limit:  # 마지막 배치(더 지울 행 없음) → 종료. 무한루프 불가.
                    break
    return total


# ── SC14 참여(기여) 쓰기 진입점 (SP-AUTH-4) ──────────────────────────────────────
# 익명 경로가 아니라 세션·재직 인증(deps.require_member / require_employment)을 통과한
# 기여 라우트 전용 쓰기다(INV-1 "열거된 SC14 기여 쓰기", NFR20). 익명 표면의 허용 쓰기는
# 위 insert_compare_log·purge_compare_log 2종뿐으로 유지되며, 아래 두 진입점은 기여(SC14)
# 서비스 계층(session·employment·benefit_edit)에서만 호출된다. write_symbols 회귀 게이트
# (test_database, AU-7)가 허용집합 = {execute, insert_compare_log, purge_compare_log} 를 고정한다
# (transaction 은 쓰기 키워드 미포함이라 필터엔 안 잡히나 심볼 존재는 게이트가 확인한다).


async def execute(sql: str, params: tuple = ()) -> int:
    """참여 쓰기 1문(INSERT/UPDATE/DELETE)을 실행하고 영향 행 수를 반환한다(SP-AUTH-4).

    풀이 autocommit=True 라 단문은 즉시 커밋된다. 본체+이력처럼 다문 원자성이 필요하면
    transaction() 으로 묶는다. 값은 SQL 텍스트에 삽입하지 않고 %s 로만 바인딩한다
    (원시 SQL 규약, SP-API-3)."""
    async with get_pool().acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(sql, params)
            return cur.rowcount or 0


@asynccontextmanager
async def transaction():
    """참여 원자 쓰기 트랜잭션 — 복지 본체 + TBENEFIT_EDIT_LOG 등 다문 원자성용(SP-AUTH-4·9).

    풀이 autocommit=True 라도 conn.begin() 으로 명시 트랜잭션을 열고, with 블록 정상 종료 시
    commit·예외 발생 시 rollback 한다. 획득한 커넥션을 yield 하여 호출측이 여러 쓰기를 한
    트랜잭션으로 묶게 한다(T-13.10.1 낙관적 동시성 편집). 종료 시 커넥션은 풀에 반환된다."""
    async with get_pool().acquire() as conn:
        await conn.begin()
        try:
            yield conn
            await conn.commit()
        except Exception:
            await conn.rollback()
            raise


async def ping() -> bool:
    """DB 가용성 확인 — health 레디니스 확장(선택, DG-4 미채택으로 현재 미사용)용."""
    try:
        row = await fetch_one("SELECT 1 AS ok", ())
        return bool(row and row.get("ok") == 1)
    except Exception:
        return False
