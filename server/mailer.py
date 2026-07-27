"""SP-AUTH-11 메일러 추상화 — Console(개발) / SMTP(운영).

`mailer_mode` + `smtp_user` 로 선택하며, `mailer_mode=smtp` 라도 `smtp_user` 미설정이면
ConsoleMailer 로 폴백해 실발송을 막는다(규칙3). **신규 의존성 0**(stdlib `smtplib` +
`asyncio.to_thread`). 코드·이메일 원문을 운영 로그나 응답에 남기지 않는다(NFR31) — 개발용
ConsoleMailer 만 편의로 stdout 에 코드를 찍으며, 이는 운영 게이트(로그 grep) 대상 밖이다.
"""
from __future__ import annotations

import asyncio
import smtplib
import ssl
from email.message import EmailMessage

from server.config import get_settings

_LOGIN_SUBJECT = "[loupit] 로그인 코드"
_EMPLOY_SUBJECT = "[loupit] 재직 인증 코드"

# 연결·대화 전체 상한(초). 코드 TTL 이 5분이라 그 안에 끝나지 않으면 어차피 무의미하고,
# 무한 대기는 asyncio.to_thread 의 기본 스레드풀 슬롯을 영구 점유해 API 전체를 멈춘다
# (socket.getdefaulttimeout() 이 None 이라 미지정 시 정말로 무한이다 — 실측 확인).
_SMTP_TIMEOUT_SEC = 15


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
        # `starttls()` 를 컨텍스트 없이 부르면 stdlib 기본이 check_hostname=False·CERT_NONE 이라
        # 암호화만 되고 **상대를 확인하지 않는다**(python3.10 실측). 그 위로 SMTP 비밀번호와 인증
        # 코드가 흐르므로 반드시 검증 컨텍스트를 명시한다.
        ctx = ssl.create_default_context()
        with smtplib.SMTP(self._host, self._port, timeout=_SMTP_TIMEOUT_SEC) as s:
            s.starttls(context=ctx)
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
        # 발신 주소 검증(2026-07-27). `smtp_from or smtp_user` 폴백 자체는 유지한다 — Gmail 처럼
        # 계정명이 곧 이메일인 제공자에선 정당하다. 문제는 **결과가 주소가 아닐 때**다: Resend 의
        # smtp_user 는 리터럴 `"resend"` 라서 폴백하면 From 이 `resend` 가 되고, 수신측이 거부하는데
        # 서버 로그엔 성공으로 남아 원인 추적이 어렵다. 그래서 폴백을 막는 게 아니라 최종값을 본다.
        # (발신 도메인은 SPF/DKIM 정렬 대상이므로 운영에서 아무 값이나 될 수 없다.)
        sender = s.smtp_from or s.smtp_user
        if "@" not in sender:
            raise RuntimeError(
                f"mailer_mode=smtp 인데 발신 주소가 이메일이 아님(smtp_from={s.smtp_from!r}, "
                f"폴백 smtp_user={s.smtp_user!r}) — SMTP_FROM 에 발신 주소를 지정하세요"
                " (예: 'loupit <no-reply@jobcho.wiki>')."
            )
        return SmtpMailer(s.smtp_host, s.smtp_port, s.smtp_user, s.smtp_pass, sender)
    return ConsoleMailer()
