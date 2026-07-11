"""T-04.6.1 GET /api/v1/health 라이브니스 테스트 (TH-1).

T-04.6.2(레디니스 503 확장)는 DG-4 미채택(2026-07-11 확정, MVP 라이브니스
전용)으로 구현 대상이 아니다 — TH-2 테스트도 작성하지 않는다.
"""
from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_TH1_health_liveness_ok(client):
    resp = await client.get("/api/v1/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
    assert resp.headers.get("cache-control") == "no-store"
