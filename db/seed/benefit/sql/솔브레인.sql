-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 솔브레인 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('soulbrain', '솔브레인',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수사원/연구/특허 포상', 50, 'compensation',
   'est', '우수사원 포상, 연구개발 포상, 특허 관련 포상 (추정)', FALSE, NULL, 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계 유급휴가', NULL, 'time_off',
   'est', '하계 유급휴가 + 휴가비 지원', TRUE, '하계 유급휴가 및 휴가비 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상제도 운영', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '유치원~대학 등록금 지원, 입학축하금 지급 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조사 지원 + 사내 상조회 운영 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '외국어 인텐시브 과정', NULL, 'growth',
   'est', NULL, TRUE, '외국어 인텐시브 과정, 맞춤형 교육, 인문학 특강', 60),
  (@comp_id, 'edu_support', '학위지원제도', NULL, 'growth',
   'est', NULL, TRUE, '학위지원제도 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양지', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영비 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내 식당', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영', 81),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '(추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 전세자금 대출 지원', 83),
  (@comp_id, 'holiday_gift', '명절/생일/창립기념 선물', 30, 'perks',
   'est', '명절선물, 생일선물, 창립기념일 선물 (추정)', FALSE, NULL, 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
