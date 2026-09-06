# 웨이브 2 프로브 결과 · 선발표 (W-0 → W-1, 2026-09-05)

프로브 16 → **가능 11 · 조건부 3 · 불가 2** → 수집 진입 **13** (조건부 중 삼양식품·KAI 진입, 한화솔루션 보류).

| # | 회사 | 시장/종목 | 판정 | 정본 URL | 항목 | 렌더 | eng(slug) | 유형 |
|---|---|---|---|---|---|---|---|---|
| 1 | 삼성중공업 | KOSPI 010140 | 가능 | samsungshi.com/Ko/Welfare.aspx | 30 | SSR(설명은 data-tip 속성) | samsung_heavy | large |
| 2 | LG이노텍 | KOSPI 011070 | 가능 | www.lginnotek.com/recruit/worklife.lgit | 20 | SSR(주석 유령 4) | lg_innotek | large |
| 3 | 대덕전자 | KOSPI 353200 | 가능 | www.daeduck.com/ko/content/welfaresystem.do | 18(+교육 5) | SSR | daeduck | mid |
| 4 | 삼성화재 | KOSPI 000810 | 가능 | samsungcareers.com/subsid/detail/E21 | 30 | SSR(법인 전용 페이지) | samsung_fire | large·금융 |
| 5 | 삼성SDS | KOSPI 018260 | 가능 | samsungcareers.com/subsid/detail/C60 | 23 | SSR(법인 전용 페이지) | samsung_sds | large |
| 6 | 삼성E&A | KOSPI 028050 | 가능 | samsungena.com/kr/careers/company-life (+samsungcareers D80) | 23(+29 설명) | SSR | samsung_ena | large |
| 7 | 이수페타시스 | KOSPI 007660 | 가능 | www.petasys.com/kor/recruit/recruit02.jsp | 25(라벨) | SSR | isu_petasys | mid |
| 8 | 셀트리온제약 | KOSDAQ 068760 | 가능 | www.celltrionph.com/ko-kr/career/welfare | 17 | SSR | celltrion_pharm | (셀트리온 선례) |
| 9 | 넷마블 | KOSPI 251270 | 가능 | company.netmarble.com/hr/system (+career 16, 컴퍼니 공통) | 15(라벨) | SSR(탭 CSS 숨김) | netmarble | large |
| 10 | 동진쎄미켐 | KOSDAQ 005290 | 가능 | dongjin.careerlink.kr/welfare (+본사 JPEG 15) | 9+15 | __NEXT_DATA__ + 이미지 | dongjin_semichem | mid |
| 11 | 한화생명 | KOSPI 088350 | 가능 | company.hanwhalife.com/ko/recruitment/welfare | 5블록/18 | SSR | hanwha_life | large·금융 |
| 12 | 삼양식품 | KOSPI 003230 | 조건부(PNG) | www.samyangfoods.com/kor/recruit/recruit.do | 10(법정 2 제외 8) | 이미지 1장, WAF UA 차단 | samyang_foods | mid |
| 13 | 한국항공우주산업 | KOSPI 047810 | 조건부(PNG) | www.koreaaero.com/KO/Sustainability/WelfareSystem.aspx (+ATS benefits 12) | 29+12 | 이미지 + Next CSR | kai | large |
| — | 한화솔루션 | KOSPI 009830 | **보류**(조건부) | 인사이트부문 도메인의 그룹 공통 11항목 — 「시행 여부는 계열사별 상이」 면책. 부문은 케미칼·큐셀·인사이트 3개(첨단소재는 별도 계열사) | — | — | — | HD현대중공업 유형 — 법인 전용 복지 페이지 생기면 재프로브 |
| — | 대우건설 | KOSPI 047040 | **불가**(robots) | erecruit.daewooenc.com `Disallow: /` | — | — | — | 재시도 감시 = robots 26B |
| — | 신한지주 | KOSPI 055550 | **불가**(지주) | 지주 채용 주체 등재 없음(하나·우리 동형) | — | — | — | 은행지주 구조 3사째 |

프로브 통과율 14/16(88%, 웨이브 1 73%). 그룹 분포: 삼성 4(각 법인 전용 페이지) · 한화 1 · KOSDAQ 2 · 금융 2.
DART corp_code: `scratchpad/corp_codes_wave2.csv` (16사 전부 종목코드 정확 매칭, DART 명 「한국항공우주」·「삼성화재해상보험」).
