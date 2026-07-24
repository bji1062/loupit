# 참여 API (FRD)

**목적**: PRD 범위 **SC14(참여, 2026-07-21 증분)**의 기능 — 무비밀번호 이메일 코드 로그인, 계정 관리·탈퇴, 회사 도메인 이메일 재직 인증, 복지 등록·수정, 편집 이력 열람 — 을 구현 가능한 수준의 **HTTP·전송 계약**으로 확정한다. 각 엔드포인트의 메서드·경로·요청·응답 상태코드·오류·세션·CSRF·해시 at-rest·발송 리밋을 명세한다. 익명 열람·비교(F1~F8, FR-1x~9x)는 로그인 없이 그대로이며 본 문서 대상이 아니다.

**참조 상위문서**: PRD `04-범위.md`(SC14)·`07-비기능-요구사항.md`(NFR16·17·20·30·31), USECASE `09-참여.md`(UC-70~UC-77)·`01-액터와-개요.md`(액터 A6), SPEC `01-개요와-아키텍처.md`(INV-1·INV-8·INV-9·T2·T9·T10), SPEC `13-참여-로그인.md`(SP-AUTH 상세 구현 계약)·`02-데이터베이스-스키마.md`(참여 7테이블 DDL).

**상위 추적**: FRD → USECASE → PRD → 브리프. 본 문서(FR-10x·FR-11x)는 참여 엔드포인트의 **전송 계약**을 소유하고, 저장 스키마·해시 알고리즘·세션 발급 상세는 SP-AUTH(SPEC 13)·SP-DB(SPEC 02)가 소유한다(중복 정의 금지). 전역 규약은 `01-개요와-FR규칙.md`(FR-01·FR-08)를 상속하되, FR-01의 "서버 무쓰기"는 **익명 경로 한정**으로 해석하고 기여(SC14) 쓰기는 본 문서가 정의한다.

**FR-ID 대역**: 본 문서는 **FR-100~FR-115**를 소유한다(숫자 십단위 대역 FR-0x~FR-9x가 소진되어, SC14 참여 도메인은 그다음 FR-10x·FR-11x로 확장한다). 각 FR은 자신을 충족하는 UC(UC-70~UC-77)와 상위 범위 SC14, 관련 NFR·INV를 역참조한다.

**전역 전제(본 문서 FR 공통)**: (1) 익명 열람·비교는 로그인 없이 유지되며, 본 문서 엔드포인트는 **복지 기여**를 하려는 사용자에게만 적용된다(SC14). (2) 로그인은 **무비밀번호 이메일 6자리 코드**뿐이다 — 비밀번호·OAuth·소셜 로그인은 존재하지 않는다(SC10). (3) 세션·재직 검증은 **미들웨어가 아니라 라우트 의존성(Depends)**으로 표현되어, `app.user_middleware == ['CORSMiddleware']`가 유지된다(INV-9·TS-2). (4) 서버 저장 PII는 로그인 이메일 + 닉네임뿐이며, 회사 이메일·인증 코드·세션 토큰은 원문 저장 0(해시/HMAC만, 검증 직후 파기, INV-8·NFR30). (5) 쓰기 요청은 세션 쿠키 + 커스텀 헤더(`X-Loupit-Client`)를 동반한다(CSRF, FR-113).

---

## 공통 규약 (전 FR 적용)

| 항목 | 규약 | 근거 |
|------|------|------|
| 기본 경로 | 모든 엔드포인트는 `/api/v1/` 아래에 위치한다(익명 API와 동일 오리진). | §8 |
| 인증 방식 | 세션 쿠키(`loupit_sid`, HttpOnly·Secure·SameSite=Lax·Path=/api/v1) + 라우트 의존성 검증. `Authorization` 헤더·JWT·비밀번호 미사용. | INV-9 |
| CSRF | 상태변경(POST/PUT/DELETE) 요청은 커스텀 헤더 `X-Loupit-Client` 필수. nginx 게이트 + 앱 레벨 이중 검사(FR-113). CORS `allow_credentials=false` 유지. | FR-113 |
| 응답 형식 | `Content-Type: application/json; charset=utf-8`. 인증·계정 응답은 `Cache-Control: no-store`. | NFR16 |
| 저장 스키마 | 참여 7테이블 DDL·해시 컬럼은 SP-DB(SPEC 02)·SP-AUTH(SPEC 13)가 소유. 본 문서는 전송 계약만 정의. | 문서 분담 |
| PII·해시 | 회사 이메일·코드·토큰 원문 무저장(FR-111). 로그·응답에 이메일·코드 원문 미출력. | INV-8·NFR30 |

---

## FR 인덱스

