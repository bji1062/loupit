"""SP-AUTH-4·7 라우트 의존성 — 세션·재직 검증(미들웨어 아님, INV-9).

세션·재직 검증은 `app.add_middleware` 가 아니라 FastAPI `Depends` 로만 주입한다 —
`app.user_middleware == ['CORSMiddleware']` 불변(T2·T10, AU-2)을 지키기 위함이다.
익명 GET 라우터는 이 의존성을 쓰지 않는다(익명 표면 불변).
"""
from __future__ import annotations

from fastapi import Cookie, Depends, Header, HTTPException, Request

from server import database
from server.services import employment, operator, session


async def require_csrf(x_loupit_client: str | None = Header(default=None)) -> None:
    """상태변경(POST/PUT/DELETE) CSRF 방어 — 커스텀 헤더 `X-Loupit-Client` 필수, 부재 시 403(FR-113·SP-AUTH-12).

    크로스오리진은 preflight 없이 커스텀 헤더를 못 붙이고, preflight 는 CORS 허용목록 +
    `allow_credentials=false` 에서 실패한다(SameSite=Lax 와 결합). nginx Layer A 게이트에 더한
    앱 레벨 이중 검사 — 미들웨어가 아니라 라우트 의존성으로 구현해 `app.user_middleware ==
    ['CORSMiddleware']` 불변을 지킨다(INV-9). 익명 GET·익명 비교 로그(sendBeacon)는 비대상이라
    이 의존성을 달지 않는다. 쓰기 라우트에서 세션·재직 의존성보다 **먼저** 평가되도록 앞에 둔다."""
    if not x_loupit_client:
        raise HTTPException(status_code=403, detail="잘못된 요청입니다.")


async def require_member(loupit_sid: str | None = Cookie(default=None)) -> dict:
    """세션 쿠키(loupit_sid)를 검증해 회원 dict({'MBR_ID':...})를 반환, 없으면 401.

    쿠키 원문을 `resolve_session`(DB엔 해시만 조회)으로 검증한다 — 미들웨어가 아니라
    상태변경/계정 라우트가 `Depends(require_member)`로 개별 주입한다(FR-100·101, INV-9)."""
    member = await session.resolve_session(loupit_sid)
    if not member:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다.")
    return member


# ── SP-AUTH-19 운영 콘솔 관문 ─────────────────────────────────────────────────────
#
# 두 겹이고, **바깥 겹이 본체**다.
#   ① 이 요청이 SSH 터널(=루프백 직결)로 왔는가  ← 노출 범위. 없으면 404.
#   ② 이 세션의 계정이 운영자 화이트리스트에 있는가 ← 신원. 없으면 404.
#
# 둘 다 **404** 를 낸다(401·403 이 아니다). 다른 코드를 주면 "여기에 무언가 있다"를 알려 준다 —
# 관리 화면에서는 존재 자체가 정보다.

#: nginx 가 프록시할 때 **반드시** 붙이는 헤더들(infra/nginx/loupit.conf 의 모든 proxy_pass 블록).
#: 이 중 하나라도 있으면 그 요청은 nginx 를 거쳤다 = 인터넷에서 왔다.
_PROXY_MARKERS = ("x-real-ip", "x-forwarded-for", "x-forwarded-proto")


def came_through_proxy(headers) -> bool:
    """이 요청이 nginx 를 거쳐 왔는가 — 순수 함수(테스트가 직접 부른다)."""
    return any(h in headers for h in _PROXY_MARKERS)


async def require_loopback(request: Request) -> None:
    """SSH 터널 전용 관문 — nginx 를 거친 요청이면 **404**(SP-AUTH-19.2).

    **왜 nginx `deny` 가 아니라 앱에서 판정하나.** `release.sh` 는 nginx conf 를 배포하지
    않고(함정 ⑭), 새 호스트를 프로비저닝하다 한 줄을 빠뜨리면 관리 화면이 **조용히 인터넷에
    열린다.** 잊을 수 있는 것에 보안을 걸지 않는다 — 보증을 코드로 옮기면 설정 표류와 무관해진다.

    **판정 근거**: `infra/nginx/loupit.conf` 의 모든 `proxy_pass` 블록이 `X-Real-IP`·
    `X-Forwarded-For`·`X-Forwarded-Proto` 를 설정한다. 따라서 그 헤더 **없이** 앱 포트에
    도달한 요청은 nginx 를 거치지 않았다 = 루프백 직결 = `ssh -L` 터널이다.
    (`request.client.host` 만 보면 안 된다 — nginx 도 127.0.0.1 에서 프록시하므로 둘이 같다.)

    공격자가 헤더를 **위조**해도 자기를 막을 뿐이고, **지울 수는 없다**(nginx 가 append 한다).
    ⚠ 이 전제는 nginx conf 에 달려 있으므로 `test_console_gate.py` 가 "모든 proxy_pass 블록이
      X-Real-IP 를 설정하는가"를 회귀로 검사한다. 전제가 깨지면 알아야 한다.
    """
    if came_through_proxy(request.headers):
        raise HTTPException(status_code=404, detail="Not Found")


async def require_operator(member: dict = Depends(require_member)) -> dict:
    """운영자 세션을 요구한다. 아니면 **404**(존재를 알리지 않는다).

    반환 dict 에 `MBR_ID` 와 `LOGIN_EMAIL_NM` 이 담긴다 — 이 `MBR_ID` 가 `DECIDED_BY_ID` 로
    자동 주입되어 **감사를 자율신고에서 벗어나게 한다**(SP-AUTH-19.1). 그게 콘솔의 주된 이득이다.

    `resolve_session` 은 `MBR_ID` 만 돌려주므로 이메일은 여기서 따로 읽는다. 세션 검증 경로를
    넓히지 않기 위해서다 — 익명 대비 비용이 붙는 것은 운영 라우트뿐이어야 한다.
    탈퇴 계정(`STATUS_CD<>'active'`)은 조회되지 않으므로 권한도 함께 사라진다.
    """
    row = await database.fetch_one(
        "SELECT MBR_ID, LOGIN_EMAIL_NM FROM TMEMBER WHERE MBR_ID=%s AND STATUS_CD='active'",
        (member["MBR_ID"],),
    )
    if not row or not operator.is_operator(row["LOGIN_EMAIL_NM"]):
        raise HTTPException(status_code=404, detail="Not Found")
    return row


async def require_employment(comp_id: int, member: dict = Depends(require_member)) -> dict:
    """경로변수 comp_id 회사의 **활성 재직 인증**을 요구, 없으면 403(SP-AUTH-4·7).

    IDOR 방어 — 인증한 회사의 복지만 편집할 수 있게 게이트한다(복지 편집 T-13.10 이 소비)."""
    verification = await employment.active_verification(member["MBR_ID"], comp_id)
    if not verification:
        raise HTTPException(status_code=403, detail="해당 회사 재직 인증이 필요합니다.")
    return verification
