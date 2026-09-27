"""출처 주소 주간 점검 — **실 DB** 쓰기·보관·기준선 + 콘솔 API (SRC-20~SRC-34, SC-1 2026-09-27).

`test_source_check.py` 가 판정과 예절을 가짜 HTTP 계층으로 잰다. 여기서 재는 것은 그 뒤 — 결과가 DB 에 어떻게
남고(한 실행 = 한 시각·한 트랜잭션, `--dry-run`·시험 실행은 무기록, 180일 보관), 콘솔이 그 이력에서 연속 실패를
어떻게 세는가다. 네트워크는 여기서도 가짜다.

⚠ 이 파일은 `DB_NAME` 이 가리키는 DB 에 실제로 쓴다(conftest 가드가 `loupit_test` 로 제한). 자기 회사(`srcchk_`
접두)만 만들고 치운다. `TSOURCE_CHECK` 는 이 기능만 쓰는 표라 픽스처가 **통째로** 비운다 — 격리 스키마라서 된다.
전체 실행(`load_targets` 무필터)은 시드된 다른 회사도 대상으로 잡는다 — 가짜 계층이 기본 응답으로 답한다.
"""
from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta

import httpx
import pymysql
import pytest
import pytest_asyncio

from server import database
from server import source_check as sc
from server.tests.conftest import _connect
from server.tests.test_source_check import HTML, FakeClock, FakeResp

NOW = datetime(2026, 10, 5, 0, 17, 0)
TP_CD = "srcchk_tp"
OP_EMAIL = "srcchk-operator@example.com"
USER_EMAIL = "srcchk-user@example.com"

#: 회사 영문명 → (이름, 출처 주소). 이름은 가나다 순으로 콘솔 정렬을 잴 수 있게 골랐다.
COMPANIES = {
    "srcchk_a": ("점검가사", "https://a.srcchk.example/benefit"),
    "srcchk_b": ("점검나사", "https://b.srcchk.example/welfare"),
    "srcchk_c": ("점검다사", "https://c.srcchk.example/report.pdf"),
    "srcchk_d": ("점검라사", "https://d.srcchk.example/life"),
    "srcchk_e": ("점검마사", "https://e.srcchk.example/new-benefit"),
    "srcchk_f": ("점검바사", "https://f.srcchk.example/recruit"),
    "srcchk_g": ("점검사사", "https://g.srcchk.example/gone-from-targets"),
    "srcchk_none": ("점검아사", None),
}
URL = {eng: url for eng, (_nm, url) in COMPANIES.items()}


class DBWeb:
    """가짜 HTTP 계층 — 대본에 없는 robots.txt 는 404, 대본에 없는 페이지는 정상 응답(시드된 다른 회사용: PDF 주소는
    PDF 머리, 그 밖은 복지 낱말이 든 HTML). 기본 응답이 정상이어야 전체 실행에서 우리 회사 판정만 도드라진다."""

    def __init__(self, clock: FakeClock, pages: dict | None = None):
        self.clock, self.pages = clock, dict(pages or {})
        self.urls: list[str] = []

    def __call__(self, url, headers, timeout):
        self.urls.append(url)
        self.clock.now += 0.2
        spec = self.pages.get(url)
        if spec is None:
            if url.endswith("/robots.txt"):
                spec = (404, {}, b"")
            elif sc.looks_pdf(url):
                spec = (200, {"Content-Type": "application/pdf"}, b"%PDF-1.4")
            else:
                spec = (200, HTML, "복리후생".encode())
        if isinstance(spec, BaseException):
            raise spec
        return FakeResp(*spec)


def _clean(conn) -> None:
    with conn.cursor() as cur:
        cur.execute("DELETE FROM TSOURCE_CHECK")
        cur.execute("DELETE FROM TCOMPANY WHERE COMP_ENG_NM LIKE 'srcchk%%'")
        cur.execute("DELETE FROM TCOMPANY_TYPE WHERE COMP_TP_CD=%s", (TP_CD,))
    conn.commit()


@pytest.fixture
def db(schema_db):
    """점검 대상 7곳(출처 있음) + 출처 없는 1곳. 쓰기는 운영과 같은 autocommit=False 커넥션으로 한다."""
    conn = _connect(autocommit=False)
    _clean(conn)
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES (%s, '점검유형')", (TP_CD,))
        tp = cur.lastrowid
        for eng, (nm, url) in COMPANIES.items():
            cur.execute("INSERT INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, CAREERS_BENEFIT_URL) "
                        "VALUES (%s, %s, %s, %s)", (eng, nm, tp, url))
        cur.execute("SELECT COMP_ENG_NM, COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM LIKE 'srcchk%%'")
        ids = dict(cur.fetchall())
    conn.commit()
    try:
        yield conn, ids
    finally:
        conn.rollback()
        _clean(conn)
        conn.close()


