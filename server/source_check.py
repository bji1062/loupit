"""출처 주소 주간 점검 (SC-1 · SP-DB-19 · SP-AUTH-19.9, 2026-09-27) — `python3 -m server.ops source-check`.

## 왜 있는가

복지 데이터 78개사는 공식 출처 주소(`TCOMPANY.CAREERS_BENEFIT_URL`)를 근거로 하고, 화면의 「공식」 배지도
거기에 기댄다. 그런데 회사가 그 페이지를 없애거나 옮겨도 **알 방법이 없었다.** `infra/verify/link-audit.py` 는
사이트 안쪽 링크만 보고 외부 `http(s)://` 는 건너뛴다. 롯데케미칼은 보고서 PDF 가 출처인데 파일 이름이 해마다
바뀐다 — 작년 주소는 어느 날 조용히 404 가 된다.

그래서 주 1회(`loupit-source-check.timer`, 월 09:17 KST) 주소마다 한 번 두드려 판정을 `TSOURCE_CHECK` 에 한 행씩
남기고, 운영 콘솔 「출처 점검」 탭이 마지막 실행과 연속 실패를 보여 준다(사용자 결정 2026-09-27 「나 방식」).
GitHub 이슈 자동 등록(「가 방식」)은 만들지 않았다 — 관리가 안 되면 그때 붙인다. 행이 구조화돼 있어(판정 코드·
HTTP·최종 주소·시각) 붙이는 쪽은 이 표를 읽기만 하면 된다.

## 운영 서버가 남의 지시로 내부망을 두드리지 않는다 (SSRF, 2026-09-27 독립 검토 BLOCK-1)

이 코드는 운영 서버에서 남의 서버 78곳이 보내는 `Location` 을 따라간다. 도메인이 만료·탈취되면 그쪽이 우리 서버로
하여금 `127.0.0.1:8000`(운영 API·콘솔)·`169.254.169.254`(클라우드 메타데이터)·`10.x` 를 GET 하게 만들 수 있다.
그래서 두 겹으로 막는다 — 막힌 주소는 **연결하지 않고** `error`(「내부·사설 주소」)로 남긴다.

1. **주소 층**(`check_address`, DNS 전): 시드·리다이렉트 홉·`//host`·robots.txt 와 그 리다이렉트 **전부**에서 http(s)
   아닌 스킴, 기본 포트(80·443) 밖, `localhost`, 공인이 아닌 IP 글자(IPv6·옛 IPv4 표기 `127.1`·IPv4 를 품은 IPv6)를 거부한다.
2. **전송 층**(`_pinned_create_connection`, 연결 직전): 이름을 **한 번** 풀어 검사하고 **검사한 그 주소로만** 붙는다.
   두 번째 해석이 없으니 DNS 재바인딩(검사 뒤 내부 IP 로 바꿔치기) 창이 없다. http.client 가 연결에 쓰는 자리만 바꿔
   끼우므로 HTTPS 의 SNI·인증서·호스트 이름 검증은 그대로다. 환경 변수 프록시는 쓰지 않는다(`_opener`).

## 남의 서버다 — 예절

- 호스트마다 robots.txt 를 **먼저** 읽고, **리다이렉트 목적지마다 그 origin 의 robots.txt 를 다시** 묻는다. 막힌 경로는
  요청하지 않고 `robots` 로 남긴다. RFC 9309 §2.3.1(리드 확정 2026-09-27): 4xx 는 「없음」 = 허용, 5xx 는 「닿지 못함」 =
  **전면 금지**(`robots`), 전송 실패(DNS·TLS·시간 초과·연결 거부·내부 주소 차단)는 본 요청을 하지 않고 `error` 로 남긴다 —
  사이트가 금지한 것이 아니라 닿지 않는 것이라, 「점검 안 함」 뒤에 숨기면 죽은 도메인(현대모비스 NXDOMAIN)과 내부 주소
  차단이 「확인 필요」에서 빠진다.
- User-Agent 는 정직한 이름 하나다(`USER_AGENT`). 막혀도 **UA 를 바꿔 다시 두드리지 않는다** — 그건 봇 방어를
  속이는 일이고, 우리 사이트가 당하면 싫은 일이다.
- 요청 사이 3초 이상, 같은 호스트는 10초 이상 쉰다 — **리다이렉트 홉 사이도** 같다. 한 번에 한 요청이다. 타임아웃
  20초는 한 주소가 서버를 기다린 시간의 합(리다이렉트 포함, 쉼 제외)이다. 리다이렉트 5회. 한 실행 전체 예산은
  90분(`RUN_BUDGET_SEC`) — 넘으면 남은 곳은 건너뛰고 결과를 쓴다(유닛의 `TimeoutStartSec=2h` 가 그보다 길다).
  78곳 전체가 robots.txt 76번 + 본 요청 78번이라 약 9분 걸린다(2026-09-27 dry-run 실측 8분 31초).
- HTML 은 5 MB 까지만 읽고, PDF 는 `Range` 로 머리 2 KB 만 달라고 한다(무시하면 64 KB 에서 끊는다). 압축은 gzip·
  deflate 만 청하고 풀어서 본다(풀린 크기도 같은 상한 — 압축 폭탄). 못 푸는 압축이면 낱말 판정을 생략한다.
- TLS 는 인증서·호스트 이름을 검증하되 암호 목록은 넓힌다 — 전방 보안 없는 옛 서버(농심)도 상태를 볼 수 있게
  (`_ssl_context`).
- **본문·스크린샷은 저장하지 않는다**(저작권·용량). 판정과 메타데이터만 남긴다.

### robots.txt 는 표준 라이브러리로 판정하지 않는다

`urllib.robotparser` 는 **먼저 나온 규칙**이 이긴다. RFC 9309 는 **가장 긴 규칙**이 이긴다(길이가 같으면 허용).
실제 대상에서 갈린다(2026-09-27 실측): SK하이닉스 `talent.skhynix.com` 은 `Disallow: /` 다음 줄에 `Allow: /hub/` 를
두는데, 표준 파서로는 우리 출처 `/hub/ko/culture/welfare` 가 **금지**로 나온다 — 거짓 「robots 금지」다. 거꾸로
`Allow: /` 를 먼저 쓰는 사이트(올리브영·카카오페이 greetinghr)에서는 뒤따르는 금지를 못 보고 **막힌 경로를
두드린다.** 와일드카드(`*`·`$`)도 모른다. 그래서 RFC 9309 의 묶음 선택·최장 일치만 여기서 구현한다
(`parse_robots`).

## 헛경보를 내지 않는다

감시 도구가 거짓 경보를 내면 사람은 곧 경보를 보지 않는다. 그래서:

- 복지 낱말이 **처음부터 없던** 페이지(자바스크립트로 그리는 사이트)는 `ok` 다. `content_lost` 는 **있던 낱말이
  사라졌을 때만** 낸다 — 기준은 같은 회사·같은 주소의 마지막 내용 관측이다(`load_expectations`). 압축을 못 풀었거나
  하는 이유로 내용을 못 본 주는 기준을 건드리지 않는다(`KEYWORD_YN` NULL).
- `www.` 유무·http→https·IDN 표기(한글/punycode)는 이동이 아니다. 다른 호스트로 가거나 사이트 첫 화면(`/`)으로 튕긴
  것만 `moved`.
- robots 금지는 「확인 필요」가 아니다 — 점검하지 **않은** 것이라 따로 센다(`ATTENTION_CODES`).
- 한 번 실패는 일시적일 수 있다 — 판단은 콘솔의 「연속」 횟수로 한다(2주 연속부터 확인).

## 종료 코드 · 쓰기

DB 실패가 아니면 0 이다. 두드린 사이트가 죽은 것은 **점검의 결과**지 점검기의 실패가 아니다 — 그걸로 타이머가
빨개지면 진짜 고장(DB·스키마)과 구분되지 않는다.

모든 주소를 두드린 **뒤에** 한 트랜잭션으로 쓴다(같은 `RUN_DTM`). 중간에 죽으면 아무것도 남지 않는다 — 반쯤 쓴
실행이 「마지막 점검」이 되면 나머지 회사가 콘솔에서 사라진다. 같은 이유로 `--only`·`--limit`(시험용)은 `--dry-run`
처럼 **쓰지 않는다**: 한 곳만 두드린 실행이 78곳짜리 실행을 덮으면 안 된다.
"""
from __future__ import annotations

