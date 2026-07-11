-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha', '한화',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '지주/방산', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 부합하는 성과급 지급', 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '독신자 숙소', NULL, 'work_env',
   'est', NULL, TRUE, '지방 사업장 근무 독신자 숙소 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '매년 10일 휴가 연속 사용 장려, 한화그룹사 여가/레저/식음시설 이용 가능', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '10년/20년/30년 근속자 포상 및 해외여행 상품권 지급', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '본인/가족 병원비 지원', 100, 'health',
   'est', '본인 및 가족 병원비, 본인 치과 치료비 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담 전문가를 통한 심리적 고충 해소 비용 지원', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '중학교 이상 자녀 학자금 지원(자녀수 제한 없음)', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가, 경조금 및 경조 물품 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '외국어 학습비 지원', NULL, 'growth',
   'est', NULL, TRUE, '각종 외국어 학습 비용 지원', 60),
  (@comp_id, 'mba', '해외 유학 연수(MBA)', NULL, 'growth',
   'est', NULL, TRUE, 'MBA/Sloan/석박사 과정, 사전학습 지원금 최대 2천만원, 유학기간 급여/생활지원금/학비 전액 지원', 61),
  (@comp_id, 'career', 'Global Talent/지역전문가', NULL, 'growth',
   'est', NULL, TRUE, 'Global Talent Program(해외법인 파견), 지역전문가제도(해외파견), HPMP(신입 직무역량교육), EMBA/AMP/핵심인재 육성', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '한화콘도/플라자호텔', 50, 'leisure',
   'est', '한화콘도 및 플라자호텔 이용 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금 무이자 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 계약 시 무이자 자금 대부', 81),
  (@comp_id, 'discount', '갤러리아 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '갤러리아몰, 갤러리아 백화점 직원 할인가 적용', 82),
  (@comp_id, 'commute_subsidy', '셔틀버스', 120, 'perks',
   'est', '여수/군산공장 셔틀버스 운영 (추정)', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
