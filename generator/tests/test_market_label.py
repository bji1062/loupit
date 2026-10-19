"""상장 구분 표시(코스피 상장 · 코스닥 상장 · 코넥스 상장 · 비상장) — `sector.market_of` · 회사 페이지 ·
회사 목록 · 빌드 검사 GC-31 · 「상장사」 문구 (2026-10-19, 사용자 결정 2026-10-18: 비상장 대기업도 등록한다)."""
from __future__ import annotations

import re

import pytest

from generator import checks
from generator.config import CFG
from generator.context import build_context
from generator.pages import company, company_index, find, home
from generator.release import _content_fingerprint
from generator.render import make_env
from generator.sector import DELISTED, UNLISTED, load_markets, load_sectors, market_of, sector_of
from generator.slug import BuildError

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


def test_index_plain_list_shows_market_next_to_industry(fake_bundle, fake_now):
    ctx = build_context(fake_bundle, now=fake_now)  # 재무 없는 빌드 → ul 목록
    html = company_index.render(make_env(), ctx, CFG).html
    assert html.count('class="index-market">비상장</span>') == len(fake_bundle["companies"])


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
