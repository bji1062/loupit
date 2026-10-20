**판정: 가능**
- 정본 URL: https://www.gscaltex.com/kr/recruit/hrsystem/welfarebenefits (법인 자기 도메인 · Recruit > 인사제도 > 복리후생 · SSR)
- 행 수: 25 (법정 제외 뒤)
- 렌더: 원본 HTML 태그 제거(주석 걷은 뒤) — 헤드리스 렌더 0회

점검: ① 분할기 `5` · ② 길이 `25 rows, ok · 0 violations` · ③ 법정 낱말 검출 4 · 면제 2(7절 판단 — 전부 허용) · ④ `_row_check.py --corpus 리포 시드` `총 오류 0 — 통과`(확인 0 · 금액 행 1 = estimated) · ⑤ 항목 페이지 분류 20행 — 문안 수정 없음 · 예외 후보 1(7절) · ⑥ 점검기 `ok 200 None text/html True None`
요청 수: 판정 3 / 수집 11(점검기 2 포함) — `W/gs_caltex/req.log`
UA: 일반 브라우저 `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36` · 사이트 키 · 토큰 사용 없음 · OpenDART 는 운영 키(로그 `<키 생략>`)
그룹 · 형제: GS 기등록 형제 GS건설(2026 지속가능경영보고서 PDF 정본) · GS리테일(2025 지속가능경영보고서 PDF 정본). 이번 출처의 고유 문구(Welcafe · 350만 포인트 · 생활안정자금 4,000만원 · 인재개발원 생활관 · 매칭 그랜트 · 장례지원 서비스 · 구성원 상담 · 자율출퇴근제 · 80여 개)를 두 시드에 grep — 겹침 0. GS리테일 시드의 「GS칼텍스」 2회는 배구단 스포츠 티켓 행(회사 등록 아님). 페이지 주어 = 회사 자신, GS그룹 주어 · 계열사별 상이 단서 없음 → 각주 없음.
공고 근거 0행 / 전체 25행
등록: **비상장(종목코드 없음)** · 최대주주 지에스에너지(주) 50.0%(리드 메모 · `dart/company-12.json`) · DART corp_code 00165459 · `induty_code` 19210 · 설립 1967-05-19 · 재무 2023~2025(비상장 2021 · 2022 = 013, 판정 (162)) · 직원 2021~2025 · 직원 3,120(2025 사업보고서) · INDUSTRY_NM `정유/화학`(코퍼스 기존 값 1 — S-Oil 과 합류) · 유형 large · LOGO G

**위험 표시:**

| 위험 표시 | 해당이면 행(SORT) |
|---|---|
| 기등록 형제(코퍼스에 같은 그룹 법인) | GS건설 · GS리테일 — 문장 겹침 0, 전 행 해당 없음(대조 결과만 기록) |

그 밖(그룹 공통 · 그룹 통합 채용 · 통합 보고 · PDF 짝 맞추기 · 이미지 판독 · 붙여넣기) 해당 없음.

## 1. 출처 표

받은 날 2026-10-20(UTC) · 원문 사본 `W/gs_caltex/` · 해시 `W/gs_caltex/SHA256SUMS`

