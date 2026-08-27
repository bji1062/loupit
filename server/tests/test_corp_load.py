"""corp_code 매핑 적재·생성기 재무 로더 — FN-1·FN-4 (SP-FIN-2·4, T-15.1.1·15.1.5·15.2.1).

근거: `docs/SPEC/15-회사정보-재무.md` · `PLAN-회사정보-확장-2026-08-21.md` §5-1 · 함정 (69).

FN-1 이 지키는 것:
  - **회사는 이름으로 맞춘다.** CSV 의 `comp_id` 는 `load.py --fresh` 재시드 뒤 바뀔 수 있다
    (AUTO_INCREMENT 재배정, #15 동형). 이름이 정본이고 id 는 힌트다 — 다르면 경고하고 이름을 믿는다.
  - `status=UNMAPPED`(CJ올리브영) 는 건너뛰되 **말한다**(조용한 누락 금지).
  - 금융 7사만 `financial`, CJ ENM 두 페이지는 **같은 법인**(1:N).
  - `load.py` 마지막 단계에서 호출된다 → `seeded_db` 만으로 매핑이 채워져 있어야 한다.

FN-4 가 지키는 것: 생성기 로더(`generator/finance.py::load_finance`)가 **실제 쿼리 경로**로
CJ ENM 두 페이지에 같은 수치를 주고 서로를 `siblings` 로 안다. (픽스처가 파이프라인을 건너뛰는
테스트는 그 구간에 없는 것과 같다 — 그래서 bundle.py 가 쓰는 aiomysql 경로 그대로 돈다.)
"""
from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import load_corp  # noqa: E402  # db/seed/load_corp.py

FINANCIAL_7 = {"DB손해보험", "NH투자증권", "기업은행", "삼성생명", "삼성카드", "카카오뱅크", "카카오페이"}
CJ_ENM_CORP = "00265324"


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def _rows(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


# ── FN-1: seeded_db 위 실 DB ─────────────────────────────────────────────────

def test_FN1_seed_populates_mapping_at_last_step(seeded_db):
    """`load.main(fresh=True)` 만으로 TCORP·TCOMPANY_CORP 가 채워진다(재시드 후 매핑 소실 방지)."""
    rows = load_corp.read_map()
    mapped = [r for r in rows if r["status"] != "UNMAPPED"]
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_CORP") == len(mapped) == 101
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCORP") == len({r["corp_code"] for r in mapped}) == 100
    # 매핑된 회사는 전부 실재하는 TCOMPANY 를 가리킨다(고아 0)
    assert _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_CORP cc LEFT JOIN TCOMPANY c ON c.COMP_ID=cc.COMP_ID WHERE c.COMP_ID IS NULL",
    ) == 0


def test_FN1_reapply_is_idempotent(seeded_db):
    """재적용은 행을 바꾸지 않는다. ⓘ 이 DB 에서 CSV comp_id 는 **실제로 어긋나 있다**(fresh 재시드는
    파일 순서로 ID 를 배정하고, CSV 는 증분 적재된 prod 의 ID 를 담고 있다 — DB손해보험 csv=2/db=9).
    그래서 `id_drift` 는 비어 있지 않은 것이 정상이고, 드리프트 100건이 전부 이름으로 해소돼 101행이
    맞물린다는 사실이 이 테스트의 요점이다. 경고는 행마다가 아니라 **요약 한 줄**이어야 진짜 경고가 묻히지 않는다."""
    before = _rows(seeded_db, "SELECT COMP_ID, CORP_CODE, MATCH_CD FROM TCOMPANY_CORP ORDER BY COMP_ID")
    corps_before = _rows(seeded_db, "SELECT CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD FROM TCORP ORDER BY CORP_CODE")
    lines: list[str] = []
    with seeded_db.cursor() as cur:
        stats = load_corp.apply(cur, load_corp.read_map(), out=lines.append)
    seeded_db.commit()
    assert _rows(seeded_db, "SELECT COMP_ID, CORP_CODE, MATCH_CD FROM TCOMPANY_CORP ORDER BY COMP_ID") == before
    assert _rows(seeded_db, "SELECT CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD FROM TCORP ORDER BY CORP_CODE") == corps_before
    assert stats["mapped"] == 101 and stats["unmatched"] == []
    assert all(db_id == dict((nm, cid) for cid, nm in _rows(seeded_db, "SELECT COMP_ID, COMP_NM FROM TCOMPANY"))[nm]
               for nm, _csv_id, db_id in stats["id_drift"]), "드리프트가 이름으로 해소되지 않았다"
    drift_lines = [ln for ln in lines if "드리프트" in ln]
    assert len(drift_lines) <= 1, f"드리프트 경고가 행마다 찍힌다({len(drift_lines)}줄) — 요약 한 줄이어야 한다"


