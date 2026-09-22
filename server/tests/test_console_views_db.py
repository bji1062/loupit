"""SP-AUTH-19.7·19.8 운영 콘솔 확장 — **실 DB** 조회 화면·숨김/복구 감사·관문 매트릭스 (CV-1~CV-15).

`test_console_gate.py` 가 관문과 표면을 순수 함수로, `test_admin_host_gate.py` 가 관리 호스트 판정과
nginx 전제를 잰다. 여기서 재는 것은 그 뒤 — 세션이 실제로 발급된 상태에서:

- **관문 매트릭스의 세션 축**(CV-1): 관리 호스트 + 맞는 비밀이라도 비운영자는 404, 운영자만 200.
- **이메일 경계**(CV-2·CV-3): 로그인 이메일은 운영자 회원 목록에만. 공개 응답·비운영자 응답에는 없다.
- **페이지네이션 경계**(CV-4): limit 0·초과는 422, 커서는 경계 행을 빼고, 마지막 페이지의 커서는 null.
- **숨김/복구 감사**(CV-6~CV-8): 결정자는 세션에서(`MOD_ID`), 숨김은 대기 신고를 닫고, 복구로 되돌아온다.

httpx ASGITransport 로 앱을 직접 두드린다(test_community_api 와 같은 방식) — 세션 쿠키·CSRF 헤더·
의존성 순서까지 실제 경로 그대로다.

⚠ 이 파일은 `DB_NAME` 이 가리키는 DB 에 실제로 쓴다(conftest 가드가 `loupit_test` 로 제한).
자기 행(닉네임 `cv-` 접두 회원·회사 1·그 회사의 이력)만 만들고 치운다.
"""
from __future__ import annotations

import asyncio
import json
import re
from pathlib import Path

import httpx
import pytest
import pytest_asyncio

from server import database

OP_EMAIL = "cv-operator@example.com"
ALICE_EMAIL = "cv-alice@example.com"
BOB_EMAIL = "cv-bob@example.com"
COMP_ENG = "CV Console Co"
CSRF = {"X-Loupit-Client": "test"}
ADMIN_HOST = "admin.jobcho.wiki"
SECRET = "c" * 16 + "0123456789abcdef0123456789abcdef"  # 48자 — 테스트 전용 가짜 값
ROOT = Path(__file__).resolve().parents[2]


def _via(host: str, gate: str | None = None) -> dict:
    """nginx 를 거친 요청의 헤더(프록시 표식 + Host [+ 게이트 헤더])."""
    h = {"host": host, "x-real-ip": "198.51.100.4", "x-forwarded-for": "198.51.100.4", "x-forwarded-proto": "https"}
    if gate is not None:
        h["x-loupit-admin-gate"] = gate
    return h


async def _clean() -> None:
    comp = await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (COMP_ENG,))
    mbrs = [r["MBR_ID"] for r in await database.fetch_all("SELECT MBR_ID FROM TMEMBER WHERE NICKNAME_NM LIKE 'cv-%%'")]
    if mbrs:
        marks = ",".join(["%s"] * len(mbrs))
        # 조치 이력은 추가 전용이라 앱에는 지우는 경로가 없다 — 테스트 정리만 여기서 직접 지운다.
        await database.execute(f"DELETE FROM TPOST_ACTION_LOG WHERE ACTOR_MBR_ID IN ({marks})", tuple(mbrs))
        await database.execute(f"DELETE FROM TPOST_REPORT WHERE MBR_ID IN ({marks})", tuple(mbrs))
        # 글을 지우면 댓글·반응은 CASCADE. 글의 작성자 FK 는 SET NULL 이라 회원보다 **먼저** 지워야 찾을 수 있다.
        await database.execute(f"DELETE FROM TPOST WHERE MBR_ID IN ({marks})", tuple(mbrs))
        await database.execute(f"DELETE FROM TMEMBER WHERE MBR_ID IN ({marks})", tuple(mbrs))
    if comp:
        await database.execute("DELETE FROM TBENEFIT_EDIT_LOG WHERE COMP_ID=%s", (comp["COMP_ID"],))
        await database.execute("DELETE FROM TCOMPANY WHERE COMP_ID=%s", (comp["COMP_ID"],))
    await database.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_CD='cv_tp'")
    await database.execute("DELETE FROM TMAIL_SUPPRESSION WHERE TARGET_HASH_VAL=%s", ("d" * 64,))
    await database.execute("DELETE FROM TPOST_ACTION_LOG WHERE NOTE_CTNT LIKE 'cv-%%' OR ACTOR_MBR_ID IS NULL")