| 구분 | URL | robots | 상태 · 크기 | 사본 경로 | sha256(앞 16) |
|---|---|---|---|---|---|
| **정본** 복리후생 | https://www.gscaltex.com/kr/recruit/hrsystem/welfarebenefits | 허용 | 200 · 54,145 | `welfarebenefits_kr.html` / 텍스트 `welfarebenefits_kr.txt` | 45984e94ebf6b8ed / c939bf9c46e15850 |
| 보조 인사제도 | https://www.gscaltex.com/kr/recruit/hrsystem/hrsystem | 허용 | 200 · 48,940 | `hrsystem_kr.html` / `hrsystem_kr.txt` | 07c6d13a1a77313e / cc23f40f67df0d60 |
| 보조 인재육성 | https://www.gscaltex.com/kr/recruit/hrsystem/talentdevelopment | 허용 | 200 · 50,297 | `talentdevelopment_kr.html` / `.txt` | 4bca827422466191 / 472b96727640a9e1 |
| 보조 영문 복리후생(헤더 Eng) | https://www.gscaltex.com/en/recruit/hrsystem/welfarebenefits | 허용 | 200 · 49,177 | `welfarebenefits_en.html` / `.txt` | 19a78b34831b9f6e / 0e19567101eceaea |
| 보조 공시 | OpenDART 2026 반기보고서 (2026.06) 접수 20260814002233 | — | 200 | `dart/doc_20260814002233/20260814002233.txt` | zip 7aa3ef23204ccdc8 |
| 보조 공시 | OpenDART 사업보고서 (2025.12) 접수 20260331004120 | — | 200 | `dart/doc_20260331004120/20260331004120.txt` | zip 6c63ab5cad28b57d |
| 제외 지속가능성보고서 목록 | https://www.gscaltex.com/kr/Sustainability/SustainabilityReport | 목록 허용 · PDF 링크 `/download/<번호>` 는 `Disallow: /download/` | 200 · 54,642 | `sustreport_kr.html` | fdb0215359bfd153 |
| 제외 채용 사이트 | https://recruit.gscaltex.com | `User-agent: *` `Disallow: /`(검색봇 5종만 허용 · AI 봇 이름 없음) | robots 만 200 · 195 | `robots_recruit.gscaltex.com.txt` | f06b9d607207de0b |
| 메일 관측 | https://www.gscaltex.com/kr/PrivacyPolicy | 허용 | 200 · 66,526 | `privacy_kr.html` | b5ea1bd6a302302a |

- robots `www.gscaltex.com`(BOM 없음): `User-agent: *` / `Disallow: /download/` · `Disallow: /monitoring/prSystem` · Sitemap. AI 봇(ClaudeBot · anthropic-ai · GPTBot · CCBot · Google-Extended) 이름 레코드 없음 → `*` 따름 = 정본 허용. `recruit.gscaltex.com`(CRLF · BOM 없음): 한 레코드에 NaverBot · Yeti · Googlebot · Daumoa · NateBot `Allow: /`, `*` `Disallow: /` → 본문 요청 0.
- 정본 고른 이유: 법인 자기 도메인 상시 SSR 페이지 · 복지 절이 가장 많음 · 응답 본문에 「복리후생」 낱말 · 점검기 `ok`(keyword True). 사이트맵(`sitemap.xml` 143 URL)에 국문 · 영문 둘 다 등재. 페이지 HTML 주석 43개는 전부 머리 · 꼬리 메뉴 · 분석 태그(복지 블록 안 주석 없음).
- 영문판은 국문과 구성이 같고, 국문 단독 항목 1(퇴직연금 관련 경영성과급 DC 납부 지원) · 숫자 차이 1(단체상해보험 한도 — 8절).

## 2. 행별 인용표

사본 경로 약칭: KR = `W/gs_caltex/welfarebenefits_kr.txt` · EN = `W/gs_caltex/welfarebenefits_en.txt` · HR = `W/gs_caltex/hrsystem_kr.txt` · TD = `W/gs_caltex/talentdevelopment_kr.txt` · H26 = `W/gs_caltex/dart/doc_20260814002233/20260814002233.txt` · B25 = `W/gs_caltex/dart/doc_20260331004120/20260331004120.txt`

