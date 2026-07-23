"""SP-AUTH-11 메일러 추상화 — Console(개발) / SMTP(운영).

`mailer_mode` + `smtp_user` 로 선택하며, `mailer_mode=smtp` 라도 `smtp_user` 미설정이면
ConsoleMailer 로 폴백해 실발송을 막는다(규칙3). **신규 의존성 0**(stdlib `smtplib` +
`asyncio.to_thread`). 코드·이메일 원문을 운영 로그나 응답에 남기지 않는다(NFR31) — 개발용
ConsoleMailer 만 편의로 stdout 에 코드를 찍으며, 이는 운영 게이트(로그 grep) 대상 밖이다.
"""
from __future__ import annotations

import asyncio
import smtplib
from email.message import EmailMessage

from server.config import get_settings

_LOGIN_SUBJECT = "[loupit] 로그인 코드"
_EMPLOY_SUBJECT = "[loupit] 재직 인증 코드"


def _body(code: str, ttl_min: int) -> str:
    return f"인증 코드: {code}\n{ttl_min}분 안에 입력하세요. 본 메일을 요청하지 않았다면 무시하세요."


class ConsoleMailer:
    """개발용 — 코드를 stdout 에 출력(실발송 없음). 운영 게이트 대상 외."""

    async def send_login_code(self, email: str, code: str) -> None:
        print(f"[ConsoleMailer] 로그인 코드 → {email}: {code}")

    async def send_employ_code(self, email: str, code: str) -> None:
        print(f"[ConsoleMailer] 재직 인증 코드 → {email}: {code}")


class SmtpMailer:
    """운영용 — stdlib smtplib(STARTTLS). 블로킹 전송을 asyncio.to_thread 로 오프로드한다.

    응답·서버 로그에 코드 원문을 남기지 않는다(NFR31)."""

    def __init__(self, host: str, port: int, user: str, password: str, sender: str) -> None:
        self._host, self._port = host, port
        self._user, self._pass = user, password
        self._from = sender or user

    def _send(self, to: str, subject: str, body: str) -> None:
        msg = EmailMessage()
        msg["From"] = self._from
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self._host, self._port) as s:
            s.starttls()
            if self._user:
                s.login(self._user, self._pass)
            s.send_message(msg)

    async def send_login_code(self, email: str, code: str) -> None:
        ttl = get_settings().login_code_ttl_min
        await asyncio.to_thread(self._send, email, _LOGIN_SUBJECT, _body(code, ttl))

    async def send_employ_code(self, email: str, code: str) -> None:
        ttl = get_settings().login_code_ttl_min
        await asyncio.to_thread(self._send, email, _EMPLOY_SUBJECT, _body(code, ttl))


def get_mailer():
    """`mailer_mode` 로 메일러 선택. **운영 fail-closed**(보안점검 2026-07-23):

    `mailer_mode=smtp` 인데 `smtp_user` 가 비면, 코드가 stdout(운영 로그)으로 새는 ConsoleMailer 로
    **조용히 폴백하지 않고 기동/발송을 실패**시킨다(NFR31). ConsoleMailer(코드 stdout 출력)는 오직
    `mailer_mode=console`(명시적 개발 선택)에서만 반환된다 — 운영은 mailer_mode=smtp + smtp_user 필수."""
    s = get_settings()
    if s.mailer_mode == "smtp":
        if not s.smtp_user:
            raise RuntimeError(
                "mailer_mode=smtp 인데 smtp_user 미설정 — 코드가 로그로 새는 console 폴백을 막기 위해 "
                "실패(fail-closed). SMTP 자격을 주입하거나 개발이면 mailer_mode=console 로 명시하세요."
            )
        return SmtpMailer(s.smtp_host, s.smtp_port, s.smtp_user, s.smtp_pass, s.smtp_from)
    return ConsoleMailer()
