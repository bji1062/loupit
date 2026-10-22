"""SP-AUTH-9 복지 편집 서비스 — 확인 요청 큐 · 배지 서버 강제 · 낙관적 동시성 · 본체+이력 원자 트랜잭션.

**회원의 등록·수정은 바로 반영되지 않는다**(2026-10-21 사용자 결정). 회원 쓰기는 `TBENEFIT_EDIT_REQUEST` 에
요청 한 줄을 만들 뿐이고(`create_request`·`update_request`, 본체·이력 무접촉), 운영자가 콘솔에서 승인할 때
`approve_request` 가 본체 INSERT/UPDATE 와 편집 이력 INSERT(TBENEFIT_EDIT_LOG)를 **한 트랜잭션**으로 원자화한다.
`TCOMPANY_BENEFIT` 에 상태 칸을 넣지 않은 이유: 그 표를 읽는 곳(참조 번들·정적 생성·히트맵·적재·백필)이 전부
걸러야 해서 하나만 빠뜨려도 대기 건이 공개된다 — 큐를 별도 표로 두면 승인 전에는 공개 경로가 보지 못한다.

- 배지 강제(승인 때): `BADGE_CD='verified'`(재직자 확인)·`BADGE_SRC_CD='user_report'`·`EXPIRES_DTM=+18개월`.
  이력의 편집자(ACTOR)는 **요청한 회원**이다(운영자는 결정자로 요청 행에만 남는다).
- 금액출처 분기(DC-9·DC-10, INV-5): 금액 행 `AMT_SOURCE_CD='estimated'`, 정성 행 `none`(금액 NULL).
- 낙관적 동시성: 버전 컬럼 없이 `MOD_DTM`(없으면 `INS_DTM`) 토큰 비교 — 제출 때 불일치 시 409(현재 행 동봉),
  승인 때 제출 때 토큰과 다르면 `stale`(운영자는 거절로 처리).
- 밴드·계산 무변경(INV-5): `AMT_SOURCE_CD`가 밴드를 정하고 `BADGE_CD`는 표시 전용 — calc.js 무변경.

신규 의존성 0(stdlib json).
"""
from __future__ import annotations

import hashlib
import json

from pymysql.err import IntegrityError

from server import database
from server.config import get_settings
from server.models.reference import Benefit
from server.services import reference

# 편집 이력 스냅샷 필드 — 사용자 편집 의미가 있는 필드만(내부 PK·시각·출처 URL 제외).
# 시각 컬럼(verified_dtm/expires_dtm/INS/MOD)은 datetime 이라 JSON 직렬화 불가 + 편집 diff 무의미 → 제외.
_SNAPSHOT_KEYS = (
    "benefit_cd", "benefit_nm", "benefit_ctgr_cd", "benefit_amt",
    "qual_yn", "note_ctnt", "badge_cd", "amt_source",
)

# 단일 행 재조회(토큰용 INS_DTM·MOD_DTM 포함) — 삽입·갱신 직후 응답 조립용.
_SQL_ROW = """
  SELECT BENEFIT_ID, BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm, BENEFIT_AMT AS benefit_amt,
         BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd, AMT_SOURCE_CD AS amt_source,
         QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt, NOTE_CTNT AS note_ctnt,
         VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm, BADGE_SRC_CD AS badge_src_cd,
         BADGE_SRC_URL_CTNT AS badge_src_url_ctnt, SORT_ORDER_NO AS sort_order_no, INS_DTM, MOD_DTM
    FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s"""

# 회사 복지 목록(편집용 투영) — 각 행에 base_dtm(낙관동시성 토큰)·benefit_id(PUT 대상)를 실으려
# BENEFIT_ID·INS_DTM·MOD_DTM 포함. 이 투영은 인증·no-store 편집 경로 전용(공개 목록 아님).
_SQL_LIST = """
  SELECT BENEFIT_ID, BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm, BENEFIT_AMT AS benefit_amt,
         BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd, AMT_SOURCE_CD AS amt_source,
         QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt, NOTE_CTNT AS note_ctnt,
         VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm, BADGE_SRC_CD AS badge_src_cd,
         BADGE_SRC_URL_CTNT AS badge_src_url_ctnt, SORT_ORDER_NO AS sort_order_no, INS_DTM, MOD_DTM
    FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s ORDER BY SORT_ORDER_NO, BENEFIT_ID"""

