"""출처 주소 주간 점검 — 판정·예절·robots·TLS·SSRF·압축 (SRC-1~SRC-15, SC-1 2026-09-27).

**네트워크를 두드리는 테스트는 없다.** `urllib_get` 자리에 가짜 HTTP 계층(`FakeWeb`)을 끼운다 — 주소마다 대본을
주고, 요청마다 (시각, 주소, 헤더)를 적는다. 시계와 잠도 주입한다(`FakeClock`): 간격 규칙을 **실제로 자지 않고**
잰다. 스위트가 간격만큼 느려지면 다음 사람이 이 테스트를 지운다(test_dart_http 와 같은 이유).

재는 것:
- 판정 표 전부(설계서 §6) — 200+낱말 / 200 무낱말 첫 실행 / 직전 낱말→이번 없음 / PDF 정상·아님 / 404·403·429·5xx·
  시간 초과 / 다른 호스트·루트로 리다이렉트 / robots 금지.
- 예절 — 정직한 UA 하나(막혀도 바꿔 재시도 안 함), 요청 사이 3초·같은 호스트 10초, robots 를 먼저, 받는 양 상한.
- robots.txt 는 RFC 9309 로 판정한다 — 표준 파서가 실제 대상(SK하이닉스·가온전선)에서 틀린 모양을 못박는다.
  5xx 는 전면 금지, 전송 실패는 요청하지 않고 error, 리다이렉트 목적지마다 다시 묻는다(2026-09-27 검토 MED-1·2).
- 내부 주소(SSRF) — 시드·리다이렉트·`//host`·robots.txt 리다이렉트·IPv6·옛 IPv4 표기·DNS 해석 전부 연결 전에 막는다
  (검토 BLOCK-1). 가짜 해석기와 **로컬 서버 두 대**(루프백)로 재현표를 그대로 돌린다 — 외부 네트워크는 쓰지 않는다.
DB 쓰기·보관·콘솔 API 는 `test_source_check_db.py` 가 실 DB(loupit_test)로 잰다.
"""
from __future__ import annotations

import gzip
import http.client
import http.server
import re
import socket
import ssl
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import urllib.robotparser
import zlib
from pathlib import Path

import pytest

from server import source_check as sc

ROOT = Path(__file__).resolve().parents[2]


class FakeClock:
    """단조 시계 + 잠 — 잠은 시계를 그만큼 앞으로 민다."""

    def __init__(self, start: float = 1000.0):
        self.now = start
        self.slept: list[float] = []

    def __call__(self) -> float:
        return self.now

    def sleep(self, sec: float) -> None:
        self.slept.append(sec)
        self.now += sec


class FakeResp:
    def __init__(self, status: int, headers: dict | None = None, body: bytes = b""):
        self.status = status
        self.headers = {k.lower(): v for k, v in (headers or {}).items()}
        self._body = body
        self.read_bytes = 0
        self.closed = False

    def read(self, n: int) -> bytes:
        chunk = self._body[self.read_bytes:self.read_bytes + n]
        self.read_bytes += len(chunk)
        return chunk

    def close(self) -> None:
        self.closed = True


class FakeWeb:
    """주소 → 대본(`(상태, 헤더, 본문)` 또는 예외). 대본에 없는 robots.txt 는 404, 그 밖의 주소는 테스트 실패다 —
    점검기가 엉뚱한 곳을 두드리면 바로 드러난다. 요청 한 번은 `latency` 초 걸린다."""

    def __init__(self, clock: FakeClock, pages: dict, latency: float = 0.4):
        self.clock, self.pages, self.latency = clock, pages, latency
        self.calls: list[dict] = []
        self.responses: list[FakeResp] = []

    def __call__(self, url: str, headers: dict, timeout: float):
        start = self.clock.now
        self.clock.now += self.latency
        self.calls.append({"start": start, "end": self.clock.now, "url": url, "headers": dict(headers),
                           "timeout": timeout})
        spec = self.pages.get(url)
        if spec is None:
            if url.endswith("/robots.txt"):
                spec = (404, {}, b"")
            else:
                raise AssertionError(f"대본에 없는 주소를 두드렸다: {url}")
        if isinstance(spec, BaseException):
            raise spec
        status, headers_, body = spec
        resp = FakeResp(status, headers_, body)
        self.responses.append(resp)
        return resp

    def urls(self) -> list[str]:
        return [c["url"] for c in self.calls]


HTML = {"Content-Type": "text/html; charset=utf-8"}


def _target(url: str, comp_id: int = 1, eng: str = "testco") -> sc.Target:
    return sc.Target(comp_id, eng, "테스트사", url)


def _run(targets, pages, *, expectations=None, latency=0.4):
    clock = FakeClock()
    web = FakeWeb(clock, pages, latency=latency)
    results = sc.run_checks(targets, expectations=expectations or {}, http=web, clock=clock, sleep=clock.sleep)
    return results, web, clock


def _one(url, pages, *, expect_keyword=False):
    results, web, _clock = _run([_target(url)], pages, expectations={(1, url): expect_keyword})
    return results[0], web


# ── SRC-1: 판정 표(설계서 §6) ───────────────────────────────────────────────────

U = "https://careers.example.co.kr/benefit"


@pytest.mark.parametrize("body", [
    "<h2>복리후생</h2>".encode("utf-8"),
    "<p>사내 복지 제도</p>".encode("cp949"),   # EUC-KR 페이지 — 선언이 틀려도 바이트로 찾는다
    b"<h1>Our BENEFITS</h1>",                  # 대소문자 무시
    b"<title>Employee Welfare</title>",
])
def test_SRC1a_200과_복지_낱말이면_ok_이고_낱말_있음을_적는다(body):
    r, _web = _one(U, {U: (200, HTML, body)})
    assert (r.result_cd, r.keyword_yn, r.http_status) == ("ok", True, 200)
    assert r.final_url is None and r.detail is None and r.content_type == "text/html"


def test_SRC1b_낱말이_처음부터_없던_페이지는_ok_다_헛경보_금지():
    """자바스크립트로 그리는 채용 사이트는 원문에 낱말이 없다. 처음 보는 주소에서 그걸 경보로 내면 매주 헛경보다."""
    r, _web = _one(U, {U: (200, HTML, b"<div id=app></div><script src=/app.js></script>")}, expect_keyword=False)
    assert (r.result_cd, r.keyword_yn) == ("ok", False)