import functools
import http.client
import ipaddress
import re
import socket
import ssl
import string
import time
import urllib.error
import urllib.request
import zlib
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from urllib.parse import quote, urljoin, urlsplit, urlunsplit

import pymysql

USER_AGENT = "Mozilla/5.0 (compatible; loupit-source-check/1.0; +https://jobcho.wiki)"
#: robots.txt 의 `User-agent:` 줄이 우리를 부를 이름(제품 토큰). 사이트 운영자가 우리만 막고 싶을 때 쓰는 이름이다.
ROBOTS_AGENT = "loupit-source-check"

#: 복지 낱말 — 대소문자를 가리지 않는다. 「복리후생」은 「복지」를 품지 않으므로 둘 다 필요하다.
KEYWORDS = ("복리후생", "복지", "benefit", "welfare")

GAP_SEC = 3.0             # 아무 두 요청 사이(리다이렉트 홉 포함)
SAME_HOST_GAP_SEC = 10.0  # 같은 호스트 두 요청 사이
TIMEOUT_SEC = 20.0        # 한 주소가 서버를 기다린 시간의 합(리다이렉트 포함, 간격 쉼 제외)
MAX_REDIRECTS = 5
#: 한 실행 전체의 시간 예산. 넘으면 남은 회사는 건너뛰고(판정 error) 결과를 쓴다 — systemd 가 끊어 그 주 결과가
#: 통째로 사라지는 것보다 낫다. 유닛의 `TimeoutStartSec=2h` 가 이보다 넉넉히 길어야 한다(SRC-8 이 대조한다).
RUN_BUDGET_SEC = 90 * 60
HTML_MAX_BYTES = 5 * 1024 * 1024
PDF_RANGE = "bytes=0-2047"
PDF_MAX_BYTES = 64 * 1024     # 서버가 Range 를 무시하고 파일 전체를 줄 때 여기서 끊는다
ROBOTS_MAX_BYTES = 512 * 1024  # RFC 9309 — 파서는 최소 500 KiB 를 읽어야 한다
RETENTION_DAYS = 180
#: 요청하는 포트 — 기본 포트만. 우리 서버의 내부 서비스(8000·8001·3306)를 가리키는 주소를 한 겹 더 막는다.
ALLOWED_PORTS = (None, 80, 443)
#: 청하는 압축 — 표준 라이브러리(zlib)로 풀 수 있는 것만. br 은 표준 라이브러리에 없고 의존성을 늘리지 않는다.
ACCEPT_ENCODING = "gzip, deflate"
REDIRECT_CODES = (301, 302, 303, 307, 308)

#: 판정 값집합(SP-DB-19) — 콘솔 조회 서비스도 이 순서로 센다.
RESULT_CODES = ("ok", "content_lost", "gone", "blocked", "error", "moved", "robots")

#: 「확인 필요」 — 사람이 가서 봐야 하는 판정. **`robots` 는 여기 없다**: 사이트가 막아 점검하지 **않은** 것이지 출처가
#: 망가진 것이 아니다. 넣으면 매주 같은 곳이 떠서 숫자가 영영 0 이 되지 않고, 늘 0 이 아닌 숫자는 아무도 안 본다
#: (2026-09-27 dry-run 실측: 78곳 중 5곳이 `User-agent: *` 전체 금지 — 삼성카드·코웨이·CJ ENM 엔터·CJ제일제당·농심.
#: 농심은 TLS 암호를 넓힌 뒤 robots.txt 가 읽히면서 드러났다).
#: 콘솔의 연속 횟수도 이 판정만 센다.
ATTENTION_CODES = ("content_lost", "gone", "blocked", "error", "moved")

#: 요약 한 줄의 짧은 이름. 콘솔의 긴 이름(SP-AUTH-19.9)과 뜻이 같다.
SUMMARY_LABEL = {"content_lost": "내용 사라짐", "gone": "없어짐", "blocked": "차단", "error": "오류", "moved": "이동"}


# ── 예외 ────────────────────────────────────────────────────────────────────

class CheckError(Exception):
    """판정 `error` 로 떨어질 실패 — 메시지가 곧 콘솔의 「설명」이다."""


class InternalAddress(CheckError):
    """내부·사설 주소 거부(SSRF 방어) — 연결하지 않았다. OSError 가 아니라 urllib 가 URLError 로 감싸지 않고 그대로 올린다."""


class TooManyRedirects(CheckError):
    """리다이렉트 5회 초과."""


class BodyTimeout(CheckError):
    """주소 하나의 시간(20초)을 다 썼다 — 전송 실패와 같이 다룬다."""


class NotChecked(Exception):
    """판정 `robots` — 요청하지 않았다(robots.txt 금지, 또는 RFC 9309 에 따라 전면 금지로 본 경우)."""


# ── 낱말·형식 ───────────────────────────────────────────────────────────────
#
# 낱말은 **바이트로** 찾는다. 한국 회사 페이지에는 아직 EUC-KR(CP949)이 있고 charset 선언이 틀린 곳도 있다 —
# 디코딩에 기대면 인코딩을 잘못 짚은 날 낱말이 「사라져」 헛경보가 된다. 한글 낱말은 UTF-8·CP949 두 벌을 원문
# 바이트에서, 영문 낱말은 소문자로 내린 바이트에서 찾는다. 한글 낱말의 CP949 바이트는 전부 0xA1 이상이라
# ASCII 소문자화와 섞이지 않는다. (압축 응답은 `decode_body` 가 먼저 푼다.)
_KO_NEEDLES = tuple(dict.fromkeys(
    kw.encode(enc) for kw in KEYWORDS if not kw.isascii() for enc in ("utf-8", "cp949")))
_EN_NEEDLES = tuple(kw.encode("ascii") for kw in KEYWORDS if kw.isascii())


def has_keyword(body: bytes) -> bool:
    if any(n in body for n in _KO_NEEDLES):
        return True
    low = body.lower()
    return any(n in low for n in _EN_NEEDLES)


def looks_pdf(url: str) -> bool:
    """주소만 보고 PDF 인지 — `Range` 를 붙일지 요청 **전에** 정해야 해서 응답을 기다릴 수 없다."""
    return urlsplit(url).path.lower().endswith(".pdf")


def pdf_head_ok(body: bytes) -> bool:
    """머리 1 KB 안에 `%PDF` — 규격상 맨 앞이지만 리더들이 앞쪽 잡음을 그만큼 허용한다(엄격히 보면 헛경보)."""
    return b"%PDF" in body[:1024]


