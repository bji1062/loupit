-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG유플러스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_uplus', 'LG유플러스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '통신', 'L', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_uplus');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급/인센티브', 500, 'compensation',
   'est', '개인성과+팀+연말 성과급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'holiday_gift', '명절 상여금', 100, 'compensation',
   'est', '설/추석 상여금 (추정)', FALSE, NULL, 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 제도', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '종합건강진단 격년 1회', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '의료비 지원 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산축하금', 50, 'family',
   'est', '자녀 출산 축하금 (추정)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '자녀 학자금 지원 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조휴가 및 경조금 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', 'LG인화원 교육', NULL, 'growth',
   'est', NULL, TRUE, 'LG인화원 교육 지원', 60),
  (@comp_id, 'lang', '외국어 학습비', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학습비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '곤지암리조트 등', 50, 'leisure',
   'est', '곤지암리조트 등 휴양시설 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '멀티 복지포인트', 250, 'perks',
   'est', '연 250만원, 여가/자기계발/물품 구입', FALSE, NULL, 80),
  (@comp_id, 'telecom', '통신비', 180, 'perks',
   'est', '월 최대 15만원(단말 할부금 포함)', FALSE, NULL, 81),
  (@comp_id, 'discount', '그룹사 제품 할인', NULL, 'perks',
   'est', NULL, TRUE, '그룹사 제품 할인 및 구매 혜택', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
