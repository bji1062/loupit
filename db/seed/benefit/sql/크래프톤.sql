-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 크래프톤 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://www.krafton.com/careers/life/
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 크래프톤 공식 사이트 Careers 라이프 페이지의 지원제도 탭 (www.krafton.com/careers/life/). 서버 렌더 HTML
--     본문에 4묶음 22항목(일하기 즐거운 6 · 함께 성장하는 4 · 생활이 편리한 8 · 건강을 책임지는 4)이 들어 있다(헤드리스 불필요).
--     채용공고(Greenhouse 임베드) 본문이 크래프톤 라이프 및 복리후생 링크로 이 주소를 가리킨다.
--     robots.txt = User-agent: * / Disallow: /wp-admin/ 뿐(2026-09-28 확인). 본문 sha256 cca08d98…dd37d2fd5e.
--   보조 = 크래프톤 2025 ESG REPORT(PDF 114쪽, 2026-07-13 작성, www.krafton.com/ir/esg/ 에서 링크)
--     p.26 통근버스 · p.35 사외 교육 · p.36 보상 · p.37 일·가정 양립 · 근무지원 제도 · p.38 복리후생 표 · p.44 건강 증진 · p.79 우리사주.
--     www.krafton.com/wp-content/uploads/2026/07/KRAFTON-ESG-REPORT-2025_0713_v.2.pdf sha256 9fbd1024…af840d56a9b.
--   스튜디오(펍지 스튜디오 · 블루홀스튜디오 등) 전용 처우는 섞지 않았다. 법인 자기 도메인 페이지라 그룹 각주 없음.
--   법정 제도 제외: 임신기 · 육아기 근로시간 단축 · 임산부 정기건강진단 시간 · 난임치료 휴가 · 유사산 휴가 ·
--     출산전후 휴가 · 배우자 출산 휴가 · 야간 휴일근무 보상휴가는 행이 아니다.
--   금액: 원문 연액 1(parenting 자녀돌봄 지원금 연 500만 원) · 구본 추정 승계 5(meal · commute_subsidy · resort ·
--     insurance · health_check) · 구본 공식 수치 미승계 2(fitness 월 10만 원 · birthday_leave 5만 원 — 원문에 숫자 없음).
--   재코딩 1(leave_general 명절 반차 → holiday_gift 명절 선물) · 구본 삭제 2(satellite_office · books) · 신규 코드 0.
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): 조치 없음 — parenting 500 은 ESG p.37 연 500만 원 지급 + 보도자료 미사용액 현금 환급으로 지급액 확인 · 956 leave_general → holiday_gift 재코딩 · 958 · 970 표적 삭제 — 최종 27행
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('krafton', '크래프톤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'K', 'https://www.krafton.com/careers/life/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'krafton');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.krafton.com/careers/life/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 라이프 일하기 즐거운 1·2 · 함께 성장하는 3 · 생활이 편리한 4·5 · ESG p.26·38
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '합리적인 가격의 구성원 전용 사내 카페 운영 (공식 채용 페이지 라이프 지원제도 사내 카페 항목)', 10),
  (@comp_id, 'meal', '사내 식당 (조식·중식·석식)', 864, 'perks',
   'est', '조식, 중식, 석식을 모두 제공하는 사내 식당 운영 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 11),
  (@comp_id, 'team_dinner', '워크샵 지원', NULL, 'perks',
   'est', NULL, TRUE, '외부 활동으로 팀워크를 다지고 동료와 소통하도록 워크샵 지원 (공식 채용 페이지 워크샵 항목) — 지원 금액·횟수 미기재', 12),
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '주거 안정을 위한 주택자금대출 및 주택자금대출 이자지원제도 운영 (공식 채용 페이지 주택자금대출 항목), 정규직 대상 (2025 ESG 보고서) — 대출 한도·이자 지원율 미기재', 13),
  (@comp_id, 'commute_subsidy', '출근버스', 120, 'perks',
   'est', '대중교통 이용 불편을 줄이기 위한 출근 버스 운행, 역삼·서초·판교 거점별 및 강남역–역삼역 구간 셔틀버스 (2025 ESG 보고서) (추정)', FALSE, NULL, 14),

  -- ── 시간·휴가 (time_off) ── 라이프 일하기 즐거운 3·4·6 · ESG p.38
  (@comp_id, 'long_service_leave', '리프레시·장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '입사 후 매 3년 근속마다 리프레시 휴가, 매 5년 근속마다 장기근속 기념품과 포상휴가 (공식 채용 페이지 리프레시 휴가·장기근속 항목). 2025 ESG 보고서에는 매 5년 근속 시 장기근속 기념품과 가족여행 상품권 지급으로 기재, 정규직 대상 — 휴가 일수 미기재', 20),
  (@comp_id, 'birthday_leave', '생일 상품권·반일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일날 상품권과 반일 특별휴가 제공 (공식 채용 페이지 생일과 명절 항목 · 2025 ESG 보고서) — 상품권 금액 미기재', 21),

  -- ── 여가·라이프 (leisure) ── 라이프 일하기 즐거운 5 · 생활이 편리한 8
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '취미와 자기계발을 위한 사내 동호회 운영 (공식 채용 페이지 동호회 항목) — 활동비 지원 여부 미기재', 30),
  (@comp_id, 'resort', '리조트 지원', 50, 'leisure',
   'est', '가족 혹은 지인과 함께 쉴 수 있는 리조트 지원 (공식 채용 페이지 리조트 항목) (추정)', FALSE, NULL, 31),

  -- ── 보상 (compensation) ── 라이프 일하기 즐거운 6 · ESG p.38·보상·우리사주 절
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 제공 (공식 채용 페이지 생일과 명절 항목 · 2025 ESG 보고서) — 선물 내용·금액 미기재', 40),
  (@comp_id, 'profit_sharing', '단기 성과급 (PS)', NULL, 'compensation',
   'est', NULL, TRUE, '단기 성과급(STI)을 PS(Profit Sharing) 방식으로 운영해 연간 조직 성과 공유 (2025 ESG 보고서 보상 항목) — 지급률 미기재', 41),
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '2021년 KOSPI 상장과 함께 우리사주제도 도입, 우리사주조합 운영 (2025 ESG 보고서) — 회사 지원 내용 미기재', 42),

  -- ── 성장·커리어 (growth) ── 라이프 함께 성장하는 1·2 · ESG p.35 사외 교육 지원제도
  (@comp_id, 'edu_support', '사외 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '역량 강화를 위한 직무교육과 자기계발 교육 지원 (공식 채용 페이지 사외 교육 항목). 국내외 온·오프라인 직무 역량 향상 교육, 직무 관련 세미나·컨퍼런스 참석, 해외 온라인 교육 과정, 국가 공인 교육기관 과정, 정규직·계약직 동일 적용 (2025 ESG 보고서 사외 교육 지원제도) — 지원 한도 미기재', 50),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어, 중국어, 일본어, 한국어 교육 지원 (공식 채용 페이지 외국어 교육 항목). 사내 지정 외국어 교육 기관을 통한 사외 어학 교육, 총 13개 언어 (2025 ESG 보고서) — 지원 한도 미기재', 51),
  (@comp_id, 'self_development', '자격증 취득 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 수행에 필요한 직무 관련 자격증 취득 비용 지원 (2025 ESG 보고서 사외 교육 지원제도) — 지원 한도 미기재', 52),

  -- ── 근무환경 (work_env) ── 라이프 함께 성장하는 4 · 생활이 편리한 6·7 · ESG p.38
  (@comp_id, 'work_tools', 'AI 업무 Tool 지원', NULL, 'work_env',
   'est', NULL, TRUE, 'ChatGPT Enterprise와 직무·직군별 AI Tool 제공 (공식 채용 페이지 AI 업무 Tool 지원 항목)', 60),
  (@comp_id, 'parking', '주차 지원', NULL, 'work_env',
   'est', NULL, TRUE, '자차 통근이 불가피한 구성원에게 주차 공간 지원 (공식 채용 페이지 주차 항목)', 61),
  (@comp_id, 'nap_room', '휴게시설', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자와 리클라이너가 비치된 휴식공간, 남녀 샤워실, 모유수유 공간 운영 (공식 채용 페이지 휴게시설 항목), 게이머스라운지 운영 (2025 ESG 보고서)', 62),

  -- ── 가족·돌봄 (family) ── 라이프 생활이 편리한 1·2·3 · ESG p.37·38
  (@comp_id, 'parenting', '출산·육아 지원', 500, 'family',
   'est', '2025년 1월 1일 이후 출산한 구성원에게 자녀당 출산장려금 6천만 원과 만 1~8세 자녀돌봄 서비스 및 지원금 연 500만 원(8년간 최대 4천만 원) 지급, 국내 법인 정규직 대상. 육아휴직 최대 2년, 배우자 산전 검사 휴가, 주말 일일 자녀돌봄 프로그램 운영 (2025 ESG 보고서 일·가정 양립 지원 제도)', FALSE, NULL, 70),
  (@comp_id, 'childcare', '직장 어린이집 리틀포레', NULL, 'family',
   'est', NULL, TRUE, '육아 부담을 줄이고 자녀의 건강한 성장을 돕도록 회사가 직접 운영하는 어린이집 (공식 채용 페이지 어린이집 항목). 리틀포레, 만 0~5세 미취학 자녀 대상, 역삼과 판교에서 운영 (2025 ESG 보고서)', 71),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 출산, 장례, 자녀 입학 등 경조사 지원 (공식 채용 페이지 경조사 항목) — 경조금·휴가 일수 미기재', 72),

  -- ── 건강·의료 (health) ── 라이프 건강을 책임지는 1~4 · ESG p.37·38·건강 증진 정책
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '구성원과 직계가족까지 포함하는 단체 의료보험 운영 (공식 채용 페이지 단체보험 항목 · 2025 ESG 보고서) (추정)', FALSE, NULL, 80),
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 구성원 건강검진 지원 (공식 채용 페이지 건강검진 항목 · 2025 ESG 보고서) (추정)', FALSE, NULL, 81),
  (@comp_id, 'fitness', '운동비 지원', NULL, 'health',
   'est', NULL, TRUE, '구성원의 건강 증진을 위해 매월 운동비 지원 (공식 채용 페이지 운동비 항목) — 월 지원 금액 미기재', 82),
  (@comp_id, 'mental', '마인드 케어', NULL, 'health',
   'est', NULL, TRUE, '스트레스나 부정적인 마음 상태의 회복을 돕는 전문 심리 상담 지원 (공식 채용 페이지 마인드 케어 항목), 복직자 심리상담 지원 (2025 ESG 보고서)', 83),

  -- ── 근무유연성 (flexibility) ── ESG p.37 근무지원 제도 · 일·가정 양립 지원 제도
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '코어타임을 제외한 업무시간을 구성원이 자율적으로 조정하는 선택적 근로시간제 운영 (2025 ESG 보고서 근무지원 제도)', 90),
  (@comp_id, 'remote_work', '자녀돌봄 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '자녀의 첫 입학과 새 학년 적응기, 방학기간 등 자녀돌봄이 필요한 시기에 재택근무 가능 (2025 ESG 보고서 자녀돌봄 유연근무제도)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
