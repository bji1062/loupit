-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 케어젠 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: 없음
-- badge: est
--
-- 참고:
--   출처 상세: 사용자 제공 검색 AI 요약(2026-10-04 · 사본 sha256 47f345d07d5e5191656eed1e5fcf4c73c03381b652bb81b379bae64872f8f81b) — 회사 공식 원문 아님 · 기준 39
--   사본 = loupit-evidence 2026-10-02-recollect-3-7 caregen user_paste_2026-10-04.txt
--   공식 출처 탐색(2026-10-02): 자기 도메인 caregen.co.kr 은 robots.txt 부터 403 · OpenDART 2025 사업보고서 · 2026 반기보고서에 세울 수 있는 복지 문장 0
--   (우리사주조합 주주 현황 한 칸은 리드 판정으로 불성립 · 사내대출제도는 2026-10-04 기준 13 폐기로 welfare_fund_loan 행으로 되살림).
--   요약본 항목 가운데 법정 제도 · 근무 환경 묘사 · 회사 주도 교육 · 코드 없는 항목은 싣지 않았다. 전 행 금액 없음.
--   구본 9행: 덮어쓰기 7 · 재코딩 1(long_service_leave → long_service_bonus) · 삭제 1(excellence_award). 새 행 9.
-- 재수집(2026-10-04): 공식 출처 없음 — 사용자 결정(2026-10-04)으로 검색 AI 요약 기준 수록, 근거 URL 없는 회사로 남는다
-- 검증(2026-10-04, RV-3-7 기준 39): 17행 전부 요약본 낱말 그대로 · 법정 10 · 근무 환경 묘사와 회사 주도 교육 8 · 코드 없음 2 제외 확인 · 금액 0 · 머리말을 리드 판정 51 모양(URL 없음 · 출처 상세)으로 맞춤 — 최종 17행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(welfare_fund_loan) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('caregen', '케어젠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 10),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '각종 경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 20),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'discount', '주요 제품 직원 할인·자회사 제품할인', NULL, 'perks',
   'est', NULL, TRUE, '주요 제품 직원 할인 · 자회사 제품할인 — 지원금/보험 · 근무 환경 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 30),
  (@comp_id, 'birthday_gift', '생일선물/파티', NULL, 'perks',
   'est', NULL, TRUE, '생일선물/파티 — 선물 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 31),
  (@comp_id, 'meal', '저녁식사 제공·식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '저녁식사 제공 · 식비 지원 — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 32),
  (@comp_id, 'snack_bar', '음료제공(차, 커피)·카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '음료제공(차, 커피) · 카페테리아 — 교육/생활 · 근무 환경 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 33),
  (@comp_id, 'welfare_fund_loan', '사내대출제도 (퇴직금 한도 내)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대상 퇴직금 한도 내 사내대출제도 시행 (2025 사업보고서 · 2026 반기보고서 대주주 등과의 거래내용 신용공여 항목) — 대출 용도·금리 미기재, 직원대출제도 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 34),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'bonus', '상여금', NULL, 'compensation',
   'est', NULL, TRUE, '상여금 — 급여제도 항목, 지급 기준·지급률 미기재 (공식 원문 미확인 · 검색 AI 요약 기준)', 40),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 — 급여제도 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 41),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 — 급여제도 항목, 지급 기준·지급률 미기재 (공식 원문 미확인 · 검색 AI 요약 기준)', 42),
  (@comp_id, 'holiday_gift', '명절선물/귀향비', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물/귀향비 — 선물 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 43),

  -- ── 여가 (leisure) ──
  (@comp_id, 'company_event', '창립일행사', NULL, 'leisure',
   'est', NULL, TRUE, '창립일행사 — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 50),
  (@comp_id, 'summer_vacation_subsidy', '휴가비지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비지원 — 리프레시 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 51),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실 — 근무 환경 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 60),
  (@comp_id, 'uniform', '유니폼지급', NULL, 'work_env',
   'est', NULL, TRUE, '유니폼지급 — 근무 환경 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 61),
  (@comp_id, 'parking', '주차장제공', NULL, 'work_env',
   'est', NULL, TRUE, '주차장제공 — 출퇴근 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 62),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 — 리프레시 항목, 일수·유급 여부 미기재 (공식 원문 미확인 · 검색 AI 요약 기준)', 70),
  (@comp_id, 'leave_general', '경조휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '경조휴가제 — 리프레시 항목, 경조 사유별 일수 미기재 (공식 원문 미확인 · 검색 AI 요약 기준)', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
