"""대문 생성 페이지 계약 (대문 재설계 2단계, 2026-09-13) — `generator/pages/home.py`.

1단계 수기 셸 계약(`test_home_shell.py`)을 **생성 페이지**로 옮긴다. 수기 셸은 nginx 폴백으로만 남았다가
후속 PR 에서 지운다. 링크 드리프트는 이제 GC-20(`test_links.py::_build_all_pages` 에 대문 포함)이 모든
생성 페이지와 같은 그물로 잡는다 — 대문만 따로 검사하던 이유(수기 HTML)가 사라졌다.
"""
from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

import pytest

from generator.config import CFG
from generator.context import build_context
from generator.employ import _to_manwon, _to_year
from generator.format import krw_manwon
from generator.pages import combo, company, home
from generator.pages.company import CATEGORY_ORDER
from generator.pages.find import derive_codes
from generator.render import make_env

REPO_ROOT = Path(__file__).resolve().parents[2]
SEED_SQL = REPO_ROOT / "db" / "seed" / "benefit" / "sql"
_SEED_ENG_RE = re.compile(
    r"INSERT\s+IGNORE\s+INTO\s+TCOMPANY\s*\([^)]*COMP_ENG_NM[^)]*\)\s*VALUES\s*\(\s*'([^']+)'", re.I | re.S,
)
_M9_HREF_RE = re.compile(r'href="(/login|/mypage|/verify|/edit|/edits)(?:[/?#][^"]*)?"')


def _render(bundle, now, *, finance=None, employ=None, pairs=None):
    env = make_env()
    ctx = build_context(bundle, now=now, finance=finance, employ=employ)
    if pairs is None:
        pairs = combo.load_pairs(ctx)
    return home.render(env, ctx, CFG, pairs=pairs), ctx


def _main(html: str) -> str:
    return html[html.index("<main"):html.index("</main>")]


def _cta(html: str) -> str:
    block = html[html.index('class="home-cta"'):]
    return block[:block.index("</div>")]


# ── 1. 머리 — 루트 문서만 지는 책임 ───────────────────────────────────────────


def test_home_is_the_root_document(fake_bundle, fake_now, fake_combinations_path):
    page, _ = _render(fake_bundle, fake_now)
    assert page.path == "index.html"
    assert page.url == CFG.site_origin + "/"
    assert page.in_sitemap


def test_head_keeps_naver_verification_brand_title_and_canonical(fake_bundle, fake_now, fake_combinations_path):
    html = _render(fake_bundle, fake_now)[0].html
    assert re.search(r'<meta name="naver-site-verification" content="\w+">', html), "소유확인 메타가 없으면 서치어드바이저 소유권을 잃는다"
    assert re.search(r"<title>잡초위키 — ", html), "브랜드가 title 첫 어절이어야 한다"
    canonical = re.findall(r'<link rel="canonical" href="([^"]+)">', html)
    og_url = re.findall(r'<meta property="og:url" content="([^"]+)">', html)
    assert canonical == og_url == [CFG.site_origin + "/"]
    assert f'<meta property="og:site_name" content="{CFG.site_name}">' in html
    ld = [json.loads(s) for s in re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)]
    assert any(d.get("@type") == "WebSite" and d.get("name") == "잡초위키" for d in ld)


def test_home_font_preload_matches_other_pages(fake_bundle, fake_now, fake_combinations_path):
    """대문도 다른 생성 페이지와 **같은** 폰트 preload 를 갖는다(2026-09-13 적대 검증 LOW 반영).

    preload 를 빼도 `styles.css` 의 `@font-face`(font-display: swap)가 같은 2MB 를 받는다 — 전송량은 0 도 줄지
    않고 폰트 발견만 늦어져 대문만 폴백 글꼴이 더 오래 보인다. 전송량을 줄이려면 서브셋·unicode-range 가 답이다.
    """
    html = _render(fake_bundle, fake_now)[0].html
    env = make_env()
    other = company.render_all(env, build_context(fake_bundle, now=fake_now))[0].html
    tag = '<link rel="preload" href="/assets/v2/fonts/PretendardVariable.woff2"'
    assert html.count(tag) == 1 and other.count(tag) == 1


# ── 2. 정적 허브 계약 ─────────────────────────────────────────────────────────


