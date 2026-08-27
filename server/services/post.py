"""SP-COMM-4·5 커뮤니티 서비스 — 목록·상세·댓글 열람, 글·댓글·좋아요 쓰기, 카운터 트랜잭션, 일일 카운트.

- 작성자 식별은 응답에 **닉네임만**(INV-8). 닉네임은 `LEFT JOIN TMEMBER` 로 읽고 NULL(탈퇴·SET NULL)이면
  "탈퇴한 회원". 재직 배지(`verified_comp_nm`)는 작성자의 활성·미폐기·미만료 `TEMPLOY_VERIFICATION`
  회사명 — 회원이 여러 회사를 인증했을 수 있어 조인 대신 **상관 서브쿼리 LIMIT 1**(글의 회사 태그와
  같은 회사를 우선)로 읽는다(LEFT JOIN 이면 행이 곱해진다).
- 비정규화 카운터(`LIKE_CNT`·`COMMENT_CNT`)는 자식 삽입·삭제와 **같은 트랜잭션**에서 ±1 한다.
  좋아요 토글은 글 행을 `FOR UPDATE` 로 잠가 같은 회원의 연타를 직렬화하고, UNIQUE 는 뒤의 보루다.
- 소프트 삭제 마스킹: 글 `TITLE_NM='(삭제됨)', BODY_CTNT=''`, 댓글 `BODY_CTNT=''`. 원문 보존 없음.
- 일일 상한: `INS_DTM >= UTC_DATE()`(UTC 자정 기준 카운트 — 복지 편집 `_daily_count` 관례).

신규 의존성 0.
"""
from __future__ import annotations

import re

from server import database
from server.config import get_settings

DELETED_TITLE = "(삭제됨)"
WITHDRAWN_NICK = "탈퇴한 회원"

# ── slug — `generator/slug.py::slug_of` 와 **같은 규칙**(FR-51) ─────────────────────────
# 서버는 생성기를 import 하지 않는다(런타임 의존 방향). 대신 규칙을 복제하고 test_community_api
# CM-7.5 가 두 구현을 맞대어 드리프트를 막는다. 생성기와 달리 빈 slug 에 예외를 던지지 않는다 —
# 회사 태그 링크 하나 때문에 목록 전체가 500 이 되면 안 된다(빈 문자열이면 프론트가 링크를 생략).
_NON_ALNUM_RE = re.compile(r"[^a-z0-9]+")
_DASH_RUN_RE = re.compile(r"-{2,}")


def slug_of(comp_eng_nm: str) -> str:
    s = comp_eng_nm.strip().lower()
    s = _NON_ALNUM_RE.sub("-", s)
    s = _DASH_RUN_RE.sub("-", s)
    return s.strip("-")


# ── SQL ────────────────────────────────────────────────────────────────────────

# 작성자의 재직 배지 회사명 — 글의 회사 태그와 같은 회사를 우선, 없으면 최신 인증.
# `COALESCE(v.COMP_ID = p.COMP_ID, 0)`: 태그가 NULL 이면 비교가 NULL 이라 0 으로 접는다.
_SQL_VERIFIED = """
  (SELECT vc.COMP_NM FROM TEMPLOY_VERIFICATION v JOIN TCOMPANY vc ON vc.COMP_ID = v.COMP_ID
    WHERE v.MBR_ID = p.MBR_ID AND v.REVOKED_DTM IS NULL
      AND (v.EXPIRES_DTM IS NULL OR v.EXPIRES_DTM > UTC_TIMESTAMP())
    ORDER BY COALESCE(v.COMP_ID = p.COMP_ID, 0) DESC, v.EMPLOY_VRF_ID DESC LIMIT 1) AS verified_comp_nm"""

_SQL_POST_COLS = f"""
  SELECT p.POST_ID AS post_id, p.MBR_ID AS mbr_id, p.CATEGORY_CD AS category, p.TITLE_NM AS title,
         p.BODY_CTNT AS body, p.LIKE_CNT AS like_cnt, p.COMMENT_CNT AS comment_cnt,
         p.INS_DTM AS created_at, p.MOD_DTM AS updated_at, p.EDITED_YN AS edited, p.STATUS_CD AS status,
         COALESCE(m.NICKNAME_NM, %s) AS nickname,
         c.COMP_ID AS comp_id, c.COMP_NM AS comp_nm, c.COMP_ENG_NM AS comp_eng_nm,{_SQL_VERIFIED}
    FROM TPOST p
    LEFT JOIN TMEMBER m ON m.MBR_ID = p.MBR_ID
    LEFT JOIN TCOMPANY c ON c.COMP_ID = p.COMP_ID"""

