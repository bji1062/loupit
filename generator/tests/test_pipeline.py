"""T-07.1·7.11 파이프라인 전체 구동·Tier-0 게이트 (GC-1·GC-2·GC-10).

GC-2(회사 개수·INV-6)·GC-10(비-JS 본문·INV-3)은 배포 차단 Tier-0 게이트다.
"""
from __future__ import annotations

import re

import pytest

from generator import build as build_module
from generator.checks import _check_company_count, _check_non_js_body, run_generated_checks
from generator.context import build_context
from generator.pages import combo, company, policy
from generator.render import make_env
from generator.slug import BuildError

_SCRIPT_RE = re.compile(r"<script\b[^>]*>.*?</script>", re.IGNORECASE | re.DOTALL)


def _run_pipeline(fake_bundle, fake_now, out_dir):
    return build_module.run(str(out_dir), fake_bundle, lastmod="2026-07-11")


# ── GC-1: 파이프라인 무예외·개수 ────────────────────────────────────────────


def test_gc1_run_succeeds_without_exception(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    rc = _run_pipeline(fake_bundle, fake_now, tmp_path / "dist")
    assert rc == 0


def test_gc1_generates_expected_page_counts(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    company_pages = company.render_all(env, ctx)
    policy_pages = policy.render_all(env, ctx)
    assert len(company_pages) == 3  # fake 번들 회사 3
    assert len(policy_pages) == 5  # 정책 4 + 404


def test_gc1_generates_two_combos_with_fake_combinations(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    from generator.config import CFG

    combo_pages = combo.render_all(env, ctx, CFG)
    assert len(combo_pages) == 2  # 유효 2(무효 1은 스킵, GC-23)


def test_gc1_dist_tree_contains_sitemap_and_robots(fake_bundle, fake_now, fake_combinations_path, tmp_path):
    out_dir = tmp_path / "dist"
    _run_pipeline(fake_bundle, fake_now, out_dir)
    assert (out_dir / "sitemap.xml").exists()
    assert (out_dir / "robots.txt").exists()
    for f in ("privacy.html", "terms.html", "disclaimer.html", "ads.html", "404.html"):
        assert (out_dir / f).exists()


# ── GC-2 (Tier-0, INV-6): 회사 페이지 개수 ≈ 번들 회사 수, 200 아님 ─────────


def test_gc2_company_page_count_equals_bundle_company_count(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = company.render_all(env, ctx)
    assert len(pages) == len(fake_bundle["companies"]) == 3


def test_gc2_company_count_is_never_200_guard_rejects_it():
    """INV-6 회귀 — 200개 회사 페이지가 검출되면 빌드 실패해야 한다."""
    from generator.context import Page

    fake_200_pages = [
        Page(path=f"company/c{i}.html", url=f"https://jobcho.wiki/company/c{i}", html="<h1>x</h1>복지", title="t", description="d")
        for i in range(200)
    ]
    with pytest.raises(BuildError):
        _check_company_count(fake_200_pages)


def test_gc2_zero_company_pages_rejected():
    with pytest.raises(BuildError):
        _check_company_count([])


def test_gc2_run_generated_checks_passes_for_fake_bundle_pipeline(
    fake_bundle, fake_now, fake_combinations_path
):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    from generator.config import CFG

    pages = company.render_all(env, ctx) + combo.render_all(env, ctx, CFG) + policy.render_all(env, ctx)
    run_generated_checks("unused", pages)  # 예외 없어야 GREEN


# ── GC-10 (Tier-0, INV-3): script 제거 후 회사명·복지 항목명 잔존 ──────────


def test_gc10_company_page_readable_without_script(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = company.render_all(env, ctx)
    for p, c in zip(pages, fake_bundle["companies"]):
        stripped = _SCRIPT_RE.sub("", p.html)
        assert c["comp_nm"] in stripped
        assert any(b["benefit_nm"] in stripped for b in c["benefits"])


def test_gc10_combo_page_readable_without_script(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    from generator.config import CFG

    pages = combo.render_all(env, ctx, CFG)
    assert pages, "조합 페이지가 최소 1개 생성돼야 검증 가능"
    for p in pages:
        stripped = _SCRIPT_RE.sub("", p.html)
        assert "<h1>" in stripped
        assert "복지" in stripped


def test_gc10_check_non_js_body_rejects_missing_content():
    from generator.context import Page

    bad_page = Page(
        path="company/empty.html",
        url="https://jobcho.wiki/company/empty",
        html="<html><body>no h1 no keyword</body></html>",
        title="t",
        description="d",
    )
    with pytest.raises(BuildError):
        _check_non_js_body([bad_page])
