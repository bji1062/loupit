-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 테크윙 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('techwing', '테크윙',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'T', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'techwing');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수/모범사원 포상', 50, 'compensation',
   'est', '공로상, 우수/모범사원, 제안/특허 포상 (추정)', FALSE, NULL, 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사내 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '사내 기숙사 운영', 20),
  (@comp_id, 'lounge', '복지동', NULL, 'work_env',
   'est', NULL, TRUE, '복지동(노래방, 스쿼시, 스크린골프, 실내야구 등)', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진 (본인+배우자)', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험 (상해/질병)', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영(정규직 간호사), 금연수당 지원', 42),
  (@comp_id, 'fitness', '체력단련실/운동장', NULL, 'health',
   'est', NULL, TRUE, '체력 단련실, 야외 운동장(풋살, 농구 등)', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '(추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조휴가/물품 지원', 50, 'family',
   'est', '승진자/결혼기념일 축하 선물 포함 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직급별 역량 강화 교육', NULL, 'growth',
   'est', NULL, TRUE, '신입/승진자 교육, 전사 조직활성화, 직급별 역량 강화', 60),
  (@comp_id, 'lang', '어학 자기계발비/온라인 강좌', NULL, 'growth',
   'est', NULL, TRUE, '어학 자기계발비 지원, 온라인 어학 강좌 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '리조트 (대명, 한화 회원권)', 50, 'leisure',
   'est', '숙박료 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'library', '북카페/전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '북카페 운영, 전자도서관 운영', 71),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '사내 직영 식당', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'commute_subsidy', '통근버스/교통비', 120, 'perks',
   'est', '통근버스 운행 + 교통비 지원 (추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '대출 제도', NULL, 'perks',
   'est', NULL, TRUE, '지원 대출 제도 운영', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
