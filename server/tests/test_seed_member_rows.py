"""SP-SEED-12 재직자 행 보존 — 시드·백필은 재직자 행(`BADGE_CD='verified'`)을 쓰지 않는다 (SK-1~SK-12).

사고(2026-09-20 06:17:36 UTC, 웨이브 4 적재): 멱등 `python3 db/seed/load.py` 한 번에 운영의 재직자 수정
2행(크래프톤 「휴양시설 지원」 BENEFIT_ID 971 · CJ ENM 커머스부문 「통신비 지원」 1400)이 시드 값으로
되돌아갔다. 복지 SQL 의 `ON DUPLICATE KEY UPDATE` 가 `BADGE_CD` 까지 덮어 `est` 로 만들고, 백필이 그
행을 `official` 로 올린 뒤 출처·신선도까지 시드 것으로 바꿨다. `MOD_ID` 는 재직자로 남아, 편집 이력에서
파생하는 「공식·재직자 수정」 배지가 **시드 값 위에** 달렸다(허위 표시).

이 스위트가 지키는 것:
  - SK-1 멱등 재적용은 재직자 행을 **전 컬럼 그대로** 두고, 그러면서도 시드는 여전히 적용한다(대조군).
         편집은 **실제 서비스 경로**(`services.benefit_edit`)로 만든다 — 흉내 낸 SQL 이 아니라 운영과 같은
         쓰기가 적재를 견디는지 본다(픽스처가 파이프라인을 건너뛰는 테스트는 그 구간에 없는 것과 같다).
  - SK-2 백필은 재직자 행을 읽지도 쓰지도 않는다(amt_source·출처·신선도).
  - SK-3 재직자 행은 다른 회사 행의 앵커 강등 판정에 끼어들지 않는다 — 앵커 규칙 자체는 산다.
  - SK-4 적재 도중 다른 커넥션에서 재직자 편집이 커밋되면 적재 전체를 되돌린다.
  - SK-5·SK-6 `--fresh` 는 재직자 데이터가 있으면 거부한다(함수·CLI). 명시적 폐기 허용만 통과한다.
  - SK-7 폐기 허용 신호는 load.py 와 테스트 코드 밖 어디에도 없다(추적 파일 전체).
  - SK-8·SK-9 재직자 표지는 편집 서비스와 같은 값이고, 보존 컬럼 목록은 스키마에서 읽는다(새 컬럼 자동 포함).
  - SK-10 복구 마이그레이션이 적재와 겹쳐도 되살린 값이 남는다(② 잠금 — 이력을 남기지 않는 쓰기도 지킨다).
  - SK-11 대조(⑤)는 이진 비교라 대소문자만 바꾼 쓰기도 잡는다.
  - SK-12 표가 적재 밖에서 다시 만들어졌으면(번호 되감김) 멱등 재적재도 거부한다(⑦).
  - SK-13 폐기 허용은 서빙 스키마 이름이면 무조건 거부한다(DROP 전에) — 서빙 이름 목록은 C-1 가드와 같다.

⚠ 재직자 데이터를 만드는 테스트는 끝나면 `main(fresh=True, discard_member_edits=True)` 로 정본 시드를
  다시 세운다(`members` 픽스처) — 다른 파일의 정확 카운트(SD-4 2450 등)가 그 상태를 전제한다.
"""
from __future__ import annotations

import asyncio
import json
import os
import re
import subprocess
import sys
import threading
from pathlib import Path

import pymysql
import pytest

from server.tests.conftest import MIGRATIONS_DIR, _split_sql_statements

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import backfill_dec2  # noqa: E402  # db/seed/backfill_dec2.py
import load as seed_load  # noqa: E402  # db/seed/load.py

CANON_BENEFITS = 2450  # SD-4 정본 복지 행 수(test_seed_counts)
TAMPERED_NM = "SK 변조 대조군"
RESTORE_MIGRATION = MIGRATIONS_DIR / "20260924_restore_member_edits.sql"


# ── 헬퍼 ────────────────────────────────────────────────────────────────────

def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def _comp_id(conn, eng: str) -> int:
    cid = _scalar(conn, "SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM=%s", (eng,))
    assert cid, f"회사 {eng} 없음(시드 전제)"
    return cid


def _benefit_id(conn, comp_id: int, code: str) -> int:
    bid = _scalar(conn, "SELECT BENEFIT_ID FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s", (comp_id, code))
    assert bid, f"복지 {comp_id}/{code} 없음(시드 전제)"
    return bid