def test_FN1_unmapped_company_is_skipped_and_announced(seeded_db):
    assert _scalar(
        seeded_db,
        "SELECT COUNT(*) FROM TCOMPANY_CORP cc JOIN TCOMPANY c ON c.COMP_ID=cc.COMP_ID WHERE c.COMP_NM='CJ올리브영'",
    ) == 0
    lines: list[str] = []
    with seeded_db.cursor() as cur:
        stats = load_corp.apply(cur, load_corp.read_map(), out=lines.append)
    seeded_db.commit()
    assert stats["skipped_unmapped"] == ["CJ올리브영"]
    assert any("CJ올리브영" in ln and "UNMAPPED" in ln for ln in lines), "건너뛴 회사를 표준출력에 남기지 않았다"


def test_FN1_financial_seven_and_everyone_else_general(seeded_db):
    rows = _rows(
        seeded_db,
        "SELECT c.COMP_NM, k.ACCT_SET_CD, k.FS_DIV_CD FROM TCOMPANY_CORP cc "
        "JOIN TCOMPANY c ON c.COMP_ID=cc.COMP_ID JOIN TCORP k ON k.CORP_CODE=cc.CORP_CODE",
    )
    financial = {nm for nm, acct, _ in rows if acct == "financial"}
    assert financial == FINANCIAL_7
    assert all(acct in ("general", "financial") for _, acct, _ in rows)
    assert all(div == "CFS" for _, _, div in rows), "기본 표시 기준은 CFS"


def test_FN1_cj_enm_two_pages_share_one_corporation(seeded_db):
    rows = _rows(
        seeded_db,
        "SELECT c.COMP_NM FROM TCOMPANY_CORP cc JOIN TCOMPANY c ON c.COMP_ID=cc.COMP_ID "
        "WHERE cc.CORP_CODE=%s ORDER BY c.COMP_NM",
        (CJ_ENM_CORP,),
    )
    assert [r[0] for r in rows] == ["CJ ENM 엔터테인먼트부문", "CJ ENM 커머스부문"]


def test_FN1_corp_nm_prefers_dart_name_from_note(seeded_db):
    """TCORP.CORP_NM 은 DART 명(note 에 있으면) — 우리 표시명과 다를 수 있다(KT ≠ 케이티)."""
    by_code = {code: nm for code, nm in _rows(seeded_db, "SELECT CORP_CODE, CORP_NM FROM TCORP")}
    assert by_code["00190321"] == "케이티"
    assert by_code["00223799"] == "씨제이올리브네트웍스"
    assert by_code["00261443"] == "NC"
    assert by_code["00126380"] == "삼성전자"  # note 없음 → comp_nm
    assert by_code["00149655"] == "삼성물산"  # note 는 있으나 DART 명 아님 → comp_nm


def test_FN1_match_by_name_not_by_csv_comp_id(seeded_db, clean_tx):
    """CSV comp_id 가 틀려도 이름으로 맞추고 드리프트를 보고한다. 이름이 DB 에 없으면 쓰지 않고 말한다."""
    conn = clean_tx
    rows = load_corp.read_map()
    samsung = next(r for r in rows if r["comp_nm"] == "삼성전자")
    real_id = _scalar(conn, "SELECT COMP_ID FROM TCOMPANY WHERE COMP_NM='삼성전자'")
    drifted = {**samsung, "comp_id": str(real_id + 1000)}
    ghost = {**samsung, "comp_id": "9999", "comp_nm": "없는회사", "corp_code": "09999999", "stock_code": "999999", "note": ""}
    lines: list[str] = []
    with conn.cursor() as cur:
        stats = load_corp.apply(cur, [drifted, ghost], out=lines.append)
        cur.execute("SELECT COMP_ID FROM TCOMPANY_CORP WHERE CORP_CODE=%s", (samsung["corp_code"],))
        assert [r[0] for r in cur.fetchall()] == [real_id]
        cur.execute("SELECT COUNT(*) FROM TCORP WHERE CORP_CODE='09999999'")
        assert cur.fetchone()[0] == 0, "DB 에 없는 회사의 법인을 만들었다"
    assert stats["id_drift"] == [("삼성전자", real_id + 1000, real_id)]
    assert stats["unmatched"] == ["없는회사"]
    assert any("없는회사" in ln for ln in lines)


