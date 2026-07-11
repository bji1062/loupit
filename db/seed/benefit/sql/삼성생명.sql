-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성생명 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_life', '삼성생명',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_life');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수/모범사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '매월 우수사원, 모범사원 선발 및 포상', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출근제', NULL, 'flexibility',
   'est', NULL, TRUE, '8-5제/9-6제/10-7제 선택, PC온오프 제도 근무시간 관리', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 대상 휴가+휴가금, 근속별 생활안정보험 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '본인+배우자(40세~) 종합검진, 검진일 공가', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '재해사망2억/일반사망1.2억/입원실손/암치료 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '마음건강상담실 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산축하금', 50, 'family',
   'est', '출산축하금 및 출산용품 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '유치원/고교/대학교 학자금 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사/생일', 50, 'family',
   'est', '경조휴가/경조금, 기념일 축하선물 연1회 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, '공통교육, 직무교육, 전문자격 취득 지원, 리더양성교육', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '아난티/소노벨/한화/금호 등 전국 50여개소 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '볼링, 영화, 캘리그라피, 레포츠 등 동호회 운영지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 80, 'perks',
   'est', '연간 80만원 상당', FALSE, NULL, 80),
  (@comp_id, 'meal', '사내식당', 288, 'perks',
   'est', '조식+중식 지원, 일 12,000원 x 240일 (추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택대출 이자지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/임차 대출이자 지원', 82),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '노후 경제안정 개인연금 보험료 지원 (추정)', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
