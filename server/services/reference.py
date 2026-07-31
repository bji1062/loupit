"""SP-API-7 참조 번들 빌더 — 단일 소스 (SP-ARCH-4).

런타임 라우터(server/routers/reference.py, FR-92)와 빌드타임 generator(C2,
SP-GEN)가 이 함수 하나를 공유한다(단일 소스 심볼 동일성 회귀는
server/tests/test_arch.py::test_T3_bundle_single_source, T-01.3.1이 소유).
원시 SQL 5회 + 파이썬 조립. 부수효과·쓰기 0(순수 조립).
"""
from __future__ import annotations

import logging

import json

logger = logging.getLogger(__name__)

_SQL_TYPES = """
  SELECT COMP_TP_ID AS comp_tp_id, COMP_TP_CD AS comp_tp_cd, COMP_TP_NM AS comp_tp_nm
    FROM TCOMPANY_TYPE ORDER BY COMP_TP_ID"""

_SQL_PRESETS = """
  SELECT t.COMP_TP_CD AS comp_tp_cd, p.BENEFIT_CD AS benefit_cd, p.BENEFIT_NM AS benefit_nm,
         p.BENEFIT_AMT AS benefit_amt, p.BENEFIT_CTGR_CD AS benefit_ctgr_cd, p.BADGE_CD AS badge_cd,
         p.DEFAULT_CHECKED_YN AS default_checked_yn, p.SORT_ORDER_NO AS sort_order_no
    FROM TBENEFIT_PRESET p JOIN TCOMPANY_TYPE t ON p.COMP_TP_ID = t.COMP_TP_ID
   ORDER BY t.COMP_TP_CD, p.SORT_ORDER_NO, p.PRESET_ID"""

_SQL_COMPANIES = """
  SELECT c.COMP_ID AS comp_id, c.COMP_ENG_NM AS comp_eng_nm, c.COMP_NM AS comp_nm,
         t.COMP_TP_CD AS comp_tp_cd, c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm,
         c.WORK_STYLE_VAL AS work_style_val, c.CAREERS_BENEFIT_URL AS careers_benefit_url
    FROM TCOMPANY c JOIN TCOMPANY_TYPE t ON c.COMP_TP_ID = t.COMP_TP_ID
   ORDER BY c.COMP_ID"""

_SQL_ALIASES = "SELECT COMP_ID AS comp_id, ALIAS_NM AS alias_nm FROM TCOMPANY_ALIAS ORDER BY ALIAS_ID"

_SQL_BENEFITS = """
  SELECT COMP_ID AS comp_id, BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm,
         BENEFIT_AMT AS benefit_amt, BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd,
         AMT_SOURCE_CD AS amt_source, QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt,
         NOTE_CTNT AS note_ctnt, VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm,
         BADGE_SRC_CD AS badge_src_cd, BADGE_SRC_URL_CTNT AS badge_src_url_ctnt,
         SORT_ORDER_NO AS sort_order_no, BENEFIT_ID AS benefit_id
    FROM TCOMPANY_BENEFIT ORDER BY COMP_ID, SORT_ORDER_NO, BENEFIT_ID"""

# 복지 한 줄의 **출처 계보**(SP-GEN 배지) — "누가 마지막으로 손댔나".
#
# 왜 컬럼이 아니라 파생인가: 근거는 이미 `TBENEFIT_EDIT_LOG`(append-only 감사 원장)에 있다.
# 컬럼을 따로 두면 원장과 두 갈래가 되고, 어긋나는 날 어느 쪽이 참인지 알 수 없다.
#
# 판정: `create` 이력이 있으면 **재직자 등록**(생성 기원이 이긴다 — 등록 후 수정해도 등록이다),
#       `update` 만 있으면 **공식·재직자 수정**, 이력이 없으면 **공식**(시드 원본).
# ⚠ 편집은 `require_employment` 게이트 뒤라 **그 회사 재직 인증자만** 남길 수 있다 —
#   그래서 라벨이 '사용자'가 아니라 '재직자'다.
_SQL_EDIT_ORIGIN = """
  SELECT BENEFIT_ID AS benefit_id,
         MAX(EDIT_TYPE_CD = 'create') AS has_create,
         MAX(EDIT_TYPE_CD = 'update') AS has_update
    FROM TBENEFIT_EDIT_LOG WHERE BENEFIT_ID IS NOT NULL GROUP BY BENEFIT_ID"""


