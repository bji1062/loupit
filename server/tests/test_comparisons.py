"""비교 로그·트렌딩 API 계약 테스트 (INV-1 개정 2026-07-14).

"실시간 비교 TOP 10" 위젯을 위해 익명 비교 로그 쓰기 1종(POST /comparisons/log)과
집계 조회 1종(GET /comparisons/trending)을 추가한다. 저장은 회사쌍 comp_id + 시각뿐 —
사용자 식별자·IP·연봉 등 입력값은 절대 저장하지 않는다(FR-07 서버 미전송 원칙의
예외는 이 익명 쌍 카운트로 한정). 표면 변화는 test_surface.py TS-1이 정본으로 고정.

fake_data(client 의존)의 canned fetch_all/fetch_one은 본 라우터의 SQL을 모르므로,
각 테스트가 monkeypatch로 database 헬퍼를 재-patch한다(SP-API-14.1 모듈 참조 패턴).
"""
from __future__ import annotations

import pytest

from server import database

_TRENDING_ROWS = [
    {"a_comp_id": 1, "a_comp_nm": "삼성전자", "b_comp_id": 2, "b_comp_nm": "SK하이닉스", "cnt": 12},
    {"a_comp_id": 3, "a_comp_nm": "네이버", "b_comp_id": 4, "b_comp_nm": "카카오", "cnt": 7},
]


def _patch_exists(monkeypatch, existing_ids):
    """POST 존재검증용 fetch_all patch — TCOMPANY IN(%s,%s) 조회에 canned 응답."""

    async def _fetch_all(sql: str, params: tuple = ()):
        assert "FROM TCOMPANY" in sql and "IN (%s, %s)" in sql, f"예상 밖 SQL: {sql!r}"
        return [{"comp_id": cid} for cid in existing_ids if cid in params]

    monkeypatch.setattr(database, "fetch_all", _fetch_all)


def _patch_insert(monkeypatch):
    calls: list[tuple] = []

    async def _insert(a_comp_id: int, b_comp_id: int) -> None:
        calls.append((a_comp_id, b_comp_id))

    monkeypatch.setattr(database, "insert_compare_log", _insert)
    return calls


# ── POST /comparisons/log ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_TCMP1_post_log_valid_pair_204_and_single_insert(client, monkeypatch):
    """유효 쌍 → 204 No Content + insert_compare_log(a,b) 정확히 1회 + no-store."""
    _patch_exists(monkeypatch, {1, 2})
    calls = _patch_insert(monkeypatch)
    resp = await client.post("/api/v1/comparisons/log", json={"a": 1, "b": 2})
    assert resp.status_code == 204
    assert resp.content == b""
    assert calls == [(1, 2)]
    assert resp.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_TCMP2_post_log_same_company_422_no_insert(client, monkeypatch):
    """a == b → 422 (동일 회사 자기비교 로그 거부), insert 미호출."""
    _patch_exists(monkeypatch, {1})
    calls = _patch_insert(monkeypatch)
    resp = await client.post("/api/v1/comparisons/log", json={"a": 1, "b": 1})
    assert resp.status_code == 422
    assert calls == []


@pytest.mark.asyncio
async def test_TCMP3_post_log_unknown_company_404_no_insert(client, monkeypatch):
    """미존재 comp_id 포함 → 404, insert 미호출 (직접 입력 모드 쌍은 로그 대상 아님)."""
    _patch_exists(monkeypatch, {1})  # 2는 미존재
    calls = _patch_insert(monkeypatch)
    resp = await client.post("/api/v1/comparisons/log", json={"a": 1, "b": 2})
    assert resp.status_code == 404
    assert calls == []


@pytest.mark.asyncio
async def test_TCMP4_post_log_invalid_body_422(client, monkeypatch):
    """비정수·누락·0 이하 → 422 (pydantic 검증)."""
    calls = _patch_insert(monkeypatch)
    for body in ({"a": "삼성", "b": 2}, {"a": 1}, {"a": 0, "b": 2}, {}):
        resp = await client.post("/api/v1/comparisons/log", json=body)
        assert resp.status_code == 422, f"body={body} → {resp.status_code}"
    assert calls == []


# ── GET /comparisons/trending ────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_TCMP5_get_trending_shape_and_cache_header(client, monkeypatch):
    """200 {"items":[{a_comp_id,a_comp_nm,b_comp_id,b_comp_nm,cnt}]} + public max-age=60."""

    async def _fetch_all(sql: str, params: tuple = ()):
        assert "TCOMPARE_LOG" in sql
        return [dict(r) for r in _TRENDING_ROWS]

    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    resp = await client.get("/api/v1/comparisons/trending")
    assert resp.status_code == 200
    assert resp.json() == {"items": _TRENDING_ROWS}
    assert resp.headers.get("cache-control") == "public, max-age=60"


@pytest.mark.asyncio
async def test_TCMP6_get_trending_uses_ttl_cache(client, monkeypatch):
    """두 번째 호출은 인메모리 캐시 히트 — DB 재조회 0 (reference/all과 동일 패턴)."""
    hits = {"n": 0}

    async def _fetch_all(sql: str, params: tuple = ()):
        hits["n"] += 1
        return [dict(r) for r in _TRENDING_ROWS]

    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    first = await client.get("/api/v1/comparisons/trending")
    second = await client.get("/api/v1/comparisons/trending")
    assert first.json() == second.json()
    assert hits["n"] == 1


@pytest.mark.asyncio
async def test_TCMP7_get_trending_empty_items(client, monkeypatch):
    """로그 0건 → 200 {"items": []} (오류 아님 — 위젯은 빈 목록이면 숨김)."""

    async def _fetch_all(sql: str, params: tuple = ()):
        return []

    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    resp = await client.get("/api/v1/comparisons/trending")
    assert resp.status_code == 200
    assert resp.json() == {"items": []}


@pytest.mark.asyncio
async def test_TCMP8_head_trending_allowed(client, monkeypatch):
    """HEAD 허용(L-1 정합) — 200, 본문 없음."""

    async def _fetch_all(sql: str, params: tuple = ()):
        return []

    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    resp = await client.head("/api/v1/comparisons/trending")
    assert resp.status_code == 200
    assert resp.content == b""
