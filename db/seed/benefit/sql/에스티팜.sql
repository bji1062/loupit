-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에스티팜 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.stpharm.co.kr/ko/careers
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 공식 출처 두 곳뿐이다. 둘 다 서버렌더 HTML 텍스트라 헤드리스 불필요.
--       S1 정본 = 자기 도메인 www.stpharm.co.kr/ko/careers 의 ST PHARM’s Welfare 섹션
--          (5카테고리 12항목 — Health Benefits · Leisure · Family · Office · Others).
--       S2 보조 = 동아쏘시오그룹 채용사이트의 에스티팜 법인 전용 페이지
--          talent.dongasocio.com/kr/page/donga/HRF102040 복리후생 블록 (5카테고리 13항목).
--          귀속 경로: 그룹 채용 홈 → 계열사 목록 에스티팜 → HRF102040, 본문 h2.name 에스티팜,
--          사업장 반월공장·시화공장, 사이트 바로가기 www.stpharm.co.kr, 채용 문의 insa@stpharm.co.kr.
--          형제 법인 동아ST 페이지(HRF102020)와 항목이 달라 공용 템플릿이 아니다 →
--          법인 전용 페이지라 그룹 통합 채용 기준 각주는 붙이지 않았다(삼성화재 선례).
--       두 출처는 8항목만 겹친다. 겹치는 항목은 한 행에 양쪽 라벨을 적고, 한쪽에만 있는
--          항목(S1 전용 4 · S2 전용 5 + 의료비 및 단체보험의 단체보험)도 둘 다 이 법인
--          공식 출처라 수록했다 — 행마다 출처를 QUAL_DESC 에 밝혔다. 합집합 → 18행.
--       국문판이 정본이다. 영문판 /en/careers 는 1:1 대응이 아니라(복지몰 운영 ↔ Selective
--          welfare system, 포상 제도 ↔ performance rewards 추가) 해석 보조로만 봤고 행 근거로 쓰지 않았다.
--       원문 오타 「사택 (반원, 시화 근무자)」의 반원은 반월공장이다(영문판 Banwol · S2 반월공장).
--       S2 호스트는 서버가 중간 인증서를 안 보낸다(curl exit 60). 검증을 끄지 않고 리프 인증서
--          AIA 의 Sectigo DV R36 중간 인증서를 받아 CA 번들에 더해 검증한 뒤 받았다.
--       그룹 공통 기업문화 페이지(복지 항목 0)·그룹 ATS donga.recruiter.co.kr(robots 전면 금지)·
--          주차 도메인 www.stpharm.com 은 쓰지 않았다.
--       금액: 두 출처 모두 금액 표기 0건 → 18행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       신규 코드 0. 법정 제도 서술은 두 출처에 없다.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 18 → 17행. SORT 41 복지몰 운영(discount)은 영문판이 같은 칸을
--       Selective welfare system 으로 옮겨 SORT 43 선택적 복지(welfare_point)에 병합 · SORT 70 미기재 사항 보강.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('stpharm', '에스티팜',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'S', 'https://www.stpharm.co.kr/ko/careers');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'stpharm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.stpharm.co.kr/ko/careers'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — S1 Health Benefits · S2 HEALTH ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '상해, 재해 관련 의료비 (에스티팜 홈페이지 Careers 페이지 Health Benefits 항목) · 의료비 및 단체보험 (동아쏘시오그룹 채용사이트 에스티팜 페이지 HEALTH 항목) — 지원 한도·지원 비율·가족 포함 여부 미기재', 10),
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 검진 (에스티팜 홈페이지 Careers 페이지 Health Benefits 항목) · 건강검진 (동아쏘시오그룹 채용사이트 에스티팜 페이지 HEALTH 항목) — 검진 주기·검진 항목·가족 포함 여부·비용 미기재', 11),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '의료비 및 단체보험 (동아쏘시오그룹 채용사이트 에스티팜 페이지 HEALTH 항목에만 기재) — 보장 범위·가입 대상·보험료 부담 미기재', 12),

  -- ── 여가·라이프 (leisure) — S1 Leisure · S2 REFRESH ──
  (@comp_id, 'resort', '콘도 숙박 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 숙박 제공, 회사 보유분에 한함 (에스티팜 홈페이지 Careers 페이지 Leisure 항목) · 콘도/리조트 지원 (동아쏘시오그룹 채용사이트 에스티팜 페이지 REFRESH 항목) — 보유 콘도 위치·이용 횟수·본인 부담 미기재', 20),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (에스티팜 홈페이지 Careers 페이지 Leisure 항목에만 기재) — 동호회 종류·활동비 한도 미기재', 21),

  -- ── 가족·돌봄 (family) — S1 Family · S2 LIFE·FAMILY ──
  (@comp_id, 'event', '경조사 지원금', NULL, 'family',
   'est', NULL, TRUE, '가족 경조사 지원금 (에스티팜 홈페이지 Careers 페이지 Family 항목) · 경조사 지원 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목) — 경조 구분별 지원 금액 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (에스티팜 홈페이지 Careers 페이지 Family 항목 · 동아쏘시오그룹 채용사이트 에스티팜 페이지 FAMILY 항목) — 대상 학교급·자녀 수 제한·지원 한도 미기재', 31),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 (동아쏘시오그룹 채용사이트 에스티팜 페이지 FAMILY 항목에만 기재) — 설치 위치·정원·대상 연령 미기재', 32),

  -- ── 경제적 부가혜택 (perks) — S1 Office·Others · S2 LIFE ──
  (@comp_id, 'meal', '중식 식대 제공', NULL, 'perks',
   'est', NULL, TRUE, '식대 제공, 중식 (에스티팜 홈페이지 Careers 페이지 Office 항목에만 기재) — 제공 방식·식대 단가 미기재', 40),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목에만 기재) — 운행 노선·대상 사업장·본인 부담 미기재', 42),
  (@comp_id, 'welfare_point', '선택적 복지·복지몰', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복지 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목) · 복지몰 운영 (에스티팜 홈페이지 Careers 페이지 Others 항목) — 연간 포인트 금액·사용처 미기재', 43),
  (@comp_id, 'housing_loan', '임직원 대출', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대출 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목에만 기재) — 대출 용도·한도·이율 미기재', 44),

  -- ── 근무환경 (work_env) — S1 Office · S2 LIFE ──
  (@comp_id, 'dormitory', '사택·기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '사택, 반월·시화 근무자 대상 (에스티팜 홈페이지 Careers 페이지 Office 항목) · 기숙사 운영 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목) — 입주 자격·세대 수·본인 부담 미기재', 50),

  -- ── 성장·교육 (growth) — S1 Office · S2 CAREER ──
  (@comp_id, 'edu_support', '사외 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육비, 사외 교육 훈련 (에스티팜 홈페이지 Careers 페이지 Office 항목) · 자기개발 지원 (동아쏘시오그룹 채용사이트 에스티팜 페이지 CAREER 항목) — 지원 한도·대상 과정 미기재', 60),

  -- ── 보상·금전 (compensation) — S1 Office · S2 REFRESH·LIFE ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '포상 제도, 장기 근속 등 (에스티팜 홈페이지 Careers 페이지 Office 항목) · 장기 근속 포상 (동아쏘시오그룹 채용사이트 에스티팜 페이지 REFRESH 항목) — 근속 연수 기준·포상 내용(금품·휴가 여부)·금액 미기재', 70),
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주제도 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목에만 기재) — 배정 조건·회사 지원 여부 미기재', 71),

  -- ── 휴가 (time_off) — S1 Others ──
  (@comp_id, 'summer_leave', '하계·동계 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 제도, 하계·동계 (에스티팜 홈페이지 Careers 페이지 Others 항목에만 기재) — 부여 일수·유급 여부·시기 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
