"""generator/tests/test_stat_card.py — 복지 스탯 카드 + 원장 (SP-GEN-5.6, 2026-09-03 채택).

계약 셋을 잡는다:
  ① **카드는 목차, 원장이 본문** — 카드 행의 `#앵커` 가 원장 행 `id` 와 1:1이고, 설명 전문은
     원장에만 있다(두 곳에 두면 같은 문장이 두 번 실리거나 한쪽만 갱신된다).
  ② **금액 신뢰도는 배지와 독립축** — '공식' 배지가 붙은 추정 금액이 맨숫자로 나가지 않는다.
  ③ **비교 기준은 사실만** — 평균·순위는 corpus 하나가 만들고, 동률은 '공동'으로 드러낸다.
"""
from __future__ import annotations

import re
from datetime import datetime

import pytest

from generator import corpus as corpus_mod
from generator.context import build_context
from generator.format import amount_kind
from generator.pages import company
from generator.radar import radar_svg
from generator.render import make_env


def _render(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return {p.path: p for p in company.render_all(env, ctx)}


def _samsung(fake_bundle, fake_now):
    return _render(fake_bundle, fake_now)["company/samsung-elec.html"].html


# ── ① 카드 = 목차, 원장 = 본문 ──────────────────────────────────────────────


def test_card_row_anchors_match_ledger_row_ids_one_to_one(fake_bundle, fake_now):
    """카드 행 링크가 전부 원장 행으로 떨어진다. 하나라도 어긋나면 그 링크는 **에러 없이**
    페이지 맨 위로 간다 — 눈에 안 띄는 고장이라 테스트가 유일한 방어선이다."""
    for p in _render(fake_bundle, fake_now).values():
        card_links = set(re.findall(r'class="sc-row[^"]*" href="#(b-[^"]+)"', p.html))
        ledger_ids = set(re.findall(r'<article class="led-row" id="(b-[^"]+)"', p.html))
        assert card_links, f"{p.path}: 카드 행 링크가 없다"
        assert card_links == ledger_ids, f"{p.path}: 카드↔원장 앵커 불일치 {card_links ^ ledger_ids}"


def test_every_benefit_appears_once_in_card_and_once_in_ledger(fake_bundle, fake_now):
    html = _samsung(fake_bundle, fake_now)
    for name in ("식대 지원", "성과급 인센티브", "리프레시 휴가"):
        assert html.count(f">{name}<") == 2, f"{name} 은 카드 1 + 원장 1 이어야 한다"


def test_benefit_description_lives_only_in_the_ledger(fake_bundle, fake_now):
    """정성 설명·비고의 집은 원장 하나다(SEO 본문이자 중복 방지)."""
    html = _samsung(fake_bundle, fake_now)
    desc = "3년 근속마다 2주 부여"
    assert html.count(desc) == 1
    ledger_start = html.index('id="benefit-ledger"')
    assert html.index(desc) > ledger_start, "설명이 카드 쪽에 새어 있다"


def test_ledger_row_can_be_targeted_without_js(fake_bundle, fake_now):
    """이동·강조가 앵커와 CSS 만으로 된다 — 회사 페이지의 유일한 <script> 는 그래프 모양 기억뿐."""
    html = _samsung(fake_bundle, fake_now)
    assert 'href="#b-meal"' in html and 'id="b-meal"' in html
    scripts = re.findall(r'<script[^>]*src="([^"]+)"', html)
    assert all("metricshape" in s or "static-ads" in s or "authnav" in s for s in scripts), scripts


# ── ② 금액 신뢰도 ≠ 배지 ────────────────────────────────────────────────────


def test_estimated_amount_is_marked_even_when_badge_is_official(fake_bundle, fake_now):
    """픽스처의 '식대 지원' 은 badge_cd=official + amt_source=estimated 다 — 이 조합이 실데이터의
    다수(SK텔레콤 금액 11건 중 8건)이고, 첫 시안이 이걸 공식 수치로 오독했다."""
    html = _samsung(fake_bundle, fake_now)
    row = html[html.index('id="b-meal"'):]
    row = row[:row.index("</article>")]
    assert "추정치" in row, "추정 금액인데 원장이 그렇게 말하지 않는다"
    assert "benefit-amount est" in row, "추정 금액에 표식(점선 클래스)이 없다"
    # 같은 행의 배지는 계보(공식)를 그대로 말한다 — 두 축을 합치지 않는다
    assert "badge-official" in row


def test_stated_amount_is_not_marked_as_estimate(fake_bundle, fake_now):
    html = _samsung(fake_bundle, fake_now)
    row = html[html.index('id="b-incentive"'):]
    row = row[:row.index("</article>")]
    assert "회사 공식 수치" in row and "추정치" not in row


def test_amount_tally_matches_the_source_rows(fake_bundle, fake_now):
    """사이드 '항목 구성' 의 숫자는 **원본 복지 행에서 직접 센 값**과 같아야 한다.

    (합이 맞는지만 보면 `stated+est+qual == total` 은 분할의 정의라 항상 참이라 아무것도 못 잡는다.)
    """
    ctx = build_context(fake_bundle, now=fake_now)
    corpus = corpus_mod.build(ctx.companies, company.CATEGORY_ORDER)
    for c in ctx.companies:
        raw = c["benefits"]
        groups = company._group_benefits(raw, fake_now, comp_id=c["comp_id"])
        counts = company._card_view(c, groups, corpus)["counts"]
        assert counts["total"] == len(raw)
        assert counts["stated"] == sum(1 for b in raw if amount_kind(b) == "stated")
        assert counts["est"] == sum(1 for b in raw if amount_kind(b) == "estimated")
        assert counts["qual"] == sum(1 for b in raw if b["qual_yn"])
        assert counts["blank"] == sum(1 for b in raw if amount_kind(b) == "none" and not b["qual_yn"])
        assert counts["stated"] + counts["est"] + counts["qual"] + counts["blank"] == counts["total"]
        assert counts["amount"] == counts["stated"] + counts["est"]


def test_anchor_ids_are_unique_not_just_matching(fake_bundle, fake_now):
    """집합 비교는 같은 id 가 두 번 있어도 통과한다 — 개수까지 본다."""
    for p in _render(fake_bundle, fake_now).values():
        ids = re.findall(r'<article class="led-row" id="(b-[^"]+)"', p.html)
        assert len(ids) == len(set(ids)), f"{p.path}: 중복 앵커 {ids}"


def test_company_with_no_convertible_amount_never_says_zero(fake_now):
    """정량 금액이 하나도 없는 회사(실데이터 11곳: KB금융·LG CNS 등)에 '0만원' 을 찍지 않는다.

    `krw_manwon(0)` 이 "0만원"(truthy)이라 폴백이 안 걸렸다 — 없는 값을 0 으로 **표시**하는 것은
    0 으로 **더하는** 것과 다르다(corpus 주석과 같은 규칙)."""
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 7, "comp_eng_nm": "qualonly", "comp_nm": "정성전용사", "comp_tp_cd": "none",
            "industry_nm": "IT", "logo_nm": "Q", "work_style_val": {}, "aliases": [],
            "benefits": [{
                "benefit_cd": "lounge", "benefit_nm": "라운지", "benefit_amt": None,
                "benefit_ctgr_cd": "work_env", "badge_cd": "official", "amt_source": "none",
                "qual_yn": True, "qual_desc_ctnt": "휴게공간 운영",
                "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
            }],
        }],
    }
    env = make_env()
    ctx = build_context(bundle, now=fake_now)
    html = company.render_all(env, ctx)[0].html
    assert "0만원" not in html
    assert "금액 합계 연" not in html  # 부제에서도 빠진다


