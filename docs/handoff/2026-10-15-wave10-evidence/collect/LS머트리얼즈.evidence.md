**판정: 가능**
- 정본 URL: https://www.lsmaterials.co.kr/kr/recruitment/personnel_system.html (법인 자기 도메인 채용정보 > 인사제도 · 「LS머트리얼즈 복리후생 제도」 16항목 + 인재 육성 교육 표 + 평가/보상)
- 행 수: 21행(정성 20 · 금액 1 — 식대 추정 864) · 신규 코드 0
- 렌더: SSR 원본 HTML(정본 · 회사 계정 채용 사이트 둘 다) — 헤드리스 렌더 · 이미지 판독 없음

점검: ① 분할기 5 · ② 길이 21 rows 0 violations · ③ 법정 낱말 검출 4 · 면제 2(아래 7절 — 전부 허용) · ④ `_row_check` 총 오류 0(단독 · `--corpus` 대기 폴더 둘 다 · 확인 0) · ⑤ 항목 페이지 19행 분류 전부 원문 뜻대로(예외 후보 0) · ⑥ 점검기 `ok 200 text/html keyword True`
요청 수: 판정 16(그중 1회는 URL 공백으로 curl 이 로컬에서 거부 — 네트워크 미전송) / 수집 8(채용 사이트 3 · OpenDART 3 · 점검기 2) — 로그 `W/ls_materials/req.log`
UA: 기본 브라우저 UA(`Mozilla/5.0 … Chrome/128.0 Safari/537.36`) · robots 가 AI 봇을 이름으로 막지 않음 · 사이트 키 · 토큰 사용 없음 · OpenDART 는 운영 키(로그 `<키 생략>`)
그룹 · 형제 점검: LS그룹 계열. 기등록 형제 LS ELECTRIC(`LS일렉트릭.sql` · 리포) · 가온전선(`가온전선.sql` · 리포) · LS마린솔루션(`LS마린솔루션.sql` · 대기). 세 시드 머리말 정본은 각자 자기 도메인 · 자기 ATS(`ls-electric.com/ko/recruit/intro` · `gaoncable.recruiter.co.kr/…` · `lsmarinesolution.co.kr/kor/Recruit`) — 이번 정본과 호스트가 다르다. 이번 원문 고유 구절(「호텔/콘도」 · 「손자녀」 · 「생일자 선물대」 · 「외국어 어학 검정」 · 「다양한 제도를 운영」)을 대기 폴더 240파일에 grep → 0건. 「레포츠」 · 「야유회」 · 「조/중/석」 · 「전화 외국어」 · 「주택구입/전세자금」 · 「종합검진 실시」 · 「출생 축하」는 LS 계열 아닌 회사들에서만 나옴(롯데정밀화학 · 원익IPS · SK하이닉스 등) — LS 형제 문장 겹침 0행. LS그룹 공용 채용 인사제도 페이지(「LS는」 주어 · 계열사 별 차이 단서)는 요청 0회 · 인용 0건. 구명 LS엠트론 사업부(2021-01-01 물적분할 — 채용 사이트 intro 원문) 자료는 쓰지 않았다(분할 전 자료 0건).
공고 근거 0행 / 전체 21행 (지금 열린 공고 2건 — 연구개발 경력직 · 2026 상시채용 — 은 본문이 이미지 + 채용 사이트 링크라 근거로 쓰지 않음)
DART 이력: 2023-12 상장 · 재무 · 직원 2023~ (리드 명단 기재 그대로) · 직원 139명(2026 반기 · 기간제 포함)

| 위험 표시 | 해당이면 행(SORT) |
|---|---|
| 그룹 공통(그룹 주어 페이지 · 「계열사별 상이」 단서) | 없음 |
| 그룹 통합 채용 페이지 · 템플릿 근거 | 없음 |
| 보고 범위가 여러 법인(통합 보고 각주 · 「○○는」 문장만 골라 씀) | 없음(반기보고서 주석 연결 문장은 쓰지 않고 별도 「회사가」 문장만 — 22) |
| PDF 표 짝 맞추기 | 없음 |
| 이미지 판독 | 없음 |
| 사용자 붙여넣기 사본 | 없음 |
| 기등록 형제(코퍼스 · 대기 폴더에 같은 그룹 법인) | 해당 — LS ELECTRIC · 가온전선 · LS마린솔루션(문장 겹침 0 · 전 행 법인 자기 출처) |

