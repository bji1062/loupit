"""`db/migrations/20260924_restore_member_edits.sql` — 되돌아간 재직자 편집 되살리기 (RM-1~RM-2).

사고 상태를 **실제 경로로 재현**한 뒤 마이그레이션을 건다:
  ① 편집 서비스(`services.benefit_edit`)로 재직자 편집을 만든다 — 운영의 EDIT_LOG #1·#2 와 같은 값 +
     두 번 고친 행 · 금액 행을 정성으로 바꾼 행(JSON null·true) · 충돌 등록 행 · 등록한 뒤 고친 충돌 행 ·
     되돌아가지 않은 재직자 행.
  ② 그 회사들의 시드 SQL 을 다시 돌리고 백필한다 — 2026-09-20 웨이브 4 적재가 한 일과 같다(시드 SQL 의
     `ON DUPLICATE KEY UPDATE` 는 여전히 행을 가리지 않는다 — 막는 것은 load.py 이고, 여기선 일부러 우회한다).
  ③ 마이그레이션 2회: 1회차는 되돌아간 행만 AFTER_VAL 로 되살리고, 2회차는 아무것도 바꾸지 않는다.

`BENEFIT_ID` 가 다른 행을 가리키는 이력(= `--fresh` 재배정 뒤의 이력)은 건드리지 않는지도 본다.
"""
from __future__ import annotations

import asyncio
import json
import re
import sys
from datetime import timedelta
from pathlib import Path

import pymysql
import pytest

from server.tests.conftest import MIGRATIONS_DIR, _split_sql_statements

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import backfill_dec2  # noqa: E402
import load as seed_load  # noqa: E402

MIGRATION = MIGRATIONS_DIR / "20260924_restore_member_edits.sql"
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"


def _utc_conn() -> pymysql.connections.Connection:
    """세션 시간대를 UTC 로 고정한 커넥션 — 편집 서비스는 VERIFIED_DTM 을 UTC_TIMESTAMP() 로 쓰므로
    TIMESTAMP(이력 INS_DTM)와 DATETIME 을 같은 기준으로 비교하려면 세션이 UTC 여야 한다."""
    conn = seed_load.connect()
    with conn.cursor() as cur:
        cur.execute("SET time_zone = '+00:00'")
    return conn


def _all_rows(conn) -> dict:
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute("SELECT * FROM TCOMPANY_BENEFIT ORDER BY BENEFIT_ID")
        return {r["BENEFIT_ID"]: r for r in cur.fetchall()}


def _id(conn, eng: str, code: str) -> int:
    with conn.cursor() as cur:
        cur.execute("SELECT b.BENEFIT_ID FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID=b.COMP_ID "
                    "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s", (eng, code))
        row = cur.fetchone()
    assert row, f"{eng}/{code} 없음(시드 전제)"
    return row[0]


