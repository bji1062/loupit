**판정: 가능**
- 정본 URL: https://www.dnautomotive.com/sub/recruitment/personnel.asp (자기 도메인 인재 채용 > 인사제도 · 복리 후생 블록)
- 항목 수: 16행(법정 제외 · 업무 교육 제외 · 권장 휴가 1건 판단 요청)
- 렌더: 없음 — 정본 · 그리팅 채용 사이트 · ESG 페이지 · 영문판 모두 원본 HTML(SSR)에 항목 텍스트. 이미지 판독 없음.

점검 결과(2026-10-15 UTC):
- ① 분할기 5문장 → `5`
- ② 길이 → `TOTAL 1 files, 16 rows, 0 violations`
- ③ 법정 · 편집 낱말 → 검출 1(SORT 12 meal NOTE 「추정」 — 식대 꼬리 식, 허용)
- ④ 행 점검 → `총 오류 0 — 통과`(단독 · `--corpus` 대기 폴더 둘 다) · 금액 행 1(SORT 12 meal 288 → estimated) · stated 0
- ⑤ 항목 페이지 분류 → 14행 대상, 오분류 0(7절) · 사본 `dn_automotive/_work/check5.txt`
- ⑥ 정본 점검기 실측 → **`error`**「robots.txt 에 닿지 못했다(TLS 인증서 검증 실패(unable to get local issuer certificate))」 — 서버가 중간 인증서(Thawte TLS RSA CA G1)를 빠뜨린다. 그 중간 인증서를 `EXTRA_INTERMEDIATES` 에 더한 모의 실행 → **`ok 200 text/html keyword True`**. 배포 시 주의(10절) · 사본 `dn_automotive/_work/check6.txt`

요청 수: 판정 14 / 수집 11(합 25 — curl GET 18(판정 12 · 수집 6) · TLS 핸드셰이크 확인 2(판정) · OpenDART 2 · 점검기 3(실측 1 — robots 에서 TLS 실패 · 모의 2)). 로그 `dn_automotive/req.log`.
UA: 기본 브라우저 UA(`Mozilla/5.0 … Chrome/128.0 Safari/537.36`). 사이트 JS 키 · 토큰 사용 없음. POST 없음.
그룹 · 형제 점검: 코퍼스 · 대기 폴더(218파일) `grep -l -E "DN|동아타이어|디엔"` → 3파일(클래시스 · 현대글로비스 · 펄어비스)인데 전부 「CDN」 · 「DNS」 낱말 — DN 계열 형제 0. 리드 메모의 DN그룹(지주 DN · DN솔루션즈) 채용 사이트(`career-dncompany.recruiter.co.kr`, 채용정보 페이지의 「DN SOLUTIONS 채용 바로가기」)는 요청하지 않았고 인용 0. 정본 · 그리팅 두 출처 모두 주어가 「DN AUTOMOTIVE는」 단수, 계열사 · 그룹 단서 없음 → 각주 없음. 구명(동아타이어공업 · 디티알오토모티브) 페이지 인용 0.
공고 근거 0행 / 전체 16행(게시 중 공고 2건은 복리후생 블록이 없다).
DART 이력: 2021~2025 재무 CFS · 직원 5개년 ok(리드 `dart/check.log` 8행) — 짧지 않음.

**위험 표시 없음** — 그룹 공통 · 그룹 통합 채용 · 통합 보고 · PDF 표 짝 맞추기 · 이미지 판독 · 붙여넣기 · 기등록 형제 모두 해당 없음. (참고: 보조 출처가 ATS(그리팅)지만 회사 계정 서브도메인 `dnautomotive.career.greetinghr.com` 이고 자기 도메인 채용정보 페이지 「DN AUTOMOTIVE 채용 바로가기」가 그곳을 링크한다.)

## 1. 출처 표

