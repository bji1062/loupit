"""T-07.15 가이드 콘텐츠 `/guide` (GC-29, SC11).

2026-07-21 AdSense "가치 없는 콘텐츠" 반려 대응으로 신설한 편집 콘텐츠의 계약.
여기서 강제하는 것은 세 가지다 — **충분한 분량**, **본문 수치와 실데이터의 일치**,
**계산 상수와 엔진의 일치**. 셋 중 하나라도 무너지면 이 콘텐츠는 반려 사유를
해소하기는커녕 거짓말을 실은 페이지가 된다.
"""
from __future__ import annotations

import re
from pathlib import Path

import pytest

from generator.config import CFG
from generator.content import guides as G
from generator.content.guides import build_guide_docs, related_for
from generator.context import build_context
from generator.pages import guide
from generator.quality import visible_text_len
from generator.render import make_env
from generator.stats import build_stats

CALC_JS = Path(__file__).resolve().parents[2] / "web" / "assets" / "js" / "calc.js"

# 본문 최소 분량 — 임계(1,000자)의 두 배. 임계를 겨우 넘는 글은 "얇지 않다"일 뿐
# "읽을 값어치가 있다"가 아니다. 편집 콘텐츠의 기준은 그보다 높아야 한다.
MIN_ARTICLE_CHARS = 2000


@pytest.fixture
def stats(fake_bundle, fake_now):
    return build_stats(build_context(fake_bundle, now=fake_now))


@pytest.fixture
def docs(stats):
    return build_guide_docs(stats)


