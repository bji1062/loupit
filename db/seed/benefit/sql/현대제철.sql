-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대제철 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_steel', '현대제철',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '철강', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '하기/리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가 5일, 반기별 Refresh 휴가, 승진휴가, 휴가비 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이후 5년마다 기념품, 15년 포상금+기념품, 20년 배우자 동반 해외여행', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '정기검진+종합건강진단', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인 100%, 가족 50%', FALSE, NULL, 41),
  (@comp_id, 'clinic', '사내 부속의원', NULL, 'health',
   'est', NULL, TRUE, '인천/포항공장 사내 부속의원 운영', 42),
  (@comp_id, 'fitness', '수영장/헬스', NULL, 'health',
   'est', NULL, TRUE, '본사 직원전용 수영장, 당진/인천/포항/순천 헬스+사우나', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아', NULL, 'family',
   'est', NULL, TRUE, '산전후휴가(여), 배우자출산휴가(남)', 50),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사업장별 육아시설 보유', 51),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '고등학교부터 전액 지원 (추정)', FALSE, NULL, 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/리조트', 50, 'leisure',
   'est', '현대설악콘도/해비치/대명/리솜 등 할인 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동아리 활동 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '서울/당진/인천/포항/순천 전 지역 (추정)', FALSE, NULL, 80),
  (@comp_id, 'discount', '차량/백화점 할인', NULL, 'perks',
   'est', NULL, TRUE, '현대/기아 차량 할인(근속별 추가), 현대백화점 상시 10% 할인카드+인터넷몰', 81),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 1억/전세 5천만 저금리 대출, 독신자 숙소(당진/포항)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
