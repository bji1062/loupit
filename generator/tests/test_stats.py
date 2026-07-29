"""T-07.14 번들 집계 통계 (GC-28).

가이드 A군 6편이 소비하는 수치의 계약. **이 테스트가 존재하는 이유**: 가이드
본문의 숫자를 하드코딩하면 데이터가 바뀐 순간 글이 조용히 거짓이 된다. 수치는
빌드타임 파생값이어야 하고, 그 파생이 실데이터와 맞는지는 여기서 강제한다.

기대값은 전부 `generator/tests/fixtures.py` 의 3개사 8행에서 손으로 센 것이다.
"""
from __future__ import annotations

import pytest

from generator.context import build_context
from generator.stats import build_stats, dist


@pytest.fixture
def stats(fake_bundle, fake_now):
    return build_stats(build_context(fake_bundle, now=fake_now))


# ── 분포 헬퍼 ──────────────────────────────────────────────────────


def test_gc28_dist_basic():
    d = dist([4, 2, 2])
    assert (d.min, d.max, d.count) == (2, 4, 3)
    assert d.median == 2
    assert d.mean == pytest.approx(8 / 3)


def test_gc28_dist_even_count_median_is_midpoint():
    assert dist([1, 2, 3, 4]).median == 2.5


def test_gc28_dist_empty_is_none_not_zero():
    """빈 표본의 중앙값은 0이 아니라 '없음'이다 — 0은 사실 주장이 된다."""
    d = dist([])
    assert d.count == 0 and d.median is None and d.mean is None


# ── 전체 규모 ──────────────────────────────────────────────────────


def test_gc28_totals(stats):
    assert stats.company_count == 3
    assert stats.benefit_count == 8


def test_gc28_benefits_per_company(stats):
    d = stats.benefits_per_company
    assert (d.min, d.median, d.max) == (2, 2, 4)


# ── 9카테고리 ──────────────────────────────────────────────────────


def test_gc28_categories_follow_canonical_order_and_omit_absent(stats):
    from generator.pages.company import CATEGORY_ORDER

    keys = [c.key for c in stats.categories]
    assert keys == [k for k in CATEGORY_ORDER if k in set(keys)], "9카테고리 정본 순서가 아니다"
    assert "flexibility" not in keys, "픽스처에 없는 카테고리가 들어왔다"


def test_gc28_category_counts(stats):
    by_key = {c.key: c for c in stats.categories}
    assert by_key["compensation"].item_count == 2
    assert by_key["compensation"].company_count == 2
    assert by_key["perks"].item_count == 1
    assert by_key["perks"].company_count == 1


def test_gc28_category_company_share_is_percent_of_all_companies(stats):
    by_key = {c.key: c for c in stats.categories}
    assert by_key["compensation"].company_share == pytest.approx(200 / 3)


# ── 업종·기업유형 ───────────────────────────────────────────────────


def test_gc28_industry_groups(stats):
    by_name = {g.name: g for g in stats.industries}
    assert by_name["반도체"].company_count == 2
    assert by_name["IT"].company_count == 1


def test_gc28_company_type_groups_use_label_not_code(stats):
    names = {g.name for g in stats.company_types}
    assert "대기업" in names, "comp_tp_nm 라벨이 아니라 코드가 노출됐다"


def test_gc28_unknown_company_type_is_not_invented(stats):
    """types 테이블에 없는 코드('unlisted')는 라벨을 지어내지 않는다(UC-41 1a)."""
    by_name = {g.name: g for g in stats.company_types}
    assert "unlisted" not in by_name
    assert by_name["대기업"].company_count == 2


# ── 근무형태 도입률 ─────────────────────────────────────────────────


def test_gc28_work_style_adoption(stats):
    by_key = {w.key: w for w in stats.work_style}
    assert by_key["flex"].company_count == 3
    assert by_key["flex"].share == pytest.approx(100.0)
    assert by_key["remote"].company_count == 2
    assert by_key["unlimitedPTO"].company_count == 1


def test_gc28_work_style_has_korean_labels(stats):
    assert {w.label for w in stats.work_style} >= {"재택근무", "유연근무"}


# ── 금액 환산 분포 ──────────────────────────────────────────────────


def test_gc28_quantified_value_per_company(stats):
    """정량 복지 금액 합(만원). 정성 항목은 합계에 들어가면 안 된다."""
    d = stats.company_value
    assert sorted(d.values) == [100, 1440, 5030]
    assert d.median == 1440


def test_gc28_quant_vs_qual_split(stats):
    assert stats.quantified_count == 5
    assert stats.qualitative_count == 3
    assert stats.quantified_count + stats.qualitative_count == stats.benefit_count


# ── 신뢰도·출처 (방법론 가이드 B군이 소비) ──────────────────────────────


def test_gc28_amount_confidence_counts(stats):
    assert stats.amt_source["stated"] == 3
    assert stats.amt_source["estimated"] == 5


def test_gc28_source_kind_counts(stats):
    assert stats.badge_src["scrape_official"] == 4
    assert stats.badge_src["manual_estimate"] == 3


def test_gc28_source_url_coverage_rejects_unsafe_scheme(stats):
    """`javascript:` 출처는 커버리지에 세면 안 된다 — 링크로 쓸 수 없는 값이다."""
    assert stats.src_url_count == 5
    assert stats.src_url_share == pytest.approx(500 / 8)


# ── 흔한 복지 ──────────────────────────────────────────────────────


def test_gc28_top_benefit_names_are_sorted_desc_then_name(stats):
    names = stats.top_benefit_names
    counts = [n.count for n in names]
    assert counts == sorted(counts, reverse=True)
    assert all(n.count >= 1 for n in names)


def test_gc28_stats_are_deterministic(fake_bundle, fake_now):
    """같은 번들 → 같은 결과. 빌드마다 글의 숫자가 흔들리면 안 된다."""
    a = build_stats(build_context(fake_bundle, now=fake_now))
    b = build_stats(build_context(fake_bundle, now=fake_now))
    assert a == b
