-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파마리서치 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('pharma_research', '파마리서치',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'P', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pharma_research');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '경영성과급/실적 인센티브', 100, 'compensation',
   'est', '연간 경영실적 목표 달성 시 경영성과급 + 영업부문 월/분기/연간 실적 인센티브 (추정)', FALSE, NULL, 1),
  (@comp_id, 'holiday_gift', '명절/생일/결혼기념일 포인트', 20, 'compensation',
   'est', '명절 선물 + 생일/결혼기념일 특별 포인트 (추정)', FALSE, NULL, 2),
  (@comp_id, 'excellence_award', '우수사원 포상', 30, 'compensation',
   'est', '성공 사례 또는 우수 사원 선정 시 포상금 (추정)', FALSE, NULL, 3),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계 및 연말 단체 Refresh 휴가 (본인 연차 사용)', 30),
  (@comp_id, 'long_service_leave', '장기근속 휴가/포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속휴가 및 포상', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '전 직원 단체상해보험 가입 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 100, 'family',
   'est', '(추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 20, 'family',
   'est', '휴가, 경조금, 화환 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/자기계발 교육', 50, 'growth',
   'est', '신규 입사자 교육, 직무 교육, e-러닝, 기타 직무수행 교육 지원 (추정)', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '리조트/게스트하우스', 50, 'leisure',
   'est', '법인 리조트 회원권 + 자체 게스트하우스 운영 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', 10, 'leisure',
   'est', '(추정)', FALSE, NULL, 71),
  (@comp_id, 'massage', '휴식공간 (포켓볼/안마의자)', NULL, 'leisure',
   'est', NULL, TRUE, '포켓볼, 안마의자 등 휴식 공간 제공', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 50, 'perks',
   'est', '복지포인트 50만원 지급', FALSE, NULL, 80),
  (@comp_id, 'meal', '조식/중식/석식 제공', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페/간식', 30, 'perks',
   'est', '사내 카페 운영 및 이용비 지원, 간식 및 음료 제공 (추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택/생계 대출', NULL, 'perks',
   'est', NULL, TRUE, '최대 7천만원 주택대출 + 최대 1천만원 생계대출 지원', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