def test_SRC1c_지난번에_있던_낱말이_사라지면_content_lost_다():
    r, _web = _one(U, {U: (200, HTML, b"<p>Page renewed</p>")}, expect_keyword=True)
    assert (r.result_cd, r.keyword_yn, r.http_status) == ("content_lost", False, 200)
    assert "낱말" in r.detail


def test_SRC1d_PDF_머리가_PDF_면_ok_고_Range_로_머리만_달라고_한다():
    pdf = "https://www.lotte.co.kr/upload/report/chemical/lottechemical_SR_kor_2025.pdf"
    r, web = _one(pdf, {pdf: (206, {"Content-Type": "application/pdf", "Content-Range": "bytes 0-2047/9000000"},
                              b"%PDF-1.7\n" + b"x" * 2039)})
    assert (r.result_cd, r.keyword_yn, r.http_status) == ("ok", None, 206)
    [page] = [c for c in web.calls if c["url"] == pdf]
    assert page["headers"]["Range"] == "bytes=0-2047"
    assert page["headers"]["Accept-Encoding"] == "identity", "Range 가 압축 전 바이트를 가리키게 무압축으로 청한다"


def test_SRC1e_PDF_주소가_PDF_가_아니면_content_lost_다():
    """파일을 지우고 「찾을 수 없음」 HTML 을 200 으로 주는 서버가 흔하다 — 상태 코드만 보면 놓친다."""
    pdf = "https://www.lotte.co.kr/upload/report/old.pdf"
    r, _web = _one(pdf, {pdf: (200, HTML, b"<html>file not found</html>")})
    assert (r.result_cd, r.http_status) == ("content_lost", 200)
    assert "PDF 가 아니다" in r.detail and "text/html" in r.detail


@pytest.mark.parametrize("status, expected", [
    (404, "gone"), (410, "gone"),
    (401, "blocked"), (403, "blocked"), (429, "blocked"),
    (500, "error"), (502, "error"), (503, "error"),
    (400, "error"),  # 그 밖의 4xx 도 「접속 오류」 — 상태 코드는 HTTP 칸에 그대로 남는다
])
def test_SRC1f_상태_코드_판정(status, expected):
    r, _web = _one(U, {U: (status, HTML, b"<p>error</p>")})
    assert (r.result_cd, r.http_status, r.keyword_yn) == (expected, status, None)
    assert str(status) in r.detail


@pytest.mark.parametrize("exc, needle", [
    (urllib.error.URLError(socket.timeout("timed out")), "시간 초과"),
    (TimeoutError("timed out"), "시간 초과"),
    (urllib.error.URLError(socket.gaierror(-2, "Name or service not known")), "DNS"),
    (urllib.error.URLError(ssl.SSLCertVerificationError(1, "certificate verify failed")), "TLS"),
    (urllib.error.URLError(ConnectionRefusedError(111, "refused")), "연결 거부"),
    (http.client.RemoteDisconnected("closed"), "연결을 닫았다"),
])
def test_SRC1g_전송_실패는_error_고_원인이_설명에_남는다(exc, needle):
    r, _web = _one(U, {U: exc})
    assert (r.result_cd, r.http_status) == ("error", None)
    assert needle in r.detail, r.detail


def test_SRC1h_다른_호스트로_리다이렉트되면_moved_다():
    r, _web = _one(U, {U: (302, {"Location": "https://newco.example.com/careers"}, b""),
                       "https://newco.example.com/careers": (200, HTML, "복지".encode())})
    assert (r.result_cd, r.http_status, r.keyword_yn) == ("moved", 200, None)
    assert r.final_url == "https://newco.example.com/careers"
    assert "newco.example.com" in r.detail


def test_SRC1i_사이트_첫_화면으로_튕기면_moved_다():
    r, _web = _one(U, {U: (301, {"Location": "/"}, b""),
                       "https://careers.example.co.kr/": (200, HTML, "복리후생 메뉴가 있는 첫 화면".encode())})
    assert (r.result_cd, r.final_url) == ("moved", "https://careers.example.co.kr/")
    assert "첫 화면" in r.detail


def test_SRC1j_www_와_https_는_이동이_아니다():
    """http→https·www 붙이기는 사이트가 그대로다 — 이걸 이동으로 치면 헛경보다. 최종 주소는 적어 둔다."""
    src = "http://example.co.kr/recruit/welfare.jsp"
    final = "https://www.example.co.kr/recruit/welfare.jsp"
    r, _web = _one(src, {src: (301, {"Location": final}, b""), final: (200, HTML, "복지".encode())})
    assert (r.result_cd, r.keyword_yn, r.final_url) == ("ok", True, final)


def test_SRC1k_첫_화면이_출처인_주소는_첫_화면에_머물러도_이동이_아니다():
    root = "https://recruit.example.com"
    r, _web = _one(root, {root: (200, HTML, b"<p>welcome</p>")})
    assert r.result_cd == "ok"


def test_SRC1l_리다이렉트가_5회를_넘으면_error_고_홉_사이에도_같은_호스트_10초를_쉰다():
    """리다이렉트 홉도 요청 하나다 — 홉 사이 간격이 0초면 「한 번에 한 요청·같은 호스트 10초」가 홉에서 깨진다(검토 LOW-1)."""
    pages = {f"https://a.example.com/{i}": (302, {"Location": f"/{i + 1}"}, b"") for i in range(10)}
    r, web = _one("https://a.example.com/0", pages)
    assert r.result_cd == "error" and "리다이렉트" in r.detail
    hops = [c for c in web.calls if not c["url"].endswith("robots.txt")]
    assert len(hops) == sc.MAX_REDIRECTS + 1
    for prev, cur in zip(web.calls, web.calls[1:]):
        assert cur["start"] - prev["end"] >= sc.SAME_HOST_GAP_SEC - 1e-9, f"홉 사이를 쉬지 않았다: {cur['url']}"


def test_SRC1m_robots_금지면_요청하지_않고_robots_로_남긴다():
    robots = "https://careers.example.co.kr/robots.txt"
    r, web = _one(U, {robots: (200, {"Content-Type": "text/plain"}, b"User-agent: *\nDisallow: /\n")})
    assert (r.result_cd, r.http_status) == ("robots", None)
    assert U not in web.urls(), "robots 가 막은 주소를 두드렸다"


ROBOTS_U = "https://careers.example.co.kr/robots.txt"


