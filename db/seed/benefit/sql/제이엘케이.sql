-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 제이엘케이 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jlk', '제이엘케이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'AI/의료', 'J', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jlk');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과 인센티브', 100, 'compensation',
   'est', '업무 성과에 따른 인센티브 (추정)', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '출근시간을 유연하게 선택 가능', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '고급 안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '고급 안마의자 제공', 20),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육/특허 공동출원', NULL, 'growth',
   'est', NULL, TRUE, '업무를 위한 교육 및 특허 공동 출원 지원', 60),
  (@comp_id, 'books', '업무 도서 지원', 10, 'growth',
   'est', '(추정)', FALSE, NULL, 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', 10, 'leisure',
   'est', '다양한 사내 동호회 활동 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '조식/중식/석식 제공', 432, 'perks',
   'est', '매일 다른 메뉴의 아침식사 + 점심/석식 식대 제공 (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', 'Hello Cafe 포인트', 60, 'perks',
   'est', '매달 5만 포인트, 최고급 원두 커피와 간식 이용', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
