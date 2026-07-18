"""SP-API-4 인메모리 TTL 캐시.

reference/all 응답을 DB 반복 조회 없이 서빙하기 위한 프로세스 로컬 캐시.
단일 프로세스 인메모리(asyncio 단일 스레드 이벤트 루프)라 저장 자체에는 쓰기
락이 불필요하다. 다만 만료 경계에서 여러 요청이 동시에 미스 판정을 받으면(dogpile)
각자 DB 재조립을 수행해 중복 부하가 생긴다(low#2) — get_or_set이 asyncio.Lock
이중검사로 이를 억제해, 만료 시점 재빌드를 요청 수와 무관하게 1회로 수렴시킨다.
"""
from __future__ import annotations

import asyncio
import time
from typing import Any, Awaitable, Callable


class TTLCache:
    """key -> (만료 monotonic 시각, value). 만료 시 get()에서 pop 후 None 반환."""

    def __init__(self, ttl_seconds: int):
        self._ttl = ttl_seconds
        self._store: dict[str, tuple[float, Any]] = {}
        # 재빌드 직렬화용 락(dogpile 방어, low#2). 이 캐시는 단일 키(reference_all·
        # comparisons_trending)만 담으므로 인스턴스당 락 1개로 충분하다.
        self._rebuild_lock = asyncio.Lock()

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

    async def get_or_set(self, key: str, builder: Callable[[], Awaitable[Any]]) -> Any:
        """캐시 히트면 즉시 반환, 미스면 락 하에 단 1회만 builder()로 재빌드한다.

        이중검사(double-checked locking): 락 밖에서 1차 확인 → 히트면 락 없이 반환.
        미스면 락을 잡고 재확인 — 대기 중 다른 요청이 이미 채웠으면 그 값을 재사용해
        중복 DB 조립을 피한다. builder가 예외를 던지면 `async with`가 락을 반드시
        해제하므로 락 누수는 없다(값은 저장되지 않아 다음 요청이 재시도)."""
        value = self.get(key)
        if value is not None:
            return value
        async with self._rebuild_lock:
            value = self.get(key)  # 이중검사: 대기 중 채워졌으면 재사용
            if value is not None:
                return value
            value = await builder()
            self.set(key, value)
            return value

    def clear(self) -> None:
        self._store.clear()
