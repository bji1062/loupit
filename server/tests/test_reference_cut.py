"""/compare 경량화(2026-10-22) — 번들 한 번 조립 → /reference/all · /index · /companies/{id} 세 응답.

무 DB(bundle_stub 와 같은 방식으로 조립기를 캔드로 대체). 같은 결과 보장:
  · `/reference/all` 바이트는 예전 방식(검증된 덤프 직렬화)과 같다
  · `/reference/index` 는 번들과 회사 수 · 순서 · 키가 맞고 복지 행이 없다
  · `/reference/companies/{id}` 는 모든 회사에 대해 번들의 그 회사와 JSON 이 같다(edit_origin 포함)
  · 눈금 통계의 합 · rmax · total 은 `generator/corpus.py::build` 와 같다
  · 승인 반영(`cache.clear()`) 뒤 세 응답이 모두 새 값이다
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

import pytest

from generator import corpus as corpus_mod
from generator.pages.company import CATEGORY_ORDER
from server.models.reference import IndexCompany, ReferenceBundle, ReferenceIndex
from server.services.reference_cut import category_stats, cut_bundle

_DATA = Path(__file__).resolve().parents[2] / "generator" / "tests" / "data"


def _load_maker():
    spec = importlib.util.spec_from_file_location("make_compare_index_cases", _DATA / "make_compare_index_cases.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


MAKER = _load_maker()


def _bundle() -> dict:
    return MAKER.fake_bundle()


@pytest.fixture
def cut_stub(monkeypatch):
    """`reference_router` 가 쓰는 조립기를 8사 가짜 번들로 대체 — 호출 수를 센다."""
    from server.routers import reference as reference_router

    state = {"calls": 0, "bundle": _bundle()}

    class _Ctx:
        async def __aenter__(self):
            return object()

        async def __aexit__(self, *exc):
            return False

    class _Pool:
        def acquire(self):
            return _Ctx()

    async def _build(conn):
        state["calls"] += 1
        return json.loads(json.dumps(state["bundle"]))

    monkeypatch.setattr(reference_router, "get_pool", lambda: _Pool())
    monkeypatch.setattr(reference_router, "build_reference_bundle", _build)
    return state


# ── 순수: 자르기 함수 ────────────────────────────────────────────────────────

def test_픽스처는_지금_서버_함수_출력과_같다():
    """compare_index_cases.json 이 낡지 않았다 — 서버 함수를 바꿨으면 make_compare_index_cases.py 로 다시 뽑는다."""
    on_disk = json.loads((_DATA / "compare_index_cases.json").read_text(encoding="utf-8"))
    fresh = json.loads(json.dumps(MAKER.build_cases(), ensure_ascii=False))
    assert on_disk == fresh


def test_all_바이트는_예전_방식과_같다():
    """/reference/all 은 검증된 덤프의 json.dumps 그대로(바이트 동일) — 자르기가 응답을 바꾸지 않는다."""
    bundle = _bundle()
    legacy = json.dumps(ReferenceBundle.model_validate(bundle).model_dump(), ensure_ascii=False).encode("utf-8")
    assert cut_bundle(bundle).all_body == legacy


def test_index_는_복지행_없는_번들과_같은_순서():
    bundle = _bundle()
    cut = cut_bundle(bundle)
    index = json.loads(cut.index_body)
    assert list(index) == ["company_types", "benefit_presets", "companies", "category_stats"]  # 최상위 정확히 4키
    assert [c["comp_id"] for c in index["companies"]] == [c["comp_id"] for c in bundle["companies"]]
    assert [c["comp_nm"] for c in index["companies"]] == [c["comp_nm"] for c in bundle["companies"]]
    for c in index["companies"]:
        assert set(c) == set(IndexCompany.model_fields)  # 모델이 필드를 떨구지 않는다
        assert "benefits" not in c and "work_style_val" not in c and "careers_benefit_url" not in c
    assert index["company_types"] == json.loads(cut.all_body)["company_types"]
    assert index["benefit_presets"] == json.loads(cut.all_body)["benefit_presets"]
    ReferenceIndex.model_validate(index)


def test_benefit_n_은_표시행을_뺀_셀_수_있는_복지_수():
    from generator import marks

    bundle = _bundle()
    index = json.loads(cut_bundle(bundle).index_body)
    for src, c in zip(bundle["companies"], index["companies"]):
        assert c["benefit_n"] == len(marks.countable(src))
    by_id = {c["comp_id"]: c["benefit_n"] for c in index["companies"]}
    assert by_id[1] == 2, "KT: 법정 표시 행(출산/육아 지원) 하나는 뺀다"
    assert by_id[2] == 2, "알테오젠: 업무 교육 표시 행은 빼고 검색 요약 행(ai_parse)은 센다"


def test_눈금_통계는_corpus_build_와_같다():
    bundle = ReferenceBundle.model_validate(_bundle()).model_dump()
    stats = category_stats(bundle["companies"])
    corpus = corpus_mod.build(bundle["companies"], CATEGORY_ORDER)
    assert stats["total"] == corpus.total
    assert stats["rmax"] == corpus.rmax
    assert list(stats["sums"]) == CATEGORY_ORDER  # 카테고리 집합 · 순서
    for k in CATEGORY_ORDER:
        assert stats["sums"][k] / stats["total"] == corpus.avgs[k], k  # 합 ÷ 분모 = 평균(같은 나눗셈)


def test_눈금_통계_빈_번들과_rmax_최소_1():
    assert category_stats([]) == {"total": 0, "sums": {k: 0 for k in CATEGORY_ORDER}, "rmax": 1}


def test_회사별_상세는_번들의_그_회사_그대로():
    bundle = _bundle()
    cut = cut_bundle(bundle)
    dump = json.loads(cut.all_body)
    assert set(cut.company_bodies) == {c["comp_id"] for c in dump["companies"]}
    for c in dump["companies"]:
        assert json.loads(cut.company_bodies[c["comp_id"]]) == c
    origins = {b["edit_origin"] for c in json.loads(cut.all_body)["companies"] for b in c["benefits"]}
    assert {"seed", "edited", "member"} <= origins, "출처 계보(edit_origin)가 상세에도 실린다"


# ── 라우터 ───────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_세_응답은_한_번_조립에서_나온다(client, cut_stub):
    r_all = await client.get("/api/v1/reference/all")
    r_idx = await client.get("/api/v1/reference/index")
    r_one = await client.get("/api/v1/reference/companies/1")
    assert (r_all.status_code, r_idx.status_code, r_one.status_code) == (200, 200, 200)
    assert cut_stub["calls"] == 1


@pytest.mark.asyncio
async def test_all_응답_바이트는_자르기_전과_같다(client, cut_stub):
    r = await client.get("/api/v1/reference/all")
    legacy = json.dumps(ReferenceBundle.model_validate(_bundle()).model_dump(), ensure_ascii=False).encode("utf-8")
    assert r.content == legacy
    assert r.headers["content-type"] == "application/json; charset=utf-8"
    assert r.headers["cache-control"] == "public, max-age=3600"


@pytest.mark.asyncio
async def test_index_응답_계약(client, cut_stub):
    r = await client.get("/api/v1/reference/index")
    assert r.headers["content-type"] == "application/json; charset=utf-8"
    assert r.headers["cache-control"] == "public, max-age=3600"
    body = r.json()
    ReferenceIndex.model_validate(body)
    assert len(body["companies"]) == 8
    assert [c["comp_id"] for c in body["companies"]] == list(range(1, 9))
    assert len(r.content) < len((await client.get("/api/v1/reference/all")).content)


@pytest.mark.asyncio
async def test_모든_회사의_상세는_번들과_같다(client, cut_stub):
    bundle = (await client.get("/api/v1/reference/all")).json()
    for c in bundle["companies"]:
        r = await client.get(f"/api/v1/reference/companies/{c['comp_id']}")
        assert r.status_code == 200
        assert r.json() == c
        assert r.headers["cache-control"] == "public, max-age=3600"


@pytest.mark.asyncio
async def test_없는_id_404_잘못된_id_422(client, cut_stub):
    assert (await client.get("/api/v1/reference/companies/9999")).status_code == 404
    assert (await client.get("/api/v1/reference/companies/0")).status_code == 422
    assert (await client.get("/api/v1/reference/companies/-3")).status_code == 422
    assert (await client.get("/api/v1/reference/companies/abc")).status_code == 422


@pytest.mark.asyncio
async def test_HEAD_허용_본문_없음(client, cut_stub):
    for path in ("/api/v1/reference/index", "/api/v1/reference/companies/1"):
        resp = await client.head(path)
        assert resp.status_code == 200 and resp.content == b""
        assert resp.headers.get("cache-control") == "public, max-age=3600"


@pytest.mark.asyncio
async def test_승인_반영_cache_clear_뒤_세_응답이_모두_새_값(client, cut_stub):
    before_idx = (await client.get("/api/v1/reference/index")).json()
    assert before_idx["companies"][0]["comp_nm"] == "KT"
    cut_stub["bundle"]["companies"][0]["comp_nm"] = "KT(개명)"
    # 캐시 안이라 아직 옛 값
    assert (await client.get("/api/v1/reference/companies/1")).json()["comp_nm"] == "KT"
    client.app.state.reference_cache.clear()  # 콘솔 승인이 하는 일
    assert (await client.get("/api/v1/reference/index")).json()["companies"][0]["comp_nm"] == "KT(개명)"
    assert (await client.get("/api/v1/reference/companies/1")).json()["comp_nm"] == "KT(개명)"
    assert (await client.get("/api/v1/reference/all")).json()["companies"][0]["comp_nm"] == "KT(개명)"
    assert cut_stub["calls"] == 2


@pytest.mark.asyncio
async def test_benefit_codes_와_캐시_키가_충돌하지_않는다(client, cut_stub):
    """같은 캐시를 쓰는 benefit_codes 가 자르기 결과를 덮어쓰거나 그 반대가 되지 않는다."""
    from server.services import benefit_codes
    from server.routers import reference as reference_router

    assert reference_router._CACHE_KEY != benefit_codes.CACHE_KEY
