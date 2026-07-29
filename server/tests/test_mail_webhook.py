"""Resend 바운스 웹훅 (SP-AUTH-16 · P1-4, 2026-07-29 신설).

**왜 만드는가**: Resend API 키가 발송 전용이라 배달 결과를 조회할 수 없다
(`GET /emails` → `restricted_api_key` 401). 그래서 게이트웨이가 거부·격리해도 앱은 영영
모른다 — 화면엔 "코드를 보냈습니다"가 뜨는데 메일은 안 갔고, 그 사용자는 로그인을 아예 못 한다.
웹훅은 읽기 권한 없이 제공자가 결과를 밀어주는 유일한 경로다(전권 키는 본문까지 읽히므로 기각).

**무 DB** — `database.execute/fetch_one` 을 monkeypatch 해 SQL·파라미터·상태코드만 본다
(test_auth_code 와 동일 규약). 원문 이메일이 저장 파라미터에 새지 않음(INV-8·T9)이 핵심 게이트.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time

import pytest
from fastapi.routing import APIRoute

from server.services import mail_events

SECRET_RAW = b"webhook-test-secret-0123456789ab"
SECRET = "whsec_" + base64.b64encode(SECRET_RAW).decode()
RECIPIENT = "bounced.user@example.com"


def _now() -> int:
    """라우터는 **실시간** 신선도(±300s)를 검사한다 — 고정 타임스탬프를 쓰면 시간이 지날수록
    전 테스트가 재생 방어에 걸려 깨진다(초판이 실제로 그랬다: 2027년 값이 '미래' 로 거부됨).
    서명 단위 테스트(test_webhook_sig)만 `now` 를 주입해 경계를 고정한다."""
    return int(time.time())


def _headers(body: bytes, msg_id: str = "msg_1", ts: int | None = None) -> dict:
    ts = _now() if ts is None else ts
    signed = f"{msg_id}.{ts}.".encode() + body
    sig = base64.b64encode(hmac.new(SECRET_RAW, signed, hashlib.sha256).digest()).decode()
    return {"svix-id": msg_id, "svix-timestamp": str(ts), "svix-signature": "v1," + sig}


def _payload(event_type: str = "email.bounced", *, bounce: dict | None = None, to=RECIPIENT) -> bytes:
    data = {"email_id": "e_123", "from": "no-reply@jobcho.wiki", "subject": "[jobcho.wiki] 로그인 코드"}
    if to is not None:
        data["to"] = to
    if bounce is not None:
        data["bounce"] = bounce
    return json.dumps({"type": event_type, "created_at": "2026-07-29T01:02:03.000Z", "data": data}).encode()


HARD = {"type": "Permanent", "subType": "General", "message": "Mailbox does not exist"}
SOFT = {"type": "Transient", "subType": "MailboxFull", "message": "Mailbox full"}


@pytest.fixture
def app_factory(monkeypatch):
    """시크릿 값을 바꿔 앱을 조립하는 팩토리(test_m9_gate.app_with_m9 와 같은 규약)."""
    from server.config import get_settings
    from server.main import create_app

    def _make(secret: str | None, *, m9: str | None = None):
        # ⚠ `None`(미설정)을 `delenv` 로 표현하면 **안 된다**(2026-07-29 실측): pydantic 이
        #   `server/.env` 를 다시 읽으므로, 운영 서버처럼 파일에 시크릿이 있으면 지워도 되살아나
        #   MW-1(라우터 부재)이 깨진다. 프로세스 환경변수가 dotenv 보다 우선하므로 **빈 문자열로
        #   덮어야** '미설정'이 재현된다.
        monkeypatch.setenv("RESEND_WEBHOOK_SECRET", "" if secret is None else secret)
        if m9 is None:
            monkeypatch.delenv("M9_ENABLED", raising=False)
        else:
            monkeypatch.setenv("M9_ENABLED", m9)
        get_settings.cache_clear()
        return create_app()

    yield _make
    get_settings.cache_clear()


@pytest.fixture
def spy_db(monkeypatch):
    """`database.execute`/`fetch_one` 을 가로채 SQL·파라미터를 수집한다."""
    calls: list[tuple[str, tuple]] = []

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    async def _fetch_one(sql, params=()):
        calls.append((sql, params))
        return None

    monkeypatch.setattr("server.database.execute", _exec)
    monkeypatch.setattr("server.database.fetch_one", _fetch_one)
    return calls


async def _post(app, body: bytes, headers: dict):
    import httpx

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:
        return await c.post("/api/v1/webhooks/resend", content=body, headers=headers)


# ── 등록 게이트(fail-closed) ──────────────────────────────────────────────────
def test_MW1_route_absent_without_secret(app_factory):
    """시크릿 미설정이면 **라우터 자체를 등록하지 않는다**.

    이게 fail-closed 의 핵심이다: 검증할 수 없는 상태에서 엔드포인트가 열려 있으면 누구나
    위조 바운스를 밀어넣어 **임의 주소의 로그인을 영구 차단**할 수 있다(표적 잠금).
    또한 이 성질 덕에 현 프로덕션의 익명 표면(INV-1)은 **기본값에서 변하지 않는다**."""
    paths = {r.path for r in app_factory(None).routes if isinstance(r, APIRoute)}
    assert "/api/v1/webhooks/resend" not in paths


def test_MW1b_route_present_with_secret_even_when_m9_off(app_factory):
    """시크릿이 있으면 **M9 가 꺼져 있어도** 등록된다 — prod(M9 OFF)가 수신 호스트이기 때문."""
    app = app_factory(SECRET, m9=None)
    routes = {(r.path, m) for r in app.routes if isinstance(r, APIRoute) for m in r.methods}
    assert ("/api/v1/webhooks/resend", "POST") in routes
    # M9 는 여전히 꺼져 있어야 한다(웹훅이 참여 라우터를 딸려오지 않는다)
    assert not any("/members" in p for p, _ in routes), "웹훅 등록이 M9 표면을 함께 열었다"


# ── 서명 ─────────────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MW2_valid_signature_records_event(app_factory, spy_db):
    body = _payload(bounce=HARD)
    r = await _post(app_factory(SECRET), body, _headers(body))
    assert r.status_code == 200
    assert any("TMAIL_EVENT" in sql for sql, _ in spy_db), "이벤트 원장 INSERT 부재"


@pytest.mark.asyncio
async def test_MW3_bad_signature_rejected_and_writes_nothing(app_factory, spy_db):
    """위조는 401 이고 **DB 를 건드리지 않는다** — 검증 전 부작용 0."""
    body = _payload(bounce=HARD)
    h = _headers(body)
    h["svix-signature"] = "v1," + base64.b64encode(b"z" * 32).decode()
    r = await _post(app_factory(SECRET), body, h)
    assert r.status_code == 401
    assert not spy_db, f"서명 실패인데 DB 접근 발생: {spy_db}"


@pytest.mark.asyncio
async def test_MW3b_body_must_be_verified_raw(app_factory, spy_db):
    """원문 바이트로 검증한다 — 파싱→재직렬화하면 공백·키 순서가 달라져 정상 요청이 401 이 된다.

    아래 본문은 일부러 **들여쓰기와 키 순서가 표준 직렬화와 다르다**. 라우터가 `request.body()`
    를 그대로 검증하면 통과하고, `json.dumps(parsed)` 로 다시 만들면 실패한다."""
    body = b'{  "data" : {"to": "x@example.com", "email_id":"e1"} ,\n  "type":"email.delivered"  }'
    r = await _post(app_factory(SECRET), body, _headers(body))
    assert r.status_code == 200


# ── 멱등 ─────────────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MW4_duplicate_delivery_is_idempotent(app_factory, spy_db):
    """at-least-once 배달 — 같은 `svix-id` 가 두 번 와도 원장은 1행이어야 한다.

    구현은 `INSERT IGNORE`(복합 UNIQUE)라 애플리케이션 레이스에도 안전하다. `SELECT` 후
    `INSERT` 하는 검사-후-행동은 동시 재전송에서 둘 다 통과한다."""
    body = _payload(bounce=HARD)
    app = app_factory(SECRET)
    r1 = await _post(app, body, _headers(body))
    r2 = await _post(app, body, _headers(body))
    assert r1.status_code == r2.status_code == 200
    inserts = [sql for sql, _ in spy_db if "TMAIL_EVENT" in sql and "INSERT" in sql.upper()]
    assert all("IGNORE" in sql.upper() or "ON DUPLICATE" in sql.upper() for sql in inserts), (
        "중복 제거가 UNIQUE 제약이 아니라 검사-후-행동이면 동시 재전송에서 이중 기록된다"
    )


# ── 억제 판정(순수 함수) ──────────────────────────────────────────────────────
def test_MW5_suppression_rules():
    """무엇이 억제를 유발하는가 — **되돌리기 어려운 결정이라 보수적으로** 판정한다."""
    assert mail_events.suppression_reason("email.bounced", HARD) == "hard_bounce"
    assert mail_events.suppression_reason("email.complained", None) == "complaint"
    assert mail_events.suppression_reason("email.suppressed", None) == "suppressed"

    # 일시 실패는 억제하지 않는다 — 메일함이 잠깐 찬 사용자를 영구 차단하면 안 된다.
    assert mail_events.suppression_reason("email.bounced", SOFT) is None
    assert mail_events.suppression_reason("email.delivery_delayed", None) is None
    assert mail_events.suppression_reason("email.failed", None) is None
    assert mail_events.suppression_reason("email.delivered", None) is None
    assert mail_events.suppression_reason("email.sent", None) is None

    # 정보가 애매하면 억제하지 않는다(락아웃보다 재발송이 낫다).
    assert mail_events.suppression_reason("email.bounced", None) is None
    assert mail_events.suppression_reason("email.bounced", {"type": "Undetermined"}) is None
    assert mail_events.suppression_reason("email.bounced", {"subType": "General"}) is None


def test_MW5b_bounce_type_is_case_insensitive():
    """제공자 표기 흔들림(Permanent/permanent/PERMANENT)에 판정이 갈리지 않게 한다."""
    for v in ("Permanent", "permanent", "PERMANENT", " Permanent "):
        assert mail_events.suppression_reason("email.bounced", {"type": v}) == "hard_bounce"


@pytest.mark.asyncio
async def test_MW6_hard_bounce_suppresses(app_factory, spy_db):
    body = _payload("email.bounced", bounce=HARD)
    await _post(app_factory(SECRET), body, _headers(body))
    assert any("TMAIL_SUPPRESSION" in sql for sql, _ in spy_db), "하드 바운스인데 억제 미등록"


@pytest.mark.asyncio
async def test_MW7_soft_bounce_does_not_suppress(app_factory, spy_db):
    body = _payload("email.bounced", bounce=SOFT)
    await _post(app_factory(SECRET), body, _headers(body))
    assert any("TMAIL_EVENT" in sql for sql, _ in spy_db), "일시 바운스도 원장에는 남아야 한다"
    assert not any("TMAIL_SUPPRESSION" in sql for sql, _ in spy_db), "일시 바운스가 억제를 걸었다"


# ── 원문 무저장 ───────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MW8_plaintext_recipient_never_stored(app_factory, spy_db):
    """저장 파라미터 어디에도 평문 수신자·본문이 없어야 한다(INV-8·T9·NFR30).

    웹훅 페이로드는 평문 주소를 실어 오므로, 편의로 그대로 넣는 실수가 가장 나기 쉽다."""
    body = _payload(bounce=HARD)
    await _post(app_factory(SECRET), body, _headers(body))
    flat = " ".join(repr(p) for _, p in spy_db)
    assert RECIPIENT not in flat, f"평문 수신자가 저장 파라미터에 노출: {flat}"
    assert "example.com" not in flat

    # 해시는 auth_code 와 **같은 규칙**이어야 발송 기록과 상관관계가 잡힌다.
    from server.services.auth_code import _hash_target

    assert _hash_target(RECIPIENT) in flat, "TAUTH_CODE 와 다른 해시 규칙 — 조인이 0건이 된다"


@pytest.mark.asyncio
async def test_MW8b_recipient_hash_folds_plus_tag_and_dots(app_factory, spy_db):
    """`+태그`·구글 도트 변형이 같은 수신함으로 접힌다 — 억제 우회 방지(배달주소 기준)."""
    from server.services.auth_code import _delivery_address

    assert _delivery_address("a+tag@gmail.com") == _delivery_address("a@gmail.com")


# ── 무시·오류 경로 ────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MW9_non_email_or_recipientless_events_ignored_with_200(app_factory, spy_db):
    """수신자가 없는 이벤트(domain.*·contact.*)는 **200 으로 조용히 무시**한다.

    4xx 를 주면 제공자가 재시도 큐에 계속 쌓아 무한 재전송이 된다 — 우리가 처리할 것이
    없다는 사실은 오류가 아니다."""
    for body in (_payload("domain.created", to=None), _payload("contact.updated", to=None)):
        r = await _post(app_factory(SECRET), body, _headers(body))
        assert r.status_code == 200
    assert not any("TMAIL_EVENT" in sql for sql, _ in spy_db), "수신자 없는 이벤트가 원장에 들어갔다"


@pytest.mark.asyncio
async def test_MW10_malformed_json_rejected(app_factory, spy_db):
    """서명은 맞는데 본문이 JSON 이 아니면 400 — 서명 통과가 곧 형식 보장은 아니다."""
    body = b"not-json{{{"
    r = await _post(app_factory(SECRET), body, _headers(body))
    assert r.status_code == 400
    assert not any("TMAIL_EVENT" in sql for sql, _ in spy_db)


@pytest.mark.asyncio
async def test_MW11_multiple_recipients_all_recorded(app_factory, spy_db):
    """`to` 가 배열이면 전원을 기록한다 — 복합 UNIQUE 라 두 번째 이후가 삼켜지지 않는다."""
    body = _payload("email.bounced", bounce=HARD, to=["a@example.com", "b@example.com"])
    await _post(app_factory(SECRET), body, _headers(body))
    from server.services.auth_code import _hash_target

    flat = " ".join(repr(p) for _, p in spy_db)
    assert _hash_target("a@example.com") in flat and _hash_target("b@example.com") in flat


@pytest.mark.asyncio
async def test_MW12_no_cache_header(app_factory, spy_db):
    """응답은 캐시 금지(SP-API-12 공통 규약)."""
    body = _payload(bounce=HARD)
    r = await _post(app_factory(SECRET), body, _headers(body))
    assert r.headers.get("cache-control") == "no-store"
