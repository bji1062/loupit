# 원익IPS 복지 수집 근거 (evidence)

- 회사: (주)원익아이피에스 / WONIK IPS · KOSDAQ 240810
- COMP_ENG_NM: `wonik_ips` · COMP_NM: `원익IPS` · 유형 `mid` · INDUSTRY_NM `반도체장비` · LOGO_NM `W`
- 수집일: 2026-09-01 · 파싱 방식: 정적 HTML(서버사이드 PHP) 단일 GET, JS 실행 불필요
- 산출: **24행**(초안 28행 → 검증 판정 반영 −4) · 금액 명시(stated) **0건** · 신규 코드 **0개**

---

## 1. 사용 URL

| # | URL | HTTP | 크기 | 역할 |
|---|---|---|---|---|
| A | `https://www.ips.co.kr/ko/careers/system.php` | 200 | 37,767 B | **정본** — 인재채용>인사제도. 복리후생 탭 15항목 + 인사제도 탭(인센티브) + 인재교육 탭(교육과정·멘토링) |
| B | `https://www.ips.co.kr/ko/careers/culture.php` | 200 | 39,331 B | 보조 — 인재채용>조직문화. 근무·조직문화 제도 9종 |
| C | `https://www.ips.co.kr/robots.txt` | 200 | — | robots 확인 |

TCOMPANY.CAREERS_BENEFIT_URL 에는 **A** 를 넣었다.

### 사용하지 않은 URL과 이유
- `https://wonik.recruiter.co.kr/career/home`, `https://ips.recruiter.co.kr/` — **원익그룹 공용 채용 포털**이라 자사 도메인이 아니다. 그룹 공통 복지를 원익IPS 고유 복지로 귀속시키면 배지 계보(공식)의 출처가 흐려진다. 계약 6항(그룹 공통 복지 개별사 귀속 금지)에 따라 **전면 배제**.
- `welfare.php` / `benefit.php` — **둘 다 404**. 경로 추측 금지(프로브 주의 1).
- `/ko/etc/privacy.php`, `/ko/careers/recruit.php` — 이번 세션에서 확인, **404**. 존재하지 않는 경로다.

### 도메인 소유 확인
TLS 인증서 subject `O = "WONIK IPS CO., LTD.", CN = *.ips.co.kr` (Sectigo OV). 유효기간 2026-05-06 ~ **2026-11-20** — ⚠ 재수집이 11월 20일을 넘기면 TLS 실패 가능성.

## 2. robots.txt (전문)

```
User-agent: *
Disallow: /siteSystemWonik
Disallow: /module
```

`/ko/careers/*` 는 어느 Disallow 에도 걸리지 않는다. **허용**. Crawl-delay 없음, Sitemap 선언 없음. 봇 차단·WAF 챌린지·rate limit 미관측(일반 Chrome UA 로 200).

## 3. 회사 공식 이메일 도메인 관측 (계약 7항)

- 페이지 전체에서 관측된 이메일 주소는 **`ips.esg@wonik.com` 단 1건**(A 페이지 GNB 의 ESG 관련 문의 블록, "3영업일 이내 이메일 회신" 안내와 함께).
- 즉 **관측 이메일 도메인 = `wonik.com`** (원익그룹 공용 메일 도메인). 웹 도메인 `ips.co.kr` 과 메일 도메인이 다르다.
- `@ips.co.kr` 주소는 A·B·`/ko/etc/email.php` 어디에서도 관측되지 않았다. 채용 문의 전용 메일 주소도 게시되어 있지 않다.
- ⚠ 재직 인증 도메인 화이트리스트에 쓸 경우: `wonik.com` 은 **원익그룹 전 계열사 공용**일 개연성이 높아 원익IPS 단독 귀속 근거로는 약하다. 근거는 이 1건뿐임을 명기한다.

---

## 4. 행별 원문 인용표 (초안 28행 — 검증 판정 반영 결과는 §11)

원문은 짧은 발췌만 옮겼다(계약: 원문 복제 금지). 출처 열의 A = system.php, B = culture.php.

### 보상·금전 (compensation) — 3행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 10 | `excellence_award` | 포상제도(공로상·경영기여상) | A 복리후생 | `포상제도 — 분기별 공로상, 경영기여상 시상 등` |
| 11 | `incentive` | 경영성과 성과급·프로젝트 인센티브 | A 인사제도 | `인센티브 — 경영성과(매출, 이익 목표달성)에 따른 성과급 지급, 프로젝트 인센티브 지급` |
| 12 | `holiday_gift` | 명절·기념일 선물 | A 복리후생 | `선물지급 — 명절, 생일,결혼기념일 등` |

