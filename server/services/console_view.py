"""SP-AUTH-19.7 운영 콘솔 조회 — 현황·회원·게시판·복지 수정 이력 (읽기 전용).

콘솔 라우터(`routers/console.py`)만 부른다. 그 라우터는 노출 범위 관문(`require_console_access`)과
운영자 관문(`require_operator`) 뒤에 있으므로, 여기서 돌려주는 **회원 로그인 이메일**은 운영자
화면 밖으로 나가지 않는다. 공개 라우터가 이 모듈을 import 하면 그 계약이 깨진다 — 이메일이 담긴
응답은 이 파일과 콘솔 라우터 사이에만 있어야 한다(test_console_views_db 가 경계를 잰다).

규칙 셋:
- **값은 가공하지 않는다.** 닉네임·제목·본문·편집 메모는 사용자 입력 원문이고, 서버가 HTML 을
  만들거나 이스케이프하지 않는다 — 표시는 콘솔 페이지가 노드 조립(`textContent`)으로만 한다
  (큐 응답 CF-8 과 같은 규약). 발췌만 길이를 자른다.
- **키셋 페이징**(`before=<PK>` · `LIMIT n+1` 로 다음 커서 판정) — 커뮤니티 목록(SP-COMM-4)과 같은
  관례다. 오프셋은 새 행이 들어오면 페이지 경계가 밀려 같은 행을 두 번 보거나 건너뛴다.
- 시각은 DB 세션 시간대(=UTC, 서버 `Etc/UTC`) 문자열 그대로 싣는다. KST 변환은 화면이 한다.
"""
from __future__ import annotations

import json

from server import database
from server.services import post as post_svc

EXCERPT_LEN = 120  # 게시판 발췌 — 한 줄에서 무엇인지 알아볼 만큼만(원문 전체는 커뮤니티 상세에 있다)
WITHDRAWN_EDITOR = "(탈퇴)"  # 편집 이력 공개 조회(benefit_edit._SQL_EDITS)와 같은 표기

#: 게시판 상태 필터 허용값 — `TPOST`·`TPOST_COMMENT.STATUS_CD` 값집합(SP-DB-18.5)과 같다.
BOARD_STATUSES = ("active", "hidden", "deleted")


def _dt(v) -> str | None:
    return None if v is None else str(v)


def _parse_json(v):
    """JSON 컬럼(문자열·이미 파싱된 값·None) → 파이썬 값. 깨진 값은 None(화면 하나 때문에 500 을 내지 않는다)."""
    if v is None or isinstance(v, (dict, list)):
        return v
    try:
        return json.loads(v)
    except (ValueError, TypeError):
        return None


def _page(rows: list[dict], limit: int, key: str) -> tuple[list[dict], int | None]:
    """`LIMIT n+1` 로 읽은 행 → (이번 페이지, 다음 커서). 더 없으면 커서는 None."""
    has_more = len(rows) > limit
    rows = rows[:limit]
    return rows, (rows[-1][key] if has_more and rows else None)


# ── 현황 ──────────────────────────────────────────────────────────────────────
#
# 한 문장·스칼라 서브쿼리 묶음 — 왕복 1회. 표가 작아(회원 수 명, 글 수십) 인덱스 없는 COUNT 도
# 싸다. 기간 경계는 `UTC_TIMESTAMP() - INTERVAL` — 복지 편집 일일 상한(`_daily_count`)과 같은 관례.
SQL_OVERVIEW = """
  SELECT
    (SELECT COUNT(*) FROM TMEMBER)                                                        AS members_total,
    (SELECT COUNT(*) FROM TMEMBER WHERE STATUS_CD='active')                               AS members_active,
    (SELECT COUNT(*) FROM TMEMBER WHERE INS_DTM >= UTC_TIMESTAMP() - INTERVAL 7 DAY)      AS members_new_7d,
    (SELECT COUNT(*) FROM TMEMBER WHERE INS_DTM >= UTC_TIMESTAMP() - INTERVAL 30 DAY)     AS members_new_30d,
    (SELECT COUNT(*) FROM TEMPLOY_VERIFICATION WHERE REVOKED_DTM IS NULL
        AND (EXPIRES_DTM IS NULL OR EXPIRES_DTM > UTC_TIMESTAMP()))                       AS vrf_active,
    (SELECT COUNT(*) FROM TEMPLOY_VRF_REQUEST WHERE STATUS_CD='pending')                  AS vrf_pending,
    (SELECT COUNT(*) FROM TCOMPANY_REQUEST WHERE STATUS_CD='pending')                     AS comp_req_pending,
    (SELECT COUNT(*) FROM TCOMPANY_REQUEST WHERE STATUS_CD<>'pending')                    AS comp_req_decided,
    (SELECT COUNT(*) FROM TPOST)                                                          AS posts_total,
    (SELECT COUNT(*) FROM TPOST WHERE INS_DTM >= UTC_TIMESTAMP() - INTERVAL 7 DAY)        AS posts_7d,
    (SELECT COUNT(*) FROM TPOST WHERE STATUS_CD='hidden')                                 AS posts_hidden,
    (SELECT COUNT(*) FROM TPOST_COMMENT)                                                  AS comments_total,
    (SELECT COUNT(*) FROM TPOST_COMMENT WHERE INS_DTM >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS comments_7d,
    (SELECT COUNT(*) FROM TPOST_COMMENT WHERE STATUS_CD='hidden')                         AS comments_hidden,
    (SELECT COUNT(*) FROM TPOST_REPORT WHERE STATUS_CD='pending')                         AS reports_pending,
    (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG)                                              AS edits_total,
    (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG WHERE INS_DTM >= UTC_TIMESTAMP() - INTERVAL 30 DAY) AS edits_30d,
    (SELECT COUNT(*) FROM TMAIL_SUPPRESSION WHERE RELEASED_DTM IS NULL)                   AS suppressed_active,
    UTC_TIMESTAMP()                                                                       AS as_of"""


