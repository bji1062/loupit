# 웨이브 1 코퍼스 횡단 감사 — 통합 준비 데이터

- 감사일: 2026-09-01 · 읽기 전용(저장소 무변경)
- 대상: `…/scratchpad/wave1/{고려아연,현대건설,LS일렉트릭,원익IPS,LGCNS,엘앤에프,하나마이크론,심텍,한국타이어,KB금융,HD현대}.sql` (11파일)
- 기준: 기존 코퍼스 `/home/ubuntu/loupit/db/seed/benefit/sql/*.sql` 102파일 · 1,553행 · 코드 74종
- 재현: `python3 …/scratchpad/wave1/_audit2.py` (`load._split_sql_statements` · `company_meta.parse_header_insert`/`_row_chunks` · `generator.slug.slug_of` 실제 임포트)

## 0. 한 줄 요약

| 항목 | 결과 |
|---|---|
| 구조 문제 | **2건** (BLOCK 1 · MED 1) — 그 외 전 항목 통과 |
| 신규 BENEFIT_CD | **17종** (과제 명시 12 + **누락 5 = HD현대**) → 권고 반영 시 **9종** |
| 어휘 판정 | 유지 9 · 흡수 5 · 통합 3(→1) |
| 회사 간 일관성 문제 | **6건** (신규 11 내부 4 · 코퍼스 대비 2) |
| 신규 행 수 | 203행 (권고 병합 2건 반영 시 **201행**) |
| SD-4 새 기대값 | 1553 + 203 = **1756** / 권고 반영 시 **1754** |
| SD-3 · SI-8 · SM-1 | 102 → **113** |
| SB-10 추가 eng | **11종 전부** (11파일 모두 실 http URL 헤더) |
| 이메일 도메인 | 추가 6 · 보류(@rejected) 2 · 미관측 3 — SED 가드 충돌 **0** |

---

## 1. 신규 BENEFIT_CD 심사

### 1-0. 먼저: 과제 목록이 5종을 빠뜨렸다

과제가 명시한 12종 외에 **HD현대에서만 5종이 더 신규**다. 코퍼스 74종 대조 결과 신규는 총 **17종**이다.

> 누락분: `workation` · `free_seating` · `office_furniture` · `family_card` · `fuel_support` (전부 HD현대)

HD현대는 신규 11개사 중 신규코드 최다(5종/20행)이면서 유일하게 **그룹 통합 채용 페이지**를 근거로 삼은 파일이다. 어휘 심사와 별개로 귀속 리스크가 가장 큰 파일이라는 뜻이기도 하다(전 행 설명 말미에 "(그룹 통합 채용 기준) 계열사 간 일부 상이 가능" 부기 — 정직하나, 지주 단독 복지가 아님을 스스로 밝힌다).

### 1-1. 판정 요약표

| 코드 | 회사 | 판정 | 이동처 | 근거 |
|---|---|---|---|---|
| `travel_support` | 현대건설 | **통합 기준코드로 유지** | — | 여행·휴양 3종의 수용처 |
| `overseas_trip` | 원익IPS | **통합** | → `travel_support` | 동일 성격(회사 부담 여행경비) |
| `vacation_program` | KB금융 | **통합** | → `travel_support` | 동일 성격, KB는 `resort` 별도 보유라 코드 필요 |
| `summer_vacation_subsidy` | 심텍 | **통합(권장)** | → `travel_support` | 하계휴가비=휴가 비용 지원. 대안 `holiday_gift`는 라벨 왜곡 |
| `child_entrance_gift` | 심텍 | **흡수** | → `child_edu` 행 병합 | 아이센스 `child_edu`='자녀 입학축하금' 선례 + 코퍼스 '자녀학자금/입학축하금' 단일행 선례 |
| `family_program` | 원익IPS | **흡수** | → `company_event` 행 병합 | 삼성카드 `company_event`='가족친화 프로그램' **직접 선례** · KB '패밀리데이'도 company_event |
| `office_furniture` | HD현대 | **흡수** | → `work_tools` | 코퍼스 `work_tools`에 '스탠딩 책상'(kakao_bank) · '최신 맥북/스탠딩데스크'(kakao_pay) 선례 |
| `fuel_support` | HD현대 | **흡수** | → `transport` | 코퍼스 `transport`에 '유류대'(yuhan)·'KTX 비용'(s_oil)·'대리운전비'(jusung) 선례 |
| `family_card` | HD현대 | **흡수(선택)** | → `discount` 행 병합 | 둘 다 임직원 할인 혜택. 유지도 방어 가능(연회비 지원 = 현금성) |
| `overseas_safety` | 현대건설 | **유지** | — | 흡수처 없음(현대건설은 `insurance`·`medical` 이미 보유). 건설·플랜트·상사에 재현성 |
| `welfare_fund_loan` | 현대건설 | **유지** | — | `housing_loan` 흡수는 **원문 왜곡**(용도 미공개). 사내근로복지기금은 대기업 보편 제도 |
| `blood_bank` | 심텍 | **유지** | — | `clinic`(부속의원)·`medical`(의료비) 어느 쪽도 아님. 저가치 싱글턴임을 명시 |
| `car_wash` | 한국타이어 | **유지** | — | `parking`≠세차. 사업장 편의시설 특수 항목 |
| `car_rental` | LGCNS | **유지** | — | 흡수처 없음(LGCNS `discount`는 가전 할인으로 점유) |
| `promotion_gift` | LGCNS | **유지** | — | `holiday_gift` 흡수 시 히트맵 라벨('명절 선물')이 승진 선물을 잘못 표기 |
| `workation` | HD현대 | **유지** | — | `remote_work`·`satellite_office` 모두 HD현대가 이미 보유. 별개 제도 |
| `free_seating` | HD현대 | **유지** | — | work_env 기존 6종 어디에도 안 맞음. 대기업 확산 제도라 재현성 있음 |

