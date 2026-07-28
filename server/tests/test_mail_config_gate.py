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

import re
from pathlib import Path

import pytest

# server/tests/test_mail_config_gate.py → parents[2] = 리포 루트
ROOT = Path(__file__).resolve().parents[2]

# 메일 발송 엔드포인트 2종 × prod·beta = 4개 location 블록. 이 4곳이 리밋·타임아웃·헤더 계약을
# 공유하므로, 아래 헬퍼가 "실제 conf 에서" 값을 뽑아 프론트 상수와 대조한다(하드코딩 드리프트 방지).
_MAIL_LOCATIONS = ("/api/v1/members/login-code", "/api/v1/employment/verify-code")
_NGINX_CONFS = ("infra/nginx/loupit.conf", "infra/nginx/loupit-beta.conf")


def _mail_location_bodies() -> dict[str, str]:
    """`location = <메일 엔드포인트> { ... }` 본문을 {"<conf>:<경로>": 본문} 으로 반환.

    ⚠ 이 파서의 초판은 **양방향으로 거짓말했다**(2026-07-28 적대검토에서 실측 반증). 남긴다:
      · 거짓 초록: 깊이 계산이 **주석 속 중괄호**까지 셌다. `# … { …` 처럼 짝 없는 여는 괄호가
        한 줄만 들어가면 깊이가 안 닫혀 본문이 **다음 location 을 통째로 삼킨다**. prod
        `login-code` 에서 `add_header Retry-After …` 를 지우고 그런 주석을 넣었더니, 삼킨
        `verify-code` 의 헤더가 어서션을 대신 만족시켜 **MG-9 가 통과**했다(재현 확인).
        같은 방식으로 `proxy_read_timeout` 삭제도 이웃 값에 가려져 MG-6·MG-8 이 거짓 통과했다.
      · 거짓 빨강: `^\\s*` 의 `\\s` 가 **개행을 먹어** 매치 시작이 앞 빈 줄로 밀리고, 그러면
        `len(body) > 1` 브레이크가 블록에 진입하기도 전에 발동해 본문이 1~2줄로 잘렸다.
        `location =  /x` (공백 2칸)·`{` 를 다음 줄에 두는 등 nginx 가 정상으로 받는 포맷도
        "블록이 없다 = 계약이 사라졌다"로 릴리스를 멈췄다.
    → 그래서 (a) 개행을 안 먹는 `[ \\t]*` 와 유연한 공백, (b) **주석 제거 후** 깊이 계산,
      (c) "깊이가 1 이상 올라갔다가 0 으로 복귀"를 종료 조건으로, (d) 본문이 이웃 `location` 을
      삼켰으면 조용히 통과시키지 말고 **즉시 실패**시킨다."""
    out: dict[str, str] = {}
    for conf in _NGINX_CONFS:
        text = (ROOT / conf).read_text(encoding="utf-8")
        for loc in _MAIL_LOCATIONS:
            m = re.search(rf"^[ \t]*location[ \t]*=[ \t]*{re.escape(loc)}[ \t]*\{{[ \t]*$", text, re.M)
            assert m, (
                f"{conf} 에서 `location = {loc}` 를 찾지 못했다 — 계약이 삭제됐거나 "
                f"conf 포맷이 이 파서의 기대(한 줄 `location = <경로> {{`)와 다르다"
            )
            depth, opened, body = 0, False, []
            for line in text[m.start():].splitlines():
                body.append(line)
                code = line.split("#", 1)[0]  # 주석 속 중괄호는 세지 않는다(문자열 안 `#` 은
                depth += code.count("{") - code.count("}")  # 조기 절단 → 시끄럽게 실패하는 쪽)
                if depth > 0:
                    opened = True
                elif opened:
                    break
            assert opened and depth == 0, f"{conf}:{loc} 블록의 중괄호가 닫히지 않았다"
            joined = "\n".join(body)
            assert not re.search(r"^[ \t]*location\b", joined[len(body[0]):], re.M), (
                f"{conf}:{loc} 본문이 **다음 location 블록을 삼켰다** — 이웃의 지시자가 이 블록의 "
                "어서션을 대신 만족시켜 거짓 통과가 된다. conf 의 짝 없는 중괄호를 확인하라"
            )
            out[f"{conf}:{loc}"] = joined
    assert len(out) == len(_NGINX_CONFS) * len(_MAIL_LOCATIONS)
    return out


