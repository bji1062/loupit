-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엔켐 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('enchem', '엔켐',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'enchem');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', 100, 'compensation',
   'est', '(추정)', FALSE, NULL, 1),
  (@comp_id, 'stock_option', '스톡옵션', NULL, 'compensation',
   'est', NULL, TRUE, '스톡 옵션 부여', 2),
  (@comp_id, 'excellence_award', '우수 사원 포상', 30, 'compensation',
   'est', '(추정)', FALSE, NULL, 3),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'parking', '주차장 제공', NULL, 'work_env',
   'est', NULL, TRUE, '주차장 제공', 20),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발 지원', 50, 'growth',
   'est', '(추정)', FALSE, NULL, 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내 식당/식대 지원', 432, 'perks',
   'est', '구내 식당 + 식대 지원 (추정)', FALSE, NULL, 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
