# 웨이브 3 프로브 결과 · 선발표 (W-0 → W-1, 2026-09-14)

프로브 16 → **가능 11 · 조건부 3 · 불가 2** → 수집 진입 **12**(가능 11 + 조건부 더존비즈온). 프로브 통과율 12/16(75%, 웨이브 1 73% · 웨이브 2 88%).
선발 규칙(웨이브 2 그대로): 데이터랩 수요 순 · 업종 균형 · 금융 ≤3 · HD그룹 ≤2 · 공기업 제외 · 지주는 채용 주체 등재 먼저.
대기열에서 뺀 것: 대우건설(erecruit robots `Disallow: /` 26B 재확인 2026-09-14) · 한화솔루션(법인 전용 페이지 없음, 재프로브 조건 미충족) · 테스(수요 표 오염) · OCI홀딩스(지주 ≠ 사업회사) · 삼성에피스홀딩스(2025-11 설립, 재무 이력 부족).

재무·직원 3축(리드 확인, DART API 2026-09-14): 16사 전부 2025 사업보고서 재무 계정·직원 현황 있음. 금융 4사의 `fnlttSinglAcnt` 2021 = 013 은 기등록 NH투자증권·KB금융도 같아 엔드포인트 한계(데이터 결측 아님). 루닛 2021 = 013 은 2022-07 상장이라 정당한 결측(LG CNS 선례).

| # | 회사 | 시장/종목 | corp_code | 판정 | 정본 URL | 항목 | 렌더 | eng(slug) | 유형 | 업종(제안) | 로고 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 포스코인터내셔널 | KOSPI 047050 | 00124504 | 가능 | www.poscointl.com/welfare | 24 | SSR | posco_intl | large | (합류 값 없으면 수집기 판단) | P |
| 2 | 포스코퓨처엠 | KOSPI 003670 | 00155276 | 가능 | www.poscofuturem.com/recruitment/personnel.do | 38(법정 ~6 제외) | SSR(형제 컨테이너 분할) | posco_futurem | large | 배터리소재 | P |
| 3 | 키움증권 | KOSPI 039490 | 00296290 | 가능 | www3.kiwoom.com/h/ir/recruit/VWelfareView | 16 | SSR 라벨 | kiwoom | large·금융 | 증권 | K |
| 4 | 삼성증권 | KOSPI 016360 | 00104856 | 가능 | www.samsungsecurities.co.kr/kor/recruit/benefit.do (+samsungcareers E40) | 24(4대보험 제외 23) | SSR 라벨 | samsung_sec | large·금융 | 증권 | S |
| 5 | SK바이오팜 | KOSPI 326030 | 00878696 | 가능 | www.skbp.com/kor/sustainability/talent.do | 16줄(~24) | SSR | sk_biopharm | large | 제약 | S |
| 6 | 대한전선 | KOSPI 001440 | 00113207 | 가능 | www.taihan.com/company/talentSystem | 8 | SSR | taihan | large | 전선/전력 | T |
| 7 | 에스티팜 | KOSDAQ 237690 | 00871833 | 가능 | www.stpharm.co.kr/ko/careers (+talent.dongasocio.com HRF102040 법인 전용) | 12+13(합집합 ~17) | SSR | stpharm | mid | 제약 | S |
| 8 | 로보티즈 | KOSDAQ 108490 | 00946030 | 가능 | robotisrecruiter.ninehire.site/welfare | 10 | Next SSR(__NEXT_DATA__ 필터) | robotis | mid | 로봇 | R |
| 9 | 루닛 | KOSDAQ 328130 | 01397620 | 가능 | www.lunit.io/ko/careers/ | 9(채택 7~8) | SSR | lunit | mid | AI/의료 | L |
| 10 | 씨젠 | KOSDAQ 096530 | 00788773 | 가능 | seegene.recruiter.co.kr/career/welfare | 20(법정 1 제외) | CSR + 빌더 JSON(KAI 선례) | seegene | mid | 의료기기 | S |
| 11 | 더존비즈온 | KOSPI 012510 | 00172291 | **조건부 → 진입** | www.douzone.com/job/benefits.jsp (+공고 REM2026048 이미지, 09-16 마감 — 원본·해시 확보) | 8(+공고 9) | SSR + PNG | douzone | mid | IT서비스 | D |
| 12 | 가온전선 | KOSPI 000500 | 00104768 | 가능 | gaoncable.recruiter.co.kr/appsite/company/callSubPage?code1=4000&code2=4600 (데이터 = POST getMainView menuCode 4600) | 13 | JS 렌더(잡플렉스 appsite) | gaon_cable | mid | 전선/전력 | G |
| — | HD현대일렉트릭 | KOSPI 267260 | 01205851 | **조건부 → 보류** | recruit.hd.com 그룹 공통 복지(HD현대와 청크 바이트 동일, 「계열사간 일부 상이」) | 18 | JS 청크 | — | — | — | — |
| — | 두산밥캣 | KOSPI 241560 | 01032486 | **조건부 → 보류** | career.doosan.com benefit1·2(그룹 공통, 「계열사 별 상이」 면책) | 7+9 | SSR | — | — | — | — |
| — | 한국금융지주 | KOSPI 071050 | 00432102 | **불가**(법인 일치) | 그룹 포털에 지주 등재는 있으나 복지 메뉴 없음 · 그룹 SR 표는 증권 전용 항목 혼입 | 0 | — | — | — | — | — |
| — | 미래에셋증권 | KOSPI 006800 | 00111722 | **불가**(항목 0) | 법인 채용사이트·회사소개·그룹 채용사이트 모두 복지 항목 0 | 0 | — | — | — | — | — |