def _proxy_read_timeouts() -> dict[str, int]:
    """메일 4블록의 `proxy_read_timeout <N>s` 실측값."""
    out = {}
    for key, body in _mail_location_bodies().items():
        m = re.search(r"proxy_read_timeout\s+(\d+)s\s*;", body)
        assert m, f"{key} 에 proxy_read_timeout 이 없다"
        out[key] = int(m.group(1))
    return out


def _edge_worst_case_budgets() -> dict[str, int]:
    """메일 4블록의 **엣지 최악 예산** = `proxy_connect_timeout` + `proxy_read_timeout`(초).

    프론트 타임아웃의 기준선은 `proxy_read_timeout` 혼자가 아니다(적대검토 2026-07-28 정정) —
    업스트림 연결이 늦으면 connect 예산이 먼저 소진되고 그 뒤에 read 예산이 시작된다."""
    out = {}
    for key, body in _mail_location_bodies().items():
        c = re.search(r"proxy_connect_timeout\s+(\d+)s\s*;", body)
        r = re.search(r"proxy_read_timeout\s+(\d+)s\s*;", body)
        assert c and r, f"{key} 에 proxy_connect_timeout·proxy_read_timeout 이 모두 있어야 한다"
        out[key] = int(c.group(1)) + int(r.group(1))
    return out


def _strip_js_line_comments(src: str) -> str:
    """`//` 줄 주석 제거. 가드가 **주석 속 단어**로 만족되는 거짓 초록을 막는다.

    (URL 의 `//` 까지 자르지만 이 파일 검사엔 무해하고, 자르는 방향은 항상 '더 엄격'이다.)"""
    return "\n".join(line.split("//", 1)[0] for line in src.splitlines())


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
    # 위 15 는 하드코딩이라 conf 가 바뀌면 조용히 거짓이 된다 → 실제 값과 대조한다.
    actual = _proxy_read_timeouts()
    assert set(actual.values()) == {NGINX_PROXY_READ_TIMEOUT}, (
        f"nginx proxy_read_timeout 이 {NGINX_PROXY_READ_TIMEOUT}s 가정과 다르다: {actual}"
    )