## 1. 출처 표

| 구분 | URL | robots | 받은 날(UTC) | sha256(앞 16) | 사본 |
|---|---|---|---|---|---|
| robots | https://www.lsmaterials.co.kr/robots.txt | `User-agent: *` · `Disallow: /madm/` · `Allow:/` → 본문 경로 전부 허용 · AI 봇 이름 줄 없음 · BOM 없음 | 2026-10-15 | adaa8207cbd13468 | `W/ls_materials/raw/robots_www.txt` |
| **정본** 인사제도 | https://www.lsmaterials.co.kr/kr/recruitment/personnel_system.html | 허용 | 2026-10-15 | ecbe61363945f957 | `raw/personnel_system.html` · 텍스트 `txt/personnel_system.txt` |
| 보조 인적자본 | https://www.lsmaterials.co.kr/kr/esg/human_rights_capital.html | 허용 | 2026-10-15 | cb468aaf9befbb3d | `raw/human_rights_capital.html` · `txt/human_rights_capital.txt` |
| 보조 인적자본 정책 PDF | 같은 도메인 `/_common/download.asp?…&dname=(LS머트리얼즈) 인적자본 정책.pdf`(자료실 ESG 정책) — PDF 1.6 4쪽 · 제정 2025-12-01 · 시행 2025-11-01 · 파일 수정 2026-06-30 · 적용 범위 회사 전 임직원 | 허용 | 2026-10-15 | e407d2216ab5f88f | `raw/hc_policy.pdf` · `hc_policy.txt` |
| 회사 계정 채용 사이트 robots | https://lsmaterials-recruit.career.greetinghr.com/robots.txt | `*` Allow `/` · Disallow 는 `/o/*/apply` · `/m/*` · `/a/*` 등 지원 경로뿐 → `/welfare` · `/culture` 허용 | 2026-10-15 | af2c2f658e53f95 | `raw/robots_greeting.txt` |
| 채용 사이트 복리후생 | https://lsmaterials-recruit.career.greetinghr.com/welfare(→ `/ko/welfare`) — 자기 도메인 채용공고 「채용공고 바로가기」 링크 · 꼬리말 LS머트리얼즈(주) 사업자번호 · 법인 단수 주어 | 허용 | 2026-10-15 | f3e10b6fbf91b30e | `raw/greeting_welfare.html` · `txt/greeting_welfare.txt` |
| 채용 사이트 인재육성/평가보상 | https://lsmaterials-recruit.career.greetinghr.com/culture | 허용 | 2026-10-15 | 27ead62d6aceb15b | `raw/greeting_culture.html` · `txt/greeting_culture.txt` |
| 공시 | OpenDART 2026 반기보고서(2026.06) 접수 20260814003148 — 직원 등 현황 마. 유연근무제도 사용 현황 · 재무제표 주석 장기종업원급여충당부채 | — | 2026-10-15 | d07d7a12efbdaba4 | `raw/doc_20260814003148.zip` · `dart_txt/20260814003148.txt` |
| 공시 | OpenDART [기재정정]사업보고서(2025.12) 접수 20260604000337 — 아. 유연근무제도 사용 현황 | — | 2026-10-15 | 571febfffc436146 | `raw/doc_20260604000337.zip` · `dart_txt/20260604000337.txt` |
| 제외 | `/kr/esg/esg_report.html` — 2025 ESG Report 국 · 영문 링크가 `javascript:alert(현재 준비중입니다.)` → 보고서 없음 | 허용 | 2026-10-15 | 055bbf29e6333599 | `raw/esg_report.html` |
| 제외 | `/kr/recruitment/careers.html`(인재상만 · 항목 0) · 채용 사이트 `/intro` · `/management`(회사 소개 · 인권경영 원칙 — 항목 0) · 채용공고 목록 · 공고 2건(본문 이미지 + 채용 사이트 링크) | 허용 | 2026-10-15 | — | `raw/careers.html` · `raw/greeting_intro.html` · `raw/greeting_management.html` · `raw/notice*.html` |

