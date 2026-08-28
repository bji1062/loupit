"""직원 현황(DART empSttus) 스키마 계약 — CE-1~CE-10.

근거: `docs/SPEC/17-회사정보-지표.md` SP-MET-4(스키마)·SP-MET-5(합계행)·SP-MET-6(급여 단위)·
SP-MET-7(근속 표기)·SP-MET-8(가중평균). 수치는 전부 2026-08-28 DART 전수 실측이다.

**이 테스트가 지키는 것은 컬럼 목록이 아니라 설계 결정 4가지다.** 어기면 화면에 틀린 숫자가
나가고, 넷 다 **에러 없이** 그렇게 된다:

  1. **직원도 법인 단위다** — 재무와 같은 이유. `TCORP_EMPLOY` 에 `COMP_ID` 가 있으면
     `CJ ENM 엔터테인먼트부문`·`커머스부문`(같은 corp_code 00265324, 실측)이 인원을 **두 벌**
     갖게 되고, 한쪽만 갱신되는 순간 두 페이지가 다른 직원수를 보여준다.
  2. **원문을 그대로 남긴다** — 근속 표기는 5종(`11.70`·`92개월`·`13년 6월`·`6년 4개월`·`-`)이고
     급여 단위는 **같은 회사가 해마다 바뀐다**(CJ ENM: 2018 원 → 2019 백만원 → 2020 원, 실측).
     정규화값만 저장하면 규칙이 틀렸을 때 되돌릴 근거가 없어 **전량 재수집**해야 한다.
     그래서 `RAW_TENURE_NM`·`RAW_SALARY_NM` 이 있다.
  3. **결측은 NULL 이고 0 이 아니다** — 파싱 실패·타당 범위 밖(SP-MET-6)을 0 으로 채우면
     "평균연봉 0원"이 사실인 것처럼 나가고, 가중평균의 분자에 섞여 회사 평균까지 끌어내린다.
     NOT NULL/DEFAULT 0 은 그 조용한 거짓을 스키마가 강제하는 것과 같다.
  4. **합계행 판정을 저장한다** — 7사가 부문행과 합계행을 함께 낸다. 전부 더하면 삼성전자가
     128,881 → 257,762 명이 된다(정확히 두 배). 판정을 집계 시점마다 문자열로 다시 하면
     규칙이 두 곳으로 갈라진다(배지 계보가 네 렌더러로 갈라졌던 것과 같은 종류) → `TOTAL_ROW_YN`.

무DB 계약(CE-1~4·CE-10)은 schema.sql 텍스트만 본다. CE-5~9 는 `clean_tx` 로 실제 DDL 동작을 본다.

⚠ **성별(`SEX_CD`)은 저장하되 화면에 내지 않는다**(사용자 결정 2026-08-28). 그 계약은 스키마가
아니라 렌더러의 몫이라 여기서 검사하지 않는다 — 생성물 검사(SP-MET-12)가 담당한다.
"""
from __future__ import annotations

import re
from pathlib import Path

import pymysql
import pytest

from server.tests.conftest import SCHEMA_SQL, TABLE_CREATE_ORDER

EMPLOY_TABLE = "TCORP_EMPLOY"

# 결측이 허용돼야 하는 컬럼 — 값이 없을 수 있고, 그때 0 이 아니라 NULL 이어야 한다.
NULLABLE_COLS = ["HEADCNT", "TENURE_YEAR", "AVG_SALARY_AMT",
                 "RAW_TENURE_NM", "RAW_SALARY_NM", "RCEPT_NO"]

# 결측이 허용되면 안 되는 컬럼 — 이게 비면 그 행이 **누구의 어느 해 무엇인지** 정해지지 않는다.
# (UNIQUE 키 4컬럼 + 합계행 판정. MySQL 은 UNIQUE 안의 NULL 을 서로 다르게 보므로,
#  NULL 을 허용하면 유일성 자체가 무너져 같은 부문이 여러 벌 쌓인다.)
NOT_NULL_COLS = ["CORP_CODE", "BSNS_YEAR", "SEGMENT_NM", "SEX_CD", "TOTAL_ROW_YN"]


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

def test_CE1_employ_table_exists_in_schema():
    """`TCORP_EMPLOY` 가 schema.sql 에 정의돼 있다(신규 프로비저닝의 정본)."""
    assert re.search(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{EMPLOY_TABLE}\b", _schema_text(), re.IGNORECASE
    ), "schema.sql 에 TCORP_EMPLOY DDL 이 없다"


