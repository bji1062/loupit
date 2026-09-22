"""SP-AUTH-19 운영 콘솔 (FR-107·115) — SSH 터널 또는 관리 호스트(admin.jobcho.wiki) 전용.

라우터명이 `admin` 이 **아닌** 이유: 그 이름은 레거시 델타로 영구 제외돼 있다
(`server/routers/__init__.py`). 이름을 되살리면 "제거했다"는 기록과 어긋난다.

## 두 겹의 관문 — 바깥이 본체다

라우터 레벨 `dependencies=[Depends(require_console_access)]` 가 **먼저** 돈다(FastAPI 는 라우터
의존성을 경로 의존성보다 앞서 해결한다). 그래서 허락된 입구(SSH 터널 · 비밀번호 뒤의 관리 호스트,
SP-AUTH-19.8) 밖에서 온 요청은 세션을 보기도 전에 404 로 끊긴다 — 순서가 뒤바뀌면 비로그인
요청에 401 이 나가 **여기에 무언가 있다**를 알려 준다.

## 왜 콘솔이 CLI 보다 나은가 — 편의가 아니라 감사다

`DECIDED_BY_ID`·`MOD_ID` 를 **세션에서 자동 주입**한다. CLI 는 `--by N` 을 사람이 손으로 넣고 FK 도
검증도 없어 그 감사 기록은 자율신고다. 요청 본문으로 받지 않는 것이 핵심이다.

## 되돌릴 수 없는 것은 여기 없다

복지 하드 삭제·재직 인증 폐기는 CLI 에만 있다(SP-AUTH-19.4). 브라우저 클릭 한 번 뒤에
비가역 조작을 두지 않는다. 게시판 숨김은 상태 한 줄이라 복구 버튼이 같은 화면에 있다.

## 회원 이메일은 여기서만 나간다

회원 탭은 로그인 이메일을 싣는다(운영자가 연락·확인에 쓴다). 그 응답은 이 라우터의 두 관문 뒤에만
있고, 모든 응답이 `Cache-Control: no-store` 다 — 브라우저·중간 캐시에 남기지 않는다.
"""
from __future__ import annotations

import base64
import hashlib
import re
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from fastapi.responses import HTMLResponse
from fastapi.routing import APIRoute
from pydantic import BaseModel, Field, field_validator
from pymysql.err import OperationalError
from starlette.datastructures import Headers
from starlette.routing import Match

from server.deps import console_access_allowed, require_console_access, require_csrf, require_operator
from server.models.post import DECIDE_ACTIONS
from server.services import console_view, operator
from server.services import report as report_svc

_SCOPE_KEY = "loupit.console_access"  # 한 요청 안에서 판정을 한 번만 하려는 캐시 키(ASGI scope 확장)


class ConsoleRoute(APIRoute):
    """관문 밖 요청에는 **매칭되지 않는** 콘솔 라우트 — 존재 자체를 숨긴다(2026-09-18 적대 검토 반영).

    라우터 의존성(`require_console_access`)은 라우트가 매칭된 **뒤**에 돈다. 그 전에 Starlette·FastAPI 가
    내는 응답 — 틀린 메서드 405(`Allow` 동봉) · 깨진 JSON 422 · 슬래시 차이 307 — 은 관문을 거치지 않고
    인터넷에 "여기 콘솔이 있다"를 알려 준다. 매칭 단계에서 같은 판정을 해 `Match.NONE` 을 돌려주면
    요청은 없는 경로가 되어 전역 404 로 떨어진다(관문의 404 와 본문까지 같다).

    판정은 scope 에 한 번만 적어 둔다 — 라우터는 경로가 맞는 라우트마다 `matches` 를 부르고, 불일치
    경고 로그가 요청 하나에 여러 번 찍히면 진짜 신호를 가린다."""

    def matches(self, scope):
        match, child_scope = super().matches(scope)
        if match == Match.NONE or scope.get("type") != "http":
            return match, child_scope
        if _SCOPE_KEY not in scope:
            scope[_SCOPE_KEY] = console_access_allowed(Headers(scope=scope))
        if not scope[_SCOPE_KEY]:
            return Match.NONE, {}
        return match, child_scope


async def _no_store(response: Response) -> None:
    """콘솔 JSON 응답 전부 `no-store` — 회원 이메일·사용자 입력 원문이 캐시에 남지 않게 한다.

    라우트마다 붙이면 새 라우트 하나를 빠뜨리는 날 그 응답만 캐시된다(관문을 라우터 레벨에 두는
    것과 같은 이유). 오류 응답은 전역 예외 핸들러가 따로 no-store 를 붙인다(SP-API-12)."""
    response.headers["Cache-Control"] = "no-store"


# 라우터 레벨 의존성 = 경로 의존성보다 먼저 평가된다. 노출 범위 판정이 **항상 첫 관문**이어야
# 하므로 여기에 둔다(각 라우트에 붙이면 하나를 빠뜨리는 날 그 라우트만 공개된다).
router = APIRouter(
    prefix="/console", tags=["console"], route_class=ConsoleRoute,
    dependencies=[Depends(require_console_access), Depends(_no_store)],
)

#: InnoDB 잠금 충돌 — 1213 교착 · 1205 잠금 대기 초과. 게시판 숨김과 신고 처리는 **같은 잠금 순서**(대상 →
#: 신고 행, `services/report.py`)라 서로 교착하지 않는다 — 이 번역은 그 뒤의 그물이다: 다른 긴 트랜잭션이 대상
#: 행을 오래 쥐어 대기가 초과되는 경우에도 운영자는 500 이 아니라 "다시 시도하라"(409)를 봐야 한다.
_LOCK_CONFLICT = (1205, 1213)


def _lock_conflict(exc: OperationalError) -> bool:
    return bool(exc.args) and exc.args[0] in _LOCK_CONFLICT


#: 목록 API 한 페이지 상한 — 폰에서 한 번에 그릴 만큼. 초과는 422(조용히 자르면 "다 봤다"로 오독한다).
PAGE_MAX = 100
PAGE_DEFAULT = 50


class DecisionIn(BaseModel):
    """결정 입력 — **`decided_by` 가 없다.** 그 값은 세션에서만 온다(SP-AUTH-19.5 ③).

    본문으로 받으면 운영자가 남의 ID 를 적을 수 있고, 그러면 감사는 여전히 자율신고다.
    모델에 필드를 두지 않는 것이 가장 강한 방어다 — 실수로 쓸 수가 없다."""

    note: str | None = Field(default=None, max_length=500)


class CompanyDecisionIn(DecisionIn):
    approve: bool


class ReportDecisionIn(DecisionIn):
    """신고 처리 입력(FR-131) — `action ∈ {hide, dismiss}`. 결정자 필드는 부모와 같이 **없다**."""

    action: str = Field(..., max_length=8)

    @field_validator("action")
    @classmethod
    def _valid_action(cls, v: str) -> str:
        if v not in DECIDE_ACTIONS:
            raise ValueError("action 은 hide 또는 dismiss 여야 합니다.")
        return v


