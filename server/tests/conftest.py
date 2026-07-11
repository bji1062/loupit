"""SP-DB-16 테스트 픽스처 — LOUPIT MySQL 스키마 격리·DDL 적용 오케스트레이션.

근거: SPEC/02 SP-DB-16(테스트 명세) · TASK/02 T-02.1.1·T-02.1.2.
접속 정보는 server/.env(dotenv)에서만 읽는다 — 비밀번호를 화면/로그/코드에
하드코딩하지 않는다(os.environ 경유). 스키마명 LOUPIT는 비어있는 실 스키마이며
별도 loupit_test 권한이 없으므로, 이 스키마 안에서 5개 참조 테이블을
DROP/CREATE 하여 테스트 세션을 격리한다(TASK/00 §4 DG-4 확정 사항).
"""

from __future__ import annotations

import os
import sys
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


def _connect(autocommit: bool = True) -> pymysql.connections.Connection:
    """LOUPIT 커넥션. 기본 autocommit=True — 읽기 테스트가 열린 트랜잭션으로
    메타데이터 락(MDL)을 쥔 채 남아 `load.main()`의 DDL(DROP TABLE)을 무기한
    막지 않도록 한다. SM 멱등성 테스트가 세션 커넥션으로 조회한 뒤 재시드
    DDL을 호출하므로, autocommit=False면 조회 트랜잭션의 MDL에 DROP이 걸려
    행(hang)한다. 제약(CN) 테스트만 롤백 격리가 필요하므로 autocommit=False
    전용 커넥션(clean_tx)을 따로 쓴다."""
    conn = pymysql.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        autocommit=autocommit,
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
    """LOUPIT 스키마 pymysql 커넥션 (세션 범위, autocommit=True) — SC-1 로드 전제 하네스.

    autocommit=True라 조회가 MDL을 붙든 채 남지 않아, SM 테스트의 재시드 DDL이
    이 세션 커넥션 때문에 막히지 않는다."""
    conn = _connect(autocommit=True)
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
    """CN-* 제약 테스트 격리 — autocommit=False **전용 커넥션**에서 삽입/삭제를
    커밋하지 말고, 종료 후 롤백·종료해 다음 테스트에 영향이 없게 한다.

    세션 `db_conn`은 autocommit=True(위 사유)이므로 트랜잭션 롤백 격리가
    필요한 CN은 이 전용 커넥션을 쓴다. `schema_db` 의존은 스키마 적용 보장용.
    함수 스코프라 매 테스트 종료 시 커넥션을 닫아 MDL 잔존이 없다."""
    conn = _connect(autocommit=False)
    try:
        yield conn
    finally:
        try:
            conn.rollback()
        finally:
            conn.close()


@pytest.fixture(scope="session")
def seeded_db(schema_db):
    """schema 적용 뒤 `load.main(fresh=True)`로 시드+백필 전체 적용(T-03.1.1).

    SP-SEED 완료로 db/seed/(company_types.sql·benefit_presets.sql·
    benefit/sql/*.sql·load.py)가 갖춰졌으므로, 본 픽스처는 순수 SQL
    수동 적용 대신 로더 엔트리포인트 `load.main(fresh=True)`를 호출해
    스키마 재생성부터 DEC-2 백필까지 전체 파이프라인(프로버넌스 정밀
    판본, backfill_dec2.py)을 실행한다. `schema_db` 의존은 픽스처 순서
    보장용이며, 실제 적재는 load.main이 자체 커넥션으로 수행한다.
    """
    conn = schema_db  # 픽스처 순서 보장용 — 조회는 이 커넥션으로, 적재는 load.main 자체 커넥션
    if str(SEED_DIR) not in sys.path:
        sys.path.insert(0, str(SEED_DIR))
    import load as seed_load  # type: ignore  # db/seed/load.py (경로 기반 sibling import)

    seed_load.main(fresh=True)
    yield conn


@pytest.fixture
def db_name() -> str:
    """대상 스키마명(LOUPIT) — information_schema 질의에 사용."""
    return os.environ["DB_NAME"]