@pytest.mark.parametrize("robots_reply", [(404, {}, b""), (403, {}, b""), (401, {}, b""), (410, {}, b"")])
def test_SRC1n_robots_가_4xx_면_없음_곧_허용이다(robots_reply):
    """RFC 9309 §2.3.1.3 「unavailable」 — 4xx(401·403 포함)는 규칙이 없는 것이다(리드 확정 2026-09-27)."""
    r, web = _one(U, {ROBOTS_U: robots_reply, U: (200, HTML, "복지".encode())})
    assert r.result_cd == "ok"
    assert web.urls() == [ROBOTS_U, U], "robots 를 먼저 읽지 않았다"


@pytest.mark.parametrize("status", [500, 503])
def test_SRC1o_robots_가_5xx_면_전면_금지로_보고_요청하지_않는다(status):
    """RFC 9309 §2.3.1.4 「unreachable」 — 서버 오류면 전면 금지로 봐야 한다(MUST, 검토 MED-1). 판정은 robots(점검 안 함) —
    사이트는 살아 있고 규칙만 못 읽은 것이라 「확인 필요」가 아니다(리드 확정 2026-09-27)."""
    r, web = _one(U, {ROBOTS_U: (status, {}, b""), U: (200, HTML, "복지".encode())})
    assert (r.result_cd, r.http_status) == ("robots", None) and r.result_cd not in sc.ATTENTION_CODES
    assert r.detail == f"robots.txt 가 HTTP {status} — RFC 9309 에 따라 전면 금지로 보고 요청하지 않았다"
    assert U not in web.urls(), "robots.txt 가 5xx 인데 본 주소를 두드렸다"


@pytest.mark.parametrize("exc, expected", [
    (urllib.error.URLError(socket.timeout("timed out")), "robots.txt 에 닿지 못했다(시간 초과"),
    (urllib.error.URLError(socket.gaierror(-2, "Name or service not known")), "robots.txt 에 닿지 못했다(DNS 실패"),
    (urllib.error.URLError(ssl.SSLError(1, "handshake failure")), "robots.txt 에 닿지 못했다(TLS"),
    (urllib.error.URLError(ConnectionRefusedError(111, "Connection refused")), "robots.txt 에 닿지 못했다(연결 거부"),
    # 연결 직전 검사(고정 연결)가 robots.txt 의 이름이 내부로 풀린다며 막은 경우 — 전송 실패와 같이 error 다.
    (sc.InternalAddress("내부·사설 주소로 해석된다(careers.example.co.kr → 10.0.0.5) — 요청하지 않았다"),
     "robots.txt 가 내부·사설 주소로 해석된다(careers.example.co.kr → 10.0.0.5)"),
])
def test_SRC1p_robots_에_닿지_못하면_요청하지_않고_error_로_남긴다(exc, expected):
    """전송 실패(DNS·TLS·시간 초과·연결 거부·내부 주소 차단)도 본 요청은 하지 않는다(RFC 9309). 다만 판정은 robots 가 아니라
    error 다(리드 확정 2026-09-27) — 사이트가 금지한 것이 아니라 닿지 않는 것이다. robots 로 두면 죽은 도메인(현대모비스
    NXDOMAIN)과 내부 주소 차단이 「점검 안 함」 뒤에 숨어 「확인 필요」에서 빠진다. 설명에는 robots 단계의 원인을 싣는다."""
    r, web = _one(U, {ROBOTS_U: exc, U: (200, HTML, "복지".encode())})
    assert (r.result_cd, r.http_status) == ("error", None) and r.result_cd in sc.ATTENTION_CODES
    assert r.detail.startswith(expected), r.detail
    assert r.detail.endswith("요청하지 않았다"), r.detail
    assert U not in web.urls(), "robots.txt 에 닿지 못했는데 본 주소를 두드렸다"


def test_SRC1q_robots_리다이렉트가_5회를_넘으면_없음으로_본다():
    """RFC 9309 §2.3.1.2 — robots.txt 리다이렉트가 5회를 넘으면 「없음」(허용)으로 볼 수 있다."""
    pages = {"https://careers.example.co.kr/robots.txt": (302, {"Location": "/r1"}, b"")}
    pages.update({f"https://careers.example.co.kr/r{i}": (302, {"Location": f"/r{i + 1}"}, b"") for i in range(1, 9)})
    pages[U] = (200, HTML, "복지".encode())
    r, web = _one(U, pages)
    assert r.result_cd == "ok" and U in web.urls()


# ── SRC-2: robots.txt 는 RFC 9309 로 ─────────────────────────────────────────────

def test_SRC2a_가장_긴_규칙이_이긴다__표준_파서가_틀리는_실제_모양():
    """SK하이닉스 `talent.skhynix.com`(2026-09-27 실측) — `Disallow: /` 다음 `Allow: /hub/`. 표준 파서는 먼저 나온
    규칙이 이겨 우리 출처를 **금지**로 본다(거짓 robots). RFC 9309 는 긴 규칙(`/hub/`)이 이긴다."""
    text = "User-agent: *\nDisallow: /\nAllow: /hub/\n"
    url = "https://talent.skhynix.com/hub/ko/culture/welfare"
    assert sc.parse_robots(text).allows(url) is True
    assert sc.parse_robots(text).allows("https://talent.skhynix.com/admin") is False
    std = urllib.robotparser.RobotFileParser()
    std.parse(text.splitlines())
    assert std.can_fetch(sc.ROBOTS_AGENT, url) is False, "표준 파서가 고쳐졌다면 이 모듈의 자체 판정을 다시 보라"


def test_SRC2b_Allow_슬래시가_먼저_와도_뒤의_금지를_지킨다():
    """올리브영·카카오페이(greetinghr) 모양 — 표준 파서는 `Allow: /` 에서 멈춰 막힌 경로를 두드린다."""
    text = "User-agent: *\nAllow: /\nDisallow: /o/*/apply\nDisallow: /m/*\n"
    rules = sc.parse_robots(text)
    assert rules.allows("https://career.example.com/ko/benefit") is True
    assert rules.allows("https://career.example.com/o/123/apply") is False
    assert rules.allows("https://career.example.com/m/x") is False


def test_SRC2c_와일드카드와_끝_표시():
    rules = sc.parse_robots("User-agent: *\nDisallow: /*.pdf$\nDisallow: /search?q=\n")
    assert rules.allows("https://x.com/report/a.pdf") is False
    assert rules.allows("https://x.com/report/a.pdf?v=2") is True, "`$` 는 주소 끝이다"
    assert rules.allows("https://x.com/search?q=복지") is False, "질의 문자열도 경로의 일부로 본다"
    assert rules.allows("https://x.com/search") is True