### 근무환경 (work_env) — 3행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 20 | `dormitory` | 기숙사 운영 | A 복리후생 | `기숙사 운영 — 기숙사, 주거비 지원` |
| 21 | `lounge` | 직원 휴게시설·사내 카페테리아 | A 복리후생 (B 보강) | `직원휴게시설 — 피트니스 시설, 안마의자, 사내 카페테리아, 직원 휴게실, 옥상하늘정원` / B: `창의적 근무환경 조성 — ... 사내 카페테리아 등을 운영` |
| 22 | `uniform` | 자율복장 365 Day | B | `자율복장 365 Day — ... 자유로운 복장의 문화조성` |

### 건강·의료 (health) — 3행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 30 | `health_check` | 종합건강검진 | A 복리후생 | `건강검진 — 종합건강검진` |
| 31 | `insurance` | 의료비 지원(단체상해·해외출장자 보험) | A 복리후생 | `의료비 지원 — 단체상해/해외출장자 보험` |
| 32 | `fitness` | 사내 피트니스 시설 | A 복리후생 | `직원휴게시설 — 피트니스 시설, ...` |

### 가족·돌봄 (family) — 2행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 40 | `child_edu` | 자녀 학자금 | A 복리후생 | `학자금 — 본인학자금, 자녀학자금` |
| 41 | `family_program` ★신규 | 가족친화 프로그램·가족 테마여행 | A 복리후생 + B | A: `가족친화프로그램 운영 — 여행, 체험활동` / B: `가족 테마여행 지원 — ... 테마별 여행 또는 다양한 레크리에이션 프로그램 등을 운영` |

### 성장·커리어 (growth) — 4행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 50 | `edu_support` | 본인 학자금 | A 복리후생 | `학자금 — 본인학자금, 자녀학자금` |
| 51 | `lang` | 사내 외국어 교육 | A 복리후생 | `어학교육지원 — 사내외국어 교육` |
| 52 | `career` | 멘토링 프로그램 | A 인재교육 | `04 멘토링 프로그램 — 조직 및 업무 적응을 위하여 입사 후 3개월 동안 멘토 (선배사원) - 멘티 (신규사원) 활동 진행` |
| 53 | `self_development` | 사내 교육과정 제도 | A 인재교육 | `교육과정 제도 — ... 온라인/정규집합/맞춤형 집합 등 다양한 교육 방법론을 적용` / `01 기본교육` `02 기술교육` / `03 신입사원 Retention 교육 — 신입사원이 입사하고 3년간 ...` |

### 여가·라이프 (leisure) — 6행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 60 | `club` | 사내 동호회 | A 복리후생 | `사내 동호회 운영` |
| 61 | `resort` | 휴양시설 지원 | A 복리후생 | `휴양시설 지원 — 대명,한화,무주,휘닉스 등` |
| 62 | `massage` | 안마의자 | A 복리후생 | `직원휴게시설 — ... 안마의자 ...` |
| 63 | `culture_day` | 문화가 있는 날 | B | `문화가 있는 날 — 매주 수요일 문화관람을 하는 직원에게 Flexible근무를 허용` |
| 64 | `company_event` | 임직원 행복 이벤트 | B | `임직원 행복 이벤트 실시 — ... 다양한 조직문화 이벤트 (힐링산행, 포차데이 등) 시행` |
| 65 | `overseas_trip` ★신규 | 해외 배낭여행비 지원 | A 복리후생 + B | A: `해외배낭여행비 지원 — 년 3~4명 선발 후 지원` / B: `해외 배낭 여행 지원` |

### 경제적 부가혜택 (perks) — 7행