def _row(conn, benefit_id: int) -> dict | None:
    """복지 한 행의 **전 컬럼**(SELECT *) — 컬럼이 늘어도 비교 대상이 저절로 늘어난다."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute("SELECT * FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (benefit_id,))
        return cur.fetchone()


def _row_by_code(conn, eng: str, code: str) -> dict | None:
    """`--fresh` 뒤에는 BENEFIT_ID 가 다시 매겨진다 — (회사 영문명, 복지 코드)로 찾는다."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT b.* FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID=b.COMP_ID "
            "WHERE c.COMP_ENG_NM=%s AND b.BENEFIT_CD=%s", (eng, code))
        return cur.fetchone()


def _tamper(conn, benefit_id: int) -> None:
    """비재직자 행을 시드와 다르게 바꿔 둔다 — 적재가 시드를 적용했는지(또는 안 했는지)의 증거."""
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM=%s, BENEFIT_AMT=999, AMT_SOURCE_CD='stated', "
            "BADGE_SRC_CD='manual', VERIFIED_DTM='2001-01-01 00:00:00', EXPIRES_DTM='2002-07-01 00:00:00' "
            "WHERE BENEFIT_ID=%s", (TAMPERED_NM, benefit_id))


def _insert_edit_log(conn, benefit_id, comp_id, mbr_id, edit_type="update", after=None) -> None:
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TBENEFIT_EDIT_LOG (BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, AFTER_VAL) "
            "VALUES (%s, %s, %s, %s, %s)",
            (benefit_id, comp_id, mbr_id, edit_type, json.dumps(after or {}, ensure_ascii=False)))


def _reseed_canonical(conn) -> None:
    """정본 시드로 되돌린다 — 격리 스키마의 테스트 데이터는 일회용이라 재직자 데이터 폐기를 **명시적으로** 허용한다."""
    seed_load.main(fresh=True, discard_member_edits=True)
    with conn.cursor() as cur:
        cur.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE %s", ("sk-%",))


@pytest.fixture
def members(seeded_db):
    """편집 이력 FK(ACTOR_MBR_ID) 대상 테스트 회원 2명. 끝나면 정본 시드로 되돌리고 회원을 지운다."""
    ids = {}
    with seeded_db.cursor() as cur:
        cur.execute("DELETE FROM TMEMBER WHERE NICKNAME_NM LIKE %s", ("sk-%",))
        for nick in ("sk-kim", "sk-lee"):
            cur.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, %s)",
                        (f"{nick}@example.com", nick))
            ids[nick] = cur.lastrowid
    try:
        yield ids
    finally:
        _reseed_canonical(seeded_db)


async def _service_edits(krafton, cj_com, resort, telecom, collide_cd, kim, lee) -> dict:
    """운영과 같은 쓰기 경로로 재직자 편집 4건을 만든다(풀은 이 코루틴 안에서 열고 닫는다)."""
    from server import database
    from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn
    from server.services import benefit_edit as svc

    await database.init_pool()
    try:
        async def token(comp_id, benefit_id):
            return {b["benefit_id"]: b["base_dtm"] for b in await svc.fetch_company_benefits(comp_id)}[benefit_id]

        # (가) 사고 1 재현 — 크래프톤 휴양시설: 금액을 비우고 「2회」로 고쳤다(EDIT_LOG #1 과 같은 값).
        r = await svc.update_benefit(krafton, resort, kim, BenefitUpdateIn(
            base_dtm=await token(krafton, resort), benefit_nm="휴양시설 지원",
            benefit_amt=None, qual_yn=False, note_ctnt="2회"))
        assert r["result"] == "ok", r
        # (나) 사고 2 재현 — CJ ENM 커머스 통신비: 정성 → 월 5만원(연 60만원, EDIT_LOG #2 와 같은 값).
        r = await svc.update_benefit(cj_com, telecom, lee, BenefitUpdateIn(
            base_dtm=await token(cj_com, telecom), benefit_nm="통신비 지원",
            benefit_amt=60, qual_yn=False, note_ctnt="1인당 월 5만원"))
        assert r["result"] == "ok", r
        # (다) 충돌 등록 — 시드에서 지운 코드를 재직자가 등록했다(다음 웨이브 시드가 그 코드를 새로 들고 오는 상황).
        r = await svc.create_benefit(krafton, kim, BenefitCreateIn(
            benefit_cd=collide_cd, benefit_nm="재직자 등록 도서 지원", benefit_ctgr_cd="perks",
            benefit_amt=12, qual_yn=False, note_ctnt="월 1만원 재직자 확인"))
        assert r["result"] == "ok", r
        collide_id = r["benefit"]["benefit_id"]
        # (라) 시드에 없는 코드를 재직자가 등록했다.
        r = await svc.create_benefit(krafton, kim, BenefitCreateIn(
            benefit_cd="sk_member_only", benefit_nm="재직자만 아는 복지", benefit_ctgr_cd="leisure", qual_yn=True))
        assert r["result"] == "ok", r
        only_id = r["benefit"]["benefit_id"]
    finally:
        await database.close_pool()
    return {"collide_id": collide_id, "only_id": only_id}


