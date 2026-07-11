-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화오션 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_ocean', '한화오션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '조선', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_ocean');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 제공', NULL, 'work_env',
   'est', NULL, TRUE, '3인 1실 기숙사 제공', 20),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '채용시 건강검진, 36세 이상 본인/40세 이상 배우자 건강검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '1년 이상 근속자 자녀(유치원/고등/대학) 학자금 지원', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '본인(배우자 포함) 및 가족, 형제자매 경조금/휴가 지원', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 회원권', 50, 'leisure',
   'est', '전국 유명 휴양지 콘도 회원권 보유, 임직원 이용 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내식당 중식/석식 무료', 288, 'perks',
   'est', '중식 및 석식 무료 제공, 일 12,000원 x 240일 환산 (추정)', FALSE, NULL, 80),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '광양/순천/여수 등 인근 지역 통근버스 운행 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