def test_row_with_no_amount_but_not_qualitative_is_named_consistently(fake_now):
    """`qual_yn=False` 인데 금액이 빈 행 — 재직자가 금액을 비운 채 저장하면 실제로 생긴다
    (`services/benefit_edit.py` 가 `amt_source='none'` 으로 만든다).

    카드·원장·히트맵이 이 행을 **같은 축으로** 부르는지 본다. 예전에는 히트맵만 '추정치' 로
    분류해 한 복지가 화면마다 다른 출처를 갖고 있었다."""
    from generator.pages import heatmap

    b = {
        "benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": None,
        "benefit_ctgr_cd": "perks", "badge_cd": "official", "amt_source": "none",
        "qual_yn": False, "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
    }
    assert amount_kind(b) == "none"
    assert heatmap._source_of(b) == "qual"  # 추정치로 색칠하지 않는다
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 8, "comp_eng_nm": "blankamt", "comp_nm": "금액미기재사", "comp_tp_cd": "none",
            "industry_nm": "IT", "logo_nm": "B", "work_style_val": {}, "aliases": [], "benefits": [b],
        }],
    }
    env = make_env()
    ctx = build_context(bundle, now=fake_now)
    html = company.render_all(env, ctx)[0].html
    assert "금액 미기재" in html          # 카드: 정성과 구분되는 말
    assert "금액 환산 없음" in html        # 원장: 금액을 모른다는 사실
    # 사이드 집계도 갈라 센다 — '정성 항목' 0, '금액 미기재' 1
    assert "정성 항목<span>금액 환산 불가</span></dt><dd>0</dd>" in html
    assert "금액 미기재<span>환산 가능·값 모름</span></dt><dd>1</dd>" in html