| FR-ID | 제목 | 엔드포인트/범위 | 주 커버 UC |
|-------|------|-----------------|------------|
| **FR-100** | 참여 API 표면·쓰기 라우트 열거 | 기여 쓰기 라우트 한정·세션=의존성 | UC-70~77(전제) |
| **FR-101** | 세션 계약(불투명 토큰·해시·쿠키·TTL) | 세션 발급·검증·만료·폐기 | UC-71 |
| **FR-102** | `POST /members/login-code` — 로그인 코드 발송 | 이메일→코드 발송·균일 204 | UC-70 |
| **FR-103** | `POST /members/login` — 코드 검증·세션 발급 | 코드 검증·닉네임 자동생성·Set-Cookie | UC-71 |
| **FR-104** | 계정 관리 — me·닉네임·로그아웃·탈퇴 | GET/PUT/DELETE `/members/me`, 로그아웃 | UC-72 |
| **FR-105** | `POST /employment/verify-code` — 재직 코드 발송 | 도메인 매칭→회사 이메일 코드 발송 | UC-73 |
| **FR-106** | `POST /employment/verify` — 재직 인증 생성 | 코드 검증·원문 파기·HMAC 보관 | UC-73 |
| **FR-107** | `POST /employment/requests` — 수동 승인 요청 | 소명 제출·승인 큐 | UC-74 |
| **FR-108** | `POST /companies/{comp_id}/benefits` — 복지 등록 | 재직 인증 게이트·verified 배지·이력 | UC-75 |
| **FR-109** | `PUT /companies/{comp_id}/benefits/{benefit_id}` — 복지 수정 | base_dtm 동시성·409·이력 | UC-76 |
| **FR-110** | `GET /companies/{comp_id}/edits` — 편집 이력 | 공개 조회·닉네임 조인·no-store | UC-77 |
| **FR-111** | 인증 데이터 at-rest·PII 최소 계약 | 해시/HMAC·원문 파기·PII 컬럼 한정 | UC-71·73(전제) |
| **FR-112** | 발송·시도 리밋·계정 열거 방지 | rate limit·쿨다운·시도 상한·균일 응답 | UC-70·73(전제) |
| **FR-113** | CSRF·세션 전송 헤더 계약 | X-Loupit-Client·쿠키 속성·CORS | UC-75·76(전제) |
| **FR-114** | 참여 공통 상태코드·오류 응답 | 401/403/409/422 매트릭스·envelope | UC-70~77 |
| **FR-115** | 운영자 CLI 계약(참여 관리) | 승인·거부·인증 취소·복지 삭제 | UC-74 |

---

## [FR-100] 참여 API 표면·쓰기 라우트 열거

**설명**: SC14 기여 기능이 추가하는 쓰기 라우트를 **한정 열거**하고, 세션·재직 검증이 미들웨어가 아닌 라우트 의존성으로만 표현됨을 표면 수준 계약으로 고정한다. INV-1(API 표면)의 기여 확장 구체화다.

**상세 동작**
- 정상: 참여로 추가되는 라우트는 아래 열거집합뿐이다.

  | # | 메서드 | 경로 | 소유 FR | 세션 | 재직 인증 |
  |---|--------|------|---------|:----:|:--------:|
  | 1 | POST | `/api/v1/members/login-code` | FR-102 | 불필요 | — |
  | 2 | POST | `/api/v1/members/login` | FR-103 | 발급 | — |
  | 3 | POST | `/api/v1/members/logout` | FR-104 | 필요 | — |
  | 4 | GET | `/api/v1/members/me` | FR-104 | 필요 | — |
  | 5 | PUT | `/api/v1/members/me` | FR-104 | 필요 | — |
  | 6 | DELETE | `/api/v1/members/me` | FR-104 | 필요 | — |
  | 7 | POST | `/api/v1/employment/verify-code` | FR-105 | 필요 | — |
  | 8 | POST | `/api/v1/employment/verify` | FR-106 | 필요 | — |
  | 9 | POST | `/api/v1/employment/requests` | FR-107 | 필요 | — |
  | 10 | POST | `/api/v1/companies/{comp_id}/benefits` | FR-108 | 필요 | 해당 회사 |
  | 11 | PUT | `/api/v1/companies/{comp_id}/benefits/{benefit_id}` | FR-109 | 필요 | 해당 회사 |
  | 12 | GET | `/api/v1/companies/{comp_id}/edits` | FR-110 | 불필요(공개) | — |

- 금지: 인증·세션 미들웨어를 `app.add_middleware`로 등록하지 않는다. 세션·재직 검증은 `require_member`·`require_employment(comp_id)` 의존성으로만 주입한다(INV-9). 사용자 DELETE 복지 라우트는 v1에 없다(운영자 CLI 전용, FR-115).
- 대안(비허용 메서드): 열거 외 메서드는 405 `Allow` 헤더와 함께 반환(FR-114).

**검증·비즈니스 규칙**
1. 익명 GET 5종 + 익명 로그 POST 1종 + 위 기여 쓰기 라우트(POST/PUT) + 공개 GET 2종(me·edits)만 존재한다. 그 외 쓰기 0(Tier-0 TS-1 재명세, T2).
2. `app.user_middleware == ['CORSMiddleware']` — 인증/세션 미들웨어 0(INV-9, T2·T10).
3. 라우터 파일은 `member.py`·`employment.py`·`benefit_edit.py`이며 금지명 `auth`를 쓰지 않는다(T10, test_package allowlist 확장).
4. 세션은 라우트 의존성이므로 익명 GET 경로의 dependant 트리에 `require_member`가 없다(T2·T10).

