-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 클래시스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('classys', '클래시스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'C', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'classys');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', 100, 'compensation',
   'est', '성과급 지급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'compensation',
   'est', '명절 선물 지급 (추정)', FALSE, NULL, 2),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '노트북/사무용품', NULL, 'work_env',
   'est', NULL, TRUE, '노트북 및 사무용품 지급', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차/보건휴가/경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 보건휴가, 경조휴가, 근로자의 날 휴무', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '산전후휴가/육아휴직', NULL, 'family',
   'est', NULL, TRUE, '산전후 휴가, 남성출산휴가, 육아휴직', 50),
  (@comp_id, 'event', '경조사 지원', 20, 'family',
   'est', '각종 경조사 지원 및 경조휴가 (추정)', FALSE, NULL, 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '휴양시설 이용 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '식비 지원', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '카페테리아/음료', 20, 'perks',
   'est', '카페테리아, 음료 제공 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