| 출처 | 쓰임 | robots | 받은 날(UTC) | sha256 | 사본 |
|---|---|---|---|---|---|
| https://www.dnautomotive.com/sub/recruitment/personnel.asp | **정본**(인사제도 · 복리 후생 블록 · 인재 개발 체계도) | `/robots.txt` 200 72바이트 = HTML(`location.href='/'`) — 규칙 없음 → 허용(`*` · AI 봇 이름 없음 · BOM 없음) | 2026-10-15 10:45 | ac3314f3…074c | `dn_automotive/personnel.html` · 텍스트 `personnel.txt`(0c3791…e351) |
| https://dnautomotive.career.greetinghr.com/welfare (→ `/ko/welfare`) | 보조 1(회사 계정 채용 사이트 인사 제도 · 복리 후생 — 항목이 정본보다 많다) | `User-agent: *` · `Allow: /` · `Disallow: /o/*/apply` · `/m/*` · `/a/*` 등 → `/welfare` · `/o/<id>` 허용 · AI 봇 이름 없음 · BOM 없음 | 2026-10-15 10:46 | 25f449aa…3e | `greeting_welfare.html` · `greeting_welfare.txt`(239181…863) |
| https://www.dnautomotive.com/sub/business/vms.asp | 보조 2(지속가능경영 > ESG 경영 · UN SDGs 건강과 복지 칸) | 위 호스트 | 2026-10-15 10:47 | 496585…e376 | `esg_vms.html` · `esg_vms.txt`(0c1561…137) |
| https://www.dnautomotive.com/en/sub/recruitment/personnel.asp | 보조 3(헤더 메뉴 EN 영문판 — 건강검진 주기) | 위 호스트 | 2026-10-15 10:47 | 8f65172e…2028 | `en_personnel.html` · `en_personnel.txt` |
| OpenDART 2026 반기보고서(접수 **20260814001265**, [첨부추가]반기보고서 (2026.06)) | 직원 수 · 유연근무제 사용 현황 | — | 2026-10-15 10:46 | zip 725636…49 | `dart_20260814001265.zip` · `dart_20260814001265.txt` |
| https://www.dnautomotive.com/sub/recruitment/information.asp | 채용정보(그리팅 · DN솔루션즈 채용 링크 확인) — 인용 0 | 위 호스트 | 2026-10-15 10:45 | a0c5e4…dad | `information.html` |
| 그리팅 공고 `/o/239742` · `/o/237262` | 복리후생 블록 없음 — 인용 0 | 그리팅 robots 허용 | 2026-10-15 10:46 | `sha256.txt` | `posting_*.html` |
| `/sub/media/news.asp` · `/en/` · `/` · `/sub/business/esg.asp`(72바이트 리다이렉트 셸) | 탐색 — 인용 0 | | | `sha256.txt` | |
| `www.dnautomotive.co.kr` | 인증서 이름 불일치(curl 60) — 쓰지 않음 | | | | |

- TLS: `www.dnautomotive.com` 은 잎 인증서(*.dncompany.com · SAN 에 dnautomotive.com · dongahtire.co.kr 등)만 보내고 중간 인증서 Thawte TLS RSA CA G1 을 빠뜨린다(openssl verify 21). AIA 주소 `http://cacerts.thawte.com/ThawteTLSRSACAG1.crt`(GET 200 · 발급자 DigiCert Global Root G2)를 받아 시스템 저장소에 더해 정상 검증으로 받았다(`_work/ca_plus.pem`) — 검증 끄기 없음. http:// 는 20초 시간 초과.
- 정본 고르기: 자기 도메인 상시 SSR 페이지이고 본문에 「복리 후생」 낱말이 있다. 그리팅이 항목은 더 많지만 계약 §3-1 대로 자기 도메인 상시 페이지가 먼저. 두 페이지 모두 발행일이 없어 시점 우열 없음 — 같은 제도는 두 문장을 다 실었다.
- 숨김 검사: 복리 후생 블록은 HTML 주석 밖 정상 마크업(personnel.html 489~573행). 주석 8개는 짧은 마크업 주석(60자 넘는 주석 0).