def test_SRC2d_우리를_부르는_묶음이_있으면_그것만_없으면_별표_묶음():
    text = ("User-agent: Googlebot\nAllow: /\n\n"
            "User-agent: LOUPIT-Source-Check\nDisallow: /private\n\n"
            "User-agent: *\nDisallow: /\n")
    rules = sc.parse_robots(text)
    assert rules.allows("https://x.com/careers") is True, "우리 묶음(대소문자 무시)을 두고 별표 묶음을 썼다"
    assert rules.allows("https://x.com/private/a") is False
    # 코웨이·CJ 모양 — 이름 붙은 봇들에게만 열고 나머지(*)는 전부 막는다 → 우리는 막힌다.
    coway = "User-agent: ClaudeBot\nUser-agent: Googlebot\nDisallow: /order/\n\nUser-agent: *\nDisallow: /\n"
    assert sc.parse_robots(coway).allows("https://www.coway.com/recruit") is False


def test_SRC2e_묶음_밖_규칙_빈_Disallow_동률_주석():
    assert sc.parse_robots("Disallow: /\nUser-agent: *\nAllow: /x\n").allows("https://x.com/a") is True
    assert sc.parse_robots("User-agent: *\nDisallow:\n").allows("https://x.com/a") is True
    assert sc.parse_robots("User-agent: *\nDisallow: /a # 관리\nAllow: /a\n").allows("https://x.com/a") is True
    assert sc.parse_robots("﻿User-agent : *\nDisallow : /a\n").allows("https://x.com/a/b") is False
    assert sc.parse_robots("<html>not a robots file</html>").allows("https://x.com/a") is True


def test_SRC2f_별표_묶음이_여럿이면_합친다():
    rules = sc.parse_robots("User-agent: *\nDisallow: /a\n\nUser-agent: *\nDisallow: /b\n")
    assert rules.allows("https://x.com/a1") is False and rules.allows("https://x.com/b1") is False


def test_SRC2g_같은_호스트의_금지_경로로_리다이렉트되면_따라가지_않는다():
    """robots 는 가져오는 **주소마다** 따른다(RFC 9309) — 시드가 허용이어도 그 사이트가 보낸 곳이 금지면 멈춘다(검토 MED-2)."""
    seed = "https://h.example.com/benefit"
    r, web = _one(seed, {"https://h.example.com/robots.txt": (200, {}, b"User-agent: *\nDisallow: /private/\n"),
                         seed: (302, {"Location": "/private/benefit"}, b"")})
    assert (r.result_cd, r.http_status) == ("robots", None)
    assert "리다이렉트 목적지" in r.detail and "/private/benefit" in r.detail
    assert "https://h.example.com/private/benefit" not in web.urls(), "robots 금지 경로를 두드렸다"


def test_SRC2h_다른_호스트로_리다이렉트되면_그_호스트의_robots_를_읽고_금지면_멈춘다():
    seed = "https://h.example.com/benefit"
    r, web = _one(seed, {seed: (302, {"Location": "https://other.example.org/x"}, b""),
                         "https://other.example.org/robots.txt": (200, {}, b"User-agent: *\nDisallow: /\n")})
    assert r.result_cd == "robots" and "other.example.org" in r.detail
    urls = web.urls()
    assert "https://other.example.org/robots.txt" in urls, "리다이렉트 목적지의 robots.txt 를 읽지 않았다"
    assert "https://other.example.org/x" not in urls, "금지된 목적지를 두드렸다"
    # 허용이면 그대로 간다(이동 판정).
    r, web = _one(seed, {seed: (302, {"Location": "https://other.example.org/x"}, b""),
                         "https://other.example.org/x": (200, HTML, "복지".encode())})
    assert r.result_cd == "moved" and "https://other.example.org/x" in web.urls()


def test_SRC2i_http_robots_가_https_로_넘어가면_그_파일을_https_의_robots_로도_쓴다():
    """실측(NAVER, 2026-09-27): http 시드의 robots.txt 가 https 로 308 → 본 요청도 https 로 308. 받은 https robots.txt 를
    https origin 의 것으로도 기억해야 같은 파일을 20초 뒤에 또 받지 않는다. 규칙은 그대로 적용된다."""
    seed = "http://h.example.com/benefit"
    r, web = _one(seed, {
        "http://h.example.com/robots.txt": (308, {"Location": "https://h.example.com/robots.txt"}, b""),
        "https://h.example.com/robots.txt": (200, {}, b"User-agent: *\nDisallow: /private\n"),
        seed: (308, {"Location": "https://h.example.com/benefit"}, b""),
        "https://h.example.com/benefit": (200, HTML, "복지".encode()),
    })
    assert (r.result_cd, r.final_url) == ("ok", "https://h.example.com/benefit")
    assert web.urls().count("https://h.example.com/robots.txt") == 1, web.urls()


# ── SRC-3: 간격 — 요청 사이 3초, 같은 호스트 10초 ─────────────────────────────────

def test_SRC3_요청_사이_3초_같은_호스트_10초를_지킨다():
    same1 = "https://cjnews.example.net/a"
    same2 = "https://cjnews.example.net/b"
    other = "https://www.other.example.com/c"
    pages = {u: (200, HTML, "복지".encode()) for u in (same1, same2, other)}
    targets = [_target(same1, 1, "a"), _target(other, 2, "c"), _target(same2, 3, "b")]
    results, web, clock = _run(targets, pages, latency=0.7)
    assert [r.result_cd for r in results] == ["ok", "ok", "ok"]
    calls = web.calls
    for prev, cur in zip(calls, calls[1:]):
        assert cur["start"] - prev["end"] >= sc.GAP_SEC - 1e-9, f"3초를 쉬지 않았다: {prev['url']} → {cur['url']}"
    by_host: dict[str, list[dict]] = {}
    for c in calls:
        by_host.setdefault(c["url"].split("/")[2], []).append(c)
    for host, cs in by_host.items():
        for prev, cur in zip(cs, cs[1:]):
            assert cur["start"] - prev["end"] >= sc.SAME_HOST_GAP_SEC - 1e-9, f"{host} 에 10초를 쉬지 않았다"
    # 한 번에 한 요청 — 겹치는 구간이 없다.
    assert all(cur["start"] >= prev["end"] for prev, cur in zip(calls, calls[1:]))
    # robots.txt 를 호스트마다 **한 번**, 본 요청보다 **먼저**.
    robots = [c["url"] for c in calls if c["url"].endswith("/robots.txt")]
    assert robots == ["https://cjnews.example.net/robots.txt", "https://www.other.example.com/robots.txt"]
    assert all(c["url"].endswith("/robots.txt") for c in calls[:2])
    assert clock.slept and all(s > 0 for s in clock.slept), "간격을 잠으로 지키지 않았다"


