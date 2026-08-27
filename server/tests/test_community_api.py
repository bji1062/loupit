"""SC15 커뮤니티 API — **실 DB** 왕복 + httpx 상태코드 매트릭스 (CM-3~CM-7).

근거: `docs/FRD/14-커뮤니티-API.md` FR-121~131 · `docs/SPEC/14-커뮤니티.md` SP-COMM-4~6.

**왜 스텁이 아니라 실 DB 인가.** 목록 SQL 은 닉네임·회사·재직 배지 조인과 상관 서브쿼리를 포함하고,
좋아요·댓글은 카운터를 같은 트랜잭션에서 움직인다. 그 구간을 SQL 텍스트 패턴 스텁으로 흉내 내면
"픽스처가 파이프라인을 건너뛰는 테스트는 그 구간에 없는 것과 같다"(HANDOFF-2026-08-21 §4).
그래서 `schema_db` 위에 aiomysql 풀을 열고(test_console_flow_db 와 같은 방식) 앱을 httpx
ASGITransport 로 두드린다 — 세션 쿠키·CSRF 헤더·의존성 순서까지 실제 경로 그대로다.

⚠ 이 파일은 `DB_NAME` 이 가리키는 DB 에 실제로 쓴다(conftest 가드가 `loupit_test` 로 제한).
자기 행(회원 3·회사 1·커뮤니티 4테이블)만 만들고 치운다 — 시드 회사를 지우지 않는다.
"""
from __future__ import annotations

import httpx
import pytest
import pytest_asyncio
from fastapi.routing import APIRoute

from server import database

OP_EMAIL = "comm-operator@example.com"
ALICE_EMAIL = "comm-alice@example.com"
BOB_EMAIL = "comm-bob@example.com"
CSRF = {"X-Loupit-Client": "test"}
COMMUNITY_TABLES = ("TPOST_REPORT", "TPOST_REACTION", "TPOST_COMMENT", "TPOST")


async def _clean(emails: tuple[str, ...], comp_eng: str) -> None:
    for t in COMMUNITY_TABLES:
        await database.execute(f"DELETE FROM {t}")
    # 세션·재직 인증은 TMEMBER CASCADE 로 함께 사라진다.
    fmt = ",".join(["%s"] * len(emails))
    await database.execute(f"DELETE FROM TMEMBER WHERE LOGIN_EMAIL_NM IN ({fmt})", emails)
    await database.execute("DELETE FROM TCOMPANY WHERE COMP_ENG_NM=%s", (comp_eng,))
    await database.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_CD=%s", ("comm_tp",))


@pytest_asyncio.fixture
async def comm(schema_db, monkeypatch):
    """운영자 1 · 일반 회원 2(alice 는 회사 재직 인증 보유) · 회사 1 + 세션 3개 + 앱 클라이언트."""
    from server.config import get_settings
    from server.main import create_app
    from server.services import session as session_svc

    await database.init_pool()
    s = get_settings()
    monkeypatch.setattr(s, "operator_emails", OP_EMAIL)  # 콘솔 라우터 등록 조건 + is_operator
    comp_eng = "Comm Test Co"
    emails = (OP_EMAIL, ALICE_EMAIL, BOB_EMAIL)
    await _clean(emails, comp_eng)
    try:
        await database.execute(
            "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s,'comm-op'), (%s,'comm-alice'), (%s,'comm-bob')",
            emails,
        )
        ids = {r["LOGIN_EMAIL_NM"]: r["MBR_ID"] for r in await database.fetch_all(
            f"SELECT MBR_ID, LOGIN_EMAIL_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM IN (%s,%s,%s)", emails)}
        await database.execute(
            "INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES ('comm_tp', '테스트유형')")
        tp = (await database.fetch_one("SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='comm_tp'"))["COMP_TP_ID"]
        await database.execute(
            "INSERT INTO TCOMPANY (COMP_NM, COMP_ENG_NM, COMP_TP_ID) VALUES ('커뮤테스트사', %s, %s)", (comp_eng, tp))
        comp = (await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (comp_eng,)))["COMP_ID"]
        await database.execute(
            "INSERT INTO TEMPLOY_VERIFICATION (MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM) "
            "VALUES (%s, %s, 'domain', %s, UTC_TIMESTAMP() + INTERVAL 30 DAY)",
            (ids[ALICE_EMAIL], comp, "a" * 64))
        cookies = {name: {"loupit_sid": await session_svc.issue_session(ids[email])}
                   for name, email in (("op", OP_EMAIL), ("alice", ALICE_EMAIL), ("bob", BOB_EMAIL))}

        app = create_app()
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://t/api/v1") as c:
            yield {
                "c": c, "app": app, "comp": comp, "comp_slug": "comm-test-co",
                "op": ids[OP_EMAIL], "alice": ids[ALICE_EMAIL], "bob": ids[BOB_EMAIL],
                "ck": cookies, "settings": s,
            }
    finally:
        await _clean(emails, comp_eng)
        await database.close_pool()


