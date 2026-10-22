"""복지 등록·수정 운영자 확인 큐 — **실 DB** 요청 → 승인·거절 흐름 (BR-1~BR-30, 2026-10-21 사용자 결정).

회원의 복지 등록·수정은 바로 반영되지 않는다. 요청 한 줄(`TBENEFIT_EDIT_REQUEST`)만 만들고, 운영자가 콘솔에서
승인할 때 본체(`TCOMPANY_BENEFIT`)와 편집 이력(`TBENEFIT_EDIT_LOG`)이 한 트랜잭션으로 바뀐다. 여기서 재는 것:

- 요청 단계: 202 · 본체/이력 무변경 · 표준 코드 밖 422 · 이미 있는 코드 409 · 같은 대상 대기 중 409 · 하루 한도는 **요청 수**
- 회원 화면: 편집용 목록에 **내 요청만**(대기 전부 + 최근 30일 결정분, 거절 사유 포함)
- 승인: create(고른 코드 · 코드에서 정한 카테고리 · verified 배지 · 이력 편집자=회원) / update(반영 · 이력) /
  stale · target_gone · not_pending · 이미 있는 코드 → 409, 결정자는 세션에서
- 거절: 본체 무변경 · 사유 저장
- 공개 이력의 편집 주체: 운영자 → 「운영자」, 탈퇴 → 「(탈퇴)」
- `GET /benefit-codes` 모양 · LABEL_OVERRIDE 적용, 운영 요약 메일의 새 큐, 마이그레이션, `--fresh` 가드

httpx ASGITransport 로 앱을 직접 두드린다(세션 쿠키·CSRF 헤더·의존성 순서까지 실제 경로). 기본 주소가 루프백 `127.0.0.1:8000`
이라 콘솔 관문(터널 입구)을 통과한다. ⚠ `DB_NAME` 이 가리키는 DB(`loupit_test`)에 실제로 쓴다 — `br-` 접두 행만 만들고 치운다.
"""
from __future__ import annotations

import asyncio
import json
import re
import sys
from pathlib import Path
from types import SimpleNamespace

import httpx
import pytest
import pytest_asyncio

from server import database, ops
from server.cache import TTLCache
from server.models.benefit_edit import BenefitCreateIn
from server.tests.conftest import MIGRATIONS_DIR, SCHEMA_SQL, _split_sql_statements

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))
import load as seed_load  # noqa: E402

OP_EMAIL = "br-operator@example.com"
CSRF = {"X-Loupit-Client": "test"}
COMP_A, COMP_B = "br-alpha", "br-beta"
MIGRATION = MIGRATIONS_DIR / "20261022_benefit_edit_request.sql"


async def _clean() -> None:
    comps = [r["COMP_ID"] for r in await database.fetch_all(
        "SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM IN (%s, %s)", (COMP_A, COMP_B))]
    if comps:
        marks = ",".join(["%s"] * len(comps))
        await database.execute(f"DELETE FROM TBENEFIT_EDIT_LOG WHERE COMP_ID IN ({marks})", tuple(comps))
        await database.execute(f"DELETE FROM TCOMPANY WHERE COMP_ID IN ({marks})", tuple(comps))
    await database.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE 'br-%%'")
    await database.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_CD='br_tp'")


async def _add_benefit(comp: int, cd: str, nm: str, ctgr: str, amt: int | None = 100, qual: bool = False) -> int:
    await database.execute(
        "INSERT INTO TCOMPANY_BENEFIT (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD, QUAL_YN, "
        "BADGE_CD, AMT_SOURCE_CD, BADGE_SRC_CD) VALUES (%s,%s,%s,%s,%s,%s,'official',%s,'scrape_official')",
        (comp, cd, nm, amt, ctgr, qual, "stated" if amt is not None else "none"))
    return (await database.fetch_one(
        "SELECT BENEFIT_ID FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s", (comp, cd)))["BENEFIT_ID"]


@pytest_asyncio.fixture
async def br(schema_db, monkeypatch):
    """운영자 · alice · bob(회사 A 재직) · carol(재직 없음) · 회사 A(meal 1개) · 회사 B(표준 코드 공급용 4개)."""
    from server.config import get_settings
    from server.main import create_app
    from server.services import session as session_svc

    await database.init_pool()
    monkeypatch.setattr(get_settings(), "operator_emails", OP_EMAIL)
    await _clean()
    try:
        await database.execute(
            "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES "
            "(%s,'br-op'), ('br-alice@example.com','br-alice'), ('br-bob@example.com','br-bob'), "
            "('br-carol@example.com','br-carol')", (OP_EMAIL,))
        ids = {r["NICKNAME_NM"]: r["MBR_ID"] for r in await database.fetch_all(
            "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE NICKNAME_NM LIKE 'br-%%'")}
        await database.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES ('br_tp', '테스트유형')")
        tp = (await database.fetch_one("SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='br_tp'"))["COMP_TP_ID"]
        for eng, nm in ((COMP_A, "요청테스트사A"), (COMP_B, "요청테스트사B")):
            await database.execute("INSERT INTO TCOMPANY (COMP_NM, COMP_ENG_NM, COMP_TP_ID) VALUES (%s,%s,%s)",
                                   (nm, eng, tp))
        comp_a = (await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (COMP_A,)))["COMP_ID"]
        comp_b = (await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (COMP_B,)))["COMP_ID"]
        meal = await _add_benefit(comp_a, "meal", "구내식당", "compensation", 432)
        # 회사 B 가 표준 코드 목록을 공급한다(목록은 모든 회사의 복지에서 파생된다).
        for cd, nm, ctgr in (("gym", "헬스장", "health"), ("book", "도서 지원", "growth"),
                             ("snack", "간식", "perks"), ("transport", "통근 지원", "compensation")):
            await _add_benefit(comp_b, cd, nm, ctgr, 50)
        for who in ("alice", "bob"):
            await database.execute(
                "INSERT INTO TEMPLOY_VERIFICATION (MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM) "
                "VALUES (%s, %s, 'domain', %s, UTC_TIMESTAMP() + INTERVAL 30 DAY)",
                (ids[f"br-{who}"], comp_a, (who[0] * 64)))
        cookies = {n: {"loupit_sid": await session_svc.issue_session(ids[f"br-{n}"])}
                   for n in ("op", "alice", "bob", "carol")}
        app = create_app()
        app.state.reference_cache = TTLCache(3600)
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://127.0.0.1:8000/api/v1") as c:
            yield {"c": c, "ids": ids, "a": comp_a, "b": comp_b, "meal": meal, "ck": cookies, "app": app}
    finally:
        await _clean()
        await database.close_pool()


# ── 호출 보조 ─────────────────────────────────────────────────────────────────

async def _post(br, who, body, comp=None):
    return await br["c"].post(f"/companies/{comp or br['a']}/benefits", json=body, headers=CSRF, cookies=br["ck"][who])