# ── SRC-4·5: 정직한 UA · 받는 양 ─────────────────────────────────────────────────

def test_SRC4_UA_는_정직한_이름_하나고_막혀도_바꿔_다시_두드리지_않는다():
    r, web = _one(U, {U: (403, HTML, b"Access denied")})
    assert r.result_cd == "blocked"
    assert {c["headers"]["User-Agent"] for c in web.calls} == {sc.USER_AGENT}
    assert web.urls().count(U) == 1, "막힌 뒤 다시 두드렸다"
    assert "loupit-source-check" in sc.USER_AGENT and "jobcho.wiki" in sc.USER_AGENT
    assert all(c["timeout"] == sc.TIMEOUT_SEC for c in web.calls)


def test_SRC5a_Range_를_무시한_PDF_는_64KB_에서_끊는다():
    pdf = "https://x.example.com/big.pdf"
    r, web = _one(pdf, {pdf: (200, {"Content-Type": "application/pdf"}, b"%PDF-1.4\n" + b"0" * (3 * 1024 * 1024))})
    assert r.result_cd == "ok"
    [resp] = [x for x in web.responses if x.read_bytes > 0]
    assert resp.read_bytes <= sc.PDF_MAX_BYTES and resp.closed


def test_SRC5b_HTML_은_5MB_까지만_읽는다():
    body = b"<html>" + b"a" * (7 * 1024 * 1024) + "복지".encode()
    r, web = _one(U, {U: (200, HTML, body)})
    assert (r.result_cd, r.keyword_yn) == ("ok", False), "5MB 뒤의 낱말까지 읽었다"
    assert max(x.read_bytes for x in web.responses) == sc.HTML_MAX_BYTES


def test_SRC5c_본문이_20초_안에_끝나지_않으면_error_다():
    clock = FakeClock()

    class Slow(FakeResp):
        def read(self, n):
            clock.now += 15  # 조각마다 15초 — 소켓 타임아웃(조각별)에는 안 걸리지만 전체 마감은 넘는다
            return b"a" * min(n, 1024)

    def web(url, headers, timeout):
        return FakeResp(404) if url.endswith("robots.txt") else Slow(200, HTML)

    [r] = sc.run_checks([_target(U)], expectations={}, http=web, clock=clock, sleep=clock.sleep)
    assert r.result_cd == "error" and "시간 초과" in r.detail


# ── SRC-6: 요약 한 줄 ────────────────────────────────────────────────────────────

def _res(cd: str) -> sc.Result:
    return sc.Result(_target(U), cd)


def test_SRC6_요약_한_줄은_설계서_모양이고_robots_는_확인_필요가_아니다():
    rs = [_res("ok")] * 74 + [_res("gone"), _res("blocked"), _res("blocked"), _res("error")]
    assert sc.summary_line(rs) == "출처 점검 78곳: 정상 74 · 확인 필요 4(없어짐 1 · 차단 2 · 오류 1)"
    assert sc.summary_line([_res("ok")] * 3) == "출처 점검 3곳: 정상 3 · 확인 필요 0"
    rs = [_res("ok")] * 2 + [_res("robots")] * 2 + [_res("moved")]
    assert sc.summary_line(rs) == "출처 점검 5곳: 정상 2 · 확인 필요 1(이동 1) · 점검 안 함 2(robots 금지)"
    assert set(sc.ATTENTION_CODES) == set(sc.RESULT_CODES) - {"ok", "robots"}


# ── SRC-7: 어떤 사이트도 점검 전체를 멈추지 못한다 ──────────────────────────────────

def test_SRC7_예외를_던지는_사이트가_있어도_나머지를_점검한다():
    bad, good = "https://bad.example.com/x", "https://good.example.com/y"

    class Weird(Exception):
        pass

    results, _web, _clock = _run([_target(bad, 1, "bad"), _target(good, 2, "good")],
                                 {bad: Weird("boom"), good: (200, HTML, "복지".encode())})
    assert [r.result_cd for r in results] == ["error", "ok"]
    assert "Weird" in results[0].detail
    rs = sc.run_checks([_target("ftp://x.example.com/a"), _target("http://[::1/broken")], expectations={},
                       http=None, clock=FakeClock(), sleep=lambda s: None)
    assert [(r.result_cd, "http(s)" in r.detail) for r in rs] == [("error", True), ("error", True)], \
        "시드의 이상한 주소 한 줄이 점검 전체를 멈췄다"


# ── SRC-8: 주간 타이머 · 프로비저닝 ──────────────────────────────────────────────

def test_SRC8_타이머는_월요일_09시17분_KST_에_ops_source_check_를_부른다():
    """서버는 UTC 다 — 월 09:17 KST = 월 00:17 UTC. 유닛 글자가 곧 운영 설정이라 글자로 못박는다."""
    svc = (ROOT / "infra/systemd/loupit-source-check.service").read_text(encoding="utf-8")
    timer = (ROOT / "infra/systemd/loupit-source-check.timer").read_text(encoding="utf-8")
    for needed in ("Type=oneshot", "User=ubuntu", "WorkingDirectory=/home/ubuntu/loupit",
                   "ExecStart=/usr/bin/python3 -m server.ops source-check\n",
                   "SyslogIdentifier=loupit-source-check", "network-online.target", "mysql.service"):
        assert needed in svc, f"서비스 유닛에 {needed!r} 가 없다"
    assert "--dry-run" not in svc, "타이머가 dry-run 으로 돌면 콘솔은 영영 비어 있다"
    # 전체 시간 예산과 systemd 제한의 정합(검토 LOW-2) — 점검기가 **스스로** 예산에서 멈추고 결과를 쓸 시간이 남아야 한다.
    # 제한이 먼저 오면 SIGTERM 으로 그 주 결과가 통째로 사라진다.
    m = re.search(r"^TimeoutStartSec=(\d+)h$", svc, re.M)
    assert m and int(m.group(1)) * 3600 - sc.RUN_BUDGET_SEC >= 30 * 60, "TimeoutStartSec 가 예산보다 30분 이상 길지 않다"
    assert re.search(r"^OnCalendar=Mon \*-\*-\* 00:17:00$", timer, re.M)
    assert re.search(r"^Persistent=true$", timer, re.M)
    prov = (ROOT / "infra/deploy/provision.sh").read_text(encoding="utf-8")
    for unit in ("loupit-source-check.service", "loupit-source-check.timer"):
        assert f"infra/systemd/{unit}\" /etc/systemd/system/{unit}" in prov, f"provision.sh 가 {unit} 을 복사하지 않는다"
    assert "systemctl enable --now loupit-source-check.timer" in prov