- 홈: DART 홈 주소 비어 있음 → DNS 로 `www.lsmaterials.co.kr`(국내 IP) 확인 · `/` 는 JS 로 `/kr/main/main.html` 이동 · 메인 GNB 「채용정보 > 인사제도」 · 「지속가능경영 > 인적자본」. (`lsmaterials.com` 은 Squarespace 해외 사이트 — 요청하지 않음.)
- 정본 고른 이유: 법인 자기 도메인 상시 페이지 · SSR · 복리후생 블록이 가장 많고 「복리후생」 낱말이 본문에 있음 · 로그인 · 리다이렉트 없음. 점검기 ⑥ `ok 200 None text/html True None`.
- 두 채용 원문의 시점: 정본은 평가제도를 OKR 로(`txt/personnel_system.txt:40`), 채용 사이트는 SPCM 으로(`txt/greeting_culture.txt:36`) 적고, 출생 축하금을 정본만 「최대 1천만원」으로 적는다 — 정본이 더 새 판으로 보인다(둘 다 발행일 없음). 같은 항목은 정본 문장을 먼저 쓰고, 채용 사이트는 정본에 없는 낱말(생일자 선물대 · 장기근속 휴가 · 유연근무제 · 수유실 · PI/PS)만 받쳤다.

## 2. 행별 인용표