_ORDER_BY = {
    "latest": "p.POST_ID DESC",
    "likes": "p.LIKE_CNT DESC, p.POST_ID DESC",      # 커서는 POST_ID 만 — 동률 경계 중복 수용(FR-121)
    "comments": "p.COMMENT_CNT DESC, p.POST_ID DESC",
}

_SQL_COMMENTS = """
  SELECT k.COMMENT_ID AS comment_id, k.MBR_ID AS mbr_id, k.BODY_CTNT AS body, k.STATUS_CD AS status,
         k.INS_DTM AS created_at, COALESCE(m.NICKNAME_NM, %s) AS nickname,
         (SELECT vc.COMP_NM FROM TEMPLOY_VERIFICATION v JOIN TCOMPANY vc ON vc.COMP_ID = v.COMP_ID
           WHERE v.MBR_ID = k.MBR_ID AND v.REVOKED_DTM IS NULL
             AND (v.EXPIRES_DTM IS NULL OR v.EXPIRES_DTM > UTC_TIMESTAMP())
           ORDER BY v.EMPLOY_VRF_ID DESC LIMIT 1) AS verified_comp_nm
    FROM TPOST_COMMENT k LEFT JOIN TMEMBER m ON m.MBR_ID = k.MBR_ID
   WHERE k.POST_ID = %s"""

# 활성 글 잠금(쓰기 트랜잭션 진입) — 상태·소유자 판정을 같은 잠금 안에서 한다.
_SQL_LOCK_POST = "SELECT POST_ID, MBR_ID, STATUS_CD, LIKE_CNT, COMMENT_CNT FROM TPOST WHERE POST_ID=%s FOR UPDATE"


# ── 공통 ──────────────────────────────────────────────────────────────────────

async def daily_count(table: str, mbr_id: int) -> int:
    """오늘(UTC 자정 이후) 이 회원이 남긴 행 수 — 일일 상한 게이트(FR-132). 삭제한 것도 센다(INS_DTM 기준).
    `table` 은 내부 상수만 온다(사용자 입력 아님) — 신고 서비스도 같은 함수를 쓴다."""
    assert table in ("TPOST", "TPOST_COMMENT", "TPOST_REPORT")
    row = await database.fetch_one(
        f"SELECT COUNT(*) AS n FROM {table} WHERE MBR_ID=%s AND INS_DTM >= UTC_DATE()", (mbr_id,)
    )
    return int(row["n"]) if row else 0


async def company_exists(comp_id: int) -> bool:
    return await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ID=%s", (comp_id,)) is not None


async def member_email(mbr_id: int) -> str | None:
    """공지 권한 판정용 — 세션은 MBR_ID 만 주므로 TMEMBER 를 재조회한다(`require_operator` 와 같은 이유)."""
    row = await database.fetch_one(
        "SELECT LOGIN_EMAIL_NM FROM TMEMBER WHERE MBR_ID=%s AND STATUS_CD='active'", (mbr_id,)
    )
    return row["LOGIN_EMAIL_NM"] if row else None


def _comp_tag(row: dict) -> dict | None:
    if row.get("comp_id") is None:
        return None
    return {"comp_id": row["comp_id"], "comp_nm": row["comp_nm"], "slug": slug_of(row["comp_eng_nm"] or "")}


def _list_item(row: dict) -> dict:
    return {
        "post_id": row["post_id"], "category": row["category"], "title": row["title"],
        "nickname": row["nickname"], "verified_comp_nm": row["verified_comp_nm"], "comp": _comp_tag(row),
        "like_cnt": row["like_cnt"], "comment_cnt": row["comment_cnt"],
        "created_at": row["created_at"], "edited": bool(row["edited"]),
    }


# ── 읽기 (FR-121~123) ─────────────────────────────────────────────────────────

async def list_posts(category: str | None, sort: str, limit: int, before: int | None) -> tuple[list[dict], int | None]:
    """목록 — active 만·키셋(`POST_ID < before`)·LIMIT+1 로 next_before 판정."""
    sql = _SQL_POST_COLS + " WHERE p.STATUS_CD='active'"
    params: list = [WITHDRAWN_NICK]
    if category is not None:
        sql += " AND p.CATEGORY_CD=%s"
        params.append(category)
    if before is not None:
        sql += " AND p.POST_ID < %s"
        params.append(before)
    sql += f" ORDER BY {_ORDER_BY[sort]} LIMIT %s"
    params.append(limit + 1)
    rows = await database.fetch_all(sql, tuple(params))
    has_more = len(rows) > limit
    rows = rows[:limit]
    items = [_list_item(r) for r in rows]
    return items, (rows[-1]["post_id"] if has_more and rows else None)


