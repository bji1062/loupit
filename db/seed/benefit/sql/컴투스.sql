-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 컴투스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('com2us', '컴투스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'C', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'com2us');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브제 운영', 1),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 지급', 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '코어타임 자율출퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '코어타임 10시~15시, 주 40~52시간 범위 내 자율 선택 근무', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '1시간 단위 연차 + 창립기념일', NULL, 'time_off',
   'est', NULL, TRUE, '1시간 단위 연차 사용, 창립기념일 휴무, 크리스마스 다음날 유급휴일', 30),
  (@comp_id, 'refresh_leave', '리커버리데이', NULL, 'time_off',
   'est', NULL, TRUE, '한 달에 한 번 재충전 시간 제공', 31),
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 제도', 32),
  (@comp_id, 'birthday_leave', '생일 선물', NULL, 'time_off',
   'est', NULL, TRUE, '생일 선물 지급', 33),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 (본인+가족 1인)', 100, 'health',
   'est', '본인 + 동반 가족 1인 (배우자 또는 직계존비속 중 1인)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험 (본인+가족)', 30, 'health',
   'est', '의료실손형/치과보장형 택 1, 본인/배우자/자녀 포함 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', 'EAP 심리상담', NULL, 'health',
   'est', NULL, TRUE, '상담포유(EAP): 직장 스트레스, 불면증, 가정 부문, 코로나 블루 케어 등 종합 상담', 42),
  (@comp_id, 'fitness', '제휴 헬스장 무료', NULL, 'health',
   'est', NULL, TRUE, '회사 제휴 헬스장 (주말 운영), 사원증 무료 입장, 운동복/수건 무료, GX 프로그램 무료', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금 및 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가 지원', 50),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '제휴 리조트/콘도', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회/게임대회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 게임 대회 (모바일/PC/온라인), 사내 동호회 운영', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드', 250, 'perks',
   'est', '연 250만원', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당 삼시세끼', 432, 'perks',
   'est', '아침 무료(주먹밥/샌드위치 등), 점심 4가지 메뉴, 저녁 제공', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '카페/스무디 등 모든 제조 음료 1,000원, 야간 매점(20시)', 82),
  (@comp_id, 'commute_subsidy', '셔틀버스', 120, 'perks',
   'est', '판교역/미금역 전용 셔틀버스 (추정)', FALSE, NULL, 83),
  (@comp_id, 'housing_loan', '전세 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전세 대출 이자 일부 지원', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