async def _member_update(comp_id: int, benefit_id: int, mbr_id: int, **fields) -> None:
    """편집 서비스로 재직자 수정 1건(풀은 이 코루틴 안에서 열고 닫는다)."""
    from server import database
    from server.models.benefit_edit import BenefitUpdateIn
    from server.services import benefit_edit as svc

    await database.init_pool()
    try:
        token = {b["benefit_id"]: b["base_dtm"] for b in await svc.fetch_company_benefits(comp_id)}[benefit_id]
        r = await svc.update_benefit(comp_id, benefit_id, mbr_id, BenefitUpdateIn(base_dtm=token, **fields))
        assert r["result"] == "ok", r
    finally:
        await database.close_pool()


def _replay_wave(*engs: str) -> None:
    """2026-09-20 웨이브 4 적재가 한 일을 그대로 — 그 회사들의 시드 SQL + 백필을 로더의 보존 장치 없이
    돌린다(시드 SQL 의 업서트는 여전히 재직자 행을 가리지 않는다). 재직자 행이 시드 값·official 로 되돌아간다."""
    files = [p for p in sorted(seed_load.BENEFIT_SQL_DIR.glob("*.sql"))
             if any(f"VALUES ('{e}'," in p.read_text(encoding="utf-8") for e in engs)]
    assert len(files) == len(engs), files
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            for f in files:
                seed_load.run_sql_file(cur, f)
            backfill_dec2.backfill(cur)
        conn.commit()
    finally:
        conn.close()


def _apply_restore_migration() -> None:
    """복구 마이그레이션을 자체 커넥션으로 운영과 같은 순서로 실행한다."""
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            for stmt in _split_sql_statements(RESTORE_MIGRATION.read_text(encoding="utf-8")):
                cur.execute(stmt)
        conn.commit()
    finally:
        conn.close()


# ── SK-1: 멱등 재적용은 재직자 행을 지키고, 시드는 그대로 적용한다 ─────────────────────

def test_SK1_멱등_재적용은_재직자_행을_전_컬럼_그대로_두고_시드는_적용한다(seeded_db, members):
    kim, lee = members["sk-kim"], members["sk-lee"]
    krafton, cj_com = _comp_id(seeded_db, "krafton"), _comp_id(seeded_db, "cj_enm_com")
    resort, telecom = _benefit_id(seeded_db, krafton, "resort"), _benefit_id(seeded_db, cj_com, "telecom")
    collide_cd = "books"
    with seeded_db.cursor() as cur:  # 시드에 있던 코드를 비워 재직자 등록 자리를 만든다
        cur.execute("DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s", (krafton, collide_cd))
    control = _benefit_id(seeded_db, cj_com, "welfare_point")
    control_canon = _row(seeded_db, control)
    _tamper(seeded_db, control)

    made = asyncio.run(_service_edits(krafton, cj_com, resort, telecom, collide_cd, kim, lee))
    member_ids = [resort, telecom, made["collide_id"], made["only_id"]]
    before = {bid: _row(seeded_db, bid) for bid in member_ids}
    assert all(r["BADGE_CD"] == "verified" for r in before.values()), "전제: 서비스가 verified 로 썼다"
    total_before = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT")

    stats = seed_load.main(fresh=False)

    # 1) 재직자 행 — 값·배지·출처·신선도·MOD_ID·MOD_DTM 까지 전 컬럼이 적재 전과 같다.
    for bid in member_ids:
        assert _row(seeded_db, bid) == before[bid], f"재직자 행 {bid} 가 멱등 적재에 바뀌었다"
    # 2) 대조군 — 변조한 비재직자 행은 시드 값으로 돌아왔다(보존 장치가 시드 적용까지 막지는 않는다).
    after_control = _row(seeded_db, control)
    drift = {k: (after_control[k], v) for k, v in control_canon.items() if k != "MOD_DTM" and after_control[k] != v}
    assert not drift, f"비재직자 행에 시드가 다시 적용되지 않았다: {drift}"
    # 3) 행 수 — 충돌 코드는 재직자 행 하나로 남고(중복 없음), 재직자 전용 행도 그대로다.
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT") == total_before
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s",
                   (krafton, collide_cd)) == 1
    # 4) 통계 — 재직자 행 4, 그중 시드 업서트가 덮었다가 되돌린 행 3(가·나·다). (라)는 시드가 모르는 코드.
    assert stats["member_rows"] == 4
    assert stats["member_restored"] == 3


