-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대글로비스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_glovis', '현대글로비스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '물류', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_glovis');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '업적급/성과급', 500, 'compensation',
   'est', '업적급 최대 연봉35%(책임매니저), 경영성과 연계 성과급 (추정)', FALSE, NULL, 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '하기/장기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가+장기휴가 장려, Refresh 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원+가족 주기적 건강검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인+직계가족 질병/상해 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리/건강 상담', NULL, 'health',
   'est', NULL, TRUE, '전문 심리/의료인 상담, 스트레스/건강관리 지원', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 사내 어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '(추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '리더십/직무/어학 교육, 라이프스타일 특강, IDP, 학습플랫폼(터치클래스)', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 할인', 50, 'leisure',
   'est', '전국 유명콘도 임직원 할인 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'discount', '차량 구입 지원', NULL, 'perks',
   'est', NULL, TRUE, '근속년수에 따라 차량 구입 비용 지원', 80),
  (@comp_id, 'housing_loan', '주택자금/사택', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/전세자금, 지방근무자 사택', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
