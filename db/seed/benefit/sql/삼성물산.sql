-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성물산 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_ct', '삼성물산',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설/무역', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_ct');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '연령별 차등 혜택', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자 의료비, 자녀 실손보험 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '질병사망/상해사망/후유장해/3대질병 (추정)', FALSE, NULL, 42),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '레포츠센터 및 피트니스센터 이용 지원', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원/중/고/대학 학자금 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조금/경조휴가/화환, 직급/근속 차등 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'SVP(입문/승격/계층별), SLP(MBA/해외연수/경영자양성), SGP(지역전문가/어학/해외파견), SEP(상사실무/사업특화/Insight특강)', 60),
  (@comp_id, 'lang', '온라인 학습', NULL, 'growth',
   'est', NULL, TRUE, '어학/직무 등 온라인 학습 과정 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/워터파크', 100, 'leisure',
   'est', '전국 제휴 콘도, 캐리비안베이 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '연간 복지포인트 (추정)', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '무주택자 주택임차/구입 저금리 대출(사내근로복지기금)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
