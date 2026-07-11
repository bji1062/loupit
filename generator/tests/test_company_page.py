"""T-07.5 회사 상세 본문 렌더 테스트 (GC-6·11·12·13·14·15·16·17)."""
from __future__ import annotations

import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import company
from generator.render import make_env


def _render(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return {p.path: p for p in company.render_all(env, ctx)}


def _samsung(fake_bundle, fake_now):
    pages = _render(fake_bundle, fake_now)
    return pages["company/samsung-elec.html"]


def _naver(fake_bundle, fake_now):
    pages = _render(fake_bundle, fake_now)
    return pages["company/naver.html"]


# ── GC-6: 단일 h1 = 정식명 ──────────────────────────────────────────────


def test_gc6_company_page_has_exactly_one_h1_with_company_name(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    h1s = re.findall(r"<h1>(.*?)</h1>", p.html)
    assert len(h1s) == 1
    assert h1s[0] == "삼성전자"


# ── GC-11: 복지 비어있지 않음(프리셋 폴백 흔적 없음) ────────────────────────


def test_gc11_every_company_has_at_least_one_non_empty_benefit_category(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    for c in fake_bundle["companies"]:
        groups = company._group_benefits(c["benefits"], fake_now)
        assert len(groups) >= 1
        assert sum(len(items) for _, _, items in groups) >= 1


def test_gc11_no_benefit_preset_fallback_marker_in_rendered_html(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert "preset" not in p.html.lower()
    assert "benefit_presets" not in p.html


# ── GC-12: 근무형태 허위 금지 — true 키만 "제공" ────────────────────────────


def test_gc12_work_style_only_true_keys_are_labeled_provided(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    # samsung_elec work_style_val = {remote:True, flex:True, overtime:True}
    assert p.html.count("제공") == 3
    assert "재택근무 제공" in p.html
    assert "유연근무 제공" in p.html
    assert "야근 있음(고지) 제공" in p.html
    assert "무제한 휴가 제공" not in p.html
    assert "리프레시 휴가 제공" not in p.html


def test_gc12_work_style_section_omitted_when_no_true_keys():
    from datetime import datetime

    bundle = {
        "company_types": [],
        "benefit_presets": {},
        "companies": [
            {
                "comp_id": 9,
                "comp_eng_nm": "empty_ws",
                "comp_nm": "빈근무사",
                "comp_tp_cd": "none",
                "industry_nm": "기타",
                "logo_nm": "E",
                "work_style_val": {},
                "aliases": [],
                "benefits": [
                    {
                        "benefit_nm": "테스트 복지",
                        "benefit_amt": 10,
                        "benefit_ctgr_cd": "perks",
                        "badge_cd": "official",
                        "amt_source": "stated",
                        "qual_yn": False,
                        "verified_dtm": "2026-01-01",
                        "expires_dtm": "2099-12-31",
                    }
                ],
            }
        ],
    }
    env = make_env()
    ctx = build_context(bundle, now=datetime(2026, 7, 11))
    pages = company.render_all(env, ctx)
    assert "근무형태" not in pages[0].html.split("복지 항목")[0]


# ── GC-13: 배지 3파생 라벨 ──────────────────────────────────────────────


def test_gc13_official_badge_label_present(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert "공식 확인" in p.html


def test_gc13_estimated_badge_label_present(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert "추정" in p.html


def test_gc13_stale_badge_label_present_for_expired_benefit(fake_bundle, fake_now):
    # 건강검진 지원 항목의 expires_dtm=2020-01-01 → fake_now(2026) 기준 만료
    p = _samsung(fake_bundle, fake_now)
    assert "만료·재확인 필요" in p.html


def test_gc13_badge_is_text_label_not_only_color(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert re.search(r'class="badge badge-(official|est|stale)"[^>]*>(공식 확인|추정|만료·재확인 필요)', p.html)


# ── GC-14: 출처 스킴 화이트리스트(http/https만 링크) ────────────────────────


def test_gc14_javascript_scheme_source_url_not_linked(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert "javascript:" not in p.html


def test_gc14_https_scheme_source_url_is_linked(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert 'href="https://ex.com/samsung/perks"' in p.html


# ── GC-15: 면책 노출 ─────────────────────────────────────────────────────


def test_gc15_disclaimer_block_and_link_present_on_every_company_page(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    for p in company.render_all(env, ctx):
        assert 'class="disclaimer"' in p.html
        assert 'href="/disclaimer"' in p.html


# ── GC-16: CTA 프리필(순수 <a>, prefill/slot 파라미터 미방출) ──────────────


def test_gc16_company_cta_href_has_pure_a_param(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert f'href="{CFG.compare_path}?a=samsung_elec"' in p.html
    assert "이 회사로 비교하기" in p.html


def test_gc16_no_prefill_or_slot_param_emitted(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    for p in company.render_all(env, ctx):
        cta_hrefs = re.findall(r'class="cta"><a href="([^"]+)"', p.html)
        assert cta_hrefs, "CTA <a href> 미검출"
        for href in cta_hrefs:
            assert "prefill=" not in href
            assert "slot=" not in href


# ── GC-17: 광고 슬롯 자리·표기·min-height, 복지표 내부 슬롯 0 ──────────────


def test_gc17_company_page_has_content_mid_and_content_bottom_ad_slots(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert p.html.count('class="ad-slot"') == 2
    assert 'data-slot="content_mid"' in p.html
    assert 'data-slot="content_bottom"' in p.html
    assert p.html.count('class="ad-label">광고</span>') == 2
    assert re.search(r'ad-slot"[^>]*style="min-height:\d+px"', p.html)


def test_gc17_ad_client_id_is_placeholder(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert f'data-ad-client="{CFG.adsense_client_id}"' in p.html
    assert "ca-pub-XXXX" in p.html or CFG.adsense_client_id in p.html


def test_gc17_no_ad_slot_inside_benefit_table(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    table_start = p.html.index('class="benefit-table"')
    table_end = p.html.index("</section>", table_start)
    assert "ad-slot" not in p.html[table_start:table_end]
