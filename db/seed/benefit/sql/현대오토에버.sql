-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대오토에버 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_autoever', '현대오토에버',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_autoever');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제 운영', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '별도 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 외 별도 5일 휴가, 백신/보건휴가, 휴가비 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '종합건강검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '(추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사/명절', 50, 'family',
   'est', '경조사 지원, 명절 귀향비 (추정)', FALSE, NULL, 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '구내식당 운영, 일 18,000원 x 240일 (추정)', FALSE, NULL, 81),
  (@comp_id, 'telecom', '통신비', 30, 'perks',
   'est', '(추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대출 + 차량구입비 지원', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
