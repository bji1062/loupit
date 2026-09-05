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
from pathlib import Path

import pytest

from generator import corpus as corpus_mod
from generator.context import build_context
from generator.format import amount_kind, badge_state
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
    """이동·강조가 앵커와 CSS 만으로 된다 — 회사 페이지의 <script> 는 전부 **인핸스먼트**다.

    허용 목록으로 잡아 두는 이유: 본문 표시·이동에 필요한 스크립트가 하나라도 늘면 그 순간
    "JS 없이 완성"(NFR24)이 깨진다. 목록의 넷은 모두 죽어도 화면이 성립한다 — 모양 기억
    (metricshape) · 광고(static-ads) · 로그인 메뉴(authnav) · 출처 렌즈 강조(lens)."""
    html = _samsung(fake_bundle, fake_now)
    assert 'href="#b-meal"' in html and 'id="b-meal"' in html
    scripts = re.findall(r'<script[^>]*src="([^"]+)"', html)
    allowed = ("metricshape", "static-ads", "authnav", "lens.js")
    assert all(any(a in s for a in allowed) for s in scripts), scripts


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


def test_rank_of_exposes_item_count_rank_only(fake_bundle):
    """`rank_of()` 가 내는 키는 정확히 이 넷이다 — 금액 순위 키가 되살아나면 여기서 빨개진다.

    낱말 가드가 아니라 **구조 가드**다: `render.py` 는 `undefined=StrictUndefined` 라
    템플릿이 없는 키를 쓰는 순간 빌드가 죽는다. 그러니 `amount_rank`·`amount_tied` 를
    **만들지 않는 것** 자체가 D-6("등록 금액 합에 순위를 붙이지 마라")의 진짜 방어선이고,
    이 테스트는 그 방어선이 뚫렸는지를 본다. 금액 합계 값(`Corpus.amounts`)은 카드의
    '등록 금액 합' 문구가 쓰므로 남는다 — 여기서 막는 것은 **등수·몫**이다.
    """
    companies = [
        {"comp_id": 1, "benefits": [{"benefit_ctgr_cd": "perks", "qual_yn": False,
                                     "benefit_amt": 500}] * 3},
        {"comp_id": 2, "benefits": [{"benefit_ctgr_cd": "perks", "qual_yn": False,
                                     "benefit_amt": 10000}] * 1},
    ]
    corpus = corpus_mod.build(companies, company.CATEGORY_ORDER)
    assert set(corpus.rank_of(1)) == {"total", "item_count", "items_rank", "items_tied"}


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


def _sc_rank_rows(html: str) -> list[tuple[str, str]]:
    """카드 순위 블록의 행 전부를 (머리 텍스트, 행 HTML) 로 낸다.

    ⚠ 두 가지를 일부러 다르게 한다.
      · "등록 금액 합" 은 페이지 **부제**(`company-sub`)에도 있다 — `html.index` 로 바로 자르면
        카드가 아니라 앞쪽 부제가 잡힌다. 그래서 `.sc-rank` 블록 안에서만 자른다.
      · `<dl class="sc-rank">` **전부**를 훑는다. 첫 블록만 보면 순위를 둘째 `<dl>` 에 옮기는
        것만으로 가드를 빠져나간다(실측: 이전 가드가 그 뮤테이션을 통과시켰다).
    """
    rows = []
    for block in re.findall(r'<dl class="sc-rank">(.*?)</dl>', html, re.S):
        for row in re.findall(r"<div>(.*?)</div>", block, re.S):
            head = re.sub(r"<[^>]+>", "", row[:row.index("</dt>")])
            rows.append((head.strip(), row))
    return rows


