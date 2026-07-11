-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 휴젤 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hugel', '휴젤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오/제약', 'H', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '상황에 따라 필요시 원격근무 가능', 10),
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근, 시차출퇴근 운영', 11),
  (@comp_id, 'family_day', '패밀리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 셋째주 금요일 반일 근무', 12),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'welcome_kit', '온보딩 프로그램', NULL, 'work_env',
   'est', NULL, TRUE, '신규 입사자 온보딩 프로그램 운영', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연중 사용 가능한 Refresh 휴가 3일', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상제도 운영', 31),
  (@comp_id, 'birthday_leave', '창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 대체 휴무', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '당일 반차 지원', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '육아지원금', 120, 'family',
   'est', '미취학 아동 대상 (추정 월10만)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '고교, 대학 학자금 지원 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 향상 프로그램 지원', 60),
  (@comp_id, 'edu_support', '직무교육', NULL, 'growth',
   'est', NULL, TRUE, '직무 교육 프로그램(영업/생산/R&D), 개인 희망 교육(직무 연계) 지원, 사내 강사 제도 운영', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/리조트', 50, 'leisure',
   'est', '회원권 운영 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 120, 'perks',
   'est', '연간 최대 120만원 지급', FALSE, NULL, 80),
  (@comp_id, 'meal', '조식 제공', 144, 'perks',
   'est', '일 6,000원 x 240일 환산 (추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페', 50, 'perks',
   'est', '서울사무소 사내 카페 운영 (추정)', FALSE, NULL, 82),
  (@comp_id, 'commute_subsidy', '야근 교통비', 30, 'perks',
   'est', '야근 교통비 지원 (추정)', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
