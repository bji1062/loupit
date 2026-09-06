"""generator/tests/test_find_page.py — `/find` 「복지로 찾기」 (SP-FIND).

잡으려는 회귀 넷:
  ① **비-JS 본문이 안내 문구로 쪼그라드는 것.** 도구는 JS 라 색인되지 않는다. 크롤러가 보는
     것은 카테고리 9개 × 코드 표가 전부이고, 그 표가 없으면 이 페이지는 빈 페이지다.
  ② **표시명 규칙이 파이썬과 JS 로 갈라지는 것.** 표는 여기서, 칩은 `find.js` 에서 이름을 얻는다
     — 같은 코드가 두 이름을 갖는 순간 사용자는 같은 조건을 두 번 고른다.
  ③ **템플릿 훅이 조용히 사라지는 것.** `data-*` 는 마크업과 `find.js` 사이의 계약이라
     하나가 빠지면 화면이 에러 없이 절반만 그려진다.
  ④ **탭이 페이지 종류마다 달라지는 것.** 생성 페이지·수기 셸 전부에 같은 탭이 있어야 한다
     (test_gnb_tabs 가 순서를, 여기서는 새 탭의 실재를 본다).
"""
from __future__ import annotations

import re
from pathlib import Path

from generator.config import CFG
from generator.content.nav import GNB_TABS
from generator.context import build_context
from generator.pages import combo, company, company_index, find, heatmap, policy
from generator.pages import sitemap as sitemap_page
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
FIND_JS = REPO_ROOT / "web" / "assets" / "js" / "find.js"
FIND_TEMPLATE = REPO_ROOT / "generator" / "templates" / "find.html"
WEB = REPO_ROOT / "web"
SHELLS = [
    "index.html", "compare/index.html", "login.html", "mypage.html",
    "verify.html", "edit.html", "edits.html", "community/index.html",
]


