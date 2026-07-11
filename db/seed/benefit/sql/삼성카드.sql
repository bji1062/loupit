-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성카드 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 주의: 원본 txt 파일 내용이 "에코비트"로 표기됨 (삼성 계열사 환경사업 자회사)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_card', '삼성카드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '금융/카드', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '연 1회 정기 종합건강검진', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '본인/배우자 단체보험 (추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '헬스장 할인', 30, 'health',
   'est', '헬스장 등록비 최대 55% 할인 (추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '고등학교/대학교 학자금 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사/생일/명절', 50, 'family',
   'est', '경조휴가, 생일 문화상품권, 창립기념 쌀, 설/추석 현물 (추정)', FALSE, NULL, 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회', 200, 'leisure',
   'est', '연간 최대 200만원 지원', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'discount', '임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '의료기관/학원/콘도/여행/대형쇼핑몰 제휴할인, 삼성카드 임직원몰', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
