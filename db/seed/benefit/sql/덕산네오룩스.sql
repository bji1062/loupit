-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 덕산네오룩스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 82 카테고리 통일. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('duksan_neolux', '덕산네오룩스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '디스플레이소재', 'D', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  -- 2026-09-22 재코딩 excellence_award(compensation, 1) → long_service_leave(time_off, 19) — 우수 선발이 아니라 근속 연동 포상 — 리프레쉬 휴가가 한 줄에 있어 경계 규칙상 장기근속 휴가: db/migrations/20260922_recode_benefit_rows.sql
  (@comp_id, 'long_service_leave', '장기근속 포상', 50, 'time_off',
   'est', '근속메달, 기념패, 포상금, 해외여행, 리프레쉬 휴가 등 (추정)', FALSE, NULL, 19),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '정기 검진 + 개인 종합검진 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '대학교 전액 실비 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조금/입학축하금', 50, 'family',
   'est', '경조금, 휴가, 경조물품 + 유치원~고등학교 입학 축하금 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무 역량 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무 역량 교육 운영, 본인 학자금 지원 (정규대학/대학원)', 60),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 교육 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '하계 휴양시설', 50, 'leisure',
   'est', '제휴 휴양시설 추첨 제공 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영/지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '복지 포인트 지급 (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영, 간식 및 음료 제공', 81),
  -- 카테고리 통일(2026-09-21): perks → compensation
  (@comp_id, 'holiday_gift', '명절/창립기념일 선물', 20, 'compensation',
   'est', '설/추석 연 1회 + 창립기념일 기념품 (추정)', FALSE, NULL, 82),
  -- 2026-09-22 재코딩 dormitory(work_env, 20) → housing_support(perks, 82) — 시설이 아니라 주거 지원비(현금): db/migrations/20260922_recode_benefit_rows.sql
  (@comp_id, 'housing_support', '원거리 주거 지원', NULL, 'perks',
   'est', '6년간 지원', TRUE, '원거리 거주자 6년간 주거 지원비 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
