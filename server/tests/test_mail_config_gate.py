"""메일 설정 게이트 — 오설정이 '조용한 무발송'이 되지 않게 한다(적대검토 2026-07-27).

**수정 상호작용 결함**: 같은 세션에 넣은 두 수정이 서로를 무력화했다.
  - 수정3 `send_code_safe` — 발송 예외를 삼켜 균일 204(계정 열거 차단)를 지킨다
  - 수정4 `get_mailer` fail-closed — 오설정이면 RuntimeError 로 크게 실패한다
그런데 `get_mailer()` 호출이 `send_code_safe` 에 넘기는 lambda **안**에 있어, fail-closed 의
RuntimeError 까지 삼켜졌다. 결과는 정확히 fail-closed 가 막으려던 상태다 — 기동 성공, 응답 204,
**메일 0통**, 로그 한 줄. 적대검토 5개 렌즈 중 4개가 독립적으로 같은 결함에 수렴했다.

교훈: **설정 오류와 일시적 발송 실패는 다른 종류다.** 전자는 배포 시점에 크게 실패해야 하고,
후자만 삼켜야 한다. 그래서 설정 검증을 요청 경로가 아니라 **앱 기동 시점**으로 옮긴다.
"""
from __future__ import annotations

import pytest


# ── 기동 시점 검증 ──────────────────────────────────────────────────────────────
def test_MG1_validate_mail_config_raises_on_bad_sender(monkeypatch):
    """M9 ON + 발신 주소 오설정 → 기동 검증이 실패한다(요청이 오기 전에)."""
    from server.config import Settings
    from server.main import validate_mail_config

    s = Settings(_env_file=None, m9_enabled=True, mailer_mode="smtp",
                 smtp_user="resend", smtp_host="smtp.resend.com", smtp_pass="x", smtp_from="")
    with pytest.raises(RuntimeError, match="발신 주소"):
        validate_mail_config(s)


def test_MG2_validate_mail_config_passes_on_good_config():
    """정상 설정은 통과."""
    from server.config import Settings
    from server.main import validate_mail_config

    s = Settings(_env_file=None, m9_enabled=True, mailer_mode="smtp", smtp_user="resend",
                 smtp_host="smtp.resend.com", smtp_pass="x",
                 smtp_from="loupit <no-reply@jobcho.wiki>")
    validate_mail_config(s)  # 예외 없어야 함


def test_MG3_skipped_when_m9_off():
    """M9 OFF 배포(현 프로덕션)는 메일을 아예 안 보내므로 검증 대상이 아니다."""
    from server.config import Settings
    from server.main import validate_mail_config

    s = Settings(_env_file=None, m9_enabled=False, mailer_mode="smtp", smtp_user="", smtp_from="")
    validate_mail_config(s)  # OFF 면 통과


# ── mailer_mode 오타 방어 ───────────────────────────────────────────────────────
@pytest.mark.parametrize("bad", ["SMTP", "stmp", "smtp ", "Console", "none"])
def test_MG4_unknown_mailer_mode_is_rejected(monkeypatch, bad):
    """`mailer_mode` 오타가 조용히 ConsoleMailer 로 폴백하지 않는다.

    구 판본은 `== "smtp"` 만 봐서 `SMTP`·`stmp` 같은 값이 전부 else 로 떨어졌다. 그 결과가
    ConsoleMailer 이고, 그건 **인증 코드와 수신 이메일을 평문으로 journald 에 적재**한다는 뜻이다
    (NFR31 위반). 운영에서 가장 조용하고 가장 나쁜 실패라 명시적으로 거부한다."""
    from server.config import Settings
    from server.main import validate_mail_config

    s = Settings(_env_file=None, m9_enabled=True, mailer_mode=bad,
                 smtp_user="resend", smtp_host="h", smtp_pass="x",
                 smtp_from="a@b.com")
    with pytest.raises(RuntimeError, match="mailer_mode"):
        validate_mail_config(s)


def test_MG5_console_mode_is_allowed_but_only_exactly(monkeypatch):
    """정확히 'console' 은 허용(개발·베타의 명시적 선택)."""
    from server.config import Settings
    from server.main import validate_mail_config

    s = Settings(_env_file=None, m9_enabled=True, mailer_mode="console")
    validate_mail_config(s)


# ── 타임아웃이 엣지 타임아웃보다 넉넉히 짧은가 ───────────────────────────────────
def test_MG6_smtp_timeout_leaves_headroom_under_nginx():
    """SMTP 타임아웃이 nginx `proxy_read_timeout`(15s)보다 충분히 짧다.

    같거나 크면 제공자가 느려질 때 nginx 가 먼저 끊어 **클라이언트가 204 대신 504** 를 받는다 —
    "계정 유무 무관 균일 204"(계정 열거 차단) 계약이 엣지에서 깨지고, 느린 응답 자체가 관측
    채널이 된다. 실측: `/etc/nginx/sites-available/loupit-beta.conf` `proxy_read_timeout 15s`."""
    from server.mailer import _SMTP_TIMEOUT_SEC

    NGINX_PROXY_READ_TIMEOUT = 15
    assert _SMTP_TIMEOUT_SEC < NGINX_PROXY_READ_TIMEOUT, (
        f"SMTP 타임아웃 {_SMTP_TIMEOUT_SEC}s 가 nginx {NGINX_PROXY_READ_TIMEOUT}s 이상 — 504 로 샌다"
    )
    assert NGINX_PROXY_READ_TIMEOUT - _SMTP_TIMEOUT_SEC >= 5, (
        "여유가 5초 미만 — TLS 핸드셰이크·DNS 변동을 흡수하지 못한다"
    )


# ── 테스트 스위트가 실제 메일을 보내지 않는가 ─────────────────────────────────────
@pytest.mark.asyncio
async def test_MG7_test_suite_never_uses_real_smtp_mailer():
    """conftest 의 전역 스텁이 살아 있어, 어떤 테스트도 실제 SMTP 로 나가지 않는다.

    `test_csrf.py::test_AC1_with_csrf_header_passes_gate` 는 CSRF 헤더를 **붙여서**
    `/members/login-code` 를 호출하고 204 를 검증한다 — 즉 핸들러가 끝까지 실행된다. 스텁이 없으면
    `MAILER_MODE=smtp` 인 서버에서 릴리스 게이트를 돌릴 때마다 **운영 Resend 계정으로 진짜 메일이
    나간다**(무료 티어 일 100통 소모·도메인 평판 손상). 적대검토가 blocker 로 잡은 항목."""
    from server import mailer

    m = mailer.get_mailer()
    assert not isinstance(m, mailer.SmtpMailer), (
        f"테스트에서 실 SMTP 메일러가 선택됨: {type(m).__name__} — conftest 전역 스텁이 깨졌다"
    )