async def _token(br, who="alice") -> str:
    r = await br["c"].get(f"/companies/{br['a']}/benefits", cookies=br["ck"][who])
    return next(b for b in r.json()["benefits"] if b["benefit_id"] == br["meal"])["base_dtm"]


async def _put(br, who, body, bid=None):
    return await br["c"].put(f"/companies/{br['a']}/benefits/{bid or br['meal']}", json=body, headers=CSRF,
                             cookies=br["ck"][who])


async def _count(table: str, where: str = "1=1", params: tuple = ()) -> int:
    return (await database.fetch_one(f"SELECT COUNT(*) AS n FROM {table} WHERE {where}", params))["n"]


async def _bodies(br) -> tuple[int, int]:
    """(본체 행 수, 이력 행 수) — 요청 단계가 둘 다 건드리지 않는지 본다."""
    return (await _count("TCOMPANY_BENEFIT", "COMP_ID=%s", (br["a"],)),
            await _count("TBENEFIT_EDIT_LOG", "COMP_ID=%s", (br["a"],)))


async def _request_id(br, name: str) -> int:
    return (await database.fetch_one(
        "SELECT EDIT_REQUEST_ID AS id FROM TBENEFIT_EDIT_REQUEST WHERE COMP_ID=%s AND BENEFIT_NM=%s "
        "ORDER BY EDIT_REQUEST_ID DESC LIMIT 1", (br["a"], name)))["id"]


async def _approve(br, rid, **body):
    return await br["c"].post(f"/console/benefit-requests/{rid}/approve", json=body, headers=CSRF,
                              cookies=br["ck"]["op"])


async def _reject(br, rid, **body):
    return await br["c"].post(f"/console/benefit-requests/{rid}/reject", json=body, headers=CSRF,
                              cookies=br["ck"]["op"])


# ── BR-1~2: 마이그레이션 ─────────────────────────────────────────────────────────

def test_BR1_마이그레이션의_새_표는_schema_와_같은_DDL_이다():
    def ddl(text: str) -> str:
        m = re.search(r"CREATE TABLE IF NOT EXISTS TBENEFIT_EDIT_REQUEST \(.*?\) ENGINE=InnoDB[^;]*;", text, re.S)
        assert m, "TBENEFIT_EDIT_REQUEST DDL 을 찾지 못했다"
        return m.group(0)

    assert ddl(MIGRATION.read_text(encoding="utf-8")) == ddl(SCHEMA_SQL.read_text(encoding="utf-8"))


def test_BR2_마이그레이션은_칸을_더하고_운영자_이력을_옮기며_재실행해도_같다(schema_db):
    """옛 스키마(ACTOR_KIND_CD 없음)를 만든 뒤 마이그레이션 2회 — 칸 추가 · 운영자 행만 operator · 두 번째는 변화 없음."""
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            cur.execute("DELETE FROM TBENEFIT_EDIT_LOG")
            cur.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES ('br_tp', 't')")
            cur.execute("SELECT LAST_INSERT_ID()")
            tp = cur.fetchone()[0]
            cur.execute("INSERT INTO TCOMPANY (COMP_NM, COMP_ENG_NM, COMP_TP_ID) VALUES ('t', 'br-mig', %s)", (tp,))
            comp = cur.lastrowid
            cur.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES ('br-mig@example.com', 'br-mig')")
            mbr = cur.lastrowid
            cur.execute("ALTER TABLE TBENEFIT_EDIT_LOG DROP COLUMN ACTOR_KIND_CD")  # 옛 스키마로 되돌린다
            rows = [  # (actor, type, note) — 운영자 정정 · 운영자 삭제 · 회원 편집 · 탈퇴 회원 편집(메모가 운영자가 아님)
                (None, "update", "운영자 정정: 금액 오기"), (None, "delete", "반달리즘"),
                (mbr, "update", "운영자라고 적은 회원"), (None, "update", "회원 탈퇴 전 편집"),
            ]
            for actor, typ, note in rows:
                cur.execute(
                    "INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, EDIT_NOTE_CTNT) "
                    "VALUES (%s,%s,%s,%s)", (comp, actor, typ, note))
            conn.commit()

            def run_migration():
                for stmt in _split_sql_statements(MIGRATION.read_text(encoding="utf-8")):
                    cur.execute(stmt)
                conn.commit()

            def kinds():
                cur.execute("SELECT ACTOR_KIND_CD FROM TBENEFIT_EDIT_LOG WHERE COMP_ID=%s ORDER BY EDIT_LOG_ID", (comp,))
                return [r[0] for r in cur.fetchall()]

            run_migration()
            assert kinds() == ["operator", "operator", "member", "member"]
            cur.execute("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() "
                        "AND TABLE_NAME='TBENEFIT_EDIT_REQUEST'")
            assert cur.fetchone()[0] == 1
            run_migration()  # 재실행 안전
            assert kinds() == ["operator", "operator", "member", "member"]
            cur.execute("DELETE FROM TBENEFIT_EDIT_LOG WHERE COMP_ID=%s", (comp,))
            cur.execute("DELETE FROM TCOMPANY WHERE COMP_ID=%s", (comp,))
            cur.execute("DELETE FROM TMEMBER WHERE MBR_ID=%s", (mbr,))
            cur.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_CD='br_tp'")
        conn.commit()
    finally:
        conn.close()


# ── BR-3~: 요청 단계 ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR3_등록은_202_요청만_만들고_본체와_이력을_건드리지_않는다(br):
    before = await _bodies(br)
    r = await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "사내 헬스장", "benefit_amt": 120,
                                  "qual_yn": False, "note_ctnt": "월 1만원", "edit_note": "공지 확인"})
    assert r.status_code == 202, r.text
    assert r.headers["cache-control"] == "no-store"
    req = r.json()["request"]
    assert req["status"] == "pending" and req["type"] == "create" and req["benefit_nm"] == "사내 헬스장"
    assert await _bodies(br) == before, "요청 단계에서 본체나 이력이 바뀌었다"
    row = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s", (req["request_id"],))
    assert row["MBR_ID"] == br["ids"]["br-alice"] and row["BENEFIT_CD"] == "gym" and row["BENEFIT_AMT"] == 120
    assert row["STATUS_CD"] == "pending" and row["DECIDED_BY_ID"] is None
    # 대기 요청은 공개 번들에 없다 — 본체가 그대로라 공개 경로(참조 번들)가 볼 수 없다.
    from server.services.reference import build_reference_bundle
    async with database.get_pool().acquire() as conn:
        bundle = await build_reference_bundle(conn)
    names = {b["benefit_nm"] for c in bundle["companies"] for b in c["benefits"]}
    assert "사내 헬스장" not in names


@pytest.mark.asyncio
async def test_BR4_목록에_없음_요청은_코드_없이_들어가고_같은_이름_대기는_막힌다(br):
    r = await _post(br, "alice", {"benefit_nm": "특이한 복지"})
    assert r.status_code == 202, r.text
    assert (await database.fetch_one("SELECT BENEFIT_CD FROM TBENEFIT_EDIT_REQUEST"))["BENEFIT_CD"] is None
    again = await _post(br, "alice", {"benefit_nm": "특이한 복지"})
    assert again.status_code == 409
    other = await _post(br, "alice", {"benefit_nm": "또 다른 복지"})  # 이름이 다르면 다른 대상
    assert other.status_code == 202