**추적**: SC14 / UC-70~77(전제) / INV-1·INV-9·NFR20 / T2·T10 / SP-AUTH.

---

## [FR-101] 세션 계약(불투명 토큰·해시·쿠키·TTL)

**설명**: 로그인 성공(FR-103) 시 발급되는 세션의 형태·저장·전송·만료·폐기 계약. JWT·OAuth·비밀번호를 쓰지 않는다.

**상세 동작**
- 발급: 불투명 랜덤 토큰(`secrets`)을 생성하고, **DB에는 SHA-256 해시만** 저장한다(TSESSION.TOKEN_HASH_VAL). 원문 토큰은 쿠키로만 전달된다.
- 쿠키: `loupit_sid` = 토큰 원문, 속성 `HttpOnly; Secure; SameSite=Lax; Path=/api/v1; Max-Age=<30d>`.
- 검증: 요청 쿠키의 토큰을 해시해 TSESSION에서 조회, 미만료·미폐기 세션이면 인가(라우트 의존성 `require_member`).
- 만료·폐기: TTL(~30일) 경과 또는 로그아웃(FR-104)·탈퇴 시 폐기(REVOKED_DTM). 만료 세션은 `_retention_scheduler`가 주기 퍼지.

**검증·비즈니스 규칙**
1. DB에 세션 토큰 **원문 컬럼 부재** — `TOKEN_HASH_VAL`(CHAR(64)) 해시만(T9, INV-8).
2. 쿠키는 `HttpOnly`(JS 접근 차단)·`Secure`(HTTPS)·`SameSite=Lax`(CSRF 완화)·`Path=/api/v1`(익명 정적 경로에 쿠키 미전송).
3. 세션 TTL·쿨다운 등 수치는 config가 소유하나, config 필드명에 `session` 부분문자열이 있어도 test_config 재명세(금지 substring에서 `session` 제거)로 허용된다 — 단 `jwt·oauth·password_reset·social`은 계속 금지(T10).
4. 세션은 미들웨어가 아니라 의존성이다(INV-9).

**추적**: SC14 / UC-71 / INV-8·INV-9·NFR17·NFR30 / T9·T10 / SP-AUTH.

---

## [FR-102] `POST /api/v1/members/login-code` — 로그인 코드 발송

**설명**: 이메일 주소로 6자리 로그인 코드를 발송한다. 계정 존재 여부를 응답으로 노출하지 않는다(계정 열거 차단).

**상세 동작**
- 정상: 요청 이메일에 대해 6자리 코드를 생성, 코드의 **해시**만 만료(+5분)와 함께 저장(TAUTH_CODE, PURPOSE=login)하고 이메일로 발송한 뒤 **균일 204**를 반환한다.
- 대안(rate limit·쿨다운): 발송 상한·재전송 쿨다운 초과 시 발송을 억제하되 응답은 균일 유지(FR-112).
- 예외(형식 오류): 이메일 형식 위반은 422. 계정 유무는 노출하지 않는다.

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `email` | body(JSON) | string | N | 이메일 형식. 개인정보 수집·이용 **동의** 전제(프론트 UC-70 1a) |

**출력·상태**

| 상태 | 조건 | 본문 |
|------|------|------|
| 204 No Content | 발송 성공 또는 계정 부재(균일) | (없음) |
| 422 Unprocessable Entity | 이메일 형식 오류 | 오류 envelope(FR-114) |
| 429 Too Many Requests | 발송 rate limit 초과(nginx `loupit_mail` 존) | 오류 envelope |

- 헤더: `Cache-Control: no-store`. 응답 본문·로그에 코드·계정 존재 여부 미포함.

**검증·비즈니스 규칙**
1. 계정 유무와 무관하게 **동일한 204**(계정 열거 차단, NFR31).
2. 코드 원문은 저장하지 않고 해시만(TAUTH_CODE.CODE_HASH_VAL). 만료 +5분(FR-111).
3. 발송은 nginx rate limit(`loupit_mail` 3r/m 계열) + 재전송 쿨다운으로 상한(FR-112, NFR31).
4. 이메일 원문은 로그에 남기지 않는다(PII 로그 grep 게이트).

**추적**: SC14 / UC-70 / NFR30·NFR31 / FR-111·FR-112·FR-114 / SP-AUTH·SP-INFRA(메일 존).

---

## [FR-103] `POST /api/v1/members/login` — 코드 검증·세션 발급

**설명**: 발송된 6자리 코드를 검증하고, 성공 시 계정을 조회·생성하며 세션을 발급한다. 신규면 닉네임을 자동 생성한다.

**상세 동작**
- 정상: `{email, code}`를 받아 저장된 코드 해시·만료·시도횟수와 대조한다. 성공 시 계정을 조회(기존)하거나 생성(신규, 닉네임 `직장인-{랜덤6}` 자동 부여)하고, 세션을 발급(FR-101)해 Set-Cookie와 함께 200을 반환한다.
- 대안(신규 사용자): `is_new=true` 반환, 닉네임은 마이페이지(FR-104)에서 변경 가능.
- 예외(코드 불일치·만료·시도 초과): 401/410/429(FR-112·FR-114). 코드는 상한(5회) 초과 시 무효화.

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `email` | body | string | N | UC-70에서 코드를 받은 이메일 |
| `code` | body | string | N | 6자리 숫자 코드 |

