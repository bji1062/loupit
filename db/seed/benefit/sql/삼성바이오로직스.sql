-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성바이오로직스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_bio', '삼성바이오로직스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '바이오', 'S', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_bio');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원+가족 건강검진 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '임직원+가족 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '사내 부속의원/약국', NULL, 'health',
   'est', NULL, TRUE, '사내 부속의원과 약국 운영, 응급상황 대비 및 건강관리', 42),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스센터, 전문 강사 개인별 맞춤 트레이닝', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '바이오 드림파크 어린이집 사내 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원~대학교 학자금 지원 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, '바이오 전문가 역량개발, 리더십 과정, GMP교육, Biotech Training Lab 실습', 60),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학과정(글로벌 임직원 한국어 포함), Biz. Skill Up 온라인 과정', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '국내 휴양소 제휴 여가 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'library', '사내 북카페', NULL, 'leisure',
   'est', NULL, TRUE, '원하는 책 자유 대여 휴식공간', 71),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '자기계발/취미/건강/여행 등 포인트 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '건강식 무료 제공, 일 18,000원 x 240일', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