def test_static_hub_contract(fake_bundle, fake_now, fake_combinations_path):
    """app.js 없음 · 도구 셸 잔해 없음 · 광고 배선(landing + 슬롯 1 + static-ads) · authnav 스크립트."""
    html = _render(fake_bundle, fake_now)[0].html
    srcs = re.findall(r'<script[^>]*\bsrc="([^"]+)"', html)
    assert not any(s.endswith("/app.js") for s in srcs), srcs
    assert any(s.endswith("/static-ads.js") for s in srcs), "슬롯만 두고 로더를 빼면 광고가 조용히 0 이 된다"
    assert any(s.endswith("/authnav.js") for s in srcs)
    for dead in ('id="app"', 'id="trending"', 'id="boot-error"'):
        assert dead not in html
    assert '<body data-page-type="landing">' in html
    assert html.count('data-ad-position="content_bottom"') == 1
    assert 'data-ad-position="report_bottom"' not in html


def test_single_h1_brand_first_and_one_skip_link_target(fake_bundle, fake_now, fake_combinations_path):
    html = _render(fake_bundle, fake_now)[0].html
    h1s = re.findall(r"<h1\b[^>]*>(.*?)</h1>", html, re.S)
    assert len(h1s) == 1 and h1s[0].startswith("잡초위키")
    assert html.count('id="main-heading"') == 1, "본문 바로가기 대상은 base.html 의 <main> 하나다 — 중복 id 금지"


def test_cta_offers_two_compare_modes_and_no_find_card(fake_bundle, fake_now, fake_combinations_path):
    html = _render(fake_bundle, fake_now)[0].html
    cta = _cta(html)
    assert re.findall(r'href="([^"]+)"', cta) == ["/compare/", "/compare/#input"]
    assert "입력할 필요가 없습니다" in cta and "브라우저 안에서만" in cta
    assert 'id="home-find"' in html, "복지검색 입구는 칩 섹션이 맡는다"


def test_no_visible_m9_link(fake_bundle, fake_now, fake_combinations_path):
    html = _render(fake_bundle, fake_now)[0].html
    for m in _M9_HREF_RE.finditer(html):
        tag = html[html.rfind("<a", 0, m.start()): html.find(">", m.start()) + 1]
        assert "data-authnav" in tag and "hidden" in tag, tag


# ── 3. 숫자는 데이터에서 ──────────────────────────────────────────────────────


def test_strip_counts_come_from_bundle(fake_bundle, fake_now, fake_combinations_path):
    page, ctx = _render(fake_bundle, fake_now)
    rows = sum(len(c["benefits"]) for c in ctx.companies)
    strip = page.html[page.html.index('class="home-strip"'):page.html.index("</dl>")]
    assert f"<dd>{len(ctx.companies)}곳</dd>" in strip
    assert f"<dd>{rows:,}건</dd>" in strip
    assert f"표준 항목 {len(derive_codes(ctx.companies))}종" in strip


def test_find_chips_carry_real_codes_and_category_anchors(fake_bundle, fake_now, fake_combinations_path):
    """`/find?b=` 는 실재 코드, `#cat-` 는 CATEGORY_ORDER 키 — 오타면 빈 결과·맨 위로 떨어진다(404 보다 조용하다)."""
    page, ctx = _render(fake_bundle, fake_now)
    codes = set(derive_codes(ctx.companies))
    found_codes = re.findall(r'href="/find\?b=([^"&#]+)"', page.html)
    found_cats = re.findall(r'href="/find#cat-([^"]+)"', page.html)
    assert found_codes and set(found_codes) <= codes
    assert found_cats and set(found_cats) <= set(CATEGORY_ORDER)


def test_combo_labels_follow_generated_h1_order(fake_bundle, fake_now, fake_combinations_path):
    page, ctx = _render(fake_bundle, fake_now)
    for label, href in [(c["label"], c["href"]) for c in home.build_view(ctx)["combos"]]:
        path = href[len("/vs/"):]
        first_slug = path.split("-", 1)[0]
        first = next(c for c in ctx.companies if ctx.slugs[c["comp_eng_nm"]].startswith(first_slug))
        assert label.startswith(first["comp_nm"]), (label, href)


def test_sector_groups_merge_only_singletons(fake_bundle, fake_now, monkeypatch):
    monkeypatch.setattr(home, "load_sectors", lambda: {"A": "전기·전자", "B": "IT 서비스"})
    finance = {1: {"stock_cd": "A"}, 2: {"stock_cd": "A"}, 3: {"stock_cd": "B"}}
    ctx = build_context(fake_bundle, now=fake_now, finance=finance)
    groups = home._sector_groups(ctx)
    assert [g["name"] for g in groups] == ["전기·전자", home.OTHER_SECTOR]
    top = groups[0]["top"]
    assert [r["n"] for r in top] == sorted((r["n"] for r in top), reverse=True), "항목 수 내림차순"


