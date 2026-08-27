"""히트맵 `/heatmap` (SP-HEAT, 2026-08-27) — 배치 불변식·그룹 기준·표현 규약.

배치는 빌드 시점 계산이라 "그려졌는가"를 브라우저 없이 수치로 잰다: 면적 합이 캔버스와 같고,
칸이 캔버스 밖으로 나가지 않고, 서로 겹치지 않으며, 회사가 하나도 빠지지 않는다(첫 목업에서
작은 그룹의 15곳이 조용히 사라졌다 — 그 실패를 여기서 잡는다).
"""
from __future__ import annotations

import copy
import re

import pytest

from generator.config import CFG
from generator.context import build_context
from generator.pages import heatmap
from generator.render import make_env
from generator.sector import UNLISTED, load_sectors, sector_of
from generator.tests.fixtures import FAKE_BUNDLE, FAKE_FINANCE
from generator.treemap import nested_layout, squarify

SECTORS = {"005930": "전기·전자", "035420": "IT 서비스", "035760": "오락·문화"}


def _ctx(with_finance=True):
    return build_context(copy.deepcopy(FAKE_BUNDLE), finance=copy.deepcopy(FAKE_FINANCE) if with_finance else None)


# ── treemap 순수 함수 ────────────────────────────────────────────────────────


def test_squarify_areas_are_proportional_and_fill_the_box():
    tiles = squarify([(6, "a"), (3, "b"), (1, "c")], 0, 0, 100, 50)
    assert {t[0] for t in tiles} == {"a", "b", "c"}
    area = {t[0]: t[3] * t[4] for t in tiles}
    assert area["a"] == pytest.approx(3000) and area["b"] == pytest.approx(1500) and area["c"] == pytest.approx(500)
    assert sum(area.values()) == pytest.approx(5000)
    for _, x, y, w, h in tiles:
        assert x >= -1e-9 and y >= -1e-9 and x + w <= 100 + 1e-6 and y + h <= 50 + 1e-6


def test_squarify_drops_zero_weights_and_handles_empty():
    assert squarify([], 0, 0, 10, 10) == []
    assert [t[0] for t in squarify([(0, "z"), (2, "a")], 0, 0, 10, 10)] == ["a"]


def test_nested_layout_keeps_every_member_even_in_tiny_groups():
    """그룹이 아주 작아도 안쪽 회사 타일이 사라지면 안 된다(면적 음수 → 조용한 누락)."""
    groups = {"big": [(1000, "b1"), (500, "b2")], "tiny": [(1, "t1")], "tiny2": [(1, "t2")]}
    heads, tiles = nested_layout(groups, 100, 62.5)
    assert {h.name for h in heads} == set(groups)
    assert {t.obj for t in tiles} == {"b1", "b2", "t1", "t2"}
    for t in tiles:
        assert t.w > 0 and t.h > 0


def _no_overlap(rects):
    for i, a in enumerate(rects):
        for b in rects[i + 1:]:
            ox = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
            oy = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
            assert not (ox > 1e-6 and oy > 1e-6), f"타일 겹침: {a} vs {b}"


# ── 뷰모델 ───────────────────────────────────────────────────────────────────


def test_view_welfare_mode_places_every_company_in_both_orientations():
    view = heatmap.build_view(_ctx(), SECTORS)
    w = next(m for m in view["modes"] if m["key"] == "w")
    names = {c["comp_nm"] for c in FAKE_BUNDLE["companies"]}
    for orient, lay in w["layouts"].items():
        assert {t["nm"] for t in lay["tiles"]} == names, orient
        rects = [(t["x"], t["y"], t["w"], t["h"]) for t in lay["tiles"]]
        _no_overlap(rects)
        for x, y, ww, hh in rects:
            assert -1e-6 <= x and -1e-6 <= y and x + ww <= 100.001 and y + hh <= 100.001
        assert sum(g["w"] * g["h"] for g in lay["groups"]) == pytest.approx(100 * 100, rel=1e-6)


