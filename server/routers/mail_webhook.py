"""Resend(Svix) 메일 배달 웹훅 — `POST /webhooks/resend` (SP-AUTH-16 · P1-4, 2026-07-29).

**이 라우터는 조건부 등록이다**: `RESEND_WEBHOOK_SECRET` 이 비면 `main.create_app` 이 아예
등록하지 않는다(fail-closed). 검증할 수 없는 채로 열려 있으면 위조 바운스 한 건으로 임의
주소의 로그인을 영구 차단할 수 있기 때문이다. **M9 스위치와는 무관**하다 — 수신 호스트는
prod(M9 OFF)이고, 지금 실발송하는 beta 와 발신 도메인·무료 티어를 공유하므로 억제 목록은
한 곳에 모여야 한다.

**엣지 계약(중요)**: 이 경로는 nginx `^~ /api/v1/` 의 Layer A(`X-Loupit-Client` 요구)에서
**면제**돼야 한다 — 제공자가 그 헤더를 붙일 리 없다. `= /api/v1/health` 예외와 같은 패턴으로
`= /api/v1/webhooks/resend` 블록을 둔다(SP-INFRA-3.4.8). 면제해도 안전한 근거는 **서명**이다:
헤더 게이트가 아니라 HMAC 이 이 엔드포인트의 인증이다.

**상태코드 규약**: 제공자는 2xx 가 아니면 재시도 큐에 쌓는다.
  - 200 — 처리했거나, 우리가 처리할 것이 없는 이벤트(무시)
  - 400 — 서명은 맞는데 본문이 JSON 이 아님(재시도해도 같으므로 알린다)
  - 401 — 서명 검증 실패(위조·시크릿 불일치). 재시도돼도 계속 401 이어야 정상이다
"""
from __future__ import annotations

import json
import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse

from server.config import get_settings
from server.services import mail_events
from server.services.webhook_sig import SignatureError, verify_svix

logger = logging.getLogger(__name__)

router = APIRouter(tags=["webhooks"])

_NO_STORE = {"Cache-Control": "no-store"}


def _recipients(raw) -> list[str]:
    """`data.to` 는 문자열 또는 배열이다. 공백·빈 값은 버린다."""
    if isinstance(raw, str):
        raw = [raw]
    if not isinstance(raw, list):
        return []
    return [x.strip() for x in raw if isinstance(x, str) and x.strip()]


@router.post("/webhooks/resend", status_code=200)
async def resend_webhook(request: Request) -> JSONResponse:
    s = get_settings()
    # ⚠ **원문 바이트로 검증한다.** 파싱 후 재직렬화하면 공백·키 순서가 달라져 서명이 깨진다
    #   (정상 요청이 401 이 되고, 원인은 로그 어디에도 안 남는다). 파싱은 검증 **뒤**에 한다.
    raw = await request.body()
    try:
        verify_svix(
            secret=s.resend_webhook_secret,
            svix_id=request.headers.get("svix-id", ""),
            svix_timestamp=request.headers.get("svix-timestamp", ""),
            body=raw,
            signature_header=request.headers.get("svix-signature", ""),
        )
    except SignatureError as exc:
        # 사유는 서버 로그에만 — 응답 본문에 실으면 공격자에게 검증 단계를 알려준다.
        logger.warning("웹훅 서명 검증 실패: %s", exc)
        raise HTTPException(status_code=401, detail="서명 검증에 실패했습니다.") from exc

    try:
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            raise ValueError("최상위가 객체가 아니다")
    except (ValueError, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail="본문을 해석할 수 없습니다.") from exc

    event_type = str(payload.get("type") or "")
    data = payload.get("data") if isinstance(payload.get("data"), dict) else {}
    recipients = _recipients(data.get("to"))

    # 수신자가 없는 이벤트(domain.*·contact.*·suppression.*)는 우리가 다룰 것이 없다.
    # 4xx 를 주면 제공자가 무한 재시도하므로 **200 으로 조용히 무시**한다(오류가 아니다).
    if not event_type.startswith("email.") or not recipients:
        return JSONResponse({"ignored": True}, headers=_NO_STORE)

    svix_id = request.headers.get("svix-id", "")
    bounce = data.get("bounce")
    for recipient in recipients:
        await mail_events.record_event(
            svix_id=svix_id,
            event_type=event_type,
            recipient=recipient,
            provider_msg_id=data.get("email_id"),
            bounce=bounce,
            event_dtm=payload.get("created_at"),
        )
    return JSONResponse({"ok": True}, headers=_NO_STORE)
