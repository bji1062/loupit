"""SP-API-4 인메모리 TTL 캐시.

reference/all 응답을 DB 반복 조회 없이 서빙하기 위한 프로세스 로컬 캐시.
단일 프로세스 인메모리(asyncio 단일 스레드 이벤트 루프) — 쓰기 락 불필요.
"""
from __future__ import annotations

import time
from typing import Any


class TTLCache:
    """key -> (만료 monotonic 시각, value). 만료 시 get()에서 pop 후 None 반환."""

    def __init__(self, ttl_seconds: int):
        self._ttl = ttl_seconds
        self._store: dict[str, tuple[float, Any]] = {}

    def get(self, key: str) -> Any | None:
        item = self._store.get(key)
        if item is None:
            return None
        expires_at, value = item
        if time.monotonic() >= expires_at:  # 만료 → 미스 취급
            self._store.pop(key, None)
            return None
        return value

    def set(self, key: str, value: Any) -> None:
        self._store[key] = (time.monotonic() + self._ttl, value)

    def clear(self) -> None:
        self._store.clear()
