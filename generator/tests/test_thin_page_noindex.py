"""T-07.13 얇은 페이지 자동 noindex (GC-27).

배경: 2026-07-21 AdSense 심사가 "가치 없는 콘텐츠"로 반려됐다. 실측상 회사
페이지 95개 중 23개가 본문 1,000자 미만이라 사이트 평균 품질을 끌어내리고
있었다(`docs/HANDOFF-2026-07-19.md` §G-1).

여기서 강제하는 계약은 **고정 제외 목록이 아니라 빌드타임 임계 판정**이다 —
데이터가 보강되면 코드 변경 0으로 색인에 자동 복귀해야 한다.
"""
from __future__ import annotations

import dataclasses
import re

import pytest

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, policy, sitemap
from generator.quality import visible_text_len
from generator.render import make_env

ROBOTS_RE = re.compile(r'<meta name="robots" content="([^"]+)">')


# ── 측정법: §G-1 재현 ────────────────────────────────────────────────


def test_gc27_visible_text_len_strips_script_style_comment():
    """`<script>·<style>·주석`은 본문이 아니다 — §G-1 측정법과 동일해야 한다."""
    html = (
        "<html><head><style>body{color:red}</style>"
        "<script>var x = '아주 긴 스크립트 문자열입니다';</script></head>"
        "<body><!-- 주석은 본문이 아니다 --><p>본문</p></body></html>"
    )
    assert visible_text_len(html) == len("본문")


def test_gc27_visible_text_len_normalizes_whitespace():
    """태그 제거 후 공백 정규화 — 들여쓰기가 글자수를 부풀리면 안 된다."""
    html = "<div>\n   가   나\t\t다\n</div>"
    assert visible_text_len(html) == len("가 나 다")


def test_gc27_visible_text_len_counts_attribute_free_text_only():
    """속성값은 세지 않는다(본문에 보이지 않으므로)."""
    html = '<img alt="보이지 않는 매우 긴 대체 텍스트"><p>짧다</p>'
    assert visible_text_len(html) == len("짧다")


# ── 임계 판정: 회사 페이지 ─────────────────────────────────────────────


def _render_companies(env, ctx, min_chars, monkeypatch):
    monkeypatch.setattr(
        company, "CFG", dataclasses.replace(CFG, thin_page_min_chars=min_chars)
    )
    return company.render_all(env, ctx)


def test_gc27_thin_company_page_gets_noindex_and_leaves_sitemap(
    fake_bundle, fake_now, monkeypatch
):
    """임계를 아무도 넘지 못하는 값(매우 큼)에서는 전 페이지가 제외돼야 한다."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = _render_companies(env, ctx, 10**9, monkeypatch)

    assert pages, "회사 페이지가 렌더되지 않았다"
    for p in pages:
        assert p.noindex is True, f"{p.path}: 임계 미달인데 noindex 아님"
        assert p.in_sitemap is False, f"{p.path}: 임계 미달인데 sitemap 포함"
        assert ROBOTS_RE.search(p.html), f"{p.path}: robots 메타 없음"


def test_gc27_thick_company_page_has_no_robots_meta(fake_bundle, fake_now, monkeypatch):
    """임계를 전부 넘는 값(0)에서는 robots 메타가 아예 방출되지 않아야 한다.

    `noindex` 기본값이 조용히 색인을 막는 회귀를 잡는다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = _render_companies(env, ctx, 0, monkeypatch)

    for p in pages:
        assert p.noindex is False
        assert p.in_sitemap is True
        assert ROBOTS_RE.search(p.html) is None, f"{p.path}: 불필요한 robots 메타"


