"""회사 상세 '연도별 추이' 섹션 렌더 — MET-10 (SPEC/17 SP-MET-9·10, 2026-08-28).

`test_employ.py` 가 **수치**(집계·단위·전년 대비)를, `test_charts.py` 가 **좌표**(축·결측·부호)를
본다. 여기서 보는 것은 그 둘이 만나 실제로 페이지에 박힌 결과다 — 두 모듈이 각자 맞아도 배선이
어긋나면 화면은 조용히 틀린다.

이 스위트가 못박는 계약:
  1. 섹션 위치는 실적 표 **뒤**, CTA **앞**. 표는 지우지 않는다(정확한 값을 읽는 자리다).
  2. 카드는 **항상 6장, 순서 고정**. 값이 없으면 사라지는 게 아니라 없다고 **말한다**.
  3. 금융 세트는 매출 자리에 자산총계(SP-MET-2) — 그 판단은 `finance.metric_columns` 하나가 내린다.
  4. 그래프는 **두 벌 다** HTML 에 있고 전환은 라디오 + CSS 다. JS 는 선택 기억만 한다(NFR24).
  5. 결측은 잇지 않는다 — 선은 끊기고 막대는 자리를 비운다(0 으로 그리면 없는 사실을 그리는 것이다).
  6. 성별은 이 페이지에 없다(사용자 결정 2026-08-28). SVG 프레젠테이션 속성에 `var(--` 도 없다.
"""
from __future__ import annotations

import copy
import json
import re

from generator import build as build_module
from generator.context import build_context
from generator.finance import metric_columns
from generator.pages import company
from generator.render import make_env
from generator.tests.fixtures import (
    FAKE_BUNDLE,
    FAKE_EMPLOY,
    FAKE_FINANCE,
    make_sibling_employ,
    make_sibling_fixture,
)

NOTICE = "공시 수치를 그대로 옮긴 것이며 평가가 아닙니다"
EMPLOY_CARD_NAMES = ["평균연봉", "평균근속", "직원수"]
# SP-MET-1 검증값(삼성전자 연결 2025). 구현이 이 값을 못 내면 틀린 것이다.
SAMSUNG_2025 = {"salary": "15,706", "tenure": "13.7", "head": "128,881"}
_TAG_RE = re.compile(r"<[^>]+>")


def _pages(bundle, finance, employ, now):
    env = make_env()
    ctx = build_context(bundle, now=now, finance=finance, employ=employ)
    return {p.path: p.html for p in company.render_all(env, ctx)}


def _section(html: str) -> str:
    start = html.index('<section class="metrics"')
    return html[start: html.index("</section>", start)]


def _cards(section: str) -> list[tuple[str, str]]:
    """(data-metric, 카드 HTML) — 문서 순서 그대로."""
    parts = re.split(r'(?=<div class="metric-card" data-metric=")', section)
    return [(re.search(r'data-metric="([^"]+)"', p).group(1), p) for p in parts if p.startswith('<div class="metric-card"')]


def _card(section: str, key: str) -> str:
    return dict(_cards(section))[key]


def _chart(card: str, shape: str) -> str:
    return re.search(rf'<div class="mchart mchart-{shape}">(<svg.*?</svg>)</div>', card, re.S).group(1)


# ── 위치·구조 ────────────────────────────────────────────────────────────────

def test_MET10_section_sits_after_the_finance_table_and_before_the_cta(fake_bundle, fake_finance, fake_employ, fake_now):
    """표를 **대체하지 않는다.** 그래프는 흐름을 보는 자리고 표는 값을 정확히 읽는 자리다."""
    html = _pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"]
    assert html.index('<section class="finance"') < html.index('<section class="metrics"') < html.index('class="cta"')
    assert '<table class="benefit-table finance-table">' in html, "실적 표가 사라졌다"
    assert "<h2>연도별 추이</h2>" in html


