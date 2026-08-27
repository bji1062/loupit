"""SC15 커뮤니티 4테이블 스키마 계약 — CM-2 (SP-DB-18 · SP-COMM-3).

근거: `docs/SPEC/14-커뮤니티.md` SP-COMM-3 · `docs/FRD/14-커뮤니티-API.md` 전제(4)(5) ·
`docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md` §3-2.

**이 테스트가 지키는 것은 컬럼 목록이 아니라 설계 결정 4가지다.**

  1. **조회수 컬럼이 없다.** 봇 트래픽이 실사용의 수백 배(`GET /` 1,875~11,036 vs 실세션 1~4)라
     조회수는 곧 거짓 숫자가 된다 — 함정 (57)("대체 콘텐츠가 집계인 척") 과 같은 계열.
  2. **작성자·회사 태그는 SET NULL 로 존치한다.** 편집 이력(TBENEFIT_EDIT_LOG)과 같은 규약 —
     탈퇴·회사 삭제가 글을 지우지 않는다(삭제는 앱의 소프트 삭제뿐).
  3. **댓글·좋아요는 글에 CASCADE 한다.** 글이 물리적으로 사라지면 자식도 사라진다(고아 없음).
  4. **좋아요·신고는 회원당 1회다.** UNIQUE 가 카운터 정합(LIKE_CNT)과 중복 신고 차단(409)의 근거다.

무DB 계약(CM-2.1~2.6)은 schema.sql 텍스트만 본다. CM-2.7~2.11 은 `clean_tx` 로 실제 DDL 동작을,
CM-2.12 는 마이그레이션 사본의 멱등성을 실 DB 에서 본다.
"""
from __future__ import annotations

import re

import pymysql
import pytest

from server.tests.conftest import (
    MIGRATIONS_DIR,
    PARTICIPATION_CREATE_ORDER,
    SCHEMA_SQL,
    TABLE_CREATE_ORDER,
    apply_sql,
)

COMMUNITY_TABLES = ["TPOST", "TPOST_COMMENT", "TPOST_REACTION", "TPOST_REPORT"]
MIGRATION = MIGRATIONS_DIR / "20260827_add_community.sql"


def _schema_text() -> str:
    return SCHEMA_SQL.read_text(encoding="utf-8")


def _table_block(text: str, name: str) -> str:
    """해당 CREATE TABLE 블록만 잘라낸다(다음 CREATE TABLE 직전까지)."""
    m = re.search(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{name}\b(.*?)(?=CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+T|\Z)",
        text, re.IGNORECASE | re.DOTALL,
    )
    assert m, f"{name} DDL 이 없다"
    return m.group(1)


def _fk_clause(block: str, column: str) -> str:
    m = re.search(rf"FOREIGN\s+KEY\s*\(\s*{column}\s*\)\s*REFERENCES\s+\w+\s*\(\s*\w+\s*\)([^,\n]*)",
                  block, re.IGNORECASE)
    assert m, f"{column} FK 가 없다"
    return m.group(0).upper()


# ── 무DB 계약 ────────────────────────────────────────────────────────────────

