"""SP-API-6.1 참조 번들 응답 모델 — CompanyType·PresetBenefit·Benefit·Company·ReferenceBundle.

§02 스키마 컬럼을 snake_case 필드로 1:1 매핑한다. 감사 4종(INS_ID 등)·내부 PK
(ALIAS_ID/PRESET_ID/BENEFIT_ID)는 미노출(§02 공통 규약).
"""
from __future__ import annotations

from pydantic import BaseModel


class CompanyType(BaseModel):  # FR-D2 / TCOMPANY_TYPE
    comp_tp_id: int
    comp_tp_cd: str  # ∈ {large,startup,mid,foreign,public,freelance}
    comp_tp_nm: str
    growth_rate_val: float | None = None  # DECIMAL(5,4) → float
    growth_label_nm: str | None = None
    stability_score_no: int | None = None  # 1~100


class PresetBenefit(BaseModel):  # FR-D3 / TBENEFIT_PRESET (출처·만료·amt_source 없음)
    benefit_cd: str
    benefit_nm: str
    benefit_amt: int | None = None  # 만원. NULL 가능
    benefit_ctgr_cd: str  # 9종
    badge_cd: str = "est"  # 프리셋은 통상 est
    default_checked_yn: bool = True
    sort_order_no: int | None = None


class Benefit(BaseModel):  # FR-D5 / TCOMPANY_BENEFIT
    benefit_cd: str
    benefit_nm: str
    benefit_amt: int | None = None  # 만원. qual_yn=true면 None
    benefit_ctgr_cd: str  # 9종
    badge_cd: str  # ∈ {official, est}
    amt_source: str  # ∈ {stated, estimated, none} ← AMT_SOURCE_CD(SP-DB-5 필드맵)
    qual_yn: bool
    qual_desc_ctnt: str | None = None
    note_ctnt: str | None = None
    verified_dtm: str | None = None  # ISO8601 문자열
    expires_dtm: str | None = None
    badge_src_cd: str | None = None  # ∈ {scrape_official,scrape_fallback,ai_parse,manual,user_report}
    badge_src_url_ctnt: str | None = None
    sort_order_no: int | None = None


class Company(BaseModel):  # FR-D4 / TCOMPANY (+aliases,+benefits 인라인)
    comp_id: int
    comp_eng_nm: str
    comp_nm: str
    comp_tp_cd: str  # TCOMPANY_TYPE 조인 파생
    industry_nm: str | None = None
    logo_nm: str | None = None
    work_style_val: dict | None = None  # {remote,flex,unlimitedPTO,refreshLeave,overtime}
    careers_benefit_url: str | None = None
    aliases: list[str]  # 회사당 ≥1
    benefits: list[Benefit]  # 회사당 ≥1 (실복지, 비어있지 않음)


class ReferenceBundle(BaseModel):  # FR-D1 (최상위 정확히 3키)
    company_types: list[CompanyType]
    benefit_presets: dict[str, list[PresetBenefit]]  # {comp_tp_cd: [...]}
    companies: list[Company]
