# 핸드오프 — 로그인+재직인증+복지편집(SC14) 문서화 ML-A

> **⚠ 최신 상태는 §H(2026-07-27) 를 먼저 읽을 것.** AdSense 는 더 이상 M9 게이트가 아니다 —
> 실제 게이트는 (1) 라이브 정책 문안 동시 배포, (2) SMTP 계정 조달, (3) 운영 pepper 2종이다.
> `M9_ENABLED` 마스터 스위치가 도입되어 참여 라우터·세션 퍼지·정책 문안을 한 값으로 묶는다.

> **다음 세션 시작점(구, §H 로 갱신됨)**: **ML-B ①②③④ 전부 완료·검증(✅) — 검토 체크포인트 도달**. ① SP-DB(SPEC/02), ② SP-INFRA(SPEC/11 §3.4·§6.2a·§7, 적대검증 2회), ④ T-13.2.1(`run_tests.sh` 참여 백업 + `test_runner_backup.py`), ③ Tier-0 6파일 재명세(`@pytest.mark.sc14` RED 격리, 적대검증). 각 단계 커밋됨. **다음 = 사용자 검토 후 M9 TDD**(TASK/13 41리프) — M9 활성화 체크리스트: (a) `db/schema.sql`에 참여 7테이블 DDL + `load.py --fresh`가 재생성(#14 가드 확장), (b) `conftest.TABLE_CREATE_ORDER`에 `PARTICIPATION_CREATE_ORDER` 병합, (c) sc14 RED 6스펙을 그린으로(마커 해제 또는 `-m sc14`), (d) 베이스 test(TS-1·test_package allowlist·test_database write_symbols) SC14 갱신, (e) SPEC/11 §6.2a 런타임 GRANT + §3.4 nginx conf 실파일 반영. **배포는 AdSense 심사 결과까지 홀드**(§E). 이 문서 + 메모리 `loupit-login-feature-docs`가 재개 컨텍스트다.
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
| ② SP-INFRA 재명세 | `SPEC/11` **§3.4**(`loupit_mail` 3r/m 존·메일 `=` 블록·`X-Loupit-Client` 게이트)·**§6.2a**(런타임 참여 쓰기 GRANT)·**§7**(SMTP·pepper 키 해제)·**§3.2 드리프트 주석**·SM-16/17 | ✅ **완료·적대검증 2회** — 1차 7 findings(**blocker: 런타임 쓰기 GRANT 누락** — SELECT-only로는 SC14 첫 쓰기 command denied) + 2차 5 findings(**major: 스키마 `loupit`→`LOUPIT` 대문자**(`lower_case_table_names=0`, 감사 #6·#13)·TCOMPARE_LOG 기저 그랜트 누락·§E 레이블·추적행 6/11) 전부 수정 + 자체 GRANT 버그 1건(TEMPLOY_VERIFICATION 소프트폐기=UPDATE). **핵심 발견**: 실 `loupit.conf`가 SPEC보다 앞섬 — Layer A(`X-Loupit-Client` 전역 게이트)·Layer B(봇)·limits 이미 라이브라 SC14 쓰기 CSRF는 상속만, 메일 존만 신규 |
| ③ Tier-0 test 재명세 | 6 test 파일 + conftest + run_tests.sh — §C 정정 4건 반영 | ✅ **완료·적대검증**(사용자 결정: **`@pytest.mark.sc14` 격리**) — **그린세이프 인플레이스**(test_config 금지 substring 축소 `smtp·session·secret` 허용·`social` 추가 / conftest REMOVED_TABLES에서 TMEMBER 해제 / docstring 노트)는 베이스 게이트 그린 유지. **SC14 RED 6스펙**(AU-1 TS-1 참여표면·AU-3/4 스키마 PII·해시·AU-5 config·AU-6 라우터 allowlist·AU-7 db execute/transaction)은 마커로 격리. conftest.pytest_configure 마커 등록·`run_tests.sh` 베이스 `-m "not sc14"`·`test_runner_backup.py` 게이트제외 가드. `PARTICIPATION_CREATE_ORDER`는 **inert 상수**(M9가 TABLE_CREATE_ORDER에 병합). 검증(게이트 미실행): collect-only **6 deselect / 208 base 무오류**·py_compile·test_config 격리. 적대검증 major 2 수정(AU-3 STATUS_CD 비-PII 누락·AU-4 AUTH_CODE_ID PK 오탐) |
| ④ T-13.2.1 백업 확장 | `run_tests.sh` 백업/재주입을 참여 7테이블로 확장(안전 선행, `test_runner_backup.py` 신규) | ✅ **완료·적대검증**(사용자 결정: **④ 먼저 → ③**) — `backup_participation`/`reinject_participation`를 프로벤 TCOMPARE_LOG 경로와 **병렬**로 추가. **존재검사(information_schema) 기반**이라 참여 테이블 부재 시 완전 no-op(현 그린 게이트 무영향), M9 이후 자동 활성. FK-ON fail-safe(로스터 드리프트 시 전량 거부·덤프 보존)·백업은 트랩·pytest 전·재주입은 재시드 후. `test_runner_backup.py` 구조 가드 8검사(DB 무접촉, 베이스 게이트 상시). `bash -n`·standalone 검증(**라이브 게이트 미실행** — 뮤테이션 금지). 적대검증 2에이전트: blocker/major 0, minor 3(temp 누수·mysql PATH 가드) 수정. ⚠ **M9 의존(미완결)**: 실보존 작동엔 (a) `db/schema.sql`에 7테이블 DDL, (b) `load.py --fresh`가 그 DDL 재생성(현 참조 5테이블만)·#14 가드 확장 필요 — 그 전엔 안전 no-op |

**① DDL 정본 = `SPEC/02` SP-DB-17**. 생성순서(conftest `TABLE_CREATE_ORDER`): TMEMBER→DOMAIN→SESSION→AUTH_CODE→VERIFICATION→VRF_REQUEST→EDIT_LOG.
**RED 테스트 스테이징 논점(③에서 결정)**: SC14 test 증분을 마커/스킵으로 격리해 라이브 베이스 릴리스 게이트(`release.sh`)를 green 유지(구현 전 RED가 베이스 배포를 막지 않도록).

---

## G. 2026-07-25 세션 종료 — 내일 재개 지점

### 오늘 한 일 (전부 GREEN·커밋됨)

| # | 항목 | 결과 |
|---|---|---|
| 1 | **인증 e2e 라이브 확인** (beta·격리 DB `loupit_beta`) | 16단계 PASS — `login-code 204 → 코드(journalctl) → login 200(쿠키 HttpOnly·Secure·Lax·Path=/api/v1) → me 200 / 무쿠키 401 → 재직 verify-code 204 → verify 201(삼성 comp40) → 편집용 GET(no-store·행별 benefit_id+base_dtm) → 등록 201 → PUT 200 → 구 base_dtm 409(현재행 동봉) → 최신 PUT 200(정성 전환 amt_source=none) → 익명 /edits diff → IDOR 403 → CSRF 403 → 정성+금액 422` |
| 2 | **프론트 테스트 보강** | `login.js`·`mypage.js`·`verify.js` 를 `edit.js` 구조(순수 export + `init*Page()` 가드)로 리팩터 → 순수 유닛 3파일 + **실 HTML 을 jsdom 에 올려 배선 검증하는 `auth-dom.test.js`(4화면 30건)**. 프론트 전체 **566 green** |
| 3 | **`/edits` 페이지네이션**(사용자 결정 = 커서 노출) | 응답에 `edit_id`(=EDIT_LOG_ID) 동봉 + 프론트 '더 보기'가 `before=<마지막 id>` 로 이어받기. `schema.sql` 에 `idx_editlog_comp_cursor(COMP_ID, EDIT_LOG_ID)` 추가. FRD FR-110·SP-AUTH-10·TASK T-13.11.1 동반 갱신 |
| 4 | **UX 폴리시**(409 뒤 재시도 → 오해 401) | 401·409 를 `getMe()` 프로브로 규명(서버 메시지 문자열 매칭 안 함). 프로브 3값 — `alive`/`dead`(명시적 401)/**`unknown`**(타임아웃·5xx·네트워크, **세션 만료로 단정 금지**). 409 는 "이미 인증" vs "이 회사 이메일이 이미 사용됨"(주체 단정 안 함). 소비된 코드는 비우고 코드 단계를 닫아 재시도 경로 자체를 제거 |
| 5 | **release.sh M9 활성화 가드**(적대리뷰 major) | 릴리스 1회로 AdSense 게이트 전 M9 가 조용히 활성화되던 경로 차단 — 서빙 스키마에 참여 테이블이 7/7 이 아니면 `M9_ACTIVATE=1` 없이 중단(테스트 게이트 [1] **앞**). `server/tests/test_release_m9_gate.py` 4건 + mysql 셰임 4분기 동작 검증(DB 무접촉) |
| 6 | **베타 테스트 데이터 정리** | 참여 6테이블 0행 + 사용자 등록 복지 2건 삭제 → 복지 시드 1317 복귀. 시드 보존(회사 95·도메인 31), AUTO_INCREMENT 1 리셋, beta API 재시작(참조 캐시). 스냅샷 = `docs/beta-testdata-backup-20260725.sql`(해시·이메일 마스킹본) |

**적대적 리뷰** `wf_5a510a37`(25에이전트·5렌즈): 제기 20 → **확증 14**(blocker 1·major 6·minor 7) **전부 수정**, 반증 6 기각. 수정이 진짜 게이트인지 **뮤테이션으로 검증**(SQL 별칭 제거·파라미터 스왑·프로브 단정·버튼 잠금 해제 뮤턴트 모두 검출).

**커밋**: `main` **6879454**(백엔드·문서·schema·release 가드·.gitignore) · `m9-frontend` **dc1b285**(프론트). origin 푸시 완료.

### 지금 상태 스냅샷

- **테스트**: 백엔드 `DB_NAME=loupit_test python3 -m pytest server/tests -q -m "not sc14"` → **327 passed** / `-m sc14` → 3 passed. 프론트 `cd /home/ubuntu/loupit-fe && node --test 'web/**/*.test.js'` → **566 passed**.
  - ⚠️ 프론트 테스트에 jsdom 이 필요한데 worktree 엔 node_modules 가 없다 → **심링크**로 해결: `ln -s /home/ubuntu/loupit/node_modules /home/ubuntu/loupit-fe/node_modules` (`.gitignore` 앵커 패턴으로 커밋 차단됨).
- **서비스**: prod `loupit-api`(:8000) **미재시작**(내 백엔드 변경 미로드·서빙 스키마에 참여 테이블 없어 inert) · beta `loupit-beta-api`(:8001) 재시작됨. 베타 docroot 는 여전히 worktree(`/home/ubuntu/loupit-fe/web`).
- **베타 DB**: 시드 상태(회사 95·복지 1317·도메인 31, 참여 테이블 전부 0행). 회사 이메일 HMAC 이 지워져 `@samsung.com` 등 **이전 주소 재사용 가능**.

### 내일 시작점 (우선순위 순)

1. **`m9-frontend` → `main` 병합 시점 결정**. 병합하면 프론트 5화면이 **프로덕션 docroot 에 들어간다**(`web/` 직서빙) — 즉 `/login`·`/mypage`·`/verify`·`/edit`·`/edits` 가 jobcho.wiki 에 노출된다. 백엔드 라우트는 서빙 스키마에 참여 테이블이 없어 500/404 이므로, **병합 = 사실상 M9 프론트 공개**다. AdSense 게이트와 함께 판단할 것. 보류하면 worktree 분리 유지(메모리 `loupit-deploy-host` "M9 프론트 worktree 분리" 절의 되돌리기 절차 참조).
2. **M9 활성화**(AdSense 승인 후): 체크리스트 = (a) `db/schema.sql` 7테이블 적용, (b) `conftest.TABLE_CREATE_ORDER` 에 `PARTICIPATION_CREATE_ORDER` 병합, (c) sc14 마커 RED→그린 편입, (d) 베이스 test(TS-1·allowlist·write_symbols) 갱신, (e) `SPEC/11 §6.2a` GRANT·`§3.4` nginx 실파일 반영, (f) **운영 pepper 2종 주입**(`login_code_hmac_pepper`·`comp_email_hmac_pepper`) + `mailer_mode=smtp`(현재 Console 이면 코드가 로그로 나간다). 실행은 `M9_ACTIVATE=1 RELEASE_CONFIRM=1 bash infra/deploy/release.sh`.
3. **남은 nit**(리뷰에서 잘렸거나 낮은 우선순위): ① 재직 429 후 재발송 안내 문구 다듬기(서버가 무발송인 구간을 클라가 60초 막지만, 상한 초과 직후 문구가 여전히 '새 코드를 받아주세요') ② `edit.js` 의 401 처리도 verify.js 처럼 프로브로 구분할지 ③ 운영자 삭제 이력이 `(탈퇴)` 로 표시되는 문구(리뷰에서 '설계 선택'으로 기각).
4. **실 브라우저 시각 확인 미실시** — 이 호스트에 헤드리스 브라우저가 없다. jsdom 으로 배선·id 정합은 덮었지만 CSS·모바일 레이아웃은 미확인. 필요하면 사용자 브라우저로 `https://beta.loupit.co/login` 부터 훑을 것.

### 재개용 실전 메모

- 로그인/재직 코드는 ConsoleMailer → `journalctl -u loupit-beta-api --since "2 min ago" | grep ConsoleMailer` 에서 6자리 릴레이. 이메일은 형식만 맞으면 됨.
- 베타 API 는 **main 트리 `server/`** 코드를 쓴다(worktree 아님) → 백엔드 수정 후 `sudo systemctl restart loupit-beta-api`.
- 프론트 편집은 **`/home/ubuntu/loupit-fe/web/` 에만**(main 트리 `web/` 편집 = 프로덕션 즉시 노출). git 은 `git -C /home/ubuntu/loupit-fe`.
- 회사 검색은 한글 쿼리라 `curl -G --data-urlencode "q=삼성"` 로 호출할 것(인라인 URL 은 깨진다).

---

## H. 2026-07-27 — AdSense 게이트 해제 + `M9_ENABLED` 마스터 스위치

### H-1. 게이트 재정의 (사용자 제기: "애드센스랑 상관 없이 로그인 기능 추가해도 되지 않아?")

**맞다. AdSense 는 M9 의 진짜 게이트가 아니었다.** §E 의 "심사 결과까지 홀드"는 보수적 일괄 홀드였다.
AdSense 가 요구하는 건 **정확한 개인정보 고지**인데, 그건 아래 게이트 ①을 고치면 동시에 만족된다.
심사에 실제로 나쁜 건 "반쯤 배포"(프론트만 병합해 `/login.html` 이 500 나는 채로 크롤링)다 —
**제대로 켜는 쪽이 어중간하게 두는 것보다 안전**하다.

실제 게이트 3종:

| # | 게이트 | 성격 | 상태 |
|---|---|---|---|
| ① | **라이브 정책 문안 동시 배포** | 법적(개인정보보호법 §30) · 회피 불가 | ✅ **본 세션에서 코드 완료** — 배포는 활성화 릴리스에서 |
| ② | **SMTP 계정 조달** | 외부 의존 · 유일한 리드타임 항목 | ⬜ 미정(사용자 결정 대기) |
| ③ | **운영 pepper 2종 주입** | 보안 · 즉시 가능 | ⬜ 활성화 시 |

**① 이 왜 하드 게이트인가**: 라이브 `/privacy` 는 지금 "jobcho.wiki(잡초)는 **회원가입·로그인·계정
기능이 없습니다.** 이용자를 식별하는 개인정보(이름·**이메일**·전화번호 등)를 서버에 수집하거나
저장하지 않습니다" 라고, `/terms` 는 "**로그인·계정 없음** — 로그인·회원가입 없이 제공되며" 라고
선언한다. 로그인이 켜지는 순간 둘 다 허위 기재가 된다(서비스는 실제로 로그인 이메일을 저장한다).

**② SMTP 권고**: 재직 인증 코드는 **회사 메일서버(samsung.com 등)로** 들어간다. 대기업 게이트웨이는
SPF/DKIM/DMARC 미정렬 발신을 거의 확실히 스팸/거부 처리하므로, SPEC 예시의 개인 네이버 계정
(`smtp.naver.com`)은 로그인 코드는 몰라도 **재직 인증은 실질적으로 작동하지 않는다**. `jobcho.wiki`
도메인으로 DKIM 서명하는 트랜잭션 메일 서비스 권장 — **Resend**(DNS TXT 3개·무료 3,000통/월) 또는
**Amazon SES**($0.10/1,000·샌드박스 해제 1~2일). 둘 다 SMTP 릴레이를 제공하므로 `smtplib` 그대로,
**신규 의존성 0 유지**.

### H-2. `M9_ENABLED` — 하나의 스위치가 런타임과 문안을 함께 뒤집는다

**발견한 함정(문서에 없던 것)**: `server/main.py` 가 참여 라우터 3종을 **무조건** 등록하고 있었다.
프로덕션이 inert 했던 유일한 근거는 `loupit-api` 가 **2026-07-20 기동 이후 안 죽었다**는 것뿐이다 —
prod·beta 는 같은 트리(`WorkingDirectory=/home/ubuntu/loupit`)를 쓰며, 재시작한 beta 는 참여 라우트가
살아 있고(401/200) 재시작 안 한 prod 만 404 였다. 즉 **재부팅 한 번**이면 참여 테이블 0/7 인 스키마
위에서 M9 쓰기 표면이 켜졌다. `release.sh` 의 M9 활성화 가드(6879454)는 **릴리스 경로만** 덮는다.

도입한 계약 — 하나의 환경변수가 셋을 동시에 지배한다:

| 축 | 파일 | 반영 시점 |
|---|---|---|
| (A) 참여 라우터 3종 등록 | `server/main.py` (`s.m9_enabled`) | 프로세스 재시작 |
| (B) 세션·코드 retention purge | `server/main.py` `_purge_sessions_safe(m9_enabled)` | 재시작 |
| (C) 정책 문안(개인정보 P7·약관 T5·P1/T2 개정) | `generator/content/policy.py` (`cfg.m9_enabled`) | 사이트 재빌드 |

- 배포별: prod `server/.env` **키 부재 = OFF** · beta `server/.env.beta` `M9_ENABLED=1` · 테스트는
  conftest 가 세션 전역 `setdefault("M9_ENABLED","1")`(베이스 게이트 TS-1 이 ON 표면을 계약으로 가짐).
- `release.sh` 가 `server/.env` 를 `set -a` 로 source 하므로, 활성화 릴리스 한 번에 `[4/7]` 정적
  재생성과 `[5/7]` API 재시작이 **같은 값**을 본다.
- ⚠ **빈값 금지**: `M9_ENABLED=` 는 pydantic ValidationError 로 **앱이 부팅하지 못한다**. 끄려면
  키를 지우거나 `0`. `server/.env` 에 `M9_ENABLED=0` 을 넣어도 안 된다 — conftest 의 `load_dotenv` 가
  먼저 채워 `setdefault` 가 못 덮고 베이스 테스트 63건이 OFF 로 떨어져 RED 가 된다.

**중간에 잡은 자체 결함**: 초판은 생성기가 `== "1"` 로만 파싱해, 서버(pydantic 의 넓은 truthy 집합)와
갈라졌다 — `M9_ENABLED=true` 배포에서 **로그인은 켜지고 정책 문안은 "로그인 없음"으로 남는**, 이
스위치가 막으려던 바로 그 상태. `generator.config.env_flag()` 로 규칙을 통일하고 교차 검증
(`test_policy_m9` PM-11, 10개 env 값)으로 고정했다.

### H-3. 함께 해소한 것

- **T-13.2.2 (실간극)**: 참여 7테이블이 `apply_sql(schema.sql)` 로 **생성만 되고 DROP 목록엔 없어**
  영원히 안 지워졌다 → 세션 간 행 잔존 + `TCOMPANY` 재생성 시 COMP_ID 재배정으로 살아남은 이력 행이
  다른 회사로 재해석되는 **#15 동형** 결함. `TABLE_CREATE_ORDER` 에 병합하고, 계약을 "schema.sql 의
  **모든** 테이블이 격리 사이클 안"으로 일반화(`test_schema_isolation.py` SI-1~6)해 향후 테이블 추가도
  자동으로 잡히게 했다. 동반: `AUDIT_EXEMPT_TABLES` 에 `TBENEFIT_EDIT_LOG` 추가(append-only,
  SPEC/02 §SC-4 가 이미 명세하던 예외를 테스트가 안 따라간 상태였음) + 부재 적극검증 `test_SC4c`.
- **T-13.1.3 마커 정정**: `[ ]` 였으나 `test_surface.py:67-82` 에 이미 존재·상시 그린.
- **env 예제 2종**: `infra/env/server.env.example` 에 M9 블록(주석 처리·빈값 금지 경고),
  `server/.env.example` 헤더를 SC10 실제 금지범위로 정정.

### H-4. 검증

| 스위트 | 결과 |
|---|---|
| 백엔드 `-m "not sc14"` | **353 passed**(327 → +6 M9 게이트 +20 스키마 격리·파라미터 확장) |
| 백엔드 `-m sc14` | 3 passed (활성화까지 격리 유지 — 서빙 스키마엔 참여 테이블이 없어 RED 가 정상) |
| 생성기 | **211 passed**(201 → +10, PC-2 모드 파라미터화 포함) |
| 프론트(main 트리) | **423 passed** |

배포별 플래그 실측: prod `m9_enabled=False`(DB `LOUPIT`) / beta `m9_enabled=True`(DB `loupit_beta`).
prod 참여 테이블 **0/7**, beta·test 7/7. prod API 는 여전히 참여 라우트 404(기동 2026-07-20).

### H-5. 남은 것 · 미결

1. **beta 재시작 검증 미실시** — 권한 거부로 `systemctl restart loupit-beta-api` 를 못 돌렸다.
   `.env.beta` 파싱은 실측 확인(`m9_enabled=True`)했으나 **실기동 확인은 사용자 몫**:
   `sudo systemctl restart loupit-beta-api` 후 `curl -o /dev/null -w '%{http_code}'
   http://127.0.0.1:8001/api/v1/members/me` 가 **401**이어야 한다(404 면 게이트가 OFF 로 떨어진 것).
2. **[미결] 공유 docroot 에서 beta 정책 문안**: `/home/ubuntu/loupit-fe/web/dist` 는
   `/home/ubuntu/loupit/web/dist` **심링크(동일 inode 확인)** — prod·beta 가 정책 HTML 을 물리적으로
   공유한다. 따라서 (C)만은 "prod OFF · beta ON" 이 **불가능**하다. 현재 beta 는 로그인이 살아 있는데
   공유 `/privacy` 는 "로그인 없음"을 말한다. beta 는 `X-Robots-Tag noindex` + `robots.txt Disallow: /`
   전면 차단이고 테스터가 운영자 본인뿐이라 **활성화 시 일괄 해소로 두는 것이 현 판단**이나,
   심링크 해제(beta 전용 빌드)를 원하면 별도 작업이다.
3. **`release.sh` M9 가드와 플래그의 관계 미정리**: 가드는 "서빙 스키마 7/7 이면 이미 활성"으로 보는데,
   이제 테이블이 있어도 `M9_ENABLED` 없이는 라우터가 안 켜진다(방어 심화). `test_release_m9_gate.py`
   가 한글 헤딩 문자열 슬라이싱에 의존하므로 손대면 동시 갱신 필요 — 별도 커밋 권장.
4. **활성화 체크리스트(갱신본)**: (a) `db/schema.sql` 7테이블 — **이미 완료**(구 체크리스트 오류),
   (b) conftest 병합 — **완료(H-3)**, (c) sc14 마커 해제, (d) 베이스 test 갱신 — **대부분 완료**,
   (e) `SPEC/11 §6.2a` GRANT·`§3.4` nginx 실파일 반영, (f) **`M9_ENABLED=1` + pepper 2종 +
   `MAILER_MODE=smtp`** 를 `server/.env` 에 주입, (g) 사이트 재빌드(정책 문안 전환) + API 재시작.
   실행은 `M9_ACTIVATE=1 RELEASE_CONFIRM=1 bash infra/deploy/release.sh`.
5. **GRANT 드리프트는 문서 결함이 아니다**(초기 판단 정정): SPEC/11 L548 과
   `infra/mysql/provision_accounts.sql` L9-14 가 "라이브는 단일 `APP_LOUPIT`(GRANT ALL) 계정"임을
   **정직히 기록**하고 §6.2a 를 도달 목표로 명시하고 있다. 다만 그 때문에 런타임이 참여 테이블에
   쓸 권한을 이미 갖고 있으므로, 지금 M9 를 막는 것은 **`M9_ENABLED` 게이트뿐**이다.
6. `m9-frontend` 병합 판단은 여전히 미결(§G 1번). 단 §G 의 "병합 = 사실상 M9 프론트 공개"는
   **과대평가**다 — prod nginx 에 `location = /login|/mypage|/verify|/edit|/edits` 가 **없어**
   클린 URL 은 404 다. 노출되는 건 말미 `location / { try_files $uri $uri/ =404; }` 를 타는
   `/login.html` 등뿐이고, `location ~ ^/(login|mypage|verify|edit|edits)\.html$ { return 404; }`
   한 줄로 활성화 전까지 완전 차단 가능하다.