| SORT | 코드 | 이름 | 원문 그대로 · 사본:줄 | 출처 표기 | 칩 |
|---|---|---|---|---|---|
| 10 | housing_loan | 주택 융자 (주택구입·전세 자금) | 「주택 융자: 주택구입/전세 자금」「(1억5천만 원 한도, 연 0.5%)」 KR:271-272 (구분 「주거지원」 KR:270) | 공식 홈페이지 복리후생 주거지원 항목 | — |
| 11 | welfare_point | 복지포인트 350만 포인트 (Welcafe) | 「복지포인트 지원 350만 Point 및 Welcafe운영」 KR:287 · 「임직원에게 일정 포인트(350만 포인트)를 지급하고 본인이 문화생활, 체육시설 등에서 사용한 후 회사 시스템(welcafe)에서 정산하는 방식」 KR:306 | 공식 홈페이지 복리후생 선택적 복지제도 운영 항목 | — |
| 12 | welfare_fund_loan | 생활안정자금 | 「생활안정자금(4,000만원 한도, 연2.2%)」 KR:294 · 「Loan for emergency living expenses(up to KRW 40 million, 2.2% p.a.)」 EN:270 | 공식 홈페이지 복리후생 생활안정 지원 항목 · 공식 영문 홈페이지 Employee Benefits 항목 | — |
| 13 | pension_support | 개인형 퇴직연금(IRP) 매칭 지원 | 「노후 대비 개인형 퇴직연금(IRP) 지원(매칭 그랜트 본인 25만 원, 회사 25만 원)」 KR:298 · 「퇴직연금 관련 경영성과급 DC 납부 지원」 KR:299 | 공식 홈페이지 복리후생 생활안정 지원 항목 | — |
| 20 | dormitory | 사택·기숙사 (여수공장·연구소) | 「사택(여수공장) 및 기숙사(연구소 및 여수공장)」 KR:273 | 공식 홈페이지 복리후생 주거지원 항목 | — |
| 21 | nap_room | 수유실 | 「…육아 휴직 및 단축근무, 수유실 설치, 유치원 교육비…」 KR:309 | 공식 홈페이지 복리후생 Work & Life Balance 추구 항목 | — |
| 30 | medical | 의료비·치과보철료 지원 (본인·배우자·자녀) | 「의료비(1억 원 한도, 본인/배우자/자녀)」 KR:275 · 「치과보철료(500만원 한도, 본인/배우자/자녀)」 KR:276 | 공식 홈페이지 복리후생 건강증진 항목 | — |
| 31 | health_check | 종합건강검진 (임직원·배우자) | 「종합건강검진 및 건강증진프로그램 지원」 KR:277 · 「임직원 및 배우자 종합건강검진 실시를 통해 …, 독감 등 예방접종을 통해 사전에 질환을 예방할 수 있도록 관리」 KR:302 | 공식 홈페이지 복리후생 건강증진프로그램 항목 | — |
| 32 | fitness | 건강증진 프로그램 | 「건강강좌를 비롯하여 금연/비만/근골격계 질환 예방 등 다양한 건강증진 프로그램을 운영하고」 KR:302 · 라벨 KR:277 | 공식 홈페이지 복리후생 건강증진프로그램 항목 | — |
| 33 | insurance | 단체상해보험 | 「단체상해보험 가입(최대 2억 원_업무중 산재포함)」 KR:279 (EN:255 「up to KRW 100 million」 — 8절) | 공식 홈페이지 복리후생 건강증진 항목 | — |
| 34 | mental | 구성원 상담 프로그램(EAP) | 「구성원 상담 프로그램(EAP)」 KR:296 · 「2007년 부터 … 외부전문가와 상담을 통해 해결할 수 있도록 지원 … 임직원과 그 가족들이 상담하고자 하는 대인관계 갈등, 스트레스 등 각종 고충과 재무설계, 자녀 인성 및 진로 등의 문제에 대해 전문가와 직접 상담」 KR:304 | 공식 홈페이지 복리후생 구성원상담프로그램(EAP) 항목 | — |
| 40 | parenting | 출산·입학 축하금 | 「출산축하금(첫째 600만원, 둘째 1,000만원, 셋째 이상 1,500만원)」 KR:281 · 「입학축하금(초등학교,중학교,고등학교 240만원)」 KR:284 | 공식 홈페이지 복리후생 자녀양육 지원 항목 | — |
| 41 | child_edu | 자녀 학자금·유치원 교육비 | 「자녀 학자금(고등학교/대학교 전액, 자녀 수 제한 없음)」 KR:285 · 「유치원 교육비(2년간 240만원)」 KR:282 | 공식 홈페이지 복리후생 자녀양육 지원 항목 | — |
| 42 | childcare | 직장 어린이집 (본사·여수공장) | 「어린이집 운영(본사 및 여수공장)」 KR:283 | 공식 홈페이지 복리후생 자녀양육 지원 항목 | — |
| 43 | fertility_support | 난임치료비 지원 | 「난임치료비 지원」 KR:278 | 공식 홈페이지 복리후생 건강증진 항목 | — |
| 44 | event | 경조휴가·경조금·장례지원 서비스 | 「경조휴가 및 경조금(결혼/사망/회갑/칠순/팔순 등)」 KR:295 · 「장례지원 서비스」 KR:297 | 공식 홈페이지 복리후생 생활안정 지원 항목 | — |
| 50 | edu_support | 온라인 교육 시스템 | 「온라인 교육 시스템을 통한 다양한 교육 Contents 지원」 KR:288 | 공식 홈페이지 복리후생 자기계발 및 여가 지원 항목 | — |
| 51 | mba | MBA/Global on-line 과정 (우수 인재 육성) | 「우수 인재 육성」 TD:280 · 「국내외 유수대학 MBA/Global on-line 과정」 TD:281 | 공식 홈페이지 인재육성 우수 인재 육성 항목 | — |
| 60 | resort | 콘도·휴양소·인재개발원 생활관 | 「전국 콘도 및 휴양소(전국 30여개 시설)」 KR:289 · 「인재개발원 생활관(청평)」 KR:290 · 「2주간의 리프레시(refresh) 휴가 제도 및 인재개발원, 전국 콘도미니엄, 연중 휴양소 지원 등 건강한 휴식을 적극 지원」 KR:308 | 공식 홈페이지 복리후생 자기계발 및 여가 지원 항목 · Work & Life Balance 추구 항목 | — |
| 61 | club | 동호회 활동 (80여 개) | 「더불어 구성원들이 80여 개의 동호회 활동을 통해 여가를 활용하고 있습니다.」 KR:309 · 「We also support some 80 employee clubs」 EN:283 | 공식 홈페이지 복리후생 Work & Life Balance 추구 항목 · 공식 영문 홈페이지 Work & Life Balance 항목 | — |
| 70 | refresh_leave | 리프레시 휴가 | 「리프레시(refresh) 휴가 실시」 KR:291 · 「2주간의 리프레시(refresh) 휴가 제도」 KR:308 | 공식 홈페이지 복리후생 Work & Life Balance 추구 · 자기계발 및 여가 지원 항목 | 맨 칩 |
| 71 | long_service_leave | 장기근속 기념금품·휴가 (5년 단위) | 「장기근속 기념금품 및 휴가(5년 단위)」 KR:292 | 공식 홈페이지 복리후생 자기계발 및 여가 지원 항목 | 맨 칩 |
| 80 | profit_sharing | 전사 성과급 (경영 성과 연동) | 「보상」 HR:271 · 「경영 성과에 따른 전사 성과급 지급」 HR:272 | 공식 홈페이지 인사제도 보상 항목 | — |
| 81 | incentive | 개인 인센티브 | 「평가에 따른 개인인센티브 지급 및 연봉 차등 조정」 HR:273 (연봉 차등 조정은 뺌) | 공식 홈페이지 인사제도 보상 항목 | — |
| 90 | flex_work | 자율출퇴근제 | 「자율출퇴근제 : 08시~10시(여수 공장 07시~09시) 사이 출근하여 8시간 근무」 HR:282 · 표 「시차출퇴근제 사용자 수 | 1,313 | 1,412 | 1,511」 H26:13103-13106 · 「시차출퇴근제를 도입하고 있으며 … 시차출퇴근제 사용자 수는 시차출퇴근제를 적용받는 전체 직원 숫자임」 H26:13115 | 공식 홈페이지 인사제도 조직문화 항목 · 2026 반기보고서 유연근무제도 사용 현황 항목 | 맨 칩 |

