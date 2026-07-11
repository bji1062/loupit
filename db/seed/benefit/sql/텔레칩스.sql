-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 텔레칩스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('telechips', '텔레칩스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체/자동차칩', 'T', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'telechips');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', 'PI (최대 연봉 30%)', NULL, 'compensation',
   'est', 'Productivity Incentive: 최대 연봉의 30%', TRUE, 'PI(Productivity Incentive) + PS(Profit Sharing)', 1),
  (@comp_id, 'profit_sharing', 'PS (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, 'Profit Sharing 별도 지급', 2),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '휴게공간/수면실', NULL, 'work_env',
   'est', NULL, TRUE, '별도의 휴게공간, 수면실', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '정기 휴가 5일', NULL, 'time_off',
   'est', '휴가비 지원제도 포함', TRUE, '연차 이외 매년 5일 정기 휴가 자유 사용', 30),
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '5년, 10년 근속 휴가', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진 (본인+배우자)', 100, 'health',
   'est', '국내 최고 수준 시설, 팀장 이상 부모 검진 추가 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '의료 실비보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '결혼/환갑 축하, 조의금/조화/장례물품 지원 (추정)', FALSE, NULL, 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', 'CoT 교육/코칭', NULL, 'growth',
   'est', NULL, TRUE, '개인 적성 고려 CoT 교육 + 부서장 코칭', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '사내 카페/각 층 음료', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페, 각 층 커피/녹차 등 제공', 80),
  (@comp_id, 'meal', '무료 조식', 144, 'perks',
   'est', '무료 조식 제공 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
