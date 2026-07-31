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
    # 2026-07-31 라벨 정리: "공식 확인" → "공식". 세 렌더러(정적·비교리포트·디렉터리)가
    # 서로 다른 문구를 쓰고 있었고(디렉터리는 이미 '공식'), 이 변경이 셋을 일치시킨다.
    b = {"badge_cd": "official", "expires_dtm": "2099-12-31"}
    r = badge_state(b, NOW)
    assert r == {"code": "official", "label": "공식"}


# ── 출처 계보 배지 (2026-07-31) ─────────────────────────────────────────────
#
# 배지가 "어떻게 수집했나"가 아니라 **"누가 마지막으로 손댔나"**를 말한다.
# `edit_origin` 은 편집 이력에서 파생되며, 편집은 `require_employment` 게이트 뒤라
# **그 회사 재직 인증자만** 남길 수 있다 — 그래서 라벨이 '사용자'가 아니라 '재직자'다.


def test_badge_state_member_added():
    r = badge_state({"badge_cd": "official", "edit_origin": "member"}, NOW)
    assert r == {"code": "member", "label": "재직자 등록"}


def test_badge_state_member_edited():
    r = badge_state({"badge_cd": "official", "edit_origin": "edited"}, NOW)
    assert r == {"code": "edited", "label": "공식·재직자 수정"}


def test_badge_state_expiry_beats_edit_origin():
    """**신선도가 최우선.** 누가 넣었든 오래된 값은 오래된 값이다.

    이 우선순위가 뒤집히면 만료된 재직자 등록 항목이 '재직자 등록'으로만 보이고
    사용자는 그 값이 낡았다는 가장 급한 정보를 놓친다."""
    for origin in ("member", "edited", None):
        r = badge_state({"badge_cd": "official", "edit_origin": origin, "expires_dtm": "2000-01-01"}, NOW)
        assert r["code"] == "stale", f"{origin}: 만료가 계보를 이기지 못했다"


def test_badge_state_unknown_origin_falls_back_to_badge_cd():
    """모르는 값이 오면 기존 축으로 떨어진다(전방 호환 — 새 origin 이 생겨도 안 깨진다)."""
    assert badge_state({"badge_cd": "official", "edit_origin": "???"}, NOW)["code"] == "official"
    assert badge_state({"badge_cd": "est", "edit_origin": None}, NOW)["code"] == "est"


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
    b = {"badge_cd": "official", "expires_dtm": None}
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
