#!/usr/bin/env python3
"""SMTP 설정 검증기 — 앱을 거치지 않고 메일 경로만 단계별로 확인한다.

사용법(리포 루트에서):
    python3 infra/deploy/verify_mail.py                 # 설정·연결·인증까지만(발송 없음)
    python3 infra/deploy/verify_mail.py you@example.com # 위 + 실제 테스트 메일 1통 발송

`server/.env` 를 그대로 읽으므로, 앱이 보게 될 설정과 정확히 같은 값을 검증한다.
비밀번호는 어떤 경우에도 출력하지 않는다.
"""
from __future__ import annotations

import smtplib
import ssl
import sys
import time
from email.message import EmailMessage
from pathlib import Path

sys.path.insert(0, "/home/ubuntu/loupit")


def ok(m):
    print(f"  \033[32m✓\033[0m {m}")


def bad(m):
    print(f"  \033[31m✗\033[0m {m}")


def info(m):
    print(f"    {m}")


def main() -> int:
    to = sys.argv[1] if len(sys.argv) > 1 else None

    print("\n[1] 설정 로드 (server/.env)")
    from server.config import Settings

    s = Settings()
    for k in ("mailer_mode", "smtp_host", "smtp_port", "smtp_user", "smtp_from"):
        info(f"{k:12s} = {getattr(s, k)!r}")
    info(f"{'smtp_pass':12s} = {'설정됨(' + str(len(s.smtp_pass)) + '자)' if s.smtp_pass else '비어있음'}")

    if s.mailer_mode != "smtp":
        bad(f"mailer_mode={s.mailer_mode!r} — 실발송하려면 'smtp' 여야 한다(지금은 코드가 로그로 나감)")
        return 1
    ok("mailer_mode=smtp")

    print("\n[2] get_mailer() fail-closed 검사")
    try:
        from server.mailer import SmtpMailer, get_mailer

        m = get_mailer()
        if not isinstance(m, SmtpMailer):
            bad(f"SmtpMailer 가 아님: {type(m).__name__}")
            return 1
        ok(f"SmtpMailer 선택됨 (From={m._from!r})")
    except RuntimeError as e:
        bad(f"설정 거부됨: {e}")
        return 1

    print(f"\n[3] TCP 연결 → {s.smtp_host}:{s.smtp_port}")
    t0 = time.time()
    try:
        conn = smtplib.SMTP(s.smtp_host, s.smtp_port, timeout=15)
    except Exception as e:
        bad(f"연결 실패: {type(e).__name__}: {e}")
        info("587 이 막혔거나 호스트명이 틀렸을 수 있다.")
        return 1
    ok(f"연결됨 ({time.time()-t0:.1f}s)")

    with conn:
        print("\n[4] STARTTLS (인증서 검증 포함)")
        try:
            conn.starttls(context=ssl.create_default_context())
            ok("TLS 수립·인증서 검증 통과")
        except ssl.SSLCertVerificationError as e:
            bad(f"인증서 검증 실패: {e}")
            return 1
        except Exception as e:
            bad(f"STARTTLS 실패: {type(e).__name__}: {e}")
            return 1

        print("\n[5] SMTP AUTH")
        try:
            conn.login(s.smtp_user, s.smtp_pass)
            ok(f"인증 성공 (user={s.smtp_user!r})")
        except smtplib.SMTPAuthenticationError as e:
            bad(f"인증 거부: {e.smtp_code} {e.smtp_error!r}")
            info("API 키가 틀렸거나 SMTP_USER 가 제공자 규격과 다르다.")
            return 1
        except Exception as e:
            bad(f"인증 실패: {type(e).__name__}: {e}")
            return 1

        if not to:
            print("\n[6] 발송 생략 — 수신 주소를 인자로 주면 실제로 1통 보낸다.")
            print("\n\033[32m설정·연결·인증까지 정상.\033[0m\n")
            return 0

        print(f"\n[6] 테스트 발송 → {to}")
        msg = EmailMessage()
        msg["From"] = m._from
        msg["To"] = to
        msg["Subject"] = "[loupit] 메일 설정 테스트"
        msg.set_content(
            "loupit 메일 발송 경로 검증용 테스트입니다.\n"
            "이 메일이 도착했다면 SMTP 설정이 정상입니다.\n\n"
            "※ 스팸함에 있었다면 SPF/DKIM/DMARC DNS 레코드를 확인하세요."
        )
        try:
            refused = conn.send_message(msg)
            if refused:
                bad(f"일부 수신자 거부: {refused}")
                return 1
            ok("발송 수락됨(제공자가 큐에 넣음)")
        except Exception as e:
            bad(f"발송 실패: {type(e).__name__}: {e}")
            return 1

    print("\n\033[32m전 단계 통과.\033[0m 수신함(+스팸함)을 확인하세요.")
    print("기업 도메인(@samsung.com 등)에도 별도로 보내볼 것 — 게이트웨이가 더 엄격하다.\n")
    return 0


if __name__ == "__main__":
    if not Path("/home/ubuntu/loupit/server/.env").exists():
        bad("server/.env 없음")
        sys.exit(1)
    sys.exit(main())
