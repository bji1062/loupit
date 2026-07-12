"""T-04.4.1 build_reference_bundle 빌더 유닛 테스트 + T-04.7.* GET /reference/all 라우터 테스트
+ TE-1 전역 예외 핸들러 (SP-API-7·9, FR-92·FR-D1, INV-2).

무 DB. 빌더는 fake conn/cursor(aiomysql DictCursor 흉내)로, 라우터는 conftest
`client`/`bundle_stub` 픽스처로 검증한다.
"""
from __future__ import annotations

import json
from decimal import Decimal

import pytest

# ─────────────────────────────────────────────────────────────────────
# fake aiomysql conn/cursor — build_reference_bundle(conn) 유닛 테스트용
# ─────────────────────────────────────────────────────────────────────


class _FakeCursor:
    """SQL 텍스트 패턴으로 캔드 행 집합을 매칭 반환하는 fake DictCursor."""

    def __init__(self, datasets: dict[str, list[dict]]):
        self._datasets = datasets
        self._last_rows: list[dict] = []
        self.executed_sql: list[str] = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def execute(self, sql: str, params: tuple = ()):
        self.executed_sql.append(sql)
        if "TCOMPANY_TYPE" in sql and "JOIN" not in sql:
            self._last_rows = self._datasets["types"]
        elif "TBENEFIT_PRESET" in sql:
            self._last_rows = self._datasets["presets"]
        elif "TCOMPANY c JOIN TCOMPANY_TYPE" in sql and "WHERE" not in sql:
            self._last_rows = self._datasets["companies"]
        elif "TCOMPANY_ALIAS" in sql and "WHERE" not in sql:
            self._last_rows = self._datasets["aliases"]
        elif "TCOMPANY_BENEFIT" in sql and "WHERE" not in sql:
            self._last_rows = self._datasets["benefits"]
        else:
            raise AssertionError(f"예상치 못한 SQL: {sql}")

    async def fetchall(self):
        # 얕은 복사한 dict 리스트 반환 — 빌더가 in-place로 pop/mutate 하므로
        # 원본 캔드 데이터를 훼손하지 않도록 매 호출 시 새 dict로 복제한다.
        return [dict(r) for r in self._last_rows]


class _FakeConn:
    def __init__(self, datasets: dict[str, list[dict]]):
        self._cursor = _FakeCursor(datasets)

    def cursor(self):
        return self._cursor


def _builder_datasets() -> dict[str, list[dict]]:
    return {
        "types": [
            {
                "comp_tp_id": 1,
                "comp_tp_cd": "large",
                "comp_tp_nm": "대기업",
                "growth_rate_val": Decimal("0.04"),  # 실 aiomysql DECIMAL 재현
                "growth_label_nm": "대기업 평균 4%",
                "stability_score_no": 90,
            },
            {
                "comp_tp_id": 2,
                "comp_tp_cd": "startup",
                "comp_tp_nm": "스타트업",
                "growth_rate_val": Decimal("0.06"),  # 실 aiomysql DECIMAL 재현
                "growth_label_nm": "스타트업 평균 6%",
                "stability_score_no": 40,
            },
        ],
        "presets": [
            {
                "comp_tp_cd": "large",
                "benefit_cd": "meal",
                "benefit_nm": "식대",
                "benefit_amt": 200,
                "benefit_ctgr_cd": "compensation",
                "badge_cd": "est",
                "default_checked_yn": 1,
                "sort_order_no": 1,
            },
        ],
        "companies": [
            {
                "comp_id": 1,
                "comp_eng_nm": "testco",
                "comp_nm": "테스트기업",
                "comp_tp_cd": "large",
                "industry_nm": "IT",
                "logo_nm": "T",
                "work_style_val": '{"remote": true, "flex": false}',
                "careers_benefit_url": "https://testco.example/careers",
            },
            {
                "comp_id": 2,
                "comp_eng_nm": "nowsvals",
                "comp_nm": "노설명회사",
                "comp_tp_cd": "startup",
                "industry_nm": None,
                "logo_nm": None,
                "work_style_val": None,
                "careers_benefit_url": None,
            },
        ],
        "aliases": [
            {"comp_id": 1, "alias_nm": "테스트기업"},
            {"comp_id": 1, "alias_nm": "testco"},
            {"comp_id": 2, "alias_nm": "노설명회사"},
        ],
        "benefits": [
            {
                "comp_id": 1,
                "benefit_cd": "meal",
                "benefit_nm": "식대",
                "benefit_amt": 220,
                "benefit_ctgr_cd": "compensation",
                "badge_cd": "official",
                "amt_source": "stated",
                "qual_yn": 0,
                "qual_desc_ctnt": None,
                "note_ctnt": None,
                "verified_dtm": None,
                "expires_dtm": None,
                "badge_src_cd": "scrape_official",
                "badge_src_url_ctnt": "https://testco.example/careers",
                "sort_order_no": 1,
            },
            {
                "comp_id": 2,
                "benefit_cd": "flex_time",
                "benefit_nm": "유연근무",
                "benefit_amt": None,
                "benefit_ctgr_cd": "flexibility",
                "badge_cd": "est",
                "amt_source": "none",
                "qual_yn": 1,
                "qual_desc_ctnt": "부서별 상이",
                "note_ctnt": None,
                "verified_dtm": None,
                "expires_dtm": None,
                "badge_src_cd": "ai_parse",
                "badge_src_url_ctnt": None,
                "sort_order_no": 1,
            },
        ],
    }


