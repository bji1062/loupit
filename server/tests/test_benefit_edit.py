"""SP-AUTH-9·10 복지 편집·편집 이력 공개 조회 (AB-*, AH-*, T-13.10·T-13.11).

httpx ASGITransport + 인메모리 참여 스토어(무 실 DB). 배지 서버 강제·낙관적 동시성
(base_dtm)·본체+이력 원자 트랜잭션·익명 공개 이력 조회를 라우트 계약으로 검증한다.
회사 SQL용 conftest.fake_data 와 독립(참여 SQL 전용 스텁).
"""
from __future__ import annotations

from datetime import datetime, timedelta

import httpx
import pytest
import pytest_asyncio

from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn
from server.services import benefit_edit as svc

_AUTH = {"Cookie": "loupit_sid=SESSIONRAW"}  # benefit_env 가 심은 유효 세션(회사 10 재직 인증)


# ── 순수 유닛 (모델·헬퍼) ─────────────────────────────────────────────────────
def test_version_token_prefers_mod_over_ins():
    ins = datetime(2026, 1, 1, 0, 0, 0)
    mod = datetime(2026, 2, 2, 3, 4, 5)
    base = {"benefit_nm": "a", "benefit_amt": 1}
    assert svc._version_token({**base, "INS_DTM": ins, "MOD_DTM": None}).startswith(ins.isoformat())
    assert svc._version_token({**base, "INS_DTM": ins, "MOD_DTM": mod}).startswith(mod.isoformat())


def test_version_token_changes_when_content_changes_same_dtm():
    """같은 초(같은 dtm)라도 내용이 바뀌면 토큰이 달라진다(초해상도 CAS 보강, lost-update 차단)."""
    ins = datetime(2026, 1, 1, 0, 0, 0)
    t_a = svc._version_token({"INS_DTM": ins, "MOD_DTM": None, "benefit_nm": "a", "benefit_amt": 1})
    t_b = svc._version_token({"INS_DTM": ins, "MOD_DTM": None, "benefit_nm": "a", "benefit_amt": 2})
    assert t_a != t_b


def test_snapshot_has_core_benefit_fields():
    snap = svc._snapshot(
        {"benefit_cd": "meal", "benefit_nm": "식대", "benefit_ctgr_cd": "compensation",
         "benefit_amt": 220, "qual_yn": 0, "note_ctnt": None, "badge_cd": "verified", "amt_source": "estimated"}
    )
    assert snap["benefit_cd"] == "meal" and snap["benefit_nm"] == "식대"
    assert snap["benefit_amt"] == 220 and snap["badge_cd"] == "verified"


def test_create_model_qual_with_amount_rejected():
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="gym", benefit_nm="헬스장", benefit_ctgr_cd="health",
                        benefit_amt=100, qual_yn=True)


def test_create_model_bad_category_rejected():
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="meal", benefit_nm="식대", benefit_ctgr_cd="not_a_category", benefit_amt=1)


def test_create_model_bad_benefit_cd_rejected():
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="Meal Card!", benefit_nm="식대", benefit_ctgr_cd="compensation", benefit_amt=1)


def test_create_model_blank_name_rejected():
    """공백-only 이름은 Field(min_length=1)를 통과하나 strip 후 빈 문자열이라 거부(#5)."""
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="meal", benefit_nm="   ", benefit_ctgr_cd="compensation", benefit_amt=1)


def test_update_model_requires_base_dtm():
    with pytest.raises(ValueError):
        BenefitUpdateIn(benefit_nm="식대", benefit_amt=1)  # base_dtm 누락 → 검증 실패