async def _post(env, who: str, **over) -> int:
    body = {"category": "free", "title": "제목", "body": "본문", **over}
    r = await env["c"].post("/posts", json=body, headers=CSRF, cookies=env["ck"][who])
    assert r.status_code == 201, r.text
    return r.json()["post_id"]


async def _comment(env, who: str, post_id: int, body: str = "댓글") -> int:
    r = await env["c"].post(f"/posts/{post_id}/comments", json={"body": body}, headers=CSRF, cookies=env["ck"][who])
    assert r.status_code == 201, r.text
    return r.json()["comment_id"]


# ── CM-3 목록 ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CM3_1_empty_list_is_anonymous_and_no_store(comm):
    r = await comm["c"].get("/posts")
    assert r.status_code == 200
    assert r.json() == {"items": [], "next_before": None}
    assert r.headers["cache-control"] == "no-store"


@pytest.mark.asyncio
async def test_CM3_2_list_shape_nickname_badge_tag_and_no_view_count(comm):
    """항목 = 닉네임만(INV-8) + 재직 배지 + 회사 태그(slug) + 카운터. 조회수 키 없음. active 만."""
    a = await _post(comm, "alice", comp_id=comm["comp"])
    b = await _post(comm, "bob", title="밥의 글")
    deleted = await _post(comm, "bob", title="곧 지움")
    r = await comm["c"].delete(f"/posts/{deleted}", headers=CSRF, cookies=comm["ck"]["bob"])
    assert r.status_code == 204

    items = (await comm["c"].get("/posts")).json()["items"]
    assert [i["post_id"] for i in items] == [b, a], "최신순(POST_ID DESC) · deleted 제외"
    alice_item = items[1]
    assert set(alice_item) == {"post_id", "category", "title", "nickname", "verified_comp_nm", "comp",
                               "like_cnt", "comment_cnt", "created_at", "edited"}
    assert alice_item["nickname"] == "comm-alice"
    assert alice_item["verified_comp_nm"] == "커뮤테스트사", "활성 재직 인증 → 배지용 회사명"
    assert alice_item["comp"] == {"comp_id": comm["comp"], "comp_nm": "커뮤테스트사", "slug": comm["comp_slug"]}
    assert alice_item["edited"] is False and alice_item["like_cnt"] == 0 and alice_item["comment_cnt"] == 0
    bob_item = items[0]
    assert bob_item["verified_comp_nm"] is None and bob_item["comp"] is None
    for i in items:
        assert not any("view" in k or "hit" in k for k in i), "조회수 키가 응답에 있다(FR 전제 4)"
        assert "email" not in str(i).lower() and "mbr_id" not in i


@pytest.mark.asyncio
async def test_CM3_3_category_filter_and_422(comm):
    free = await _post(comm, "alice")
    career = await _post(comm, "alice", category="career")
    assert [i["post_id"] for i in (await comm["c"].get("/posts?category=career")).json()["items"]] == [career]
    assert [i["post_id"] for i in (await comm["c"].get("/posts?category=free")).json()["items"]] == [free]
    for bad in ("/posts?category=news", "/posts?sort=views", "/posts?limit=51", "/posts?limit=0", "/posts?before=0"):
        r = await comm["c"].get(bad)
        assert r.status_code == 422, bad
        assert r.headers["cache-control"] == "no-store"
    assert (await comm["c"].get("/posts?limit=50")).status_code == 200