async def overview() -> dict:
    """현황 숫자 묶음 — 건수만(사용자 입력·식별자 0). `as_of` 는 집계 시각(UTC)."""
    r = await database.fetch_one(SQL_OVERVIEW)
    as_of = r.pop("as_of")
    return {
        "as_of": _dt(as_of),
        "members": {"total": r["members_total"], "active": r["members_active"],
                    "new_7d": r["members_new_7d"], "new_30d": r["members_new_30d"]},
        "verifications": {"active": r["vrf_active"], "pending": r["vrf_pending"]},
        "company_requests": {"pending": r["comp_req_pending"], "decided": r["comp_req_decided"]},
        "posts": {"total": r["posts_total"], "new_7d": r["posts_7d"], "hidden": r["posts_hidden"]},
        "comments": {"total": r["comments_total"], "new_7d": r["comments_7d"], "hidden": r["comments_hidden"]},
        "reports": {"pending": r["reports_pending"]},
        "benefit_edits": {"total": r["edits_total"], "new_30d": r["edits_30d"]},
        "mail_suppression": {"active": r["suppressed_active"]},
    }


# ── 회원 ──────────────────────────────────────────────────────────────────────
#
# 「마지막 로그인」 컬럼은 스키마에 없다. 로그인 = 세션 발급이므로 `MAX(TSESSION.INS_DTM)` 으로
# 대신한다. ⚠ 만료·폐기 세션은 보존 퍼지(`session.purge_expired`, 일 1회)가 지우므로 이 값은
# **보존 중인 세션 기준**이다 — 30일(세션 TTL) 넘게 안 들어온 회원은 NULL 이 되고, 로그아웃한
# 회원은 다음 퍼지 전까지만 보인다. 화면이 그 뜻을 그대로 적는다(「최근 세션」).
SQL_MEMBERS = """
  SELECT m.MBR_ID, m.NICKNAME_NM, m.LOGIN_EMAIL_NM, m.STATUS_CD, m.INS_DTM,
         (SELECT MAX(s.INS_DTM) FROM TSESSION s WHERE s.MBR_ID = m.MBR_ID) AS LAST_SESSION_DTM
    FROM TMEMBER m"""