@pytest.mark.asyncio
async def test_BR5_표준_코드_밖은_422_이미_있는_코드는_409_옛_클라이언트의_카테고리는_무시(br):
    outside = await _post(br, "alice", {"benefit_cd": "not_a_standard_code", "benefit_nm": "x"})
    assert outside.status_code == 422
    bad_shape = await _post(br, "alice", {"benefit_cd": "Bad Code!", "benefit_nm": "x"})
    assert bad_shape.status_code == 422
    exists = await _post(br, "alice", {"benefit_cd": "meal", "benefit_nm": "식대 또"})  # 회사 A 에 이미 있다
    assert exists.status_code == 409 and "수정" in exists.json()["detail"]
    legacy = await _post(br, "alice", {"benefit_cd": "book", "benefit_nm": "도서", "benefit_ctgr_cd": "zzz-garbage"})
    assert legacy.status_code == 202, "옛 edit.js 가 카테고리를 보내도 깨지면 안 된다"
    assert await _count("TBENEFIT_EDIT_REQUEST") == 1


@pytest.mark.asyncio
async def test_BR6_정성_불변식_인증_CSRF는_그대로다(br):
    assert (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스", "benefit_amt": 5,
                                      "qual_yn": True})).status_code == 422
    body = {"benefit_cd": "gym", "benefit_nm": "헬스"}
    assert (await br["c"].post(f"/companies/{br['a']}/benefits", json=body, headers=CSRF)).status_code == 401
    assert (await _post(br, "carol", body)).status_code == 403  # 재직 인증 없음
    assert (await _post(br, "alice", body, comp=br["b"])).status_code == 403  # 남의 회사
    assert (await br["c"].post(f"/companies/{br['a']}/benefits", json=body,
                               cookies=br["ck"]["alice"])).status_code == 403  # CSRF 헤더 없음
    assert await _count("TBENEFIT_EDIT_REQUEST") == 0


@pytest.mark.asyncio
async def test_BR7_같은_대상의_대기_중_등록은_409다_다른_회원은_따로(br):
    assert (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).status_code == 202
    assert (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스 다시"})).status_code == 409
    assert (await _post(br, "bob", {"benefit_cd": "gym", "benefit_nm": "헬스(밥)"})).status_code == 202


@pytest.mark.asyncio
async def test_BR8_수정은_202_본체는_그대로_제출_때_스냅샷과_토큰이_남는다(br):
    token = await _token(br)
    before = await _bodies(br)
    row0 = await database.fetch_one("SELECT * FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],))
    r = await _put(br, "alice", {"base_dtm": token, "benefit_nm": "구내식당(수정)", "benefit_amt": 500})
    assert r.status_code == 202, r.text
    assert r.json()["request"]["type"] == "update"
    assert await _bodies(br) == before
    assert await database.fetch_one("SELECT * FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],)) == row0
    req = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_REQUEST")
    assert req["BASE_TOKEN_VAL"] == token and req["BENEFIT_ID"] == br["meal"] and req["BENEFIT_CD"] == "meal"
    snap = json.loads(req["BEFORE_VAL"])
    assert snap["benefit_nm"] == "구내식당" and snap["benefit_amt"] == 432
    # 같은 항목에 이 회원의 대기가 있으면 409, 다른 회원은 따로
    assert (await _put(br, "alice", {"base_dtm": token, "benefit_nm": "또", "benefit_amt": 1})).status_code == 409
    assert (await _put(br, "bob", {"base_dtm": token, "benefit_nm": "밥의 수정", "benefit_amt": 1})).status_code == 202


@pytest.mark.asyncio
async def test_BR9_수정_제출은_낡은_토큰이면_409_현재_행_동봉_요청_안_만든다(br):
    r = await _put(br, "alice", {"base_dtm": "2020-01-01T00:00:00:abcdefabcdef", "benefit_nm": "x", "benefit_amt": 1})
    assert r.status_code == 409
    assert r.json()["current_benefit"]["benefit_nm"] == "구내식당" and r.json()["benefits"]
    assert await _count("TBENEFIT_EDIT_REQUEST") == 0
    assert (await _put(br, "alice", {"benefit_nm": "x"})).status_code == 422  # base_dtm 누락
    assert (await _put(br, "alice", {"base_dtm": "t", "benefit_nm": "x"}, bid=999999)).status_code == 404
    assert (await _put(br, "carol", {"base_dtm": "t", "benefit_nm": "x"})).status_code == 403


@pytest.mark.asyncio
async def test_BR10_하루_한도는_요청_수로_센다_승인으로_생긴_이력은_세지_않는다(br, monkeypatch):
    from server.config import get_settings
    monkeypatch.setattr(get_settings(), "daily_edit_limit", 2)
    # 이 회원 명의의 이력 행이 이미 여러 개 있어도(옛 방식이면 한도 초과) 요청은 받는다.
    for _ in range(5):
        await database.execute(
            "INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD) VALUES (%s,%s,'update')",
            (br["a"], br["ids"]["br-alice"]))
    assert (await _post(br, "alice", {"benefit_nm": "하나"})).status_code == 202
    assert (await _post(br, "alice", {"benefit_nm": "둘"})).status_code == 202
    third = await _post(br, "alice", {"benefit_nm": "셋"})
    assert third.status_code == 429
    assert (await _post(br, "bob", {"benefit_nm": "밥 하나"})).status_code == 202  # 회원별


@pytest.mark.asyncio
async def test_BR11_편집용_목록은_내_요청만_싣는다_거절_사유_포함_30일_지난_결정분은_뺀다(br):
    token = await _token(br)
    assert (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "알리스 등록"})).status_code == 202
    assert (await _post(br, "bob", {"benefit_cd": "book", "benefit_nm": "밥 등록"})).status_code == 202
    assert (await _put(br, "alice", {"base_dtm": token, "benefit_nm": "알리스 수정", "benefit_amt": 9})).status_code == 202
    rid = await _request_id(br, "알리스 등록")
    assert (await _reject(br, rid, note="이름이 모호해요")).status_code == 200
    old = await _post(br, "alice", {"benefit_cd": "snack", "benefit_nm": "오래된 결정"})
    old_id = old.json()["request"]["request_id"]
    await _reject(br, old_id, note="옛 사유")
    await database.execute("UPDATE TBENEFIT_EDIT_REQUEST SET DECIDED_DTM = UTC_TIMESTAMP() - INTERVAL 31 DAY "
                           "WHERE EDIT_REQUEST_ID=%s", (old_id,))

    r = await br["c"].get(f"/companies/{br['a']}/benefits", cookies=br["ck"]["alice"])
    assert r.status_code == 200 and r.headers["cache-control"] == "no-store"
    reqs = r.json()["requests"]
    names = {q["benefit_nm"]: q for q in reqs}
    assert set(names) == {"알리스 등록", "알리스 수정"}, "남의 요청이나 31일 지난 결정분이 섞였다"
    assert names["알리스 등록"]["status"] == "rejected" and names["알리스 등록"]["decide_note"] == "이름이 모호해요"
    assert names["알리스 수정"]["status"] == "pending" and names["알리스 수정"]["benefit_id"] == br["meal"]
    assert "MBR_ID" not in r.text and "member_id" not in r.text
    bob = (await br["c"].get(f"/companies/{br['a']}/benefits", cookies=br["ck"]["bob"])).json()["requests"]
    assert [q["benefit_nm"] for q in bob] == ["밥 등록"]


# ── BR-12: 표준 코드 목록 ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR12_코드_목록은_익명_공개_표시명_규칙을_그대로_쓴다(br):
    from generator.benefit_codes import LABEL_OVERRIDE
    r = await br["c"].get("/benefit-codes")  # 쿠키 · CSRF 헤더 없음
    assert r.status_code == 200
    assert r.headers["cache-control"].startswith("public")
    codes = r.json()["codes"]
    by_code = {c["code"]: c for c in codes}
    assert {"meal", "gym", "book", "snack", "transport"} <= set(by_code)
    assert set(by_code["gym"]) == {"code", "label", "ctgr", "aliases"}
    assert by_code["gym"]["ctgr"] == "health" and by_code["gym"]["label"] == "헬스장"
    assert by_code["transport"]["label"] == LABEL_OVERRIDE["transport"], "LABEL_OVERRIDE 가 적용되지 않았다"
    order = [c["ctgr"] for c in codes]
    assert order == sorted(order, key=["compensation", "flexibility", "work_env", "time_off", "health", "family",
                                       "growth", "leisure", "perks"].index), "카테고리 순서가 아니다"


# ── BR-13~: 콘솔 큐 ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR13_콘솔_큐는_원문을_가공하지_않고_싣고_비운영자에겐_404다(br):
    token = await _token(br)
    await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "<img src=x onerror=alert(1)>",
                              "edit_note": "<script>x</script>"})
    await _put(br, "bob", {"base_dtm": token, "benefit_nm": "수정안", "benefit_amt": 1})
    r = await br["c"].get("/console/queues", cookies=br["ck"]["op"])
    assert r.status_code == 200
    data = r.json()
    items = {i["type"]: i for i in data["benefit_requests"]}
    assert items["create"]["name"] == "<img src=x onerror=alert(1)>" and items["create"]["edit_note"] == "<script>x</script>"
    assert items["create"]["benefit_cd"] == "gym" and items["create"]["existing_codes"] == ["meal"]
    assert items["create"]["nickname"] == "br-alice" and items["create"]["company"] == "요청테스트사A"
    assert items["update"]["before"]["benefit_nm"] == "구내식당" and items["update"]["stale"] is False
    assert items["update"]["current"]["benefit_nm"] == "구내식당" and items["update"]["target_gone"] is False
    assert {c["code"] for c in data["benefit_codes"]} >= {"gym", "meal"}
    assert (await br["c"].get("/console/queues", cookies=br["ck"]["alice"])).status_code == 404


