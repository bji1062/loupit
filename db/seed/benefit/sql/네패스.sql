-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 네패스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nepes', '네패스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체패키징', 'N', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nepes');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '시차출근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출근제 운영', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '타지역 거주자 숙소 지원', NULL, 'work_env',
   'est', '7년간 지원', TRUE, '타 지역 거주자 숙소 7년 지원', 20),
  (@comp_id, 'nap_room', '사내 수면실/샤워실', NULL, 'work_env',
   'est', NULL, TRUE, '사내 수면실, 샤워실 보유', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차촉진제도', NULL, 'time_off',
   'est', NULL, TRUE, '연차촉진제도 운영', 30),
  (@comp_id, 'birthday_leave', '생일 연차 휴식', NULL, 'time_off',
   'est', NULL, TRUE, '생일 당일 연차 휴식', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'fitness', '체육시설', NULL, 'health',
   'est', NULL, TRUE, '체육시설 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '산단 직장 공동 어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금 지원', 200, 'family',
   'est', '(추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조금 지원', 50, 'family',
   'est', '경조사 상조용품 조부모/외조부모 확대 적용 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '월 단위 교육훈련', NULL, 'growth',
   'est', NULL, TRUE, '월 단위 교육훈련 제공', 60),
  (@comp_id, 'lang', '영어교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어교육 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '연수원/리조트', 50, 'leisure',
   'est', '연수원 이용 지원, 리조트 제휴업체 운영 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 40, 'perks',
   'est', '직급에 따라 30~50만원', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당 (중식/석식/야식)', 432, 'perks',
   'est', '구내 식당 운영', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페/무인매점', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페, 무인매점, 카페 제휴업체 운영', 82),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '(추정)', FALSE, NULL, 83),
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'perks',
   'est', '추석, 설날 명절 선물 지급 (추정)', FALSE, NULL, 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