def test_amount_total_carries_no_rank_and_no_annual_claim(fake_bundle, fake_now):
    """등록 금액에는 대출 한도·일회성 포상 같은 **연간 환산이 아닌 값**이 섞여 있다
    (CJ ENM 커머스 1억 600만원 중 1억 = 주택자금 대출 한도). 그런 합계에 '연' 과 순위를 붙이면
    "이 회사가 1번째" 라는 없는 사실이 된다(D-6).

    열쇠를 '번째' 세기에서 **모집단 문구**로 바꿨다. 이 저장소는 순위든 몫이든 모집단을 떼고
    말하지 않으므로(`113개사 중 …`), 규약을 지키는 금액 순위라면 반드시 '개사 중' 을 달고
    온다 — 낱말 목록을 쫓는 대신 규약에서 도출한 하나를 본다. 셈 대신 **행**으로 자르므로
    금액 순위를 어느 자리에 끼워 넣든(둘째 `<dl>` 포함) 항목 수 행의 문구 변경에는 침묵한다.
    """
    html = _samsung(fake_bundle, fake_now)
    assert "금액 합계 연" not in html
    money = [(k, v) for k, v in _sc_rank_rows(html) if "금액" in k]
    assert money, "카드 순위 블록에서 금액 행을 못 찾았다 — 가드가 헛돌고 있다"
    for head, row in money:
        dd = row[row.index("<dd>"):].strip()
        # ① 구조: 금액 행의 값 칸은 **합계 하나**다. 순위든 몫이든 무엇이 붙어도 여기서 깨진다.
        assert re.fullmatch(r"<dd><strong>[^<]*</strong></dd>", dd), \
            f"금액 행 '{head}' 의 값 칸에 합계 말고 다른 것이 붙었다(D-6): {dd}"
        # ② 규약: 이 저장소는 모집단 없는 순위를 쓰지 않으므로, 규약을 지킨 금액 순위라면
        #    반드시 '개사 중' 을 달고 온다. 값 칸 밖(머리 등)에 끼워도 잡힌다.
        assert "개사 중" not in row, f"금액 행 '{head}' 에 모집단을 낀 순위/몫이 붙었다(D-6)"


def test_item_count_row_keeps_its_population_rank(fake_bundle, fake_now):
    """항목 수 순위 문구 「N개사 중 (공동) M번째」는 **유지하기로 한 결정**이다(2026-09-04 사용자).

    '상위 %' 로 바꾸자는 안을 철회한 이유: 이용자가 늘어 데이터가 좋아지면 동률이 풀린다 —
    지금 107/113 이 '공동' 인 것은 문구의 결함이 아니라 데이터의 현재 상태다. 그 결정이
    조용히 뒤집히지 않도록 여기서 못박는다(D-6 가드와 **다른 축**이라 테스트를 갈랐다).
    """
    html = _samsung(fake_bundle, fake_now)
    # 기대값은 화면이 아니라 corpus 에서 가져온다 — 숫자를 테스트에 적어 두면 픽스처가 늘 때
    # 테스트가 먼저 거짓말을 시작한다.
    corpus = corpus_mod.build(fake_bundle["companies"], company.CATEGORY_ORDER)
    rank = corpus.rank_of(1)  # 1 = samsung_elec(_samsung 이 고른 회사)
    item_row = next(v for k, v in _sc_rank_rows(html) if "등록 복지 항목" in k)
    assert f"{rank['total']}개사 중" in item_row
    assert f"{rank['items_rank']}번째" in item_row


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


def test_radar_vertices_have_hover_hit_areas_with_labels(fake_bundle, fake_now):
    """r=4 점은 마우스를 올리기 어렵다 — 꼭짓점마다 투명 히트 원(r=14) + 즉시 뜨는 CSS 라벨."""
    html = _samsung(fake_bundle, fake_now)
    svg = html[html.index('<svg class="rd"'):]
    svg = svg[:svg.index("</svg>")]
    hits = re.findall(r'<g class="rd-hit"><circle class="rd-hitc" [^>]*r="14"></circle>'
                      r'<text class="rd-hv" [^>]*>([^<]*)</text></g>', svg)
    assert len(hits) == 9
    assert any(t.startswith("복리후생 ") and "평균 " in t for t in hits)
    assert "<title>" not in svg  # role="img" 아래 title 은 안 읽히고, SEO <title> 카운트만 흐린다
    # 히트 원이 마지막에 그려져야 포인터를 받는다(최상단 페인트)
    assert svg.rindex('class="rd-hit"') > svg.rindex('class="rd-lb"')


# ── ④ 모바일 접기 · 출처 렌즈 (SP-GEN-5.7, 2026-09-04) ──────────────────────
#
# 렌즈의 계약은 한 문장이다: **칩이 말한 수 = 띠가 깔리는 행 수 = 사이드 집계**. 셋이 갈리는
# 순간 렌즈는 거짓말이 된다. 그리고 어느 렌즈에서도 **행이 사라지지 않는다** — 숨기면 본문이
# DOM 에서 빠져 색인이 깎이고 "복지가 8개뿐"으로 읽힌다.

CARD_ROW_RE = re.compile(r'class="sc-row[^"]*" href="#(b-[^"]+)" data-lens="([^"]*)"')
LED_ROW_RE = re.compile(r'<article class="led-row" id="(b-[^"]+)" data-amt="[^"]*" data-lens="([^"]*)"')
CHIP_RE = re.compile(r'data-lens-key="([a-z]+)"[^>]*>([^<]*)<b>(\d+)</b>')


def _chips(html: str) -> dict:
    return {k: int(n) for k, _, n in CHIP_RE.findall(html)}


