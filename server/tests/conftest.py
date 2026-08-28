"""SP-DB-16 테스트 픽스처 — LOUPIT MySQL 스키마 격리·DDL 적용 오케스트레이션.

근거: SPEC/02 SP-DB-16(테스트 명세) · TASK/02 T-02.1.1·T-02.1.2.
접속 정보는 server/.env 에서만 읽는다 — 비밀번호를 화면/로그/코드에 하드코딩하지
않는다(os.environ 경유).

**스키마 재사용 + 복원(C-1 수정, 2026-07-12):** 이 서버는 LOUPIT 스키마를 테스트에도
재사용한다(APP_LOUPIT 이 별도 DB 생성권한이 없음). 테스트는 5개 참조 테이블을
DROP/CREATE 하므로, **서빙 스키마 대상 테스트는 run_tests.sh 경유로만 허용**한다 —
run_tests.sh 는 테스트 종료 후 load.py 로 서빙 데이터를 자동 복원(trap)하고
LOUPIT_ALLOW_SERVING_SCHEMA=1 로 이를 신호한다. pytest_configure 의 assert_test_target
가드는 이 신호가 없는 맨 `pytest` 직접 실행(복원 보장 없음)을 차단해, run_tests.sh 가
서빙을 비운 채 복원하지 않던 2026-07-11 C-1 회귀를 막는다.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pymysql
import pytest
from dotenv import load_dotenv

from server.tests.schema_guard import ServingSchemaError, assert_test_target

# server/tests/conftest.py → parents[2] = 리포 루트(/home/ubuntu/loupit)
ROOT = Path(__file__).resolve().parents[2]
SCHEMA_SQL = ROOT / "db" / "schema.sql"
MIGRATIONS_DIR = ROOT / "db" / "migrations"
SEED_DIR = ROOT / "db" / "seed"
REFERENCE_SQL = SEED_DIR / "reference.sql"
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"

load_dotenv(ROOT / "server" / ".env")

# M9 게이트(2026-07-27): 참여 라우터 등록·세션 퍼지·정책 문안은 `M9_ENABLED`(기본 OFF)가
# 지배한다. 테스트 하네스는 **ON 을 기본**으로 잡는다 — 베이스 게이트의 표면 계약
# (test_surface TS-1)이 참여 라우트를 포함한 M9 표면이기 때문이다. OFF 경로는 test_m9_gate 가
# monkeypatch 로 따로 검증한다. `setdefault` 라 CLI 에서 `M9_ENABLED=0` 으로 덮어쓸 수 있다.
# prod `server/.env` 에는 이 키를 넣지 않는다(부재=OFF) — 위 load_dotenv 가 그 파일을 읽으므로
# 키를 넣는 순간 프로덕션까지 켜진다.
os.environ.setdefault("M9_ENABLED", "1")

# 테스트는 **절대** 실제 메일을 보내지 않는다(적대검토 2026-07-27 blocker).
# `test_csrf.py::test_AC1_with_csrf_header_passes_gate` 는 CSRF 헤더를 붙여 /members/login-code 를
# 호출하고 204 를 검증한다 — 즉 핸들러가 끝까지 실행돼 메일러에 도달한다. 운영 서버의
# `server/.env` 에 `MAILER_MODE=smtp` 가 들어간 뒤 릴리스 게이트(run_tests.sh)를 돌리면
# **운영 Resend 계정으로 진짜 메일이 나간다**(무료 티어 일 100통 소모·도메인 평판 손상·수신자는
# 테스트용 가짜 주소라 하드바운스).
# conftest 가 load_dotenv 로 server/.env 를 읽으므로 이 위험은 실재한다 → 여기서 강제로 console 로
# 고정한다. `setdefault` 가 아니라 **덮어쓰기**여야 한다(.env 값을 이겨야 하므로).
os.environ["MAILER_MODE"] = "console"


def pytest_configure(config):
    """세션 시작 즉시 테스트 대상 DB_NAME 이 안전한지 검증(C-1 안전장치).

    서빙 스키마(LOUPIT) 대상 테스트는 복원을 보장하는 run_tests.sh 경유(환경변수
    LOUPIT_ALLOW_SERVING_SCHEMA=1)로만 허용한다. 이 신호가 없는 맨 `pytest` 직접 실행은
    schema_db 픽스처의 DROP TABLE 이 서빙 데이터를 복원 없이 비우므로 여기서 중단한다 —
    2026-07-11 C-1 회귀 차단."""
    # SC14 마커 등록(③ RED 스테이징): 미구현 SC14 스펙은 @pytest.mark.sc14 로 격리하고, 베이스
    # 릴리스 게이트는 run_tests.sh 의 `-m "not sc14"` 로 제외해 그린을 유지한다(M9 구현 후 활성).
    config.addinivalue_line(
        "markers",
        "sc14: SC14 참여(로그인·재직인증·복지편집) RED 스펙 — 구현(M9) 전 실패, 베이스 게이트 제외",
    )
    allow_serving = os.environ.get("LOUPIT_ALLOW_SERVING_SCHEMA") == "1"
    try:
        assert_test_target(os.environ.get("DB_NAME"), allow_serving=allow_serving)
    except ServingSchemaError as exc:
        pytest.exit(f"[C-1 안전장치] {exc}", returncode=3)
    _acquire_testdb_lock()


# ── 테스트 DB 상호 배제 락 (2026-07-30, restore-drill 신설과 함께) ──────────────────
# 주간 복원 훈련(`infra/deploy/restore-drill.sh`)이 같은 `loupit_test` 에 프로덕션 덤프를
# 복원했다가 지운다. 그 DB 계정은 `LOUPIT`·`loupit_beta`·`loupit_test` 세 곳에만 권한이 있고
# CREATE DATABASE 권한이 없어(2026-07-30 실측) 훈련 대상을 따로 만들 수 없기 때문이다.
#
# 겹치면 서로를 망가뜨린다 → 두 쪽이 **같은 파일**을 flock 한다. 락이 한쪽에만 있으면 락이
# 아니다. 여기서 잡지 않으면 훈련 쪽 `flock -n` 은 언제나 성공하고 상호 배제는 없는 것이다.
# 🚨 `/var/lock` 에 두지 마라. 이 커널은 `fs.protected_regular=2` 라 **끈적·전체쓰기
# 디렉터리(/run/lock, 1777)에서는 남이 소유한 파일을 열 수 없다** — root 도 마찬가지다.
# 훈련(User=ubuntu)이 만든 락을 root 로 돌린 pytest 가 못 열어 상호 배제가 조용히 사라졌다
# (2026-07-30 실발현). 모드 0666 으로도 안 된다 — 걸리는 것은 모드가 아니라 소유자 불일치다.
_TESTDB_LOCK_FILE = os.environ.get("DRILL_LOCK_FILE", "/run/loupit/testdb.lock")
_TESTDB_LOCK_WAIT_SEC = 180
_testdb_lock_fh = None  # 프로세스 수명 동안 열어 둔다(닫히면 락이 풀린다)


def _acquire_testdb_lock() -> None:
    """훈련과 겹치지 않게 테스트 DB 락을 잡는다. 잡을 수 없으면 **이유를 말하고** 중단한다.

    실패를 삼키지 않는 이유: 조용히 진행하면 훈련이 세션 도중 테이블을 드롭해 **원인을 알 수
    없는 무작위 실패**로 나타난다. 그건 진단에 몇 시간이 든다. 반대로 락을 아예 열 수 없는
    환경(`/run/loupit` 부재 등)은 훈련도 못 도는 환경이므로, 그때는 경고만 하고 진행한다
    — 없는 경쟁자를 이유로 테스트를 막으면 그게 더 나쁘다."""
    global _testdb_lock_fh
    import fcntl
    import time

    try:
        fh = open(_TESTDB_LOCK_FILE, "w")
    except OSError as exc:  # 락 파일을 못 연다 = 훈련도 못 돈다 → 경쟁자 없음
        print(f"[testdb-lock] 락 파일 사용 불가({exc}) — 상호 배제 없이 진행한다.")
        return

    deadline = time.monotonic() + _TESTDB_LOCK_WAIT_SEC
    while True:
        try:
            fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
            _testdb_lock_fh = fh  # 참조를 남겨 GC 로 닫히지 않게 한다
            return
        except BlockingIOError:
            if time.monotonic() >= deadline:
                fh.close()
                pytest.exit(
                    f"[testdb-lock] {_TESTDB_LOCK_FILE} 이 {_TESTDB_LOCK_WAIT_SEC}초째 잠겨 있다 — "
                    "복원 훈련(loupit-restore-drill.service)이 도는 중일 수 있다. "
                    "`systemctl status loupit-restore-drill` 로 확인하라.",
                    returncode=3,
                )
            time.sleep(1)


def pytest_unconfigure(config):
    """세션 종료 시 락을 명시적으로 놓는다.

    프로세스가 죽으면 커널이 어차피 flock 을 푼다 — 이건 정확성이 아니라 **위생**이다.
    안 닫으면 인터프리터 종료 때 `ResourceWarning: unclosed file` 이 매 실행마다 찍히고,
    그런 상시 경고는 진짜 경고를 묻는다."""
    global _testdb_lock_fh
    if _testdb_lock_fh is not None:
        _testdb_lock_fh.close()
        _testdb_lock_fh = None

# 생성 순서(FK 부모→자식, SP-DB-8). DROP은 이 역순(자식→부모)으로 수행한다.
# 역할분담(#1, 2026-07-18): 이 계층은 테스트 격리를 위해 TCOMPARE_LOG 를 계속 DROP/CREATE
# 한다(테스트가 이 테이블을 필요로 하고, 격리는 빈 상태에서 시작해야 한다). 서빙 로그의 실데이터
# 보호(게이트 실행마다 비워지는 것을 막는 백업/재주입)는 이 계층이 아니라 상위 래퍼
# infra/deploy/run_tests.sh 가 담당한다 — pytest 이전 mysqldump 백업 → 재시드 이후 재주입.
# 여기서 TCOMPARE_LOG 를 빼면 스키마가 미완성돼 테스트가 깨지므로, 드랍 목록에는 그대로 둔다.
_REFERENCE_CREATE_ORDER = [
    "TCOMPANY_TYPE",
    "TCOMPANY",
    "TCOMPANY_ALIAS",
    "TCOMPANY_BENEFIT",
    "TBENEFIT_PRESET",
    "TCOMPARE_LOG",  # 익명 비교 로그(INV-1 개정 2026-07-14) — FK→TCOMPANY라 자식 위치
]

# SP-DB-11 제거 테이블 15종(TMEMBER 는 SC14 로 SP-DB-17 이 신규 소유 → 제거목록에서 해제, ③ §C item1
# — SC-6(FK→REMOVED 0건) 통과에 필수: 참여 FK 가 TMEMBER 를 참조). TSOCIAL_ACCOUNT·TEMAIL_VERIFICATION
# 은 무소셜·무비밀번호로 영구 제거 유지. 격리 시 잔존분이 있다면 함께 정리(negative 보장).
REMOVED_TABLES = [
    "TSOCIAL_ACCOUNT", "TEMAIL_VERIFICATION",
    "TPROFILE", "TPROFILE_JOB_FIT", "TJOB_GROUP", "TJOB",
    "TPROFILER_QUESTION", "TQUESTION_SCENARIO", "TPROFILER_RESULT",
    "TCOMPARISON", "TCOMPARISON_FEED", "TDAILY_STAT", "TPOPULAR_CASE",
    "TBENEFIT_REPORT", "TCOMPANY_BENEFIT_BADGE_LOG",
]

# ── SC14 참여 7테이블 생성순서(FK 부모→자식, SP-DB-17) ─────────────────────────────────
# **T-13.2.2 편입 완료(2026-07-27)**: 이 위상은 아래에서 TABLE_CREATE_ORDER 에 병합된다.
#
# 구 주석은 "DDL 이 db/schema.sql 에 없어 schema_db 픽스처가 생성하지 못한다"며 inert 상수로
# 뒀는데, 그 전제는 SP-DB-17 DDL 이 schema.sql 에 들어오면서 **이미 거짓**이 됐다. 그 사이 이
# 목록만 죽은 채로 남아, 참여 테이블은 `apply_sql(schema.sql)` 로 **생성은 되고 DROP 목록엔 없어
# 영원히 안 지워지는** 상태였다 — 세션 간 행 잔존 + `TCOMPANY` 재생성으로 COMP_ID 가 재배정될 때
# 살아남은 이력 행이 다른 회사로 재해석되는 #15 동형 결함(test_schema_isolation SI-1·SI-2).
#
# 서빙 스키마의 실데이터 보호는 이 계층이 아니라 run_tests.sh ④(참여 7테이블 mysqldump 백업 →
# 재시드 후 재주입)가 담당한다 — TCOMPARE_LOG 와 완전히 같은 역할분담(#1)이다.
PARTICIPATION_CREATE_ORDER = [
    "TMEMBER", "TCOMPANY_EMAIL_DOMAIN", "TSESSION", "TAUTH_CODE",
    "TEMPLOY_VERIFICATION", "TEMPLOY_VRF_REQUEST",
    # 회사 등록 요청 큐(2026-07-29). FK 부모는 TMEMBER 하나뿐이라 위치 제약이 느슨하지만,
    # 같은 '요청 큐' 성격인 TEMPLOY_VRF_REQUEST 옆에 둔다. ⚠ TCOMPANY FK 가 **없다** —
    # 아직 존재하지 않는 회사를 요청하는 창구라서다(db/schema.sql 의 해당 절 참조).
    "TCOMPANY_REQUEST",
    "TBENEFIT_EDIT_LOG",
    # ── SC15 커뮤니티 4테이블(SP-DB-18, 2026-08-27) — 참여 그룹 **끝**에 부모→자식 순서로 ──
    # FK 위상: TPOST(TMEMBER·TCOMPANY) → TPOST_COMMENT(TPOST·TMEMBER) → TPOST_REACTION(TPOST·TMEMBER)
    # → TPOST_REPORT(TMEMBER). 부모가 전부 이 목록 앞에 있으므로 SI-4 를 만족한다.
    # 참여 그룹에 두는 이유: 라우터 등록이 `m9_enabled` 안에 있고(FR-120 전제 6) FK 가 TMEMBER 라
    # M9 OFF 스키마에는 이 4테이블도 없다 — 표면과 스키마가 설정 하나로 함께 움직인다.
    # `run_tests.sh` 는 격리 전환(2026-08-26) 후 백업 목록이 없으므로 동반 수정 불요.
    "TPOST", "TPOST_COMMENT", "TPOST_REACTION", "TPOST_REPORT",
]

# ── 메일 배달 결과 2테이블(SP-AUTH-16, P1-4 바운스 웹훅) ────────────────────────────
# 참여 7테이블과 **별도 그룹**인 이유: FK 가 하나도 없고 M9 스위치와 무관하게 존재한다
# (M9 OFF 인 프로덕션도 웹훅을 받아 억제 목록을 쌓는다 — db/schema.sql 의 해당 절 참조).
# FK 가 없으므로 생성 순서 제약도 없다 → 목록 맨 뒤에 둔다(SI-4 는 FK 부모만 본다).
#
# ⚠ **여기 넣는 것만으로는 부족하다**: 게이트가 서빙 스키마를 DROP/CREATE 하므로
# `infra/deploy/run_tests.sh` 의 백업/재주입 목록에도 반드시 함께 넣어야 한다. 안 그러면
# **릴리스마다 프로덕션 억제 목록이 소실**된다(TCOMPARE_LOG·참여 7테이블과 똑같은 위험).
#
# TMAIL_SEND_RATE(2026-07-30, P1-3 배달주소 백오프)도 같은 그룹이다 — FK 0개, M9 무관.
# 내용은 "이 수신함에 최근 몇 통" 이라는 억제 상태이고, 릴리스에서 날아가면 백오프가 통째로
# 되감겨 **릴리스가 곧 우회 수단**이 된다(퍼지 보존기간을 창보다 길게 잡은 것과 같은 이유).
MAIL_OPS_CREATE_ORDER = ["TMAIL_EVENT", "TMAIL_SUPPRESSION", "TMAIL_SEND_RATE"]

# ── DART 법인 데이터 4테이블(재무 2026-08-21 · 직원 2026-08-28) ──────────────────
# ⚠ 이름이 `CORP_FINANCE_...` 지만 **재무 전용이 아니다** — SPEC/17(SP-MET-4)이 직원 현황
# `TCORP_EMPLOY` 를 같은 법인 축에 얹으면서 이 그룹은 "DART 법인 데이터 전부"가 됐다.
# 상수 이름은 참조하는 코드가 있어 그대로 두고, 범위는 이 주석이 정의한다.
#
# 근거: docs/PLAN-회사정보-확장-2026-08-21.md · docs/SPEC/17-회사정보-지표.md.
# FK 위상: TCORP(무의존) → TCOMPANY_CORP(TCOMPANY·TCORP) → TCORP_FINANCE(TCORP)
# → TCORP_EMPLOY(TCORP). 넷 다 부모가 TCORP(그룹 선두)·TCOMPANY(_REFERENCE_CREATE_ORDER,
# 이 그룹보다 앞)뿐이라 그룹을 통째로 뒤에 붙이면 SI-4(부모→자식)를 만족한다.
#
# 🚨 **여기 넣지 않으면 그 테이블 구간에는 테스트가 없는 것과 같다.** schema.sql 로 생성만
# 되고 DROP 목록에 없어 세션 간 행이 남으며, TCORP 재생성 시 살아남은 행이 다른 법인으로
# 재해석된다 — 참여 7테이블이 실제로 겪은 #15 동형 결함이고, 이 저장소가 반복해서 당한 함정이다.
#
# ⚠ 서빙 스키마를 DROP/CREATE 하던 구 게이트에서는 `infra/deploy/run_tests.sh` 의 백업/재주입
# 목록에도 함께 넣어야 했다(2026-08-26 격리 전환으로 그 목록은 사라졌다 — 게이트는 이제
# loupit_test 만 만진다). 재무·직원은 재수집 가능한 파생 데이터지만, 수집에 API 호출 비용과
# 시간이 들고 무엇보다 **비면 회사 페이지의 실적·직원 섹션이 통째로 사라진다** — 그리고 그
# 소멸은 에러를 남기지 않는다(함정 (57)).
CORP_FINANCE_CREATE_ORDER = ["TCORP", "TCOMPANY_CORP", "TCORP_FINANCE", "TCORP_EMPLOY"]

# 활성 격리 사이클 = 참조 6 + 참여 7 + 메일 3 + DART 법인 4. 참여가 뒤에 오는 것이 FK 부모→자식
# 순서를 만족한다(TMEMBER 는 무의존, 나머지는 TCOMPANY·TCOMPANY_BENEFIT·TMEMBER 를 참조 — SI-4).
TABLE_CREATE_ORDER = (
    _REFERENCE_CREATE_ORDER
    + PARTICIPATION_CREATE_ORDER
    + MAIL_OPS_CREATE_ORDER
    + CORP_FINANCE_CREATE_ORDER
)
TABLE_DROP_ORDER = list(reversed(TABLE_CREATE_ORDER))


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

    # API 계약 테스트 hermetic — 개발용 server/.env(CORS_ALLOW_ORIGINS)와 무관하게
    # CORS 허용목록을 정본 기본값으로 고정한다(env var가 .env보다 우선, pydantic-settings).
    # TCORS-1·2가 정적 오리진(jobcho.wiki) echo·프리플라이트를 기대하므로 결정성 확보.
    monkeypatch.setenv("CORS_ALLOW_ORIGINS", "https://jobcho.wiki,https://www.jobcho.wiki")
    get_settings.cache_clear()

    app = create_app()
    app.state.reference_cache = TTLCache(get_settings().reference_cache_ttl)
    app.state.trending_cache = TTLCache(get_settings().trending_cache_ttl)  # 비교 트렌딩(lifespan 대응)

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
