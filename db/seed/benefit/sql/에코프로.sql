-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에코프로 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ecopro', '에코프로',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'profit_sharing', '성과급/특별상여', NULL, 'compensation',
   'est', NULL, TRUE, '특별상여 연간 3회, 평가급(운영직 월 최대 20만원), Profit Sharing 성과급', 1),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 등', 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 30),
  (@comp_id, 'birthday_leave', '생일 상품권', NULL, 'time_off',
   'est', NULL, TRUE, '근로자 생일 상품권 지급', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'fitness', '헬스장/당구장/탁구장', NULL, 'health',
   'est', NULL, TRUE, '헬스장, 당구장, 탁구장 등 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원 (장례용품 포함), 사우회 운영', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영/지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내식당 (중/석식)', 288, 'perks',
   'est', '구내식당 중식/석식 제공 (일 12,000원 x 240일 환산)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '사택/정착지원금', NULL, 'perks',
   'est', NULL, TRUE, '사택 또는 정착지원금 지급', 81),
  (@comp_id, 'discount', '제휴업체 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체 직원 할인', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