# 편집 이력 공개 조회(닉네임 조인·최신순·커서 페이지네이션). 편집자 이메일·MBR_ID 미노출(INV-8).
_SQL_EDITS = """
  SELECT l.EDIT_LOG_ID AS edit_id,
         CASE WHEN l.ACTOR_KIND_CD = 'operator' THEN '운영자' ELSE COALESCE(m.NICKNAME_NM, '(탈퇴)') END AS nickname,
         l.ACTOR_KIND_CD AS actor_kind, l.EDIT_TYPE_CD AS edit_type,
         l.BEFORE_VAL AS before_val, l.AFTER_VAL AS after_val, l.EDIT_NOTE_CTNT AS edit_note,
         l.INS_DTM AS dtm
    FROM TBENEFIT_EDIT_LOG l LEFT JOIN TMEMBER m ON m.MBR_ID = l.ACTOR_MBR_ID
   WHERE l.COMP_ID=%s"""


# 낙관적 동시성 토큰 지문에 넣는 가변 내용 필드(이 값이 바뀌면 토큰이 바뀐다).
_FINGERPRINT_KEYS = ("benefit_nm", "benefit_amt", "qual_yn", "amt_source", "note_ctnt", "badge_cd")


def _content_fingerprint(row: dict) -> str:
    """가변 내용의 짧은 해시 — 같은 초(TIMESTAMP 초 해상도) 편집도 내용이 다르면 토큰이 달라져 lost-update 차단."""
    parts = "|".join(f"{row.get(k)!r}" for k in _FINGERPRINT_KEYS)
    return hashlib.sha256(parts.encode()).hexdigest()[:12]


def _version_token(row: dict) -> str:
    """낙관적 동시성 토큰 = `MOD_DTM|INS_DTM ISO`:`내용 지문`.

    스펙의 MOD_DTM 낙관적 동시성(버전 컬럼 없음)을 따르되, TIMESTAMP 초 해상도로 같은 초에
    발생하는 선점 수정을 놓치는 한계를 내용 지문으로 보강한다(스키마 변경 없이 강한 CAS)."""
    dtm = row.get("MOD_DTM") or row.get("INS_DTM")
    dtm_iso = dtm.isoformat() if hasattr(dtm, "isoformat") else str(dtm)
    return f"{dtm_iso}:{_content_fingerprint(row)}"


def _snapshot(row: dict) -> dict:
    """편집 이력(before/after)용 핵심 복지 필드 스냅샷 — 사용자 편집 필드만(JSON 직렬화 안전)."""
    snap = {k: row.get(k) for k in _SNAPSHOT_KEYS}
    snap["qual_yn"] = bool(snap.get("qual_yn"))
    return snap


def _public_benefit(row: dict) -> dict:
    """편집 응답용 단일 복지 dict — 공개 계약 Benefit + 편집 전용 필드(base_dtm·benefit_id).

    base_dtm(낙관동시성 토큰)·benefit_id(PUT 대상 PK)는 인증·no-store 편집 경로에서만 노출된다.
    공개·캐시 경로(/reference·GET /companies/{id})는 reference 계층을 쓰므로 이 둘이 새지 않는다(§02 PK 비노출)."""
    d = Benefit(**reference._norm_benefit(dict(row))).model_dump()
    d["base_dtm"] = _version_token(row)
    d["benefit_id"] = row.get("BENEFIT_ID")
    return d


def _parse_json(v):
    """JSON 컬럼(문자열/이미 파싱된 값/None) → 파이썬 값. 실패 시 None."""
    if v is None or isinstance(v, (dict, list)):
        return v
    try:
        return json.loads(v)
    except (ValueError, TypeError):
        return None


async def _daily_count(mbr_id: int, comp_id: int) -> int:
    """최근 24시간 이 회원이 이 회사에 보낸 **요청 수**(일일 상한 게이트, FR-112).

    승인으로 생기는 이력 행은 세지 않는다 — 한도는 회원이 누르는 횟수를 막는 장치이고 운영자의 승인은 무관하다."""
    row = await database.fetch_one(
        "SELECT COUNT(*) AS n FROM TBENEFIT_EDIT_REQUEST "
        "WHERE MBR_ID=%s AND COMP_ID=%s AND INS_DTM > UTC_TIMESTAMP() - INTERVAL 1 DAY",
        (mbr_id, comp_id),
    )
    return int(row["n"]) if row else 0