def _rows(reader, comp_id: int) -> list[dict]:
    """검증 읽기는 autocommit 세션 커넥션으로 — 쓰는 쪽 트랜잭션의 스냅숏에 묶이지 않는다."""
    with reader.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute("SELECT * FROM TSOURCE_CHECK WHERE COMP_ID=%s ORDER BY CHECK_ID", (comp_id,))
        return list(cur.fetchall())


def _count(reader) -> int:
    with reader.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM TSOURCE_CHECK")
        return cur.fetchone()[0]


def _insert(conn, run_dtm, comp_id, url, result_cd, *, kw=None, http=None, final=None, detail=None) -> None:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TSOURCE_CHECK (RUN_DTM, COMP_ID, CHECK_URL, RESULT_CD, HTTP_STATUS_NO, FINAL_URL, "
                    "KEYWORD_YN, DETAIL_CTNT) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                    (run_dtm, comp_id, url, result_cd, http, final, kw, detail))
    conn.commit()


def _run(conn, pages=None, *, now=NOW, **kw):
    clock = FakeClock()
    web = DBWeb(clock, pages)
    out: list[str] = []
    rc = sc.main(conn, http=web, clock=clock, sleep=clock.sleep, now=lambda: now, out=out.append, **kw)
    return rc, web, out


# ── SRC-20~26: 점검기 쓰기 ──────────────────────────────────────────────────────

def test_SRC20_dry_run_과_시험_실행은_DB_에_쓰지_않는다(db, schema_db):
    """보관 기한이 지난 행까지 그대로여야 한다 — 지우는 것도 쓰기다."""
    conn, ids = db
    _insert(conn, NOW - timedelta(days=200), ids["srcchk_a"], URL["srcchk_a"], "ok", kw=1)
    before = _count(schema_db)
    for kw in ({"dry_run": True}, {"only": ["srcchk_a"]}, {"limit": 2}):
        rc, web, out = _run(conn, **kw)
        assert rc == 0, kw
        assert _count(schema_db) == before, f"{kw} 가 DB 에 썼다"
        assert "DB 에 쓰지 않았다" in out[-1]
        # 손으로 돌리는 실행은 시작을 알리고 한 곳마다 한 줄씩 — 10분 동안 말이 없지 않게.
        assert out[0].startswith("출처 점검 시작:")
        n_targets = int(out[0].split("출처 점검 시작: ", 1)[1].split("곳", 1)[0])
        assert sum(1 for line in out if line.startswith("  ") and "://" in line) == n_targets
    # --only 는 그 회사만 두드린다.
    _rc, web, _out = _run(conn, only=["srcchk_a"])
    assert [u for u in web.urls if not u.endswith("robots.txt")] == [URL["srcchk_a"]]


def test_SRC21_한_실행은_한_시각으로_쓰이고_180일_지난_행은_지운다(db, schema_db):
    conn, ids = db
    _insert(conn, NOW - timedelta(days=181), ids["srcchk_a"], URL["srcchk_a"], "ok", kw=1)
    _insert(conn, NOW - timedelta(days=179), ids["srcchk_a"], URL["srcchk_a"], "ok", kw=1)
    pages = {
        URL["srcchk_a"]: (200, HTML, "<h1>복지 제도</h1>".encode()),
        URL["srcchk_b"]: (404, HTML, b"not found"),
        URL["srcchk_c"]: (206, {"Content-Type": "application/pdf"}, b"%PDF-1.6 ..."),
        URL["srcchk_d"]: (301, {"Location": "https://elsewhere.example.org/x"}, b""),
        "https://elsewhere.example.org/x": (200, HTML, b"hello"),
    }
    rc, _web, out = _run(conn, pages)
    assert rc == 0

    a = _rows(schema_db, ids["srcchk_a"])
    assert [r["RUN_DTM"] for r in a] == [NOW - timedelta(days=179), NOW], "181일 전 행이 남았거나 179일 전 행이 지워졌다"
    new = a[-1]
    assert (new["RESULT_CD"], new["HTTP_STATUS_NO"], new["KEYWORD_YN"], new["CONTENT_TYPE_NM"], new["FINAL_URL"]) == (
        "ok", 200, 1, "text/html", None)
    assert new["CHECK_URL"] == URL["srcchk_a"] and new["ELAPSED_MS_NO"] >= 0
    [b] = _rows(schema_db, ids["srcchk_b"])
    assert (b["RESULT_CD"], b["HTTP_STATUS_NO"], b["KEYWORD_YN"]) == ("gone", 404, None)
    [c] = _rows(schema_db, ids["srcchk_c"])
    assert (c["RESULT_CD"], c["HTTP_STATUS_NO"], c["KEYWORD_YN"]) == ("ok", 206, None)
    [d] = _rows(schema_db, ids["srcchk_d"])
    assert (d["RESULT_CD"], d["FINAL_URL"]) == ("moved", "https://elsewhere.example.org/x")
    assert _rows(schema_db, ids["srcchk_none"]) == [], "출처 주소가 없는 회사를 점검했다"
    with schema_db.cursor() as cur:
        cur.execute("SELECT COUNT(DISTINCT RUN_DTM) FROM TSOURCE_CHECK WHERE RUN_DTM >= %s", (NOW,))
        assert cur.fetchone()[0] == 1, "한 실행의 행이 여러 시각으로 흩어졌다"
    assert any(line.startswith("출처 점검 ") and "확인 필요" in line for line in out)
    assert "1행 삭제" in out[-1]
    # 타이머 실행은 문제 회사만 적는다 — 매주 journald 에 정상 회사 78줄을 쌓지 않는다.
    assert any("srcchk_b" in line for line in out) and not any("srcchk_a " in line for line in out)


def test_SRC22_사라진_낱말은_돌아올_때까지_content_lost_고_주소가_바뀌면_기준도_새로_선다(db, schema_db):
    """기준선이 「마지막 관측」 그대로면 사라진 다음 주에 「낱말 없음」이 새 기준이 되어 ok 로 돌아가고 연속이 끊긴다."""
    conn, ids = db
    a, b = URL["srcchk_a"], URL["srcchk_b"]
    with_kw, without = (200, HTML, "복리후생 안내".encode()), (200, HTML, b"<div id=root></div>")
    script = [(with_kw, "ok"), (without, "content_lost"), (without, "content_lost"), (with_kw, "ok")]
    for week, (page, expected) in enumerate(script):
        rc, _w, _o = _run(conn, {a: page, b: without}, now=NOW + timedelta(days=7 * week))
        assert rc == 0
        assert _rows(schema_db, ids["srcchk_a"])[-1]["RESULT_CD"] == expected, f"{week}주차"
        assert _rows(schema_db, ids["srcchk_b"])[-1]["RESULT_CD"] == "ok", "처음부터 낱말이 없던 페이지에 헛경보"

    _run(conn, {a: without, b: without}, now=NOW + timedelta(days=28))
    assert _rows(schema_db, ids["srcchk_a"])[-1]["RESULT_CD"] == "content_lost"
    moved_to = "https://a.srcchk.example/benefit-v2"
    with conn.cursor() as cur:
        cur.execute("UPDATE TCOMPANY SET CAREERS_BENEFIT_URL=%s WHERE COMP_ID=%s", (moved_to, ids["srcchk_a"]))
    conn.commit()
    _run(conn, {moved_to: without, b: without}, now=NOW + timedelta(days=35))
    last = _rows(schema_db, ids["srcchk_a"])[-1]
    assert (last["CHECK_URL"], last["RESULT_CD"]) == (moved_to, "ok"), "옛 주소의 기준선이 새 주소에 옮겨 붙었다"


def test_SRC23_표가_없으면_쓰는_실행은_네트워크_전에_실패하고_dry_run_은_계속한다(db, monkeypatch):
    conn, _ids = db
    monkeypatch.setattr(sc, "table_exists", lambda _conn: False)
    rc, web, out = _run(conn)
    assert rc == 1 and web.urls == [], "표도 없는데 남의 서버부터 두드렸다"
    assert "TSOURCE_CHECK 표가 없다" in out[-1]
    rc, web, out = _run(conn, dry_run=True)
    assert rc == 0 and web.urls, "dry-run 은 표 없이도 판정해 보여 줘야 한다(운영 반영 전 보정용)"
    assert any("표가 없다" in line for line in out)


def test_SRC24_대상은_출처_주소가_있는_회사이고_only_limit_으로_좁힌다(db):
    conn, ids = db
    everyone = {t.comp_eng_nm for t in sc.load_targets(conn)}
    assert {e for e, (_n, u) in COMPANIES.items() if u} <= everyone
    assert "srcchk_none" not in everyone
    [only] = sc.load_targets(conn, only=["srcchk_b", "no_such_co"])
    assert (only.comp_eng_nm, only.url, only.comp_id) == ("srcchk_b", URL["srcchk_b"], ids["srcchk_b"])
    assert len(sc.load_targets(conn, limit=2)) == 2
    _rc, _web, out = _run(conn, only=["srcchk_b", "no_such_co"])
    assert any("no_such_co" in line for line in out), "없는 회사를 조용히 넘겼다"


def test_SRC25_회사가_지워지면_점검_이력도_지워진다(db, schema_db):
    conn, ids = db
    _insert(conn, NOW, ids["srcchk_g"], URL["srcchk_g"], "gone", http=404)
    with conn.cursor() as cur:
        cur.execute("DELETE FROM TCOMPANY WHERE COMP_ID=%s", (ids["srcchk_g"],))
    conn.commit()
    assert _rows(schema_db, ids["srcchk_g"]) == []


def test_SRC25b_fresh_재시드는_점검_이력을_비운다(db, schema_db):
    """`load.py --fresh` 는 TCOMPANY 를 다시 만들어 COMP_ID 가 새로 매겨진다 — 옛 점검 행이 남으면 다른 회사의 연속
    실패로 읽힌다(#15 동형, 2026-09-27 검토 LOW-3). 그래서 fresh 경로가 표를 비우는지 함수와 호출 자리를 함께 잰다."""
    import inspect

    from server.tests.conftest import SEED_DIR

    if str(SEED_DIR) not in sys.path:
        sys.path.insert(0, str(SEED_DIR))
    import load as seed_load  # db/seed/load.py

    conn, ids = db
    _insert(conn, NOW, ids["srcchk_a"], URL["srcchk_a"], "ok", kw=1)
    with conn.cursor() as cur:
        seed_load._truncate_source_check(cur)
    conn.commit()
    assert _count(schema_db) == 0
    src = inspect.getsource(seed_load.main)
    fresh_block = src[src.index("run_sql_file(cur, SCHEMA_SQL)"):src.index("run_sql_file(cur, COMPANY_TYPES_SQL)")]
    assert "_truncate_source_check(cur)" in fresh_block, "--fresh 경로가 출처 점검 이력을 비우지 않는다"


def test_SRC26_사이트가_다_죽어도_0_DB_가_실패하면_1(db, monkeypatch):
    conn, _ids = db
    everything_down = {URL[e]: (503, HTML, b"") for e, (_n, u) in COMPANIES.items() if u}
    rc, _web, out = _run(conn, everything_down)
    assert rc == 0, "두드린 사이트의 실패가 점검기의 실패가 됐다 — 타이머가 빨개진다"

    def broken(*_a, **_k):
        raise pymysql.err.OperationalError(2013, "Lost connection to MySQL server during query")

    monkeypatch.setattr(sc, "record", broken)
    rc, _web, out = _run(conn)
    assert rc == 1 and "DB 기록" in out[-1]


def test_SRC27_ops_source_check_가_점검기를_부른다(db, monkeypatch):
    """CLI 경로를 통째로 — 기본값(실제 urllib·시계)을 **부를 때** 찾으므로 가짜 계층이 끼워진다."""
    from server import ops

    conn, _ids = db
    clock = FakeClock()
    web = DBWeb(clock)
    monkeypatch.setattr(sc, "urllib_get", web)
    monkeypatch.setattr(sc, "GAP_SEC", 0.0)
    monkeypatch.setattr(sc, "SAME_HOST_GAP_SEC", 0.0)
    rc = ops.cmd_source_check(conn, argparse.Namespace(dry_run=True, only=["srcchk_a"], limit=None))
    assert rc == 0 and URL["srcchk_a"] in web.urls


# ── SRC-30~34: 콘솔 API ────────────────────────────────────────────────────────

@pytest_asyncio.fixture
async def console(db, monkeypatch):
    """운영자·일반 회원 세션 + 앱. `db` 픽스처의 회사를 그대로 쓴다."""
    from server.config import get_settings
    from server.main import create_app
    from server.services import session as session_svc

    _conn, ids = db
    await database.init_pool()
    monkeypatch.setattr(get_settings(), "operator_emails", OP_EMAIL)
    await database.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE 'srcchk-%%'")
    try:
        await database.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, 'srcchk-op'), "
                               "(%s, 'srcchk-user')", (OP_EMAIL, USER_EMAIL))
        mbr = {r["NICKNAME_NM"]: r["MBR_ID"] for r in await database.fetch_all(
            "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE NICKNAME_NM LIKE 'srcchk-%%'")}
        cookies = {k: {"loupit_sid": await session_svc.issue_session(mbr[f"srcchk-{k}"])} for k in ("op", "user")}
        transport = httpx.ASGITransport(app=create_app(), raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://127.0.0.1:8000/api/v1") as c:
            yield {"c": c, "ck": cookies, "ids": ids}
    finally:
        await database.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE 'srcchk-%%'")  # 세션은 CASCADE
        await database.close_pool()


T1, T2, T3 = NOW - timedelta(days=14), NOW - timedelta(days=7), NOW


async def _history(ids) -> None:
    """세 번의 실행 이력 — 회사마다 다른 모양(설계서 §6 「여러 실행 이력」)."""
    old_e = "https://e.srcchk.example/old-benefit"
    plan = {
        "srcchk_a": [(T1, "ok"), (T2, "ok"), (T3, "ok")],                    # 늘 정상
        "srcchk_b": [(T1, "ok"), (T2, "gone"), (T3, "gone")],                # 2주 연속
        "srcchk_c": [(T1, "error"), (T2, "blocked"), (T3, "content_lost")],  # 판정이 바뀌어도 연속 3
        "srcchk_d": [(T1, "gone"), (T2, "ok"), (T3, "moved")],               # 정상이 끼면 끊긴다
        "srcchk_f": [(T1, "robots"), (T2, "robots"), (T3, "robots")],        # 점검 안 함 — 연속이 아니다
        "srcchk_g": [(T1, "gone"), (T2, "gone")],                            # 마지막 실행에 없다(대상에서 빠졌다)
    }
    for eng, runs in plan.items():
        for run_dtm, cd in runs:
            await database.execute("INSERT INTO TSOURCE_CHECK (RUN_DTM, COMP_ID, CHECK_URL, RESULT_CD, HTTP_STATUS_NO) "
                                   "VALUES (%s, %s, %s, %s, %s)",
                                   (run_dtm, ids[eng], URL[eng], cd, 404 if cd == "gone" else None))
    # e: 주소를 고쳤다 — 옛 주소의 실패 2번은 새 주소의 연속에 들어가지 않는다.
    for run_dtm in (T1, T2):
        await database.execute("INSERT INTO TSOURCE_CHECK (RUN_DTM, COMP_ID, CHECK_URL, RESULT_CD) VALUES (%s,%s,%s,'gone')",
                               (run_dtm, ids["srcchk_e"], old_e))
    await database.execute("INSERT INTO TSOURCE_CHECK (RUN_DTM, COMP_ID, CHECK_URL, RESULT_CD, FINAL_URL, DETAIL_CTNT) "
                           "VALUES (%s, %s, %s, 'error', NULL, '시간 초과(20초)')",
                           (T3, ids["srcchk_e"], URL["srcchk_e"]))


@pytest.mark.asyncio
async def test_SRC30_한_번도_안_돌았으면_빈_결과다(console):
    r = await console["c"].get("/console/source-checks", cookies=console["ck"]["op"])
    assert r.status_code == 200
    assert r.json() == {"last_run_dtm": None, "total": 0,
                        "counts": {cd: 0 for cd in sc.RESULT_CODES}, "items": []}
    ov = (await console["c"].get("/console/overview", cookies=console["ck"]["op"])).json()
    assert ov["source_check"] is None


@pytest.mark.asyncio
async def test_SRC31_연속_처음_실패_마지막_정상_정렬(console):
    await _history(console["ids"])
    d = (await console["c"].get("/console/source-checks", cookies=console["ck"]["op"])).json()
    assert d["last_run_dtm"] == str(T3) and d["total"] == 6
    assert d["counts"] == {"ok": 1, "content_lost": 1, "gone": 1, "blocked": 0, "error": 1, "moved": 1, "robots": 1}
    by = {it["comp_eng_nm"]: it for it in d["items"]}
    assert "srcchk_g" not in by, "마지막 실행에 없는 회사가 끼었다"
    got = {eng: (it["result_cd"], it["fail_streak"], it["first_fail_dtm"], it["last_ok_dtm"]) for eng, it in by.items()}
    assert got == {
        "srcchk_a": ("ok", 0, None, str(T3)),
        "srcchk_b": ("gone", 2, str(T2), str(T1)),
        "srcchk_c": ("content_lost", 3, str(T1), None),
        "srcchk_d": ("moved", 1, str(T3), str(T2)),
        "srcchk_e": ("error", 1, str(T3), None),
        "srcchk_f": ("robots", 0, None, None),
    }
    # 문제가 먼저(연속 내림차순, 같으면 회사명) → robots 금지 → 정상.
    assert [it["comp_eng_nm"] for it in d["items"]] == [
        "srcchk_c", "srcchk_b", "srcchk_d", "srcchk_e", "srcchk_f", "srcchk_a"]
    e = by["srcchk_e"]
    assert set(e) == {"comp_nm", "comp_eng_nm", "url", "result_cd", "http_status", "final_url", "detail",
                      "fail_streak", "first_fail_dtm", "last_ok_dtm"}
    assert (e["comp_nm"], e["url"], e["http_status"], e["final_url"], e["detail"]) == (
        "점검마사", URL["srcchk_e"], None, None, "시간 초과(20초)")
    assert by["srcchk_b"]["http_status"] == 404

    ov = (await console["c"].get("/console/overview", cookies=console["ck"]["op"])).json()
    assert ov["source_check"] == {"last_run_dtm": str(T3), "total": 6, "attention": 4, "robots": 1}


@pytest.mark.asyncio
async def test_SRC32_운영자만_보고_응답은_캐시되지_않는다(console):
    c = console["c"]
    assert (await c.get("/console/source-checks")).status_code == 401
    assert (await c.get("/console/source-checks", cookies=console["ck"]["user"])).status_code == 404
    proxied = {"x-real-ip": "198.51.100.7", "x-forwarded-for": "198.51.100.7", "x-forwarded-proto": "https"}
    assert (await c.get("/console/source-checks", headers=proxied, cookies=console["ck"]["op"])).status_code == 404
    r = await c.get("/console/source-checks", cookies=console["ck"]["op"])
    assert r.status_code == 200 and r.headers["cache-control"] == "no-store"
    assert (await c.post("/console/source-checks", cookies=console["ck"]["op"])).status_code in (404, 405)


@pytest.mark.asyncio
async def test_SRC33_점검기가_쓴_실행을_콘솔이_그대로_읽는다(console, db):
    """쓰는 쪽(`source_check.record`)과 읽는 쪽(`console_view`)이 같은 열·같은 뜻을 쓰는지 — 두 끝을 한 번에."""
    conn, ids = db
    rc, _web, _out = _run(conn, {URL["srcchk_b"]: (403, HTML, b"denied"),
                                 URL["srcchk_c"]: (200, {"Content-Type": "application/pdf"}, b"%PDF-1.5")})
    assert rc == 0
    d = (await console["c"].get("/console/source-checks", cookies=console["ck"]["op"])).json()
    b = next(it for it in d["items"] if it["comp_eng_nm"] == "srcchk_b")
    assert (b["result_cd"], b["http_status"], b["fail_streak"], b["first_fail_dtm"]) == ("blocked", 403, 1, str(NOW))
    assert "봇 방어" in b["detail"]
    assert d["last_run_dtm"] == str(NOW)
    assert [it["comp_eng_nm"] for it in d["items"] if it["result_cd"] != "ok"] == ["srcchk_b"]


@pytest.mark.asyncio
async def test_SRC34_현황은_출처_점검_표가_없어도_뜬다(monkeypatch):
    """스키마 적용 전에 앱이 먼저 떠도 콘솔 첫 화면(=로그인 확인)이 500 이 되면 안 된다. 다른 DB 오류는 삼키지 않는다."""
    from server.services import console_view

    async def missing(*_a, **_k):
        raise pymysql.err.ProgrammingError(1146, "Table 'loupit.TSOURCE_CHECK' doesn't exist")

    monkeypatch.setattr(console_view, "list_source_checks", missing)
    assert await console_view.source_check_brief() is None

    async def other(*_a, **_k):
        raise pymysql.err.ProgrammingError(1064, "syntax error")

    monkeypatch.setattr(console_view, "list_source_checks", other)
    with pytest.raises(pymysql.err.ProgrammingError):
        await console_view.source_check_brief()