**출력·상태**

| 상태 | 조건 | 본문 |
|------|------|------|
| 200 OK | 코드 검증 성공 | `{"nickname": "...", "is_new": bool}` + `Set-Cookie: loupit_sid=...` |
| 401 Unauthorized | 코드 불일치 | 오류 envelope |
| 410 Gone | 코드 만료(+5분) | 오류 envelope |
| 429 Too Many Requests | 시도 상한(5회) 초과 | 오류 envelope |

- 헤더: `Cache-Control: no-store`.

**검증·비즈니스 규칙**
1. 검증 성공 시 코드는 소비 처리(CONSUMED_DTM), 재사용 불가.
2. 신규 계정의 저장 PII = 로그인 이메일 + 자동 닉네임뿐(INV-8, T9).
3. 세션 쿠키 속성은 FR-101 준수. 응답 본문에 세션 토큰 원문·이메일 미포함.
4. 시도 상한·만료는 FR-112.

**추적**: SC14 / UC-71 / INV-8·INV-9·NFR16·NFR30 / FR-101·FR-111·FR-112 / SP-AUTH.

---

## [FR-104] 계정 관리 — `/members/me`·로그아웃·탈퇴

**설명**: 로그인 사용자의 프로필 조회, 닉네임 변경, 로그아웃, 탈퇴를 제공한다(세션 의존성 인가).

**상세 동작**
- `GET /members/me`: 현재 닉네임·보유 재직 인증 목록(회사·만료)·상태 반환(200, no-store).
- `PUT /members/me` `{nickname}`: 닉네임 변경(고유성 검증). 성공 200, 중복 409.
- `POST /members/logout`: 세션 폐기(쿠키 삭제 + DB 무효화). 204.
- `DELETE /members/me`: 탈퇴 — **로그인 이메일 파기(NULL)** + 전 세션 폐기. **닉네임·편집 이력은 존치**(공개 이력 무결성, 약관 T5 고지). 204.

**입력**

| 엔드포인트 | 파라미터 | 위치 | 제약 |
|-----------|----------|------|------|
| PUT /members/me | `nickname` | body | 고유·길이/문자 제약(SP-AUTH) |
| 그 외 | (없음) | — | 세션 쿠키로 주체 식별 |

**출력·상태**

| 상태 | 조건 |
|------|------|
| 200 OK | me 조회 / 닉네임 변경 성공 |
| 204 No Content | 로그아웃 / 탈퇴 성공 |
| 401 Unauthorized | 세션 없음·만료 |
| 409 Conflict | 닉네임 중복 |

**검증·비즈니스 규칙**
1. 모든 엔드포인트는 `require_member` 의존성 인가(세션 없으면 401).
2. 탈퇴 시 이메일 원문만 파기하고 편집 이력의 닉네임은 남긴다(UC-72 5a). 이 존치는 약관 T5·가입 동의에 고지된다(SP-POL).
3. `GET /members/me`는 `no-store`(캐시 금지, 개인 상태).
4. 응답에 회사 이메일·세션 토큰 등 비밀값 미포함(INV-8).

**추적**: SC14 / UC-72 / INV-8·NFR16 / FR-101 / SP-AUTH·SP-POL(T5).

---

## [FR-105] `POST /api/v1/employment/verify-code` — 재직 코드 발송

**설명**: 회사 도메인 이메일로 재직 인증 코드를 발송한다. 입력 도메인이 대상 회사 등록 도메인과 일치해야 한다.

**상세 동작**
- 정상: `{comp_id, company_email}`을 받아 입력 도메인이 해당 회사 등록 도메인(TCOMPANY_EMAIL_DOMAIN)과 일치하면, 6자리 코드를 생성해 **해시**만 저장(TAUTH_CODE, PURPOSE=employ_verify, comp_id·mbr_id 연계)하고 그 회사 이메일로 발송 후 204.
- 대안(도메인 미등록): 해당 회사 도메인 미등록이면 수동 승인(FR-107)으로 유도(409 manual_required).
- 예외(도메인 불일치): 입력 이메일 도메인이 회사 등록 도메인과 다르면 422.

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | body | int | N | 등록 회사 PK |
| `company_email` | body | string | N | 회사 이메일. 도메인 매칭 대상 |

**출력·상태**

| 상태 | 조건 |
|------|------|
| 204 No Content | 도메인 일치·발송 성공 |
| 409 Conflict | `manual_required`(도메인 미등록) / `already_verified` |
| 422 Unprocessable Entity | 입력 도메인이 회사 등록 도메인과 불일치 |
| 429 Too Many Requests | 발송 rate limit 초과 |

- 세션 의존성 인가(401), `Cache-Control: no-store`.