def decode_body(raw: bytes, content_encoding: str, limit: int) -> tuple[bytes, str | None]:
    """`Content-Encoding` 을 푼다 → (본문, None). 못 푸는 압축이면 (원문, 사유) — 판정은 그 주 낱말을 보지 않는다.

    풀린 크기는 `limit` 에서 끊는다: 5 MB 압축이 수 GB 로 부푸는 응답(압축 폭탄)을 메모리에 풀지 않는다. 읽기를 상한에서
    끊어 스트림이 도중에 잘려도 `decompressobj` 는 풀 수 있는 만큼 돌려준다."""
    enc = content_encoding.strip().lower()
    if enc in ("", "identity"):
        return raw, None
    if enc in ("gzip", "x-gzip", "deflate"):
        for wbits in (47, -15):  # 47 = zlib·gzip 머리 자동 인식, -15 = 머리 없는 deflate(그렇게 보내는 서버가 있다)
            try:
                return zlib.decompressobj(wbits).decompress(raw, limit), None
            except zlib.error:
                continue
        return raw, f"압축을 풀 수 없다({enc})"
    return raw, f"압축 응답({enc})"


# ── 주소 ────────────────────────────────────────────────────────────────────

def _ascii_host(host: str) -> str:
    """IDN 호스트 → ASCII(punycode). 표준 codec(IDNA 2003)이라 의존성이 없다. 이미 ASCII 면 그대로."""
    return host if host.isascii() else host.encode("idna").decode("ascii")


def _quote(text: str, encoding: str) -> str:
    try:
        return quote(text, encoding=encoding, safe=string.punctuation)
    except UnicodeEncodeError:  # ISO-8859-1 밖의 글자 — 이미 유니코드로 온 값이다
        return quote(text, encoding="utf-8", safe=string.punctuation)


def request_url(url: str, encoding: str = "utf-8") -> str:
    """요청용 주소 — 호스트는 소문자·IDNA(punycode), 경로·질의는 비ASCII·공백만 퍼센트 인코딩한다(이미 인코딩된
    `%XX` 와 구분 기호는 그대로). 호스트까지 퍼센트 인코딩하면 IDN 주소가 깨진다(검토 LOW-5). 사용자 정보(`user:pw@`)는
    버린다 — 보낼 일이 없다. 호스트 없는 상대 주소는 글자만 인코딩한다. `Location` 헤더는 http.client 가 ISO-8859-1 로
    풀어 오므로 그 바이트로 되돌려 인코딩한다(urllib 와 같은 처리). 잘못된 포트·IPv6 표기·IDNA 불가 호스트는 ValueError."""
    parts = urlsplit(url)
    if not parts.netloc:
        return _quote(url, encoding)
    host, port = parts.hostname or "", parts.port  # 포트가 숫자가 아니거나 범위 밖이면 ValueError
    try:
        host = _ascii_host(host)
    except UnicodeError as exc:
        raise ValueError(f"호스트 이름을 IDNA 로 바꿀 수 없다({parts.hostname})") from exc
    netloc = f"[{host}]" if ":" in host else host
    if port is not None:
        netloc += f":{port}"
    return urlunsplit((parts.scheme.lower(), netloc, _quote(parts.path, encoding),
                       _quote(parts.query, encoding), _quote(parts.fragment, encoding)))


def _normalize(url: str, encoding: str = "utf-8") -> str:
    try:
        return request_url(url, encoding)
    except ValueError as exc:
        raise CheckError(f"http(s) 주소로 해석할 수 없다({exc})") from exc


def _site(host: str | None) -> str:
    """이동 판정용 호스트 — 소문자·ASCII(IDN 은 punycode 로), 끝 점과 맨 앞 `www.` 를 뗀다."""
    h = (host or "").lower().rstrip(".")
    try:
        h = _ascii_host(h)
    except UnicodeError:
        pass
    return h[4:] if h.startswith("www.") else h


def _is_root(path: str) -> bool:
    return path in ("", "/")


def moved_reason(original: str, final: str) -> str | None:
    """최종 주소가 이동인가 — 다른 호스트이거나, 첫 화면이 아니던 주소가 사이트 첫 화면(`/`)으로 떨어졌다."""
    a, b = urlsplit(original), urlsplit(final)
    if _site(a.hostname) != _site(b.hostname):
        return f"다른 호스트로 이동({b.hostname})"
    if _is_root(b.path) and not _is_root(a.path):
        return "사이트 첫 화면으로 튕겼다"
    return None


# ── 내부 주소 거부(SSRF, 모듈 머리말) ─────────────────────────────────────────────

_NAT64 = ipaddress.ip_network("64:ff9b::/96")


def _as_ip(host: str):
    """호스트가 IP 글자이면 그 주소, 이름이면 None. 옛 IPv4 표기(`127.1`·`0x7f.1`·`2130706433`·`0177.0.0.1`)까지 본다 —
    소켓 해석기는 이런 글자도 받아들이므로 `ipaddress` 만 보면 빠진다."""
    text = host.split("%", 1)[0]  # IPv6 구역 표시(fe80::1%eth0)
    try:
        return ipaddress.ip_address(text)
    except ValueError:
        pass
    try:
        return ipaddress.IPv4Address(socket.inet_aton(text))
    except (OSError, ValueError):
        return None


def blocked_ip(addr) -> bool:
    """공인 주소가 아니면 막는다 — 루프백·사설·링크로컬(169.254 메타데이터)·100.64/10·0/8·예약·멀티캐스트·IPv6 사이트로컬.

    IPv6 안에 IPv4 를 품은 모양(`::ffff:`·6to4·Teredo·NAT64)은 품은 IPv4 까지 본다. `is_private` 가 아니라 `not is_global`
    인 이유: 100.64.0.0/10 은 is_private 가 거짓이다. 멀티캐스트·`fec0::/10`·NAT64 는 is_global 이 참으로 나와(파이썬 3.10)
    따로 본다."""
    if addr.version == 6:
        inner = [addr.ipv4_mapped, addr.sixtofour, *(addr.teredo or ())]
        if addr in _NAT64:
            inner.append(ipaddress.IPv4Address(int(addr) & 0xFFFF_FFFF))
        if any(i is not None and blocked_ip(i) for i in inner) or addr.is_site_local:
            return True
    # 예약 대역(IPv6 ::/8 의 ::127.0.0.1 같은 옛 IPv4 호환 표기 등)도 막는다 — 재검토 LOW-A(2026-09-27).
    return (not addr.is_global) or addr.is_multicast or addr.is_reserved


def check_address(url: str) -> None:
    """주소 층 — DNS 전에 글자만 보고 막는다: http(s) 가 아닌 스킴 · `localhost` · 공인이 아닌 IP 글자 · 기본 포트(80·443)
    밖. 이름이 내부 주소로 **해석**되는 경우는 전송 층(`_pinned_create_connection`)이 연결 직전에 막는다. 이 층이 있어야
    가짜 HTTP 계층으로 「요청 0건」을 증명할 수 있다."""
    try:
        parts = urlsplit(url)
        port = parts.port
    except ValueError as exc:
        raise CheckError(f"http(s) 주소로 해석할 수 없다({exc})") from exc
    if parts.scheme not in ("http", "https") or not parts.hostname:
        raise CheckError("http(s) 주소가 아니다")
    host = parts.hostname.rstrip(".")
    if host == "localhost" or host.endswith(".localhost"):
        raise InternalAddress(f"내부 주소를 가리킨다({host}) — 요청하지 않았다")
    ip = _as_ip(host)
    if ip is not None and blocked_ip(ip):
        raise InternalAddress(f"내부·사설 주소를 가리킨다({host}) — 요청하지 않았다")
    if port not in ALLOWED_PORTS:
        raise CheckError(f"기본 포트(80·443)가 아니다({port}) — 요청하지 않았다")