def test_numbers_use_one_year_same_formatters_and_head_threshold(fake_bundle, fake_now, fake_employ):
    employ = {cid: dict(years) for cid, years in fake_employ.items()}
    ctx = build_context(fake_bundle, now=fake_now, employ=employ)
    year = max(y for e in ctx.employ.values() for y in e)
    # 한 회사의 인원을 문턱 아래로 — 연봉 축에서만 빠져야 한다
    small = next(cid for cid, e in ctx.employ.items() if year in e and cid in ctx.by_id)
    ctx.employ[small][year] = dict(ctx.employ[small][year], head=home.SALARY_MIN_HEAD - 1)
    nums = home._numbers(ctx)
    assert nums["year"] == year
    axes = {a["title"]: a["rows"] for a in nums["axes"]}
    small_name = ctx.by_id[small]["comp_nm"]
    assert small_name in [r["name"] for r in axes["직원 수"]]
    salary_axis = next(v for k, v in axes.items() if k.startswith("평균연봉"))
    assert small_name not in [r["name"] for r in salary_axis]
    for r in salary_axis:
        c = next(c for c in ctx.companies if c["comp_nm"] == r["name"])
        assert r["text"] == krw_manwon(_to_manwon(ctx.employ[c["comp_id"]][year]["salary"]))
    for r in axes["평균 근속"]:
        c = next(c for c in ctx.companies if c["comp_nm"] == r["name"])
        assert r["text"] == f"{_to_year(ctx.employ[c['comp_id']][year]['tenure']):.1f}년"
        assert not r["text"].startswith("공동"), "「공동」은 정수 항목 수 전용"


def test_items_rank_marks_ties_only_when_counts_are_equal(fake_bundle, fake_now):
    bundle = fake_bundle
    a, b = bundle["companies"][0], bundle["companies"][1]
    n = min(len(a["benefits"]), len(b["benefits"]))
    a["benefits"], b["benefits"] = a["benefits"][:n], b["benefits"][:n]
    ctx = build_context(bundle, now=fake_now)
    rows = next(ax for ax in home._numbers(ctx)["axes"] if ax["title"] == "복지 항목 수")["rows"]
    texts = {r["name"]: r["text"] for r in rows}
    assert texts[a["comp_nm"]] == texts[b["comp_nm"]] == f"공동 {n}항목"


def test_numbers_without_employ_keep_items_axis_only(fake_bundle, fake_now, fake_combinations_path):
    html = _render(fake_bundle, fake_now)[0].html
    assert "사업보고서(DART)" not in html, "직원 현황이 없는 빌드에 DART 기준 문장을 적지 않는다"
    assert "<h3>복지 항목 수</h3>" in html
    assert "<h3>직원 수</h3>" not in html


def test_trust_counts_close_to_total(fake_bundle, fake_now):
    ctx = build_context(fake_bundle, now=fake_now)
    t = home._trust(ctx)
    parts = [t["stated"], t["estimated"], t["qual"], t["no_amount"] or "0"]
    assert sum(int(p.replace(",", "")) for p in parts) == int(t["total"].replace(",", ""))


def test_output_is_deterministic_no_build_time(fake_bundle, fake_combinations_path):
    """lastmod 는 내용 지문이다 — 빌드 시각이 들어가면 매 빌드가 「바뀐 페이지」가 된다."""
    from datetime import datetime
    one = _render(fake_bundle, datetime(2026, 1, 1))[0].html
    two = _render(fake_bundle, datetime(2031, 12, 31))[0].html
    assert one == two


# ── 4. 새로 등록된 회사 — 등록 이력 파일 ─────────────────────────────────────


def test_recent_waves_take_latest_two_with_present_companies(fake_bundle, fake_now, tmp_path, monkeypatch, fake_combinations_path):
    reg = tmp_path / "reg.json"
    reg.write_text(json.dumps({"waves": [
        {"date": "2026-01-01", "label": "옛", "companies": ["samsung_elec"]},
        {"date": "2026-03-01", "label": "없는 회사만", "companies": ["ghost_co"]},
        {"date": "2026-02-01", "label": "둘째", "companies": ["sk_hynix", "naver"]},
    ]}, ensure_ascii=False), encoding="utf-8")
    monkeypatch.setattr(home, "REGISTRATIONS_PATH", reg)
    page, ctx = _render(fake_bundle, fake_now)
    recent = home.build_view(ctx)["recent"]
    assert [w["date"] for w in recent] == ["2026-02-01", "2026-01-01"], "없는 회사만 있는 웨이브는 건너뛴다"
    assert "<dd>2026-02-01</dd>" in page.html
    assert "ghost_co" not in page.html


