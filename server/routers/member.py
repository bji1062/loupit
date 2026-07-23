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

from fastapi import APIRouter, Cookie, Depends, HTTPException, Response
from pymysql.err import IntegrityError

from server import database
from server.deps import require_member
from server.models.member import (
    LoginCodeIn,
    LoginIn,
    LoginResult,
    MeResponse,
    NicknameUpdateIn,
    VerificationItem,
)
from server.services import auth_code, session

router = APIRouter(tags=["member"])


def _gen_nickname() -> str:
    """자동 닉네임 `직장인-######` — 가입 시 부여(마이페이지에서 변경, SP-AUTH-5.4)."""
    return f"직장인-{secrets.randbelow(1_000_000):06d}"


async def _get_or_create_member(email: str) -> tuple[dict, bool]:
    """이메일로 활성 회원 조회, 없으면 신규 생성(닉네임 자동) 후 (회원, is_new) 반환.

    PII = 로그인 이메일 + 자동 닉네임뿐(INV-8·T9). INSERT UNIQUE 충돌은 두 종류를 구분한다
    (보안점검 2026-07-23): **이메일 중복**(동일 이메일 동시 첫 로그인·버튼 더블클릭 레이스)은
    이미 만들어진 계정을 재조회해 is_new=False 로 흡수하고, **닉네임 중복**만 새 닉네임으로 재시도한다.
    (구현: INSERT 실패 시 해당 이메일 계정이 존재하면 그걸 반환, 없으면 닉네임 충돌로 보고 재시도.)"""
    norm = auth_code._normalize_email(email)
    row = await database.fetch_one(
        "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM=%s AND STATUS_CD='active'",
        (norm,),
    )
    if row:
        return row, False

    last_exc: Exception | None = None
    for _ in range(5):
        try:
            await database.execute(
                "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, %s)",
                (norm, _gen_nickname()),
            )
            new_row = await database.fetch_one(
                "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM=%s",
                (norm,),
            )
            return new_row, True
        except Exception as exc:  # UNIQUE 위반(pymysql IntegrityError 등)
            last_exc = exc
            # 이메일 중복 레이스: 다른 동시 요청이 같은 이메일로 계정을 이미 만들었으면 그걸 흡수.
            existing = await database.fetch_one(
                "SELECT MBR_ID, NICKNAME_NM FROM TMEMBER WHERE LOGIN_EMAIL_NM=%s AND STATUS_CD='active'",
                (norm,),
            )
            if existing:
                return existing, False
            # 이메일이 아직 없다 = 닉네임 충돌 → 새 닉네임으로 재시도.
    raise HTTPException(500, "가입 처리 중 오류가 발생했습니다.") from last_exc


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


@router.get("/members/me", response_model=MeResponse)
async def get_me(response: Response, member: dict = Depends(require_member)) -> MeResponse:
    """마이페이지 — 닉네임·상태·활성 재직 인증 목록(회사 이메일·MBR_ID 미노출, no-store, AM-1)."""
    mbr_id = member["MBR_ID"]
    row = await database.fetch_one(
        "SELECT NICKNAME_NM, STATUS_CD FROM TMEMBER WHERE MBR_ID=%s", (mbr_id,)
    )
    verifs = await database.fetch_all(
        "SELECT v.COMP_ID AS comp_id, c.COMP_NM AS comp_nm, v.EXPIRES_DTM AS expires_dtm "
        "FROM TEMPLOY_VERIFICATION v JOIN TCOMPANY c ON c.COMP_ID = v.COMP_ID "
        "WHERE v.MBR_ID=%s AND v.REVOKED_DTM IS NULL "
        "AND (v.EXPIRES_DTM IS NULL OR v.EXPIRES_DTM > UTC_TIMESTAMP()) ORDER BY v.COMP_ID",
        (mbr_id,),
    )
    response.headers["Cache-Control"] = "no-store"
    return MeResponse(
        nickname=row["NICKNAME_NM"],
        status=row["STATUS_CD"],
        verifications=[VerificationItem(**v) for v in verifs],
    )


@router.put("/members/me", response_model=MeResponse)
async def update_me(
    body: NicknameUpdateIn, response: Response, member: dict = Depends(require_member)
) -> MeResponse:
    """닉네임 변경 — UNIQUE 원자 검사(중복 409, AM-2). no-store."""
    mbr_id = member["MBR_ID"]
    try:
        await database.execute(
            "UPDATE TMEMBER SET NICKNAME_NM=%s WHERE MBR_ID=%s", (body.nickname, mbr_id)
        )
    except IntegrityError:  # 닉네임 UNIQUE 위반 — 원자 검사(레이스 안전)
        raise HTTPException(status_code=409, detail="이미 사용 중인 닉네임입니다.")
    row = await database.fetch_one(
        "SELECT NICKNAME_NM, STATUS_CD FROM TMEMBER WHERE MBR_ID=%s", (mbr_id,)
    )
    response.headers["Cache-Control"] = "no-store"
    return MeResponse(nickname=row["NICKNAME_NM"], status=row["STATUS_CD"], verifications=[])


@router.post("/members/logout", status_code=204)
async def logout(
    loupit_sid: str | None = Cookie(default=None), member: dict = Depends(require_member)
) -> Response:
    """로그아웃 — 세션 폐기 + 쿠키 삭제 → 204 (AM-3)."""
    if loupit_sid:
        await session.revoke_session(loupit_sid)
    resp = Response(status_code=204, headers={"Cache-Control": "no-store"})
    session.clear_session_cookie(resp)
    return resp


@router.delete("/members/me", status_code=204)
async def withdraw(member: dict = Depends(require_member)) -> Response:
    """탈퇴(AM-4) — 로그인 이메일 원문 파기(NULL)·전 세션 폐기·재직 인증(회사 이메일 HMAC 포함) 파기.

    닉네임·편집 이력(TBENEFIT_EDIT_LOG)은 공개 이력 무결성 위해 **존치**(약관 T5·개인정보 P7 고지).
    본체+세션+재직을 한 트랜잭션으로 원자 처리한다(SP-AUTH-6)."""
    mbr_id = member["MBR_ID"]
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "UPDATE TMEMBER SET LOGIN_EMAIL_NM=NULL, STATUS_CD='withdrawn' WHERE MBR_ID=%s",
                (mbr_id,),
            )
            await cur.execute(
                "UPDATE TSESSION SET REVOKED_DTM=UTC_TIMESTAMP() WHERE MBR_ID=%s AND REVOKED_DTM IS NULL",
                (mbr_id,),
            )
            # 재직 인증 삭제 = 폐기 + 회사 이메일 HMAC 파기(COMP_EMAIL_HASH_VAL CHAR64 NOT NULL
            # UNIQUE 라 blank 불가 → 행 삭제로 HMAC 자체를 제거).
            await cur.execute("DELETE FROM TEMPLOY_VERIFICATION WHERE MBR_ID=%s", (mbr_id,))
    resp = Response(status_code=204, headers={"Cache-Control": "no-store"})
    session.clear_session_cookie(resp)
    return resp
