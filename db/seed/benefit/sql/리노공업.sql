-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 리노공업 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: 없음
-- badge: est
--
-- 참고:
--   출처 상세: 사용자 제공 검색 AI 요약(2026-10-04 · 사본 lino/user_paste_2026-10-04.txt · sha256 781515bb780859a215401938735b4becde5f7f191dd7165007d4c0e0716e2248) — 회사 공식 원문 아님 · 기준 39
--   공식 출처 탐색(2026-10-02): 자기 도메인 leeno.com 에 채용 · 복리후생 메뉴 없음, OpenDART 2025 사업보고서 · 2026 반기보고서에 직원 복지 제도 문장 없음.
--     마이다스 ATS leeno.recruiter.co.kr 는 robots 전면 금지라 읽지 않음. 공식 근거 행 0 — 전 행이 요약본 근거다.
--   요약본 체크리스트 항목 중 법정 제도(퇴직금 · 4대 보험 · 법정 휴가 · 근로자의 날 휴무)는 싣지 않았다.
--   요약본 뒤 4줄의 숫자 · 평가 문장은 쓰지 않았다(기준 39-c). 금액 전부 NULL — 구본 추정 승계 0.
--   상여금은 bonus(지급 기준 없는 이름). 공시의 성과급은 임원 전용이라 근거로 쓰지 않았다.
--   구본 5행은 같은 코드로 덮어쓴다(금액 비움). 새 행 3(bonus · leave_general · lounge). 재코딩 0. 신규 코드 0.
--   SORT 섹션 순서 = 요약본 분류 순서(지원금/보험 · 급여제도 · 교육/생활 · 리프레시).
-- 재수집(2026-10-04): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 사용자 제공 검색 AI 요약으로 다시 세웠다 — 공식 원문 없음(기준 39)
-- 검증(2026-10-04, RV-3-7 기준 39): 7행 전부 요약본 낱말 그대로 · 법정 4 · 숫자 평가 줄 제외 확인 · 머리말을 리드 판정 51 모양(URL 없음 · 출처 상세)으로 맞춤 · 리드 판정 53 휴식 공간 lounge 추가 — 최종 8행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lino', '리노공업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'R', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lino');

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

  -- ── 가족·돌봄 (family) — 요약본 지원금/보험 ──
  (@comp_id, 'event', '각종 경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 20),
  (@comp_id, 'child_edu', '자녀학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 — 지원금/보험 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 21),

  -- ── 보상 (compensation) — 요약본 급여제도 ──
  (@comp_id, 'bonus', '상여금', NULL, 'compensation',
   'est', NULL, TRUE, '상여금 — 급여제도 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 30),

  -- ── 경제적 부가혜택 (perks) — 요약본 교육/생활 ──
  (@comp_id, 'meal', '구내식당(사원식당)', NULL, 'perks',
   'est', NULL, TRUE, '구내식당(사원식당) — 교육/생활 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 40),
  (@comp_id, 'commute_subsidy', '통근버스 운행', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 — 출퇴근 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 41),

  -- ── 휴가 (time_off) — 요약본 리프레시 ──
  (@comp_id, 'leave_general', '경조휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '경조휴가제 — 리프레시 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 50),

  -- ── 근무환경 (work_env) — 요약본 사내 식당 및 편의 시설 ──
  (@comp_id, 'lounge', '휴식 공간', NULL, 'work_env',
   'est', NULL, TRUE, '휴식 공간 — 사내 식당 및 편의 시설 항목 (공식 원문 미확인 · 검색 AI 요약 기준)', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