# ── 라우트 계약 픽스처 ────────────────────────────────────────────────────────
@pytest_asyncio.fixture
async def benefit_env(monkeypatch):
    """로그인 회원 MBR_ID=1(회사 10 재직 인증) + 복지/이력 SQL 인메모리 스텁.

    회사 10·20 존재. 회원 1은 회사 10만 재직 인증(회사 20 편집 시 403). 회원 9는 세션 없음.
    """
    from server import database
    from server.main import create_app
    from server.services import session as session_svc

    store = {
        "sessions": [{"MBR_ID": 1, "TOKEN_HASH_VAL": session_svc._hash_token("SESSIONRAW"), "revoked": False}],
        "verifications": [{"MBR_ID": 1, "COMP_ID": 10, "revoked": False}],
        "companies": {10, 20},
        "members": {1: "직장인-000001", 7: "탈퇴예정"},
        "benefits": [],   # TCOMPANY_BENEFIT 행
        "edit_logs": [],  # TBENEFIT_EDIT_LOG 행
        "_bseq": 0, "_lseq": 0, "_clock": 0,
    }

    def _tick() -> datetime:
        """단조 증가 시각 — INS_DTM/MOD_DTM 토큰이 편집마다 반드시 달라지게 한다."""
        store["_clock"] += 1
        return datetime(2026, 1, 1, 0, 0, 0) + timedelta(seconds=store["_clock"])

    def _benefit_by_id(bid):
        return next((b for b in store["benefits"] if b["BENEFIT_ID"] == bid), None)

    async def _fetch_one(sql, params=()):
        if "FROM TSESSION" in sql and "TOKEN_HASH_VAL" in sql:
            for s in store["sessions"]:
                if s["TOKEN_HASH_VAL"] == params[0] and not s["revoked"]:
                    return {"MBR_ID": s["MBR_ID"]}
            return None
        if "FROM TEMPLOY_VERIFICATION" in sql:  # active_verification: (mbr, comp)
            for v in store["verifications"]:
                if v["MBR_ID"] == params[0] and v["COMP_ID"] == params[1] and not v["revoked"]:
                    return {"EMPLOY_VRF_ID": 1, "COMP_ID": v["COMP_ID"]}
            return None
        if "COUNT(*)" in sql and "TBENEFIT_EDIT_LOG" in sql:  # _daily_count: (mbr, comp)
            n = sum(1 for l in store["edit_logs"] if l["ACTOR_MBR_ID"] == params[0] and l["COMP_ID"] == params[1])
            return {"n": n}
        if "FROM TCOMPANY WHERE COMP_ID" in sql:  # 회사 존재(404 게이트): (comp,)
            return {"COMP_ID": params[0]} if params[0] in store["companies"] else None
        raise AssertionError(f"benefit fake: unmatched fetch_one: {sql!r}")

    async def _fetch_all(sql, params=()):
        if "FROM TBENEFIT_EDIT_LOG" in sql:  # list_edits: (comp[, before], limit)
            comp = params[0]
            before = params[1] if len(params) == 3 else None
            limit = params[-1]
            rows = [l for l in store["edit_logs"] if l["COMP_ID"] == comp]
            if before is not None:
                rows = [l for l in rows if l["EDIT_LOG_ID"] < before]
            rows = sorted(rows, key=lambda l: l["EDIT_LOG_ID"], reverse=True)[:limit]
            return [
                {"nickname": store["members"].get(l["ACTOR_MBR_ID"]),  # 탈퇴 후에도 닉네임 존치
                 "edit_type": l["EDIT_TYPE_CD"], "before_val": l["BEFORE_VAL"], "after_val": l["AFTER_VAL"],
                 "edit_note": l["EDIT_NOTE_CTNT"], "dtm": l["INS_DTM"]}
                for l in rows
            ]
        if "FROM TCOMPANY_BENEFIT WHERE COMP_ID" in sql:  # fetch_company_benefits: (comp,)
            comp = params[0]
            return [_public_row(b) for b in store["benefits"] if b["COMP_ID"] == comp]
        raise AssertionError(f"benefit fake: unmatched fetch_all: {sql!r}")

    def _public_row(b):
        return {k: b.get(k) for k in (
            "benefit_cd", "benefit_nm", "benefit_amt", "benefit_ctgr_cd", "badge_cd", "amt_source",
            "qual_yn", "qual_desc_ctnt", "note_ctnt", "verified_dtm", "expires_dtm",
            "badge_src_cd", "badge_src_url_ctnt", "sort_order_no", "INS_DTM", "MOD_DTM", "BENEFIT_ID")}

    class _Cur:
        def __init__(self):
            self.lastrowid = None
            self._result = None

        async def __aenter__(self):
            return self

        async def __aexit__(self, *e):
            return False

        async def execute(self, sql, params=()):
            if "INSERT INTO TCOMPANY_BENEFIT" in sql:
                comp, cd = params[0], params[1]
                if any(b["COMP_ID"] == comp and b["benefit_cd"] == cd for b in store["benefits"]):
                    from pymysql.err import IntegrityError
                    raise IntegrityError(1062, "Duplicate uq_comp_benefit")
                store["_bseq"] += 1
                # params: comp, cd, nm, ctgr, amt, qual, note, amt_source, ins_id
                store["benefits"].append({
                    "BENEFIT_ID": store["_bseq"], "COMP_ID": comp, "benefit_cd": cd, "benefit_nm": params[2],
                    "benefit_ctgr_cd": params[3], "benefit_amt": params[4], "qual_yn": params[5],
                    "note_ctnt": params[6], "amt_source": params[7], "qual_desc_ctnt": None,
                    "badge_cd": "verified", "badge_src_cd": "user_report", "badge_src_url_ctnt": None,
                    "verified_dtm": _tick(), "expires_dtm": _tick(), "sort_order_no": 0,  # create=재검증(UTC_TIMESTAMP·+18mo)
                    "INS_DTM": _tick(), "MOD_DTM": None,
                })
                self.lastrowid = store["_bseq"]
                return 1
            if "SELECT" in sql and "FROM TCOMPANY_BENEFIT" in sql and "BENEFIT_ID=%s" in sql:
                if "COMP_ID=%s" in sql:  # FOR UPDATE (update path): (bid, comp)
                    b = _benefit_by_id(params[0])
                    self._result = _public_row(b) if b and b["COMP_ID"] == params[1] else None
                else:  # 삽입/갱신 직후 재조회: (bid,)
                    b = _benefit_by_id(params[0])
                    self._result = _public_row(b) if b else None
                return 1
            if "UPDATE TCOMPANY_BENEFIT" in sql:
                # params: nm, amt, qual, amt_source, note, mod_id, bid, comp
                bid, comp = params[-2], params[-1]
                b = _benefit_by_id(bid)
                if b and b["COMP_ID"] == comp:
                    b.update({"benefit_nm": params[0], "benefit_amt": params[1], "qual_yn": params[2],
                              "amt_source": params[3], "note_ctnt": params[4], "badge_cd": "verified",
                              "badge_src_cd": "user_report", "MOD_DTM": _tick()})
                    if "VERIFIED_DTM=UTC_TIMESTAMP()" in sql:  # 편집=재검증(신선도 리셋)
                        b["verified_dtm"] = _tick()
                        b["expires_dtm"] = _tick()
                return 1
            if "INSERT INTO TBENEFIT_EDIT_LOG" in sql:
                store["_lseq"] += 1
                # params: bid, comp, actor, edit_type, before_json, after_json, note
                store["edit_logs"].append({
                    "EDIT_LOG_ID": store["_lseq"], "BENEFIT_ID": params[0], "COMP_ID": params[1],
                    "ACTOR_MBR_ID": params[2], "EDIT_TYPE_CD": params[3], "BEFORE_VAL": params[4],
                    "AFTER_VAL": params[5], "EDIT_NOTE_CTNT": params[6], "INS_DTM": _tick(),
                })
                return 1
            raise AssertionError(f"benefit fake cursor: unmatched: {sql!r}")

        async def fetchone(self):
            return self._result

    class _Conn:
        def cursor(self):
            return _Cur()

    class _Txn:
        async def __aenter__(self):
            return _Conn()

        async def __aexit__(self, *e):
            return False

    async def _noop():
        return None

    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    monkeypatch.setattr(database, "transaction", lambda: _Txn())
    monkeypatch.setattr(database, "init_pool", _noop)
    monkeypatch.setattr(database, "close_pool", _noop)

    app = create_app()
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t",
                                 headers={"X-Loupit-Client": "web"}) as c:  # CSRF 기본 통과
        yield c, store


