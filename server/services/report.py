"""SP-COMM-6 신고 서비스 — 접수·콘솔 큐·처리 (FR-130·131).

- 접수는 대상을 바꾸지 않는다(자동 숨김 없음). 대상 존재·`active` 확인은 접수 시 여기서 한다 —
  `TARGET_ID` 는 두 테이블을 가리키므로 FK 가 없다(SP-DB-18).
- 같은 (회원, 대상) 중복은 UNIQUE 충돌 → `duplicate`(라우터가 409).
- 처리(`hide`/`dismiss`)는 콘솔에서만, `decided_by` 는 **세션에서** 온다(SP-AUTH-19 와 동일 — 기본값 없음).
  `hide` 는 대상을 `hidden` 으로 바꾸고 같은 대상의 다른 pending 신고를 일괄 `actioned` 로.
  되돌릴 수 있는 것만(SP-AUTH-19.4): 하드 삭제 없음. 카운터(`COMMENT_CNT` 등)는 손대지 않는다.
- 게시판 직접 숨김·복구(`set_visibility`, SP-AUTH-19.7) — 신고 없이 콘솔 게시판 탭에서. 같은 SQL 모양·
  같은 감사(세션의 운영자 → `MOD_ID`), 숨길 때 같은 대상의 pending 신고를 함께 닫는다.
"""
from __future__ import annotations

import logging

from pymysql.err import IntegrityError

from server import database
from server.config import get_settings
from server.services import post as post_svc

logger = logging.getLogger(__name__)

EXCERPT_LEN = 80

_TARGET_TABLE = {"post": "TPOST", "comment": "TPOST_COMMENT"}
_TARGET_PK = {"post": "POST_ID", "comment": "COMMENT_ID"}

# 큐: pending 만, 발췌는 글=제목·댓글=본문 앞부분(사용자 입력 원문 — 콘솔은 textContent 로만 표시).
SQL_LIST_PENDING_REPORTS = """
  SELECT r.REPORT_ID, r.TARGET_TYPE_CD, r.TARGET_ID, r.REASON_CD, r.DETAIL_CTNT, r.INS_DTM,
         m.NICKNAME_NM,
         CASE r.TARGET_TYPE_CD
           WHEN 'post'    THEN (SELECT p.TITLE_NM FROM TPOST p WHERE p.POST_ID = r.TARGET_ID)
           WHEN 'comment' THEN (SELECT k.BODY_CTNT FROM TPOST_COMMENT k WHERE k.COMMENT_ID = r.TARGET_ID)
         END AS EXCERPT
    FROM TPOST_REPORT r LEFT JOIN TMEMBER m ON m.MBR_ID = r.MBR_ID
   WHERE r.STATUS_CD='pending' ORDER BY r.REPORT_ID LIMIT %s"""

SQL_FETCH_PENDING_REPORT = (
    "SELECT REPORT_ID, TARGET_TYPE_CD, TARGET_ID FROM TPOST_REPORT "
    "WHERE REPORT_ID=%s AND STATUS_CD='pending' FOR UPDATE"
)
# 같은 대상의 pending 전부 → actioned (hide). `AND STATUS_CD='pending'` 가드가 첫 결정을 보존한다.
SQL_ACTION_TARGET_REPORTS = (
    "UPDATE TPOST_REPORT SET STATUS_CD='actioned', DECIDED_BY_ID=%s, DECIDED_DTM=UTC_TIMESTAMP(), "
    "DECIDE_NOTE_CTNT=%s, MOD_ID=%s WHERE TARGET_TYPE_CD=%s AND TARGET_ID=%s AND STATUS_CD='pending'"
)
SQL_DISMISS_REPORT = (
    "UPDATE TPOST_REPORT SET STATUS_CD='dismissed', DECIDED_BY_ID=%s, DECIDED_DTM=UTC_TIMESTAMP(), "
    "DECIDE_NOTE_CTNT=%s, MOD_ID=%s WHERE REPORT_ID=%s AND STATUS_CD='pending'"
)


