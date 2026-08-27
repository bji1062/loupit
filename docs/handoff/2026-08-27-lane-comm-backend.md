# 세션 기록 — 2026-08-27 · 레인 커뮤니티 백엔드(스키마 + 서버)

브랜치 `lane/comm-backend`(worktree `/home/ubuntu/loupit-wt/comm`). `docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md`
§5 **PR-3(스키마) + PR-4(서버)**. 정본: `FRD/14-커뮤니티-API.md`(전송) · `SPEC/14-커뮤니티.md`(구현) ·
`TASK/14` T-14.1.1~14.5.3. 프론트·정책 문안·nginx·상단 탭은 **하지 않았다**(다른 레인).
커밋 2개: ① `af42ad1` 스키마+conftest+계약 테스트 · ② 서버(라우터·서비스·모델·콘솔·digest·표면 게이트).

## 한 일

| # | 조치 | 어디 |
|---|---|---|
| 1 | 4테이블 DDL — `TPOST`(VIEW_CNT 없음·SET NULL·인덱스 4종) · `TPOST_COMMENT`(CASCADE) · `TPOST_REACTION`(UNIQUE) · `TPOST_REPORT`(UNIQUE, TARGET_ID FK 아님) | `db/schema.sql` 참여 절 끝 · 사본 `db/migrations/20260827_add_community.sql` · `docs/SPEC/02` **SP-DB-18** 절 |
| 2 | 격리 편입 — `PARTICIPATION_CREATE_ORDER` 끝에 부모→자식 4개 | `server/tests/conftest.py` |
| 3 | 설정 4키(`daily_post_limit=10`·`daily_comment_limit=50`·`daily_report_limit=20`·`post_list_max_limit=50`) | `server/config.py` |
| 4 | `optional_member` — 쿠키 있으면 회원, 없거나 무효면 None, **401 없음**. `require_member` 와 별개 심볼 | `server/deps.py` |
| 5 | 입력 신뢰 경계 모델(strip·제어문자·URL 3개·값집합·comp_id≥1) + 응답 모델 | `server/models/post.py` |
| 6 | 서비스 — 목록(닉네임 조인·재직 배지·회사 태그 slug·키셋 LIMIT+1)·상세·댓글·글/댓글/좋아요 쓰기(카운터 트랜잭션·`FOR UPDATE`)·일일 카운트 | `server/services/post.py` |
| 7 | 신고 서비스 — 접수(대상 활성 확인·UNIQUE→duplicate)·콘솔 큐(발췌 80자)·`decide`(hide=대상 hidden+동일 대상 일괄 actioned / dismiss) | `server/services/report.py` |
| 8 | 라우터 — 공개 GET 3 + 세션 쓰기 6 (`require_csrf`→`require_member`) · `POST /reports` 202 | `server/routers/post.py`·`report.py`(신설) |
| 9 | 콘솔 — `queues.reports` + `POST /console/reports/{id}/decide`(`ReportDecisionIn`, 결정자 필드 없음) + **콘솔 화면에 신고 섹션**(노드 조립·링크 없음) | `server/routers/console.py` |
| 10 | M9 블록 안 `include_router` 2줄 | `server/main.py` |
| 11 | `ops digest` 4번째 큐 "게시물 신고 N건" + `list-reports` CLI(조회만 — 처리는 콘솔) | `server/ops.py` |
| 12 | 표면 게이트 개정 — TS-1 정확 집합(+GET 3·쓰기 8·콘솔 1) · allowlist(`post.py`·`report.py`) · M9 OFF 이중 가드(`/posts`·`/reports`) · CO-10 · AO-3 DELETE 집합 · digest 스텁 | `test_surface`·`test_package`·`test_m9_gate`·`test_console_gate`·`test_ops`·`test_ops_digest` |
| 13 | 신규 테스트 67 — CM-2 스키마 13 · 모델 422 표 · **실 DB+httpx 매트릭스** · deps/ops/config | `test_community_schema.py`·`test_community_models.py`·`test_community_api.py`·`test_community_deps_ops.py` |

## 왜 이렇게

- **실 DB 로 잰다.** 목록 SQL 은 조인 + 상관 서브쿼리이고 좋아요·댓글은 카운터를 같은 트랜잭션에서
  움직인다. SQL 텍스트 패턴 스텁으로는 그 구간이 "없는 것과 같다"(HANDOFF-2026-08-21 §4). 그래서
  `test_community_api` 는 `schema_db` 위에 aiomysql 풀을 열고 세션 쿠키·CSRF 헤더까지 실제 경로로 두드린다
  (`test_console_flow_db` 방식). 자기 행만 만들고 치운다 — 시드 회사는 건드리지 않는다.