# ── SK-2: 백필은 재직자 행을 읽지도 쓰지도 않는다 ─────────────────────────────────────

def test_SK2_백필은_재직자_행을_건드리지_않는다(seeded_db):
    """추정 표기 없는 note 라 백필이 보면 'stated' 로 바꿀 재직자 행 — 출처·신선도도 시드 것으로 덮으면 안 된다.
    한 트랜잭션 안에서 만들고 백필한 뒤 **롤백**한다(정본 시드 불변)."""
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            krafton = _comp_id(conn, "krafton")
            bid = _benefit_id(conn, krafton, "resort")
            cur.execute(
                "UPDATE TCOMPANY_BENEFIT SET BENEFIT_AMT=60, QUAL_YN=FALSE, NOTE_CTNT='1인당 월 5만원', "
                "AMT_SOURCE_CD='estimated', BADGE_CD='verified', BADGE_SRC_CD='user_report', "
                "BADGE_SRC_URL_CTNT=NULL, VERIFIED_DTM='2026-09-18 05:31:19', "
                "EXPIRES_DTM='2028-03-18 05:31:19', MOD_ID=3, MOD_DTM='2026-09-18 05:31:19' "
                "WHERE BENEFIT_ID=%s", (bid,))
            before = _row(conn, bid)

            stats = backfill_dec2.backfill(cur)

            assert _row(conn, bid) == before, "백필이 재직자 행을 바꿨다(amt_source·출처·신선도 중 하나)"
            non_member = _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD <> 'verified'")
            assert sum(stats["amt_source"].values()) == non_member, "amt_source 집계가 재직자 행을 셌다"
    finally:
        conn.rollback()
        conn.close()


# ── SK-3: 재직자 행은 앵커 강등 판정에 끼어들지 않는다 ─────────────────────────────────

def test_SK3_재직자_행은_앵커_판정에_끼지_않고_앵커_규칙은_산다(seeded_db):
    """같은 (코드·금액)이 ≥3개사면 stated→estimated(M-4). 셋째 회사가 **재직자 행**이면 앵커가 아니다 —
    재직자 값이 다른 회사의 공식 값을 강등시키면 안 된다. 셋 다 공식이면 여전히 강등(규칙 생존 대조군)이고,
    그 앵커 묶음에 재직자 행이 끼어 있어도 재직자 행은 강등하지 않는다.

    재직자 행은 `stated` 로 둔다 — 예전 백필이 재직자 행의 amt_source 를 다시 계산해 추정 표기 없는
    note 를 `stated` 로 올려 두었을 수 있다(운영에 남아 있을 수 있는 모양). 그래야 판정(GROUP BY)과
    강등(UPDATE)의 재직자 행 제외가 **각각** 시험된다."""
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            a, b, c, d = (_comp_id(conn, e) for e in ("krafton", "cj_enm_com", "samsung_elec", "kt"))
            rows = [
                # (회사, 코드, 배지, 금액출처) — note 에 추정 표기가 없어 규칙상 stated 후보
                (a, "sk_anchor_member", "official", "estimated"),
                (b, "sk_anchor_member", "official", "estimated"),
                (c, "sk_anchor_member", "verified", "stated"),  # 셋째 회사가 재직자 행 → 앵커 아님
                (a, "sk_anchor_seed", "official", "estimated"),
                (b, "sk_anchor_seed", "official", "estimated"),
                (c, "sk_anchor_seed", "official", "estimated"),  # 공식 3사 → 앵커(강등)
                (d, "sk_anchor_seed", "verified", "stated"),  # 앵커 묶음 안의 재직자 행 → 강등 금지
            ]
            for comp, code, badge, amt_src in rows:
                cur.execute(
                    "INSERT INTO TCOMPANY_BENEFIT (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD, "
                    " BADGE_CD, AMT_SOURCE_CD, BADGE_SRC_CD, NOTE_CTNT, QUAL_YN, VERIFIED_DTM, EXPIRES_DTM) "
                    "VALUES (%s, %s, '앵커 탐침', 777, 'perks', %s, %s, %s, '명시 연 777만원', FALSE, "
                    "        '2026-09-18 00:00:00', '2028-03-18 00:00:00')",
                    (comp, code, badge, amt_src, "user_report" if badge == "verified" else "ai_parse"))
            member_c = _benefit_id(conn, c, "sk_anchor_member")
            member_d = _benefit_id(conn, d, "sk_anchor_seed")
            before = {bid: _row(conn, bid) for bid in (member_c, member_d)}

            backfill_dec2.backfill(cur)

            def src(comp, code):
                return _scalar(conn, "SELECT AMT_SOURCE_CD FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s",
                               (comp, code))

            assert src(a, "sk_anchor_member") == "stated" and src(b, "sk_anchor_member") == "stated", (
                "재직자 행이 앵커 판정(GROUP BY)에 끼어 두 회사의 공식 명시 금액을 강등시켰다")
            assert {src(x, "sk_anchor_seed") for x in (a, b, c)} == {"estimated"}, "앵커 강등 규칙(M-4)이 죽었다"
            for bid in (member_c, member_d):
                assert _row(conn, bid) == before[bid], f"재직자 행 {bid} 를 백필이 바꿨다(앵커 강등 UPDATE 포함)"
    finally:
        conn.rollback()
        conn.close()