@pytest.mark.asyncio
async def test_CM3_4_keyset_paging_and_sorts(comm):
    ids = [await _post(comm, "alice", title=f"글{i}") for i in range(5)]
    p1 = (await comm["c"].get("/posts?limit=2")).json()
    assert [i["post_id"] for i in p1["items"]] == [ids[4], ids[3]]
    assert p1["next_before"] == ids[3]
    p2 = (await comm["c"].get(f"/posts?limit=2&before={p1['next_before']}")).json()
    assert [i["post_id"] for i in p2["items"]] == [ids[2], ids[1]]
    p3 = (await comm["c"].get(f"/posts?limit=2&before={p2['next_before']}")).json()
    assert [i["post_id"] for i in p3["items"]] == [ids[0]]
    assert p3["next_before"] is None, "마지막 페이지는 next_before=null(LIMIT+1 판정)"

    # 좋아요·댓글 정렬 — 카운터 DESC, 동률은 POST_ID DESC
    for who in ("alice", "bob"):
        assert (await comm["c"].put(f"/posts/{ids[1]}/like", headers=CSRF, cookies=comm["ck"][who])).status_code == 200
    await comm["c"].put(f"/posts/{ids[0]}/like", headers=CSRF, cookies=comm["ck"]["bob"])
    likes = [i["post_id"] for i in (await comm["c"].get("/posts?sort=likes")).json()["items"]]
    assert likes == [ids[1], ids[0], ids[4], ids[3], ids[2]]
    await _comment(comm, "bob", ids[2])
    comments = [i["post_id"] for i in (await comm["c"].get("/posts?sort=comments")).json()["items"]]
    assert comments[0] == ids[2]


# ── CM-4 상세 ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CM4_1_detail_optional_member_is_mine_liked(comm):
    p = await _post(comm, "alice", body="본문 내용")
    anon = await comm["c"].get(f"/posts/{p}")
    assert anon.status_code == 200 and anon.headers["cache-control"] == "no-store"
    d = anon.json()
    assert d["body"] == "본문 내용" and d["is_mine"] is False and d["liked"] is False
    assert d["updated_at"] is None and d["edited"] is False
    assert "email" not in str(d).lower() and "mbr_id" not in d

    mine = (await comm["c"].get(f"/posts/{p}", cookies=comm["ck"]["alice"])).json()
    assert mine["is_mine"] is True and mine["liked"] is False
    await comm["c"].put(f"/posts/{p}/like", headers=CSRF, cookies=comm["ck"]["bob"])
    bob = (await comm["c"].get(f"/posts/{p}", cookies=comm["ck"]["bob"])).json()
    assert bob["is_mine"] is False and bob["liked"] is True and bob["like_cnt"] == 1


@pytest.mark.asyncio
async def test_CM4_2_garbage_cookie_is_anonymous_not_401(comm):
    """익명 경로다 — 위조·만료 쿠키가 와도 401 이 아니라 익명으로 읽는다(optional_member)."""
    p = await _post(comm, "alice")
    r = await comm["c"].get(f"/posts/{p}", cookies={"loupit_sid": "forged-or-expired"})
    assert r.status_code == 200 and r.json()["is_mine"] is False


@pytest.mark.asyncio
async def test_CM4_3_deleted_hidden_missing_are_404(comm):
    p = await _post(comm, "alice")
    await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["alice"])
    assert (await comm["c"].get(f"/posts/{p}")).status_code == 404
    h = await _post(comm, "alice")
    await database.execute("UPDATE TPOST SET STATUS_CD='hidden' WHERE POST_ID=%s", (h,))
    assert (await comm["c"].get(f"/posts/{h}")).status_code == 404
    assert (await comm["c"].get(f"/posts/{h}/comments")).status_code == 404
    assert (await comm["c"].get("/posts/999999")).status_code == 404
    assert (await comm["c"].get("/posts/0")).status_code == 422