def _page(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return find.render(env, ctx, CFG), ctx


# ── 페이지 생성 ──────────────────────────────────────────────────────────────


def test_find_page_is_generated_with_canonical_route(fake_bundle, fake_now):
    page, _ = _page(fake_bundle, fake_now)
    assert page.path == "find.html"
    assert page.url == f"{CFG.site_origin}/find"
    assert page.in_sitemap is True
    assert "복지로 찾기" in page.title
    assert page.description and len(page.description) <= 200


def test_find_page_declares_no_page_type(fake_bundle, fake_now):
    """검색 화면 무광고 규약 — `page_type` 을 선언하지 않으면 ads.js 는 'default'(광고 0)다."""
    page, _ = _page(fake_bundle, fake_now)
    assert "data-page-type" not in page.html


def test_find_page_is_in_sitemap(fake_bundle, fake_now, fake_combinations_path):
    """빌드 배선을 그대로 재현해 sitemap 에 /find 가 실리는지 본다(build.py 와 같은 순서)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    pages = (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG), heatmap.render(env, ctx, CFG), find.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )
    urls = [p.url for p in pages if p.in_sitemap]
    index = {u: {"lastmod": "2026-09-06", "changed": True} for u in urls}
    xml = sitemap_page.render_sitemap(env, urls, index, CFG).html
    assert f"<loc>{CFG.site_origin}/find</loc>" in xml


# ── ① 비-JS 본문 ─────────────────────────────────────────────────────────────


def test_non_js_body_carries_category_tables(fake_bundle, fake_now):
    page, ctx = _page(fake_bundle, fake_now)
    view = find.build_view(ctx)
    assert view["categories"], "픽스처에 카테고리가 없다 — 가드가 공회전한다"
    for cat in view["categories"]:
        assert f'id="cat-{cat["key"]}"' in page.html
        assert cat["label"] in page.html
    # 표는 `.table-scroll` 안에서만 가로 스크롤한다(SPEC 10 MD-4) — 카테고리마다 하나씩
    assert page.html.count('class="table-scroll"') == len(view["categories"])
    assert page.html.count("<table") == len(view["categories"])


def test_non_js_body_rows_link_into_the_tool(fake_bundle, fake_now):
    """표의 각 줄이 `/find?b=<code>` 입구다 — 정적 본문에서 도구로 넘어가는 유일한 길."""
    page, ctx = _page(fake_bundle, fake_now)
    codes = find.derive_codes(ctx.companies)
    assert codes
    for code in codes:
        assert f'href="/find?b={code}"' in page.html, f"{code} 줄에 링크가 없다"


def test_non_js_body_shows_counts_not_adjectives(fake_bundle, fake_now):
    """숫자는 세어서 나온 사실이어야 한다(보유 회사 수·금액 있는 회사 수)."""
    page, ctx = _page(fake_bundle, fake_now)
    view = find.build_view(ctx)
    assert f"등록 회사 {view['total_companies']}곳" in page.html
    for cat in view["categories"]:
        for row in cat["rows"]:
            assert f"{row['count']}곳" in page.html


def test_static_body_is_not_hidden(fake_bundle, fake_now):
    """도구가 켜져도 표를 숨기지 않는다 — 숨기면 색인 가치가 사라진다."""
    page, _ = _page(fake_bundle, fake_now)
    m = re.search(r'<section class="find-static"([^>]*)>', page.html)
    assert m, "정적 본문 절이 없다"
    assert "hidden" not in m.group(1)
    tool = re.search(r'<section class="find-tool"([^>]*)>', page.html)
    assert tool and "hidden" in tool.group(1), "도구는 부팅 전까지 닫혀 있어야 한다"


# ── ② 코드 사전 ──────────────────────────────────────────────────────────────


def test_derive_codes_counts_companies_not_rows(fake_bundle, fake_now):
    _, ctx = _page(fake_bundle, fake_now)
    codes = find.derive_codes(ctx.companies)
    for code, info in codes.items():
        owners = sum(
            1 for c in ctx.companies
            if any(b.get("benefit_cd") == code for b in c["benefits"])
        )
        assert info["count"] == owners, code
        assert info["ctgr"], f"{code}: 카테고리가 비었다"


def test_derive_codes_splits_shared_display_names():
    """같은 대표 이름을 쓰는 코드는 화면에서 갈라져야 한다 — 실데이터의 통근버스·장기근속."""
    companies = [
        {"comp_id": 1, "benefits": [
            {"benefit_cd": "transport", "benefit_nm": "통근버스", "benefit_ctgr_cd": "perks", "qual_yn": True},
            {"benefit_cd": "commute_subsidy", "benefit_nm": "통근버스", "benefit_ctgr_cd": "perks", "qual_yn": True},
            {"benefit_cd": "aa", "benefit_nm": "지원금", "benefit_ctgr_cd": "perks", "qual_yn": True},
            {"benefit_cd": "bb", "benefit_nm": "지원금", "benefit_ctgr_cd": "perks", "qual_yn": True},
        ]},
        {"comp_id": 2, "benefits": [
            {"benefit_cd": "bb", "benefit_nm": "지원금", "benefit_ctgr_cd": "perks", "qual_yn": True},
        ]},
        {"comp_id": 3, "benefits": [
            {"benefit_cd": "bb", "benefit_nm": "주택 지원금", "benefit_ctgr_cd": "perks", "qual_yn": True},
        ]},
    ]
    codes = find.derive_codes(companies)
    assert codes["transport"]["label"] != codes["commute_subsidy"]["label"]
    assert codes["transport"]["label"] == find.LABEL_OVERRIDE["transport"]
    # override 가 없는 중복은 별칭 병기(별칭이 없으면 코드 id)
    assert codes["aa"]["label"] == "지원금 · aa"
    assert codes["bb"]["label"] == "지원금 · 주택 지원금"


def test_label_override_matches_the_js_module():
    """표(파이썬)와 칩(JS)이 같은 이름을 불러야 한다 — 정본은 둘 중 하나가 아니라 **같음**이다."""
    js = FIND_JS.read_text(encoding="utf-8")
    block = re.search(r"export const LABEL_OVERRIDE = \{(.*?)\n\};", js, re.S)
    assert block, "find.js 에서 LABEL_OVERRIDE 를 찾지 못했다"
    js_map = dict(re.findall(r"(\w+):\s*'([^']+)'", block.group(1)))
    assert js_map == find.LABEL_OVERRIDE, "표시명 override 가 파이썬·JS 사이에서 갈라졌다"


def test_most_common_tie_breaks_by_code_point_like_the_js_module():
    """동률 대표 이름은 코드포인트 순 — JS 쪽과 **같은 규칙**이어야 표와 칩이 같은 이름을 부른다.

    `가`(U+AC00) < `힣`(U+D7A3) 라 한 번씩 나온 두 이름 중 `가나`가 대표가 된다. 한국어 로케일
    정렬을 쓰면 같은 결과가 보장되지 않는다(그래서 양쪽 다 로케일을 쓰지 않는다).
    """
    codes = find.derive_codes([
        {"comp_id": 1, "benefits": [{"benefit_cd": "x", "benefit_nm": "힣나", "benefit_ctgr_cd": "perks", "qual_yn": True}]},
        {"comp_id": 2, "benefits": [{"benefit_cd": "x", "benefit_nm": "가나", "benefit_ctgr_cd": "perks", "qual_yn": True}]},
    ])
    assert codes["x"]["base_label"] == "가나"
    assert codes["x"]["aliases"] == ["가나", "힣나"]


def test_codes_with_no_benefit_cd_are_skipped():
    codes = find.derive_codes([{"comp_id": 1, "benefits": [{"benefit_nm": "이름만", "benefit_ctgr_cd": "perks"}]}])
    assert codes == {}


# ── ③ 템플릿 훅 ─────────────────────────────────────────────────────────────


def test_template_carries_every_hook_the_module_binds(fake_bundle, fake_now):
    """`find.js` 가 찾는 `[data-*]` 훅이 템플릿과 산출물에 모두 있어야 한다."""
    page, _ = _page(fake_bundle, fake_now)
    js = FIND_JS.read_text(encoding="utf-8")
    hooks = sorted({m for m in re.findall(r"\[data-([a-z-]+)[\]=]", js)})
    assert len(hooks) >= 20, f"훅을 못 찾았다({len(hooks)}개) — 정규식이 낡았다"
    missing_tpl = [h for h in hooks if f"data-{h}" not in FIND_TEMPLATE.read_text(encoding="utf-8")]
    missing_html = [h for h in hooks if f"data-{h}" not in page.html]
    assert missing_tpl == [], f"템플릿에 없는 훅: {missing_tpl}"
    assert missing_html == [], f"산출물에 없는 훅: {missing_html}"


def test_page_loads_the_find_module(fake_bundle, fake_now):
    page, _ = _page(fake_bundle, fake_now)
    assert '<script type="module" src="/assets/v2/js/find.js" defer></script>' in page.html


# ── ④ GNB ───────────────────────────────────────────────────────────────────


def test_find_tab_is_in_the_canonical_tab_list():
    assert ("복지로 찾기", "/find") in GNB_TABS


def test_find_tab_exists_on_every_page_type(fake_bundle, fake_now, fake_combinations_path):
    """생성 페이지 전 종류(회사·인덱스·히트맵·찾기·조합·정책·404)에 새 탭이 있어야 한다."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = combo.load_pairs(ctx)
    pages = (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG), heatmap.render(env, ctx, CFG), find.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )
    kinds = {p.path.split("/")[0] for p in pages}
    assert {"company", "companies.html", "heatmap.html", "find.html", "404.html"} <= kinds
    for p in pages:
        assert '<a href="/find"' in p.html, f"{p.path}: 복지로 찾기 탭이 없다"


def test_find_tab_exists_in_every_hand_written_shell():
    for name in SHELLS:
        html = (WEB / name).read_text(encoding="utf-8")
        assert '<a href="/find" class="gnb-link"' in html, f"{name}: 복지로 찾기 탭이 없다"
