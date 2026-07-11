-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 셀트리온 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('celltrion', '셀트리온',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '바이오/제약', 'C', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브제 운영', 1),
  (@comp_id, 'stock_option', '스톡옵션/우리사주', NULL, 'compensation',
   'est', NULL, TRUE, '스톡옵션, 우리사주제도', 2),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상', 3),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '상해/질병 치료비', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),
  (@comp_id, 'clinic', '사내 보건실', NULL, 'health',
   'est', NULL, TRUE, '사내 보건실 운영', 43),
  (@comp_id, 'fitness', '사내 체육시설', NULL, 'health',
   'est', NULL, TRUE, '사내 체육시설 이용 가능', 44),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '산전후 휴가, 남성출산휴가, 육아휴직', 50),
  (@comp_id, 'childcare', '임직원 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 어린이집 운영', 51),
  (@comp_id, 'child_edu', '자녀 학자금/특수교육', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원, 장애 자녀 특수교육비 지원', 52),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '가족/본인 경조사 지원, 영빈관 지원, 생일선물, 명절선물', 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육/학자금 지원', NULL, 'growth',
   'est', NULL, TRUE, '신입사원교육(OJT), 직무능력향상교육, 본인 학자금 지원, 해외여행 지원', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 회원가', 50, 'leisure',
   'est', '주요 관광지 콘도 회원가 이용 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회/문화체험', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 및 지원, 월 1회 사내 문화체험 클래스', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복지제도', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당 삼시세끼', 432, 'perks',
   'est', '아침/점심/저녁 제공 (추정)', FALSE, NULL, 81),
  (@comp_id, 'commute_subsidy', '셔틀버스/콜택시', 120, 'perks',
   'est', '출퇴근 셔틀버스, 심야 콜택시, 수도권 외 미혼사원 귀향비 (추정)', FALSE, NULL, 82),
  (@comp_id, 'parking', '주차장/주차비', NULL, 'perks',
   'est', NULL, TRUE, '주차장 제공 및 주차비 지원', 83),
  (@comp_id, 'snack_bar', '카페테리아/간식', NULL, 'perks',
   'est', NULL, TRUE, '카페테리아, 간식 및 음료 제공', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
