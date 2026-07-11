-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NH투자증권 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nh_invest', 'NH투자증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'N', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nh_invest');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 별도 지급', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 시행', 10),
  (@comp_id, 'pc_off', 'PC OFF제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC OFF제 시행', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '다양한 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '다양한 휴가 제도 운영', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', 600, 'health',
   'est', '본인 무제한, 가족 연간 600만원 한도', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학/중/고/대학교 자녀 학자금 지원', 50),
  (@comp_id, 'event', '경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 지원', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 지원', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드', 300, 'perks',
   'est', '연간 300만원 선불카드 지급', FALSE, NULL, 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