def test_CE2_employ_table_in_isolation_cycle():
    """🚨 격리 사이클 편입 — 빠뜨리면 **이 구간에 테스트가 없는 것과 같다**(반복 함정).

    conftest 의 `CORP_FINANCE_CREATE_ORDER` 에 없으면 schema.sql 로 생성만 되고 DROP 목록엔
    없어, 세션 간 행이 남는다. 그 상태에서 `TCORP` 가 재생성되면 살아남은 직원 행이 다른
    법인으로 재해석된다 — 참여 7테이블이 실제로 겪은 #15 동형 결함(SI-1·SI-2)이다."""
    assert EMPLOY_TABLE in TABLE_CREATE_ORDER, (
        "TCORP_EMPLOY 가 TABLE_CREATE_ORDER(=CORP_FINANCE_CREATE_ORDER 경유)에 미편입 — "
        "생성만 되고 영원히 안 지워진다"
    )


def test_CE3_headcount_is_stored_per_corporation_not_per_page():
    """🚨 `COMP_ID` 가 있으면 안 된다 — 직원 현황도 **법인 단위**다.

    CJ ENM 2페이지가 같은 법인을 가리키므로(실측), 페이지 단위로 저장하면 인원이 두 벌이 되고
    한쪽만 갱신되는 순간 두 페이지의 직원수가 갈라진다. 조회는 TCOMPANY_CORP 를 경유한다."""
    block = _table_block(EMPLOY_TABLE)
    assert not re.search(r"\bCOMP_ID\b", block, re.IGNORECASE), (
        "TCORP_EMPLOY 에 COMP_ID 가 있다 — 직원 현황은 법인(CORP_CODE) 단위로 저장해야 한다"
    )
    assert re.search(r"\bCORP_CODE\b", block, re.IGNORECASE), "TCORP_EMPLOY 에 CORP_CODE 가 없다"


def test_CE4_raw_columns_are_preserved():
    """원문 보존 — 정규화 규칙이 바뀌어도 **재수집 없이** 재계산할 수 있어야 한다(SP-MET-4).

    근속 5종·급여 단위 연도별 변동은 규칙이 앞으로도 바뀔 수 있다는 뜻이다. 원문이 없으면
    규칙 수정 = 100사 × 11년 전량 재호출이고, 그때 DART 응답이 지금과 같다는 보장도 없다."""
    block = _table_block(EMPLOY_TABLE)
    missing = [c for c in ("RAW_TENURE_NM", "RAW_SALARY_NM", "SEGMENT_NM", "SEX_CD")
               if not re.search(rf"\b{c}\b", block, re.IGNORECASE)]
    assert not missing, f"TCORP_EMPLOY 에 원문 컬럼이 없다: {missing} — 규칙이 바뀌면 전량 재수집이 된다"


def test_CE10_migration_matches_schema():
    """🚨 마이그레이션과 schema.sql 의 DDL 이 갈라지면 안 된다(CF-10 과 같은 계약).

    schema.sql 은 **신규 프로비저닝**, 마이그레이션은 **기존 서빙 DB** 를 담당한다. 한쪽만
    고치면 두 환경이 조용히 다른 스키마가 되고, 그 차이는 테이블이 만들어진 시점에 따라
    달라져서 재현이 어렵다. 정본은 schema.sql 이고 이 테스트가 사본의 드리프트를 막는다."""
    mig = Path(SCHEMA_SQL).parent / "migrations" / "20260828_add_corp_employ.sql"
    assert mig.is_file(), f"마이그레이션 파일 부재: {mig}"

    def block(text: str, name: str) -> str:
        m = re.search(
            rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{name}\s*\((.*?)\n\)\s*ENGINE",
            text, re.IGNORECASE | re.DOTALL,
        )
        assert m, f"{name} DDL 을 찾을 수 없다"
        return re.sub(r"\s+", " ", m.group(1)).strip()

    assert block(_schema_text(), EMPLOY_TABLE) == block(mig.read_text(encoding="utf-8"), EMPLOY_TABLE), (
        "schema.sql 과 20260828_add_corp_employ.sql 의 DDL 이 다르다 — 정본은 db/schema.sql 이다"
    )


# ── DB 동작 계약 ─────────────────────────────────────────────────────────────

def _mk_corp(conn, corp_code="00126380", nm="삼성전자", stock="005930", acct="general"):
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCORP (CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD) "
            "VALUES (%s, %s, %s, %s, 'CFS')",
            (corp_code, nm, stock, acct),
        )
    return corp_code


_INSERT = (
    "INSERT INTO TCORP_EMPLOY "
    "(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD, TOTAL_ROW_YN, HEADCNT, TENURE_YEAR, "
    " AVG_SALARY_AMT, RAW_TENURE_NM, RAW_SALARY_NM, RCEPT_NO) "
    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
)