# ── ③ 비교 기준(코퍼스)은 사실만 ────────────────────────────────────────────


def test_corpus_average_and_axis_max_are_computed_once_over_all_companies(fake_bundle):
    corpus = corpus_mod.build(fake_bundle["companies"], company.CATEGORY_ORDER)
    n = len(fake_bundle["companies"])
    assert corpus.total == n
    # 평균 = 그 카테고리 항목 수의 산술평균(빈 회사도 0 으로 센다 — 없는 축은 '없다'는 사실이다)
    per = [sum(1 for b in c["benefits"] if b["benefit_ctgr_cd"] == "perks") for c in fake_bundle["companies"]]
    assert corpus.avgs["perks"] == pytest.approx(sum(per) / n)
    assert corpus.rmax == max(
        max(sum(1 for b in c["benefits"] if b["benefit_ctgr_cd"] == k) for k in company.CATEGORY_ORDER)
        for c in fake_bundle["companies"]
    )


def test_rank_discloses_ties(fake_bundle):
    """동률을 숨긴 '2번째' 는 거짓이다(실측: SK텔레콤 27항목 = LG CNS 27항목)."""
    companies = [
        {"comp_id": 1, "benefits": [{"benefit_ctgr_cd": "perks", "qual_yn": True}] * 3},
        {"comp_id": 2, "benefits": [{"benefit_ctgr_cd": "perks", "qual_yn": True}] * 3},
        {"comp_id": 3, "benefits": [{"benefit_ctgr_cd": "perks", "qual_yn": True}] * 9},
    ]
    corpus = corpus_mod.build(companies, company.CATEGORY_ORDER)
    tied = corpus.rank_of(1)
    assert (tied["items_rank"], tied["items_tied"]) == (2, True)
    top = corpus.rank_of(3)
    assert (top["items_rank"], top["items_tied"]) == (1, False)


def test_page_prints_the_tie_word_when_tied(fake_bundle, fake_now):
    """픽스처 3사 중 두 곳이 항목 수가 같으면 화면에 '공동' 이 나온다."""
    counts = sorted(len(c["benefits"]) for c in fake_bundle["companies"])
    pages = _render(fake_bundle, fake_now)
    if len(set(counts)) < len(counts):  # 동률이 있는 픽스처에서만 의미 있는 단언
        assert any("공동" in p.html for p in pages.values())
    for p in pages.values():
        assert "개사 중" in p.html  # 순위 문구 자체는 모든 회사에 있다


# ── 레이더 SVG(정적) ────────────────────────────────────────────────────────


def test_radar_has_nine_axes_and_two_polygons(fake_bundle, fake_now):
    html = _samsung(fake_bundle, fake_now)
    svg = html[html.index("<svg class=\"rd\""):]
    svg = svg[:svg.index("</svg>")]
    assert svg.count('class="rd-ax"') == 9
    assert 'class="rd-you"' in svg and 'class="rd-avg"' in svg  # 회사 + 등록사 평균
    assert svg.count('class="rd-lb"') == 9


def test_radar_aria_label_carries_the_numbers_not_just_the_shape(fake_bundle, fake_now):
    """그림을 못 보는 사람에게 '그래프'라고만 말하는 것은 아무것도 말하지 않는 것이다."""
    html = _samsung(fake_bundle, fake_now)
    m = re.search(r'<svg class="rd" viewBox="[^"]*" role="img" aria-label="([^"]+)"', html)
    assert m and "삼성전자" in m.group(1)
    assert re.search(r"복리후생 \d+", m.group(1))


def test_radar_refuses_mismatched_series():
    """길이가 어긋난 채 그리면 '건강' 자리에 '가족' 값이 찍혀도 아무도 모른다."""
    with pytest.raises(ValueError):
        radar_svg([1, 2, 3], [0.5, 0.5], ["a", "b", "c"], 8)


