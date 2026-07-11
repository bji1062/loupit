-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한미반도체 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanmi_semi', '한미반도체',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '아이디어/공로 포상', 50, 'compensation',
   'est', '아이디어 제안 포상금 + 회사 발전 공로자 포상금/상패 (추정)', FALSE, NULL, 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '1인1실 기숙사 무상 (신축 오피스텔)', NULL, 'work_env',
   'est', NULL, TRUE, '1인 1실 기숙사 무상 제공, 신축 오피스텔 풀옵션 완비', 20),
  (@comp_id, 'parking', '주차공간 제공', NULL, 'work_env',
   'est', NULL, TRUE, '주차공간 제공', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '특별 휴가 1주일 + 휴가비', 100, 'time_off',
   'est', '매년 1주일 특별 휴가 + 100만 복지포인트 지급', FALSE, NULL, 30),
  (@comp_id, 'long_service_leave', '장기근속 순금 선물', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 감사 선물(순금) 지급', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 (출장 검진)', 100, 'health',
   'est', '출장 건강 검진 실시 - 가천대 길병원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'fitness', '풋살/농구장', NULL, 'health',
   'est', NULL, TRUE, '전용 풋살, 농구장 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 (고등/대학)', 200, 'family',
   'est', '매년 고등학교, 대학교 학자금 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'fertility_support', '출산 축하 선물', 10, 'family',
   'est', '출산 축하 상품권 지급 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조금/장례용품', 50, 'family',
   'est', '각종 경조사 경조금, 경조휴가, 장례용 물품 지원 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '도서 구매 지원', 20, 'growth',
   'est', '(추정)', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '한화리조트', 50, 'leisure',
   'est', '주요 휴양지 리조트 제공 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트 (명절/가정의달)', 60, 'perks',
   'est', '설날/추석 각 20만 + 가정의 달 20만 복지포인트', FALSE, NULL, 80),
  (@comp_id, 'meal', '점심/저녁 무상 제공', 432, 'perks',
   'est', '대기업 전문 케이터링(아워홈) 입점 (추정)', FALSE, NULL, 81),
  (@comp_id, 'holiday_gift', '생일/명절 선물', 20, 'perks',
   'est', '생일 케이크 상품권 + 명절 복지포인트 (추정)', FALSE, NULL, 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
