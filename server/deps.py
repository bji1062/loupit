"""SP-AUTH-4·7 라우트 의존성 — 세션·재직 검증(미들웨어 아님, INV-9).

세션·재직 검증은 `app.add_middleware` 가 아니라 FastAPI `Depends` 로만 주입한다 —
`app.user_middleware == ['CORSMiddleware']` 불변(T2·T10, AU-2)을 지키기 위함이다.
익명 GET 라우터는 이 의존성을 쓰지 않는다(익명 표면 불변).
"""
from __future__ import annotations

import hmac
import logging

from fastapi import Cookie, Depends, Header, HTTPException, Request

from server import database
from server.config import get_settings
from server.services import employment, operator, session

logger = logging.getLogger(__name__)


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


async def optional_member(loupit_sid: str | None = Cookie(default=None)) -> dict | None:
    """세션 쿠키가 **있으면** 회원 dict, 없거나 무효면 None — **어떤 경우에도 401 을 내지 않는다**(SP-COMM-4).

    익명 열람 경로(커뮤니티 상세·댓글, FR-122·123)가 `is_mine`·`liked` 를 계산할 때만 쓴다.
    `require_member` 와 **별개 심볼**이다 — AU-2 계약("익명 GET 의 dependant 트리에 require_member
    부재")은 그 이름의 부재로 재므로, 이 함수가 그것을 감싸거나 이름을 재사용하면 안 된다.
    DB 장애는 삼키지 않는다 — 장애를 '익명'으로 위장하면 상세 자체도 곧 실패하므로 정직하게 올린다."""
    if not loupit_sid:
        return None
    return await session.resolve_session(loupit_sid)


# ── SP-AUTH-19 운영 콘솔 관문 ─────────────────────────────────────────────────────
#
# 두 겹이고, **바깥 겹이 본체**다.
#   ① 이 요청이 허락된 입구로 왔는가            ← 노출 범위. 아니면 404.
#      입구는 둘뿐이다: A = SSH 터널(루프백 직결) · B = 관리 호스트(SP-AUTH-19.8).
#   ② 이 세션의 계정이 운영자 화이트리스트에 있는가 ← 신원. 없으면 404.
#
# 둘 다 **404** 를 낸다(401·403 이 아니다). 다른 코드를 주면 "여기에 무언가 있다"를 알려 준다 —
# 관리 화면에서는 존재 자체가 정보다.

#: nginx 가 프록시할 때 **반드시** 붙이는 헤더들(infra/nginx/*.conf 의 모든 proxy_pass 블록).
#: 이 중 하나라도 있으면 그 요청은 nginx 를 거쳤다 = 인터넷에서 왔다.
_PROXY_MARKERS = ("x-real-ip", "x-forwarded-for", "x-forwarded-proto")

#: 관리 vhost(`infra/nginx/loupit-admin.conf`)만 붙이는 게이트 헤더. 본 사이트·베타의 모든
#: proxy_pass 블록은 이 헤더를 **빈 값으로 덮어 지운다** — 클라이언트가 보낸 값이 앱에 닿지 않는다.
ADMIN_GATE_HEADER = "x-loupit-admin-gate"

#: 이보다 짧은 비밀은 설정 실수로 보고 통과 B 를 닫는다(`openssl rand -hex 32` = 64자).
ADMIN_GATE_SECRET_MIN_LEN = 32


def came_through_proxy(headers) -> bool:
    """이 요청이 nginx 를 거쳐 왔는가 — 순수 함수(테스트가 직접 부른다)."""
    return any(h in headers for h in _PROXY_MARKERS)


def _configured_admin_host(settings) -> str | None:
    """설정된 관리 호스트(소문자). 비었거나 모양이 호스트명이 아니면 None = 통과 B 닫힘.

    포트·경로·공백이 섞인 값은 **맞춰 주지 않고 닫는다.** nginx 가 넘기는 `$host` 에는 포트가
    없으므로 `admin.jobcho.wiki:443` 같은 설정은 어차피 영원히 일치하지 않는다 — 조용히 안 맞는
    것보다 "설정이 틀렸다"로 읽히는 쪽이 낫다."""
    host = (settings.admin_host or "").strip().lower()
    if not host or any(c in host for c in ":/ \t"):
        return None
    return host


def _secret_value(raw) -> str:
    """`SecretStr`(설정) 또는 평문 문자열(테스트 주입) → 평문. 비밀을 repr·오류 메시지에 싣지 않으려고
    설정 쪽은 `SecretStr` 이고, 값을 꺼내는 곳은 이 함수 하나뿐이다."""
    if raw is None:
        return ""
    return raw.get_secret_value() if hasattr(raw, "get_secret_value") else str(raw)


