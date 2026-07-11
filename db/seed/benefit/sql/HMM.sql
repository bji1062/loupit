-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HMM 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hmm', 'HMM',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '해운', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hmm');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '본인+가족 종합건강검진', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '각종 질병/사고 대비 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산축하 용품', 10, 'family',
   'est', '출산축하 아기용품 지급 (추정)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '고등/대학 등록금 일부 또는 전액 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사/생일', 50, 'family',
   'est', '경조사비/특별휴가/화환, 웨딩카(대형세단+유류비), 생일 기프티콘 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무/직급별 교육, 해운실무, 전문자격 취득, 신임팀장과정, 리더십스쿨, 경영트렌드 특강', 60),
  (@comp_id, 'lang', '어학/글로벌 교육', NULL, 'growth',
   'est', NULL, TRUE, '전화/온라인 어학, BIZ English Workshop, 해외승선교육, 해외주재원 교육', 61),
  (@comp_id, 'career', '주재원/경력개발', NULL, 'growth',
   'est', NULL, TRUE, '전세계 20여개 법인, 70여개 지점 주재원 선발, 주니어 직무이동 제도', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인콘도', 50, 'leisure',
   'est', '다양한 지역 유명 휴양시설 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '독서/야구/축구/농구/산악/수영/볼링/마라톤/테니스 등, 체육대회/가요제', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드/포인트', 200, 'perks',
   'est', '여가/자기개발용 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '제휴식당', 432, 'perks',
   'est', '인근 제휴식당 중식/석식 무상, 일 18,000원 x 240일', FALSE, NULL, 81),
  (@comp_id, 'transport', '교통비', 30, 'perks',
   'est', '교통비 일정액 (추정)', FALSE, NULL, 82),
  (@comp_id, 'telecom', '통신비', 30, 'perks',
   'est', '통신비 일정액 (추정)', FALSE, NULL, 83),
  (@comp_id, 'snack_bar', '사내 카페', 30, 'perks',
   'est', '월간 한도 내 50% 지원 (추정)', FALSE, NULL, 84),
  (@comp_id, 'pension_support', '개인연금', 50, 'perks',
   'est', '가입금액 50% 지원 (추정)', FALSE, NULL, 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