def _address_ok(url: str) -> bool:
    try:
        check_address(_normalize(url))
        return True
    except CheckError:
        return False


# ── robots.txt (RFC 9309) ───────────────────────────────────────────────────

def _norm_pct(s: str) -> str:
    """퍼센트 인코딩을 한 모양으로 — 비ASCII 는 UTF-8 로 인코딩하고 `%xx` 는 대문자로."""
    return re.sub(r"%[0-9a-fA-F]{2}", lambda m: m.group(0).upper(), _quote(s, "utf-8"))


@functools.lru_cache(maxsize=1024)
def _robots_regex(pattern: str) -> re.Pattern:
    """`*` = 아무 글자열, 끝의 `$` = 주소 끝. 그 밖의 글자는 글자 그대로(접두 일치)."""
    anchored = pattern.endswith("$")
    body = pattern[:-1] if anchored else pattern
    return re.compile(".*".join(re.escape(part) for part in body.split("*")) + ("$" if anchored else ""))


@dataclass(frozen=True)
class RobotsRules:
    """우리에게 적용되는 규칙 묶음 — `(허용?, 패턴)`. 비어 있으면 전부 허용."""

    rules: tuple[tuple[bool, str], ...] = ()

    def allows(self, url: str) -> bool:
        """RFC 9309 §2.2.2 — 맞는 규칙 중 **가장 긴** 것이 이긴다. 길이가 같으면 허용이 이긴다."""
        p = urlsplit(url)
        target = _norm_pct((p.path or "/") + (f"?{p.query}" if p.query else ""))
        best_len, allowed = -1, True
        for allow, pattern in self.rules:
            if _robots_regex(pattern).match(target):
                if len(pattern) > best_len or (len(pattern) == best_len and allow):
                    best_len, allowed = len(pattern), allow
        return allowed


ALLOW_ALL = RobotsRules()


def parse_robots(text: str, agent: str = ROBOTS_AGENT) -> RobotsRules:
    """robots.txt → 우리 제품 토큰에 적용되는 규칙(RFC 9309 §2.1·2.2.1).

    묶음 = `User-agent` 줄 하나 이상 + 뒤따르는 규칙. 우리 토큰(대소문자 무시)을 부르는 묶음이 있으면 그것들을,
    없으면 `*` 묶음들을 합쳐 쓴다. 빈 줄은 묶음을 끊지 않는다. 빈 `Disallow:` 는 규칙이 아니다."""
    groups: list[tuple[list[str], list[tuple[bool, str]]]] = []
    current = None
    in_rules = False
    for raw in text.lstrip("﻿").splitlines():
        line = raw.split("#", 1)[0].strip()
        key, sep, value = line.partition(":")
        if not sep:
            continue
        key, value = key.strip().lower(), value.strip()
        if key == "user-agent":
            if current is None or in_rules:
                current = ([], [])
                groups.append(current)
                in_rules = False
            current[0].append(value.split("/", 1)[0].strip().lower())
        elif key in ("allow", "disallow") and current is not None:  # 묶음 밖 규칙은 무시한다
            in_rules = True
            if value:
                current[1].append((key == "allow", _norm_pct(value)))
    token = agent.lower()
    chosen = [g for g in groups if token in g[0]] or [g for g in groups if "*" in g[0]]
    return RobotsRules(tuple(rule for g in chosen for rule in g[1]))


# ── 전송 — 요청 한 번(리다이렉트 안 따라감) ────────────────────────────────────────

class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """urllib 가 리다이렉트를 대신 따라가지 않게 한다 — 홉마다 주소·robots·간격을 `fetch` 가 직접 본다."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _pinned_create_connection(address, timeout=socket._GLOBAL_DEFAULT_TIMEOUT, source_address=None):
    """전송 층 — 이름을 **한 번** 풀어 검사하고, 검사한 그 주소로만 붙는다(`socket.create_connection` 자리).

    두 번째 해석이 없으니 DNS 재바인딩 창(검사를 통과한 뒤 내부 IP 로 바뀌기)이 없다. 풀린 주소 중 하나라도 공인이
    아니면 호스트째 거부한다 — 골라 붙는 것보다 단순하고 안전하다."""
    host, port = address
    infos = socket.getaddrinfo(host, port, 0, socket.SOCK_STREAM)
    bad = sorted({sa[0] for *_rest, sa in infos if blocked_ip(ipaddress.ip_address(sa[0].split("%", 1)[0]))})
    if not infos or bad:
        raise InternalAddress(f"내부·사설 주소로 해석된다({host} → {', '.join(bad) or '주소 없음'}) — 요청하지 않았다")
    err = None
    for family, type_, proto, _canon, sa in infos:
        sock = None
        try:
            sock = socket.socket(family, type_, proto)
            if timeout is not socket._GLOBAL_DEFAULT_TIMEOUT:
                sock.settimeout(timeout)
            if source_address:
                sock.bind(source_address)
            sock.connect(sa)
            return sock
        except OSError as exc:
            err = exc
            if sock is not None:
                sock.close()
    raise err


class _PinnedHTTPConnection(http.client.HTTPConnection):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._create_connection = _pinned_create_connection


class _PinnedHTTPSConnection(http.client.HTTPSConnection):
    """`connect()` 는 부모 그대로다 — `super().connect()`(고정 연결) 뒤 `wrap_socket(server_hostname=…)` 이라 SNI·인증서·
    호스트 이름 검증이 그대로 선다."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._create_connection = _pinned_create_connection


class _PinnedHTTPHandler(urllib.request.HTTPHandler):
    def http_open(self, req):
        return self.do_open(_PinnedHTTPConnection, req)


class _PinnedHTTPSHandler(urllib.request.HTTPSHandler):
    def https_open(self, req):
        return self.do_open(_PinnedHTTPSConnection, req, context=self._context)


def _ssl_context() -> ssl.SSLContext:
    """점검기 전용 TLS 컨텍스트 — 파이썬 기본값에서 **암호 목록만** OpenSSL `DEFAULT` 로 넓힌다(리드 결정 2026-09-27).

    파이썬 3.10+ 기본 컨텍스트는 전방 보안(FS)이 없는 RSA 키 교환 암호를 뺀다. 농심 채용 사이트는 TLS 1.2 에서 그런
    암호(`AES256-GCM-SHA384`)만 주어, 기본값으로는 핸드셰이크가 실패하고 **매주 「접속 오류」 헛경보**가 났다
    (2026-09-27 dry-run — 같은 호스트에 `openssl s_client` 는 붙는다). 이 점검기는 공개 페이지의 상태만 본다 — 보내는
    비밀도 받는 비밀도 없어 FS 가 지킬 것이 없다.

    그 밖은 그대로다: 인증서 검증(CERT_REQUIRED)·호스트 이름 검증·TLS 1.2 이상. 가짜 서버가 「정상」을 꾸며 내지
    못하게 막는 것은 여전히 필요하다(SRC-10 이 지킨다). 앱의 다른 HTTPS 호출에는 이 컨텍스트를 쓰지 않는다."""
    ctx = ssl.create_default_context()
    ctx.set_ciphers("DEFAULT")
    return ctx