async def get_post(post_id: int, viewer_mbr_id: int | None) -> dict | None:
    """상세 — active 만(deleted/hidden 은 None → 404). `is_mine`·`liked` 는 세션이 있을 때만 참일 수 있다."""
    row = await database.fetch_one(
        _SQL_POST_COLS + " WHERE p.POST_ID=%s AND p.STATUS_CD='active'", (WITHDRAWN_NICK, post_id)
    )
    if not row:
        return None
    liked = False
    if viewer_mbr_id is not None:
        liked = await database.fetch_one(
            "SELECT REACTION_ID FROM TPOST_REACTION WHERE POST_ID=%s AND MBR_ID=%s", (post_id, viewer_mbr_id)
        ) is not None
    item = _list_item(row)
    item.update({
        "body": row["body"], "updated_at": row["updated_at"],
        "is_mine": viewer_mbr_id is not None and row["mbr_id"] == viewer_mbr_id,
        "liked": liked,
    })
    return item


async def post_is_active(post_id: int) -> bool:
    return await database.fetch_one(
        "SELECT POST_ID FROM TPOST WHERE POST_ID=%s AND STATUS_CD='active'", (post_id,)
    ) is not None


async def list_comments(post_id: int, after: int | None, limit: int, viewer_mbr_id: int | None) -> tuple[list[dict], int | None]:
    """댓글 — 오래된 순(COMMENT_ID ASC)·`after` 커서·LIMIT+1. 비활성(deleted/hidden)은 `body:null, deleted:true` 자리만."""
    sql = _SQL_COMMENTS
    params: list = [WITHDRAWN_NICK, post_id]
    if after is not None:
        sql += " AND k.COMMENT_ID > %s"
        params.append(after)
    sql += " ORDER BY k.COMMENT_ID ASC LIMIT %s"
    params.append(limit + 1)
    rows = await database.fetch_all(sql, tuple(params))
    has_more = len(rows) > limit
    rows = rows[:limit]
    items = []
    for r in rows:
        active = r["status"] == "active"
        items.append({
            "comment_id": r["comment_id"], "nickname": r["nickname"], "verified_comp_nm": r["verified_comp_nm"],
            "body": r["body"] if active else None, "deleted": not active,
            "is_mine": viewer_mbr_id is not None and r["mbr_id"] == viewer_mbr_id,
            "created_at": r["created_at"],
        })
    return items, (rows[-1]["comment_id"] if has_more and rows else None)


# ── 쓰기 (FR-124~129) ─────────────────────────────────────────────────────────

async def create_post(mbr_id: int, payload) -> dict:
    """글 작성. 반환 result: ok(+post_id) / rate_limited(429) / comp_not_found(422). 공지 권한은 라우터가 본다."""
    if await daily_count("TPOST", mbr_id) >= get_settings().daily_post_limit:
        return {"result": "rate_limited"}
    if payload.comp_id is not None and not await company_exists(payload.comp_id):
        return {"result": "comp_not_found"}
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "INSERT INTO TPOST (MBR_ID, CATEGORY_CD, TITLE_NM, BODY_CTNT, COMP_ID, INS_ID) "
                "VALUES (%s, %s, %s, %s, %s, %s)",
                (mbr_id, payload.category, payload.title, payload.body, payload.comp_id, mbr_id),
            )
            post_id = cur.lastrowid
    return {"result": "ok", "post_id": post_id}


async def update_post(post_id: int, mbr_id: int, payload) -> dict:
    """글 수정 — 본인만·active 만·`category` 불변·EDITED_YN=1. 반환 result: ok(+updated_at) / not_found / forbidden / comp_not_found."""
    if payload.comp_id is not None and not await company_exists(payload.comp_id):
        return {"result": "comp_not_found"}
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_LOCK_POST, (post_id,))
            row = await cur.fetchone()
            if not row or row["STATUS_CD"] != "active":
                return {"result": "not_found"}
            if row["MBR_ID"] != mbr_id:
                return {"result": "forbidden"}
            await cur.execute(
                "UPDATE TPOST SET TITLE_NM=%s, BODY_CTNT=%s, COMP_ID=%s, EDITED_YN=TRUE, "
                "MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() WHERE POST_ID=%s",
                (payload.title, payload.body, payload.comp_id, mbr_id, post_id),
            )
            await cur.execute("SELECT MOD_DTM FROM TPOST WHERE POST_ID=%s", (post_id,))
            updated = (await cur.fetchone())["MOD_DTM"]
    return {"result": "ok", "updated_at": updated}


