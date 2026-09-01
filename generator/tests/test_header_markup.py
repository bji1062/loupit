"""전역 헤더 마크업 동기화 계약 (2026-09-01).

**왜 있는가** — 사용자 신고: *"상단 메뉴를 누를 때마다 프레임이 변경된다. 회사정보·히트맵을
누르면 로고 마크가 사라진다."* 원인은 헤더가 두 벌이었다는 것이다. 수기 셸 8개는 초록 GNB
(`data-global` + `.brand` 로고 이미지)를 쓰는데 생성기 `partials/_header.html` 만 옛 텍스트
헤더(`.site-logo`)를 냈고, CSS 는 `header:not([data-global])` 로 그 차이를 성실히 유지하고
있었다. 즉 **스타일이 아니라 마크업이 갈라진 것**이라 눈으로만 잡히고 테스트로는 안 잡혔다.

여기서 고정하는 것은 "보기 좋음"이 아니라 **페이지를 오갈 때 헤더가 그대로인가**다:
  (1) 모든 헤더가 같은 셸을 쓴다 — `data-global class="gnb"`.
  (2) 브랜드 로고(이미지 + 점 강조)가 **모든** 페이지에 있다 — 사라진 그 마크다.
  (3) 옛 텍스트 헤더(`.site-logo`)는 어디에도 남지 않는다(회귀 차단).
  (4) 탭 뒤 링크 구성('비교 조합' + 로그인 슬롯)도 같다 — 링크가 하나 더/덜 있으면 그것도
      사용자에겐 '프레임 변경'이다.
탭 순서·라벨 자체는 `test_gnb_tabs.py` 소유라 여기서 다시 세지 않는다(중복 금지).
"""
from __future__ import annotations

import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, company_index, heatmap, policy
from generator.render import make_env
from generator.tests.test_gnb_tabs import SHELLS, _header_links

# 상단 메뉴로 **오가는** 셸 — 생성 페이지와 함께 헤더가 완전히 같아야 한다(사용자 신고의 범위).
NAV_SHELL_NAMES = frozenset({"index.html", "compare/index.html", "community/index.html"})
# 인증 흐름 안의 셸 — GNB 탭으로 도달하지 않는다(로그인 슬롯 경유). 브랜드·탭은 같게 두되
# 보조 링크(본문 바로가기·비교 조합·로그인 슬롯)는 의도적으로 줄인 상태다. 그 의도를 고정한다.
AUTH_SHELL_NAMES = frozenset(SHELLS) - NAV_SHELL_NAMES

_HEADER_OPEN_RE = re.compile(r"<header\b[^>]*>", re.I)
# 수기 셸과 바이트 동일해야 하는 브랜드 한 줄. 이 문자열이 곧 "잡초 마크"다.
BRAND_HTML = (
    '<a href="/" class="brand">'
    '<img class="brand-logo" src="/assets/v2/img/logo.svg" alt="" width="34" height="22">'
    'jobcho<span class="brand-dot">.</span>wiki</a>'
)


def _all_pages(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    return (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG)]
        + [heatmap.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )


def _shell_htmls(names: frozenset[str] | None = None) -> dict[str, str]:
    return {
        name: f.read_text(encoding="utf-8")
        for name, f in SHELLS.items()
        if names is None or name in names
    }


# ── (1) 같은 셸 ──────────────────────────────────────────────────────────────


def test_every_header_is_the_same_shell(fake_bundle, fake_now, fake_combinations_path):
    """`data-global` 이 CSS 분기의 키다 — 빠지면 그 페이지만 옛 레이아웃으로 돌아간다."""
    sources = {p.path: p.html for p in _all_pages(fake_bundle, fake_now)} | _shell_htmls()
    assert sources
    for name, html in sources.items():
        m = _HEADER_OPEN_RE.search(html)
        assert m, f"{name}: header 랜드마크 없음"
        tag = m.group(0)
        assert "data-global" in tag and 'class="gnb"' in tag, f"{name}: 헤더 셸이 다르다 — {tag}"


# ── (2) 브랜드 로고 ──────────────────────────────────────────────────────────


