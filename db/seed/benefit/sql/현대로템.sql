-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대로템 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_rotem', '현대로템',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '철도/방산', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_rotem');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가+휴가비 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상 제도', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '직원+가족 종합검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '직원+가족 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '(추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사/명절', 50, 'family',
   'est', '경조사 지원+명절 선물 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '계층별/직무교육', NULL, 'growth',
   'est', NULL, TRUE, '신임/향상과정, 신입사원 교육, 전문직무/사이버/정보화 교육, 조직활성화 과정', 60),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '사내 외국어 과정, 사이버 어학, 이문화 이해과정', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '사계절 휴양소', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '각종 동호회 활동 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '상/하반기 지급 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 288, 'perks',
   'est', '중식 무료(조석 유료), 일 12,000원 x 240일 (추정)', FALSE, NULL, 81),
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '(추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/전세자금, 부임이사 지원', 83),
  (@comp_id, 'discount', '차량 보조금', NULL, 'perks',
   'est', NULL, TRUE, '차량 구입시 보조금, 개인연금 지원', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