@pytest.mark.asyncio
async def test_BR14_제출_뒤_본체가_바뀌면_큐가_stale_삭제되면_target_gone_으로_보인다(br):
    token = await _token(br)
    await _put(br, "alice", {"base_dtm": token, "benefit_nm": "수정안", "benefit_amt": 1})
    await database.execute("UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM='누가 먼저 고침' WHERE BENEFIT_ID=%s", (br["meal"],))
    item = (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"][0]
    assert item["stale"] is True and item["current"]["benefit_nm"] == "누가 먼저 고침"
    await database.execute("DELETE FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],))
    item = (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"][0]
    assert item["target_gone"] is True and item["stale"] is False


# ── BR-15~: 승인 ─────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR15_등록_승인은_운영자가_고른_코드와_코드의_카테고리로_반영하고_이력의_편집자는_회원이다(br):
    cache = br["app"].state.reference_cache
    cache.set("reference_all", b"sentinel")
    r = await _post(br, "alice", {"benefit_cd": "book", "benefit_nm": "회사가 부르는 이름", "benefit_amt": 120,
                                  "qual_yn": False, "note_ctnt": "월 10만원", "edit_note": "복지몰 공지"})
    rid = r.json()["request"]["request_id"]
    # 회원은 book 을 골랐지만 운영자가 gym 으로 바로잡는다 — 카테고리는 회원이 아니라 코드에서 정해진다(gym = health).
    ok = await _approve(br, rid, benefit_cd="gym", note="확인함")
    assert ok.status_code == 200, ok.text
    assert ok.json()["result"] == "approved" and "다음 배포" in ok.json()["next"]
    assert cache.get("reference_all") is None, "승인 뒤 참조 캐시를 비워야 비교·복지검색이 바로 새 값을 본다"

    row = await database.fetch_one("SELECT * FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD='gym'", (br["a"],))
    assert row["BENEFIT_NM"] == "회사가 부르는 이름" and row["BENEFIT_CTGR_CD"] == "health"
    assert row["BADGE_CD"] == "verified" and row["BADGE_SRC_CD"] == "user_report" and row["AMT_SOURCE_CD"] == "estimated"
    assert row["BENEFIT_AMT"] == 120 and row["NOTE_CTNT"] == "월 10만원" and row["EXPIRES_DTM"] is not None
    assert row["INS_ID"] == br["ids"]["br-alice"]
    log = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_LOG WHERE BENEFIT_ID=%s", (row["BENEFIT_ID"],))
    assert log["EDIT_TYPE_CD"] == "create" and log["ACTOR_MBR_ID"] == br["ids"]["br-alice"]
    assert log["ACTOR_KIND_CD"] == "member" and log["BEFORE_VAL"] is None and log["EDIT_NOTE_CTNT"] == "복지몰 공지"
    req = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s", (rid,))
    assert req["STATUS_CD"] == "approved" and req["DECIDED_BY_ID"] == br["ids"]["br-op"], "결정자는 세션에서 와야 한다"
    assert req["APPLIED_BENEFIT_CD"] == "gym" and req["RESULT_BENEFIT_ID"] == row["BENEFIT_ID"]
    assert req["EDIT_LOG_ID"] == log["EDIT_LOG_ID"] and req["DECIDE_NOTE_CTNT"] == "확인함"
    # 공개 이력과 출처 배지(재직자 등록)
    pub = (await br["c"].get(f"/companies/{br['a']}/edits")).json()
    assert pub[0]["nickname"] == "br-alice" and pub[0]["actor_kind"] == "member"
    from server.services.reference import build_reference_bundle
    async with database.get_pool().acquire() as conn:
        bundle = await build_reference_bundle(conn)
    comp = next(c for c in bundle["companies"] if c["comp_id"] == br["a"])
    assert next(b for b in comp["benefits"] if b["benefit_cd"] == "gym")["edit_origin"] == "member"


@pytest.mark.asyncio
async def test_BR16_등록_승인_거부_조건들_코드_필수_표준_밖_이미_있음_두_번째(br):
    rid = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    assert (await _approve(br, rid)).status_code == 422 and (await _approve(br, rid)).json()["detail"] == "code_required"
    assert (await _approve(br, rid, benefit_cd="nope_not_standard")).status_code == 422
    dup = await _approve(br, rid, benefit_cd="meal")  # 회사 A 에 이미 있는 코드
    assert dup.status_code == 409 and dup.json()["detail"] == "duplicate"
    assert await _count("TBENEFIT_EDIT_REQUEST", "STATUS_CD='pending'") == 1, "실패한 승인은 요청을 건드리지 않는다"
    assert (await _approve(br, rid, benefit_cd="gym")).status_code == 200
    again = await _approve(br, rid, benefit_cd="gym")
    assert again.status_code == 409 and again.json()["detail"] == "not_pending"
    assert (await _approve(br, 999999, benefit_cd="gym")).json()["detail"] == "not_pending"


@pytest.mark.asyncio
async def test_BR17_수정_승인은_반영하고_이력에_전후를_남기며_정성_전환도_금액출처를_맞춘다(br):
    token = await _token(br)
    r = await _put(br, "alice", {"base_dtm": token, "benefit_nm": "구내식당·식대", "qual_yn": True,
                                 "note_ctnt": "점심 제공", "edit_note": "정성으로 정정"})
    rid = r.json()["request"]["request_id"]
    ok = await _approve(br, rid, benefit_cd="ignored_for_update")
    assert ok.status_code == 200, ok.text
    row = await database.fetch_one("SELECT * FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],))
    assert row["BENEFIT_NM"] == "구내식당·식대" and row["QUAL_YN"] == 1 and row["BENEFIT_AMT"] is None
    assert row["AMT_SOURCE_CD"] == "none" and row["BADGE_CD"] == "verified" and row["MOD_ID"] == br["ids"]["br-alice"]
    assert row["BENEFIT_CD"] == "meal"
    log = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_LOG WHERE BENEFIT_ID=%s", (br["meal"],))
    assert log["EDIT_TYPE_CD"] == "update" and log["ACTOR_MBR_ID"] == br["ids"]["br-alice"]
    assert json.loads(log["BEFORE_VAL"])["benefit_amt"] == 432 and json.loads(log["AFTER_VAL"])["qual_yn"] is True
    req = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s", (rid,))
    assert req["STATUS_CD"] == "approved" and req["RESULT_BENEFIT_ID"] == br["meal"] and req["EDIT_LOG_ID"] == log["EDIT_LOG_ID"]


@pytest.mark.asyncio
async def test_BR18_제출_뒤_대상이_바뀌었으면_승인은_stale_409_거절은_된다(br):
    token = await _token(br)
    rid = (await _put(br, "alice", {"base_dtm": token, "benefit_nm": "내 수정", "benefit_amt": 1})).json()["request"]["request_id"]
    # bob 의 수정이 먼저 승인돼 대상이 바뀐다
    bob_rid = (await _put(br, "bob", {"base_dtm": token, "benefit_nm": "밥 수정", "benefit_amt": 2})).json()["request"]["request_id"]
    assert (await _approve(br, bob_rid)).status_code == 200
    stale = await _approve(br, rid)
    assert stale.status_code == 409 and stale.json()["detail"] == "stale"
    assert (await database.fetch_one("SELECT BENEFIT_NM FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s",
                                     (br["meal"],)))["BENEFIT_NM"] == "밥 수정", "stale 승인이 본체를 덮었다"
    assert await _count("TBENEFIT_EDIT_LOG", "BENEFIT_ID=%s", (br["meal"],)) == 1
    assert (await _reject(br, rid, note="그 사이 바뀌었어요")).status_code == 200


@pytest.mark.asyncio
async def test_BR19_대상이_지워졌으면_승인은_target_gone_409(br):
    token = await _token(br)
    rid = (await _put(br, "alice", {"base_dtm": token, "benefit_nm": "내 수정", "benefit_amt": 1})).json()["request"]["request_id"]
    await database.execute("DELETE FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],))  # 운영자 CLI 삭제
    gone = await _approve(br, rid)
    assert gone.status_code == 409 and gone.json()["detail"] == "target_gone"
    assert (await database.fetch_one("SELECT STATUS_CD FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s",
                                     (rid,)))["STATUS_CD"] == "pending"


# ── BR-20~: 거절 ─────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR20_거절은_본체와_이력을_건드리지_않고_사유를_저장한다(br):
    before = await _bodies(br)
    rid = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    r = await _reject(br, rid, note="공식 자료가 필요해요")
    assert r.status_code == 200 and r.json()["result"] == "rejected"
    assert await _bodies(br) == before
    req = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s", (rid,))
    assert req["STATUS_CD"] == "rejected" and req["DECIDE_NOTE_CTNT"] == "공식 자료가 필요해요"
    assert req["DECIDED_BY_ID"] == br["ids"]["br-op"] and req["DECIDED_DTM"] is not None
    again = await _reject(br, rid)
    assert again.status_code == 409 and again.json()["detail"] == "not_pending"
    assert (await _approve(br, rid, benefit_cd="gym")).json()["detail"] == "not_pending"
    # 거절된 뒤에는 같은 대상을 다시 요청할 수 있다(대기가 아니므로)
    assert (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스 다시"})).status_code == 202


# ── BR-21~: 콘솔 관문 · 결정자 ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR21_콘솔_승인_거절은_CSRF_운영자_관문_뒤에_있고_결정자_필드가_없다(br):
    from server.routers.console import BenefitApproveIn, DecisionIn
    for model in (BenefitApproveIn, DecisionIn):
        assert not {"decided_by", "decided_by_id", "operator_id", "mbr_id"} & set(model.model_fields)
    rid = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    c = br["c"]
    assert (await c.post(f"/console/benefit-requests/{rid}/approve", json={"benefit_cd": "gym"},
                         cookies=br["ck"]["op"])).status_code == 403  # CSRF 헤더 없음
    assert (await c.post(f"/console/benefit-requests/{rid}/approve", json={"benefit_cd": "gym"}, headers=CSRF,
                         cookies=br["ck"]["alice"])).status_code == 404  # 비운영자
    assert (await c.post(f"/console/benefit-requests/{rid}/reject", json={}, headers=CSRF)).status_code == 401
    # 요청 본문이 결정자를 지정하려 해도 DECIDED_BY_ID 는 세션이다
    assert (await _approve(br, rid, benefit_cd="gym", decided_by=br["ids"]["br-bob"],
                           decided_by_id=br["ids"]["br-bob"])).status_code == 200
    assert (await database.fetch_one("SELECT DECIDED_BY_ID FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s",
                                     (rid,)))["DECIDED_BY_ID"] == br["ids"]["br-op"]
    # 관문 밖(공개 호스트 · 프록시 표식)은 존재 자체를 숨긴다
    outside = await c.get("/console/queues", cookies=br["ck"]["op"],
                          headers={"host": "jobcho.wiki", "x-real-ip": "198.51.100.4",
                                   "x-forwarded-for": "198.51.100.4", "x-forwarded-proto": "https"})
    assert outside.status_code == 404


@pytest.mark.asyncio
async def test_BR22_콘솔_현황은_대기_건수를_센다(br):
    await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})
    d = (await br["c"].get("/console/overview", cookies=br["ck"]["op"])).json()
    assert d["benefit_requests"]["pending"] == 1


@pytest.mark.asyncio
async def test_BR23_콘솔_복지_이력_탭은_운영자_편집을_운영자로_싣는다(br):
    await database.execute(
        "INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, ACTOR_KIND_CD, EDIT_TYPE_CD, EDIT_NOTE_CTNT) "
        "VALUES (%s, NULL, 'operator', 'delete', '운영자 삭제')", (br["a"],))
    items = (await br["c"].get("/console/benefit-edits", cookies=br["ck"]["op"])).json()["items"]
    assert items[0]["editor_kind"] == "operator"


# ── BR-24~: 공개 이력의 편집 주체 · CLI ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR24_공개_이력은_운영자는_운영자_탈퇴는_탈퇴로_보인다(br):
    ins = ("INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, ACTOR_KIND_CD, EDIT_TYPE_CD, EDIT_NOTE_CTNT) "
           "VALUES (%s, %s, %s, %s, %s)")
    await database.execute(ins, (br["a"], None, "operator", "update", "운영자 정정: 금액"))
    await database.execute(ins, (br["a"], None, "operator", "delete", "운영자 삭제"))
    await database.execute(ins, (br["a"], None, "member", "update", "탈퇴한 회원의 편집"))
    await database.execute(ins, (br["a"], br["ids"]["br-bob"], "member", "update", "밥의 편집"))
    r = await br["c"].get(f"/companies/{br['a']}/edits")
    assert r.status_code == 200
    got = [(i["nickname"], i["actor_kind"]) for i in r.json()]  # 최신순
    assert got == [("br-bob", "member"), ("(탈퇴)", "member"), ("운영자", "operator"), ("운영자", "operator")]
    assert "MBR_ID" not in r.text and "mbr_id" not in r.text


def _sync_ops_conn():
    """ops CLI 가 쓰는 동기 커넥션(DB_NAME 환경변수가 가리키는 격리 DB)."""
    return ops._connect()


@pytest.mark.asyncio
async def test_BR25_delete_benefit_CLI_는_operator_로_기록한다(br):
    conn = await asyncio.to_thread(_sync_ops_conn)
    try:
        rc = await asyncio.to_thread(
            ops.cmd_delete_benefit, conn, SimpleNamespace(benefit_id=br["meal"], note="반달리즘 정정"))
    finally:
        conn.close()
    assert rc == 0
    log = await database.fetch_one("SELECT * FROM TBENEFIT_EDIT_LOG WHERE COMP_ID=%s", (br["a"],))
    assert log["EDIT_TYPE_CD"] == "delete" and log["ACTOR_MBR_ID"] is None and log["ACTOR_KIND_CD"] == "operator"
    pub = (await br["c"].get(f"/companies/{br['a']}/edits")).json()
    assert pub[0]["nickname"] == "운영자"


@pytest.mark.asyncio
async def test_BR26_요약_메일_큐는_대기_ID만_싣고_CLI_가_같은_목록을_보인다(br, capsys):
    token = await _token(br)
    await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "비밀스러운 복지명"})
    await _put(br, "bob", {"base_dtm": token, "benefit_nm": "또 비밀", "benefit_amt": 1})
    rid_done = (await _post(br, "alice", {"benefit_cd": "book", "benefit_nm": "처리된 건"})).json()["request"]["request_id"]
    await _reject(br, rid_done)
    sql = next(q for k, _l, _c, q in ops._DIGEST_QUERIES if k == "benefit_requests")
    ids = [r["id"] for r in await database.fetch_all(sql)]  # 실 SQL 문법 확인(스텁이 못 잡는다)
    assert len(ids) == 2 and rid_done not in ids

    conn = await asyncio.to_thread(_sync_ops_conn)
    try:
        digest = await asyncio.to_thread(ops.collect_digest, conn)
        assert digest["benefit_requests"] == ids
        subject, body = ops.digest_subject(digest), ops.digest_body(digest)
        assert "복지 등록 및 수정 확인 2" in subject
        assert "복지 등록 및 수정 확인" in body and "list-benefit-requests" in body
        assert "비밀스러운" not in body and "또 비밀" not in body and "br-alice" not in body  # 건수와 ID 만
        rc = await asyncio.to_thread(ops.cmd_list_benefit_requests, conn, SimpleNamespace(all=False, limit=50))
        assert rc == 0
        out = capsys.readouterr().out
        assert "비밀스러운 복지명" in out and "처리된 건" not in out and "목록에 없음" not in out
        await asyncio.to_thread(ops.cmd_list_benefit_requests, conn, SimpleNamespace(all=True, limit=50))
        assert "처리된 건" in capsys.readouterr().out
    finally:
        conn.close()


# ── BR-27~: 적재 프로그램 · 서비스 수준 ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_BR27_fresh_는_확인_요청이_있으면_거부하고_폐기가_허용되면_함께_비운다(br):
    await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})
    conn = await asyncio.to_thread(seed_load.connect)
    try:
        def check():
            with conn.cursor() as cur:
                n_log, n_member, n_req = seed_load._member_data_counts(cur)
                assert n_req == 1
                with pytest.raises(seed_load.FreshRefusedError) as exc:
                    seed_load._refuse_fresh_over_member_data(cur, False)
                assert "복지 확인 요청 1건" in str(exc.value)
                seed_load._clear_edit_log(cur)  # 폐기 허용 경로
                cur.execute("SELECT COUNT(*) FROM TBENEFIT_EDIT_REQUEST")
                assert cur.fetchone()[0] == 0
            conn.commit()
        await asyncio.to_thread(check)
    finally:
        conn.close()


