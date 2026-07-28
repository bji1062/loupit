"""로그인 진입점 슬롯 계약 검증 (SC14, 2026-07-28).

핵심 계약은 "슬롯은 **정적으로는 숨겨진 채** 모든 헤더에 존재한다"이다. 이유:

  생성물(`web/dist/*`)은 prod 와 beta 가 **같은 바이트를 서빙**한다 — beta 체크아웃의
  `web/dist` 가 프로덕션 dist 로 가는 심링크다. 따라서 "beta 에만 로그인 버튼"을 빌드
  시점에 만드는 것이 원리적으로 불가능하고, 갈라내기는 런타임(`authnav.js` 가
  `/members/me` 를 프로브: 404=꺼짐/401=로그인/200=닉네임)이 전담한다.

  그래서 **정적 HTML 이 로그인 링크를 노출하면 그 자체가 결함**이다. prod 는 로그인
  페이지를 nginx 가 404 로 막고 있고(`infra/nginx/loupit.conf` M9 차단 블록), 라이브
  정책 문안(`/privacy`·`/terms`)이 "로그인·계정 기능 없음"을 선언 중이라, 눌리는 진입점이
  공개되면 고지 위반이 된다. 이 테스트가 그 회귀를 막는다.

(b) 수기 셸(`web/index.html`·`web/compare/index.html`)은 생성기를 거치지 않는 하드코딩
    HTML 이라 상수를 import 할 수 없다 → 마크업 **동기화**를 문자열로 검증한다
    (`test_footer_links.py` 가 같은 방식을 쓴다).
"""
from __future__ import annotations

import re
from pathlib import Path

from generator.context import build_context
from generator.pages import combo, company, policy
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
SHELLS = (REPO_ROOT / "web" / "index.html", REPO_ROOT / "web" / "compare" / "index.html")
PARTIAL = REPO_ROOT / "generator" / "templates" / "partials" / "_authnav.html"

_SLOT_RE = re.compile(r"<a\b[^>]*\bdata-authnav\b[^>]*>", re.I)
_HEADER_RE = re.compile(r"<header[^>]*>(.*?)</header>", re.S | re.I)


def _slot_tag(html: str) -> str:
    m = _SLOT_RE.search(html)
    assert m, "data-authnav 슬롯을 찾을 수 없음"
    return m.group(0)


def _rendered_pages(fake_bundle, fake_now, fake_combinations_path=None):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = list(company.render_all(env, ctx)) + list(policy.render_all(env, ctx))
    return pages


# ── 슬롯 존재 + 기본 숨김 ────────────────────────────────────────────────────


def test_generated_pages_carry_hidden_authnav_slot(fake_bundle, fake_now):
    """생성 페이지 전부가 슬롯을 갖고, 그 슬롯은 `hidden` 이어야 한다."""
    pages = _rendered_pages(fake_bundle, fake_now)
    assert pages, "렌더된 페이지가 없음"
    for p in pages:
        tag = _slot_tag(p.html)
        assert "hidden" in tag, f"{p.path}: 슬롯이 hidden 이 아니다 — prod 에 진입점이 노출된다"


def test_shells_carry_hidden_authnav_slot():
    """수기 셸도 동일하게 슬롯 + hidden."""
    for f in SHELLS:
        tag = _slot_tag(f.read_text(encoding="utf-8"))
        assert "hidden" in tag, f"{f.name}: 슬롯이 hidden 이 아니다"


def test_slot_lives_inside_the_header_landmark(fake_bundle, fake_now):
    """진입점은 전역 헤더 랜드마크 안에 있어야 한다(NFR13)."""
    for p in _rendered_pages(fake_bundle, fake_now):
        head = _HEADER_RE.search(p.html)
        assert head, f"{p.path}: header 랜드마크 없음"
        assert _SLOT_RE.search(head.group(1)), f"{p.path}: 슬롯이 header 밖에 있다"
    for f in SHELLS:
        head = _HEADER_RE.search(f.read_text(encoding="utf-8"))
        assert head and _SLOT_RE.search(head.group(1)), f"{f.name}: 슬롯이 header 밖에 있다"


# ── 정적 노출 금지(회귀 방지의 본체) ────────────────────────────────────────


def test_no_visible_login_link_in_static_html(fake_bundle, fake_now):
    """`/login`·`/mypage` 로 가는 링크는 **hidden 슬롯 그 하나뿐**이어야 한다.

    누군가 "그냥 링크 하나 넣자"로 되돌리면 여기서 잡힌다 — 그 변경은 prod 에
    눌리는(그리고 404 로 떨어지는) 진입점을 공개한다.
    """
    hrefs = re.compile(r'href="(/login|/mypage|/verify|/edit|/edits)(?:[/?#][^"]*)?"')
    for p in _rendered_pages(fake_bundle, fake_now):
        for m in hrefs.finditer(p.html):
            # 이 href 를 담은 <a ...> 여는 태그를 되짚어 hidden·data-authnav 인지 본다
            start = p.html.rfind("<a", 0, m.start())
            end = p.html.find(">", m.start())
            tag = p.html[start:end + 1]
            assert "data-authnav" in tag and "hidden" in tag, (
                f"{p.path}: 정적 HTML 이 노출된 M9 링크를 갖고 있다 → {tag[:120]}"
            )


def test_slot_markup_is_in_sync_between_partial_and_shells():
    """생성기 partial 과 수기 셸의 슬롯 여는 태그가 **같아야** 한다(드리프트 차단)."""
    ref = _slot_tag(PARTIAL.read_text(encoding="utf-8"))
    for f in SHELLS:
        got = _slot_tag(f.read_text(encoding="utf-8"))
        assert got == ref, f"{f.name}: 슬롯 마크업이 partial 과 다르다\n  partial={ref}\n  shell  ={got}"


def test_slot_has_label_element_for_nickname():
    """닉네임을 textContent 로 넣을 대상(`data-authnav-label`)이 있어야 한다."""
    for src in (PARTIAL, *SHELLS):
        assert "data-authnav-label" in src.read_text(encoding="utf-8"), f"{src.name}: 라벨 요소 없음"


# ── 스크립트 배선 ────────────────────────────────────────────────────────────


def test_authnav_script_is_wired(fake_bundle, fake_now):
    """슬롯만 있고 스크립트가 없으면 영원히 숨겨진 채로 남는다."""
    for p in _rendered_pages(fake_bundle, fake_now):
        assert "js/authnav.js" in p.html, f"{p.path}: authnav.js 스크립트 태그 없음"
    for f in SHELLS:
        assert "js/authnav.js" in f.read_text(encoding="utf-8"), f"{f.name}: authnav.js 없음"