**결과: 신규 17종 → 유지 9종**(`travel_support` `overseas_safety` `welfare_fund_loan` `blood_bank` `car_wash` `car_rental` `promotion_gift` `workation` `free_seating`), `family_card` 유지 시 10종.

### 1-2. 여행·휴양 3종 통합(과제 지정 1순위) — 상세

세 코드는 전부 `leisure` 카테고리이고, 셋 다 기존 `resort`(휴양**시설** 이용, 코퍼스 78회)로는 표현 불가하다(세 회사 중 현대건설·KB금융은 `resort` 행을 이미 별도로 갖고 있어 흡수 자체가 UNIQUE 위반).

```
현대건설  travel_support     해외여행 지원        2년 해외근무 시 본인·배우자 해외여행 지원
원익IPS   overseas_trip      해외 배낭여행비 지원   년 3~4명 선발 후 지원
KB금융    vacation_program   휴양프로그램         하계 성수기 임직원·가족 휴양 프로그램
심텍      summer_vacation_subsidy  하계휴가비     지급액·시기 미기재
```

→ **`travel_support` 하나로 통합**(정의: "회사가 비용을 부담하는 여행·휴양 프로그램/지원금"). 각 사의 `BENEFIT_NM`·설명이 차이를 그대로 보존하므로 정보 손실이 없고, 히트맵은 3~4타일 묶음 1개, 비교표는 같은 행에 정렬된다. 싱글턴 3~4개로 두면 **어느 쌍에서도 비교가 성립하지 않는다**(`web/assets/js/report.js:161` — `const key = item.benefit_cd || item.benefit_nm`).

- 잔여 리스크: 심텍 하계휴가비는 현금성이라 `compensation` 해석 여지가 있다. 다만 심텍 파일이 이미 `leisure`로 뒀고, 코퍼스 `holiday_gift`(명절·기념일 선물)에 넣으면 ITEM_LABEL이 '명절 선물'로 찍혀 화면이 거짓말을 한다. → `travel_support` 권장, 반대 결정 시 **코드 유지**(흡수 금지).

### 1-3. `child_entrance_gift` — 선례 충돌 확정

- 배치1 아이센스: `(@comp_id, 'child_edu', '자녀 입학축하금', …)` (아이센스.sql L68)
- 코퍼스: `'child_edu', '자녀학자금/입학축하금'` 단일행 선례 존재
- 웨이브1 고려아연: 입학축하금을 `child_edu` 설명 안에 포함(`'…자녀 학자금 지원, 중·고등학교 입학축하금, …'`)

심텍만 별도 코드로 분리했다. 심텍은 `child_edu`(자녀대학교 학자금) 행을 이미 갖고 있어 **코드를 살리려면 2행, 선례를 따르려면 1행**이다.

→ **흡수**: 심텍 `child_edu` 행의 `BENEFIT_NM`을 `자녀 학자금·입학축하금`으로, 설명에 두 라벨 원문을 병기. 심텍 18행 → 17행.

### 1-4. `family_program` — 삼성카드 선례와 정면 충돌

코퍼스 `company_event`(3회) 중 **삼성카드 = '가족친화 프로그램'** 이다. 원익IPS가 같은 말을 새 코드로 만들었고, 심지어 원익IPS는 `company_event`('임직원 행복 이벤트') 행도 따로 갖고 있다.