def test_BR28_등록_모델은_코드_없이도_받고_카테고리는_무엇이든_받아_무시한다():
    m = BenefitCreateIn(benefit_nm="이름", benefit_ctgr_cd="whatever")
    assert m.benefit_cd is None and m.benefit_ctgr_cd == "whatever"
    assert BenefitCreateIn(benefit_cd="  GYM ", benefit_nm="x").benefit_cd == "gym"
    assert BenefitCreateIn(benefit_cd="", benefit_nm="x").benefit_cd is None
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="Meal Card!", benefit_nm="x")
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_nm="   ")
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_nm="x", benefit_amt=10, qual_yn=True)


def test_BR29_코드_목록은_서버와_생성기가_같은_규칙을_쓴다():
    """서버 목록은 generator/benefit_codes.derive_codes 결과 그대로다(규칙을 세 번째로 복사하지 않는다)."""
    from generator.benefit_codes import derive_codes
    from generator.pages import find
    from server.services import benefit_codes as svc_codes
    assert find.derive_codes is derive_codes and svc_codes.derive_codes is derive_codes
    companies = [
        {"comp_id": 1, "comp_eng_nm": "x1", "benefits": [
            {"benefit_cd": "a", "benefit_nm": "에이", "benefit_ctgr_cd": "perks", "qual_yn": False, "benefit_amt": 1},
            {"benefit_cd": "transport", "benefit_nm": "통근", "benefit_ctgr_cd": "compensation", "qual_yn": False}]},
        {"comp_id": 2, "comp_eng_nm": "x2", "benefits": [
            {"benefit_cd": "a", "benefit_nm": "에이", "benefit_ctgr_cd": "perks", "qual_yn": False},
            {"benefit_cd": "a", "benefit_nm": "에이 둘", "benefit_ctgr_cd": "perks", "qual_yn": False}]},
    ]
    out = svc_codes.build_code_list(companies)
    assert [c["code"] for c in out] == ["transport", "a"]  # compensation 이 perks 보다 앞
    assert next(c for c in out if c["code"] == "a")["aliases"] == ["에이 둘"]  # 대표 이름은 별칭에서 뺀다
    assert next(c for c in out if c["code"] == "transport")["label"] == find.LABEL_OVERRIDE["transport"]