async def fetch_company_benefits(comp_id: int) -> list[dict]:
    """회사 복지 목록(편집용 투영, 각 행 base_dtm 동봉) — 편집 응답 benefits[]·편집용 조회 공용.

    base_dtm(낙관동시성 토큰)은 편집자만 보는 인증·no-store 경로(create/update 응답·편집용 GET)로만
    노출된다 — 공개·캐시 가능한 GET /companies/{id} 상세엔 두지 않는다(캐시 stale→오탐 409 방지)."""
    rows = await database.fetch_all(_SQL_LIST, (comp_id,))
    return [_public_benefit(r) for r in rows]


# 요청 행 한 줄을 회원에게 돌려주는 모양 — 남의 요청은 절대 안 나간다(MBR_ID 로 걸러 조회한다).
def _request_summary(r: dict) -> dict:
    return {
        "request_id": r["EDIT_REQUEST_ID"], "type": r["REQ_TYPE_CD"], "status": r["STATUS_CD"],
        "benefit_nm": r["BENEFIT_NM"], "benefit_id": r["BENEFIT_ID"], "benefit_cd": r["BENEFIT_CD"],
        "decide_note": r["DECIDE_NOTE_CTNT"] if r["STATUS_CD"] == "rejected" else None,
        "at": r["INS_DTM"].isoformat() if hasattr(r["INS_DTM"], "isoformat") else str(r["INS_DTM"]),
        "decided_at": (r["DECIDED_DTM"].isoformat() if hasattr(r["DECIDED_DTM"], "isoformat")
                       else (str(r["DECIDED_DTM"]) if r["DECIDED_DTM"] else None)),
    }


_SQL_MY_REQUESTS = """
  SELECT EDIT_REQUEST_ID, REQ_TYPE_CD, STATUS_CD, BENEFIT_NM, BENEFIT_ID, BENEFIT_CD, DECIDE_NOTE_CTNT,
         INS_DTM, DECIDED_DTM
    FROM TBENEFIT_EDIT_REQUEST
   WHERE MBR_ID=%s AND COMP_ID=%s
     AND (STATUS_CD='pending' OR DECIDED_DTM > UTC_TIMESTAMP() - INTERVAL 30 DAY)
   ORDER BY EDIT_REQUEST_ID DESC"""


async def list_my_requests(comp_id: int, mbr_id: int) -> list[dict]:
    """이 회원이 이 회사에 보낸 요청 — 대기 전부 + 최근 30일 결정분(유형·이름·상태·거절 사유·시각)."""
    rows = await database.fetch_all(_SQL_MY_REQUESTS, (mbr_id, comp_id))
    return [_request_summary(r) for r in rows]


async def _lock_member(cur, mbr_id: int) -> None:
    """같은 회원의 동시 제출을 직렬화한다(대기 중복 판정이 경합으로 뚫리지 않게). 행 하나를 잠글 뿐이다."""
    await cur.execute("SELECT MBR_ID FROM TMEMBER WHERE MBR_ID=%s FOR UPDATE", (mbr_id,))
    await cur.fetchone()


