"""히트맵 `/heatmap` (SP-HEAT, 2026-08-27) — 배치 불변식·그룹 기준·표현 규약.

배치는 빌드 시점 계산이라 "그려졌는가"를 브라우저 없이 수치로 잰다: 면적 합이 캔버스와 같고,
칸이 캔버스 밖으로 나가지 않고, 서로 겹치지 않으며, 회사가 하나도 빠지지 않는다(첫 목업에서
작은 그룹의 15곳이 조용히 사라졌다 — 그 실패를 여기서 잡는다).
"""
from __future__ import annotations

import copy
import json
import re
from pathlib import Path

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
    # 속성 순서·개수에 기대지 않는다 — 헤더 마크업이 바뀌어도(2026-09-01 gnb 통일에서 실제로
    # `class="gnb-link"` 이 끼어들었다) 이 검사가 지키려는 것은 "히트맵 탭이 현재 탭인가" 하나다.
    assert re.search(r'<a href="/heatmap"[^>]*aria-current="page"', p.html)
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
    """같은 회사의 다른 칸을 찾으려면 `ckey`(회사 slug)가 필요하다 — href 의 **경로 부분**과 같은 값.

    카테고리 모드의 칸은 복지 한 건이라 `#b-{코드}` 앵커가 붙는다(회사 페이지의 그 행으로 간다).
    앵커는 경로가 아니므로 회사 판정은 여전히 `ckey` 하나로 한다."""
    for m in heatmap.build_view(_ctx(), SECTORS)["modes"]:
        for p in m["panels"]:
            for t in p["layouts"]["landscape"]["tiles"]:
                assert t["ckey"] and t["href"].split("#")[0] == f"/company/{t['ckey']}"


def test_page_emits_highlight_attributes_and_readout():
    p = _page()
    assert 'data-g="g0"' in p.html and "data-c=" in p.html and "data-nm=" in p.html
    assert "data-group-nm" not in p.html  # 묶음 이름은 그룹 요소에만(칸 중복 출력 금지)
    assert 'data-readout' in p.html and 'aria-live="polite"' in p.html


# ── 첫 화면 = 복지 지도만, 나머지는 패널별 데이터 파일(2026-10-22) ───────────────


def _pages():
    return heatmap.render_all(make_env(), _ctx(), CFG)


def test_first_html_bakes_only_the_welfare_map_and_others_are_empty_vessels():
    page = _pages()[0]
    html = page.html
    assert html.count('class="hm-map hm-landscape"') == 1 and html.count('class="hm-map hm-portrait"') == 1
    panels = re.findall(r'<div class="hm-panel" data-panel="([^"]+)"( data-src="[^"]+")?>', html)
    lazy = [k for k, src in panels if src]
    assert lazy and len(lazy) == len(panels) - 1  # 복지 패널 하나만 src 가 없다(구운 쪽)
    for m in re.finditer(r'<div class="hm-panel" data-panel="[^"]+" data-src="[^"]+">(.*?)\n    </div>', html, re.S):
        assert "hm-t" not in m.group(1) and 'class="hm-nojs"' in m.group(1) and "자바스크립트가 필요합니다" in m.group(1)
        assert "noscript" not in m.group(1)  # 안내가 기본으로 보인다 — JS 가 맡으면 걷는다(스크립트 로드 실패에도 빈 패널 금지)


def test_welfare_panel_markup_and_link_count_unchanged():
    """구운 복지 패널은 지금까지와 같은 칸 수 — 회사 수만큼(가로·세로 두 벌)."""
    ctx = _ctx()
    page = heatmap.render_all(make_env(), ctx, CFG)[0]
    assert len(re.findall(r'<a class="hm-t ', page.html)) == 2 * len(ctx.companies)


def test_data_pages_one_per_lazy_panel_with_fingerprint_url_and_json_type():
    pages = _pages()
    view = heatmap.build_view(_ctx(), SECTORS)
    expected = sum(len(m["panels"]) for m in view["modes"] if m["key"] != "w")
    data = pages[1:]
    assert len(data) == expected and expected >= 2
    for d in data:
        assert d.path.startswith("heatmap/") and d.path.endswith(".json") and not d.in_sitemap
        assert d.content_type.startswith("application/json")
        assert json.loads(d.html)["v"] == 1
        key = d.path.removeprefix("heatmap/").removesuffix(".json")
        assert re.fullmatch(r"heatmap/[a-z]-[a-z_]+\.[0-9a-f]{10}\.json", d.path), key  # 내용 지문이 파일 이름에
        assert f'data-src="/{d.path}"' in pages[0].html and "?v=" not in pages[0].html