# ── BR-30~: 검토 반영(2026-10-21) — stale 판정 · 요청자 상태 · 한도 경합 · 잃었던 커버리지 ─────────────────────

async def _update_req(br, who="alice", name="수정안", amt=1) -> int:
    r = await _put(br, who, {"base_dtm": await _token(br, who), "benefit_nm": name, "benefit_amt": amt})
    assert r.status_code == 202, r.text
    return r.json()["request"]["request_id"]


@pytest.mark.asyncio
async def test_BR30_시드_적재가_MOD_DTM_만_올려도_내용이_같으면_stale_이_아니다(br):
    """load.py 는 공식 행의 배지를 official→est→official 로 오가며 내용이 같아도 MOD_DTM 을 올린다."""
    rid = await _update_req(br)
    await database.execute("UPDATE TCOMPANY_BENEFIT SET BADGE_CD='est' WHERE BENEFIT_ID=%s", (br["meal"],))
    await database.execute("UPDATE TCOMPANY_BENEFIT SET BADGE_CD='official', MOD_DTM = UTC_TIMESTAMP() + INTERVAL 9 SECOND "
                           "WHERE BENEFIT_ID=%s", (br["meal"],))
    item = (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"][0]
    assert item["stale"] is False, "시각만 바뀐 행이 stale 로 보인다"
    ok = await _approve(br, rid)
    assert ok.status_code == 200, ok.text
    assert (await database.fetch_one("SELECT BENEFIT_NM FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s",
                                     (br["meal"],)))["BENEFIT_NM"] == "수정안"


@pytest.mark.asyncio
async def test_BR30b_내용이_실제로_바뀌면_stale_콘솔_표시와_승인_판정이_같다(br):
    rid = await _update_req(br)
    await database.execute("UPDATE TCOMPANY_BENEFIT SET BENEFIT_AMT=999 WHERE BENEFIT_ID=%s", (br["meal"],))
    item = (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"][0]
    assert item["stale"] is True
    r = await _approve(br, rid)
    assert r.status_code == 409 and r.json()["detail"] == "stale"


@pytest.mark.asyncio
async def test_BR31_요청한_뒤_탈퇴한_회원의_요청은_승인할_수_없다(br):
    rid_c = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    rid_u = await _update_req(br, "bob", "밥 수정")
    for who in ("alice", "bob"):  # member.py 탈퇴: 소프트 삭제 + 재직 인증 삭제
        await database.execute("UPDATE TMEMBER SET LOGIN_EMAIL_NM=NULL, STATUS_CD='withdrawn' WHERE MBR_ID=%s",
                               (br["ids"][f"br-{who}"],))
    await database.execute("DELETE FROM TEMPLOY_VERIFICATION WHERE MBR_ID=%s", (br["ids"]["br-bob"],))
    items = {i["id"]: i for i in (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"]}
    assert items[rid_c]["requester"] == "withdrawn" and items[rid_u]["requester"] == "withdrawn"
    before = await _bodies(br)
    for rid, body in ((rid_c, {"benefit_cd": "gym"}), (rid_u, {})):
        r = await _approve(br, rid, **body)
        assert r.status_code == 409 and r.json()["detail"] == "requester_inactive", r.text
    assert await _bodies(br) == before
    assert (await _reject(br, rid_c, note="탈퇴")).status_code == 200


@pytest.mark.asyncio
async def test_BR31b_재직_인증이_만료_폐기된_요청자도_승인할_수_없다(br):
    rid1 = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    rid2 = (await _post(br, "bob", {"benefit_cd": "book", "benefit_nm": "도서"})).json()["request"]["request_id"]
    await database.execute("UPDATE TEMPLOY_VERIFICATION SET EXPIRES_DTM = UTC_TIMESTAMP() - INTERVAL 1 DAY WHERE MBR_ID=%s",
                           (br["ids"]["br-alice"],))
    await database.execute("UPDATE TEMPLOY_VERIFICATION SET REVOKED_DTM = UTC_TIMESTAMP() WHERE MBR_ID=%s",
                           (br["ids"]["br-bob"],))
    items = {i["id"]: i for i in (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()["benefit_requests"]}
    assert items[rid1]["requester"] == "no_employment" and items[rid2]["requester"] == "no_employment"
    for rid, cd in ((rid1, "gym"), (rid2, "book")):
        r = await _approve(br, rid, benefit_cd=cd)
        assert r.status_code == 409 and r.json()["detail"] == "requester_inactive"
    assert await _count("TCOMPANY_BENEFIT", "COMP_ID=%s", (br["a"],)) == 1


@pytest.mark.asyncio
async def test_BR32_병렬_제출도_하루_한도를_넘지_못한다(br, monkeypatch):
    from server.config import get_settings
    monkeypatch.setattr(get_settings(), "daily_edit_limit", 2)
    rs = await asyncio.gather(*[_post(br, "alice", {"benefit_nm": f"병렬 {i}"}) for i in range(6)])
    codes = sorted(r.status_code for r in rs)
    assert codes == [202, 202, 429, 429, 429, 429], codes
    assert await _count("TBENEFIT_EDIT_REQUEST") == 2


@pytest.mark.asyncio
async def test_BR33_대기가_표시_상한을_넘으면_전체_건수를_따로_알린다(br):
    from server.services import console_view
    for i in range(3):
        await _post(br, "alice", {"benefit_nm": f"대기 {i}"})
    assert len(await console_view.list_pending_benefit_requests(limit=2)) == 2
    assert await console_view.count_pending_benefit_requests() == 3
    data = (await br["c"].get("/console/queues", cookies=br["ck"]["op"])).json()
    assert data["benefit_requests_total"] == 3 and len(data["benefit_requests"]) == 3


@pytest.mark.asyncio
async def test_BR34_공개_이력_no_store_최신순_키셋_키_화이트리스트_닉네임_존치(br):
    from server.tests.member_edit_support import approved_create
    for cd in ("gym", "book", "snack"):
        r = await approved_create(br["a"], br["ids"]["br-alice"], BenefitCreateIn(benefit_cd=cd, benefit_nm=cd), ctgr="perks")
        assert r["result"] == "ok", r
    await database.execute(
        "INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, ACTOR_KIND_CD, EDIT_TYPE_CD, EDIT_NOTE_CTNT) "
        "VALUES (%s, NULL, 'operator', 'update', '운영자 정정')", (br["a"],))
    r = await br["c"].get(f"/companies/{br['a']}/edits")
    assert r.status_code == 200 and r.headers["cache-control"] == "no-store"
    items = r.json()
    assert len(items) == 4 and items[0]["nickname"] == "운영자"
    ids = [i["edit_id"] for i in items]
    assert ids == sorted(ids, reverse=True) and "EDIT_LOG_ID" not in r.text
    assert set(items[0]) <= {"edit_id", "nickname", "actor_kind", "edit_type", "before", "after", "edit_note", "dtm"}
    page1 = (await br["c"].get(f"/companies/{br['a']}/edits?limit=3")).json()
    assert [i["edit_id"] for i in page1] == ids[:3]
    page2 = (await br["c"].get(f"/companies/{br['a']}/edits?limit=3&before={page1[-1]['edit_id']}")).json()
    assert [i["edit_id"] for i in page2] == ids[3:]
    assert (await br["c"].get(f"/companies/{br['a']}/edits?before={ids[-1]}")).json() == []
    # 탈퇴한 기여자의 닉네임은 이력에 남는다(닉네임은 존치, 이메일만 파기)
    await database.execute("UPDATE TMEMBER SET LOGIN_EMAIL_NM=NULL, STATUS_CD='withdrawn' WHERE MBR_ID=%s",
                           (br["ids"]["br-alice"],))
    assert (await br["c"].get(f"/companies/{br['a']}/edits")).json()[1]["nickname"] == "br-alice"
    assert (await br["c"].get("/companies/99999999/edits")).status_code == 404


@pytest.mark.asyncio
async def test_BR35_승인_중_IntegrityError_는_롤백되어_요청은_대기_그대로다(br, monkeypatch):
    """사전 확인을 건너뛰게 만들어 uq_comp_benefit 위반 경로(IntegrityError)를 탄다 — 본체 · 이력 · 요청 모두 무변화."""
    from server.services import benefit_edit
    rid = (await _post(br, "alice", {"benefit_cd": "gym", "benefit_nm": "헬스"})).json()["request"]["request_id"]
    await _add_benefit(br["a"], "gym", "이미 있는 헬스", "health")  # 같은 코드가 이미 있다
    before = await _bodies(br)
    monkeypatch.setattr(benefit_edit, "_SQL_CODE_EXISTS", "SELECT 1 FROM TCOMPANY_BENEFIT WHERE 1=0 AND COMP_ID=%s AND BENEFIT_CD=%s")
    r = await _approve(br, rid, benefit_cd="gym")
    assert r.status_code == 409 and r.json()["detail"] == "duplicate"
    assert await _bodies(br) == before
    assert (await database.fetch_one("SELECT STATUS_CD, EDIT_LOG_ID FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s",
                                     (rid,))) == {"STATUS_CD": "pending", "EDIT_LOG_ID": None}


@pytest.mark.asyncio
async def test_BR36_편집용_목록은_세션_재직이_없으면_401_403(br):
    assert (await br["c"].get(f"/companies/{br['a']}/benefits")).status_code == 401
    assert (await br["c"].get(f"/companies/{br['a']}/benefits", cookies=br["ck"]["carol"])).status_code == 403
    assert (await br["c"].get(f"/companies/{br['b']}/benefits", cookies=br["ck"]["alice"])).status_code == 403


@pytest.mark.asyncio
async def test_BR37_남의_회사_복지_ID_로_수정_요청하면_404_요청은_안_생긴다(br):
    other = (await database.fetch_one("SELECT BENEFIT_ID FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s LIMIT 1", (br["b"],)))["BENEFIT_ID"]
    r = await _put(br, "alice", {"base_dtm": "x", "benefit_nm": "침입", "benefit_amt": 1}, bid=other)
    assert r.status_code == 404
    assert await _count("TBENEFIT_EDIT_REQUEST") == 0


@pytest.mark.asyncio
async def test_BR38_수정_승인은_재검증_시각을_새로_찍고_출처를_user_report_로_바꾼다(br):
    await database.execute(
        "UPDATE TCOMPANY_BENEFIT SET VERIFIED_DTM = UTC_TIMESTAMP() - INTERVAL 400 DAY, "
        "EXPIRES_DTM = UTC_TIMESTAMP() - INTERVAL 30 DAY, BADGE_SRC_CD='scrape_official' WHERE BENEFIT_ID=%s", (br["meal"],))
    rid = await _update_req(br)
    assert (await _approve(br, rid)).status_code == 200
    row = await database.fetch_one(
        "SELECT *, (VERIFIED_DTM > UTC_TIMESTAMP() - INTERVAL 1 DAY) AS fresh, "
        "(EXPIRES_DTM > UTC_TIMESTAMP() + INTERVAL 17 MONTH) AS far FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (br["meal"],))
    assert row["fresh"] == 1 and row["far"] == 1, "신선도가 리셋되지 않았다(만료 행이 밴드를 부당 확대한다)"
    assert row["BADGE_SRC_CD"] == "user_report" and row["BADGE_CD"] == "verified"


@pytest.mark.asyncio
async def test_BR39_운영자_이력만으로는_재직자_수정_배지가_붙지_않는다(br):
    from server.services.reference import build_reference_bundle
    ins = ("INSERT INTO TBENEFIT_EDIT_LOG (BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, ACTOR_KIND_CD, EDIT_TYPE_CD) "
           "VALUES (%s, %s, %s, %s, %s)")

    async def origin(bid):
        async with database.get_pool().acquire() as conn:
            bundle = await build_reference_bundle(conn)
        comp = next(c for c in bundle["companies"] if c["comp_id"] == br["a"])
        return next(b for b in comp["benefits"] if b["benefit_cd"] == bid)["edit_origin"]

    await database.execute(ins, (br["meal"], br["a"], None, "operator", "update"))
    assert await origin("meal") == "seed", "운영자 정정만으로 「공식·재직자 수정」이 됐다"
    await database.execute(ins, (br["meal"], br["a"], br["ids"]["br-alice"], "member", "update"))
    assert await origin("meal") == "edited"
