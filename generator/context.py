"""generator/context.py — Page 모델·컨텍스트 인덱스 (SP-GEN-2).

모든 렌더 함수(company/combo/policy/sitemap)는 `Page`를 반환한다. 릴리스
(SP-GEN-11)·sitemap(SP-GEN-9)·검증(SP-GEN-12)이 공통 소비하는 단일 산출 타입.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from generator.slug import validate_slugs


@dataclass(frozen=True)
class Page:
    """생성기의 단일 산출 단위 (SP-GEN-2.2)."""

    path: str  # dist 상대 경로 (예: "company/samsung-elec.html")
    url: str  # 절대 canonical URL (예: "https://jobcho.wiki/company/samsung-elec")
    html: str  # 완성 HTML(또는 sitemap/robots는 xml/txt) 문자열
    title: str  # <title> 텍스트(중복 검증용, FR-59)
    description: str  # meta description(중복 검증용)
    in_sitemap: bool = True  # 404 등은 False
    content_type: str = "text/html; charset=utf-8"


@dataclass
class Ctx:
    """빌드 컨텍스트 — 번들 인덱스·slug 매핑·빌드 시각 (SP-GEN-2.3)."""

    companies: list[dict]
    by_eng: dict[str, dict]
    by_id: dict
    types_by_cd: dict[str, dict]
    slugs: dict[str, str]
    build_now: datetime = field(default_factory=datetime.utcnow)


def build_context(bundle: dict, now: datetime | None = None) -> Ctx:
    """번들 dict → 인덱스·slug 검증 완료된 `Ctx` (SP-GEN-2.3).

    slug 충돌은 `validate_slugs`가 `BuildError`로 표면화한다(SP-GEN-3).
    """
    companies = bundle["companies"]
    by_eng = {c["comp_eng_nm"]: c for c in companies}
    by_id = {c["comp_id"]: c for c in companies}
    types_by_cd = {t["comp_tp_cd"]: t for t in bundle["company_types"]}
    slugs = validate_slugs(companies)
    return Ctx(
        companies=companies,
        by_eng=by_eng,
        by_id=by_id,
        types_by_cd=types_by_cd,
        slugs=slugs,
        build_now=now or datetime.utcnow(),
    )
