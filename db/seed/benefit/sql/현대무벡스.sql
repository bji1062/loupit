-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대무벡스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_muvex', '현대무벡스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '산업기계', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_muvex');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상금 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '종합검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),
  (@comp_id, 'fitness', '스포츠센터', NULL, 'health',
   'est', NULL, TRUE, '사내 스포츠센터 운영', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/입학 선물', 30, 'family',
   'est', '출산선물, 자녀입학선물(유치원/초/중) (추정)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '(추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사/명절/생일', 50, 'family',
   'est', '경조사, 명절선물, 생일선물 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '본인 학자금', NULL, 'growth',
   'est', NULL, TRUE, '본인 학자금 지급', 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드', 100, 'perks',
   'est', '개인별 복지카드 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '구내식당 운영, 일 18,000원 x 240일 (추정)', FALSE, NULL, 81),
  (@comp_id, 'transport', '통근차량', 120, 'perks',
   'est', '통근차량+시내교통비 (추정)', FALSE, NULL, 82),
  (@comp_id, 'snack_bar', '복지 카페', 50, 'perks',
   'est', '(추정)', FALSE, NULL, 83),
  (@comp_id, 'pension_support', '개인연금', 50, 'perks',
   'est', '(추정)', FALSE, NULL, 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
