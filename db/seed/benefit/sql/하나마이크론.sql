-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 하나마이크론 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://hanamicron.recruiter.co.kr/career/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 하나마이크론 공식 채용사이트(기업 홈 GNB 에서 직접 링크된
--       recruiter.co.kr 위탁 ATS)의 인사제도 > 복리후생 페이지.
--       Next.js App Router SPA 라 정적 fetch 는 빈 셸(가시 텍스트 16자)로 조용히
--       실패한다 — Playwright 헤드리스 렌더(networkidle + 3s)로 본문 693자 확보 후 파싱.
--       페이지 대분류 6개 / 개별 항목 14개 = 행 14개, 항목 누락·추가 없음.
--       금액: 페이지가 금액을 일절 공개하지 않는다. 신규 회사라 앵커도 없어
--       전 행 BENEFIT_AMT NULL + QUAL_YN TRUE (금액정책 (b) 명시값만).
--       incentive 행의 연간 0~300% 서술만 같은 사이트 /career/system(보상과 승진) 근거.
--       고유명사 처리: 급식 위탁사·리조트 제휴사 실명과 기숙사 번지 주소는
--       제3자 브랜드라 QUAL_DESC 에서 일반화(원문은 evidence 파일에 그대로 보존).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hana_micron', '하나마이크론',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체후공정', 'H', 'https://hanamicron.recruiter.co.kr/career/welfare');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hana_micron');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hanamicron.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── 원문 대분류: 우수사원 포상 및 격려금
  (@comp_id, 'excellence_award', '자랑스런 하나인상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 제도 자랑스런 하나인상 시상', 10),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 — 3/5/7/10년 등 근속연수에 따라 차등 지급', 11),
  (@comp_id, 'incentive', '생산성격려금(PI)', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과에 따라 생산성격려금(PI) 지급 — 경영실적에 따라 연간 0~300% 운영', 12),

  -- ── 근무환경 (work_env) ── 원문 대분류: 기숙사 및 통근버스
  (@comp_id, 'dormitory', '사원 전용 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '사원 주거 안정을 위한 전용 기숙사 제공 (충남 천안 소재)', 20),

  -- ── 건강·의료 (health) ── 원문 대분류: 건강 생활 지원
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 운영 (응급처치 및 비상약 제공, 건강상담 등)', 30),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '매년 전사원 일반검진, 만35세 이상 종합검진 제공', 31),

  -- ── 가족·돌봄 (family) ── 원문 대분류: 가정 생활 지원
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원', 41),

  -- ── 여가·라이프 (leisure) ── 원문 대분류: 여가 생활 지원
  (@comp_id, 'resort', '휴양시설(제휴 리조트)', NULL, 'leisure',
   'est', NULL, TRUE, '전국 제휴 리조트 무기명 회원권으로 휴양시설 이용', 50),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원', 51),

  -- ── 경제적 부가혜택 (perks) ── 원문 대분류: 사내 식당 및 Cafe / 통근버스 / 할인가맹점
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 운영 — 영양과 건강을 고려한 식단 제공 (급식 전문 업체 위탁 운영)', 60),
  (@comp_id, 'snack_bar', '사내 카페/무인매점', NULL, 'perks',
   'est', NULL, TRUE, '사내 Cafe 및 무인매점 운영', 61),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '천안 주요 지역 통근버스 운영', 62),
  (@comp_id, 'discount', '할인가맹점', NULL, 'perks',
   'est', NULL, TRUE, '병원·영화·헤어·안경·전자제품·자동차 등 업체와 협약해 임직원 할인가 제공', 63)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