class VisibilityIn(DecisionIn):
    """게시판 숨김/복구 입력(SP-AUTH-19.7) — `action ∈ {hide, restore}`. 결정자 필드는 **없다**.

    `note` 는 숨길 때 함께 닫히는 pending 신고의 결정 메모로 남는다(대상 행에는 메모 칸이 없다)."""

    action: str = Field(..., max_length=8)

    @field_validator("action")
    @classmethod
    def _valid_action(cls, v: str) -> str:
        if v not in report_svc.VISIBILITY_ACTIONS:
            raise ValueError("action 은 hide 또는 restore 여야 합니다.")
        return v


@router.get("/queues")
async def queues(op: dict = Depends(require_operator)) -> dict:
    """대기 큐 4종(재직 승인·회사 등록·발송 억제 + SC15 게시물 신고)을 **구조화된 JSON** 으로 돌려준다.

    ⚠ 여기 담기는 `EVIDENCE_CTNT`·`REQ_COMP_NM`·`REF_URL_CTNT`·`NICKNAME_NM` 은 전부
    **사용자 입력 원문**이다. 서버는 값을 그대로 싣고, 그리는 쪽(`_PAGE`)이 노드
    조립으로만 표시한다 — 서버가 HTML 을 만들어 보내면 그 순간 XSS 경로가 생긴다.

    억제 목록은 **해시만** 싣는다(원문 주소는 애초에 저장되지 않는다, T9).
    """
    pending = await operator.list_pending_verifications()
    companies = await operator.list_pending_company_requests()
    suppressed = await operator.list_suppressed()
    reports = await report_svc.list_pending_reports()  # SC15 신고 큐(FR-131) — 발췌·상세도 사용자 입력 원문
    return {
        "operator": op["LOGIN_EMAIL_NM"],
        "reports": reports,
        "verifications": [
            {
                "id": r["VRF_REQUEST_ID"], "member_id": r["MBR_ID"], "nickname": r["NICKNAME_NM"],
                "company_id": r["COMP_ID"], "company": r["COMP_NM"],
                "evidence": r["EVIDENCE_CTNT"], "at": str(r["INS_DTM"]),
            } for r in pending
        ],
        "company_requests": [
            {
                "id": r["COMP_REQUEST_ID"], "member_id": r["MBR_ID"], "nickname": r["NICKNAME_NM"],
                "name": r["REQ_COMP_NM"], "ref_url": r["REF_URL_CTNT"], "at": str(r["INS_DTM"]),
            } for r in companies
        ],
        "suppressed": [
            {
                "id": r["MAIL_SUPP_ID"], "target_hash": r["TARGET_HASH_VAL"],
                "reason": r["REASON_CD"], "at": str(r["INS_DTM"]),
            } for r in suppressed
        ],
    }


# ── SP-AUTH-19.7 조회 화면 4종 (전부 읽기 — 게시판 숨김/복구만 아래 POST) ────────────────────


@router.get("/overview")
async def overview(op: dict = Depends(require_operator)) -> dict:
    """현황 — 건수만. 콘솔이 첫 화면에서 부르므로 로그인 확인(401 → 로그인 단계)도 겸한다."""
    return {"operator": op["LOGIN_EMAIL_NM"], **await console_view.overview()}


@router.get("/members")
async def members(
    limit: int = Query(default=PAGE_DEFAULT, ge=1, le=PAGE_MAX),
    before: int | None = Query(default=None, ge=1),  # 커서(MBR_ID) — 이 값보다 먼저 가입한 회원
    _op: dict = Depends(require_operator),
) -> dict:
    """회원 목록(최신 가입순) — ⚠ **로그인 이메일이 담긴 유일한 응답**이다. 운영자 전용."""
    items, next_before = await console_view.list_members(limit, before)
    return {"items": items, "next_before": next_before}


@router.get("/posts")
async def board_posts(
    limit: int = Query(default=PAGE_DEFAULT, ge=1, le=PAGE_MAX),
    before: int | None = Query(default=None, ge=1),
    status: Literal["active", "hidden", "deleted"] | None = Query(default=None),
    _op: dict = Depends(require_operator),
) -> dict:
    """게시판 글 전체(상태 무관, 최신순) — 공개 목록과 달리 숨김·삭제도 보인다(복구하려면 찾아야 한다)."""
    items, next_before = await console_view.list_posts(limit, before, status)
    return {"items": items, "next_before": next_before}


@router.get("/comments")
async def board_comments(
    limit: int = Query(default=PAGE_DEFAULT, ge=1, le=PAGE_MAX),
    before: int | None = Query(default=None, ge=1),
    status: Literal["active", "hidden", "deleted"] | None = Query(default=None),
    _op: dict = Depends(require_operator),
) -> dict:
    items, next_before = await console_view.list_comments(limit, before, status)
    return {"items": items, "next_before": next_before}


@router.get("/benefit-edits")
async def benefit_edits(
    limit: int = Query(default=PAGE_DEFAULT, ge=1, le=PAGE_MAX),
    before: int | None = Query(default=None, ge=1),
    _op: dict = Depends(require_operator),
) -> dict:
    """복지 수정 이력 전 회사 횡단(최신순) — **읽기 전용**. 되돌리기는 이번 범위가 아니다."""
    items, next_before = await console_view.list_benefit_edits(limit, before)
    return {"items": items, "next_before": next_before}


async def _visibility(target_type: str, target_id: int, body: VisibilityIn, op: dict) -> dict:
    try:
        out = await report_svc.set_visibility(target_type, target_id, body.action, op["MBR_ID"], body.note)
    except OperationalError as exc:
        if _lock_conflict(exc):
            raise HTTPException(status_code=409, detail="busy") from exc
        raise
    if out["result"] in ("hidden", "restored"):
        return out
    # 대상 없음도 404 가 아니라 409 다 — 이 라우터의 404 는 "관문 밖/운영자 아님"과 구분되지
    # 않아야 하므로(존재 비공개), 운영자에게 보이는 상태 충돌은 전부 409 + 기계 토큰으로 준다.
    raise HTTPException(status_code=409, detail=out["result"])