def admin_gate_open(headers, settings, *, warn: bool = True) -> bool:
    """통과 B — 관리 호스트 경유 요청인가. 순수 함수(테스트가 설정을 주입해 직접 부른다).

    세 조건이 **전부** 참이어야 한다:
      ① 비밀이 32자 이상 설정돼 있다(비었거나 짧으면 닫힘 — fail-closed)
      ② `Host` 가 `ADMIN_HOST` 와 같다 — 대소문자는 무시한다(DNS 는 대소문자를 가리지 않고
         nginx `$host` 는 이미 소문자다). **포트가 붙은 Host 는 불일치**다: 관리 vhost 는
         `proxy_set_header Host $host` 로 포트 없는 이름만 넘기므로, 포트가 보이면 그 요청은
         그 vhost 를 거치지 않았다.
      ③ 게이트 헤더가 비밀과 같다 — `hmac.compare_digest`(상수 시간 비교).

    ②가 있는 이유: 비밀이 새더라도 **본 사이트로는** 통과하지 못하게 한다(본 사이트는 Host 가
    `jobcho.wiki` 이고, 게다가 게이트 헤더를 지운다). 두 조건을 따로 깨야 한다."""
    secret = _secret_value(settings.admin_gate_secret).strip()
    if len(secret) < ADMIN_GATE_SECRET_MIN_LEN:
        return False
    expected_host = _configured_admin_host(settings)
    if expected_host is None:
        return False
    if (headers.get("host") or "").lower() != expected_host:
        return False
    provided = headers.get(ADMIN_GATE_HEADER) or ""
    if hmac.compare_digest(provided.encode("utf-8"), secret.encode("utf-8")):
        return True
    # 관리 호스트로 왔는데 비밀이 틀렸다 = 거의 항상 nginx 스니펫과 `.env` 의 불일치다(공격자는
    # 관리 vhost 의 비밀번호를 먼저 넘어야 여기 닿는다). 원인을 찾게 남기되 **값은 찍지 않는다.**
    if warn:
        logger.warning("관리 호스트 요청의 게이트 헤더가 설정과 다르다(%s) — nginx 스니펫과 server/.env 를 대조하라",
                       "헤더 없음" if not provided else "값 불일치")
    return False


def console_access_allowed(headers, *, warn: bool = True) -> bool:
    """콘솔 입구 판정 — 통과 A(SSH 터널: 프록시 표식 없음) 또는 통과 B(관리 호스트). 순수 판정만 한다.

    `require_console_access`(라우터 의존성)와 콘솔 라우트 매칭(`routers/console.ConsoleRoute`)이
    **같은 판정**을 쓴다 — 두 곳이 다른 규칙을 가지면 한쪽이 뒷문이 된다."""
    return not came_through_proxy(headers) or admin_gate_open(headers, get_settings(), warn=warn)


async def require_console_access(request: Request) -> None:
    """콘솔 노출 범위 관문 — 허락된 두 입구가 아니면 **404**(SP-AUTH-19.2·19.8).

    **통과 A = SSH 터널.** 프록시 헤더 **없이** 앱 포트에 도달한 요청은 nginx 를 거치지 않았다
    = 루프백 직결 = `ssh -L` 터널이다. `infra/nginx/*.conf` 의 모든 `proxy_pass` 블록이
    `X-Real-IP`·`X-Forwarded-For`·`X-Forwarded-Proto` 를 설정한다는 사실이 근거다.
    (`request.client.host` 만 보면 안 된다 — nginx 도 127.0.0.1 에서 프록시하므로 둘이 같다.)
    공격자가 헤더를 **위조**해도 자기를 막을 뿐이고, **지울 수는 없다**(nginx 가 append 한다).

    **통과 B = 관리 호스트.** `admin_gate_open` 참조. 비밀번호(nginx `auth_basic`)를 넘은
    요청에만 관리 vhost 가 게이트 헤더를 붙이므로, 이 관문은 "비밀번호를 통과했다"를 앱이 확인하는
    자리다. 설정(`ADMIN_HOST`·`ADMIN_GATE_SECRET`)이 없으면 닫혀 있고, 그때 동작은 옛
    `require_loopback` 과 정확히 같다.

    **왜 nginx `deny` 가 아니라 앱에서 판정하나.** `release.sh` 는 nginx conf 를 배포하지
    않고(함정 ⑭), 새 호스트를 프로비저닝하다 한 줄을 빠뜨리면 관리 화면이 **조용히 인터넷에
    열린다.** 잊을 수 있는 것에 보안을 걸지 않는다 — 보증을 코드로 옮기면 설정 표류와 무관해진다.
    ⚠ 두 통과 모두 nginx conf 의 전제에 기대므로 `test_console_gate.py`·`test_admin_host_gate.py`
      가 "모든 proxy_pass 블록이 X-Real-IP 를 설정하고 게이트 헤더를 지우는가(관리 vhost 는
      비밀번호 뒤에서 붙이는가)"를 회귀로 검사한다. 전제가 깨지면 알아야 한다.

    ⚠ 의존성은 **라우트가 매칭된 뒤**에야 돈다. 그 전에 나가는 응답 — 메서드가 틀리면 405(`Allow`
      헤더 동봉), 본문 JSON 이 깨지면 422, 슬래시가 다르면 307 — 은 이 관문을 거치지 않아 "여기에
      콘솔이 있다"를 알려 준다(2026-09-18 적대 검토 실측). 그래서 콘솔 라우트는 매칭 단계에서도 같은
      판정(`console_access_allowed`)을 하고, 관문 밖이면 **매칭 자체를 거부**한다(`ConsoleRoute`).
      이 의존성은 그 뒤의 두 번째 겹이다(라우트 클래스가 바뀌어도 관문은 남는다).
    """
    if not console_access_allowed(request.headers):
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
