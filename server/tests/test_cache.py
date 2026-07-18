"""T-04.2.3 cache.py TTLCache 유닛 테스트 (SP-API-4).

무 DB — monotonic 시계를 monkeypatch로 제어해 만료 경계를 결정론적으로 검증한다.
get_or_set(dogpile 방어, low#2)는 asyncio.Lock 이중검사로 동시 미스의 재빌드를
1회로 수렴시키고, builder 예외 시 락 누수가 없음을 검증한다.
"""
from __future__ import annotations

import asyncio

import pytest


def test_set_then_get_hit(monkeypatch):
    from server import cache as cache_mod

    clock = {"t": 100.0}
    monkeypatch.setattr(cache_mod.time, "monotonic", lambda: clock["t"])

    c = cache_mod.TTLCache(ttl_seconds=10)
    c.set("k", "v")
    assert c.get("k") == "v"


def test_ttl_zero_is_immediate_miss(monkeypatch):
    from server import cache as cache_mod

    clock = {"t": 100.0}
    monkeypatch.setattr(cache_mod.time, "monotonic", lambda: clock["t"])

    c = cache_mod.TTLCache(ttl_seconds=0)
    c.set("k", "v")
    clock["t"] += 0.001  # 극소 경과만으로도 만료
    assert c.get("k") is None


def test_expired_entry_is_popped_from_store(monkeypatch):
    from server import cache as cache_mod

    clock = {"t": 100.0}
    monkeypatch.setattr(cache_mod.time, "monotonic", lambda: clock["t"])

    c = cache_mod.TTLCache(ttl_seconds=5)
    c.set("k", "v")
    clock["t"] += 5.001
    assert c.get("k") is None
    assert "k" not in c._store  # 만료 시 pop 확인


def test_get_missing_key_returns_none():
    from server import cache as cache_mod

    c = cache_mod.TTLCache(ttl_seconds=10)
    assert c.get("nope") is None


def test_clear_empties_store():
    from server import cache as cache_mod

    c = cache_mod.TTLCache(ttl_seconds=10)
    c.set("a", 1)
    c.set("b", 2)
    c.clear()
    assert c.get("a") is None
    assert c.get("b") is None


# ── get_or_set: dogpile 방어(low#2) ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_or_set_builds_on_miss_and_caches():
    """미스 → builder 1회 호출·값 캐시. 두 번째 호출은 히트라 builder 미호출."""
    from server import cache as cache_mod

    calls = {"n": 0}

    async def _builder():
        calls["n"] += 1
        return "built"

    c = cache_mod.TTLCache(ttl_seconds=100)
    assert await c.get_or_set("k", _builder) == "built"
    assert await c.get_or_set("k", _builder) == "built"
    assert calls["n"] == 1  # 두 번째는 캐시 히트


@pytest.mark.asyncio
async def test_get_or_set_concurrent_miss_builds_once():
    """만료 경계 동시 미스 N건 → 이중검사 락으로 builder 정확히 1회(dogpile 억제)."""
    from server import cache as cache_mod

    calls = {"n": 0}

    async def _builder():
        calls["n"] += 1
        await asyncio.sleep(0.02)  # 재빌드 지연 창 — 이 사이 다른 요청이 락 대기
        return "built"

    c = cache_mod.TTLCache(ttl_seconds=100)
    results = await asyncio.gather(*[c.get_or_set("k", _builder) for _ in range(10)])
    assert results == ["built"] * 10
    assert calls["n"] == 1  # 10개 동시요청이 1회 재빌드만 유발


@pytest.mark.asyncio
async def test_get_or_set_builder_exception_releases_lock():
    """builder 예외는 전파되고(값 미저장) 락은 해제 → 다음 호출이 재빌드 가능(락 누수 없음)."""
    from server import cache as cache_mod

    c = cache_mod.TTLCache(ttl_seconds=100)

    async def _boom():
        raise RuntimeError("build failed")

    with pytest.raises(RuntimeError):
        await c.get_or_set("k", _boom)

    # 락이 풀렸는지: 이어지는 정상 builder가 데드락 없이 완주해야 한다.
    async def _ok():
        return "recovered"

    assert await c.get_or_set("k", _ok) == "recovered"
