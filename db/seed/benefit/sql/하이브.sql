-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 하이브 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 원본 txt는 '하이브로(드래곤빌리지)' 데이터
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hybe', '하이브',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '엔터테인먼트', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hybe');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '장기근속자 스톡옵션', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 스톡옵션 제도 운영', 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '듀얼 모니터 제공', NULL, 'work_env',
   'est', NULL, TRUE, '듀얼 모니터 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '자율 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '자율 휴가제 운영', 30),
  (@comp_id, 'family_day', '금요일 조기퇴근', NULL, 'time_off',
   'est', NULL, TRUE, '금요일 오후 5시 퇴근 (1시간 30분 조기퇴근)', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '프리미엄 건강검진', 100, 'health',
   'est', '차움병원 100만원 상당 프리미엄 검진 (본인 전액, 가족 50% 지원)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지원', 50),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '입사 지원금', NULL, 'leisure',
   'est', NULL, TRUE, '최대 1,000만원 이직 지원금 (3년 이상 경력자)', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '중식/석식 식대 지원', 240, 'perks',
   'est', '월 20만원 점심식대 + 석식 별도 지원', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '간식/맥주 무제한', NULL, 'perks',
   'est', NULL, TRUE, '간식 무한 제공, 맥주 무제한 공급', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