def _parse_ws(v):  # JSON 컬럼(문자열) → dict, 실패 시 None
    if v is None:
        return None
    if isinstance(v, dict):
        return v
    try:
        return json.loads(v)
    except (ValueError, TypeError):
        return None


def _edit_origin(row: dict | None) -> str:
    """이력 집계 → `seed`(공식) | `edited`(공식·재직자 수정) | `member`(재직자 등록).

    `create` 가 `update` 를 이긴다 — 재직자가 등록한 뒤 스스로 고쳐도 그 줄의 기원은 등록이다.
    """
    if not row:
        return "seed"
    if row.get("has_create"):
        return "member"
    if row.get("has_update"):
        return "edited"
    return "seed"


def _norm_benefit(r: dict) -> dict:
    r["qual_yn"] = bool(r.get("qual_yn"))
    for k in ("verified_dtm", "expires_dtm"):
        if r.get(k) is not None:
            r[k] = r[k].isoformat() if hasattr(r[k], "isoformat") else str(r[k])
    return r


async def build_reference_bundle(conn) -> dict:
    """단일 정본 조립 함수. 런타임(reference/all)·빌드타임(generator) 공유(SP-ARCH-4)."""
    async with conn.cursor() as cur:  # DictCursor
        await cur.execute(_SQL_TYPES)
        types = await cur.fetchall()
        await cur.execute(_SQL_PRESETS)
        presets = await cur.fetchall()
        await cur.execute(_SQL_COMPANIES)
        comps = await cur.fetchall()
        await cur.execute(_SQL_ALIASES)
        aliases = await cur.fetchall()
        await cur.execute(_SQL_BENEFITS)
        benefits = await cur.fetchall()
        # 편집 이력은 참여(M9) 테이블이다. 이 함수는 **익명 열람 경로**(INV-1)라, 이력 조회가
        # 실패했다고 회사·복지 전체가 사라지면 안 된다 → 실패 시 전부 '시드 원본'으로 본다.
        # 조용히 넘기지는 않는다: 경고를 남겨야 "배지가 왜 다 공식이지"를 추적할 수 있다.
        origin_by_id: dict = {}
        try:
            await cur.execute(_SQL_EDIT_ORIGIN)
            origin_by_id = {r["benefit_id"]: r for r in await cur.fetchall()}
        except Exception:  # noqa: BLE001 — 테이블 부재(구 스키마)·권한 등 원인 무관
            logger.warning(
                "편집 이력 조회 실패 — 모든 복지를 '공식'(시드 원본)으로 표시한다. "
                "TBENEFIT_EDIT_LOG 존재 여부를 확인하라.", exc_info=True)

    # 성장률·안정성 컬럼은 브랜드 축 제거(2026-07-20)로 번들에서 뺐다. DB 컬럼은 남아 있으나
    # 어느 소비처도 읽지 않는다 — Decimal 직렬화 정규화도 함께 불필요해졌다.

    # 그룹핑
    presets_by_type: dict[str, list] = {}
    for p in presets:
        p["default_checked_yn"] = bool(p.get("default_checked_yn"))
        presets_by_type.setdefault(p.pop("comp_tp_cd"), []).append(p)

    aliases_by_comp: dict[int, list[str]] = {}
    for a in aliases:
        aliases_by_comp.setdefault(a["comp_id"], []).append(a["alias_nm"])

    benefits_by_comp: dict[int, list] = {}
    for b in benefits:
        # 조인 키는 번들 계약에 없다 — 파생값으로 바꿔 넣고 버린다.
        b["edit_origin"] = _edit_origin(origin_by_id.get(b.pop("benefit_id")))
        cid = b.pop("comp_id")
        benefits_by_comp.setdefault(cid, []).append(_norm_benefit(b))

    for c in comps:
        c["work_style_val"] = _parse_ws(c.get("work_style_val"))
        c["aliases"] = aliases_by_comp.get(c["comp_id"], [])
        c["benefits"] = benefits_by_comp.get(c["comp_id"], [])

    return {"company_types": types, "benefit_presets": presets_by_type, "companies": comps}
