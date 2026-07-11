"""T-04.2.1 config.py Settings 유닛 테스트 (SP-API-2).

무 DB — 환경변수/기본값 파싱만 검증한다. 인증·메일·소셜 로그인 키가
정의되지 않았음(NFR16)을 구조적으로 강제한다.
"""
from __future__ import annotations


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
    """JWT_SECRET·OAUTH_*·SMTP_*·세션 키 필드 부재 (INV-1·NFR16)."""
    from server.config import Settings

    field_names = set(Settings.model_fields.keys())
    forbidden_substrings = ("jwt", "oauth", "smtp", "session", "secret", "password_reset")
    for name in field_names:
        lowered = name.lower()
        for bad in forbidden_substrings:
            assert bad not in lowered, f"인증/메일 필드 발견 금지: {name}"


def test_get_settings_is_cached_singleton():
    from server.config import get_settings

    a = get_settings()
    b = get_settings()
    assert a is b