## 2. 행별 인용표

| SORT | 코드 | 이름 | 원문 그대로 · 사본:줄 | 출처 표기 | 칩 |
|---|---|---|---|---|---|
| 10 | housing_loan | 주택자금 지원 (전세자금 대출 이자 지원) | 「주택자금 지원 (전세자금 대출 이자 지원)」 personnel.txt:107 · EN 「Housing financing support (mortgage interest support)」 en_personnel.txt:104 | 공식 홈페이지 인사제도 복리후생 Welfare Benefits 항목 | — |
| 11 | snack_bar | 사내 카페 | 「사내카페 & 수면실」 personnel.txt:120 · 「사내 카페, 수면실 등 휴식 시설」 greeting_welfare.txt:46 | 홈페이지 Smart Working Culture · 채용 사이트 복지 시설 | — |
| 12 | meal | 사내 중식 무료 제공 (288) | 「사내 중식 무료 제공, 조식 석식 운영」 greeting_welfare.txt:45 | 채용 사이트 복지 시설 | — |
| 13 | commute_subsidy | 통근버스 운영 | 「부산/울산/경남 지역 통근버스 운영」 greeting_welfare.txt:57 | 채용 사이트 기타 복지 지원 | — |
| 14 | birthday_gift | 생일 축하 선물 | 「생일 축하 선물」 greeting_welfare.txt:59 · 「생일자에게 모바일 상품권 지급」 :60 | 채용 사이트 복리후생 | — |
| 20 | resort | 제휴 콘도·숙박시설 이용 지원 | 「여가 복지몰 운영 (제휴 콘도 시설 이용지원)」 personnel.txt:108 · 「복지몰 운영 (제휴 숙박시설 지원)」 greeting_welfare.txt:43 · EN 「Running a website to provide discounts on booking hotels and resorts for employees」 en_personnel.txt:105 | 홈페이지 Welfare Benefits · 채용 사이트 | — |
| 21 | summer_vacation_subsidy | 하계 휴가비 지원 | 「하계 휴가비 지원」 greeting_welfare.txt:42(「Refresh 휴가제도」 :40 아래) | 채용 사이트 Refresh 휴가제도 | — |
| 30 | event | 경조사 지원 (경조금·경조휴가·상조물품) | 「경·조사 지원 / 학자금 지원」 personnel.txt:109 · 「경조 휴가 및 경조금, 상조물품 및 화환 지급」 greeting_welfare.txt:55 | 홈페이지 Welfare Benefits · 채용 사이트 가족 복지 지원 | — |
| 31 | child_edu | 자녀 학자금 지원 | 「경·조사 지원 / 학자금 지원」 personnel.txt:109 · 「자녀 대학교 학비 지원」 greeting_welfare.txt:53 | 같음 | — |
| 32 | childcare | 사내 어린이집 | 「사내 어린이집 운영」 greeting_welfare.txt:54 · 「직장 어린이집 운영」 esg_vms.txt:79 | 채용 사이트 가족 복지 지원 · ESG 경영 UN SDGs 건강과 복지 | — |
| 40 | health_check | 건강검진 지원·독감접종비 지원 | 「건강 검진 지원」 personnel.txt:111 · 「Providing annual health checkups」 en_personnel.txt:108 · 「건강검진 지원 / 회사 내에서 건강검진 실시 / 독감접종비 50% 지원」 greeting_welfare.txt:34~36 | 홈페이지 건강 관리 프로그램 · 영문 홈페이지 · 채용 사이트 건강검진 지원 | — |
| 41 | clinic | 건강증진센터 (물리치료사 상주) | 「건강 상담」 personnel.txt:112 · 「재활 및 물리 치료」 :113 · 「건강증진센터 운영 / 물리치료사 상주하여 재활/물리치료 제공 / 건강증진프로그램 실시」 greeting_welfare.txt:37~39 · 「건강검진, 보건관리자 상주 / 건강증진센터 운영」 esg_vms.txt:80~81 | 홈페이지 건강 관리 프로그램 · 채용 사이트 건강검진 지원 · ESG | — |
| 42 | fitness | 사내 피트니스 센터 | 「체력단련실」 personnel.txt:121 · 「사내 피트니스 센터」 greeting_welfare.txt:47 | 홈페이지 Smart Working Culture · 채용 사이트 복지 시설 | — |
| 50 | lang | 영어 교육 지원 (사내 원어민 강사·전화영어) | 「외국어 교육」 personnel.txt:87(STEP 01 「모든 직원이 가져야 하는 기본 역량」 :85) · 「영어 교육 제공」 :117 · 「사내 원어민 강사 상주하여 주 2회 업무시간에 수업 실시」 greeting_welfare.txt:49 · 「전화영어 / 온라인강의 / 오프라인강의 지원」 :50(「영어&직무 교육 지원」 :48 아래) | 홈페이지 인재 개발 체계도 · 전문 교육 프로그램 · 채용 사이트 영어&직무 교육 지원 | — |
| 60 | lounge | 수면실·사내 라운지 | 「사내카페 & 수면실」 personnel.txt:120 · 「사내 카페, 수면실 등 휴식 시설」 greeting_welfare.txt:46 · 「직원 스트레스 완화를 위한 수면실 카페가 설치가 된 / 사내 라운지 운영」 esg_vms.txt:82~83 | 홈페이지 · 채용 사이트 · ESG | — |
| 61 | uniform | 근무복 제공 | 「입사 시 근무복 제공」 greeting_welfare.txt:58 | 채용 사이트 기타 복지 지원 | — |