## 3. 코드 판단

- SORT 12 `welfare_fund_loan`: 국문 라벨에 대출 낱말이 없지만 「연2.2%」(이율)와 영문 헤더 메뉴판 「Loan for emergency living expenses」가 대출임을 밝힌다 → 경계 「원문이 대출 · 융자 · 대부를 밝히면 뒤엣것」. 이름에는 원문에 없는 「대출」을 넣지 않았다.
- SORT 13 `pension_support`: IRP 매칭 그랜트(회사 25만 원 부담)와 퇴직연금 관련 경영성과급 DC 납부 지원을 한 행(같은 코드). 퇴직연금(DC/DB) 자체는 법정이라 싣지 않고, 회사 매칭 · 성과급 DC 납부 지원만.
- SORT 32 `fitness`: 「건강증진프로그램」(건강강좌 · 금연/비만/근골격계 질환 예방). 코퍼스 grep(이번 세션) — 「건강증진」 이름 행 코드 = fitness 5 · clinic 3(시설) → 프로그램은 fitness. 금연이 별 항목이 아니라 프로그램 나열 안 한 낱말이라 `smoking_cessation` 따로 세우지 않음(억지 분리 방지 — 8절 판단 요청 1).
- SORT 31 `health_check`: 독감 예방접종을 검진 행 서술에 — 코퍼스 grep 「예방접종」 health_check 9행(종합건강검진·독감 예방접종 등) · overseas_safety 1.
- SORT 44 `event`: 장례지원 서비스를 경조 행에 — 코퍼스 grep 「장례」 event 9행.
- SORT 60 `resort`: 인재개발원 생활관(청평)을 휴양 행에 — KR:308 이 「인재개발원, 전국 콘도미니엄, 연중 휴양소 지원 등 건강한 휴식」으로 함께 묶는다. 코퍼스 grep 「연수원」 resort 5행(콘도·생활연수원 등).
- SORT 71 `long_service_leave`: 「기념금품 및 휴가」 한 줄 → 경계 「휴가와 포상을 한 줄에 함께 적은 원문」.
- SORT 80 · 81: 「경영 성과에 따른 전사 성과급」(회사 실적 연동) = `profit_sharing` · 「평가에 따른 개인인센티브」 = `incentive` — 원문이 두 줄로 나눔.
- 신규 코드: **없음**.

