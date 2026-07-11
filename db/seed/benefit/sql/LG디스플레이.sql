-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG디스플레이 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_display', 'LG디스플레이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '디스플레이', 'L', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_display');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', 'PS/PI 인센티브', 500, 'compensation',
   'est', 'PS(Profit Sharing)+PI(Personal)+Vision Incentive (추정)', FALSE, NULL, 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계/Turn-off 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '유급하계휴가 4일, Turn-off 휴가 운영', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '본인+배우자 주기적 종합건강검진', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인+가족 질병/상해 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '중대 질병/장애 보험금 (추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장보육시설', NULL, 'family',
   'est', NULL, TRUE, '직장보육시설 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '중/고/대학교 학자금 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '결혼/회갑 등 경조금+경조휴가 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, '미래사업가 후보양성, 리더/후계자 코칭, 직무별 전문교육(R&D/생산/영업/지원)', 60),
  (@comp_id, 'mba', 'MBA/학위파견', NULL, 'growth',
   'est', NULL, TRUE, '국내외 R&D/MBA 학위 파견, 해외법인 주재원, 집중 어학연수', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인콘도', 50, 'leisure',
   'est', 'LG생활연수원, 전국 콘도 숙박비 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠/봉사활동/음악/종교 등 동호회 활동비 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복리후생 포인트', 200, 'perks',
   'est', '자기계발/생활/건강/레저/패션 등 자율 사용 (추정)', FALSE, NULL, 80),
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '통근버스 지원 (추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택융자/사택', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/임차 융자금, 사택/기숙사 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
