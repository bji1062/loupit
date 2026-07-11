-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데케미칼 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_chem', '롯데케미칼',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'L', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'pc_off', 'PC-OFF제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF제 시행', 10),
  (@comp_id, 'flex_work', '선택적 근로제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로제, 워라벨데이, 본사 스마트오피스 운영', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택/독신자숙소', NULL, 'work_env',
   'est', NULL, TRUE, '사택 및 독신자숙소 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '힐링휴가/안식월/하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '힐링휴가, 안식월 휴가(간부사원), 하계휴가', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '종합 건강검진 및 정기 건강진단 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '병원비 지원', 50, 'health',
   'est', '1만원 이상 병원비 지급, 보험과 별개 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'fertility_support', '난임 직원 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 휴직 및 치료비 지원', 50),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영', 51),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원', 52),
  (@comp_id, 'parenting', '출산/육아 정책', NULL, 'family',
   'est', NULL, TRUE, '여성 자동육아휴직(2년), 남성 육아휴직 의무화', 53),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 격려 상여금', 54),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 학습비 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 어학학습비 지원', 60),
  (@comp_id, 'edu_support', '교육/자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '온라인강좌(롯데아카데미), 신입사원 입문과정, 해외연수, 글로벌 인재육성, R&D 스쿨, 직무별 전문가 과정/자격증 취득 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/리조트', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동 지원, 임직원 가족 문화체험활동', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트(엘포인트)', 130, 'perks',
   'est', '엘포인트 130만원 지급, 롯데그룹 제휴카드(W카드)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 융자 지원', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
