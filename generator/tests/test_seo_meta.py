"""T-07.6·7.6·7.11.5 SEO head·JSON-LD·중복 검증 (GC-5·7·8·9·26)."""
from __future__ import annotations

import json
import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, company_index, heatmap, policy
from generator.render import make_env

_TAG_COUNT_PATTERNS = {
    "title": re.compile(r"<title>"),
    "meta_description": re.compile(r'<meta name="description"'),
    "canonical": re.compile(r'<link rel="canonical"'),
    "og:title": re.compile(r'<meta property="og:title"'),
    "og:description": re.compile(r'<meta property="og:description"'),
    "og:type": re.compile(r'<meta property="og:type"'),
    "og:url": re.compile(r'<meta property="og:url"'),
    "og:image": re.compile(r'<meta property="og:image"'),
}


def _all_pages(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return company.render_all(env, ctx) + combo.render_all(env, ctx, CFG)


# ── GC-5: 필수 태그 각 정확히 1 ──────────────────────────────────────────


def test_gc5_company_page_has_each_seo_tag_exactly_once(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    for name, pattern in _TAG_COUNT_PATTERNS.items():
        assert len(pattern.findall(p.html)) == 1, f"{name} 개수 != 1"


def test_gc5_combo_page_has_each_seo_tag_exactly_once(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = combo.render_all(env, ctx, CFG)[0]
    for name, pattern in _TAG_COUNT_PATTERNS.items():
        assert len(pattern.findall(p.html)) == 1, f"{name} 개수 != 1"


# ── GC-7: 페이지 간 title·description 중복 0 ────────────────────────────


def test_gc7_titles_and_descriptions_are_unique_across_all_pages(fake_bundle, fake_now, fake_combinations_path):
    pages = _all_pages(fake_bundle, fake_now, fake_combinations_path)
    titles = [p.title for p in pages]
    descs = [p.description for p in pages]
    assert len(titles) == len(set(titles)), f"title 중복: {titles}"
    assert len(descs) == len(set(descs)), f"description 중복: {descs}"


# ── GC-8: canonical == og:url == 자기 URL ───────────────────────────────


def test_gc8_company_canonical_equals_og_url_equals_self_url(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    canonical = re.search(r'<link rel="canonical" href="([^"]+)">', p.html).group(1)
    og_url = re.search(r'<meta property="og:url" content="([^"]+)">', p.html).group(1)
    assert canonical == og_url == p.url


def test_gc8_combo_canonical_equals_og_url_equals_self_url(fake_bundle, fake_now, fake_combinations_path):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = combo.render_all(env, ctx, CFG)[0]
    canonical = re.search(r'<link rel="canonical" href="([^"]+)">', p.html).group(1)
    og_url = re.search(r'<meta property="og:url" content="([^"]+)">', p.html).group(1)
    # 계약은 셋의 일치이지 오리진 리터럴이 아니다(함정 0079).
    assert canonical == og_url == p.url == f"{CFG.site_origin}/vs/samsung-elec-sk-hynix"


# ── GC-9: JSON-LD 파싱 오류 0·필드 정확·부재 키 확인 ────────────────────────


def test_gc9_company_jsonld_parses_and_has_organization_fields(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    m = re.search(r'<script type="application/ld\+json">(.*?)</script>', p.html, re.S)
    assert m, "JSON-LD <script> 미검출"
    data = json.loads(m.group(1))  # 파싱 오류 0
    assert data["@type"] == "Organization"
    assert data["name"] == "삼성전자"
    assert "samsung_elec" in data["alternateName"]
    for forbidden in ("logo", "image", "address", "telephone"):
        assert forbidden not in data


# ── GC-26: lang·charset·한글 무결성 ──────────────────────────────────────


def test_gc26_html_lang_ko_and_charset_utf8(fake_bundle, fake_now, fake_combinations_path):
    for p in _all_pages(fake_bundle, fake_now, fake_combinations_path):
        assert '<html lang="ko">' in p.html
        assert '<meta charset="utf-8">' in p.html


def test_gc26_korean_text_not_mangled(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    p = company.render_all(env, ctx)[0]
    assert "삼성전자" in p.html
    assert "식대 지원" in p.html


# ── 404 색인 차단 — 오류 페이지에만 noindex, 콘텐츠 페이지는 무영향 ──────────
#
# 계기: 2026-07-30 링크 전수 감사(`docs/HANDOFF-2026-07-30.md` §5-a). 404 에 robots
# 메타가 없고 **자기 canonical** (`https://jobcho.wiki/404`)이 있어 오류 페이지가 색인
# 대상이 될 수 있었다(감사가 잡은 내부 404 1건이 바로 이 canonical 이다 —
# `infra/verify/link-audit.py` 는 href/src/action 만 수집하므로 og:url 은 무관).
#
# 이 대역의 **유일한 실질 위험은 전역 오염**이다. `_head_meta.html` 은 전 페이지가
# 공유하는 partial 이라, 거기 붙인 noindex 가 회사·조합·정책까지 번지면 사이트 전체가
# 검색에서 사라진다. 그래서 아래는 항상 **양방향**으로 확인한다 — 404 에 있는가,
# 그리고 콘텐츠 페이지에 없는가. 한 방향만 있는 테스트는 이 사고를 못 잡는다.

_ROBOTS_RE = re.compile(r'<meta name="robots" content="([^"]*)">')
_CANONICAL_RE = re.compile(r'<link rel="canonical" href="([^"]+)">')


def _all_indexable_pages(fake_bundle, fake_now):
    """색인돼야 하는 전 페이지(회사·회사인덱스·조합·정책 4종). 404 는 제외.

    `test_links._build_all_pages` 와 같이 프로덕션(`build.run`)과 동일 배선으로
    만든다 — combo_pairs 를 넘기지 않으면 회사 페이지 일부가 사각지대에 남는다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    pages = (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG)]
        + [heatmap.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )
    return [p for p in pages if p.path != "404.html"]


def _page_404(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    found = [p for p in policy.render_all(env, ctx) if p.path == "404.html"]
    assert len(found) == 1, f"404 페이지 개수 != 1: {len(found)}"
    return found[0]


def test_404_page_has_noindex_robots_meta(fake_bundle, fake_now, fake_combinations_path):
    """404 에 `noindex` robots 메타가 정확히 1개."""
    p = _page_404(fake_bundle, fake_now)
    found = _ROBOTS_RE.findall(p.html)
    assert len(found) == 1, f"404 robots 메타 개수 != 1: {found}"
    assert "noindex" in found[0], f"404 robots 에 noindex 없음: {found[0]}"


def test_404_page_has_no_self_canonical(fake_bundle, fake_now, fake_combinations_path):
    """404 는 자기 canonical 을 방출하지 않는다.

    `/404` 는 서빙되는 라우트가 아니라 nginx `error_page` 본문이다 — 그 URL 을
    canonical 로 선언하는 것은 (a) 404 를 반환하는 URL 을 가리키는 죽은 링크이고
    (b) noindex 와 충돌하는 신호다. 둘 다 없애는 편이 맞다.
    """
    p = _page_404(fake_bundle, fake_now)
    assert _CANONICAL_RE.findall(p.html) == [], "404 에 canonical 이 남아 있다"


def test_404_page_is_excluded_from_sitemap(fake_bundle, fake_now, fake_combinations_path):
    """`in_sitemap=False` — sitemap 이 색인을 다시 권유하면 noindex 가 무의미해진다."""
    assert _page_404(fake_bundle, fake_now).in_sitemap is False


def test_content_pages_have_no_robots_meta(fake_bundle, fake_now, fake_combinations_path):
    """회사·조합·정책·회사인덱스 어디에도 robots 메타가 붙지 않는다(← 전역 오염 가드).

    이 서비스는 검색 유입이 수익의 뼈대다. 콘텐츠 페이지에 noindex 가 새어 나가는
    것은 이 대역이 만들 수 있는 유일한 중대 사고이므로 전 페이지를 훑는다.
    """
    polluted = [
        (p.path, _ROBOTS_RE.findall(p.html))
        for p in _all_indexable_pages(fake_bundle, fake_now)
        if _ROBOTS_RE.findall(p.html)
    ]
    assert not polluted, f"콘텐츠 페이지에 robots 메타가 붙었다: {polluted}"


def test_content_pages_never_contain_noindex(fake_bundle, fake_now, fake_combinations_path):
    """`noindex` 문자열 자체가 콘텐츠 페이지 HTML 어디에도 없다(태그 형태 무관 가드)."""
    polluted = [p.path for p in _all_indexable_pages(fake_bundle, fake_now) if "noindex" in p.html]
    assert not polluted, f"콘텐츠 페이지에 noindex 가 새어 나갔다: {polluted}"


def test_indexable_pages_keep_exactly_one_self_canonical(fake_bundle, fake_now, fake_combinations_path):
    """색인 대상 전 페이지는 여전히 자기 canonical 을 정확히 1개 유지한다.

    404 의 canonical 을 없애려면 공유 partial 의 canonical 방출을 조건부로 만들어야
    한다. 그 조건이 헐거우면 **콘텐츠 페이지의 canonical 이 조용히 사라진다** —
    중복 콘텐츠(조합 A-B/B-A)가 곧바로 색인 문제가 되는 구조라 여기서 못박는다.
    """
    for p in _all_indexable_pages(fake_bundle, fake_now):
        found = _CANONICAL_RE.findall(p.html)
        assert found == [p.url], f"{p.path}: canonical 이 자기 URL 1개가 아니다 — {found}"
