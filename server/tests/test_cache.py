"""T-04.2.3 cache.py TTLCache 유닛 테스트 (SP-API-4).

무 DB — monotonic 시계를 monkeypatch로 제어해 만료 경계를 결정론적으로 검증한다.
"""
from __future__ import annotations


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