def test_radar_survives_a_company_with_an_empty_category(fake_now):
    """빈 카테고리는 0 이다 — 축을 빼면 회사마다 모양의 뜻이 달라진다."""
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 5, "comp_eng_nm": "onecat", "comp_nm": "한칸사", "comp_tp_cd": "none",
            "industry_nm": "기타", "logo_nm": "O", "work_style_val": {}, "aliases": [],
            "benefits": [{
                "benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 100,
                "benefit_ctgr_cd": "perks", "badge_cd": "official", "amt_source": "stated",
                "qual_yn": False, "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
            }],
        }],
    }
    env = make_env()
    ctx = build_context(bundle, now=fake_now)
    html = company.render_all(env, ctx)[0].html
    svg = html[html.index("<svg class=\"rd\""):]
    assert svg[:svg.index("</svg>")].count('class="rd-ax"') == 9


# ── 편집 진입(SC14) ─────────────────────────────────────────────────────────


def test_edit_link_points_at_the_exact_benefit_and_stays_hidden_until_m9(fake_bundle, fake_now):
    """`/edit` 은 M9 게이트 뒤다 — 꺼진 호스트에 노출하면 404 로 가는 진입점이 된다."""
    html = _samsung(fake_bundle, fake_now)
    links = re.findall(r'<a class="led-ask-go"([^>]*)>', html)
    assert links, "편집 진입 링크가 없다"
    for attrs in links:
        assert "data-authnav-edit" in attrs and "hidden" in attrs
        assert 'rel="nofollow"' in attrs
    assert 'href="/edit?comp=1&amp;benefit=meal"' in html


def test_edit_ask_wording_follows_the_amount_source(fake_bundle, fake_now):
    html = _samsung(fake_bundle, fake_now)

    def ask_of(anchor):
        row = html[html.index(f'id="{anchor}"'):]
        row = row[:row.index("</article>")]
        m = re.search(r'class="led-ask-go"[^>]*>([^<]+)</a>', row)
        return m.group(1) if m else ""

    assert "실제 금액" in ask_of("b-meal")          # 추정 금액 → 실제 값을 묻는다
    assert ask_of("b-incentive").startswith("수정")  # 회사 공식 수치 → 묻지 않는다
    assert "환산 금액" in ask_of("b-refresh_leave")  # 정성 → 환산 값을 묻는다


def test_combo_page_rows_carry_no_edit_link():
    """조합 페이지는 남의 회사 복지를 나란히 두는 자리라 '수정'이 누구 것인지 모호해진다."""
    groups = company._group_benefits(
        [{"benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 100, "benefit_ctgr_cd": "perks",
          "badge_cd": "official", "amt_source": "stated", "qual_yn": False,
          "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31"}],
        datetime(2026, 7, 11),
    )
    assert groups[0][2][0]["edit_href"] is None

# ── 화면 간 정합(히트맵 ↔ 회사 페이지) ─────────────────────────────────────


def test_heatmap_category_tiles_land_on_a_real_ledger_row(fake_bundle, fake_now):
    """히트맵 카테고리 칸의 `#b-…` 가 그 회사 원장에 **실재하는 id** 여야 한다.

    앵커 문자열을 두 곳에서 만들면 어긋나도 에러가 없다 — 링크는 조용히 페이지 맨 위로 간다.
    두 페이지를 실제로 대조하는 테스트는 이것 하나뿐이다."""
    from generator.pages import heatmap

    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    ledger = {}
    for p in company.render_all(env, ctx):
        slug = p.path[len("company/"):-len(".html")]
        ledger[slug] = set(re.findall(r'<article class="led-row" id="(b-[^"]+)"', p.html))
    seen = 0
    for mode in heatmap.build_view(ctx, {})["modes"]:
        for panel in mode["panels"]:
            for t in panel["layouts"]["landscape"]["tiles"]:
                if "#" not in t["href"]:
                    continue  # 복지·실적 모드는 회사 단위라 앵커가 없다
                slug, anchor = t["href"].split("#")
                slug = slug[len("/company/"):]
                assert anchor in ledger[slug], f"{slug}: 히트맵 칸 #{anchor} 가 원장에 없다"
                seen += 1
    assert seen, "앵커가 붙은 칸이 하나도 없다(카테고리 모드가 비었나)"