def _seed_eng_names() -> list[str]:
    """시드 SQL 의 **모든** 회사 자기등록 문장 — 파일당 첫 문장만 보면 두 회사를 넣은 시드의 둘째가 빠진다."""
    names = []
    for f in sorted(SEED_SQL.glob("*.sql")):
        found = [m.group(1) for m in _SEED_ENG_RE.finditer(f.read_text(encoding="utf-8"))]
        assert found, f"{f.name}: TCOMPANY 자기등록 문장이 없다"
        names.extend(found)
    return names


def test_registrations_file_lists_every_seed_company_exactly_once():
    """회사를 등록하는 PR 이 등록 이력을 빠뜨리면 여기서 붉어진다 — 대문 「새로 등록된 회사」가 조용히 낡지 않게."""
    waves = home.load_registrations()
    listed = Counter(e for w in waves for e in w["companies"])
    dup = [e for e, n in listed.items() if n > 1]
    assert not dup, f"두 웨이브에 실린 회사: {dup}"
    seed = set(_seed_eng_names())
    assert set(listed) == seed, (
        f"등록 이력에 없는 시드 회사: {sorted(seed - set(listed))} · 시드에 없는 이력 회사: {sorted(set(listed) - seed)}"
    )
    dates = [w["date"] for w in waves]
    assert all(re.fullmatch(r"\d{4}-\d{2}-\d{2}", d) for d in dates)
    assert len(set(dates)) == len(dates), "같은 날짜의 웨이브가 둘이면 대문에 같은 제목이 두 번 나온다"


# ── 5. 적대 검증 반영(2026-09-13) ─────────────────────────────────────────────


def _employ_row(salary=120_000_000, tenure=10.0, head=5_000):
    return {"salary": salary, "tenure": tenure, "head": head}


def test_employ_year_needs_coverage_not_just_the_latest(fake_bundle, fake_now):
    """공시 시즌 부분 수집 — 새 연도를 가진 회사가 소수면 그 연도로 순위를 만들지 않는다(적대 검증 MED)."""
    partial = {1: {2025: _employ_row(), 2026: _employ_row(head=9_999)}, 2: {2025: _employ_row()}, 3: {2025: _employ_row()}}
    ctx = build_context(fake_bundle, now=fake_now, employ=partial)
    assert home._employ_year(ctx) == 2025, "1/3 만 가진 2026 으로 순위를 만들면 소수 회사끼리의 거짓 순위다"
    full = {cid: {**years, 2026: _employ_row()} for cid, years in partial.items()}
    ctx_full = build_context(fake_bundle, now=fake_now, employ=full)
    assert home._employ_year(ctx_full) == 2026, "다 모이면 새 연도로 넘어간다"


def test_salary_note_only_when_salary_axis_exists(fake_bundle, fake_now):
    """연봉 축이 문턱에 걸려 통째로 빠지면 문턱을 설명하는 문장도 빠진다."""
    small = {cid: {2025: _employ_row(head=home.SALARY_MIN_HEAD - 1)} for cid in (1, 2, 3)}
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now, employ=small)
    html = home.render(env, ctx, CFG, pairs=[]).html
    assert "<h3>직원 수</h3>" in html and "평균연봉 (" not in html
    assert "명 이상 회사만 순위에 넣었습니다" not in html
    big = {cid: {2025: _employ_row(head=home.SALARY_MIN_HEAD)} for cid in (1, 2, 3)}
    html_big = home.render(env, build_context(fake_bundle, now=fake_now, employ=big), CFG, pairs=[]).html
    assert "명 이상 회사만 순위에 넣었습니다" in html_big


def test_generated_marker_for_smoke(fake_bundle, fake_now, fake_combinations_path):
    """스모크 SM-1b 가 생성 대문과 nginx 폴백(수기 셸)을 가르는 표식 — 수기 셸에는 없어야 의미가 있다."""
    html = _render(fake_bundle, fake_now)[0].html
    assert html.count("data-home-generated") == 1
    assert "data-home-generated" not in (REPO_ROOT / "web" / "index.html").read_text(encoding="utf-8")

