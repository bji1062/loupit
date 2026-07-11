-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK이노베이션 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_innovation', 'SK이노베이션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '에너지/화학', 'S', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', 500, 'compensation',
   'est', '능력주의 성과급 제도 (추정)', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 지원', 10),
  (@comp_id, 'flex_work', '탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력근무제 운영', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '업무장비 지원', NULL, 'work_env',
   'est', NULL, TRUE, '노트북 및 사무용품 지원', 20),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무 시 기숙사 지원', 21),
  (@comp_id, 'nap_room', '휴게/편의시설', NULL, 'work_env',
   'est', NULL, TRUE, '수유실, 휴게실, 수면실, 사내 정원', 22),
  (@comp_id, 'parking', '주차장', NULL, 'work_env',
   'est', NULL, TRUE, '주차장 제공', 23),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '휴가제도', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 반차, 경조휴가, 창립일휴무, 근로자의날 휴무', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상제도 운영', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '정기 건강검진 본인+배우자+자녀 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인+배우자+자녀 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, 'Fitness Center 운영', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '산전후 휴가, 출산/육아 휴직', 50),
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영', 51),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '자녀 학자금 지원 (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조휴가 및 경조금 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '역량개발 교육', NULL, 'growth',
   'est', NULL, TRUE, '구성원 역량개발 및 리더십 육성 교육 제도', 60),
  (@comp_id, 'books', '사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, '사내 도서관 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소/콘도', 50, 'leisure',
   'est', '휴양소 및 콘도 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', 'SK행복카드/패밀리카드', 200, 'perks',
   'est', 'SK행복카드, SK패밀리카드 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '조식/중식/석식 제공, 일 18,000원 x 240일', FALSE, NULL, 81),
  (@comp_id, 'transport', '통근버스', 120, 'perks',
   'est', '통근버스 운행 (추정)', FALSE, NULL, 82),
  (@comp_id, 'commute_subsidy', '야간 교통비', 30, 'perks',
   'est', '야간 교통비 지급 (추정)', FALSE, NULL, 83),
  (@comp_id, 'snack_bar', '간식/음료', 50, 'perks',
   'est', '간식 및 음료 제공 (추정)', FALSE, NULL, 84),
  (@comp_id, 'housing_loan', '주택자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 융자 지원, 지방 근무 시 주거비 지원', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