# ── SK-4: 적재 도중 재직자 편집이 커밋되면 적재 전체를 되돌린다 ───────────────────────────

def test_SK4_적재_도중_재직자_편집이_커밋되면_적재를_되돌린다(seeded_db, members, monkeypatch):
    """스냅숏 뒤에 들어온 편집은 보존 대상에 없다 — 시드가 덮었을 수 있다. 그런 적재는 커밋하지 않는다.

    적재 커넥션을 REPEATABLE READ 로 연다(CI 의 mysql:8.0 기본값). 운영 서버는 READ COMMITTED 라
    적재 트랜잭션 안에서 읽어도 새 커밋이 보이지만, REPEATABLE READ 에서는 스냅숏에 갇혀 못 본다 —
    ⑥ 이 적재 트랜잭션 밖에서 읽는다는 사실을 이 서버에서도 시험하려는 것이다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    control = _benefit_id(seeded_db, krafton, "club")
    _tamper(seeded_db, control)

    plain_connect = seed_load.connect

    def rr_connect():
        conn = plain_connect()
        with conn.cursor() as cur:
            cur.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ")
        return conn

    monkeypatch.setattr(seed_load, "connect", rr_connect)
    original = backfill_dec2.backfill

    def racing_backfill(cur):
        stats = original(cur)
        other = plain_connect()  # 적재 트랜잭션 밖 — 편집 서비스가 그 사이 커밋한 것과 같다
        try:
            _insert_edit_log(other, None, krafton, kim, after={"benefit_cd": "resort"})
            other.commit()
        finally:
            other.close()
        return stats

    monkeypatch.setattr(backfill_dec2, "backfill", racing_backfill)
    with pytest.raises(seed_load.MemberRowGuardError, match="편집"):
        seed_load.main(fresh=False)
    # 커밋이 없었다 — 적재가 커밋됐다면 대조군이 시드 값으로 돌아왔을 것이다.
    assert _row(seeded_db, control)["BENEFIT_NM"] == TAMPERED_NM, "되돌렸어야 할 적재가 커밋됐다"


# ── SK-5: `--fresh` 는 재직자 데이터가 있으면 거부한다(함수) ──────────────────────────────

@pytest.mark.parametrize("state", ["편집 이력만", "재직자 행만"])
def test_SK5_fresh_는_재직자_데이터가_있으면_거부하고_명시적_폐기만_통과한다(seeded_db, members, state):
    """「편집 이력만」 = 오늘(2026-09-24) 운영 상태 — 재직자 행은 되돌아갔고 이력 2건만 남았다.
    이때 `--fresh` 가 돌면 다시 매겨진 BENEFIT_ID 에 이력이 붙어 **엉뚱한 행**에 재직자 배지가 뜬다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    resort = _benefit_id(seeded_db, krafton, "resort")
    control = _benefit_id(seeded_db, krafton, "club")
    control_nm = _row(seeded_db, control)["BENEFIT_NM"]
    _tamper(seeded_db, control)  # 거부됐다면 DROP·재적재가 없었으니 변조가 그대로 남는다
    if state == "편집 이력만":
        _insert_edit_log(seeded_db, resort, krafton, kim, after={"benefit_cd": "resort", "note_ctnt": "2회"})
    else:
        with seeded_db.cursor() as cur:
            cur.execute("UPDATE TCOMPANY_BENEFIT SET BADGE_CD='verified', BADGE_SRC_CD='user_report' "
                        "WHERE BENEFIT_ID=%s", (resort,))

    with pytest.raises(seed_load.FreshRefusedError, match="재직자"):
        seed_load.main(fresh=True)
    assert _row(seeded_db, control)["BENEFIT_NM"] == TAMPERED_NM, "거부했는데 DROP·재적재가 일어났다"

    # 명시적 폐기 허용 — 재직자 행·편집 이력이 함께 사라지고 정본 시드가 선다(이력이 남으면 엉뚱한 행을 가리킨다).
    seed_load.main(fresh=True, discard_member_edits=True)
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='verified'") == 0
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG") == 0, "폐기 허용인데 편집 이력이 남았다"
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT") == CANON_BENEFITS
    assert _row_by_code(seeded_db, "krafton", "club")["BENEFIT_NM"] == control_nm


