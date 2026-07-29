"""Svix 웹훅 서명 검증 (Resend 바운스 웹훅 — SP-AUTH-16, 2026-07-29 신설).

Resend 는 웹훅 전송에 Svix 를 쓴다. 검증 규약은 하나뿐이다:

    signed_content = f"{svix-id}.{svix-timestamp}.".encode() + <원문 바디 바이트>
    expected       = base64(HMAC-SHA256(base64decode(secret 에서 'whsec_' 제거), signed_content))

`svix-signature` 헤더는 `v1,<base64> v1,<base64> …` 형태로 **여러 개**가 올 수 있다(시크릿
로테이션 중). 하나라도 일치하면 통과다.

**이 모듈이 보안 경계인 이유**: 이 웹훅은 바운스를 받으면 그 주소를 억제 목록에 올려
**로그인 메일 발송을 막는다**. 검증이 뚫리면 위조 이벤트 하나로 임의 주소를 잠글 수 있다
(표적 계정 잠금 = 서비스 거부). 그래서 모든 실패 경로는 **거부**로 수렴하고, 애매한 입력은
통과가 아니라 예외다.

⚠ **원문 바디 바이트로만 검증하라.** JSON 을 파싱했다가 다시 직렬화하면 키 순서·공백이
달라져 서명이 깨진다(정상 요청이 401 이 된다). 라우터는 `await request.body()` 의 결과를
그대로 넘기고, 파싱은 **검증 통과 후에** 한다.
"""
from __future__ import annotations

import base64
import binascii
import hashlib
import hmac
import time

# Svix 표준 허용 오차. 이보다 오래된(또는 미래의) 타임스탬프는 서명이 유효해도 거부한다 —
# 유출된 과거 요청의 무기한 재생을 막는 유일한 장치다(서명 자체엔 만료가 없다).
TOLERANCE_SEC = 300

_PREFIX = "whsec_"
_VERSION = "v1"


class SignatureError(Exception):
    """서명·타임스탬프 검증 실패. 라우터가 401 로 변환한다(본문에 사유를 싣지 않는다)."""


def _decode_secret(secret: str) -> bytes:
    """`whsec_` 접두를 떼고 base64 디코드한다.

    접두 없는 값도 받는다 — Resend 대시보드가 접두를 빼고 보여주는 경우가 있고, 그때
    사용자가 `.env` 에 접두 없이 넣는 것이 자연스러운 실수라서다. 다만 **빈 값·비base64 는
    거부**한다: 시크릿 미설정이 조용한 통과가 되면 fail-closed 가 무너진다.
    """
    if not secret or not secret.strip():
        raise SignatureError("웹훅 시크릿이 비어 있다")
    body = secret[len(_PREFIX):] if secret.startswith(_PREFIX) else secret
    if not body:
        raise SignatureError("웹훅 시크릿이 접두사뿐이다")
    try:
        # validate=True: base64 알파벳 밖 문자를 조용히 버리지 않고 오류로 만든다.
        key = base64.b64decode(body, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise SignatureError("웹훅 시크릿이 base64 가 아니다") from exc
    if not key:
        raise SignatureError("웹훅 시크릿이 빈 키로 디코드됐다")
    return key


def _parse_timestamp(raw: str, now: float) -> int:
    """10진 정수만 받는다 — `1e9`·`0x10`·소수·공백 포함은 거부.

    `int()` 는 ` 123 `(공백)과 `+123` 을 조용히 받아준다. 관대한 파싱은 검증 대상 문자열과
    서명 대상 문자열이 갈라질 여지를 만들므로 원문 그대로만 인정한다.
    """
    if not raw or not raw.isdigit():
        raise SignatureError("svix-timestamp 가 10진 정수가 아니다")
    ts = int(raw)
    drift = now - ts
    if drift > TOLERANCE_SEC:
        raise SignatureError("svix-timestamp 가 허용 창보다 오래됐다(재생 의심)")
    if drift < -TOLERANCE_SEC:
        raise SignatureError("svix-timestamp 가 미래다(시계 스큐 초과)")
    return ts


def _candidate_signatures(header: str) -> list[str]:
    """`v1,<b64> v2,<b64> …` 에서 v1 서명만 추려낸다. 하나도 없으면 거부."""
    found = []
    for part in (header or "").split():
        version, _, sig = part.partition(",")
        if version == _VERSION and sig:
            found.append(sig)
    if not found:
        raise SignatureError("svix-signature 에 v1 서명이 없다")
    return found


def verify_svix(
    *,
    secret: str,
    svix_id: str,
    svix_timestamp: str,
    body: bytes,
    signature_header: str,
    now: float | None = None,
) -> None:
    """검증 성공 시 조용히 반환, 실패 시 `SignatureError`.

    반환값을 bool 로 두지 않는 것은 의도적이다 — 호출부가 `if verify(...)` 를 빼먹어도
    **통과로 오독되지 않게** 하기 위해서다(무시할 수 없는 실패).
    """
    key = _decode_secret(secret)
    _parse_timestamp(svix_timestamp, time.time() if now is None else now)
    candidates = _candidate_signatures(signature_header)

    signed = f"{svix_id}.{svix_timestamp}.".encode() + body
    expected = base64.b64encode(hmac.new(key, signed, hashlib.sha256).digest()).decode()

    # 타이밍 누출 방지 — 후보 전부를 상수시간으로 비교하고, 일치를 찾아도 즉시 빠져나가지
    # 않는다(조기 반환은 "몇 번째에서 맞았는가"를 시간으로 흘린다).
    ok = False
    for candidate in candidates:
        if hmac.compare_digest(candidate, expected):
            ok = True
    if not ok:
        raise SignatureError("서명 불일치")