@functools.lru_cache(maxsize=1)
def _opener() -> urllib.request.OpenerDirector:
    """요청 오프너 — **처음 쓸 때** 만든다: 콘솔 API 가 이 모듈의 상수를 불러도 TLS 컨텍스트를 만들지 않는다(검토 LOW-8).

    `build_opener` 를 쓰지 않고 필요한 처리기만 단다 — http·https(고정 연결) · 오류 응답 · 리다이렉트 안 따라가기.
    그래서 환경 변수 프록시(ProxyHandler)가 끼지 않고(프록시를 거치면 우리가 검사한 주소가 아니라 프록시가 해석한
    주소로 간다) `file:`·`ftp:`·`data:` 처리기도 없다(SRC-11d)."""
    opener = urllib.request.OpenerDirector()
    for handler in (urllib.request.UnknownHandler(), urllib.request.HTTPDefaultErrorHandler(), _NoRedirect(),
                    urllib.request.HTTPErrorProcessor(), _PinnedHTTPHandler(),
                    _PinnedHTTPSHandler(context=_ssl_context())):
        opener.add_handler(handler)
    return opener


def urllib_get(url: str, headers: dict[str, str], timeout: float):
    """요청 **한 번**(리다이렉트를 따라가지 않는다). 3xx·4xx·5xx 도 예외가 아니라 응답으로 돌려준다 — `HTTPError`
    는 응답과 같은 모양이다(`.status`·`.headers`·`.read`·`.close`). 전송 실패(DNS·TLS·시간 초과)는 그대로 던지고,
    내부 주소는 연결 전에 `InternalAddress` 로 던진다.

    테스트는 이 함수 대신 가짜를 주입한다 — 네트워크를 두드리는 테스트는 없어야 한다."""
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        return _opener().open(req, timeout=timeout)
    except urllib.error.HTTPError as exc:
        return exc


# ── 간격 ────────────────────────────────────────────────────────────────────

class Pacer:
    """요청 간격 — 아무 두 요청 사이 `GAP_SEC`, 같은 호스트 사이 `SAME_HOST_GAP_SEC`. 리다이렉트 홉도 요청 하나다.

    간격은 앞 요청이 **끝난** 뒤부터 잰다(쉬는 시간). 시계·잠은 주입한다 — 테스트가 실제로 자지 않고 간격을 잰다."""

    def __init__(self, clock, sleep):
        self.clock, self.sleep = clock, sleep
        self._last_any: float | None = None
        self._last_host: dict[str, float] = {}

    def wait(self, host: str) -> None:
        due = []
        if self._last_any is not None:
            due.append(self._last_any + GAP_SEC)
        if host in self._last_host:
            due.append(self._last_host[host] + SAME_HOST_GAP_SEC)
        if due:
            delay = max(due) - self.clock()
            if delay > 0:
                self.sleep(delay)

    def done(self, hosts) -> None:
        now = self.clock()
        self._last_any = now
        for h in hosts:
            self._last_host[h] = now


# ── 가져오기 ─────────────────────────────────────────────────────────────────

@dataclass
class Fetched:
    status: int
    url: str                    # 마지막으로 요청한 주소(리다이렉트를 따라간 뒤)
    content_type: str | None    # 매개변수를 뗀 소문자
    body: bytes                 # 2xx 일 때만, 상한까지만, 압축은 푼 뒤
    undecoded: str | None = None  # 압축을 못 풀었으면 그 사유(본문 판정 생략)


def _header(resp, name: str) -> str:
    headers = getattr(resp, "headers", None)
    return ((headers.get(name) if headers is not None else None) or "").strip()


def _close(resp) -> None:
    try:
        resp.close()
    except Exception:  # noqa: BLE001 — 닫기 실패는 판정과 무관하다
        pass


def _read(resp, limit: int, deadline: float, clock) -> bytes:
    """상한까지만 읽는다. 조각 사이에 마감을 본다 — 소켓 타임아웃은 조각마다라 느린 서버가 한 조각씩 흘리면 끝없이
    붙잡힌다."""
    chunks, got = [], 0
    while got < limit:
        if clock() > deadline:
            raise BodyTimeout(f"시간 초과({TIMEOUT_SEC:.0f}초 — 본문이 끝나지 않았다)")
        chunk = resp.read(min(64 * 1024, limit - got))
        if not chunk:
            break
        chunks.append(chunk)
        got += len(chunk)
    return b"".join(chunks)


def fetch(url: str, *, http, clock, pacer: Pacer, headers: dict[str, str], limit_for, gate=None,
          meter: dict | None = None) -> Fetched:
    """리다이렉트를 최대 `MAX_REDIRECTS` 번 따라가며 가져온다. **홉마다** ① 주소 검사(내부 주소면 요청 없이 거부)
    ② `gate(주소, 몇 번째 홉)` — 본 요청은 그 origin 의 robots.txt 를 다시 묻는다 ③ 간격 ④ 요청 한 번.

    20초는 서버를 기다린 시간의 **합**이다 — 홉마다 새 20초를 주지 않고, 간격 쉼은 넣지 않는다. `meter["spent"]` 에
    기다린 초를 쌓는다(실패해도 남아 「소요」로 적힌다). `limit_for(content_type)` 가 읽을·풀 상한을 정한다."""
    meter = meter if meter is not None else {}
    meter.setdefault("spent", 0.0)
    current = _normalize(url)
    for hop in range(MAX_REDIRECTS + 1):
        check_address(current)
        if gate is not None:
            gate(current, hop)
        host = urlsplit(current).hostname
        budget = TIMEOUT_SEC - meter["spent"]
        if budget <= 0:
            raise BodyTimeout(f"시간 초과({TIMEOUT_SEC:.0f}초 — 리다이렉트 포함)")
        pacer.wait(host)
        started = clock()
        try:
            resp = http(current, headers, budget)
            try:
                status = int(resp.status)
                if status in REDIRECT_CODES:
                    location = _header(resp, "location")
                    if not location:
                        raise CheckError(f"HTTP {status} 인데 이동할 주소(Location)가 없다")
                    current = _normalize(urljoin(current, _normalize(location, encoding="iso-8859-1")))
                    continue
                ctype = _header(resp, "content-type").split(";", 1)[0].strip().lower() or None
                if not 200 <= status < 300:
                    return Fetched(status, current, ctype, b"")
                limit = limit_for(ctype)
                raw = _read(resp, limit, started + budget, clock)
                body, undecoded = decode_body(raw, _header(resp, "content-encoding"), limit)
                return Fetched(status, current, ctype, body, undecoded)
            finally:
                _close(resp)
        finally:
            meter["spent"] += clock() - started
            pacer.done([host])
    raise TooManyRedirects(f"리다이렉트 {MAX_REDIRECTS}회 초과")


def _transport_failure(exc: BaseException) -> bool:
    """닿지 못한 실패인가 — DNS·TLS·연결·시간 초과·응답 파손·내부 주소 거부. (robots.txt 판정이 이것으로 갈린다.)"""
    return isinstance(exc, (OSError, http.client.HTTPException, InternalAddress, BodyTimeout))