@pytest.mark.asyncio
async def test_builder_top_level_keys_exactly_three():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    assert set(bundle.keys()) == {"company_types", "benefit_presets", "companies"}


@pytest.mark.asyncio
async def test_builder_output_json_serializable_growth_rate_float():
    """실 aiomysql이 DECIMAL(growth_rate_val)을 Decimal로 반환해도 번들이 JSON
    직렬화 가능해야 한다 — 라이브 GET /reference/all 500(Decimal 직렬화 불가) 회귀 방지.
    fake 데이터셋의 growth_rate_val은 Decimal이며, 빌더가 float로 정규화(FR-D)해야 한다."""
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    json.dumps(bundle)  # Decimal 잔존 시 TypeError로 실패
    gr = bundle["company_types"][0]["growth_rate_val"]
    assert isinstance(gr, float), f"growth_rate_val은 float여야 함(현재 {type(gr).__name__})"


@pytest.mark.asyncio
async def test_builder_work_style_val_parsed_to_dict():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    comp1 = next(c for c in bundle["companies"] if c["comp_id"] == 1)
    assert comp1["work_style_val"] == {"remote": True, "flex": False}
    comp2 = next(c for c in bundle["companies"] if c["comp_id"] == 2)
    assert comp2["work_style_val"] is None


@pytest.mark.asyncio
async def test_builder_amt_source_alias_present_on_benefits():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    comp1 = next(c for c in bundle["companies"] if c["comp_id"] == 1)
    assert comp1["benefits"][0]["amt_source"] == "stated"


@pytest.mark.asyncio
async def test_builder_qual_yn_and_default_checked_yn_coerced_to_bool():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    comp2 = next(c for c in bundle["companies"] if c["comp_id"] == 2)
    assert comp2["benefits"][0]["qual_yn"] is True
    preset = bundle["benefit_presets"]["large"][0]
    assert preset["default_checked_yn"] is True


@pytest.mark.asyncio
async def test_builder_aliases_and_benefits_inlined_per_company():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    comp1 = next(c for c in bundle["companies"] if c["comp_id"] == 1)
    assert set(comp1["aliases"]) == {"테스트기업", "testco"}
    assert len(comp1["benefits"]) == 1
    comp2 = next(c for c in bundle["companies"] if c["comp_id"] == 2)
    assert comp2["aliases"] == ["노설명회사"]


@pytest.mark.asyncio
async def test_builder_benefit_presets_grouped_by_comp_tp_cd():
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    assert "large" in bundle["benefit_presets"]
    assert "comp_tp_cd" not in bundle["benefit_presets"]["large"][0]  # 그룹핑 키는 pop됨