# ── SK-6: CLI — 거부는 종료 코드 2, 폐기 신호는 진행 ─────────────────────────────────────

def test_SK6_CLI_fresh_거부는_종료코드_2이고_폐기_신호가_있어야_진행한다(seeded_db, members):
    from server.tests.schema_guard import assert_test_target

    env = dict(os.environ)
    assert_test_target(env.get("DB_NAME"))  # 🚨 파괴 CLI 를 부르는 테스트 — 서빙 이름이면 여기서 멈춘다
    env["LOUPIT_ALLOW_FRESH"] = "1"
    env.pop("LOUPIT_DISCARD_MEMBER_EDITS", None)
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    control = _benefit_id(seeded_db, krafton, "club")
    _tamper(seeded_db, control)
    _insert_edit_log(seeded_db, _benefit_id(seeded_db, krafton, "resort"), krafton, kim, after={"benefit_cd": "resort"})

    cmd = [sys.executable, str(SEED_DIR / "load.py"), "--fresh"]
    r = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 2, f"거부 종료 코드가 2가 아니다: {r.returncode}\n{r.stderr}"
    assert "재직자" in r.stderr and "python3 db/seed/load.py" in r.stderr, r.stderr  # 이유 + 대신 쓸 명령
    assert _row(seeded_db, control)["BENEFIT_NM"] == TAMPERED_NM, "CLI 가 거부했는데 DROP·재적재가 일어났다"

    env["LOUPIT_DISCARD_MEMBER_EDITS"] = "1"
    r = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG") == 0
    assert _row_by_code(seeded_db, "krafton", "club")["BENEFIT_NM"] != TAMPERED_NM


# ── SK-7: 폐기 허용 신호는 운영 스크립트에 없다 ───────────────────────────────────────

def test_SK7_폐기_허용_신호는_load_py_와_테스트_코드에만_있다():
    """🚨 신호를 스크립트·문서에 새기는 순간 `--fresh` 거부가 무력해진다 — 호출자가 계약을 지운다(함정 0075 와
    같은 모양). 폐기 허용은 격리 테스트 코드가 `main(discard_member_edits=True)` 로만 쓴다.

    추적 파일 **전체**를 본다(운영 스크립트·CI·마이그레이션·문서·서버 코드). 신호의 정의가 있는
    db/seed/load.py 와 server/tests 만 예외다. 미추적 인계 문서(docs/handoff)는 커밋하지 않으므로 보지 않는다."""
    try:
        listed = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError) as exc:
        pytest.skip(f"git ls-files 불가: {exc}")
    env_hits, arg_hits = [], []
    for rel in filter(None, listed.decode("utf-8").split("\0")):
        if rel == "db/seed/load.py" or rel.startswith("server/tests/"):
            continue
        path = ROOT / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "LOUPIT_DISCARD_MEMBER_EDITS" in text:
            env_hits.append(rel)
        if rel.endswith(".py") and re.search(r"discard_member_edits\s*=\s*True", text):
            arg_hits.append(rel)
    assert not env_hits, f"재직자 데이터 폐기 신호(환경변수)가 load.py·테스트 밖에 있다: {env_hits}"
    assert not arg_hits, f"재직자 데이터 폐기 허용(discard_member_edits=True)이 테스트 밖 코드에 있다: {arg_hits}"


# ── SK-8·SK-9: 표지·컬럼 목록 ─────────────────────────────────────────────────────

def test_SK8_재직자_표지는_편집_서비스가_쓰는_값과_같다():
    """보존 장치의 판정 기준(`MEMBER_BADGE_CD`)과 편집 서비스가 강제하는 배지가 갈라지면 보존이 조용히 꺼진다."""
    badge = backfill_dec2.MEMBER_BADGE_CD
    src = (ROOT / "server" / "services" / "benefit_edit.py").read_text(encoding="utf-8")
    insert = src[src.index("INSERT INTO TCOMPANY_BENEFIT"):src.index("INSERT INTO TBENEFIT_EDIT_LOG")]
    update = src[src.index("UPDATE TCOMPANY_BENEFIT SET"):]
    update = update[:update.index("WHERE")]
    assert f"'{badge}'" in insert, "등록(create) 경로의 배지 값이 시드 보존 표지와 다르다"
    assert f"BADGE_CD='{badge}'" in update, "수정(update) 경로의 배지 값이 시드 보존 표지와 다르다"
    assert seed_load.MEMBER_BADGE_CD == badge


