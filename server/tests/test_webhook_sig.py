"""Svix 웹훅 서명 검증 (P1-4 바운스 웹훅, 2026-07-29 신설).

**왜 직접 구현하는가**: Svix 공식 SDK 는 신규 의존성이고, 이 프로젝트는 인증 라이브러리
도입을 의도적으로 피해 왔다(`server/requirements.txt` 머리말). 검증 알고리즘은
`HMAC-SHA256(secret, f"{id}.{timestamp}.{body}")` 하나뿐이라 stdlib(`hmac`·`hashlib`·
`base64`)로 완결된다 — 새 공급망 위험을 지지 않는다.

**왜 서명이 절대적인가**: 이 엔드포인트는 바운스를 받으면 해당 주소를 **억제 목록에 올린다**.
검증이 약하면 공격자가 위조 바운스 하나로 **임의 주소의 로그인을 영구 차단**할 수 있다
(표적 계정 잠금). 그래서 아래 테스트는 "통과해야 하는 것" 보다 **"반드시 거부해야 하는 것"**
쪽이 훨씬 많다.
"""
from __future__ import annotations

import base64
import hashlib
import hmac

import pytest

from server.services.webhook_sig import SignatureError, verify_svix

# whsec_ 뒤는 base64. 테스트 전용 더미 키(운영 시크릿과 무관).
_SECRET_RAW = b"loupit-test-secret-0123456789abcdef"
SECRET = "whsec_" + base64.b64encode(_SECRET_RAW).decode()

MSG_ID = "msg_2abcDEF"
TS = 1_800_000_000  # 고정 시각(테스트는 now 를 주입하므로 실시간과 무관)
BODY = b'{"type":"email.bounced","data":{"email_id":"e1"}}'


def _sign(body: bytes, *, secret_raw: bytes = _SECRET_RAW, msg_id: str = MSG_ID, ts: int = TS) -> str:
    """Svix 규약대로 서명 헤더를 만든다 — `v1,<base64(HMAC-SHA256)>`."""
    signed = f"{msg_id}.{ts}.".encode() + body
    mac = hmac.new(secret_raw, signed, hashlib.sha256).digest()
    return "v1," + base64.b64encode(mac).decode()


def _verify(**kw):
    """기본 인자로 검증 1회 — 개별 테스트는 바꿀 것만 넘긴다."""
    args = {
        "secret": SECRET,
        "svix_id": MSG_ID,
        "svix_timestamp": str(TS),
        "body": BODY,
        "signature_header": _sign(BODY),
        "now": TS,
    }
    args.update(kw)
    return verify_svix(**args)


# ── 통과해야 하는 것 ──────────────────────────────────────────────────────────
def test_WS1_valid_signature_passes():
    _verify()  # 예외 없음 = 통과


def test_WS2_multiple_signatures_one_valid_passes():
    """Svix 는 시크릿 로테이션 중 서명을 **공백 구분으로 여러 개** 보낸다.

    하나라도 맞으면 통과여야 한다 — 전부 일치를 요구하면 로테이션 때 전 이벤트가 유실된다."""
    bogus = "v1," + base64.b64encode(b"x" * 32).decode()
    _verify(signature_header=f"{bogus} {_sign(BODY)}")


def test_WS3_unknown_version_ignored_but_v1_honored():
    """미래 버전(v2 등)이 섞여도 v1 만 보고 판정한다."""
    _verify(signature_header=f"v2,{base64.b64encode(b'y' * 32).decode()} {_sign(BODY)}")


def test_WS4_timestamp_within_tolerance_passes():
    _verify(now=TS + 299)
    _verify(now=TS - 299)


# ── 반드시 거부해야 하는 것 ───────────────────────────────────────────────────
def test_WS5_tampered_body_rejected():
    """본문 1바이트만 바뀌어도 서명이 완전히 달라진다 — 페이로드 변조 차단."""
    with pytest.raises(SignatureError):
        _verify(body=BODY.replace(b"email.bounced", b"email.complained"))


def test_WS6_tampered_id_rejected():
    """`svix-id` 가 서명 대상이라, id 만 바꿔치기한 재생(replay)도 막힌다."""
    with pytest.raises(SignatureError):
        _verify(svix_id="msg_forged")


