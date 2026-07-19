"""T-09.9.1·9.9.2 전역 푸터 링크 정합 검증 (PC-5).

(a) SP-GEN 생성 페이지(company/combo/policy) 푸터가 `POLICY_FOOTER_LINKS`를
    순회 렌더해 라벨·라우트가 일치하는지(SP-GEN 소유, 본 세션이 구현·검증).
(b) SP-FE 수기 셸 `web/index.html`·`web/compare/index.html` 푸터 4정책
    링크가 `POLICY_FOOTER_LINKS`와 일치하는지(무빌드 정적 HTML — 하드코딩,
    상수 import 불가. SP-FE(M6) 소유 파일이며 본 세션은 web/ 코드를
    수정하지 않는다 — 검증만).

(b)는 저장소 현재 상태를 있는 그대로 검증한다. `web/compare/index.html`은
M0 스캐폴드가 남긴 자리표시자 라우트(`/policy/privacy` 등)를 쓰고 있어
`POLICY_FOOTER_LINKS`(`/privacy` 등)와 **불일치**하며, `web/index.html`은
아직 존재하지 않는다(SP-FE M6 본체 셸 미착수). 이 두 실패는 SP-GEN(07)
구현 결함이 아니라 **SP-FE(06, M6) 핸드오프 블로커**이며, 해당 파일을
고치는 것은 본 세션의 범위(web/ 코드 금지) 밖이다 — 의도적으로 실패
상태로 남겨 다음 SP-FE 세션이 정확히 무엇을 맞춰야 하는지 드러낸다
(가짜 green 금지).
"""
from __future__ import annotations

import re
from pathlib import Path

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import build_context
from generator.pages import combo, company, policy
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
LANDING_SHELL = REPO_ROOT / "web" / "index.html"
COMPARE_SHELL = REPO_ROOT / "web" / "compare" / "index.html"

_FOOTER_BLOCK_RE = re.compile(r"<footer[^>]*>(.*?)</footer>", re.S | re.I)
# 정책 링크 nav만 추출한다 — PC-5의 계약은 "정책 4종 라벨·라우트 정합"이지
# "푸터에 다른 링크가 없음"이 아니다(2026-07-19 푸터에 회사 인덱스 진입문 nav 추가).
_POLICY_NAV_RE = re.compile(r'<nav aria-label="정책 링크"[^>]*>(.*?)</nav>', re.S)
_SITE_NAV_RE = re.compile(r'<nav aria-label="사이트 탐색"[^>]*>(.*?)</nav>', re.S)
_LINK_RE = re.compile(r'<a href="([^"]+)">([^<]*)</a>')


def _extract_footer_links(html: str) -> list[tuple[str, str]]:
    """푸터의 **정책 링크 nav** 내부 `<a href>` 목록 → `[(label, route)]`."""
    footer = _FOOTER_BLOCK_RE.search(html)
    assert footer, "footer 요소를 찾을 수 없음"
    nav = _POLICY_NAV_RE.search(footer.group(1))
    assert nav, '푸터에 <nav aria-label="정책 링크"> 없음'
    return [(label.strip(), href) for href, label in _LINK_RE.findall(nav.group(1))]


def _extract_site_nav_links(html: str) -> list[tuple[str, str]]:
    """푸터의 사이트 탐색 nav(회사 인덱스 진입문) → `[(label, route)]`."""
    footer = _FOOTER_BLOCK_RE.search(html)
    assert footer, "footer 요소를 찾을 수 없음"
    nav = _SITE_NAV_RE.search(footer.group(1))
    return [(label.strip(), href) for href, label in _LINK_RE.findall(nav.group(1))] if nav else []


# ── (a) 생성 페이지(SP-GEN) 푸터 — POLICY_FOOTER_LINKS 순회 렌더 일치 ───────


