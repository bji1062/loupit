-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성SDI 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_sdi', '삼성SDI',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리/전자', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_sdi');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 전 임직원 건강진단 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자 질병/부상/출산 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '열린 상담 센터: 직장생활/개인 고충/생활 전반 전문 심리상담', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '각 사업장 사내 어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '사내 복지기금 학비 지원 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조사 지원금 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', 'MBA/학술연수', NULL, 'growth',
   'est', NULL, TRUE, '삼성MBA/E-MBA, R&D 국내외 석박사 학술연수, 지역전문가(3개월 어학+1년 현지연구)', 60),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '외국어 생활관, 사내 어학과정 개설', 61),
  (@comp_id, 'edu_support', '학습셀/교육', NULL, 'growth',
   'est', NULL, TRUE, '10주 학습셀 프로그램, 부서간 교육 콘텐츠 학습', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/워터파크', 100, 'leisure',
   'est', '캐리비안베이 저렴이용, 전국 콘도/리조트 회원권 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '건강관리/여가/자기계발 등 자유 사용 (추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '무주택 사원 주택 구입 저금리 대출', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
