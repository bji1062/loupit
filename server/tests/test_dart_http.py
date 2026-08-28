"""DART 전송 계층 재시도 — `db/seed/dart_http.py` (2026-08-28 실사고 대응).

**왜 이 파일이 있는가.** 직원 수집(법인 100 × 11개년 = 1,100 호출)이 셀트리온 2016 한 번의
`urlopen error timed out` 으로 통째로 죽었다. 재시도가 없었고, 커밋이 끝에 한 번뿐이라 그때까지
받은 것도 전부 사라져 **0행**으로 끝났다. 수천 번 두드리는 작업에서 일시적 오류는 예외가 아니라
정상 분포의 꼬리다.

여기서 못박는 것은 두 가지다.
  1. **다시 하면 될 것만** 다시 한다 — 4xx 를 재시도하면 틀린 키로 네 번 두드리고 똑같이 실패한다.
  2. 재시도는 **말하고** 한다. 조용히 기다리면 수집이 왜 느린지 아무도 모른다.

실제로 기다리지 않기 위해 `sleep_fn`·`opener` 를 주입한다 — 스위트가 백오프만큼 느려지면
다음 사람이 이 테스트를 지운다.
"""
from __future__ import annotations

import json
import sys
import urllib.error
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import dart_http  # noqa: E402  # db/seed/dart_http.py

URL = "https://opendart.fss.or.kr/api/x.json?crtfc_key=secret"


class _Resp:
    def __init__(self, payload):
        self._b = json.dumps(payload).encode("utf-8")

    def read(self):
        return self._b

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


def _opener(script):
    """호출마다 `script` 의 다음 항목을 낸다 — 예외면 던지고, dict 면 응답으로 준다."""
    calls = []

    def open_(req, timeout=None):
        item = script[len(calls)]
        calls.append(req)
        if isinstance(item, BaseException):
            raise item
        return _Resp(item)

    open_.calls = calls
    return open_


def _http(code):
    return urllib.error.HTTPError(URL, code, "boom", {}, None)


# ── 무엇이 일시적인가 ────────────────────────────────────────────────────────

@pytest.mark.parametrize("exc", [
    urllib.error.URLError("timed out"),
    TimeoutError("timed out"),
    ConnectionResetError("peer"),
    _http(429), _http(500), _http(502), _http(503), _http(504),
])
def test_transient_errors_are_worth_retrying(exc):
    assert dart_http.is_transient(exc) is True


@pytest.mark.parametrize("exc", [_http(400), _http(401), _http(403), _http(404), ValueError("bad json")])
def test_permanent_errors_are_not_retried(exc):
    """4xx 는 요청·키가 틀린 것이다. 네 번 두드려도 같은 답이 오고 로그만 늘어난다.

    ⚠ `HTTPError` 는 `URLError` 의 하위 클래스라, 먼저 걸러내지 않으면 404 까지 전송 오류가 된다.
    """
    assert dart_http.is_transient(exc) is False


# ── 재시도 동작 ──────────────────────────────────────────────────────────────

def test_retries_then_succeeds_and_returns_the_payload():
    """실사고의 재현 — 첫 호출이 타임아웃이어도 수집이 죽지 않는다."""
    waits = []
    op = _opener([urllib.error.URLError("timed out"), {"status": "000", "list": [1]}])
    got = dart_http.fetch_json(URL, user_agent="t", sleep_fn=waits.append, opener=op)
    assert got == {"status": "000", "list": [1]}
    assert len(op.calls) == 2
    assert waits == [dart_http.BACKOFF_SEC]


def test_backoff_grows_and_the_last_failure_is_raised_unwrapped():
    """마지막 예외를 감싸지 않는 이유: 호출자가 키를 가린 채 메시지를 만든다."""
    waits = []
    boom = urllib.error.URLError("timed out")
    op = _opener([boom] * dart_http.ATTEMPTS)
    with pytest.raises(urllib.error.URLError) as ei:
        dart_http.fetch_json(URL, user_agent="t", sleep_fn=waits.append, opener=op)
    assert ei.value is boom
    assert len(op.calls) == dart_http.ATTEMPTS
    assert waits == [dart_http.BACKOFF_SEC * (2 ** i) for i in range(dart_http.ATTEMPTS - 1)]


def test_permanent_failure_costs_exactly_one_call():
    op = _opener([_http(401)])
    with pytest.raises(urllib.error.HTTPError):
        dart_http.fetch_json(URL, user_agent="t", sleep_fn=lambda _: None, opener=op)
    assert len(op.calls) == 1


def test_retry_says_so_on_stderr(capsys):
    """조용한 재시도는 수집이 왜 느린지 아무도 모르게 만든다."""
    op = _opener([urllib.error.URLError("timed out"), {"status": "000"}])
    dart_http.fetch_json(URL, user_agent="t", sleep_fn=lambda _: None, opener=op)
    err = capsys.readouterr().err
    assert "재시도" in err and "URLError" in err


def test_user_agent_is_sent():
    op = _opener([{"status": "000"}])
    dart_http.fetch_json(URL, user_agent="loupit-dart-employ/1.0", sleep_fn=lambda _: None, opener=op)
    assert op.calls[0].get_header("User-agent") == "loupit-dart-employ/1.0"


def test_both_collectors_share_this_transport():
    """정책이 두 수집기에 흩어지면 언젠가 한쪽만 고쳐진다 — 그래서 둘 다 이 모듈을 부른다."""
    import dart_employ
    import dart_finance

    for mod in (dart_employ, dart_finance):
        src = Path(mod.__file__).read_text(encoding="utf-8")
        assert "dart_http.fetch_json(" in src, mod.__name__
        assert "urllib.request.urlopen" not in src, f"{mod.__name__} 이 전송을 직접 한다 — 재시도를 우회한다"
