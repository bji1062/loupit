"""SP-AUTH-5·6 회원 라우터 — 무비밀번호 로그인·계정·로그아웃·탈퇴 (FR-102~104).

M9: 로그인 흐름(로그인 코드 발송·코드 검증→세션) 착지(T-13.6). me·로그아웃·탈퇴(T-13.7)와
CSRF 헤더(`X-Loupit-Client`, T-13.13.1)는 후속 리프가 얹는다.

- 파일명 `auth` 금지(레거시 잔재 방지, T10) — 로그인 라우터는 본 `member.py`.
- 세션 검증은 미들웨어가 아니라 `deps.require_member`(Depends)로만 주입한다(INV-9) — 본
  라우터 등록이 `app.user_middleware == ['CORSMiddleware']` 불변을 깨지 않는다(AU-2).
- 계정 유무와 무관하게 로그인 코드 응답은 균일 204(계정 열거 차단, NFR31).
"""
from __future__ import annotations

import secrets

from fastapi import APIRouter, HTTPException, Response

from server import database
from server.models.member import LoginCodeIn, LoginIn, LoginResult
from server.services import auth_code, session

router = APIRouter(tags=["member"])


def _gen_nickname() -> str:
    """자동 닉네임 `직장인-######` — 가입 시 부여(마이페이지에서 변경, SP-AUTH-5.4)."""
    return f"직장인-{secrets.randbelow(1_000_000):06d}"


async def _get_or_create_member(email: str) -> tuple[dict, bool]:
    """이메일로 활성 회원 조회, 없으면 신규 생성(닉네임 자동) 후 (회원, is_new) 반환.

    PII = 로그인 이메일 + 자동 닉네임뿐(INV-8·T9). 닉네임 UNIQUE 충돌 시 몇 회 재생성한다."""
    norm = auth_code._normalize_email(email)
    row = await database.fetch_one(
        "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM=%s AND STATUS_CD='active'",
        (norm,),
    )
    if row:
        return row, False

    last_exc: Exception | None = None
    for _ in range(5):  # 닉네임 UNIQUE 충돌 재시도(확률 낮음)
        try:
            await database.execute(
                "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, %s)",
                (norm, _gen_nickname()),
            )
            break
        except Exception as exc:  # IntegrityError(닉네임 중복) 등 — 재생성 후 재시도
            last_exc = exc
    else:
        raise HTTPException(500, "가입 처리 중 오류가 발생했습니다.") from last_exc

    row = await database.fetch_one(
        "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM=%s",
        (norm,),
    )
    return row, True


@router.post("/members/login-code", status_code=204)
async def request_login_code(body: LoginCodeIn) -> Response:
    """로그인 코드 발송 — 계정 유무 무관 균일 204(계정 열거 차단, AL-1, FR-102)."""
    await auth_code.issue_login_code(body.email)
    return Response(status_code=204, headers={"Cache-Control": "no-store"})


@router.post("/members/login")
async def login(body: LoginIn, response: Response) -> LoginResult:
    """코드 검증 → 세션 발급 → Set-Cookie → 200 {nickname, is_new} (AL-2·3·4, FR-103).

    실패: 불일치 401 / 만료 410 / 시도 상한 429."""
    result = await auth_code.verify_login_code(body.email, body.code)
    if result == auth_code.CodeResult.EXPIRED:
        raise HTTPException(410, "코드가 만료되었습니다. 다시 요청하세요.")
    if result == auth_code.CodeResult.TOO_MANY:
        raise HTTPException(429, "시도 횟수를 초과했습니다. 다시 요청하세요.")
    if result != auth_code.CodeResult.OK:
        raise HTTPException(401, "코드가 일치하지 않습니다.")

    member, is_new = await _get_or_create_member(body.email)
    raw = await session.issue_session(member["MBR_ID"])
    session.set_session_cookie(response, raw)
    response.headers["Cache-Control"] = "no-store"
    return LoginResult(nickname=member["NICKNAME_NM"], is_new=is_new)