def describe_error(exc: BaseException) -> str:
    """전송 실패 → 콘솔 「설명」 한 줄. 원인 종류가 보여야 사람이 다음 행동을 고른다(주소 수정 / 기다림 / 무시)."""
    if isinstance(exc, CheckError):
        return str(exc)
    reason = exc.reason if isinstance(exc, urllib.error.URLError) else exc
    if isinstance(reason, CheckError):
        return str(reason)
    if isinstance(reason, str):
        return f"요청 실패({reason})"[:200]
    if isinstance(reason, (socket.timeout, TimeoutError)):
        return f"시간 초과({TIMEOUT_SEC:.0f}초)"
    if isinstance(reason, socket.gaierror):
        return "DNS 실패 — 도메인을 찾을 수 없다"
    if isinstance(reason, ssl.SSLError):  # 속성은 핸드셰이크 중 C 쪽이 채운다 — 없을 수도 있다
        why = getattr(reason, "verify_message", None) or getattr(reason, "reason", None) or type(reason).__name__
        kind = "인증서 검증 실패" if isinstance(reason, ssl.SSLCertVerificationError) else "오류"
        return f"TLS {kind}({why})"[:200]
    if isinstance(reason, http.client.RemoteDisconnected):
        return "서버가 응답 없이 연결을 닫았다"
    if isinstance(reason, http.client.IncompleteRead):
        return "응답이 중간에 끊겼다"
    if isinstance(reason, http.client.HTTPException):
        return f"HTTP 응답을 해석할 수 없다({type(reason).__name__})"
    if isinstance(reason, ConnectionRefusedError):
        return "연결 거부"
    if isinstance(reason, ConnectionResetError):
        return "연결이 끊겼다(reset)"
    if isinstance(reason, OSError):
        return f"네트워크 오류({type(reason).__name__}: {reason})"[:200]
    return f"점검기 오류({type(reason).__name__}: {reason})"[:200]


# ── 판정 ────────────────────────────────────────────────────────────────────

@dataclass
class Target:
    comp_id: int
    comp_eng_nm: str
    comp_nm: str
    url: str


@dataclass
class Result:
    target: Target
    result_cd: str
    http_status: int | None = None
    final_url: str | None = None
    content_type: str | None = None
    keyword_yn: bool | None = None
    elapsed_ms: int | None = None
    detail: str | None = None


def classify(url: str, fetched: Fetched, *, expect_keyword: bool) -> tuple[str, bool | None, str | None]:
    """응답 하나 → (판정, KEYWORD_YN, 설명). 상태 코드가 먼저다 — 다른 곳으로 튕겨 404 면 `gone` 이 더 쓸모 있다.

    KEYWORD_YN 은 **이 주소의 HTML 을 실제로 본 경우**(ok·content_lost)에만 적는다. 이동한 페이지나 못 푼 압축 본문은
    다른(또는 못 본) 관측이라, 그걸 기준선에 섞으면 원래 주소로 돌아온 뒤의 판정이 흔들린다."""
    status = fetched.status
    if status in (404, 410):
        return "gone", None, f"HTTP {status}"
    if status in (401, 403, 429):
        return "blocked", None, f"HTTP {status} — 봇 방어일 수 있다(UA 를 바꿔 다시 두드리지 않는다)"
    if not 200 <= status < 300:
        return "error", None, f"HTTP {status}"
    reason = moved_reason(url, fetched.url)
    if reason:
        return "moved", None, reason
    if looks_pdf(url) or fetched.content_type == "application/pdf":
        if fetched.undecoded:
            return "ok", None, f"{fetched.undecoded} — PDF 머리 확인 생략"
        if pdf_head_ok(fetched.body):
            return "ok", None, None
        return "content_lost", None, f"PDF 가 아니다({fetched.content_type or '형식 불명'})"
    if fetched.undecoded:
        return "ok", None, f"{fetched.undecoded} — 낱말 판정 생략"
    if has_keyword(fetched.body):
        return "ok", True, None
    if expect_keyword:
        return "content_lost", False, "지난 점검에 있던 복지 낱말이 이번엔 없다"
    return "ok", False, None  # 처음부터 낱말이 없던 페이지(JS 렌더링) — 헛경보를 내지 않는다


@dataclass(frozen=True)
class RobotsVerdict:
    """robots.txt 를 읽은 결과. `kind`: rules(규칙대로) · closed(5xx·못 푸는 본문 — RFC 9309 에 따라 전면 금지) ·
    unreachable(전송 실패 — 요청하지 않고 `error`) · internal(robots.txt 나 그 리다이렉트가 내부 주소 — `error`)."""

    kind: str
    rules: RobotsRules = ALLOW_ALL
    reason: str | None = None


class RobotsCache:
    """출처(scheme+host)마다 robots.txt 를 한 번씩만 읽는다. 읽기도 요청이라 간격을 지키고, 그 리다이렉트도 홉마다
    주소를 검사한다(robots.txt 의 리다이렉트로 내부 주소를 가리키는 경우 — 검토 BLOCK-1 재현 표 마지막 줄)."""

    def __init__(self, *, http, pacer: Pacer, clock):
        self.http, self.pacer, self.clock = http, pacer, clock
        self._verdicts: dict[str, RobotsVerdict] = {}

    @staticmethod
    def origin(url: str) -> str:
        p = urlsplit(_normalize(url))
        return f"{p.scheme}://{p.netloc}"

    def load(self, url: str) -> RobotsVerdict:
        origin = self.origin(url)
        if origin in self._verdicts:
            return self._verdicts[origin]
        landed = None  # robots.txt 리다이렉트가 다른 origin 의 /robots.txt 에 닿았으면 그 origin
        try:
            got = fetch(origin + "/robots.txt", http=self.http, clock=self.clock, pacer=self.pacer,
                        headers={"User-Agent": USER_AGENT, "Accept-Encoding": ACCEPT_ENCODING},
                        limit_for=lambda _ct: ROBOTS_MAX_BYTES)
        except TooManyRedirects:
            verdict = RobotsVerdict("rules")  # RFC 9309 §2.3.1.2 — 5회를 넘으면 「없음」(허용)으로 볼 수 있다
        except InternalAddress as exc:
            verdict = RobotsVerdict("internal", reason=str(exc))
        except Exception as exc:  # noqa: BLE001 — 무엇이 터져도 본 요청을 하지 않는 쪽으로 기운다
            if _transport_failure(exc) or not isinstance(exc, CheckError):
                verdict = RobotsVerdict("unreachable", reason=describe_error(exc))
            else:  # 3xx 인데 Location 없음·http(s) 밖으로 리다이렉트 등 — 「없음」(4xx 급)
                verdict = RobotsVerdict("rules")
        else:
            final = urlsplit(got.url)
            if final.path == "/robots.txt" and f"{final.scheme}://{final.netloc}" != origin:
                landed = f"{final.scheme}://{final.netloc}"
            if 200 <= got.status < 300:
                if got.undecoded:
                    verdict = RobotsVerdict("closed", reason=f"{got.undecoded}이라 읽을 수 없다")
                else:
                    verdict = RobotsVerdict("rules", parse_robots(got.body.decode("utf-8", errors="replace")))
            elif got.status >= 500:
                verdict = RobotsVerdict("closed", reason=f"HTTP {got.status}")
            else:  # 4xx(와 그 밖) — RFC 9309 「unavailable」: 규칙 없음 = 허용
                verdict = RobotsVerdict("rules")
        self._verdicts[origin] = verdict
        if landed:  # 받은 것이 곧 그 origin 의 robots.txt 다 — http→https 리다이렉트 뒤 같은 파일을 또 받지 않는다
            self._verdicts.setdefault(landed, verdict)
        return verdict


def _ms(sec: float) -> int:
    return max(0, int(round(sec * 1000)))


def _clip(value: str | None, n: int) -> str | None:
    """칸 길이를 넘는 값은 자른다 — 엄격 모드에서 한 행이 넘치면 한 실행 전체의 INSERT 가 실패한다."""
    return value if value is None or len(value) <= n else value[: n - 1] + "…"


