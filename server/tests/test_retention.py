"""#7b TCOMPARE_LOG 보존 퍼지 유닛 테스트 — 배치 DELETE 루프 + 스케줄러 예외 격리.

무 DB. aiomysql 풀/커서를 흉내낸 fake로 batch LIMIT 루프의 종료 조건과 SQL/파라미터
바인딩을 검증하고, 스케줄러 1회 실행이 DB 예외를 삼켜 앱을 죽이지 않음을 확인한다
(POST /comparisons/log 무한 축적 상한 — 무인증 익명 로그 남용 방어).
"""
from __future__ import annotations

import pytest


class _BatchCursor:
    """execute마다 미리 지정한 rowcount 시퀀스를 소비하는 fake DictCursor."""

    def __init__(self, rowcounts):
        self._rowcounts = list(rowcounts)
        self.calls: list[tuple] = []
        self.rowcount = 0

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def execute(self, sql, params=()):
        self.calls.append((sql, params))
        self.rowcount = self._rowcounts.pop(0) if self._rowcounts else 0


class _BatchConn:
    def __init__(self, cursor):
        self._cursor = cursor

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    def cursor(self):
        return self._cursor


class _BatchPool:
    def __init__(self, cursor):
        self._conn = _BatchConn(cursor)

    def acquire(self):
        return self._conn


# ── database.purge_compare_log — 배치 DELETE 루프 ────────────────────────────


@pytest.mark.asyncio
async def test_purge_loops_until_batch_underfilled(monkeypatch):
    """rowcount [5000,5000,120], batch=5000 → 3회 execute 후 종료, 총 10120 삭제.
    마지막 배치(120 < 5000)에서 멈춘다(더 지울 행 없음)."""
    from server import database

    cur = _BatchCursor([5000, 5000, 120])
    monkeypatch.setattr(database, "_pool", _BatchPool(cur))

    total = await database.purge_compare_log(30, 5000)
    assert total == 10120
    assert len(cur.calls) == 3
    sql, params = cur.calls[0]
    assert "DELETE FROM TCOMPARE_LOG" in sql
    assert "INS_DTM <" in sql and "LIMIT %s" in sql
    assert params == (30, 5000)  # (retention_days, batch_limit) %s 바인딩 순서


@pytest.mark.asyncio
async def test_purge_single_batch_when_nothing_to_delete(monkeypatch):
    """삭제 대상 0건 → 1회 execute(0 < batch) 후 즉시 종료, 총 0."""
    from server import database

    cur = _BatchCursor([0])
    monkeypatch.setattr(database, "_pool", _BatchPool(cur))
    total = await database.purge_compare_log(30, 5000)
    assert total == 0
    assert len(cur.calls) == 1


@pytest.mark.asyncio
async def test_purge_terminates_on_unknown_rowcount(monkeypatch):
    """드라이버가 rowcount=-1(미상) 반환 시에도 무한루프 없이 1회 후 종료(-1 < batch)."""
    from server import database

    cur = _BatchCursor([-1])
    monkeypatch.setattr(database, "_pool", _BatchPool(cur))
    total = await database.purge_compare_log(30, 5000)
    assert len(cur.calls) == 1  # 종료 보장(핵심)
    assert total == -1  # 로깅 표기값 — 종료 자체가 계약


# ── main._purge_compare_log_safe — 스케줄러 1회 실행의 예외 격리 ──────────────


@pytest.mark.asyncio
async def test_purge_safe_runs_purge_with_settings(monkeypatch):
    """정상 경로: 설정값(retention_days·batch)을 그대로 purge_compare_log에 넘긴다."""
    from server import database, main as main_mod
    from server.config import get_settings

    seen: dict = {}

    async def _ok(retention_days, batch_limit):
        seen["args"] = (retention_days, batch_limit)
        return 42

    monkeypatch.setattr(database, "purge_compare_log", _ok)
    s = get_settings()
    await main_mod._purge_compare_log_safe(s)
    assert seen["args"] == (s.compare_log_retention_days, s.compare_log_purge_batch)


@pytest.mark.asyncio
async def test_purge_safe_swallows_db_exception(monkeypatch):
    """DB 장애 시 예외를 삼켜 앱(lifespan)을 죽이지 않는다 — 전파되면 이 await가 raise."""
    from server import database, main as main_mod
    from server.config import get_settings

    async def _boom(retention_days, batch_limit):
        raise RuntimeError("db down — 이 예외는 스케줄러가 흡수해야 함")

    monkeypatch.setattr(database, "purge_compare_log", _boom)
    # 예외 미전파 = 정상 리턴(None). 전파되면 pytest가 에러로 잡는다.
    assert await main_mod._purge_compare_log_safe(get_settings()) is None