# ── CM-5 쓰기: 관문·권한·경계·상한 ─────────────────────────────────────────

@pytest.mark.asyncio
async def test_CM5_1_csrf_then_session_order(comm):
    """`require_csrf` → `require_member` 순서: 헤더 없으면 세션이 있어도 403, 헤더 있고 세션 없으면 401."""
    body = {"category": "free", "title": "t", "body": "b"}
    assert (await comm["c"].post("/posts", json=body, cookies=comm["ck"]["alice"])).status_code == 403
    assert (await comm["c"].post("/posts", json=body, headers=CSRF)).status_code == 401
    assert (await comm["c"].post("/posts", json=body, headers=CSRF, cookies={"loupit_sid": "x"})).status_code == 401
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 201 and set(r.json()) == {"post_id"} and r.headers["cache-control"] == "no-store"


@pytest.mark.asyncio
async def test_CM5_2_notice_is_operator_only(comm):
    body = {"category": "notice", "title": "공지", "body": "b"}
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 403
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["op"])
    assert r.status_code == 201
    assert (await comm["c"].get(f"/posts/{r.json()['post_id']}")).json()["category"] == "notice"


@pytest.mark.asyncio
async def test_CM5_3_unknown_company_tag_is_422(comm):
    body = {"category": "free", "title": "t", "body": "b", "comp_id": 999999}
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_CM5_4_validation_422_through_route(comm):
    """모델 422 가 라우트에서 type·loc·msg 만 노출한다(NFR31 — 입력 원문 반향 없음)."""
    body = {"category": "free", "title": "   ", "body": "비밀본문"}
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 422
    assert "비밀본문" not in r.text
    assert set(r.json()["detail"][0]) == {"type", "loc", "msg"}