→ **흡수**: 원익IPS의 두 행을 `company_event` 하나로 병합(`BENEFIT_NM`='임직원·가족 행복 프로그램', 설명에 힐링산행/포차데이 + 가족 테마여행 병기). 원익IPS 28행 → 27행.
(대안: 가족 테마여행만 `travel_support`로 분리 — 원문이 "가족친화프로그램(여행, 체험활동)" 한 항목이라 **비권장**.)

---

## 2. 회사 간 코드 일관성 (전수)

### 2-1. 카테고리 배정 — 편차 0

신규 203행 중 기존 코드를 쓴 행 **전부**가 코퍼스 최빈 카테고리와 일치했다. (`massage`→leisure, `welcome_kit`→leisure, `holiday_gift`→compensation, `uniform`→work_env, `culture_day`→leisure, `housing_support`→perks 등 소수 코드까지 포함)

### 2-2. 같은 성격 → 다른 코드 (문제 6건)

| # | 성격 | 갈라진 코드 | 회사 | 심각도 | 권고 |
|---|---|---|---|---|---|
| C-1 | **통근버스** | `commute_subsidy` ×6 vs `transport` ×1 | 원익IPS·LGCNS·엘앤에프·하나마이크론·심텍·한국타이어 / **HD현대** | **HIGH** | HD현대 통근버스 → `commute_subsidy` |
| C-2 | **개인 유류·교통비** | `transport` ×2 vs `fuel_support` ×1 | 현대건설·원익IPS / **HD현대** | **HIGH** | HD현대 유류비 → `transport` (C-1과 한 쌍으로 처리) |
| C-3 | **가족친화 프로그램** | `company_event` ×3 vs `family_program` ×1 | LGCNS·KB금융·원익IPS / **원익IPS** | **HIGH** | §1-4 흡수 |
| C-4 | **자녀 입학축하금** | `child_edu` 내포 ×2 vs `child_entrance_gift` ×1 | 고려아연·(아이센스) / **심텍** | **HIGH** | §1-3 흡수 |
| C-5 | **여행·휴양 지원** | `travel_support`/`overseas_trip`/`vacation_program`/`summer_vacation_subsidy` | 현대건설·원익IPS·KB금융·심텍 | **HIGH** | §1-2 통합 |
| C-6 | **안마의자** | `massage` ×1 vs `lounge` 내포 ×1 | 원익IPS / 엘앤에프 | LOW | **무변경**. 코퍼스도 massage/lounge/nap_room 3분할(선재 부채). 엘앤에프 행은 '공장 편의시설(휴게실·안마의자)' 복합이라 `lounge`가 맞다 |

### 2-3. 문제 아님으로 판정한 분기(기록)

- **사내식당 vs 사내카페**: `meal`(식사 제공) / `snack_bar`(카페·무인매점·칸틴) 구분이 신규 6개사 전부 코퍼스 관례와 일치. KB금융 '사내식당·사내카페'를 `meal` 한 행으로 묶은 것도 원문이 한 항목이라 정합.
- **주거**: `dormitory`(사택·기숙사, work_env) / `housing_loan`(대출) / `housing_support`(임차·주거비) 3분할이 7개사에서 일관.
- **경조사**: `event`(경조금·화환) / `leave_general`(경조휴가)를 LS일렉트릭만 2행으로 분리 — 원문이 두 항목이라 정합.
- **장기근속**: `long_service_bonus`(포상금·기념품) / `long_service_leave`(휴가) 분리가 LS일렉트릭·엘앤에프에서 일관. ⚠ 다만 코퍼스에 **`long_service`(효성중공업 '장기근속 포상', time_off) 유령 코드 1건**이 이미 있다 — 웨이브1과 무관한 선재 부채, 별도 정리 권고.
- **학자금**: `child_edu`(자녀) / `edu_support`(본인) 분리가 원익IPS·LGCNS에서 일관.
- **어린이집**: `childcare`(사내 시설) / `child_edu`(외부 유치원 학자금) 분리 — 한국타이어가 둘 다 보유하며 원문 구분과 일치.
- **원익IPS `dormitory` + `housing_support`**: 원문 한 항목("기숙사 운영 및 주거비 지원")을 2행으로 분할. 시설 vs 현금이라 분리가 낫다. LOW, 무변경.
- **심텍 `resort`(콘도) + `company_event`(야유회)**: 원문 라벨 "콘도 및 야유회" 분할. 헤더 주석에 16라벨→18행 근거가 적혀 있어 추적 가능. 무변경.

