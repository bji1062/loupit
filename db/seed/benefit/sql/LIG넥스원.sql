-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LIG넥스원 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lig_nex1', 'LIG넥스원',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '방산', 'L', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근무시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '주 40시간 선택적 근무시간제, 시차출퇴근제', 10),
  (@comp_id, 'pc_off', 'PC-Off제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-Off제 시행', 11),
  (@comp_id, 'family_day', '가정의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 가정의 날', 12),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '지방사업장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방사업장 기숙사 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 5일 별도, 징검다리 휴가 권장', 30),
  (@comp_id, 'refresh_leave', '리프레시/Re-Fill 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 지원금(국내여행비), Re-Fill 휴가, 해외문화 체험비 지원, 여행포인트 지급, 마이너스휴가/연차이월 제도', 31),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이상 5년 단위 장기근속비 지급, 정년 퇴임식 및 기념품', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '본인/배우자 종합건강검진 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 정기보험', 30, 'health',
   'est', '본인/배우자 단체 정기보험 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담/헬스키퍼', NULL, 'health',
   'est', NULL, TRUE, '본인/가족 심리상담 지원, 헬스키퍼 상주, 금연/다이어트 캠페인', 42),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '사내외 피트니스센터 운영', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영, 육아기 근로단축', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀수 무관 학자금(중등/고등/대학), 만 6세 유치원비 지원', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금/경조휴가, 상조 인력/물품 지원, 사내커플 결혼 축하금, 초등/중등 입학/수능 축하 선물', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무/리더십 교육', NULL, 'growth',
   'est', NULL, TRUE, 'OJT, 직군별 입문교육, 2년차 리텐션, 직무역량/리더십 교육, 핵심인재 학위 파견', 60),
  (@comp_id, 'lang', '어학/사외 교육', NULL, 'growth',
   'est', NULL, TRUE, '어학교육, 사외 직무교육, 온라인/독서통신교육, 학회 논문/세미나 참석 지원', 61),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 지원', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원, 가족 초청행사, 무비데이', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '조/중/석식 제공', 432, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '(추정)', FALSE, NULL, 82),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택 임대/매입 자금 대출 지원, 수도권 입사자 특별 대출', 83),
  (@comp_id, 'snack_bar', '층별 Tea Zone/N-Cafe', NULL, 'perks',
   'est', NULL, TRUE, '층별 Tea Zone, N-Cafe, 호프데이', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