def _card_rows(html: str) -> dict:
    return {a: set(lens.split()) for a, lens in CARD_ROW_RE.findall(html)}


def test_lens_chip_number_equals_the_rows_it_highlights(fake_bundle, fake_now):
    """칩의 숫자와 그 칩이 띠를 까는 행 수가 같다. 판정을 복사하면 여기서 갈린다."""
    for p in _render(fake_bundle, fake_now).values():
        chips = _chips(p.html)
        if not chips:
            continue
        rows = _card_rows(p.html)
        assert chips["all"] == len(rows), f"{p.path}: 전체 칩 {chips['all']} ≠ 행 {len(rows)}"
        for key, n in chips.items():
            if key == "all":
                continue
            hit = sum(1 for keys in rows.values() if key in keys)
            assert hit == n, f"{p.path}: 칩 {key}={n} 인데 그 키를 가진 행은 {hit}"


def test_ledger_row_carries_the_same_lens_keys_as_the_card_row(fake_bundle, fake_now):
    """카드와 원장은 같은 27행이다 — 렌즈 키가 어긋나면 한 화면만 띠가 깔린다."""
    for p in _render(fake_bundle, fake_now).values():
        card = _card_rows(p.html)
        ledger = {a: set(lens.split()) for a, lens in LED_ROW_RE.findall(p.html)}
        assert card, f"{p.path}: 카드 행이 없다"
        assert card == ledger, f"{p.path}: 카드↔원장 렌즈 키 불일치"


def test_lens_chips_are_hidden_until_js_wakes_them(fake_bundle, fake_now):
    """JS 가 죽거나 늦게 와도 **죽은 컨트롤이 남지 않는다**(`data-authnav-edit` 와 같은 규약).
    렌즈는 본문이 아니라 강조라, 없으면 지금 배포된 화면 그대로다(NFR24)."""
    html = _samsung(fake_bundle, fake_now)
    assert '<div class="sc-lens" hidden data-lens-chips>' in html
    assert html.count("data-lens-key=") >= 2


def test_lens_omits_buckets_that_have_no_rows(fake_bundle, fake_now):
    """0건 칩은 눌러도 27행이 전부 흐려지기만 하는 컨트롤이다 — 내보내지 않는다.
    숫자로서의 0 은 사이드 「항목 구성」이 이미 말한다."""
    html = _samsung(fake_bundle, fake_now)
    chips = _chips(html)
    assert chips == {"all": 4, "stated": 1, "est": 1, "qual": 2, "expired": 1}, chips
    assert "재직자 등록·수정 <b>" not in html  # 편집 이력 0 인 회사


def test_lens_disappears_when_there_is_only_one_bucket(fake_now):
    """모든 행이 같은 통에 들어가면 렌즈는 '전체'와 같은 말을 두 번 하는 것이다 — 안 낸다."""
    bundle = {
        "company_types": [], "benefit_presets": {},
        "companies": [{
            "comp_id": 9, "comp_eng_nm": "qualonly2", "comp_nm": "정성만사", "comp_tp_cd": "none",
            "industry_nm": "IT", "logo_nm": "Q", "work_style_val": {}, "aliases": [],
            "benefits": [{
                "benefit_cd": f"q{i}", "benefit_nm": f"정성{i}", "benefit_amt": None,
                "benefit_ctgr_cd": "work_env", "badge_cd": "official", "amt_source": "none",
                "qual_yn": True, "qual_desc_ctnt": "설명", "verified_dtm": "2026-01-01",
                "expires_dtm": "2099-12-31",
            } for i in range(3)],
        }],
    }
    env = make_env()
    ctx = build_context(bundle, now=fake_now)
    html = company.render_all(env, ctx)[0].html
    assert "data-lens-chips" not in html
    assert 'data-lens="qual"' in html  # 행의 키는 그대로 있다(원장·카드 정합)