def test_CM2_1_community_tables_exist_in_schema():
    text = _schema_text()
    missing = [t for t in COMMUNITY_TABLES if not re.search(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{t}\b", text, re.IGNORECASE)]
    assert not missing, f"schema.sql 에 없는 커뮤니티 테이블: {missing}"


def test_CM2_2_no_view_count_column():
    """🚨 조회수 컬럼 부재 — 봇이 실사용의 수백 배라 조회수는 거짓 숫자가 된다(계획 §3-2)."""
    block = _table_block(_schema_text(), "TPOST")
    assert not re.search(r"\bVIEW_CNT\b|\bVIEW_COUNT\b|\bHIT_CNT\b|\bREAD_CNT\b", block, re.IGNORECASE), (
        "TPOST 에 조회수 컬럼이 있다 — 정렬은 최신·댓글·좋아요 3종뿐이다(FR-121)"
    )


def test_CM2_3_author_and_company_are_set_null():
    """작성자·회사 태그는 ON DELETE SET NULL — 탈퇴·회사 삭제가 글을 지우지 않는다(편집 이력 규약)."""
    text = _schema_text()
    post = _table_block(text, "TPOST")
    assert "SET NULL" in _fk_clause(post, "MBR_ID"), "TPOST.MBR_ID 가 SET NULL 이 아니다"
    assert "SET NULL" in _fk_clause(post, "COMP_ID"), "TPOST.COMP_ID 가 SET NULL 이 아니다"
    assert "DEFAULT NULL" in re.search(r"MBR_ID\s+INT\s+([^\n]*)", post).group(1).upper(), (
        "TPOST.MBR_ID 가 NULL 허용이 아니면 SET NULL 이 실패한다"
    )
    comment = _table_block(text, "TPOST_COMMENT")
    assert "SET NULL" in _fk_clause(comment, "MBR_ID"), "TPOST_COMMENT.MBR_ID 가 SET NULL 이 아니다"
    report = _table_block(text, "TPOST_REPORT")
    assert "SET NULL" in _fk_clause(report, "MBR_ID"), "TPOST_REPORT.MBR_ID 가 SET NULL 이 아니다"


def test_CM2_4_children_cascade_on_post():
    """댓글·좋아요는 글에 CASCADE — 글이 물리적으로 사라지면 고아가 남지 않는다."""
    text = _schema_text()
    assert "CASCADE" in _fk_clause(_table_block(text, "TPOST_COMMENT"), "POST_ID")
    reaction = _table_block(text, "TPOST_REACTION")
    assert "CASCADE" in _fk_clause(reaction, "POST_ID")
    assert "CASCADE" in _fk_clause(reaction, "MBR_ID"), (
        "좋아요는 SET NULL 이 아니라 CASCADE 다 — MBR_ID NULL 인 좋아요는 UNIQUE(POST_ID, MBR_ID)를 무력화한다"
    )


def test_CM2_5_unique_constraints():
    """회원당 1회 — 좋아요 UNIQUE(POST_ID, MBR_ID) · 신고 UNIQUE(TARGET_TYPE_CD, TARGET_ID, MBR_ID)."""
    text = _schema_text()
    reaction = _table_block(text, "TPOST_REACTION")
    assert re.search(r"UNIQUE\s+KEY\s+\w+\s*\(\s*POST_ID\s*,\s*MBR_ID\s*\)", reaction, re.IGNORECASE), (
        "TPOST_REACTION 에 UNIQUE(POST_ID, MBR_ID) 가 없다 — 좋아요를 무한히 누를 수 있다"
    )
    report = _table_block(text, "TPOST_REPORT")
    assert re.search(r"UNIQUE\s+KEY\s+\w+\s*\(\s*TARGET_TYPE_CD\s*,\s*TARGET_ID\s*,\s*MBR_ID\s*\)",
                     report, re.IGNORECASE), (
        "TPOST_REPORT 에 UNIQUE(TARGET_TYPE_CD, TARGET_ID, MBR_ID) 가 없다 — 중복 신고 409 의 근거가 없다"
    )
    # TARGET_ID 는 FK 가 아니다 — 두 테이블(글·댓글)을 가리킨다(SP-COMM-3).
    assert not re.search(r"FOREIGN\s+KEY\s*\(\s*TARGET_ID\s*\)", report, re.IGNORECASE)


def test_CM2_6_in_isolation_cycle_after_parents():
    """SI-1 계열 — 격리 사이클 편입 + 참여 그룹 뒤(TMEMBER·TCOMPANY 가 부모)."""
    missing = [t for t in COMMUNITY_TABLES if t not in TABLE_CREATE_ORDER]
    assert not missing, (
        f"커뮤니티 테이블이 TABLE_CREATE_ORDER 에 미편입: {missing} — "
        "conftest 에 넣지 않으면 생성만 되고 영원히 안 지워진다(참여 7테이블이 겪은 결함)"
    )
    assert PARTICIPATION_CREATE_ORDER[-4:] == COMMUNITY_TABLES, (
        "커뮤니티 4테이블은 PARTICIPATION_CREATE_ORDER 끝에 부모→자식 순서로 붙는다(SP-COMM-3)"
    )
    pos = {t: i for i, t in enumerate(TABLE_CREATE_ORDER)}
    assert pos["TMEMBER"] < pos["TPOST"] < pos["TPOST_COMMENT"] < pos["TPOST_REACTION"] < pos["TPOST_REPORT"]
    assert pos["TCOMPANY"] < pos["TPOST"]


def test_CM2_6b_migration_matches_schema():
    """🚨 마이그레이션 사본과 schema.sql 의 DDL 이 갈라지면 안 된다(CF-10 과 같은 계약).

    schema.sql 은 **신규 프로비저닝**, 마이그레이션은 **기존 서빙 DB** 를 담당한다. 정본은 schema.sql."""
    assert MIGRATION.is_file(), f"마이그레이션 파일 부재: {MIGRATION}"
    mig_text = MIGRATION.read_text(encoding="utf-8")

    def block(text: str, name: str) -> str:
        m = re.search(
            rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{name}\s*\((.*?)\n\)\s*ENGINE",
            text, re.IGNORECASE | re.DOTALL,
        )
        assert m, f"{name} DDL 을 찾을 수 없다"
        return re.sub(r"\s+", " ", m.group(1)).strip()

    drifted = [t for t in COMMUNITY_TABLES if block(_schema_text(), t) != block(mig_text, t)]
    assert not drifted, f"schema.sql 과 마이그레이션의 DDL 이 다르다: {drifted} — 정본은 db/schema.sql"


# ── DB 동작 계약 ─────────────────────────────────────────────────────────────

def _mk_member(conn, email: str, nick: str) -> int:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, %s)", (email, nick))
        return cur.lastrowid


def _mk_company(conn, eng: str) -> int:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES (%s, '대기업')", (f"tp_{eng}"[:20],))
        tp = cur.lastrowid
        cur.execute("INSERT INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID) VALUES (%s, %s, %s)",
                    (eng, f"회사-{eng}", tp))
        return cur.lastrowid


def _mk_post(conn, mbr_id: int | None, comp_id: int | None = None, category: str = "free") -> int:
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TPOST (MBR_ID, CATEGORY_CD, TITLE_NM, BODY_CTNT, COMP_ID, INS_ID) "
            "VALUES (%s, %s, '제목', '본문', %s, %s)",
            (mbr_id, category, comp_id, mbr_id),
        )
        return cur.lastrowid


