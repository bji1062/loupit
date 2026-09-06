"""generator/tests/test_find_page.py — `/find` 「복지검색」 (SP-FIND).

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

import json
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
LABEL_CASES = REPO_ROOT / "generator" / "tests" / "data" / "find_label_cases.json"
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
    assert "복지검색" in page.title
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


def _companies_from_label_cases(cases: dict) -> list[dict]:
    """픽스처의 `코드 → {이름: 빈도}` 를 회사 목록으로 되돌린다(행 하나 = 회사 하나).

    회사 안에서 코드는 UNIQUE 라 같은 코드를 여러 번 쓰려면 회사를 나눠야 한다 — 그래서
    빈도만큼 회사를 만든다. JS 쪽 테스트도 **같은 방식으로** 같은 파일을 읽는다.
    """
    companies, cid = [], 0
    for code, info in cases["codes"].items():
        for name, freq in info["names"].items():
            for _ in range(freq):
                cid += 1
                companies.append({"comp_id": cid, "benefits": [{
                    "benefit_cd": code, "benefit_nm": name,
                    "benefit_ctgr_cd": info["ctgr"], "qual_yn": True, "benefit_amt": None,
                }]})
    return companies


def test_real_bundle_labels_match_the_shared_fixture():
    """실데이터 86종의 대표 이름·별칭 순서를 못 박는다.

    같은 파일을 `web/assets/js/find.test.js` 도 읽어 같은 기대값을 검사한다 — 표(파이썬)와
    칩(JS)이 **같은 이름을 부른다**는 약속을 실데이터로 재는 자리다. 규칙을 손대면 여기가 먼저 빨개진다.
    """
    cases = json.loads(LABEL_CASES.read_text(encoding="utf-8"))
    assert len(cases["codes"]) == 86, "픽스처가 실데이터 86종이 아니다"
    codes = find.derive_codes(_companies_from_label_cases(cases))
    assert sorted(codes) == sorted(cases["codes"])
    for code, want in cases["codes"].items():
        assert codes[code]["label"] == want["label"], code
        assert codes[code]["aliases"] == want["aliases"], code


def test_category_order_matches_the_shared_fixture(fake_bundle, fake_now):
    """카테고리 안 순서 = 보유 회사 수 내림차순 → 라벨. **칩 줄과 정적 표가 같은 순서**여야 한다.

    JS 쪽이 한국어 로케일 정렬을 쓰는 동안 네 카테고리에서 순서가 갈려 있었다(2026-09-06 검증).
    두 구현이 같은 픽스처로 같은 기대값을 재면 그 어긋남이 다시 조용히 들어올 수 없다.
    """
    cases = json.loads(LABEL_CASES.read_text(encoding="utf-8"))
    codes = find.derive_codes(_companies_from_label_cases(cases))
    by_cat: dict[str, list] = {}
    for info in codes.values():
        by_cat.setdefault(info["ctgr"], []).append(info)
    for key, want in cases["category_order"].items():
        got = [i["code"] for i in sorted(by_cat[key], key=lambda i: (-i["count"], i["label"]))]
        assert got == want, key


def test_short_generic_name_wins_over_one_company_wording():
    """동률일 때 **짧은 일반명**이 이긴다 — 한 회사의 표기가 86종 전체의 이름이 되면 안 된다.

    실데이터에서 이름이 전부 1회씩인 코드가 19종이라 라벨이 tie-break 로만 정해진다. 빈도만 보고
    코드포인트로 가르면 라틴·숫자·괄호가 한글 앞에 서서 「KB 패밀리데이」가 야유회 코드의 이름이 됐다.
    """
    cases = json.loads(LABEL_CASES.read_text(encoding="utf-8"))
    for code, expect in (("company_event", "야유회"), ("mba", "대학원비 지원"),
                         ("work_tools", "노트북 지원"), ("profit_sharing", "경영성과금"),
                         ("massage", "안마의자"), ("birthday_leave", "생일 선물")):
        names = cases["codes"][code]["names"]
        assert expect in names, f"{code}: 픽스처에 {expect} 가 없다"
        top = max(names.values())
        assert len([n for n, k in names.items() if k == top]) > 1, f"{code}: 동률이 아니다 — 가드가 공회전한다"
        assert cases["codes"][code]["label"] == expect, code
        # 더 길거나 회사 고유 표기인 후보가 실제로 함께 있었다는 것까지 확인한다
        assert any(len(n) > len(expect) for n in names), code


def test_most_common_tie_breaks_by_length_then_code_point():
    """동률 대표 이름은 **길이 → 코드포인트** — JS 쪽과 같은 규칙이어야 표와 칩이 같은 이름을 부른다.

    길이가 먼저다(짧은 쪽이 대개 수식어 없는 일반명). 길이도 같으면 `가`(U+AC00) < `힣`(U+D7A3).
    한국어 로케일 정렬을 쓰면 같은 결과가 보장되지 않는다(그래서 양쪽 다 로케일을 쓰지 않는다).
    """
    def one(code, name, cid):
        return {"comp_id": cid, "benefits": [{"benefit_cd": code, "benefit_nm": name,
                                              "benefit_ctgr_cd": "perks", "qual_yn": True}]}
    codes = find.derive_codes([one("x", "아주 긴 이름", 1), one("x", "짧은이름", 2)])
    assert codes["x"]["base_label"] == "짧은이름"
    assert codes["x"]["aliases"] == ["짧은이름", "아주 긴 이름"]
    same_len = find.derive_codes([one("y", "힣나", 1), one("y", "가나", 2)])
    assert same_len["y"]["base_label"] == "가나"
    assert same_len["y"]["aliases"] == ["가나", "힣나"]


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
    """탭 라벨은 **「복지검색」(4자)** 다 — 페이지 제목(「복지검색」)과 일부러 다르다.

    5자 라벨은 익명·M9 ON 에서 360~400px 헤더를 두 줄로 만든다(탭 폭 +71px → 「로그인」이 둘째 줄).
    라벨을 다시 늘리려면 그 폭에서 헤더 높이를 먼저 재라.
    """
    assert ("복지검색", "/find") in GNB_TABS
    assert all(len(label) <= 4 for label, _ in GNB_TABS), "탭 라벨이 4자를 넘으면 좁은 폭 헤더가 두 줄이 된다"


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
        assert '<a href="/find"' in p.html, f"{p.path}: 복지검색 탭이 없다"


def test_find_tab_exists_in_every_hand_written_shell():
    for name in SHELLS:
        html = (WEB / name).read_text(encoding="utf-8")
        assert '<a href="/find" class="gnb-link"' in html, f"{name}: 복지검색 탭이 없다"