def test_SRC10_점검기_TLS_는_암호만_넓히고_인증서와_호스트_이름은_그대로_검증한다():
    """리드 결정(2026-09-27): 농심처럼 전방 보안 없는 RSA 키 교환만 주는 서버 때문에 암호 목록을 `DEFAULT` 로 넓혔다.
    넓힌 것은 **암호뿐**이어야 한다 — 인증서·호스트 이름 검증이 풀리면 가짜 서버가 「정상」을 꾸밀 수 있다.
    그리고 실제 요청에 쓰이는 오프너가 **이** 컨텍스트를 들고 있어야 한다(만들어 놓고 안 쓰면 헛경보가 그대로다)."""
    [https] = [h for h in sc._opener().handlers if isinstance(h, urllib.request.HTTPSHandler)]
    ctx = https._context
    assert ctx.verify_mode == ssl.CERT_REQUIRED, "인증서 검증이 풀렸다"
    assert ctx.check_hostname is True, "호스트 이름 검증이 풀렸다"
    assert ctx.minimum_version >= ssl.TLSVersion.TLSv1_2, "TLS 1.2 미만을 허용한다"
    assert any(c["name"] == "AES256-GCM-SHA384" for c in ctx.get_ciphers()), \
        "농심이 주는 암호(RSA 키 교환)가 목록에 없다 — 매주 TLS 헛경보가 난다"
    assert isinstance(https, sc._PinnedHTTPSHandler), "요청 오프너가 점검기 전용(고정 연결) 처리기를 쓰지 않는다"


def test_SRC9_ops_에_source_check_명령이_있다():
    from server import ops

    args = ops.build_parser().parse_args(["source-check", "--dry-run", "--only", "a", "--only", "b", "--limit", "3"])
    assert (args.dry_run, args.only, args.limit, args.func) == (True, ["a", "b"], 3, ops.cmd_source_check)
    args = ops.build_parser().parse_args(["source-check"])
    assert (args.dry_run, args.only, args.limit) == (False, None, None)
    with pytest.raises(SystemExit):
        ops.build_parser().parse_args(["source-check", "--limit", "0"])


# ── SRC-11: 내부 주소(SSRF) — 연결하지 않는다 (2026-09-27 검토 BLOCK-1) ───────────────────

@pytest.mark.parametrize("seed", [
    "http://127.0.0.1:8000/api/v1/console",      # 운영 API·콘솔
    "http://localhost/x", "http://sub.localhost/x", "http://localhost./x",
    "http://[::1]/x",
    "http://169.254.169.254/opc/v1/instance/",   # 클라우드 메타데이터
    "http://10.0.0.1/x", "http://192.168.0.1/x", "http://172.16.0.1/x", "http://100.64.0.1/x", "http://0.0.0.0/x",
    "http://127.1/x", "http://0x7f.1/x", "http://2130706433/x", "http://0177.0.0.1/x",  # 옛 IPv4 표기
    "http://[::ffff:127.0.0.1]/x", "http://[64:ff9b::7f00:1]/x", "http://[2002:7f00:1::]/x",  # IPv4 를 품은 IPv6
    "http://[fe80::1%25eth0]/x", "http://[fec0::1]/x", "http://224.0.0.1/x", "http://[ff02::1]/x",
])
def test_SRC11a_시드가_내부_주소면_robots_도_읽지_않고_error_다(seed):
    r, web = _one(seed, {})
    assert (r.result_cd, r.http_status) == ("error", None)
    assert "내부" in r.detail, r.detail
    assert web.urls() == [], f"내부 주소 시드에 요청했다: {web.urls()}"


@pytest.mark.parametrize("location", [
    "http://127.0.0.1:8000/", "//10.0.0.1/x", "http://localhost:8001/x", "http://[::1]/x", "http://127.1/x",
])
def test_SRC11b_리다이렉트가_내부_주소를_가리키면_따라가지_않는다(location):
    r, web = _one(U, {U: (302, {"Location": location}, b"")})
    assert r.result_cd == "error" and "내부" in r.detail
    assert web.urls() == [ROBOTS_U, U], f"내부 주소로 따라갔다: {web.urls()}"


def test_SRC11b2_robots_txt_리다이렉트가_내부_주소를_가리키면_본_요청도_하지_않는다():
    r, web = _one(U, {ROBOTS_U: (302, {"Location": "http://127.0.0.1:8000/robots-internal"}, b"")})
    assert r.result_cd == "error" and "robots.txt" in r.detail and "내부" in r.detail
    assert web.urls() == [ROBOTS_U], "내부 주소나 본 주소를 두드렸다"


def test_SRC11b3_기본_포트_밖은_요청하지_않는다():
    r, web = _one("https://example.co.kr:8443/benefit", {})
    assert r.result_cd == "error" and "포트" in r.detail and web.urls() == []


class _Resolver:
    """가짜 해석기 — 표에 있는 이름만 풀고, IP 글자·localhost 는 진짜 해석기(네트워크 없음: 숫자·/etc/hosts)에 넘긴다.
    그 밖의 이름은 DNS 실패다 — 테스트가 밖으로 DNS 를 묻는 일이 없게."""

    def __init__(self, table, real):
        self.table, self.real, self.calls = table, real, []

    def __call__(self, host, port, *args, **kwargs):
        self.calls.append(host)
        if host in self.table:
            return [(socket.AF_INET, socket.SOCK_STREAM, 6, "", (ip, port)) for ip in self.table[host]]
        if host == "localhost" or sc._as_ip(host) is not None:
            return self.real(host, port, *args, **kwargs)
        raise socket.gaierror(-2, "Name or service not known")