## 4. 법정 제도

- 걷은 것: 「출산축하휴가(10일)」 KR:309 — 대상(본인 · 배우자)이 적혀 있지 않지만 배우자 출산휴가 법정 20일 · 출산전후휴가 90일 어느 쪽에도 못 미쳐 상회분 없음 → 행 없음. 「육아 휴직 및 단축근무」 KR:309 · EN:283 → 법정(상회 기간 · 급여 보전 미기재).
- 퇴직연금: SORT 13 은 법정 퇴직급여 위의 회사 매칭 · 납부 지원만(③ 검출 「퇴직연금」 허용 — 7절).
- 재취업지원: 출처에 전직 · 재취업 지원 문장 없음(직원 3,120 → 의무 대상이나 해당 행 없음).
- 🚨 11-27 재계산 대상: **없음** — 난임은 「난임치료비 지원」(비용 지원 · 휴가 일수 없음)뿐, 난임치료휴가 유급 일수 문장 없음.
- 건강검진: 「종합건강검진」 · 「배우자」라 복지(법정 검진 이름만 아님).

## 5. 금액

| SORT | 코드 | 원문 숫자 | 산식 · 갈래 | ④ 예측 |
|---|---|---|---|---|
| 11 | welfare_point | 「일정 포인트(350만 포인트)를 지급」 KR:306 | 350만 포인트 → 350(만원) · §3-3 estimated ② 포인트 환산 · NOTE 끝 「지급 주기 미기재, 1포인트 1원 기준 환산」(코퍼스 LG 계열 「110만 포인트 지급 … 지급 주기 미기재, 1포인트 1원 기준 환산」과 같은 꼴) | estimated |

숫자가 있지만 비운 것:

| SORT | 원문 숫자 | 비운 이유 |
|---|---|---|
| 10 | 1억5천만 원 한도 · 연 0.5% | 대출 원금 한도 · 이율 |
| 12 | 4,000만원 한도 · 연2.2% | 대출 원금 한도 · 이율 |
| 13 | 매칭 그랜트 본인 25만 원 · 회사 25만 원 | 주기 미기재 · 본인 납입 조건부 매칭 |
| 30 | 의료비 1억 원 한도 · 치과보철료 500만원 한도 | 한도 |
| 33 | 최대 2억 원 | 보장 한도 |
| 40 | 출산축하금 600 · 1,000 · 1,500만원 · 입학축하금 240만원 | 1회성 |
| 41 | 유치원 교육비 2년간 240만원 · 학자금 전액 | 기간 상한(조건부) · 비율 |
| 90 | 시차출퇴근제 적용 1,313명 | 통계 숫자 |