---

## 3. 구조 전수 검증

### 3-1. 통과 항목 (11파일 전부)

| 검사 | 방법 | 결과 |
|---|---|---|
| 골격 5문장 | `load._split_sql_statements` 실행 | **11/11 = 5문장** |
| 문장 순서·종류 | 주석 제거 후 선두 토큰 대조 | INSERT IGNORE TCOMPANY → SET @comp_id → UPDATE TCOMPANY → DELETE FROM TCOMPANY_BENEFIT → INSERT INTO TCOMPANY_BENEFIT **전부 일치** |
| `parse_header_insert` | `company_meta` 실 임포트 | 11/11 통과, (eng, 한글명, 유형) 추출 성공 |
| REGDATA 대조 | COMP_NM·COMP_ENG_NM | **11/11 정확 일치** (LS ELECTRIC / LG CNS / 한국타이어앤테크놀로지 포함) |
| 10컬럼 | 엄격 정규식 vs `_row_chunks` 개수 | 203 = 203 **전 행 형식 일치** |
| BENEFIT_CD 중복(UNIQUE) | 회사 내 | **0건** |
| SORT 중복 | 회사 내 | **0건** |
| SORT 단조 | 회사 내 | **11/11 단조 증가** |
| 카테고리 9종 도메인 | 전 행 | **203/203 유효** |
| BADGE_CD='est' | 전 행 | **203/203** (DELETE est 재실행 안전성 유지) |
| QUAL_YN ↔ AMT 불변식 | TRUE→AMT NULL·QUAL_DESC 有·NOTE NULL / FALSE→AMT 有·NOTE 有·QUAL_DESC NULL | **위반 0건** |
| VARCHAR 길이 | CD30·NM100·NOTE200·QUAL_DESC500·ENG30·COMP_NM100·INDUSTRY50·LOGO10·URL500 | **초과 0건** |
| slug 충돌 | `generator.slug.slug_of`, 기존 102 + 신규 11 = 113 상호 | **충돌 0건** |
| eng/COMP_NM 기존 충돌 | 코퍼스 102 대조 | **0건** |
| DELETE est 표준형 | 문자열 완전 일치 | 11/11 |
| ON DUPLICATE KEY UPDATE | 존재 | 11/11 |
| URL 3중 일치 | 헤더 주석 = INSERT = UPDATE | 11/11 |
| 헤더 `-- 출처: AI 파싱 (2026-09-01)` | 백필 VERIFIED_DTM 근거 | 11/11 |
| 헤더 `-- URL: http…` | 백필 scrape_official 근거 | 11/11 |
| 앵커 강등(SI-M4) 위험 | (child_edu, 600) 코퍼스 대조 | **0건** — HD현대 유일 금액행은 `stated` 유지 |
| `benefit_edit` 코드 정규식 | `^[a-z][a-z0-9_]{1,29}$` | 신규 17종 전부 통과 |

### 3-2. 문제 2건

| 심각도 | 파일 | 내용 |
|---|---|---|
| **BLOCK** | 고려아연.sql L5 | 주석에 홑따옴표 4개 — `-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)`. 계약 명시 금지 사항. **현재는 따옴표가 짝수라 우연히 5문장으로 정상 분할되지만**, `_split_sql_statements`는 주석을 모르므로 이 구간 안의 `;`는 문자열로 보호돼 삼켜진다. 나머지 10파일은 전부 따옴표 없이 `-- badge: est …`로 썼다 → 고려아연만 고치면 된다 |
| MED | 심텍.sql | SORT_ORDER_NO가 `1, 2`로 시작(나머지는 40·41…). 계약의 "SORT 10단위 섹션" 이탈. 표시 순서 자체는 정상(단조)이라 기능 영향 없음 → `10, 11`로 교정 권고 |

---

## 4. 통합 산출

### 4-a. 회사별 행 수 · SD-4 새 기대값

| 회사 | eng | 유형 | 행 | 금액 stated | 신규코드 | 권고 반영 후 행 |
|---|---|---|---:|---:|---:|---:|
| 고려아연 | `korea_zinc` | large | 12 | 0 | 0 | 12 |
| 현대건설 | `hyundai_enc` | large | 12 | 0 | 3 | 12 |
| LS일렉트릭 | `ls_electric` | large | 11 | 0 | 0 | 11 |
| 원익IPS | `wonik_ips` | mid | 28 | 0 | 2 | **27** |
| LGCNS | `lg_cns` | large | 25 | 0 | 2 | 25 |
| 엘앤에프 | `landf` | mid | 20 | 0 | 0 | 20 |
| 하나마이크론 | `hana_micron` | mid | 14 | 0 | 0 | 14 |
| 심텍 | `simmtech` | mid | 18 | 0 | 3 | **17** |
| 한국타이어 | `hankook_tire` | large | 22 | 0 | 1 | 22 |
| KB금융 | `kbfg` | large | 21 | 0 | 1 | 21 |
| HD현대 | `hd_hyundai` | large | 20 | **1** | 5 | 20 (family_card 흡수 시 19) |
| **합계** | | | **203** | **1** | 17 | **201** (또는 200) |

