-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- S-Oil 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('s_oil', 'S-Oil',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '정유/화학', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 's_oil');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'bonus', '상여금', 800, 'compensation',
   'est', '연 800% 상여금', FALSE, NULL, 1),
  (@comp_id, 'incentive', '성과급', 500, 'compensation',
   'est', '경영실적 기반 업계 최고 수준 (추정)', FALSE, NULL, 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'family_day', '패밀리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 수요일 정시퇴근 장려, 가족과의 시간/자기계발', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택', NULL, 'work_env',
   'est', NULL, TRUE, '사택 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '집중 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '연 1회 2주간 휴가사용 의무화 (사무직/기술직)', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '본인/배우자 일반검진 또는 종합검진', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자/자녀 치료비 및 병실료, 재해지원 최고 2천만원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '외부 전문기관 심리상담 서비스(직장/가정/대인관계), 스트레칭 타임(오전/오후)', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원~중등 분기 정액, 고등/대학 등록금 전액 지원, 장애자녀 특수교육비 추가 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사/사우회', 50, 'family',
   'est', '경조금/특별휴가, 사우회(소액대출/장제용품/생일선물) (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'conference', '세미나/컨퍼런스', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 외부 세미나/컨퍼런스 참여 적극 지원', 60),
  (@comp_id, 'edu_support', '직무교육', NULL, 'growth',
   'est', NULL, TRUE, '직무전문역량교육, 기본역량교육, 리더십 향상 교육, 신입사원 OJT', 61),
  (@comp_id, 'mba', 'MBA/석사과정', NULL, 'growth',
   'est', NULL, TRUE, '국내외 MBA 유학, 프랑스 IFP School 이공계 석사 지원', 62),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학과정: 영작문, 영어협상, 일본어, 중국어', 63),
  (@comp_id, 'career', 'Job Rotation/Posting', NULL, 'growth',
   'est', NULL, TRUE, 'Job Rotation(일정기간 후 직무순환), Job Posting(분기별 사내공모제)', 64),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '동/하계 휴양소, 전국 유명 콘도 이용 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 장려 및 운영비 지원, 체육의날/노사화합체육대회', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/전세자금 장기 저리융자', 80),
  (@comp_id, 'transport', 'KTX 비용 지원', 50, 'perks',
   'est', '매월 왕복 2회 KTX 지원 (추정)', FALSE, NULL, 81),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '매월 일정액 10년간 지원 (추정)', FALSE, NULL, 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
