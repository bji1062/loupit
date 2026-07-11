-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 올릭스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('olix', '올릭스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'O', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'olix');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절/생일 상품권', 20, 'compensation',
   'est', '명절 상품권 + 생일 상품권 지급 (추정)', FALSE, NULL, 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차 20일', NULL, 'time_off',
   'est', NULL, TRUE, '연차 20일 제공, 가족돌봄휴가 제공', 30),
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 (특수검진 포함)', 100, 'health',
   'est', '매년 건강검진 지원, 연구원 특수검진 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '단체보험 가입 (추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', 20, 'family',
   'est', '본인 및 가족 경조사 지원 (추정)', FALSE, NULL, 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 프로그램', 30, 'growth',
   'est', '어학 프로그램 운영 (추정)', FALSE, NULL, 60),
  (@comp_id, 'books', '사내 도서관', 10, 'growth',
   'est', '(추정)', FALSE, NULL, 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인 콘도', 50, 'leisure',
   'est', '법인 회원 콘도 이용 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', 10, 'leisure',
   'est', '사내 동호회 운영 및 지원 (추정)', FALSE, NULL, 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주거 지원', NULL, 'perks',
   'est', NULL, TRUE, '주거 지원', 80),
  (@comp_id, 'snack_bar', '카페테리아', 20, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'parking', '주차공간/주차비 지원', NULL, 'perks',
   'est', NULL, TRUE, '주차공간 및 주차비 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
