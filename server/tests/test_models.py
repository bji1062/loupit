"""T-04.3.1·T-04.3.2 Pydantic 응답 모델 유닛 테스트 (SP-API-6).

무 DB — 필드 존재/타입/기본값만 검증한다. 실계약(엔드포인트 통합)은
TR-4(test_reference.py)·TSE-1(test_search.py)·TH-1(test_health.py)이 담당.
"""
from __future__ import annotations

import pytest
from pydantic import ValidationError


def test_company_type_fields():
    from server.models.reference import CompanyType

    ct = CompanyType(comp_tp_id=1, comp_tp_cd="large", comp_tp_nm="대기업")
    assert ct.comp_tp_cd == "large"
    assert ct.comp_tp_nm == "대기업"


def test_company_type_drops_removed_brand_fields():
    """브랜드 축 제거(2026-07-20) — 성장률·안정성은 계약에서 빠졌다.
    모델이 필드를 유지하면 SQL에서 빼도 model_dump가 null로 되살려 번들에 새어 나간다."""
    from server.models.reference import CompanyType

    ct = CompanyType(comp_tp_id=1, comp_tp_cd="freelance", comp_tp_nm="프리랜서")
    dumped = ct.model_dump()
    for gone in ("growth_rate_val", "growth_label_nm", "stability_score_no"):
        assert gone not in dumped, f"{gone}는 계약에서 제거됐어야 한다"


def test_preset_benefit_defaults():
    from server.models.reference import PresetBenefit

    pb = PresetBenefit(
        benefit_cd="meal",
        benefit_nm="식대",
        benefit_ctgr_cd="compensation",
    )
    assert pb.badge_cd == "est"
    assert pb.default_checked_yn is True
    assert pb.benefit_amt is None


def test_benefit_requires_amt_source_and_qual_yn():
    from server.models.reference import Benefit

    b = Benefit(
        benefit_cd="meal",
        benefit_nm="식대",
        benefit_ctgr_cd="compensation",
        badge_cd="official",
        amt_source="stated",
        qual_yn=False,
    )
    assert b.amt_source == "stated"
    assert b.qual_yn is False
    assert b.verified_dtm is None
    assert b.expires_dtm is None


def test_benefit_missing_required_fields_raises():
    from server.models.reference import Benefit

    with pytest.raises(ValidationError):
        Benefit(benefit_cd="meal", benefit_nm="식대")  # ctgr/badge/amt_source/qual_yn 누락


def test_company_aliases_and_benefits_lists():
    from server.models.reference import Benefit, Company

    b = Benefit(
        benefit_cd="meal",
        benefit_nm="식대",
        benefit_ctgr_cd="compensation",
        badge_cd="official",
        amt_source="stated",
        qual_yn=False,
    )
    c = Company(
        comp_id=1,
        comp_eng_nm="testco",
        comp_nm="테스트기업",
        comp_tp_cd="large",
        aliases=["테스트기업", "testco"],
        benefits=[b],
    )
    assert c.aliases == ["테스트기업", "testco"]
    assert len(c.benefits) == 1
    assert c.work_style_val is None


def test_reference_bundle_top_level_exactly_three_keys():
    from server.models.reference import ReferenceBundle

    bundle = ReferenceBundle(company_types=[], benefit_presets={}, companies=[])
    keys = set(bundle.model_dump().keys())
    assert keys == {"company_types", "benefit_presets", "companies"}


def test_company_search_item_five_fields_only():
    from server.models.company import CompanySearchItem

    item = CompanySearchItem(
        comp_id=1, comp_nm="테스트기업", comp_tp_cd="large", industry_nm="IT", logo_nm="T"
    )
    dumped = item.model_dump()
    assert set(dumped.keys()) == {"comp_id", "comp_nm", "comp_tp_cd", "industry_nm", "logo_nm"}
    # 축소 투영 — 복지/별칭/근무형태 필드 부재
    assert not hasattr(item, "benefits")
    assert not hasattr(item, "aliases")
    assert not hasattr(item, "work_style_val")


def test_health_response_status_field():
    from server.models.common import HealthResponse

    hr = HealthResponse(status="ok")
    assert hr.status == "ok"


def test_error_envelope_detail_field():
    from server.models.common import ErrorEnvelope

    ee = ErrorEnvelope(detail="일시적인 오류가 발생했습니다.")
    assert ee.detail
