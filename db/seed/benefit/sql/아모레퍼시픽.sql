-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아모레퍼시픽 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('amorepacific', '아모레퍼시픽',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'A', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'amorepacific');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절/기념일 선물', 30, 'compensation',
   'est', 'Happy Gift(설, 추석, 근로자의 날) 특별 선물 (추정)', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원이 근로시간 및 근로장소를 선택/조정 가능', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '루프가든/미술관/여성휴게라운지', NULL, 'work_env',
   'est', NULL, TRUE, '본사 속 세 개의 정원 루프가든, 사내 미술관 전시 관람, 여성 휴게 라운지', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', 'Refresh/Happy Vacation/가산연차', NULL, 'time_off',
   'est', NULL, TRUE, '일반 연차에 추가로 Refresh, Happy Vacation, 가산 연차 지원', 30),
  (@comp_id, 'birthday_leave', '생일반차(유급)', NULL, 'time_off',
   'est', '생일 선물 및 생일반차(유급) 제공', TRUE, NULL, 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'clinic', 'AP-세브란스 클리닉', NULL, 'health',
   'est', NULL, TRUE, '본사 16층 사내 병원, 가정의학과/산부인과/이비인후과 등 전문의급 의료진 진료', 40),
  (@comp_id, 'mental', '해피라이프 컨설팅', NULL, 'health',
   'est', NULL, TRUE, '전문상담기관을 통한 심리적 지원 프로그램', 41),
  (@comp_id, 'fitness', 'AP 피트니스', NULL, 'health',
   'est', NULL, TRUE, '요가, 퍼스널 트레이닝, 필라테스, 발레피트, 줌바 등 프로그램 제공', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '300여평, 90명 규모 사내 어린이집 운영', 50),
  (@comp_id, 'child_edu', '자녀 학자금/유치원 보조금', 100, 'family',
   'est', '유치원 보조금 + 자녀 학자금 지원 (추정)', FALSE, NULL, 51),
  (@comp_id, 'parenting', '예비맘 배려', NULL, 'family',
   'est', NULL, TRUE, '예비맘 단축근무, 임산부 전용 의자/발받침대/담요, 태아검진 외출/조퇴 허용', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '평생 맞춤형 학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기주도적 학습을 통해 지속적으로 성장할 수 있도록 지원', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양지/콘도', 50, 'leisure',
   'est', '임직원 전용 휴양지와 콘도 서비스 운영 (추정)', FALSE, NULL, 70),
  (@comp_id, 'massage', '마사지 테라피 라온(RA-ON)', NULL, 'leisure',
   'est', NULL, TRUE, '시각장애인 안마사의 전문 수기치료 서비스 제공', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복지제도', 200, 'perks',
   'est', '자기계발 및 다양한 복지혜택 제공 (추정)', FALSE, NULL, 80),
  (@comp_id, 'discount', '자사 제품 임직원 특별가', 50, 'perks',
   'est', '임직원 전용 구매사이트 (추정)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택자금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '매매/전세 주택자금 지원 제도', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