@pytest_asyncio.fixture
async def cv(schema_db, monkeypatch):
    """운영자·alice(재직 인증)·bob(수동 승인 대기)·탈퇴 회원 1 + 회사 1 + 글 2·댓글 1·신고 1·편집 이력 2."""
    from server.config import get_settings
    from server.main import create_app
    from server.services import session as session_svc

    await database.init_pool()
    s = get_settings()
    monkeypatch.setattr(s, "operator_emails", OP_EMAIL)
    monkeypatch.setattr(s, "admin_host", ADMIN_HOST)
    monkeypatch.setattr(s, "admin_gate_secret", SECRET)
    await _clean()
    try:
        await database.execute(
            "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s,'cv-op'), (%s,'cv-alice'), (%s,'cv-bob')",
            (OP_EMAIL, ALICE_EMAIL, BOB_EMAIL))
        await database.execute(  # 탈퇴 회원 — 이메일은 파기(NULL), 닉네임은 존치(INV-8)
            "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM, STATUS_CD) VALUES (NULL, 'cv-gone', 'withdrawn')")
        ids = {r["NICKNAME_NM"]: r["MBR_ID"] for r in await database.fetch_all(
            "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE NICKNAME_NM LIKE 'cv-%%'")}
        await database.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES ('cv_tp', '테스트유형')")
        tp = (await database.fetch_one("SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='cv_tp'"))["COMP_TP_ID"]
        await database.execute("INSERT INTO TCOMPANY (COMP_NM, COMP_ENG_NM, COMP_TP_ID) VALUES ('콘솔테스트사', %s, %s)",
                               (COMP_ENG, tp))
        comp = (await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (COMP_ENG,)))["COMP_ID"]
        # 등록 도메인 2개 + 비활성 1개 — 회원 탭은 활성만, 이름순으로 싣는다(회사 삭제 시 CASCADE 로 정리된다).
        await database.execute(
            "INSERT INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN) VALUES "
            "(%s, 'z-cvtest.example', TRUE), (%s, 'cvtest.example', TRUE), (%s, 'old-cvtest.example', FALSE)",
            (comp, comp, comp))
        await database.execute(
            "INSERT INTO TEMPLOY_VERIFICATION (MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM) "
            "VALUES (%s, %s, 'domain', %s, UTC_TIMESTAMP() + INTERVAL 30 DAY)", (ids["cv-alice"], comp, "e" * 64))
        await database.execute("INSERT INTO TEMPLOY_VRF_REQUEST (MBR_ID, COMP_ID, EVIDENCE_CTNT) VALUES (%s, %s, '증빙')",
                               (ids["cv-bob"], comp))
        # 사용자 입력 원문에 마크업을 심는다 — 서버가 가공하지 않고 그대로 싣는지 본다(CF-8 과 같은 규약).
        await database.execute(
            "INSERT INTO TPOST (MBR_ID, CATEGORY_CD, TITLE_NM, BODY_CTNT) VALUES "
            "(%s, 'free', '<img src=x onerror=alert(1)>', %s), (%s, 'career', '두 번째 글', '본문')",
            (ids["cv-alice"], "가" * 300, ids["cv-bob"]))
        posts = [r["POST_ID"] for r in await database.fetch_all(
            "SELECT POST_ID FROM TPOST WHERE MBR_ID IN (%s,%s) ORDER BY POST_ID", (ids["cv-alice"], ids["cv-bob"]))]
        await database.execute("INSERT INTO TPOST_COMMENT (POST_ID, MBR_ID, BODY_CTNT) VALUES (%s, %s, '댓글 원문')",
                               (posts[0], ids["cv-bob"]))
        comment = (await database.fetch_one("SELECT COMMENT_ID FROM TPOST_COMMENT WHERE POST_ID=%s", (posts[0],)))["COMMENT_ID"]
        await database.execute(
            "INSERT INTO TPOST_REPORT (TARGET_TYPE_CD, TARGET_ID, MBR_ID, REASON_CD) VALUES ('post', %s, %s, 'spam')",
            (posts[0], ids["cv-bob"]))
        await database.execute(
            "INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, BEFORE_VAL, AFTER_VAL, EDIT_NOTE_CTNT) "
            "VALUES (%s, %s, 'create', NULL, %s, '신규 등록'), (%s, %s, 'update', %s, %s, '<b>금액 정정</b>')",
            (comp, ids["cv-alice"], json.dumps({"benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 200}),
             comp, ids["cv-alice"], json.dumps({"benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 200}),
             json.dumps({"benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 240})))
        cookies = {n: {"loupit_sid": await session_svc.issue_session(ids[f"cv-{n}"])} for n in ("op", "alice")}

        app = create_app()
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://127.0.0.1:8000/api/v1") as c:
            yield {"c": c, "ids": ids, "comp": comp, "posts": posts, "comment": comment, "ck": cookies, "s": s}
    finally:
        await _clean()
        await database.close_pool()


# ── CV-1: 관문 매트릭스의 세션 축 ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CV1_관문_매트릭스_실세션(cv):
    """브리프의 관문 표 전체를 실제 세션으로 — 터널 / 본 호스트 / 관리 호스트 × 비밀 × 세션."""
    c, op, alice = cv["c"], cv["ck"]["op"], cv["ck"]["alice"]
    get = lambda headers, cookies=None: c.get("/console/overview", headers=headers, cookies=cookies)  # noqa: E731

    assert (await get({}, op)).status_code == 200                                     # 터널 + 운영자
    assert (await get(_via("jobcho.wiki", SECRET), op)).status_code == 404            # 본 호스트 — 비밀을 알아도
    assert (await get(_via(ADMIN_HOST), op)).status_code == 404                       # 관리 호스트 + 비밀 없음
    assert (await get(_via(ADMIN_HOST, "wrong-secret-" * 4), op)).status_code == 404  # + 틀린 비밀
    assert (await get(_via(ADMIN_HOST, SECRET))).status_code == 401                   # + 맞는 비밀, 세션 없음 → 로그인 단계
    assert (await get(_via(ADMIN_HOST, SECRET), alice)).status_code == 404            # + 비운영자 세션
    r = await get(_via(ADMIN_HOST, SECRET), op)                                       # + 운영자 세션
    assert r.status_code == 200 and r.json()["operator"] == OP_EMAIL
    assert r.headers["cache-control"] == "no-store"
    assert (await get(_via("ADMIN.JOBCHO.WIKI", SECRET), op)).status_code == 200      # Host 대소문자 무시
    assert (await get(_via(ADMIN_HOST + ":443", SECRET), op)).status_code == 404      # 포트 붙은 Host = 불일치

    # 짧은 설정값(32자 미만) = 관리 호스트 입구 닫힘. 터널은 그대로 열려 있다.
    cv["s"].admin_gate_secret = "short-secret"
    assert (await get(_via(ADMIN_HOST, "short-secret"), op)).status_code == 404
    assert (await get({}, op)).status_code == 200

    # 404 본문은 라우트가 없을 때와 같다 — 운영자 이메일 등 무엇도 새지 않는다.
    body = (await get(_via("jobcho.wiki", SECRET), op)).text
    assert OP_EMAIL not in body and body == (await c.get("/no-such-route")).text


@pytest.mark.asyncio
async def test_CV1b_관리_호스트_쓰기도_CSRF_헤더를_요구한다(cv):
    """관리 호스트에서도 쓰기의 CSRF 방어는 약해지지 않는다 — 비밀·세션이 맞아도 헤더가 없으면 403."""
    path = f"/console/posts/{cv['posts'][1]}/visibility"
    body = {"action": "hide"}
    r = await cv["c"].post(path, json=body, headers=_via(ADMIN_HOST, SECRET), cookies=cv["ck"]["op"])
    assert r.status_code == 403
    r = await cv["c"].post(path, json=body, headers={**_via(ADMIN_HOST, SECRET), **CSRF}, cookies=cv["ck"]["op"])
    assert r.status_code == 200 and r.json()["result"] == "hidden"


# ── CV-2·3: 이메일은 운영자 화면에만 ─────────────────────────────────────────

@pytest.mark.asyncio
async def test_CV2_회원_목록은_운영자에게만_이메일을_보여준다(cv):
    c = cv["c"]
    assert (await c.get("/console/members", cookies=cv["ck"]["alice"])).status_code == 404
    assert (await c.get("/console/members")).status_code == 401
    r = await c.get("/console/members", params={"limit": 4}, cookies=cv["ck"]["op"])
    assert r.status_code == 200 and r.headers["cache-control"] == "no-store"
    items = r.json()["items"]
    assert [m["nickname"] for m in items] == ["cv-gone", "cv-bob", "cv-alice", "cv-op"], "최신 가입순이 아니다"
    by = {m["nickname"]: m for m in items}
    assert by["cv-alice"]["email"] == ALICE_EMAIL
    assert by["cv-gone"]["email"] is None and by["cv-gone"]["status"] == "withdrawn", "파기된 이메일을 지어냈다"
    # 인증 시각(since)은 DB 가 찍는다 — 값이 있는지만 보고 나머지는 정확히 맞춘다.
    [alice_v] = by["cv-alice"]["verifications"]
    [bob_v] = by["cv-bob"]["verifications"]
    assert alice_v.pop("since") and bob_v.pop("since"), "인증·요청 시각이 비었다"
    # 도메인 인증은 로그인 이메일이 아니라 회사 메일로 통과한 것이다 — 그 회사의 **활성** 등록 도메인을
    # 이름순으로 함께 싣는다(2026-09-22: 네이버 가입자가 회사 인증된 것처럼 보였다). 비활성은 뺀다.
    assert alice_v == {"company": "콘솔테스트사", "company_id": cv["comp"], "method": "domain", "state": "active",
                       "domains": ["cvtest.example", "z-cvtest.example"]}
    # 수동 승인(대기)은 메일을 거치지 않았다 — 도메인을 붙이면 메일로 확인한 것처럼 읽힌다.
    assert bob_v == {"company": "콘솔테스트사", "company_id": cv["comp"], "method": "manual", "state": "pending",
                     "domains": []}
    assert by["cv-op"]["last_session_at"] is not None, "세션을 발급했는데 최근 세션이 비었다"
    assert by["cv-bob"]["last_session_at"] is None


@pytest.mark.asyncio
async def test_CV3_이메일은_공개_응답과_다른_콘솔_응답에_없다(cv):
    """회원 탭 밖으로 이메일이 새지 않는다 — 공개 커뮤니티 목록·콘솔의 다른 화면 전부."""
    c, op = cv["c"], cv["ck"]["op"]
    for path in ("/posts", "/console/posts", "/console/comments", "/console/benefit-edits", "/console/overview",
                 "/console/queues"):
        text = (await c.get(path, cookies=op, headers=CSRF)).text
        assert ALICE_EMAIL not in text and BOB_EMAIL not in text, f"{path} 응답에 회원 이메일이 있다"


def test_CV3b_이메일을_읽는_모듈은_허용목록_안에_있다():
    """구조 경계 — `LOGIN_EMAIL_NM` 을 읽는 모듈이 늘면 새 누출 경로 후보다. 늘릴 때는 여기서 **의식적으로** 넓혀라.
    그리고 콘솔 조회 서비스(`console_view`)는 콘솔 라우터만 import 한다."""
    allowed = {
        "server/deps.py",                    # require_operator — 화이트리스트 대조
        "server/routers/member.py",          # 로그인·가입(본인)
        "server/services/auth_code.py",      # 코드 발송·검증
        "server/services/operator.py",       # 운영자 판정(CLI 공용)
        "server/services/post.py",           # 공지 작성 권한(운영자 판정)
        "server/services/console_view.py",   # 콘솔 회원 목록 ← 이메일을 **응답에 싣는** 유일한 곳
        "server/routers/console.py",         # 운영자 표시(`operator`)
    }
    readers = set()
    for f in (ROOT / "server").rglob("*.py"):
        rel = f.relative_to(ROOT).as_posix()
        if "/tests/" in rel:
            continue
        if "LOGIN_EMAIL_NM" in f.read_text(encoding="utf-8"):
            readers.add(rel)
    assert readers <= allowed, f"허용목록 밖에서 로그인 이메일을 읽는다: {readers - allowed}"
    importers = {f.relative_to(ROOT).as_posix() for f in (ROOT / "server").rglob("*.py")
                 if "/tests/" not in f.as_posix() and re.search(r"\bconsole_view\b", f.read_text(encoding="utf-8"))
                 and f.name != "console_view.py"}
    assert importers == {"server/routers/console.py"}, f"console_view 를 콘솔 라우터 밖에서 쓴다: {importers}"


# ── CV-4: 페이지네이션 경계 ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CV4_키셋_페이지네이션_경계(cv):
    c, op = cv["c"], cv["ck"]["op"]
    for bad in ({"limit": 0}, {"limit": 101}, {"before": 0}, {"limit": "x"}):
        assert (await c.get("/console/members", params=bad, cookies=op)).status_code == 422, bad
    assert (await c.get("/console/posts", params={"status": "bogus"}, cookies=op)).status_code == 422

    first = (await c.get("/console/members", params={"limit": 2}, cookies=op)).json()
    assert [m["nickname"] for m in first["items"]] == ["cv-gone", "cv-bob"]
    assert first["next_before"] == cv["ids"]["cv-bob"], "커서는 이번 페이지 마지막 행의 키다"
    second = (await c.get("/console/members", params={"limit": 2, "before": first["next_before"]}, cookies=op)).json()
    assert [m["nickname"] for m in second["items"]] == ["cv-alice", "cv-op"], "경계 행이 겹치거나 빠졌다"

    # 마지막 페이지 = 더 없음(null). 우리 글 2개만 남도록 커서를 맞춘다: 첫 글 바로 위에서 시작.
    last = (await c.get("/console/posts", params={"limit": 5, "before": cv["posts"][0] + 1}, cookies=op)).json()
    assert last["items"][0]["post_id"] == cv["posts"][0]
    tail = (await c.get("/console/posts", params={"limit": 100, "before": 1}, cookies=op)).json()
    assert tail == {"items": [], "next_before": None}


# ── CV-5: 게시판·이력 — 값은 가공하지 않는다 ─────────────────────────────────────

@pytest.mark.asyncio
async def test_CV5_게시판과_복지_이력은_원문을_그대로_싣는다(cv):
    c, op = cv["c"], cv["ck"]["op"]
    posts = (await c.get("/console/posts", params={"limit": 2}, cookies=op)).json()["items"]
    p1 = next(p for p in posts if p["post_id"] == cv["posts"][0])
    assert p1["title"] == "<img src=x onerror=alert(1)>", "서버가 제목을 가공했다 — 표시 방어는 화면 한 곳이다"
    assert p1["excerpt"] == "가" * 120, "발췌는 120자(문자 단위)여야 한다"
    assert (p1["report_cnt"], p1["report_pending_cnt"]) == (1, 1)
    assert p1["nickname"] == "cv-alice" and p1["member_id"] == cv["ids"]["cv-alice"]

    comments = (await c.get("/console/comments", params={"limit": 1}, cookies=op)).json()["items"]
    assert comments[0]["comment_id"] == cv["comment"] and comments[0]["post_id"] == cv["posts"][0]

    edits = (await c.get("/console/benefit-edits", params={"limit": 2}, cookies=op)).json()["items"]
    upd, crt = edits
    assert (upd["edit_type"], crt["edit_type"]) == ("update", "create"), "최신순이 아니다"
    assert upd["company"] == "콘솔테스트사" and upd["benefit_nm"] == "식대" and upd["benefit_cd"] == "meal"
    assert upd["before"]["benefit_amt"] == 200 and upd["after"]["benefit_amt"] == 240
    assert upd["note"] == "<b>금액 정정</b>"
    assert upd["editor_id"] == cv["ids"]["cv-alice"] and upd["editor_nickname"] == "cv-alice"
    assert crt["before"] is None


# ── CV-6~8: 숨김/복구 — 감사와 되돌림 ─────────────────────────────────────────

async def _status(table: str, pk: str, id_: int) -> dict:
    return await database.fetch_one(f"SELECT STATUS_CD, MOD_ID, MOD_DTM FROM {table} WHERE {pk}=%s", (id_,))


@pytest.mark.asyncio
async def test_CV6_글_숨김은_세션의_운영자를_기록하고_대기_신고를_닫는다(cv):
    c, op, pid = cv["c"], cv["ck"]["op"], cv["posts"][0]
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "hide", "note": "스팸"}, headers=CSRF, cookies=op)
    assert r.status_code == 200 and r.json() == {"result": "hidden", "reports_actioned": 1}
    row = await _status("TPOST", "POST_ID", pid)
    assert row["STATUS_CD"] == "hidden"
    assert row["MOD_ID"] == cv["ids"]["cv-op"], "결정자가 세션에서 오지 않았다 — 감사가 자율신고다"
    assert row["MOD_DTM"] is not None
    rep = await database.fetch_one(
        "SELECT STATUS_CD, DECIDED_BY_ID, DECIDE_NOTE_CTNT FROM TPOST_REPORT WHERE TARGET_TYPE_CD='post' AND TARGET_ID=%s",
        (pid,))
    assert (rep["STATUS_CD"], rep["DECIDED_BY_ID"], rep["DECIDE_NOTE_CTNT"]) == ("actioned", cv["ids"]["cv-op"], "스팸")
    # 공개 표면에서 사라졌다(상세 404) — 숨김이 실제로 숨긴다.
    assert (await c.get(f"/posts/{pid}")).status_code == 404
    # 두 번 숨길 수 없다(409 + 기계 토큰).
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "hide"}, headers=CSRF, cookies=op)
    assert r.status_code == 409 and r.json()["detail"] == "not_active"


@pytest.mark.asyncio
async def test_CV7_복구로_되돌아오고_카운터는_불변이다(cv):
    c, op, pid = cv["c"], cv["ck"]["op"], cv["posts"][0]
    before = await database.fetch_one("SELECT COMMENT_CNT, LIKE_CNT FROM TPOST WHERE POST_ID=%s", (pid,))
    assert (await c.post(f"/console/posts/{pid}/visibility", json={"action": "hide"}, headers=CSRF,
                         cookies=op)).status_code == 200
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "restore"}, headers=CSRF, cookies=op)
    assert r.status_code == 200 and r.json()["result"] == "restored"
    row = await _status("TPOST", "POST_ID", pid)
    assert row["STATUS_CD"] == "active" and row["MOD_ID"] == cv["ids"]["cv-op"]
    assert (await c.get(f"/posts/{pid}")).status_code == 200, "복구했는데 공개 상세가 여전히 404"
    after = await database.fetch_one("SELECT COMMENT_CNT, LIKE_CNT FROM TPOST WHERE POST_ID=%s", (pid,))
    assert after == before, "숨김/복구가 카운터를 건드렸다(운영자 hidden 은 카운터 불변 — SP-DB-18)"
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "restore"}, headers=CSRF, cookies=op)
    assert r.status_code == 409 and r.json()["detail"] == "not_hidden"


