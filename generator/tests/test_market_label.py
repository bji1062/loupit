"""상장 구분 표시(코스피 상장 · 코스닥 상장 · 코넥스 상장 · 비상장) — `sector.market_of` · 회사 페이지 ·
회사 목록 · 빌드 검사 GC-31 · 「상장사」 문구 (2026-10-19, 사용자 결정 2026-10-18: 비상장 대기업도 등록한다)."""
from __future__ import annotations

import copy
import csv
import re
from pathlib import Path

import pytest

from generator import build as build_module
from generator import checks
from generator.config import CFG
from generator.context import build_context
from generator.pages import company, company_index, find, heatmap, home
from generator.release import _content_fingerprint
from generator.render import make_env
from generator.sector import DELISTED, UNLISTED, load_markets, load_sectors, market_of, sector_of
from generator.slug import BuildError
from generator.tests.fixtures import FAKE_BUNDLE, FAKE_FINANCE

MARKETS = {"000001": "KOSPI", "000002": "KOSDAQ", "000003": "KONEX", "000004": DELISTED}


def test_market_of_labels_each_market():
    assert market_of({"stock_cd": "000001"}, MARKETS) == "코스피 상장"
    assert market_of({"stock_cd": "000002"}, MARKETS) == "코스닥 상장"
    assert market_of({"stock_cd": "000003"}, MARKETS) == "코넥스 상장"


def test_market_of_is_unlisted_for_delisted_missing_code_and_missing_mapping():
    assert market_of({"stock_cd": "000004"}, MARKETS) == UNLISTED  # 상장폐지
    assert market_of({"stock_cd": None}, MARKETS) == UNLISTED  # 종목코드 없음
    assert market_of({"stock_cd": ""}, MARKETS) == UNLISTED
    assert market_of(None, MARKETS) == UNLISTED  # 재무 매핑 없음
    assert market_of({"stock_cd": "999999"}, MARKETS) == UNLISTED  # CSV 에 없는 코드


def test_sector_of_puts_delisted_in_unlisted_group():
    sectors = {"000004": "소프트웨어", "000001": "제약"}
    assert sector_of({"stock_cd": "000004"}, sectors, MARKETS) == UNLISTED
    assert sector_of({"stock_cd": "000001"}, sectors, MARKETS) == "제약"
    assert sector_of({"stock_cd": "000004"}, sectors) == "소프트웨어"  # markets 를 안 주면 기존 동작 그대로


def test_load_markets_reads_csv_and_values_are_known():
    markets = load_markets()
    assert len(markets) >= 90 and markets.get("005930") == "KOSPI"
    assert set(markets.values()) <= {"KOSPI", "KOSDAQ", "KONEX", DELISTED}
    assert set(markets) >= set(load_sectors())


# ── 회사 페이지: company-sub 줄 ─────────────────────────────────────────────


