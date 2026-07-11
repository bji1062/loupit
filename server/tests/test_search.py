"""T-04.8.* GET /api/v1/companies/search?q= 테스트 (TSE-1~7, SP-API-10)."""
from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_TSE1_name_alias_like_match_returns_five_fields_only(client):
    resp = await client.get("/api/v1/companies/search", params={"q": "삼성"})
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, list)
    assert len(body) >= 1
    for item in body:
        assert set(item.keys()) == {"comp_id", "comp_nm", "comp_tp_cd", "industry_nm", "logo_nm"}
    assert resp.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_TSE2_missing_q_is_422(client):
    resp = await client.get("/api/v1/companies/search")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_TSE3_blank_or_whitespace_q_returns_empty_200(client):
    resp1 = await client.get("/api/v1/companies/search", params={"q": ""})
    assert resp1.status_code == 200
    assert resp1.json() == []

    resp2 = await client.get("/api/v1/companies/search", params={"q": "   "})
    assert resp2.status_code == 200
    assert resp2.json() == []


@pytest.mark.asyncio
async def test_TSE4_over_length_q_is_422(client):
    resp = await client.get("/api/v1/companies/search", params={"q": "가" * 51})
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_TSE5_limit_20_upper_bound(client):
    resp = await client.get("/api/v1/companies/search", params={"q": "매치회사"})
    assert resp.status_code == 200
    body = resp.json()
    assert len(body) <= 20


@pytest.mark.asyncio
async def test_TSE6_injection_and_wildcard_no_crash(client):
    resp = await client.get("/api/v1/companies/search", params={"q": "%_!"})
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_TSE6_sql_uses_placeholder_and_escape_clause():
    """SQL에 %s 바인딩·ESCAPE 사용 검증 (주입 방지, FR-93 규칙2)."""
    from server.routers.companies import _SQL_SEARCH

    assert "%s" in _SQL_SEARCH
    assert "ESCAPE '!'" in _SQL_SEARCH
    assert "f'" not in _SQL_SEARCH and "{" not in _SQL_SEARCH  # 문자열 결합 금지(리터럴 상수)


@pytest.mark.asyncio
async def test_TSE7_zero_matches_returns_empty_200(client):
    resp = await client.get("/api/v1/companies/search", params={"q": "존재안함"})
    assert resp.status_code == 200
    assert resp.json() == []
