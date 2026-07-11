-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화시스템 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_systems', '한화시스템',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '방산/IT', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_systems');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적/탄력적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제(주 단위 자유 선택), 탄력적 근로시간제(2주/3개월 단위 조정)', 10),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '육아와 업무를 병행하는 재택근무제 운영', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '안식휴가/채움휴직', NULL, 'time_off',
   'est', NULL, TRUE, '일정 주기 안식휴가 및 자기계발을 위한 채움휴직 제도', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '마음 건강 프로그램', NULL, 'health',
   'est', NULL, TRUE, '직원과 가족들의 건강한 마음을 위한 마음 건강 프로그램 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산휴가/아빠휴가', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산시 출산휴가 및 아빠휴가 부여', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원부터 대학교까지 자녀 학자금 지원', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '학위과정/교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '학술연수(국내 석/박사), 국내외 학위과정, 산업특화교육, Mentoring/Shadowing', 60),
  (@comp_id, 'career', '글로벌 리더 양성', NULL, 'growth',
   'est', NULL, TRUE, '해외법인 파견(미국/독일/중국/일본 등 1~2년 주재), 직무역량 강화(MOIM, 온라인콘텐츠), 재취업 교육 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소/워터파크', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '사업장 이동 근무시 주택대출 등 지원', 81),
  (@comp_id, 'meal', '조/중/석식 제공', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
