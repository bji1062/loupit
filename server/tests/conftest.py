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


# ═══════════════════════════════════════════════════════════════════════
# SP-API-14.1 — API 계약 테스트 픽스처 (무 DB, monkeypatch 캔드 데이터)
#
# 위 SP-DB/SP-SEED 픽스처(db_conn·schema_db·clean_tx·seeded_db)와는 완전히
# 독립적이다 — API 테스트는 실 MySQL을 전혀 쓰지 않고 server.database의
# fetch_all/fetch_one을 canned 함수로 monkeypatch해 검증한다(SP-API §14).
# ═══════════════════════════════════════════════════════════════════════

import httpx  # noqa: E402
import pytest_asyncio  # noqa: E402


# ── 캔드 데이터: 회사 상세(comp_id=1) ────────────────────────────────────
_DETAIL_COMPANY_ROW = {
    "comp_id": 1,
    "comp_eng_nm": "testco",
    "comp_nm": "테스트기업",
    "comp_tp_cd": "large",
    "industry_nm": "IT",
    "logo_nm": "T",
    "work_style_val": '{"remote": true, "flex": false}',
    "careers_benefit_url": "https://testco.example/careers",
}
_DETAIL_ALIAS_ROWS = [{"alias_nm": "테스트기업"}, {"alias_nm": "testco"}]
_DETAIL_BENEFIT_ROWS = [
    {
        "benefit_cd": "meal",
        "benefit_nm": "식대",
        "benefit_amt": 220,
        "benefit_ctgr_cd": "compensation",
        "badge_cd": "official",
        "amt_source": "stated",
        "qual_yn": 0,
        "qual_desc_ctnt": None,
        "note_ctnt": None,
        "verified_dtm": None,
        "expires_dtm": None,
        "badge_src_cd": "scrape_official",
        "badge_src_url_ctnt": "https://testco.example/careers",
        "sort_order_no": 1,
    },
]

# ── 캔드 데이터: 검색 풀 (이름/별칭 부분일치 대상) ───────────────────────
_SEARCH_POOL = [
    {
        "comp_id": 1,
        "comp_nm": "테스트기업",
        "comp_tp_cd": "large",
        "industry_nm": "IT",
        "logo_nm": "T",
        "_aliases": ["테스트기업", "testco"],
    },
    {
        "comp_id": 3,
        "comp_nm": "삼성전자",
        "comp_tp_cd": "large",
        "industry_nm": "전자",
        "logo_nm": "S",
        "_aliases": ["삼성", "samsung"],
    },
] + [
    {
        "comp_id": 100 + i,
        "comp_nm": f"매치회사{i}",
        "comp_tp_cd": "mid",
        "industry_nm": "제조",
        "logo_nm": "M",
        "_aliases": [],
    }
    for i in range(30)  # TSE-5: LIMIT 20 상한 검증용 30건 풀
]


def _unescape_like(term: str) -> str:
    """companies.py `_like_escape` + `%...%` 래핑의 역변환(테스트 매칭용)."""
    term = term.strip("%")
    out: list[str] = []
    i = 0
    while i < len(term):
        if term[i] == "!" and i + 1 < len(term):
            out.append(term[i + 1])
            i += 2
        else:
            out.append(term[i])
            i += 1
    return "".join(out)


@pytest.fixture
def fake_data(monkeypatch):
    """`database.fetch_all`/`fetch_one`을 SQL 텍스트 패턴 분기로 캔드 행 반환하도록 patch.

    회사 검색(search)·상세(companies/{id}) 라우터가 사용하는 두 헬퍼만
    대상으로 한다 — build_reference_bundle은 conn.cursor()를 직접 쓰므로
    무관(빌더 유닛 테스트는 test_reference.py가 fake conn으로 별도 검증).
    """
    from server import database

    async def _fetch_all(sql: str, params: tuple = ()):
        if "LEFT JOIN TCOMPANY_ALIAS" in sql and "LIKE %s ESCAPE" in sql:
            # companies/search — params = (like, like, prefix)
            term = _unescape_like(params[0]) if params else ""
            if not term:
                return []
            matched = [
                {k: v for k, v in row.items() if k != "_aliases"}
                for row in _SEARCH_POOL
                if term in row["comp_nm"] or any(term in a for a in row["_aliases"])
            ]
            return matched[:20]  # 실 SQL의 LIMIT 20 에뮬레이션
        if "FROM TCOMPANY_ALIAS WHERE COMP_ID = %s" in sql:
            comp_id = params[0] if params else None
            return list(_DETAIL_ALIAS_ROWS) if comp_id == 1 else []
        if "FROM TCOMPANY_BENEFIT WHERE COMP_ID = %s" in sql:
            comp_id = params[0] if params else None
            return [dict(r) for r in _DETAIL_BENEFIT_ROWS] if comp_id == 1 else []
        raise AssertionError(f"fake_data: 매칭되지 않은 fetch_all SQL: {sql!r}")

    async def _fetch_one(sql: str, params: tuple = ()):
        if "WHERE c.COMP_ID = %s" in sql:
            comp_id = params[0] if params else None
            return dict(_DETAIL_COMPANY_ROW) if comp_id == 1 else None
        raise AssertionError(f"fake_data: 매칭되지 않은 fetch_one SQL: {sql!r}")

    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    monkeypatch.setattr(database, "fetch_one", _fetch_one)
    return {"detail": _DETAIL_COMPANY_ROW, "search_pool": _SEARCH_POOL}


