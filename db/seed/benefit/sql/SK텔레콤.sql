-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK텔레콤 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('skt', 'SK텔레콤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '통신', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skt');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '사내 공모전 포상', NULL, 'compensation',
   'est', NULL, TRUE, 'IDEATHON 우승 시 상금 지급', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '자율 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '사무실/집/거점오피스 자율 선택', 10),
  (@comp_id, 'flex_work', '자율 근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '2주/4주 단위 80h/160h 자율 설정, 10분 단위 조절, 매달 둘째·넷째주 4일 근무', 11),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스 운영', 12),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', 'IT 장비 지원', 50, 'work_env',
   'est', '매년 IT기기 구매비 지원, 3년마다 최신형 노트북(개발자 맥북프로), 허먼밀러 의자 (추정)', FALSE, NULL, 20),
  (@comp_id, 'lounge', '라운지/휴게공간', NULL, 'work_env',
   'est', NULL, TRUE, 'Refresh zone(리클라이너/안마의자/헬스키퍼 상주), The Lounge 31층(바리스타 커피/간식)', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '체력단련 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 외 체력단련 휴가 5일, 본인 승인 휴가제', 30),
  (@comp_id, 'long_service_leave', '장기근속 휴가/포상', NULL, 'time_off',
   'est', NULL, TRUE, '5년마다 휴가30일+200만 또는 휴가10일+1000만 선택, 10년/20년 45일 유급 리프레시, 15년 추가 10일', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '최고 수준 건강검진 전액 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 200, 'health',
   'est', '본인 100% + 가족(부모/배우자/자녀/배우자부모) 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '심리상담실 상시 운영, 강북삼성병원 24시간 핫라인, 의무실 상시 운영', 42),
  (@comp_id, 'fitness', '사내 헬스센터', NULL, 'health',
   'est', NULL, TRUE, '액티움(Actium) 300평, 월1만원, 농구장, KPGA/KLPGA 프로 골프레슨, 스크린골프', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산휴가 90일(배우자10일), 육아휴직 남녀2년(2회 분할), 초등입학시 3개월 휴직', 50),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '푸르니 재단 행복날개 어린이집 사내 운영', 51),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원~대학교 학자금 전액 지원 (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사/생일 지원', 50, 'family',
   'est', '결혼/조사 지원, 생일 SK pay 포인트, 부모님 회갑~구순 축하금, 자녀 첫생일 축하금 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'Up-skilling Program: AI개발/서비스기획/네트워크/마케팅 등 직무별 전문가 육성', 60),
  (@comp_id, 'mba', '석사과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '온라인 해외 석사학위(Data Science/Computer Engineering/MBA) 입사 1년차부터 가능', 61),
  (@comp_id, 'books', '사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, 'T타워 18층 무인도서관, 3만권 이상, E-book 이용 가능', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '쏠비치 양양, 소노펠리체 비발디파크 등 230개 시설 임직원 할인 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '소모임 지원', 24, 'leisure',
   'est', '매달 1인 2만원 지원', FALSE, NULL, 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생비', 400, 'perks',
   'est', '매년 400만 포인트(가족검진40만+귀성비20만 등), 학원/여행/공연 등 사용', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', 'The Table 한식/아시안/양식/샐러드, 일 18,000원 x 240일', FALSE, NULL, 81),
  (@comp_id, 'telecom', '통신비 지원', 290, 'perks',
   'est', '매달 24만2천원까지 지원 (연 290만)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '사내 대출/주거지원', NULL, 'perks',
   'est', NULL, TRUE, '사내 대출 1억 한도, 주거 안정 자금 지원', 83),
  (@comp_id, 'snack_bar', '사내 카페/베이커리', 50, 'perks',
   'est', 'Café & Bakery 앱 주문/결제, 장보기포인트 매월 5만원 (추정)', FALSE, NULL, 84),
  (@comp_id, 'discount', '자사 서비스 할인', NULL, 'perks',
   'est', NULL, TRUE, 'SK나이츠 농구티켓, 해피셰어카(업무용 차량 개인이용)', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
