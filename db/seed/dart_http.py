"""db/seed/dart_http.py — DART 전송 계층 한 곳. **일시적 실패를 재시도한다.**

왜 별도 모듈인가: 재시도 정책은 `dart_employ.py` 와 `dart_finance.py` 가 **똑같이** 따라야 하는
규칙이고, 두 파일에 각각 적으면 언젠가 한쪽만 고쳐진다(이 저장소가 반복해서 밟은 함정).

왜 재시도가 필요한가 — 2026-08-28 실사고:
  직원 수집(법인 100 × 11개년 = 1,100 호출)이 **셀트리온 2016 한 번의 `urlopen error timed out`**
  으로 통째로 죽었다. 재시도가 없어 20분 실행이 0행으로 끝났고, 커밋이 마지막에 한 번뿐이라
  그때까지 받은 것도 전부 사라졌다. 외부 API 를 수천 번 두드리는 작업에서 일시적 오류는
  **예외 상황이 아니라 정상 분포의 꼬리**다.

무엇을 재시도하고 무엇을 안 하는가:
  · 재시도한다 — 전송 계층 오류(타임아웃·연결 끊김·DNS)와 서버가 "나중에 다시"라고 말하는 상태
    코드(429·5xx). 다시 하면 될 수 있는 것들이다.
  · ⛔ 재시도하지 않는다 — 4xx(400·401·403 등). 키가 틀렸거나 요청이 틀린 것이라 100번 해도 같다.
    조용히 세 번 더 두드려 로그만 늘리고 실패는 그대로다.
  · ⛔ DART **응답 본문의 status 코드**(013 데이터 없음 등)는 여기까지 오지 않는다. 그건 정상
    응답이고 각 수집기가 해석한다 — 전송 실패와 섞으면 "데이터 없음"을 세 번씩 다시 묻게 된다.

재시도는 **말하고** 한다(stderr). 조용한 재시도는 느려진 이유를 아무도 모르게 만든다.
"""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request

ATTEMPTS = 4  # 첫 시도 + 재시도 3회
BACKOFF_SEC = 1.5  # 1.5s → 3s → 6s (지수). 총 대기 최대 10.5초 — 한 호출이 붙잡는 시간의 상한이다
RETRY_STATUS = (429, 500, 502, 503, 504)


def is_transient(exc: BaseException) -> bool:
    """다시 하면 될 수 있는 실패인가.

    `HTTPError` 가 `URLError` 의 하위 클래스라 **순서가 중요하다** — 먼저 걸러내지 않으면
    404·401 까지 전송 오류로 보고 재시도하게 된다.
    """
    if isinstance(exc, urllib.error.HTTPError):
        return exc.code in RETRY_STATUS
    return isinstance(exc, (urllib.error.URLError, TimeoutError, ConnectionError, OSError))


def fetch_json(url: str, *, timeout: float = 20.0, user_agent: str,
               attempts: int = ATTEMPTS, backoff: float = BACKOFF_SEC,
               sleep_fn=time.sleep, opener=urllib.request.urlopen) -> dict:
    """GET → JSON dict. 일시적 실패는 지수 백오프로 재시도하고, 마지막 예외를 그대로 올린다.

    마지막 예외를 **감싸지 않고** 올리는 이유: 호출자가 키를 가린 채 메시지를 만들고 있고,
    여기서 한 겹 더 감싸면 그 마스킹이 원본 URL 이 든 문자열을 놓칠 수 있다.
    `sleep_fn`·`opener` 는 테스트 주입점이다 — 재시도 테스트가 실제로 기다리면 스위트가 느려진다.
    """
    req = urllib.request.Request(url, headers={"User-Agent": user_agent})
    for attempt in range(attempts):
        try:
            with opener(req, timeout=timeout) as resp:  # noqa: S310 — 고정 https 호스트
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:  # noqa: BLE001 — 판정은 `is_transient` 하나가 한다
            if attempt == attempts - 1 or not is_transient(exc):
                raise
            wait = backoff * (2 ** attempt)
            print(f"  · DART 일시 오류({type(exc).__name__}) — {wait:.1f}초 후 재시도 "
                  f"{attempt + 2}/{attempts}", file=sys.stderr)
            sleep_fn(wait)
    raise AssertionError("도달 불가")  # 루프는 반환하거나 던진다