def _scalar(conn, sql: str, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def test_CM2_7_member_delete_keeps_post_with_null_author(clean_tx):
    """★ 탈퇴(행 삭제)가 글을 지우지 않는다 — MBR_ID 만 NULL 이 되고 글은 남는다."""
    conn = clean_tx
    m = _mk_member(conn, "cm27@example.com", "cm27")
    p = _mk_post(conn, m)
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TPOST_COMMENT (POST_ID, MBR_ID, BODY_CTNT) VALUES (%s, %s, '댓글')", (p, m))
        cur.execute("DELETE FROM TMEMBER WHERE MBR_ID=%s", (m,))
    assert _scalar(conn, "SELECT COUNT(*) FROM TPOST WHERE POST_ID=%s", (p,)) == 1, "글이 사라졌다(CASCADE?)"
    assert _scalar(conn, "SELECT MBR_ID FROM TPOST WHERE POST_ID=%s", (p,)) is None
    assert _scalar(conn, "SELECT MBR_ID FROM TPOST_COMMENT WHERE POST_ID=%s", (p,)) is None
    assert _scalar(conn, "SELECT COUNT(*) FROM TPOST_COMMENT WHERE POST_ID=%s", (p,)) == 1


def test_CM2_8_company_delete_nulls_tag(clean_tx):
    conn = clean_tx
    m = _mk_member(conn, "cm28@example.com", "cm28")
    c = _mk_company(conn, "cm28co")
    p = _mk_post(conn, m, comp_id=c)
    with conn.cursor() as cur:
        cur.execute("DELETE FROM TCOMPANY WHERE COMP_ID=%s", (c,))
    assert _scalar(conn, "SELECT COMP_ID FROM TPOST WHERE POST_ID=%s", (p,)) is None
    assert _scalar(conn, "SELECT COUNT(*) FROM TPOST WHERE POST_ID=%s", (p,)) == 1


def test_CM2_9_post_delete_cascades_children(clean_tx):
    conn = clean_tx
    m = _mk_member(conn, "cm29@example.com", "cm29")
    p = _mk_post(conn, m)
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TPOST_COMMENT (POST_ID, MBR_ID, BODY_CTNT) VALUES (%s, %s, '댓글')", (p, m))
        cur.execute("INSERT INTO TPOST_REACTION (POST_ID, MBR_ID) VALUES (%s, %s)", (p, m))
        cur.execute("DELETE FROM TPOST WHERE POST_ID=%s", (p,))
    assert _scalar(conn, "SELECT COUNT(*) FROM TPOST_COMMENT WHERE POST_ID=%s", (p,)) == 0
    assert _scalar(conn, "SELECT COUNT(*) FROM TPOST_REACTION WHERE POST_ID=%s", (p,)) == 0


def test_CM2_10_one_like_per_member(clean_tx):
    """좋아요 UNIQUE(POST_ID, MBR_ID) 위반 → IntegrityError. 이게 LIKE_CNT 정합의 근거다."""
    conn = clean_tx
    m = _mk_member(conn, "cm210@example.com", "cm210")
    p = _mk_post(conn, m)
    with conn.cursor() as cur:
        cur.execute("INSERT INTO TPOST_REACTION (POST_ID, MBR_ID) VALUES (%s, %s)", (p, m))
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute("INSERT INTO TPOST_REACTION (POST_ID, MBR_ID) VALUES (%s, %s)", (p, m))


def test_CM2_11_one_report_per_member_per_target(clean_tx):
    """신고 UNIQUE(TARGET_TYPE_CD, TARGET_ID, MBR_ID) 위반 → IntegrityError(라우터는 409 로 번역).

    같은 ID 라도 **대상 유형이 다르면** 다른 대상이다(글 #1 과 댓글 #1)."""
    conn = clean_tx
    m = _mk_member(conn, "cm211@example.com", "cm211")
    p = _mk_post(conn, m)
    sql = "INSERT INTO TPOST_REPORT (TARGET_TYPE_CD, TARGET_ID, MBR_ID, REASON_CD) VALUES (%s, %s, %s, 'spam')"
    with conn.cursor() as cur:
        cur.execute(sql, ("post", p, m))
        cur.execute(sql, ("comment", p, m))  # 유형이 다르면 통과
        with pytest.raises(pymysql.err.IntegrityError):
            cur.execute(sql, ("post", p, m))


def test_CM2_12_migration_is_idempotent(schema_db, db_name):
    """마이그레이션 사본을 **2회** 적용해도 오류가 없고 4테이블이 그대로다(재실행 안전).

    ⚠ 세션 픽스처(schema_db) 위에서 4테이블을 지웠다 다시 만든다 — 커뮤니티 행은 이 시점에
    없어야 하며(각 테스트가 자기 행을 치운다), 부모(TMEMBER·TCOMPANY)는 건드리지 않는다."""
    conn = schema_db
    with conn.cursor() as cur:
        cur.execute("SET FOREIGN_KEY_CHECKS=0")
        for t in reversed(COMMUNITY_TABLES):
            cur.execute(f"DROP TABLE IF EXISTS {t}")
        cur.execute("SET FOREIGN_KEY_CHECKS=1")
    conn.commit()
    apply_sql(conn, MIGRATION)
    apply_sql(conn, MIGRATION)  # 2회째 — IF NOT EXISTS 라 no-op 이어야 한다
    with conn.cursor() as cur:
        cur.execute(
            "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s AND TABLE_NAME IN "
            "('TPOST','TPOST_COMMENT','TPOST_REACTION','TPOST_REPORT')",
            (db_name,),
        )
        names = {r[0] for r in cur.fetchall()}
    assert names == set(COMMUNITY_TABLES)