@pytest.fixture
def pages(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return guide.render_all(env, ctx, CFG)


# ── 분량·구성 ───────────────────────────────────────────────────────


def test_gc29_twelve_guides_plus_index(pages):
    assert len(pages) == 13, "가이드 12편 + 인덱스 1"
    assert {p.path for p in pages} >= {"guide.html"}


def test_gc29_every_article_meets_min_length(pages):
    """임계 통과가 아니라 '읽을 분량'을 강제한다."""
    for p in pages:
        if p.path == "guide.html":
            continue
        n = visible_text_len(p.html)
        assert n >= MIN_ARTICLE_CHARS, f"{p.path}: 본문 {n}자 (최소 {MIN_ARTICLE_CHARS})"


def test_gc29_no_guide_is_noindexed(pages):
    """편집 콘텐츠가 임계에 걸리면 신설한 의미가 없다."""
    for p in pages:
        assert p.noindex is False, f"{p.path}: 가이드가 색인에서 빠졌다"
        assert p.in_sitemap is True


def test_gc29_every_section_has_prose(docs):
    """표만 있고 문장이 없는 절은 데이터 덤프지 글이 아니다."""
    for d in docs:
        assert d.sections, f"{d.slug}: 절이 없다"
        for s in d.sections:
            assert s.paragraphs, f"{d.slug}#{s.anchor}: 문단이 없다"
            assert sum(len(p) for p in s.paragraphs) >= 120, f"{d.slug}#{s.anchor}: 문단이 너무 짧다"


def test_gc29_all_three_groups_present(docs):
    groups = {d.group for d in docs}
    assert groups == {"data", "method", "practical"}


# ── SEO 계약 (기존 test_seo_meta 규칙과 동일) ──────────────────────────


def test_gc29_titles_and_descriptions_are_unique(pages):
    titles = [p.title for p in pages]
    descs = [p.description for p in pages]
    assert len(set(titles)) == len(titles), "중복 title"
    assert len(set(descs)) == len(descs), "중복 meta description"


def test_gc29_description_within_limit(pages):
    for p in pages:
        assert len(p.description) <= CFG.desc_max, f"{p.path}: description {len(p.description)}자"


def test_gc29_canonical_matches_url(pages):
    for p in pages:
        assert f'<link rel="canonical" href="{p.url}">' in p.html


def test_gc29_articles_carry_article_jsonld(pages):
    for p in pages:
        if p.path == "guide.html":
            continue
        # jsonld 필터가 compact separators 를 쓴다(format.jsonld_dumps).
        assert '"@type":"Article"' in p.html


def test_gc29_slugs_are_url_safe(docs):
    for d in docs:
        assert re.fullmatch(r"[a-z0-9-]+", d.slug), f"{d.slug}: slug 문자 규칙 위반"


# ── 링크망 (고아 방지, GC-26 과 같은 발상) ─────────────────────────────


def test_gc29_every_guide_links_out(docs):
    for d in docs:
        rel = related_for(d, docs)
        assert rel, f"{d.slug}: 관련 글 링크 0건"
        assert all(route != d.route for _, route in rel), f"{d.slug}: 자기 자신을 링크"


def test_gc29_no_group_is_a_closed_sink(docs):
    """묶음 안에서만 링크가 돌면 크롤러가 그 묶음에 갇힌다."""
    for d in docs:
        routes = {route for _, route in related_for(d, docs)}
        outside = {x.route for x in docs if x.group != d.group}
        assert routes & outside, f"{d.slug}: 묶음 밖으로 나가는 링크가 없다"


def test_gc29_index_links_every_article(pages, docs):
    index = next(p for p in pages if p.path == "guide.html")
    for d in docs:
        assert f'href="{d.route}"' in index.html, f"인덱스가 {d.slug} 를 링크하지 않는다"


# ── 수치가 실데이터에서 온다 (핵심 계약) ──────────────────────────────


def test_gc29_numbers_track_the_data(fake_bundle, fake_now):
    """번들을 바꾸면 본문 숫자도 바뀌어야 한다 — 하드코딩이면 이 테스트가 잡는다."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    before = {p.path: p.html for p in guide.render_all(env, ctx, CFG)}

    trimmed = dict(fake_bundle)
    trimmed["companies"] = fake_bundle["companies"][:2]  # 회사 3 → 2
    after = {p.path: p.html for p in guide.render_all(env, build_context(trimmed, now=fake_now), CFG)}

    landscape = "guide/benefit-landscape-2026.html"
    assert before[landscape] != after[landscape], "회사 수가 줄었는데 본문이 그대로다"


def test_gc29_landscape_states_actual_counts(pages, stats):
    p = next(x for x in pages if x.path == "guide/benefit-landscape-2026.html")
    assert f"{stats.company_count:,}" in p.html
    assert f"{stats.benefit_count:,}" in p.html


def test_gc29_empty_sample_says_so_instead_of_zero(stats):
    """표본이 없을 때 0으로 단정하지 않는다 — 0은 사실 주장이다."""
    assert G._n(None) == "집계 없음"
    assert G._mw(None) == "집계 없음"
    assert G._pct(None) == "집계 없음"


# ── 계산 상수가 엔진과 일치한다 (정책 문안의 _RETENTION 과 같은 패턴) ─────


def _js_const(name: str) -> str:
    src = CALC_JS.read_text(encoding="utf-8")
    m = re.search(rf"export const {name}\s*=\s*([^;]+);", src)
    assert m, f"calc.js 에서 {name} 을 찾지 못했다"
    return m.group(1)


@pytest.mark.parametrize(
    "js_name,py_value",
    [
        ("MONTHLY_STD_HRS", G.MONTHLY_STD_HRS),
        ("OT_MULT", G.OT_MULT),
        ("WEEKS_PER_MONTH", G.WEEKS_PER_MONTH),
        ("WEEKS_PER_YEAR", G.WEEKS_PER_YEAR),
        ("LEGAL_WEEK_HRS", G.LEGAL_WEEK_HRS),
        ("COMMUTE_WORKDAYS", G.COMMUTE_WORKDAYS),
        ("COMMUTE_ROUND_TRIP", G.COMMUTE_ROUND_TRIP),
        ("BAND_EXPIRE", G.BAND_EXPIRE),
    ],
)
def test_gc29_scalar_constants_match_calc_js(js_name, py_value):
    """방법론 글이 인용하는 상수가 실제 계산 엔진과 어긋나면 글이 거짓이 된다."""
    raw = _js_const(js_name).split("//")[0].strip()
    assert float(raw) == float(py_value), f"{js_name}: 문안 {py_value} vs calc.js {raw}"


def test_gc29_band_base_matches_calc_js():
    raw = _js_const("BAND_BASE")
    assert f"stated: {G.BAND_STATED}" in raw
    assert f"estimated: {G.BAND_ESTIMATED}" in raw


def test_gc29_uncertainty_guide_quotes_the_bands(pages):
    p = next(x for x in pages if x.path == "guide/uncertainty-band.html")
    assert f"±{int(G.BAND_STATED * 100)}%" in p.html
    assert f"±{int(G.BAND_ESTIMATED * 100)}%" in p.html
    # 만료는 가산이지 치환이 아니다 — 합산값이 본문에 실제로 나와야 한다.
    assert f"±{int((G.BAND_ESTIMATED + G.BAND_EXPIRE) * 100)}%" in p.html


def test_gc29_anchor_guide_shows_the_basis_not_just_the_number(pages):
    """앵커는 산출식과 같이 나와야 한다 — 숫자만 공개하면 검증할 수 없다."""
    p = next(x for x in pages if x.path == "guide/amount-anchors.html")
    for name, value, basis in G.AMOUNT_ANCHORS:
        assert name in p.html
        assert f"{value:,}만원" in p.html
        assert basis in p.html


# ── XSS 회귀 (기존 GC-21 과 같은 계약) ────────────────────────────────


def test_gc29_company_names_are_escaped_in_guides(fake_bundle_xss, fake_now):
    """업종·복지 이름이 본문 표에 들어가므로 이스케이프가 유지돼야 한다."""
    env = make_env()
    ctx = build_context(fake_bundle_xss, now=fake_now)
    for p in guide.render_all(env, ctx, CFG):
        assert "<script>alert(1)</script>" not in p.html


# ── 한국어 표기 품질 ─────────────────────────────────────────────────


def test_gc29_no_escaped_apostrophe_entities_in_prose(pages):
    """산문에 곧은 작은따옴표를 쓰면 autoescape 가 `&#39;` 로 바꾼다.

    브라우저에서는 정상 렌더되지만 본문 인용에 활자 따옴표(“ ”)를 쓰기로 했으므로,
    `&#39;` 가 남아 있다는 것은 치환을 빠뜨렸다는 신호다.
    """
    for p in pages:
        assert "&#39;" not in p.html, f"{p.path}: 곧은 따옴표 잔존"


def test_gc29_josa_agrees_with_preceding_noun():
    """받침에 따라 조사가 갈린다 — 데이터에서 온 라벨에 조사를 고정하면 비문이 된다."""
    assert G._josa("보상", "로") == "으로"       # 받침 ㅇ
    assert G._josa("유연성", "로") == "으로"     # 받침 ㅇ
    assert G._josa("휴가", "로") == "로"         # 받침 없음
    assert G._josa("복리후생", "로") == "으로"   # 받침 ㅇ
    assert G._josa("서울", "로") == "로"         # 받침 ㄹ = 예외
    assert G._josa("건강", "이") == "이"
    assert G._josa("휴가", "이") == "가"


def test_gc29_landscape_prose_has_no_broken_particle(pages):
    """실제 렌더 결과에 "'…'로" 형태의 비문이 없어야 한다."""
    p = next(x for x in pages if x.path == "guide/benefit-landscape-2026.html")
    assert "”로 " not in p.html or "”으로 " in p.html