async def create_request(comp_id: int, mbr_id: int, payload, codes: dict[str, dict]) -> dict:
    """복지 등록 확인 요청 — 본체·이력은 건드리지 않는다.

    반환 result: ok(+request) / rate_limited(429) / unknown_code(422·표준 코드 밖) /
    duplicate(409·그 회사에 이미 있는 코드) / pending_exists(409·같은 대상 대기 중).
    `codes` = `benefit_codes.get_code_map` 결과(표준 코드 94종)."""
    cd = payload.benefit_cd
    if cd is not None and cd not in codes:
        return {"result": "unknown_code"}
    if await _daily_count(mbr_id, comp_id) >= get_settings().daily_edit_limit:
        return {"result": "rate_limited"}

    amt = None if payload.qual_yn else payload.benefit_amt
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await _lock_member(cur, mbr_id)
            if cd is not None:
                await cur.execute(
                    "SELECT 1 FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s", (comp_id, cd))
                if await cur.fetchone():
                    return {"result": "duplicate"}
            # 같은 대상 = 같은 회사 · 같은 코드. 코드가 없는 요청(목록에 없음)은 같은 이름으로 본다.
            await cur.execute(
                "SELECT 1 FROM TBENEFIT_EDIT_REQUEST WHERE MBR_ID=%s AND COMP_ID=%s AND REQ_TYPE_CD='create' "
                "AND STATUS_CD='pending' AND BENEFIT_CD <=> %s AND (%s IS NOT NULL OR BENEFIT_NM=%s)",
                (mbr_id, comp_id, cd, cd, payload.benefit_nm),
            )
            if await cur.fetchone():
                return {"result": "pending_exists"}
            await cur.execute(
                "INSERT INTO TBENEFIT_EDIT_REQUEST "
                "(COMP_ID, MBR_ID, REQ_TYPE_CD, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, QUAL_YN, NOTE_CTNT, "
                " EDIT_NOTE_CTNT, INS_ID) VALUES (%s, %s, 'create', %s, %s, %s, %s, %s, %s, %s)",
                (comp_id, mbr_id, cd, payload.benefit_nm, amt, payload.qual_yn, payload.note_ctnt,
                 payload.edit_note, mbr_id),
            )
            req_id = cur.lastrowid
    return {"result": "ok", "request": await _fetch_my_request(req_id, mbr_id)}


async def update_request(comp_id: int, benefit_id: int, mbr_id: int, payload) -> dict:
    """복지 수정 확인 요청 — 제출 때 토큰을 확인하고(불일치 409·현재 행 동봉) 요청만 만든다. 본체는 그대로.

    반환 result: ok(+request) / rate_limited(429) / not_found(404) / conflict(409·현재 행 동봉) /
    pending_exists(409·같은 항목에 이 회원의 대기 요청이 있음)."""
    if await _daily_count(mbr_id, comp_id) >= get_settings().daily_edit_limit:
        return {"result": "rate_limited"}

    amt = None if payload.qual_yn else payload.benefit_amt
    conflict_row = None
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await _lock_member(cur, mbr_id)
            await cur.execute(_SQL_ROW + " AND COMP_ID=%s", (benefit_id, comp_id))
            row = await cur.fetchone()
            if not row:
                return {"result": "not_found"}
            if _version_token(row) != payload.base_dtm:
                conflict_row = row  # 선점 수정 — 아무것도 쓰지 않는다
            else:
                await cur.execute(
                    "SELECT 1 FROM TBENEFIT_EDIT_REQUEST WHERE MBR_ID=%s AND BENEFIT_ID=%s "
                    "AND REQ_TYPE_CD='update' AND STATUS_CD='pending'", (mbr_id, benefit_id))
                if await cur.fetchone():
                    return {"result": "pending_exists"}
                await cur.execute(
                    "INSERT INTO TBENEFIT_EDIT_REQUEST "
                    "(COMP_ID, MBR_ID, REQ_TYPE_CD, BENEFIT_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, QUAL_YN, "
                    " NOTE_CTNT, EDIT_NOTE_CTNT, BASE_TOKEN_VAL, BEFORE_VAL, INS_ID) "
                    "VALUES (%s, %s, 'update', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                    (comp_id, mbr_id, benefit_id, row["benefit_cd"], payload.benefit_nm, amt, payload.qual_yn,
                     payload.note_ctnt, payload.edit_note, payload.base_dtm,
                     json.dumps(_snapshot(row), ensure_ascii=False), mbr_id),
                )
                req_id = cur.lastrowid
    if conflict_row is not None:
        return {"result": "conflict", "current_benefit": _public_benefit(conflict_row),
                "benefits": await fetch_company_benefits(comp_id)}
    return {"result": "ok", "request": await _fetch_my_request(req_id, mbr_id)}


async def _fetch_my_request(req_id: int, mbr_id: int) -> dict:
    row = await database.fetch_one(
        "SELECT EDIT_REQUEST_ID, REQ_TYPE_CD, STATUS_CD, BENEFIT_NM, BENEFIT_ID, BENEFIT_CD, DECIDE_NOTE_CTNT, "
        "INS_DTM, DECIDED_DTM FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s AND MBR_ID=%s",
        (req_id, mbr_id),
    )
    return _request_summary(row)


