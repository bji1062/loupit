"""SP-AUTH-11 SMTP 발송 경로 하드닝 — 실발송 직전 점검(2026-07-27).

**배경**: `mailer_mode=smtp` 경로는 저장소 역사상 **한 번도 실행된 적이 없다**(줄곧 Console).
Resend 연동으로 처음 운영에 투입되기 직전이라, 실행되지 않아 드러나지 않았던 결함을 계약으로 고정한다.

확증된 결함 4건(전부 smtp 모드에서만 발현):
  1. TLS 미검증 — `starttls()` 를 컨텍스트 없이 호출하면 stdlib 기본이
     `check_hostname=False`·`verify_mode=CERT_NONE` 이다(python3.10 실측). 암호화는 되지만 **상대를
     확인하지 않아** MITM 이 가능하고, 그 위로 SMTP 비밀번호와 인증 코드가 흐른다.
  2. 타임아웃 없음 — `socket.getdefaulttimeout()` 이 None 이라 `smtplib.SMTP(host, port)` 가 무한
     블록된다. `asyncio.to_thread` 로 오프로드돼 있어 **기본 스레드풀 슬롯이 영구 점유**되고,
     반복되면 API 전체가 멈춘다.
  3. 발송 실패가 500 으로 샌다 — 라우터는 "계정 유무 무관 균일 204"(계정 열거 차단, NFR31)를
     계약으로 걸어 두었는데, 메일 예외가 그대로 올라가면 500 이 되어 계약이 깨진다.
  4. `smtp_from` 미검증 — `sender or user` 폴백인데 Resend 의 `smtp_user` 는 문자열 `"resend"`(주소
     아님)라, `SMTP_FROM` 을 빠뜨리면 From 이 유효 주소가 아닌 채 발송된다. fail-closed 검사는
     `smtp_user` 만 본다.

무 DB·무 네트워크 — 소켓을 스텁으로 가로채 인자만 검증한다.
"""
from __future__ import annotations

import smtplib
import ssl

import pytest


@pytest.fixture
def smtp_spy(monkeypatch):
    """`smtplib.SMTP` 를 가로채 생성 인자·starttls 컨텍스트·로그인·발송을 기록한다."""
    rec: dict = {"init": None, "starttls": "미호출", "login": None, "sent": None}

    class FakeSMTP:
        def __init__(self, host=None, port=0, local_hostname=None, timeout=None, **kw):
            rec["init"] = {"host": host, "port": port, "timeout": timeout}

        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

        def starttls(self, *, context=None, **kw):
            rec["starttls"] = context

        def login(self, user, password):
            rec["login"] = user

        def send_message(self, msg):
            rec["sent"] = msg

    monkeypatch.setattr(smtplib, "SMTP", FakeSMTP)
    return rec


def _mailer(**over):
    from server.mailer import SmtpMailer

    kw = dict(host="smtp.resend.com", port=587, user="resend",
              password="re_secret", sender="loupit <no-reply@jobcho.wiki>")
    kw.update(over)
    return SmtpMailer(**kw)


# ── 결함 1: TLS 검증 ────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS1_starttls_uses_verifying_context(smtp_spy):
    """STARTTLS 가 **인증서·호스트명을 검증하는** 컨텍스트를 명시적으로 넘긴다.

    컨텍스트를 생략하면 stdlib 기본이 검증을 끄므로, 암호화만 되고 상대는 아무나여도 통과한다."""
    await _mailer().send_login_code("hong@samsung.com", "123456")

    ctx = smtp_spy["starttls"]
    assert isinstance(ctx, ssl.SSLContext), f"starttls 에 SSLContext 미전달: {ctx!r}"
    assert ctx.check_hostname is True, "호스트명 검증 꺼짐 — MITM 가능"
    assert ctx.verify_mode == ssl.CERT_REQUIRED, f"인증서 검증 꺼짐: {ctx.verify_mode}"


# ── 결함 2: 타임아웃 ────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS2_connection_has_timeout(smtp_spy):
    """SMTP 연결에 유한 타임아웃이 걸린다 — 무한 블록이 스레드풀을 잠식하지 못하게."""
    await _mailer().send_login_code("hong@samsung.com", "123456")

    t = smtp_spy["init"]["timeout"]
    assert t is not None, "timeout 미지정 — 응답 없는 서버에 영구 블록된다"
    assert 0 < t <= 30, f"타임아웃이 비현실적: {t}s (코드 TTL 5분 안에 끝나야 함)"


# ── 결함 4: 발신 주소 ───────────────────────────────────────────────────────────
def test_MS4_get_mailer_rejects_missing_sender(monkeypatch):
    """`mailer_mode=smtp` 인데 `smtp_from` 이 없으면 fail-closed.

    구 판본은 `sender or user` 로 폴백해, Resend 처럼 user 가 주소가 아닌 제공자에서 유효하지 않은
    From 으로 발송을 시도했다(수신 거부). 조용한 실패보다 기동 실패가 낫다."""
    from server.config import Settings, get_settings

    import server.mailer as m

    monkeypatch.setattr(m, "get_settings", lambda: Settings(
        _env_file=None, mailer_mode="smtp", smtp_user="resend",
        smtp_host="smtp.resend.com", smtp_pass="re_x", smtp_from=""))
    with pytest.raises(RuntimeError, match="smtp_from"):
        m.get_mailer()
    get_settings.cache_clear()