async def _target_is_active(target_type: str, target_id: int) -> bool:
    table, pk = _TARGET_TABLE[target_type], _TARGET_PK[target_type]
    return await database.fetch_one(
        f"SELECT {pk} FROM {table} WHERE {pk}=%s AND STATUS_CD='active'", (target_id,)
    ) is not None


async def create_report(mbr_id: int, payload) -> dict:
    """접수. 반환 result: ok(+report_id) / rate_limited(429) / target_not_found(404) / duplicate(409)."""
    if await post_svc.daily_count("TPOST_REPORT", mbr_id) >= get_settings().daily_report_limit:
        return {"result": "rate_limited"}
    if not await _target_is_active(payload.target_type, payload.target_id):
        return {"result": "target_not_found"}
    try:
        async with database.transaction() as conn:
            async with conn.cursor() as cur:
                await cur.execute(
                    "INSERT INTO TPOST_REPORT (TARGET_TYPE_CD, TARGET_ID, MBR_ID, REASON_CD, DETAIL_CTNT, INS_ID) "
                    "VALUES (%s, %s, %s, %s, %s, %s)",
                    (payload.target_type, payload.target_id, mbr_id, payload.reason, payload.detail, mbr_id),
                )
                report_id = cur.lastrowid
    except IntegrityError:  # uq_report_target_member — 같은 (회원, 대상) 중복
        return {"result": "duplicate"}
    return {"result": "ok", "report_id": report_id}


async def list_pending_reports(limit: int = 100) -> list[dict]:
    """콘솔 큐 항목 — 값은 그대로(서버는 HTML 을 만들지 않는다), 발췌만 80자로 자른다."""
    rows = await database.fetch_all(SQL_LIST_PENDING_REPORTS, (limit,))
    return [
        {
            "report_id": r["REPORT_ID"], "target_type": r["TARGET_TYPE_CD"], "target_id": r["TARGET_ID"],
            "excerpt": (r["EXCERPT"] or "")[:EXCERPT_LEN], "reason": r["REASON_CD"], "detail": r["DETAIL_CTNT"],
            "reporter_nickname": r["NICKNAME_NM"] or post_svc.WITHDRAWN_NICK, "created_at": str(r["INS_DTM"]),
        }
        for r in rows
    ]


async def decide_report(report_id: int, action: str, decided_by: int, note: str | None) -> str:
    """처리. 반환: hidden / dismissed / not_pending.

    `hide`: 대상 `STATUS_CD='hidden'`(active 일 때만 — 이미 deleted 면 그대로 둔다) + 같은 대상의
    pending 신고 전부 actioned. `dismiss`: 이 신고만 dismissed, 대상 불변. 둘 다 한 트랜잭션."""
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(SQL_FETCH_PENDING_REPORT, (report_id,))
            rep = await cur.fetchone()
            if not rep:
                return "not_pending"
            if action == "hide":
                ttype, tid = rep["TARGET_TYPE_CD"], rep["TARGET_ID"]
                table, pk = _TARGET_TABLE[ttype], _TARGET_PK[ttype]
                await cur.execute(
                    f"UPDATE {table} SET STATUS_CD='hidden', MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() "
                    f"WHERE {pk}=%s AND STATUS_CD='active'",
                    (decided_by, tid),
                )
                await cur.execute(SQL_ACTION_TARGET_REPORTS, (decided_by, note, decided_by, ttype, tid))
                return "hidden"
            await cur.execute(SQL_DISMISS_REPORT, (decided_by, note, decided_by, report_id))
            return "dismissed"


