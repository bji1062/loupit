-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LS마린솔루션 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.lsmarinesolution.co.kr/kor/Recruit
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인(lsmarinesolution.co.kr) 인재채용 상시 게시판. 복지 항목은 같은 게시판의 회사 공고
--     「통신 영업 및 선박 관리 경력직 채용 공고」(Recruitdetail?idx=44 · 게시 2024-06-18 · 접수 2024-07-03 마감 ·
--     게시판에 지금도 공개 · 첨부 PDF 같은 문안) 의 급여 및 근무조건 · 복리후생 블록에서 읽었다(SSR 원본 HTML · 렌더 없음).
--   보조 = OpenDART 2026 반기보고서(접수 20260814001451) 직원 등 현황 유연근무제도 사용 현황 표.
--   귀속: 공고 주어 · 문의처가 이 법인(LS Marine Solution · 메일 도메인 lsms.co.kr) — 각주 없음.
--     LS그룹 채용 인사제도 페이지(lsholdings.com · 주어 LS는 · 계열사 별 차이 단서)는 한 건도 쓰지 않았다.
--     기등록 형제 LS ELECTRIC · 가온전선 시드와 문장 겹침 없음.
--     구명 KT서브마린 시절 공고(2022 · idx=40)는 쓰지 않았다 — 2024 공고와 항목이 같고 2024 공고에 생일 축하금이 더해졌다.
--   금액: 원문에 원 숫자 없음 → 13행 전부 NULL(정성). 식대는 끼니 · 단가가 없어 NULL.
--   제외: 법정(4대보험 · 퇴직연금 · 법정 수당) · 이사회 안건 제목 사내근로복지기금 출연(제도 운영 문장 아님 — 판단 요청) ·
--     우리사주조합(주주 표 한 칸 · 수량 없음) · 원격근무제(공시 사용자 수 - · 자기 출처 문장 없음) · 임원 보수 칸.
--   공고 근거 12행 / 전체 13행 · SORT 섹션 순서 = 공고에 처음 나온 순서(compensation · perks · growth · family · health),
--     공시에만 있는 flexibility 는 끝.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 공고 근거 12행 등록(리드 판정 138 — 한시적 출처) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 13행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ls_marine_solution', 'LS마린솔루션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전선/전력', 'L', 'https://www.lsmarinesolution.co.kr/kor/Recruit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_marine_solution');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lsmarinesolution.co.kr/kor/Recruit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 2024 채용 공고 급여 및 근무조건 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과평가에 따라 별도 지급(연 1회) (공식 채용 공고 급여 및 근무조건 성과급 항목) — 지급 기준·지급률 미기재', 10),

  -- ── 경제적 부가혜택 (perks) — 2024 채용 공고 급여 및 근무조건 · 복리후생 ──
  (@comp_id, 'meal', '급식', NULL, 'perks',
   'est', NULL, TRUE, '급식 별도 지급 (공식 채용 공고 급여 및 근무조건 항목) — 제공 끼니·식대 단가 미기재', 20),
  (@comp_id, 'transport', '출퇴근 보조비', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 보조비 별도 지급 (공식 채용 공고 급여 및 근무조건 항목) — 지급 금액·지급 방식 미기재', 21),
  (@comp_id, 'telecom', '통신 보조비', NULL, 'perks',
   'est', NULL, TRUE, '통신 보조비 별도 지급 (공식 채용 공고 급여 및 근무조건 항목) — 지급 금액·지급 방식 미기재', 22),
  (@comp_id, 'housing_loan', '주택자금 및 생활안정자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 및 생활안정자금 대부 (공식 채용 공고 복리후생 항목) — 대부 한도·이율·상환 조건 미기재', 23),
  (@comp_id, 'birthday_gift', '생일 축하금', NULL, 'perks',
   'est', NULL, TRUE, '생일 축하금 지원 (공식 채용 공고 복리후생 항목) — 지급 금액 미기재', 24),
  (@comp_id, 'welfare_point', '복지 포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지 포인트 지급 (공식 채용 공고 복리후생 항목) — 배정 금액·사용처 미기재', 25),

  -- ── 성장·커리어 (growth) — 2024 채용 공고 복리후생 ──
  (@comp_id, 'self_development', '본인 학자금 지원', NULL, 'growth',
   'est', NULL, TRUE, '본인 학자금 지원 (공식 채용 공고 복리후생 항목) — 지원 과정·지원 범위 미기재', 30),

  -- ── 가족·돌봄 (family) — 2024 채용 공고 복리후생 ──
  (@comp_id, 'child_edu', '자녀 학자금·자녀교육 보조비', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원, 자녀교육 보조비 지원 (공식 채용 공고 복리후생 항목) — 지원 학령·지원 금액 미기재', 40),
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지원 (공식 채용 공고 복리후생 항목) — 경조 종류·지급 금액 미기재', 41),

  -- ── 건강·의료 (health) — 2024 채용 공고 복리후생 ──
  (@comp_id, 'medical', '본인 및 가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 의료비 지원 (공식 채용 공고 복리후생 항목) — 지원 범위·한도 미기재', 50),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (공식 채용 공고 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 51),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 사용자 2026년 반기 7명 · 2025년 27명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