def test_CE5_nullability_contract(clean_tx):
    """🚨 결측 컬럼은 NULL 을 받고, 식별 컬럼은 받지 않는다 — 실제 DDL 로 확인한다.

    NULL 허용 여부를 스키마 텍스트가 아니라 information_schema 로 보는 이유: 컬럼 정의에
    `DEFAULT NULL` 을 적어도 실제 타입/키 제약이 다르게 걸릴 수 있고, 우리가 믿어야 하는 것은
    **서버가 만든 테이블**이다.

    식별 4컬럼이 NULL 을 받으면 UNIQUE 가 무너진다 — MySQL 은 UNIQUE 안의 NULL 을 서로 다른
    값으로 보므로 같은 부문이 몇 벌이든 쌓이고, 그 중복은 가중평균의 분모를 부풀린다."""
    conn = clean_tx
    with conn.cursor() as cur:
        cur.execute(
            "SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=%s", (EMPLOY_TABLE,)
        )
        cols = {r[0].upper(): (r[1], r[2]) for r in cur.fetchall()}

    missing = [c for c in NULLABLE_COLS + NOT_NULL_COLS if c not in cols]
    assert not missing, f"TCORP_EMPLOY 에 없는 컬럼: {missing}"

    wrong = [c for c in NULLABLE_COLS if cols[c][0] != "YES"]
    assert not wrong, (
        f"결측이 허용돼야 할 컬럼이 NOT NULL 이다: {wrong} — 값이 없으면 NULL 이지 0 이 아니다. "
        "NOT NULL 이면 수집기가 0 을 채우게 되고 '평균연봉 0원'이 사실인 양 나간다(SP-MET-6)"
    )
    zero_default = [c for c in NULLABLE_COLS if str(cols[c][1]) in ("0", "0.00")]
    assert not zero_default, f"결측 컬럼에 0 기본값이 걸려 있다: {zero_default} — 조용한 거짓이 된다"

    nullable_id = [c for c in NOT_NULL_COLS if cols[c][0] != "NO"]
    assert not nullable_id, (
        f"식별 컬럼이 NULL 을 허용한다: {nullable_id} — UNIQUE 안의 NULL 은 서로 다르게 취급돼 "
        "같은 부문×성별 행이 여러 벌 쌓인다"
    )


def test_CE6_same_segment_cannot_be_stored_twice(clean_tx):
    """(법인, 연도, 부문, 성별) 은 유일 — 재수집이 같은 행을 두 벌 만들면 인원이 부풀려진다.

    UNIQUE 가 없으면 수집기를 두 번 돌린 것만으로 삼성전자 직원수가 두 배가 되고, 그건
    합계행 함정(SP-MET-5)과 화면에서 구분되지 않는다."""
    conn = clean_tx
    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        cur.execute("SELECT INDEX_NAME, NON_UNIQUE, COLUMN_NAME FROM information_schema.STATISTICS "
                    "WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=%s AND INDEX_NAME='uq_corp_employ' "
                    "ORDER BY SEQ_IN_INDEX", (EMPLOY_TABLE,))
        rows = cur.fetchall()
        assert rows, "uq_corp_employ UNIQUE 키가 없다"
        assert all(r[1] == 0 for r in rows), "uq_corp_employ 가 UNIQUE 가 아니다"
        assert [r[2].upper() for r in rows] == ["CORP_CODE", "BSNS_YEAR", "SEGMENT_NM", "SEX_CD"], (
            f"UNIQUE 키 구성이 다르다: {[r[2] for r in rows]}"
        )

        cur.execute(_INSERT, (corp, 2025, "DX부문", "남", False, 70_000, 13.70,
                              157_064_509, "13.70", "157,064,509", "20260311000123"))
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute(_INSERT, (corp, 2025, "DX부문", "남", False, 99_999, 1.00,
                                  20_000_000, "1.00", "20,000,000", "20260311000123"))