def test_WS7_tampered_timestamp_rejected():
    with pytest.raises(SignatureError):
        _verify(svix_timestamp=str(TS + 1))


def test_WS8_wrong_secret_rejected():
    with pytest.raises(SignatureError):
        _verify(signature_header=_sign(BODY, secret_raw=b"wrong-secret"))


def test_WS9_replay_outside_tolerance_rejected():
    """오래된 이벤트 재생 차단 — 서명이 유효해도 시각이 창 밖이면 거부한다.

    미래 방향도 막는다(시계 스큐를 빙자한 무기한 유효 서명 방지)."""
    with pytest.raises(SignatureError):
        _verify(now=TS + 301)
    with pytest.raises(SignatureError):
        _verify(now=TS - 301)


def test_WS10_missing_or_malformed_headers_rejected():
    for bad in ("", "   ", "garbage", "v1", "v1,", ",abc"):
        with pytest.raises(SignatureError):
            _verify(signature_header=bad)


def test_WS11_non_numeric_timestamp_rejected():
    for bad in ("", "abc", "1e9", "0x10", " 1800000000 ", "1800000000.5"):
        with pytest.raises(SignatureError):
            _verify(svix_timestamp=bad)


def test_WS12_empty_secret_rejected():
    """시크릿 미설정으로 검증이 **통과해 버리는** 최악을 막는다(fail-closed)."""
    for bad in ("", "   ", "whsec_", "not-base64!@#", "whsec_!!!"):
        with pytest.raises(SignatureError):
            _verify(secret=bad)


def test_WS12b_secret_with_invalid_base64_chars_rejected_strictly():
    """`b64decode(validate=True)` 를 강제한다 — **오타 시크릿의 조용한 재해석**을 막는다.

    ⚠ **이 테스트가 `verify_svix` 가 아니라 `_decode_secret` 을 직접 부르는 이유**(뮤테이션
    2회로 배운 것): `verify_svix` 로는 이 회귀를 원리적으로 잡을 수 없다. 잘못된 시크릿은
    **어차피 서명 불일치로 같은 `SignatureError`** 를 내므로, `pytest.raises` 는 "시크릿을
    거부했다"와 "서명이 안 맞았다"를 구분하지 못한다 — 두 뮤턴트가 그래서 살아남았다.
    강도를 소유한 단위를 직접 검증해야 판정이 성립한다.

    실질 피해: `validate` 없이는 파이썬이 알파벳 밖 문자를 **조용히 버려** 오타 시크릿이
    *다른 키* 로 받아들여진다. 그러면 정상 웹훅이 전부 401 로 죽는데 원인은 어디에도
    안 남는다(설정 오류가 런타임 미스터리로 둔갑).
    """
    from server.services.webhook_sig import _decode_secret

    valid_b64 = base64.b64encode(_SECRET_RAW).decode()
    # 잘못된 문자를 버리면 길이가 맞아떨어져 **조용히 디코드되는** 형태들.
    for bad in ("ab!!cd!!", "wh!sec_" + valid_b64, valid_b64[:-1] + " " + valid_b64[-1:]):
        with pytest.raises(SignatureError):
            _decode_secret(bad)

    # 대조군: 정상 시크릿은 접두 유무와 무관하게 같은 키로 디코드된다(WS14 와 짝).
    assert _decode_secret(SECRET) == _SECRET_RAW == _decode_secret(valid_b64)


def test_WS13_signature_compared_in_constant_time(monkeypatch):
    """타이밍 공격 방어 — 비교는 반드시 `hmac.compare_digest` 로 한다.

    `==` 로 바꾸면 이 테스트가 잡는다(뮤테이션 가드)."""
    calls = []
    real = hmac.compare_digest

    def spy(a, b):
        calls.append((a, b))
        return real(a, b)

    monkeypatch.setattr("server.services.webhook_sig.hmac.compare_digest", spy)
    _verify()
    assert calls, "서명 비교에 hmac.compare_digest 를 쓰지 않았다(타이밍 누출)"


def test_WS14_secret_without_prefix_also_accepted():
    """Resend 대시보드가 `whsec_` 없이 보여주는 경우가 있어 접두 없는 값도 받는다.

    단 base64 로 디코드되지 않으면 거부한다(WS12)."""
    raw_b64 = base64.b64encode(_SECRET_RAW).decode()
    _verify(secret=raw_b64)
