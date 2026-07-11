-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한미약품 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanmi_pharm', '한미약품',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_pharm');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '경영성과급/SEM', NULL, 'compensation',
   'est', NULL, TRUE, '분기별 CIQ+연간 업무 성과 기반 개인별 차등 성과급, 국내사업부 SEM 월간 성과 보상', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '사업장/직군별 맞춤 유연근무제', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '사업장별 라운지/여성휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '사업장별 라운지, 여성휴게실 별도, 수유실 운영', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 휴가 (연차 22일+)', NULL, 'time_off',
   'est', NULL, TRUE, '연차 22일, 리프레시 휴가, 휴가 및 숙박 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상 포인트', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 포인트 지급', 31),
  (@comp_id, 'birthday_leave', '기념일 축하 (연 4회 포인트)', NULL, 'time_off',
   'est', NULL, TRUE, '입사 1주년 축하 선물(Retention Program), 기념일 연 4회 포인트 지급', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '연 1회 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 전액 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀수 무관 자녀 학자금 전액 지원', 50),
  (@comp_id, 'parenting', '출산 축하 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 축하 지원', 51),
  (@comp_id, 'event', '경조사 지원/사우회', NULL, 'family',
   'est', NULL, TRUE, '경조금, 화환, 휴가 등 지원, 사우회 운영', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', 'H-MBA 핵심인재 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'H-MBA 핵심인재 Program 운영', 60),
  (@comp_id, 'edu_support', '계층/직무/어학 교육', NULL, 'growth',
   'est', NULL, TRUE, '임원/리더십/팔로워십/승진교육, 직무역량강화, 어학교육, 해외 연수', 61),
  (@comp_id, 'self_development', '개인학자금 (상급학교 전액)', NULL, 'growth',
   'est', NULL, TRUE, '개인학자금 상급학교 학자금 전액 지원', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '호텔/콘도 할인', 50, 'leisure',
   'est', '전국 유명 호텔/콘도 임직원 할인 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내식당 (조식/중식)', 360, 'perks',
   'est', '조식+중식 제공, 사내 중식당 50% 할인 (일 15,000원 x 240일 환산)', FALSE, NULL, 80),
  (@comp_id, 'commute_subsidy', '셔틀버스/교통비', 120, 'perks',
   'est', '셔틀버스 + 교통비 지원 (추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택자금 사내대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금을 위한 사내 대출 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
