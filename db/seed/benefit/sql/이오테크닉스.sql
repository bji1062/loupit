-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이오테크닉스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('eo_technics', '이오테크닉스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '레이저장비', 'E', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eo_technics');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '장기근속 포상금', 50, 'compensation',
   'est', '근속 10년차부터 장기근속 포상금 지급 (추정)', FALSE, NULL, 1),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '남/여 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '남/여 휴게실(1인용 리클라이너), 사내 샤워실', 20),
  (@comp_id, 'parking', '무료 주차장 (300대)', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 무료 주차 개방 (300대 주차 가능)', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진 (간부 정밀)', 100, 'health',
   'est', '매년 종합검진, 간부급 삼성병원 정밀 검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '수술/입원비 지원', 100, 'health',
   'est', '본인, 배우자, 직계비속 수술 및 입원비 지원 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 전용 직장 어린이집 운영', 50),
  (@comp_id, 'child_edu', '대학교 등록금 지원', 200, 'family',
   'est', '(추정)', FALSE, NULL, 51),
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '산전후 휴가, 남성출산휴가, 보건휴가, 육아휴직', 52),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조금, 조화, 장례비품 지원 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학비 지원', 50, 'growth',
   'est', '영어/중국어/일본어 등 (추정)', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '자가 콘도/리조트 제휴', 50, 'leisure',
   'est', '부산, 강릉, 속초 자가 콘도 + 대명, 한화, 롯데 리조트 + 숙박요금 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '조식/중식/석식 제공', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
