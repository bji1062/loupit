-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HPSP 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hpsp', 'HPSP',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hpsp');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', 300, 'compensation',
   'est', '인센티브제 (추정)', FALSE, NULL, 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '노트북 지원', NULL, 'work_env',
   'est', NULL, TRUE, '업무용 노트북 지원', 20),
  (@comp_id, 'nap_room', '안마의자/휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자 비치 휴게시설', 21),
  (@comp_id, 'parking', '주차장', NULL, 'work_env',
   'est', NULL, TRUE, '주차장 제공', 22),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 + 휴가비 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '체력단련실', NULL, 'health',
   'est', NULL, TRUE, '사내 체력단련실 운영', 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '각종 경조사 지원 (추정)', FALSE, NULL, 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무교육', NULL, 'growth',
   'est', NULL, TRUE, '직무능력향상 교육', 60),
  (@comp_id, 'self_development', '자기계발비', 50, 'growth',
   'est', '자기계발비 지원 (추정)', FALSE, NULL, 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자 웰컴키트 지급', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '점심식사', 288, 'perks',
   'est', '점심 제공, 일 12,000원 x 240일 (추정)', FALSE, NULL, 80),
  (@comp_id, 'telecom', '통신비', 30, 'perks',
   'est', '통신비 지원 (추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '음료 제공', 30, 'perks',
   'est', '사내 음료 제공 (추정)', FALSE, NULL, 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
