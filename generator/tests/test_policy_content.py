"""T-09.1~09.6 정책 콘텐츠 단위 테스트 (SP-POL-2~6, PC-1·2·6·11·13).

`generator.content.policy`를 직접 import해 검증한다 — 무 DB·무 렌더
파이프라인(SP-GEN 미착수, M5). 생성물 검증(PC-3·4·5·7·8·9·10·12)은
`test_policy_pages.py`/`test_footer_links.py`(SP-GEN 렌더 착지 후 M5)로
연기한다 — 여기서는 콘텐츠 소스만 검증한다(가짜 green 금지).

PC-13(Tier-0, NFR21)은 실제 SP-GEN `templates/policy.html`이 아직 없으므로,
SP-GEN이 반드시 사용할 메커니즘(Jinja2 `autoescape=True`, `paragraphs` 원문
삽입·`|safe` 미부착)을 최소 재현해 이스케이프 안전을 지금 시점에 검증한다.
SP-GEN 착지 시 실제 `policy.html` 렌더로 교체해도 이 계약(비-safe 삽입)은
동일해야 한다.
"""
from __future__ import annotations

import re

import jinja2
import pytest

from generator.config import GenConfig
from generator.content.policy import (
    DRAFT_BANNER,
    POLICY_FOOTER_LINKS,
    POLICY_KEYS,
    REQUIRED_ITEMS,
    PolicyDoc,
    PolicySection,
    build_policy_docs,
)

CFG = GenConfig()

# SP-POL-1 표(라우트·dist 파일 정본) — Nginx `= /privacy` … 1:1 정합(SP-ARCH-2)
EXPECTED_ROUTE_FILE = {
    "privacy": ("/privacy", "privacy.html"),
    "terms": ("/terms", "terms.html"),
    "disclaimer": ("/disclaimer", "disclaimer.html"),
    "ads": ("/ads", "ads.html"),
}

ANCHOR_RE = re.compile(r"^[a-z0-9-]+$")


# ── PC-1: 4종 존재·순서·라우트/파일 (FR-80, SP-POL-1·2.2) ──────────────────


def test_pc1_build_policy_docs_returns_exactly_four_in_order():
    docs = build_policy_docs(CFG)
    assert [d.key for d in docs] == list(POLICY_KEYS)
    assert POLICY_KEYS == ("privacy", "terms", "disclaimer", "ads")


def test_pc1_key_set_matches_policy_keys():
    docs = build_policy_docs(CFG)
    assert {d.key for d in docs} == {"privacy", "terms", "disclaimer", "ads"}


def test_pc1_route_and_filename_match_sp_pol_1_table():
    docs = build_policy_docs(CFG)
    for d in docs:
        expected_route, expected_filename = EXPECTED_ROUTE_FILE[d.key]
        assert d.route == expected_route
        assert d.filename == expected_filename


def test_pc1_all_docs_are_policy_doc_instances():
    for d in build_policy_docs(CFG):
        assert isinstance(d, PolicyDoc)
        for s in d.sections:
            assert isinstance(s, PolicySection)


# ── PC-2: 필수 섹션 누락 0·앵커 유일·앵커 정규식 (FR-81~84) ────────────────


@pytest.mark.parametrize("key", list(POLICY_KEYS))
def test_pc2_required_items_covered(key):
    docs = {d.key: d for d in build_policy_docs(CFG)}
    doc = docs[key]
    req_ids = {s.req_id for s in doc.sections}
    assert req_ids >= REQUIRED_ITEMS[key], (
        f"{key}: 누락된 필수 항목 {REQUIRED_ITEMS[key] - req_ids}"
    )


@pytest.mark.parametrize("key", list(POLICY_KEYS))
def test_pc2_anchors_unique_and_match_pattern(key):
    docs = {d.key: d for d in build_policy_docs(CFG)}
    doc = docs[key]
    anchors = [s.anchor for s in doc.sections]
    assert len(anchors) == len(set(anchors)), f"{key}: 앵커 중복 {anchors}"
    for a in anchors:
        assert ANCHOR_RE.match(a), f"{key}: 앵커 패턴 위반 {a!r}"


def test_pc2_privacy_p1_p2_align_with_no_login_no_server_write():
    """P1·P2 문안이 실구현(서버 사용자 저장 0·localStorage 한정, INV-4)과 정합."""
    doc = next(d for d in build_policy_docs(CFG) if d.key == "privacy")
    p1 = next(s for s in doc.sections if s.req_id == "P1")
    p2 = next(s for s in doc.sections if s.req_id == "P2")
    assert any("로그인" in p or "회원가입" in p for p in p1.paragraphs)
    assert any("서버" in p and ("수집" in p or "저장" in p) for p in p1.paragraphs)
    assert any("localStorage" in p for p in p2.paragraphs)
    assert any("서버" in p for p in p2.paragraphs)


# ── PC-6: 면책조항 D-4 밴드 문안 정합 (FR-83·DEC-2, INV-5) ─────────────────