def test_MS4d_email_like_smtp_user_still_falls_back(monkeypatch):
    """반대 방향 가드: `smtp_user` 가 이메일인 제공자(Gmail 등)에선 폴백이 계속 허용된다.

    검증 대상은 '폴백 여부'가 아니라 '최종 발신값이 주소인가' 다 — 과잉 제한으로 정상 설정을
    막지 않도록 이 케이스를 계약으로 고정한다(초판이 실제로 이 회귀를 냈고 test_mailer 가 잡았다)."""
    from server.config import Settings

    import server.mailer as m

    monkeypatch.setattr(m, "get_settings", lambda: Settings(
        _env_file=None, mailer_mode="smtp", smtp_user="noreply@jobcho.wiki",
        smtp_host="smtp.example", smtp_pass="x", smtp_from=""))
    mailer = m.get_mailer()
    assert isinstance(mailer, m.SmtpMailer)
    assert mailer._from == "noreply@jobcho.wiki"


def test_MS4b_get_mailer_rejects_sender_without_at(monkeypatch):
    """From 이 이메일 형태가 아니면 거부 — `resend` 같은 계정명이 흘러드는 것을 막는다."""
    from server.config import Settings

    import server.mailer as m

    monkeypatch.setattr(m, "get_settings", lambda: Settings(
        _env_file=None, mailer_mode="smtp", smtp_user="resend",
        smtp_host="smtp.resend.com", smtp_pass="re_x", smtp_from="resend"))
    with pytest.raises(RuntimeError, match="smtp_from"):
        m.get_mailer()


@pytest.mark.asyncio
async def test_MS4c_display_name_form_is_accepted(smtp_spy):
    """`이름 <주소>` 표기는 정상 통과하고 그대로 From 에 실린다."""
    await _mailer(sender="loupit <no-reply@jobcho.wiki>").send_login_code("a@b.com", "123456")
    assert smtp_spy["sent"]["From"] == "loupit <no-reply@jobcho.wiki>"


# ── 결함 3: 균일 204 계약 ───────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS3_send_failure_does_not_break_uniform_204(monkeypatch):
    """메일 발송이 실패해도 `issue_login_code` 는 예외를 밖으로 던지지 않는다.

    라우터의 "계정 유무 무관 균일 204"(계정 열거 차단)는 보안 계약이다. SMTP 장애가 500 으로 새면
    계약이 깨질 뿐 아니라, 장애 구간에서 응답 코드가 갈리는 관측 채널이 생긴다.
    실패는 **서버 로그로만** 남긴다(코드 원문은 절대 로그에 남기지 않는다)."""
    from server.services import auth_code

    import server.mailer as m

    class BoomMailer:
        async def send_login_code(self, email, code):
            raise smtplib.SMTPException("relay refused")

    monkeypatch.setattr(m, "get_mailer", lambda: BoomMailer())
    monkeypatch.setattr(auth_code, "recent_unconsumed_exists", _async_false)
    monkeypatch.setattr(auth_code.database, "execute", _async_noop)

    await auth_code.issue_login_code("hong@samsung.com")  # 예외가 새면 실패


@pytest.mark.asyncio
async def test_MS3b_send_failure_never_logs_the_code(monkeypatch, caplog):
    """실패 로그에 코드 원문·이메일 원문이 남지 않는다(NFR31)."""
    import logging

    from server.services import auth_code

    import server.mailer as m

    seen: dict = {}

    class BoomMailer:
        async def send_login_code(self, email, code):
            seen["code"] = code  # 실제 발급된 원문을 여기서 포획
            # 제공자가 실패 메시지에 수신 주소를 반향하는 경우까지 흉내낸다
            raise smtplib.SMTPException(f"relay refused for {email} (code {code})")

    monkeypatch.setattr(m, "get_mailer", lambda: BoomMailer())
    monkeypatch.setattr(auth_code, "recent_unconsumed_exists", _async_false)
    monkeypatch.setattr(auth_code.database, "execute", _async_noop)

    with caplog.at_level(logging.ERROR):
        await auth_code.issue_login_code("hong@samsung.com")

    assert seen.get("code"), "테스트 하네스가 코드를 못 잡음"
    assert seen["code"] not in caplog.text, "로그에 인증 코드 원문 노출(NFR31)"
    assert "hong@samsung.com" not in caplog.text, "로그에 수신 이메일 원문 노출(NFR31)"


async def _async_false(*a, **kw):
    return False


async def _async_noop(*a, **kw):
    return 1