def test_axis_scale_is_identical_across_companies(fake_bundle, fake_now):
    """레이더 축 최댓값은 **등록 회사 전체 기준**이라 모든 페이지에서 같아야 한다.

    회사마다 자기 최댓값으로 정규화하면 모양이 회사 간 비교가 아니라 자기 자랑이 된다."""
    ends = set()
    for p in _render(fake_bundle, fake_now).values():
        svg = p.html[p.html.index('<svg class="rd"'):]
        svg = svg[:svg.index("</svg>")]
        ends.add(tuple(re.findall(r'<line class="rd-ax"[^>]*x2="([\d.]+)" y2="([\d.]+)"', svg)))
    assert len(ends) == 1, "회사마다 축 끝점이 다르다 — 스케일이 회사별로 잡혔다"

# ── 리뷰 반영 회귀(2026-09-04) ──────────────────────────────────────────────


def test_note_and_qual_desc_are_both_kept(fake_now):
    """정성 설명과 비고는 다른 필드다 — `or` 로 묶으면 둘 다 있는 행에서 비고가 사라진다
    (라이브 6행: 케어젠 '휴가비 지원', 텔레칩스 'Productivity Incentive…')."""
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 9, "comp_eng_nm": "bothtext", "comp_nm": "둘다사", "comp_tp_cd": "none",
            "industry_nm": "IT", "logo_nm": "B", "work_style_val": {}, "aliases": [],
            "benefits": [{
                "benefit_cd": "leave", "benefit_nm": "연차/반차", "benefit_amt": None,
                "benefit_ctgr_cd": "time_off", "badge_cd": "official", "amt_source": "none",
                "qual_yn": True, "qual_desc_ctnt": "연차, 반차, 경조휴가", "note_ctnt": "휴가비 지원",
                "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
            }],
        }],
    }
    html = company.render_all(make_env(), build_context(bundle, now=fake_now))[0].html
    assert "연차, 반차, 경조휴가" in html and "휴가비 지원" in html


def test_amount_total_carries_no_rank_and_no_annual_claim(fake_bundle, fake_now):
    """등록 금액에는 대출 한도·일회성 포상 같은 **연간 환산이 아닌 값**이 섞여 있다
    (CJ ENM 커머스 1억 600만원 중 1억 = 주택자금 대출 한도). 그런 합계에 '연' 과 순위를 붙이면
    "이 회사가 1번째" 라는 없는 사실이 된다(D-6)."""
    html = _samsung(fake_bundle, fake_now)
    assert "금액 합계 연" not in html
    assert "등록 금액 합" in html
    rank_block = html[html.index('class="sc-rank"'):html.index("</dl>", html.index('class="sc-rank"'))]
    assert "번째" in rank_block  # 항목 수 순위는 남는다(우리가 센 사실이다)
    assert rank_block.count("번째") == 1, "금액 순위가 아직 있다"


def test_all_estimated_company_says_so(fake_now):
    """공식 수치가 하나도 없는 회사가 65/113 이다 — 그 합계를 '(추정 포함)' 이라 부르면 과소 진술이다."""
    row = lambda cd, amt: {
        "benefit_cd": cd, "benefit_nm": cd, "benefit_amt": amt, "benefit_ctgr_cd": "perks",
        "badge_cd": "official", "amt_source": "estimated", "qual_yn": False,
        "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
    }
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 10, "comp_eng_nm": "allest", "comp_nm": "전부추정사", "comp_tp_cd": "none",
            "industry_nm": "IT", "logo_nm": "A", "work_style_val": {}, "aliases": [],
            "benefits": [row("meal", 300), row("club", 24)],
        }],
    }
    html = company.render_all(make_env(), build_context(bundle, now=fake_now))[0].html
    assert "(전부 추정)" in html and "(추정 포함)" not in html


def test_robots_keeps_the_login_shell_out_of_the_crawl_budget():
    """원장이 회사×항목마다 `/edit?comp=&benefit=` 를 만든다(라이브 1,755 고유 URL).
    `noindex` 는 크롤한 **뒤에** 적용되므로 예산은 이미 쓰인 뒤다 — 이 사이트의 병목이 거기다."""
    from generator.pages import sitemap as sitemap_page

    txt = sitemap_page.render_robots().html
    for path in ("/edit", "/edits", "/login", "/mypage", "/verify"):
        assert f"Disallow: {path}" in txt, path
