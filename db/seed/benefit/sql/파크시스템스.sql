-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파크시스템스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('park_systems', '파크시스템스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체계측', 'P', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'park_systems');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', 'PS/PI (연 1회)', NULL, 'compensation',
   'est', NULL, TRUE, '연 1회 PS/PI 지급', 1),
  (@comp_id, 'stock_option', '스톡옵션', NULL, 'compensation',
   'est', NULL, TRUE, '스톡옵션 선택적 지급', 2),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '기본 9am-6pm, 유연근무제 운영', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '필요시 재택근무 가능', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '고사양 PC 지원', NULL, 'work_env',
   'est', NULL, TRUE, '데스크탑 or 노트북 등 고사양 PC 지원', 20),
  (@comp_id, 'parking', '주차비 지원', NULL, 'work_env',
   'est', NULL, TRUE, '주차비 지원', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '5년, 10년, 15년 포상제도 운영', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '유료 건강검진 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'clinic', '보건 관리자 상주', NULL, 'health',
   'est', NULL, TRUE, '보건 관리자(간호사) 상주', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '유명 어린이집 운영', 50),
  (@comp_id, 'fertility_support', '출산 축하금', 100, 'family',
   'est', '출산 축하금 100만원 + 출산 선물', FALSE, NULL, 51),
  (@comp_id, 'event', '경조금/화환/상조용품', 50, 'family',
   'est', '(추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무 교육 전액 지원', NULL, 'growth',
   'est', NULL, TRUE, '원하는 직무 교육 모두 지원', 60),
  (@comp_id, 'lang', '어학 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '어학 프로그램 지원', 61),
  (@comp_id, 'mba', '대학원비 지원', NULL, 'growth',
   'est', NULL, TRUE, '대학원비 지원', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'library', '전자 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자 도서관 운영', 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영금 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '복지(몰)포인트 제도 운영 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '중식/석식 지원', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '스낵바 (커피, 다과 무료)', NULL, 'perks',
   'est', NULL, TRUE, '스낵바 운영 (커피, 다과 무료)', 82),
  (@comp_id, 'telecom', '통신비 지원', 30, 'perks',
   'est', '통신비 일부 지원 (추정)', FALSE, NULL, 83),
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'perks',
   'est', '(추정)', FALSE, NULL, 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
