-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화에어로스페이스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_aerospace', '한화에어로스페이스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공/방산', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_aerospace');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근제', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '아빠휴가', NULL, 'time_off',
   'est', NULL, TRUE, '아빠휴가 제도', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '본인/가족 의료비 지원', 100, 'health',
   'est', '(추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원, 사우회(경조사회)', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '해외 석/박사/교육', NULL, 'growth',
   'est', NULL, TRUE, '해외 석/박사 프로그램, 교육비 지원, 해외법인 파견근무, 신입사원교육, 외국어 교육 지원', 60),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구입비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '한화리조트/더플라자호텔', 50, 'leisure',
   'est', '한화리조트 할인, 더플라자호텔 할인 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'discount', '한화갤러리아/63빌딩 할인', NULL, 'perks',
   'est', NULL, TRUE, '한화갤러리아, 63빌딩 할인, 한화 문화센터 지원', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
