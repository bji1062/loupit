"""SP-DB-16 테스트 픽스처 — LOUPIT MySQL 스키마 격리·DDL 적용 오케스트레이션.

근거: SPEC/02 SP-DB-16(테스트 명세) · TASK/02 T-02.1.1·T-02.1.2.
접속 정보는 server/.env(dotenv)에서만 읽는다 — 비밀번호를 화면/로그/코드에
하드코딩하지 않는다(os.environ 경유). 스키마명 LOUPIT는 비어있는 실 스키마이며
별도 loupit_test 권한이 없으므로, 이 스키마 안에서 5개 참조 테이블을
DROP/CREATE 하여 테스트 세션을 격리한다(TASK/00 §4 DG-4 확정 사항).
"""

from __future__ import annotations

import os
from pathlib import Path

import pymysql
import pytest
from dotenv import load_dotenv

# server/tests/conftest.py → parents[2] = 리포 루트(/home/ubuntu/loupit)
ROOT = Path(__file__).resolve().parents[2]
SCHEMA_SQL = ROOT / "db" / "schema.sql"
MIGRATIONS_DIR = ROOT / "db" / "migrations"
SEED_DIR = ROOT / "db" / "seed"
REFERENCE_SQL = SEED_DIR / "reference.sql"
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"

load_dotenv(ROOT / "server" / ".env")

# 생성 순서(FK 부모→자식, SP-DB-8). DROP은 이 역순(자식→부모)으로 수행한다.
TABLE_CREATE_ORDER = [
    "TCOMPANY_TYPE",
    "TCOMPANY",
    "TCOMPANY_ALIAS",
    "TCOMPANY_BENEFIT",
    "TBENEFIT_PRESET",
]
TABLE_DROP_ORDER = list(reversed(TABLE_CREATE_ORDER))

# SP-DB-11 제거 테이블 16종 — 격리 시 잔존분이 있다면 함께 정리(negative 보장).
REMOVED_TABLES = [
    "TMEMBER", "TSOCIAL_ACCOUNT", "TEMAIL_VERIFICATION",
    "TPROFILE", "TPROFILE_JOB_FIT", "TJOB_GROUP", "TJOB",
    "TPROFILER_QUESTION", "TQUESTION_SCENARIO", "TPROFILER_RESULT",
    "TCOMPARISON", "TCOMPARISON_FEED", "TDAILY_STAT", "TPOPULAR_CASE",
    "TBENEFIT_REPORT", "TCOMPANY_BENEFIT_BADGE_LOG",
]


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


def apply_sql(conn: pymysql.connections.Connection, path: os.PathLike) -> None:
    """SQL 파일을 읽어 다중 문장을 순차 실행한다 (T-02.1.1 `apply_sql` 헬퍼)."""
    text = Path(path).read_text(encoding="utf-8")
    with conn.cursor() as cur:
        for stmt in _split_sql_statements(text):
            cur.execute(stmt)
    conn.commit()


def _connect() -> pymysql.connections.Connection:
    conn = pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        autocommit=False,
    )
    with conn.cursor() as cur:
        cur.execute("SET NAMES utf8mb4")
    return conn


def _drop_all_tables(conn: pymysql.connections.Connection) -> None:
    with conn.cursor() as cur:
        cur.execute("SET FOREIGN_KEY_CHECKS=0")
        for t in TABLE_DROP_ORDER + REMOVED_TABLES:
            cur.execute(f"DROP TABLE IF EXISTS {t}")
        cur.execute("SET FOREIGN_KEY_CHECKS=1")
    conn.commit()


@pytest.fixture(scope="session")
def db_conn():
    """LOUPIT 스키마 pymysql 커넥션 (세션 범위) — SC-1 로드 전제 하네스."""
    conn = _connect()
    yield conn
    conn.close()


@pytest.fixture(scope="session")
def schema_db(db_conn):
    """db/schema.sql 적용 픽스처 (T-02.1.2).

    테스트 세션 격리를 위해 5개 참조 테이블(+ 잔존 제거 테이블)을 먼저
    DROP한 뒤 schema.sql을 재적용한다. LOUPIT는 재사용 스키마이므로
    스키마 자체는 DROP하지 않고 테이블 단위로 재생성한다.
    """
    _drop_all_tables(db_conn)
    apply_sql(db_conn, SCHEMA_SQL)
    yield db_conn
    _drop_all_tables(db_conn)


@pytest.fixture
def clean_tx(schema_db):
    """CN-* 제약 테스트 격리 — 테스트 내 삽입/삭제를 커밋하지 말고,
    종료 후 롤백해 다음 테스트에 영향이 없게 한다."""
    conn = schema_db
    yield conn
    conn.rollback()


@pytest.fixture(scope="session")
def seeded_db(schema_db):
    """schema → reference.sql → benefit/sql/*.sql → migrations 순서 적용(SP-DB-10).

    reference.sql·benefit/sql/*.sql은 SP-SEED(다음 단계) 산출물이며 본
    픽스처는 **적용 오케스트레이션만** 담당한다(T-02.1.2). 아직 해당 파일이
    없으면 건너뛰고 schema만 적용된 상태로 진행 — DC-*(시드 후 값집합) 중
    데이터 존재를 요구하는 케이스는 SP-SEED 완료 전까지 skip 처리된다.
    """
    conn = schema_db
    if REFERENCE_SQL.exists():
        apply_sql(conn, REFERENCE_SQL)
    if BENEFIT_SQL_DIR.exists():
        for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):
            apply_sql(conn, f)
    if MIGRATIONS_DIR.exists():
        for f in sorted(MIGRATIONS_DIR.glob("*.sql")):
            apply_sql(conn, f)
    yield conn


@pytest.fixture
def db_name() -> str:
    """대상 스키마명(LOUPIT) — information_schema 질의에 사용."""
    return os.environ["DB_NAME"]
