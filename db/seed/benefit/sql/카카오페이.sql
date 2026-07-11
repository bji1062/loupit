-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오페이 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_pay', '카카오페이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '핀테크', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '스톡옵션', NULL, 'compensation',
   'est', NULL, TRUE, '스톡옵션 선택적 지급', 1),
  (@comp_id, 'holiday_gift', '명절 상여', 60, 'compensation',
   'est', '명절 상여 60만원 지급', FALSE, NULL, 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', 'WorkOn 선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 단위 근로시간 관리, 코어타임 없음, 0시간 근무 가능, 12/31 조기퇴근', 10),
  (@comp_id, 'remote_work', '전사 전면 재택', NULL, 'flexibility',
   'est', NULL, TRUE, '전사 전면 재택근무', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '안식 휴가(3년마다)', 200, 'time_off',
   'est', '근속 3년마다 30일 유급 휴가 + 휴가비 200만원', FALSE, NULL, 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 실비 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체보험(가족 포함)', 30, 'health',
   'est', '본인/배우자/직계 상해보험, 양가부모+자녀 실손, 부부+자녀 치과보험 (추정)', FALSE, NULL, 42),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담 지원', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '어린이집 지원', NULL, 'family',
   'est', NULL, TRUE, '어린이집 지원(시설 양호)', 50),
  (@comp_id, 'event', '경조사/생일 지원', NULL, 'family',
   'est', NULL, TRUE, '생일 축하 선물, 경조사 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '도서 구매 무제한', NULL, 'growth',
   'est', NULL, TRUE, '도서 구매 무제한 지원, 동영상 강의 결재시 구입 가능', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 리조트', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'massage', '전속 안마사/안마의자', NULL, 'leisure',
   'est', NULL, TRUE, '전속 안마사 30분 안마, 격층 안마의자, 남녀 수면실', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '카카오페이 포인트', 360, 'perks',
   'est', '월 30만 포인트(연 360만원)', FALSE, NULL, 80),
  (@comp_id, 'meal', '식대 지원', 240, 'perks',
   'est', '월 20만원(연 240만원), 사내식당, 야근식대 법인카드', FALSE, NULL, 81),
  (@comp_id, 'commute_subsidy', '통근버스/야근택시', 120, 'perks',
   'est', '통근버스, 야근 택시 법인카드 (추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '전세/매매 대출이자', NULL, 'perks',
   'est', NULL, TRUE, '최대 3억원 대출이자 지원(이자 2%만 자비 부담)', 83),
  (@comp_id, 'snack_bar', '사내 카페/매점', 144, 'perks',
   'est', '아메리카노 500원/라떼 1000원, 콜라/사이다 등 무료, 사내매점 70~80% 할인 (추정)', FALSE, NULL, 84),
  (@comp_id, 'discount', '카카오프렌즈/항공/차량 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오프렌즈샵 20% 할인, 김포/제주 항공 할인, 벤츠/BMW MOU 2% 할인', 85),
  (@comp_id, 'work_tools', '최신 맥북/스탠딩데스크', NULL, 'perks',
   'est', NULL, TRUE, '최신/최고급 맥북 또는 아이맥, 개인 스탠딩 데스크, 주말 업무용 차량 대여', 86),
  (@comp_id, 'parking', '주차비 지원', NULL, 'perks',
   'est', NULL, TRUE, '주차비 지원', 87)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
