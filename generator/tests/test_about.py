"""T-07.16 소개·문의 페이지 (GC-30).

2026-07-29 신설. 그전까지 사이트에는 운영 주체를 밝히는 페이지도, 독립된 문의
창구도 없었다 — 연락처가 정책 페이지 안쪽 블록에만 있었다.

여기서 강제하는 것은 **존재**와 **연결**이다. 페이지가 있어도 어디서도 링크되지
않으면 심사관도 크롤러도 도달하지 못한다.
"""
from __future__ import annotations

import dataclasses

from generator.config import CFG
from generator.content.about import ABOUT_KEYS, build_about_docs
from generator.context import build_context
from generator.pages import about
from generator.quality import visible_text_len
from generator.render import make_env


def _pages(fake_bundle, fake_now, cfg=CFG):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return {p.path: p for p in about.render_all(env, ctx, cfg)}


def test_gc30_both_pages_render(fake_bundle, fake_now):
    pages = _pages(fake_bundle, fake_now)
    assert set(pages) == {"about.html", "contact.html"}


def test_gc30_both_are_indexable(fake_bundle, fake_now):
    """신뢰 페이지는 색인돼야 값어치가 있다."""
    for p in _pages(fake_bundle, fake_now).values():
        assert p.in_sitemap is True
        assert p.noindex is False
        assert '<meta name="robots"' not in p.html


def test_gc30_pages_have_substance(fake_bundle, fake_now):
    """빈 소개 페이지는 없느니만 못하다."""
    for path, p in _pages(fake_bundle, fake_now).items():
        n = visible_text_len(p.html)
        assert n >= 1200, f"{path}: 본문 {n}자"


def test_gc30_about_states_limits_not_only_claims(fake_bundle, fake_now):
    """소개 페이지가 한계를 밝혀야 한다 — 자랑만 있는 소개는 신뢰를 깎는다."""
    html = _pages(fake_bundle, fake_now)["about.html"].html
    assert "지금 못 하고 있는 것" in html


def test_gc30_contact_is_shown_and_linked(fake_bundle, fake_now):
    for p in _pages(fake_bundle, fake_now).values():
        assert CFG.policy_contact in p.html
        assert f'href="mailto:{CFG.policy_contact}"' in p.html


def test_gc30_contact_falls_back_to_text_for_non_email(fake_bundle, fake_now):
    """이메일이 아닌 연락처 값이 들어와도 임의 스킴으로 링크하지 않는다(NFR21)."""
    cfg = dataclasses.replace(CFG, policy_contact="추후 공지")
    for p in _pages(fake_bundle, fake_now, cfg).values():
        assert "추후 공지" in p.html
        assert 'href="mailto:추후 공지"' not in p.html


def test_gc30_pages_cross_link_each_other(fake_bundle, fake_now):
    pages = _pages(fake_bundle, fake_now)
    assert 'href="/contact"' in pages["about.html"].html
    assert 'href="/about"' in pages["contact.html"].html


def test_gc30_seo_meta_is_unique_and_bounded(fake_bundle, fake_now):
    pages = list(_pages(fake_bundle, fake_now).values())
    assert len({p.title for p in pages}) == len(pages)
    assert len({p.description for p in pages}) == len(pages)
    for p in pages:
        assert len(p.description) <= CFG.desc_max
        assert f'<link rel="canonical" href="{p.url}">' in p.html


def test_gc30_no_ads_on_trust_pages(fake_bundle, fake_now):
    """신뢰가 목적인 페이지에 광고를 얹으면 목적과 충돌한다 → page_type 미선언."""
    for p in _pages(fake_bundle, fake_now).values():
        assert "data-page-type" not in p.html


def test_gc30_doc_keys_match_declared_set():
    assert tuple(d.key for d in build_about_docs(CFG)) == ABOUT_KEYS
