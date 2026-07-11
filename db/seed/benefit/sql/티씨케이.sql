-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 티씨케이 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('tck', '티씨케이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'T', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'tck');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '영업이익 초과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '목표 영업이익 초과 달성 시 이익금 비율/임직원 수로 배분', 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사내 아파트/기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '출퇴근 거리에 따라 안성 시내 아파트 이용 가능', 20),
  (@comp_id, 'lounge', '사내 영화관', NULL, 'work_env',
   'est', NULL, TRUE, '퇴근 후 영화 관람 가능한 사내 영화관 운영', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진 (본인+배우자)', 100, 'health',
   'est', '지정병원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'medical', '본인 실비 의료비', 50, 'health',
   'est', '상해/질병 본인 실비 지원 (추정)', FALSE, NULL, 42),
  (@comp_id, 'fitness', '24시간 사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '24시간 이용 가능한 사내 헬스장 운영', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 (유학 포함)', 200, 'family',
   'est', '고등/대학 수업료, 유학자녀 국내사립대 수준 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조금/휴가', 50, 'family',
   'est', '(추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/계층별 교육', NULL, 'growth',
   'est', NULL, TRUE, '공통교육, 글로벌교육, 직무교육, 계층교육(신입OJT, 직급별, 승진자)', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '전국 콘도 회원권', 50, 'leisure',
   'est', '전국 유명 휴양지 콘도 보유 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '축구, 야구, 볼링, 산악, 자전거, 영화, 봉사 동아리 등', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '여행, 어학원, 온라인강좌, 서적, 영화, 공연, 헬스, 운동용품 등 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '조식/중식/석식 무료', 432, 'perks',
   'est', '삼시 무료 제공 (추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페/간식', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아 커피/차 무료, 현장직군 간식 지급', 82),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '기숙사 및 안성 주요 지점 통근 버스 (추정)', FALSE, NULL, 83),
  (@comp_id, 'housing_loan', '주택/전세/긴급 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입, 임차자금, 긴급자금 저리 대출 지원', 84),
  (@comp_id, 'holiday_gift', '명절/생일/결혼기념 포인트', 30, 'perks',
   'est', '명절 복지포인트, 생일/결혼기념일 축하 포인트 (추정)', FALSE, NULL, 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
