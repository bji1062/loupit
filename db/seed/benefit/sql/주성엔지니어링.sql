-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 주성엔지니어링 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jusung', '주성엔지니어링',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'J', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jusung');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 무료 제공', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 거주자 기숙사 무료 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시 휴가 (1달)', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 제도 (1달 연속 휴가)', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 임직원 검진 실시 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 (무제한)', 200, 'family',
   'est', '고등학교/대학교 등록금, 자녀 수 제한 없이 지원 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '기념일 조기퇴근', NULL, 'family',
   'est', NULL, TRUE, '부모님 생신, 배우자 생일, 결혼기념일 중 연 2회 17시 조기 퇴근', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인 콘도', 50, 'leisure',
   'est', '법인 명의 콘도 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내 식당 (삼시)', 432, 'perks',
   'est', '아침, 점심, 저녁 제공, 점심시간 2시간(12~14시) (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 사내 카페 운영, 커피 제공', 81),
  (@comp_id, 'holiday_gift', '명절 선물 포인트', 20, 'perks',
   'est', '설/추석 선물 포인트, 선물 신청몰에서 선택 (추정)', FALSE, NULL, 82),
  (@comp_id, 'transport', '대리운전비 지원', 30, 'perks',
   'est', '늦은 퇴근/업무 회식 시 대리 운전비 지원 (추정)', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