def _comp(conn, eng: str) -> int:
    with conn.cursor() as cur:
        cur.execute("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (eng,))
        return cur.fetchone()[0]


def _seed_file(eng: str) -> Path:
    hits = [p for p in sorted(BENEFIT_SQL_DIR.glob("*.sql")) if f"VALUES ('{eng}'," in p.read_text(encoding="utf-8")]
    assert len(hits) == 1, (eng, hits)
    return hits[0]


def _apply_migration() -> int:
    """운영과 같은 순서로 문장을 실행하고 UPDATE 가 **바꾼** 행 수 합계를 돌려준다(mysql -vv 의 Changed)."""
    conn = seed_load.connect()
    changed = 0
    try:
        with conn.cursor() as cur:
            for stmt in _split_sql_statements(MIGRATION.read_text(encoding="utf-8")):
                cur.execute(stmt)
                if _first_keyword(stmt) == "UPDATE":
                    changed += cur.rowcount
        conn.commit()
    finally:
        conn.close()
    return changed


def _first_keyword(stmt: str) -> str:
    body = re.sub(r"^(\s*--[^\n]*\n)+", "", stmt + "\n").strip()
    return body.split(None, 1)[0].upper() if body else ""


async def _edits(ids: dict, kim: int, lee: int) -> None:
    from server import database
    from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn
    from server.services import benefit_edit as svc

    async def update(comp, bid, mbr, **kw):
        token = {b["benefit_id"]: b["base_dtm"] for b in await svc.fetch_company_benefits(comp)}[bid]
        r = await svc.update_benefit(comp, bid, mbr, BenefitUpdateIn(base_dtm=token, **kw))
        assert r["result"] == "ok", r

    await database.init_pool()
    try:
        # 운영 EDIT_LOG #1·#2 와 같은 편집
        await update(ids["krafton"], ids["resort"], kim, benefit_nm="휴양시설 지원", benefit_amt=None,
                     qual_yn=False, note_ctnt="2회")
        await update(ids["cj_enm_com"], ids["telecom"], lee, benefit_nm="통신비 지원", benefit_amt=60,
                     qual_yn=False, note_ctnt="1인당 월 5만원")
        # 두 번 고친 행 — 마지막 이력의 AFTER_VAL 이 이긴다
        await update(ids["krafton"], ids["fitness"], kim, benefit_nm="운동비 지원", benefit_amt=100,
                     qual_yn=False, note_ctnt="첫 수정")
        await update(ids["krafton"], ids["fitness"], kim, benefit_nm="운동비 지원(연 150)", benefit_amt=150,
                     qual_yn=False, note_ctnt="두 번째 수정")
        # 금액 행을 정성으로 — AFTER_VAL 에 qual_yn true · benefit_amt null · note_ctnt null(JSON null 변환 시험)
        await update(ids["krafton"], ids["commute"], kim, benefit_nm="야근 택시비 + 출근 버스",
                     benefit_amt=None, qual_yn=True, note_ctnt=None)
        # 충돌 등록 — 시드에서 지운 코드를 재직자가 다른 카테고리로 등록(등록 이력은 카테고리까지 되살린다)
        r = await svc.create_benefit(ids["cj_enm_com"], lee, BenefitCreateIn(
            benefit_cd="leisure_ticket", benefit_nm="OTT 이용권", benefit_ctgr_cd="perks",
            benefit_amt=24, qual_yn=False, note_ctnt="연 24만원 상당"))
        assert r["result"] == "ok", r
        ids["ticket"] = r["benefit"]["benefit_id"]
        # 등록한 뒤 고친 행 — 마지막 이력은 수정이지만 재직자가 만든 행이라 카테고리·설명·출처 URL·정렬은
        # 등록이 쓴 그대로여야 한다(마지막 이력의 종류가 아니라 등록 이력의 유무로 갈린다)
        r = await svc.create_benefit(ids["cj_enm_com"], lee, BenefitCreateIn(
            benefit_cd="edu_support", benefit_nm="자기계발비", benefit_ctgr_cd="compensation",
            benefit_amt=50, qual_yn=False, note_ctnt="연 50만원"))
        assert r["result"] == "ok", r
        ids["edu"] = r["benefit"]["benefit_id"]
        await update(ids["cj_enm_com"], ids["edu"], lee, benefit_nm="자기계발비", benefit_amt=50,
                     qual_yn=False, note_ctnt="연 50만원(재직자 확인)")
        # 정성 행을 금액 행으로 바꾼 뒤 금액만 다시 고친 행 — 마지막 이력은 금액→금액이지만 이력에 전환이
        # 있으므로 시드의 정성 설명·공식 출처 URL 을 비워야 한다(전환 판정은 이력 전체, 사용자 결정 2026-09-25)
        await update(ids["cj_enm_com"], ids["lang"], lee, benefit_nm="어학시험 응시료", benefit_amt=20,
                     qual_yn=False, note_ctnt="연 2회 · 1회 10만원")
        await update(ids["cj_enm_com"], ids["lang"], lee, benefit_nm="어학시험 응시료", benefit_amt=24,
                     qual_yn=False, note_ctnt="연 2회 · 1회 12만원")
        # 되돌아가지 않은 재직자 행 — 시드 재실행 대상이 아닌 회사
        await update(ids["samsung_elec"], ids["samsung_fitness"], kim, benefit_nm="피트니스센터",
                     benefit_amt=36, qual_yn=False, note_ctnt="월 3만원 상당")
    finally:
        await database.close_pool()


@pytest.fixture
def reverted(seeded_db):
    """재직자 편집 → 웨이브 적재 재현(시드 SQL 재실행 + 백필)까지 마친 상태. 끝나면 정본 시드로 되돌린다."""
    conn = seeded_db
    with conn.cursor() as cur:
        cur.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE %s", ("rm-%",))
        cur.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES ('rm-kim@example.com', 'rm-kim')")
        kim = cur.lastrowid
        cur.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES ('rm-lee@example.com', 'rm-lee')")
        lee = cur.lastrowid
    ids = {eng: _comp(conn, eng) for eng in ("krafton", "cj_enm_com", "samsung_elec")}
    ids.update(resort=_id(conn, "krafton", "resort"), fitness=_id(conn, "krafton", "fitness"),
               commute=_id(conn, "krafton", "commute_subsidy"),
               club=_id(conn, "krafton", "club"), telecom=_id(conn, "cj_enm_com", "telecom"),
               lang=_id(conn, "cj_enm_com", "lang"),
               discount=_id(conn, "cj_enm_com", "discount"),
               samsung_fitness=_id(conn, "samsung_elec", "fitness"))
    with conn.cursor() as cur:  # 재직자 등록 자리 — 다음 웨이브 시드가 같은 코드를 들고 오는 상황
        cur.execute("DELETE FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID IN (%s, %s)",
                    (_id(conn, "cj_enm_com", "leisure_ticket"), _id(conn, "cj_enm_com", "edu_support")))
    try:
        asyncio.run(_edits(ids, kim, lee))
        with _utc_conn() as uc:
            post_edit = _all_rows(uc)
        # 되돌아가지 않은 재직자 행을 편집 뒤에 누군가(운영자) 손봤다 — 여전히 verified 라 되살리기 대상이
        # 아니다. 가드가 없으면 마지막 AFTER_VAL 로 되감겨 이 수정이 사라진다.
        with conn.cursor() as cur:
            cur.execute("UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT='운영자가 고친 비고' WHERE BENEFIT_ID=%s",
                        (ids["samsung_fitness"],))
        # 대상이 다른 행을 가리키는 이력(= --fresh 재배정 뒤 남은 이력 모양) — 되살리면 엉뚱한 행이 바뀐다
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO TBENEFIT_EDIT_LOG (BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, AFTER_VAL) VALUES "
                "(%s, %s, %s, 'update', %s), (%s, %s, %s, 'update', %s)",
                (ids["club"], ids["krafton"], kim, json.dumps({"benefit_cd": "resort", "benefit_nm": "엉뚱",
                 "benefit_amt": 1, "qual_yn": False, "note_ctnt": None, "amt_source": "estimated"}),
                 ids["discount"], ids["krafton"], lee, json.dumps({"benefit_cd": "discount", "benefit_nm": "엉뚱",
                 "benefit_amt": 1, "qual_yn": False, "note_ctnt": None, "amt_source": "estimated"})))
        # 웨이브 적재 재현 — 두 회사의 시드 SQL + 백필(load.py 의 보존 장치를 일부러 거치지 않는다)
        replay = seed_load.connect()
        try:
            with replay.cursor() as cur:
                cur.execute("SET NAMES utf8mb4")
                for eng in ("krafton", "cj_enm_com"):
                    seed_load.run_sql_file(cur, _seed_file(eng))
                backfill_dec2.backfill(cur)
            replay.commit()
        finally:
            replay.close()
        yield {"ids": ids, "kim": kim, "lee": lee, "post_edit": post_edit}
    finally:
        seed_load.main(fresh=True, discard_member_edits=True)
        with conn.cursor() as cur:
            cur.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE %s", ("rm-%",))


