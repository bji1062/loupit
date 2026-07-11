-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 유한양행 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('yuhan', '유한양행',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'Y', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'yuhan');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '기념일 기념품', 20, 'compensation',
   'est', '창립기념일, 근로자의 날, 생일 등 기념품 지급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'excellence_award', '장기근속 포상/퇴직금 누진제', NULL, 'compensation',
   'est', NULL, TRUE, '퇴직금 누진제, 장기근속 표창+기념품+상금+특별휴가+자사주식, 정년퇴직자 6개월 공로연수휴가', 2),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '지방지점 합숙소', NULL, 'work_env',
   'est', NULL, TRUE, '지방지점 합숙소 운영', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차휴가 (법정 상회)', NULL, 'time_off',
   'est', NULL, TRUE, '연간 22일(최대 32일) 연차휴가 부여, 자유로운 휴가사용 문화', 30),
  (@comp_id, 'long_service_leave', '장기근속 특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 특별휴가, 정년퇴직자 6개월 공로연수휴가', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '초음파/내시경/암검사 포함 매년 실시 (추정)', FALSE, NULL, 40),
  (@comp_id, 'fitness', '사내 헬스클럽', NULL, 'health',
   'est', NULL, TRUE, '본사, 공장, 연구소에 실내 헬스클럽 운영', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 전액 지원', 200, 'family',
   'est', '자녀수 제한없이 중고등/대학교(의/약/치의학전문대학원 포함) 전액 실비 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조금/경조휴가', 20, 'family',
   'est', '경조금, 경조휴가, 부의용품, 화환, 사우공제회 (추정)', FALSE, NULL, 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육/연수 지원', 100, 'growth',
   'est', '리더십교육, 전문과정, 역량교육, 사외 전문교육과정 (추정)', FALSE, NULL, 60),
  (@comp_id, 'mba', '단기 MBA/석박사 파견', NULL, 'growth',
   'est', NULL, TRUE, '단기 MBA과정, 석박사 학위 파견', 61),
  (@comp_id, 'lang', '어학 지원', 50, 'growth',
   'est', '국내/해외 어학연수, 사내 원어민 스터디, 어학과정(동영상/전화/화상/학원) (추정)', FALSE, NULL, 62),
  (@comp_id, 'books', '버들문고/전자도서관', 10, 'growth',
   'est', '희망 도서구매 지원, 회사 전용 전자도서관 (추정)', FALSE, NULL, 63),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '하기휴양소/콘도미니엄', 50, 'leisure',
   'est', '하기휴양소 및 콘도미니엄 운영 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', 10, 'leisure',
   'est', '사내 동호회 운영 및 활동비 지원 (추정)', FALSE, NULL, 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 저금리 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 저금리 장기 대출 제도, 전근사원 이사비 실비 지급', 80),
  (@comp_id, 'transport', '통근버스/유류대', 120, 'perks',
   'est', '공장/연구소 통근버스, 차량 유류대 지원 (추정)', FALSE, NULL, 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
