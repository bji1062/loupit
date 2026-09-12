"""T-07.7 인기 조합 렌더 테스트 (GC-6·16·17·20·22·23)."""
from __future__ import annotations

import json
import re
from pathlib import Path

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
    assert 'id="consent-banner"' not in p.html   # 배너 제거(SP-ADS-7, 2026-08-28)
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
    # 계약은 "역순 쌍이 같은 canonical 로 접힌다"이지 오리진 리터럴이 아니다 —
    # SITE_ORIGIN 주입 환경(베타·CI env 가드)에서 리터럴 단정은 오탐이 된다(함정 0079).
    assert pages[0].url == f"{CFG.site_origin}/vs/samsung-elec-sk-hynix"


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


# ── SP-CMP-4 쌍 레이더 (2026-09-12) ─────────────────────────────────────────
#
# `/vs` 3쪽은 **Python 이 굽는다**. 도구(모드 A)가 같은 그림을 JS 로 그리지만, 색인되는 쪽은
# 여기이고 여기가 정본이다 — 둘이 어긋나면 `test_radar.py` 의 골든 픽스처가 잡는다.


def test_combo_page_carries_the_pair_radar(fake_bundle, fake_now, fake_combinations_path):
    pages = _render(fake_bundle, fake_now)
    p = next(p for p in pages if p.path == "vs/samsung-elec-sk-hynix.html")
    assert '<svg class="rdp"' in p.html
    assert 'viewBox="0 34 416 356"' in p.html, "쌍용 viewBox(오른쪽 +16·아래 +26)"
    assert p.html.count('class="rdp-ax"') == 9, "축 9개 — 카테고리 정본 순서"
    assert 'class="rdp-a"' in p.html and 'class="rdp-b"' in p.html
    assert 'class="rdp-avg"' in p.html, "평균 점선이 없으면 '6항목'이 많은지 적은지 말할 수 없다"


def test_combo_radar_needs_no_javascript(fake_bundle, fake_now, fake_combinations_path):
    """조합 페이지의 그림은 좌표가 HTML 에 박혀 있다 — 스크립트가 죽어도 완전하다(NFR24)."""
    pages = _render(fake_bundle, fake_now)
    p = next(p for p in pages if p.path.startswith("vs/"))
    scripts = re.findall(r'<script[^>]*src="([^"]+)"', p.html)
    assert not any("radar" in s for s in scripts), "정적 페이지에 JS 렌더러가 실렸다"


def test_combo_radar_says_zero_as_not_registered(fake_bundle, fake_now, fake_combinations_path):
    """0 은 「등록 없음」이다 — 도구 화면과 **같은 낱말**로 적는다(SP-CMP-3)."""
    pages = _render(fake_bundle, fake_now)
    for p in (x for x in _render(fake_bundle, fake_now) if x.path.startswith("vs/")):
        svg = p.html[p.html.index('<svg class="rdp"'):]
        svg = svg[:svg.index("</svg>")]
        assert "0항목" not in svg
    assert pages


def test_combo_radar_axes_are_keyboard_reachable(fake_bundle, fake_now, fake_combinations_path):
    p = next(p for p in _render(fake_bundle, fake_now) if p.path.startswith("vs/"))
    assert p.html.count('class="rdp-hit" tabindex="0" role="img" aria-label="') == 9


def test_combo_page_keeps_a_slot_for_handwritten_prose(fake_combinations_path):
    """🚨 이 3쪽의 색인 가치를 가르는 것은 **손으로 쓴 산문**뿐이다.

    자동 생성 표·그림은 「검색 결과에 매우 가까운 비슷한 페이지」 판정을 바꾸지 못한다. 지금은
    고유 완결문장 0 + 광고 3자리라 방치가 심사에 최악이고, 못 쓸 것 같으면 폐기(+301)가 낫다.
    이 테스트는 그 자리를 템플릿에서 **지우지 못하게** 한다(SP-CMP-9).
    """
    tpl = (Path(__file__).resolve().parents[1] / "templates" / "combo.html").read_text(encoding="utf-8")
    assert "{# 산문 #}" in tpl


def test_combo_radar_scale_is_the_whole_corpus_not_the_pair(fake_bundle, fake_now, fake_combinations_path):
    """쌍마다 최댓값을 다시 잡으면 회사를 바꿀 때마다 같은 숫자가 다른 크기로 그려진다."""
    from generator import corpus as corpus_mod
    from generator.context import build_context
    from generator.pages.company import CATEGORY_ORDER

    ctx = build_context(fake_bundle, now=fake_now)
    rmax = corpus_mod.build(ctx.companies, CATEGORY_ORDER).rmax
    pages = [p for p in _render(fake_bundle, fake_now) if p.path.startswith("vs/")]
    # 고리·눈금은 `k <= rmax` 인 것만 그려진다 — 픽스처처럼 rmax 가 작으면 하나도 안 나오는 것이
    # **정상**이다. 쌍마다 최댓값을 다시 잡았다면 이 목록이 쌍마다 달라진다.
    expected = [k for k in (2, 4, 6, 8) if k <= rmax]
    for p in pages:
        ticks = [int(t) for t in re.findall(r'<text class="rdp-tick"[^>]*>(\d+)</text>', p.html)]
        assert ticks == expected, f"{p.path}: 눈금이 전 회사 기준이 아니다"
