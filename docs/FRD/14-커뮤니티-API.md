# 커뮤니티 API (FRD)

**목적**: PRD 범위 **SC15(커뮤니티, 2026-08-27 증분)**의 기능 — 게시글 목록·상세·댓글 열람(익명), 글·댓글·좋아요·신고 쓰기(로그인 세션), 운영자 신고 처리 — 를 구현 가능한 **HTTP·전송 계약**으로 확정한다. 로그인·세션·CSRF·리밋의 **기제는 SC14(FRD 13)를 그대로 재사용**하며 본 문서는 커뮤니티 엔드포인트만 정의한다.

**참조 상위문서**: PRD `04-범위.md`(SC15·SC10 정의 확정), USECASE `10-커뮤니티.md`(UC-80~UC-87), SPEC `01`(INV-1 개정·INV-8·INV-9), SPEC `14-커뮤니티.md`(SP-COMM), SPEC `02`(SP-DB-18 4테이블 DDL), 계획 `PLAN-커뮤니티-회사정보탭-2026-08-27.md`.

**FR-ID 대역**: **FR-120~FR-133**. 각 FR 은 UC(UC-80~87)·SC15·관련 NFR·INV 를 역참조한다.

**전역 전제**: (1) 열람 GET 3종은 익명·무쿠키(`apiFetch`, INV-1 개정). (2) 쓰기는 세션 쿠키 + `X-Loupit-Client`(FR-113) — `require_csrf` → `require_member` 순서. (3) 작성자 식별은 응답에 **닉네임만**(INV-8). (4) 조회수 컬럼·API 없음. (5) 삭제는 소프트. (6) 라우터는 M9 게이트(`m9_enabled`) 안에서만 등록된다 — 참여 테이블(TMEMBER) FK 가 있으므로.

---

## 공통 규약

| 항목 | 규약 |
|---|---|
| 기본 경로 | `/api/v1/posts…` · `/api/v1/reports` · `/api/v1/console/reports…` |
| 캐시 | 공개 GET: `Cache-Control: no-store`(1차. 목록은 편집 직후 stale 이 사용자에게 바로 보이는 쪽이 나쁘다). 쓰기: `no-store` |
| 페이징 | 키셋 — `?limit=20(≤50)&before=<id>`; 응답에 `next_before`(없으면 null). offset 없음(편집 이력 FR-110 관례) |
| 오류 envelope | 기존 전역 핸들러(`{detail}`) 그대로. 422 는 type·loc·msg 만(NFR31) |
| 시각 | ISO8601 UTC 문자열 |

## FR 인덱스

| FR-ID | 제목 | 엔드포인트 | UC |
|---|---|---|---|
| FR-120 | 커뮤니티 API 표면(INV-1 개정) | 공개 GET 3 + 세션 쓰기 8 + 콘솔 1 | 전제 |
| FR-121 | 목록 | `GET /posts` | UC-80 |
| FR-122 | 상세 | `GET /posts/{post_id}` | UC-81 |
| FR-123 | 댓글 목록 | `GET /posts/{post_id}/comments` | UC-81 |
| FR-124 | 글 작성 | `POST /posts` | UC-82 |
| FR-125 | 글 수정 | `PUT /posts/{post_id}` | UC-83 |
| FR-126 | 글 삭제(소프트) | `DELETE /posts/{post_id}` | UC-83 |
| FR-127 | 댓글 작성 | `POST /posts/{post_id}/comments` | UC-84 |
| FR-128 | 댓글 삭제(소프트) | `DELETE /posts/{post_id}/comments/{comment_id}` | UC-84 |
| FR-129 | 좋아요 토글 | `PUT /posts/{post_id}/like` | UC-85 |
| FR-130 | 신고 | `POST /reports` | UC-86 |
| FR-131 | 신고 처리(콘솔) | `GET /console/queues`(확장) · `POST /console/reports/{report_id}/decide` | UC-87 |
| FR-132 | 입력 신뢰 경계·일일 리밋 | 전 쓰기 | UC-82~86 |
| FR-133 | 정책 문안 동반 | privacy P10 · terms T6 | 전제 |

---

## FR-120 커뮤니티 API 표면

- TS-1 기대 집합에 **정확히** 다음이 추가된다 — 공개 GET `/posts`·`/posts/{post_id}`·`/posts/{post_id}/comments`; 쓰기 `POST /posts`·`PUT /posts/{post_id}`·`DELETE /posts/{post_id}`·`POST /posts/{post_id}/comments`·`DELETE /posts/{post_id}/comments/{comment_id}`·`PUT /posts/{post_id}/like`·`POST /reports`·`POST /console/reports/{report_id}/decide`. 그 외 쓰기 0.
- 미들웨어 0 불변(TS-2). 라우터 파일 allowlist(test_package)에 `post.py`·`report.py` 추가.

## FR-121 `GET /posts`

- 쿼리: `category ∈ {notice, free, career, suggestion}`(생략=전체) · `sort ∈ {latest, comments, likes}`(기본 latest) · `limit` · `before`.
- 응답 200 `{items:[{post_id, category, title, nickname, verified_comp_nm|null, comp:{comp_id, comp_nm, slug}|null, like_cnt, comment_cnt, created_at, edited: bool}], next_before}`. `active` 만.
- `sort=comments|likes` 는 (카운터 DESC, post_id DESC) 정렬이고 커서는 `post_id` 만 쓴다(1차 단순화 — 동률 경계에서 중복 가능성은 수용, 문서화).
- 422: 알 수 없는 category/sort, limit>50.