@pytest_asyncio.fixture
async def client(fake_data, monkeypatch):
    """ASGITransport 기반 httpx 클라이언트 — 러닝 서버·실 DB 불필요.

    lifespan은 ASGITransport에서 자동 실행되지 않으므로(SP-API-14.1 참고),
    풀 초기화 없이 `app.state.reference_cache`만 직접 채워 캐시 경로를
    검증 가능하게 한다. `init_pool`/`close_pool`도 방어적으로 no-op patch.
    """
    from server import database
    from server.cache import TTLCache
    from server.config import get_settings
    from server.main import create_app

    async def _noop_init_pool():
        return None

    async def _noop_close_pool():
        return None

    monkeypatch.setattr(database, "init_pool", _noop_init_pool)
    monkeypatch.setattr(database, "close_pool", _noop_close_pool)

    app = create_app()
    app.state.reference_cache = TTLCache(get_settings().reference_cache_ttl)

    # raise_app_exceptions=False: Starlette의 ServerErrorMiddleware는 등록된
    # Exception 핸들러로 500 응답을 보낸 뒤에도 원 예외를 다시 raise한다(ASGI
    # 서버 로그용 설계). 기본값(True)이면 httpx가 그 재raise를 테스트까지
    # 전파해 "핸들러가 응답을 보냈는데도 테스트가 예외로 실패"하는 상황이
    # 된다. TE-1(전역 예외 핸들러) 검증을 위해 False로 응답만 관찰한다.
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:
        c.app = app  # type: ignore[attr-defined]  # TR-6: 테스트에서 app.state 직접 조작용
        yield c


@pytest.fixture
def bundle_stub(monkeypatch):
    """`reference/all`이 소비하는 `get_pool`·`build_reference_bundle`을 캔드로 대체.

    reference/all은 conn을 얻어 build_reference_bundle(conn)을 호출하므로,
    풀 없이 검증하려면 get_pool()도 무해한 더미로 막아야 한다(SP-API-14.1
    "풀 없이 reference/all·companies/{id} 검증용" 헬퍼).
    호출횟수 카운터(calls)로 TR-5(캐시 히트)·TR-6(TTL 만료 재조립)를 검증한다.
    """
    from server.routers import reference as reference_router

    canned_bundle = {
        "company_types": [
            {
                "comp_tp_id": 1,
                "comp_tp_cd": "large",
                "comp_tp_nm": "대기업",
                "growth_rate_val": 0.04,
                "growth_label_nm": "대기업 평균 4%",
                "stability_score_no": 90,
            },
        ],
        "benefit_presets": {
            "large": [
                {
                    "benefit_cd": "meal",
                    "benefit_nm": "식대",
                    "benefit_amt": 200,
                    "benefit_ctgr_cd": "compensation",
                    "badge_cd": "est",
                    "default_checked_yn": True,
                    "sort_order_no": 1,
                },
            ],
        },
        "companies": [
            {
                "comp_id": 1,
                "comp_eng_nm": "testco",
                "comp_nm": "테스트기업",
                "comp_tp_cd": "large",
                "industry_nm": "IT",
                "logo_nm": "T",
                "work_style_val": {"remote": True, "flex": False},
                "careers_benefit_url": "https://testco.example/careers",
                "aliases": ["테스트기업", "testco"],
                "benefits": [
                    {
                        "benefit_cd": "meal",
                        "benefit_nm": "식대",
                        "benefit_amt": 220,
                        "benefit_ctgr_cd": "compensation",
                        "badge_cd": "official",
                        "amt_source": "stated",
                        "qual_yn": False,
                        "qual_desc_ctnt": None,
                        "note_ctnt": None,
                        "verified_dtm": None,
                        "expires_dtm": None,
                        "badge_src_cd": "scrape_official",
                        "badge_src_url_ctnt": "https://testco.example/careers",
                        "sort_order_no": 1,
                    },
                ],
            },
        ],
    }

    state = {"calls": 0}

    class _FakePoolCtx:
        async def __aenter__(self):
            return object()  # build_reference_bundle이 monkeypatch되어 conn 미사용

        async def __aexit__(self, *exc):
            return False

    class _FakePool:
        def acquire(self):
            return _FakePoolCtx()

    async def _fake_build_reference_bundle(conn):
        state["calls"] += 1
        return {
            "company_types": [dict(t) for t in canned_bundle["company_types"]],
            "benefit_presets": {k: [dict(p) for p in v] for k, v in canned_bundle["benefit_presets"].items()},
            "companies": [dict(c) for c in canned_bundle["companies"]],
        }

    # `reference_router`(소비 모듈)에 바인딩된 이름을 직접 patch한다 — reference.py가
    # `from server.database import get_pool` / `from server.services.reference import
    # build_reference_bundle`로 import했으므로, 원본 모듈(server.database 등)이 아니라
    # 이미 바인딩된 이 로컬 이름을 patch해야 실제 호출 시점에 반영된다.
    monkeypatch.setattr(reference_router, "get_pool", lambda: _FakePool())
    monkeypatch.setattr(reference_router, "build_reference_bundle", _fake_build_reference_bundle)

    return state