- **재직 배지는 LEFT JOIN 이 아니라 상관 서브쿼리 LIMIT 1.** SPEC 은 "LEFT JOIN" 이라 적었지만 한 회원이
  여러 회사를 인증할 수 있어(그룹 도메인) 조인이면 글이 목록에 곱해진다. 글의 회사 태그와 같은 회사를
  우선, 없으면 최신 인증. 의미는 같고 행 수만 보존한다.
- **좋아요 토글은 글 행 `FOR UPDATE`.** "있는가" 판정과 ±1 이 한 잠금 안에 있어야 연타에 카운터가 안
  어긋난다. UNIQUE 는 그 뒤의 보루. CM-6 이 실 DB 에서 `LIKE_CNT == COUNT(*)` 를 잰다.
- **slug 는 서버에 복제.** 생성기를 import 하면 런타임 의존 방향이 뒤집힌다. `services/post.slug_of` 가
  `generator.slug.slug_of` 와 같은 규칙이고 CM-7.5 가 둘을 맞대어 드리프트를 막는다. 차이 하나 — 빈 slug 에
  예외를 던지지 않는다(태그 하나 때문에 목록 전체가 500 이 되면 안 된다). 응답 필드명은 FRD 그대로 `comp.slug`.
- **콘솔 화면에 신고 섹션을 넣었다.** 큐·decide 라우트만 있고 버튼이 없으면 운영자는 curl 로만 처리할 수
  있다. `_PAGE` 는 `console.py` 안(서버 파일)이고 규칙(innerHTML 금지·자동 링크 금지)을 그대로 따랐다 —
  CO-13 이 검사한다.
- **`list-reports` CLI 를 추가한 이유**: digest 본문이 `python3 -m server.ops <cmd>` 를 안내하는데 없는 명령을
  안내하면 막다른 길이다. 조회만이고 결정 명령은 두지 않았다(`--by` 자율신고 감사를 늘리지 않는다).

## FRD 와 다른 점 (프론트 레인이 알아야 할 것)

| 항목 | FRD/SPEC | 구현 | 근거 |
|---|---|---|---|
| 댓글 목록 응답 | `{items:[…]}` 만 명시 | `{items, next_after}` | 목록의 `next_before` 와 대칭. 커서가 `after` 라 이름도 `next_after` |
| 콘솔 `excerpt` | "≤80자·이스케이프" | **80자 절단만, 이스케이프 없음** | 서버는 HTML 을 만들지 않는다(CF-8 규약). 콘솔은 `textContent` 로 그린다 |
| `GET /posts` 422 | — | `HTTPException(422)` → `{detail: "문장"}` | 쿼리 파라미터 검증은 모델이 아니라 라우터 (본문 422 는 `[{type,loc,msg}]` 그대로) |
| `PUT /posts/{id}` 본문 | `category` 불수용 | `{title, body, comp_id}` — `category` 는 **무시**(200) | pydantic `extra=ignore` 기본. 회사 태그는 수정 가능 |
| `optional_member` | "실패해도 None" | 쿠키 없음·무효 세션 → None. **DB 예외는 삼키지 않는다** | 장애를 '익명'으로 위장하면 상세도 곧 실패한다 — 정직하게 500 |
| 신고 대상 | 부재 404 | 부재·`deleted`·`hidden` 전부 404 | 비활성 대상은 신고할 것이 없다 |
| 콘솔 decide 부재 ID | — | 409 `not_pending` | 기존 콘솔 라우트(승인·거부)와 같은 계약 |
| 댓글 `limit` | 미명시 | 기본 50·최대 200 | 편집 이력 라우트와 같은 값 |
| 일일 상한 | `INS_DTM >= UTC_DATE()` | 그대로. **삭제한 것도 센다** | MySQL 세션 tz=UTC 실측 |

## 검증

- 백엔드 **560 → 634 + 1 skip**(신규 커뮤니티 4파일 67 + 기존 테이블 파라미터화 확장 8, 회귀 0) · 생성기 **242 무변경**.
- RED 확인: CM-2.1 이 `schema.sql 에 없는 커뮤니티 테이블` 로 실패 → DDL 후 GREEN. 서버 테스트는
  라우터·서비스가 없는 상태에서 ImportError/KeyError 로 RED → 구현 후 113/114(CM-7.4 의 라우트 키 실수 1건은
  테스트 버그, 수정).