def test_view_groups_by_krx_sector_and_unlisted_fallback():
    view = heatmap.build_view(_ctx(), SECTORS)
    w = next(m for m in view["modes"] if m["key"] == "w")
    groups = {g["name"] for g in w["layouts"]["landscape"]["groups"]}
    assert "전기·전자" in groups and "IT 서비스" in groups
    assert UNLISTED in groups  # 재무 매핑이 없는 회사(comp_id 2)는 비상장 그룹
    assert sector_of(None, SECTORS) == UNLISTED
    assert sector_of({"stock_cd": "999999"}, SECTORS) == UNLISTED
    assert sector_of({"stock_cd": "005930"}, SECTORS) == "전기·전자"


def test_view_finance_mode_excludes_financial_and_unmapped_and_needs_two_years():
    view = heatmap.build_view(_ctx(), SECTORS)
    f = next(m for m in view["modes"] if m["key"] == "f")
    names = {t["nm"] for t in f["layouts"]["landscape"]["tiles"]}
    assert "삼성전자" in names
    assert "네이버" not in names  # 금융 세트(FAKE_FINANCE 3 = financial)
    assert f["count"] == len(names)
    tile = next(t for t in f["layouts"]["landscape"]["tiles"] if t["nm"] == "삼성전자")
    assert tile["cls"].startswith("d") and "%" in tile["sub"]


def test_view_without_finance_has_only_welfare_mode():
    view = heatmap.build_view(_ctx(with_finance=False), SECTORS)
    assert [m["key"] for m in view["modes"]] == ["w"]


def test_color_steps_cover_seven_bins():
    assert [heatmap.yoy_step(v) for v in (-40, -20, -5, 0, 5, 20, 40)] == [0, 1, 2, 3, 4, 5, 6]
    cuts = heatmap._quantile_cuts(list(range(1, 71)))
    assert len(cuts) == 6 and cuts == sorted(cuts)
    assert heatmap.seq_step(0, cuts) == 0 and heatmap.seq_step(10_000, cuts) == 6


# ── 페이지 ───────────────────────────────────────────────────────────────────


def _page():
    env = make_env()
    return heatmap.render(env, _ctx(), CFG)


def test_page_route_seo_and_nav():
    p = _page()
    assert p.path == "heatmap.html" and p.url == f"{CFG.site_origin}/heatmap" and p.in_sitemap
    assert p.title.endswith(CFG.site_name) and p.description
    assert f'<link rel="canonical" href="{CFG.site_origin}/heatmap">' in p.html
    assert 'href="/heatmap" aria-current="page"' in p.html
    assert "/assets/v2/css/heatmap.css" in p.html and "/assets/v2/js/heatmap.js" in p.html
    assert "data-page-type" not in p.html  # 광고 0


def test_page_is_readable_without_js_and_links_every_company():
    p = _page()
    html = re.sub(r"<script\b[^>]*>.*?</script>", "", p.html, flags=re.S)
    assert "<h1>" in html and "읽는 법" in html
    for c in FAKE_BUNDLE["companies"]:
        assert f'>{c["comp_nm"]}</b>' in html
    assert 'class="hm-map hm-landscape"' in html and 'class="hm-map hm-portrait"' in html
    assert "hidden" not in re.findall(r'<section class="hm-mode"[^>]*>', html)[0]  # JS 없으면 둘 다 보인다


def test_page_uses_only_facts_no_rating_words():
    p = _page()
    for bad in ("성장성", "등급", "전망", "우수", "양호", "추천"):
        assert bad not in p.html, bad


def test_sector_csv_loads_and_has_only_krx_sectors():
    sectors = load_sectors()
    assert len(sectors) >= 90, "krx_sector.csv 가 비었거나 크게 줄었다"
    assert all(re.fullmatch(r"\d{6}", k) for k in sectors)
    assert "005930" in sectors  # 삼성전자