| SORT | BENEFIT_CD | BENEFIT_NM | 출처 | 원문 발췌 |
|---|---|---|---|---|
| 70 | `meal` | 사내식당 무상 식사 | A 복리후생 | `사내식당 운영 — 조/중/석/간식 무상지급` |
| 71 | `transport` | 교통비 지원 | A 복리후생 | `교통비/통신비 지원 — 직책/직무별 차등 지급` |
| 72 | `telecom` | 통신비 지원 | A 복리후생 | `교통비/통신비 지원 — 직책/직무별 차등 지급` |
| 73 | `commute_subsidy` | 통근버스/셔틀버스 | A 복리후생 | `통근버스/셔틀버스 운영` |
| 74 | `housing_support` | 주거비 지원 | A 복리후생 | `기숙사 운영 — 기숙사, 주거비 지원` |
| 75 | `birthday_gift` | 생일 선물 | A 복리후생 | `선물지급 — 명절, 생일,결혼기념일 등` |
| 76 | `team_dinner` | 크로스 소통(팀 간 운동경기·석식) | B | `크로스 소통 시행 — ... 시행(팀 간 운동경기 및 석식)` |

---

## 5. 금액 정책 (계약 4항)

**금액 명시행 0건.** A·B 어디에도 원·만원·% 단위 금액이 없다. 신규 회사라 승계할 앵커도 없으므로 **전 행** `BENEFIT_AMT=NULL`, `QUAL_YN=TRUE`, `NOTE_CTNT=NULL`, `QUAL_DESC_CTNT` 채움으로 넣었다(DC-9 정성 불변식 충족).

- `해외배낭여행비 지원 — 년 3~4명`은 **인원**이지 금액이 아니다. 금액으로 환산하지 않았다.
- `사내식당 조/중/석/간식 무상지급`은 끼니가 명시되지만 **단가가 없다**. 계약 6항에 따라 금액 없이 정성으로만 수록(다른 회사 단가를 끌어오면 앵커 오염).
- `인센티브 — 성과급`도 배수·금액 미표기라 정성.
- `AMT_SOURCE_CD` 는 계약의 10컬럼 INSERT 에 없어 SQL 에 쓰지 않았다. 전 행 `QUAL_YN=TRUE` 이므로 백필(DG-2)이 `none` 으로 도출한다.

## 6. 신규 코드 2개와 사유 (계약 5항)

| 코드 | 카테고리 | 사유 |
|---|---|---|
| `overseas_trip` | leisure | 계약 어휘에 **해외여행 지원** 개념이 없다. `resort` 는 이미 휴양시설(대명·한화·무주·휘닉스)에 배정됐고, `leisure_ticket` 은 공연·입장권 의미라 부적합. 「년 3~4명 선발」이라는 독립 선발 프로그램이라 다른 행에 흡수시킬 수 없다. |
| `family_program` | family | 계약 family 군(child_edu, childcare, event, fertility_support, parenting, wedding)에 **가족 대상 여행·체험 프로그램**이 없다. `event` 는 기존 시드에서 경조사 의미로 굳었고, `company_event` 는 임직원 행복 이벤트(B)에 배정했다. `family_day` 는 계약이 명시하듯 **조기퇴근** 의미라 금지. |

## 7. 코드 선택 판단 기록 (헷갈릴 만한 것)

