#!/usr/bin/env python3
"""메일 설정 검증기 — 앱을 거치지 않고 호스트별 메일 경로를 단계별로 확인한다.

사용법(리포 루트에서):
    python3 infra/deploy/verify_mail.py                  # prod: smtp 기대 + 연결·인증(발송 없음)
    python3 infra/deploy/verify_mail.py you@example.com  # 위 + 실제 테스트 메일 1통 발송
    sudo python3 infra/deploy/verify_mail.py --host beta # beta: **console 기대**(실발송하면 실패)

**왜 호스트 인자가 필요한가**(2026-07-29, P3-② ): 구 판본은 `server/.env` 만 읽고
`mailer_mode != 'smtp'` 를 실패로 봤다. 그래서 "베타는 실발송하면 **안 된다**"라는 반대 방향
불변식을 **표현할 수조차 없었다** — 베타가 prod 자격증명을 상속해 prod 발신 도메인과 무료 티어
쿼터를 쓰고 있었는데도 이 검증기는 초록이었다. 기대값을 호스트가 소유하게 바꾼다.

**유효 설정을 런타임과 같은 방식으로 합성한다**: systemd `EnvironmentFile` 이 프로세스 env 를
채우고, pydantic 이 그 위에서 `server/.env` 를 폴백으로 읽는다. 그래서 대상 호스트의
EnvironmentFile 을 os.environ 에 먼저 얹은 뒤 `Settings()` 를 만든다 — `.env.beta` 만 읽으면
"상속으로 채워지는 값"을 놓쳐 지금 고치려는 결함을 그대로 못 본다.

비밀번호는 어떤 경우에도 출력하지 않는다.
"""
from __future__ import annotations

import os
import re
import smtplib
import ssl
import sys
import time
from email.message import EmailMessage
from pathlib import Path

sys.path.insert(0, "/home/ubuntu/loupit")

ROOT = Path("/home/ubuntu/loupit")

# 호스트별 기대 메일 모드. **이 표가 정책이다** — 값이 아니라 의도를 적는다.
#   prod : 실사용자 로그인 코드를 보내는 유일한 호스트 → smtp 필수
#   beta : 실발송 금지. prod 발신 도메인·무료 티어 쿼터를 나눠 쓰면 안 된다(P3-②)
HOSTS = {
    "prod": {"env_file": None, "expect": "smtp"},
    "beta": {"env_file": ROOT / "server" / ".env.beta", "expect": "console"},
}

_ENV_LINE = re.compile(r"^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$")


def load_environment_file(path: Path) -> dict[str, str]:
    """systemd EnvironmentFile 을 프로세스 env 로 얹는 것과 같게 해석한다(주석·빈 줄 무시)."""
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = _ENV_LINE.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip("'\"")
    return out


def ok(m):
    print(f"  \033[32m✓\033[0m {m}")


def bad(m):
    print(f"  \033[31m✗\033[0m {m}")


def info(m):
    print(f"    {m}")


def main() -> int:
    argv = sys.argv[1:]
    host = "prod"
    if "--host" in argv:
        i = argv.index("--host")
        host = argv[i + 1] if i + 1 < len(argv) else ""
        del argv[i:i + 2]
    if host not in HOSTS:
        bad(f"--host 는 {sorted(HOSTS)} 중 하나여야 한다 (받은 값: {host!r})")
        return 2
    expect = HOSTS[host]["expect"]
    env_file = HOSTS[host]["env_file"]
    to = argv[0] if argv else None

    print(f"\n[1] 설정 로드 (호스트={host}, 기대 mailer_mode={expect!r})")
    if env_file is not None:
        try:
            overlay = load_environment_file(env_file)
        except PermissionError:
            bad(f"{env_file} 를 읽을 수 없다 — `sudo` 로 실행하라(EnvironmentFile 은 root 소유 600)")
            return 2
        info(f"EnvironmentFile {env_file} → {len(overlay)}개 키를 프로세스 env 로 얹음")
        os.environ.update(overlay)

    from server.config import Settings

    s = Settings()
    for k in ("mailer_mode", "smtp_host", "smtp_port", "smtp_user", "smtp_from"):
        info(f"{k:12s} = {getattr(s, k)!r}")
    info(f"{'smtp_pass':12s} = {'설정됨(' + str(len(s.smtp_pass)) + '자)' if s.smtp_pass else '비어있음'}")

    if s.mailer_mode != expect:
        if expect == "smtp":
            bad(f"mailer_mode={s.mailer_mode!r} — 실발송하려면 'smtp' 여야 한다(지금은 코드가 로그로 나감)")
        else:
            # 반대 방향 어서션. 이게 없으면 "베타가 prod 자격증명을 상속했다"를 초록으로 지나친다.
            bad(
                f"mailer_mode={s.mailer_mode!r} — {host} 는 {expect!r} 여야 한다. "
                f"{env_file} 에 MAILER_MODE 가 없어 prod 의 server/.env 를 상속했을 가능성이 크다 "
                "→ prod 발신 도메인·무료 티어 쿼터를 나눠 쓰게 된다(P3-②)."
            )
        return 1
    ok(f"mailer_mode={s.mailer_mode}")

    print("\n[2] get_mailer() fail-closed 검사")
    try:
        from server.mailer import ConsoleMailer, SmtpMailer, get_mailer

        want = SmtpMailer if expect == "smtp" else ConsoleMailer
        m = get_mailer()
        if not isinstance(m, want):
            bad(f"{want.__name__} 가 아님: {type(m).__name__}")
            return 1
        ok(f"{want.__name__} 선택됨" + (f" (From={m._from!r})" if isinstance(m, SmtpMailer) else ""))
    except RuntimeError as e:
        bad(f"설정 거부됨: {e}")
        return 1

    if expect != "smtp":
        # 여기서 끝낸다 — SMTP 연결·인증·발송은 실발송 호스트에만 의미가 있다.
        print(f"\n{host} 는 실발송 호스트가 아니다. SMTP 연결 검사는 건너뛴다.")
        if to:
            bad(f"{host} 에 발송 대상({to})을 준 것은 모순이다 — 이 호스트는 메일을 보내지 않는다.")
            return 1
        ok(f"{host} 메일 설정 정상 — 실발송 경로 없음(prod 쿼터·평판과 분리)")
        return 0

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
        # 서비스명은 mailer 에서 가져온다 — 여기 하드코딩하면 또 갈라진다(2026-07-28).
        from server.mailer import SERVICE_NAME

        msg["Subject"] = f"[{SERVICE_NAME}] 메일 설정 테스트"
        msg.set_content(
            f"{SERVICE_NAME} 메일 발송 경로 검증용 테스트입니다.\n"
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
