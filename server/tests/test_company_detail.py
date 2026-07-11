"""T-04.9.* GET /api/v1/companies/{comp_id} 테스트 (TC-1~4, SP-API-11)."""
from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_TC1_existing_company_full_object(client):
    resp = await client.get("/api/v1/companies/1")
    assert resp.status_code == 200
    body = resp.json()
    assert body["comp_id"] == 1
    assert "benefits" in body and len(body["benefits"]) > 0
    assert "aliases" in body and len(body["aliases"]) >= 1
    assert body["work_style_val"] == {"remote": True, "flex": False}
    assert resp.headers.get("cache-control") == "public, max-age=3600"

    # 스키마 준수(Company 모델 검증 통과)
    from server.models.reference import Company

    Company(**body)


@pytest.mark.asyncio
async def test_TC2_missing_company_is_404(client):
    resp = await client.get("/api/v1/companies/999999")
    assert resp.status_code == 404
    assert resp.json() == {"detail": "회사를 찾을 수 없습니다."}
    assert resp.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_TC3_non_integer_comp_id_is_422(client):
    resp = await client.get("/api/v1/companies/abc")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_TC4_zero_comp_id_is_422(client):
    resp = await client.get("/api/v1/companies/0")
    assert resp.status_code == 422