**검증·비즈니스 규칙**
1. `require_member` 인가 필요(로그인 상태).
2. 회사 이메일 원문은 이 단계에서 저장하지 않는다(코드 검증 성공 시점에 HMAC만, FR-106).
3. 발송·시도 상한은 FR-112.

**추적**: SC14 / UC-73 / INV-8·NFR30·NFR31 / FR-106·FR-107·FR-112 / SP-AUTH.

---

## [FR-106] `POST /api/v1/employment/verify` — 재직 인증 생성

**설명**: 재직 코드를 검증하고 성공 시 재직 인증 레코드를 생성한다. 회사 이메일 원문은 파기하고 HMAC 해시만 보관한다.

**상세 동작**
- 정상: `{comp_id, company_email, code}` 검증 성공 시 TEMPLOY_VERIFICATION 생성 — 회사 이메일 **원문 파기**, `COMP_EMAIL_HASH_VAL`(HMAC)만 보관, VRF_METHOD=domain, 만료 +365일. 201 반환. 해당 회사 복지 편집(FR-108·109) 권한 활성화.
- 예외(코드 불일치·만료·시도): 401/410/429(FR-112·FR-114).
- 예외(HMAC 중복): 같은 회사 이메일 HMAC이 타 계정에 이미 존재하면 409(한 회사 이메일=한 계정).

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | body | int | N | UC-73 대상 회사 |
| `company_email` | body | string | N | 코드 발송에 쓴 회사 이메일(검증 후 원문 파기) |
| `code` | body | string | N | 6자리 코드 |

**출력·상태**

| 상태 | 조건 |
|------|------|
| 201 Created | 재직 인증 생성 |
| 401/410/429 | 코드 불일치/만료/시도 초과 |
| 409 Conflict | 회사 이메일 HMAC 중복(타 계정 기인증) / already_verified |

**검증·비즈니스 규칙**
1. 인증 생성 후 회사 이메일 **원문 컬럼 부재** — HMAC(`COMP_EMAIL_HASH_VAL`)만(T9, INV-8·NFR30).
2. 인증 만료 +365일. 만료 시 재인증 필요(퇴사자 자연 차단).
3. `require_member` 인가 필요.

**추적**: SC14 / UC-73 / INV-8·NFR30 / FR-105·FR-112·FR-114 / SP-AUTH·SP-DB.

---

## [FR-107] `POST /api/v1/employment/requests` — 수동 승인 요청

**설명**: 도메인 인증이 불가한 회사(도메인 미등록·그룹사 공유 등)에 대해 소명을 제출해 운영자 수동 승인 큐에 등록한다.

**상세 동작**
- 정상: `{comp_id, evidence}`를 받아 TEMPLOY_VRF_REQUEST(STATUS=pending) 생성, 202 반환. 운영자(A5)가 CLI로 심사(FR-115).
- 대안(중복 pending): 동일 회사 pending 요청이 있으면 기존 유지(중복 방지).

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | body | int | N | 대상 회사 |
| `evidence` | body | string | N | 재직 소명(텍스트). 이스케이프 저장(NFR21) |

**출력·상태**

| 상태 | 조건 |
|------|------|
| 202 Accepted | 승인 큐 등록 |
| 401 Unauthorized | 세션 없음 |
| 409 Conflict | 동일 회사 pending 중복 |

**검증·비즈니스 규칙**
1. `require_member` 인가 필요.
2. 소명 텍스트는 이스케이프 저장·표시(XSS, NFR21). 처리 결과는 마이페이지(FR-104)에서 확인.
3. 승인 시 VRF_METHOD=manual 재직 인증 생성(FR-115, 운영자 CLI).

**추적**: SC14 / UC-74 / INV-8·NFR21 / FR-115 / SP-AUTH·SP-INFRA.

---

## [FR-108] `POST /api/v1/companies/{comp_id}/benefits` — 복지 등록

**설명**: 해당 회사 재직 인증 보유자가 신규 복지 항목을 등록한다. 서버가 배지 시맨틱을 강제하고 편집 이력을 append한다.

**상세 동작**
- 정상: 세션 + `require_employment(comp_id)` + `X-Loupit-Client` 검증 후 복지 행을 삽입한다. 서버가 배지를 강제: `BADGE_CD='verified'`(재직자 확인)·`AMT_SOURCE_CD='estimated'`·`BADGE_SRC_CD='user_report'`·`EXPIRES_DTM=+18개월`. 정성이면 `QUAL_YN=true`·금액 NULL. 같은 트랜잭션에서 TBENEFIT_EDIT_LOG(EDIT_TYPE=create, before=∅→after 스냅샷)를 append한다. 201 + 갱신된 복지 목록 반환. 참조 캐시 무효화.
- 예외(권한 없음): 세션·재직 인증 미보유 401/403. 미인증 로그인자는 "재직 인증하고 편집하기"로 유도.
- 예외(CSRF 헤더 부재): 403(FR-113).
- 예외(중복·상한): 동일 회사·코드 중복 409, 일일 편집 상한(30건) 초과 429.

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | path | int | N | 재직 인증 보유 회사 |
| `benefit_cd` | body | string | N | 복지 코드(소문자 스네이크 `^[a-z][a-z0-9_]{1,29}$`, 회사 내 유니크 `uq_comp_benefit` — 중복 시 409) |
| `benefit_nm` | body | string | N | 복지 표시명(이스케이프) |
| `benefit_ctgr_cd` | body | string | N | 9카테고리 중 하나 |
| `benefit_amt` | body | int\|null | Y | 금액(만원). 정성이면 null |
| `qual_yn` | body | bool | N | 정성 여부(true면 금액 null 강제) |
| `note_ctnt` | body | string\|null | Y | 비고(이스케이프) |
| `edit_note` | body | string\|null | Y | 편집 요약(이력 기록) |

