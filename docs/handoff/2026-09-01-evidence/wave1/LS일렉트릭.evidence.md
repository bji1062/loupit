# LS ELECTRIC (엘에스일렉트릭㈜) — 복지 수집 근거

- 수집일: 2026-09-01
- COMP_ENG_NM: `ls_electric` · COMP_NM: `LS ELECTRIC` · 유형: `large` · INDUSTRY_NM: `전력기기` · LOGO_NM: `L`
- 산출 행 수: **12행** (복리후생 원문 항목 7개 → 축 분리 4건 반영 = 11행 + 인사운영방식 탭 성과급 1행)
- 금액 stated: **0건** (페이지가 금액·일수·지급률을 일절 공개하지 않음 → 전 행 `QUAL_YN=TRUE`, `BENEFIT_AMT=NULL`)
- 신규 BENEFIT_CD: **없음** (12개 전부 계약 §5 정식 어휘)

---

## 1. 사용 URL

| 용도 | URL | 상태 |
|---|---|---|
| **정본 (유일 근거)** | `https://www.ls-electric.com/ko/recruit/intro` | HTTP 200 · 53,317 bytes · `text/html; charset=utf-8` · 정적 HTML |
| robots | `https://www.ls-electric.com/robots.txt` | HTTP 200 |

### 미사용 (의도적 배제)

| URL | 배제 사유 |
|---|---|
| `https://www.lsholdings.com/ko/careers/personnel-system` | **LS그룹 공통**. 페이지 자체가 "복리후생제도는 각 계열사 별 차이가 있을 수 있습니다"라고 명시 → 개별사 귀속 근거로 쓰면 허위. 계약 §6(그룹 공통 복지 개별사 귀속 금지) |
| `https://lselectric.recruiter.co.kr/career/home` | 제3자 ATS 호스팅 도메인(`recruiter.co.kr`). 계약 §1. 더불어 복지 서술 자체가 없음 |
| 사람인 / 캐치 / 인크루트 등 | 계약 §1 금지 출처. 이들에 뜨는 통근버스·구내식당 등은 **공식 페이지에 근거 없음** → 수록하지 않음 |

## 2. robots 확인

```
User-agent:*
Allow: /
Disallow: /ko/upload/
Disallow: /ko/dl/
Disallow: /@mgt
Disallow: /education/data/
Disallow: /ko/@mgt
Disallow: /ko/education/data/
```

→ `/ko/recruit/intro` 는 Disallow 4패턴 어디에도 해당하지 않고 `Allow: /` 적용. **수집 허용.**
UA 위장 없이 기본 curl 로 HTTP 200. 봇 차단 없음.

## 3. 추출 방법 — 탭 혼입 차단

`/ko/recruit/intro` **한 URL에 탭 5개**(WHY LS ELECTRIC / 인재상 / 인사운영방식 / 복리후생 / 인재육성)가
전부 서버 렌더되어 한 문서에 들어 있다. 문서 전체를 긁으면 인재상·인재육성 문구가 복지로 섞인다.

→ HTML 주석 쌍 `<!-- 복리후생 -->` … `<!--// 복리후생 -->` 으로 **먼저 블록을 잘라낸 뒤**
(추출 블록 2,236 bytes) 그 안의 `p.tit` / `div.desc` 페어 7개만 사용했다.
아래 인용문은 전부 그 블록 내부에서만 나온 것이다.

블록 리드 문구(참고, 행 생성 안 함): "LS ELECTRIC은 사원 개개인이 LS ELECTRIC을 자랑스러운 일터로
생각하고, 가정과 직장에서 보람있는 생활을 영위할 수 있도록 실질적인 지원과 혜택을 제공해 드리고 있습니다."

## 4. 원문 항목 7개 (블록 내 `p.tit` / `div.desc` 원문)

| # | 제목 (`p.tit`) | 설명 원문 (`div.desc`) |
|---|---|---|
| 1 | 주택지원 제도 | 주택마련  자금 및 전세 자금 지원 및 지방사업장 근무시 기숙사/사택 제공 |
| 2 | 건강진단/의료비지원 | 임직원 및 배우자의 종합검진과 가족 의료비를 지원 |
| 3 | 경조사 지원 | 각종 경조사별 경조금, 화환 및 경조휴가 지원 |
| 4 | 휴양소 운영 | 임직원의 여가생활을 위하여 휴양시설 운영 |
| 5 | 학자금 지원 | 자녀교육에 따른 경제적 부담을 덜어주기 위한 중학교, 고등학교, 전문대학, 대학교 취학자녀에 대한 학자금 지원 |
| 6 | 장기근속상 | 장기근속에 따른 휴가 및 여행 혹은 포상금 지원 |
| 7 | 사원복지카드 | 기념일(생일 혹은 결혼기념일), 명절(설/추석) 맞이 복지포인트 지급 |