def test_SK9_보존_컬럼_목록은_스키마에서_읽어_새_컬럼도_덮는다(seeded_db):
    with seeded_db.cursor() as cur:
        cur.execute("ALTER TABLE TCOMPANY_BENEFIT ADD COLUMN SK_PROBE_VAL VARCHAR(20) NULL")
        try:
            cols = seed_load._benefit_columns(cur)
        finally:
            cur.execute("ALTER TABLE TCOMPANY_BENEFIT DROP COLUMN SK_PROBE_VAL")
    assert "SK_PROBE_VAL" in cols, "새 컬럼이 보존 목록에 없다 — 컬럼 목록을 하드코딩했다"
    assert "BENEFIT_ID" not in cols, "조인 키(PK)는 되돌릴 대상이 아니다"
    assert {"BADGE_CD", "AMT_SOURCE_CD", "VERIFIED_DTM", "EXPIRES_DTM", "MOD_ID", "MOD_DTM", "INS_DTM"} <= set(cols)


# ── SK-10: 복구 마이그레이션이 적재와 겹쳐도 되살린 값이 남는다(② 잠금) ─────────────────────

def test_SK10_복구_마이그레이션이_적재와_겹쳐도_되살린_값이_남는다(seeded_db, members, monkeypatch):
    """스냅숏(②) 뒤·업서트 전에 복구 마이그레이션이 커밋되면, 되살린 행은 스냅숏에 없어 시드가 다시 덮는다 —
    ⑤(스냅숏에 없던 행)·⑥(마이그레이션은 이력을 남기지 않는다) 둘 다 모른다. 적재가 ②에서 이력이 가리키는
    행을 잠가, 마이그레이션이 적재 커밋 **뒤에** 돌게 해야 한다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    resort = _benefit_id(seeded_db, krafton, "resort")
    asyncio.run(_member_update(krafton, resort, kim, benefit_nm="휴양시설 지원", benefit_amt=None,
                               qual_yn=False, note_ctnt="2회"))
    _replay_wave("krafton")  # 사고 재현 — 시드 값·official 로 돌아가고 이력만 남았다
    assert _row(seeded_db, resort)["BADGE_CD"] == "official", "전제: 사고 상태"

    race: dict = {}
    original_run = seed_load.run_sql_file

    def run_and_race(cur, path):
        # 첫 복지 SQL 직전 = ② 뒤·크래프톤 업서트 전. 여기서 다른 커넥션이 복구 마이그레이션을 건다.
        if "thread" not in race and Path(path).parent == seed_load.BENEFIT_SQL_DIR:
            errors: list = []

            def migrate():
                try:
                    _apply_restore_migration()
                except Exception as exc:  # noqa: BLE001 — 스레드 예외를 본 테스트로 올린다
                    errors.append(exc)

            thread = threading.Thread(target=migrate, daemon=True)
            thread.start()
            thread.join(timeout=3.0)  # 적재가 그 행을 잠갔다면 3초 안에 끝날 수 없다
            race.update(thread=thread, errors=errors, finished_during_load=not thread.is_alive())
        return original_run(cur, path)

    monkeypatch.setattr(seed_load, "run_sql_file", run_and_race)
    seed_load.main(fresh=False)
    race["thread"].join(timeout=120)
    assert not race["errors"], race["errors"]
    assert not race["finished_during_load"], "복구 마이그레이션이 적재 도중 커밋됐다 — ② 잠금이 없다"
    row = _row(seeded_db, resort)
    assert (row["BADGE_CD"], row["BENEFIT_AMT"], row["NOTE_CTNT"]) == ("verified", None, "2회"), (
        "되살린 값을 적재가 다시 덮었다")


# ── SK-11: 대조(⑤)는 이진 비교 ─────────────────────────────────────────────────────

def test_SK11_대조는_이진_비교라_대소문자만_바꾼_쓰기도_잡는다(seeded_db, members, monkeypatch):
    """컬럼 콜레이션(utf8mb4_0900_ai_ci)으로 비교하면 'resort pass' 와 'RESORT PASS' 가 같다 — 앞으로 생길
    어떤 단계가 재직자 행을 대소문자만 바꿔 써도 ⑤ 가 통과시킨다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    resort = _benefit_id(seeded_db, krafton, "resort")
    asyncio.run(_member_update(krafton, resort, kim, benefit_nm="휴양시설 지원", benefit_amt=None,
                               qual_yn=False, note_ctnt="resort pass 2x"))
    original = backfill_dec2.backfill

    def sneaky_backfill(cur):
        stats = original(cur)
        # MOD_DTM 을 명시 대입해 ON UPDATE 자동 갱신을 막는다 — 대소문자 변화만 남긴다.
        cur.execute("UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = UPPER(NOTE_CTNT), MOD_DTM = MOD_DTM "
                    "WHERE BENEFIT_ID=%s", (resort,))
        return stats

    monkeypatch.setattr(backfill_dec2, "backfill", sneaky_backfill)
    with pytest.raises(seed_load.MemberRowGuardError, match="보존 실패"):
        seed_load.main(fresh=False)
    assert _row(seeded_db, resort)["NOTE_CTNT"] == "resort pass 2x", "되돌렸어야 할 적재가 커밋됐다"


