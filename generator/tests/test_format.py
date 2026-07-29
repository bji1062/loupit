"""T-07.4.2·4.3 표시 포맷·배지·JSON-LD 헬퍼 단위 테스트 (SP-GEN-4.3)."""
from __future__ import annotations

import json
from datetime import datetime

import pytest

from generator.format import (
    WS_LABELS,
    badge_state,
    iso_date,
    jsonld_dumps,
    krw_manwon,
    work_style_label,
)

NOW = datetime(2026, 7, 11)


# ── krw_manwon (FR-04) ──────────────────────────────────────────────────────


def test_krw_manwon_none_returns_empty():
    assert krw_manwon(None) == ""


def test_krw_manwon_under_eok():
    assert krw_manwon(1200) == "1,200만원"


def test_krw_manwon_exact_eok():
    assert krw_manwon(10000) == "1억원"


def test_krw_manwon_eok_and_man():
    assert krw_manwon(12345) == "1억 2,345만원"


def test_krw_manwon_zero():
    assert krw_manwon(0) == "0만원"


# ── iso_date ─────────────────────────────────────────────────────────────


def test_iso_date_none():
    assert iso_date(None) == ""


def test_iso_date_string():
    assert iso_date("2026-04-15") == "2026-04-15"


def test_iso_date_string_with_time_truncates():
    assert iso_date("2026-04-15T00:00:00") == "2026-04-15"


def test_iso_date_datetime_object():
    assert iso_date(datetime(2026, 4, 15)) == "2026-04-15"


# ── work_style_label ─────────────────────────────────────────────────────


def test_work_style_label_remote():
    assert work_style_label("remote") == "재택근무"


def test_work_style_label_all_keys_covered():
    for k in ("remote", "flex", "unlimitedPTO", "refreshLeave", "overtime"):
        assert work_style_label(k) == WS_LABELS[k]


def test_work_style_label_unknown_returns_key():
    assert work_style_label("mystery") == "mystery"


# ── badge_state (FR-54·05, INV-5) ───────────────────────────────────────


def test_badge_state_official_and_not_expired():
    """사람이 공식 페이지에서 직접 확인한 항목만 "공식 확인"이다."""
    b = {"badge_cd": "official", "expires_dtm": "2099-12-31", "badge_src_cd": "scrape_official"}
    r = badge_state(b, NOW)
    assert r == {"code": "official", "label": "공식 확인"}


def test_badge_state_ai_parsed_official_is_downgraded_in_wording():
    """자동 파싱 산출물은 "공식 확인"이라 단언하지 않는다 (§G-3 과잉 주장 해소).

    출처는 공식 페이지라 코드는 official 계열이지만, 추출을 기계가 한 이상
    '확인했다'고 말할 근거가 없다 — 1,246건이 이 경로다.
    """
    b = {"badge_cd": "official", "expires_dtm": "2099-12-31", "badge_src_cd": "ai_parse"}
    r = badge_state(b, NOW)
    assert r == {"code": "official-derived", "label": "공식 페이지 기반"}


def test_badge_state_official_without_src_cd_is_not_upgraded():
    """출처 방식을 모르면 낮은 쪽으로 말한다 — 모름을 '확인함'으로 올리면 안 된다."""
    b = {"badge_cd": "official", "expires_dtm": "2099-12-31"}
    r = badge_state(b, NOW)
    assert r["label"] == "공식 페이지 기반"


def test_badge_state_estimated_and_not_expired():
    b = {"badge_cd": "est", "expires_dtm": "2099-12-31"}
    r = badge_state(b, NOW)
    assert r == {"code": "est", "label": "추정"}


def test_badge_state_missing_badge_cd_defaults_to_est():
    b = {"expires_dtm": "2099-12-31"}
    r = badge_state(b, NOW)
    assert r["code"] == "est"


def test_badge_state_expired_overrides_official():
    """만료가 최우선 — official이어도 만료면 stale (FR-54)."""
    b = {"badge_cd": "official", "expires_dtm": "2020-01-01"}
    r = badge_state(b, NOW)
    assert r == {"code": "stale", "label": "만료·재확인 필요"}


def test_badge_state_no_expires_dtm_not_stale():
    b = {"badge_cd": "official", "expires_dtm": None, "badge_src_cd": "scrape_official"}
    r = badge_state(b, NOW)
    assert r["code"] == "official"


def test_badge_state_does_not_emit_band_coefficient():
    """밴드 계수(DEC-2)는 SP-CALC 소유 — badge_state는 산출하지 않는다(INV-5)."""
    b = {"badge_cd": "official", "expires_dtm": "2099-12-31", "amt_source": "estimated"}
    r = badge_state(b, NOW)
    assert set(r.keys()) == {"code", "label"}


# ── jsonld_dumps (NFR21·8) ───────────────────────────────────────────────


def test_jsonld_dumps_parses_back_to_same_object():
    obj = {"@type": "Organization", "name": "삼성전자"}
    s = jsonld_dumps(obj)
    # 이스케이프 시퀀스를 되돌려 원본과 동치인지 확인 (json.loads가 \uXXXX 해석)
    assert json.loads(s) == obj


def test_jsonld_dumps_escapes_script_breakout_chars():
    obj = {"name": "<script>alert(1)</script>"}
    s = jsonld_dumps(obj)
    assert "<script>" not in s
    assert "</script>" not in s
    assert "\\u003c" in s and "\\u003e" in s


def test_jsonld_dumps_escapes_ampersand():
    obj = {"name": "A&B"}
    s = jsonld_dumps(obj)
    assert "\\u0026" in s
    assert json.loads(s) == obj