칩 6코드 행 없음(유연근무 · 재택 · 리프레시 · 장기근속 휴가 행 0).

## 3. 코드 판단

- SORT 20 resort — 「여가 복지몰 운영 (제휴 콘도 시설 이용지원)」: 어휘 경계상 복지몰 = `welfare_point` 이지만 이 몰은 괄호 · 영문판(「website to provide discounts on booking hotels and resorts」)이 밝히듯 콘도 · 숙박 예약 창구다. 포인트 · 금액이 원문에 없어 `welfare_point` 행을 세우면 「복지포인트 있음」으로 과장된다 → `resort` 한 행에 복지몰 문장을 서술로(8절 판단 요청 1).
- SORT 40 health_check — 독감접종비 50% 지원은 같은 「건강검진 지원」 블록 안 항목이고 코퍼스 관례가 `health_check` 다(이번 세션 grep: 독감 · 예방접종 낱말이 든 행 코드 health_check 20 · clinic 2 · leave_general 1 · 서술 내 mental 1). `medical` 행을 따로 세우지 않았다.
- SORT 41 clinic — 「건강 상담」은 심리상담 낱말이 없어 `mental` 이 아니라 건강증진센터 · 물리치료 · 보건관리자와 같은 건강관리실 성격으로 `clinic` 서술에.
- SORT 50 lang — 「전화영어 / 온라인강의 / 오프라인강의 지원」은 「영어&직무 교육 지원」 칸 안 「사내 원어민 강사」 다음 줄이라 영어 몫으로 읽었다. 온라인 · 오프라인 강의에 직무 과목이 섞였을 수 있다 — 원문 그대로 인용했고 이름은 영어만.
- SORT 11 snack_bar · 60 lounge — 「사내카페 & 수면실」 한 라벨을 시설별 두 행으로(계약 §3-11 · 각 행은 자기 몫). lounge 서술의 ESG 문장 「수면실 카페가 설치가 된 사내 라운지」는 원문 한 문장이라 그대로.
- **신규 코드: 없음.**

## 4. 법정 제도