| SORT | 코드 | 이름 | 원문 그대로 · 사본 경로:줄 | 출처 표기 | 칩 |
|---|---|---|---|---|---|
| 10 | lang | 외국어 교육 지원 (전화 외국어·어학 검정·교육비) | 「글로벌 교육 / 전화 외국어 지원 / 외국어 어학 검정 지원 / 진급자 어학성적 평가 / 외국어 교육비 지원」 `txt/personnel_system.txt:29-33`(진급자 평가는 뺌) · 「자기계발 지원 / 사내교육, 외국어 학원 등 지원」 `:65-66` | 인사제도 인재 육성 교육 · 복리후생 | — |
| 20 | incentive | 성과급 (PI·PS) | 「구성원들의 성과 목표 달성과 역량 향상을 유인하기 위해 성과급 제도를 운영하여, 도전적 목표와 지속적인 동기유발을 도모」 `txt/personnel_system.txt:52` · 「② 성과급 지급(PI/PS)을 통해 직원들의 목표달성과 성과향상을 유인하며」 `txt/greeting_culture.txt:46` | 인사제도 평가/보상 · 채용 사이트 평가/보상 | — |
| 21 | excellence_award | 우수사원 포상 | 「포상제도 운영 / 우수사원/장기근속 포상」 `txt/personnel_system.txt:67-68` · 「우수사원/장기근속 포상제도 운영」 `txt/greeting_welfare.txt:14` | 복리후생 | — |
| 22 | long_service_bonus | 장기근속 포상 | 같은 줄 `txt/personnel_system.txt:68` · `txt/greeting_welfare.txt:14` · 「회사가 장기근속 임직원에게 지급하는 장기종업원급여와 관련하여 합리적으로 추정되는 손실금액을 반영한 금액입니다.」 `dart_txt/20260814003148.txt:11169`(별도 주석) | 복리후생 · 2026 반기보고서 주석 | — |
| 30 | event | 경조사 지원 | 「경조사 지원 / 경조사/생일 등 지원」 `txt/personnel_system.txt:56-57` · 「경조사/생일자 선물대 등 지원」 `txt/greeting_welfare.txt:4` | 복리후생 | — |
| 31 | child_edu | 자녀 학자금 (중·고·대학교) | 「학자금 지원 / 자녀 중/고/대학교 학자금」 `txt/personnel_system.txt:73-74` · `txt/greeting_welfare.txt:19-20` | 복리후생 | — |
| 32 | parenting | 출생 축하 지원금 (자녀·손자녀 출산 시 최대 1천만원) | 「출생 축하 지원금 운영 / 임직원 자녀/손자녀 출산 시 / 축하금(최대 1천만원) 지급)」 `txt/personnel_system.txt:85-87` · 「자녀 및 손자녀 출산 시 출생 축하 및 양육 지원금을 지급하고 있습니다.」 `txt/human_rights_capital.txt:39` (같은 문장 정책 PDF `hc_policy.txt:66` 3쪽) · 채용 사이트 「출산축하금 운영 / 임직원 자녀/손자녀 출산 시 축하금 지급」 `txt/greeting_welfare.txt:31-32` | 복리후생 · 인적자본 페이지 | — |
| 40 | resort | 숙박비 지원 (호텔·콘도) | 「숙박비 지원 / 호텔/콘도 등 비용 지원」 `txt/personnel_system.txt:58-59` · 「호텔/콘도 등 이용 시 비용 지원」 `txt/greeting_welfare.txt:6` | 복리후생 | — |
| 41 | club | 사내 동호회 (봉사·풋살·레포츠회 등) | 「사내 동호회 운영 / 봉사/풋살/레포츠회 등」 `txt/personnel_system.txt:77-78` · 「봉사/풋살/레포츠회 등 동호회(인포멀) 운영」 `txt/greeting_welfare.txt:24` | 복리후생 | — |
| 42 | company_event | 야유회 (연 1회) | 「야유회 실시 / 연 1회 실시」 `txt/personnel_system.txt:83-84` · 「직원 단합을 위한 야유회 실시」 `txt/greeting_welfare.txt:30` | 복리후생 | — |
| 50 | summer_leave | 하계휴가 (유급 5일) | 「휴가 제도 / 연차휴가 및 하계휴가 / (유급 5일) 부여」 `txt/personnel_system.txt:60-62` · 「휴가(연차/장기근속/하계휴가), 유연근무제 시행」 `txt/greeting_welfare.txt:8` | 복리후생 | — |
| 51 | long_service_leave | 장기근속 휴가 | 「휴가/유연근무제 / 휴가(연차/장기근속/하계휴가), 유연근무제 시행」 `txt/greeting_welfare.txt:7-8` | 채용 사이트 복리후생 | 맨 칩 |
| 60 | meal | 구내식당 (조·중·석식 무료 제공) | 「구내식당 운영 / 조/중/석/야식 무료 제공」 `txt/personnel_system.txt:63-64` (채용 사이트 「식사 제공(구내식당 內 조/중/석/야식 운영)」 `txt/greeting_welfare.txt:10`) | 복리후생 | — |
| 61 | housing_loan | 주택자금 지원 (주택구입·전세자금) | 「주택자금 지원 / 주택구입/전세자금 지원」 `txt/personnel_system.txt:75-76` · `txt/greeting_welfare.txt:21-22` | 복리후생 | — |
| 62 | birthday_gift | 생일자 선물 | 「경조사/생일 등 지원」 `txt/personnel_system.txt:57` · 「경조사/생일자 선물대 등 지원」 `txt/greeting_welfare.txt:4` | 복리후생 경조사 지원 | — |
| 70 | medical | 본인·가족 의료비 지원 | 「의료비 지원 / 본인/가족의료비 지원」 `txt/personnel_system.txt:69-70` · `txt/greeting_welfare.txt:15-16` | 복리후생 | — |
| 71 | health_check | 종합검진 (임직원·배우자) | 「건강검진 지원 / 종합검진 실시(임직원/배우자)」 `txt/personnel_system.txt:71-72` · `txt/greeting_welfare.txt:17-18` | 복리후생 | — |
| 72 | fitness | 헬스장·샤워실 운영 | 「헬스장/샤워실 운영 / 사내 복지시설 운영」 `txt/personnel_system.txt:79-80` · 「사내 복지시설 운영 / 샤워장/헬스장/수유실 등 운영」 `txt/greeting_welfare.txt:25-26` | 복리후생 | — |
| 73 | insurance | 단체상해보험 (전 직원 가입) | 「단체상해보험 가입 / 전직원 가입」 `txt/personnel_system.txt:81-82` · 「정기 건강검진 및 직원 단체상해보험 가입 등을 통해 임직원과 가족의 건강을 보살피고 있습니다.」 `txt/human_rights_capital.txt:41` | 복리후생 · 인적자본 페이지 | — |
| 80 | flex_work | 유연근무제 (시차출퇴근제·탄력적 근로시간제) | 「휴가(연차/장기근속/하계휴가), 유연근무제 시행」 `txt/greeting_welfare.txt:8` · 「시차 출퇴근제, 탄력적 근로시간제 등 개별 상황에 맞춘 유연한 일과 생산성을 장려합니다.」 `txt/human_rights_capital.txt:37` (정책 PDF `hc_policy.txt:62`) · 반기 「시차출퇴근제 사용자 수 | 1 | 0 | -」 `dart_txt/20260814003148.txt:15638-15641` | 채용 사이트 · 인적자본 페이지 · 2026 반기보고서 | 맨 칩 |
| 90 | nap_room | 수유실 | 「샤워장/헬스장/수유실 등 운영」 `txt/greeting_welfare.txt:26` | 채용 사이트 복리후생 | — |