# ── 프론트 abort 가 엣지보다 먼저 끊지 않는가(적대검토 ⑤) ────────────────────────
def test_MG8_frontend_mail_timeout_exceeds_nginx_read_timeout():
    """`api.js` 의 메일 전용 타임아웃이 nginx `proxy_read_timeout` 보다 **길다**.

    짧으면 제공자가 느릴 때 **서버가 정상 204 를 만드는 도중 브라우저가 먼저 abort** 한다 →
    화면엔 "네트워크 오류예요"가 뜨는데 메일은 실제로 나갔고, 재클릭해도 앱 쿨다운 60초에 막혀
    아무 일도 안 일어난다(사용자는 로그인 불가로 체감). 구 판본이 정확히 이 상태였다:
    프론트 `DEFAULT_TIMEOUT=8000` = SMTP `_SMTP_TIMEOUT_SEC=8` — 그런데 smtplib timeout 은
    대화 전체가 아니라 **개별 소켓 연산** 상한이라 총 소요가 8s 를 넘는 것이 정상 범위다.

    ⚠ MG-6 과 방향이 반대다(헷갈리기 쉬움): **SMTP < nginx < 프론트**.
      SMTP 는 엣지보다 먼저 끝나야 하고(504 방지), 프론트는 엣지보다 늦게 끊어야 한다(abort 방지).
    """
    # ⚠ 주석을 먼저 지운다 — 안 지우면 `// … MAIL_TIMEOUT …` 같은 **설명 문장 한 줄**만으로
    #   아래 "헬퍼가 실제로 쓰는가" 가드가 만족돼 적용이 제거돼도 초록이 된다(적대검토 지적).
    api_js = _strip_js_line_comments((ROOT / "web/assets/js/api.js").read_text(encoding="utf-8"))
    m = re.search(r"const MAIL_TIMEOUT\s*=\s*(\d+)\s*;", api_js)
    assert m, "api.js 에 MAIL_TIMEOUT 상수가 없다 — 메일 호출이 기본 8s 로 되돌아갔을 수 있다"
    mail_timeout_sec = int(m.group(1)) / 1000

    for key, edge in _edge_worst_case_budgets().items():
        assert mail_timeout_sec > edge, (
            f"{key}: 프론트 메일 타임아웃 {mail_timeout_sec}s 가 엣지 최악 예산 {edge}s"
            "(connect+read) 이하 — 브라우저가 먼저 abort 해 '네트워크 오류'로 오인된다"
        )

    # 메일 2종에만 적용됐는가(전역 상향이 아님) — 전역이면 읽기 경로 오류 감지까지 늘어진다.
    assert re.search(r"const DEFAULT_TIMEOUT\s*=\s*8000\s*;", api_js), (
        "DEFAULT_TIMEOUT 이 8000 이 아니다 — 메일 전용 상향이 전역 상향으로 번졌는지 확인하라"
    )
    # 실제 **호출 인자**로 넘기는지 본다: `apiSend(...{ timeout: MAIL_TIMEOUT })` 형태.
    for helper, path in (("requestLoginCode", "/members/login-code"),
                         ("requestEmployCode", "/employment/verify-code")):
        m = re.search(rf"{helper}\s*=[^;]*?{re.escape(path)}[^;]*?\{{\s*timeout:\s*MAIL_TIMEOUT\s*\}}",
                      api_js, re.S)
        assert m, f"{helper} 가 `{{ timeout: MAIL_TIMEOUT }}` 을 apiSend 인자로 넘기지 않는다"
    # 메일이 **아닌** 헬퍼가 이 상수를 가져다 쓰면 위 '전역 아님' 주장이 무너진다.
    assert len(re.findall(r"MAIL_TIMEOUT", api_js)) == 3, (  # 정의 1 + 사용 2
        f"MAIL_TIMEOUT 등장 횟수가 3(정의1+사용2)이 아니다: {len(re.findall(r'MAIL_TIMEOUT', api_js))}"
    )


# ── 429 에 재시도 대기(Retry-After)가 실리는가(적대검토 ③) ───────────────────────
def test_MG9_mail_429_carries_retry_after_in_all_four_blocks():
    """메일 4블록 전부가 `Retry-After` 를 싣고, 그 값이 `map $status` 조건부인가.

    실측(2026-07-28 격리 하네스, nginx 1.18.0)이 셋을 갈랐다:
      · 정적 `add_header Retry-After 20 always` → **성공 204 에도 붙는다**(오도)
      · `map` 인데 `always` 누락            → 429 에 **안 붙는다**(429 는 에러 응답)
      · `map` + `always`                    → 204·403 미부착, 429 만 부착 ✓
    한 블록이라도 빠지면 같은 공유 버킷(`loupit_mail`)의 429 인데 안내가 갈린다."""
    for key, body in _mail_location_bodies().items():
        assert re.search(r"add_header\s+Retry-After\s+\$loupit_retry_after\s+always\s*;", body), (
            f"{key} 에 `add_header Retry-After $loupit_retry_after always;` 가 없다"
        )

    limits = (ROOT / "infra/nginx/loupit-limits.conf").read_text(encoding="utf-8")
    m = re.search(r"map\s+\$status\s+\$loupit_retry_after\s*\{(.*?)\}", limits, re.S)
    assert m, "conf.d/loupit-limits.conf 에 map $status $loupit_retry_after 가 없다(nginx -t 가 실패한다)"
    block = m.group(1)
    assert re.search(r"^\s*429\s+20\s*;", block, re.M), "429 → 20 매핑이 없다(rate=3r/m → 토큰 1개 20초)"
    assert re.search(r'^\s*default\s+""\s*;', block, re.M), (
        'default 가 "" 가 아니다 — 빈 값이라야 429 아닌 응답에 헤더가 붙지 않는다'
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