def _payload(cd="meal", nm="식대", ctgr="compensation", amt=220, qual=False, note=None, edit_note="추가"):
    p = {"benefit_cd": cd, "benefit_nm": nm, "benefit_ctgr_cd": ctgr, "qual_yn": qual, "edit_note": edit_note}
    if amt is not None:
        p["benefit_amt"] = amt
    if note is not None:
        p["note_ctnt"] = note
    return p


# ── AB — 복지 등록·수정 ───────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_AB1_create_requires_session_401(benefit_env):
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits", json=_payload())  # 쿠키 없음
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_AB1_create_requires_employment_403(benefit_env):
    """회사 20은 재직 인증 없음 → 403(IDOR 방어)."""
    c, store = benefit_env
    r = await c.post("/api/v1/companies/20/benefits", json=_payload(), headers=_AUTH)
    assert r.status_code == 403
    assert store["benefits"] == []


@pytest.mark.asyncio
async def test_AB2_create_forces_verified_badge_and_appends_log(benefit_env):
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits", json=_payload(amt=220), headers=_AUTH)
    assert r.status_code == 201
    body = r.json()
    b = body["benefit"]
    assert b["badge_cd"] == "verified"          # 서버 강제(사용자 지정 불가)
    assert b["amt_source"] == "estimated"        # 금액 행 → estimated
    assert b["badge_src_cd"] == "user_report"
    assert b["base_dtm"]                          # 낙관적 동시성 토큰 노출
    assert isinstance(body["benefits"], list) and len(body["benefits"]) == 1
    assert r.headers.get("cache-control") == "no-store"
    # 편집 이력 append(create)
    assert len(store["edit_logs"]) == 1
    log = store["edit_logs"][0]
    assert log["EDIT_TYPE_CD"] == "create" and log["BEFORE_VAL"] is None and log["ACTOR_MBR_ID"] == 1