def test_gc27_noindex_keeps_follow(fake_bundle, fake_now, monkeypatch):
    """`nofollow` 가 아니라 `follow` 여야 한다.

    회사 페이지는 `related_companies` 가노다순 링으로 전 회사를 잇는다(GC-26).
    제외 페이지에서 링크 추적까지 끊으면 그 링이 끊겨 나머지 페이지 크롤 경로가
    사라진다 — 색인에서 빼는 것과 링크 그래프를 끊는 것은 다른 결정이다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = _render_companies(env, ctx, 10**9, monkeypatch)

    for p in pages:
        assert ROBOTS_RE.search(p.html).group(1) == "noindex, follow"


def test_gc27_threshold_is_the_only_switch(fake_bundle, fake_now, monkeypatch):
    """같은 페이지가 임계값만 바꿔 양쪽으로 갈려야 한다(하드코딩 목록 아님)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    lengths = [visible_text_len(p.html) for p in _render_companies(env, ctx, 0, monkeypatch)]
    mid = sorted(lengths)[len(lengths) // 2]

    pages = _render_companies(env, ctx, mid, monkeypatch)
    excluded = [p for p in pages if p.noindex]
    included = [p for p in pages if not p.noindex]
    assert excluded and included, "임계가 실제 분기를 만들지 못했다"
    assert all(visible_text_len(p.html) < mid for p in excluded)
    assert all(visible_text_len(p.html) >= mid for p in included)


# ── sitemap 연동 ────────────────────────────────────────────────────


def test_gc27_sitemap_omits_thin_pages(fake_bundle, fake_now, monkeypatch):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = _render_companies(env, ctx, 10**9, monkeypatch)
    urls = [p.url for p in pages if p.in_sitemap]
    sm = sitemap.render_sitemap(env, urls, "2026-07-29", CFG)
    assert re.findall(r"<loc>([^<]+)</loc>", sm.html) == []


# ── 조합 페이지: 손글씨 해설로 임계를 정면 통과 ─────────────────────────


def test_gc27_commented_combo_passes_threshold(fake_bundle, fake_now, fake_combinations_path):
    """해설이 있는 쌍(samsung_elec·sk_hynix)은 임계를 정면 통과해야 한다(§G-5-4 정합).

    구조만 같은 페이지를 양산하면 programmatic thin content 라 역효과다 —
    조합을 유지하려면 쌍마다 고유 해설이 있어야 한다는 것이 그 조사의 결론이다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = {p.path: p for p in combo.render_all(env, ctx, CFG)}
    p = pages["vs/samsung-elec-sk-hynix.html"]

    assert visible_text_len(p.html) >= CFG.thin_page_min_chars, (
        f"해설을 붙이고도 임계 미달({visible_text_len(p.html)}자)"
    )
    assert p.noindex is False and p.in_sitemap is True
    assert "이 비교를 읽는 법" in p.html


def test_gc27_uncommented_combo_is_excluded(fake_bundle, fake_now, fake_combinations_path):
    """해설 없는 쌍은 색인에서 빠지는 것이 정직한 결과다.

    해설 없이 색인에 남기면 그게 바로 §G-5-4 가 경고한 "구조 동일 페이지 양산"이다.
    """
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = {p.path: p for p in combo.render_all(env, ctx, CFG)}
    p = pages["vs/naver-sk-hynix.html"]  # 픽스처에만 있는 쌍 — 해설 미보유

    assert p.noindex is True and p.in_sitemap is False
    assert "이 비교를 읽는 법" not in p.html


def test_gc27_every_curated_pair_has_commentary():
    """프로덕션 큐레이션 목록의 **모든** 쌍이 해설을 보유해야 한다.

    조합을 추가하면서 해설을 빼먹으면 그 페이지는 조용히 색인에서 사라진다 —
    조용한 누락을 막는 것이 이 테스트의 전부다.
    """
    import json

    from generator.content.combos import commentary_for
    from generator.pages.combo import COMBINATIONS_PATH

    raw = json.loads(COMBINATIONS_PATH.read_text(encoding="utf-8"))
    for item in raw["combinations"]:
        paras = commentary_for(item["a"], item["b"])
        assert len(paras) >= 2, f"{item['a']}·{item['b']}: 해설 문단이 {len(paras)}개"
        assert sum(len(p) for p in paras) >= 400, f"{item['a']}·{item['b']}: 해설이 너무 짧다"


# ── 정책·404 회귀 ───────────────────────────────────────────────────


def test_gc27_policy_pages_never_carry_robots_meta(fake_bundle, fake_now):
    """정책 4종·404 는 임계 판정 대상이 아니다(고지 문서는 짧아도 필요하다)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    for p in policy.render_all(env, ctx):
        assert p.noindex is False
        assert ROBOTS_RE.search(p.html) is None


@pytest.mark.parametrize("field", ["noindex"])
def test_gc27_page_defaults_to_indexable(field):
    """`Page` 기본값이 색인 허용이어야 한다 — 새 페이지 타입이 조용히 빠지지 않도록."""
    from generator.context import Page

    p = Page(path="x.html", url="https://jobcho.wiki/x", html="", title="", description="")
    assert getattr(p, field) is False
