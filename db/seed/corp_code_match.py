#!/usr/bin/env python3
"""등록 회사 ↔ DART `corp_code` 매칭 (읽기 전용 — CSV 만 쓴다).

근거: `docs/PLAN-회사정보-확장-2026-08-21.md` §3·§5-1.

**자동 매칭은 후보 생성까지다.** 회사명 문자열 매칭은 계열사 오매핑 전력이 있어
(bokziri 집계 770개 중 148개 회사명 오염) 애매한 것은 확정하지 않고 사람에게 넘긴다.
2026-08-21 실행 결과 102개 중 96개가 자동 확정, 6개가 검수 대상이었고 그 6개의 판정은
아래 `MANUAL` 에 근거와 함께 박아 뒀다 — **재실행해도 같은 결과가 나온다.**

사용법:
    python3 db/seed/corp_code_match.py --corpcode-xml /path/to/CORPCODE.xml \\
        [--out db/seed/corp_code_map.csv]

CORPCODE.xml 받는 법(키는 server/.env):
    curl -s -o corpCode.zip \\
      "https://opendart.fss.or.kr/api/corpCode.xml?crtfc_key=$DART_API_KEY" && unzip corpCode.zip
"""
from __future__ import annotations

import argparse
import csv
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV_PATH = ROOT / "server" / ".env"

# 사업부문 접미사 — 우리 서비스의 구분이지 법인 구분이 아니다.
DIVISION_SUFFIX = re.compile(r"(엔터테인먼트부문|커머스부문|부문)$")

# ── 사람 검수 결과(2026-08-21) ───────────────────────────────────────────────
# 자동 매칭이 확정하지 못한 6건. `corp_code=None` 은 "법인을 특정하지 못했다"는 뜻이며
# 빈칸으로 남기는 것이 추측으로 채우는 것보다 정직하다(§3-4 "없으면 비워 두고 그렇게 말한다").
MANUAL: dict[str, dict] = {
    "KT": {
        "corp_code": "00190321", "stock_code": "030200",
        "note": "DART 정식명이 한글 '케이티' 라 영문 표기로는 매칭되지 않는다",
    },
    "삼성물산": {
        "corp_code": "00149655", "stock_code": "028260",
        "note": "동명 2건. modify_date 2026-03-23 인 쪽이 현행 — 00126229/000830 은 2017 이후 갱신 없음",
    },
    "CJ올리브네트웍스": {
        "corp_code": "00223799", "stock_code": "",
        "note": "비상장이라 stock_code 없음. DART 명 '씨제이올리브네트웍스'",
    },
    "LIG디펜스앤에어로스페이스(구 LIG넥스원)": {
        "corp_code": "00503668", "stock_code": "079550",
        "note": "사명 변경 — DART 'LIG디펜스앤에어로스페이스'(정식 엘아이지디펜스앤에어로스페이스(주))",
    },
    "엔씨소프트(NC)": {
        "corp_code": "00261443", "stock_code": "036570",
        "note": "사명 변경 — DART corp_name 은 'NC'(정식 (주)엔씨)",
    },
    "CJ올리브영": {
        "corp_code": None, "stock_code": "",
        "note": "후보 2건(01423068·00429870) 모두 2025 사업보고서 없음 — 비상장. "
                "법인 특정 불가라 비워 둔다. 재무는 채우지 않는다",
    },
}


def norm(s: str) -> str:
    s = (s or "").strip()
    s = re.sub(r"\(주\)|㈜|주식회사", "", s)
    s = re.sub(r"[\s\-.,·()＆&]", "", s)
    return s.lower()


def _env() -> dict[str, str]:
    env: dict[str, str] = {}
    for line in ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env


