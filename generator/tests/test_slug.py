"""T-07.3 slug 규칙·조합 경로·충돌 검증 (SP-GEN-3, GC-3·GC-4)."""
from __future__ import annotations

import re

import pytest

from generator.slug import BuildError, combo_slug, slug_of, validate_combo_paths, validate_slugs

SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


# ── GC-3: slug 정규화·유일성 ────────────────────────────────────────────────


@pytest.mark.parametrize(
    "eng,expected",
    [
        ("samsung_elec", "samsung-elec"),
        ("sk_hynix", "sk-hynix"),
        ("cj", "cj"),
        ("  Naver  ", "naver"),
        ("S-Oil", "s-oil"),
        ("a___b", "a-b"),
    ],
)
def test_gc3_slug_of_normalizes(eng, expected):
    assert slug_of(eng) == expected


def test_gc3_slug_of_matches_url_pattern():
    for eng in ("samsung_elec", "sk_hynix", "cj", "hyundai-mobis", "S_Oil Corp"):
        assert SLUG_RE.match(slug_of(eng))


def test_gc3_slug_of_empty_raises_build_error():
    with pytest.raises(BuildError):
        slug_of("___")


def test_gc3_slug_of_invalid_raises_build_error_on_empty_after_strip():
    with pytest.raises(BuildError):
        slug_of("")


def test_gc3_validate_slugs_returns_unique_mapping():
    companies = [
        {"comp_eng_nm": "samsung_elec"},
        {"comp_eng_nm": "sk_hynix"},
        {"comp_eng_nm": "naver"},
    ]
    slugs = validate_slugs(companies)
    assert slugs == {
        "samsung_elec": "samsung-elec",
        "sk_hynix": "sk-hynix",
        "naver": "naver",
    }
    assert len(set(slugs.values())) == len(companies)


def test_gc3_validate_slugs_collision_raises_build_error():
    # 서로 다른 COMP_ENG_NM이 동일 slug로 정규화되는 충돌 데이터
    companies = [
        {"comp_eng_nm": "sk_hynix"},
        {"comp_eng_nm": "sk-hynix"},  # 동일 slug "sk-hynix"
    ]
    with pytest.raises(BuildError):
        validate_slugs(companies)


# ── GC-4: 조합 경로 정렬·유일·충돌 ──────────────────────────────────────────


def test_gc4_combo_slug_sorts_lexicographically():
    slugs = {"a": "samsung-elec", "b": "sk-hynix"}
    path, first, second = combo_slug("a", "b", slugs)
    assert first <= second
    assert path == f"{first}-{second}"
    assert path == "samsung-elec-sk-hynix"


def test_gc4_combo_slug_is_order_independent():
    slugs = {"a": "samsung-elec", "b": "sk-hynix"}
    p1, f1, s1 = combo_slug("a", "b", slugs)
    p2, f2, s2 = combo_slug("b", "a", slugs)
    assert p1 == p2
    assert (f1, s1) == (f2, s2)


def test_gc4_validate_combo_paths_unique_ok():
    slugs = {"a": "samsung-elec", "b": "sk-hynix", "c": "naver"}
    pairs = [("a", "b"), ("b", "c")]
    result = validate_combo_paths(pairs, slugs)
    assert set(result.keys()) == {"samsung-elec-sk-hynix", "naver-sk-hynix"}


def test_gc4_validate_combo_paths_collision_raises_build_error():
    # 세그먼트 모호성: ("a-b","c") vs ("a","b-c") 모두 "a-b-c" 문자열 생성
    slugs = {"x1": "a-b", "x2": "c", "x3": "a", "x4": "b-c"}
    pairs = [("x1", "x2"), ("x3", "x4")]
    with pytest.raises(BuildError):
        validate_combo_paths(pairs, slugs)
