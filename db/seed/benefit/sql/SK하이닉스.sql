-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK하이닉스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_hynix', 'SK하이닉스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '반도체', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_hynix');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브(PI/PS)', 500, 'compensation',
   'est', '최대 연봉 50% (추정)', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '1주~4주 단위 자율 근무시간 조절, Happy Friday(매월 셋째 금요일 자기개발/재충전)', 10),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '시·공간 제약 없는 업무환경 제공을 위해 거점오피스 운영', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '미혼 구성원 1인1실~2인1실, 침대/책상/에어컨 완비, 식당/체육관/편의점 등 부대시설', 20),
  (@comp_id, 'lounge', '사내 편의시설', NULL, 'work_env',
   'est', NULL, TRUE, '은행, 카페, 음식점, 편의점, 미용실, 세탁소, 약국, 제과점, 쇼핑센터 등', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상제도 운영', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 지원, 근속10년/만40세 이상 종합검진, 배우자 격년 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인+가족 질병/부상 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '사내 부속의원', NULL, 'health',
   'est', NULL, TRUE, '이천/청주 사내 부속의원, 물리치료실, 사내 약국 무료 이용', 42),
  (@comp_id, 'fitness', '체육시설', NULL, 'health',
   'est', NULL, TRUE, '체육관, 수영장, 헬스클럽, 테니스장, 볼링장, 스쿼시장, 풋살장 등', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신/출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '임신 전기간 단축근무, 난임휴가/의료비, 다자녀 출산축하금, 입학자녀 돌봄휴직 3개월, 도담이방(임산부 휴게공간)', 50),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '이천/청주/분당 어린이집 운영, 만2세~만5세 미취학 자녀 대상', 51),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원~대학 입학금/수업료 100% 실비 지원 (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조금/공조금, 화환, 장례지원 서비스 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'SKHU 반도체 전문가 학습 플랫폼, mySUNI SK그룹 교육, 국내외 우수대학 육성프로그램(ADP/KAIST EE/DSS)', 60),
  (@comp_id, 'career', '커리어 성장 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'CGP(Career Growth Program) 사내 커리어 성장, 글로벌 사업장 교환근무 기회', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/리조트', 50, 'leisure',
   'est', '소노호텔&리조트, 웰리힐리파크 등 법인콘도/호텔 할인 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동아리', NULL, 'leisure',
   'est', NULL, TRUE, '연극, 합창, 사진, 축구, 야구, 볼링, 수영, 테니스 등 25개 이상 동아리 운영', 71),
  (@comp_id, 'library', '사내 문화시설', NULL, 'leisure',
   'est', NULL, TRUE, '영화관, 갤러리, 공연장, 아트홀, 도서관, 북카페, 산책로', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '전용 복지포털 1,300여 가맹점 사용 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '조식/중식/석식/야식 무료, 기숙사 식당 포함, 일 18,000원 x 240일', FALSE, NULL, 81),
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '수도권 전 지역 무료, 리무진 통근버스, 다양한 시간대 운행 (추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/임차 자금 지원, 기혼 무주택자 임대아파트 3년 무료 제공', 83),
  (@comp_id, 'snack_bar', '카페테리아', 50, 'perks',
   'est', '사내 카페 운영 (추정)', FALSE, NULL, 84),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '월 납입액 50% 회사 지원 (추정)', FALSE, NULL, 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