# ── RM-1: 되돌아간 행만 AFTER_VAL 로 되살리고, 두 번째 실행은 아무것도 바꾸지 않는다 ─────────

def test_RM1_되돌아간_재직자_행만_AFTER_VAL_로_되살리고_재실행은_0행(reverted):
    ids, kim = reverted["ids"], reverted["kim"]
    restored = {ids["resort"], ids["telecom"], ids["fitness"], ids["commute"], ids["ticket"], ids["edu"], ids["lang"]}
    # 정성 → 금액으로 바꾼 수정이 이력에 있고 마지막 상태가 금액 행 — 시드 설명·공식 출처 URL 을 비운다
    qual_to_amt = {ids["telecom"], ids["lang"]}
    with _utc_conn() as uc:
        before = _all_rows(uc)
        # 재현 전제 — 운영 사고와 같은 모양: 시드 값·official·시드 출처인데 MOD_ID 는 재직자
        r = before[ids["resort"]]
        assert (r["BADGE_CD"], r["BENEFIT_AMT"], r["NOTE_CTNT"], r["MOD_ID"]) == ("official", 50, "(추정)", kim)
        assert before[ids["samsung_fitness"]]["BADGE_CD"] == "verified", "전제: 되돌아가지 않은 재직자 행"
        assert before[ids["edu"]]["BADGE_SRC_URL_CTNT"], "전제: 시드 충돌이 공식 출처 URL 을 채웠다"
        for bid in qual_to_amt:  # 전제: 시드에서 정성 행이고 설명·공식 출처 URL 이 있다(1400 운영 모양)
            assert before[bid]["QUAL_YN"] == 1 and before[bid]["QUAL_DESC_CTNT"] and before[bid]["BADGE_SRC_URL_CTNT"], bid
        with uc.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute("SELECT l.BENEFIT_ID, l.EDIT_TYPE_CD, l.ACTOR_MBR_ID, l.AFTER_VAL, l.INS_DTM, "
                        "       l.INS_DTM + INTERVAL 18 MONTH AS EXP_DTM, t.HAS_CREATE "
                        "  FROM TBENEFIT_EDIT_LOG l "
                        "  JOIN (SELECT BENEFIT_ID, MAX(EDIT_LOG_ID) AS LAST_ID, "
                        "               MAX(EDIT_TYPE_CD = 'create') AS HAS_CREATE FROM TBENEFIT_EDIT_LOG "
                        "         WHERE BENEFIT_ID IS NOT NULL GROUP BY BENEFIT_ID) t ON t.LAST_ID = l.EDIT_LOG_ID")
            last = {x["BENEFIT_ID"]: x for x in cur.fetchall()}
    assert last[ids["edu"]]["EDIT_TYPE_CD"] == "update" and last[ids["edu"]]["HAS_CREATE"] == 1, "전제"

    assert _apply_migration() == 7, "1회차는 되돌아간 재직자 행 7개만 바꿔야 한다"

    with _utc_conn() as uc:
        after = _all_rows(uc)
    changed = {bid for bid in before if after[bid] != before[bid]}
    assert changed == restored, f"바뀐 행이 다르다 — 더: {changed - restored} / 빠짐: {restored - changed}"

    for bid in restored:
        a, b, log = after[bid], before[bid], last[bid]
        want = json.loads(log["AFTER_VAL"])
        assert a["BENEFIT_NM"] == want["benefit_nm"]
        assert a["BENEFIT_AMT"] == want["benefit_amt"]  # JSON null → SQL NULL (문자열 'null' 아님)
        assert a["QUAL_YN"] == int(want["qual_yn"])  # JSON boolean → 0/1
        assert a["NOTE_CTNT"] == want["note_ctnt"]
        assert a["AMT_SOURCE_CD"] == want["amt_source"]
        assert (a["BADGE_CD"], a["BADGE_SRC_CD"]) == ("verified", "user_report")
        assert a["VERIFIED_DTM"] == log["INS_DTM"] and a["EXPIRES_DTM"] == log["EXP_DTM"]
        # MOD — 마지막 이력이 등록이면 비운다(등록은 MOD 를 쓰지 않는다), 아니면 그 이력의 편집자·시각
        latest_create = log["EDIT_TYPE_CD"] == "create"
        assert (a["MOD_ID"], a["MOD_DTM"]) == ((None, None) if latest_create else (log["ACTOR_MBR_ID"], log["INS_DTM"]))
        if log["HAS_CREATE"]:
            # 재직자가 만든 행 — 등록이 쓴 그대로: 카테고리 = AFTER_VAL, 설명·출처 URL 없음, 정렬 0
            assert (a["BENEFIT_CTGR_CD"], a["QUAL_DESC_CTNT"], a["BADGE_SRC_URL_CTNT"], a["SORT_ORDER_NO"]) == (
                want["benefit_ctgr_cd"], None, None, 0), bid
        elif bid in qual_to_amt:
            # 정성 → 금액 전환 — 시드의 정성 설명(「금액 미기재」 류)과 공식 출처 URL 은 비우고 나머지는 그대로
            assert (a["QUAL_DESC_CTNT"], a["BADGE_SRC_URL_CTNT"]) == (None, None), bid
            for col in ("BENEFIT_CTGR_CD", "SORT_ORDER_NO"):
                assert a[col] == b[col], f"{bid}.{col} 가 바뀌었다"
        else:
            # 시드에서 온 행 — 수정이 쓰지 않는 컬럼은 그대로
            for col in ("BENEFIT_CTGR_CD", "QUAL_DESC_CTNT", "BADGE_SRC_URL_CTNT", "SORT_ORDER_NO"):
                assert a[col] == b[col], f"{bid}.{col} 가 바뀌었다"
        for col in ("COMP_ID", "BENEFIT_CD", "INS_ID", "INS_DTM"):
            assert a[col] == b[col], f"{bid}.{col} 가 바뀌었다"

    # 마지막 이력이 이긴다 — 두 번 고친 행은 두 번째 값
    assert (after[ids["fitness"]]["BENEFIT_AMT"], after[ids["fitness"]]["NOTE_CTNT"]) == (150, "두 번째 수정")
    # JSON null·불리언 — 문자열 'null' 이나 0 이 아니라 SQL NULL 과 1
    c = after[ids["commute"]]
    assert (c["QUAL_YN"], c["BENEFIT_AMT"], c["NOTE_CTNT"], c["AMT_SOURCE_CD"]) == (1, None, None, "none")
    assert after[ids["ticket"]]["BENEFIT_CTGR_CD"] == "perks"
    assert after[ids["edu"]]["BENEFIT_CTGR_CD"] == "compensation"  # 등록 뒤 고쳐도 등록의 카테고리
    # 되살린 모든 행이 편집 직후 상태 그대로 — 전 컬럼(시각은 서비스 UPDATE 와 이력 INSERT 사이 1초 안팎 허용).
    # 정성 → 금액 전환 행의 설명·출처 URL 은 일부러 비웠으므로 이 비교에서 뺀다(위에서 NULL 을 확인했다).
    post = reverted["post_edit"]
    for bid in restored:
        for col, v in post[bid].items():
            if bid in qual_to_amt and col in ("QUAL_DESC_CTNT", "BADGE_SRC_URL_CTNT"):
                continue
            got = after[bid][col]
            if col in ("VERIFIED_DTM", "EXPIRES_DTM", "MOD_DTM") and v is not None and got is not None:
                assert abs(got - v) <= timedelta(seconds=2), (bid, col)
            else:
                assert got == v, f"{bid}.{col}: {got!r} != 편집 직후 {v!r}"

    # 2회차 — 멱등: 0행, 어떤 행도 바뀌지 않는다
    assert _apply_migration() == 0, "2회차가 행을 바꿨다(멱등 아님)"
    with _utc_conn() as uc:
        assert _all_rows(uc) == after


