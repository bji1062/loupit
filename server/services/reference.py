"""SP-API-7 참조 번들 빌더 — 단일 소스 (SP-ARCH-4).

런타임 라우터(server/routers/reference.py, FR-92)와 빌드타임 generator(C2,
SP-GEN)가 이 함수 하나를 공유한다(단일 소스 심볼 동일성 회귀는
server/tests/test_arch.py::test_T3_bundle_single_source, T-01.3.1이 소유).
원시 SQL 5회 + 파이썬 조립. 부수효과·쓰기 0(순수 조립).
"""
from __future__ import annotations

import json

_SQL_TYPES = """
  SELECT COMP_TP_ID AS comp_tp_id, COMP_TP_CD AS comp_tp_cd, COMP_TP_NM AS comp_tp_nm,
         GROWTH_RATE_VAL AS growth_rate_val, GROWTH_LABEL_NM AS growth_label_nm,
         STABILITY_SCORE_NO AS stability_score_no
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
         SORT_ORDER_NO AS sort_order_no
    FROM TCOMPANY_BENEFIT ORDER BY COMP_ID, SORT_ORDER_NO, BENEFIT_ID"""


def _parse_ws(v):  # JSON 컬럼(문자열) → dict, 실패 시 None
    if v is None:
        return None
    if isinstance(v, dict):
        return v
    try:
        return json.loads(v)
    except (ValueError, TypeError):
        return None


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

    # DECIMAL(5,4) growth_rate_val → float (JSON 직렬화 + FR-D 계약 float|None).
    # 실 aiomysql DictCursor는 DECIMAL을 Decimal로 반환한다 — generator(Jinja str화)는
    # 무해하나 API JSONResponse는 Decimal 직렬화 불가하므로 단일 소스에서 정규화한다.
    for t in types:
        if t.get("growth_rate_val") is not None:
            t["growth_rate_val"] = float(t["growth_rate_val"])

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
        cid = b.pop("comp_id")
        benefits_by_comp.setdefault(cid, []).append(_norm_benefit(b))

    for c in comps:
        c["work_style_val"] = _parse_ws(c.get("work_style_val"))
        c["aliases"] = aliases_by_comp.get(c["comp_id"], [])
        c["benefits"] = benefits_by_comp.get(c["comp_id"], [])

    return {"company_types": types, "benefit_presets": presets_by_type, "companies": comps}
