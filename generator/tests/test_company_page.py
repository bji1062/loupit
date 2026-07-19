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


# ── GC-17: 광고 슬롯 자리(2026-07-19 개정 — SP-ADS-9 계약 정렬) ─────────────
# 정적 HTML은 빈 [data-ad-position] 호스트만 방출하고 라벨·예약·<ins>는 ads.js가
# 런타임 주입한다. 승인 전(placeholder client) 빈 '광고' 박스를 정적으로 그리지
# 않는다(감사 #12 — 구 계약은 회사 98페이지에 빈 점선 박스 2개씩 상시 렌더했다).


def test_gc17_company_page_has_ad_position_hosts(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert 'data-ad-position="content_mid"' in p.html
    assert 'data-ad-position="content_bottom"' in p.html
    assert p.html.count("data-ad-position=") == 2


def test_gc17_static_html_has_no_prerendered_ad_box(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert 'class="ad-slot"' not in p.html   # 광고 박스는 ads.js 렌더 전용
    assert "ad-label" not in p.html          # '광고' 라벨도 렌더 시에만(span+::before 이중 라벨 방지)
    assert "data-ad-client" not in p.html    # client id는 adsConfig.js 단일 소유(A-2)
    assert "data-slot=" not in p.html        # 구 계약 마크업 잔존 금지


def test_gc17_no_ad_host_inside_benefit_table(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    table_start = p.html.index('class="benefit-table"')
    table_end = p.html.index("</section>", table_start)
    assert "data-ad-position" not in p.html[table_start:table_end]


# ── GC-24: 정적 광고·동의 배선(SP-ADS-9 — body page-type·배너·진입 스크립트) ──


def test_gc24_company_static_ads_wiring(fake_bundle, fake_now):
    p = _samsung(fake_bundle, fake_now)
    assert '<body data-page-type="company">' in p.html
    assert 'id="consent-banner"' in p.html
    assert 'data-consent="grant"' in p.html and 'data-consent="deny"' in p.html
    assert '/assets/v2/js/static-ads.js' in p.html
    assert "data-affiliate-host" in p.html


def test_M2_qualitative_benefit_null_desc_no_none_token():
    """M-2 회귀: 정성복지(qual_yn=True)의 qual_desc_ctnt가 NULL이어도 benefit-amount 셀에
    'None' 문자열이 렌더되면 안 된다(과거 아모레퍼시픽 <td>None</td> 누수)."""
    from datetime import datetime

    bundle = {
        "company_types": [],
        "benefit_presets": {},
        "companies": [
            {
                "comp_id": 77, "comp_eng_nm": "qualco", "comp_nm": "정성사",
                "comp_tp_cd": "none", "industry_nm": "기타", "logo_nm": "Q",
                "work_style_val": {}, "aliases": [],
                "benefits": [
                    {
                        "benefit_nm": "보건관리자 상주", "benefit_amt": None,
                        "benefit_ctgr_cd": "health", "badge_cd": "official",
                        "amt_source": "none", "qual_yn": True,
                        # qual_desc_ctnt 없음 → None (버그 조건 재현)
                        "verified_dtm": "2026-01-01", "expires_dtm": "2099-12-31",
                    }
                ],
            }
        ],
    }
    env = make_env()
    ctx = build_context(bundle, now=datetime(2026, 7, 11))
    html = company.render_all(env, ctx)[0].html
    assert ">None<" not in html, "정성복지 qual_desc NULL이 'None'으로 렌더됨(M-2 회귀)"


# ── GC-25: 관련 회사·조합 내부 링크(2026-07-19 고아 페이지 해소) ─────────────
# 배경: 회사 95·조합 3 페이지로 가는 내부 링크가 사이트 전체에 0건이라 sitemap
# 으로만 발견 가능한 고아 상태였다(크롤 우선순위·탐색 가능성·심사 신호 저하).


def _related_hrefs(html: str) -> list[str]:
    """관련 회사 섹션의 href만 추출(다른 구획 링크와 분리)."""
    start = html.find('class="related-companies"')
    if start < 0:
        return []
    end = html.index("</section>", start)
    return re.findall(r'href="([^"]+)"', html[start:end])


def test_gc25_company_page_links_to_related_companies(fake_bundle, fake_now):
    """모든 회사 페이지가 다른 회사 상세로 가는 링크를 최소 1개 갖는다."""
    for path, p in _render(fake_bundle, fake_now).items():
        hrefs = _related_hrefs(p.html)
        assert hrefs, f"{path}: 관련 회사 링크 0건(고아)"
        assert all(h.startswith("/company/") for h in hrefs), f"{path}: {hrefs}"
        self_slug = "/" + path[: -len(".html")]
        assert self_slug not in hrefs, f"{path}: 자기 자신 링크"
        assert len(hrefs) == len(set(hrefs)), f"{path}: 중복 링크 {hrefs}"


def test_gc25_same_industry_company_is_preferred(fake_bundle, fake_now):
    """같은 업종(반도체) 회사가 관련 목록 선두에 온다 — 관련성 우선."""
    hrefs = _related_hrefs(_samsung(fake_bundle, fake_now).html)
    assert hrefs[0] == "/company/sk-hynix"


def test_gc25_isolated_industry_still_gets_links(fake_bundle, fake_now):
    """업종 단독사(네이버=IT)도 가나다순 인접 폴백으로 링크를 받는다.
    실데이터 95개 중 48개가 업종 단독사라 폴백 없이는 절반이 고아로 남는다."""
    hrefs = _related_hrefs(_naver(fake_bundle, fake_now).html)
    assert len(hrefs) >= 1
    assert "/company/naver" not in hrefs


def test_gc25_combo_links_rendered_when_pairs_given(fake_bundle, fake_now):
    """이 회사가 등장하는 조합 페이지로 링크한다(조합 목록 주입 시)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    pairs = [("samsung_elec", "sk_hynix")]
    pages = {p.path: p for p in company.render_all(env, ctx, combo_pairs=pairs)}
    html = pages["company/samsung-elec.html"].html
    assert 'class="related-combos"' in html
    assert 'href="/vs/samsung-elec-sk-hynix"' in html
    # 조합에 없는 회사는 조합 구획 자체를 방출하지 않는다
    assert 'class="related-combos"' not in pages["company/naver.html"].html


def test_gc25_no_combo_section_without_pairs(fake_bundle, fake_now):
    """조합 목록 미주입(기본) → 조합 구획 없음. 관련 회사 링크는 그대로."""
    p = _samsung(fake_bundle, fake_now)
    assert 'class="related-combos"' not in p.html
    assert _related_hrefs(p.html)


def test_gc25_industry_tokens_bridge_free_text_variants():
    """업종이 자유 텍스트라 '전자/반도체'와 '반도체'는 완전일치로는 남남이다.
    구분자 토큰이 겹치면 같은 업종군으로 본다(실데이터 삼성전자↔SK하이닉스,
    네이버↔카카오가 이 경로로 연결된다)."""
    tok = company._industry_tokens
    assert tok("전자/반도체") & tok("반도체")
    assert tok("IT/포털") & tok("IT/플랫폼")
    assert not tok("게임") & tok("바이오")
    assert tok(None) == set() and tok("") == set()
    assert tok(" 전자 / 반도체 ") == {"전자", "반도체"}


# ── GC-26: 링크 그래프 도달성(2026-07-19 검수 반증 반영) ────────────────────
# 반증 내용: 업종 매칭이 상한을 채우면 폴백이 실행되지 않아 큰 업종군이 폐쇄
# 싱크가 됐다(실데이터 게임 8사 — 그 안으로 들어온 크롤러는 나머지 87개를 못 봄).
# 당시 연결이 유지된 유일한 이유는 ncsoft의 수동 메타 '게임/IT' 한 줄이었다.
# 이제 가나다순 앞·뒤 이웃을 선예약해 전 회사가 양방향 링으로 이어진다.


def _reach_all(bundle, now):
    """관련 회사 링크만으로 만든 방향 그래프에서 시작점별 도달 회사 수."""
    from collections import deque

    ctx = build_context(bundle, now=now)
    rev = {v: k for k, v in ctx.slugs.items()}
    adj = {
        c["comp_eng_nm"]: [rev[h.rsplit("/", 1)[1]] for _, h in company._related_companies(c, ctx)]
        for c in ctx.companies
    }

    def reach(start):
        seen, q = {start}, deque([start])
        while q:
            for nxt in adj[q.popleft()]:
                if nxt not in seen:
                    seen.add(nxt)
                    q.append(nxt)
        return seen

    return adj, {e: reach(e) for e in adj}


def _bundle_with_saturated_industry(n_same=9, n_other=4):
    """한 업종에 상한(6) 초과 회사가 몰린 번들 — 폐쇄 싱크 재현용."""
    companies = []
    for i in range(n_same):
        companies.append(_mk_company(f"game{i}", f"가게임{i:02d}", "게임"))
    for i in range(n_other):
        companies.append(_mk_company(f"bio{i}", f"하바이오{i:02d}", "바이오"))
    return {"company_types": [], "benefit_presets": {}, "companies": companies}


def _mk_company(eng, nm, industry):
    return {
        "comp_id": abs(hash(eng)) % 100000,
        "comp_eng_nm": eng,
        "comp_nm": nm,
        "comp_tp_cd": "large",
        "industry_nm": industry,
        "logo_nm": nm[0],
        "work_style_val": {},
        "aliases": [],
        "benefits": [
            {
                "benefit_nm": "복지",
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


def test_gc26_saturated_industry_does_not_create_closed_sink(fake_now):
    """업종 포화 클러스터에서 시작해도 전 회사에 도달한다(체인 슬롯 선예약)."""
    bundle = _bundle_with_saturated_industry()
    adj, reach = _reach_all(bundle, fake_now)
    total = len(adj)
    unreached = {e: sorted(set(adj) - r) for e, r in reach.items() if len(r) < total}
    assert not unreached, f"폐쇄 싱크 발생: {unreached}"


def test_gc26_every_company_emits_both_alphabetical_neighbours(fake_now):
    """전 회사가 가나다순 앞·뒤 이웃을 항상 방출 → 인바운드 ≥2(단일 페이지 제거 내성)."""
    bundle = _bundle_with_saturated_industry()
    adj, _ = _reach_all(bundle, fake_now)
    indeg = {e: 0 for e in adj}
    for targets in adj.values():
        for t in targets:
            indeg[t] += 1
    assert min(indeg.values()) >= 2, f"인바운드 1 이하 존재: {indeg}"


def test_gc26_related_selection_is_deterministic(fake_bundle, fake_now):
    """같은 번들 → 빌드마다 동일 링크(동명 회사 동점도 comp_eng_nm으로 안정 정렬)."""
    ctx = build_context(fake_bundle, now=fake_now)
    first = [company._related_companies(c, ctx) for c in ctx.companies]
    second = [company._related_companies(c, ctx) for c in ctx.companies]
    assert first == second