- 걷은 문구: 「법정교육」(personnel.txt:90 · 인재 개발 체계도) — 업무 · 법정 교육. 공시 육아휴직 · 배우자 출산휴가 · 육아기 단축 사용자 표(dart txt 18820~18890대) — 법정 제도 사용 실적이라 행 없음.
- 상회분 판정: 원문에 법정 휴가 상회 문장 없음.
- 재취업지원: 원문에 해당 제도 없음. 직원 1,564명(2026 반기보고서 직원 등 현황 합계 · dart txt:18834).
- 보건관리자 상주(SORT 41): 산안법상 선임 의무 인력이지만 계약 §3-2 「법정 열거 밖 시설(보건관리실 · 사내 간호사 — 「산안법 성격」으로 거르지 않는다)」대로 clinic 서술에 남겼다. 법정 검진 이름(일반 · 특수 · 배치전)은 원문에 없음.
- 🚨 11-27 재계산 대상: 없음(난임 휴가 · 난임 지원 문장 0).

## 5. 금액

| SORT | 원문 숫자 | 처리 | 갈래 |
|---|---|---|---|
| 12 meal | 「사내 중식 무료 제공, 조식 석식 운영」 — 단가 없음 | 288 = 중식 1끼 × 12,000원 × 240일. 조식 · 석식은 「운영」이라 회사 부담이 원문에 없어 세지 않음(꼬리 「, 조식·석식 제외」). ④ 예측 estimated | §3-3 ④ 식대 |
| 40 health_check | 「독감접종비 50% 지원」 | NULL — 비율 | 비율 |
| 50 lang | 「주 2회」 | NULL — 횟수 | 횟수 |

stated 0 · estimated 1. 그 밖에 원 · 만원 숫자 0.

## 6. 제외 목록

| 원문 | 사본:줄 | 이유 |
|---|---|---|
| Refresh 휴가제도 — 「하계 1주, 동계 1주 휴가 권장」 | greeting_welfare.txt:40~41 | 권장 휴가(회사가 더 주는 날이 원문에 없음 · 계약 §3-6) — 8절 판단 요청 2 |
| APQP, PM, 리더십 교육 · 워크샵 프로그램 | personnel.txt:115~116 | 업무 교육(전문 교육 프로그램 칸) |
| 직무역량 및 공통역량 교육 프로그램 제공 및 교육비 지원 | greeting_welfare.txt:51 | 업무 교육 — 8절 판단 요청 3 |
| 기본소양교육 · 신규 입사자 입문교육 · 법정교육 · 사내/사외 전문교육 · 임원·팀(파트)장 교육 · 승진자 교육 · 기타 계층 교육 | personnel.txt:86~103 | 업무 · 입문 · 법정 · 리더십 교육 |
| 연구소 사무공간 | personnel.txt:119 | 사옥 시설 나열(§3-12) |
| 복리후생 규정 운영 | esg_vms.txt:78 | 제도 내용 없음 |
| 커리어 개발 관리 · 노사협의회 실시 및 고충 처리반 운영 | esg_vms.txt | 사원 지원형 이동 아님 · 복지 아님 |
| 공시 유연근무제 「미활용」 · 사용자 수 「-」 | dart txt:18899~18911 | 원문 제도 없음 |
| 공시 우리사주조합 「-」 · 주식매수선택권 정관 · 종업원 주식기준보상 | dart txt:18070 · 911 · 8085 | 주주 표 빈칸 · 재량 부여(복지 아님) |
| 그리팅 공고 연봉 「5,400만원 (… 2026년 대졸 신입사원 초봉 기준)」 | posting_239742.html | 급여(복지 아님) |

## 7. 낱말 스윕 · 항목 페이지