- **`insurance` (SORT 31)** — 원문 라벨은 「의료비 지원」이지만 부연이 `단체상해/해외출장자 보험` 뿐이다. 계약 3항의 `insurance = 단체상해보험` 정의에 정확히 들어맞는다. 라벨만 보고 `medical` 을 **추가로** 만들면 같은 한 줄을 두 행으로 부풀리는 과잉 해석이라 1행으로 통합하고, BENEFIT_NM 에 원문 라벨과 실제 내용을 함께 적었다.
- **`edu_support` vs `child_edu`** — 원문 `학자금 — 본인학자금, 자녀학자금` 한 줄이 두 대상을 명시적으로 분리하므로 2행으로 나눴다(본인 → growth, 자녀 → family). 기존 시드 관례와 일치.
- **`transport` / `telecom`** — 원문 `교통비/통신비 지원` 한 줄이 두 항목을 슬래시로 병기. 둘 다 명시라 2행. 조건(`직책/직무별 차등 지급`)은 양쪽 QUAL_DESC 에 그대로 남겼다.
- **`dormitory` / `housing_support`** — 원문 `기숙사 운영 — 기숙사, 주거비 지원`. 주거비 지원이 별도로 명시돼 있어 2행(기숙사는 시설=work_env, 주거비는 현금성=perks).
- **`holiday_gift` / `birthday_gift`** — 원문 `선물지급 — 명절, 생일,결혼기념일 등`. 명절·생일이 명시라 2행. **결혼기념일**은 별도 코드를 만들지 않고 `holiday_gift` 설명에 흡수했다(`wedding` 은 결혼 경조 의미라 결혼**기념일** 선물과 다르다).
- **`fitness` / `massage` / `lounge`** — 원문 `직원휴게시설` 한 줄이 5개 시설을 나열. 성격이 갈리는 피트니스(건강)·안마의자(여가)만 떼고, 나머지 3개(사내 카페테리아·직원 휴게실·옥상하늘정원)는 `lounge` 1행으로 묶었다. `massage` 는 기존 시드 선례가 leisure 4 : health 1 이라 leisure.
- **`culture_day`** — 실질은 수요일 Flexible 근무지만 제도명이 「문화가 있는 날」이고 계약 어휘가 이를 여가군에 두었으며 기존 시드 선례(`culture_day` → leisure)도 있어 leisure. 이 한 건 때문에 `flex_work` 를 따로 만들면 같은 제도가 2행이 된다.
- **`uniform` (자율복장)** — 기존 시드에 `유니폼·복장 → uniform / work_env` 선례가 있어 그대로 따랐다.
- **`career` vs `self_development`** — 멘토링은 기존 시드 선례가 `career`(성장). 사내 교육체계는 `edu_support` 가 본인학자금에 이미 배정돼 `self_development` 로 넣었다.
- **`team_dinner` (크로스 소통)** — 「소통 제도」로 소개되지만 원문이 제공 내용을 `팀 간 운동경기 및 석식` 으로 못박아 놓았다. 그 제공분만 복지로 수록하고 BENEFIT_NM 에 제도명을 함께 남겨 부풀림이 없게 했다.
- 카테고리 배정은 전부 **기존 95개 시드의 다수 관례**(health_check→health, resort→leisure, child_edu→family, meal→perks, edu_support→growth, club→leisure, fitness→health, lang→growth, insurance→health, incentive→compensation, commute_subsidy→perks, excellence_award→compensation, holiday_gift→compensation, dormitory→work_env, transport→perks, lounge→work_env, telecom→perks, birthday_gift→perks, housing_support→perks, team_dinner→perks, company_event→leisure)를 따랐다.

## 8. 의도적으로 **수록하지 않은** 것

| 원문 | 미수록 사유 |
|---|---|
| `연봉제`, `성과평가 / 역량평가 / 다면진단` (A 인사제도) | 평가·임금체계이지 복지가 아니다. |
| `온라인 소통 게시판 운영`, `경영현황 설명회 시행` (B) | 사내 커뮤니케이션·IR 제도. 임직원에게 돌아가는 급부가 없다. |
| `창의적 근무환경 조성 — 직무에 적합한 사무가구 제공` (B) | `work_tools` 는 계약이 **IT장비 의미**로 못박아 부적합. 사무가구만을 위한 신규 코드는 과잉이라 미수록. 같은 문장의 사내 카페테리아 부분만 `lounge` 근거로 보강 사용. |
| `일하는 문화` 9개조 (B) | 행동강령. |
| 4대보험·퇴직연금·법정 연차 | 계약 3항 법정 제도 미수록. 애초에 A·B 에 언급도 없다. |
| 원익그룹 채용포털의 복지 문구 | 자사 도메인이 아니라 배제(§1 참조). |

## 9. 검증 결과

- 로더 분할기(`db/seed/load.py::_split_sql_statements`)로 실제 분할 → **5문장**(INSERT IGNORE TCOMPANY / SET @comp_id / UPDATE / DELETE / INSERT). 정상.
- **주석에 홑따옴표 0개** — 관례상 헤더의 `badge: 'est'` 표기도 따옴표를 빼고 `badge: est` 로 적었다(계약 경고 준수, 분할기 안전).
- BENEFIT_CD 중복 0 (uq_comp_benefit 안전) · 28개 코드 전부 `^[a-z][a-z0-9_]{1,29}$` 통과.
- BENEFIT_CTGR_CD 전부 9종 정본 내. SORT_ORDER_NO 10단위 섹션 오름차순(10~12 / 20~22 / 30~32 / 40~41 / 50~53 / 60~65 / 70~76), CATEGORY_ORDER 순서와 일치.
- DC-9 정성 불변식 위반 0 · QUAL_DESC 누락 0 · BENEFIT_NM ≤100자 · QUAL_DESC ≤500자.
- 저장소 무수정 · DB 미접속(읽기 전용 조회만). 산출물은 이 디렉터리에만 생성.

## 10. 반영 시 주의

