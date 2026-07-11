-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG에너지솔루션 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_energy', 'LG에너지솔루션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리', 'L', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_energy');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '경영성과급/인센티브', 500, 'compensation',
   'est', '경영성과급+On Spot+Golden Collar Incentive (추정)', FALSE, NULL, 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 5일', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 정기검진, 만35세/근속5년 이상 종합검진(본인1년+배우자2년)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자 전액, 자녀 50% (추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '건강증진비', 30, 'health',
   'est', '건강증진비 지원 (추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '중/고/대학 전액(자녀 수 제한 없음)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '결혼/회갑 등 경조금+경조휴가 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/경력개발 교육', NULL, 'growth',
   'est', NULL, TRUE, '직급/직무별 체계적 교육, 개별 육성면담, 계획적 경력개발제도', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인콘도', 50, 'leisure',
   'est', 'LG생활연수원/곤지암리조트/강촌리조트 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '산악/음악/볼링/스킨스쿠버 등 동호회 적극 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '건강증진/자기계발/여가&생활/복지매장 4개 카테고리 (추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금/사택', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/전세자금 지원, 공장근무자 사택/기숙사', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
