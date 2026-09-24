"""SP-SEED-12 재직자 행 보존 — 시드·백필은 재직자 행(`BADGE_CD='verified'`)을 쓰지 않는다 (SK-1~SK-9).

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
  - SK-7 폐기 허용 신호는 운영 스크립트·CI·마이그레이션에 없다.
  - SK-8·SK-9 재직자 표지는 편집 서비스와 같은 값이고, 보존 컬럼 목록은 스키마에서 읽는다(새 컬럼 자동 포함).

⚠ 재직자 데이터를 만드는 테스트는 끝나면 `main(fresh=True, discard_member_edits=True)` 로 정본 시드를
  다시 세운다(`members` 픽스처) — 다른 파일의 정확 카운트(SD-4 2451 등)가 그 상태를 전제한다.
"""
from __future__ import annotations

import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path

import pymysql
import pytest

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import backfill_dec2  # noqa: E402  # db/seed/backfill_dec2.py
import load as seed_load  # noqa: E402  # db/seed/load.py

CANON_BENEFITS = 2451  # SD-4 정본 복지 행 수(test_seed_counts)
TAMPERED_NM = "SK 변조 대조군"


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
    재직자 값이 다른 회사의 공식 값을 강등시키면 안 된다. 셋 다 공식이면 여전히 강등(규칙 생존 대조군)."""
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            a, b, c = (_comp_id(conn, e) for e in ("krafton", "cj_enm_com", "samsung_elec"))
            rows = [
                # (회사, 코드, 배지, note) — note 에 추정 표기가 없어 규칙상 stated 후보
                (a, "sk_anchor_member", "official", "회사 명시 연 777만원"),
                (b, "sk_anchor_member", "official", "회사 명시 연 777만원"),
                (c, "sk_anchor_member", "verified", "재직자 확인 연 777만원"),
                (a, "sk_anchor_seed", "official", "회사 명시 연 777만원"),
                (b, "sk_anchor_seed", "official", "회사 명시 연 777만원"),
                (c, "sk_anchor_seed", "official", "회사 명시 연 777만원"),
            ]
            for comp, code, badge, note in rows:
                cur.execute(
                    "INSERT INTO TCOMPANY_BENEFIT (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD, "
                    " BADGE_CD, AMT_SOURCE_CD, BADGE_SRC_CD, NOTE_CTNT, QUAL_YN, VERIFIED_DTM, EXPIRES_DTM) "
                    "VALUES (%s, %s, '앵커 탐침', 777, 'perks', %s, 'estimated', %s, %s, FALSE, "
                    "        '2026-09-18 00:00:00', '2028-03-18 00:00:00')",
                    (comp, code, badge, "user_report" if badge == "verified" else "ai_parse", note))

            backfill_dec2.backfill(cur)

            def src(comp, code):
                return _scalar(conn, "SELECT AMT_SOURCE_CD FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s",
                               (comp, code))

            assert src(a, "sk_anchor_member") == "stated" and src(b, "sk_anchor_member") == "stated", (
                "재직자 행이 앵커 판정에 끼어 두 회사의 공식 명시 금액을 강등시켰다")
            assert src(c, "sk_anchor_member") == "estimated", "재직자 행의 금액출처(estimated)를 백필이 바꿨다"
            assert {src(x, "sk_anchor_seed") for x in (a, b, c)} == {"estimated"}, "앵커 강등 규칙(M-4)이 죽었다"
    finally:
        conn.rollback()
        conn.close()


# ── SK-4: 적재 도중 재직자 편집이 커밋되면 적재 전체를 되돌린다 ───────────────────────────

def test_SK4_적재_도중_재직자_편집이_커밋되면_적재를_되돌린다(seeded_db, members, monkeypatch):
    """스냅숏 뒤에 들어온 편집은 보존 대상에 없다 — 시드가 덮었을 수 있다. 그런 적재는 커밋하지 않는다."""
    kim = members["sk-kim"]
    krafton = _comp_id(seeded_db, "krafton")
    control = _benefit_id(seeded_db, krafton, "club")
    _tamper(seeded_db, control)

    original = backfill_dec2.backfill

    def racing_backfill(cur):
        stats = original(cur)
        other = seed_load.connect()  # 적재 트랜잭션 밖 — 편집 서비스가 그 사이 커밋한 것과 같다
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

def test_SK7_폐기_허용_신호는_운영_스크립트_CI_마이그레이션에_없다():
    """🚨 신호를 스크립트에 새기는 순간 `--fresh` 거부가 무력해진다 — 호출자가 계약을 지운다(함정 0075 와 같은 모양).
    폐기 허용은 격리 테스트 코드가 `main(discard_member_edits=True)` 로만 쓴다."""
    hits = []
    for base in ("infra", ".github", "db/migrations"):
        for p in sorted((ROOT / base).rglob("*")):
            if p.is_file() and "LOUPIT_DISCARD_MEMBER_EDITS" in p.read_text(encoding="utf-8", errors="ignore"):
                hits.append(str(p.relative_to(ROOT)))
    assert not hits, f"재직자 데이터 폐기 신호가 운영 경로에 있다: {hits}"


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