@router.post("/posts/{post_id}/visibility", status_code=200)
async def post_visibility(
    post_id: int, body: VisibilityIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """글 숨김(active→hidden)·복구(hidden→active). `MOD_ID` 는 `op["MBR_ID"]`(세션)에서 온다."""
    return await _visibility("post", post_id, body, op)


@router.post("/comments/{comment_id}/visibility", status_code=200)
async def comment_visibility(
    comment_id: int, body: VisibilityIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    return await _visibility("comment", comment_id, body, op)


@router.post("/verifications/{req_id}/approve", status_code=200)
async def approve_verification(
    req_id: int, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """수동 재직 승인 — `DECIDED_BY_ID` 는 `op["MBR_ID"]`(세션)에서 온다."""
    result = await operator.approve_verification(req_id, op["MBR_ID"], body.note)
    if result == "not_pending":
        raise HTTPException(status_code=409, detail="not_pending")
    return {"result": result}


@router.post("/verifications/{req_id}/reject", status_code=200)
async def reject_verification(
    req_id: int, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    if not await operator.reject_verification(req_id, op["MBR_ID"], body.note):
        raise HTTPException(status_code=409, detail="not_pending")
    return {"result": "rejected"}


@router.post("/company-requests/{req_id}/decide", status_code=200)
async def decide_company_request(
    req_id: int, body: CompanyDecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """🚨 **회사를 만들지 않는다** — 상태만 바꾼다(SP-AUTH-17 과 동일 계약).

    실제 등록은 `db/seed` 작업이고, 회사를 추가하면 **정적 사이트 재생성이 필수**다.
    응답에 그 안내를 실어 승인 직후에 잊지 않게 한다."""
    if not await operator.decide_company_request(req_id, body.approve, op["MBR_ID"], body.note):
        raise HTTPException(status_code=409, detail="not_pending")
    return {
        "result": "approved" if body.approve else "rejected",
        "next": ("상태만 바뀌었다. 실제 등록은 db/seed 작업 + 정적 사이트 재생성(generator.build)."
                 if body.approve else None),
    }


@router.post("/suppressions/{target_hash}/release", status_code=200)
async def release_suppression(
    target_hash: str, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """억제 해제 — **해시로** 받는다(원문 주소는 브라우저·요청 로그에 남기지 않는다).

    억제는 위조·오탐 바운스 한 건으로 사용자가 로그인을 영영 못 하게 만들 수 있어서,
    되돌리는 수단이 반드시 있어야 한다(SP-AUTH-16). 행은 지우지 않고 `RELEASED_DTM` 만
    채운다 — 반복 오탐을 추적하려면 누가 언제 풀었는지가 남아야 한다."""
    if len(target_hash) != 64 or not all(c in "0123456789abcdef" for c in target_hash.lower()):
        raise HTTPException(status_code=422, detail="invalid_target_hash")
    if not await operator.release_suppression(target_hash.lower(), op["MBR_ID"]):
        raise HTTPException(status_code=409, detail="not_suppressed")
    return {"result": "released"}


@router.post("/reports/{report_id}/decide", status_code=200)
async def decide_report(
    report_id: int, body: ReportDecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """게시물 신고 처리(FR-131) — `hide`(대상 hidden + 같은 대상 pending 일괄 actioned) / `dismiss`.

    되돌릴 수 있는 것만: hidden 은 상태 한 줄이고 하드 삭제는 없다(SP-AUTH-19.4). `DECIDED_BY_ID` 는
    `op["MBR_ID"]`(세션)에서 온다 — 본문에 그 필드가 없다(CO-12 가 지킨다)."""
    try:
        result = await report_svc.decide_report(report_id, body.action, op["MBR_ID"], body.note)
    except OperationalError as exc:  # 잠금 대기 초과 등 — `_LOCK_CONFLICT` 주석
        if _lock_conflict(exc):
            raise HTTPException(status_code=409, detail="busy") from exc
        raise
    if result == "not_pending":
        raise HTTPException(status_code=409, detail="not_pending")
    return {"result": result}


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def console_page() -> Response:
    """콘솔 화면. **`web/dist` 가 아니라 여기서 낸다.**

    `web/dist` 는 공개 문서 루트라 거기 두는 순간 인터넷에 노출된다(그 디렉터리에 쓰는 것은
    곧 프로덕션 반영이다). 라우터에서 내면 이 파일도 `require_console_access` 관문 뒤에 있다.

    ⚠ 이 응답은 **운영자 세션을 요구하지 않는다** — 껍데기 HTML 에는 데이터가 없고, 실제
    내용은 운영자 필수 API 들이 준다. 입구를 통과한 사람에게 로그인 폼을 보여 주려면 화면
    자체는 열려 있어야 한다.
    """
    return HTMLResponse(_PAGE, headers={"Cache-Control": "no-store", "Content-Security-Policy": _CSP})


# ⚠ 이 페이지의 규칙 두 가지(SP-AUTH-19.5) — 어기면 관리자가 표적이 된다.
#   ① `innerHTML` 금지. 증빙·회사명·닉네임·제목·본문·편집 메모는 사용자 입력 원문이다 →
#      `textContent` 로만 넣는다.
#   ② 자동 하이퍼링크 금지. 증빙·참고 URL 은 사용자가 넣은 외부 주소다. `<a href>` 로 만들면
#      관리자가 무심코 눌러 IP 노출·피싱을 당한다 → 텍스트로 보여주고 **복사**하게 한다.
#   (탭도 링크가 아니라 버튼이다 — 화면 전환에 URL 이동이 필요 없다.)
# r-문자열인 이유: 안의 JS 에 역슬래시가 들어가는 날 파이썬이 조용히 먼저 해석해 버린다.
_PAGE = r"""<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer">
<title>운영 콘솔 — jobcho.wiki</title>
<style>
  :root { color-scheme: light dark; --bd:#8884; --mut:#7a7a7a; --acc:#3a6fd8; --hot:#c60; }
  * { box-sizing: border-box; }
  body { font: 15px/1.6 system-ui, -apple-system, "Apple SD Gothic Neo", sans-serif;
         margin: 0 auto; max-width: 72rem; padding: 1rem; overflow-wrap: anywhere; }
  h1 { font-size: 1.15rem; margin: 0; }
  h2 { font-size: 1rem; margin: 1.5rem 0 .5rem; border-bottom: 1px solid var(--bd); padding-bottom: .3rem; }
  .top { display: flex; gap: .5rem 1rem; align-items: baseline; flex-wrap: wrap; }
  .who { color: var(--mut); font-size: .85rem; display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
  .tabs { display: flex; gap: .25rem; overflow-x: auto; margin: .75rem 0 0; padding-bottom: .25rem;
          border-bottom: 1px solid var(--bd); }
  .tabs[hidden] { display: none; }
  .tabs button { flex: 0 0 auto; border-radius: 6px 6px 0 0; border-bottom: none; font-size: .9rem; padding: .35rem .5rem; }
  .tabs button[aria-selected="true"] { background: #8882; font-weight: 600; }
  .item { border: 1px solid var(--bd); border-radius: 8px; padding: .75rem .9rem; margin: .5rem 0; }
  .head { display: flex; gap: .5rem; align-items: baseline; flex-wrap: wrap; }
  .id { font-weight: 600; }
  .meta { color: var(--mut); font-size: .85rem; }
  .raw { background: #8881; border-radius: 6px; padding: .45rem .6rem; margin: .5rem 0;
         white-space: pre-wrap; word-break: break-all; font-family: ui-monospace, monospace;
         font-size: .85rem; }
  .rowbtns { display: flex; gap: .4rem; flex-wrap: wrap; margin-top: .5rem; align-items: center; }
  button, select { font: inherit; padding: .3rem .7rem; border: 1px solid var(--bd);
           border-radius: 6px; background: transparent; color: inherit; cursor: pointer; }
  button:hover { background: #8882; }
  button:disabled { opacity: .5; cursor: default; }
  input[type=text] { font: inherit; padding: .3rem .5rem; border: 1px solid var(--bd);
                     border-radius: 6px; background: transparent; color: inherit; flex: 1 1 10rem; min-width: 0; }
  .empty { color: var(--mut); font-style: italic; }
  .warn { border-left: 3px solid var(--hot); padding-left: .7rem; color: var(--mut); font-size: .85rem; margin: .75rem 0; }
  #msg { position: sticky; top: 0; padding: .4rem 0; background: Canvas; min-height: 1rem; z-index: 1; }
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(10.5rem, 1fr)); gap: .5rem; }
  .card { border: 1px solid var(--bd); border-radius: 8px; padding: .6rem .75rem; }
  .card h3 { font-size: .85rem; margin: 0 0 .3rem; color: var(--mut); font-weight: 600; }
  .card dl { margin: 0; display: grid; grid-template-columns: 1fr auto; gap: .1rem .5rem; }
  .card dt { font-size: .85rem; }
  .card dd { margin: 0; font-variant-numeric: tabular-nums; text-align: right; }
  .card dd.hot { color: var(--hot); font-weight: 700; }
  /* 표는 자기 상자 안에서만 가로로 스크롤한다 — 페이지 전체가 옆으로 밀리면 폰에서 탭이 사라진다. */
  .tbl { overflow-x: auto; max-width: 100%; border: 1px solid var(--bd); border-radius: 8px; }
  table { border-collapse: collapse; width: 100%; font-size: .85rem; }
  /* 칸 최소 폭 — 본문의 overflow-wrap:anywhere 를 그대로 물려받으면 칸이 몇 글자 폭까지 쪼그라들어
     표가 상자 안에서 스크롤하는 대신 세로로 길게 부서진다(390px 실측). 짧은 값(.nw)은 줄바꿈 없이,
     긴 원문(.txt)만 넉넉한 폭 안에서 아무 데서나 끊는다. */
  th, td { text-align: left; vertical-align: top; padding: .4rem .55rem; border-bottom: 1px solid var(--bd);
           min-width: 6.5rem; word-break: keep-all; }
  th { position: sticky; top: 0; background: Canvas; white-space: nowrap; font-weight: 600; }
  th, td.nw { min-width: 0; }
  td.nw { white-space: nowrap; }
  td.txt { min-width: 14rem; max-width: 28rem; word-break: normal; }
  td .sub { color: var(--mut); display: block; }
  .pill { display: inline-block; font-size: .75rem; padding: 0 .4rem; border-radius: 999px; border: 1px solid var(--bd); }
  .pill.hidden, .pill.pending { border-color: var(--hot); color: var(--hot); }
  .pill.deleted, .pill.withdrawn, .pill.revoked, .pill.expired { color: var(--mut); }
  .diff { margin: 0; padding-left: 1rem; }
  .filters { display: flex; gap: .4rem; flex-wrap: wrap; align-items: center; margin: .5rem 0; }
  .filters button[aria-pressed="true"] { background: #8882; font-weight: 600; }
  .more { margin: .5rem 0 1rem; }
</style></head><body>
<div class="top">
  <h1>운영 콘솔</h1>
  <div class="who" id="who"></div>
</div>
<nav class="tabs" id="tabs" role="tablist" aria-label="콘솔 화면" hidden></nav>
<div id="msg" role="status" aria-live="polite"></div>
<div id="root"></div>
<script>
// ── 이 파일의 유일한 규칙: DOM 은 노드 조립으로만 만든다. innerHTML 은 쓰지 않는다. ──
const $ = (t, cls, text) => { const e = document.createElement(t);
  if (cls) e.className = cls; if (text !== undefined && text !== null) e.textContent = text; return e; };
const root = document.getElementById('root');
const msgEl = document.getElementById('msg');
const tabsEl = document.getElementById('tabs');
const whoEl = document.getElementById('who');
const say = (t) => { msgEl.textContent = t; };

/** /api/v1 아래 아무 경로나 호출한다. 상태코드 해석은 호출부 몫. */
async function req(path, opts = {}) {
  return fetch('/api/v1' + path, {
    credentials: 'include',
    headers: { 'X-Loupit-Client': 'console', 'Content-Type': 'application/json' },
    ...opts,
  });
}

const NEEDS_LOGIN = Symbol('needs-login');

async function api(path, opts = {}) {
  const res = await req('/console' + path, opts);
  if (res.status === 401) throw NEEDS_LOGIN;   // 세션 없음 → 로그인 단계로
  if (res.status === 404) {
    // 비운영자 세션이면 여기서 막다른 길이 된다 — 쿠키를 손으로 지워야 다른 계정으로 들어갈 수 있었다.
    // 표시를 달아 첫 화면이 로그아웃·다시 로그인 단계로 보낼 수 있게 한다(2026-09-18 적대 검토 반영).
    const err = new Error('운영자 세션이 아니거나 허락된 입구 밖 접근이다 (404)');
    err.notAllowed = true;
    throw err;
  }
  if (!res.ok) {
    // 409 는 기계 토큰(detail)으로 온다 — 사람이 읽을 문구로 바꿔 보여 준다.
    let detail = '';
    try { detail = (await res.json()).detail; } catch (e) { detail = ''; }
    throw new Error(CONFLICT[detail] || ('실패 ' + res.status + (detail ? ' ' + JSON.stringify(detail) : '')));
  }
  return res.json();
}

const CONFLICT = {
  not_pending: '이미 처리된 요청이다 — 새로고침하라.',
  not_suppressed: '이미 해제됐다.',
  not_found: '대상이 없다.',
  not_active: '공개 상태가 아니라 숨길 수 없다(이미 숨김이거나 작성자가 삭제했다).',
  not_hidden: '숨김 상태가 아니라 복구할 것이 없다.',
  busy: '같은 대상을 다른 처리가 동시에 잡고 있었다 — 새로고침한 뒤 다시 하라.',
};

// ── 표시 규약 ────────────────────────────────────────────────────────────────
// 서버 시각은 UTC 문자열("YYYY-MM-DD HH:MM:SS")이다. 운영자는 한국에 있으므로 KST 로 바꿔 보여 준다.
// 문자열에 'Z' 를 붙여 UTC 로 **명시**해 파싱한다 — 붙이지 않으면 브라우저가 현지 시각으로 읽어 9시간 밀린다.
function kst(s) {
  if (!s) return '—';
  const d = new Date(String(s).replace(' ', 'T') + 'Z');
  if (isNaN(d.getTime())) return String(s);
  return d.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul', year: '2-digit', month: '2-digit',
    day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false }) + ' KST';
}
const LABEL = {
  active: '공개', hidden: '숨김', deleted: '삭제(작성자)', withdrawn: '탈퇴',
  expired: '만료', revoked: '폐기', pending: '승인 대기',
  create: '등록', update: '수정', delete: '삭제',
  notice: '공지', free: '자유', career: '커리어', suggestion: '건의',
  hide: '숨김', restore: '복구', board: '게시판', report: '신고 처리',
};
const MEMBER_LABEL = { active: '활성', withdrawn: '탈퇴' };
const VRF_LABEL = { active: '인증됨', expired: '만료', revoked: '폐기', pending: '승인 대기' };
const lab = (v, map = LABEL) => (v in map ? map[v] : String(v));
const pill = (state, text) => $('span', 'pill ' + state, text);

// ── 로그인 단계 ─────────────────────────────────────────────────────────────
// 이 폼이 **여기** 있어야 하는 이유: 세션 쿠키는 호스트별(Domain 없음)이라 jobcho.wiki 에서 받은
// 쿠키가 이 주소(터널 127.0.0.1 · 관리 호스트)로 오지 않는다. 그리고 이 입구들에는 정적 /login
// 페이지가 없다(앱 포트·관리 vhost 는 /api/v1 만 낸다). "로그인이 필요하다"고 말하면서 그 방법을
// 주지 않는 화면은 막다른 길이다(함정 ㉘ — 실패 경로를 먼저 열어라).
function renderLogin(reason, offerLogout) {
  root.replaceChildren();
  whoEl.replaceChildren();
  tabsEl.hidden = true;
  root.appendChild($('h2', null, '운영자 로그인'));
  if (reason) root.appendChild($('div', 'meta', reason));
  if (offerLogout) {
    // 지금 세션(운영자가 아닌 계정)을 끊어야 다른 이메일로 들어갈 수 있다.
    const out = $('button', null, '지금 세션 로그아웃');
    out.onclick = async () => {
      await req('/members/logout', { method: 'POST' });
      renderLogin('로그아웃했다. 운영자 이메일로 다시 로그인하라.');
    };
    root.appendChild(out);
  }
  root.appendChild($('div', 'meta',
    '이 주소(' + location.host + ')의 세션이 따로 필요하다 — 쿠키는 호스트별이라 jobcho.wiki 로그인은 여기 오지 않는다.'));

  const box = $('div', 'item');
  const row1 = $('div', 'rowbtns');
  const email = $('input'); email.type = 'text'; email.placeholder = '운영자 이메일';
  email.autocomplete = 'username'; email.inputMode = 'email';
  const sendBtn = $('button', null, '코드 받기');
  row1.appendChild(email); row1.appendChild(sendBtn);
  box.appendChild(row1);

  const row2 = $('div', 'rowbtns');
  const code = $('input'); code.type = 'text'; code.placeholder = '6자리 코드';
  code.inputMode = 'numeric'; code.maxLength = 6; code.autocomplete = 'one-time-code';
  const loginBtn = $('button', null, '로그인');
  row2.appendChild(code); row2.appendChild(loginBtn);
  box.appendChild(row2);
  root.appendChild(box);

  sendBtn.onclick = async () => {
    if (!email.value.trim()) { say('이메일을 입력하라.'); return; }
    sendBtn.disabled = true;
    try {
      const res = await req('/members/login-code',
        { method: 'POST', body: JSON.stringify({ email: email.value.trim() }) });
      // 응답은 계정 유무와 무관하게 균일 204 다(계정 열거 방지). 억제된 주소만 409.
      if (res.status === 204) say('코드를 보냈다. 메일함을 확인하라(5분 유효).');
      else if (res.status === 409) say('이 주소는 반송 이력으로 발송이 억제돼 있다 — ops release-suppression 으로 해제하라.');
      else if (res.status === 429) say('요청이 너무 잦다 — 20초쯤 뒤에 다시 하라.');
      else say('예상 밖 응답: ' + res.status);
    } catch (e) { say('실패: ' + e.message); }
    sendBtn.disabled = false;
  };

  loginBtn.onclick = async () => {
    loginBtn.disabled = true;
    try {
      const res = await req('/members/login', {
        method: 'POST',
        body: JSON.stringify({ email: email.value.trim(), code: code.value.trim() }),
      });
      if (res.ok) { say('로그인됨.'); await load(); return; }
      // 상태코드 계약(SP-AUTH-13): 401 불일치 / 410 만료 / 429 시도 초과.
      say({ 401: '코드가 맞지 않는다.', 410: '코드가 만료됐다 — 다시 받아라.',
            429: '시도 횟수를 넘겼다 — 코드를 다시 받아라.' }[res.status]
          || ('로그인 실패: ' + res.status));
    } catch (e) { say('실패: ' + e.message); }
    loginBtn.disabled = false;
  };
}

/** 사용자 입력 원문 한 덩어리 — 텍스트로 보여주고 복사 버튼만 준다(링크 만들지 않음). */
function rawBlock(label, value) {
  const wrap = $('div');
  wrap.appendChild($('div', 'meta', label));
  const box = $('div', 'raw', value || '(없음)');
  wrap.appendChild(box);
  if (value) {
    const b = $('button', null, '복사');
    b.onclick = () => navigator.clipboard.writeText(value).then(() => say('복사했다.'));
    wrap.appendChild(b);
  }
  return wrap;
}

function rawWarning() {
  return $('div', 'warn',
    '닉네임·제목·본문·증빙·회사명·참고 URL 은 사용자가 입력한 원문이다. 링크로 만들지 않는다 — ' +
    '누르면 IP 가 노출되고 피싱일 수 있다. 확인이 필요하면 복사해서 안전한 곳에서 열어라.');
}

function section(title, items, render) {
  root.appendChild($('h2', null, title + ' (' + items.length + ')'));
  if (!items.length) { root.appendChild($('div', 'empty', '대기 없음.')); return; }
  items.forEach((it) => root.appendChild(render(it)));
}

/** 작업 버튼 — 성공하면 결과를 알리고 지금 탭을 다시 그린다. */
function actionButton(label, fn, confirmText) {
  const b = $('button', null, label);
  b.onclick = async () => {
    if (confirmText && !window.confirm(confirmText)) return;
    b.disabled = true;
    try { const r = await fn(); say(JSON.stringify(r)); await rerender(); }
    catch (e) {
      // 작업 도중 세션이 만료될 수 있다. 그때 `e.message` 를 찍으면 undefined 가 뜬다
      // (NEEDS_LOGIN 은 Error 가 아니라 Symbol 이다) — 다시 로그인 단계로 보낸다.
      if (e === NEEDS_LOGIN) { renderLogin('작업 도중 세션이 만료됐다. 다시 로그인하라.'); return; }
      say('실패: ' + e.message); b.disabled = false;
    }
  };
  return b;
}

/** 셀 하나 — 문자열은 텍스트 노드로, 노드는 그대로. 어느 쪽이든 HTML 로 해석되는 경로가 없다. */
function cell(value, cls) {
  const td = $('td', cls);
  if (value instanceof Node) td.appendChild(value);
  else td.textContent = (value === null || value === undefined || value === '') ? '—' : String(value);
  return td;
}

/**
 * 키셋 페이지 표 — 첫 페이지를 그리고, 다음 커서가 있으면 「더 보기」로 이어 붙인다.
 * columns: [{ label, cls, get: (row) => 문자열|Node }], fetchPage: (before) => Promise<{items, next_before}>.
 */
async function pagedTable(columns, fetchPage, emptyText) {
  const box = $('div', 'tbl');
  const table = $('table');
  const thead = $('thead'); const hr = $('tr');
  columns.forEach((c) => hr.appendChild($('th', null, c.label)));
  thead.appendChild(hr); table.appendChild(thead);
  const tbody = $('tbody'); table.appendChild(tbody);
  box.appendChild(table);
  const more = $('button', 'more', '더 보기');
  let cursor = null;
  let shown = 0;
  const addPage = async (before) => {
    const page = await fetchPage(before);
    page.items.forEach((row) => {
      const tr = $('tr');
      columns.forEach((c) => tr.appendChild(cell(c.get(row), c.cls)));
      tbody.appendChild(tr);
    });
    shown += page.items.length;
    cursor = page.next_before;
    more.hidden = cursor === null || cursor === undefined;
    if (!shown) {
      const tr = $('tr'); const td = $('td', 'empty', emptyText || '없음.');
      td.colSpan = columns.length; tr.appendChild(td); tbody.appendChild(tr);
    }
  };
  more.onclick = async () => {
    more.disabled = true;
    try { await addPage(cursor); } catch (e) {
      if (e === NEEDS_LOGIN) { renderLogin('세션이 만료됐다. 다시 로그인하라.'); return; }
      say('실패: ' + e.message);
    }
    more.disabled = false;
  };
  await addPage(null);
  const wrap = $('div'); wrap.appendChild(box); wrap.appendChild(more);
  return wrap;
}

const qs = (params) => {
  const p = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v !== null && v !== undefined && v !== '') p.set(k, v); });
  const s = p.toString();
  return s ? '?' + s : '';
};

/** 닉네임 + 회원 번호 — 두 줄. 탈퇴(작성자 NULL)면 번호가 없다. */
function who(nickname, memberId) {
  const f = document.createDocumentFragment();
  f.appendChild(document.createTextNode(nickname || '—'));
  f.appendChild($('span', 'sub', memberId ? 'MBR ' + memberId : '(탈퇴)'));
  return f;
}

// ── 탭 1: 현황 ───────────────────────────────────────────────────────────────
function card(title, rows) {
  const c = $('div', 'card');
  c.appendChild($('h3', null, title));
  const dl = $('dl');
  rows.forEach(([label, value, hot]) => {
    dl.appendChild($('dt', null, label));
    dl.appendChild($('dd', hot && value > 0 ? 'hot' : null, String(value)));
  });
  c.appendChild(dl);
  return c;
}

async function renderOverview() {
  const d = await api('/overview');
  root.appendChild($('div', 'meta', '집계 ' + kst(d.as_of) + ' · 주황 숫자 = 처리할 일'));
  const grid = $('div', 'cards');
  grid.appendChild(card('회원', [['전체', d.members.total], ['활성', d.members.active],
    ['최근 7일 가입', d.members.new_7d], ['최근 30일 가입', d.members.new_30d]]));
  grid.appendChild(card('재직 인증', [['인증됨(유효)', d.verifications.active],
    ['수동 승인 대기', d.verifications.pending, true]]));
  grid.appendChild(card('회사 등록 요청', [['대기', d.company_requests.pending, true],
    ['처리됨', d.company_requests.decided]]));
  grid.appendChild(card('게시물', [['전체', d.posts.total], ['최근 7일', d.posts.new_7d], ['숨김', d.posts.hidden]]));
  grid.appendChild(card('댓글', [['전체', d.comments.total], ['최근 7일', d.comments.new_7d], ['숨김', d.comments.hidden]]));
  grid.appendChild(card('신고', [['대기', d.reports.pending, true]]));
  grid.appendChild(card('복지 수정 이력', [['전체', d.benefit_edits.total], ['최근 30일', d.benefit_edits.new_30d]]));
  grid.appendChild(card('메일 발송 억제', [['억제 중', d.mail_suppression.active, true]]));
  root.appendChild(grid);
  const todo = d.verifications.pending + d.company_requests.pending + d.reports.pending;
  const go = $('div', 'rowbtns');
  const btn = $('button', null, '처리 대기 열기 (' + todo + ')');
  btn.onclick = () => show('queues');
  go.appendChild(btn);
  root.appendChild(go);
}

// ── 탭 2: 처리 대기(기존 큐 4종) ─────────────────────────────────────────────
async function renderQueues() {
  const data = await api('/queues');
  root.appendChild(rawWarning());

  section('재직 수동 승인', data.verifications, (v) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + v.id));
    h.appendChild($('span', null, v.company));
    h.appendChild($('span', 'meta', v.nickname + ' (MBR ' + v.member_id + ') · ' + kst(v.at)));
    el.appendChild(h);
    el.appendChild(rawBlock('증빙(사용자 입력 원문)', v.evidence));
    const btns = $('div', 'rowbtns');
    const note = $('input'); note.type = 'text'; note.placeholder = '메모(선택)';
    btns.appendChild(note);
    btns.appendChild(actionButton('승인', () => api('/verifications/' + v.id + '/approve',
      { method: 'POST', body: JSON.stringify({ note: note.value || null }) })));
    btns.appendChild(actionButton('거부', () => api('/verifications/' + v.id + '/reject',
      { method: 'POST', body: JSON.stringify({ note: note.value || null }) })));
    el.appendChild(btns);
    return el;
  });

  section('회사 등록 요청', data.company_requests, (c) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + c.id));
    h.appendChild($('span', 'meta', (c.nickname || '(탈퇴 회원 ' + c.member_id + ')') + ' · ' + kst(c.at)));
    el.appendChild(h);
    el.appendChild(rawBlock('요청 회사명(사용자 입력 원문)', c.name));
    el.appendChild(rawBlock('참고 URL(사용자 입력 원문 — 누르지 마라)', c.ref_url));
    el.appendChild($('div', 'meta',
      '승인해도 회사는 생기지 않는다. db/seed 작업 + 정적 사이트 재생성이 따로 필요하다.'));
    const btns = $('div', 'rowbtns');
    const note = $('input'); note.type = 'text'; note.placeholder = '메모(선택)';
    btns.appendChild(note);
    btns.appendChild(actionButton('승인 표시', () => api('/company-requests/' + c.id + '/decide',
      { method: 'POST', body: JSON.stringify({ approve: true, note: note.value || null }) })));
    btns.appendChild(actionButton('거부', () => api('/company-requests/' + c.id + '/decide',
      { method: 'POST', body: JSON.stringify({ approve: false, note: note.value || null }) })));
    el.appendChild(btns);
    return el;
  });

  // SC15 게시물 신고(FR-131). 발췌·상세·닉네임은 전부 사용자 입력 원문 → rawBlock(텍스트 노드)만.
  // '숨김' 은 되돌릴 수 있는 상태 변경(hidden)이고 하드 삭제가 아니다 — 같은 대상의 다른 신고도 함께 처리된다.
  section('게시물 신고', data.reports || [], (r) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + r.report_id));
    h.appendChild($('span', null, (r.target_type === 'post' ? '글' : '댓글') + ' #' + r.target_id + ' · ' + r.reason));
    h.appendChild($('span', 'meta', r.reporter_nickname + ' · ' + kst(r.created_at)));
    el.appendChild(h);
    el.appendChild(rawBlock('대상 발췌(사용자 입력 원문, 80자)', r.excerpt));
    el.appendChild(rawBlock('신고 상세(사용자 입력 원문)', r.detail));
    const btns = $('div', 'rowbtns');
    const note = $('input'); note.type = 'text'; note.placeholder = '메모(선택)';
    btns.appendChild(note);
    btns.appendChild(actionButton('숨김(같은 대상 신고 일괄 처리)', () => api('/reports/' + r.report_id + '/decide',
      { method: 'POST', body: JSON.stringify({ action: 'hide', note: note.value || null }) })));
    btns.appendChild(actionButton('기각', () => api('/reports/' + r.report_id + '/decide',
      { method: 'POST', body: JSON.stringify({ action: 'dismiss', note: note.value || null }) })));
    el.appendChild(btns);
    return el;
  });

  section('메일 발송 억제', data.suppressed, (s) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + s.id));
    h.appendChild($('span', null, s.reason));
    h.appendChild($('span', 'meta', kst(s.at)));
    el.appendChild(h);
    // 주소 원문은 애초에 저장되지 않는다(T9) — 해시만 보여준다.
    el.appendChild($('div', 'raw', s.target_hash));
    const btns = $('div', 'rowbtns');
    btns.appendChild(actionButton('억제 해제', () => api('/suppressions/' + s.target_hash + '/release',
      { method: 'POST', body: JSON.stringify({ note: null }) })));
    el.appendChild(btns);
    return el;
  });
}

// ── 탭 3: 회원 ───────────────────────────────────────────────────────────────
// 인증 방식은 풀어 쓴다 — 예전 「메일」 한 글자가 옆 칸의 로그인 이메일로 읽혀, 네이버 가입자가
// 회사 인증을 받은 것처럼 보였다(2026-09-22). 도메인 인증은 로그인 이메일과 **별개의 회사 메일**로
// 코드를 받아 통과한 것이고, 그 주소 원문은 저장하지 않으므로 회사의 등록 도메인만 보여 준다.
const METHOD_LABEL = { domain: '회사 메일로 인증', manual: '운영자 수동 승인' };

function verificationList(list) {
  if (!list.length) return '—';
  const ul = $('ul', 'diff');
  list.forEach((v) => {
    const li = $('li');
    li.appendChild(document.createTextNode((v.company || '(삭제된 회사 ' + v.company_id + ')') + ' '));
    li.appendChild(pill(v.state, lab(v.state, VRF_LABEL)));
    const how = v.state === 'pending' ? '수동 승인 요청' : lab(v.method, METHOD_LABEL);
    const domains = (v.domains || []).length ? ' (@' + v.domains.join(' · @') + ')' : '';
    li.appendChild(document.createTextNode(' ' + how + domains));
    if (v.since) li.appendChild($('span', 'sub', ' · ' + kst(v.since)));
    ul.appendChild(li);
  });
  return ul;
}

async function renderMembers() {
  root.appendChild($('div', 'warn',
    '로그인 이메일은 개인정보다 — 이 화면 밖으로 옮기지 마라(캡처·복사 주의). ' +
    '「최근 세션」은 보존 중인 세션 기준이다(만료·로그아웃 세션은 매일 지워진다). ' +
    '재직 인증은 로그인 이메일과 별개다 — 「회사 메일로 인증」은 괄호 안 도메인의 회사 주소로 코드를 받아 ' +
    '통과한 것이고, 그 주소 원문은 저장하지 않는다(도메인은 지금 등록된 목록).'));
  root.appendChild(await pagedTable([
    { label: 'ID', cls: 'nw', get: (m) => String(m.member_id) },
    { label: '닉네임', get: (m) => m.nickname },
    { label: '로그인 이메일', cls: 'nw', get: (m) => m.email || '(탈퇴 — 파기됨)' },
    { label: '상태', cls: 'nw', get: (m) => pill(m.status, lab(m.status, MEMBER_LABEL)) },
    { label: '가입', cls: 'nw', get: (m) => kst(m.joined_at) },
    { label: '최근 세션', cls: 'nw', get: (m) => kst(m.last_session_at) },
    { label: '재직 인증', get: (m) => verificationList(m.verifications) },
  ], (before) => api('/members' + qs({ before })), '회원 없음.'));
}

// ── 탭 4: 게시판(글·댓글) ────────────────────────────────────────────────────
const board = { kind: 'posts', status: '' };

function visibilityButton(kind, id, status) {
  const path = '/' + kind + '/' + id + '/visibility';
  if (status === 'active') {
    return actionButton('숨김', () => api(path, { method: 'POST', body: JSON.stringify({ action: 'hide' }) }),
      '#' + id + ' 을(를) 숨긴다. 공개 목록·상세에서 사라지고, 같은 대상의 대기 신고도 함께 닫힌다. 복구할 수 있다.');
  }
  if (status === 'hidden') {
    return actionButton('복구', () => api(path, { method: 'POST', body: JSON.stringify({ action: 'restore' }) }),
      '#' + id + ' 을(를) 다시 공개한다.');
  }
  return '—';  // deleted = 작성자 본인의 삭제(본문 마스킹) — 되살릴 원문이 없다
}

function titleCell(title, excerpt) {
  const f = document.createDocumentFragment();
  f.appendChild(document.createTextNode(title || ''));
  if (excerpt) f.appendChild($('span', 'sub', excerpt));
  return f;
}

/** 조치 이력(TPOST_ACTION_LOG) 마지막 1건 + 총 횟수 — 누가 숨겼는지는 복구 뒤에도 여기 남는다. */
function actionCell(cnt, last) {
  if (!cnt || !last) return '—';
  const f = document.createDocumentFragment();
  f.appendChild(document.createTextNode(lab(last.action) + ' · ' + (last.actor_id ? 'MBR ' + last.actor_id : '(탈퇴)')
    + ' · ' + kst(last.at)));
  f.appendChild($('span', 'sub', lab(last.source) + (last.note ? ' · ' + last.note : '') + ' · 총 ' + cnt + '회'));
  return f;
}

function reportCell(pending, total) {
  if (!total) return '0';
  return pending ? pill('pending', '대기 ' + pending + ' / ' + total) : String(total);
}

async function renderBoard() {
  root.appendChild(rawWarning());
  const bar = $('div', 'filters');
  [['posts', '글'], ['comments', '댓글']].forEach(([k, label]) => {
    const b = $('button', null, label);
    b.setAttribute('aria-pressed', String(board.kind === k));
    b.onclick = () => { board.kind = k; rerender(); };
    bar.appendChild(b);
  });
  const sel = $('select');
  sel.setAttribute('aria-label', '상태');
  [['', '전체 상태'], ['active', '공개'], ['hidden', '숨김'], ['deleted', '삭제(작성자)']].forEach(([v, label]) => {
    const o = $('option', null, label); o.value = v; if (board.status === v) o.selected = true; sel.appendChild(o);
  });
  sel.onchange = () => { board.status = sel.value; rerender(); };
  bar.appendChild(sel);
  root.appendChild(bar);

  if (board.kind === 'posts') {
    root.appendChild(await pagedTable([
      { label: 'ID', cls: 'nw', get: (p) => String(p.post_id) },
      { label: '분류', cls: 'nw', get: (p) => lab(p.category) },
      { label: '제목 / 발췌', cls: 'txt', get: (p) => titleCell(p.title, p.excerpt) },
      { label: '작성자', get: (p) => who(p.nickname, p.member_id) },
      { label: '작성', cls: 'nw', get: (p) => kst(p.created_at) },
      { label: '상태', cls: 'nw', get: (p) => pill(p.status, lab(p.status)) },
      { label: '댓글·좋아요', cls: 'nw', get: (p) => p.comment_cnt + ' · ' + p.like_cnt },
      { label: '신고', cls: 'nw', get: (p) => reportCell(p.report_pending_cnt, p.report_cnt) },
      { label: '최근 조치', get: (p) => actionCell(p.action_cnt, p.last_action) },
      { label: '조작', cls: 'nw', get: (p) => visibilityButton('posts', p.post_id, p.status) },
    ], (before) => api('/posts' + qs({ before, status: board.status })), '글 없음.'));
  } else {
    root.appendChild(await pagedTable([
      { label: 'ID', cls: 'nw', get: (k) => String(k.comment_id) },
      { label: '글', cls: 'txt', get: (k) => titleCell('#' + k.post_id + ' ' + (k.post_title || ''), null) },
      { label: '발췌', cls: 'txt', get: (k) => k.excerpt },
      { label: '작성자', get: (k) => who(k.nickname, k.member_id) },
      { label: '작성', cls: 'nw', get: (k) => kst(k.created_at) },
      { label: '상태', cls: 'nw', get: (k) => pill(k.status, lab(k.status)) },
      { label: '신고', cls: 'nw', get: (k) => reportCell(k.report_pending_cnt, k.report_cnt) },
      { label: '최근 조치', get: (k) => actionCell(k.action_cnt, k.last_action) },
      { label: '조작', cls: 'nw', get: (k) => visibilityButton('comments', k.comment_id, k.status) },
    ], (before) => api('/comments' + qs({ before, status: board.status })), '댓글 없음.'));
  }
}

// ── 탭 5: 복지 수정 이력(읽기 전용) ──────────────────────────────────────────
const FIELD_LABEL = {
  benefit_cd: '코드', benefit_nm: '이름', benefit_ctgr_cd: '카테고리', benefit_amt: '금액(만원)',
  qual_yn: '정성', note_ctnt: '비고', badge_cd: '배지', amt_source: '금액 출처',
};
const show1 = (v) => (v === null || v === undefined || v === '') ? '∅' : (typeof v === 'object' ? JSON.stringify(v) : String(v));

/** 전→후 — 수정은 바뀐 필드만, 등록은 후 값, 삭제는 전 값. 값은 전부 텍스트 노드다. */
function diffList(e) {
  const b = (e.before && typeof e.before === 'object') ? e.before : {};
  const a = (e.after && typeof e.after === 'object') ? e.after : {};
  const keys = Array.from(new Set(Object.keys(b).concat(Object.keys(a))));
  const ul = $('ul', 'diff');
  keys.forEach((k) => {
    let line = null;
    if (e.edit_type === 'update') {
      if (JSON.stringify(b[k]) !== JSON.stringify(a[k])) line = show1(b[k]) + ' → ' + show1(a[k]);
    } else if (e.edit_type === 'create') {
      line = show1(a[k]);
    } else {
      line = show1(b[k]);
    }
    if (line !== null) ul.appendChild($('li', null, (FIELD_LABEL[k] || k) + ': ' + line));
  });
  if (!ul.childNodes.length) return '(바뀐 필드 없음)';
  return ul;
}

async function renderEdits() {
  root.appendChild($('div', 'warn',
    '읽기 전용이다 — 되돌리기는 여기서 하지 않는다. 편집 메모·항목 값은 재직자가 입력한 원문이다.'));
  root.appendChild(await pagedTable([
    { label: 'ID', cls: 'nw', get: (e) => String(e.edit_id) },
    { label: '시각', cls: 'nw', get: (e) => kst(e.at) },
    { label: '회사', get: (e) => e.company || ('(삭제된 회사 ' + e.company_id + ')') },
    { label: '항목', get: (e) => titleCell(e.benefit_nm || '', e.benefit_cd) },
    { label: '유형', cls: 'nw', get: (e) => lab(e.edit_type) },
    { label: '전 → 후', cls: 'txt', get: (e) => diffList(e) },
    { label: '편집 메모', cls: 'txt', get: (e) => e.note },
    { label: '편집자', get: (e) => who(e.editor_nickname, e.editor_id) },
  ], (before) => api('/benefit-edits' + qs({ before })), '이력 없음.'));
}

// ── 탭 전환 ─────────────────────────────────────────────────────────────────
// 탭은 링크가 아니라 버튼이다(위 규칙 ②). 지금 탭은 URL 조각(#members 등)에 적어 새로고침해도 남긴다.
const TABS = [
  { id: 'overview', label: '현황', render: renderOverview },
  { id: 'queues', label: '처리 대기', render: renderQueues },
  { id: 'members', label: '회원', render: renderMembers },
  { id: 'board', label: '게시판', render: renderBoard },
  { id: 'edits', label: '복지 이력', render: renderEdits },  // 390px 에서 탭 다섯이 한 줄에 들도록 짧게
];
let current = 'overview';

function drawTabs() {
  tabsEl.replaceChildren();
  TABS.forEach((t) => {
    const b = $('button', null, t.label);
    b.setAttribute('role', 'tab');
    b.setAttribute('aria-selected', String(t.id === current));
    b.onclick = () => show(t.id);
    tabsEl.appendChild(b);
  });
  tabsEl.hidden = false;
}

async function show(id) {
  current = TABS.some((t) => t.id === id) ? id : 'overview';
  if (location.hash !== '#' + current) history.replaceState(null, '', '#' + current);
  drawTabs();
  await rerender();
}

async function rerender() {
  root.replaceChildren();
  say('불러오는 중…');
  try {
    await TABS.find((t) => t.id === current).render();
    say('');
  } catch (e) {
    // 세션 없음은 **오류가 아니라 다음 단계**다. 여기서 문구만 띄우면 막다른 길이 된다.
    if (e === NEEDS_LOGIN) { renderLogin('세션이 없거나 만료됐다.'); return; }
    say(e.message);
  }
}

async function load() {
  root.replaceChildren();
  say('불러오는 중…');
  let data;
  try {
    data = await api('/overview');  // 로그인 확인 겸 운영자 주소
  } catch (e) {
    if (e === NEEDS_LOGIN) { renderLogin('세션이 없거나 만료됐다.'); return; }
    if (e.notAllowed) { renderLogin('이 세션은 운영자 계정이 아니다(또는 허락된 입구 밖이다).', true); return; }
    say(e.message);
    return;
  }
  whoEl.replaceChildren(document.createTextNode('운영자: ' + data.operator));
  const out = $('button', null, '로그아웃');
  out.onclick = async () => {
    await req('/members/logout', { method: 'POST' });
    renderLogin('로그아웃했다.');
  };
  whoEl.appendChild(out);
  await show(location.hash.slice(1) || 'overview');
}
load();
</script></body></html>
"""


def _sha256_source(pattern: str) -> str:
    """페이지 안 인라인 블록 하나의 CSP 해시(`'sha256-…'`). 블록이 없거나 둘 이상이면 기동 시 실패한다."""
    blocks = re.findall(pattern, _PAGE, re.S)
    if len(blocks) != 1:
        raise RuntimeError(f"콘솔 페이지 인라인 블록이 정확히 1개가 아니다({len(blocks)}): {pattern}")
    return "'sha256-" + base64.b64encode(hashlib.sha256(blocks[0].encode("utf-8")).digest()).decode() + "'"


# 콘솔 화면의 CSP — **이 페이지에 있는 인라인 스크립트·스타일 딱 하나씩만** 실행을 허락한다(해시).
# 화면은 사용자 입력을 텍스트 노드로만 넣지만(규칙 ①), 그 규칙이 언젠가 한 군데서 깨지더라도
# 주입된 스크립트는 돌지 않고(`script-src` 해시), 돌더라도 밖으로 못 보낸다(`connect-src 'self'`,
# `img-src` 없음 — 이미지 비콘 차단). 해시는 `_PAGE` 에서 계산하므로 페이지를 고쳐도 따라온다.
_CSP = "; ".join([
    "default-src 'none'",
    "script-src " + _sha256_source(r"<script>(.*?)</script>"),
    "style-src " + _sha256_source(r"<style>(.*?)</style>"),
    "connect-src 'self'",
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'",
])
