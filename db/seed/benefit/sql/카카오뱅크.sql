-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오뱅크 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_bank', '카카오뱅크',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '핀테크/은행', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '스톡옵션', NULL, 'compensation',
   'est', NULL, TRUE, '스톡옵션 선택적 지급', 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', 'Mytime 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '30분 단위 출근시간 선택(오전 8~10시), 자율적 업무시간 설정', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 시행 중(팀별 상이)', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '유연한 휴가 사용', NULL, 'time_off',
   'est', NULL, TRUE, '연 15일 휴가, 2시간/4시간/8시간 자유로운 사용', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', 200, 'time_off',
   'est', '만 3년 근속 시 유급 휴가 및 휴가비 200만원', FALSE, NULL, 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '본인 및 가족 1명 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '본인/배우자/자녀/부모/배우자부모까지 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신/출산/육아 제도', NULL, 'family',
   'est', NULL, TRUE, '임신기간 근무단축, 산전후휴가, 육아휴직, 난임휴가 등', 50),
  (@comp_id, 'childcare', '어린이집 지원', NULL, 'family',
   'est', NULL, TRUE, '신청시 어린이집 등원 가능', 51),
  (@comp_id, 'child_edu', '자녀 학자금/영유아 지원', 10, 'family',
   'est', '고등/대학 학자금 지원, 4~7세 자녀 영유아지원금 월 10만원(2년간)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가/경조비, 장의용품/장례도우미 파견 지원', 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육/컨퍼런스', NULL, 'growth',
   'est', NULL, TRUE, '사내 Insight & Trend 교육, 해외 컨퍼런스 참여, 외부 교육 수강 지원', 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '자기계발비', 600, 'perks',
   'est', '연 600만원 자기계발비', FALSE, NULL, 80),
  (@comp_id, 'meal', '사내식당', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '대출이자 지원 제도', 82),
  (@comp_id, 'snack_bar', '사내 스낵바', NULL, 'perks',
   'est', NULL, TRUE, '사내 스낵바 운영', 83),
  (@comp_id, 'discount', '카카오프렌즈샵 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오프렌즈샵 20% 할인', 84),
  (@comp_id, 'work_tools', '스탠딩 책상', NULL, 'perks',
   'est', NULL, TRUE, '스탠딩 책상 지원', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