def check_target(target: Target, *, expect_keyword: bool, robots: RobotsCache, http, pacer: Pacer, clock) -> Result:
    """주소 하나를 점검한다. **어떤 예외도 밖으로 내지 않는다** — 남의 서버가 무슨 응답을 해도, 시드에 이상한 주소가
    한 줄 있어도 나머지 회사는 점검된다(종료 코드 계약, 모듈 머리말)."""
    try:
        return _check_target(target, expect_keyword=expect_keyword, robots=robots, http=http, pacer=pacer,
                             clock=clock)
    except Exception as exc:  # noqa: BLE001
        return Result(target, "error", detail=describe_error(exc))


def _check_target(target: Target, *, expect_keyword: bool, robots: RobotsCache, http, pacer: Pacer, clock) -> Result:
    try:
        url = _normalize(target.url)
        check_address(url)  # 시드가 내부 주소면 robots.txt 도 읽지 않는다
    except CheckError as exc:
        return Result(target, "error", detail=str(exc))
    pdf = looks_pdf(url)
    headers = {"User-Agent": USER_AGENT,
               "Accept": "application/pdf,*/*;q=0.8" if pdf else "text/html,application/xhtml+xml,*/*;q=0.8",
               "Accept-Language": "ko-KR,ko;q=0.9,en;q=0.5",  # 한국어 페이지를 본다 — 언어 협상으로 /en 에 튕기지 않게
               # PDF 는 Range 가 압축 전 바이트를 가리키게 무압축으로 청한다.
               "Accept-Encoding": "identity" if pdf else ACCEPT_ENCODING}
    if pdf:
        headers["Range"] = PDF_RANGE

    def limit_for(ctype):
        return PDF_MAX_BYTES if pdf or ctype == "application/pdf" else HTML_MAX_BYTES

    def gate(hop_url: str, hop: int) -> None:
        """홉마다 그 origin 의 robots.txt 를 묻는다(검토 MED-2 — 같은 호스트의 금지 경로도, 다른 호스트도)."""
        verdict = robots.load(hop_url)
        where = "" if hop == 0 else f"리다이렉트 목적지({_clip(hop_url, 120)})의 "
        if verdict.kind == "internal":
            raise InternalAddress(f"{where}robots.txt 가 {verdict.reason}")
        if verdict.kind == "unreachable":
            raise CheckError(f"{where}robots.txt 에 닿지 못했다({verdict.reason}) — RFC 9309 에 따라 요청하지 않았다")
        if verdict.kind == "closed":
            raise NotChecked(f"{where}robots.txt 가 {verdict.reason} — RFC 9309 에 따라 전면 금지로 보고 요청하지 않았다")
        if not verdict.rules.allows(hop_url):
            raise NotChecked(f"{where}경로를 robots.txt 가 막는다 — 요청하지 않았다" if hop
                             else "robots.txt 가 이 경로를 막는다 — 요청하지 않았다")

    meter = {"spent": 0.0}
    try:
        got = fetch(url, http=http, clock=clock, pacer=pacer, headers=headers, limit_for=limit_for, gate=gate,
                    meter=meter)
    except NotChecked as exc:
        return Result(target, "robots", detail=str(exc))
    except Exception as exc:  # noqa: BLE001 — 종료 코드 계약(모듈 머리말): 사이트 실패는 판정이지 점검기 실패가 아니다
        return Result(target, "error", elapsed_ms=_ms(meter["spent"]) if meter["spent"] else None,
                      detail=describe_error(exc))
    result_cd, keyword_yn, detail = classify(target.url, got, expect_keyword=expect_keyword)
    return Result(
        target, result_cd, http_status=got.status,
        final_url=got.url if got.url != url else None,
        content_type=got.content_type, keyword_yn=keyword_yn,
        elapsed_ms=_ms(meter["spent"]), detail=detail,
    )


def run_checks(targets: list[Target], *, expectations: dict[tuple[int, str], bool], http=urllib_get,
               clock=time.monotonic, sleep=time.sleep, on_result=None, budget: float = RUN_BUDGET_SEC) -> list[Result]:
    """전부 점검한다. robots.txt 를 **먼저 한 바퀴** 읽는다 — 한 호스트의 robots 와 본 요청 사이에 10초를 멍하니
    기다리는 대신 다른 호스트의 robots 로 그 틈을 채운다(전체 시간 ≈ 요청 수 × 3초). `on_result` 는 한 곳이 끝날
    때마다 불린다(손으로 돌릴 때 10분 동안 말이 없지 않게). 실행 예산(`budget`)을 넘기면 남은 곳은 건너뛴다."""
    started = clock()
    pacer = Pacer(clock, sleep)
    robots = RobotsCache(http=http, pacer=pacer, clock=clock)
    for t in targets:
        if clock() - started > budget:
            break
        if _address_ok(t.url):
            robots.load(t.url)
    results = []
    for t in targets:
        if clock() - started > budget:
            r = Result(t, "error", detail=f"점검 시간 예산({budget / 60:.0f}분)을 넘겨 이번 실행에서 건너뛰었다")
        else:
            r = check_target(t, expect_keyword=expectations.get((t.comp_id, t.url), False),
                             robots=robots, http=http, pacer=pacer, clock=clock)
        results.append(r)
        if on_result is not None:
            on_result(r)
    return results


# ── DB ──────────────────────────────────────────────────────────────────────

SQL_TARGETS = """
  SELECT COMP_ID, COMP_ENG_NM, COMP_NM, CAREERS_BENEFIT_URL
    FROM TCOMPANY
   WHERE CAREERS_BENEFIT_URL IS NOT NULL AND CAREERS_BENEFIT_URL <> ''"""

SQL_TABLE_EXISTS = (
    "SELECT COUNT(*) AS n FROM information_schema.TABLES "
    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'TSOURCE_CHECK'"
)

# (회사, 주소)마다 **내용을 실제로 본** 마지막 행(KEYWORD_YN 이 있는 행). MAX(CHECK_ID) = 가장 늦게 쓴 행이다 —
# 한 실행은 한 트랜잭션으로 쓰이므로 나중 실행의 행 번호가 항상 크다.
SQL_EXPECTATIONS = """
  SELECT s.COMP_ID, s.CHECK_URL, s.KEYWORD_YN, s.RESULT_CD
    FROM TSOURCE_CHECK s
    JOIN (SELECT MAX(CHECK_ID) AS CHECK_ID FROM TSOURCE_CHECK
           WHERE KEYWORD_YN IS NOT NULL GROUP BY COMP_ID, CHECK_URL) last ON last.CHECK_ID = s.CHECK_ID"""

SQL_INSERT = (
    "INSERT INTO TSOURCE_CHECK (RUN_DTM, COMP_ID, CHECK_URL, RESULT_CD, HTTP_STATUS_NO, FINAL_URL, "
    "CONTENT_TYPE_NM, KEYWORD_YN, ELAPSED_MS_NO, DETAIL_CTNT) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
)
SQL_PURGE = "DELETE FROM TSOURCE_CHECK WHERE RUN_DTM < %s"


def load_targets(conn, only: list[str] | None = None, limit: int | None = None) -> list[Target]:
    sql, params = SQL_TARGETS, []
    if only:
        sql += f" AND COMP_ENG_NM IN ({','.join(['%s'] * len(only))})"
        params += list(only)
    sql += " ORDER BY COMP_ID"
    if limit:
        sql += " LIMIT %s"
        params.append(limit)
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()
    return [Target(r["COMP_ID"], r["COMP_ENG_NM"], r["COMP_NM"], r["CAREERS_BENEFIT_URL"].strip()) for r in rows]