**출력·상태**

| 상태 | 조건 | 본문 |
|------|------|------|
| 201 Created | 등록 성공 | `{benefit, benefits[]}` |
| 401/403 | 세션 없음 / 재직 인증·CSRF 헤더 없음 | 오류 envelope |
| 409 Conflict | 동일 회사·코드 중복 | 오류 envelope |
| 429 Too Many Requests | 일일 편집 상한 초과 | 오류 envelope |

**검증·비즈니스 규칙**
1. 배지는 서버가 강제(사용자가 official·stated 지정 불가). `BADGE_CD='verified'`는 신규 제3값(기존 official/est 게이트 불변, `est` 재사용 금지).
2. 행 INSERT + 이력 INSERT는 **원자 트랜잭션**(SP-DB `transaction()`).
3. 편집자 = MBR_ID(감사컬럼 INS_ID/MOD_ID 활성화). calc.js 밴드 로직 무변경(표시 계층만 확장).
4. 응답 `benefits[]`로 클라이언트 REF 인메모리 치환·재렌더. 정적 페이지 반영은 야간 재생성(신선도 고지).

**추적**: SC14 / UC-75 / INV-1·INV-8·NFR21 / FR-113·FR-114 / SP-AUTH·SP-DB·SP-ENGINE(밴드 무변경).

---

## [FR-109] `PUT /api/v1/companies/{comp_id}/benefits/{benefit_id}` — 복지 수정

**설명**: 기존 복지 항목을 수정한다. 낙관적 동시성(`base_dtm`)으로 충돌을 감지한다.

**상세 동작**
- 정상: 세션 + `require_employment(comp_id)` + CSRF 검증 후, 요청의 `base_dtm`(읽은 행의 MOD_DTM)이 현재 행과 일치하면 행을 갱신하고 같은 트랜잭션에서 이력(EDIT_TYPE=update, before→after)을 append한다. 200 + 갱신 목록. official 행을 사용자가 수정하면 배지가 verified로 강등.
- 예외(동시성 충돌): `base_dtm` 불일치 시 **409 + 현재 행 동봉**(클라이언트가 현재값 diff 표시 후 재편집).
- 예외(권한·CSRF·상한): FR-108과 동일(401/403/429).

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | path | int | N | 재직 인증 보유 회사 |
| `benefit_id` | path | int | N | 수정 대상 항목 |
| `base_dtm` | body | string(dtm) | N | 읽은 행의 MOD_DTM(동시성 기준) |
| (수정 필드) | body | — | Y | benefit_nm·benefit_amt·qual_yn·note_ctnt·edit_note (FR-108과 동일 규약) |

**출력·상태**

| 상태 | 조건 | 본문 |
|------|------|------|
| 200 OK | 수정 성공 | `{benefit, benefits[]}` |
| 409 Conflict | `base_dtm` 불일치(선점 수정) | `{current_benefit, benefits[]}`(현재값 동봉) |
| 401/403/429 | 권한/CSRF/상한 | 오류 envelope |

**검증·비즈니스 규칙**
1. `base_dtm` 낙관적 동시성 — 버전 컬럼 없이 MOD_DTM 비교. 불일치는 409(현재 행 반환).
2. 행 UPDATE + 이력 INSERT 원자 트랜잭션(`SELECT ... FOR UPDATE`).
3. official→verified 강등은 사용자 편집 시 자동(신뢰도 시맨틱).
4. v1은 사용자 DELETE 없음(운영자 CLI 전용, FR-115).

**추적**: SC14 / UC-76 / INV-1·INV-8 / FR-108·FR-113·FR-114 / SP-AUTH·SP-DB.

---

## [FR-110] `GET /api/v1/companies/{comp_id}/edits` — 편집 이력 조회

**설명**: 회사 복지 편집 이력을 공개 조회한다. 로그인 불필요(익명 가능).

**상세 동작**
- 정상: 해당 회사 편집 이력을 최신순으로 반환한다(닉네임 조인, `limit`·`before` 페이지네이션). 200, `no-store`.
- 대안(이력 없음): 빈 배열.
- 대안(탈퇴 기여자): 이력의 닉네임은 존치되어 그대로 표시(이메일은 파기됨, UC-72).

**입력**