def test_SRC11c_해석한_주소가_내부면_연결_전에_거부하고_공인이면_그_주소로만_붙는다(monkeypatch):
    """전송 층 — 해석과 연결을 **한 번에** 한다. 두 번째 해석이 없으니 재바인딩 창이 없다(검토 BLOCK-1 ①)."""
    resolver = _Resolver({"internal.example": ["10.0.0.5"], "mixed.example": ["93.184.216.34", "127.0.0.1"],
                          "public.example": ["93.184.216.34"]}, socket.getaddrinfo)
    monkeypatch.setattr(socket, "getaddrinfo", resolver)

    def no_socket(*a, **k):
        raise AssertionError("검사 전에 소켓을 만들었다")

    monkeypatch.setattr(socket, "socket", no_socket)
    for host in ("internal.example", "mixed.example"):  # 하나라도 내부면 호스트째 거부
        with pytest.raises(sc.InternalAddress) as ei:
            sc._pinned_create_connection((host, 80), 1)
        assert "해석된다" in str(ei.value)

    connected = []

    class FakeSock:
        def __init__(self, family, type_, proto):
            self.family = family

        def settimeout(self, t):
            pass

        def connect(self, sa):
            connected.append(sa)

    monkeypatch.setattr(socket, "socket", FakeSock)
    resolver.calls.clear()
    sock = sc._pinned_create_connection(("public.example", 443), 5)
    assert isinstance(sock, FakeSock) and connected == [("93.184.216.34", 443)]
    assert resolver.calls == ["public.example"], "해석을 두 번 했다 — 재바인딩 창이 생긴다"


def test_SRC11d_오프너는_고정_연결_처리기만_쓰고_프록시_파일_처리기가_없다():
    handlers = sc._opener().handlers
    kinds = {type(h) for h in handlers}
    assert sc._PinnedHTTPHandler in kinds and sc._PinnedHTTPSHandler in kinds
    assert not any(type(h) in (urllib.request.HTTPHandler, urllib.request.HTTPSHandler) for h in handlers), \
        "고정하지 않은 기본 http(s) 처리기가 남아 우회로가 된다"
    for banned in (urllib.request.ProxyHandler, urllib.request.FileHandler, urllib.request.FTPHandler,
                   urllib.request.DataHandler):
        assert not any(isinstance(h, banned) for h in handlers), f"{banned.__name__} 가 있다"


class _Recorder(http.server.BaseHTTPRequestHandler):
    """로컬 서버 — 받은 (Host, 경로)를 적고 `route(host, path)` 대로 답한다."""

    hits: list = []
    route = staticmethod(lambda host, path: (404, {}, b""))

    def do_GET(self):  # noqa: N802 — http.server 규약
        host = (self.headers.get("Host") or "").split(":")[0]
        type(self).hits.append((host, self.path))
        status, headers, body = type(self).route(host, self.path)
        self.send_response(status)
        for k, v in headers.items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def _serve(address, route):
    handler = type("H", (_Recorder,), {"hits": [], "route": staticmethod(route)})
    try:
        server = http.server.ThreadingHTTPServer(address, handler)
    except OSError as exc:
        pytest.skip(f"로컬 서버를 {address} 에 띄울 수 없다({exc})")
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, handler


def test_SRC11e_검토_재현표를_실제_전송_계층으로_돌려도_내부_서버는_요청을_하나도_받지_않는다(monkeypatch):
    """검토 부록의 재현을 그대로 — 실제 `urllib_get`(고정 연결·TLS 없는 http) + 루프백 서버 두 대. 외부 네트워크 없음.

    B(127.0.0.1) = 내부 역할: 무엇이든 받으면 기록한다. A(127.0.0.2) = 외부 역할: 이 테스트에서만 「공인」으로 친다.
    대조군(A 의 정상 페이지)이 ok 여야 차단이 「하네스가 망가져서」가 아님이 증명된다."""
    b_server, b = _serve(("127.0.0.1", 0), lambda host, path: (200, HTML, "복지".encode()))
    port_b = b_server.server_address[1]
    internal = f"http://127.0.0.1:{port_b}/internal"

    def route_a(host, path):
        if host == "robots.example" and path == "/robots.txt":
            return 302, {"Location": f"http://127.0.0.1:{port_b}/robots-internal"}, b""
        redirects = {"/go": internal, "/go-localhost": f"http://localhost:{port_b}/internal",
                     "/go-relative": f"//127.0.0.1:{port_b}/internal", "/go-dns": f"http://internal.example:{port_b}/x"}
        if path in redirects:
            return 302, {"Location": redirects[path]}, b""
        if path == "/ok":
            return 200, HTML, "<h1>복리후생</h1>".encode()
        return 404, {}, b""

    a_server, a = _serve(("127.0.0.2", 0), route_a)
    port_a = a_server.server_address[1]
    try:
        original = sc.blocked_ip
        monkeypatch.setattr(sc, "blocked_ip", lambda addr: False if str(addr) == "127.0.0.2" else original(addr))
        monkeypatch.setattr(sc, "ALLOWED_PORTS", (None, 80, 443, port_a, port_b))
        monkeypatch.setattr(socket, "getaddrinfo", _Resolver(
            {"a.example": ["127.0.0.2"], "robots.example": ["127.0.0.2"], "internal.example": ["127.0.0.1"],
             "rebind.example": ["127.0.0.2", "127.0.0.1"]}, socket.getaddrinfo))
        seeds = [
            internal, f"http://localhost:{port_b}/internal", f"http://127.1:{port_b}/internal",
            f"http://[::1]:{port_b}/internal",
            f"http://a.example:{port_a}/go", f"http://a.example:{port_a}/go-localhost",
            f"http://a.example:{port_a}/go-relative", f"http://a.example:{port_a}/go-dns",
            f"http://robots.example:{port_a}/page", f"http://internal.example:{port_b}/x",
            f"http://rebind.example:{port_a}/ok",
        ]
        targets = [_target(u, i, f"t{i}") for i, u in enumerate(seeds)] + [_target(f"http://a.example:{port_a}/ok", 99)]
        results = sc.run_checks(targets, expectations={}, http=sc.urllib_get, clock=time.monotonic,
                                sleep=lambda s: None)
    finally:
        a_server.shutdown()
        b_server.shutdown()
    *blocked, control = results
    assert [(r.result_cd, "내부" in (r.detail or "")) for r in blocked] == [("error", True)] * len(seeds), \
        [(r.target.url, r.result_cd, r.detail) for r in blocked]
    assert b.hits == [], f"내부 역할 서버가 요청을 받았다: {b.hits}"
    assert ("rebind.example", "/ok") not in a.hits and ("rebind.example", "/robots.txt") not in a.hits, \
        "내부로도 풀리는 이름에 연결했다"
    assert (control.result_cd, control.keyword_yn) == ("ok", True), "대조군이 실패했다 — 하네스가 망가졌다"
    assert ("a.example", "/ok") in a.hits