def test_MET10_six_cards_in_a_fixed_order_on_every_page(fake_bundle, fake_finance, fake_employ, fake_now):
    """회사마다 카드 수가 달라지면 세 회사를 나란히 둔 화면이 매번 다른 모양이 된다."""
    pages = _pages(fake_bundle, fake_finance, fake_employ, fake_now)
    for path, acct_set in (("company/samsung-elec.html", "general"), ("company/naver.html", "financial")):
        keys = [k for k, _ in _cards(_section(pages[path]))]
        assert keys == ["salary", "tenure", "head", *[f for f, _ in metric_columns(acct_set)]], path


def test_MET10_two_chart_sets_and_one_radio_pair_with_bar_as_the_default(fake_bundle, fake_finance, fake_employ, fake_now):
    """막대·꺾은선을 **둘 다** 굽고 CSS 가 고른다(SP-MET-10). 기본은 막대(사용자 결정 2026-08-28).

    기본이 막대인 이유는 축이 0 에 고정돼 길이가 거짓말을 못 하기 때문이다 — 처음 온 사람이 보는
    화면이라 사실상의 결정이고, 꺾은선은 라디오로 언제든 고를 수 있다.
    """
    sec = _section(_pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"])
    assert sec.count('type="radio"') == 2 and sec.count('name="metric-shape"') == 2
    assert 'id="metric-shape-bar" value="bar" checked' in sec
    assert 'id="metric-shape-line" value="line" aria-label' in sec, "꺾은선이 기본이 되면 안 된다"
    for key, card in _cards(sec):
        assert card.count('<div class="mchart mchart-bar">') == 1, key
        assert card.count('<div class="mchart mchart-line">') == 1, key
        assert card.count("<svg") == 2, key
    # 라디오·라벨·카드는 **형제**여야 `:checked ~ .metric-cards` 가 닿는다.
    assert re.search(r'id="metric-shape-line"[^>]*>\s*<label[^>]*>꺾은선</label>\s*<div class="metric-cards">', sec)


def test_MET10_basis_badge_source_and_notice_are_present(fake_bundle, fake_finance, fake_employ, fake_now):
    sec = _section(_pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"])
    assert '<span class="badge finance-basis">연결 기준</span>' in sec
    assert "직원 현황은 법인 1벌이라 연결·별도 구분이 없습니다" in sec, "근속에도 연결 기준이 있는 줄 안다"
    assert '출처: 금융감독원 전자공시(DART) 사업보고서 · 접수번호 <a href="https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260318000001"' in sec
    assert f'<p class="metrics-notice">{NOTICE}</p>' in sec


def test_MET10_shape_script_is_loaded_only_where_the_section_exists(fake_bundle, fake_finance, fake_employ, fake_now):
    pages = _pages(fake_bundle, fake_finance, fake_employ, fake_now)
    assert "/assets/v2/js/metricshape.js" in pages["company/samsung-elec.html"]
    assert "metricshape" not in pages["company/sk-hynix.html"], "그래프가 없는 페이지에 스크립트를 싣지 않는다"


# ── 수치: 실측 검증값 ────────────────────────────────────────────────────────

def test_MET1_headline_numbers_match_the_measured_reference(fake_bundle, fake_finance, fake_employ, fake_now):
    """삼성전자 2025 = 15,706만원 · 13.7년 · 128,881명(SP-MET-1). 단위나 반올림이 갈리면 여기서 걸린다."""
    sec = _section(_pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"])
    for key, expected in SAMSUNG_2025.items():
        assert f"<strong>{expected}</strong>" in _card(sec, key), key
    for name, unit in zip(EMPLOY_CARD_NAMES, ("만원", "년", "명")):
        assert f'{name}<span class="metric-unit">{unit}</span>' in sec, name
    # 큰 숫자와 그래프 라벨은 **같은 포맷 함수**를 쓴다 — 카드는 15,706 인데 그래프는 15706.0 이면 갈린 것이다.
    assert "15706.0" not in sec and "13.70" not in sec


def test_MET10_money_unit_is_stated_once_and_shared_by_the_three_amount_cards(fake_bundle, fake_finance, fake_employ, fake_now):
    """한 회사 안에서 조와 억을 섞으면 세 그래프를 나란히 읽을 수 없다(SP-MET-10)."""
    pages = _pages(fake_bundle, fake_finance, fake_employ, fake_now)
    sam = _section(pages["company/samsung-elec.html"])
    assert "금액 단위 조원" in sam
    for key in ("revenue", "op_income", "net_income"):
        assert '<span class="metric-unit">조원</span>' in _card(sam, key), key
    nav = _section(pages["company/naver.html"])
    assert "금액 단위 억원" in nav, "카카오페이형(자산 5.3조 · 영업이익 503억)은 억원이라야 뭉개지지 않는다"


def test_MET2_financial_page_swaps_revenue_for_total_assets(fake_bundle, fake_finance, fake_employ, fake_now):
    """금융 세트는 매출 자리에 자산총계(SP-MET-2). 표·카드가 **같은 함수**를 보므로 갈라질 수 없다."""
    html = _pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/naver.html"]
    sec = _section(html)
    assert 'data-metric="assets"' in sec and "자산총계" in sec
    assert 'data-metric="revenue"' not in sec
    assert "<strong>330,000</strong>" in _card(sec, "assets")
    assert "<strong>9,000</strong>" in _card(sec, "op_income"), "금융 영업이익은 계정 누락이었지 없던 게 아니다"
    # 같은 페이지의 표도 같은 3종이다 — 세트 판정이 두 곳이면 언젠가 한쪽만 고쳐진다.
    table = html[html.index('<section class="finance"'): html.index('<section class="metrics"')]
    assert '<th scope="col">자산총계</th>' in table
    assert '<th scope="col">매출</th>' not in table


def test_MET10_empty_card_says_so_instead_of_disappearing(fake_bundle, fake_employ, fake_now):
    """직원만 실린 빌드(수집 순서상 실제로 존재한다) — 금액 3종은 카드를 남기고 없다고 말한다."""
    sec = _section(_pages(fake_bundle, None, fake_employ, fake_now)["company/samsung-elec.html"])
    assert len(_cards(sec)) == 6
    for key, name in (("revenue", "매출"), ("op_income", "영업이익"), ("net_income", "순이익")):
        card = _card(sec, key)
        assert f'<p class="metric-empty">{name} 공시 값이 없습니다</p>' in card, key
        assert "<svg" not in card, "값이 없는 카드에 빈 그래프를 그리지 않는다"
    assert "<strong>15,706</strong>" in _card(sec, "salary")


# ── 그림: 결측·색·id ─────────────────────────────────────────────────────────

def test_MET9_missing_years_break_the_line_and_leave_the_bar_empty(fake_bundle, fake_finance, fake_employ, fake_now):
    """삼성전자 픽스처는 직원 2023 이 비어 있다(연도축에는 있다). 0 으로 이으면 없는 사실을 그리는 것이다."""
    sec = _section(_pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"])
    salary = _card(sec, "salary")
    assert len(re.findall(r'class="lp"', _chart(salary, "line"))) == 2, "결측에서 선이 끊기지 않았다"
    assert ">—<" in _chart(salary, "bar"), "막대는 자리를 비우되 비었다고 말한다"
    # 금액 카드는 반대 모양의 결측이다 — 재무가 2021 부터라 앞이 비어 있다(선분은 하나).
    assert len(re.findall(r'class="lp"', _chart(_card(sec, "revenue"), "line"))) == 1
    assert _chart(_card(sec, "revenue"), "bar").count(">—<") == 6, "2015~2020 여섯 해가 비어 있다"


def test_MET9_svg_never_carries_css_variables_in_presentation_attributes(fake_bundle, fake_finance, fake_employ, fake_now):
    """`fill="var(--pos)"` 는 브라우저에 따라 **조용히 무시**되어 검은 도형만 남는다(실측).

    색은 클래스로만 준다 — 그 클래스 목록도 `charts.py` 가 정한 것뿐이어야 CSS 가 전부 입힌다.
    """
    allowed = {"ax", "gl", "yt", "yr", "yr last", "lp", "ar-pos", "ar-neg", "bar pos", "bar neg",
               "hc", "hv"}  # 호버 칸·즉시 라벨(2026-09-04)
    for html in _pages(fake_bundle, fake_finance, fake_employ, fake_now).values():
        if 'class="metrics"' not in html:
            continue
        for svg in re.findall(r"<svg.*?</svg>", _section(html), re.S):
            assert "var(--" not in svg
            # 유일 허용 예외: 호버 툴팁 히트 칸의 fill="transparent"(2026-09-01, SP-MET-9) —
            # 색이 아니라 포인터 수신 장치라 이 불변식(테마 색은 CSS 소유)의 취지를 해치지 않는다.
            stripped = svg.replace('fill="transparent"', "")
            assert not re.search(r'\b(fill|stroke|opacity)=', stripped), "프레젠테이션 속성은 CSS 소유다"
            assert set(re.findall(r'class="([^"]+)"', svg)) <= allowed


def test_MET9_each_card_gets_its_own_clip_path_id(fake_bundle, fake_finance, fake_employ, fake_now):
    """카드 6장이 한 페이지에 있다 — id 가 겹치면 **다른 카드의 클립**이 걸려 면적이 통째로 사라진다."""
    for path, html in _pages(fake_bundle, fake_finance, fake_employ, fake_now).items():
        ids = re.findall(r'<clipPath id="([^"]+)"', html)
        assert len(ids) == len(set(ids)), path
        assert all(f'url(#{i})' in html for i in ids), path


def test_MET8_gender_never_reaches_the_page(fake_bundle, fake_finance, fake_employ, fake_now):
    """성별은 집계 가중치로만 쓰고 화면·표·툴팁 어디에도 남기지 않는다(사용자 결정 2026-08-28)."""
    for path, html in _pages(fake_bundle, fake_finance, fake_employ, fake_now).items():
        text = _TAG_RE.sub(" ", html)
        for word in ("성별", "남성", "여성", "남녀"):
            assert word not in text, (path, word)


def test_MET10_section_says_only_facts(fake_bundle, fake_finance, fake_employ, fake_now):
    """DEC-B 금칙어를 이 섹션 안에서도 직접 센다 — 전역 가드(FN-6)가 픽스처를 바꾸며 헐거워질 수 있다."""
    for path, html in _pages(fake_bundle, fake_finance, fake_employ, fake_now).items():
        if 'class="metrics"' not in html:
            continue
        text = _TAG_RE.sub(" ", _section(html)).replace(NOTICE, " ")
        for word in ("성장성", "등급", "전망", "우수", "양호"):
            assert word not in text, (path, word)


# ── 경계: 없음·형제 ──────────────────────────────────────────────────────────

def test_MET10_no_figures_no_section(fake_bundle, fake_finance, fake_employ, fake_now):
    pages = _pages(fake_bundle, fake_finance, fake_employ, fake_now)
    assert 'class="metrics"' not in pages["company/sk-hynix.html"], "재무도 직원도 없는 회사"
    for path, html in _pages(copy.deepcopy(fake_bundle), None, None, fake_now).items():
        assert 'class="metrics"' not in html, path
        assert "metricshape" not in html, path


def test_MET10_siblings_sharing_one_corporation_get_identical_cards(fake_now):
    """CJ ENM 두 부문은 **한 법인**이라 같은 수치를 받는다(사용자 결정 2026-08-28: 부문별로 나누지 않는다).

    DART 의 `fo_bbm` 부문명과 우리 페이지 구분이 1:1 이라는 보장이 없어, 나누는 순간 근거 없는
    매핑을 우리가 만들게 된다.
    """
    bundle, finance = make_sibling_fixture()
    pages = _pages(bundle, finance, make_sibling_employ(), fake_now)
    ent, com = _section(pages["company/cj-enm-ent.html"]), _section(pages["company/cj-enm-com.html"])
    assert [(k, _TAG_RE.sub(" ", c)) for k, c in _cards(ent)] == [(k, _TAG_RE.sub(" ", c)) for k, c in _cards(com)]
    assert "<strong>9,850</strong>" in _card(ent, "salary")
    assert "적자 전환" in _card(ent, "net_income"), "부호가 뒤집히면 비율이 아니라 사건이다"


# ── CLI: --employ-json ──────────────────────────────────────────────────────

def test_MET11_build_cli_renders_metrics_from_json_dumps(tmp_path, fake_combinations_path):
    """JSON 왕복은 comp_id 와 **연도 둘 다** 문자열로 떨어뜨린다 — 되돌리지 않으면 전년 대비가 사라진다."""
    b, f, e = tmp_path / "b.json", tmp_path / "f.json", tmp_path / "e.json"
    b.write_text(json.dumps(FAKE_BUNDLE, ensure_ascii=False), encoding="utf-8")
    f.write_text(json.dumps(FAKE_FINANCE, ensure_ascii=False), encoding="utf-8")
    e.write_text(json.dumps(FAKE_EMPLOY, ensure_ascii=False), encoding="utf-8")
    out = tmp_path / "dist"
    rc = build_module.main(["--bundle-json", str(b), "--finance-json", str(f),
                            "--employ-json", str(e), "--out", str(out), "--no-gzip"])
    assert rc == 0
    html = (out / "company" / "samsung-elec.html").read_text(encoding="utf-8")
    sec = _section(html)
    assert "<strong>15,706</strong>" in sec and "<strong>128,881</strong>" in sec
    assert "전년 대비" in sec, "연도 키가 문자열로 남으면 전년 대비가 조용히 사라진다"


def test_MET11_employ_json_needs_the_bundle_json_and_says_so(tmp_path, capsys):
    rc = build_module.main(["--employ-json", str(tmp_path / "e.json"), "--out", str(tmp_path / "d")])
    assert rc == 2
    assert "--employ-json" in capsys.readouterr().err


def test_MET11_build_without_employ_json_says_so_and_renders_the_rest(tmp_path, fake_combinations_path, capsys):
    """미적재를 조용히 넘기지 않는다 — 카드가 통째로 빠지는 것은 에러를 남기지 않는 소멸이다."""
    b, f = tmp_path / "b.json", tmp_path / "f.json"
    b.write_text(json.dumps(FAKE_BUNDLE, ensure_ascii=False), encoding="utf-8")
    f.write_text(json.dumps(FAKE_FINANCE, ensure_ascii=False), encoding="utf-8")
    out = tmp_path / "dist"
    assert build_module.main(["--bundle-json", str(b), "--finance-json", str(f),
                              "--out", str(out), "--no-gzip"]) == 0
    err = capsys.readouterr().err
    assert "employ 미주입" in err
    html = (out / "company" / "samsung-elec.html").read_text(encoding="utf-8")
    assert '<section class="metrics"' in html, "재무만 있어도 금액 카드는 그린다"
    assert "평균연봉 공시 값이 없습니다" in html


def test_MET11_build_log_counts_missing_cells_instead_of_hiding_them(tmp_path, fake_combinations_path, capsys):
    b, f, e = tmp_path / "b.json", tmp_path / "f.json", tmp_path / "e.json"
    b.write_text(json.dumps(FAKE_BUNDLE, ensure_ascii=False), encoding="utf-8")
    f.write_text(json.dumps(FAKE_FINANCE, ensure_ascii=False), encoding="utf-8")
    e.write_text(json.dumps(FAKE_EMPLOY, ensure_ascii=False), encoding="utf-8")
    build_module.main(["--bundle-json", str(b), "--finance-json", str(f), "--employ-json", str(e),
                       "--out", str(tmp_path / "dist"), "--no-gzip"])
    err = capsys.readouterr().err
    assert "employ 회사 2 · 회사×연도 12" in err, "결측은 세어서 찍는다(조용한 결측 금지)"


def test_MET10_basis_badge_does_not_touch_the_sentence_after_it(fake_bundle, fake_finance, fake_employ, fake_now):
    """`.badge` 는 `display:inline-flex` 에 margin 이 없어, 마크업에 공백이 없으면 알약 테두리에
    본문이 그대로 달라붙는다 — 「연결 기준금액 단위 조원」. 재무가 실린 **모든** 회사 페이지에 나온다.
    부분 문자열 검사로는 안 잡히므로 앞의 한 칸까지 포함해 못박는다.
    """
    sec = _section(_pages(fake_bundle, fake_finance, fake_employ, fake_now)["company/samsung-elec.html"])
    assert '<span class="badge finance-basis">연결 기준</span> 금액 단위 조원' in sec
    assert "기준금액" not in sec