- **SD-4**: `1553 + 203 = 1756` → **권고(§1-3·1-4) 반영 시 `1553 + 201 = 1754`**, family_card까지 병합 시 1753.
  `server/tests/test_seed_counts.py:55` 의 값·독스트링 내역 문단을 함께 갱신할 것.
- **SD-3 / SI-8 / SM-1**: `102 → 113` (`test_seed_counts.py:33`, `test_seed_integrity.py:161`, 멱등성 스냅샷)
- **금액 stated 1건**: HD현대 `child_edu` 600만원(월 50만원 명시). note에 '추정'·'환산' 미포함 → `derive_amt_source`가 `stated` 반환 ✔. 코퍼스에 (child_edu, 600) 부재라 M-4 앵커 강등도 안 걸린다 ✔.
- **GC-2**: REGDATA 계획대로 "정확히 200 BuildError" → "복지 0행 회사 존재 시 BuildError"로 교체 필요(회사 113개).

### 4-b. SB-10 추가 eng — **11종 전부**

`test_seed_badge_backfill.py:164` `real_url_engs` 집합에 아래 11개를 추가해야 한다. 11파일 모두 `-- URL: https://…` 실 URL 헤더를 가져 백필이 `BADGE_SRC_CD='scrape_official'`로 분류한다. **추가하지 않으면 SB-10이 반드시 빨개진다.**

```python
    # 웨이브 1 신규 회사(2026-09-01, 11) — 자사/그룹 공식 채용·복지 페이지 URL
    "korea_zinc", "hyundai_enc", "ls_electric", "wonik_ips", "lg_cns", "landf",
    "hana_micron", "simmtech", "hankook_tire", "kbfg", "hd_hyundai",
```

- 결과: scrape_official 회사 22 → **33**.
- ⚠ 3개사는 위탁 ATS 도메인이 정본 URL이다 — `hanamicron.recruiter.co.kr` · `hankooktire.recruiter.co.kr` · `careers.kbfg.com`(그룹 통합) · `recruit.hd.com`(그룹 통합). 계약 §1의 "공식 홈에서 링크된 브랜드 ATS" 예외로 evidence에 근거가 적혀 있으나, `scrape_official` 배지가 "자사 도메인"을 뜻한다고 읽는 사람이 있으면 오해 소지가 있다. 테스트 주석에 한 줄 남길 것.

### 4-c. REGDATA 계획 대비 누락·불일치

| # | 항목 | 판정 | 상세 |
|---|---|---|---|
| R-1 | `corp_code_map.csv` **comp_id 103~113** | **충돌** | 기존 CSV는 이미 `103 = CJ프레시웨이`. 실제 사용 id는 1~103(96번 결번, 102행). 조인은 **이름 기준**이라 기능 장애는 없고 `id_drift` 경고만 늘지만(`load_corp.py:94`), 힌트 값이 틀린 채 굳는다. → **104~114** 또는 결번 96 포함 재배치 권고 |
| R-2 | LS·LG CNS **DART 명 표기** | **불일치** | REGDATA 초안: `DART 명 엘에스일렉트릭` / `DART 명 LG씨엔에스`(따옴표 없음). `load_corp._DART_NM_RE = DART[^']*'([^']+)'` 는 **작은따옴표 안**만 읽는다 → 매칭 실패 → `TCORP.CORP_NM`이 우리 표시명(`LS ELECTRIC`·`LG CNS`)으로 들어간다. 기존 관례는 `DART 명 '씨제이올리브네트웍스'`. → **따옴표를 씌울 것** |
| R-3 | `WAVE1_ALIASES` | **필수(선택 아님)** | seed200(102행)에 신규 11개사 **전부 부재** 확인. override 없으면 `build_company_meta`가 `aliases=[comp_nm]` 폴백 + 경고 로그. SD-6(별칭≥1)은 통과하지만 `한국타이어`·`LS산전`·`LG씨엔에스`·`L&F`·`원익아이피에스` 검색이 통째로 죽는다 |
| R-4 | 별칭 초안 ↔ 수집기 관측 | **보강 제안** | 아래 §4-c-1 |
| R-5 | `FINANCIAL_COMPANIES` + KB금융 | **정확** | `load_corp.py:34` + `test_corp_load.py:30` `FINANCIAL_7`→`FINANCIAL_8`. HD현대는 지주지만 매출 계정이 있는 일반 법인이라 **추가하면 안 된다**(REGDATA도 안 넣음 ✔) |
| R-6 | FN-1 핀 101/100 → 112/111 | **정확** | `test_corp_load.py:52-53,74` 실측 확인(102 CSV행 − UNMAPPED 1 = 101 링크 / CJ ENM 2행 1법인 = 100 법인) |
| R-7 | krx_sector 11행 | **정확** | 정본 경로는 `db/seed/` 가 아니라 **`generator/data/krx_sector.csv`**(현재 99행+헤더 → 110행+헤더). 섹터 선례 판단(반도체장비=기계·장비 등)도 기존 행과 일치 |
| R-8 | 파일명 ↔ COMP_NM | LOW | `LS일렉트릭.sql`→'LS ELECTRIC', `LGCNS.sql`→'LG CNS', `한국타이어.sql`→'한국타이어앤테크놀로지'. 기능 무관(로드 순서만 좌우)이나 코퍼스 관례는 파일명≈COMP_NM |
| R-9 | 회사 추가 시 정적 재생성 | 리마인더 | MEMORY 함정: 회사 추가 후 정적 재생성 필수 |