- **신규 회사이므로 정적 페이지 재생성이 필수**다(MEMORY: 회사 추가 시 정적 재생성 필수). 회사 상세·디렉터리·비교·히트맵 전부 새 COMP_ID 를 타야 한다.
- 히트맵 `ITEM_LABEL`(generator/pages/heatmap.py)에 `overseas_trip`·`family_program` 이 없다 → 코드의 최빈 `benefit_nm` 으로 자동 라벨링된다. 짧은 묶음 이름을 원하면 매핑 추가를 검토할 것(필수는 아님).
- 이 회사는 **28행 전부 정성**이라 금액 축(히트맵 금액 랭킹 등)에는 기여하지 않는다. 본문 두께 기여는 QUAL_DESC 서술로 들어간다.

---

## 11. 검증 판정 반영 (2026-09-01) — 28행 → 24행

검증·감사가 4건을 **반증 또는 웨이브 공통 규칙 위반**으로 판정했다. 아래대로 반영했다.
새로 만든 문구는 없다 — 병합 문구도 §4 인용표의 원문 발췌를 그대로 옮긴 것이다.

| 조치 | 대상 행 | 사유 |
|---|---|---|
| **삭제** | `uniform` 「자율복장 365 Day」(SORT 22) | **반증**. 원문은 "자유로운 복장의 문화조성"이지 **유니폼(근무복) 지급이 아니다**. `uniform` 으로 넣으면 의미가 정반대로 뒤집혀 비교 축이 오염된다. 복장 자율화는 급부가 아니라 문화 정책 |
| **삭제** | `self_development` 「사내 교육과정 제도」(SORT 53) | **웨이브 공통 규칙** — 회사가 주도·운영하는 교육 *체계*(온라인/정규집합/맞춤형 집합, 기본·기술교육, Retention 교육)는 복지가 아니다. 임직원에 대한 **명시적 비용 지원 문구가 없다** |
| **삭제** | `team_dinner` 「크로스 소통」(SORT 76) | 원문이 규정한 것은 **소통 프로그램**(부서·팀 간 크로스 소통)이고 제공 형태가 운동경기·석식일 뿐, **회식비 지원 제도가 아니다**. `team_dinner`(회식비 지원)로 넣으면 과잉 해석 |
| **병합** | `family_program` 「가족친화 프로그램·가족 테마여행」(SORT 41) → `company_event`(SORT 64) | 회사가 주최·운영하는 임직원(가족 포함) 참여 **행사 프로그램**이라 코퍼스 선례상 `company_event` 가 정확하다. 신규 코드를 만들 근거가 못 된다. 원 서술은 `company_event` 의 `QUAL_DESC` 에 병기했다 |
| **코드 교체** | `overseas_trip` → `travel_support` (SORT 65, 표시명·서술 불변) | 웨이브 내 여행·휴양 지원 코드를 `travel_support` 하나로 통일(현대건설 선례). 행 수 불변, 신규 코드 −1 |

- 결과: **신규 BENEFIT_CD 0개**(`overseas_trip`·`family_program` 둘 다 소멸) — §6 의 신규 코드 표는 무효다.
- `company_event`(SORT 64) 최종 `QUAL_DESC`:
  "힐링산행, 포차데이 등 조직문화 이벤트 시행. 가족친화프로그램(여행, 체험활동) 운영 및 가족 테마여행·레크리에이션 프로그램 지원"
  — 앞부분은 B 원문 `임직원 행복 이벤트 실시 … (힐링산행, 포차데이 등)`,
    뒷부분은 A 원문 `가족친화프로그램 운영 — 여행, 체험활동` + B 원문 `가족 테마여행 지원 — … 테마별 여행 또는 다양한 레크리에이션 프로그램 등을 운영`.
- 삭제 4행은 전부 **각 카테고리 섹션의 마지막 SORT** 였으므로 재번호가 필요 없다. 최종 SORT:
  compensation 10~12 / work_env 20~21 / health 30~32 / family 40 / growth 50~52 / leisure 60~65 / perks 70~75.
  중복 0 · 10단위 섹션 유지.
- 24행 전부 `QUAL_YN=TRUE` · `BENEFIT_AMT=NULL` — 금액 불변식 그대로.
- §7·§8 의 판단 기록 중 `uniform`·`self_development`·`team_dinner`·`family_program` 관련 문단은
  이 절의 판정으로 **대체**된다.
