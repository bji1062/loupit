-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 레인보우로보틱스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('rainbow_robotics', '레인보우로보틱스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '로봇', 'R', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'rainbow_robotics');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 운영', 1),
  (@comp_id, 'holiday_gift', '생일 상품권', 5, 'compensation',
   'est', '생일자 상품권 지급 (추정)', FALSE, NULL, 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차/반차/반반차', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 반차, 반반차', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진(연1회)', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '육아휴직', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 제도 운영', 50),
  (@comp_id, 'event', '경조사 지원', 20, 'family',
   'est', '경조휴가 및 경조사비 지원 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발비 지원', 30, 'growth',
   'est', '(추정)', FALSE, NULL, 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '중식 제공', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '다과/커피머신', 20, 'perks',
   'est', '임직원 다과 제공 및 커피머신 구비 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