# ── SK-12: 표가 적재 밖에서 다시 만들어졌으면 거부(⑦) ─────────────────────────────────────

def test_SK12_표가_적재_밖에서_다시_만들어졌으면_멱등_재적재도_거부한다(seeded_db, members):
    """TCOMPANY_BENEFIT 이 적재 밖에서 DROP·재생성되면 AUTO_INCREMENT 가 되감긴다. 그 위에 멱등 재적재를
    커밋하면 편집 이력에 남은 번호가 **다른 복지**에 붙어 그 행에 재직자 배지가 뜬다. 적재는 거부하고
    (롤백 — 표는 비어 있는 채로 남는다) 백업 복원을 안내해야 한다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    resort = _benefit_id(seeded_db, krafton, "resort")
    _insert_edit_log(seeded_db, resort, krafton, kim, after={"benefit_cd": "resort", "note_ctnt": "2회"})
    with seeded_db.cursor() as cur:
        cur.execute("SET FOREIGN_KEY_CHECKS=0")
        try:
            cur.execute("DROP TABLE TCOMPANY_BENEFIT")
        finally:
            cur.execute("SET FOREIGN_KEY_CHECKS=1")

    with pytest.raises(seed_load.MemberRowGuardError, match="백업"):
        seed_load.main(fresh=False)
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT") == 0, "거부했는데 재적재가 커밋됐다"
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG") == 1


# ── SK-13: 폐기 허용은 서빙 스키마에서 무조건 거부(심층 방어) ─────────────────────────────

def test_SK13_폐기_허용은_서빙_스키마_이름이면_DROP_전에_거부한다(seeded_db, monkeypatch):
    """폐기 허용의 방벽이 conftest C-1 한 겹뿐이면, 금지된 `LOUPIT_ALLOW_SERVING_SCHEMA=1 DB_NAME=LOUPIT pytest`
    한 번에 서빙의 편집 이력까지 지워진다. 접속한 스키마 이름이 서빙이면 load.py 가 스스로 멈춰야 한다.
    이 격리 DB 를 「서빙 이름」으로 취급하게 해 두고, 재직자 데이터가 없어도 DROP 전에 거부하는지 본다."""
    from server.tests.schema_guard import SERVING_SCHEMAS as GUARD_SERVING_SCHEMAS

    assert seed_load.SERVING_SCHEMAS == GUARD_SERVING_SCHEMAS, "load.py 와 C-1 가드의 서빙 스키마 목록이 갈라졌다"

    krafton = _comp_id(seeded_db, "krafton")
    control = _benefit_id(seeded_db, krafton, "club")
    control_nm = _row(seeded_db, control)["BENEFIT_NM"]
    _tamper(seeded_db, control)  # 거부됐다면 DROP·재적재가 없었으니 변조가 그대로 남는다
    current_db = _scalar(seeded_db, "SELECT DATABASE()")
    monkeypatch.setattr(seed_load, "SERVING_SCHEMAS", frozenset({current_db}))

    with pytest.raises(seed_load.FreshRefusedError, match="서빙 스키마"):
        seed_load.main(fresh=True, discard_member_edits=True)
    assert _row(seeded_db, control)["BENEFIT_NM"] == TAMPERED_NM, "거부했는데 DROP·재적재가 일어났다"

    monkeypatch.undo()  # 격리 DB 이름으로 되돌린 뒤 정본 시드를 다시 세운다(다른 파일의 정확 카운트가 전제)
    seed_load.main(fresh=True, discard_member_edits=True)
    assert _row_by_code(seeded_db, "krafton", "club")["BENEFIT_NM"] == control_nm
