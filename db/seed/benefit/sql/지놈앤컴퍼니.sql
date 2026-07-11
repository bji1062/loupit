-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 지놈앤컴퍼니 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('genome_company', '지놈앤컴퍼니',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'G', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'genome_company');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절/생일 선물', 20, 'compensation',
   'est', '명절선물 + 생일선물 지급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'excellence_award', '직무발명 보상제도', 30, 'compensation',
   'est', '(추정)', FALSE, NULL, 2),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', 20, 'family',
   'est', '(추정)', FALSE, NULL, 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 지원', 30, 'growth',
   'est', '(추정)', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회 지원', 10, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'welcome_kit', '웰컴키트', 5, 'leisure',
   'est', '웰컴키트 제공 (추정)', FALSE, NULL, 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '식대 지원', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '카페테리아/간식/커피', 30, 'perks',
   'est', '음료 및 간식, 커피머신 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