def test_data_url_fingerprint_follows_content():
    ctx = _ctx()
    a = heatmap.render_all(make_env(), ctx, CFG)[0].html
    b = heatmap.render_all(make_env(), ctx, CFG)[0].html
    assert a == b  # 결정적
    ctx2 = _ctx()
    ctx2.companies[0]["benefits"][0]["benefit_nm"] = "다른 이름"
    c = heatmap.render_all(make_env(), ctx2, CFG)[0].html
    assert re.findall(r'data-src="([^"]+)"', a) != re.findall(r'data-src="([^"]+)"', c)


def test_panel_data_covers_both_orientations_with_same_tiles():
    for m in heatmap.build_view(_ctx(), SECTORS)["modes"]:
        for p in m["panels"]:
            d = heatmap.panel_data(p)
            n = len(d["tiles"])
            for o in heatmap.ORIENT_ORDER:
                assert sorted(t[0] for t in d[o]["t"]) == list(range(n)), (m["key"], p["key"], o)
                assert len(d[o]["g"]) == len(d["groups"])


# ── 서버 그림 = 브라우저 그림 픽스처 ─────────────────────────────────────────


def test_panel_cases_fixture_matches_current_template_and_panel_data():
    """`heatmap_panel_cases.json` 이 지금 템플릿·panel_data 가 내는 것과 같다 — JS 테스트(heatmap.test.js)가 같은
    파일로 buildMaps 를 잰다. 다르면 `python3 generator/tests/data/make_heatmap_cases.py` 로 다시 뽑는다."""
    import sys
    from pathlib import Path
    data_dir = Path(__file__).resolve().parent / "data"
    sys.path.insert(0, str(data_dir))
    try:
        import make_heatmap_cases
    finally:
        sys.path.remove(str(data_dir))
    want = make_heatmap_cases.build_cases()
    have = json.loads((data_dir / "heatmap_panel_cases.json").read_text(encoding="utf-8"))
    assert have == want, "heatmap_panel_cases.json 이 낡았다 — make_heatmap_cases.py 로 다시 뽑아라"
    assert {p["mode"] for p in have["panels"]} >= {"w", "f", "c"}


# ── 크기 상한 ────────────────────────────────────────────────────────────────


def test_size_caps_first_html_and_data_files():
    """상한은 실측(2026-10-22, 286사·6,475행)으로 정했다: 첫 HTML 압축 35KB(이전 716KB) · 데이터 파일 최대 65KB.
    가짜 번들은 작아서 절대값으로는 못 잡는다 — 그래서 구조도 함께 잰다: 칸 설명은 한 번만(두 배치가 공유)."""
    import gzip
    pages = _pages()
    assert len(gzip.compress(pages[0].html.encode("utf-8"))) <= 60_000
    for d in pages[1:]:
        assert len(gzip.compress(d.html.encode("utf-8"))) <= 100_000, d.path
        data = json.loads(d.html)
        assert len(data["tiles"]) == len(data["landscape"]["t"]) == len(data["portrait"]["t"])
        assert d.html.count('"landscape"') == 1 and d.html.count('"portrait"') == 1


def test_maps_have_no_static_aria_hidden():
    """안 보이는 배치는 CSS(display:none)가 접근성 트리에서 뺀다 — 정적 aria-hidden 은 ≤640px 에서 보이는 세로 지도를 지운다."""
    css = (Path(__file__).resolve().parents[2] / "web/assets/css/heatmap.css").read_text(encoding="utf-8")
    assert ".hm-portrait { aspect-ratio:3 / 4; display:none; }" in css and ".hm-landscape { display:none; }" in css
    assert "aria-hidden" not in _pages()[0].html.split('<article class="heatmap-page">')[1]


def test_gc32_heatmap_weight_gate():
    import os
    from generator.checks import HEATMAP_DATA_GZ_MAX, HEATMAP_HTML_GZ_MAX, BuildError
    from generator.context import Page
    pages = _pages()
    from generator.checks import _check_heatmap_weight
    _check_heatmap_weight(pages)  # 정상 빌드는 통과
    noise = os.urandom(HEATMAP_HTML_GZ_MAX).hex()  # 압축이 안 되는 글
    big_html = Page(path="heatmap.html", url="u", html=noise, title="t", description="d")
    with pytest.raises(BuildError, match="GC-32.*첫 HTML"):
        _check_heatmap_weight([big_html])
    big_data = Page(path="heatmap/c-perks.0123456789.json", url="u", html=os.urandom(HEATMAP_DATA_GZ_MAX).hex(),
                    title="t", description="d", in_sitemap=False)
    with pytest.raises(BuildError, match="GC-32.*c-perks"):
        _check_heatmap_weight([pages[0], big_data])
    assert HEATMAP_HTML_GZ_MAX == 70_000 and HEATMAP_DATA_GZ_MAX == 150_000
