"""T-07.1·7.11 파이프라인 전체 구동·Tier-0 게이트 (GC-1·GC-2·GC-10).

GC-2(회사 개수·INV-6)·GC-10(비-JS 본문·INV-3)은 배포 차단 Tier-0 게이트다.
"""
from __future__ import annotations

import re

import pytest

from generator import build as build_module
from generator.checks import (
    _check_company_count,
    _check_home_present,
    _check_non_js_body,
    run_generated_checks,
)
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


def test_gc2_company_count_200_is_allowed_after_expansion_revision():
    """INV-6 개정(2026-09-01, PLAN-회사확장) — 구판의 `== 200 이면 BuildError` 트랩은 은퇴했다.

    그 가드가 지키던 실질(복지 없는 회사 페이지 금지)은 SD-5(DB, 회사별 복지 ≥1)와
    GC-10(페이지, script 제거 후 복지 본문 존재)이 이중으로 강제한다. 정상 확장이 200 을
    지나는 순간 오폭하지 않아야 한다 — 그 회귀를 여기서 고정한다."""
    from generator.context import Page

    fake_200_pages = [
        Page(path=f"company/c{i}.html", url=f"https://jobcho.wiki/company/c{i}", html="<h1>x</h1>복지", title="t", description="d")
        for i in range(200)
    ]
    _check_company_count(fake_200_pages)  # 예외 없어야 GREEN


def test_gc2_zero_company_pages_rejected():
    with pytest.raises(BuildError):
        _check_company_count([])


def test_gc2_run_generated_checks_passes_for_fake_bundle_pipeline(
    fake_bundle, fake_now, fake_combinations_path
):
    """게이트는 **실제 빌드가 내는 페이지 집합**으로 통과해야 한다 — 대문 포함(GC-28)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    from generator.config import CFG
    from generator.pages import home

    pages = (
        company.render_all(env, ctx)
        + combo.render_all(env, ctx, CFG)
        + policy.render_all(env, ctx)
        + [home.render(env, ctx, CFG, pairs=combo.load_pairs(ctx))]
    )
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


# ── GC-28 (Tier-0): 생성 대문 필수 ─────────────────────────────────────────
#
# 2026-09-15 후속 정리(PR #55)로 수기 셸 `web/index.html` 과 nginx 폴백
# (`try_files /dist/index.html /index.html`)을 걷었다. 이제 `/` 를 떠받치는 건
# 생성 대문 하나뿐이라, 대문이 빠진 산출물을 스왑하면 대문이 즉시 404 가 된다.
# 스모크(SM-1b)는 **스왑이 끝난 뒤** 보므로 그때는 이미 라이브가 죽어 있다 —
# 스왑 **전** 게이트에서 세운다.


def _home_page(html: str):
    from generator.context import Page

    return Page(path="index.html", url="https://jobcho.wiki/", html=html, title="t", description="d")


def _one_company():
    from generator.context import Page

    return Page(
        path="company/c1.html",
        url="https://jobcho.wiki/company/c1",
        html="<h1>회사</h1>복지",
        title="t",
        description="d",
    )


def test_gc28_missing_home_page_rejected():
    """대문이 통째로 빠진 산출물 — 다른 검사는 전부 통과해도 여기서 막혀야 한다."""
    with pytest.raises(BuildError, match="GC-28"):
        run_generated_checks("unused", [_one_company()])


def test_gc28_home_without_generated_marker_rejected():
    """경로만 맞고 내용이 엉뚱한 문서(옛 수기 셸·빈 셸)도 대문이 아니다."""
    with pytest.raises(BuildError, match="GC-28"):
        _check_home_present([_home_page("<html><body><div class='home'>대문 비슷한 것</div></body></html>")])


def test_gc28_marker_only_inside_script_rejected():
    """표식이 `<script>` 안에만 있으면 비-JS 크롤러에겐 없는 것과 같다(INV-3)."""
    with pytest.raises(BuildError, match="GC-28"):
        _check_home_present([_home_page("<html><body><script>var x='data-home-generated';</script></body></html>")])


def test_gc28_duplicate_home_pages_rejected():
    """대문 2개 = 어느 쪽이 스왑되는지 모른다. 개수 계약은 정확히 1이다."""
    with pytest.raises(BuildError, match="GC-28"):
        _check_home_present([_home_page("<div data-home-generated>x</div>")] * 2)


def test_gc28_real_generated_home_passes(fake_bundle, fake_now, fake_combinations_path):
    """실제 생성 대문은 통과해야 한다 — 게이트가 릴리스를 상시 막으면 안 된다."""
    from generator.config import CFG
    from generator.pages import home

    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    _check_home_present([home.render(env, ctx, CFG, pairs=combo.load_pairs(ctx))])  # 예외 없어야 GREEN
