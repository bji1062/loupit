# 핸드오프 — 로그인+재직인증+복지편집(SC14) 문서화 ML-A

> **다음 세션 시작점**: §D 스윕 완료 + **ML-B 기반 ① SP-DB 재명세 완료·검증(✅)**. 다음 = **ML-B 기반 ②부터**(§F 진행표) — ② SP-INFRA(SPEC/11) → ③ Tier-0 5개 test 재명세[§C 정정 4건] → ④ T-13.2.1 백업 확장 → **검토 체크포인트 정지**. M9 TDD(TASK/13 41리프)는 검토·승인 후. **배포는 AdSense 심사 결과까지 홀드**(§E). 이 문서 + 메모리 `loupit-login-feature-docs`가 재개 컨텍스트다.
> **최종 갱신**: 2026-07-22, §D 스윕 완료 — item 1(USECASE.md A6)·item 2(17리프)·item 4(Tier-0 xref, §C 정정 4건 발견)·**item 3=Option C 전면 정합화**(GET 4종→5종+로그 POST ~40곳·로그인 영구제외 잔존 15+건·카운트 드리프트·SC14 쓰기 라우터 언급). 워크플로 2회(검증 `wf_bf90465a`·재조정 `wf_accac492`) + 2차 수동 정밀수정 28건. 라이브 정책 문안 카브아웃 준수. 최종 grep 검증: API표면·로그인잔존·카운트 전부 클린.

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
| 6 | `SPEC/13-참여-로그인.md`(신규, **SP-AUTH 정본**, 15섹션) + `SPEC.md` 얇은인덱스(13문서화·INV-1~9·113 FR) | ✅ 검증완료 | (이 커밋) |
| 7 | `SPEC/09-정책-페이지.md`(약관 T5 신설·T2 정정·**P1 정정** + 개인정보 P7 신설) + SPEC/13 역참조 동기화 | ✅ 검증완료 | (이 커밋) |
| 8 | `TASK/00`(M9·DAG·DG-5·게이트 AU-1~4 #28~31) + `TASK/13`(41리프) + `TASK.md`(총 327리프) + `TASK/09` M9 노트 | ✅ 검증완료 | (이 커밋) |

### 각 파일 개정 시 공통 규칙
인덱스(PRD.md/USECASE.md/FRD.md/SPEC.md/TASK.md)의 **3요소(참조목록·ID마스터표·커버리지)**를 리프와 함께 갱신. RESUME.md 단계표도 필요 시.

### Step 6 완료 결과 (SP-AUTH 정본)
- `docs/SPEC/13-참여-로그인.md` 저술 완료 — **SP-AUTH-1~15**: 모듈구조·config(금지 substring 재명세)·7테이블 컬럼계약(DDL은 SP-DB)·세션(불투명토큰·SHA-256·`require_member`)·무비밀번호 로그인·계정/탈퇴·재직인증(도메인 화이트리스트·HMAC·원문파기)·수동승인+운영자 CLI·복지편집(배지 강제·`base_dtm` 낙관적 동시성·원자 트랜잭션)·편집이력·mailer(Console/SMTP)·CSRF·리밋·상태코드·테스트명세(AU-1~7 Tier-0 + AL/AS/AM/AE/AB/AH/AC/AX/AO)·추적요약.
- `docs/SPEC.md` 얇은인덱스 갱신 완료: §2 참조목록 13행(SP-AUTH 추가), §3 마스터표 SP-AUTH, §5 커버리지, §6 카운트(**113 FR·INV-1~9**)·참여 추적행, "영구제외" 문구 SC14 개정(§1·§6), **INV-1~7→INV-1~9**(Step 3 이월분 3셀 정정).
- **검증**: 적대적 4차원 워크플로(`wf_1f7019d6-20c`) — blocker 0. major 3(정성 `AMT_SOURCE_CD` 분기·SPEC.md INV-1~9 3셀·SP-INFRA 재명세 플래그) 전부 수정, minor 8 중 관련 6 수정·2(GET 4종/badge 드리프트)는 범위밖 확인.

### Step 7 완료 결과 (SPEC/09 정책)
- 약관 **T5 신설**(#t5: 무비밀번호 로그인 가입·탈퇴·편집이력 존치)·**T2 정정**(구 "로그인 없이 제공"→익명 열람 무로그인 + 기여 로그인)·개인정보 **P7 신설**(#p7: 회원 PII 최소·해시 at-rest·탈퇴 파기)·**P1/meta_description 정정**(익명 무수집 ↔ 기여 로그인 구분). REQUIRED_ITEMS·필수항목표·PC-2·SP-POL-1 표·SP-POL-11·커버리지·전역불변식 line16(INV-4 익명 스코프) 동반 갱신.
- **SPEC/13 역참조 동기화**: SP-AUTH-6 'Step 7 대기'→'신설 완료' + 탈퇴 시 재직 인증(`TEMPLOY_VERIFICATION`) 폐기·회사 이메일 HMAC 파기 추가(P7 고지와 정합).
- **검증**: 적대적 3차원 `wf_110dca46-c0f` — blocker 1(_privacy P7 초과 괄호, ast.parse 확정·수정)·major 1(line16 INV-4 절대화→SC14 카브아웃)·minor 3 전부 수정.

### Step 8 완료 결과 (TASK M9) — ML-A 저술 완료
- `TASK/13-로그인참여.md`(신규, **41 리프**): SP-AUTH-1~15 TDD 분해. Tier-0 AU-1~4(#28~31) + AU-5·6·7 + AL·AS·AM·AE·AB·AH·AC·AX·AO. 최우선 선행 **T-13.2.1**(백업 확장), 재직 도메인 **DG-5**.
- `TASK/00`: **M9 마일스톤**·DAG 노드(AUTH 싱크)·**DG-5**·Tier-0 **#28~31**·G1/G3 SP-AUTH·릴리스 순서 M9 노트·#7→AU-1 표면 전이 각주. DG-1~4 상태 `- [v]` 정정.
- `TASK.md`: 참조목록 13행·M9 롤업·총 **327리프**(286+41)·Tier-0 31·미결 DG 1개(DG-5)·범위 불변식 SC14 개정. `TASK/09`에 M9 정책 확장 노트.
- **검증**: 적대적 3차원 `wf_531ed8a7-904` — blocker 0 / major 4(DG 상태·AE 케이스ID·AU-7 누락·TASK/09 정책 잔존)·minor 4 전부 수정.

> **ML-A(문서) 8단계 완료.** 다음은 §D 미결 일관성 스윕 → ML-B(코드). ML-B 착수 시 §C(Tier-0 재명세·SP-DB/SP-INFRA 선행)·TASK/13 리프를 입력으로.

---

## C. ML-B/C(코드) 착수 시 필수 — Tier-0 재명세

문서(SPEC/01 T9·T10, FRD/13 FR-100·101·113)가 계약으로 못박아 둔, **코드 구현 때 반드시 재명세할 현행 테스트**:
- `test_surface.py` **TS-1**: 쓰기 라우트 리스트를 참여 라우트 포함 열거집합으로 확장. **TS-2 어서션 원문 유지**(세션=의존성이라 미들웨어 여전히 CORS 1종).
- `test_config.py`: 금지 substring에서 **`smtp`·`session`·`secret` 제거** → `jwt·oauth·password_reset·social` 유지. 신규 필드 positive test.
- `test_package.py`: 라우터 allowlist에 **`member.py`·`employment.py`·`benefit_edit.py` 추가**. `FORBIDDEN_MODULE_NAMES`에 `auth` 유지(라우터명 `auth` 금지 → `member.py` 사용).
- `test_schema_load.py`: `REMOVED_TABLES`에서 **`TMEMBER` 제거**. 신규 AU-3(TMEMBER PII 컬럼 정확집합)·AU-4(인증 테이블 원문 이메일/코드/토큰 컬럼 부재, `*_HASH_VAL`만).
- `test_database.py`: `write_symbols` 정확 열거를 참여 쓰기 헬퍼 포함으로 재명세. `execute`/`transaction` 등 신규 심볼 허용.
- **최우선 리프(T-13.2.1)**: `infra/deploy/run_tests.sh`의 TCOMPARE_LOG 백업/재주입 장치를 **참여 7테이블로 확장**. 이것 없이 실 DB에 참여 테이블 생성 시 게이트 1회 실행 = 회원 데이터 전멸(공유 스키마 DROP/CREATE).
- **SP-DB(SPEC/02) 선행 재명세(ML-B)** — SPEC/13이 'SP-DB 비준 대기'로 미룬 것(SP-AUTH-14 선행필수): (a) `TCOMPANY_BENEFIT.BADGE_CD`에 3번째 값 **`verified`** 추가(DC-6 게이트 official/est 2값→3값), (b) **`_CNT` 접미 비준**(FRD/13 확정 `ATTEMPT_CNT`; 기존 SP-DB 접미 규약엔 `_CNT` 부재, 카운트는 `_NO`), (c) `REMOVED_TABLES`에서 **`TMEMBER` 해제** + 참여 7테이블 DDL 신규 소유, (d) SP-ARCH-8 인덱스 'DDL 5→7테이블'. 미선행 시 DC-6·SC-6 실패.
- **SP-INFRA(SPEC/11) 선행 재명세(ML-B/인프라)**: 현 SPEC/11은 `SMTP_*`를 정의금지 키로 명시(L497)하고 `loupit_mail` rate-limit 존·`X-Loupit-Client` nginx 게이트가 없다 → SC14용으로 `loupit_mail` 존 신설·`SMTP_*` 금지 해제·헤더 게이트 추가 필요(SPEC/13 SP-AUTH-11·12가 '재명세 대기'로 표기).

### item 4 재확인·정정 (2026-07-22, Tier-0 xref dim4 재실행 `wf_bf90465a`)
§C 6항목 + SP-DB/SP-INFRA 2선행 **전부 유효 간극 확인**(gap_confirmed). 아래 **4건은 §C 원문 정정**(ML-B 착수 시 이 정정본을 입력으로):
1. **REMOVED_TABLES·TABLE_CREATE_ORDER 위치 정정**: `test_schema_load.py`가 아니라 **`server/tests/conftest.py`**(L58·69)에 정의. REMOVED_TABLES에 `TMEMBER` 포함(L70), TABLE_CREATE_ORDER=6종. SC-6(FK→REMOVED 0건) 통과하려면 **TMEMBER 선제거 필수**(참여 FK가 TMEMBER 참조). `TSOCIAL_ACCOUNT`·`TEMAIL_VERIFICATION`은 잔류(무소셜·무비밀번호).
2. **test_config 금지 substring 정정**: 현행 `(jwt,oauth,smtp,session,secret,password_reset)`. 정본 = `{jwt,oauth,password_reset,social}` → **`smtp`·`session`·`secret` 제거 + `social` 신규 추가**(§C 구 'social 유지'는 오류 — 현행에 `social` 부재). + 신규 필드(mailer_mode·smtp_*·session_ttl_days·login_code_ttl_min·code_max_attempts·mail_resend_cooldown_sec·daily_edit_limit·employ_vrf_ttl_days·session_hash_pepper·comp_email_hmac_pepper) positive test.
3. **TS-1 GET 집합도 확장(§C 누락 보완)**: §C는 쓰기 라우트만 언급했으나, AU-1 재명세 시 **GET 집합도 '익명 5종 + 공개 2종(me·edits)'로 확장** 필요(현행 test_surface GET 정확일치 5종이 member/edits 등록 시 깨짐). + SPEC/01 T2 GET 열거(현재 5종)를 SPEC/13 AU-1(me·edits 포함)과 정합.
4. **test_database `execute` 금지 충돌**: 현행 `test_database.py` L102가 `execute`를 hasattr 금지 → `session.py` `db.execute`·`benefit_edit` `db.transaction()`와 정면 충돌. AU-7 재명세 시 `execute`·`transaction`을 write_symbols 허용집합에 포함. + test_package allowlist에 **`trending.py` 보존 필수**(SP-AUTH-1 파일트리는 companies 흡수 표기하나 실코드 별도 존재).

**추가 확정**: run_tests.sh 백업은 TCOMPARE_LOG 단일 → 참여 7테이블 확장(T-13.2.1 **최우선**, `server/tests/test_runner_backup.py` 신규); SP-DB `BADGE_CD='verified'` 3값(DC-6 2→3값·`test_data_contract` BADGE_CODES 확장); `_CNT` 접미 비준; TASK/11 런타임 `GRANT SELECT만`은 SC14 참여 테이블 쓰기 위해 ML-B 갱신 필요; SPEC/04 L28 database.py '쓰기 헬퍼 미제공'은 AU-7 write_symbols 재명세로 정합; 신규 참여 test 파일 11종 전부 부재(RED).

---

## D. 검증 결과(복구·완료) + 미결 일관성 스윕

- **ML-A 1~5 검증(`wf_4a354534-311`)**: 복구 완료 — blocker 0 / major 6 / minor 5 / 4차원 중 Tier-0 교차참조는 인터럽트로 미완(재실행 필요). 잔여 수정거리 = 아래 스윕.
- **Step 6 검증(`wf_1f7019d6-20c`)**: blocker 0 / major 3 전부 수정 / minor 8 중 6 수정(2 = GET 4종·badge 드리프트, 범위밖 확인). §B Step 6 노트 참조.
- **Step 7 검증(`wf_110dca46-c0f`)**: blocker 1·major 1·minor 3 전부 수정.
- **Step 8 검증(`wf_531ed8a7-904`)**: blocker 0·major 4·minor 4 전부 수정.

### 미결 일관성 스윕 — ✅ 완료 (2026-07-22, Option C 전면)
사용자 결정 = **Option C(카운트+로그인 재프레이밍+SC14 쓰기 라우터 전면 정합화)**. 검증 워크플로 `wf_bf90465a` + 재조정 워크플로 `wf_accac492`(52 에이전트) + 2차 수동 정밀수정 28건. 라이브 정책 문안 카브아웃 준수.
1. ✅ **[item 1] `USECASE.md:13`** `액터 정의(A1~A5)`→`A1~A6`(UC-A1~UC-A5 유지) + `USECASE/01:15` '다섯 액터'→'여섯 액터'.
2. ✅ **[item 2] 로그인 영구제외 잔존 17 비타깃 리프**(USECASE/02~08·FRD/02·03·04·06·07·08·09·10·11·12) 재프레이밍 — **적대검증 17/17 PASS**. 프로파일러 전용 영구제외는 보존.
3. ✅ **[item 3] GET 4종 드리프트 + 확대 잔존(Option C 전면)**: `GET 4종`→`GET 5종 + 익명 로그 POST 1종` **~40곳**(SPEC/01·04·06·11·12·SPEC.md·FRD.md·FRD/01·02·11·PRD·PRD/05·09·TASK/00·01·04·USECASE/01); 로그인 영구제외 잔존 **15+건**(SPEC/02·04·06·07·08·10·11·12·PRD/01·05·06·09·FLOW 9·WIREFRAME 6·인덱스) 재프레이밍(소유대역 SP-AUTH/SP-DB/SP-INFRA 포인터); SC14 쓰기 라우터(member/employment/benefit_edit) 아키텍처 언급 SPEC/01·04 추가; 카운트 드리프트(97 FR→113·INV-1~7→1~9·다섯→여섯 액터) 정정. **최종 grep: API표면·로그인잔존·카운트 전부 클린.**
4. ✅ **[item 4] Tier-0 교차참조 dim4 재실행**: 6항목+2선행 전부 유효 확인 + §C 정정 4건 발견(위 §C 반영) → ML-B 재명세 입력.

**카브아웃(SC14 실배포 시 갱신)**: 라이브 정책 문안(FRD/10 T2·P1·147·WIREFRAME/07 정책 콘텐츠·랜딩 '로그인 없이 비교') — 현 배포 서비스(로그인 미배포)를 정확히 기술하므로 존치. `SPEC/03:9` '레거시 로그인 데이터 미이식' = 정상(참여 테이블은 신규·빈).
**ML-B 이관(서술만 정합, 실체는 코드단계)**: SPEC/02 TMEMBER 실제 제거해제+7테이블 DDL, SPEC/11 loupit_mail/nginx conf, TASK/11 런타임 GRANT(SC14 쓰기), SPEC/04 L28 database.py 쓰기헬퍼(AU-7), T7 스모크 비교로그 POST 뉘앙스.

### 흡수된 항목(별도 작업 아님)
- ML-A 1~5 major 중 'SP-AUTH 파일 미작성' → **Step 6 해소(✅)**. '약관 T5 미존재·T2 모순' → **Step 7 해소(✅ T5 신설·T2 정정·P7)**.

---

## E. 배포·게이트 유의

- **AdSense 심사 중**(2026-07-21 제출). ML-A는 `docs/`라 배포 무관 — 안전. 그러나 정책 문안(Step 7)의 라이브 `/privacy` 반영·로그인 코드 프로덕션 배포는 **심사 결과 확인 후**(의사결정 게이트).
- **라이브 도크루트 함정**: `web/`·`web/dist` 저장 = 즉시 프로덕션. ML-A는 `docs/`만 건드려 무관하나 ML-F(프론트)·배포 시 주의.
- **브랜치**: 사용자 지시로 `main` 직접 작업·커밋·푸시.

관련 정본: 블루프린트 DDL·서비스 참조 `/home/ubuntu/job_change`(읽기전용·구설계 OAuth/JWT 포함, 재사용 패턴만) · 메모리 `loupit-login-feature-docs`·`loupit-adsense-status`·`loupit-live-docroot-hazard`. (구 정찰 `tasks/wp1ctagx8.output`은 소실.)

---

## F. ML-B 진행 (2026-07-22~)

**사용자 결정(Option A)**: ML-B 기반 4단계 → 검토 체크포인트 정지. 배포는 AdSense 게이트 홀드. M9 TDD(TASK/13 41리프)는 검토·승인 후.

| 단계 | 내용 | 상태 |
|---|---|---|
| ① SP-DB 재명세 | `SPEC/02` **SP-DB-17**(참여 7테이블 DDL 정본) + cross-ref(`_CNT` 비준·`BADGE_CD='verified'`·SP-DB-11 TMEMBER 해제·delta 12테이블·SC-1/2/4/6·DC-6) | ✅ **완료·적대검증** — DDL 본문 SP-AUTH-3 계약과 완전 정합(컬럼·AU-3/4·FK·UNIQUE·명명·SQL). 교차참조 결함 4건 수정: M1(COMMENT `17.10`→`17.8` 5곳)·M2(DC-6 2→3값)·m3(SC-4 append-only 예외)·m5(TCOMPARE_LOG 카운트 별도). 펜스 균형·7테이블 존재 확인 |
| ② SP-INFRA 재명세 | `SPEC/11` `loupit_mail` rate-limit 존·`SMTP_*` 금지해제·`X-Loupit-Client` nginx 게이트 | ⬜ **다음** |
| ③ Tier-0 test 재명세 | `conftest.py`(REMOVED_TABLES TMEMBER 제거·TABLE_CREATE_ORDER 7종 위상·픽스처)·`test_config`(social+/smtp·session·secret−)·`test_surface`(GET 5+공개 2·write 열거집합)·`test_schema_load`(AU-3/4·참여 컬럼)·`test_database`(execute/transaction 허용)·`test_package`(trending 보존) — §C 정정 4건 반영 | ⬜ |
| ④ T-13.2.1 백업 확장 | `run_tests.sh` 백업/재주입을 참여 7테이블로 확장(안전 선행, `test_runner_backup.py` 신규) | ⬜ |

**① DDL 정본 = `SPEC/02` SP-DB-17**. 생성순서(conftest `TABLE_CREATE_ORDER`): TMEMBER→DOMAIN→SESSION→AUTH_CODE→VERIFICATION→VRF_REQUEST→EDIT_LOG.
**RED 테스트 스테이징 논점(③에서 결정)**: SC14 test 증분을 마커/스킵으로 격리해 라이브 베이스 릴리스 게이트(`release.sh`)를 green 유지(구현 전 RED가 베이스 배포를 막지 않도록).