- ③ 검출 1: SORT 12 meal NOTE 「추정」 → **허용**(식대 꼬리 식).
- ⑤ 문안 수정 1: SORT 41 clinic 이 처음엔 mode `unknown`(「건강 상담」 띄어쓰기 · 「물리치료사」가 형태 규칙에 안 걸림) → ESG 원문 「보건관리자 상주」를 서술에 넣어 `room`(원문 낱말).
- 나머지 확인: meal `canteen` + breakfast · dinner(조식 · 석식 「운영」 — 나온다는 뜻으로 맞음) · free · housing_loan `interest` + lease · event flowers · funeral · leave · money · child_edu university · birthday_gift `points`(모바일 상품권) · lang `inhouse` + remote(전화영어) · fitness `inhouse` · lounge cafe · sleep.
- 예외 후보 1(기본안 = 넣지 않음 — 검증 판단):
  `{"comp": "dn_automotive", "h": "a4b7f1cbf9", "facets_add": ["cycle"], "why": "영문 인사제도 페이지가 Providing annual health checkups 로 매년 검진을 밝힌다 — cycle 규칙이 영문 annual 을 못 읽는다"}`
  (SORT 40 의 `cost` 는 「독감접종비 50% 지원」에서 켜졌다 — 행 안의 비용 지원 사실이라 그대로 둔다.)

## 8. 판단 요청

1. **SORT 20 resort ← 「여가 복지몰 운영 (제휴 콘도 시설 이용지원)」** — 어휘 경계 「복지몰 = welfare_point」와 부딪힌다. 기본안: `resort` 한 행 유지(몰의 내용이 콘도 · 숙박 예약 지원이고 포인트 · 금액 문장이 없다 — welfare_point 행은 복지포인트 축을 거짓으로 켠다).
2. **Refresh 휴가제도(「하계 1주, 동계 1주 휴가 권장」)** — 「리프레시는 이름만 있어도 싣는다」와 「권장 휴가는 싣지 않는다」가 겹친다. 원문 설명이 권장뿐이고 연차 외 추가 일수 · 유급 문장이 없다. 기본안: **싣지 않음**(권장 휴가). 같은 칸의 「하계 휴가비 지원」은 현금이라 SORT 21 로 실었다.
3. **「직무역량 및 공통역량 교육 프로그램 제공 및 교육비 지원」** — 기본안: 싣지 않음(직무 · 공통역량 = 업무 교육 과정이고 교육비 지원의 대상이 그 프로그램으로 읽힌다).

## 9. 이메일 도메인 관측

미관측(정본 · 그리팅 · ESG · 공시 텍스트에 회사 메일 주소 0 — 뉴스 목록의 언론사 도메인 1건뿐). 참고: `dnautomotive.com` MX = `spam.dncompany.com` · `spam1.dncompany.com` · `mtspm.dncompany.com`(DN 그룹 공용 메일 서버로 보임 — 실제 주소 도메인은 미관측).

## 10. 배포 시 주의

- **정본 점검기 `error`(TLS)**: `www.dnautomotive.com` 이 중간 인증서를 빠뜨린다. `server/data/extra_intermediates.pem` 에 **Thawte TLS RSA CA G1**(발급자 DigiCert Global Root G2 · AIA `http://cacerts.thawte.com/ThawteTLSRSACAG1.crt` · 사본 `dn_automotive/_work/thawte_g1.pem`)을 더하면 `ok 200 keyword True`(모의 실행 `_work/check6.txt`). 더하지 않으면 매주 `error`.
- Crawl-delay · Visit-time 없음. 공고 근거 0행. SI-9 허용 목록 추가 불필요(식대 꼬리 식 있음).

## 11. 확인하지 못한 것

- 지속가능경영보고서: 자기 도메인 ESG 페이지에 보고서 PDF 가 없다(정책서 4종 · 사업장 의견서 4종 PDF 만 — 복지 문장이 있을 가능성이 낮아 받지 않음).
- 보도자료: 뉴스 목록 첫 쪽에 복지 기사 없음(그 뒤 쪽은 보지 않음).
- `www.dnautomotive.co.kr`(인증서 이름 불일치) · DN그룹 recruiter 채용 사이트는 보지 않았다.