def test_CE7_segments_and_total_row_coexist(clean_tx):
    """★ 부문행과 합계행이 **같은 연도에 공존**할 수 있어야 한다(SP-MET-5 실측 재현).

    7사가 둘을 함께 낸다. 스키마가 이걸 막으면 수집이 실패하고, 반대로 집계가 둘을 다 더하면
    삼성전자가 128,881 → 257,762 명이 된다 — 그래서 **판정 결과를 행에 저장**해 집계가
    합계행만 세도록 한다(판정은 한 곳에서만)."""
    conn = clean_tx
    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        cur.execute(_INSERT, (corp, 2025, "DX부문", "남", False, 40_000, 13.70,
                              157_064_509, "13.70", "157,064,509", "20260311000123"))
        cur.execute(_INSERT, (corp, 2025, "DS부문", "남", False, 30_000, 12.10,
                              150_000_000, "12.10", "150,000,000", "20260311000123"))
        cur.execute(_INSERT, (corp, 2025, "성별합계", "남", True, 70_000, 13.00,
                              155_000_000, "13.00", "155,000,000", "20260311000123"))
        cur.execute("SELECT COUNT(*) FROM TCORP_EMPLOY WHERE CORP_CODE=%s AND BSNS_YEAR=2025", (corp,))
        assert cur.fetchone()[0] == 3, "부문행과 합계행이 공존하지 못한다"
        cur.execute("SELECT SUM(HEADCNT) FROM TCORP_EMPLOY "
                    "WHERE CORP_CODE=%s AND BSNS_YEAR=2025 AND TOTAL_ROW_YN=TRUE", (corp,))
        assert cur.fetchone()[0] == 70_000, "합계행만 골라 셀 수 없다 — TOTAL_ROW_YN 이 제 역할을 못한다"


def test_CE8_orphan_rows_cannot_survive_the_corporation(clean_tx):
    """FK + ON DELETE CASCADE — 법인이 사라지면 직원 행도 함께 사라진다.

    CASCADE 가 없으면 법인 삭제가 FK 로 막히거나(운영이 막힌다) 고아 행이 남는다. 고아가 남은
    채 `TCORP` 가 재생성되면 같은 CORP_CODE 를 받은 **다른 법인의 인원으로 재해석**된다 —
    #15 동형 결함이고, 에러 없이 틀린 숫자가 된다."""
    conn = clean_tx
    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute(_INSERT, ("99999999", 2025, "없는법인", "남", False, 1, None,
                                  None, None, None, None))
    conn.rollback()

    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        cur.execute(_INSERT, (corp, 2025, "DX부문", "남", False, 70_000, 13.70,
                              157_064_509, "13.70", "157,064,509", "20260311000123"))
        cur.execute("DELETE FROM TCORP WHERE CORP_CODE=%s", (corp,))
        cur.execute("SELECT COUNT(*) FROM TCORP_EMPLOY WHERE CORP_CODE=%s", (corp,))
        assert cur.fetchone()[0] == 0, "법인을 지웠는데 직원 행이 남았다 — CASCADE 가 없다"


def test_CE9_missing_stays_null_and_values_survive_round_trip(clean_tx):
    """결측은 NULL 로 남고, 실측값은 정밀도를 잃지 않는다.

    - `-` 로 오는 근속·범위 밖 급여(SP-MET-6·7)는 NULL 로 들어가야 한다. 0 으로 바뀌어 나오면
      가중평균이 그만큼 내려앉는다.
    - 근속은 소수 두 자리를 지켜야 한다(DECIMAL(5,2)). INT 였다면 13.7 이 14 로 반올림돼
      **검증값(삼성전자 2025 근속 13.7년)이 조용히 틀린다.**
    - 급여는 원 단위 정수 그대로 — 157,064,509 원(삼성전자 2025 실측, SP-MET-1)."""
    conn = clean_tx
    corp = _mk_corp(conn)
    with conn.cursor() as cur:
        cur.execute(_INSERT, (corp, 2019, "커머스부문", "여", False, 1_000, None,
                              None, "-", "83", "20200330000456"))
        cur.execute("SELECT HEADCNT, TENURE_YEAR, AVG_SALARY_AMT, RAW_TENURE_NM, RAW_SALARY_NM "
                    "FROM TCORP_EMPLOY WHERE CORP_CODE=%s AND BSNS_YEAR=2019", (corp,))
        head, tenure, salary, raw_t, raw_s = cur.fetchone()
        assert (tenure, salary) == (None, None), "결측이 0 으로 바뀌었다 — NULL 로 남아야 한다"
        assert head == 1_000
        assert (raw_t, raw_s) == ("-", "83"), "원문이 보존되지 않았다 — 재정규화 근거가 사라진다"

        cur.execute(_INSERT, (corp, 2025, "DX부문", "남", False, 128_881, 13.70,
                              157_064_509, "13.70", "157,064,509", "20260311000123"))
        cur.execute("SELECT HEADCNT, TENURE_YEAR, AVG_SALARY_AMT FROM TCORP_EMPLOY "
                    "WHERE CORP_CODE=%s AND BSNS_YEAR=2025", (corp,))
        head, tenure, salary = cur.fetchone()
        assert head == 128_881, "인원이 그대로 저장되지 않는다"
        assert float(tenure) == 13.70, f"근속 소수점이 깨졌다: {tenure} — 13.7 이 14 가 되면 검증값이 틀린다"
        assert int(salary) == 157_064_509, f"급여가 원 단위로 보존되지 않는다: {salary}"
