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

# 사용자에게 보이는 서비스명. **`loupit` 은 리포/서버 내부 이름일 뿐 브랜드가 아니다**
# (2026-07-28 실사용자 지적: 인증 메일이 `[loupit]` 로 도착했다). 라이브가 자기를 부르는 이름은
# `jobcho.wiki` 하나다 — `<title>`·`og:site_name`·`generator/config.py:site_name`,
# 그리고 **약관·개인정보 문서가 이 표기를 10회** 쓴다. 법적 문서와 인증 메일의 발신자 표기가
# 갈리면 피싱으로 오인되거나 고지 일관성 문제가 되므로 여기서 한 번만 정의해 파생시킨다.
# `SMTP_FROM` 표시명(server/.env)도 같은 문자열이어야 한다.
SERVICE_NAME = "jobcho.wiki"

_LOGIN_SUBJECT = f"[{SERVICE_NAME}] 로그인 코드"
_EMPLOY_SUBJECT = f"[{SERVICE_NAME}] 재직 인증 코드"

# 소켓 연산 1회당 상한(초). ⚠ smtplib 의 timeout 은 **대화 전체 상한이 아니라 개별 소켓 연산
# 상한**이라, 느린 피어는 이 값의 여러 배를 끌 수 있다(적대검토 2026-07-27 정정).
#
# 무한 대기는 asyncio.to_thread 의 기본 스레드풀 슬롯을 영구 점유해 API 전체를 멈춘다
# (socket.getdefaulttimeout() 이 None 이라 미지정 시 정말로 무한이다 — 실측 확인).
#
# 값은 nginx `proxy_read_timeout 15s` 보다 **넉넉히 짧아야** 한다. 같거나 크면 제공자가 느려질 때
# nginx 가 먼저 끊어 클라이언트가 204 대신 **504** 를 받고, "계정 유무 무관 균일 204"(계정 열거
# 차단) 계약이 엣지에서 깨진다. 8s = 15s 대비 7s 여유(TLS 핸드셰이크·DNS 변동 흡수).
# Resend 실측 왕복은 1s 미만이라 정상 경로엔 영향이 없다(test_mail_config_gate MG-6).
_SMTP_TIMEOUT_SEC = 8


def _body(code: str, ttl_min: int) -> str:
    return f"인증 코드: {code}\n{ttl_min}분 안에 입력하세요. 본 메일을 요청하지 않았다면 무시하세요."


class ConsoleMailer:
    """개발용 — 코드를 stdout 에 출력(실발송 없음). 운영 게이트 대상 외."""

    async def send_login_code(self, email: str, code: str) -> None:
        print(f"[ConsoleMailer] 로그인 코드 → {email}: {code}")

    async def send_employ_code(self, email: str, code: str) -> None:
        print(f"[ConsoleMailer] 재직 인증 코드 → {email}: {code}")

    def send_notice(self, to: str, subject: str, body: str) -> None:
        print(f"[ConsoleMailer] 공지 → {to}: {subject}\n{body}")


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

    def send_notice(self, to: str, subject: str, body: str) -> None:
        """운영자 대상 공지(큐 요약 등). **동기**다 — 유일한 호출자가 `ops` CLI(systemd
        oneshot)라서 이벤트 루프가 없다. 코드 발송 경로는 async 를 유지한다(요청 핸들러 안).

        ⚠ 인증 코드를 여기로 보내지 마라. 코드 발송은 TTL·NFR31 규약을 가진 위 두 메서드가
        소유한다 — 범용 통로로 코드를 흘리면 그 규약을 우회하게 된다."""
        self._send(to, subject, body)


def resolve_sender(s) -> str:
    """SMTP 발신 주소를 확정하고 검증한다 — 잘못됐으면 RuntimeError.

    `get_mailer()`(런타임, 캐시된 전역 설정)와 `main.validate_mail_config()`(기동 시점, 명시적
    설정 객체)가 **같은 규칙**을 쓰도록 분리한 헬퍼다. 분리 전에는 검증이 `get_mailer()` 안에만
    있어, 설정 객체를 인자로 받는 기동 검증이 그 인자를 무시하고 전역 캐시를 보는 불일치가 있었다."""
    if not s.smtp_user:
        raise RuntimeError(
            "mailer_mode=smtp 인데 smtp_user 미설정 — 코드가 로그로 새는 console 폴백을 막기 위해 "
            "실패(fail-closed). SMTP 자격을 주입하거나 개발이면 mailer_mode=console 로 명시하세요."
        )
    if not s.smtp_host:
        # 빈 호스트는 smtplib 이 연결 자체를 시도하지 않아 가장 헷갈리는 예외로 떨어진다.
        raise RuntimeError("mailer_mode=smtp 인데 smtp_host 미설정 — SMTP_HOST 를 지정하세요.")
    # 발신 주소 검증. `smtp_from or smtp_user` 폴백 자체는 유지한다 — Gmail 처럼 계정명이 곧
    # 이메일인 제공자에선 정당하다. 문제는 **결과가 주소가 아닐 때**다: Resend 의 smtp_user 는
    # 리터럴 "resend" 라서 폴백하면 From 이 `resend` 가 되고, 수신측이 거부하는데 서버 로그엔
    # 성공으로 남아 원인 추적이 어렵다. (발신 도메인은 SPF/DKIM 정렬 대상이다.)
    sender = s.smtp_from or s.smtp_user
    if "@" not in sender:
        raise RuntimeError(
            f"mailer_mode=smtp 인데 발신 주소가 이메일이 아님(smtp_from={s.smtp_from!r}, "
            f"폴백 smtp_user={s.smtp_user!r}) — SMTP_FROM 에 발신 주소를 지정하세요"
            f" (예: '{SERVICE_NAME} <no-reply@jobcho.wiki>')."
        )
    return sender


def get_mailer():
    """`mailer_mode` 로 메일러 선택. **운영 fail-closed**(보안점검 2026-07-23):

    `mailer_mode=smtp` 인데 `smtp_user` 가 비면, 코드가 stdout(운영 로그)으로 새는 ConsoleMailer 로
    **조용히 폴백하지 않고 기동/발송을 실패**시킨다(NFR31). ConsoleMailer(코드 stdout 출력)는 오직
    `mailer_mode=console`(명시적 개발 선택)에서만 반환된다 — 운영은 mailer_mode=smtp + smtp_user 필수."""
    s = get_settings()
    if s.mailer_mode == "smtp":
        sender = resolve_sender(s)  # 검증 규칙은 기동 시점 검증과 공유(main.validate_mail_config)
        return SmtpMailer(s.smtp_host, s.smtp_port, s.smtp_user, s.smtp_pass, sender)
    return ConsoleMailer()
