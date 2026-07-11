-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 실리콘투 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('silicon2', '실리콘투',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품유통', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'silicon2');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급', 1),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차/반차/반반차 + 휴가비', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 반차, 반반차 사용, 휴가비 지원', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '매년 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원', 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '음료/간식 제공', NULL, 'perks',
   'est', NULL, TRUE, '음료, 간식 제공', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