@pytest.mark.asyncio
async def test_CV8_댓글도_같고_작성자_삭제와_없는_대상은_되살리지_않는다(cv):
    c, op, cid = cv["c"], cv["ck"]["op"], cv["comment"]
    for action, expect in (("hide", "hidden"), ("restore", "restored")):
        r = await c.post(f"/console/comments/{cid}/visibility", json={"action": action}, headers=CSRF, cookies=op)
        assert r.status_code == 200 and r.json()["result"] == expect
    assert (await _status("TPOST_COMMENT", "COMMENT_ID", cid))["MOD_ID"] == cv["ids"]["cv-op"]

    # 작성자 본인 삭제(deleted)는 운영자가 되살리지 않는다 — 본문이 이미 마스킹돼 되살릴 원문이 없다.
    await database.execute("UPDATE TPOST SET STATUS_CD='deleted' WHERE POST_ID=%s", (cv["posts"][1],))
    for action, token in (("hide", "not_active"), ("restore", "not_hidden")):
        r = await c.post(f"/console/posts/{cv['posts'][1]}/visibility", json={"action": action}, headers=CSRF, cookies=op)
        assert r.status_code == 409 and r.json()["detail"] == token
    r = await c.post("/console/posts/999999999/visibility", json={"action": "hide"}, headers=CSRF, cookies=op)
    assert r.status_code == 409 and r.json()["detail"] == "not_found", "관문의 404 와 섞이지 않게 409 로 준다"
    # 하드 삭제 같은 다른 조작은 입력 단계에서 거부.
    r = await c.post(f"/console/comments/{cid}/visibility", json={"action": "delete"}, headers=CSRF, cookies=op)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_CV9_숨김_복구는_운영자만(cv):
    c, pid = cv["c"], cv["posts"][0]
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "hide"}, headers=CSRF, cookies=cv["ck"]["alice"])
    assert r.status_code == 404
    r = await c.post(f"/console/posts/{pid}/visibility", json={"action": "hide"},
                     headers={**_via("jobcho.wiki"), **CSRF}, cookies=cv["ck"]["op"])
    assert r.status_code == 404, "본 호스트 경유 쓰기가 관문을 넘었다"
    assert (await _status("TPOST", "POST_ID", pid))["STATUS_CD"] == "active"


