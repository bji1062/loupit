"""회사 재무(DART) 스키마 계약 — CF-1~CF-9.

근거: `docs/PLAN-회사정보-확장-2026-08-21.md` §3·§5-1·§5-2.

**이 테스트가 지키는 것은 컬럼 목록이 아니라 설계 결정 4가지다.** 전부 2026-08-21 에
실측으로 확인된 것이고, 어기면 화면에 틀린 숫자가 나간다:

  1. **법인:페이지는 1:N** — `CJ ENM 엔터테인먼트부문` 과 `커머스부문` 이 **같은 corp_code
     00265324** 를 가리킨다(실측). 회사당 법인은 하나지만, 한 법인을 여러 페이지가 가리킨다.
  2. **재무는 법인 단위로 저장한다** — `TCORP_FINANCE` 에 `COMP_ID` 가 있으면 위 두 페이지가
     같은 수치를 **두 벌** 갖게 되고, 한쪽만 갱신되는 순간 조용히 갈라진다.
  3. **연결/별도 기준은 숨길 수 없다** — LG 연결 영업이익 9,122억 vs 별도 5,971억(실측).
     기준을 안 적으면 어느 쪽이든 부정확한 주장이 된다 → `FS_DIV_CD` NOT NULL.
  4. **지표는 `account_id` 로 식별한다** — `account_nm` 은 회사마다 다르다. 실제로
     SK하이닉스는 손익을 `IS` 가 아니라 `CIS` 에 싣고, 삼성생명은 `ifrs-full_Revenue`·
     `dart_OperatingIncomeLoss` 가 아예 없다(금융업). 이름으로 뽑으면 **에러 없이 그 회사만 빈다.**

무DB 계약(CF-1~5)은 schema.sql 텍스트만 본다. CF-6~9 는 `clean_tx` 로 실제 DDL 동작을 본다.
"""
from __future__ import annotations

import re

import pymysql
import pytest

from server.tests.conftest import SCHEMA_SQL, TABLE_CREATE_ORDER

CORP_TABLES = ["TCORP", "TCOMPANY_CORP", "TCORP_FINANCE"]


def _schema_text() -> str:
    return SCHEMA_SQL.read_text(encoding="utf-8")


def _table_block(name: str) -> str:
    """해당 CREATE TABLE 블록만 잘라낸다(다음 CREATE TABLE 직전까지)."""
    text = _schema_text()
    m = re.search(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{name}\b(.*?)(?=CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+T|\Z)",
        text,
        re.IGNORECASE | re.DOTALL,
    )
    assert m, f"{name} DDL 이 db/schema.sql 에 없다"
    return m.group(1)


# ── 무DB 계약 ────────────────────────────────────────────────────────────────

def test_CF1_corp_tables_exist_in_schema():
    """세 테이블이 schema.sql 에 정의돼 있다."""
    text = _schema_text()
    missing = [t for t in CORP_TABLES if not re.search(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{t}\b", text, re.IGNORECASE)]
    assert not missing, f"schema.sql 에 없는 재무 테이블: {missing}"


def test_CF2_corp_tables_in_isolation_cycle():
    """SI-1 과 같은 계약 — 격리 사이클에 편입돼 있어야 세션 간 행이 안 남는다."""
    missing = [t for t in CORP_TABLES if t not in TABLE_CREATE_ORDER]
    assert not missing, (
        f"재무 테이블이 TABLE_CREATE_ORDER 에 미편입: {missing} — "
        "conftest 에 넣지 않으면 생성만 되고 영원히 안 지워진다(참여 7테이블이 겪은 결함)"
    )


def test_CF3_finance_is_stored_per_corporation_not_per_page():
    """🚨 `TCORP_FINANCE` 에 COMP_ID 가 있으면 안 된다 — 재무는 **법인 단위**다.

    CJ ENM 2페이지가 같은 법인을 가리키므로(실측), 페이지 단위로 저장하면 같은 수치가
    두 벌이 되고 한쪽만 갱신되는 순간 두 페이지가 다른 실적을 보여준다."""
    block = _table_block("TCORP_FINANCE")
    assert not re.search(r"\bCOMP_ID\b", block, re.IGNORECASE), (
        "TCORP_FINANCE 에 COMP_ID 가 있다 — 재무는 법인(CORP_CODE) 단위로 저장해야 한다. "
        "페이지 단위 저장은 CJ ENM 2페이지에서 수치를 갈라지게 만든다"
    )
    assert re.search(r"\bCORP_CODE\b", block, re.IGNORECASE), "TCORP_FINANCE 에 CORP_CODE 가 없다"


def test_CF4_fs_div_is_not_nullable():
    """🚨 연결/별도 기준은 NOT NULL — 기준 없는 수치는 부정확한 주장이다(LG 9,122 vs 5,971억)."""
    block = _table_block("TCORP_FINANCE")
    m = re.search(r"FS_DIV_CD\s+\S+\s+NOT\s+NULL", block, re.IGNORECASE)
    assert m, "TCORP_FINANCE.FS_DIV_CD 가 NOT NULL 이 아니다 — 연결/별도를 숨기면 안 된다"


def test_CF5_metric_identified_by_account_id():
    """지표 식별자는 `ACCT_ID`(표준계정 ID)다 — account_nm 은 회사마다 다르다."""
    block = _table_block("TCORP_FINANCE")
    assert re.search(r"\bACCT_ID\b", block, re.IGNORECASE), (
        "TCORP_FINANCE 에 ACCT_ID 가 없다 — 계정명(account_nm)으로 뽑으면 "
        "SK하이닉스(CIS 수록)·삼성생명(금융 계정체계)에서 조용히 빈다"
    )


def test_CF10_migration_matches_schema():
    """🚨 마이그레이션과 schema.sql 의 DDL 이 갈라지면 안 된다.

    schema.sql 은 **신규 프로비저닝**, 마이그레이션은 **기존 서빙 DB** 를 담당한다. 한쪽만
    고치면 두 환경이 조용히 다른 스키마가 되고, 그 차이는 테이블이 만들어진 시점에 따라
    달라져서 재현이 어렵다. 정본은 schema.sql 이고 이 테스트가 사본의 드리프트를 막는다."""
    from pathlib import Path

    mig = Path(SCHEMA_SQL).parent / "migrations" / "20260821_add_corp_finance.sql"
    assert mig.is_file(), f"마이그레이션 파일 부재: {mig}"
    mig_text = mig.read_text(encoding="utf-8")

    def block(text: str, name: str) -> str:
        m = re.search(
            rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{name}\s*\((.*?)\n\)\s*ENGINE",
            text, re.IGNORECASE | re.DOTALL,
        )
        assert m, f"{name} DDL 을 찾을 수 없다"
        return re.sub(r"\s+", " ", m.group(1)).strip()

    drifted = [t for t in CORP_TABLES if block(_schema_text(), t) != block(mig_text, t)]
    assert not drifted, (
        f"schema.sql 과 마이그레이션의 DDL 이 다르다: {drifted} — "
        "정본은 db/schema.sql 이다. 한쪽만 고치면 신규 환경과 기존 서빙이 갈라진다"
    )


# ── DB 동작 계약 ─────────────────────────────────────────────────────────────

def _mk_corp(conn, corp_code="00265324", nm="씨제이이엔엠", stock="035760", acct="general"):
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCORP (CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD) "
            "VALUES (%s, %s, %s, %s, 'CFS')",
            (corp_code, nm, stock, acct),
        )
    return corp_code


def _mk_type(conn, cd="large"):
    """기업유형은 회사마다 새로 만들 필요가 없다 — 한 번 만들어 재사용한다.

    (초판은 회사명 앞 6자로 코드를 만들었는데 `cj_enm_ent`/`cj_enm_com` 이 둘 다 `tcj_enm` 이
    되어 COMP_TP_CD UNIQUE 에 걸렸다. 테스트가 스키마가 아니라 자기 헬퍼 때문에 실패했다.)"""
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES (%s, %s)",
                    (cd, "대기업"))
        return cur.lastrowid