def test_every_header_carries_the_brand_logo(fake_bundle, fake_now, fake_combinations_path):
    """회사정보·히트맵에서 사라졌던 그 마크. 이미지 한 장이라 텍스트 대체로는 못 때운다."""
    sources = {p.path: p.html for p in _all_pages(fake_bundle, fake_now)} | _shell_htmls()
    for name, html in sources.items():
        assert BRAND_HTML in html, f"{name}: 브랜드 로고 마크업이 수기 셸과 다르다(또는 없다)"


def test_brand_text_matches_site_name():
    """로고 텍스트는 하드코딩이다(가운뎃점을 span 으로 감싸야 해서) — 설정과 어긋나면 잡는다."""
    plain = re.sub(r"<[^>]+>", "", BRAND_HTML)
    assert plain == CFG.site_name


# ── (3) 옛 헤더 회귀 차단 ────────────────────────────────────────────────────


def test_old_text_header_is_gone_everywhere(fake_bundle, fake_now, fake_combinations_path):
    sources = {p.path: p.html for p in _all_pages(fake_bundle, fake_now)} | _shell_htmls()
    for name, html in sources.items():
        assert "site-logo" not in html, f"{name}: 옛 텍스트 헤더(.site-logo)가 남아 있다"


# ── (4) 탭 뒤 구성 ──────────────────────────────────────────────────────────


def test_trailing_links_are_identical(fake_bundle, fake_now, fake_combinations_path):
    """탭 다음에 오는 것도 같아야 한다 — '비교 조합'(랜딩 레일 앵커) + 로그인 슬롯.

    생성 페이지는 `/#trending`, 랜딩 자신은 같은 문서 안이라 `#trending` 이다(둘 다 같은 곳).
    """
    for p in _all_pages(fake_bundle, fake_now):
        hrefs = [h for h, _, _ in _header_links(p.html)]
        assert "/#trending" in hrefs, f"{p.path}: '비교 조합' 링크 없음"
        assert "/compare" not in hrefs and CFG.compare_path not in hrefs, (
            f"{p.path}: GNB 에 비교하기 링크가 남아 있다 — 수기 셸엔 없어 구성이 갈린다"
            " (회사 상세는 본문에 비교 CTA 를 이미 갖고 있다)"
        )
        assert 'data-authnav' in p.html, f"{p.path}: 로그인 슬롯 없음"
    for name, html in _shell_htmls(NAV_SHELL_NAMES).items():
        hrefs = [h for h, _, _ in _header_links(html)]
        assert any(h in ("#trending", "/#trending") for h in hrefs), f"{name}: '비교 조합' 링크 없음"


# ── (5) skip-link 는 실재하는 곳을 가리킨다 ──────────────────────────────────


def test_skip_link_target_exists(fake_bundle, fake_now, fake_combinations_path):
    """`#main-heading` 이 없으면 '본문 바로가기'가 아무 데도 안 간다(죽은 UI)."""
    sources = {p.path: p.html for p in _all_pages(fake_bundle, fake_now)} | _shell_htmls(NAV_SHELL_NAMES)
    for name, html in sources.items():
        assert 'href="#main-heading"' in html, f"{name}: skip-link 없음"
        assert 'id="main-heading"' in html, f"{name}: skip-link 대상(#main-heading)이 없다"


# ── (6) 인증 흐름 셸: 브랜드·탭은 같고 보조 링크만 줄인다 ────────────────────


def test_auth_shells_keep_brand_and_tabs_but_drop_extras():
    """로그인 계열은 GNB 탭으로 도달하지 않는다 — 축소가 **의도**임을 고정한다.

    로고와 탭까지 줄이면 사용자는 여기서도 '프레임이 바뀐다'고 느낀다(그래서 그 둘은 검사한다).
    반대로 본문 바로가기·비교 조합·로그인 슬롯은 인증 화면에서 의미가 없어 빼 둔 것이다 —
    누군가 '통일'하려고 되살리면 이 테스트가 그 판단을 다시 꺼내 보게 한다.
    """
    for name, html in _shell_htmls(AUTH_SHELL_NAMES).items():
        assert BRAND_HTML in html, f"{name}: 브랜드 로고가 없다"
        hrefs = [h for h, _, _ in _header_links(html)]
        assert "/companies" in hrefs and "/heatmap" in hrefs, f"{name}: 탭이 빠졌다"
        assert not any(h in ("#trending", "/#trending") for h in hrefs), (
            f"{name}: 인증 화면에 '비교 조합' 링크가 생겼다 — 의도 변경이면 이 테스트도 함께 고쳐라"
        )
