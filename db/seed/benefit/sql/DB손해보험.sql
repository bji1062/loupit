-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DB손해보험 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: txt 원본에 엔카닷컴 데이터가 혼재되어 있어 DB손해보험 관련 항목만 추정 반영
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('db_insurance', 'DB손해보험',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'D', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'db_insurance');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 별도 지급 (추정)', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '시차출퇴근제/선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제, 선택적 근로시간제, PC-OFF제 (추정)', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 별도 지원 (추정)', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상(휴가/포상금) (추정)', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/가족 의료비 지원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '임직원 및 가족 단체보험 (추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학생/대학생 자녀 학자금 지원 (추정)', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가 지원 (추정)', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육/자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무교육, 자격증 취득 지원 (추정)', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 지원', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (추정)', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택자금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대출 지원 (추정)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