def _mk_company(conn, eng, nm, comp_tp_id=None):
    if comp_tp_id is None:
        comp_tp_id = _mk_type(conn, cd=f"tp_{eng}"[:20])
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID) VALUES (%s, %s, %s)",
                    (eng, nm, comp_tp_id))
        return cur.lastrowid


def test_CF6_one_corporation_can_back_multiple_pages(clean_tx):
    """★ 1:N — CJ ENM 두 부문이 **같은 corp_code** 를 가리킬 수 있어야 한다(실측 재현)."""
    conn = clean_tx
    corp = _mk_corp(conn)
    tp = _mk_type(conn)
    a = _mk_company(conn, "cj_enm_ent", "CJ ENM 엔터테인먼트부문", tp)
    b = _mk_company(conn, "cj_enm_com", "CJ ENM 커머스부문", tp)
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD) VALUES (%s,%s,'manual')", (a, corp))
        cur.execute("INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD) VALUES (%s,%s,'manual')", (b, corp))
        cur.execute("SELECT COUNT(*) FROM TCOMPANY_CORP WHERE CORP_CODE=%s", (corp,))
        assert cur.fetchone()[0] == 2, "한 법인을 두 페이지가 가리킬 수 없다 — CORP_CODE 에 UNIQUE 가 걸려 있다"


def test_CF7_company_maps_to_at_most_one_corporation(clean_tx):
    """역방향은 1 — 회사 하나가 법인 둘을 가리키면 어느 실적인지 정해지지 않는다."""
    conn = clean_tx
    c1 = _mk_corp(conn, "00265324", "씨제이이엔엠", "035760")
    c2 = _mk_corp(conn, "00126380", "삼성전자", "005930")
    a = _mk_company(conn, "dup_co", "중복회사")
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD) VALUES (%s,%s,'auto')", (a, c1))
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute("INSERT INTO TCOMPANY_CORP (COMP_ID, CORP_CODE, MATCH_CD) VALUES (%s,%s,'auto')", (a, c2))


def test_CF8_same_metric_cannot_be_stored_twice(clean_tx):
    """(법인, 연도, 기준, 계정) 은 유일 — 중복 수집이 같은 지표를 두 벌 만들면 안 된다."""
    conn = clean_tx
    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        sql = ("INSERT INTO TCORP_FINANCE (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, AMT_VAL) "
               "VALUES (%s, 2025, 'CFS', 'ifrs-full_Revenue', %s)")
        cur.execute(sql, (corp, 4_795_000_000_000))
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute(sql, (corp, 9_999_999_999_999))


def test_CF9_connected_and_separate_coexist(clean_tx):
    """같은 지표라도 연결/별도는 **서로 다른 행**이다 — LG 처럼 둘 다 존재할 수 있다."""
    conn = clean_tx
    corp = _mk_corp(conn, "00120021", "엘지", "003550")
    with conn.cursor() as cur:
        sql = ("INSERT INTO TCORP_FINANCE (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, AMT_VAL) "
               "VALUES (%s, 2025, %s, 'dart_OperatingIncomeLoss', %s)")
        cur.execute(sql, (corp, "CFS", 912_200_000_000))
        cur.execute(sql, (corp, "OFS", 597_100_000_000))
        cur.execute("SELECT COUNT(*) FROM TCORP_FINANCE WHERE CORP_CODE=%s", (corp,))
        assert cur.fetchone()[0] == 2
