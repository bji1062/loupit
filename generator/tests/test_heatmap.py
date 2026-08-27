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
    for orient, lay in w["panels"][0]["layouts"].items():
        assert {t["nm"] for t in lay["tiles"]} == names, orient
        rects = [(t["x"], t["y"], t["w"], t["h"]) for t in lay["tiles"]]
        _no_overlap(rects)
        for x, y, ww, hh in rects:
            assert -1e-6 <= x and -1e-6 <= y and x + ww <= 100.001 and y + hh <= 100.001
        assert sum(g["w"] * g["h"] for g in lay["groups"]) == pytest.approx(100 * 100, rel=1e-6)


def test_view_groups_by_krx_sector_and_unlisted_fallback():
    view = heatmap.build_view(_ctx(), SECTORS)
    w = next(m for m in view["modes"] if m["key"] == "w")
    groups = {g["name"] for g in w["panels"][0]["layouts"]["landscape"]["groups"]}
    assert "전기·전자" in groups and "IT 서비스" in groups
    assert UNLISTED in groups  # 재무 매핑이 없는 회사(comp_id 2)는 비상장 그룹
    assert sector_of(None, SECTORS) == UNLISTED
    assert sector_of({"stock_cd": "999999"}, SECTORS) == UNLISTED
    assert sector_of({"stock_cd": "005930"}, SECTORS) == "전기·전자"


def test_view_finance_mode_excludes_financial_and_unmapped_and_needs_two_years():
    view = heatmap.build_view(_ctx(), SECTORS)
    f = next(m for m in view["modes"] if m["key"] == "f")
    names = {t["nm"] for t in f["panels"][0]["layouts"]["landscape"]["tiles"]}
    assert "삼성전자" in names
    assert "네이버" not in names  # 금융 세트(FAKE_FINANCE 3 = financial)
    assert f["count"] == len(names)
    tile = next(t for t in f["panels"][0]["layouts"]["landscape"]["tiles"] if t["nm"] == "삼성전자")
    assert tile["cls"].startswith("d") and "%" in tile["sub"]


def test_view_without_finance_has_only_welfare_mode():
    view = heatmap.build_view(_ctx(with_finance=False), SECTORS)
    assert [m["key"] for m in view["modes"]] == ["w", "c"]  # 실적만 빠지고 카테고리는 남는다


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


# ── 카테고리 모드(항목 묶음 × 회사, 색 = 출처) ─────────────────────────────


def _cat_mode():
    return next(m for m in heatmap.build_view(_ctx(), SECTORS)["modes"] if m["key"] == "c")


def test_category_mode_has_one_panel_per_nonempty_category_in_canonical_order():
    from generator.pages.company import CATEGORY_ORDER
    keys = [p["key"] for p in _cat_mode()["panels"]]
    assert keys and keys == [k for k in CATEGORY_ORDER if k in keys]
    present = {b["benefit_ctgr_cd"] for c in FAKE_BUNDLE["companies"] for b in c["benefits"]}
    assert set(keys) == present


def test_category_panel_places_every_benefit_row_grouped_by_item_with_source_class():
    for p in _cat_mode()["panels"]:
        rows = [(c["comp_nm"], b) for c in FAKE_BUNDLE["companies"] for b in c["benefits"] if b["benefit_ctgr_cd"] == p["key"]]
        lay = p["layouts"]["landscape"]
        assert len(lay["tiles"]) == len(rows), p["key"]
        assert {t["cls"] for t in lay["tiles"]} <= {"s-stated", "s-est", "s-qual"}
        assert all(t["w"] > 0 and t["h"] > 0 for t in lay["tiles"])  # 정성도 최소 칸을 받는다
        _no_overlap([(t["x"], t["y"], t["w"], t["h"]) for t in lay["tiles"]])
        assert p["stated"] + p["est"] + p["qual"] == len(rows)
        assert p["groups"] == len({g["name"] for g in lay["groups"]})


def test_category_tile_source_and_hint():
    """공식 수치는 s-stated 이고 수정 안내가 없다; 추정·정성은 안내가 붙는다(참여 유입구)."""
    tiles = [t for p in _cat_mode()["panels"] for t in p["layouts"]["landscape"]["tiles"]]
    stated = [t for t in tiles if t["cls"] == "s-stated"]
    others = [t for t in tiles if t["cls"] != "s-stated"]
    assert stated and others
    assert all(heatmap.EDIT_HINT not in t["tip"] for t in stated)
    assert all(heatmap.EDIT_HINT in t["tip"] for t in others)
    assert all("만원" in t["sub"] or t["sub"] == "금액 없음" for t in tiles)


def test_page_renders_category_chips_and_source_legend():
    p = _page()
    assert 'class="hm-chips"' in p.html and 'data-panel="perks"' in p.html
    assert "hm-key s-stated" in p.html and "회사 공식 수치" in p.html
    assert "카테고리 모드" in p.html


# ── 강조 연결 정보(SP-HEAT-7) ────────────────────────────────────────────────


def test_tiles_and_groups_share_group_keys_within_a_panel():
    """칸의 `gkey` 는 같은 패널의 그룹 사각형과 맞물려야 한다 — 어긋나면 강조가 빈 그룹을 칠한다."""
    for m in heatmap.build_view(_ctx(), SECTORS)["modes"]:
        for p in m["panels"]:
            keys_by_orient = {}
            for orient, lay in p["layouts"].items():
                gkeys = {g["gkey"] for g in lay["groups"]}
                assert len(gkeys) == len(lay["groups"]), "그룹 키 중복"
                assert {t["gkey"] for t in lay["tiles"]} <= gkeys, f"{m['key']}/{p['key']}/{orient}: 고아 칸"
                keys_by_orient[orient] = {g["gkey"]: g["name"] for g in lay["groups"]}
            # 가로·세로가 **같은 키**를 써야 한다(배치마다 번호를 다시 매기면 어긋난다)
            assert len(set(map(lambda d: tuple(sorted(d.items())), keys_by_orient.values()))) == 1


def test_tiles_carry_company_key_for_peer_highlight():
    """같은 회사의 다른 칸을 찾으려면 `ckey`(회사 slug)가 필요하다 — href 와 같은 값."""
    for m in heatmap.build_view(_ctx(), SECTORS)["modes"]:
        for p in m["panels"]:
            for t in p["layouts"]["landscape"]["tiles"]:
                assert t["ckey"] and t["href"] == f"/company/{t['ckey']}"


def test_page_emits_highlight_attributes_and_readout():
    p = _page()
    assert 'data-g="g0"' in p.html and "data-c=" in p.html and "data-nm=" in p.html
    assert "data-group-nm" not in p.html  # 묶음 이름은 그룹 요소에만(칸 중복 출력 금지)
    assert 'data-readout' in p.html and 'aria-live="polite"' in p.html
