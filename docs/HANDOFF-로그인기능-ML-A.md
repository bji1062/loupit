# 핸드오프 — 로그인+재직인증+복지편집(SC14) 문서화 ML-A

> **다음 세션 시작점**: 아래 §진행현황의 **Step 6(SPEC/13 SP-AUTH)** 부터. 이 문서 + 메모리 `loupit-login-feature-docs` + 정찰 원본(`tasks/wp1ctagx8.output`)이 재개 컨텍스트다.
> **최종 갱신**: 2026-07-21, ML-A 1~5 완료 시점.

---

## A. 개요

loupit(라이브, jobcho.wiki)에 **로그인 + 재직 인증 + 복지 등록/수정** 기능을 추가한다(2026-07-21 사용자 결정). doc-driven 저장소이므로 **md 문서(ML-A)부터** 개정한 뒤 코드(ML-B~)로 간다. 이 작업은 "로그인 없음 = 영구 불변식"의 **공식 개정**이다.

### 핵심 프레이밍 — 익명 우선(anonymous-first)
- **열람·비교는 로그인 없이 그대로** 유지(익명 GET·무쿠키·무세션).
- 로그인 + 재직 인증은 **복지 등록·수정 기여에만** 요구.
- 편집 이력 열람(UC-77)은 **로그인 없이 공개**(나무위키식).

### 확정 설계 결정
- **로그인 = 무비밀번호 이메일 6자리 코드**. 비밀번호·OAuth·소셜 로그인은 **SC10으로 영구제외 유지**(사용자 재확인 2026-07-21).
- **재직 인증 = 회사 도메인 이메일 코드**(원문 즉시 파기·HMAC 해시만). 도메인 미등록 회사는 **운영자 CLI 수동 승인** 폴백.
- **세션 = FastAPI 라우트 의존성(Depends), 미들웨어 아님** → Tier-0 TS-2(`app.user_middleware==['CORSMiddleware']`) 보존이 핵심.
- **신규 의존성 0**: 토큰 `secrets`, 해시 `hmac`/`hashlib`, 메일 stdlib `smtplib`(+`asyncio.to_thread`). JWT/OAuth/passlib 계속 금지.
- **PII 최소**: 서버 저장 = 로그인 이메일 + 닉네임뿐. 회사 이메일·코드·토큰 원문 무저장.
- 편집 이력 = 나무위키식 공개(누가·언제·before→after). 탈퇴 시 이메일 파기·닉네임/이력 존치(약관 T5 고지).