# ── 게시판 직접 숨김·복구 (SP-AUTH-19.7, 2026-09-18) ──────────────────────────────
#
# 신고 없이도 운영자가 게시판 화면에서 글·댓글을 숨기고 되살린다. **신고 처리의 hide 와 같은 SQL
# 모양·같은 감사 방식**이다: 대상 `STATUS_CD` 한 줄 + `MOD_ID`·`MOD_DTM`(결정자 = 세션의 운영자),
# 숨길 때는 같은 대상의 pending 신고도 `actioned` 로 닫는다(안 닫으면 숨긴 글이 신고 큐에 남아
# 두 번 처리하게 된다). 카운터(`COMMENT_CNT` 등)는 손대지 않는다 — 운영자 hidden 은 카운터 불변
# 규약(SP-DB-18)이라 복구도 카운터를 되돌릴 필요가 없다.
#
# 되돌릴 수 있는 것만(SP-AUTH-19.4): 하드 삭제 없음. 복구는 **hidden → active 만** 한다 —
# `deleted` 는 작성자 본인의 결정이고 본문이 이미 마스킹돼(원문 보존 안 함) 되살릴 것도 없다.
#
# ⚠ 감사의 한계(정직 서술): `MOD_ID` 는 **마지막** 조작자만 남는다. 숨김→복구를 거치면 숨긴
#   사람은 행에서 지워진다. 그래서 조작마다 로그 한 줄(식별자만, 원문·메모 없음)을 남긴다 —
#   전체 이력은 journald 에 있다. 이력 테이블이 필요해지면 그때 스키마로 옮긴다.

SQL_LOCK_TARGET = {
    "post": "SELECT POST_ID, STATUS_CD FROM TPOST WHERE POST_ID=%s FOR UPDATE",
    "comment": "SELECT COMMENT_ID, STATUS_CD FROM TPOST_COMMENT WHERE COMMENT_ID=%s FOR UPDATE",
}
SQL_SET_TARGET_STATUS = {
    "post": ("UPDATE TPOST SET STATUS_CD=%s, MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() "
             "WHERE POST_ID=%s AND STATUS_CD=%s"),
    "comment": ("UPDATE TPOST_COMMENT SET STATUS_CD=%s, MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() "
                "WHERE COMMENT_ID=%s AND STATUS_CD=%s"),
}
#: 조작 → (지금 상태여야 하는 값, 바꿀 값, 결과 코드)
_VISIBILITY = {"hide": ("active", "hidden", "hidden"), "restore": ("hidden", "active", "restored")}
VISIBILITY_ACTIONS = frozenset(_VISIBILITY)


async def set_visibility(target_type: str, target_id: int, action: str, decided_by: int, note: str | None) -> dict:
    """글·댓글 숨김/복구. 반환 result: hidden / restored / not_found / not_active / not_hidden.

    대상 행을 `FOR UPDATE` 로 잠근 뒤 판정하고 바꾼다 — 신고 처리(`decide_report`)가 같은 대상을
    동시에 숨기는 경우에도 한쪽만 상태를 바꾼다(`AND STATUS_CD=%s` 가드).
    ⚠ 잠금 순서가 신고 처리와 반대다(여기: 대상→신고 행 / 신고 처리: 신고 행→대상). 둘이 정확히 동시에
      돌면 InnoDB 가 교착(1213)을 감지해 한쪽을 되돌린다 — 라우터가 그것을 409 `busy` 로 바꾼다
      (`routers/console._LOCK_CONFLICT`). 순서를 맞추는 대신 이렇게 한 이유: 신고 행 여럿의 잠금 순서는
      인덱스 스캔 순서라 호출부에서 보장할 수 없다."""
    from_status, to_status, result = _VISIBILITY[action]
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(SQL_LOCK_TARGET[target_type], (target_id,))
            row = await cur.fetchone()
            if not row:
                return {"result": "not_found"}
            if row["STATUS_CD"] != from_status:
                return {"result": "not_active" if action == "hide" else "not_hidden", "status": row["STATUS_CD"]}
            await cur.execute(SQL_SET_TARGET_STATUS[target_type], (to_status, decided_by, target_id, from_status))
            actioned = 0
            if action == "hide":
                await cur.execute(SQL_ACTION_TARGET_REPORTS, (decided_by, note, decided_by, target_type, target_id))
                actioned = cur.rowcount or 0
    logger.info("console %s %s#%d by MBR %d (pending reports closed: %d)",
                action, target_type, target_id, decided_by, actioned)
    return {"result": result, "reports_actioned": actioned}
