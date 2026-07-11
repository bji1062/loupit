-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엔씨소프트 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ncsoft', '엔씨소프트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'N', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ncsoft');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 상여', 60, 'compensation',
   'est', '설/추석 각 30만원', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율 출퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '자율 출퇴근제, 최대 근로시간 도달 시 사내 출입 제한하는 게이트 오프(Gate Off) 제도', 10),
  (@comp_id, 'remote_work', '주 2회 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '주 2회 재택 (팀장 협의 시 최대 4회까지 가능, 팀바팀)', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'birthday_leave', '생일 페이코 지급', 10, 'time_off',
   'est', '생일자 페이코 10만원 지급', FALSE, NULL, 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'clinic', '사내 메디컬센터', NULL, 'health',
   'est', NULL, TRUE, '전문 의사 상주, 내과/소아과/피부과 진료, 신경계/근골격계 질환 치료', 40),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집 웃는땅콩', NULL, 'family',
   'est', NULL, TRUE, '만 1세~만 5세, 최대 200명 수용', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '도서관 운영', NULL, 'growth',
   'est', NULL, TRUE, '사내 도서관 운영', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'leisure_ticket', '야구 티켓 지원', NULL, 'leisure',
   'est', NULL, TRUE, '야구 티켓 1인 무료, 동반 3인 50% 할인', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드 포인트', 300, 'perks',
   'est', '2025년부터 300만원 지급', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당 삼시세끼', 432, 'perks',
   'est', '점심 무료, 아침/저녁/샐러드 2천원', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '전세/주택 대출 이자지원', NULL, 'perks',
   'est', NULL, TRUE, '전세/주택구입 대출 1억까지 은행 연계 이자지원, 생활안정자금 3천만원 대출, 학자금 대출 상환 지원 1500만원', 82),
  (@comp_id, 'commute_subsidy', '야근 택시비 지원', NULL, 'perks',
   'est', NULL, TRUE, '23시 이후 야근 시 택시비 지원', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
