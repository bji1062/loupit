-- ══════════════════════════════════════════════════════════════════════
-- 유형별 복지 프리셋 28행 시드 (SP-SEED-4.2)
-- 소스: job_change/server/seed/seed.py BEN_PRESETS (큐레이션 상수, 재게시 아님)
-- 필드맵: key→BENEFIT_CD, name→BENEFIT_NM, val→BENEFIT_AMT, cat→BENEFIT_CTGR_CD,
--         badge→BADGE_CD, checked→DEFAULT_CHECKED_YN, 배열 인덱스→SORT_ORDER_NO
-- 역할: 비교 툴 "직접 입력" 모드 템플릿 (회사페이지 폴백 아님, D2.5)
-- 멱등: TBENEFIT_PRESET에 (COMP_TP_ID,BENEFIT_CD) UNIQUE 부재 → DELETE 후 전량 재삽입(full-refresh)
-- large 8 · mid 4 · public 8 · startup 2 · foreign 6 · freelance 0 = 28행
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

DELETE FROM TBENEFIT_PRESET;

INSERT INTO TBENEFIT_PRESET
  (COMP_TP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD, BADGE_CD, DEFAULT_CHECKED_YN, SORT_ORDER_NO)
VALUES
  -- ── large (대기업) 8행 ──
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'meal',      '식대 지원 (3식)',        360, 'perks',        'est', TRUE,  0),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'transport', '교통비/주차비',           120, 'perks',        'est', TRUE,  1),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'welfare',   '복지포인트/선택복지',     200, 'perks',        'est', TRUE,  2),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'bonus',     '성과급/인센티브',         300, 'compensation', 'est', FALSE, 3),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'health',    '건강검진 (본인+가족)',    100, 'health',       'est', TRUE,  4),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'housing',   '사내대출 이자절감',       200, 'perks',        'est', TRUE,  5),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'child_edu', '자녀 학자금',             300, 'family',       'est', FALSE, 6),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='large'), 'event',     '경조사 지원',             50,  'family',       'est', TRUE,  7),

  -- ── mid (중견기업) 4행 ──
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='mid'), 'meal',      '식대 지원',   300, 'perks',  'est', TRUE, 0),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='mid'), 'transport', '교통비',      60,  'perks',  'est', TRUE, 1),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='mid'), 'health',    '건강검진',    50,  'health', 'est', TRUE, 2),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='mid'), 'event',     '경조사 지원', 30,  'family', 'est', TRUE, 3),

  -- ── public (공기업) 8행 ──
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'meal',      '식대 지원 (3식)',     360, 'perks',  'est', TRUE,  0),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'transport', '교통비',              120, 'perks',  'est', TRUE,  1),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'welfare',   '복지포인트/선택복지', 250, 'perks',  'est', TRUE,  2),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'health',    '건강검진',            80,  'health', 'est', TRUE,  3),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'housing',   '사내대출 이자절감',   250, 'perks',  'est', TRUE,  4),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'child_edu', '자녀 학자금',         400, 'family', 'est', FALSE, 5),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'edu',       '교육비/자기개발비',   100, 'growth', 'est', TRUE,  6),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='public'), 'event',     '경조사 지원',         50,  'family', 'est', TRUE,  7),

  -- ── startup (스타트업) 2행 ──
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='startup'), 'meal',  '식대 지원 (3식)',       360, 'perks',        'est', TRUE,  0),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='startup'), 'stock', '스톡옵션/RSU 기대값',   500, 'compensation', 'est', FALSE, 1),

  -- ── foreign (외국계) 6행 ──
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'meal',      '식대 지원 (3식)',      360, 'perks',        'est', TRUE,  0),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'transport', '교통비',               100, 'perks',        'est', TRUE,  1),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'welfare',   '복지포인트',           150, 'perks',        'est', TRUE,  2),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'bonus',     '성과급/인센티브',      500, 'compensation', 'est', FALSE, 3),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'health',    '건강검진',             150, 'health',       'est', TRUE,  4),
  ((SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='foreign'), 'edu',       '교육비 (도서, 세미나)', 200, 'growth',       'est', TRUE,  5);
  -- freelance: 0행 (정상, SD-7)