# ── SRC-12: 압축 응답 (검토 MED-3) ──────────────────────────────────────────────────

KO_PAGE = "<h1>복리후생 제도</h1>".encode()


def _raw_deflate(data: bytes) -> bytes:
    c = zlib.compressobj(wbits=-15)
    return c.compress(data) + c.flush()


@pytest.mark.parametrize("encoding, body", [
    ("gzip", gzip.compress(KO_PAGE)),
    ("x-gzip", gzip.compress(KO_PAGE)),
    ("deflate", zlib.compress(KO_PAGE)),   # zlib 머리(규격대로)
    ("deflate", _raw_deflate(KO_PAGE)),    # 머리 없는 deflate(그렇게 보내는 서버가 있다)
])
def test_SRC12a_압축된_본문도_풀어서_낱말을_찾는다__헛_내용_사라짐_없음(encoding, body):
    r, web = _one(U, {U: (200, {**HTML, "Content-Encoding": encoding}, body)}, expect_keyword=True)
    assert (r.result_cd, r.keyword_yn) == ("ok", True), r.detail
    [page] = [c for c in web.calls if c["url"] == U]
    assert page["headers"]["Accept-Encoding"] == sc.ACCEPT_ENCODING == "gzip, deflate"


def test_SRC12b_못_푸는_압축은_낱말_판정을_생략하고_기준선을_건드리지_않는다():
    """br 은 표준 라이브러리에 없어 청하지 않는다. 그래도 서버가 멋대로 보내면 「사라짐」 대신 판정 생략(KEYWORD_YN NULL)."""
    r, _web = _one(U, {U: (200, {**HTML, "Content-Encoding": "br"}, b"\x8b\x02\x80garbage")}, expect_keyword=True)
    assert (r.result_cd, r.keyword_yn) == ("ok", None)
    assert "압축 응답(br)" in r.detail and "생략" in r.detail
    r, _web = _one(U, {U: (200, {**HTML, "Content-Encoding": "gzip"}, b"not gzip at all")}, expect_keyword=True)
    assert (r.result_cd, r.keyword_yn) == ("ok", None) and "풀 수 없다" in r.detail


def test_SRC12c_압축_폭탄은_상한에서_끊는다():
    bomb = gzip.compress(b"\0" * (64 * 1024 * 1024))  # 64 MB 가 수십 KB 로 — 받는 양 상한(5 MB)엔 한참 못 미친다
    raw, why = sc.decode_body(bomb, "gzip", sc.HTML_MAX_BYTES)
    assert why is None and len(raw) == sc.HTML_MAX_BYTES, "풀린 크기가 상한을 넘었다"
    r, _web = _one(U, {U: (200, {**HTML, "Content-Encoding": "gzip"}, bomb)})
    assert (r.result_cd, r.keyword_yn) == ("ok", False)


def test_SRC12d_robots_txt_도_압축을_풀어_읽는다():
    robots = gzip.compress(b"User-agent: *\nDisallow: /\n")
    r, web = _one(U, {ROBOTS_U: (200, {"Content-Encoding": "gzip"}, robots)})
    assert r.result_cd == "robots" and U not in web.urls()


# ── SRC-13: 한 실행의 시간 예산 (검토 LOW-2) ───────────────────────────────────────────

def test_SRC13_예산을_넘기면_남은_곳은_건너뛰고_결과는_남긴다():
    """systemd 가 끊으면 끝에 한 번 쓰는 결과가 통째로 사라진다 — 점검기가 스스로 멈추고 건너뛴 곳을 적는다."""
    clock = FakeClock()
    urls = [f"https://s{i}.example.com/p" for i in range(3)]
    pages = {u: (200, HTML, "복지".encode()) for u in urls}
    web = FakeWeb(clock, pages)
    slow = urls[0]

    def slow_web(url, headers, timeout):
        if url == slow:
            clock.now += 15  # 첫 페이지가 15초를 쓴다 — 주소 하나의 한도(20초) 안이지만 실행 예산(20초)을 넘긴다
        return web(url, headers, timeout)

    results = sc.run_checks([_target(u, i) for i, u in enumerate(urls)], expectations={}, http=slow_web,
                            clock=clock, sleep=clock.sleep, budget=20)
    assert results[0].result_cd == "ok"
    assert [(r.result_cd, "예산" in r.detail) for r in results[1:]] == [("error", True)] * 2
    assert urls[1] not in web.urls() and urls[2] not in web.urls()


# ── SRC-14: IDN 호스트 (검토 LOW-5) ─────────────────────────────────────────────────

def test_SRC14_한글_도메인은_punycode_로_요청하고_이동으로_치지_않는다():
    assert sc.request_url("https://한글.kr/복지?q=가") == "https://xn--bj0bj06e.kr/%EB%B3%B5%EC%A7%80?q=%EA%B0%80"
    assert sc.request_url("https://User:pw@Example.COM:443/a b") == "https://example.com:443/a%20b", "사용자 정보를 보냈다"
    assert sc.moved_reason("https://한글.kr/a", "https://xn--bj0bj06e.kr/a") is None
    seed = "https://한글.kr/복지"
    r, web = _one(seed, {"https://xn--bj0bj06e.kr/%EB%B3%B5%EC%A7%80": (200, HTML, "복지".encode())})
    assert (r.result_cd, r.final_url) == ("ok", None)
    assert web.urls() == ["https://xn--bj0bj06e.kr/robots.txt", "https://xn--bj0bj06e.kr/%EB%B3%B5%EC%A7%80"]


# ── SRC-15: 콘솔 API 는 점검기를 싣지 않는다 (검토 LOW-8) ────────────────────────────────

def test_SRC15_콘솔_조회는_점검기를_불러오지_않고_점검기는_TLS_를_처음_쓸_때_만든다():
    """API 프로세스가 기동하며 전송 계층·TLS 설정을 만들면, 어느 OpenSSL 에서 그 설정이 던지는 날 API 가 import 에서 죽는다."""
    probe = ("import sys; import server.main, server.services.console_view, server.routers.console; "
             "print('server.source_check' in sys.modules); "
             "import server.source_check as sc; print(sc._opener.cache_info().currsize)")
    out = subprocess.run([sys.executable, "-c", probe], cwd=ROOT, capture_output=True, text=True, timeout=60)
    assert out.returncode == 0, out.stderr[-2000:]
    assert out.stdout.split() == ["False", "0"], out.stdout
