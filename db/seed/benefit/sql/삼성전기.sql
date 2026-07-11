-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성전기 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_electro', '삼성전기',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전자부품', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_electro');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년/격년 정기 본인+배우자', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자/자녀 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '대학교까지 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조휴가/경조금/화환 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '입문/직무/승격/리더십 코칭 교육', 60),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '외국어 생활관(집중과정), 단기 인텐시브, 사내/사외 어학, 지역전문가(1년 해외파견)', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '워터파크/휴양소', 100, 'leisure',
   'est', '워터파크 및 전국 휴양소 할인 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '의류/식료품/스포츠/건강검진/여행/공연/독서/어학 등 (추정)', FALSE, NULL, 80),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '개인연금 보험 가입 일부 지원 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