# ── 운영자 결정(콘솔) — 승인이 곧 본체 반영이다 ──────────────────────────────────────────

_SQL_LOCK_REQUEST = """
  SELECT EDIT_REQUEST_ID, COMP_ID, MBR_ID, REQ_TYPE_CD, BENEFIT_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT,
         QUAL_YN, NOTE_CTNT, EDIT_NOTE_CTNT, BASE_TOKEN_VAL, STATUS_CD
    FROM TBENEFIT_EDIT_REQUEST WHERE EDIT_REQUEST_ID=%s FOR UPDATE"""

_SQL_MARK_APPROVED = (
    "UPDATE TBENEFIT_EDIT_REQUEST SET STATUS_CD='approved', DECIDED_BY_ID=%s, DECIDED_DTM=UTC_TIMESTAMP(), "
    "DECIDE_NOTE_CTNT=%s, APPLIED_BENEFIT_CD=%s, RESULT_BENEFIT_ID=%s, EDIT_LOG_ID=%s, MOD_ID=%s "
    "WHERE EDIT_REQUEST_ID=%s AND STATUS_CD='pending'"
)
_SQL_MARK_REJECTED = (
    "UPDATE TBENEFIT_EDIT_REQUEST SET STATUS_CD='rejected', DECIDED_BY_ID=%s, DECIDED_DTM=UTC_TIMESTAMP(), "
    "DECIDE_NOTE_CTNT=%s, MOD_ID=%s WHERE EDIT_REQUEST_ID=%s AND STATUS_CD='pending'"
)


