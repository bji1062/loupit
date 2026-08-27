"""SP-COMM-1·4·5 커뮤니티 라우터 — 열람 GET 3(익명) + 세션 쓰기 6 (FR-121~129).

- 열람 3종은 **익명**이다(INV-1 개정). 상세·댓글은 `deps.optional_member` 로 세션을 **선택적으로**
  읽어 `is_mine`·`liked` 만 계산한다 — 401 을 내지 않으며, dependant 트리에 `require_member` 가
  없다(AU-2, test_community_api CM-7.4). 목록은 세션을 아예 읽지 않는다.
- 쓰기 6종은 `deps.require_csrf`(커스텀 헤더 부재 403) → `deps.require_member`(무세션 401) 순서.
  소유자 검사(403)·상태 검사(404)는 서비스에서 같은 잠금 안에 한다.
- 공지(`category=notice`)는 운영자만 — 세션은 MBR_ID 만 주므로 TMEMBER 를 재조회해 `is_operator`.
- 전부 `Cache-Control: no-store`(공통 규약). 조회수 없음. 운영자용 삭제 라우트 없음(콘솔 hide 뿐).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from fastapi.responses import JSONResponse

from server.config import get_settings
from server.deps import optional_member, require_csrf, require_member
from server.models.post import (
    CATEGORIES,
    SORTS,
    CommentIn,
    CommentListOut,
    PostCreateIn,
    PostDetailOut,
    PostListOut,
    PostUpdateIn,
)
from server.services import operator
from server.services import post as post_svc

router = APIRouter(tags=["post"])

_NO_STORE = {"Cache-Control": "no-store"}


# ── 열람 (FR-121~123) — 익명·no-store ─────────────────────────────────────────

@router.get("/posts", response_model=PostListOut)
async def list_posts(
    response: Response,
    category: str | None = Query(default=None, max_length=12),
    sort: str = Query(default="latest", max_length=12),
    limit: int = Query(default=20, ge=1),
    before: int | None = Query(default=None, ge=1),  # 커서(POST_ID) — 이 값보다 오래된 글
) -> PostListOut:
    """목록 — 카테고리·정렬 3종·키셋. 알 수 없는 category/sort·limit 초과는 422(FR-121)."""
    if category is not None and category not in CATEGORIES:
        raise HTTPException(status_code=422, detail="카테고리가 올바르지 않습니다.")
    if sort not in SORTS:
        raise HTTPException(status_code=422, detail="정렬 기준이 올바르지 않습니다.")
    max_limit = get_settings().post_list_max_limit
    if limit > max_limit:
        raise HTTPException(status_code=422, detail=f"limit 은 최대 {max_limit} 입니다.")
    items, next_before = await post_svc.list_posts(category, sort, limit, before)
    response.headers["Cache-Control"] = "no-store"
    return PostListOut(items=items, next_before=next_before)


@router.get("/posts/{post_id}", response_model=PostDetailOut)
async def get_post(
    response: Response,
    post_id: int = Path(..., ge=1),
    viewer: dict | None = Depends(optional_member),
) -> PostDetailOut:
    """상세 — deleted/hidden/부재 404. `is_mine`·`liked` 는 쿠키가 있을 때만 참일 수 있다(FR-122)."""
    item = await post_svc.get_post(post_id, viewer["MBR_ID"] if viewer else None)
    if item is None:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    response.headers["Cache-Control"] = "no-store"
    return PostDetailOut(**item)


@router.get("/posts/{post_id}/comments", response_model=CommentListOut)
async def list_comments(
    response: Response,
    post_id: int = Path(..., ge=1),
    after: int | None = Query(default=None, ge=1),  # 커서(COMMENT_ID) — 이 값보다 새 댓글
    limit: int = Query(default=50, ge=1, le=200),
    viewer: dict | None = Depends(optional_member),
) -> CommentListOut:
    """댓글 — 오래된 순·`after` 커서. 삭제·숨김 댓글은 `body:null, deleted:true` 자리만. 글이 404 면 404(FR-123)."""
    if not await post_svc.post_is_active(post_id):
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    items, next_after = await post_svc.list_comments(post_id, after, limit, viewer["MBR_ID"] if viewer else None)
    response.headers["Cache-Control"] = "no-store"
    return CommentListOut(items=items, next_after=next_after)


# ── 쓰기 (FR-124~129) — require_csrf → require_member ─────────────────────────

@router.post("/posts", status_code=201)
async def create_post(
    body: PostCreateIn,
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> JSONResponse:
    """글 작성 → 201 `{post_id}`. 공지는 운영자만(403) · 회사 태그 미등록 422 · 일일 상한 429(FR-124)."""
    if body.category == "notice":
        email = await post_svc.member_email(member["MBR_ID"])
        if not operator.is_operator(email):
            raise HTTPException(status_code=403, detail="공지는 운영자만 작성할 수 있습니다.")
    result = await post_svc.create_post(member["MBR_ID"], body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="오늘 작성 한도를 초과했습니다.")
    if result["result"] == "comp_not_found":
        raise HTTPException(status_code=422, detail="등록되지 않은 회사입니다.")
    return JSONResponse(status_code=201, content={"post_id": result["post_id"]}, headers=_NO_STORE)


@router.put("/posts/{post_id}")
async def update_post(
    body: PostUpdateIn,
    post_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> JSONResponse:
    """글 수정 → 200 `{post_id, updated_at}`. 본인 아니면 403 · 비활성 404 · `category` 는 받지 않는다(FR-125)."""
    result = await post_svc.update_post(post_id, member["MBR_ID"], body)
    if result["result"] == "not_found":
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    if result["result"] == "forbidden":
        raise HTTPException(status_code=403, detail="본인의 글만 수정할 수 있습니다.")
    if result["result"] == "comp_not_found":
        raise HTTPException(status_code=422, detail="등록되지 않은 회사입니다.")
    return JSONResponse(
        status_code=200,
        content={"post_id": post_id, "updated_at": result["updated_at"].isoformat()},
        headers=_NO_STORE,
    )


@router.delete("/posts/{post_id}", status_code=204)
async def delete_post(
    post_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> Response:
    """글 소프트 삭제 → 204. 본인만(운영자도 이 라우트로는 못 지운다 — 운영자 조치는 콘솔 hide)(FR-126)."""
    result = await post_svc.delete_post(post_id, member["MBR_ID"])
    if result == "not_found":
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    if result == "forbidden":
        raise HTTPException(status_code=403, detail="본인의 글만 삭제할 수 있습니다.")
    return Response(status_code=204, headers=_NO_STORE)


@router.post("/posts/{post_id}/comments", status_code=201)
async def create_comment(
    body: CommentIn,
    post_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> JSONResponse:
    """댓글 작성 → 201 `{comment_id}` + COMMENT_CNT+1(트랜잭션). 비활성 글 404 · 일일 상한 429(FR-127)."""
    result = await post_svc.create_comment(post_id, member["MBR_ID"], body.body)
    if result["result"] == "rate_limited":
        raise HTTPException(status_code=429, detail="오늘 댓글 한도를 초과했습니다.")
    if result["result"] == "not_found":
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    return JSONResponse(status_code=201, content={"comment_id": result["comment_id"]}, headers=_NO_STORE)


@router.delete("/posts/{post_id}/comments/{comment_id}", status_code=204)
async def delete_comment(
    post_id: int = Path(..., ge=1),
    comment_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> Response:
    """댓글 소프트 삭제 → 204 + COMMENT_CNT-1. 본인만 403 · 글/댓글 비활성 404(FR-128)."""
    result = await post_svc.delete_comment(post_id, comment_id, member["MBR_ID"])
    if result == "not_found":
        raise HTTPException(status_code=404, detail="댓글을 찾을 수 없습니다.")
    if result == "forbidden":
        raise HTTPException(status_code=403, detail="본인의 댓글만 삭제할 수 있습니다.")
    return Response(status_code=204, headers=_NO_STORE)


@router.put("/posts/{post_id}/like")
async def toggle_like(
    post_id: int = Path(..., ge=1),
    _csrf: None = Depends(require_csrf),
    member: dict = Depends(require_member),
) -> JSONResponse:
    """좋아요 토글·멱등 → 200 `{liked, like_cnt}`. 비활성 글 404(FR-129)."""
    result = await post_svc.toggle_like(post_id, member["MBR_ID"])
    if result is None:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
    return JSONResponse(status_code=200, content=result, headers=_NO_STORE)
