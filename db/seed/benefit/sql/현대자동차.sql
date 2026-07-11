-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대자동차 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_motor', '현대자동차',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차', 'H', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '정식 근무형태, 재택근무 사무기기/인프라 지원', 10),
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '핵심근무(10시~16시) 외 출퇴근 자율, 서울/경인 8개 거점오피스(H-Work Station)', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '휴게공간', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자/수면 가능 휴게공간, 허브라운지, 포레스트라운지', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '자율 사용 5일 하기휴가, 책임 진급시 3주 유급휴가', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '정기 건강검진', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '직원+가족 질병/부상 진료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),
  (@comp_id, 'clinic', '사내 의원/약국', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 의료기관(의원/약국) 운영', 43),
  (@comp_id, 'fitness', '짐나지움', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 짐나지움 운영', 44),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산휴가(여90일/남10일), 육아휴직 최대2년, 가족여행(2박3일 숙식), 난임치료 연3일 휴가', 50),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '각 사업장별 전문 위탁 어린이집 운영', 51),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '자녀 교육비 부담완화 (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '최대 10일 경조사 휴가 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '러닝라운지/러닝랩', NULL, 'growth',
   'est', NULL, TRUE, '러닝라운지(12,000개 학습솔루션), 러닝랩(자발적 학습모임 활동비), 성장계획 제도', 60),
  (@comp_id, 'career', '사내공모/주재원', NULL, 'growth',
   'est', NULL, TRUE, '사내공모 직무변경, 전세계 해외사업장 주재원 기회', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '사계절 휴양소', 50, 'leisure',
   'est', '전국 유명 호텔/리조트 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '여가생활 포인트', 200, 'perks',
   'est', '여행/문화공연/건강관리/자기계발 등 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '위생적 영양 식사, 일 18,000원 x 240일', FALSE, NULL, 81),
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '사업장별 통근버스 (추정)', FALSE, NULL, 82),
  (@comp_id, 'discount', '차량 할인', NULL, 'perks',
   'est', NULL, TRUE, '본인명의 차량 구입/수리비 할인, 자가정비코너 운영', 83),
  (@comp_id, 'snack_bar', '간식코너', 50, 'perks',
   'est', '간식캔틴, 도시락 자판기 등 (추정)', FALSE, NULL, 84),
  (@comp_id, 'housing_loan', '주거지원금 대출', NULL, 'perks',
   'est', NULL, TRUE, '저리 장기 주거지원금, 사택/기숙사', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
