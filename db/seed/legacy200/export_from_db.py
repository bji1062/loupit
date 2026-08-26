#!/usr/bin/env python3
"""db/seed/legacy200/export_from_db.py — 서빙 DB → seed200.py 동봉본 생성 (서버 1회 실행).

배경: 시드 파이프라인의 별칭 승계 소스(200-seed 4파일)는 은퇴한 레거시 리포
(/home/ubuntu/job_change)에만 있었고 저장소에 커밋된 적이 없다(함정 74 부류).
파이프라인이 그 파일들에서 실제로 소비하는 필드는 **name·aliases 둘뿐**이며
(company_meta.build_company_meta), 그 정보의 현행 정본은 서빙 DB 다 —
TCOMPANY.COMP_NM + TCOMPANY_ALIAS.ALIAS_NM (수동 override 포함 최신 상태).

이 스크립트는 서빙 DB 를 읽어 `seed200.py`(SEED200 리스트)를 생성한다.
생성본을 커밋하면 job_change 는 어떤 경로에서도 더는 필요 없다.

서버에서:
    cd /home/ubuntu/loupit
    python3 db/seed/legacy200/export_from_db.py     # server/.env 자격 사용(읽기만)
    git add db/seed/legacy200/seed200.py && git commit && git push

멱등성: 도출본의 별칭 = DB 별칭 전체(과거 승계분 ∪ override 적용분)이므로,
이 파일로 재시드해도 apply_company_meta 가 같은 집합을 다시 만든다(라운드트립 안정).
"""
from __future__ import annotations

import os
import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT))

import pymysql  # noqa: E402  — server/requirements.txt (load.py 와 동일 의존)
from dotenv import load_dotenv  # noqa: E402

OUT = HERE / "seed200.py"


def connect():
    load_dotenv(ROOT / "server" / ".env")  # override=False — export 한 env 우선(load.py 규약)
    return pymysql.connect(
        host=os.environ.get("DB_HOST", "127.0.0.1"),
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
    )


def main() -> int:
    conn = connect()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT c.COMP_NM, a.ALIAS_NM FROM TCOMPANY c "
            "LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID "
            "ORDER BY c.COMP_NM, a.ALIAS_NM"
        )
        rows = cur.fetchall()
    finally:
        conn.close()

    by_name: dict[str, list[str]] = {}
    for comp_nm, alias_nm in rows:
        aliases = by_name.setdefault(comp_nm, [])
        if alias_nm and alias_nm != comp_nm and alias_nm not in aliases:
            aliases.append(alias_nm)

    if len(by_name) < 90:  # 시드 하한(load.py _MIN_COMPANIES)과 동일 감각의 안전선
        print(f"[export] 거부 — 회사 {len(by_name)}개(<90). 서빙 DB 가 맞는지 확인하라.")
        return 2

    lines = [
        '"""db/seed/legacy200/seed200.py — 별칭 승계 소스 동봉본 (자동 생성 — 손으로 고치지 마라).',
        "",
        f"생성: export_from_db.py, {date.today().isoformat()}, 서빙 DB(TCOMPANY+TCOMPANY_ALIAS) 도출.",
        "원 소스(job_change 200-seed 4파일)는 은퇴 — 파이프라인 소비 필드(name·aliases)만 보존한다.",
        '별칭 추가·수정은 이 파일이 아니라 override(company_meta.py) 또는 DB 갱신 후 재도출로 한다."""',
        "",
        "SEED200 = [",
    ]
    for name in sorted(by_name):
        lines.append(f"    {{'name': {name!r}, 'aliases': {by_name[name]!r}}},")
    lines += ["]", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    n_alias = sum(len(v) for v in by_name.values())
    print(f"[export] OK — {OUT} (회사 {len(by_name)} · 별칭 {n_alias})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