def test_FN1_mapping_rows_outside_csv_are_removed(seeded_db, clean_tx):
    """CSV 가 매핑의 정본이다 — 옛 COMP_ID 가 남긴 잔존 행(재시드 후 오귀속)은 지운다."""
    conn = clean_tx
    ghost_comp = _scalar(conn, "SELECT COMP_ID FROM TCOMPANY WHERE COMP_NM='CJ올리브영'")
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD) VALUES (%s, %s, 'manual')",
            (ghost_comp, "00126380"),  # 올리브영 → 삼성전자 법인이라는 거짓 행
        )
        stats = load_corp.apply(cur, load_corp.read_map(), out=lambda s: None)
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_CORP WHERE COMP_ID=%s", (ghost_comp,))
        assert cur.fetchone()[0] == 0
    assert stats["removed"] == 1


# ── FN-4: 생성기 로더 실 경로 ────────────────────────────────────────────────

def _aiomysql_conn():
    import aiomysql

    return aiomysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        db=os.environ["DB_NAME"],
        charset="utf8mb4",
        cursorclass=aiomysql.DictCursor,
    )


async def _load_via_generator():
    from generator.finance import load_finance

    conn = await _aiomysql_conn()
    try:
        return await load_finance(conn)
    finally:
        conn.close()


def test_FN4_cj_enm_pages_share_figures_and_know_siblings(seeded_db):
    conn = seeded_db
    ids = {nm: cid for cid, nm in _rows(conn, "SELECT COMP_ID, COMP_NM FROM TCOMPANY WHERE COMP_NM LIKE 'CJ ENM %%'")}
    ent, com = ids["CJ ENM 엔터테인먼트부문"], ids["CJ ENM 커머스부문"]
    fin_rows = [
        (CJ_ENM_CORP, 2025, "CFS", "ifrs-full_Revenue", "매출액", 4_795_000_000_000, "20260319000009"),
        (CJ_ENM_CORP, 2025, "CFS", "dart_OperatingIncomeLoss", "영업이익", 120_000_000_000, "20260319000009"),
        (CJ_ENM_CORP, 2025, "CFS", "ifrs-full_ProfitLoss", "당기순이익", -50_000_000_000, "20260319000009"),
        (CJ_ENM_CORP, 2025, "OFS", "ifrs-full_Revenue", "매출액", 1_000_000_000_000, "20260319000009"),
        (CJ_ENM_CORP, 2024, "CFS", "ifrs-full_Revenue", "매출액", 4_500_000_000_000, "20250320000008"),
    ]
    try:
        with conn.cursor() as cur:
            cur.executemany(
                "INSERT INTO TCORP_FINANCE (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, ACCT_NM, AMT_VAL, RCEPT_NO) "
                "VALUES (%s,%s,%s,%s,%s,%s,%s)",
                fin_rows,
            )
        finance = asyncio.run(_load_via_generator())
        assert finance[ent]["years"] == finance[com]["years"], "같은 법인인데 두 페이지 수치가 다르다"
        assert finance[ent]["siblings"] == [com] and finance[com]["siblings"] == [ent]
        assert finance[ent]["fs_div"] == "CFS"
        years = {y["year"]: y for y in finance[ent]["years"]}
        assert years[2025]["revenue"] == 4_795_000_000_000  # OFS 행은 화면 기준(CFS)이 아니라 빠진다
        assert years[2025]["net_income"] == -50_000_000_000
        assert years[2025]["rcept_no"] == "20260319000009"
        assert years[2024]["op_income"] is None  # 없는 행은 None — 0 으로 지어내지 않는다
        assert isinstance(years[2025]["revenue"], int), "DECIMAL 을 int 로 — JSON 덤프(--finance-json) 가능해야 한다"
        # 매핑만 있고 재무가 없는 회사도 목록에 있다(years 비어 있음) — 인덱스 섹션 배치(일반/금융)에 필요
        samsung_life = _scalar(conn, "SELECT COMP_ID FROM TCOMPANY WHERE COMP_NM='삼성생명'")
        assert finance[samsung_life]["acct_set"] == "financial" and finance[samsung_life]["years"] == []
        # UNMAPPED 회사는 아예 없다
        olive = _scalar(conn, "SELECT COMP_ID FROM TCOMPANY WHERE COMP_NM='CJ올리브영'")
        assert olive not in finance
    finally:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM TCORP_FINANCE WHERE CORP_CODE=%s", (CJ_ENM_CORP,))