#### 4-c-1. 별칭 초안 + 수집기 관측 병합 제안

evidence·SQL에서 실제로 관측된 표기를 초안에 병합한 최종안(추가분 **굵게**):

```python
WAVE1_ALIASES = {
  "korea_zinc":   ["고려아연"],
  "hyundai_enc":  ["현대건설", "현건", "HYUNDAI E&C", "hdec"],          # 푸터 (c) HYUNDAI E&C · hdec.kr
  "ls_electric":  ["LS ELECTRIC", "LS일렉트릭", "엘에스일렉트릭", "LS산전"],
  "wonik_ips":    ["원익IPS", "원익아이피에스", "IPS"],                   # 자사 도메인 ips.co.kr
  "lg_cns":       ["LG CNS", "LG씨엔에스", "엘지씨엔에스", "LGCNS"],      # 공백 없는 표기 = 파일명·검색어
  "landf":        ["엘앤에프", "L&F", "LnF"],                          # 푸터 LFIS@Landf.co.kr
  "hana_micron":  ["하나마이크론", "Hana Micron"],
  "simmtech":     ["심텍", "SIMMTECH"],
  "hankook_tire": ["한국타이어앤테크놀로지", "한국타이어", "한타",
                   "Hankook Tire", "한국앤컴퍼니"],                     # 그룹명은 별개 법인 — 주의(아래)
  "kbfg":         ["KB금융", "KB금융지주", "KB", "국민은행"],            # 국민은행은 자회사 — 주의(아래)
  "hd_hyundai":   ["HD현대", "에이치디현대", "현대중공업지주"],            # 구 사명 = 검색 유입 자산
}
```

⚠ 별칭 2건은 **판단이 필요**하다 — 별칭은 사이트 내 검색과 JSON-LD `alternateName`으로 나가므로, 다른 법인을 우리 페이지로 끌어오면 오정보가 된다.
- `한국앤컴퍼니`는 **별도 법인(그룹 지주)**이다 — 우리 로스터의 회사는 사업회사 `한국타이어앤테크놀로지` 뿐이다 → 넣지 말 것 권고. (evidence도 `hankookn.com`을 "한국앤컴퍼니 그룹 공용으로 보임"이라고만 적었다)
- `국민은행`은 KB금융의 **자회사**다. KB금융 복지 페이지가 그룹 통합 채용 사이트라 실질 포함 관계이긴 하나, 같은 논리면 신한/하나도 문제된다 → 넣지 말 것 권고.
- `현대중공업지주`는 HD현대의 **구 사명**(2023 변경)이라 안전 ✔.

### 4-d. 이메일 도메인 — 관측·판정·SED 충돌