## 6. 제외 목록

| 원문 | 사본:줄 | 이유 |
|---|---|---|
| 출산축하휴가(10일) | KR:309 | 법정 이하(4절) |
| 육아 휴직 및 단축근무 | KR:309 | 법정 |
| 연봉 차등 조정 | HR:273 | 급여 조정(§3-7) |
| 승진(역량 중심 직위 체계 · 조직장 선임) · 직무순환(최초 부서배치 · 개인별 경력 개발 니즈 반영) | HR:274-279 | 인사 제도 · 회사 주도 배치(`career` 아님 — 사원 스스로 지원하는 사내공모 문장 없음) |
| 자율복장제(전 요일 자율 복장) | HR:281 | 복지 코드 없음(`uniform` = 근무복 지급) · 코퍼스 grep 「자율복장」 행 0 |
| 코칭 · 멘토링(임원/팀장 · 팀원 · 신입/경력) | TD:270-273 | 업무 교육 |
| 리더십 육성 전부 | TD:274-279 | 업무 교육 |
| 글로벌 기업연수과정 · Self-designed Learning(자기주도형 국내외 직무 전문가 과정) · 기타 장/단기 전문가 과정 | TD:282-284 | 우수 인재 육성 칸의 직무 전문가 과정 — 학위 · MBA 아님(8절 판단 요청 2) |
| 직무역량 육성 전부(온라인/오프라인 통합 교육시스템 · 직무 교육 · Action Learning · DX/AX 과정 · 체험근무) | TD:285-292 | 업무 교육(복리후생 표의 「온라인 교육 시스템」은 SORT 50 으로 따로) |
| 원격근무제(재택근무 포함) 사용자 수 「-」 세 기간 | H26:13111 · B25:17789 | 회사 설명 「재택근무는 2023년부터 정부의 코로나 종식 선언 이후 실시하지 않고 있음」(H26:13115) — 더 새 원문이 제도 없음을 밝힘 |
| 선택근무제 사용자 수 「-」 세 기간 | H26:13107 · B25:17785 | 사용자 0 · 회사 설명은 시차출퇴근제만 도입 |
| 우리사주조합 주주 표 「-」 | B25:16919 | 주주 표 한 칸 · 제도 문장 없음 |
| 기타장기종업원급여 회계정책 | B25:3637 | 「장기 근속 임직원」 낱말 없는 일반 회계정책 문장(근속 급부는 SORT 71 로 이미 있음) |
| 등기이사 성과급 · 퇴직금 산정 칸 | H26:13515-13530 · B25:18007 등 | 임원 보수 칸 — 직원 적용 문장 없음 |
| 지속가능성보고서 PDF(2025 국문 등) | sustreport_kr.html `/download/1117` 등 | robots `Disallow: /download/` — 받지 않음 |
| 채용 사이트 recruit.gscaltex.com | — | robots `*` 전면 금지 |

## 7. 낱말 스윕 · 항목 페이지

③ 검출:
- SORT 11 NOTE 「환산」 → **허용**(금액 NOTE 환산 표지).
- SORT 13 NM · QUAL 「퇴직연금」 → **허용** — 법정 퇴직급여가 아니라 개인형 퇴직연금(IRP) 회사 매칭 그랜트 · 경영성과급 DC 납부 지원(회사 제도)을 원문이 따로 항목으로 적음.
- SORT 90 QUAL 「시차출퇴근」 → **허용**(확인 어휘 — 법정 아님).
- SORT 21 「수유」 면제(수유 시설).