## 선발 판단

- **더존비즈온 진입**: 복지 페이지는 더존비즈온이 운영하는 자기 도메인(푸터·TLS O=더존비즈온)에 있으나 경로가 「더존ICT그룹」이고 채용 포털에서 5개 법인 코드가 공유한다. 공고 176건 중 164건(93%)이 더존비즈온이고, 「사내어린이집(강촌캠퍼스)」은 더존비즈온 본사다. 「계열사별 상이」 면책은 없다. → HD현대 선례대로 benefits.jsp 행에는 전 행 「(그룹 통합 채용 기준)」 각주. 모집회사=더존비즈온으로 명시된 공고 REM2026048 이미지(09-16 23시 마감, `scratchpad/probe/douzone/post_*.png` sha256 기록)는 법인 확정 보조 출처로 교차 확인에 쓴다.
- **HD현대일렉트릭 보류**: 이 출처로는 기등록 HD현대와 다른 행을 하나도 만들 수 없다(웨이브 1 「계열사 상세 복제 전개 금지」). 공고 본문 API 는 미검증 — 법인 고유 복지가 공고에 나오면 재프로브.
- **두산밥캣 보류**: 한화솔루션 유형(그룹 공통 + 면책). 국내 인력이 본사 사무직 150명 규모라 그룹 공통 복지를 붙이면 귀속이 더 흐려진다.
- **금융 2사**(키움증권·삼성증권) → `load_corp.py` FINANCIAL_COMPANIES +2(10→12), 금융 지표 세트.
- 씨젠의 빌더 JSON 호스트 robots(api-recruiter `Disallow: /`·infra1-static 403)는 웨이브 2 KAI 와 같은 구조 — 페이지 경로 허용 기준으로 가능 유지.

## 프로브가 스스로 보고한 절차 이탈 (다음 계약에 반영)

- robots 확인 전 금지 호스트에 1회 요청: 에스티팜(donga.recruiter.co.kr `/career/benefit` 500·0B) · 대한전선(hoban.recruiter.co.kr `/` 301→로그인 0B) · 포스코퓨처엠(recruit.posco.com `/` 85B, robots 요청 TLS 리셋 후). 본문 근거로 쓴 것 0. → **robots.txt 를 단독으로 먼저 받고 판정한 뒤 본문 요청**을 계약 문구로 명시.
- 가온전선: robots 판독 전 같은 묶음으로 금지 경로 3건(`/sitemap.xml`·`/career/home`·`/career/benefit`, 전부 500) · Playwright 4회의 하위 리소스가 robots 금지 경로(`/resources-2.0.3a/*.js`·`/app/*`) 포함. 수집은 `POST /appsite/company/getMainView`(appsiteSn=2331, settingType=B) 직접 호출로만, **메뉴 4600 만**(비활성 4400·4500 에 ATS 벤더 샘플 문구 — 「2014년 대졸 최소 4,000만원」·자동승진·종신고용 — 유령).
- 요청 한도 초과: 키움증권 50회(Playwright 하위 리소스 39). 헤드리스 렌더는 원본 HTML 에 항목이 없을 때만.
- 요청 간격: 더존비즈온 Playwright 렌더 3회 동시.

## 수집 재개 절차 (세션 재시작 후)

1. effort 확인: 이 세션은 `.claude/agents/wave-*.md` 를 세션 시작 때 읽지 못했고, 팀원 투입이 없는 유형을 일반 팀원으로 조용히 바꿔 띄워 프로브 16개가 xhigh 로 돌았다. 프로젝트 로컬 `.claude/settings.local.json` 에 `modelSettings.claude-opus-5.effortLevel: high` 를 넣었다(재시작 후 반영 — 웨이브 끝나면 되돌린다). 재시작 뒤 짧은 시험 팀원(`wave-collect` 유형)으로 트랜스크립트 `"effort":"high"` 를 확인하고 나서 수집을 띄운다.
2. 수집(Opus high) 12사를 **6·6 두 묶음**으로(웨이브 2: 13개 동시 → 11분 만에 8개가 세션 한도로 끊김). 묶음 A: 포스코인터내셔널·포스코퓨처엠·키움증권·삼성증권·SK바이오팜·대한전선 / 묶음 B: 에스티팜·로보티즈·루닛·씨젠·더존비즈온·가온전선. 계약 `_COLLECT-CONTRACT.md`, 파일명 = 회사명 그대로(`삼성증권.sql`), slug·유형·업종·로고 = 위 표.
3. 검증(Fable high) 2사씩 6에이전트, 동시 ≤3 → 횡단 감사(Opus xhigh) 1 → 통합(Opus high) 1 → 리드가 등록 접점(corp_code_map·krx_sector·별칭·이메일·FINANCIAL +2·핀·company_registrations.json) → `bash infra/deploy/run_tests.sh` → PR.
