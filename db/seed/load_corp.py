"""SP-FIN-2 — corp_code 매핑 적재: `corp_code_map.csv` → TCORP·TCOMPANY_CORP (멱등 upsert).

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-2 · `PLAN-회사정보-확장-2026-08-21.md` §5-1 · 함정 (69).

CSV 는 `corp_code_match.py` 가 사람 검수(MANUAL)까지 반영해 쓴 **매핑의 정본**이다. 이 모듈은
그것을 DB 에 옮길 뿐 판단하지 않는다.

**회사는 `COMP_NM` 으로 맞춘다 — CSV 의 `comp_id` 는 힌트다.** `load.py --fresh` 는 TCOMPANY 를
DROP/재생성해 COMP_ID(AUTO_INCREMENT)를 다시 배정한다(#15 동형). id 로 맞추면 재시드 한 번에
삼성전자 페이지가 남의 법인 실적을 받는다. 이름이 다르면(사명 변경 등) 적재하지 않고 **말한다**.

`TCOMPANY_CORP` 는 CSV 와 **완전 동기화**한다(CSV 에 없는 회사의 행은 지운다) — `--fresh` 뒤
살아남은 옛 COMP_ID 행이 다른 회사로 재해석되는 것을 막기 위해서다. `TCORP` 는 지우지 않는다
(재무가 매달려 있고 ON DELETE CASCADE 다). `TCORP.FS_DIV_CD` 는 최초 삽입 때만 기본(CFS)을 넣고
재적용 때 덮어쓰지 않는다 — 운영자가 지주사를 별도(OFS)로 돌려놓은 결정을 재시드가 되감으면 안 된다.

CLI: `python3 db/seed/load_corp.py` (server/.env 의 DB). `load.py` 가 마지막 단계에서 `apply()` 를
직접 부르므로 평소엔 따로 돌릴 일이 없다.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
CSV_PATH = SEED_DIR / "corp_code_map.csv"

if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

# 금융 7사 — 재무제표 양식 자체가 다르다(매출·영업이익 계정 부재, 삼성생명 실측). §3 군 분류.
FINANCIAL_COMPANIES = frozenset({
    "DB손해보험", "NH투자증권", "기업은행", "삼성생명", "삼성카드", "카카오뱅크", "카카오페이",
})

# note 에 적힌 DART 정식명 — "DART 명 '씨제이올리브네트웍스'" · "DART 'LIG…'" · "DART corp_name 은 'NC'" 꼴.
_DART_NM_RE = re.compile(r"DART[^']*'([^']+)'")

_SQL_UPSERT_CORP = (
    "INSERT INTO TCORP (CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD) VALUES (%s, %s, %s, %s, 'CFS') "
    "AS new ON DUPLICATE KEY UPDATE CORP_NM = new.CORP_NM, STOCK_CD = new.STOCK_CD, ACCT_SET_CD = new.ACCT_SET_CD"
)
_SQL_UPSERT_LINK = (
    "INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD, MATCH_NOTE_CTNT) VALUES (%s, %s, %s, %s) "
    "AS new ON DUPLICATE KEY UPDATE CORP_CODE = new.CORP_CODE, MATCH_CD = new.MATCH_CD, "
    "MATCH_NOTE_CTNT = new.MATCH_NOTE_CTNT"
)


def read_map(path: Path = CSV_PATH) -> list[dict]:
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def dart_corp_nm(row: dict) -> str:
    """TCORP.CORP_NM — note 에 DART 명이 있으면 그것, 없으면 우리 표시명."""
    m = _DART_NM_RE.search(row.get("note") or "")
    return m.group(1) if m else row["comp_nm"]


def acct_set_for(comp_nm: str) -> str:
    return "financial" if comp_nm in FINANCIAL_COMPANIES else "general"


def apply(cur, rows: list[dict], *, out=print) -> dict:
    """CSV 행을 TCORP·TCOMPANY_CORP 에 upsert 한다(커밋은 호출자 몫). 반환 = 통계.

    통계 키: corps(법인 upsert 수) · mapped(매핑 행 수) · skipped_unmapped[이름] · unmatched[이름]
    (DB 에 없는 회사 — 적재 안 함) · id_drift[(이름, csv_id, db_id)] · removed(CSV 밖 잔존 행 삭제 수).
    `out` 으로 건너뜀·경고를 남긴다 — 조용한 누락 금지.
    """
    cur.execute("SELECT COMP_ID, COMP_NM FROM TCOMPANY")
    by_name = {nm: int(cid) for cid, nm in cur.fetchall()}

    stats: dict = {"corps": 0, "mapped": 0, "skipped_unmapped": [], "unmatched": [], "id_drift": [], "removed": 0}
    corps: dict[str, tuple] = {}
    links: list[tuple] = []
    for r in rows:
        nm = r["comp_nm"]
        if r.get("status") == "UNMAPPED" or not r.get("corp_code"):
            stats["skipped_unmapped"].append(nm)
            out(f"[load_corp] UNMAPPED 건너뜀: {nm} — {r.get('note') or '법인 미특정'}")
            continue
        comp_id = by_name.get(nm)
        if comp_id is None:
            stats["unmatched"].append(nm)
            out(f"[load_corp] ⚠ DB 에 없는 회사라 적재하지 않음: {nm} (csv comp_id={r.get('comp_id')}) — "
                "표시명이 바뀌었으면 corp_code_map.csv 를 다시 만들어라(함정 (70))")
            continue
        csv_id = int(r["comp_id"]) if (r.get("comp_id") or "").strip() else None
        if csv_id is not None and csv_id != comp_id:
            stats["id_drift"].append((nm, csv_id, comp_id))
        corps[r["corp_code"]] = (r["corp_code"], dart_corp_nm(r), (r.get("stock_code") or "").strip() or None,
                                 acct_set_for(nm))
        links.append((comp_id, r["corp_code"], r.get("status") or "auto", (r.get("note") or "").strip() or None))

    if stats["id_drift"]:
        # 요약 한 줄 — 행마다 찍으면(fresh 재시드 DB 에선 100건이 정상이다) 진짜 경고가 묻힌다.
        sample = ", ".join(f"{nm} csv={a}/db={b}" for nm, a, b in stats["id_drift"][:3])
        out(f"[load_corp] ⚠ comp_id 드리프트 {len(stats['id_drift'])}건 — 이름 매칭을 신뢰한다(예: {sample})")

    for c in corps.values():  # 법인 먼저(FK 부모). CJ ENM 두 행은 같은 법인 → dict 로 한 번만
        cur.execute(_SQL_UPSERT_CORP, c)
    for link in links:
        cur.execute(_SQL_UPSERT_LINK, link)
    stats["corps"] = len(corps)
    stats["mapped"] = len(links)

    if links:  # CSV 밖 잔존 행 제거 — 옛 COMP_ID 가 다른 회사로 재해석되는 것을 막는다
        ids = [link[0] for link in links]
        cur.execute(
            f"DELETE FROM TCOMPANY_CORP WHERE COMP_ID NOT IN ({','.join(['%s'] * len(ids))})", ids,
        )
        stats["removed"] = cur.rowcount or 0
        if stats["removed"]:
            out(f"[load_corp] CSV 밖 잔존 매핑 {stats['removed']}행 제거")
    return stats


def main() -> int:
    import load as seed_load  # db/seed/load.py — 접속(server/.env)만 빌린다

    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            stats = apply(cur, read_map())
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
    print(f"load_corp done: corps={stats['corps']} mapped={stats['mapped']} "
          f"unmapped={len(stats['skipped_unmapped'])} unmatched={len(stats['unmatched'])} "
          f"id_drift={len(stats['id_drift'])} removed={stats['removed']}")
    return 1 if stats["unmatched"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
