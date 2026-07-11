-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NAVER 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('naver', 'NAVER',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT/포털', 'N', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_grant', '전 직원 주식 부여', 1000, 'compensation',
   'est', '전 직원 대상 연간 1,000만원 상당 주식 부여', FALSE, NULL, 1),
  (@comp_id, 'profit_sharing', '주식 매입 리워드', 200, 'compensation',
   'est', '네이버 주식 매입 후 6개월 보유 시 매입금액 10%(연 200만원 한도) 지원', FALSE, NULL, 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율 근무(Type_O/R)', NULL, 'flexibility',
   'est', NULL, TRUE, '평일 6시~22시 자율 근무, Type_O(주3일 출근) 또는 Type_R(원격) 개인 선택, 연간 최대 4주 해외근무, OCC 사내공모', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 플러스 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2년 근속 시 15일 추가 유급휴가, 연차 2일 이상 사용시 1일x5만원 휴가비', 30),
  (@comp_id, 'leave_general', '자기돌봄/가족돌봄 휴직', NULL, 'time_off',
   'est', NULL, TRUE, '자기돌봄 휴직(3년 이상 근속, 최대 6개월 무급), 가족돌봄 휴가(최대 90일)', 31),
  (@comp_id, 'long_service_leave', '근속 기념 선물', NULL, 'time_off',
   'est', NULL, TRUE, '근속 10주년/20주년 선물 지급', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '매년 90여 개 항목, 짝수해 가족 1인 추가, 서울대/삼성병원 등 30여 개 병원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '본인/가족 의료비 보험', 100, 'health',
   'est', '직원 본인 및 배우자 가족 실손의료비/진단비 지원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', 'NAVER CARE 부속의원', NULL, 'health',
   'est', NULL, TRUE, '가정의학과/재활의학과/이비인후과/비뇨의학과/건강검진 전문상담/물리치료', 42),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '전문 상담기관 연계, 연 10회 전액 지원, 10회 이상 80% 지원', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '육아휴직 2년', NULL, 'family',
   'est', NULL, TRUE, '법정 1년 외 추가 1년, 총 2년 육아휴직', 50),
  (@comp_id, 'childcare', '네이버 어린이집', NULL, 'family',
   'est', NULL, TRUE, '서울/경기권 6개 지역 951 T/O, 오전7:30~오후10시 운영', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조비/경조휴가 지원, 사옥 내 웨딩 공간 무료 지원(1일 1예식)', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 지원비', 240, 'growth',
   'est', '연간 최대 240만원 어학 교육비', FALSE, NULL, 60),
  (@comp_id, 'conference', '외부 교육/컨퍼런스', NULL, 'growth',
   'est', NULL, TRUE, '컨퍼런스/포럼/학회 참가비 전액 지원, Tech Share/Engineering Day/Meetup 등 사내교육', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '프리미엄 리조트 40여 개', 50, 'leisure',
   'est', '회원제 전국 프리미엄 리조트 40여 개 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', 'Club Greeny', 36, 'leisure',
   'est', '동료 관심사 공유 모임, 연간 36만원 활동비', FALSE, NULL, 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'work_tools', '업무 장비 예산', 360, 'perks',
   'est', '2년에 최대 720만원(연 360만원 환산) 노트북/모니터/태블릿 자유 선택, 허먼밀러 에어론/스탠딩데스크', FALSE, NULL, 80),
  (@comp_id, 'welfare_point', '개인 업무 지원비', 360, 'perks',
   'est', '업무 몰입 위한 연간 360만원 지원금', FALSE, NULL, 81),
  (@comp_id, 'discount', '네이버 서비스 이용권', 100, 'perks',
   'est', '연간 100만원 상당(네이버페이/플러스멤버십/웹툰/VIBE/클라우드 등)', FALSE, NULL, 82),
  (@comp_id, 'meal', '사내식당 점심/저녁 무료', 432, 'perks',
   'est', '점심/저녁 무료, 각 층 캔틴(조식/커피/간식 무료) (추정)', FALSE, NULL, 83),
  (@comp_id, 'housing_loan', '대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '대출금액 1.5%를 10년간 지원(최대 2억원)', 84),
  (@comp_id, 'holiday_gift', '명절 네이버페이', 40, 'perks',
   'est', '설/추석 총 40만원 네이버페이 포인트(또는 상품권)', FALSE, NULL, 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
