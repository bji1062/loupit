-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 더블유게임즈 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wgames', '더블유게임즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'W', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wgames');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브 (최대 연봉 30%)', NULL, 'compensation',
   'est', NULL, TRUE, '연봉의 최대 30% 인센티브 지급', 1),
  (@comp_id, 'holiday_gift', '명절상여금', 40, 'compensation',
   'est', '명절상여금 20만원 x 2회', FALSE, NULL, 2),
  (@comp_id, 'excellence_award', '올해의 더블유인 포상', NULL, 'compensation',
   'est', NULL, TRUE, '올해의 더블유인 포상 + 포상 휴가', 3),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근로제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근로제 시행, 비포괄제도 주 52시간 한도 내 초과근무 수당 지급', 10),
  (@comp_id, 'remote_work', '주 1회 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '주 1회 재택 근무 (재택 시 식비 지원)', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '수면실/리프레쉬존', NULL, 'work_env',
   'est', NULL, TRUE, '남녀 각각 수면실, 리프레쉬존, 다트/라운지, 여자수면실 내 수유실', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상 (최대 1000만원)', 1000, 'time_off',
   'est', '장기 근속 포상금 최대 1000만원 + 포상 휴가', FALSE, NULL, 30),
  (@comp_id, 'birthday_leave', '생일 유급휴가+축하금', 30, 'time_off',
   'est', '생일자 유급 휴가 + 생일축하금 30만원', FALSE, NULL, 31),
  (@comp_id, 'leave_general', '연말/이사 유급휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연말 1일 유급휴가, 이사 유급휴가, 백신 유급휴가, 잔여연차 수당 정산', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '사내 헬스키퍼/헬스존', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스키퍼 운영, 사내 헬스존 운영', 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 50만원(다태아 75만원), 출산휴가 90일(다태아 120일), 임산부 2시간 단축, 육아휴직 1년', 50),
  (@comp_id, 'event', '가족 기념일 선물/경조사', NULL, 'family',
   'est', NULL, TRUE, '가족 기념일 꽃다발/케이크, 다양한 경조사 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 수업/멘토링', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학 수업 지원, 멘토링 프로그램(운영비 지원)', 60),
  (@comp_id, 'books', '도서 구매/사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 도서 구매, 사내 도서관 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 지원', 50, 'leisure',
   'est', '리프레시를 위한 콘도 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회/워크샵', NULL, 'leisure',
   'est', NULL, TRUE, '취미 동호회 활동비 지원, 전사 워크샵(해외), 체육대회/송년회/이벤트', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 250, 'perks',
   'est', '최대 연 250만원', FALSE, NULL, 80),
  (@comp_id, 'meal', '삼시세끼 식대 (법카)', 432, 'perks',
   'est', '1인1법카 아침/점심/저녁 무상제공, 점심/저녁 13,000원 식대', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '무료 스낵바/카페', NULL, 'perks',
   'est', NULL, TRUE, '무료 스낵바(커피/음료/간편식), 사내 카페테리아', 82),
  (@comp_id, 'housing_loan', '사내대출', NULL, 'perks',
   'est', NULL, TRUE, '근속기간 충족 시 사내대출 지원', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
