"""전역 상단 탭(GNB) 동기화 계약 (2026-08-27, PLAN-커뮤니티-회사정보탭 §3-1).

정본은 `generator/content/nav.py::GNB_TABS` 하나다. 헤더가 두 종류라(초록 gnb 수기 셸 7 +
생성기 partial) 탭을 한쪽에만 넣으면 페이지를 오갈 때 탭이 나타났다 사라진다. 수기 셸은
상수를 import 할 수 없으므로 **문자열로** 동기화를 검증한다(`test_authnav.py` 와 같은 방식).

계약 셋:
  (1) 모든 헤더의 주 메뉴에서 **탭 href 로 걸러낸 링크 열**이 `GNB_TABS` 와 라벨·순서까지 같다.
  (2) 탭이 가리키는 곳은 실재해야 한다 — 생성 페이지이거나 문서 루트 셸(죽은 탭 금지).
  (3) `aria-current="page"` 는 헤더당 최대 1개이고, 붙는다면 그 페이지가 속한 탭에만 붙는다.
"""
from __future__ import annotations

import re
from pathlib import Path

from generator.config import CFG
from generator.content.nav import GNB_TABS, GNB_TAB_HREFS
from generator.context import build_context
from generator.pages import combo, company, company_index, policy
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
WEB = REPO_ROOT / "web"
SHELLS = {
    "index.html": WEB / "index.html",
    "compare/index.html": WEB / "compare" / "index.html",
    "login.html": WEB / "login.html",
    "mypage.html": WEB / "mypage.html",
    "verify.html": WEB / "verify.html",
    "edit.html": WEB / "edit.html",
    "edits.html": WEB / "edits.html",
    "community/index.html": WEB / "community" / "index.html",  # SC15(2026-08-27)
}

_HEADER_RE = re.compile(r"<header[^>]*>(.*?)</header>", re.S | re.I)
_A_RE = re.compile(r"<a\b([^>]*)\bhref=\"([^\"]+)\"([^>]*)>(.*?)</a>", re.S | re.I)
_TAG_RE = re.compile(r"<[^>]+>")


def _header_links(html: str) -> list[tuple[str, str, str]]:
    """헤더 안 `<a>` 전부 → `[(href, 텍스트 라벨, 여는 태그 속성)]`."""
    m = _HEADER_RE.search(html)
    assert m, "header 랜드마크 없음"
    out = []
    for pre, href, post, inner in _A_RE.findall(m.group(1)):
        label = _TAG_RE.sub("", inner).strip()
        out.append((href, label, pre + post))
    return out


_BRAND_CLASS_RE = re.compile(r'class="[^"]*\b(?:brand|site-logo)\b[^"]*"')


def _tab_sequence(html: str) -> list[tuple[str, str]]:
    """탭 href 로 걸러낸 링크 열. 로고(`.brand`·`.site-logo`)도 `/` 를 가리키지만 탭이 아니다."""
    return [
        (label, href)
        for href, label, attrs in _header_links(html)
        if href in GNB_TAB_HREFS and not _BRAND_CLASS_RE.search(attrs)
    ]


def _all_pages(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    return (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )


# ── (1) 동기화 ───────────────────────────────────────────────────────────────


def test_gnb_tabs_constant_is_well_formed():
    labels = [l for l, _ in GNB_TABS]
    hrefs = [h for _, h in GNB_TABS]
    assert GNB_TABS[0] == ("홈", "/"), "첫 탭은 홈"
    assert len(set(hrefs)) == len(hrefs) and len(set(labels)) == len(labels), "탭 라벨·href 중복"
    assert all(h.startswith("/") for h in hrefs)


def test_generated_pages_carry_gnb_tabs_in_order(fake_bundle, fake_now, fake_combinations_path):
    pages = _all_pages(fake_bundle, fake_now)
    assert pages
    for p in pages:
        assert _tab_sequence(p.html) == list(GNB_TABS), f"{p.path}: 상단 탭이 정본과 다르다"


def test_hand_written_shells_carry_gnb_tabs_in_order():
    for name, f in SHELLS.items():
        assert f.is_file(), f"{name} 셸 없음"
        assert _tab_sequence(f.read_text(encoding="utf-8")) == list(GNB_TABS), (
            f"{name}: 상단 탭이 generator/content/nav.py::GNB_TABS 와 다르다"
        )


# ── (2) 죽은 탭 금지 ─────────────────────────────────────────────────────────


def test_every_tab_target_exists(fake_bundle, fake_now, fake_combinations_path):
    """탭 href 는 생성 페이지 라우트이거나 문서 루트의 셸이어야 한다."""
    generated = {"/" + p.path[: -len(".html")] for p in _all_pages(fake_bundle, fake_now) if p.path.endswith(".html")}
    for _, href in GNB_TABS:
        if href in generated:
            continue
        shell = WEB / ("index.html" if href == "/" else href.strip("/") + "/index.html")
        assert shell.is_file(), f"탭 {href} 가 가리키는 페이지가 없다(생성물도 셸도 아님) — 죽은 탭"


# ── (3) 현재 탭 표시 ─────────────────────────────────────────────────────────


def _current_hrefs(html: str) -> list[str]:
    return [href for href, _, attrs in _header_links(html) if 'aria-current="page"' in attrs]


def test_aria_current_marks_only_the_owning_tab(fake_bundle, fake_now, fake_combinations_path):
    for p in _all_pages(fake_bundle, fake_now):
        cur = _current_hrefs(p.html)
        assert len(cur) <= 1, f"{p.path}: aria-current 가 {len(cur)}개"
        if p.path == "companies.html" or p.path.startswith("company/"):
            assert cur == ["/companies"], f"{p.path}: 회사정보 탭이 현재 탭이어야 한다"
        else:
            assert cur == [], f"{p.path}: 속한 탭이 없는 페이지에 aria-current 가 붙었다"


def test_landing_shell_marks_home_as_current():
    html = SHELLS["index.html"].read_text(encoding="utf-8")
    assert _current_hrefs(html) == ["/"]
    assert _current_hrefs(SHELLS["community/index.html"].read_text(encoding="utf-8")) == ["/community/"]
    for name in ("compare/index.html", "login.html", "mypage.html", "verify.html", "edit.html", "edits.html"):
        assert _current_hrefs(SHELLS[name].read_text(encoding="utf-8")) == [], f"{name}: 잘못된 현재 탭"