def test_lens_keys_are_a_projection_of_the_two_existing_judgments(fake_now):
    """🚨 렌즈는 **새 판정을 만들지 않는다.** 금액 축은 `format.amount_kind`, 계보 축은
    `format.badge_state` 가 이미 정한 것을 투영만 한다. 두 축은 독립이라(DEC-2) '공식' 배지가
    붙은 추정 금액은 `stated` 가 아니라 `est` 다."""
    cases = [
        ({"benefit_amt": 100, "amt_source": "stated", "qual_yn": False, "badge_cd": "official"}, {"stated"}),
        ({"benefit_amt": 100, "amt_source": "estimated", "qual_yn": False, "badge_cd": "official"}, {"est"}),
        ({"benefit_amt": None, "amt_source": "none", "qual_yn": True, "badge_cd": "official"}, {"qual"}),
        ({"benefit_amt": None, "amt_source": "none", "qual_yn": False, "badge_cd": "official"}, {"blank"}),
        ({"benefit_amt": 100, "amt_source": "stated", "qual_yn": False, "badge_cd": "official",
          "edit_origin": "member"}, {"stated", "edited"}),
        ({"benefit_amt": 100, "amt_source": "stated", "qual_yn": False, "badge_cd": "official",
          "edit_origin": "edited"}, {"stated", "edited"}),
        ({"benefit_amt": 100, "amt_source": "estimated", "qual_yn": False, "badge_cd": "official",
          "expires_dtm": "2020-01-01"}, {"est", "expired"}),
    ]
    for b, expected in cases:
        keys = set(company.lens_keys(amount_kind(b), bool(b["qual_yn"]),
                                     badge_state(b, fake_now)["code"]))
        assert keys == expected, f"{b} → {keys}"


def test_lens_bar_says_the_same_number_as_its_chip(fake_bundle, fake_now):
    """띠 설명은 **행이 사라진 게 아니라 흐려졌을 뿐**이라고 말해야 한다 — 그 말이 없으면
    사용자는 '복지가 1개뿐'으로 읽는다. 숫자는 칩과 같은 곳에서 나온다."""
    html = _samsung(fake_bundle, fake_now)
    bars = dict(re.findall(r'data-lens-for="([a-z]+)">([^<]+)<', html))
    chips = _chips(html)
    assert set(bars) == set(chips) - {"all"}, bars
    for key, text in bars.items():
        assert f"{chips[key]}항목" in text, text
        assert "사라지지 않습니다" in text, text


def test_every_lens_bucket_is_wired_in_the_js_whitelist_and_the_css(fake_bundle, fake_now):
    """🚨 통 목록은 **세 파일**에 있다: `company.py::LENS_BUCKETS`(정본) · `lens.js::LENS_KEYS`
    (화이트리스트) · `styles.css`(띠·감쇠 규칙). 통을 하나 더하고 파이썬만 고치면 파이썬 테스트는
    전부 통과하는데 화면에서는 **눌러도 아무 일 없는 죽은 칩**이 된다(JS 가 목록 밖 키를 무시하고
    CSS 에 규칙이 없다). 에러 없이 틀린 동작 — 이 저장소가 가장 자주 밟은 함정이라 세 파일을
    여기서 잇는다."""
    root = Path(__file__).resolve().parents[2]
    js = (root / "web" / "assets" / "js" / "lens.js").read_text(encoding="utf-8")
    css = (root / "web" / "assets" / "css" / "styles.css").read_text(encoding="utf-8")
    for key, label, note in company.LENS_BUCKETS:
        assert f"'{key}'" in js, f"lens.js LENS_KEYS 에 {key} 없음 — 칩이 죽은 컨트롤이 된다"
        assert f'[data-lens-on="{key}"]' in css, f"styles.css 에 {key} 렌즈 상태 규칙 없음"
        assert f'[data-lens~="{key}"]' in css, f"styles.css 에 {key} 행 선택자 없음"
        assert label and note, f"{key}: 라벨·설명 문장이 비어 있다"


# ── ① 모바일에서 카드 행을 접는다 ───────────────────────────────────────────


def test_card_category_header_links_to_its_ledger_category(fake_bundle, fake_now):
    """모바일에서 행 목록을 접으면 카테고리 머리가 유일한 이동 수단이 된다 — 원장의 그
    카테고리로 정확히 떨어져야 한다(`scroll-margin-top` 은 이미 있다)."""
    for p in _render(fake_bundle, fake_now).values():
        heads = set(re.findall(r'<a class="sc-cat-go" href="#(cat-[a-z_]+)"', p.html))
        groups = set(re.findall(r'<section class="benefit-group" id="(cat-[a-z_]+)"', p.html))
        assert heads, f"{p.path}: 카테고리 머리 링크가 없다"
        assert heads == groups, f"{p.path}: 카드↔원장 카테고리 앵커 불일치 {heads ^ groups}"


def test_card_hint_tells_the_truth_on_both_widths(fake_bundle, fake_now):
    """폰에서는 누를 행이 없다 — "항목을 누르면" 은 그 화면에서 거짓이다. 두 문장을 함께
    내보내고 CSS 가 폭에 따라 하나만 보여 준다(JS 0)."""
    html = _samsung(fake_bundle, fake_now)
    assert '<span class="sc-hint-wide">' in html and "항목을 누르면" in html
    assert '<span class="sc-hint-narrow">' in html and "카테고리를 누르면" in html
