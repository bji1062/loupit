"""/compare 경량화(2026-10-22) — 번들 한 번 조립 → /reference/all · /index · /companies/{id} 세 응답.

무 DB(bundle_stub 와 같은 방식으로 조립기를 캔드로 대체). 같은 결과 보장:
  · `/reference/all` 바이트는 예전 방식(검증된 덤프 직렬화)과 같다
  · `/reference/index` 는 번들과 회사 수 · 순서 · 키가 맞고 복지 행이 없다
  · `/reference/companies/{id}` 는 모든 회사에 대해 번들의 그 회사와 JSON 이 같다(edit_origin 포함)
  · 눈금 통계의 합 · rmax · total 은 `generator/corpus.py::build` 와 같다
  · 승인 반영(`cache.clear()`) 뒤 세 응답이 모두 새 값이다

/find 경량화(2026-10-22)가 같은 조립에서 두 응답을 더 낸다(`/reference/find` · `/reference/notes/{code}`) — 아래 절 「/find」.
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

import pytest

from generator import corpus as corpus_mod
from generator.pages.company import CATEGORY_ORDER
from server.models.reference import IndexCompany, ReferenceBundle, ReferenceIndex
from pydantic import ValidationError

from server.models.reference import CategoryStats, ReferenceFind, ReferenceNotes
from server.services.reference_cut import amount_of, build_find, build_index, build_notes, category_stats, cut_bundle, top_benefits

_DATA = Path(__file__).resolve().parents[2] / "generator" / "tests" / "data"


def _load_maker():
    spec = importlib.util.spec_from_file_location("make_compare_index_cases", _DATA / "make_compare_index_cases.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


MAKER = _load_maker()


def _load_find_maker():
    spec = importlib.util.spec_from_file_location("make_find_lazy_cases", _DATA / "make_find_lazy_cases.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


FIND_MAKER = _load_find_maker()


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


def test_build_index_출력_키는_모델_필드와_정확히_같다():
    """반대 방향 대조(검토 L3): 자르기 함수가 모델에 없는 키를 더하면 조용히 떨어지지 않고 터진다."""
    dump = ReferenceBundle.model_validate(_bundle()).model_dump()
    index = build_index(dump)
    assert set(index) == set(ReferenceIndex.model_fields)
    assert set(index["category_stats"]) == set(CategoryStats.model_fields)
    for c in index["companies"]:
        assert set(c) == set(IndexCompany.model_fields)
    index["companies"][0]["새_키"] = 1
    with pytest.raises(ValidationError):
        ReferenceIndex.model_validate(index)


# ── /find (2026-10-22) ───────────────────────────────────────────────────────

def _find_bundle() -> dict:
    return FIND_MAKER.fake_bundle()


@pytest.fixture
def find_stub(monkeypatch):
    """조립기를 /find 픽스처 번들(40사)로 대체 — 호출 수를 센다."""
    from server.routers import reference as reference_router

    state = {"calls": 0, "bundle": _find_bundle()}

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


def test_find_픽스처는_지금_서버_함수_출력과_같다():
    """find_lazy_cases.json 이 낡지 않았다 — 서버 함수를 바꿨으면 make_find_lazy_cases.py 로 다시 뽑는다."""
    on_disk = (_DATA / "find_lazy_cases.json").read_text(encoding="utf-8")
    assert on_disk == FIND_MAKER.dump(json.loads(json.dumps(FIND_MAKER.build_cases(), ensure_ascii=False)))


def test_금액_판정_대조표는_서버_함수와_같다():
    cases = json.loads((_DATA / "find_lazy_cases.json").read_text(encoding="utf-8"))["amount_cases"]
    assert len(cases) >= 10
    for c in cases:
        assert amount_of(c["b"]) == c["amount"], c["b"]


def test_금액_판정_모서리():
    assert amount_of({"qual_yn": False, "benefit_amt": "300"}) == 300
    assert amount_of({"qual_yn": True, "benefit_amt": 500}) == 0, "정성이면 금액이 있어도 0"
    assert amount_of({"qual_yn": False, "benefit_amt": "abc"}) == 0
    assert amount_of({"qual_yn": False, "benefit_amt": float("nan")}) == 0
    assert amount_of({"qual_yn": False, "benefit_amt": -1}) == 0
    assert amount_of(None) == 0


def test_find_묶음은_번들과_같은_회사_행_순서():
    bundle = _find_bundle()
    dump = ReferenceBundle.model_validate(bundle).model_dump()
    find = ReferenceFind.model_validate(build_find(dump)).model_dump()
    assert list(find) == ["company_types", "companies", "top_notes"]  # 최상위 정확히 3키
    assert find["company_types"] == dump["company_types"]
    assert [c["comp_id"] for c in find["companies"]] == [c["comp_id"] for c in dump["companies"]]
    for src, c in zip(dump["companies"], find["companies"]):
        assert [b["benefit_cd"] for b in c["benefits"]] == [b["benefit_cd"] for b in src["benefits"]], src["comp_nm"]
        for b, sb in zip(c["benefits"], src["benefits"]):
            assert set(b) == {"benefit_cd", "benefit_nm", "benefit_ctgr_cd", "qual_yn", "benefit_amt", "amt_source", "badge_src_cd"}
            assert all(b[k] == sb[k] for k in b)
        assert "work_style_val" not in c and "careers_benefit_url" not in c


def test_find_묶음_행에는_설명이_없다():
    find = json.loads(cut_bundle(_find_bundle()).find_body)
    for c in find["companies"]:
        for b in c["benefits"]:
            assert "qual_desc_ctnt" not in b and "note_ctnt" not in b and "badge_cd" not in b


def test_top_notes_는_회사마다_금액_큰_세_개():
    dump = ReferenceBundle.model_validate(_find_bundle()).model_dump()
    top = build_find(dump)["top_notes"]
    by_comp: dict[int, list[str]] = {}
    for t in top:
        by_comp.setdefault(t["comp_id"], []).append(t["benefit_cd"])
    assert by_comp[1] == ["meal", "welfare_point", "gym"], "법정 표시 행(parenting 900)은 빠지고 동률은 번들 순서"
    assert by_comp[4] == ["meal"], "업무 교육 표시 행 · 정성 행은 빠진다"
    assert 3 not in by_comp, "금액이 하나도 없는 회사는 없음"
    assert all(len(v) <= 3 for v in by_comp.values())
    assert [b["benefit_cd"] for b in top_benefits(dump["companies"][8])] == ["meal", "gym", "snack"], "금액 동률 넷 → 앞 셋"


def test_top_notes_설명은_번들_행의_것():
    dump = ReferenceBundle.model_validate(_find_bundle()).model_dump()
    rows = {(c["comp_id"], b["benefit_cd"]): b for c in dump["companies"] for b in c["benefits"]}
    for t in build_find(dump)["top_notes"]:
        src = rows[(t["comp_id"], t["benefit_cd"])]
        assert (t["qual_desc_ctnt"], t["note_ctnt"]) == (src["qual_desc_ctnt"], src["note_ctnt"])


def test_코드별_설명은_번들의_그_코드_행_전부():
    dump = ReferenceBundle.model_validate(_find_bundle()).model_dump()
    notes = build_notes(dump)
    codes = {b["benefit_cd"] for c in dump["companies"] for b in c["benefits"]}
    assert set(notes) == codes
    for cd, n in notes.items():
        ReferenceNotes.model_validate(n)
        want = [{"comp_id": c["comp_id"], "qual_desc_ctnt": b["qual_desc_ctnt"], "note_ctnt": b["note_ctnt"]}
                for c in dump["companies"] for b in c["benefits"] if b["benefit_cd"] == cd]
        assert n["notes"] == want, cd
    assert [x["comp_id"] for x in notes["solo_code"]["notes"]] == [5], "한 회사에만 있는 코드"


def test_find_자르기_출력_키는_모델_필드와_정확히_같다():
    dump = ReferenceBundle.model_validate(_find_bundle()).model_dump()
    find = build_find(dump)
    assert set(find) == set(ReferenceFind.model_fields)
    find["top_notes"][0]["새_키"] = 1
    with pytest.raises(ValidationError):
        ReferenceFind.model_validate(find)


@pytest.mark.asyncio
async def test_find_와_notes_도_같은_조립에서_나온다(client, find_stub):
    for path in ("/api/v1/reference/all", "/api/v1/reference/index", "/api/v1/reference/find", "/api/v1/reference/notes/meal"):
        assert (await client.get(path)).status_code == 200, path
    assert find_stub["calls"] == 1


@pytest.mark.asyncio
async def test_all_바이트는_find_추가_뒤에도_같다(client, find_stub):
    r = await client.get("/api/v1/reference/all")
    legacy = json.dumps(ReferenceBundle.model_validate(_find_bundle()).model_dump(), ensure_ascii=False).encode("utf-8")
    assert r.content == legacy


@pytest.mark.asyncio
async def test_find_응답_계약(client, find_stub):
    r = await client.get("/api/v1/reference/find")
    assert r.headers["content-type"] == "application/json; charset=utf-8"
    assert r.headers["cache-control"] == "public, max-age=3600"
    body = r.json()
    ReferenceFind.model_validate(body)
    assert [c["comp_id"] for c in body["companies"]] == list(range(1, 41))
    assert len(r.content) < len((await client.get("/api/v1/reference/all")).content)


@pytest.mark.asyncio
async def test_모든_코드의_notes_는_번들_행_설명과_같다(client, find_stub):
    bundle = (await client.get("/api/v1/reference/all")).json()
    codes = sorted({b["benefit_cd"] for c in bundle["companies"] for b in c["benefits"]})
    assert "solo_code" in codes
    for cd in codes:
        r = await client.get(f"/api/v1/reference/notes/{cd}")
        assert r.status_code == 200, cd
        assert r.headers["cache-control"] == "public, max-age=3600"
        body = r.json()
        assert body["benefit_cd"] == cd
        want = [{"comp_id": c["comp_id"], "qual_desc_ctnt": b["qual_desc_ctnt"], "note_ctnt": b["note_ctnt"]}
                for c in bundle["companies"] for b in c["benefits"] if b["benefit_cd"] == cd]
        assert body["notes"] == want, cd


@pytest.mark.asyncio
async def test_notes_없는_코드_404_형식_틀리면_422(client, find_stub):
    assert (await client.get("/api/v1/reference/notes/no_such_code")).status_code == 404
    for bad in ("Meal", "me%20al", "a-b", "x" * 65):
        assert (await client.get(f"/api/v1/reference/notes/{bad}")).status_code == 422, bad


@pytest.mark.asyncio
async def test_find_notes_HEAD_허용_본문_없음(client, find_stub):
    for path in ("/api/v1/reference/find", "/api/v1/reference/notes/meal"):
        resp = await client.head(path)
        assert resp.status_code == 200 and resp.content == b""
        assert resp.headers.get("cache-control") == "public, max-age=3600"


@pytest.mark.asyncio
async def test_승인_반영_뒤_find_와_notes_도_새_값(client, find_stub):
    assert (await client.get("/api/v1/reference/notes/solo_code")).json()["notes"][0]["qual_desc_ctnt"] == "이 회사에만"
    find_stub["bundle"]["companies"][4]["benefits"][0]["qual_desc_ctnt"] = "바뀐 설명"
    find_stub["bundle"]["companies"][0]["comp_nm"] = "KT(개명)"
    assert (await client.get("/api/v1/reference/notes/solo_code")).json()["notes"][0]["qual_desc_ctnt"] == "이 회사에만"  # 캐시 안
    client.app.state.reference_cache.clear()
    assert (await client.get("/api/v1/reference/notes/solo_code")).json()["notes"][0]["qual_desc_ctnt"] == "바뀐 설명"
    assert (await client.get("/api/v1/reference/find")).json()["companies"][0]["comp_nm"] == "KT(개명)"
    assert find_stub["calls"] == 2
