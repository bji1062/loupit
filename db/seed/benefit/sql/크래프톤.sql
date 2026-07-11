-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 크래프톤 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('krafton', '크래프톤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'krafton');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 반차', NULL, 'compensation',
   'est', NULL, TRUE, '명절 기념 반차 제공', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '자율 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '자율 재택근무 (팀바팀)', 10),
  (@comp_id, 'satellite_office', '거점 오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '역삼/판교/서초 빌딩 간 핫데스크(자율좌석) 이용 가능', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '휴식 공간', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자, 리클라이너 비치된 휴식 공간, 수유실', 20),
  (@comp_id, 'parking', '주차 지원', NULL, 'work_env',
   'est', NULL, TRUE, '자차 통근 불가피 시 주차 공간 지원', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '매 5년 근속마다 기념품 및 포상 휴가', 30),
  (@comp_id, 'birthday_leave', '생일 축하', 5, 'time_off',
   'est', '생일날 5만원 지급 + 인정 반차', FALSE, NULL, 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진 (본인+가족)', 100, 'health',
   'est', '본인 포함 가족 1인 무료 (부모님/배우자/자녀), 지인 30% 할인', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 건강보험', 30, 'health',
   'est', '본인 및 가족 단체 건강보험 지원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '케이마인드 케어', NULL, 'health',
   'est', NULL, TRUE, '전문가 코칭을 통한 부정적 감정 회복 프로그램', 42),
  (@comp_id, 'fitness', '운동비 지원', 10, 'health',
   'est', '운동비 월 10만원 지원 (연 120만원 중 10만원/월)', FALSE, NULL, 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집 리틀포레', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 리틀포레 운영', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어/중국어/일본어/한국어 교육 지원, 직무 교육 및 자기계발 교육', 60),
  (@comp_id, 'books', '도서비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 지원', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내식당 삼시세끼', 432, 'perks',
   'est', '조식/중식/석식 모두 제공하는 사내 식당', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영', 81),
  (@comp_id, 'commute_subsidy', '야근 택시비 + 출근 버스', 120, 'perks',
   'est', '야근 택시비 지원, 출근 버스 운행 (추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 대출 + 셰어하우스', NULL, 'perks',
   'est', NULL, TRUE, '1억 주택자금대출 이자지원, 지방/외국 출신 초년생(경력 2년 미만) 6개월 셰어하우스 무료 제공', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
