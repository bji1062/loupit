"""SP-AUTH-9 복지 편집 서비스 — 배지 서버 강제·낙관적 동시성·본체+이력 원자 트랜잭션.

서버가 배지 시맨틱을 강제하고(사용자는 official·stated 지정 불가), 본체 INSERT/UPDATE 와
편집 이력 INSERT(TBENEFIT_EDIT_LOG)를 **한 트랜잭션**으로 원자화한다(SP-AUTH-9, FR-108·109).

- 배지 강제: `BADGE_CD='verified'`(재직자 확인)·`BADGE_SRC_CD='user_report'`·`EXPIRES_DTM=+18개월`.
- 금액출처 분기(DC-9·DC-10, INV-5): 금액 행 `AMT_SOURCE_CD='estimated'`, 정성 행 `none`(금액 NULL).
- 낙관적 동시성: 버전 컬럼 없이 `MOD_DTM`(없으면 `INS_DTM`) 토큰 비교 — 불일치 시 409(현재 행 동봉).
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
  SELECT COALESCE(m.NICKNAME_NM, '(탈퇴)') AS nickname, l.EDIT_TYPE_CD AS edit_type,
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
    """최근 24시간 이 회원이 이 회사에 남긴 편집 수(일일 상한 게이트, FR-112)."""
    row = await database.fetch_one(
        "SELECT COUNT(*) AS n FROM TBENEFIT_EDIT_LOG "
        "WHERE ACTOR_MBR_ID=%s AND COMP_ID=%s AND INS_DTM > UTC_TIMESTAMP() - INTERVAL 1 DAY",
        (mbr_id, comp_id),
    )
    return int(row["n"]) if row else 0


async def fetch_company_benefits(comp_id: int) -> list[dict]:
    """회사 복지 목록(편집용 투영, 각 행 base_dtm 동봉) — 편집 응답 benefits[]·편집용 조회 공용.

    base_dtm(낙관동시성 토큰)은 편집자만 보는 인증·no-store 경로(create/update 응답·편집용 GET)로만
    노출된다 — 공개·캐시 가능한 GET /companies/{id} 상세엔 두지 않는다(캐시 stale→오탐 409 방지)."""
    rows = await database.fetch_all(_SQL_LIST, (comp_id,))
    return [_public_benefit(r) for r in rows]


async def create_benefit(comp_id: int, mbr_id: int, payload) -> dict:
    """복지 등록 — 배지 강제·금액출처 분기·본체+이력 원자 트랜잭션.

    반환 result: ok(+benefit·benefits) / rate_limited(429) / duplicate(409·동일 회사·코드)."""
    if await _daily_count(mbr_id, comp_id) >= get_settings().daily_edit_limit:
        return {"result": "rate_limited"}

    amt = None if payload.qual_yn else payload.benefit_amt
    # 금액출처는 실제 금액 유무로 판정(DC-9·DC-10·DEC-2): 금액 있으면 estimated, 없으면 none.
    # (정성이면 amt=None → none. 비정성이라도 금액 미기재면 none — NULL 금액에 estimated 금지.)
    amt_source = "estimated" if amt is not None else "none"
    try:
        async with database.transaction() as conn:
            async with conn.cursor() as cur:
                await cur.execute(
                    "INSERT INTO TCOMPANY_BENEFIT "
                    "(COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_CTGR_CD, BENEFIT_AMT, QUAL_YN, NOTE_CTNT, "
                    " BADGE_CD, AMT_SOURCE_CD, BADGE_SRC_CD, VERIFIED_DTM, EXPIRES_DTM, INS_ID) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s, 'verified', %s, 'user_report', "
                    "        UTC_TIMESTAMP(), UTC_TIMESTAMP() + INTERVAL 18 MONTH, %s)",
                    (comp_id, payload.benefit_cd, payload.benefit_nm, payload.benefit_ctgr_cd,
                     amt, payload.qual_yn, payload.note_ctnt, amt_source, mbr_id),
                )
                benefit_id = cur.lastrowid
                await cur.execute(_SQL_ROW, (benefit_id,))
                row = await cur.fetchone()
                await cur.execute(
                    "INSERT INTO TBENEFIT_EDIT_LOG "
                    "(BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, BEFORE_VAL, AFTER_VAL, EDIT_NOTE_CTNT) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (benefit_id, comp_id, mbr_id, "create", None,
                     json.dumps(_snapshot(row), ensure_ascii=False), payload.edit_note),
                )
    except IntegrityError:  # uq_comp_benefit — 동일 회사·복지 코드 중복(원자 롤백, 이력 미기록)
        return {"result": "duplicate"}

    return {"result": "ok", "benefit": _public_benefit(row),
            "benefits": await fetch_company_benefits(comp_id)}


async def update_benefit(comp_id: int, benefit_id: int, mbr_id: int, payload) -> dict:
    """복지 수정 — base_dtm 낙관적 동시성·official→verified 강등·본체+이력 원자 트랜잭션.

    반환 result: ok / rate_limited(429) / not_found(404) / conflict(409·현재 행 동봉)."""
    if await _daily_count(mbr_id, comp_id) >= get_settings().daily_edit_limit:
        return {"result": "rate_limited"}

    amt = None if payload.qual_yn else payload.benefit_amt
    amt_source = "estimated" if amt is not None else "none"  # 금액 유무로 판정(DC-9·DC-10·DEC-2)
    outcome, result_row = None, None
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(_SQL_ROW + " AND COMP_ID=%s FOR UPDATE", (benefit_id, comp_id))
            row = await cur.fetchone()
            if not row:
                outcome = "not_found"
            elif _version_token(row) != payload.base_dtm:
                outcome, result_row = "conflict", row  # 선점 수정 — 아무것도 쓰지 않음
            else:
                before = _snapshot(row)
                # 재직자 편집 = 재검증(신선도 리셋) — create 와 동일하게 VERIFIED_DTM·EXPIRES_DTM 갱신.
                # 미갱신 시 과거 만료행이 verified 강등돼도 만료 상태로 남아 밴드가 부당 확대된다(INV-5).
                await cur.execute(
                    "UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM=%s, BENEFIT_AMT=%s, QUAL_YN=%s, "
                    "AMT_SOURCE_CD=%s, NOTE_CTNT=%s, BADGE_CD='verified', BADGE_SRC_CD='user_report', "
                    "VERIFIED_DTM=UTC_TIMESTAMP(), EXPIRES_DTM=UTC_TIMESTAMP() + INTERVAL 18 MONTH, "
                    "MOD_ID=%s, MOD_DTM=UTC_TIMESTAMP() WHERE BENEFIT_ID=%s AND COMP_ID=%s",
                    (payload.benefit_nm, amt, payload.qual_yn, amt_source, payload.note_ctnt,
                     mbr_id, benefit_id, comp_id),
                )
                await cur.execute(_SQL_ROW, (benefit_id,))
                result_row = await cur.fetchone()
                await cur.execute(
                    "INSERT INTO TBENEFIT_EDIT_LOG "
                    "(BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, BEFORE_VAL, AFTER_VAL, EDIT_NOTE_CTNT) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (benefit_id, comp_id, mbr_id, "update", json.dumps(before, ensure_ascii=False),
                     json.dumps(_snapshot(result_row), ensure_ascii=False), payload.edit_note),
                )
                outcome = "ok"

    if outcome == "not_found":
        return {"result": "not_found"}
    benefits = await fetch_company_benefits(comp_id)
    if outcome == "conflict":
        return {"result": "conflict", "current_benefit": _public_benefit(result_row), "benefits": benefits}
    return {"result": "ok", "benefit": _public_benefit(result_row), "benefits": benefits}


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
        {"nickname": r["nickname"], "edit_type": r["edit_type"],
         "before": _parse_json(r["before_val"]), "after": _parse_json(r["after_val"]),
         "edit_note": r["edit_note"], "dtm": r["dtm"]}
        for r in rows
    ]


async def company_exists(comp_id: int) -> bool:
    """편집 이력 404 게이트 — 회사 존재 여부."""
    return await database.fetch_one("SELECT COMP_ID FROM TCOMPANY WHERE COMP_ID=%s", (comp_id,)) is not None