| 파라미터 | 위치 | 타입 | 널 | 제약 |
|----------|------|------|----|------|
| `comp_id` | path | int | N | 회사 PK |
| `limit` | query | int | Y | 페이지 크기(상한 SP-AUTH) |
| `before` | query | string(dtm)\|int | Y | 커서 페이지네이션 |

**출력·상태**

| 상태 | 조건 | 본문 |
|------|------|------|
| 200 OK | 조회 성공(0건 포함) | `[{nickname, edit_type, before, after, edit_note, dtm}, ...]` |
| 404 Not Found | 미존재 comp_id | 오류 envelope |

- 세션 불필요(공개). 모든 출력 필드는 이스케이프(NFR21).

**검증·비즈니스 규칙**
1. 공개 조회 — `require_member` 미적용. 익명(A1·A2)도 열람 가능.
2. 응답에 편집자 이메일·MBR_ID 등 식별 정보 미포함(닉네임만, INV-8).
3. before/after 스냅샷은 JSON. XSS 이스케이프(NFR21).

**추적**: SC14 / UC-77 / INV-8·NFR21 / FR-108·FR-109 / SP-AUTH·SP-DB.

---

## [FR-111] 인증 데이터 at-rest·PII 최소 계약

**설명**: 참여 기능이 저장하는 비밀값·PII의 at-rest 형태를 규정한다. INV-8·NFR30의 전송·저장 구체화다.

**검증·비즈니스 규칙**
1. **세션 토큰**: 원문 무저장, SHA-256 해시만(TSESSION.TOKEN_HASH_VAL).
2. **로그인/인증 코드**: 원문 무저장, 해시만(TAUTH_CODE.CODE_HASH_VAL), 만료 +5분, 소비 후 무효.
3. **회사 이메일**: 재직 검증 성공 시 원문 파기, HMAC 해시만(TEMPLOY_VERIFICATION.COMP_EMAIL_HASH_VAL) — 중복 인증 차단용.
4. **로그인 이메일**: TMEMBER.LOGIN_EMAIL_NM(로그인 식별자), 탈퇴 시 NULL 파기. **PII 컬럼은 이메일·닉네임뿐**(T9).
5. 인증 테이블에 원문 이메일·코드·토큰 컬럼 부재(`*_HASH_VAL`만, T9). 로그·응답에 원문 미출력(PII 로그 grep 게이트).

**추적**: SC14 / UC-71·UC-73(전제) / INV-8·NFR16·NFR30 / T9 / SP-AUTH·SP-DB.

---

## [FR-112] 발송·시도 리밋·계정 열거 방지

**설명**: 메일 폭탄·브루트포스·계정 열거를 막는 상한·균일 응답 계약. NFR31의 구체화다.

**검증·비즈니스 규칙**
1. **메일 발송**: nginx rate limit(`loupit_mail` 존, 예 3r/m) + 앱 레벨 재전송 쿨다운·시간당 상한.
2. **코드 검증**: 시도 상한(5회, TAUTH_CODE.ATTEMPT_CNT)·만료(5분). 초과 시 코드 무효화·429.
3. **계정 열거 차단**: 로그인 코드 요청(FR-102)은 계정 유무와 무관하게 균일 204.
4. 경로변수 라우트(`/companies/{id}/...`)는 nginx `^~` 블록 경유이므로 앱 레벨 상한(일일 편집 30건 등)으로 방어한다.
5. 로그·응답에 이메일·코드 원문 미출력.

**추적**: SC14 / UC-70·UC-73(전제) / NFR31 / FR-102·FR-108 / SP-AUTH·SP-INFRA(nginx 리밋).

---

## [FR-113] CSRF·세션 전송 헤더 계약

**설명**: 세션 쿠키 기반 쓰기의 CSRF 방어 계약. 커스텀 헤더 + SameSite + CORS 조합.

**검증·비즈니스 규칙**
1. 상태변경(POST/PUT/DELETE) 요청은 커스텀 헤더 `X-Loupit-Client` 필수. 없으면 403.
2. 근거: 크로스오리진은 커스텀 헤더를 preflight 없이 부착 못하며, preflight는 CORS 허용목록 + `allow_credentials=false`에서 실패한다. **nginx 게이트 + 앱 레벨 이중 검사**.
3. 세션 쿠키 `SameSite=Lax`로 top-level 이외 크로스사이트 전송 차단.
4. CORS `Access-Control-Allow-Credentials`는 미설정(false) 유지. 프로덕션은 nginx 동일 오리진 프록시라 쿠키에 CORS 불관여.
5. 익명 GET(`apiFetch`)은 `credentials:'omit'`(무쿠키), 기여 쓰기(`apiSend`)·`GET /members/me`만 credentialed.

**추적**: SC14 / UC-75·UC-76(전제) / INV-9·NFR16 / FR-100·FR-108·FR-109 / SP-AUTH·SP-INFRA(nginx 헤더 게이트).

---

## [FR-114] 참여 공통 상태코드·오류 응답

**설명**: 참여 엔드포인트가 공유하는 상태코드 매트릭스와 오류 envelope. 익명 API의 FR-95를 참여 쓰기로 확장한다.

**상세 동작 — 상태코드 매트릭스**