| 회사 | eng | 관측 도메인 | 관측 근거(evidence) | 판정 | SED 영향 |
|---|---|---|---|---|---|
| 고려아연 | `korea_zinc` | `koreazinc.co.kr` | `hr@koreazinc.co.kr` — 개인정보처리방침 제9조 인사팀 연락처 | **등록** | 기존 0건·@rejected 0건 → 충돌 없음 |
| LGCNS | `lg_cns` | `lgcns.com` | `inquiry@lgcns.com` — `/kr/careers/*` 푸터 | **등록** | 충돌 없음 |
| KB금융 | `kbfg` | `kbfg.com` | `recruit2@kbfg.com` — 채용 문의(사이트 번들) | **등록** | 충돌 없음 |
| 심텍 | `simmtech` | `simmtech.com` | `ks.park@simmtech.com` — `/recruit/ordinary.aspx` 채용상담 | **등록** | 충돌 없음 |
| 엘앤에프 | `landf` | `landf.co.kr` | 4페이지 공통 푸터 `LFIS@Landf.co.kr` | **등록** ⚠ | 원문이 `Landf.co.kr` — **반드시 소문자화**. 대문자면 SED-4가 잡는다 |
| HD현대 | `hd_hyundai` | `hd.com` | `kimsb@hd.com` 외 3건(지주 인사) · 계열사는 각자 도메인(`@hhi.co.kr` 등) | **등록** | 지주 단독 매핑이라 그룹 오염 없음. 충돌 없음 |
| 원익IPS | `wonik_ips` | `wonik.com` | `ips.esg@wonik.com` **1건뿐** · 웹 도메인은 `ips.co.kr`(메일 관측 0) | **보류** | `IN(...)` 그룹 문장 없이 단일 등록하면 원익홀딩스 등 추가 시 **SED-5 실패**. `-- @rejected: wonik.com — 원익그룹 공용 메일 도메인 개연성. 관측 1건뿐이라 원익IPS 단독 귀속 근거 부족` |
| 한국타이어 | `hankook_tire` | `hankookn.com` | 채용사이트 푸터 `recruit@hankookn.com` (`hankookn` = 한국앤컴퍼니) | **보류** | 위와 동일 사유. `-- @rejected: hankookn.com — 한국앤컴퍼니 그룹 공용 대표 메일. 사업회사 단독 귀속 근거 부족` |
| 현대건설 | `hyundai_enc` | — | 정본·robots·FAQ 정규식 전수 스캔 **0건** | 미관측 | 추가 없음 |
| LS일렉트릭 | `ls_electric` | — | `mailto:` 0건, contact 페이지 404 | 미관측 | 추가 없음 |
| 하나마이크론 | `hana_micron` | — | `hanamicron.com` 전수 스캔 0건 | 미관측 | 추가 없음 |

**SED 가드 검증(추가 6건 기준)**

| 가드 | 결과 |
|---|---|
| SED-1 (slug 실재) | `korea_zinc` `lg_cns` `kbfg` `simmtech` `landf` `hd_hyundai` — 전부 신규 SQL의 COMP_ENG_NM과 정확 일치 ✔ |
| SED-2 (선언=적재) | 단일 `= 'slug'` 형식이면 1:1 ✔ |
| SED-3 (프리메일) | 6건 모두 FREEMAIL 목록 밖 ✔ |
| SED-4 (형식) | 소문자·유효 DNS ✔ (**단 `landf.co.kr` 소문자화 필수**) |
| SED-5 (단일 도메인 유일) | 기존 파일 내 동일 도메인 **0건**, 신규 6건 상호 중복 0건 ✔ |
| SED-7 (@rejected 재등록) | 기존 @rejected 12건과 겹침 **0건** ✔ · 신규 보류 2건은 사유 5자 이상 ✔ |
| 형제 도메인 함정 | `hd.com` vs 기존 `hyundai.com`(현대차) — 별개 법인·별개 회사 매핑이라 문제 없음. `ls-electric.com` vs 기존 `lsholdings.com`(LS 지주) — LS일렉트릭은 미관측이라 추가 자체가 없음 ✔ |

---

## 5. 권고 수정 목록 (반영 전 처리, 우선순위 순)

### P0 — 반영 전 필수

1. **[BLOCK] 고려아연.sql L5 주석 홑따옴표 제거.** `-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)` → `-- badge: est (추정치 — 공식 확인 시 official 로 변경)`. 나머지 10파일 형식과 통일. (현재는 짝수라 우연히 통과하지만 계약 명시 금지 + 편집 한 번에 로더가 깨진다)
2. **[HIGH] HD현대 통근/유류 코드 교체(2행).** `transport`(통근버스) → `commute_subsidy`, `fuel_support`(유류비) → `transport`. 웨이브 내 분기 2건(C-1·C-2)이 동시에 해소되고 신규 코드가 1종 줄어든다. 행 수 불변.
3. **[HIGH] 여행·휴양 3(4)종 통합.** `overseas_trip`·`vacation_program`(·`summer_vacation_subsidy`) → `travel_support`. 행 수 불변, 신규 코드 −2~3종.
4. **[HIGH] 심텍 `child_entrance_gift` → `child_edu` 병합** (18→17행) · **원익IPS `family_program` → `company_event` 병합** (28→27행). 선례 충돌 해소. → **SD-4 = 1754**.
5. **[HIGH] SB-10 `real_url_engs`에 11 eng 추가.** 누락 시 테스트가 반드시 실패한다(§4-b).