def table_exists(conn) -> bool:
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(SQL_TABLE_EXISTS)
        return bool(cur.fetchone()["n"])


def load_expectations(conn) -> dict[tuple[int, str], bool]:
    """(회사, 주소) → 이번에 복지 낱말을 기대하는가.

    같은 주소의 마지막 내용 관측이 「낱말 있음」이었거나 **이미 `content_lost`** 였으면 True 다. 뒤쪽이 없으면
    사라진 다음 주에 「낱말 없음」이 새 기준이 되어 `ok` 로 돌아가고, 연속 실패가 한 번에 끊겨 문제가 숨는다.
    주소가 바뀌면 기준도 새로 선다(키에 주소가 들어 있다)."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(SQL_EXPECTATIONS)
        rows = cur.fetchall()
    return {(r["COMP_ID"], r["CHECK_URL"]): bool(r["KEYWORD_YN"]) or r["RESULT_CD"] == "content_lost" for r in rows}


def _row(run_dtm: datetime, r: Result) -> tuple:
    return (
        run_dtm, r.target.comp_id, _clip(r.target.url, 500), r.result_cd, r.http_status,
        _clip(r.final_url, 500), _clip(r.content_type, 100),
        None if r.keyword_yn is None else int(r.keyword_yn), r.elapsed_ms, _clip(r.detail, 300),
    )


def record(conn, run_dtm: datetime, results: list[Result]) -> int:
    """한 실행을 **한 트랜잭션**으로 쓰고 보관 기한(180일)이 지난 행을 지운다. 지운 행 수를 돌려준다."""
    try:
        with conn.cursor() as cur:
            if results:
                cur.executemany(SQL_INSERT, [_row(run_dtm, r) for r in results])
            cur.execute(SQL_PURGE, (run_dtm - timedelta(days=RETENTION_DAYS),))
            purged = cur.rowcount
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    return purged


# ── 출력 · 진입점 ────────────────────────────────────────────────────────────

def summary_line(results: list[Result]) -> str:
    """「출처 점검 78곳: 정상 71 · 확인 필요 3(없어짐 1 · 오류 2) · 점검 안 함 4(robots 금지)」(2026-09-27 dry-run).

    0 인 판정은 괄호에 넣지 않는다. robots 금지는 「확인 필요」가 아니라 따로 센다(`ATTENTION_CODES`)."""
    counts = Counter(r.result_cd for r in results)
    attention = sum(counts[cd] for cd in ATTENTION_CODES)
    line = f"출처 점검 {len(results)}곳: 정상 {counts['ok']} · 확인 필요 {attention}"
    parts = [f"{SUMMARY_LABEL[cd]} {counts[cd]}" for cd in ATTENTION_CODES if counts[cd]]
    line += f"({' · '.join(parts)})" if parts else ""
    return line + (f" · 점검 안 함 {counts['robots']}(robots 금지)" if counts["robots"] else "")


def result_line(r: Result) -> str:
    http = str(r.http_status) if r.http_status is not None else "-"
    kw = {True: "낱말O", False: "낱말X", None: "     "}[r.keyword_yn]
    ms = f"{r.elapsed_ms}ms" if r.elapsed_ms is not None else "-"
    extra = " · ".join(x for x in (r.detail, f"최종 {r.final_url}" if r.final_url else None) if x)
    return f"  {r.result_cd:<12} {http:>4} {kw} {ms:>7}  {r.target.comp_eng_nm:<18} {r.target.url}" + (
        f"\n      {extra}" if extra else "")


def utc_now() -> datetime:
    """DB 에 넣는 시각 — UTC(서버·DB 세션 모두 UTC), 초 단위, 시간대 정보 없는 DATETIME."""
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)


def _say(line: str) -> None:
    print(line, flush=True)  # 파이프·journald 로 갈 때도 줄마다 바로 — 멈춘 실행이 어디서 멈췄는지 보이게


def main(conn, *, dry_run: bool = False, only: list[str] | None = None, limit: int | None = None,
         http=None, clock=None, sleep=None, now=None, out=None) -> int:
    """점검 한 번. 반환값 = 종료 코드(DB 실패만 1).

    `http`·`clock`·`sleep`·`now` 는 테스트 주입점이다 — 비우면 **부를 때** 모듈의 실물을 찾는다(기본 인자로 묶으면
    `ops source-check` 경로를 통째로 재는 테스트가 가짜 HTTP 계층을 끼울 수 없다).

    출력: 쓰지 않는 실행(dry-run·시험)은 한 곳이 끝날 때마다 한 줄씩, 쓰는 실행(타이머)은 끝에 문제 회사만 — 매주
    journald 에 78줄을 쌓지 않는다. 둘 다 마지막 줄 앞에 요약 한 줄이 있다."""
    http, clock, sleep, out = http or urllib_get, clock or time.monotonic, sleep or time.sleep, out or _say
    trial = bool(only) or bool(limit)
    write = not (dry_run or trial)
    run_dtm = (now or utc_now)()
    try:
        targets = load_targets(conn, only, limit)
        has_table = table_exists(conn)
        expectations = load_expectations(conn) if has_table else {}
        conn.rollback()  # 읽기 트랜잭션을 닫는다 — 점검하는 몇 분 동안 스냅숏·메타데이터 잠금을 쥐지 않게
    except pymysql.MySQLError as exc:
        out(f"출처 점검 실패: DB 읽기 — {type(exc).__name__}: {exc}")
        return 1
    if not has_table:
        if write:
            out("출처 점검 실패: TSOURCE_CHECK 표가 없다 — db/schema.sql 을 먼저 적용하라(release [2/7]).")
            return 1
        out("  (TSOURCE_CHECK 표가 없다 — 지난 결과 없이 판정한다. 쓰지 않는 실행이라 계속한다)")
    if only:
        missing = sorted(set(only) - {t.comp_eng_nm for t in targets})
        if missing:
            out(f"  (출처 주소가 없거나 없는 회사: {', '.join(missing)})")

    out(f"출처 점검 시작: {len(targets)}곳 — robots.txt 먼저, 요청 사이 {GAP_SEC:.0f}초·같은 호스트 {SAME_HOST_GAP_SEC:.0f}초"
        + ("" if write else " (쓰지 않는 실행 — 끝나는 대로 한 줄씩)"))
    results = run_checks(targets, expectations=expectations, http=http, clock=clock, sleep=sleep,
                         on_result=None if write else (lambda r: out(result_line(r))))
    if write:
        for r in results:
            if r.result_cd != "ok":
                out(result_line(r))
    out(summary_line(results))
    if not write:
        why = "--dry-run" if dry_run else "--only/--limit 은 시험용"
        out(f"  ({why} — DB 에 쓰지 않았다)")
        return 0
    try:
        conn.ping(reconnect=True)  # 점검하는 몇 분 사이 DB 가 재시작됐을 수 있다
        purged = record(conn, run_dtm, results)
    except pymysql.MySQLError as exc:
        out(f"출처 점검 실패: DB 기록 — {type(exc).__name__}: {exc}")
        return 1
    out(f"  기록 {len(results)}행 (RUN_DTM {run_dtm:%Y-%m-%d %H:%M:%S} UTC) · 보관 {RETENTION_DAYS}일 지난 {purged}행 삭제")
    return 0