# 한 페이지 회원들의 재직 인증(활성·만료·폐기 전부)과 대기 중 수동 승인 요청 — IN 목록 한 번씩
# (회원마다 조회하면 N+1). 회사가 지워졌으면(`ON DELETE SET NULL`) 이름이 NULL 이다.
# 도메인 인증은 로그인 이메일이 아니라 **회사 메일**로 코드를 받아 통과한 것이다 — 그런데 회사 메일은
# HMAC 만 남아(T9) 화면에는 로그인 이메일만 보이고, 「네이버 가입자가 회사 인증됐다」는 오해를 낳았다
# (2026-09-22). 그래서 그 회사의 **등록 도메인**(인증 때 통과해야 했던 목록)을 함께 싣는다. ⚠ 지금 등록된
# 활성 도메인이다 — 인증 뒤 도메인이 바뀌었을 수 있고, 여러 개면 어느 것을 썼는지는 알 수 없다.
SQL_MEMBER_VERIFICATIONS = """
  SELECT v.MBR_ID, v.COMP_ID, c.COMP_NM, v.VRF_METHOD_CD, v.INS_DTM,
         CASE WHEN v.REVOKED_DTM IS NOT NULL THEN 'revoked'
              WHEN v.EXPIRES_DTM IS NOT NULL AND v.EXPIRES_DTM <= UTC_TIMESTAMP() THEN 'expired'
              ELSE 'active' END AS STATE,
         (SELECT GROUP_CONCAT(d.EMAIL_DOMAIN_NM ORDER BY d.EMAIL_DOMAIN_NM SEPARATOR ',')
            FROM TCOMPANY_EMAIL_DOMAIN d WHERE d.COMP_ID = v.COMP_ID AND d.ACTIVE_YN = TRUE) AS DOMAINS
    FROM TEMPLOY_VERIFICATION v LEFT JOIN TCOMPANY c ON c.COMP_ID = v.COMP_ID
   WHERE v.MBR_ID IN ({ids}) ORDER BY v.EMPLOY_VRF_ID DESC"""
SQL_MEMBER_PENDING_REQUESTS = """
  SELECT r.MBR_ID, r.COMP_ID, c.COMP_NM, r.INS_DTM
    FROM TEMPLOY_VRF_REQUEST r LEFT JOIN TCOMPANY c ON c.COMP_ID = r.COMP_ID
   WHERE r.MBR_ID IN ({ids}) AND r.STATUS_CD='pending' ORDER BY r.VRF_REQUEST_ID DESC"""


async def list_members(limit: int, before: int | None) -> tuple[list[dict], int | None]:
    """회원 최신순(MBR_ID DESC). ⚠ 로그인 이메일이 담긴다 — 운영자 응답 전용."""
    sql, params = SQL_MEMBERS, []
    if before is not None:
        sql += " WHERE m.MBR_ID < %s"
        params.append(before)
    sql += " ORDER BY m.MBR_ID DESC LIMIT %s"
    params.append(limit + 1)
    rows, next_before = _page(await database.fetch_all(sql, tuple(params)), limit, "MBR_ID")

    by_member: dict[int, list[dict]] = {r["MBR_ID"]: [] for r in rows}
    if by_member:
        ids = tuple(by_member)
        marks = ",".join(["%s"] * len(ids))
        for v in await database.fetch_all(SQL_MEMBER_VERIFICATIONS.format(ids=marks), ids):
            by_member[v["MBR_ID"]].append({
                "company": v["COMP_NM"], "company_id": v["COMP_ID"],
                "method": v["VRF_METHOD_CD"], "state": v["STATE"], "since": _dt(v["INS_DTM"]),
                # 수동 승인은 메일을 거치지 않았다 — 도메인을 붙이면 메일로 확인한 것처럼 읽힌다.
                "domains": v["DOMAINS"].split(",") if v["VRF_METHOD_CD"] == "domain" and v["DOMAINS"] else [],
            })
        for q in await database.fetch_all(SQL_MEMBER_PENDING_REQUESTS.format(ids=marks), ids):
            by_member[q["MBR_ID"]].append({"company": q["COMP_NM"], "company_id": q["COMP_ID"],
                                           "method": "manual", "state": "pending", "since": _dt(q["INS_DTM"]),
                                           "domains": []})
    items = [
        {
            "member_id": r["MBR_ID"], "nickname": r["NICKNAME_NM"],
            # 탈퇴하면 이메일은 NULL 로 파기된다(INV-8) — 없는 값을 지어내지 않는다.
            "email": r["LOGIN_EMAIL_NM"], "status": r["STATUS_CD"],
            "joined_at": _dt(r["INS_DTM"]), "last_session_at": _dt(r["LAST_SESSION_DTM"]),
            "verifications": by_member[r["MBR_ID"]],
        }
        for r in rows
    ]
    return items, next_before


