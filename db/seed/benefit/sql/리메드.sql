-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 리메드 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: 없음
-- badge: est
--
-- 참고:
--   출처 상세: 사용자 제공 검색 AI 요약(2026-10-04 · 사본 sha256 3a910083eb85b2718c2d0c471c5516b6aa632894815807f67db61e959db34f41) — 회사 공식 원문 아님 · 기준 39
--   자기 도메인(remed.kr)에 채용 · 복리후생 페이지가 없어 공식 원문은 OpenDART 공시뿐이다(2026-10-02 재탐색).
--   공식 근거 1건: 2025 사업보고서 [기재정정](접수 20260626000758) 이사회 중요의결사항 경조사비지원 규정 개정 승인 의안 — event 행 앞부분.
--   나머지 행은 요약본 항목 이름 그대로이고 서술 끝에 공식 원문 미확인 표기를 단다. 금액은 싣지 않는다.
--   요약본의 법정 항목(퇴직금 · 휴일 특근수당 · 4대 보험 · 주 52시간 · 주 40시간 · 연차)과 근무 환경 · 문화 묘사(회의실 · 전용 사옥 · 회식강요 안함)는 싣지 않았다.
--   구본 머리말이 txt 원본을 임프리메드코리아 데이터라고 밝혔다. 구본 stock_option · flex_work · leave_general 은 지우고(flex_work 는 공시 유연근무제 활용 여부 부와 어긋남),
--     health_check · meal · snack_bar 는 요약본 문장으로 덮어쓴다(구본 추정 금액 승계 0).
--   근거 URL 을 두지 않는다 — 3) URL 갱신 문장 없음. 재코딩 0 · 신규 코드 0. 직원 114명(1,000인 미만).
-- 재수집(2026-10-04): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공시와 사용자 제공 검색 AI 요약으로 다시 세웠다
-- 검증(2026-10-04, RV-3-7 기준 39): 행 조치 없음 — 요약본 낱말 글자 대조 · 법정 6 · 근무 환경 묘사 3 제외 · 금액 0 확인 — 최종 8행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('remed', '리메드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'R', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'remed');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 요약본 지원금/보험 ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 10),

  -- ── 가족·돌봄 (family) — 2025 사업보고서 이사회 의안 + 요약본 지원금/보험 ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지원 규정 운영 (2025 사업보고서 이사회 중요의결사항 경조사비지원 규정 개정 승인 항목), 각종 경조사 지원 — 지원금/보험 항목, 경조 범위·지원 금액 미기재 (공식 원문 미확인 · 검색 AI 요약 기준)', 20),

  -- ── 보상 (compensation) — 요약본 급여제도 · 선물 ──
  (@comp_id, 'incentive', '인센티브제', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브제 — 급여제도 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 30),
  (@comp_id, 'holiday_gift', '명절선물/귀향비', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물/귀향비 — 선물 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 31),

  -- ── 여가·라이프 (leisure) — 요약본 교육/생활 ──
  (@comp_id, 'company_event', '워크샵', NULL, 'leisure',
   'est', NULL, TRUE, '워크샵 — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 40),

  -- ── 경제적 부가혜택 (perks) — 요약본 교육/생활 ──
  (@comp_id, 'meal', '구내식당(사원식당) · 저녁식사 제공', NULL, 'perks',
   'est', NULL, TRUE, '구내식당(사원식당), 저녁식사 제공 — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 50),
  (@comp_id, 'snack_bar', '음료제공(차, 커피)', NULL, 'perks',
   'est', NULL, TRUE, '음료제공(차, 커피) — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 51),

  -- ── 근무환경 (work_env) — 요약본 출퇴근 ──
  (@comp_id, 'dormitory', '기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 — 출퇴근 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
