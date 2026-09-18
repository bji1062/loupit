"""SP-AUTH-19.8 관리 호스트(admin.jobcho.wiki) 관문 — 판정 매트릭스 + nginx 전제 + 비밀 부재 (AH-1~AH-15).

**이 파일이 지키는 것은 "콘솔의 두 번째 입구가 본 사이트의 뒷문이 되지 않는가"다.**

관리 호스트는 세 조각이 맞물려야 안전하다. 하나라도 어긋나면 콘솔이 인터넷에 열린다:

1. **앱 판정**(`deps.admin_gate_open`) — Host 가 정확히 관리 호스트이고, 게이트 헤더가 비밀과 같을 때만.
   비밀이 비었거나 짧으면 닫힌다. AH-1~AH-6.
2. **nginx 전제** — 관리 vhost 만 **비밀번호 뒤에서** 게이트 헤더를 붙이고, 본 사이트·베타의 모든
   proxy_pass 블록은 그 헤더를 **지운다.** 앱은 이 사실을 볼 수 없으므로 conf 를 직접 읽어 검사한다.
   **전제를 검사하지 않는 보안 판정은 가정이다**(CO-11 과 같은 원칙). AH-7~AH-12.
3. **비밀 부재** — 비밀 값은 서버의 nginx 스니펫과 `server/.env` 두 곳에만 있다. 리포에 한 번이라도
   커밋되면 git 이력에서 지울 수 없다. AH-13·AH-14.

실 DB 가 필요한 세션 축(비운영자 404 · 운영자 200)은 `test_console_views_db.py` CV-1 이 잰다.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path
from types import SimpleNamespace

import httpx
import pytest
import pytest_asyncio
from fastapi import HTTPException

from server import deps

ROOT = Path(__file__).resolve().parents[2]
NGINX = ROOT / "infra" / "nginx"
ADMIN_CONF = "loupit-admin.conf"                     # 비밀번호 뒤에서 게이트 헤더를 **붙이는** 쪽
# 게이트 헤더를 **지워야** 하는 쪽 = 앱으로 프록시하는 나머지 vhost **전부**. 목록을 손으로 적으면 새 vhost 가
# 검사 밖으로 빠진다(2026-09-18 적대 검토) — proxy_pass 가 있는 conf 를 디렉터리에서 모은다.
PROXY_CONFS = sorted(
    p.name for p in NGINX.glob("*.conf")
    if any(ln.split("#", 1)[0].strip().startswith("proxy_pass") for ln in p.read_text(encoding="utf-8").splitlines())
)
PUBLIC_CONFS = tuple(c for c in PROXY_CONFS if c != ADMIN_CONF)
GATE_SNIPPET = "/etc/nginx/snippets/loupit-admin-gate.conf"

SECRET = "s" * 24 + "0123456789abcdef0123456789abcdef"   # 56자 — 테스트 전용 가짜 값
HOST = "admin.jobcho.wiki"


def _cfg(host: str = HOST, secret: str = SECRET):
    return SimpleNamespace(admin_host=host, admin_gate_secret=secret)


def _via_admin(host: str = HOST, gate: str | None = SECRET, **extra) -> dict:
    """관리 vhost 를 거친 요청의 헤더 모양 — nginx 가 붙이는 프록시 표식 + Host + 게이트 헤더."""
    h = {"x-real-ip": "203.0.113.7", "x-forwarded-for": "203.0.113.7", "x-forwarded-proto": "https",
         "host": host}
    if gate is not None:
        h["x-loupit-admin-gate"] = gate
    h.update(extra)
    return h


# ── AH-1~6: 앱 판정 매트릭스 (순수 함수) ──────────────────────────────────────

def test_AH1_맞는_호스트와_맞는_비밀이면_열린다():
    assert deps.admin_gate_open(_via_admin(), _cfg()) is True


@pytest.mark.parametrize("secret", ["", "   ", "x" * 31, "__ADMIN_GATE_SECRET__"])
def test_AH2_비밀이_비었거나_32자_미만이면_닫힌다(secret):
    """짧은 비밀은 설정 실수의 신호다 — 자리 표시자를 그대로 옮긴 경우까지 **닫힘**으로 본다.

    헤더가 그 짧은 값과 **정확히 같아도** 닫혀야 한다(비교 전에 길이로 끊는다)."""
    assert deps.admin_gate_open(_via_admin(gate=secret), _cfg(secret=secret)) is False


@pytest.mark.parametrize("host_cfg", ["", "  ", "admin.jobcho.wiki:443", "https://admin.jobcho.wiki",
                                      "admin.jobcho.wiki/console"])
def test_AH3_관리_호스트_설정이_비었거나_호스트명이_아니면_닫힌다(host_cfg):
    """포트·스킴·경로가 섞인 설정은 **맞춰 주지 않는다** — nginx `$host` 에는 포트가 없어 어차피 영원히
    안 맞는다. 조용히 안 맞는 것보다 닫힘으로 드러나는 쪽이 낫다."""
    assert deps.admin_gate_open(_via_admin(host="admin.jobcho.wiki"), _cfg(host=host_cfg)) is False


def test_AH4_Host_대소문자는_무시하고_포트가_붙으면_불일치다():
    """DNS 이름은 대소문자를 가리지 않고 nginx `$host` 는 이미 소문자다 → 대소문자 차이는 같은 호스트.
    포트가 붙은 Host 는 관리 vhost(`proxy_set_header Host $host` — 포트 없음)를 거치지 않았다는 뜻이다."""
    assert deps.admin_gate_open(_via_admin(host="ADMIN.Jobcho.Wiki"), _cfg()) is True
    assert deps.admin_gate_open(_via_admin(), _cfg(host="  Admin.JOBCHO.wiki ")) is True  # 설정값도 정규화
    assert deps.admin_gate_open(_via_admin(host="admin.jobcho.wiki:443"), _cfg()) is False
    assert deps.admin_gate_open(_via_admin(host="admin.jobcho.wiki."), _cfg()) is False     # 끝 점도 다른 이름
    assert deps.admin_gate_open(_via_admin(host="evil-admin.jobcho.wiki"), _cfg()) is False


def test_AH5_본_호스트로는_비밀을_알아도_통과하지_못한다():
    """비밀이 새더라도 본 사이트는 뒷문이 되지 않는다 — Host 조건이 따로 걸려 있다.
    (게다가 본 사이트 nginx 는 게이트 헤더를 지운다 — AH-7. 두 조건을 **따로** 깨야 한다.)"""
    for host in ("jobcho.wiki", "www.jobcho.wiki", "beta.loupit.co", "127.0.0.1:8000", ""):
        assert deps.admin_gate_open(_via_admin(host=host), _cfg()) is False, host


@pytest.mark.parametrize("gate", [None, "", SECRET[:-1], SECRET + "x", SECRET.upper(), " " + SECRET])
def test_AH6_게이트_헤더가_없거나_틀리면_닫힌다(gate):
    """비밀번호를 넘지 못한 요청에는 관리 vhost 가 헤더를 붙이지 않는다(= 헤더 없음).
    값은 **정확히** 같아야 한다 — 앞뒤 공백·대소문자·한 글자 차이 전부 불일치."""
    assert deps.admin_gate_open(_via_admin(gate=gate), _cfg()) is False


class _Req:
    def __init__(self, headers: dict):
        self.headers = headers


@pytest.mark.asyncio
async def test_AH6b_관문_매트릭스_터널_본호스트_관리호스트(monkeypatch):
    """`require_console_access` 한 함수의 전체 매트릭스 — 브리프의 관문 표를 그대로 옮긴 것이다.

    | 입구                                   | 결과 |
    | 터널(프록시 헤더 없음)                   | 통과 |
    | 본 호스트 경유(+ 비밀을 안다 해도)        | 404  |
    | 관리 호스트 + 비밀 없음/틀림/짧은 설정값   | 404  |
    | 관리 호스트 + 맞는 비밀                   | 통과 (→ 다음 관문: 세션·운영자 — CV-1)
    """
    from server.config import get_settings

    s = get_settings()
    monkeypatch.setattr(s, "admin_host", HOST)
    monkeypatch.setattr(s, "admin_gate_secret", SECRET)

    assert await deps.require_console_access(_Req({"host": "127.0.0.1:8000"})) is None   # 터널
    assert await deps.require_console_access(_Req(_via_admin())) is None                  # 관리 호스트

    for bad in (_via_admin(host="jobcho.wiki"), _via_admin(gate=None), _via_admin(gate="wrong" * 10)):
        with pytest.raises(HTTPException) as exc:
            await deps.require_console_access(_Req(bad))
        assert exc.value.status_code == 404, "403·401 이 아니라 404 — 존재 자체를 알리지 않는다"

    monkeypatch.setattr(s, "admin_gate_secret", "short-secret")  # 짧은 설정값 = 닫힘
    with pytest.raises(HTTPException) as exc:
        await deps.require_console_access(_Req(_via_admin(gate="short-secret")))
    assert exc.value.status_code == 404
    assert await deps.require_console_access(_Req({"host": "127.0.0.1:8000"})) is None   # 터널은 그대로


@pytest.mark.asyncio
async def test_AH6c_설정이_없으면_옛_터널_전용_관문과_같다(monkeypatch):
    """기본값(둘 다 빈 값)에서의 동작 = 옛 `require_loopback` 과 **정확히** 같아야 한다 —
    배포 순서상 앱이 먼저 나가고 설정은 나중에 들어간다. 그 사이에 표면이 바뀌면 안 된다."""
    from server.config import Settings, get_settings

    assert Settings.model_fields["admin_host"].default == ""
    assert deps._secret_value(Settings.model_fields["admin_gate_secret"].default) == ""
    # 비밀은 SecretStr — 설정 객체를 repr·로그로 찍어도 값이 나오지 않는다.
    shown = repr(Settings(_env_file=None, admin_gate_secret="z" * 40))
    assert "z" * 40 not in shown
    s = get_settings()
    monkeypatch.setattr(s, "admin_host", "")
    monkeypatch.setattr(s, "admin_gate_secret", "")
    assert await deps.require_console_access(_Req({"host": "127.0.0.1:8000"})) is None
    with pytest.raises(HTTPException):
        await deps.require_console_access(_Req(_via_admin(gate="")))


# ── nginx conf 파서 — 주석을 벗기고 중괄호 깊이로 블록을 자른다 ────────────────────────
#
# test_mail_config_gate 의 교훈(주석 속 중괄호가 깊이를 망쳐 이웃 블록을 삼키고 거짓 통과)을 따른다:
# 주석을 **먼저** 지운 뒤 센다. 여기서는 "proxy_pass 가 든 모든 location" 을 빠짐없이 모아야 하므로
# 이름 하나를 찾는 파서가 아니라 전체를 훑는 파서다.

def _strip_comments(text: str) -> list[str]:
    return [ln.split("#", 1)[0].rstrip() for ln in text.splitlines()]


def _blocks(conf: str) -> list[dict]:
    """conf 의 모든 `server`·`location` 블록 → [{kind, head, start, end, server, body}].

    중괄호를 **글자 단위**로 따라가며 스택으로 짝을 맞춘다 — 한 줄짜리 `location = /x { … }` 와
    블록 안의 `if (…) { return 403; }` 가 섞여도 깊이가 어긋나지 않는다. 본문은 주석 제거본이다.
    `server` 는 파일 안 순번(0부터), location 은 자기를 감싼 server 의 순번을 갖는다."""
    lines = _strip_comments((NGINX / conf).read_text(encoding="utf-8"))
    found, stack, server_i = [], [], -1
    for i, ln in enumerate(lines):
        pos = 0
        for m in re.finditer(r"[{}]", ln):
            if m.group() == "{":
                head = re.match(r"^\s*(server|location)\b(.*)$", ln[pos:m.start()])
                kind = head.group(1) if head else "other"
                if kind == "server":
                    server_i += 1
                stack.append({"kind": kind, "head": head.group(2).strip() if head else "", "start": i,
                              "server": server_i})
            else:
                assert stack, f"{conf}:{i + 1} 짝 없는 '}}' — 파서가 conf 를 잘못 읽었다"
                blk = stack.pop()
                blk["end"] = i
                found.append(blk)
            pos = m.end()
    assert not stack, f"{conf}: 닫히지 않은 블록이 있다 — 파서가 conf 를 잘못 읽었다"
    out = [b for b in found if b["kind"] in ("server", "location")]
    for b in out:
        b["body"] = "\n".join(lines[b["start"]: b["end"] + 1])
    return sorted(out, key=lambda b: b["start"])


def _server_top_level(conf: str, server: dict) -> str:
    """server 블록에서 location 본문을 뺀 줄들 = server 레벨 지시자."""
    covered = set()
    for loc in _blocks(conf):
        if loc["kind"] == "location" and server["start"] < loc["start"] <= server["end"]:
            covered.update(range(loc["start"], loc["end"] + 1))
    lines = server["body"].splitlines()
    return "\n".join(ln for k, ln in enumerate(lines, start=server["start"]) if k not in covered)


def _https_server(conf: str) -> dict:
    https = [b for b in _blocks(conf) if b["kind"] == "server" and re.search(r"^\s*listen\s+443\s+ssl", b["body"], re.M)]
    assert len(https) == 1, f"{conf} 에 443 server 블록이 정확히 하나여야 한다"
    return https[0]


def _proxy_locations(conf: str) -> list[dict]:
    locs = [b for b in _blocks(conf) if b["kind"] == "location" and re.search(r"^\s*proxy_pass\s", b["body"], re.M)]
    assert locs, f"{conf} 에서 proxy_pass location 을 하나도 찾지 못했다 — 이 검사가 무력화됐다"
    return locs


def _raw_proxy_pass_count(conf: str) -> int:
    return sum(1 for ln in _strip_comments((NGINX / conf).read_text(encoding="utf-8"))
               if re.match(r"^\s*proxy_pass\s", ln))


# ── AH-7~12: nginx 전제 ─────────────────────────────────────────────────────

def test_AH7a_프록시_conf_목록이_알려진_vhost_를_전부_담는다():
    """glob 이 조용히 비면 아래 검사가 전부 공회전한다 — 알려진 셋은 반드시 잡혀야 한다."""
    assert {"loupit.conf", "loupit-beta.conf", ADMIN_CONF} <= set(PROXY_CONFS), PROXY_CONFS


@pytest.mark.parametrize("conf", PUBLIC_CONFS)
def test_AH7_본_사이트와_베타의_모든_proxy_pass_블록이_게이트_헤더를_지운다(conf):
    """클라이언트가 보낸 `X-Loupit-Admin-Gate` 가 앱에 닿으면, 앱의 판정은 Host 조건 하나에만 기대게 된다.
    nginx 의 `proxy_set_header X "";` 는 그 헤더를 업스트림으로 **보내지 않는다**(실측 2026-09-18,
    격리 nginx 1.18 + 에코 업스트림 — 위조 헤더가 사라짐을 확인)."""
    locs = _proxy_locations(conf)
    assert len(locs) == _raw_proxy_pass_count(conf), (
        f"{conf}: location 밖(또는 파서가 못 본 곳)에 proxy_pass 가 있다 — 모든 블록을 검사하지 못한다"
    )
    for b in locs:
        assert re.search(r'^\s*proxy_set_header\s+X-Loupit-Admin-Gate\s+""\s*;', b["body"], re.M), (
            f"{conf} location {b['head']} 가 게이트 헤더를 지우지 않는다 — 클라이언트 값이 앱까지 간다"
        )
        assert GATE_SNIPPET not in b["body"], f"{conf} location {b['head']} 가 **비밀**을 붙인다 — 본 사이트가 뒷문이 된다"
        assert re.search(r"^\s*proxy_set_header\s+X-Real-IP\s", b["body"], re.M), (
            f"{conf} location {b['head']} 에 X-Real-IP 가 없다 — 이 경로의 인터넷 요청이 SSH 터널로 위장한다"
        )


def test_AH8_관리_vhost_는_server_레벨_비밀번호_뒤에_있다():
    """`auth_basic` 이 server 레벨이어야 새 location 이 자동으로 잠긴다(location 마다 걸면 하나를 빠뜨리는
    날 그 경로만 열린다). 예외는 ACME 챌린지 하나 — 인증서 갱신이 비밀번호에 막히면 90일 뒤 사이트가 죽는다."""
    blocks = _blocks(ADMIN_CONF)
    top = _server_top_level(ADMIN_CONF, _https_server(ADMIN_CONF))
    assert re.search(r'^\s*auth_basic\s+"[^"]+"\s*;', top, re.M), "443 server 레벨에 auth_basic 이 없다"
    assert re.search(r"^\s*auth_basic_user_file\s+/etc/nginx/loupit-admin\.htpasswd\s*;", top, re.M), (
        "auth_basic_user_file 이 서버 전용 경로(/etc/nginx/loupit-admin.htpasswd)가 아니다"
    )
    assert re.search(r"^\s*limit_req\s+zone=loupit_admin\b", top, re.M), "server 레벨 비밀번호 추측 리밋이 없다"
    for loc in (b for b in blocks if b["kind"] == "location"):
        if re.search(r"^\s*auth_basic\s+off\s*;", loc["body"], re.M):
            assert loc["head"] == "^~ /.well-known/acme-challenge/", (
                f"ACME 외 location({loc['head']})이 비밀번호를 끈다 — 그 경로가 인터넷에 열린다"
            )
            assert "proxy_pass" not in loc["body"], "비밀번호 예외 location 이 앱으로 프록시한다"


def test_AH9_관리_vhost_의_모든_proxy_pass_블록이_비밀을_붙이고_표식을_단다():
    """관리 vhost 의 프록시 블록은 전부 ① 게이트 스니펫 include ② 프록시 표식(X-Real-IP)
    ③ Basic 인증 헤더 제거 ④ 리밋 을 갖는다.

    ②가 빠지면 최악이다: 표식 없는 요청은 **SSH 터널로 판정**돼 비밀 없이도 통과 A 로 열린다.
    ③은 실측에서 나왔다 — nginx 는 기본으로 `Authorization`(비밀번호)을 업스트림에 넘긴다.
    앱은 그 값을 쓰지 않으므로 넘길 이유가 없다(앞으로 누가 헤더를 로그에 찍는 날 비밀번호가 샌다)."""
    locs = _proxy_locations(ADMIN_CONF)
    assert len(locs) == _raw_proxy_pass_count(ADMIN_CONF)
    for b in locs:
        where = f"{ADMIN_CONF} location {b['head']}"
        assert re.search(rf"^\s*include\s+{re.escape(GATE_SNIPPET)}\s*;", b["body"], re.M), f"{where}: 게이트 스니펫 없음"
        assert not re.search(r'^\s*proxy_set_header\s+X-Loupit-Admin-Gate\s+""', b["body"], re.M), (
            f"{where}: 게이트 헤더를 지운다 — 관리 호스트가 영원히 404 다"
        )
        assert re.search(r"^\s*proxy_set_header\s+X-Real-IP\s", b["body"], re.M), f"{where}: X-Real-IP 없음"
        assert re.search(r"^\s*proxy_set_header\s+Host\s+\$host\s*;", b["body"], re.M), (
            f"{where}: Host 를 $host(포트 없는 소문자 이름)로 넘기지 않는다 — 앱의 Host 판정이 어긋난다"
        )
        assert re.search(r'^\s*proxy_set_header\s+Authorization\s+""\s*;', b["body"], re.M), (
            f"{where}: Basic 인증 헤더(비밀번호)가 앱으로 넘어간다"
        )
        assert re.search(r"^\s*limit_req\s+zone=loupit_admin\b", b["body"], re.M), f"{where}: loupit_admin 리밋 없음"
        assert re.search(r"^\s*proxy_pass\s+http://127\.0\.0\.1:8000\s*;", b["body"], re.M), (
            f"{where}: 프로덕션 API(:8000) 외의 곳으로 프록시한다"
        )


def test_AH10_관리_vhost_는_콘솔과_로그인_경로만_프록시한다():
    """관리 호스트가 본 사이트의 두 번째 입구가 되면 안 된다 — 공개 API·커뮤니티 쓰기가 여기서 열리면
    비밀번호 뒤라는 이유로 리밋·게이트가 다르게 적용되는 **새 표면**이 생긴다."""
    heads = {b["head"] for b in _proxy_locations(ADMIN_CONF)}
    assert heads == {
        "= /api/v1/console",                 # 껍데기 HTML(주소창 이동 — 헤더 게이트 면제)
        "^~ /api/v1/console/",               # 콘솔 데이터·조작
        "= /api/v1/members/login-code",      # 둘째 잠금의 입구 3종
        "= /api/v1/members/login",
        "= /api/v1/members/logout",
    }, f"관리 vhost 프록시 경로 불일치: {heads}"
    https_index = _https_server(ADMIN_CONF)["server"]
    by_head = {b["head"]: b for b in _blocks(ADMIN_CONF) if b["kind"] == "location" and b["server"] == https_index}
    assert re.search(r"try_files\s+\S+\s+=404\s*;", by_head["/"]["body"]), "나머지 경로가 (비밀번호 뒤) 404 가 아니다"
    for head in ("^~ /api/v1/console/", "= /api/v1/members/login-code", "= /api/v1/members/login",
                 "= /api/v1/members/logout"):
        assert re.search(r'if\s*\(\$http_x_loupit_client\s*=\s*""\)\s*\{\s*rewrite\s+\^\s+/__layer_a_denied\s+last;',
                         by_head[head]["body"]), (
            f"{head}: Layer A(X-Loupit-Client) 게이트가 없다 — 본 사이트보다 방어가 약하다"
        )
    assert re.search(r"try_files\s+\S+\s+=403\s*;", by_head["= /__layer_a_denied"]["body"]), (
        "Layer A 거부 location 이 비밀번호 뒤(try_files)에서 403 을 내지 않는다"
    )
    assert "http_x_loupit_client" not in by_head["= /api/v1/console"]["body"], (
        "콘솔 껍데기에 헤더 게이트가 있다 — 주소창 이동은 커스텀 헤더를 못 붙여 화면이 영원히 403 이다"
    )
    assert re.search(r"limit_req\s+zone=loupit_mail\b", by_head["= /api/v1/members/login-code"]["body"]), (
        "관리 호스트의 코드 발송이 loupit_mail 공유 버킷을 쓰지 않는다 — 메일 폭탄의 우회로가 된다"
    )


def test_AH10b_관리_vhost_는_비밀번호_전에_경로별로_다르게_답하지_않는다():
    """`return`(과 `if … return`)은 rewrite 단계라 auth_basic 보다 **먼저** 나간다. 그러면 비밀번호 없는 스캐너가
    경로마다 다른 답(302·403·404 대 401)을 받아 호스트 구조를 그린다(2026-09-18 적대 검토 실측).
    443 server 의 location 은 `return` 을 쓰지 않고 `try_files`(access 뒤)로만 답을 고른다 — 예외는
    try_files 가 넘겨주는 **이름 있는 location**(@…, 비밀번호를 이미 넘은 뒤에만 닿는다)뿐이다.
    격리 nginx 실측: 비밀번호 없는 요청 8경로 전부 401."""
    srv = _https_server(ADMIN_CONF)
    top = _server_top_level(ADMIN_CONF, srv)
    assert not re.search(r"\breturn\b", top), (
        "443 server 레벨에 return 이 있다(봇 UA 차단 등) — 모든 location 보다 먼저, 비밀번호 전에 답한다"
    )
    for b in _blocks(ADMIN_CONF):
        if b["kind"] != "location" or b["server"] != srv["server"] or b["head"].startswith("@"):
            continue
        assert not re.search(r"\breturn\b", b["body"]), (
            f"location {b['head']} 이 비밀번호 검사 전에 답한다(return) — try_files 로 미뤄라"
        )


def test_AH11_관리_vhost_는_색인되지_않고_보안_헤더를_싣는다():
    snippet = (NGINX / "snippets" / "loupit-admin-security.conf").read_text(encoding="utf-8")
    assert re.search(r'add_header\s+X-Robots-Tag\s+"noindex, nofollow"\s+always\s*;', snippet)
    assert re.search(r'add_header\s+X-Frame-Options\s+"DENY"\s+always\s*;', snippet)
    assert re.search(r"add_header\s+Strict-Transport-Security\s", snippet)
    # add_header 는 location 에 자체 add_header 가 있으면 상속되지 않는다 → add_header 를 가진(또는
    # 무언가를 응답하는) location 은 전부 스니펫을 직접 include 해야 한다. ACME 는 add_header 가 없어 상속.
    https_index = _https_server(ADMIN_CONF)["server"]
    for b in _blocks(ADMIN_CONF):
        if b["kind"] != "location" or b["server"] != https_index:
            continue
        if b["head"] == "^~ /.well-known/acme-challenge/":
            assert "add_header" not in b["body"], "ACME location 에 add_header 가 생기면 보안 헤더 상속이 끊긴다"
            continue
        assert "loupit-admin-security.conf" in b["body"], f"location {b['head']} 에 보안·noindex 헤더가 없다"


def test_AH12_관리_리밋_존이_정의돼_있다():
    limits = (NGINX / "loupit-limits.conf").read_text(encoding="utf-8")
    assert re.search(r"^limit_req_zone\s+\$binary_remote_addr\s+zone=loupit_admin:\d+m\s+rate=\d+r/m\s*;",
                     limits, re.M), "loupit_admin 존 정의가 없다 — 관리 vhost 가 nginx -t 에서 실패한다"


# ── AH-13·14: 비밀 부재 ─────────────────────────────────────────────────────

_SECRETISH = re.compile(r"[A-Za-z0-9_\-+/=.]{32,}")
_PLACEHOLDER = re.compile(r"^__[A-Z_]+__$")


def _repo_text_files() -> list[Path]:
    """작업 트리 전체 — `git ls-files -co --exclude-standard` 가 기준이다(2026-09-18 적대 검토 M2).

    - 포함: 추적 파일 + **아직 커밋 안 된 새 파일**. 추적 파일만 보면 커밋 직전의 새 파일 — 바로 비밀이
      들어가기 쉬운 문서·conf — 을 못 본다.
    - 제외: git 이 **무시하는** 파일만(.gitignore · .git/info/exclude · 전역 excludesFile). 대표가 `server/.env`
      — 비밀이 **있어야 하는** 곳이라 여기서 찾으면 안 된다. 그리고 무시 파일은 커밋될 수 없으니 리포 유출
      경로도 아니다(.gitignore 가 `infra/nginx/snippets/loupit-admin-gate.conf`·`*.htpasswd` 를 막는 것은 AH-14).
    - 바이너리(이미지·폰트·PDF·gz)는 건너뛴다."""
    try:
        out = subprocess.run(["git", "-C", str(ROOT), "ls-files", "-z", "-co", "--exclude-standard"],
                             capture_output=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError) as exc:  # git 없는 환경 — 이 검사는 의미가 없다
        pytest.skip(f"git ls-files 불가: {exc}")
    files = [ROOT / p for p in out.decode("utf-8").split("\0") if p]
    return [f for f in files if f.is_file() and f.suffix.lower() not in {
        ".png", ".jpg", ".jpeg", ".webp", ".gif", ".ico", ".woff", ".woff2", ".pdf", ".gz"}]


def test_AH13_리포_어디에도_게이트_비밀_값이_없다():
    """비밀 값은 서버의 `/etc/nginx/snippets/loupit-admin-gate.conf` 와 `server/.env` 두 곳뿐이다.

    두 가지로 잰다:
      ① **모양** — 게이트 헤더 설정이나 `ADMIN_GATE_SECRET=` 대입에 32자 이상 값이 박혀 있으면 실패
         (자리 표시자 `__X__` 는 허용 — 일부러 32자보다 짧게 둬 복사해도 앱이 닫힘으로 본다).
      ② **실값** — 이 테스트를 도는 환경에 진짜 비밀이 있으면(운영 서버: conftest 가 server/.env 를
         읽는다) 그 문자열이 추적 파일 어디에도 없어야 한다. 모양을 바꿔 적어도 잡힌다."""
    from server.config import get_settings

    real = deps._secret_value(get_settings().admin_gate_secret).strip()
    offenders = []
    for f in _repo_text_files():
        try:
            text = f.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        rel = f.relative_to(ROOT)
        for m in re.finditer(r'X-Loupit-Admin-Gate\s+"([^"]*)"', text):
            v = m.group(1)
            if v and not _PLACEHOLDER.match(v) and _SECRETISH.search(v):
                offenders.append(f"{rel}: nginx 게이트 헤더에 비밀 모양 값")
        for m in re.finditer(r"^\s*#?\s*ADMIN_GATE_SECRET\s*=\s*(\S*)", text, re.M):
            v = m.group(1).strip("'\"")
            if v and not _PLACEHOLDER.match(v) and _SECRETISH.search(v):
                offenders.append(f"{rel}: ADMIN_GATE_SECRET 대입에 비밀 모양 값")
        if len(real) >= 8 and real in text:
            offenders.append(f"{rel}: **실제 게이트 비밀**이 들어 있다")
    assert not offenders, "게이트 비밀이 리포에 있다 — git 이력에서 지울 수 없으니 **비밀을 교체**하라:\n" + "\n".join(offenders)


def test_AH14_리포의_스니펫은_예시뿐이고_자리표시자는_닫힘_길이다():
    """실파일 이름(`loupit-admin-gate.conf`)은 리포에 없어야 하고(.gitignore 가 막는다), 예시의 자리
    표시자는 **32자 미만**이어야 한다 — 바꾸는 것을 잊고 .env 로 옮겨도 앱이 닫힘으로 처리하게."""
    snippets = NGINX / "snippets"
    tracked = subprocess.run(["git", "-C", str(ROOT), "ls-files", "infra/nginx/snippets/loupit-admin-gate.conf"],
                             capture_output=True, text=True).stdout.strip()
    assert not tracked, "비밀 스니펫 실파일이 커밋돼 있다"
    ignored = subprocess.run(["git", "-C", str(ROOT), "check-ignore", "-q",
                              "infra/nginx/snippets/loupit-admin-gate.conf"]).returncode
    assert ignored == 0, ".gitignore 가 리포 안의 비밀 스니펫 실파일을 막지 않는다"
    example = (snippets / "loupit-admin-gate.conf.example").read_text(encoding="utf-8")
    values = re.findall(r'^\s*proxy_set_header\s+X-Loupit-Admin-Gate\s+"([^"]*)"\s*;', example, re.M)
    assert len(values) == 1 and _PLACEHOLDER.match(values[0]), f"예시 스니펫 값이 자리 표시자가 아니다: {values}"
    assert len(values[0]) < deps.ADMIN_GATE_SECRET_MIN_LEN, "자리 표시자가 32자 이상 — 그대로 옮기면 앱이 연다"


# ── AH-15: 관문은 **라우팅 단계**에서도 선다 — 405·422·307 로 존재가 새지 않는다 ─────────────

@pytest_asyncio.fixture
async def gated_client(monkeypatch):
    """콘솔이 등록된 앱(M9 + 화이트리스트) + 관리 호스트 설정. DB 는 필요 없다 — 아래 요청은 전부
    의존성(세션 조회) 전에 끝난다(라우팅·본문 파싱 단계)."""
    from server.config import get_settings
    from server.main import create_app

    monkeypatch.setenv("M9_ENABLED", "1")
    monkeypatch.setenv("OPERATOR_EMAILS", "ops@example.com")
    monkeypatch.setenv("ADMIN_HOST", HOST)
    monkeypatch.setenv("ADMIN_GATE_SECRET", SECRET)
    get_settings.cache_clear()
    try:
        transport = httpx.ASGITransport(app=create_app(), raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://127.0.0.1:8000/api/v1") as c:
            yield c
    finally:
        get_settings.cache_clear()


@pytest.mark.asyncio
async def test_AH15_관문_밖에서는_405_422_307_대신_404다(gated_client):
    """라우터 의존성은 라우트가 매칭된 **뒤**에 돈다. 그 전에 나가던 응답이 인터넷에 콘솔의 존재를 알렸다
    (2026-09-18 적대 검토 실측): 틀린 메서드 → 405 + `Allow`, 깨진 JSON → 422 `json_invalid`, 끝 슬래시 → 307.
    `ConsoleRoute.matches` 가 같은 판정으로 매칭을 거부하면 전부 **없는 경로의 404** 와 똑같아진다."""
    c = gated_client
    outside = {**_via_admin(host="jobcho.wiki", gate=SECRET), "X-Loupit-Client": "x",
               "content-type": "application/json"}
    not_found = await c.get("/no-such-route")
    probes = [
        ("GET", "/console/posts/1/visibility", None),   # POST 전용 → 405 였다
        ("POST", "/console/overview", None),            # GET 전용 → 405 였다
        ("POST", "/console/posts/1/visibility", "{"),   # 깨진 JSON → 422 였다
        ("GET", "/console/", None),                     # 끝 슬래시 → 307 이었다
        ("GET", "/console/overview", None),             # 관문 404(원래부터)
    ]
    for method, path, body in probes:
        r = await c.request(method, path, headers=outside, content=body)
        assert r.status_code == 404, f"{method} {path}: {r.status_code} — 관문 밖에서 존재가 드러난다"
        assert r.text == not_found.text and "allow" not in r.headers, f"{method} {path}: 없는 경로와 다르다"

    # 관문 **안**(터널 · 관리 호스트 + 맞는 비밀)에서는 라우팅이 평소대로다 — 라우트 클래스가 콘솔을 망가뜨리지 않았다.
    for inside in ({}, _via_admin()):
        h = {**inside, "X-Loupit-Client": "x", "content-type": "application/json"}
        assert (await c.get("/console/posts/1/visibility", headers=h)).status_code == 405
        assert (await c.post("/console/posts/1/visibility", headers=h, content="{")).status_code == 422
