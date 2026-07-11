-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 네오위즈 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('neowiz', '네오위즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'N', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'neowiz');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근제, 매월 마지막 금요일 4:30 퇴근 단축근무', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '3년 근속 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '3년 근속 시 리프레시 휴가(유급) 10일 부여', 30),
  (@comp_id, 'birthday_leave', '본인/가족 기념일 선물+휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인/가족 기념일에 선물 + 연 4회 기념일 휴가 제공', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'mental', '사내 심리상담', NULL, 'health',
   'est', NULL, TRUE, '회사 상주 전문 심리상담가와 상시 심리 상담', 40),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'leisure_room', '카지노룸', NULL, 'leisure',
   'est', NULL, TRUE, '리얼 카지노 테이블+칩 구비, 블랙잭/포커 게임 가능', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내식당 삼시세끼', 432, 'perks',
   'est', '사내 식당 아침/점심/저녁 삼시세끼 제공', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '전문 바리스타 커피/음료/베이커리 메뉴 제공', 81),
  (@comp_id, 'housing_loan', '사내 대출', NULL, 'perks',
   'est', NULL, TRUE, '다양한 사내 대출제도 운영', 82),
  (@comp_id, 'discount', '자사 게임쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '피망 뉴맞고, 섯다, 포커 등 자사 게임 게임머니 쿠폰 지급', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