@pytest.mark.asyncio
async def test_AB2_create_qualitative_nulls_amount_and_source_none(benefit_env):
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits",
                     json=_payload(cd="free_snack", nm="간식", ctgr="perks", amt=None, qual=True), headers=_AUTH)
    assert r.status_code == 201
    b = r.json()["benefit"]
    assert b["qual_yn"] is True
    assert b["benefit_amt"] is None
    assert b["amt_source"] == "none"             # 정성 행 → none(DC-9·DC-10)


@pytest.mark.asyncio
async def test_AB2_create_nonqual_no_amount_source_none(benefit_env):
    """비정성이지만 금액 미기재 → amt_source='none'(NULL 금액에 estimated 금지, DC-10·DEC-2, #2)."""
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits",
                     json=_payload(cd="flexwork", nm="유연근무", ctgr="flexibility", amt=None, qual=False), headers=_AUTH)
    assert r.status_code == 201
    b = r.json()["benefit"]
    assert b["qual_yn"] is False and b["benefit_amt"] is None and b["amt_source"] == "none"


@pytest.mark.asyncio
async def test_AB6_create_qual_with_amount_422(benefit_env):
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits",
                     json=_payload(cd="gym", nm="헬스", ctgr="health", amt=50, qual=True), headers=_AUTH)
    assert r.status_code == 422
    assert store["benefits"] == []


@pytest.mark.asyncio
async def test_AB_create_duplicate_code_409(benefit_env):
    c, store = benefit_env
    a = await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    assert a.status_code == 201
    dup = await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", nm="식대2"), headers=_AUTH)
    assert dup.status_code == 409
    assert len(store["benefits"]) == 1           # 중복 삽입 안 됨(원자 롤백)


@pytest.mark.asyncio
async def test_AB5_daily_limit_429(benefit_env, monkeypatch):
    c, store = benefit_env

    async def _hot(mbr, comp):
        return 999  # 일일 상한 초과 상태

    monkeypatch.setattr(svc, "_daily_count", _hot)
    r = await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    assert r.status_code == 429
    assert store["benefits"] == []


@pytest.mark.asyncio
async def test_AB4_create_atomic_no_log_when_insert_fails(benefit_env):
    """본체 INSERT 실패(중복) 시 편집 이력도 남지 않는다(원자 트랜잭션)."""
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)  # 409
    assert len(store["edit_logs"]) == 1          # 성공 1건분만(실패는 이력 0)


