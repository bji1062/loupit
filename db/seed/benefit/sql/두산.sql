-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 원본 txt 내용은 "두산매거진" (두산 계열사)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan', '두산',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '인프라/에너지', 'D', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간 직접 선택', 10),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 운영', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '집중 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름 2주 + 겨울 1주 휴가, 해외문화탐방 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이후 5년마다 포상금+감사패', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원+배우자 종합건강검진', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자/자녀 치료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '대학까지 학자금 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사/명절', 50, 'family',
   'est', '경조금/경조휴가/상조, 명절선물 연2회 (추정)', FALSE, NULL, 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무역량 및 리더 성장 지원 교육 프로그램', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회, 두산베어스 홈경기 티켓', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
