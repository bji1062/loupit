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
    # 출처 계보(2026-07-31) — `seed`(시드 원본=공식) | `edited`(공식·재직자 수정) | `member`(재직자 등록).
    # DB 컬럼이 아니라 `services/reference.py` 가 편집 이력에서 **파생**한다(원장이 유일 근거).
    #
    # 🚨 여기 선언하지 않으면 **API 응답에서 조용히 사라진다** — 라우터가 `ReferenceBundle.
    #    model_validate` 로 검증하며 모르는 필드를 떨어뜨리기 때문이다(2026-07-31 실발현:
    #    정적 페이지는 빌더를 직접 써서 배지가 나오는데 비교 리포트·디렉터리는 영영 '공식'만
    #    보였다). 번들에 필드를 더할 때는 **반드시 이 모델도 함께** 고쳐라.
    edit_origin: str = "seed"


class Company(BaseModel):  # FR-D4 / TCOMPANY (+aliases,+benefits 인라인)
    comp_id: int
    comp_eng_nm: str
    comp_nm: str
    comp_tp_cd: str  # TCOMPANY_TYPE 조인 파생
    industry_nm: str | None = None
    logo_nm: str | None = None
    work_style_val: dict | None = None  # {remote,flex,unlimitedPTO,refreshLeave,overtime,cond?} — cond = {키: [조건 라벨]}(조건 있는 키는 false, 6c)
    careers_benefit_url: str | None = None
    aliases: list[str]  # 회사당 ≥1
    benefits: list[Benefit]  # 회사당 ≥1 (실복지, 비어있지 않음)


class ReferenceBundle(BaseModel):  # FR-D1 (최상위 정확히 3키)
    company_types: list[CompanyType]
    benefit_presets: dict[str, list[PresetBenefit]]  # {comp_tp_cd: [...]}
    companies: list[Company]


# ── /compare 부팅용 가벼운 목록 + 회사별 상세 (2026-10-22) ─────────────────────────────────
# 비교 화면은 번들 전체(복지 행 6천여 개 · 압축 약 700KB)를 부팅 때 받았지만 화면이 쓰는 상세는 고른 두 회사뿐이다.
# 부팅은 아래 가벼운 목록을, 상세는 `GET /reference/companies/{id}`(= `Company` 그대로)를 필요한 순간에 받는다.
# 🚨 번들과 마찬가지로 여기 선언하지 않은 필드는 조용히 떨어진다 — 목록에 필드를 더할 때 이 모델도 함께 고쳐라.
class IndexCompany(BaseModel):
    comp_id: int
    comp_eng_nm: str
    comp_nm: str
    comp_tp_cd: str
    industry_nm: str | None = None
    logo_nm: str | None = None
    aliases: list[str]
    benefit_n: int  # 셀 수 있는 복지 수 = generator/marks.py countable(c) 길이 (JS marks.js::countable 과 같은 정의)


class CategoryStats(BaseModel):
    """9각형 · 나비 눈금 기준 — 평균이 아니라 **합**을 싣는다(JS categoryStats 와 같은 산술로 round2 하려고)."""
    total: int  # 분모 = 전체 등록 회사 수
    sums: dict[str, int]  # 카테고리 → 표시 행을 뺀 전 회사 항목 수의 합
    rmax: int  # 한 회사 · 한 카테고리의 최댓값(최소 1)


class ReferenceIndex(BaseModel):  # 최상위 정확히 4키
    company_types: list[CompanyType]
    benefit_presets: dict[str, list[PresetBenefit]]
    companies: list[IndexCompany]
    category_stats: CategoryStats
