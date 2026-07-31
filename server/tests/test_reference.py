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
        elif "TBENEFIT_EDIT_LOG" in sql:
            self._last_rows = self._datasets["edit_origin"]
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
            },
            {
                "comp_tp_id": 2,
                "comp_tp_cd": "startup",
                "comp_tp_nm": "스타트업",
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
        # 편집 이력 파생 표본 — benefit_id 20(식대)만 재직자가 등록한 것으로 둔다.
        # 그러면 복지 2행이 각각 member / seed 가 되어 **양쪽 경로가 실제로 실행**된다
        # (한쪽만 나오면 다른 쪽 분기는 한 줄도 안 돌고 초록이 된다).
        # 세 상태의 판정 규칙 자체는 아래 `_edit_origin` 단위 테스트가 소유한다.
        "edit_origin": [
            {"benefit_id": 20, "has_create": 1, "has_update": 0},
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
                "benefit_id": 20,
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
                "benefit_id": 30,
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
async def test_builder_output_json_serializable():
    """번들은 JSON 직렬화 가능해야 한다 — 라이브 GET /reference/all 500(Decimal 직렬화 불가)
    회귀 방지. 과거 DECIMAL growth_rate_val이 원인이었고 그 컬럼은 브랜드 축 제거(2026-07-20)로
    번들에서 빠졌으나, 다른 DECIMAL이 새로 유입돼도 같은 500이 나므로 가드는 유지한다."""
    from server.services.reference import build_reference_bundle

    conn = _FakeConn(_builder_datasets())
    bundle = await build_reference_bundle(conn)
    json.dumps(bundle)  # Decimal 등 비직렬화 타입 잔존 시 TypeError로 실패

    # 브랜드 축 필드가 되살아나지 않는지 잠근다. ⚠ 빌더 출력만 보면 놓친다 —
    # 라우터는 ReferenceBundle.model_dump()로 직렬화하므로 **계약 모델에 필드가 남아 있으면
    # SQL에서 빼도 null로 되살아난다**(2026-07-20 실제로 겪음). 모델 경유로 검증한다.
    from server.models.reference import ReferenceBundle

    dumped = ReferenceBundle.model_validate(bundle).model_dump()
    for t in dumped["company_types"]:
        for gone in ("growth_rate_val", "growth_label_nm", "stability_score_no"):
            assert gone not in t, f"{gone}는 계약 모델에서도 제거됐어야 한다(브랜드 축 제거)"


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
async def test_TR8_head_reference_all_ok_empty_body(client, bundle_stub):
    """L-1 회귀: /reference/all은 HEAD도 200(405 아님)이며 본문은 비어야 한다(ASGI 바디 스트립).
    캐시/전송 헤더는 GET과 동일하게 유지된다."""
    resp = await client.head("/api/v1/reference/all")
    assert resp.status_code == 200
    assert resp.content == b""
    assert resp.headers.get("cache-control") == "public, max-age=3600"


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
async def test_TR9_low1_extra_columns_stripped_not_leaked(client, bundle_stub, monkeypatch):
    """low#1: 과거엔 model_validate로 검증만 하고 **원시 dict**를 직렬화해, DB 컬럼 추가·
    타입 드리프트로 생긴 계약 밖 필드가 그대로 응답·캐시·CDN까지 새어 나갔다. 이제 검증된
    모델의 model_dump를 직렬화하므로 계약에 없는 필드(top-level·company·benefit)는 탈락한다.
    (정상 데이터의 바이트 동일성은 라이브 606,531B 실측으로 별도 확인 — reference.py 주석.)"""
    from server.routers import reference as reference_router

    async def _drifted(conn):
        return {
            "company_types": [],
            "benefit_presets": {},
            "companies": [
                {
                    "comp_id": 1,
                    "comp_eng_nm": "testco",
                    "comp_nm": "테스트기업",
                    "comp_tp_cd": "large",
                    "industry_nm": "IT",
                    "logo_nm": "T",
                    "work_style_val": {"remote": True},
                    "careers_benefit_url": None,
                    "aliases": ["테스트기업"],
                    "benefits": [
                        {
                            "benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 220,
                            "benefit_ctgr_cd": "compensation", "badge_cd": "official",
                            "amt_source": "stated", "qual_yn": False,
                            "qual_desc_ctnt": None, "note_ctnt": None,
                            "verified_dtm": None, "expires_dtm": None,
                            "badge_src_cd": None, "badge_src_url_ctnt": None, "sort_order_no": 1,
                            "INTERNAL_SECRET_COL": "benefit-leak",  # 계약 밖(신규 컬럼 드리프트 모사)
                        },
                    ],
                    "EMP_SALARY_INTERNAL": "company-leak",  # 계약 밖
                },
            ],
            "TOP_LEVEL_DRIFT": "top-leak",  # 계약 밖 최상위 키
        }

    monkeypatch.setattr(reference_router, "build_reference_bundle", _drifted)
    resp = await client.get("/api/v1/reference/all")
    assert resp.status_code == 200
    text = resp.text
    assert "INTERNAL_SECRET_COL" not in text and "benefit-leak" not in text
    assert "EMP_SALARY_INTERNAL" not in text and "company-leak" not in text
    assert "TOP_LEVEL_DRIFT" not in text and "top-leak" not in text
    # 계약 필드는 정상 유지(과차단 아님)
    body = resp.json()
    assert body["companies"][0]["comp_nm"] == "테스트기업"
    assert body["companies"][0]["benefits"][0]["benefit_cd"] == "meal"


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


# ── 출처 계보 파생 (2026-07-31, 배지 3종) ──────────────────────────────────
#
# 배지는 "누가 마지막으로 손댔나"를 말한다. 근거는 `TBENEFIT_EDIT_LOG` 하나뿐이고
# 별도 컬럼을 두지 않는다 — 원장과 컬럼이 어긋나는 날 어느 쪽이 참인지 알 수 없기 때문이다.


def test_edit_origin_rule():
    """`create` 가 `update` 를 이긴다 — 등록 후 스스로 고쳐도 그 줄의 기원은 등록이다."""
    from server.services.reference import _edit_origin

    assert _edit_origin(None) == "seed", "이력이 없으면 시드 원본 = 공식"
    assert _edit_origin({}) == "seed"
    assert _edit_origin({"has_create": 0, "has_update": 1}) == "edited"
    assert _edit_origin({"has_create": 1, "has_update": 0}) == "member"
    assert _edit_origin({"has_create": 1, "has_update": 1}) == "member", "등록 기원이 이긴다"


@pytest.mark.asyncio
async def test_builder_attaches_edit_origin_and_hides_join_key():
    """번들의 모든 복지가 `edit_origin` 을 갖고, **조인 키는 새어 나가지 않는다**.

    `benefit_id` 는 파생을 위해 SQL 에서만 꺼내 쓰고 번들 계약에는 넣지 않는다 —
    넣는 순간 공개 응답의 필드가 하나 늘고, 되돌리기 어려운 계약이 된다.
    """
    from server.services.reference import build_reference_bundle

    bundle = await build_reference_bundle(_FakeConn(_builder_datasets()))
    origins = [b["edit_origin"] for c in bundle["companies"] for b in c["benefits"]]
    assert origins, "복지가 하나도 없다 — 이 테스트가 공회전한다"
    assert set(origins) == {"member", "seed"}, f"양쪽 경로가 실행되지 않았다: {origins}"
    for c in bundle["companies"]:
        for b in c["benefits"]:
            assert "benefit_id" not in b, "조인 키가 번들 계약으로 새어 나갔다"


@pytest.mark.asyncio
async def test_builder_survives_missing_edit_log():
    """편집 이력 조회가 실패해도 **익명 열람은 죽지 않는다**(INV-1).

    이 함수는 회사·복지 전체의 유일한 공급원이다. 참여(M9) 테이블 하나 때문에 익명 사용자가
    빈 사이트를 보면 안 된다 → 전부 '시드 원본'(공식)으로 보고 계속한다. 대신 경고를 남긴다.
    """
    from server.services.reference import build_reference_bundle

    datasets = _builder_datasets()
    conn = _FakeConn(datasets)

    original = conn._cursor.execute

    async def boom(sql, params=()):
        if "TBENEFIT_EDIT_LOG" in sql:
            raise RuntimeError("테이블 없음 모의")
        return await original(sql, params)

    conn._cursor.execute = boom
    bundle = await build_reference_bundle(conn)
    origins = {b["edit_origin"] for c in bundle["companies"] for b in c["benefits"]}
    assert origins == {"seed"}, "이력 실패 시 전부 시드로 떨어져야 한다"
    assert sum(len(c["benefits"]) for c in bundle["companies"]) > 0, "복지가 사라졌다"


@pytest.mark.asyncio
async def test_response_model_keeps_every_builder_field():
    """🚨 **빌더가 만든 필드는 응답 모델을 통과해야 한다.**

    라우터는 `ReferenceBundle.model_validate(bundle)` 로 검증하는데, Pydantic 은 **모르는
    필드를 조용히 떨어뜨린다.** 2026-07-31 에 실제로 그랬다 — `edit_origin` 을 빌더에만 넣고
    모델에 선언하지 않아, 정적 페이지(빌더 직접 소비)는 새 배지가 나오는데 비교 리포트·
    디렉터리(API 소비)는 영영 '공식'만 보였다. 서버도 클라이언트도 아무 오류를 내지 않는다.

    특정 필드가 아니라 **일반 계약**으로 잰다 — 다음에 필드를 더할 때도 이 테스트가 잡는다.
    """
    from server.models.reference import ReferenceBundle
    from server.services.reference import build_reference_bundle

    bundle = await build_reference_bundle(_FakeConn(_builder_datasets()))
    roundtrip = ReferenceBundle.model_validate(bundle).model_dump()

    def missing(built, kept, path=""):
        out = []
        if isinstance(built, dict):
            for k, v in built.items():
                if k not in kept:
                    out.append(f"{path}.{k}")
                else:
                    out += missing(v, kept[k], f"{path}.{k}")
        elif isinstance(built, list) and built and isinstance(built[0], (dict, list)):
            for i, v in enumerate(built):
                if i < len(kept):
                    out += missing(v, kept[i], f"{path}[{i}]")
        return out

    lost = missing(bundle, roundtrip)
    assert not lost, f"응답 모델이 떨어뜨린 필드(= API 소비자는 영영 못 본다): {lost}"
    # 자기검증 — 비교 대상이 비어 있으면 위 어서션은 언제나 참이다.
    assert bundle["companies"] and bundle["companies"][0]["benefits"], "표본이 비었다"