## 3. 코드 판단

- 10 `lang`: 정본 「자기계발 지원 — 사내교육, 외국어 학원 등 지원」은 복합 라벨 — 외국어 학원 몫만 `lang` 에 넣고, 「사내교육」은 내용 없는 업무 교육으로 보아 `edu_support` 행을 만들지 않았다(8절 판단 요청 1). 「진급자 어학성적 평가」는 승진 요건이라 뺐다.
- 20 `incentive`: 채용 사이트가 PI · PS 를 한 줄에 적음 → 어휘 경계대로 `incentive`(`profit_sharing` 아님).
- 21 · 22: 원문 「우수사원/장기근속 포상」 한 줄을 코드별로 가름(`excellence_award` · `long_service_bonus`). 채용 사이트가 장기근속을 휴가 줄(「휴가(연차/장기근속/하계휴가)」)과 포상 줄에 따로 적어 → `long_service_leave`(51) 와 `long_service_bonus`(22) 두 행(경계 「원문이 휴가와 포상을 다른 항목으로 나누면 두 행」).
- 30 · 62: 「경조사/생일 등 지원」 → 경조사는 `event`, 생일(채용 사이트 「생일자 선물대」)은 `birthday_gift`. 각 행은 자기 몫 구절만 인용.
- 50 `summer_leave`: 「연차휴가 및 하계휴가 (유급 5일) 부여」 — 괄호가 하계휴가 바로 뒤라 하계휴가 5일로 읽음(8절 판단 요청 2). 연차는 법정이라 뺐고 「연차」 낱말은 서술에서 걷었다.
- 72 · 90: 채용 사이트 「샤워장/헬스장/수유실 등 운영」 → 헬스장 · 샤워장은 `fitness`, 수유실은 `nap_room`(경계 「수유 · 모성 시설만」). 샤워실은 헬스장과 한 라벨이라 `fitness` 이름에 남김.
- 80 `flex_work`: 탄력적 근로시간제 · 시차출퇴근제 = `flex_work`(어휘 경계 「법정이 아니다」).
- 신규 코드: 없음.

## 4. 법정 제도

- 걷은 문구: 「연차휴가」(정본 휴가 제도 줄 · 채용 사이트 휴가 줄) · 인적자본 페이지 「임신기 및 육아기 근로시간 단축 근무, 남녀 출산휴가 및 육아휴직, 복직 시 기존 직무 복귀」(전부 법정 — 상회분을 밝히지 않음) · 「정기 건강검진」(인적자본 페이지 — 법정 일반검진과 가를 수 없어 인용하지 않음, 종합검진 행은 정본 문장만) · 채용 사이트 「임직원 보호 및 산재보험 보완」(산재보험 낱말이 서술에 들어가지 않게 인용하지 않음) · 법정의무교육 · 산업안전보건교육 · 중대재해예방교육.
- 상회분 판정: 법정 일수를 넘는다고 밝힌 휴가 · 휴직 문장 없음.
- 직원 수 · 재취업지원: 2026 반기 직원 합계 139명(남 128 · 여 11 — `dart_txt/20260814003148.txt:15519` 이하 직원 등 현황 표) — 1,000명 미만. 재취업 · 전직지원 원문 없음.
- 🚨 11-27 재계산 대상: 없음(난임 치료 휴가 · 난임 지원 원문 0건).