### P1 — 통합 작업과 같은 커밋에서

6. **테스트 핀 일괄 갱신**: SD-3 102→113 · SI-8 102→113 · SD-4 1553→1754(독스트링 내역 포함) · FN-1 101/100→112/111 · `FINANCIAL_7`→`FINANCIAL_8`(+`'KB금융'`) · SM-1 스냅샷 · GC-2 서술 교체(+SPEC INV-6).
7. **`corp_code_map.csv` comp_id를 104~114로**(103은 CJ프레시웨이 점유) — R-1.
8. **DART 명 표기에 작은따옴표**: `DART 명 '엘에스일렉트릭'` · `DART 명 'LG씨엔에스'` — 없으면 `TCORP.CORP_NM`이 우리 표시명으로 굳는다(R-2).
9. **`WAVE1_ALIASES` override 추가**(§4-c-1 병합안). seed200 미등재 확인 완료 — 없으면 11개사 검색 별칭이 자기 이름 하나로 죽는다. `한국앤컴퍼니`·`국민은행`은 **넣지 말 것**.
10. **`company_email_domain.sql`**: 단일 매핑 6건 추가(`landf.co.kr` 소문자) + `@rejected` 2줄(`wonik.com`·`hankookn.com`) 추가. 미관측 3사는 무추가.
11. **HD현대 `office_furniture` → `work_tools`** (kakao_bank/kakao_pay 선례). 행 수 불변, 신규 코드 −1.

### P2 — 선택/후속

12. **심텍 SORT `1,2` → `10,11`** (10단위 섹션 관례).
13. **HD현대 `family_card` → `discount` 병합**(−1행) 또는 유지 결정. 병합 시 SD-4 = 1753.
14. **`krx_sector.csv` 경로 확인**: 정본은 `generator/data/krx_sector.csv`. REGDATA에 경로가 없다.
15. **HD현대 귀속 문구 검토**: 20행 전부가 그룹 통합 채용 페이지 근거 + "(그룹 통합 채용 기준) 계열사 간 일부 상이 가능" 부기. 계약 §6("그룹 공통 복지를 개별사에 귀속 금지")과 경계에 있다 — HD현대는 지주 자체가 채용 주체라 방어 가능하지만, **원익IPS가 같은 이유로 그룹 포털을 전면 배제한 것과 기준이 달라진다**. 사용자 결정 필요.
16. **선재 부채(웨이브1 무관, 별도 처리)**: 코퍼스 `long_service`(효성중공업 1건) → `long_service_bonus` 정리 · 코퍼스의 통근버스 이중 표기 정리(**`transport` 15건 중 11건이 통근/셔틀** vs `commute_subsidy` 28건 중 23건이 통근/셔틀 — 즉 코퍼스 자체가 이미 11:23 으로 갈라져 있다. 권고 2번은 웨이브1을 **다수파(`commute_subsidy`)**에 붙이는 것이며, 코퍼스 11건 재코딩은 별건) · 삼성카드 `company_event`(가족친화 프로그램) 유지 확인.

### 권고 반영 후 최종 신규 코드 (9종)

```
travel_support  overseas_safety  welfare_fund_loan  blood_bank  car_wash
car_rental      promotion_gift   workation          free_seating
(+ family_card — 13번 결정에 따라 10종)
```

---

## 부록 — 재현 스크립트

- `_audit.py` : 초판. ⚠ 문장 종류 검사가 선행 주석을 statement 본문으로 오인해 **오탐 35건**(`-- ━━━ vs INSERT IGNORE` 류)을 낸다. `_audit2.py` 가 이를 교정했다.
- `_audit2.py` : 확정본. 주석 제거 후 문장 종류 판정 + 인라인 꼬리 주석 따옴표 검사 + SORT 10단위 검사 + 카테고리 편차 + 성격별 코드 분기 표.
- `_audit_rows.json` : 신규 203행 전량(코드·명·금액·카테고리·QUAL·NOTE·SORT).
- `_corpus_codes.json` : 기존 코퍼스 74코드 × 사용처(eng·명·카테고리).