def load_db_companies() -> list[tuple[int, str, list[str]]]:
    """(COMP_ID, COMP_NM, 별칭[]) — 읽기 전용."""
    env = _env()
    sql = (
        "SELECT c.COMP_ID, c.COMP_NM, COALESCE(GROUP_CONCAT(a.ALIAS_NM SEPARATOR '\\t'), '') "
        "FROM TCOMPANY c LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID "
        "GROUP BY c.COMP_ID, c.COMP_NM ORDER BY c.COMP_ID;"
    )
    out = subprocess.run(
        ["mysql", "-h", env["DB_HOST"], "-u", env["DB_USER"], env["DB_NAME"], "-N", "-e", sql],
        capture_output=True, text=True, env={**os.environ, "MYSQL_PWD": env["DB_PASSWORD"]},
    )
    if out.returncode != 0:
        sys.exit(f"DB 조회 실패: {out.stderr}")
    rows = []
    for line in out.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            rows.append((int(parts[0]), parts[1], [a for a in parts[2:] if a]))
    return rows


def load_dart(xml_path: Path) -> dict[str, list[dict]]:
    by_name: dict[str, list[dict]] = defaultdict(list)
    for r in ET.parse(xml_path).getroot().findall("list"):
        name = (r.findtext("corp_name") or "").strip()
        if not name:
            continue
        stock = (r.findtext("stock_code") or "").strip()
        by_name[norm(name)].append({
            "corp_code": (r.findtext("corp_code") or "").strip(),
            "corp_name": name, "stock_code": stock, "listed": bool(stock),
        })
    return by_name


def match(companies, dart) -> list[dict]:
    results = []
    for comp_id, comp_nm, aliases in companies:
        if comp_nm in MANUAL:                       # 사람 판정이 자동보다 우선한다
            m = MANUAL[comp_nm]
            results.append({
                "comp_id": comp_id, "comp_nm": comp_nm,
                "status": "manual" if m["corp_code"] else "UNMAPPED",
                "corp_code": m["corp_code"] or "", "stock_code": m["stock_code"],
                "note": m["note"],
            })
            continue

        keys = [comp_nm]
        base = DIVISION_SUFFIX.sub("", comp_nm).strip()
        if base != comp_nm:
            keys.append(base)
        keys.extend(aliases)

        hits, seen = [], set()
        for key in keys:
            for cand in dart.get(norm(key), []):
                if cand["corp_code"] not in seen:
                    seen.add(cand["corp_code"])
                    hits.append(cand)

        listed = [h for h in hits if h["listed"]]
        if len(listed) == 1:
            pick, status, note = listed[0], "auto", ""
        else:
            pick, status = None, "REVIEW"
            note = f"자동 확정 불가(hits={len(hits)}, listed={len(listed)}) — MANUAL 에 판정을 추가하라"
        results.append({
            "comp_id": comp_id, "comp_nm": comp_nm, "status": status,
            "corp_code": pick["corp_code"] if pick else "",
            "stock_code": pick["stock_code"] if pick else "",
            "note": note,
        })
    return results


def main() -> int:
    ap = argparse.ArgumentParser(description="회사 ↔ DART corp_code 매칭")
    ap.add_argument("--corpcode-xml", required=True, type=Path, help="DART CORPCODE.xml")
    ap.add_argument("--out", type=Path, default=ROOT / "db" / "seed" / "corp_code_map.csv")
    a = ap.parse_args()

    results = match(load_db_companies(), load_dart(a.corpcode_xml))

    with open(a.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["comp_id", "comp_nm", "status", "corp_code", "stock_code", "note"])
        w.writeheader()
        w.writerows(results)

    counts: dict[str, int] = defaultdict(int)
    for r in results:
        counts[r["status"]] += 1
    print(f"총 {len(results)}개 → {a.out}")
    for k in sorted(counts):
        print(f"  {k:9s} {counts[k]}")

    # 한 법인을 여러 페이지가 가리키는 경우(1:N) — 스키마가 표현해야 하는 관계라 눈에 띄게 찍는다
    dup: dict[str, list[str]] = defaultdict(list)
    for r in results:
        if r["corp_code"]:
            dup[r["corp_code"]].append(r["comp_nm"])
    for code, names in dup.items():
        if len(names) > 1:
            print(f"  ★ 1:N — {code}: {' / '.join(names)}")

    if counts.get("REVIEW"):
        print("\n⚠ REVIEW 항목은 사람이 판정해 MANUAL 에 추가해야 한다:")
        for r in results:
            if r["status"] == "REVIEW":
                print(f"    {r['comp_nm']}  {r['note']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
