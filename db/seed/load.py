"""SP-SEED-9 — 시드 오케스트레이터 (단일 엔트리포인트).

실행 순서(SP-SEED-3, 멱등): schema → company_types+benefit_presets →
95개 복지 SQL(회사 자기등록 포함) → company_meta 적용(별칭·근무형태) → DEC-2 백필.

CLI: `python3 db/seed/load.py [--fresh]`
  --fresh : DROP(FK 역순)+CREATE 후 전체 재시드(테스트/클린 재빌드)
  (기본)  : 멱등 재적용(운영 재시드) — schema.sql은 idempotent(CREATE TABLE IF NOT EXISTS)

접속 정보는 server/.env(dotenv)에서만 읽는다 — 비밀번호를 화면/로그/코드에
하드코딩하지 않는다(os.environ 경유).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pymysql
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_SQL = ROOT / "db" / "schema.sql"
SEED_DIR = Path(__file__).resolve().parent
COMPANY_TYPES_SQL = SEED_DIR / "company_types.sql"
BENEFIT_PRESETS_SQL = SEED_DIR / "benefit_presets.sql"
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"

# 생성 순서(FK 부모→자식, SP-DB-8). DROP은 이 역순으로 수행한다.
TABLE_CREATE_ORDER = ["TCOMPANY_TYPE", "TCOMPANY", "TCOMPANY_ALIAS", "TCOMPANY_BENEFIT", "TBENEFIT_PRESET"]
TABLE_DROP_ORDER = list(reversed(TABLE_CREATE_ORDER))

if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))


def _split_sql_statements(sql_text: str) -> list[str]:
    """세미콜론 기준 다중 문장 분할 — 문자열 리터럴 내부 ';'는 보호한다."""
    statements: list[str] = []
    buf: list[str] = []
    in_string: str | None = None
    for ch in sql_text:
        if in_string:
            buf.append(ch)
            if ch == in_string:
                in_string = None
            continue
        if ch in ("'", '"'):
            in_string = ch
            buf.append(ch)
            continue
        if ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
            continue
        buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


def run_sql_file(cur, path: os.PathLike) -> None:
    """SQL 파일을 읽어 다중 문장을 순차 실행(`SET @var` 세션은 동일 커서에서 유지)."""
    text = Path(path).read_text(encoding="utf-8")
    for stmt in _split_sql_statements(text):
        cur.execute(stmt)


def connect() -> pymysql.connections.Connection:
    """동기 pymysql 커넥션(aiomysql 아님, 시드는 동기 경로)."""
    load_dotenv(ROOT / "server" / ".env")
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        autocommit=False,
    )


def _drop_all_tables(cur) -> None:
    cur.execute("SET FOREIGN_KEY_CHECKS=0")
    for t in TABLE_DROP_ORDER:
        cur.execute(f"DROP TABLE IF EXISTS {t}")
    cur.execute("SET FOREIGN_KEY_CHECKS=1")


def verify_counts(stats: dict) -> None:
    """하한 assert(방어적 스모크) — 상세 검증은 pytest 스위트가 담당."""
    assert stats.get("promoted") is not None, "backfill 통계 누락(promoted)"


def main(fresh: bool = False) -> dict:
    """fresh=True: DROP+CREATE 후 전체 재시드. fresh=False: 멱등 재적용(기본)."""
    from backfill_dec2 import backfill
    from companies import apply_company_meta
    from company_meta import build_company_meta

    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            if fresh:
                _drop_all_tables(cur)
            run_sql_file(cur, SCHEMA_SQL)  # 1: schema (idempotent CREATE TABLE IF NOT EXISTS)
            run_sql_file(cur, COMPANY_TYPES_SQL)  # 2a: 기업유형 6종
            run_sql_file(cur, BENEFIT_PRESETS_SQL)  # 2b: 프리셋 28행(full-refresh)
            for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):  # 3: 95개 복지 SQL(회사 자기등록 포함)
                run_sql_file(cur, f)
            meta = build_company_meta()
            apply_company_meta(cur, meta)  # 4: 별칭·근무형태 보강
            stats = backfill(cur)  # 5: DEC-2 백필(official 승격·amt_source·출처·만료)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    verify_counts(stats)
    return stats


if __name__ == "__main__":
    fresh_flag = "--fresh" in sys.argv[1:]
    try:
        result_stats = main(fresh=fresh_flag)
    except Exception as exc:  # noqa: BLE001 — CLI 최종 경계, 비0 종료로 전파
        print(f"seed failed: {exc}", file=sys.stderr)
        sys.exit(1)
    print(f"seed done: {result_stats}")
