"""T-04.2.2 database.py aiomysql 풀·읽기 헬퍼 유닛 테스트 (SP-API-3).

무 DB — aiomysql 풀/커넥션/커서를 흉내낸 fake 객체를 주입해 %s 바인딩과
DictCursor 스타일 dict 반환만 검증한다. 쓰기 헬퍼(execute/commit/rollback)
심볼 부재를 구조적으로 강제한다(INV-1·NFR20).
"""
from __future__ import annotations

import pytest


class _FakeCursor:
    def __init__(self, rows):
        self._rows = rows
        self.calls = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def execute(self, sql, params=()):
        self.calls.append((sql, params))

    async def fetchall(self):
        return self._rows

    async def fetchone(self):
        return self._rows[0] if self._rows else None


class _FakeConn:
    def __init__(self, rows):
        self._rows = rows
        self.cursor_obj = _FakeCursor(rows)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    def cursor(self):
        return self.cursor_obj


class _FakePool:
    def __init__(self, rows):
        self.conn = _FakeConn(rows)

    def acquire(self):
        return self.conn


@pytest.mark.asyncio
async def test_fetch_all_binds_params_and_returns_dict_rows(monkeypatch):
    from server import database

    rows = [{"a": 1}, {"a": 2}]
    pool = _FakePool(rows)
    monkeypatch.setattr(database, "_pool", pool)

    result = await database.fetch_all("SELECT * FROM t WHERE x = %s", ("v",))
    assert result == rows
    assert pool.conn.cursor_obj.calls == [("SELECT * FROM t WHERE x = %s", ("v",))]


@pytest.mark.asyncio
async def test_fetch_one_binds_params_and_returns_single_dict(monkeypatch):
    from server import database

    rows = [{"a": 1}]
    pool = _FakePool(rows)
    monkeypatch.setattr(database, "_pool", pool)

    result = await database.fetch_one("SELECT * FROM t WHERE id = %s", (1,))
    assert result == {"a": 1}
    assert pool.conn.cursor_obj.calls == [("SELECT * FROM t WHERE id = %s", (1,))]


@pytest.mark.asyncio
async def test_fetch_one_returns_none_when_no_rows(monkeypatch):
    from server import database

    pool = _FakePool([])
    monkeypatch.setattr(database, "_pool", pool)

    result = await database.fetch_one("SELECT * FROM t WHERE id = %s", (999,))
    assert result is None


def test_write_helpers_are_absent():
    """범용 쓰기 헬퍼(execute/commit/rollback 등) 미제공 — INV-1·NFR20.

    허용 쓰기는 정확히 2종, 둘 다 익명 비교 로그(TCOMPARE_LOG) 전용:
      - `insert_compare_log` (단일 INSERT, INV-1 개정 2026-07-14)
      - `purge_compare_log`  (보존 퍼지 DELETE, #7b)
    그 외 쓰기 심볼(다른 테이블·다른 DML)이 생기면 본 게이트가 깨진다."""
    from server import database

    for forbidden in ("execute", "commit", "rollback", "insert", "update", "delete"):
        assert not hasattr(database, forbidden), f"쓰기 헬퍼 발견 금지: {forbidden}"

    # 쓰기 의미 키워드에 'purge'를 포함해 보존 퍼지류 DELETE도 게이트가 잡게 한다
    # (이전 목록은 purge를 놓쳐 사각지대였음 — 새 쓰기가 이름만 바꿔 빠져나가지 못하게).
    write_symbols = [
        name for name in dir(database)
        if not name.startswith("_") and callable(getattr(database, name))
        and any(kw in name.lower() for kw in ("insert", "update", "delete", "execute", "commit", "purge"))
    ]
    # dir()은 정렬 반환 → insert_compare_log < purge_compare_log.
    assert write_symbols == ["insert_compare_log", "purge_compare_log"], (
        f"허용된 쓰기 심볼은 insert_compare_log·purge_compare_log 2종뿐: {write_symbols}"
    )


@pytest.mark.asyncio
async def test_insert_compare_log_binds_pair(monkeypatch):
    """insert_compare_log — INSERT SQL + (a,b) %s 바인딩 (유일 허용 쓰기)."""
    from server import database

    pool = _FakePool([])
    monkeypatch.setattr(database, "_pool", pool)
    await database.insert_compare_log(1, 2)
    sql, params = pool.conn.cursor_obj.calls[-1]
    assert "INSERT INTO TCOMPARE_LOG" in sql
    assert "(A_COMP_ID, B_COMP_ID)" in sql
    assert params == (1, 2)


@pytest.mark.asyncio
async def test_ping_true_when_select_1_ok(monkeypatch):
    from server import database

    async def _fake_fetch_one(sql, params=()):
        return {"ok": 1}

    monkeypatch.setattr(database, "fetch_one", _fake_fetch_one)
    assert await database.ping() is True


@pytest.mark.asyncio
async def test_ping_false_on_exception(monkeypatch):
    from server import database

    async def _boom(sql, params=()):
        raise RuntimeError("db down")

    monkeypatch.setattr(database, "fetch_one", _boom)
    assert await database.ping() is False


def test_get_pool_asserts_when_uninitialized(monkeypatch):
    from server import database

    monkeypatch.setattr(database, "_pool", None)
    with pytest.raises(AssertionError):
        database.get_pool()


def test_get_pool_returns_initialized_pool(monkeypatch):
    from server import database

    sentinel = object()
    monkeypatch.setattr(database, "_pool", sentinel)
    assert database.get_pool() is sentinel
