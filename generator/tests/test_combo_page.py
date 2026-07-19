"""T-07.7 인기 조합 렌더 테스트 (GC-6·16·17·20·22·23)."""
from __future__ import annotations

import json
import re

from generator.config import CFG
from generator.context import build_context
from generator.pages import combo
from generator.render import make_env
from generator.tests.fixtures import FAKE_COMBINATIONS_RAW


def _render(fake_bundle, fake_now):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    return combo.render_all(env, ctx, CFG)


# ── GC-6: 단일 h1 = "A vs B" ─────────────────────────────────────────────


def test_gc6_combo_page_has_exactly_one_h1_as_a_vs_b(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    p = next(p for p in pages if p.path == "vs/samsung-elec-sk-hynix.html")
    h1s = re.findall(r"<h1>(.*?)</h1>", p.html)
    assert len(h1s) == 1
    assert h1s[0] == "삼성전자 vs SK하이닉스"


# ── GC-16: 양사 프리필 CTA ───────────────────────────────────────────────


def test_gc16_combo_cta_href_has_both_eng_params(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    p = next(p for p in pages if p.path == "vs/samsung-elec-sk-hynix.html")
    # HTML 속성 내 "&"는 autoescape가 "&amp;"로 이스케이프한다(NFR21, 표준 HTML 규약).
    # 브라우저·URL 파서는 &amp;를 &로 해석하므로 쿼리 파라미터 의미는 동일하다.
    assert f'href="{CFG.compare_path}?a=samsung_elec&amp;b=sk_hynix"' in p.html
    assert "비교 툴에서 열기" in p.html


def test_gc16_combo_cta_has_no_prefill_or_slot_param(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    for p in pages:
        cta_hrefs = re.findall(r'class="cta"><a href="([^"]+)"', p.html)
        assert cta_hrefs
        for href in cta_hrefs:
            assert "prefill=" not in href
            assert "slot=" not in href


# ── GC-17: 광고 슬롯(company와 동일 규약 — SP-ADS-9 빈 호스트, 2026-07-19 개정) ──


def test_gc17_combo_page_has_ad_position_hosts(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    p = pages[0]
    assert 'data-ad-position="content_mid"' in p.html
    assert 'data-ad-position="content_bottom"' in p.html
    assert p.html.count("data-ad-position=") == 2
    assert 'class="ad-slot"' not in p.html   # 박스·라벨은 ads.js 렌더 전용(감사 #12)
    assert "ad-label" not in p.html


def test_gc17_no_ad_host_inside_combo_benefit_summary(fake_bundle, fake_now, fake_combinations_path):
    p = _render(fake_bundle, fake_now)[0]
    start = p.html.index('class="combo-benefits"')
    end = p.html.index("</section>", start)
    assert "data-ad-position" not in p.html[start:end]


def test_gc24_combo_static_ads_wiring(fake_bundle, fake_now, fake_combinations_path):
    p = _render(fake_bundle, fake_now)[0]
    assert '<body data-page-type="combo">' in p.html
    assert 'id="consent-banner"' in p.html
    assert '/assets/v2/js/static-ads.js' in p.html
    assert "data-affiliate-host" in p.html


# ── GC-20: 내부 링크 404 없음(관련 링크는 실제 생성 페이지로만) ────────────


def test_gc20_related_company_links_target_generated_paths(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    generated_company_paths = {"/company/samsung-elec", "/company/sk-hynix", "/company/naver"}
    for p in pages:
        for href in re.findall(r'href="(/company/[^"]+)"', p.html):
            assert href in generated_company_paths


def test_gc20_related_combo_links_target_generated_combo_paths(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    generated_combo_paths = {f"/vs/{p.path[len('vs/'):-len('.html')]}" for p in pages}
    for p in pages:
        for href in re.findall(r'href="(/vs/[^"]+)"', p.html):
            assert href in generated_combo_paths


# ── GC-22: 조합 canonical 정규화 — (A,B)·(B,A) 동일 canonical, 파일 1개 ────


def test_gc22_reversed_pair_produces_same_canonical_and_single_file(fake_bundle, fake_now, tmp_path, monkeypatch):
    reversed_combos = {"combinations": [{"a": "sk_hynix", "b": "samsung_elec", "note": "역순"}]}
    combo_path = tmp_path / "reversed_combos.json"
    combo_path.write_text(json.dumps(reversed_combos, ensure_ascii=False), encoding="utf-8")
    monkeypatch.setattr(combo, "COMBINATIONS_PATH", combo_path)

    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = combo.render_all(env, ctx, CFG)
    assert len(pages) == 1
    assert pages[0].path == "vs/samsung-elec-sk-hynix.html"
    assert pages[0].url == "https://jobcho.wiki/vs/samsung-elec-sk-hynix"


# ── GC-23: 무효 조합 스킵(빌드 성공, 경고 로그) ─────────────────────────────


def test_gc23_invalid_combo_with_unregistered_company_is_skipped(fake_bundle, fake_now, fake_combinations_path, caplog):
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    with caplog.at_level("WARNING"):
        pages = combo.render_all(env, ctx, CFG)
    # FAKE_COMBINATIONS_RAW: 3항목 중 kakao 미등록 1건 스킵 → 유효 2건만 생성
    assert len(pages) == 2
    assert any("kakao" in r.message for r in caplog.records)


def test_gc23_self_pair_is_skipped(fake_bundle, fake_now, tmp_path, monkeypatch):
    self_pair = {"combinations": [{"a": "samsung_elec", "b": "samsung_elec", "note": "동일 회사"}]}
    combo_path = tmp_path / "self_pair.json"
    combo_path.write_text(json.dumps(self_pair, ensure_ascii=False), encoding="utf-8")
    monkeypatch.setattr(combo, "COMBINATIONS_PATH", combo_path)

    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pages = combo.render_all(env, ctx, CFG)
    assert len(pages) == 0