def test_pc5_company_page_footer_matches_policy_footer_links(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    links = _extract_footer_links(p.html)
    assert links == list(POLICY_FOOTER_LINKS)


def test_pc5_combo_page_footer_matches_policy_footer_links(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = combo.render_all(env, ctx, CFG)[0]
    links = _extract_footer_links(p.html)
    assert links == list(POLICY_FOOTER_LINKS)


def test_pc5_policy_pages_footer_matches_policy_footer_links_including_self(fake_bundle, fake_now):
    """정책 페이지 자신도 포함해 4링크 전부(자기 자신 포함) 순회 렌더돼야 한다."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    for p in policy.render_all(env, ctx):
        if p.path == "404.html":
            continue
        links = _extract_footer_links(p.html)
        assert links == list(POLICY_FOOTER_LINKS)


def test_pc5_generated_footer_links_target_no_404(fake_bundle, fake_now):
    """생성 페이지 푸터 링크 대상은 모두 정책 4종(실제 생성 파일)과 일치 — 404 없음."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    generated_policy_routes = {f"/{p.path[:-5]}" for p in policy.render_all(env, ctx) if p.path != "404.html"}
    assert generated_policy_routes == {route for _, route in POLICY_FOOTER_LINKS}


# ── (b) 수기 셸(SP-FE, M6) 푸터 — 정합 검증(본 세션은 web/ 미수정) ─────────


def test_pc5_compare_shell_footer_matches_policy_footer_links():
    """`web/compare/index.html`은 존재하지만(M0 스캐폴드) 현재 푸터 라우트가
    `POLICY_FOOTER_LINKS`(`/privacy`·`/terms`·`/disclaimer`·`/ads`)와 다르다
    (`/policy/privacy` 등 접두 불일치 + `/terms` 링크 자체 부재). SP-FE(M6)
    핸드오프 블로커 — 본 세션은 web/ 코드를 고치지 않는다(가짜 green 금지)."""
    assert COMPARE_SHELL.exists(), "web/compare/index.html 존재해야 함(M0 스캐폴드)"
    html = COMPARE_SHELL.read_text(encoding="utf-8")
    links = _extract_footer_links(html)
    assert links == list(POLICY_FOOTER_LINKS), (
        "web/compare/index.html 푸터가 POLICY_FOOTER_LINKS와 불일치 — "
        f"실제={links} 기대={list(POLICY_FOOTER_LINKS)} "
        "(SP-FE M6 핸드오프: 라우트를 /privacy·/terms·/disclaimer·/ads로, "
        "라벨을 POLICY_FOOTER_LINKS와 동일하게 하드코딩 정정 필요)"
    )


def test_pc5_landing_shell_footer_matches_policy_footer_links():
    """`web/index.html`(랜딩)은 아직 생성되지 않았다(SP-FE M6 본체 셸 미착수,
    TASK/06 진행 롤업: 원시 6/46). PC-5 landing 측은 M6 착지 후 검증 가능."""
    assert LANDING_SHELL.exists(), (
        "web/index.html 미존재 — SP-FE(06, M6) 본체 셸 착수 후 재검증 필요 "
        "(SP-GEN·SP-POL 범위 밖, web/ 코드 작성 금지)"
    )
    html = LANDING_SHELL.read_text(encoding="utf-8")
    links = _extract_footer_links(html)
    assert links == list(POLICY_FOOTER_LINKS)


# ── GC-27b: 회사 인덱스 진입문이 전 페이지 푸터에 있는가 (2026-07-19) ────────
# 검수 반증: 회사 페이지끼리는 이어졌으나 랜딩·비교툴에서 그 덩어리로 들어가는
# 정적 링크가 0건이라 진입 경로가 sitemap 뿐이었다. 푸터 진입문이 그 문이다.

_INDEX_LINK = ("등록 회사 목록", "/companies")


def test_gc27b_generated_pages_footer_has_company_index_link(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = company.render_all(env, ctx) + combo.render_all(env, ctx, CFG) + policy.render_all(env, ctx)
    for p in pages:
        assert _INDEX_LINK in _extract_site_nav_links(p.html), f"{p.path}: 회사 인덱스 진입문 없음"


def test_gc27b_hand_written_shells_have_company_index_link():
    """수기 셸(랜딩·비교툴)은 상수 import가 불가한 무빌드 HTML이라 하드코딩 —
    크롤러가 루트로 들어왔을 때의 유일한 정적 진입문이므로 여기서 강제한다."""
    for shell in (LANDING_SHELL, COMPARE_SHELL):
        html = shell.read_text(encoding="utf-8")
        assert _INDEX_LINK in _extract_site_nav_links(html), f"{shell.name}: 회사 인덱스 진입문 없음"