## 5. 행별 근거 대응표 (12행)

| SORT | BENEFIT_CD | 카테고리 | BENEFIT_NM | 근거 원문(항목 #) | 근거 문구 |
|---|---|---|---|---|---|
| 10 | `long_service_bonus` | compensation | 장기근속 포상 | #6 | "장기근속에 따른 … **여행 혹은 포상금 지원**" |
| 11 | `incentive` | compensation | 경영성과급(PS)·개별성과급(PI) | 인사운영방식 탭 | "경영성과급(PS) — **조직 실적에 따른 성과급 지급**" / "개별성과급(PI) — **성과가 뛰어난 사원에게 별도의 인센티브 지급**" |
| 20 | `dormitory` | work_env | 기숙사/사택 | #1 | "**지방사업장 근무시 기숙사/사택 제공**" |
| 30 | `long_service_leave` | time_off | 장기근속 휴가 | #6 | "장기근속에 따른 **휴가** … 지원" |
| 31 | `leave_general` | time_off | 경조휴가 | #3 | "각종 경조사별 … **경조휴가 지원**" |
| 40 | `health_check` | health | 종합건강진단 | #2 | "**임직원 및 배우자의 종합검진**" |
| 41 | `medical` | health | 가족 의료비 지원 | #2 | "**가족 의료비를 지원**" |
| 50 | `event` | family | 경조사 지원 | #3 | "각종 **경조사별 경조금, 화환**" |
| 51 | `child_edu` | family | 자녀 학자금 지원 | #5 | "**중학교, 고등학교, 전문대학, 대학교 취학자녀에 대한 학자금 지원**" |
| 60 | `resort` | leisure | 휴양소 | #4 | "임직원의 여가생활을 위하여 **휴양시설 운영**" |
| 70 | `housing_loan` | perks | 주택자금 지원 | #1 | "**주택마련 자금 및 전세 자금 지원**" |
| 71 | `welfare_point` | perks | 사원복지카드 | #7 | "기념일(생일 혹은 결혼기념일), 명절(설/추석) 맞이 **복지포인트 지급**" |

### 1항목 → 2행 분리한 4건과 그 사유

원문 4개 항목이 **성격이 다른 두 축을 한 문장에 묶어** 서술한다. 코드 어휘가 이미 두 축을
분리해 두고 있고 카테고리도 갈리므로, 한 행에 뭉치면 비교 축이 오염된다.

| 원문 항목 | 분리 결과 | 사유 |
|---|---|---|
| #1 주택지원 제도 | `housing_loan`(perks) + `dormitory`(work_env) | 자금 지원 vs 주거시설 제공. 카테고리 자체가 다름 |
| #2 건강진단/의료비지원 | `health_check` + `medical` (둘 다 health) | 제목이 이미 "건강진단**/**의료비지원" 두 제도. 대상도 다름(본인·배우자 검진 / 가족 의료비) |
| #3 경조사 지원 | `event`(family) + `leave_general`(time_off) | 현금·화환 vs 휴가. 계약 §5 어휘에서 휴가는 time_off 축 |
| #6 장기근속상 | `long_service_bonus`(compensation) + `long_service_leave`(time_off) | 계약 §5가 `long_service_leave`에 **"(휴가만)"** 이라 명시 → 포상금은 별도 코드로 가야 함 |

### 분리하지 않은 것

- **#7 사원복지카드**는 생일·결혼기념일·명절을 **하나의 카드로 지급되는 복지포인트**라고 서술한다.
  `birthday_gift` / `holiday_gift` 로 쪼개면 별개 제도가 3개 있는 것처럼 보이므로 `welfare_point` 1행 유지.

## 5-b. 검증 판정 반영 (2026-09-01): 인사제도 탭 성과급 1행 추가 (11 → 12행)

검증이 「인사운영방식」 탭의 **성과급 제도**를 누락(MISSED)으로 판정했다. 임금 체계(연봉제)나
평가·승진 제도는 복지가 아니지만, **제도명이 붙은 성과급·인센티브 지급**은 코퍼스에서
`incentive`(compensation)로 일관되게 수록되어 온 급부라 추가한다.

원문(정본 `/ko/recruit/intro` 인사운영방식 탭, 「능력과 성과주의 — 인사 Direction」 블록) 인용:

| 원문 제목 | 원문 설명 (인용) |
|---|---|
| 경영성과급(PS) | "조직 실적에 따른 성과급 지급" |
| 개별성과급(PI) | "성과가 뛰어난 사원에게 별도의 인센티브 지급" |

- 두 제도는 **같은 성과급 축**(PS=조직 실적 / PI=개인 성과)이라 `incentive` **1행**으로 합쳤다.
  코드가 하나뿐이라 회사 내 `uq_comp_benefit` 상 2행으로 쪼갤 수도 없다.
- **지급률·배수·금액이 전혀 없다** → `QUAL_YN=TRUE`, `BENEFIT_AMT=NULL`(계약 §4). 앵커 오염 없음.
- 같은 블록의 **연봉제**("개인의 성과를 바탕으로 연봉이 결정되는 개별 연봉제 방식")와
  **직무역량급 및 수시 포상**("수행 직무 및 고성과자에 대한 차별적 포상"),
  `Job Title`(Manager 직급 통일)·`Pay Grade 제도`는 **임금·직급 체계 서술**이라 그대로 미수록이다
  — 급부의 형태·대상이 특정되지 않아 행을 만들면 근거 없는 행이 된다(계약 §2).
- SORT: compensation 섹션 10·11. 나머지 섹션(20 / 30·31 / 40·41 / 50·51 / 60 / 70·71)은 불변.

## 6. 계약 준수 확인

- **§3 법정 제도 미수록**: 4대보험·법정 퇴직연금·법정 연차·주5일 해당 항목 원문에 없음 → 생성 0건.
  `leave_general`(경조휴가)는 근로기준법상 법정휴가가 아닌 회사 재량 제도이므로 수록 대상.
- **§4 금액**: 블록 내 숫자+단위(만원/원/일/회/%) 패턴 **0건** — 정규식 검사로 확인.
  신규 회사라 앵커도 없으므로 추정 금액을 만들지 않았다. 11행 전부 `QUAL_YN=TRUE` + `QUAL_DESC_CTNT`,
  `BENEFIT_AMT=NULL`, `NOTE_CTNT=NULL`.
- **§5 어휘**: 12개 코드 전부 정식 어휘. **신규 snake_case 코드 없음.**
  각 코드의 카테고리는 기존 시드 전체의 지배적 배정과 100% 일치(대조 확인:
  `long_service_bonus`→compensation 6/6, `long_service_leave`→time_off 44/44,
  `leave_general`→time_off 22/22, `housing_loan`→perks 57/57, `dormitory`→work_env 20/20,
  `health_check`→health 89/89, `medical`→health 48/48, `event`→family 91/91,
  `child_edu`→family 68/68, `resort`→leisure 78/78, `welfare_point`→perks 66/66).
- **§6 meal**: 공식 페이지에 식대·구내식당 서술 **없음** → `meal` 행 생성 안 함
  (취업포털에는 구내식당이 뜨지만 출처 규칙 위반이라 미채택).
- **§8 주석 홑따옴표**: `--` 주석 줄 전체에 `'` **0개** (검사 통과). 로더 분할기 안전.
- **코드 중복(UNIQUE)**: 12행 코드 전부 유일. `SORT_ORDER_NO` 10단위 섹션, 단조 증가.

## 7. 부수 관측

- **공식 이메일 도메인: 미관측.** `/ko/recruit/intro` 원본에 `mailto:` 링크 0건, 이메일 주소 패턴 0건.
  `/ko/company/contact`, `/ko/recruit/notice` 는 404. → evidence 에 기록할 이메일 도메인 없음.
  (참고: 공식 웹 도메인은 `ls-electric.com`. 회사메일 도메인 추정은 근거 없어 기록하지 않음.)
- 페이지 스택: ASP.NET MVC, HSTS, 리다이렉트 없음. 탭 UI는 jQuery `display` 토글이라
  **탭 클릭 없이 전체 콘텐츠가 초기 DOM에 존재** → 재수집 시에도 JS 렌더링 불필요.
- 기존 시드에 `ls`(LS, 전선/전력) 행이 이미 있으나 **별개 회사**. `ls_electric` 은 신규이며 충돌 없음.
- 재수집 시 유일한 주의점: 탭 5개가 한 URL이라는 것. **반드시 `<!-- 복리후생 -->` 주석 블록을 먼저 자를 것.**

## 8. 콘텐츠 분량 참고

설명문이 전부 서술문이고 정량 수치가 없어 본문 분량 기여는 중간 수준.
금액 0건이므로 회사 상세 페이지에서 금액 밴드·환산 총액에는 기여하지 않는다.

---

## 9. 실제 로더·파서로 검증한 결과 (DB 미접속, 순수 파싱)

저장소의 **진짜 함수**를 import 해서 이 파일을 통과시켜 본 결과:

| 검사 | 함수/위치 | 결과 |
|---|---|---|
| 문장 분할 | `db/seed/load.py::_split_sql_statements` | **5문장** (기대치와 일치) |
| 주석 따옴표 | 위 분할기가 `--` 주석을 모름 → `'`/`"` 홀수 개면 파일 전체가 1문장으로 붙어 ProgrammingError | `--` 줄 내 `'`·`"` **0개** |
| 자기등록 헤더 | `db/seed/company_meta.py::parse_header_insert` | `('ls_electric', 'LS ELECTRIC', 'large')` 정상 추출 |
| 수집일 헤더 | `db/seed/backfill_dec2.py::_DATE_RE` | `2026-09-01` 매치 |
| 출처 URL 헤더 | `db/seed/backfill_dec2.py::_URL_RE` | `https://www.ls-electric.com/ko/recruit/intro` 매치 |
| 금액 신뢰도 도출 | `db/seed/backfill_dec2.py::derive_amt_source` | 12행 전부 **`none`** (QUAL_YN=TRUE ⇒ none) |

→ `QUAL_YN=TRUE ⇒ BENEFIT_AMT IS NULL AND AMT_SOURCE_CD='none'` 불변식(SB-3 / DC-9) 충족.
→ `BADGE_CD='est'` 로만 넣었으므로 `DELETE ... WHERE BADGE_CD='est'` 멱등 계약(SM-3/SM-4) 유지.
→ 금액 stated 0건이라 앵커 강등 규칙(같은 code+amount 를 3개사 이상이 stated 로 쓰면 estimated 강등)과 무관.

## 10. ⚠ 이 파일만으로는 안 끝난다 — 상위(통합) 작업 필요 항목

파일을 `db/seed/benefit/sql/` 에 넣기만 하면 로더는 자동으로 집어간다(매니페스트 없음, glob 방식).
그러나 **아래는 자동이 아니며, 손대지 않으면 기존 테스트가 깨진다.** 나는 저장소를 읽기만 했으므로 미수행.

### (a) 반드시 깨지는 테스트 핀 (숫자 갱신 필요)

| 테스트 | 현재 핀 | 신규 회사 1곳 추가 후 |
|---|---|---|
| `test_seed_counts.py::test_SD3_company_count_is_102` | 102 | **103** |
| `test_seed_integrity.py::test_SI8_company_count_not_200` | 102 | **103** |
| `test_seed_idempotency.py::test_SM1_repeated_full_run_is_stable` | 102 | **103** |
| `test_seed_counts.py::test_SD4_benefit_total_row_count` | 1553 | **1565** (= 1553 + 12) |

### (b) `-- URL:` 헤더 때문에 깨지는 테스트

`-- URL:` 헤더가 있으면 백필이 이 회사 전 행을 `BADGE_SRC_CD='scrape_official'` 로 찍는다.
`test_seed_badge_backfill.py::test_SB10_scrape_official_companies_have_url` 는 `scrape_official` eng 집합을
**열거형으로 고정**(현재 21개)하고 있어, **`ls_electric` 을 `real_url_engs` 에 추가하지 않으면 실패**한다.
(URL 헤더는 계약이 요구한 것이므로 빼지 않았다 — 테스트 쪽을 갱신하는 것이 맞다.)

부수 효과(정상): `VERIFIED_DTM = 2026-09-01 00:00:00`, `EXPIRES_DTM = +18개월 = 2028-03-01`.

### (c) 동반 등록 (`docs/PLAN-회사확장-2026-09-01.md` §3 체크리스트)

| # | 대상 | 필요성 |
|---|---|---|
| 1 | `db/seed/company_meta.py` 별칭 오버라이드 | **사실상 필수** — 없으면 검색이 못 찾는다(경고 로그만 뜨고 조용히 지나감). `LS일렉트릭`, `엘에스일렉트릭`, `LS ELECTRIC`, `LS전산` 등 검토. `test_SD6_every_company_has_alias` 가 회사당 별칭 ≥1 요구 |
| 2 | `db/seed/corp_code_map.csv` 1행 | DART 재무·직원 지표 연동. 미등록 시 「연도별 추이」 없음. `test_corp_load.py` 핀(101/100)도 확인 필요 |
| 3 | `generator/data/krx_sector.csv` 1행 (STOCK_CD 키) | 섹터 분류. ⚠ **LS ELECTRIC 종목코드는 이번 수집 범위에서 확인하지 않았다** — 별도 확인 후 기입할 것. 저장소에 이미 있는 `006260 / LS / 기타금융 / KOSPI` 는 **지주사 LS 이고 별개 회사**이니 재사용 금지 |
| 4 | `db/seed/company_email_domain.sql` | 선택. **이메일 도메인 미관측이라 근거 없음 → 추가 보류 권장** (§7 참조) |
| 5 | `generator/data/combinations.json` | 선택(비교 조합 레일) |
| 6 | **정적 페이지 재생성** | 회사 추가 시 필수 |

### (d) 하지 말 것

`db/seed/reingest_benefit_sql.py` 는 `assert written == 95` 가 박힌 일회성 과거 마이그레이션이며
`load.py` 경로가 아니다. **실행하면 시드 디렉터리를 덮어쓴다.**