async def delete_post(post_id: int, mbr_id: int) -> str:
    """글 소프트 삭제 — 본인만. `STATUS_CD=deleted` + 제목·본문 마스킹(원문 보존 없음). 반환: ok / not_found / forbidden."""
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_LOCK_POST, (post_id,))
            row = await cur.fetchone()
            if not row or row["STATUS_CD"] != "active":
                return "not_found"
            if row["MBR_ID"] != mbr_id:
                return "forbidden"
            await cur.execute(
                "UPDATE TPOST SET STATUS_CD='deleted', TITLE_NM=%s, BODY_CTNT='', MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() "
                "WHERE POST_ID=%s",
                (DELETED_TITLE, mbr_id, post_id),
            )
    return "ok"


async def create_comment(post_id: int, mbr_id: int, body: str) -> dict:
    """댓글 작성 + COMMENT_CNT+1 (같은 트랜잭션). 반환 result: ok(+comment_id) / not_found / rate_limited."""
    if await daily_count("TPOST_COMMENT", mbr_id) >= get_settings().daily_comment_limit:
        return {"result": "rate_limited"}
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_LOCK_POST, (post_id,))
            row = await cur.fetchone()
            if not row or row["STATUS_CD"] != "active":
                return {"result": "not_found"}
            await cur.execute(
                "INSERT INTO TPOST_COMMENT (POST_ID, MBR_ID, BODY_CTNT, INS_ID) VALUES (%s, %s, %s, %s)",
                (post_id, mbr_id, body, mbr_id),
            )
            comment_id = cur.lastrowid
            await cur.execute("UPDATE TPOST SET COMMENT_CNT = COMMENT_CNT + 1 WHERE POST_ID=%s", (post_id,))
    return {"result": "ok", "comment_id": comment_id}


async def delete_comment(post_id: int, comment_id: int, mbr_id: int) -> str:
    """댓글 소프트 삭제 + COMMENT_CNT-1 (같은 트랜잭션). 본인만. 글이 비활성이면 404. 반환: ok / not_found / forbidden."""
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_LOCK_POST, (post_id,))
            post = await cur.fetchone()
            if not post or post["STATUS_CD"] != "active":
                return "not_found"
            await cur.execute(
                "SELECT MBR_ID, STATUS_CD FROM TPOST_COMMENT WHERE COMMENT_ID=%s AND POST_ID=%s FOR UPDATE",
                (comment_id, post_id),
            )
            row = await cur.fetchone()
            if not row or row["STATUS_CD"] != "active":  # 이미 지웠거나 숨겨졌거나 다른 글의 댓글
                return "not_found"
            if row["MBR_ID"] != mbr_id:
                return "forbidden"
            await cur.execute(
                "UPDATE TPOST_COMMENT SET STATUS_CD='deleted', BODY_CTNT='', MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() "
                "WHERE COMMENT_ID=%s",
                (mbr_id, comment_id),
            )
            await cur.execute("UPDATE TPOST SET COMMENT_CNT = COMMENT_CNT - 1 WHERE POST_ID=%s", (post_id,))
    return "ok"


async def toggle_like(post_id: int, mbr_id: int) -> dict | None:
    """좋아요 토글·멱등 — 없으면 INSERT+1, 있으면 DELETE-1 을 한 트랜잭션으로. 비활성 글은 None(404).

    글 행 `FOR UPDATE` 가 같은 글에 대한 토글을 직렬화하므로 "있는가" 판정과 ±1 이 어긋나지 않는다.
    UNIQUE(POST_ID, MBR_ID) 는 그 뒤의 보루다(SP-DB-18)."""
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_LOCK_POST, (post_id,))
            post = await cur.fetchone()
            if not post or post["STATUS_CD"] != "active":
                return None
            await cur.execute(
                "SELECT REACTION_ID FROM TPOST_REACTION WHERE POST_ID=%s AND MBR_ID=%s", (post_id, mbr_id)
            )
            existing = await cur.fetchone()
            if existing:
                await cur.execute("DELETE FROM TPOST_REACTION WHERE REACTION_ID=%s", (existing["REACTION_ID"],))
                await cur.execute("UPDATE TPOST SET LIKE_CNT = LIKE_CNT - 1 WHERE POST_ID=%s", (post_id,))
                liked = False
            else:
                await cur.execute(
                    "INSERT INTO TPOST_REACTION (POST_ID, MBR_ID, REACTION_CD, INS_ID) VALUES (%s, %s, 'like', %s)",
                    (post_id, mbr_id, mbr_id),
                )
                await cur.execute("UPDATE TPOST SET LIKE_CNT = LIKE_CNT + 1 WHERE POST_ID=%s", (post_id,))
                liked = True
            await cur.execute("SELECT LIKE_CNT FROM TPOST WHERE POST_ID=%s", (post_id,))
            like_cnt = (await cur.fetchone())["LIKE_CNT"]
    return {"liked": liked, "like_cnt": like_cnt}
