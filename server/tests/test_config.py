"""T-04.2.1 config.py Settings 유닛 테스트 (SP-API-2).

무 DB — 환경변수/기본값 파싱만 검증한다. 비밀번호·소셜·JWT 키가 정의되지 않았음
(NFR16·SC10)을 구조적으로 강제한다. SC14(③) 재명세: 금지 substring 을 좁혀
`smtp·session·secret` 을 허용(SP-AUTH-2 정당 필드)하고, SC14 필드 존재는 @pytest.mark.sc14
스펙(AU-5, 구현 M9 전 RED)으로 별도 명세한다.
"""
from __future__ import annotations

import pytest


def test_default_api_prefix():
    from server.config import Settings

    s = Settings(_env_file=None)
    assert s.api_prefix == "/api/v1"


def test_default_reference_cache_control():
    from server.config import Settings

    s = Settings(_env_file=None)
    assert s.reference_cache_control == "public, max-age=3600"
    assert s.reference_cache_ttl == 3600


def test_cors_origin_list_parses_and_strips():
    from server.config import Settings

    s = Settings(_env_file=None, cors_allow_origins=" https://a.com ,https://b.com,, ")
    assert s.cors_origin_list == ["https://a.com", "https://b.com"]


def test_cors_origin_list_default_no_wildcard():
    from server.config import Settings

    s = Settings(_env_file=None)
    assert "*" not in s.cors_origin_list
    assert s.cors_origin_list  # 비어있지 않음


def test_no_auth_fields_defined():
    """금지 substring(jwt·oauth·password_reset·social) 필드 부재 (INV-1·NFR16·T10).

    SC14(③ 재명세, 핸드오프 §C item2): 구 regime 이 금지했던 `smtp`·`session`·`secret` 은
    SC14 로 정당한 필드(mailer·세션 TTL·pepper, SP-AUTH-2)가 되어 **금지목록에서 제거**한다 —
    금지를 넓히는 게 아니라 좁히는 개정이다. 비밀번호·소셜·JWT 는 SC10 으로 영구 금지 유지하고,
    신규 `social` 을 추가해 소셜 로그인 부활을 계속 차단한다."""
    from server.config import Settings

    field_names = set(Settings.model_fields.keys())
    forbidden_substrings = ("jwt", "oauth", "password_reset", "social")
    for name in field_names:
        lowered = name.lower()
        for bad in forbidden_substrings:
            assert bad not in lowered, f"금지 인증 필드 발견: {name} (substring '{bad}')"


def test_get_settings_is_cached_singleton():
    from server.config import get_settings

    a = get_settings()
    b = get_settings()
    assert a is b


@pytest.mark.sc14
def test_AU5_sc14_config_fields_present():
    """AU-5(SC14): SP-AUTH-2 참여 설정 필드가 기본값·타입과 함께 존재한다.

    구현(M9) 전엔 필드 부재라 RED → @pytest.mark.sc14 로 베이스 게이트 제외.
    금지 substring(jwt·oauth·password_reset·social)을 어느 필드도 포함하지 않음도 재확인한다."""
    from server.config import Settings

    s = Settings(_env_file=None)
    # 메일러 (SP-AUTH-11)
    assert s.mailer_mode == "console"
    assert s.smtp_host == "" and s.smtp_port == 587
    assert s.smtp_user == "" and s.smtp_pass == "" and s.smtp_from == ""
    # 세션·코드 TTL·시도 상한 (SP-AUTH-4·5·12, FR-101·112)
    assert s.session_ttl_days == 30
    assert s.login_code_ttl_min == 10
    assert s.code_max_attempts == 5
    assert s.mail_resend_cooldown_sec == 60
    assert s.daily_edit_limit == 30
    assert s.employ_vrf_ttl_days == 365
    # 비밀 pepper (SP-AUTH-4·7, NFR30) — 기본 빈문자
    assert s.session_hash_pepper == ""
    assert s.comp_email_hmac_pepper == ""
    assert s.login_code_hmac_pepper == ""  # 로그인 코드 HMAC 키(보안점검 2026-07-23, 운영 필수)
    # 금지 substring 재확인(신규 필드가 4종을 포함하지 않음)
    for name in Settings.model_fields:
        low = name.lower()
        assert not any(bad in low for bad in ("jwt", "oauth", "password_reset", "social"))
