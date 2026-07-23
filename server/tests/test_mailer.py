"""SP-AUTH-11 메일러 — 모드 선택·폴백·원문 미노출 (T-13.12.1).

get_mailer 가 mailer_mode + smtp_user 로 Console/SMTP 를 고르고, smtp_user 미설정 시
Console 폴백함을 확인한다. SmtpMailer 전송이 코드 원문을 로그에 남기지 않음도 검증(NFR31).
"""
from __future__ import annotations

import logging

import pytest

from server.config import get_settings


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


def test_get_mailer_defaults_to_console(monkeypatch):
    monkeypatch.setenv("MAILER_MODE", "console")
    get_settings.cache_clear()
    from server.mailer import ConsoleMailer, get_mailer

    assert isinstance(get_mailer(), ConsoleMailer)


def test_get_mailer_smtp_without_user_falls_back_to_console(monkeypatch):
    """규칙3: mailer_mode=smtp 라도 smtp_user 미설정이면 Console 폴백(실발송 방지)."""
    monkeypatch.setenv("MAILER_MODE", "smtp")
    monkeypatch.setenv("SMTP_USER", "")
    get_settings.cache_clear()
    from server.mailer import ConsoleMailer, get_mailer

    assert isinstance(get_mailer(), ConsoleMailer)


def test_get_mailer_smtp_with_user_selects_smtp(monkeypatch):
    monkeypatch.setenv("MAILER_MODE", "smtp")
    monkeypatch.setenv("SMTP_USER", "noreply@loupit.example")
    monkeypatch.setenv("SMTP_HOST", "smtp.example")
    get_settings.cache_clear()
    from server.mailer import SmtpMailer, get_mailer

    assert isinstance(get_mailer(), SmtpMailer)


@pytest.mark.asyncio
async def test_smtp_mailer_send_does_not_log_code(monkeypatch, caplog):
    """SmtpMailer 전송이 코드 원문을 서버 로그에 남기지 않는다(NFR31)."""
    from server.mailer import SmtpMailer

    sent = {}

    def _fake_send(to, subject, body):
        sent["to"], sent["subject"], sent["body"] = to, subject, body

    m = SmtpMailer("smtp.example", 587, "u", "p", "from@x")
    monkeypatch.setattr(m, "_send", _fake_send)
    with caplog.at_level(logging.DEBUG):
        await m.send_login_code("user@x.com", "654321")

    assert "654321" in sent["body"]         # 실제 메일 본문엔 코드(정상)
    assert "654321" not in caplog.text      # 로그엔 코드 없음(NFR31)