@pytest.mark.asyncio
async def test_builder_is_pure_no_mutation_of_input_rows_reused():
    """동일 conn으로 재호출해도 동일 결과(순수 조립, 부수효과 0)."""
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle1 = await build_reference_bundle(conn)
    conn2 = _FakeConn(_builder_datasets())
    bundle2 = await build_reference_bundle(conn2)
    assert bundle1 == bundle2


# ─────────────────────────────────────────────────────────────────────
# T-04.7.* — GET /api/v1/reference/all 라우터 + 인메모리 캐시 (TR-1~6)
# T-04.10.1 — 전역 예외 핸들러 (TE-1)
# ─────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_TR1_cache_miss_assembles_and_returns_three_keys(client, bundle_stub):
    resp = await client.get("/api/v1/reference/all")
    assert resp.status_code == 200
    body = resp.json()
    assert set(body.keys()) == {"company_types", "benefit_presets", "companies"}


@pytest.mark.asyncio
async def test_TR2_transport_and_cache_headers(client, bundle_stub):
    resp = await client.get("/api/v1/reference/all")
    assert resp.headers.get("cache-control") == "public, max-age=3600"
    assert resp.headers.get("content-type") == "application/json; charset=utf-8"


@pytest.mark.asyncio
async def test_TR3_no_profiler_keys(client, bundle_stub):
    resp = await client.get("/api/v1/reference/all")
    body = resp.json()
    for forbidden in ("profiles", "job_groups", "questions"):
        assert forbidden not in body


@pytest.mark.asyncio
async def test_TR4_schema_compliance_and_nonempty_arrays(client, bundle_stub):
    from server.models.reference import ReferenceBundle

    resp = await client.get("/api/v1/reference/all")
    body = resp.json()
    validated = ReferenceBundle(**body)
    for company in validated.companies:
        assert len(company.benefits) > 0
        assert len(company.aliases) >= 1


@pytest.mark.asyncio
async def test_TR5_cache_hit_builder_called_once(client, bundle_stub):
    r1 = await client.get("/api/v1/reference/all")
    r2 = await client.get("/api/v1/reference/all")
    assert r1.status_code == 200 and r2.status_code == 200
    assert r1.json() == r2.json()
    assert bundle_stub["calls"] == 1


@pytest.mark.asyncio
async def test_TR6_ttl_expiry_triggers_rebuild(client, bundle_stub):
    from server.cache import TTLCache

    await client.get("/api/v1/reference/all")
    assert bundle_stub["calls"] == 1

    # TTL=0 캐시로 교체 → 즉시 만료, 다음 요청은 재조립
    client.app.state.reference_cache = TTLCache(0)
    await client.get("/api/v1/reference/all")
    assert bundle_stub["calls"] == 2


@pytest.mark.asyncio
async def test_TE1_unhandled_exception_returns_generic_500(client, bundle_stub, monkeypatch):
    from server.routers import reference as reference_router

    async def _boom(conn):
        raise RuntimeError("SELECT * FROM TCOMPANY_TYPE 접속 실패 — 이 문자열은 응답에 노출되면 안 됨")

    monkeypatch.setattr(reference_router, "build_reference_bundle", _boom)
    resp = await client.get("/api/v1/reference/all")
    assert resp.status_code == 500
    body = resp.json()
    assert body == {"detail": "일시적인 오류가 발생했습니다."}
    assert "SELECT" not in resp.text
    assert "RuntimeError" not in resp.text
    assert resp.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_TR7_contract_violation_returns_500(client, bundle_stub, monkeypatch):
    """H-1: raw Response 반환이라 response_model이 런타임 미적용 → 조립 결과가
    ReferenceBundle 계약을 위반하면 200으로 잘못된 형태를 내보내지 않고 500(전역 핸들러)."""
    from server.routers import reference as reference_router

    async def _invalid(conn):
        return {"company_types": [], "benefit_presets": {}, "companies": "부적합"}  # companies 타입 위반

    monkeypatch.setattr(reference_router, "build_reference_bundle", _invalid)
    resp = await client.get("/api/v1/reference/all")
    assert resp.status_code == 500
    assert resp.json() == {"detail": "일시적인 오류가 발생했습니다."}
    assert "부적합" not in resp.text