| 상태코드 | 발생 조건 | 적용 |
|----------|-----------|------|
| **200/201/202/204** | 정상(조회·생성·큐등록·무본문) | 전 엔드포인트 |
| **401 Unauthorized** | 세션 없음·만료, 코드 불일치 | 세션 필요 라우트·로그인 |
| **403 Forbidden** | 재직 인증 미보유, CSRF 헤더 부재 | 복지 편집·재직 필요 |
| **409 Conflict** | 닉네임 중복·HMAC 중복·`base_dtm` 충돌·중복 pending | me·verify·복지 |
| **410 Gone** | 코드 만료 | 로그인·재직 검증 |
| **422 Unprocessable Entity** | 형식·도메인 불일치 | 발송·검증 |
| **429 Too Many Requests** | rate limit·시도·편집 상한 | 발송·검증·편집 |
| **500** | 예기치 못한 서버 오류(민감정보 미노출) | 전 엔드포인트 |

**오류 응답 envelope**: `{"detail": "<메시지>"}`(명시) / 422는 FastAPI 검증 배열. `Cache-Control: no-store`. 스택·SQL·이메일·코드 원문 미노출(서버 로그만).

**검증·비즈니스 규칙**
1. 409 충돌(특히 FR-109 `base_dtm`)은 현재 상태를 동봉해 클라이언트 재조정을 돕는다.
2. 오류 응답에 PII·비밀값 미포함(INV-8).
3. 모든 비-2xx는 클라이언트가 방어적으로 흡수(무크래시, NFR26 정합).

**추적**: SC14 / UC-70~77 / NFR16·NFR26 / FR-95(익명 확장) / SP-AUTH.

---

## [FR-115] 운영자 CLI 계약(참여 관리)

**설명**: 웹 관리 패널 없이 운영자(A5)가 참여 데이터를 관리하는 CLI(`python -m server.ops`). 기존 시드 스크립트 관례를 따른다.

**상세 동작 — 명령**

| 명령 | 동작 |
|------|------|
| `list-pending` | 수동 재직 승인 대기 큐(TEMPLOY_VRF_REQUEST) 조회 |
| `approve <req_id>` | 승인 → VRF_METHOD=manual 재직 인증 생성(DECIDED_BY/DTM 기록) |
| `reject <req_id>` | 거부(사유 기록) |
| `revoke-verification <mbr_id> <comp_id>` | 재직 인증 취소(REVOKED_DTM) |
| `delete-benefit <benefit_id>` | 복지 삭제(반달리즘 대응) + EDIT_TYPE=delete 이력 기록 |

**검증·비즈니스 규칙**
1. CLI는 동기(pymysql) — 런타임 API와 분리. 사용자 대면 DELETE 라우트 없음(FR-100).
2. 삭제·승인·취소는 감사 흔적(DECIDED_BY_ID·이력)을 남긴다.
3. 운영자 인증은 서버 셸 접근 권한으로 대체(웹 관리 계정 없음).

**추적**: SC14 / UC-74 / INV-8 / FR-107·FR-109 / SP-AUTH·SP-INFRA(운영자 도구).

---

## 부록 — 추적 요약 (본 문서)

| 본 문서 FR | 충족 UC | 상위 범위 | 관련 NFR·INV | 인용 SPEC |
|:---:|--------|:---:|--------|-----------|
| FR-100 | UC-70~77(전제) | SC14 | INV-1·9, NFR20 | SP-AUTH |
| FR-101 | UC-71 | SC14 | INV-8·9, NFR17·30 | SP-AUTH |
| FR-102 | UC-70 | SC14 | NFR30·31 | SP-AUTH·SP-INFRA |
| FR-103 | UC-71 | SC14 | INV-8·9, NFR16·30 | SP-AUTH |
| FR-104 | UC-72 | SC14 | INV-8, NFR16 | SP-AUTH·SP-POL |
| FR-105 | UC-73 | SC14 | INV-8, NFR30·31 | SP-AUTH |
| FR-106 | UC-73 | SC14 | INV-8, NFR30 | SP-AUTH·SP-DB |
| FR-107 | UC-74 | SC14 | INV-8, NFR21 | SP-AUTH |
| FR-108 | UC-75 | SC14 | INV-1·8, NFR21 | SP-AUTH·SP-DB·SP-ENGINE |
| FR-109 | UC-76 | SC14 | INV-1·8 | SP-AUTH·SP-DB |
| FR-110 | UC-77 | SC14 | INV-8, NFR21 | SP-AUTH·SP-DB |
| FR-111 | UC-71·73(전제) | SC14 | INV-8, NFR16·30 | SP-AUTH·SP-DB |
| FR-112 | UC-70·73(전제) | SC14 | NFR31 | SP-AUTH·SP-INFRA |
| FR-113 | UC-75·76(전제) | SC14 | INV-9, NFR16 | SP-AUTH·SP-INFRA |
| FR-114 | UC-70~77 | SC14 | NFR16·26 | SP-AUTH |
| FR-115 | UC-74 | SC14 | INV-8 | SP-AUTH·SP-INFRA |
