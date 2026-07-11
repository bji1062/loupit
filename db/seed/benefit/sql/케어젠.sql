-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 케어젠 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('caregen', '케어젠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'compensation',
   'est', '명절 선물 지급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'excellence_award', '우수사원 포상', 30, 'compensation',
   'est', '(추정)', FALSE, NULL, 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차/반차/경조휴가', NULL, 'time_off',
   'est', '휴가비 지원', TRUE, '연차, 반차, 경조휴가, 근로자의 날 휴무', 30),
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 31),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조휴가', 50),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '점심/저녁식사 제공', 432, 'perks',
   'est', '점심식사 및 저녁식사 제공 (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '음료 제공', 20, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'discount', '자회사 제품 할인', 30, 'perks',
   'est', '자회사 제품 할인 지원 (추정)', FALSE, NULL, 82),
  (@comp_id, 'parking', '주차장 제공', NULL, 'perks',
   'est', NULL, TRUE, '주차장 제공', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
