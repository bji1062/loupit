"""SP-API-10·11 GET /companies/search·GET /companies/{comp_id}.

`server.database`를 모듈 참조로 호출한다(`database.fetch_all(...)`) — 테스트가
`monkeypatch.setattr(database, "fetch_all", ...)`로 원본 모듈을 patch하므로
(SP-API-14.1), `from server.database import fetch_all` 형태로 이름을 로컬에
바인딩하면 그 patch가 반영되지 않는다(임의결정 — 테스트 가능성 확보, 관측
가능한 API 계약은 SPEC pseudocode와 동일).
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Path, Query, Response

from server import database
from server.config import get_settings
from server.models.company import CompanySearchItem
from server.models.reference import Benefit, Company
from server.services.reference import _norm_benefit, _parse_ws

router = APIRouter(tags=["companies"])

_SQL_SEARCH = """
  SELECT DISTINCT c.COMP_ID AS comp_id, c.COMP_NM AS comp_nm, t.COMP_TP_CD AS comp_tp_cd,
         c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm
    FROM TCOMPANY c
    JOIN TCOMPANY_TYPE t   ON c.COMP_TP_ID = t.COMP_TP_ID
    LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
   WHERE c.COMP_NM LIKE %s ESCAPE '!' OR a.ALIAS_NM LIKE %s ESCAPE '!'
   ORDER BY (c.COMP_NM LIKE %s ESCAPE '!') DESC, c.COMP_NM
   LIMIT 20"""

_SQL_COMP = """
  SELECT c.COMP_ID AS comp_id, c.COMP_ENG_NM AS comp_eng_nm, c.COMP_NM AS comp_nm,
         t.COMP_TP_CD AS comp_tp_cd, c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm,
         c.WORK_STYLE_VAL AS work_style_val, c.CAREERS_BENEFIT_URL AS careers_benefit_url
    FROM TCOMPANY c JOIN TCOMPANY_TYPE t ON c.COMP_TP_ID = t.COMP_TP_ID
   WHERE c.COMP_ID = %s"""
_SQL_COMP_ALIASES = "SELECT ALIAS_NM AS alias_nm FROM TCOMPANY_ALIAS WHERE COMP_ID = %s ORDER BY ALIAS_ID"
_SQL_COMP_BENEFITS = """
  SELECT BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm, BENEFIT_AMT AS benefit_amt,
         BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd, AMT_SOURCE_CD AS amt_source,
         QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt, NOTE_CTNT AS note_ctnt,
         VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm, BADGE_SRC_CD AS badge_src_cd,
         BADGE_SRC_URL_CTNT AS badge_src_url_ctnt, SORT_ORDER_NO AS sort_order_no
    FROM TCOMPANY_BENEFIT WHERE COMP_ID = %s ORDER BY SORT_ORDER_NO, BENEFIT_ID"""


def _like_escape(s: str) -> str:  # LIKE 메타문자 무력화(ESCAPE '!')
    return s.replace("!", "!!").replace("%", "!%").replace("_", "!_")


@router.api_route("/companies/search", methods=["GET", "HEAD"], response_model=list[CompanySearchItem])
async def search_companies(
    response: Response,
    q: str = Query(..., max_length=50),  # 미제공 → 422 / >50 → 422 (FR-93)
) -> list[CompanySearchItem]:
    response.headers["Cache-Control"] = "no-store"
    term = q.strip()
    if not term:  # 공백/빈 문자열 → 200 []
        return []
    like = f"%{_like_escape(term)}%"
    prefix = f"{_like_escape(term)}%"
    rows = await database.fetch_all(_SQL_SEARCH, (like, like, prefix))
    return [CompanySearchItem(**r) for r in rows]


@router.api_route("/companies/{comp_id}", methods=["GET", "HEAD"], response_model=Company)
async def get_company(
    response: Response,
    comp_id: int = Path(..., ge=1),  # 비정수·<1 → 422 (FR-94)
) -> Company:
    row = await database.fetch_one(_SQL_COMP, (comp_id,))
    if row is None:  # 미존재 → 404 (FR-94/FR-E6)
        raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")
    aliases = await database.fetch_all(_SQL_COMP_ALIASES, (comp_id,))
    benefits = await database.fetch_all(_SQL_COMP_BENEFITS, (comp_id,))
    row["work_style_val"] = _parse_ws(row.get("work_style_val"))
    row["aliases"] = [a["alias_nm"] for a in aliases]
    row["benefits"] = [Benefit(**_norm_benefit(b)) for b in benefits]
    response.headers["Cache-Control"] = get_settings().reference_cache_control  # public, max-age=3600
    return Company(**row)
