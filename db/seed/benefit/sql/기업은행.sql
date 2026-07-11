-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 기업은행 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ibk', '기업은행',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '은행', 'I', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ibk');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '독신자 합숙소', NULL, 'work_env',
   'est', NULL, TRUE, '독신자 합숙소 운영', 20),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강진단', 100, 'health',
   'est', '직원 및 가족 건강진단 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '자녀 의료비 지원', 50, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '의무실 운영', NULL, 'health',
   'est', NULL, TRUE, '의무실 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 유치원비 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 유치원비 지원', 50),
  (@comp_id, 'event', '경조금/재해부조금', NULL, 'family',
   'est', NULL, TRUE, '재해부조금 및 각종 경조금 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '국내외 MBA 연수', NULL, 'growth',
   'est', NULL, TRUE, '국외(코넬대/미시건대/워싱턴대 등), 국내(KAIST/KDI) MBA 과정 연수', 60),
  (@comp_id, 'lang', '어학능력 향상 연수', NULL, 'growth',
   'est', NULL, TRUE, '어학능력향상 연수, 해외 벤치마킹/테마별 국외연수', 61),
  (@comp_id, 'edu_support', '학자금/자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '본인 학자금(대학원 포함), 각종 자격증 취득 지원, 자기계발비, 전문인력 육성, 기흥연수원/사이버연수원', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/휴양소', 50, 'leisure',
   'est', '콘도미니엄 대여 및 휴양소 운영 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복지제도', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택 임차/신용대출', NULL, 'perks',
   'est', NULL, TRUE, '무주택자 임차 주택 대여, 임직원 신용 대출 지원', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