# ── RM-2: 운영 적용 조건 — 분할기 안전·머리말 ──────────────────────────────────────────

def test_RM2_주석은_분할기에_안전하고_머리말에_적용_명령과_확인_쿼리가_있다():
    """load.py·conftest 의 분할기는 주석 속 홑따옴표·겹따옴표를 문자열 시작으로, 세미콜론을 문장 끝으로 본다.
    주석에 그 셋이 있으면 문장이 쪼개지거나 삼켜진다(시드 주석 함정과 같은 뿌리)."""
    text = MIGRATION.read_text(encoding="utf-8")
    for i, line in enumerate(text.splitlines(), 1):
        s = line.strip()
        if s.startswith("--"):
            assert not (set(s) & {"'", '"', ";"}), f"{i}행 주석에 분할기 구분자가 있다: {line}"
            assert s == "--" or s.startswith("-- "), f"{i}행 — mysql CLI 주석은 「-- 」(공백)으로 시작해야 한다"
    kinds = [_first_keyword(s) for s in _split_sql_statements(text)]
    assert kinds == ["SET", "SET", "UPDATE"], f"문장 구성이 다르다(주석 조각이 문장으로 샜을 수 있다): {kinds}"
    for need in ("/data/mysql/bin/mysql", "-vv", "MYSQL_PWD", "mysqldump", "loupit_beta", "971", "1400",
                 "--no-tablespaces"):  # 이 계정엔 전역 PROCESS 권한이 없어 이 옵션 없이는 백업이 실패한다
        assert need in text, f"머리말에 {need!r} 가 없다"
    assert "BADGE_CD <> 'verified'" in text, "멱등 가드(되살린 행은 다시 안 건드린다)가 없다"
