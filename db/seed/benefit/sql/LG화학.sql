-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG화학 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_chem', 'LG화학',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'L', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_chem');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', 500, 'compensation',
   'est', 'On-Spot+Golden Collar+핵심인재 인센티브 (추정)', FALSE, NULL, 1),
  (@comp_id, 'excellence_award', '연구개발상', NULL, 'compensation',
   'est', NULL, TRUE, 'LG연구개발상(1982년~), Open Innovation 우수활동상(2001년~)', 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 5일', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 정기검진, 만35세 이상 종합검진(본인1년+배우자2년)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자 전액, 자녀 50% (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '중/고/대학 전액(자녀 수 제한 없음)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조금+경조휴가 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/역량 교육', NULL, 'growth',
   'est', NULL, TRUE, '사업가 육성체계, 학위수여, Global고객 접점 교육(Presentation/Negotiation/Business Manner)', 60),
  (@comp_id, 'mba', 'Global MBA/유학', NULL, 'growth',
   'est', NULL, TRUE, 'Global MBA, 국내외 대학 파견, 지역전문가(중국/인도/브라질 등 6개월~1년)', 61),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '영어/중국어 장기합숙, 온라인/오프라인 어학과정', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인콘도', 50, 'leisure',
   'est', 'LG생활연수원/곤지암리조트/강촌리조트 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '스키/산악/음악/볼링/스킨스쿠버 등 적극 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '건강증진/자기계발/여가&생활/복지매장 (추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금/사택', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/전세자금, 지방영업 임차주택, 공장 사택/기숙사', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