def _pages(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    return {p.path: p for p in company.render_all(make_env(), ctx)}


def _sub(html: str) -> str:
    return re.search(r'<p class="company-sub">(.*?)</p>', html, re.S).group(1).strip()


def test_company_sub_shows_market_right_after_company_type(fake_bundle, fake_finance, fake_now):
    pages = _pages(fake_bundle, fake_finance, fake_now)
    sub = _sub(pages["company/samsung-elec.html"].html)  # 005930 = 코스피
    plain = re.sub(r"<!--.*?-->", "", sub)
    assert re.search(r"반도체 · [^·]+ · 코스피 상장 · 복지 \d+항목", plain), plain
    hynix = [p for k, p in pages.items() if "SK하이닉스" in p.html and "<h1>SK하이닉스</h1>" in p.html][0]
    assert "비상장" in _sub(hynix.html)  # 재무 매핑 없는 회사


def test_company_sub_market_is_inside_lastmod_skip(fake_bundle, fake_finance, fake_now):
    html = _pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"].html
    assert re.search(r"<!--lm:skip--> · 코스피 상장<!--/lm:skip-->", html)
    # 표시 문구가 바뀌어도(시장 표 갱신 · 문구 개정) 그 회사의 자기 내용 지문은 같다
    changed = html.replace("<!--lm:skip--> · 코스피 상장<!--/lm:skip-->", "<!--lm:skip--> · 코스닥 상장 (개정)<!--/lm:skip-->")
    assert changed != html and _content_fingerprint(changed) == _content_fingerprint(html)
    # skip 을 걷어낸 줄은 시장 표시가 있었는지 모를 만큼 그대로다(가운뎃점 이중 없음)
    assert " ·  · " not in re.sub(r"<!--lm:skip-->.*?<!--/lm:skip-->", "", _sub(html))


def test_company_sub_market_reflects_csv_without_touching_fingerprint(fake_bundle, fake_finance, fake_now, monkeypatch):
    before = _pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"].html
    monkeypatch.setattr(company, "load_markets", lambda: {**load_markets(), "005930": DELISTED})
    after = _pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"].html
    assert "코스피 상장" in before and "코스피 상장" not in after
    assert _content_fingerprint(before) == _content_fingerprint(after)


# ── 회사 목록 ────────────────────────────────────────────────────────────────


def test_index_table_has_listing_column_after_industry(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    html = company_index.render(make_env(), ctx, CFG).html
    assert '<th scope="col">업종</th><th scope="col">상장</th><th scope="col">연도</th>' in html
    samsung = re.search(r'<tr><th scope="row"><a[^>]*>삼성전자</a></th>.*?</tr>', html, re.S).group(0)
    assert '<td class="index-market">코스피</td>' in samsung
    hynix = re.search(r'<tr><th scope="row"><a[^>]*>SK하이닉스</a></th>.*?</tr>', html, re.S).group(0)
    assert '<td class="index-market">비상장</td>' in hynix


def test_index_plain_list_omits_market_without_finance_mapping(fake_bundle, fake_now):
    """재무 매핑이 통째로 없으면 종목코드를 모른다 — 전부 「비상장」이라 찍는 것은 거짓이므로 표시를 생략한다."""
    ctx = build_context(fake_bundle, now=fake_now)  # 재무 없는 빌드 → ul 목록
    html = company_index.render(make_env(), ctx, CFG).html
    assert "index-market" not in html and "비상장" not in html


def test_index_plain_list_shows_market_when_mapping_exists_but_no_figures(fake_bundle, fake_finance, fake_now):
    """매핑만 있고 수치가 없는 빌드(= ul 목록)에서는 업종 옆에 표시가 나온다."""
    mapping = {cid: {"stock_cd": f["stock_cd"]} for cid, f in fake_finance.items() if cid in (1, 2, 3)}
    ctx = build_context(fake_bundle, now=fake_now, finance=mapping)
    # 수치 없이 매핑만 → 표가 아니라 ul 이어야 이 테스트의 뜻이 선다(판정이 바뀌면 조용히 빠지지 말고 실패)
    assert not ctx.finance_loaded
    html = company_index.render(make_env(), ctx, CFG).html
    assert html.count('class="index-market">코스피</span>') == 2  # 삼성전자 · 네이버(픽스처에 재무 2곳)
    assert html.count('class="index-market">비상장</span>') == 1  # 매핑 없는 SK하이닉스


def test_company_page_omits_market_without_finance_mapping(fake_bundle, fake_now):
    ctx = build_context(fake_bundle, now=fake_now)
    html = {p.path: p for p in company.render_all(make_env(), ctx)}["company/samsung-elec.html"].html
    assert "비상장" not in _sub(html) and "lm:skip" not in _sub(html)


def test_company_sub_without_industry_and_type_keeps_clean_separators(fake_bundle, fake_finance, fake_now):
    for c in fake_bundle["companies"]:
        c["industry_nm"] = None
    fake_bundle["company_types"] = []
    html = _pages(fake_bundle, fake_finance, fake_now)["company/samsung-elec.html"].html
    sub = _sub(html)
    assert sub.startswith("<!--lm:skip-->코스피 상장 · <!--/lm:skip-->복지")
    assert re.sub(r"<!--lm:skip-->.*?<!--/lm:skip-->", "", sub).startswith("복지")  # 앞에 「 · 」가 남지 않는다


# ── 빌드 검사 GC-31 ──────────────────────────────────────────────────────────


def test_gc31_passes_when_every_stock_code_has_a_row(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    checks.check_market_rows(ctx, {"005930": "KOSPI", "035420": "KOSPI", "035760": "KOSPI"})


def test_gc31_fails_naming_the_company_when_row_is_missing(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    with pytest.raises(BuildError) as e:
        checks.check_market_rows(ctx, {"005930": "KOSPI"})  # 네이버(035420) 행 없음
    assert "GC-31" in str(e.value) and "네이버" in str(e.value) and "035420" in str(e.value)
    assert "삼성전자" not in str(e.value)


def test_gc31_skips_builds_without_finance(fake_bundle, fake_now):
    checks.check_market_rows(build_context(fake_bundle, now=fake_now), {})


def test_gc31_checks_when_mapping_exists_even_without_figures(fake_bundle, fake_now):
    """수치 적재(finance_loaded)가 아니라 매핑 유무로 가른다 — 매핑만 있어도 표시는 찍힌다."""
    ctx = build_context(fake_bundle, now=fake_now, finance={1: {"stock_cd": "123456"}})
    with pytest.raises(BuildError, match="GC-31"):
        checks.check_market_rows(ctx, {})


def test_gc31_runs_inside_the_build(tmp_path, fake_bundle, fake_finance, fake_combinations_path):
    """build.run 이 GC-31 을 실제로 부른다 — 호출이 빠지면 거짓 「비상장」이 조용히 나간다."""
    fake_finance[1]["stock_cd"] = "123456"  # csv 에 없는 코드
    with pytest.raises(BuildError, match="GC-31.*삼성전자"):
        build_module.run(str(tmp_path / "dist"), fake_bundle, finance=fake_finance, lastmod="2026-10-19")
    assert not (tmp_path / "dist").exists()


def test_every_registered_stock_code_has_a_market_row():
    """저장소 파일 검사 — PR 단계에서 막는다. 시드(load.py)가 서빙 DB 를 먼저 바꾼 뒤 빌드가 GC-31 로 멈추면
    API 와 정적 페이지가 어긋난다. GC-31 은 마지막 안전장치로 그대로 둔다."""
    path = Path(__file__).resolve().parents[2] / "db" / "seed" / "corp_code_map.csv"
    markets = load_markets()
    with open(path, newline="", encoding="utf-8") as fh:
        rows = [r for r in csv.DictReader(fh) if r["status"] != "UNMAPPED" and r["stock_code"].strip()]
    assert rows, "corp_code_map.csv 가 비었다"
    missing = [f"{r['comp_nm']}({r['stock_code'].strip()})" for r in rows if r["stock_code"].strip() not in markets]
    assert not missing, f"krx_sector.csv 에 행이 없는 회사 — 등록 PR 이 시장 행을 더해야 한다: {missing}"


def test_gc31_real_csv_passes_for_fixture_codes(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    checks.check_market_rows(ctx)  # 실제 krx_sector.csv


# ── 「상장사」 문구 ──────────────────────────────────────────────────────────


def test_site_description_and_find_title_do_not_say_listed_companies(fake_bundle, fake_now):
    assert "상장사" not in home.SITE_DESCRIPTION
    ctx = build_context(fake_bundle, now=fake_now)
    page = find.render(make_env(), ctx, CFG, benefit_links={})
    assert "상장사" not in page.title and "상장사" not in page.html
    assert f"회사 {len(fake_bundle['companies'])}곳" in page.html


# ── 연결 검사: DELISTED 가 히트맵 · 대문 · 목록 표에서도 실제로 먹는다 ─────────────────


def test_heatmap_puts_delisted_company_in_unlisted_group(monkeypatch):
    monkeypatch.setattr(heatmap, "load_sectors", lambda: {"005930": "전기·전자", "035420": "IT 서비스", "035760": "오락·문화"})
    monkeypatch.setattr(heatmap, "load_markets", lambda: {"005930": DELISTED, "035420": "KOSPI", "035760": "KOSPI"})
    ctx = build_context(copy.deepcopy(FAKE_BUNDLE), finance=copy.deepcopy(FAKE_FINANCE))
    w = next(m for m in heatmap.build_view(ctx)["modes"] if m["key"] == "w")
    lay = w["panels"][0]["layouts"]["landscape"]
    tiles = {t["nm"]: t["gkey"] for t in lay["tiles"]}
    groups = {g["gkey"]: g["name"] for g in lay["groups"]}
    assert groups[tiles["삼성전자"]] == UNLISTED  # 업종(전기·전자)이 남아 있어도 상장폐지는 비상장 그룹


def test_home_sector_groups_put_delisted_company_in_unlisted_group(fake_bundle, fake_now, monkeypatch):
    monkeypatch.setattr(home, "load_sectors", lambda: {"A": "전기·전자"})
    monkeypatch.setattr(home, "load_markets", lambda: {"A": DELISTED})
    ctx = build_context(fake_bundle, now=fake_now, finance={1: {"stock_cd": "A"}, 2: {"stock_cd": "A"}, 3: {"stock_cd": "A"}})
    names = [g["name"] for g in home._sector_groups(ctx)]
    assert names == [UNLISTED]  # 3사 모두 비상장 그룹 하나로 — 업종(전기·전자)은 안 나온다


def test_index_market_column_sits_under_its_header_in_both_sections(fake_bundle, fake_finance, fake_now):
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    html = company_index.render(make_env(), ctx, CFG).html
    for acct_set in ("general", "financial"):
        start = html.index(f'data-acct-set="{acct_set}"')
        sec = html[start: html.index("</section>", start)]
        pos = re.findall(r'<th scope="col">([^<]*)</th>', sec).index("상장")  # 머리 첫 칸(회사) = 본문 첫 칸(th scope=row)
        rows = re.findall(r'<tr><th scope="row">.*?</tr>', sec, re.S)
        assert rows
        for r in rows:
            cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", r, re.S)
            assert cells[pos] in ("코스피", "코스닥", "코넥스", "비상장"), (acct_set, cells)