⑤ 분류 결과(문안 고친 것 없음): housing_loan direct [buy, lease, limit, low_rate] · welfare_point [amount, uses] · dormitory dorm [regional] · medical [family, kind, limit] · health_check [comprehensive, family] · fitness unknown [] · insurance [] · mental external [family, topics] · parenting [amount, cash] · child_edu [amount, child_count, preschool, ratio, university] · childcare [site] · event [funeral, leave, money, occasions] · edu_support [online] · mba [abroad, mba] · resort [] · club [count] · refresh_leave unknown [days] · long_service_leave **leave** [repeat, years] · incentive individual [] · flex_work start [].
- fitness `unknown` · refresh_leave `unknown`(연차 외 낱말 없음) · resort facets 없음(회사 보유 · 제휴 여부 원문에 없음) — 원문대로라 그대로.
- **예외 후보 1**: SORT 71 원문 「장기근속 기념금품 및 휴가(5년 단위)」는 금품과 휴가를 함께 주는데 규칙 낱말(선물 · 기념품 · 포상금 등)에 「기념금품」이 없어 `leave` 로 떨어진다. 원문 낱말로는 못 고친다.
  `{"comp": "gs_caltex", "h": "0fcd333964", "mode": "both", "why": "원문 「장기근속 기념금품 및 휴가(5년 단위)」가 기념금품과 휴가를 함께 준다고 밝힘 (영문판 Gift and leave for long-term service)"}`
  (+ 같은 이유로 `facets_add: ["goods"]` 도 후보 — 검증이 정한다)

## 8. 판단 요청

1. **SORT 32 금연을 따로 세울지** — 원문은 「건강강좌를 비롯하여 금연/비만/근골격계 질환 예방 등 다양한 건강증진 프로그램」 한 문장 나열. 기본안: `fitness` 한 행 유지(금연은 프로그램 이름 하나로 나열됐을 뿐 별 항목 아님). 대안: `smoking_cessation` 「금연 프로그램」 행 분리.
2. **글로벌 기업연수과정 · Self-designed Learning**(TD:282-283 · 우수 인재 육성 칸) — 기본안: 제외(학위 아님 · 「직무 전문가 과정」은 업무 교육 · 연수 내용 미기재). 대안: 글로벌 기업연수를 파견형으로 보고 `mba` 서술에 흡수(이 회사 `career` 행 없음).
3. **SORT 33 단체상해보험 한도 국문 · 영문 불일치** — 국문 「최대 2억 원_업무중 산재포함」(KR:279) · 영문 「up to KRW 100 million」(EN:255). 두 페이지 모두 발행일 없음. 기본안: 국문(정본 · 문구가 더 자세함 「업무중 산재포함」) 그대로. 대안: 숫자를 빼고 「단체상해보험 가입」만.

## 9. 이메일 도메인 관측

- `@gscaltex.com` — 개인정보처리방침 페이지(`privacy_kr.html`) 3회. MX: gscaltex.com → mail.gscaltex.com · mail2.gscaltex.com · mail2.t3.gscaltex.com(우선 10). DART 홈 칸 도메인 gscaltex.co.kr 도 MX 있음(mail.gscaltex.co.kr 등) — 관측된 주소는 .com 뿐. GS 그룹 공용 메일 줄(계약 굳은 규칙 목록)에 GS 는 없음 → 법인 단독 도메인으로 보임.

## 10. 배포 시 주의

- 정본 점검기 `ok`(keyword True) — 특이 조건 없음. robots Crawl-delay · Visit-time 없음.
- DART 홈 칸 `www.gscaltex.co.kr` 와 실제 홈 `www.gscaltex.com` 이 다르다(정본은 .com).
- 한시적 출처 없음(공고 근거 0).
- 비상장 표시: 등록 시 상장 구분 = 비상장(#135 표시).

## 11. 확인하지 못한 것

- 지속가능성보고서(2025 국문 등) 본문 — robots `/download/` 금지라 읽지 않음(보고서에 복지 표가 더 있을 수 있다 — 붙여넣기 · 다른 경로 공개 사본이 생기면 보강 후보).
- 채용 사이트 recruit.gscaltex.com 복리후생 · 공고 블록 — robots 전면 금지.
- 보도자료(PR룸) 복지 기사 — 목록을 받지 않음(사이트맵에 기사 URL 없음 · 정본 항목이 충분해 요청 아낌).
- 출산축하휴가(10일)의 대상(본인 · 배우자) — 원문에 없음.