## 5. 금액

| SORT | 코드 | 원문 숫자 | 산식 | ④ 예측 | 갈래 |
|---|---|---|---|---|---|
| 60 | meal | 「조/중/석/야식 무료 제공」(단가 없음) | 하루 3끼(조 · 중 · 석) × 12,000원 × 240일 = 864만원 · 야식은 세지 않음 | estimated | §3-3 ④ 식대 |

숫자가 있지만 비운 것:

| SORT | 원문 | 비운 이유 |
|---|---|---|
| 32 | 「축하금(최대 1천만원) 지급」 | 1회성 · 상한(「최대」) → NULL · 이름 · 서술에 숫자 그대로 |
| 50 | 「(유급 5일)」 | 일수 — 금액 아님 |
| 42 | 「연 1회 실시」 | 횟수 — 금액 아님 |
| 80 | 시차출퇴근제 사용자 수 1 | 통계 — 금액 아님 |

## 6. 제외 목록

| 원문 | 이유 |
|---|---|
| 연차휴가(정본 · 채용 사이트) | 법정 |
| 임신기 · 육아기 근로시간 단축 · 남녀 출산휴가 · 육아휴직 · 복직 시 기존 직무 복귀(인적자본 페이지 · 정책) | 법정 · 상회분 없음 |
| 공통역량 교육(법정의무 · 산업안전보건 · 고객만족 · 직장 내 예절 · 중대재해예방 · 가족친화 · 준법/윤리) | 법정 · 업무 교육 |
| 계층역량 교육(신입 OJT · 그룹사 신입 · 신입 멘토링 · 중간관리자 · 직책자 리더십 · 최고경영자 · 진급대상자) | 업무 교육 |
| 직무역량 교육 사외교육(직급별 실무역량 · 전문성 향상) · 사이버연수원(사내) | 업무 교육(직급별 · 직무역량 칸 — 자율 수강이라는 문장 없음 · 판단 요청 3) |
| 진급자 어학성적 평가 | 승진 요건 |
| 「자기계발 지원」 중 「사내교육」 | 업무 교육(판단 요청 1) |
| 직급별 차등 보상 · 평가등급에 따른 임금 인상 차등 | 임금 구성 · 급여 조정 |
| 원격근무제(재택근무 포함) 사용자 수 — 반기 0 · 0 · -, 사업보고서 0 · - · - | 자기 출처 문장 없음 · 세 기간 모두 0 · - (웨이브 7 규칙) |
| 선택근무제 사용자 수 — 반기 0 · 0 · -, 사업보고서 0 · - · - | 사용자 0 · 자기 출처에 선택근무 문장 없음 |
| 우리사주조합(반기 주주 표 한 칸 · 정관 신주 배정 조항) | 제도 문장 없음(주주 표 · 정관) |
| 이사 보수지급기준 「임직원 복리후생 제도 적용(자녀 학자금, 의료비 지원 등)」 · 「정기상여 및 경영성과에 따른 성과급」 | 임원 보수 칸 |
| 장애인 근로자 멘토링 · 노사신뢰협의회 · 고충처리위원회 · 만족도 조사 | 복지 급부 아님 |
| 봉사 인포멀 「등대」 사회공헌 문단(채용 사이트 management) | 동호회 행(41)의 봉사 몫과 같은 제도 — 별 행 아님 |

유연근무제도 사용 현황 세 기간 그대로: 반기(2026 반기 · 2025 · 2024) 활용 여부 Y · Y · N / 시차출퇴근 1 · 0 · - / 선택근무 0 · 0 · - / 원격근무 0 · 0 · -(`dart_txt/20260814003148.txt:15628-15649`). 사업보고서(2025 · 2024 · 2023) 활용 여부 6 · - · 8 / 시차 0 · - · - / 선택 0 · - · - / 원격 0 · - · -(`dart_txt/20260604000337.txt:21175-21196`). 「미도입」 표기 없음.

## 7. 낱말 스윕 · 항목 페이지