async def approve_request(req_id: int, decided_by: int, benefit_cd: str | None, note: str | None,
                          codes: dict[str, dict]) -> dict:
    """요청 승인 → 본체 반영 + 편집 이력(편집자 = 요청 회원) + 요청 approved 를 **한 트랜잭션**으로.

    `decided_by` 는 세션의 운영자 MBR_ID 다(요청 본문에서 받지 않는다 — 콘솔 규약).
    create 는 운영자가 고른 `benefit_cd`(표준 코드 안, 그 회사에 없음)가 필수이고 카테고리는 코드에서 정한다.
    update 는 대상 행을 잠그고 제출 때 토큰과 같을 때만 반영한다 — 다르면 `stale`(운영자는 거절로 처리).

    반환 result: approved(+benefit_id·edit_id) / not_pending / code_required / unknown_code / duplicate /
    stale / target_gone."""
    outcome: dict | None = None
    try:
        async with database.transaction() as conn:
            async with conn.cursor() as cur:
                await cur.execute(_SQL_LOCK_REQUEST, (req_id,))
                req = await cur.fetchone()
                if not req or req["STATUS_CD"] != "pending":
                    return {"result": "not_pending"}
                comp_id, mbr_id = req["COMP_ID"], req["MBR_ID"]
                amt = None if req["QUAL_YN"] else req["BENEFIT_AMT"]
                amt_source = "estimated" if amt is not None else "none"  # 금액 유무로 판정(DC-9·DC-10·DEC-2)
                if req["REQ_TYPE_CD"] == "create":
                    if not benefit_cd:
                        return {"result": "code_required"}
                    if benefit_cd not in codes:
                        return {"result": "unknown_code"}
                    await cur.execute(
                        "SELECT 1 FROM TCOMPANY_BENEFIT WHERE COMP_ID=%s AND BENEFIT_CD=%s", (comp_id, benefit_cd))
                    if await cur.fetchone():
                        return {"result": "duplicate"}
                    await cur.execute(
                        "INSERT INTO TCOMPANY_BENEFIT "
                        "(COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_CTGR_CD, BENEFIT_AMT, QUAL_YN, NOTE_CTNT, "
                        " BADGE_CD, AMT_SOURCE_CD, BADGE_SRC_CD, VERIFIED_DTM, EXPIRES_DTM, INS_ID) "
                        "VALUES (%s, %s, %s, %s, %s, %s, %s, 'verified', %s, 'user_report', "
                        "        UTC_TIMESTAMP(), UTC_TIMESTAMP() + INTERVAL 18 MONTH, %s)",
                        (comp_id, benefit_cd, req["BENEFIT_NM"], codes[benefit_cd]["ctgr"], amt,
                         req["QUAL_YN"], req["NOTE_CTNT"], amt_source, mbr_id),
                    )
                    benefit_id, before, applied_cd = cur.lastrowid, None, benefit_cd
                else:
                    if req["BENEFIT_ID"] is None:
                        return {"result": "target_gone"}
                    await cur.execute(_SQL_ROW + " AND COMP_ID=%s FOR UPDATE", (req["BENEFIT_ID"], comp_id))
                    row = await cur.fetchone()
                    if not row:
                        return {"result": "target_gone"}
                    if _version_token(row) != req["BASE_TOKEN_VAL"]:
                        return {"result": "stale"}
                    benefit_id, before, applied_cd = req["BENEFIT_ID"], _snapshot(row), None
                    # 재직자 편집 = 재검증(신선도 리셋) — 미갱신 시 과거 만료행이 verified 강등돼도 만료 상태로
                    # 남아 밴드가 부당 확대된다(INV-5).
                    await cur.execute(
                        "UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM=%s, BENEFIT_AMT=%s, QUAL_YN=%s, "
                        "AMT_SOURCE_CD=%s, NOTE_CTNT=%s, BADGE_CD='verified', BADGE_SRC_CD='user_report', "
                        "VERIFIED_DTM=UTC_TIMESTAMP(), EXPIRES_DTM=UTC_TIMESTAMP() + INTERVAL 18 MONTH, "
                        "MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() WHERE BENEFIT_ID=%s AND COMP_ID=%s",
                        (req["BENEFIT_NM"], amt, req["QUAL_YN"], amt_source, req["NOTE_CTNT"],
                         mbr_id, benefit_id, comp_id),
                    )
                await cur.execute(_SQL_ROW, (benefit_id,))
                result_row = await cur.fetchone()
                await cur.execute(
                    "INSERT INTO TBENEFIT_EDIT_LOG "
                    "(BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, ACTOR_KIND_CD, EDIT_TYPE_CD, BEFORE_VAL, AFTER_VAL, "
                    " EDIT_NOTE_CTNT) VALUES (%s, %s, %s, 'member', %s, %s, %s, %s)",
                    (benefit_id, comp_id, mbr_id, req["REQ_TYPE_CD"],
                     json.dumps(before, ensure_ascii=False) if before is not None else None,
                     json.dumps(_snapshot(result_row), ensure_ascii=False), req["EDIT_NOTE_CTNT"]),
                )
                edit_id = cur.lastrowid
                await cur.execute(
                    _SQL_MARK_APPROVED,
                    (decided_by, note, applied_cd, benefit_id, edit_id, decided_by, req_id),
                )
                outcome = {"result": "approved", "benefit_id": benefit_id, "edit_id": edit_id}
    except IntegrityError:  # uq_comp_benefit 경합 — 원자 롤백(요청은 대기 그대로)
        return {"result": "duplicate"}
    return outcome or {"result": "not_pending"}


async def reject_request(req_id: int, decided_by: int, note: str | None) -> bool:
    """요청 거절 — 본체·이력 무접촉. 사유(note)는 회원 편집 화면에 보인다. 대기가 아니면 False."""
    return bool(await database.execute(_SQL_MARK_REJECTED, (decided_by, note, decided_by, req_id)))


async def list_edits(comp_id: int, limit: int, before: int | None) -> list[dict]:
    """편집 이력 공개 조회 — 최신순·닉네임만·before 커서(EDIT_LOG_ID). 편집자 이메일·MBR_ID 미노출(INV-8)."""
    sql = _SQL_EDITS
    params: list = [comp_id]
    if before is not None:
        sql += " AND l.EDIT_LOG_ID < %s"
        params.append(before)
    sql += " ORDER BY l.EDIT_LOG_ID DESC LIMIT %s"
    params.append(limit)
    rows = await database.fetch_all(sql, tuple(params))
    return [
        {"edit_id": r["edit_id"], "nickname": r["nickname"], "actor_kind": r["actor_kind"],
         "edit_type": r["edit_type"],
         "before": _parse_json(r["before_val"]), "after": _parse_json(r["after_val"]),
         "edit_note": r["edit_note"], "dtm": r["dtm"]}
        for r in rows
    ]


async def company_exists(comp_id: int) -> bool:
    """편집 이력 404 게이트 — 회사 존재 여부."""
    return await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ID=%s", (comp_id,)) is not None