# ── 게시판(글·댓글) ────────────────────────────────────────────────────────────
#
# 공개 목록과 달리 **상태를 가리지 않는다**(active·hidden·deleted 전부) — 운영자는 숨긴 것을 다시
# 찾아 복구할 수 있어야 한다. 신고 수는 전체·대기 두 가지(대기가 곧 할 일이다). 서브쿼리는
# `uq_report_target_member(TARGET_TYPE_CD, TARGET_ID, …)` 앞부분을 탄다.
# 조치 이력(`TPOST_ACTION_LOG`)은 건수 + 마지막 1건(누가·언제·무엇·메모)만 싣는다 — 대상 행의 `MOD_ID` 는
# 마지막 조작자만 남아 "누가 숨겼나"를 복구 뒤에 잃는다. 인덱스 `idx_action_target` 을 탄다.
# (`%%` 는 pymysql 바인딩 포맷의 이스케이프 — DATE_FORMAT 의 `%Y` 가 바인딩 자리로 읽히지 않게.)
_SQL_REPORT_COUNTS = """
         (SELECT COUNT(*) FROM TPOST_REPORT r
           WHERE r.TARGET_TYPE_CD='{t}' AND r.TARGET_ID={pk}) AS REPORT_CNT,
         (SELECT COUNT(*) FROM TPOST_REPORT r
           WHERE r.TARGET_TYPE_CD='{t}' AND r.TARGET_ID={pk} AND r.STATUS_CD='pending') AS REPORT_PENDING_CNT,
         (SELECT COUNT(*) FROM TPOST_ACTION_LOG a
           WHERE a.TARGET_TYPE_CD='{t}' AND a.TARGET_ID={pk}) AS ACTION_CNT,
         (SELECT JSON_OBJECT('action', a.ACTION_CD, 'source', a.SOURCE_CD, 'actor_id', a.ACTOR_MBR_ID,
                             'note', a.NOTE_CTNT, 'at', DATE_FORMAT(a.INS_DTM, '%%Y-%%m-%%d %%H:%%i:%%s'))
            FROM TPOST_ACTION_LOG a WHERE a.TARGET_TYPE_CD='{t}' AND a.TARGET_ID={pk}
           ORDER BY a.ACTION_LOG_ID DESC LIMIT 1) AS LAST_ACTION"""

SQL_BOARD_POSTS = f"""
  SELECT p.POST_ID, p.CATEGORY_CD, p.TITLE_NM, LEFT(p.BODY_CTNT, {EXCERPT_LEN}) AS EXCERPT, p.STATUS_CD,
         p.INS_DTM, p.MBR_ID, COALESCE(m.NICKNAME_NM, %s) AS NICKNAME, p.COMMENT_CNT, p.LIKE_CNT,
         p.MOD_ID, p.MOD_DTM,{_SQL_REPORT_COUNTS.format(t='post', pk='p.POST_ID')}
    FROM TPOST p LEFT JOIN TMEMBER m ON m.MBR_ID = p.MBR_ID
   WHERE 1=1"""

SQL_BOARD_COMMENTS = f"""
  SELECT k.COMMENT_ID, k.POST_ID, p.TITLE_NM AS POST_TITLE, LEFT(k.BODY_CTNT, {EXCERPT_LEN}) AS EXCERPT,
         k.STATUS_CD, k.INS_DTM, k.MBR_ID, COALESCE(m.NICKNAME_NM, %s) AS NICKNAME,
         k.MOD_ID, k.MOD_DTM,{_SQL_REPORT_COUNTS.format(t='comment', pk='k.COMMENT_ID')}
    FROM TPOST_COMMENT k JOIN TPOST p ON p.POST_ID = k.POST_ID
    LEFT JOIN TMEMBER m ON m.MBR_ID = k.MBR_ID
   WHERE 1=1"""


async def list_posts(limit: int, before: int | None, status: str | None) -> tuple[list[dict], int | None]:
    sql, params = SQL_BOARD_POSTS, [post_svc.WITHDRAWN_NICK]
    if status is not None:
        sql += " AND p.STATUS_CD=%s"
        params.append(status)
    if before is not None:
        sql += " AND p.POST_ID < %s"
        params.append(before)
    sql += " ORDER BY p.POST_ID DESC LIMIT %s"
    params.append(limit + 1)
    rows, next_before = _page(await database.fetch_all(sql, tuple(params)), limit, "POST_ID")
    return [
        {
            "post_id": r["POST_ID"], "category": r["CATEGORY_CD"], "title": r["TITLE_NM"],
            "excerpt": r["EXCERPT"], "status": r["STATUS_CD"], "created_at": _dt(r["INS_DTM"]),
            "member_id": r["MBR_ID"], "nickname": r["NICKNAME"],
            "comment_cnt": r["COMMENT_CNT"], "like_cnt": r["LIKE_CNT"],
            "report_cnt": r["REPORT_CNT"], "report_pending_cnt": r["REPORT_PENDING_CNT"],
            "modified_by": r["MOD_ID"], "modified_at": _dt(r["MOD_DTM"]),
            "action_cnt": r["ACTION_CNT"], "last_action": _parse_json(r["LAST_ACTION"]),
        }
        for r in rows
    ], next_before


