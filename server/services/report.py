"""SP-COMM-6 신고 서비스 — 접수·콘솔 큐·처리 (FR-130·131).

- 접수는 대상을 바꾸지 않는다(자동 숨김 없음). 대상 존재·`active` 확인은 접수 시 여기서 한다 —
  `TARGET_ID` 는 두 테이블을 가리키므로 FK 가 없다(SP-DB-18).
- 같은 (회원, 대상) 중복은 UNIQUE 충돌 → `duplicate`(라우터가 409).
- 처리(`hide`/`dismiss`)는 콘솔에서만, `decided_by` 는 **세션에서** 온다(SP-AUTH-19 와 동일 — 기본값 없음).
  `hide` 는 대상을 `hidden` 으로 바꾸고 같은 대상의 다른 pending 신고를 일괄 `actioned` 로.
  되돌릴 수 있는 것만(SP-AUTH-19.4): 하드 삭제 없음. 카운터(`COMMENT_CNT` 등)는 손대지 않는다.
"""
from __future__ import annotations

from pymysql.err import IntegrityError

from server import database
from server.config import get_settings
from server.services import post as post_svc

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