@pytest.mark.asyncio
async def test_AB3_update_optimistic_concurrency(benefit_env):
    c, store = benefit_env
    created = (await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)).json()
    bid = store["benefits"][0]["BENEFIT_ID"]
    base = created["benefit"]["base_dtm"]

    # 올바른 base_dtm → 200, 이력 update append
    ok = await c.put(f"/api/v1/companies/10/benefits/{bid}",
                     json={"base_dtm": base, "benefit_nm": "식대(수정)", "benefit_amt": 300}, headers=_AUTH)
    assert ok.status_code == 200
    assert ok.json()["benefit"]["benefit_nm"] == "식대(수정)"
    assert ok.json()["benefit"]["badge_cd"] == "verified"
    assert ok.json()["benefit"]["verified_dtm"] is not None                              # 편집=재검증(#3)
    assert ok.json()["benefit"]["verified_dtm"] != created["benefit"]["verified_dtm"]    # 신선도 리셋
    assert store["benefits"][0]["benefit_amt"] == 300
    assert store["edit_logs"][-1]["EDIT_TYPE_CD"] == "update"
    assert store["edit_logs"][-1]["BEFORE_VAL"] is not None  # before 스냅샷 존재

    # 낡은(선점된) base_dtm → 409 + 현재 행 동봉
    stale = await c.put(f"/api/v1/companies/10/benefits/{bid}",
                        json={"base_dtm": base, "benefit_nm": "덮어쓰기시도", "benefit_amt": 1}, headers=_AUTH)
    assert stale.status_code == 409
    assert stale.json()["current_benefit"]["benefit_amt"] == 300  # 현재값(선점자 반영)
    assert store["benefits"][0]["benefit_nm"] == "식대(수정)"       # 덮어쓰기 안 됨


@pytest.mark.asyncio
async def test_AB3_update_missing_base_dtm_422(benefit_env):
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    bid = store["benefits"][0]["BENEFIT_ID"]
    r = await c.put(f"/api/v1/companies/10/benefits/{bid}", json={"benefit_nm": "x"}, headers=_AUTH)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_AB3_update_nonexistent_404(benefit_env):
    c, store = benefit_env
    r = await c.put("/api/v1/companies/10/benefits/9999",
                    json={"base_dtm": "2026-01-01T00:00:01", "benefit_nm": "x", "benefit_amt": 1}, headers=_AUTH)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_AB1_update_requires_employment_403(benefit_env):
    c, store = benefit_env
    r = await c.put("/api/v1/companies/20/benefits/1",
                    json={"base_dtm": "2026-01-01T00:00:01", "benefit_nm": "x", "benefit_amt": 1}, headers=_AUTH)
    assert r.status_code == 403


# ── 편집용 조회 — base_dtm 부트스트랩 (#1, FR-109 수정 도달성) ──────────────────
@pytest.mark.asyncio
async def test_read_for_edit_requires_session_401(benefit_env):
    c, store = benefit_env
    r = await c.get("/api/v1/companies/10/benefits")  # 무쿠키
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_read_for_edit_requires_employment_403(benefit_env):
    c, store = benefit_env
    r = await c.get("/api/v1/companies/20/benefits", headers=_AUTH)  # 회사 20 재직 없음
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_read_for_edit_returns_benefits_with_base_dtm_no_store(benefit_env):
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)
    r = await c.get("/api/v1/companies/10/benefits", headers=_AUTH)
    assert r.status_code == 200
    assert r.headers.get("cache-control") == "no-store"
    benefits = r.json()["benefits"]
    assert len(benefits) == 1 and benefits[0]["base_dtm"]  # 편집 토큰 동봉


@pytest.mark.asyncio
async def test_read_for_edit_exposes_benefit_id_for_put_target(benefit_env):
    """편집용 조회가 각 복지의 benefit_id 를 동봉한다 — PUT 대상 지정에 필요(프론트 편집 폼 도달성).

    공개 계약(Benefit·/reference·GET /companies/{id})은 내부 PK 를 감추지만(§02), 인증·no-store
    편집 경로는 PUT /benefits/{benefit_id} 의 대상을 클라이언트가 알아야 하므로 benefit_id 를 노출한다."""
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)
    r = await c.get("/api/v1/companies/10/benefits", headers=_AUTH)
    b = r.json()["benefits"][0]
    assert isinstance(b.get("benefit_id"), int) and b["benefit_id"] >= 1


@pytest.mark.asyncio
async def test_create_response_benefit_exposes_benefit_id(benefit_env):
    """등록 응답의 benefit 도 benefit_id 동봉 — 방금 등록한 복지를 곧바로 수정(PUT)할 수 있게."""
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)
    assert isinstance(r.json()["benefit"].get("benefit_id"), int)