③ 검출:
- SORT 60 meal NOTE 「추정」 — 허용(식대 꼬리 표지).
- SORT 80 flex_work NM · QUAL 「시차출퇴근」 · 「시차 출퇴근」 — 허용(확인 어휘 · 법정 아님).
- SORT 90 nap_room 「수유」 — 면제(시설 · 법정은 수유 시간).

⑤ 항목 페이지(설정 있는 19행): lang both · remote · test(전화 외국어 · 어학 검정 · 학원) · incentive company · target(PS 낱말 — PI 는 규칙상 개인 쪽으로 안 셈) · excellence_award excellent · long_service_bonus unknown · event — · child_edu university · parenting cash · resort paid · club kinds · summer_leave days · paid · long_service_leave leave · meal canteen · breakfast · dinner · free · overtime(원문 야식 무료 제공) · housing_loan unknown · buy · lease · birthday_gift gift · medical family · health_check comprehensive · family · fitness inhouse · insurance — · flex_work start. 전부 원문 뜻과 맞음 — 문안 수정 · 예외 후보 없음.

## 8. 판단 요청

1. **「자기계발 지원 — 사내교육, 외국어 학원 등 지원」의 「사내교육」 몫** — 기본안: `edu_support` 행을 만들지 않는다(사내교육은 내용이 없는 업무 교육 · 외국어 학원 몫은 `lang` 10 에 이미 있음). 대안: `edu_support` 「자기계발 지원 (사내교육)」 정성 행 1 추가(복리후생 목록의 이름 있는 항목이라는 근거).
2. **「연차휴가 및 하계휴가 (유급 5일) 부여」의 5일이 누구에게 걸리나** — 기본안: 하계휴가 5일(괄호가 하계휴가 바로 뒤 · 연차는 일수가 근속별이라 5일 고정일 수 없음) → `summer_leave` 「하계휴가 (유급 5일)」. 원문이 하계휴가를 본인 연차로 쓴다고 밝히지 않으므로 싣는다.
3. **사이버연수원(사내)** — 기본안: 싣지 않는다(정본 「직무역량 교육」 칸 · 자율 수강 · 교양 문장 없음). 대안: 학습 플랫폼으로 보고 `edu_support`.

## 9. 이메일 도메인 관측

`@lsmaterials.co.kr` — 정본 꼬리말 채용 · IR · 제품 문의처(개인 이름 메일 포함 — 옮기지 않음) · 채용 사이트 꼬리말 채용 문의처. 법인 고유 도메인(LS 그룹 공용 도메인 아님). MX 미확인.

## 10. 배포 시 주의

- 정본 점검기 `ok`(SSR · keyword True) — 특이 조건 없음. robots Crawl-delay · Visit-time 없음.
- 공고 근거 0행 — 한시적 출처 없음.
- 식대는 꼬리 식 그대로 — SI-9 허용 목록 추가 불필요.
- 등록 값: slug `ls_materials` · `mid` · INDUSTRY_NM `전자부품`(기존 값 4사 — LG이노텍 · 삼화콘덴서공업 · 비에이치 · 삼성전기) · LOGO `L` · OpenDART `induty_code` 26291(축전기 제조업 계열 — 리드 명단 `dart/company-15.json`). 업종 사유: 주력이 울트라커패시터 셀 · 모듈(축전기 — 전자부품)로 같은 축전기 업체 삼화콘덴서공업이 `전자부품`. `배터리소재`(에코프로비엠 · 엔켐 등 양극재 · 전해액 소재사)는 완제 저장장치 제조와 맞지 않아 고르지 않음.

## 11. 확인하지 못한 것

- 2025 ESG Report 본문(다운로드 링크가 「현재 준비중」 알림 — 발행 전). 발행되면 복리후생 표 · 숫자 보강 가능.
- 영문판(`/ennew/…`) 인사제도 페이지 — 국문 상시 페이지가 있어 받지 않음.
- 열린 공고 2건 본문 이미지(`/upload/image/ZEBEG97PND.png` · `FK9C9U9THD.png`) — 근거가 필요 없어 받지 않음(판독 0).
- 메일 MX.
