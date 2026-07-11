-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대한항공 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('korean_air', '대한항공',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공', 'D', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '경영성과급(PS/PI)', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급(PS,PI) 및 안전장려금 지급', 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택 지원', NULL, 'work_env',
   'est', NULL, TRUE, '김포, 부산, 김해, 제주 등 사택 지원', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 여행 지원', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 직원 여행 지원 및 정년퇴직 여행비 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 (전직원)', 100, 'health',
   'est', '특수항목 포함 (추정)', FALSE, NULL, 40),
  (@comp_id, 'clinic', '부속의원', NULL, 'health',
   'est', NULL, TRUE, '1차 의료 서비스 제공, 승무원 신체검사, 기초체력 측정/운동상담/영양상담/보건관리', 41),
  (@comp_id, 'fitness', '헬스클럽/수영장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스클럽 및 수영장 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '보육비 지원', NULL, 'family',
   'est', NULL, TRUE, '보육비 지원', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '국내 고등학생/대학생 학자금 지원, 해외 유학자녀 및 해외 주재원 자녀 학자금 지원', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼/회갑/고희/출산/사망 등 경조금, 화환 및 청원휴가 지원', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '대학원 장학금/교육', NULL, 'growth',
   'est', NULL, TRUE, '인하대 국제물류대학원, 항공대 특수 대학원 장학금 지원, Cyber Campus, 인재개발원 통합교육, 전문교육기관(운항/정비/객실훈련)', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 지원', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '취미반 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '등산, 축구, 테니스, 볼링, 사진, 회화반 등 23개 취미반 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 자금 및 전세 자금 지원, 신용협동조합 운영', 80),
  (@comp_id, 'discount', '직원 할인 항공권', 200, 'perks',
   'est', '국내선/국제선 할인 항공권, 결혼/효도/청원 항공권, 타항공사 할인(협정체결), 퇴직직원용 항공권 (추정)', FALSE, NULL, 81),
  (@comp_id, 'meal', '구내식당 식사 제공', 432, 'perks',
   'est', '전 사옥 구내식당 운영, 식당 미설치 지역은 인근 식당 계약 (추정)', FALSE, NULL, 82),
  (@comp_id, 'snack_bar', '생수 제공', NULL, 'perks',
   'est', NULL, TRUE, '대리급 이상 매월 생수 지급', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
