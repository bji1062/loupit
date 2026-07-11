-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에이피알 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('apr', '에이피알',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '뷰티/화장품', 'A', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'apr');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '전직원 대상 인센티브 + 신규입사자 추가 인센티브', 1),
  (@comp_id, 'excellence_award', '월간 우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '매월 4개 분야 우수사원 선정, 휴가 및 상품 포상', 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '시차 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '매일 오전 8시~11시 30분 단위 출근시간 설정 (일 8시간, 주 40시간)', 10),
  (@comp_id, 'pc_off', 'PC-Off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간 초과 시 PC-Off 제도 운영', 11),
  (@comp_id, 'family_day', '패밀리 데이', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 마지막주 금요일 2시간 조기 퇴근', 12),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '셀프 승인 연차', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 셀프 승인제도 운영', 30),
  (@comp_id, 'refresh_leave', '리프레시 휴가 (3/6/9년)', NULL, 'time_off',
   'est', NULL, TRUE, '3,6,9년 마다 3,6,9일 리프레시 휴가 제공', 31),
  (@comp_id, 'birthday_leave', '생일 조기퇴근+선물', NULL, 'time_off',
   'est', NULL, TRUE, '생일자 2시간 조기퇴근 + 생일선물 제공', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '연 1회 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험 (본인+가족)', 30, 'health',
   'est', '본인 포함 직계가족까지 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', 'EAP 근로자 지원 프로그램', NULL, 'health',
   'est', NULL, TRUE, '근로자 지원 프로그램(EAP) 운영', 42),
  (@comp_id, 'massage', '사내 마사지룸', NULL, 'health',
   'est', NULL, TRUE, '근무시간 내 30분간 마사지룸 이용 가능', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'wedding', '결혼 축하금+휴가', 100, 'family',
   'est', '결혼 축하금 100만원 + 결혼기념휴가 5일', FALSE, NULL, 50),
  (@comp_id, 'event', '경조휴무/경조금/화환', NULL, 'family',
   'est', NULL, TRUE, '경조휴무, 경조금, 경조화환 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '직무 도서 구매비', 36, 'growth',
   'est', '매월 3만원 x 12개월', FALSE, NULL, 60),
  (@comp_id, 'career', '멘토링 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '조직/직무 조기 적응 멘토링 프로그램 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '웰컴패키지 (자사제품 100만원)', 100, 'leisure',
   'est', '웰컴메세지+기프트, 100만원 상당 자사제품 웰컴기프트', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지몰 포인트', 100, 'perks',
   'est', '매년 100만원 상당, 복지몰 내 자사제품 30~50% 할인', FALSE, NULL, 80),
  (@comp_id, 'meal', '전자식권 식대', 180, 'perks',
   'est', '월 15만원, 연 180만원 (점심시간 70분 확대 운영)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 라운지 스낵바', NULL, 'perks',
   'est', NULL, TRUE, '식사대용식/스낵류/음료/커피 무제한 제공', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
