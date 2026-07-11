-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 비에이치 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('bh', '비에이치',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전자부품', 'B', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'bh');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'family_day', '가족의 날 조기 퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '일주일 중 하루 조기 퇴근 및 외식 상품권 지원', 10),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '연 1회 (추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금 지원', 50, 'family',
   'est', '(추정)', FALSE, NULL, 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발비 지원', 50, 'growth',
   'est', '(추정)', FALSE, NULL, 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '사내복지몰 운영 (추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '중식 식대 지원', 288, 'perks',
   'est', '전 임직원 대상 중식 식대 지원 (추정 일 12,000원 x 240일)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '저렴한 비용으로 음료 및 다과 이용 가능', 82),
  (@comp_id, 'telecom', '통신비 지원', 30, 'perks',
   'est', '업무용 개인 휴대폰 요금 지원 (추정)', FALSE, NULL, 83),
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'perks',
   'est', '(추정)', FALSE, NULL, 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
