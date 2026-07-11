-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 펄어비스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('pearl_abyss', '펄어비스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'P', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '최고 수준 업무 장비', NULL, 'work_env',
   'est', NULL, TRUE, '최고 수준 업무 장비 지원', 20),
  (@comp_id, 'lounge', '사내 힐링룸/안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '사내 힐링룸 전문 안마사 마사지 서비스, 안마의자', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진 + 검진 휴가', 100, 'health',
   'est', '매년 1회 종합건강검진 + 검진 휴가 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '본인/배우자/부모님/배우자 부모님/자녀 (추정)', FALSE, NULL, 41),
  (@comp_id, 'medical', '치과 진료비 지원', 255, 'health',
   'est', '치과 진료비 연간 최대 255만원', FALSE, NULL, 42),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터 지원', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 양육비/학자금', 700, 'family',
   'est', '자녀 1명당 매월 양육비 50만원(인원 무제한), 대학 등록금 연 최대 700만원', FALSE, NULL, 50),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 부부 시술 비용 횟수 제한 없이 지원', 51),
  (@comp_id, 'parenting', '부모 요양 치료비', 480, 'family',
   'est', '매월 최대 40만원 x 12개월', FALSE, NULL, 52),
  (@comp_id, 'event', '기념일 선물', NULL, 'family',
   'est', NULL, TRUE, '원하는 날짜에 원하는 곳 배송, 자녀 입학 선물 약 30만원', 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'conference', '최신 기술 스터디', NULL, 'growth',
   'est', NULL, TRUE, '최신 기술 스터디 지원', 60),
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '패밀리데이/반려동물 보험', NULL, 'leisure',
   'est', NULL, TRUE, '가족 참여 프로그램, 1인가구 가사 청소 월 1회, 반려동물 보험비 지원', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당 삼시세끼 무료', 432, 'perks',
   'est', '삼시세끼 무료 제공', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '무료 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '무료 카페테리아 운영', 82),
  (@comp_id, 'housing_loan', '거주비/대출 이자 지원', 600, 'perks',
   'est', '회사 인근 거주 시 매월 50만원 거주비, 그 외 지역 대출 이자 실비 지원', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