### 확정 번호 (재사용 금지)
| 항목 | 값 |
|---|---|
| 범위 | **SC14**(In-scope 증분) |
| NFR | **NFR30**(해시 at-rest)·**NFR31**(발송·시도 리밋) |
| 불변식 | **INV-8**(PII 최소)·**INV-9**(세션 계약) + 아키텍처 테스트 **T9·T10** |
| 유스케이스 | 액터 **A6**(인증 기여자) · **UC-70~77** |
| FR | **FR-100~115**(FR-10x·11x 대역 — 십단위 0x~9x 소진됨) |
| SPEC 대역 | **SP-AUTH**(신규 파일 SPEC/13) |
| 정책 | 개인정보 **P7**·약관 **T5** |
| TASK | 마일스톤 **M9** · Tier-0 게이트 **AU-1~4**(#28~31) |
| 파일 서수 | USECASE/**09**, FRD/**13**(요청 12는 점유), SPEC/**13**, TASK/**13** |

### 신규 7테이블 (SP-AUTH 대역, DDL은 ML-B에서 SPEC/02)
`TMEMBER`(무비밀번호·PII최소) · `TSESSION`(토큰 SHA-256 해시) · `TAUTH_CODE`(6자리코드 해시) · `TCOMPANY_EMAIL_DOMAIN` · `TEMPLOY_VERIFICATION`(회사이메일 HMAC) · `TEMPLOY_VRF_REQUEST`(수동승인 큐) · `TBENEFIT_EDIT_LOG`(append-only). 익명 참조 5종 + TCOMPARE_LOG 유지.

---

## B. 진행현황 (ML-A 8단계)

| # | 파일 | 상태 | 커밋 |
|---|---|---|---|
| 1 | `PRD/04-범위.md` + `PRD.md` | ✅ | `a0f340b`(푸시됨) |
| 2 | `PRD/07-비기능-요구사항.md` + `PRD.md` | ✅ | `a0f340b` |
| 3 | `SPEC/01-개요와-아키텍처.md` | ✅ | `a0f340b` |
| 4 | `USECASE/09-참여.md`(신규) + `USECASE.md` + `USECASE/01` | ✅ | `c3a5e76`(푸시됨) |
| 5 | `FRD/13-참여-API.md`(신규) + `FRD.md` + `FRD/01` | ✅ | (이 커밋) |
| 6 | `SPEC/13-참여-로그인.md`(신규, **SP-AUTH 정본**) + `SPEC.md` 얇은인덱스 | ⬜ **다음** | — |
| 7 | `SPEC/09-정책-페이지.md`(개인정보 P7·약관 T5) | ⬜ | — |
| 8 | `TASK/00-빌드순서-마일스톤.md`(M9·게이트 AU-1~4) + `TASK/13-로그인참여.md`(신규 리프) + `TASK.md` | ⬜ | — |

### 각 파일 개정 시 공통 규칙
인덱스(PRD.md/USECASE.md/FRD.md/SPEC.md/TASK.md)의 **3요소(참조목록·ID마스터표·커버리지)**를 리프와 함께 갱신. RESUME.md 단계표도 필요 시.

### Step 6 착수 시 할 일 (구체)
- 신규 `docs/SPEC/13-참여-로그인.md` = **SP-AUTH 정본**: 세션(불투명 토큰·SHA-256·쿠키 속성·TTL·Depends), 무비밀번호 코드 로그인 흐름, 재직 인증(도메인 매칭·HMAC·원문 파기·수동 폴백), 복지 편집(배지 시맨틱 `verified`·낙관적 동시성 `base_dtm`·원자 트랜잭션), CSRF(X-Loupit-Client), 편집 이력, 발송/시도 리밋, 운영자 CLI, mailer(Console/SMTP), config 필드(금지 substring 재명세), 신규 7테이블 참조.
- **이월**: `docs/SPEC.md` 얇은 인덱스(참조목록 13행 + SP-AUTH + "영구제외" 문구 개정 + 마스터표/커버리지)를 Step 6에서 SPEC/13과 함께 갱신. (Step 3에서 SPEC/01의 SP-ARCH-8 표만 SP-AUTH 등재했고, 얇은 인덱스 SPEC.md는 아직 미개정.)

---

## C. ML-B/C(코드) 착수 시 필수 — Tier-0 재명세

문서(SPEC/01 T9·T10, FRD/13 FR-100·101·113)가 계약으로 못박아 둔, **코드 구현 때 반드시 재명세할 현행 테스트**:
- `test_surface.py` **TS-1**: 쓰기 라우트 리스트를 참여 라우트 포함 열거집합으로 확장. **TS-2 어서션 원문 유지**(세션=의존성이라 미들웨어 여전히 CORS 1종).
- `test_config.py`: 금지 substring에서 **`smtp`·`session`·`secret` 제거** → `jwt·oauth·password_reset·social` 유지. 신규 필드 positive test.
- `test_package.py`: 라우터 allowlist에 **`member.py`·`employment.py`·`benefit_edit.py` 추가**. `FORBIDDEN_MODULE_NAMES`에 `auth` 유지(라우터명 `auth` 금지 → `member.py` 사용).
- `test_schema_load.py`: `REMOVED_TABLES`에서 **`TMEMBER` 제거**. 신규 AU-3(TMEMBER PII 컬럼 정확집합)·AU-4(인증 테이블 원문 이메일/코드/토큰 컬럼 부재, `*_HASH_VAL`만).
- `test_database.py`: `write_symbols` 정확 열거를 참여 쓰기 헬퍼 포함으로 재명세. `execute`/`transaction` 등 신규 심볼 허용.
- **최우선 리프(T-13.2.1)**: `infra/deploy/run_tests.sh`의 TCOMPARE_LOG 백업/재주입 장치를 **참여 7테이블로 확장**. 이것 없이 실 DB에 참여 테이블 생성 시 게이트 1회 실행 = 회원 데이터 전멸(공유 스키마 DROP/CREATE).

---

## D. 검증 워크플로 (미완 — 다음 세션에서 확인)

ML-A 1~5 문서에 대한 **적대적 일관성 검증 워크플로**를 Step 5 말미에 실행했으나 세션 종료로 결과 미확인.
- **Run ID**: `wf_4a354534-311` (Task `w3so3jhca`)
- **스크립트**: `<세션디렉토리>/workflows/scripts/loupit-mla-consistency-verify-wf_4a354534-311.js`
- **차원**: 카운트·번호 / 커버리지 완전성 / 익명우선 프레이밍 모순 / Tier-0 교차참조.
- **다음 세션**: `journal.jsonl`(transcript dir)에서 각 에이전트 결과를 읽거나, 새 검증을 다시 실행. blocker/major findings가 있으면 커밋 전 수정. (문서는 배포 무관이라 미검증 커밋의 프로덕션 리스크는 0 — 검증은 안전망.)

---

## E. 배포·게이트 유의

- **AdSense 심사 중**(2026-07-21 제출). ML-A는 `docs/`라 배포 무관 — 안전. 그러나 정책 문안(Step 7)의 라이브 `/privacy` 반영·로그인 코드 프로덕션 배포는 **심사 결과 확인 후**(의사결정 게이트).
- **라이브 도크루트 함정**: `web/`·`web/dist` 저장 = 즉시 프로덕션. ML-A는 `docs/`만 건드려 무관하나 ML-F(프론트)·배포 시 주의.
- **브랜치**: 사용자 지시로 `main` 직접 작업·커밋·푸시.

관련 정본: 정찰 `tasks/wp1ctagx8.output` · 메모리 `loupit-login-feature-docs`·`loupit-adsense-status`·`loupit-live-docroot-hazard`.