@pytest.mark.asyncio
async def test_read_for_edit_roundtrip_to_put(benefit_env):
    """조회한 benefit_id·base_dtm 으로 곧바로 수정(PUT) → 200 (기존 복지 수정 도달성, #1).

    benefit_id 를 테스트 셋업(store)이 아니라 **API 응답**에서 얻어 프론트 편집 폼의 실제 경로를 검증한다."""
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)
    read = await c.get("/api/v1/companies/10/benefits", headers=_AUTH)
    row = read.json()["benefits"][0]
    bid, base = row["benefit_id"], row["base_dtm"]
    ok = await c.put(f"/api/v1/companies/10/benefits/{bid}",
                     json={"base_dtm": base, "benefit_nm": "식대(정정)", "benefit_amt": 250}, headers=_AUTH)
    assert ok.status_code == 200


@pytest.mark.asyncio
async def test_create_response_benefits_carry_base_dtm(benefit_env):
    """create/update 응답의 benefits[] 각 항목도 base_dtm 동봉(편집 준비)."""
    c, store = benefit_env
    r = await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal", amt=220), headers=_AUTH)
    assert all("base_dtm" in b for b in r.json()["benefits"])


# ── AH — 편집 이력 공개 조회 ──────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_AH1_edits_public_anonymous_200(benefit_env):
    """익명(무 쿠키)도 편집 이력 열람 가능."""
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    r = await c.get("/api/v1/companies/10/edits")  # 쿠키 없음
    assert r.status_code == 200
    items = r.json()
    assert isinstance(items, list) and len(items) == 1
    assert items[0]["edit_type"] == "create"
    assert items[0]["nickname"] == "직장인-000001"


@pytest.mark.asyncio
async def test_AH2_edits_expose_nickname_only_no_mbr_id_or_email(benefit_env):
    c, store = benefit_env
    await c.post("/api/v1/companies/10/benefits", json=_payload(cd="meal"), headers=_AUTH)
    r = await c.get("/api/v1/companies/10/edits")
    raw = r.text
    assert "MBR_ID" not in raw and "mbr_id" not in raw
    assert "ACTOR_MBR_ID" not in raw
    item = r.json()[0]
    assert set(item.keys()) <= {"nickname", "edit_type", "before", "after", "edit_note", "dtm"}


@pytest.mark.asyncio
async def test_AH3_edits_note_returned_as_data_not_executed(benefit_env):
    """편집 노트의 특수문자는 데이터로 그대로 반환(파라미터 바인딩 안전, 이스케이프는 표시 계층)."""
    c, store = benefit_env
    payload = _payload(cd="meal", edit_note="<script>alert(1)</script>")
    await c.post("/api/v1/companies/10/benefits", json=payload, headers=_AUTH)
    r = await c.get("/api/v1/companies/10/edits")
    assert r.json()[0]["edit_note"] == "<script>alert(1)</script>"  # 원문 데이터 보존(무손상)


@pytest.mark.asyncio
async def test_AH4_withdrawn_contributor_nickname_retained(benefit_env):
    """탈퇴 기여자도 닉네임은 존치되어 이력에 표시(이메일만 파기)."""
    c, store = benefit_env
    # 회원 7이 편집한 이력을 심고(회원 7은 이후 탈퇴했지만 닉네임 존치)
    store["edit_logs"].append({
        "EDIT_LOG_ID": 1, "BENEFIT_ID": 1, "COMP_ID": 10, "ACTOR_MBR_ID": 7,
        "EDIT_TYPE_CD": "update", "BEFORE_VAL": None, "AFTER_VAL": None,
        "EDIT_NOTE_CTNT": "기여", "INS_DTM": datetime(2026, 1, 1),
    })
    r = await c.get("/api/v1/companies/10/edits")
    assert r.json()[0]["nickname"] == "탈퇴예정"


@pytest.mark.asyncio
async def test_AH5_edits_no_store(benefit_env):
    c, store = benefit_env
    r = await c.get("/api/v1/companies/10/edits")
    assert r.status_code == 200
    assert r.headers.get("cache-control") == "no-store"


@pytest.mark.asyncio
async def test_AH_edits_unknown_company_404(benefit_env):
    c, store = benefit_env
    r = await c.get("/api/v1/companies/999/edits")
    assert r.status_code == 404