@pytest.mark.asyncio
async def test_CM5_5_daily_post_limit_429(comm, monkeypatch):
    monkeypatch.setattr(comm["settings"], "daily_post_limit", 2)
    await _post(comm, "alice")
    await _post(comm, "alice")
    body = {"category": "free", "title": "t", "body": "b"}
    r = await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 429
    assert (await comm["c"].post("/posts", json=body, headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 201, \
        "상한은 계정별이다"


@pytest.mark.asyncio
async def test_CM5_6_update_and_soft_delete_owner_only(comm):
    p = await _post(comm, "alice", comp_id=comm["comp"])
    upd = {"title": "수정됨", "body": "수정 본문", "comp_id": None}
    assert (await comm["c"].put(f"/posts/{p}", json=upd, cookies=comm["ck"]["alice"])).status_code == 403  # CSRF
    assert (await comm["c"].put(f"/posts/{p}", json=upd, headers=CSRF)).status_code == 401
    assert (await comm["c"].put(f"/posts/{p}", json=upd, headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 403
    assert (await comm["c"].put(f"/posts/{p}", json={**upd, "category": "notice"}, headers=CSRF,
                                cookies=comm["ck"]["alice"])).status_code == 200, "category 는 무시된다(extra ignore)"
    r = await comm["c"].put(f"/posts/{p}", json=upd, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 200 and set(r.json()) == {"post_id", "updated_at"} and r.json()["updated_at"]
    d = (await comm["c"].get(f"/posts/{p}")).json()
    assert d["title"] == "수정됨" and d["edited"] is True and d["comp"] is None and d["category"] == "free"
    assert d["updated_at"] is not None

    # 삭제: 본인만 · 소프트 · 마스킹 · 운영자도 이 라우트로는 못 지운다(FR-126)
    assert (await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 403
    assert (await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["op"])).status_code == 403
    assert (await comm["c"].delete(f"/posts/{p}", headers=CSRF)).status_code == 401
    r = await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 204 and r.headers["cache-control"] == "no-store"
    row = await database.fetch_one("SELECT STATUS_CD, TITLE_NM, BODY_CTNT FROM TPOST WHERE POST_ID=%s", (p,))
    assert row == {"STATUS_CD": "deleted", "TITLE_NM": "(삭제됨)", "BODY_CTNT": ""}, "원문 보존 없음"
    assert (await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["alice"])).status_code == 404
    assert (await comm["c"].put(f"/posts/{p}", json=upd, headers=CSRF, cookies=comm["ck"]["alice"])).status_code == 404


@pytest.mark.asyncio
async def test_CM5_7_comments_counter_cursor_soft_delete(comm, monkeypatch):
    p = await _post(comm, "alice")
    assert (await comm["c"].post(f"/posts/{p}/comments", json={"body": "x"}, cookies=comm["ck"]["bob"])).status_code == 403
    assert (await comm["c"].post(f"/posts/{p}/comments", json={"body": "x"}, headers=CSRF)).status_code == 401
    c1 = await _comment(comm, "bob", p, "첫 댓글")
    c2 = await _comment(comm, "alice", p, "둘째")
    c3 = await _comment(comm, "bob", p, "셋째")
    assert (await comm["c"].get(f"/posts/{p}")).json()["comment_cnt"] == 3

    lst = (await comm["c"].get(f"/posts/{p}/comments?limit=2")).json()
    assert [i["comment_id"] for i in lst["items"]] == [c1, c2], "오래된 순(COMMENT_ID ASC)"
    assert lst["next_after"] == c2
    assert lst["items"][1]["verified_comp_nm"] == "커뮤테스트사" and lst["items"][0]["verified_comp_nm"] is None
    assert set(lst["items"][0]) == {"comment_id", "nickname", "verified_comp_nm", "body", "deleted", "is_mine", "created_at"}
    rest = (await comm["c"].get(f"/posts/{p}/comments?after={c2}", cookies=comm["ck"]["bob"])).json()
    assert [i["comment_id"] for i in rest["items"]] == [c3] and rest["next_after"] is None
    assert rest["items"][0]["is_mine"] is True

    # 삭제: 본인만 · 자리 표시 · COMMENT_CNT-1 · 두 번 지워도 카운터는 한 번만
    assert (await comm["c"].delete(f"/posts/{p}/comments/{c1}", headers=CSRF, cookies=comm["ck"]["alice"])).status_code == 403
    assert (await comm["c"].delete(f"/posts/{p}/comments/{c1}", headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 204
    assert (await comm["c"].delete(f"/posts/{p}/comments/{c1}", headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 404
    assert (await comm["c"].get(f"/posts/{p}")).json()["comment_cnt"] == 2
    first = (await comm["c"].get(f"/posts/{p}/comments")).json()["items"][0]
    assert first["comment_id"] == c1 and first["body"] is None and first["deleted"] is True
    row = await database.fetch_one("SELECT STATUS_CD, BODY_CTNT FROM TPOST_COMMENT WHERE COMMENT_ID=%s", (c1,))
    assert row == {"STATUS_CD": "deleted", "BODY_CTNT": ""}
    # 다른 글의 댓글 ID 로는 지울 수 없다(경로 불일치 404)
    other = await _post(comm, "alice")
    assert (await comm["c"].delete(f"/posts/{other}/comments/{c2}", headers=CSRF, cookies=comm["ck"]["alice"])).status_code == 404

    # 일일 상한
    monkeypatch.setattr(comm["settings"], "daily_comment_limit", 2)
    r = await comm["c"].post(f"/posts/{p}/comments", json={"body": "넷째"}, headers=CSRF, cookies=comm["ck"]["bob"])
    assert r.status_code == 429, "bob 은 오늘 이미 2건(삭제한 것도 센다 — INS_DTM 기준)"

    # 삭제된 글에는 댓글을 못 단다
    await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["alice"])
    r = await comm["c"].post(f"/posts/{p}/comments", json={"body": "x"}, headers=CSRF, cookies=comm["ck"]["alice"])
    assert r.status_code == 404


# ── CM-6 좋아요 토글 (실 DB 카운터 정합) ───────────────────────────────────

@pytest.mark.asyncio
async def test_CM6_1_like_toggle_idempotent_counter_consistent(comm):
    p = await _post(comm, "alice")
    assert (await comm["c"].put(f"/posts/{p}/like", cookies=comm["ck"]["bob"])).status_code == 403
    assert (await comm["c"].put(f"/posts/{p}/like", headers=CSRF)).status_code == 401

    async def like(who):
        r = await comm["c"].put(f"/posts/{p}/like", headers=CSRF, cookies=comm["ck"][who])
        assert r.status_code == 200 and r.headers["cache-control"] == "no-store"
        return r.json()

    async def db_state():
        cnt = (await database.fetch_one("SELECT LIKE_CNT FROM TPOST WHERE POST_ID=%s", (p,)))["LIKE_CNT"]
        rows = (await database.fetch_one("SELECT COUNT(*) AS n FROM TPOST_REACTION WHERE POST_ID=%s", (p,)))["n"]
        return cnt, rows

    assert await like("bob") == {"liked": True, "like_cnt": 1}
    assert await like("alice") == {"liked": True, "like_cnt": 2}
    assert await db_state() == (2, 2)
    assert await like("bob") == {"liked": False, "like_cnt": 1}
    assert await db_state() == (1, 1)
    assert await like("bob") == {"liked": True, "like_cnt": 2}
    assert await like("alice") == {"liked": False, "like_cnt": 1}
    assert await db_state() == (1, 1), "카운터 = 실제 반응 행 수 (트랜잭션 정합)"
    assert (await comm["c"].get(f"/posts/{p}", cookies=comm["ck"]["bob"])).json()["liked"] is True

    await comm["c"].delete(f"/posts/{p}", headers=CSRF, cookies=comm["ck"]["alice"])
    assert (await comm["c"].put(f"/posts/{p}/like", headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 404


# ── CM-7 신고·콘솔 ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_CM7_1_report_matrix(comm, monkeypatch):
    p = await _post(comm, "alice")
    c = await _comment(comm, "alice", p)
    rep = {"target_type": "post", "target_id": p, "reason": "spam", "detail": "광고"}
    assert (await comm["c"].post("/reports", json=rep, cookies=comm["ck"]["bob"])).status_code == 403
    assert (await comm["c"].post("/reports", json=rep, headers=CSRF)).status_code == 401
    r = await comm["c"].post("/reports", json=rep, headers=CSRF, cookies=comm["ck"]["bob"])
    assert r.status_code == 202 and set(r.json()) == {"report_id"} and r.headers["cache-control"] == "no-store"
    assert (await comm["c"].post("/reports", json=rep, headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 409
    assert (await comm["c"].post("/reports", json={**rep, "target_type": "comment", "target_id": c},
                                 headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 202
    assert (await comm["c"].post("/reports", json={**rep, "target_id": 999999},
                                 headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 404
    assert (await comm["c"].post("/reports", json={**rep, "reason": "hate"},
                                 headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 422
    # 접수는 대상을 바꾸지 않는다(자동 숨김 없음)
    assert (await comm["c"].get(f"/posts/{p}")).status_code == 200
    # 삭제된 글은 신고 대상이 아니다
    d = await _post(comm, "alice")
    await comm["c"].delete(f"/posts/{d}", headers=CSRF, cookies=comm["ck"]["alice"])
    assert (await comm["c"].post("/reports", json={**rep, "target_id": d},
                                 headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 404
    # 일일 상한
    monkeypatch.setattr(comm["settings"], "daily_report_limit", 2)
    q = await _post(comm, "alice")
    assert (await comm["c"].post("/reports", json={**rep, "target_id": q},
                                 headers=CSRF, cookies=comm["ck"]["bob"])).status_code == 429


@pytest.mark.asyncio
async def test_CM7_2_console_queue_and_decide(comm):
    p = await _post(comm, "alice", title="가" * 100)
    c = await _comment(comm, "alice", p, "나" * 200)
    for who, reason in (("bob", "spam"), ("op", "abuse")):
        assert (await comm["c"].post("/reports", json={"target_type": "post", "target_id": p, "reason": reason},
                                     headers=CSRF, cookies=comm["ck"][who])).status_code == 202
    rc = await comm["c"].post("/reports", json={"target_type": "comment", "target_id": c, "reason": "privacy",
                                                "detail": "<b>원문</b>"}, headers=CSRF, cookies=comm["ck"]["bob"])
    assert rc.status_code == 202

    # 관문: 비운영자 404 · 프록시 경유 404 · 운영자 통과
    assert (await comm["c"].get("/console/queues", cookies=comm["ck"]["alice"])).status_code == 404
    assert (await comm["c"].get("/console/queues", cookies=comm["ck"]["op"],
                                headers={"X-Real-IP": "203.0.113.9"})).status_code == 404
    q = await comm["c"].get("/console/queues", cookies=comm["ck"]["op"])
    assert q.status_code == 200
    reports = q.json()["reports"]
    assert len(reports) == 3
    by_id = {r["report_id"]: r for r in reports}
    assert set(reports[0]) == {"report_id", "target_type", "target_id", "excerpt", "reason", "detail",
                               "reporter_nickname", "created_at"}
    post_reports = [r for r in reports if r["target_type"] == "post"]
    assert {r["reporter_nickname"] for r in post_reports} == {"comm-bob", "comm-op"}
    assert all(len(r["excerpt"]) <= 80 for r in reports), "발췌는 80자 이내"
    comment_report = next(r for r in reports if r["target_type"] == "comment")
    assert comment_report["excerpt"] == "나" * 80 and comment_report["detail"] == "<b>원문</b>", "서버는 값을 가공하지 않는다"
    assert "email" not in str(reports).lower()

    # hide: 대상 hidden + 같은 대상의 다른 pending 일괄 actioned + DECIDED_BY 자동 주입
    first_post_report = post_reports[0]["report_id"]
    body = {"action": "hide", "note": "광고 확인"}
    assert (await comm["c"].post(f"/console/reports/{first_post_report}/decide", json=body,
                                 cookies=comm["ck"]["op"])).status_code == 403  # CSRF
    assert (await comm["c"].post(f"/console/reports/{first_post_report}/decide", json=body, headers=CSRF,
                                 cookies=comm["ck"]["alice"])).status_code == 404
    r = await comm["c"].post(f"/console/reports/{first_post_report}/decide", json=body, headers=CSRF,
                             cookies=comm["ck"]["op"])
    assert r.status_code == 200 and r.json()["result"] == "hidden"
    assert (await comm["c"].get(f"/posts/{p}")).status_code == 404, "hidden 글은 상세 404"
    rows = await database.fetch_all(
        "SELECT REPORT_ID, STATUS_CD, DECIDED_BY_ID, DECIDED_DTM, DECIDE_NOTE_CTNT FROM TPOST_REPORT "
        "WHERE TARGET_TYPE_CD='post' AND TARGET_ID=%s", (p,))
    assert {r["STATUS_CD"] for r in rows} == {"actioned"} and len(rows) == 2
    assert all(r["DECIDED_BY_ID"] == comm["op"] and r["DECIDED_DTM"] is not None for r in rows), \
        "결정자가 세션에서 오지 않았다 — 감사가 자율신고다"
    assert {r["DECIDE_NOTE_CTNT"] for r in rows} == {"광고 확인"}
    # 두 번 결정할 수 없다
    assert (await comm["c"].post(f"/console/reports/{first_post_report}/decide", json=body, headers=CSRF,
                                 cookies=comm["ck"]["op"])).status_code == 409
    # 큐에서 사라졌다(댓글 신고만 남음)
    left = (await comm["c"].get("/console/queues", cookies=comm["ck"]["op"])).json()["reports"]
    assert [r["report_id"] for r in left] == [comment_report["report_id"]]

    # dismiss: 대상 불변 · 해당 신고만 dismissed
    r = await comm["c"].post(f"/console/reports/{comment_report['report_id']}/decide",
                             json={"action": "dismiss", "note": None}, headers=CSRF, cookies=comm["ck"]["op"])
    assert r.status_code == 200 and r.json()["result"] == "dismissed"
    assert (await database.fetch_one("SELECT STATUS_CD FROM TPOST_COMMENT WHERE COMMENT_ID=%s", (c,)))["STATUS_CD"] == "active"
    assert (await database.fetch_one("SELECT STATUS_CD FROM TPOST_REPORT WHERE REPORT_ID=%s",
                                     (comment_report["report_id"],)))["STATUS_CD"] == "dismissed"
    assert (await comm["c"].get("/console/queues", cookies=comm["ck"]["op"])).json()["reports"] == []
    # 없는 신고·잘못된 action
    assert (await comm["c"].post("/console/reports/999999/decide", json=body, headers=CSRF,
                                 cookies=comm["ck"]["op"])).status_code == 409
    assert (await comm["c"].post(f"/console/reports/{first_post_report}/decide", json={"action": "delete"},
                                 headers=CSRF, cookies=comm["ck"]["op"])).status_code == 422


@pytest.mark.asyncio
async def test_CM7_3_hidden_comment_shows_placeholder_and_keeps_counter(comm):
    """댓글 hide = 자리만 남고(`body:null, deleted:true`) COMMENT_CNT 는 손대지 않는다(SP-COMM-6)."""
    p = await _post(comm, "alice")
    c = await _comment(comm, "bob", p, "숨길 댓글")
    r = await comm["c"].post("/reports", json={"target_type": "comment", "target_id": c, "reason": "abuse"},
                             headers=CSRF, cookies=comm["ck"]["alice"])
    rid = r.json()["report_id"]
    assert (await comm["c"].post(f"/console/reports/{rid}/decide", json={"action": "hide"}, headers=CSRF,
                                 cookies=comm["ck"]["op"])).status_code == 200
    items = (await comm["c"].get(f"/posts/{p}/comments")).json()["items"]
    assert items == [{**items[0], "body": None, "deleted": True}]
    assert (await comm["c"].get(f"/posts/{p}")).json()["comment_cnt"] == 1
    # 숨겨진 댓글은 다시 신고할 수 없다(비활성 404)
    assert (await comm["c"].post("/reports", json={"target_type": "comment", "target_id": c, "reason": "spam"},
                                 headers=CSRF, cookies=comm["ck"]["op"])).status_code == 404


# ── AU-2 계열: 익명 GET 의 dependant 트리 ───────────────────────────────────

def _dep_names(dependant) -> set[str]:
    names = set()
    for d in dependant.dependencies:
        if d.call:
            names.add(d.call.__name__)
        names |= _dep_names(d)
    return names


def test_CM7_4_anonymous_gets_have_no_member_gate_but_optional(comm):
    """익명 GET 3종의 의존성 트리에 `require_member`·`require_csrf` 가 없다(AU-2 유지).
    상세·댓글은 `optional_member`(별개 심볼)로만 세션을 **선택적으로** 읽는다."""
    routes = {r.path: r for r in comm["app"].routes if isinstance(r, APIRoute) and "GET" in r.methods}
    for path in ("/api/v1/posts", "/api/v1/posts/{post_id}", "/api/v1/posts/{post_id}/comments"):
        route = routes[path]
        names = _dep_names(route.dependant)
        assert "require_member" not in names and "require_csrf" not in names, f"{path}: {names}"
        if path != "/api/v1/posts":
            assert "optional_member" in names, f"{path} 는 optional_member 로 is_mine/liked 를 계산한다"
        else:
            assert "optional_member" not in names, "목록은 세션을 읽지 않는다"


def test_CM7_5_server_slug_matches_generator_rule():
    """`comp.slug` 는 생성기 `slug_of`(FR-51)와 같은 규칙이어야 회사 페이지 링크가 맞는다.

    생성기를 import 하지 않고 같은 함수를 서버에 뒀으므로, 여기서 둘을 맞대어 드리프트를 막는다."""
    from generator.slug import slug_of
    from server.services.post import slug_of as server_slug_of

    for eng in ("Comm Test Co", "samsung_electronics", "  LG--CNS ", "CJ ENM (Entertainment)", "naver"):
        assert server_slug_of(eng) == slug_of(eng), eng