## FR-122 `GET /posts/{post_id}`

- 200 `{post_id, category, title, body, nickname, verified_comp_nm, comp, like_cnt, comment_cnt, created_at, updated_at, edited, is_mine: bool, liked: bool}`.
  `is_mine`·`liked` 는 세션 쿠키가 **있을 때만** 참일 수 있다 — 이 GET 은 익명 경로지만 쿠키가 동봉되면 읽는다(선택적 세션, `optional_member` 의존성. 401 을 내지 않는다).
- 404: 없음·`deleted`·`hidden`.

## FR-123 `GET /posts/{post_id}/comments`

- 오래된 순(`comment_id ASC`), `after=<comment_id>` 커서(댓글은 아래로 자란다). 응답 항목 `{comment_id, nickname, verified_comp_nm, body|null, deleted: bool, is_mine, created_at}` — 삭제 댓글은 `body:null, deleted:true` 로 자리만.
- 글이 404 면 404.

## FR-124 `POST /posts`

- 본문 `{category, title(1~100), body(1~5000), comp_id|null}`. 201 `{post_id}`.
- `category=notice` 는 `is_operator`(OPERATOR_EMAILS) 만 — 아니면 403. 다른 카테고리는 회원 누구나.
- `comp_id` 는 등록 회사여야 한다(없으면 422).
- 429: 계정 일일 글 상한(`daily_post_limit`, 기본 10).

## FR-125 `PUT /posts/{post_id}` · FR-126 `DELETE /posts/{post_id}`

- 본인만(403). `category` 는 받지 않는다. PUT 200 `{post_id, updated_at}` 이고 `edited=true` 가 된다. DELETE 204 → `STATUS_CD=deleted`, `TITLE_NM='(삭제됨)'`, `BODY_CTNT=''` 로 마스킹(원문 보존 안 함 — 탈퇴자 요청 대응 단순화).
- 운영자도 남의 글을 이 라우트로 지우지 않는다 — 운영자 조치는 FR-131(hidden) 뿐.

## FR-127 · FR-128 댓글

- POST `{body(1~1000)}` → 201 `{comment_id}` · `COMMENT_CNT+1`. 429 `daily_comment_limit`(50).
- DELETE 본인만 → 204 · 소프트 · `COMMENT_CNT-1`. 글이 deleted/hidden 이면 404.

## FR-129 `PUT /posts/{post_id}/like`

- 토글·멱등: 없으면 생성, 있으면 삭제. 200 `{liked, like_cnt}`. `LIKE_CNT` 는 트랜잭션 안에서 갱신.

## FR-130 `POST /reports`

- `{target_type ∈ {post, comment}, target_id, reason ∈ {spam, abuse, privacy, other}, detail ≤300}` → 202 `{report_id}`. 같은 (회원, 대상) 중복 409. 대상 부재 404. 429 `daily_report_limit`(20).
- 접수는 대상을 바꾸지 않는다(자동 숨김 없음).

## FR-131 콘솔 신고 처리

- `GET /console/queues` 응답에 `reports:[{report_id, target_type, target_id, excerpt(≤80자·이스케이프), reason, detail, reporter_nickname, created_at}]` 추가(pending 만, 최대 100).
- `POST /console/reports/{report_id}/decide` `{action ∈ {hide, dismiss}, note ≤500}` → 200. `hide` = 대상 `STATUS_CD=hidden`(글이면 상세 404, 댓글이면 자리만). `DECIDED_BY_ID`·`DECIDED_DTM` 자동. 같은 대상의 다른 pending 신고는 함께 `actioned`.
- 관문은 SP-AUTH-19 그대로(`require_loopback` + `require_operator`, 둘 다 404).

## FR-132 입력 신뢰 경계·리밋

- 길이·공백-only 거부(strip 후 빈 문자열 422) · 본문 URL(`https?://`) 3개 초과 422 · 제어문자 제거 · 저장은 파라미터 바인딩, 표시는 클라이언트 `textContent`(NFR21).
- 일일 상한 3종은 `config.py`(`daily_post_limit=10`·`daily_comment_limit=50`·`daily_report_limit=20`), 계산은 `INS_DTM >= UTC 자정` 카운트(복지 편집 `_daily_count` 관례).
- nginx: 쓰기 라우트는 기존 `^~ /api/v1/` 블록(Layer A 헤더 게이트 + `loupit_api` 리밋)을 그대로 탄다 — 새 `=` 블록 없음.

## FR-133 정책 문안 동반

- privacy **P10 게시물 정보**: 수집 항목(닉네임·글/댓글 본문·작성 시각·회사 태그·신고 사유), 목적(게시판 운영), 보유(탈퇴 후 **닉네임·본문 존치가 기본**이며 탈퇴 화면에서 "내 글 전부 삭제" 선택 가능), 열람 범위(공개).
- terms **T6 게시물**: 이용자 책임·금지행위(타인 비방·개인정보·광고·저작권 침해)·임시조치(정보통신망법 §44-2: 신고 시 운영자 숨김 가능)·게시물 이용허락(서비스 내 표시·검색 노출)·운영자 삭제권.
- 문안 변경은 **커뮤니티 공개와 같은 PR** 에서 `policy.py` + 재생성(함정 (61)).