def test_pc6_disclaimer_d4_band_wording_matches_sp_calc_coefficients():
    """D-4 문안이 SP-CALC(web/assets/js/calc.js) BAND_BASE·BAND_EXPIRE와
    문자열·의미 모두 일치(stated=0.05→"±5%", estimated=0.20→"±20%",
    만료 가산 0.15→"+15%")하고, "금액 신뢰도" 기준을 명시하며, "출처 배지
    기준" 서술은 부재해야 한다(디커플링, PC-6)."""
    doc = next(d for d in build_policy_docs(CFG) if d.key == "disclaimer")
    d4 = next(s for s in doc.sections if s.req_id == "D-4")
    text = " ".join(d4.paragraphs)

    # SP-CALC 정본 계수 (web/assets/js/calc.js BAND_BASE·BAND_EXPIRE) — 정합 재확인
    band_base_stated = 0.05
    band_base_estimated = 0.20
    band_expire = 0.15
    assert f"±{int(band_base_stated * 100)}%" in text  # "±5%"
    assert f"±{int(band_base_estimated * 100)}%" in text  # "±20%"
    assert f"+{int(band_expire * 100)}%" in text  # "+15%"

    assert "금액 신뢰도" in text
    assert "출처 배지 기준" not in text  # 디커플링(DEC-2) — 출처 배지 기준 서술 금지


def test_pc6_disclaimer_d4_does_not_understate_official_badge_estimated_amount():
    """'배지 official + 금액 estimated' 케이스의 불확실성을 과소 고지하지
    않는다(R3) — 출처가 공식이어도 금액이 추정이면 밴드가 유지됨을 명시."""
    doc = next(d for d in build_policy_docs(CFG) if d.key == "disclaimer")
    d4 = next(s for s in doc.sections if s.req_id == "D-4")
    text = " ".join(d4.paragraphs)
    assert "공식" in text and "추정" in text
    assert "유지" in text


# ── PC-11: 초안 배너(창작 금지·법률 검토) ──────────────────────────────────


def test_pc11_draft_banner_shown_when_legal_not_reviewed():
    cfg = GenConfig(legal_reviewed=False)
    docs = build_policy_docs(cfg)
    assert len(docs) == 4
    for d in docs:
        assert d.draft is True


def test_pc11_draft_banner_hidden_when_legal_reviewed():
    cfg = GenConfig(legal_reviewed=True)
    docs = build_policy_docs(cfg)
    assert len(docs) == 4
    for d in docs:
        assert d.draft is False


def test_pc11_draft_banner_text_states_legal_review_required():
    assert "초안" in DRAFT_BANNER
    assert "법률 자문" in DRAFT_BANNER
    assert "검토" in DRAFT_BANNER and "필요" in DRAFT_BANNER


# ── PC-13(Tier-0, NFR21): XSS 이스케이프·비-JS 렌더 안전 ───────────────────


def _render_paragraph_autoescaped(paragraph: str) -> str:
    """SP-GEN이 `policy.html`에서 반드시 사용할 렌더 계약(SP-GEN-4.1)을
    재현: Jinja2 `autoescape=True` 환경에서 `paragraphs` 원문을 `|safe` 없이
    삽입한다(SP-POL-2.4). 실제 `templates/policy.html`은 SP-GEN(M5) 착지 시
    이 계약을 그대로 구현해야 한다."""
    env = jinja2.Environment(autoescape=True)
    template = env.from_string("{{ paragraph }}")
    return template.render(paragraph=paragraph)


def test_pc13_script_injection_in_paragraph_is_escaped():
    malicious = "<script>alert(1)</script>"
    section = PolicySection(
        req_id="D-1",
        anchor="d1",
        toc_label="테스트",
        heading="테스트 섹션",
        paragraphs=(f"정상 문단 앞부분 {malicious} 정상 문단 뒷부분",),
    )
    rendered = _render_paragraph_autoescaped(section.paragraphs[0])
    assert "<script>alert" not in rendered
    assert "&lt;script&gt;" in rendered


def test_pc13_all_real_section_paragraphs_render_safely():
    """실제 4종 문안 전체가 autoescape 경유 시에도 원문 그대로(비-HTML) 안전
    렌더된다 — 저자 실수로 원문에 `<`·`>`가 들어가도 방어적으로 이스케이프됨을
    회귀 검증한다(운영 문안 자체는 HTML 태그를 포함하지 않아야 한다)."""
    for doc in build_policy_docs(CFG):
        for section in doc.sections:
            for p in section.paragraphs:
                assert "<script" not in p.lower()  # 문안 자체에 스크립트 태그 없음
                rendered = _render_paragraph_autoescaped(p)
                assert "<script" not in rendered.lower()
                if "<" in p or ">" in p:
                    assert "&lt;" in rendered or "&gt;" in rendered


# ── 부수 검증: POLICY_FOOTER_LINKS 상수 구조(정본, 소비는 PC-5·M5에서 검증) ─


def test_policy_footer_links_constant_has_four_entries_matching_routes():
    """POLICY_FOOTER_LINKS 자체의 구조 정합(라우트 집합)만 확인한다.
    실제 소비처(생성 페이지 `_footer.html`·수기 셸) 일치 검증은 PC-5
    (`test_footer_links.py`, SP-GEN 렌더 착지 후 M5)로 연기한다."""
    assert len(POLICY_FOOTER_LINKS) == 4
    linked_routes = {route for _, route in POLICY_FOOTER_LINKS}
    doc_routes = {d.route for d in build_policy_docs(CFG)}
    assert linked_routes == doc_routes
