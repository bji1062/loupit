"""T-04.2.2 database.py aiomysql 풀·읽기 헬퍼 유닛 테스트 (SP-API-3).

무 DB — aiomysql 풀/커넥션/커서를 흉내낸 fake 객체를 주입해 %s 바인딩과
DictCursor 스타일 dict 반환만 검증한다. 쓰기 헬퍼(execute/commit/rollback)
심볼 부재를 구조적으로 강제한다(INV-1·NFR20).
"""
from __future__ import annotations

import pytest


class _FakeCursor:
    def __init__(self, rows, rowcount=0):
        self._rows = rows
        self.rowcount = rowcount  # execute() 반환값(영향 행 수) 검증용
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
    def __init__(self, rows, rowcount=0):
        self._rows = rows
        self.cursor_obj = _FakeCursor(rows, rowcount)
        self.tx_calls = []  # begin/commit/rollback 호출 순서 기록(transaction 테스트용)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    def cursor(self):
        return self.cursor_obj

    async def begin(self):
        self.tx_calls.append("begin")

    async def commit(self):
        self.tx_calls.append("commit")

    async def rollback(self):
        self.tx_calls.append("rollback")


class _FakePool:
    def __init__(self, rows, rowcount=0):
        self.conn = _FakeConn(rows, rowcount)

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


def test_write_symbols_participation_surface():
    """AU-7(SC14 재명세): 쓰기 심볼 정확 집합 = 익명 로그 2종 + 참여 진입점 `execute` — INV-1·NFR20.

    익명 표면(INV-1)의 허용 쓰기는 여전히 둘 다 TCOMPARE_LOG 전용 2종뿐이고:
      - `insert_compare_log` (단일 INSERT, INV-1 개정 2026-07-14)
      - `purge_compare_log`  (보존 퍼지 DELETE, #7b)
    SC14 로 참여 기여 쓰기 진입점 2종이 추가됐다(SP-AUTH-4, 세션·재직 인증 통과 라우트 전용):
      - `execute`     (범용 쓰기 1문)
      - `transaction` (본체+이력 원자 CM — 쓰기 키워드 미포함이라 write_symbols 필터엔 안 잡힘)

    §C item4 — M9 표면 세그먼트에서 구 무쓰기 게이트를 이 집합으로 갱신·통합했다(구
    @pytest.mark.sc14 test_AU7 를 본 베이스 게이트로 흡수). execute 외의 범용 쓰기 모듈 심볼
    (commit/rollback/insert/update/delete)은 여전히 부재해야 한다."""
    from server import database

    # 참여 쓰기 진입점은 존재해야 한다(SP-AUTH-4).
    assert hasattr(database, "execute"), "참여 쓰기 진입점 execute 부재(SP-AUTH-4)"
    assert hasattr(database, "transaction"), "참여 원자 트랜잭션 transaction 부재(SP-AUTH-4)"

    # execute 외의 범용 쓰기 헬퍼(모듈 심볼)는 여전히 부재해야 한다 —
    # commit/rollback 은 transaction 내부에서 conn 메서드로만 호출되고 모듈 심볼로 노출되지 않는다.
    for forbidden in ("commit", "rollback", "insert", "update", "delete"):
        assert not hasattr(database, forbidden), f"범용 쓰기 모듈 심볼 발견 금지: {forbidden}"

    # 쓰기 의미 키워드에 'purge'를 포함해 보존 퍼지류 DELETE도 게이트가 잡게 한다
    # (이전 목록은 purge를 놓쳐 사각지대였음 — 새 쓰기가 이름만 바꿔 빠져나가지 못하게).
    write_symbols = [
        name for name in dir(database)
        if not name.startswith("_") and callable(getattr(database, name))
        and any(kw in name.lower() for kw in ("insert", "update", "delete", "execute", "commit", "purge"))
    ]
    # dir()은 정렬 반환 → execute < insert_compare_log < purge_compare_log.
    assert write_symbols == ["execute", "insert_compare_log", "purge_compare_log"], (
        f"허용 쓰기 심볼 = execute(참여) + insert/purge_compare_log(익명) 3종뿐: {write_symbols}"
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


@pytest.mark.asyncio
async def test_execute_binds_params_and_returns_rowcount(monkeypatch):
    """execute — 참여 쓰기 1문 %s 바인딩 + 영향 행 수(cur.rowcount) 반환(SP-AUTH-4)."""
    from server import database

    pool = _FakePool([], rowcount=3)
    monkeypatch.setattr(database, "_pool", pool)
    affected = await database.execute(
        "UPDATE TCOMPANY_BENEFIT SET BADGE_CD = %s WHERE BENEFIT_ID = %s", ("verified", 7)
    )
    assert affected == 3
    sql, params = pool.conn.cursor_obj.calls[-1]
    assert sql.startswith("UPDATE TCOMPANY_BENEFIT")
    assert params == ("verified", 7)


@pytest.mark.asyncio
async def test_transaction_commits_on_success(monkeypatch):
    """transaction — 정상 종료 시 begin→commit, 커넥션 yield 로 다문을 한 트랜잭션에 묶음(SP-AUTH-4·9)."""
    from server import database

    pool = _FakePool([])
    monkeypatch.setattr(database, "_pool", pool)
    async with database.transaction() as conn:
        assert conn is pool.conn
        async with conn.cursor() as cur:
            await cur.execute("INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID) VALUES (%s)", (1,))
    assert pool.conn.tx_calls == ["begin", "commit"]


@pytest.mark.asyncio
async def test_transaction_rolls_back_on_exception(monkeypatch):
    """transaction — 블록 내 예외 시 begin→rollback 후 예외 재전파(원자성 보장, 커밋 없음)."""
    from server import database

    pool = _FakePool([])
    monkeypatch.setattr(database, "_pool", pool)
    with pytest.raises(RuntimeError, match="boom"):
        async with database.transaction():
            raise RuntimeError("boom")
    assert pool.conn.tx_calls == ["begin", "rollback"]