- 실 DB 스모크: `loupit_test` 에 마이그레이션 2회 적용(CM-2.12) · `python3 -m server.ops list-reports` ·
  `digest`(4번째 줄 "게시물 신고 0건") 실행 확인.
- TS-1 최종 집합은 아래.

### TS-1 최종 — 쓰기(write_routes)

```
("/api/v1/comparisons/log", "POST")                          # 익명
("/api/v1/members/login-code", "POST")  ("/api/v1/members/login", "POST")  ("/api/v1/members/logout", "POST")
("/api/v1/members/me", "PUT")  ("/api/v1/members/me", "DELETE")
("/api/v1/employment/verify-code", "POST")  ("/api/v1/employment/verify", "POST")
("/api/v1/employment/requests", "POST")  ("/api/v1/employment/company-requests", "POST")
("/api/v1/companies/{comp_id}/benefits", "POST")  ("/api/v1/companies/{comp_id}/benefits/{benefit_id}", "PUT")
("/api/v1/webhooks/resend", "POST")
("/api/v1/console/verifications/{req_id}/approve", "POST")  ("/api/v1/console/verifications/{req_id}/reject", "POST")
("/api/v1/console/company-requests/{req_id}/decide", "POST")  ("/api/v1/console/suppressions/{target_hash}/release", "POST")
# ── SC15 신규 9 ──
("/api/v1/posts", "POST")  ("/api/v1/posts/{post_id}", "PUT")  ("/api/v1/posts/{post_id}", "DELETE")
("/api/v1/posts/{post_id}/comments", "POST")  ("/api/v1/posts/{post_id}/comments/{comment_id}", "DELETE")
("/api/v1/posts/{post_id}/like", "PUT")  ("/api/v1/reports", "POST")
("/api/v1/console/reports/{report_id}/decide", "POST")
```

### TS-1 최종 — GET

```
/api/v1/health  /api/v1/reference/all  /api/v1/companies/search  /api/v1/companies/{comp_id}
/api/v1/comparisons/trending  /api/v1/members/me  /api/v1/companies/{comp_id}/edits
/api/v1/companies/{comp_id}/benefits  /api/v1/console  /api/v1/console/queues
# ── SC15 신규 3 ──
/api/v1/posts  /api/v1/posts/{post_id}  /api/v1/posts/{post_id}/comments
```

## 허용 목록 밖에서 손댄 파일 (필요 결과)

- `server/tests/test_console_gate.py` CO-10 — 콘솔 라우트 **정확 집합**이라 decide 1줄 추가 없이는 깨진다.
- `server/tests/test_ops.py` AO-3 — DELETE 라우트 정확 집합. 커뮤니티 소프트 삭제 2종 선언, 복지 DELETE 부재 어서션은 유지.
- `server/tests/test_ops_digest.py` — `_FakeCursor` 가 모르는 SQL 에 raise 하므로 `TPOST_REPORT` 분기 + 픽스처 `reports` 키.
- `server/routers/__init__.py` — docstring 한 문단(모듈 목록 기록).

## 남긴 것

- **서빙 DB 마이그레이션은 안 했다**(서버 접촉 금지). 공개 PR 에서 `db/migrations/20260827_add_community.sql` 을
  prod·beta 에 적용해야 라우트가 500 을 내지 않는다 — M9 ON 인 prod 는 API 재시작 즉시 라우트가 살아나므로
  **마이그레이션이 재시작보다 먼저**여야 한다(순서가 뒤집히면 `/posts` 가 500).
- `TASK/14` 마커는 다른 worktree 에 있어 손대지 않았다 — T-14.1.1~14.5.3 전부 구현+테스트 green 이므로 `[v]` 후보.
- `docs/SPEC/02` SP-DB-15 delta 표(유지 5 + 참여 7 = 12)는 갱신하지 않았다 — 레거시 대비 델타라 SP-DB-18 절이 자체 집계를 갖는다.
- 정렬 `likes`/`comments` 의 커서는 `POST_ID` 만이라 동률 경계에서 항목이 중복·누락될 수 있다(FRD-121 이 수용한 단순화). 글이 수백 건이 되기 전에는 체감 없음.
- 프론트 레인이 쓸 계약 요약: 모든 응답 `no-store` · 시각은 naive ISO(UTC) 문자열 · 닉네임 NULL 은 `"탈퇴한 회원"` · 댓글 비활성은 `body:null, deleted:true` · 쿼리 422 는 `{detail:"문장"}`.
- 함정 후보: `docs/PITFALLS/_incoming/partial-test-order-hides-cross-file-seed-coupling.md`.