async def list_comments(limit: int, before: int | None, status: str | None) -> tuple[list[dict], int | None]:
    sql, params = SQL_BOARD_COMMENTS, [post_svc.WITHDRAWN_NICK]
    if status is not None:
        sql += " AND k.STATUS_CD=%s"
        params.append(status)
    if before is not None:
        sql += " AND k.COMMENT_ID < %s"
        params.append(before)
    sql += " ORDER BY k.COMMENT_ID DESC LIMIT %s"
    params.append(limit + 1)
    rows, next_before = _page(await database.fetch_all(sql, tuple(params)), limit, "COMMENT_ID")
    return [
        {
            "comment_id": r["COMMENT_ID"], "post_id": r["POST_ID"], "post_title": r["POST_TITLE"],
            "excerpt": r["EXCERPT"], "status": r["STATUS_CD"], "created_at": _dt(r["INS_DTM"]),
            "member_id": r["MBR_ID"], "nickname": r["NICKNAME"],
            "report_cnt": r["REPORT_CNT"], "report_pending_cnt": r["REPORT_PENDING_CNT"],
            "modified_by": r["MOD_ID"], "modified_at": _dt(r["MOD_DTM"]),
            "action_cnt": r["ACTION_CNT"], "last_action": _parse_json(r["LAST_ACTION"]),
        }
        for r in rows
    ], next_before


# ── 복지 수정 이력 ────────────────────────────────────────────────────────────
#
# 공개 이력(`benefit_edit.list_edits`)은 회사 하나·닉네임만이다. 콘솔은 **전 회사 횡단**이고
# 편집자 `MBR_ID` 를 함께 싣는다 — 회원 탭과 이어 보려면 식별자가 필요하다(운영자 전용 응답).
# `COMP_ID` 에는 FK 가 없어(이력 존치 규약) 회사가 사라졌으면 이름이 NULL 이다.
SQL_BENEFIT_EDITS = """
  SELECT l.EDIT_LOG_ID, l.COMP_ID, c.COMP_NM, l.BENEFIT_ID, l.ACTOR_MBR_ID,
         COALESCE(m.NICKNAME_NM, %s) AS NICKNAME, l.EDIT_TYPE_CD,
         l.BEFORE_VAL, l.AFTER_VAL, l.EDIT_NOTE_CTNT, l.INS_DTM
    FROM TBENEFIT_EDIT_LOG l
    LEFT JOIN TCOMPANY c ON c.COMP_ID = l.COMP_ID
    LEFT JOIN TMEMBER m ON m.MBR_ID = l.ACTOR_MBR_ID
   WHERE 1=1"""


async def list_benefit_edits(limit: int, before: int | None) -> tuple[list[dict], int | None]:
    """읽기 전용 — 되돌리기는 이번 범위가 아니다(SP-AUTH-19.4: 콘솔은 되돌릴 수 있는 조작만)."""
    sql, params = SQL_BENEFIT_EDITS, [WITHDRAWN_EDITOR]
    if before is not None:
        sql += " AND l.EDIT_LOG_ID < %s"
        params.append(before)
    sql += " ORDER BY l.EDIT_LOG_ID DESC LIMIT %s"
    params.append(limit + 1)
    rows, next_before = _page(await database.fetch_all(sql, tuple(params)), limit, "EDIT_LOG_ID")
    items = []
    for r in rows:
        before_val, after_val = _parse_json(r["BEFORE_VAL"]), _parse_json(r["AFTER_VAL"])
        snap = after_val if isinstance(after_val, dict) else before_val if isinstance(before_val, dict) else {}
        items.append({
            "edit_id": r["EDIT_LOG_ID"], "company_id": r["COMP_ID"], "company": r["COMP_NM"],
            "benefit_id": r["BENEFIT_ID"], "benefit_cd": snap.get("benefit_cd"),
            "benefit_nm": snap.get("benefit_nm"), "edit_type": r["EDIT_TYPE_CD"],
            "before": before_val, "after": after_val, "note": r["EDIT_NOTE_CTNT"],
            "editor_id": r["ACTOR_MBR_ID"], "editor_nickname": r["NICKNAME"],
            "at": _dt(r["INS_DTM"]),
        })
    return items, next_before
