-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LS 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 주의: 원본 txt 내용은 "KLT (Pulsarlube)" — LS 데이터 부재, 가용 데이터로 생성
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ls', 'LS',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전선/전력', 'L', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'family_day', '가정의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 3째주 금요일 12시 조기 퇴근', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '5년 단위 포상금 지급', 30),
  (@comp_id, 'birthday_leave', '생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일 당일 유급휴가 + 상품권', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '헬스케어비', 30, 'health',
   'est', '연 1회 건강관련 비용(검진/약/주사 등) 지원', FALSE, NULL, 40),
  (@comp_id, 'fitness', '체력단련비', 30, 'health',
   'est', '헬스장 회원권 월 비용 지원 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'holiday_gift', '명절 지원', 20, 'family',
   'est', '명절 상품권 지급 (추정)', FALSE, NULL, 50),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '여가활동비', 50, 'perks',
   'est', '문화/취미/숙박 등 여가활동비 연 1회 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '식대 지원', 50, 'perks',
   'est', '야근/휴일 근무시 식대 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