# ── CV-10: 현황 숫자 ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CV10_현황은_건수를_정확히_센다(cv):
    """다른 테스트의 잔여 행에 흔들리지 않게 **증분**으로 잰다 — 한 번 읽고, 알려진 행을 더하고, 다시 읽는다."""
    from server.services import console_view, report as report_svc

    op = cv["ids"]["cv-op"]
    a = await console_view.overview()
    await database.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES ('cv-new@example.com', 'cv-new')")
    await report_svc.set_visibility("post", cv["posts"][1], "hide", op, None)
    await report_svc.set_visibility("comment", cv["comment"], "hide", op, None)
    await database.execute("INSERT INTO TBENEFIT_EDIT_LOG (COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD) VALUES (%s, %s, 'delete')",
                           (cv["comp"], op))
    await database.execute("INSERT INTO TMAIL_SUPPRESSION (TARGET_HASH_VAL, REASON_CD) VALUES (%s, 'hard_bounce')",
                           ("d" * 64,))
    b = await console_view.overview()

    assert b["members"]["total"] - a["members"]["total"] == 1
    assert b["members"]["active"] - a["members"]["active"] == 1
    assert b["members"]["new_7d"] - a["members"]["new_7d"] == 1
    assert b["members"]["new_30d"] - a["members"]["new_30d"] == 1
    assert b["posts"]["hidden"] - a["posts"]["hidden"] == 1 and b["posts"]["total"] == a["posts"]["total"]
    assert b["comments"]["hidden"] - a["comments"]["hidden"] == 1
    assert b["benefit_edits"]["total"] - a["benefit_edits"]["total"] == 1
    assert b["benefit_edits"]["new_30d"] - a["benefit_edits"]["new_30d"] == 1
    assert b["mail_suppression"]["active"] - a["mail_suppression"]["active"] == 1
    # 픽스처가 심은 대기 건은 이미 a 에 들어 있다 — 최소한 그만큼은 있어야 한다.
    assert a["verifications"]["pending"] >= 1 and a["verifications"]["active"] >= 1 and a["reports"]["pending"] >= 1
    assert a["posts"]["new_7d"] >= 2 and a["comments"]["new_7d"] >= 1
    assert b["as_of"] and re.match(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$", b["as_of"])


# ── CV-11: 잠금 충돌은 500 이 아니라 409 busy ────────────────────────────────

@pytest.mark.asyncio
async def test_CV11_게시판_숨김과_신고_처리의_잠금_충돌은_409다(cv, monkeypatch):
    """두 경로의 잠금 순서가 반대라(대상→신고 행 / 신고 행→대상) 정확히 동시에 돌면 InnoDB 가 한쪽을 교착(1213)
    으로 되돌린다(2026-09-18 적대 검토). 그때 운영자는 500 이 아니라 "다시 하라"를 봐야 한다. 교착 자체를
    결정적으로 재현할 수 없어 서비스가 그 오류를 던지게 하고 라우터의 번역만 잰다. 다른 DB 오류는 그대로 500."""
    from pymysql.err import OperationalError

    from server.services import report as report_svc

    async def deadlock(*a, **k):
        raise OperationalError(1213, "Deadlock found when trying to get lock")

    async def gone(*a, **k):
        raise OperationalError(2013, "Lost connection to MySQL server during query")

    c, op = cv["c"], cv["ck"]["op"]
    monkeypatch.setattr(report_svc, "set_visibility", deadlock)
    monkeypatch.setattr(report_svc, "decide_report", deadlock)
    r = await c.post(f"/console/posts/{cv['posts'][0]}/visibility", json={"action": "hide"}, headers=CSRF, cookies=op)
    assert r.status_code == 409 and r.json()["detail"] == "busy"
    r = await c.post("/console/reports/1/decide", json={"action": "hide"}, headers=CSRF, cookies=op)
    assert r.status_code == 409 and r.json()["detail"] == "busy"
    monkeypatch.setattr(report_svc, "set_visibility", gone)
    r = await c.post(f"/console/posts/{cv['posts'][0]}/visibility", json={"action": "hide"}, headers=CSRF, cookies=op)
    assert r.status_code == 500, "잠금 충돌이 아닌 DB 오류까지 409 로 삼켰다"


# ── CV-12~15: 조치 이력(L8)·잠금 순서(L3) — 2026-09-18 적대 검토 반영 ─────────────────────

def test_CV12_조치_이력_마이그레이션은_schema_와_같은_DDL_이다():
    """마이그레이션은 기존 서빙 DB 용 사본이다 — 두 DDL 이 갈라지면 운영과 테스트가 다른 표를 본다."""
    from server.tests.conftest import MIGRATIONS_DIR, SCHEMA_SQL

    def ddl(text: str) -> str:
        m = re.search(r"CREATE TABLE IF NOT EXISTS TPOST_ACTION_LOG \(.*?\) ENGINE=InnoDB[^;]*;", text, re.S)
        assert m, "TPOST_ACTION_LOG DDL 을 찾지 못했다"
        return m.group(0)

    mig = (MIGRATIONS_DIR / "20260918_add_post_action_log.sql").read_text(encoding="utf-8")
    assert ddl(mig) == ddl(SCHEMA_SQL.read_text(encoding="utf-8"))


async def _log_rows(target_type: str, target_id: int) -> list[dict]:
    return list(await database.fetch_all(  # 빈 결과는 () 로 온다 — 목록 비교가 되게 list 로
        "SELECT ACTION_CD, FROM_STATUS_CD, TO_STATUS_CD, SOURCE_CD, REPORT_ID, REPORTS_ACTIONED_CNT, NOTE_CTNT, "
        "ACTOR_MBR_ID FROM TPOST_ACTION_LOG WHERE TARGET_TYPE_CD=%s AND TARGET_ID=%s ORDER BY ACTION_LOG_ID",
        (target_type, target_id)))


@pytest.mark.asyncio
async def test_CV13_숨김_복구는_메모와_주체를_잃지_않고_이력으로_쌓인다(cv):
    """대상 행의 `MOD_ID` 는 마지막 조작자만 남는다 — 숨김→복구 뒤에도 "누가 왜 숨겼나"가 이력에 남아야 한다."""
    c, op, pid, me = cv["c"], cv["ck"]["op"], cv["posts"][0], cv["ids"]["cv-op"]
    for action, note in (("hide", "cv-스팸 의심"), ("restore", "cv-오판이었다")):
        r = await c.post(f"/console/posts/{pid}/visibility", json={"action": action, "note": note},
                         headers=CSRF, cookies=op)
        assert r.status_code == 200
    rows = await _log_rows("post", pid)
    assert rows == [
        {"ACTION_CD": "hide", "FROM_STATUS_CD": "active", "TO_STATUS_CD": "hidden", "SOURCE_CD": "board",
         "REPORT_ID": None, "REPORTS_ACTIONED_CNT": 1, "NOTE_CTNT": "cv-스팸 의심", "ACTOR_MBR_ID": me},
        {"ACTION_CD": "restore", "FROM_STATUS_CD": "hidden", "TO_STATUS_CD": "active", "SOURCE_CD": "board",
         "REPORT_ID": None, "REPORTS_ACTIONED_CNT": 0, "NOTE_CTNT": "cv-오판이었다", "ACTOR_MBR_ID": me},
    ], "숨김→복구 이력이 두 행으로 남지 않았다(메모·주체 소실)"
    # 거부된 조작(409)은 이력에 남지 않는다 — 상태를 바꾸지 않았으니까.
    await c.post(f"/console/posts/{pid}/visibility", json={"action": "restore"}, headers=CSRF, cookies=op)
    assert len(await _log_rows("post", pid)) == 2
    # 게시판 화면이 이력을 보여 준다(건수 + 마지막 1건).
    item = next(p for p in (await c.get("/console/posts", params={"limit": 5}, cookies=op)).json()["items"]
                if p["post_id"] == pid)
    assert item["action_cnt"] == 2
    assert item["last_action"]["action"] == "restore" and item["last_action"]["actor_id"] == me
    assert item["last_action"]["note"] == "cv-오판이었다" and re.match(r"^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$",
                                                                     item["last_action"]["at"])


@pytest.mark.asyncio
async def test_CV14_신고_처리의_hide_도_같은_이력에_남고_dismiss_는_남지_않는다(cv):
    from server.services import report as report_svc

    pid, me = cv["posts"][0], cv["ids"]["cv-op"]
    rid = (await database.fetch_one(
        "SELECT REPORT_ID FROM TPOST_REPORT WHERE TARGET_TYPE_CD='post' AND TARGET_ID=%s", (pid,)))["REPORT_ID"]
    assert await report_svc.decide_report(rid, "hide", me, "cv-신고 확인") == "hidden"
    assert await _log_rows("post", pid) == [
        {"ACTION_CD": "hide", "FROM_STATUS_CD": "active", "TO_STATUS_CD": "hidden", "SOURCE_CD": "report",
         "REPORT_ID": rid, "REPORTS_ACTIONED_CNT": 1, "NOTE_CTNT": "cv-신고 확인", "ACTOR_MBR_ID": me}]

    # 이미 숨긴 대상을 가리키는 새 신고의 hide — 대상 상태가 안 바뀌므로 이력도 없다(신고 행만 닫힌다).
    await database.execute(
        "INSERT INTO TPOST_REPORT (TARGET_TYPE_CD, TARGET_ID, MBR_ID, REASON_CD) VALUES ('post', %s, %s, 'abuse')",
        (pid, cv["ids"]["cv-alice"]))
    rid2 = (await database.fetch_one("SELECT MAX(REPORT_ID) AS m FROM TPOST_REPORT"))["m"]
    assert await report_svc.decide_report(rid2, "hide", me, None) == "hidden"
    # 기각은 대상 불변 — 이력 없음.
    await database.execute(
        "INSERT INTO TPOST_REPORT (TARGET_TYPE_CD, TARGET_ID, MBR_ID, REASON_CD) VALUES ('comment', %s, %s, 'spam')",
        (cv["comment"], cv["ids"]["cv-alice"]))
    rid3 = (await database.fetch_one("SELECT MAX(REPORT_ID) AS m FROM TPOST_REPORT"))["m"]
    assert await report_svc.decide_report(rid3, "dismiss", me, None) == "dismissed"
    assert len(await _log_rows("post", pid)) == 1 and await _log_rows("comment", cv["comment"]) == []


@pytest.mark.asyncio
async def test_CV14b_이력_기록이_실패하면_상태_변경도_되돌린다(cv, monkeypatch):
    """상태는 바뀌었는데 이력이 없는 순간이 없어야 한다 — 같은 트랜잭션이라 이력 INSERT 가 실패하면 숨김도 없다."""
    from server.services import report as report_svc

    monkeypatch.setattr(report_svc, "SQL_INSERT_ACTION_LOG", "INSERT INTO TPOST_ACTION_LOG_NOPE (X) VALUES (%s)")
    with pytest.raises(Exception):
        await report_svc.set_visibility("post", cv["posts"][0], "hide", cv["ids"]["cv-op"], None)
    assert (await _status("TPOST", "POST_ID", cv["posts"][0]))["STATUS_CD"] == "active", "이력 없이 상태만 바뀌었다"


async def _assert_target_locked_before_reports(pid: int, run) -> object:
    """대상 글 행을 다른 트랜잭션이 쥔 채로 `run()` 을 돌린다 → run 은 대상 잠금에서 **기다려야** 하고,
    그동안 그 대상의 신고 행은 **아무도 잠그지 않은** 상태여야 한다(`FOR UPDATE NOWAIT` 가 성공).
    옛 순서(신고 행 → 대상)였다면 run 이 신고 행을 먼저 쥐고 대상에서 멈춰, NOWAIT 가 3572 로 실패한다."""
    pool = database.get_pool()
    async with pool.acquire() as holder:
        await holder.begin()
        async with holder.cursor() as cur:
            await cur.execute("SELECT POST_ID FROM TPOST WHERE POST_ID=%s FOR UPDATE", (pid,))
        task = asyncio.create_task(run())
        try:
            await asyncio.sleep(0.5)
            assert not task.done(), "대상 잠금을 기다리지 않았다 — 대상 행을 먼저 잠그지 않는다"
            async with pool.acquire() as prober:
                await prober.begin()
                try:
                    async with prober.cursor() as cur:
                        await cur.execute(
                            "SELECT REPORT_ID FROM TPOST_REPORT WHERE TARGET_TYPE_CD='post' AND TARGET_ID=%s "
                            "FOR UPDATE NOWAIT", (pid,))
                finally:
                    await prober.rollback()
        finally:
            await holder.commit()
    return await asyncio.wait_for(task, 10)


@pytest.mark.asyncio
async def test_CV15_두_숨김_경로는_같은_잠금_순서다_대상_먼저(cv):
    """L3(2026-09-18 적대 검토): 신고 처리는 신고 행 → 대상, 게시판 숨김은 대상 → 신고 행이라 동시에 돌면
    교착이 났다. 두 경로 모두 **대상 먼저**여야 순환 대기가 없다 — 실제 잠금으로 순서를 잰다."""
    from server.services import report as report_svc

    pid, me = cv["posts"][0], cv["ids"]["cv-op"]
    rid = (await database.fetch_one(
        "SELECT REPORT_ID FROM TPOST_REPORT WHERE TARGET_TYPE_CD='post' AND TARGET_ID=%s", (pid,)))["REPORT_ID"]
    assert await _assert_target_locked_before_reports(
        pid, lambda: report_svc.decide_report(rid, "hide", me, None)) == "hidden"
    out = await _assert_target_locked_before_reports(
        pid, lambda: report_svc.set_visibility("post", pid, "restore", me, None))
    assert out["result"] == "restored"
