-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한국스탠다드차타드은행(SC제일은행) 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.standardchartered.co.kr/np/kr/cms/cm/bi/RecruitInfo.jsp?menuId=HT02040100000000
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 www.standardchartered.co.kr 은행소개 → 채용정보 → 인사제도 안내 페이지(서버 렌더 HTML).
--     본문은 인사제도 개요(보상 및 복지정책 낱말)와 HR Capital 바퀴 그림뿐이라 이 페이지로 세운 행은 없다 —
--     점검기가 읽는 상시 인재채용 페이지라 정본으로 둔다. 정시 · 수시 · 특별 채용 탭 본문은 POST 로만 내려와 받지 않았다.
--   법인 고유 근거(자기 공시 · 각주 없음): OpenDART 2025 사업보고서(접수 20260331004354) ·
--     2026 반기보고서(접수 20260814002332) — 사업의 내용 종업원 등에 관한 사항(특별퇴직 · 자율출퇴근제도) ·
--     직원 등 현황 유연근무제도 사용 현황 표 · 연결재무제표 주석 주식기준보상(적금가입형 주가차액보상권).
--   그룹 템플릿 근거(각주 그룹 통합 채용 기준): Standard Chartered 그룹 채용 사이트 jobs.standardchartered.com 의
--     서울 근무 공고 2건(Global Markets Graduate Programme Korea 2027 · Coverage Banking Graduate Programme Korea 2027,
--     게시 종료 2026-12-31)의 What we offer 블록 — 두 공고 블록이 글자까지 같고 전 세계 공고 공통 문안이다.
--     귀속 = 공고 근무지 Seoul, KOR · 그룹 채용 사이트 South Korea student opportunities 페이지가 한국 법인을
--     Standard Chartered 의 100% 자회사로 소개. 기등록 SC 계열 0 → 템플릿 근거 행 4개 전부 각주.
--     블록 안 in some locations 단서는 flexible and voluntary benefits 구절에만 붙어 그 구절은 싣지 않았다.
--   금액: 금액 행 0(stated 0 · 추정 0). 원문 숫자는 사용자 수 · 주식 수 · 휴가 일수 · 기간뿐.
--   제외: 퇴직연금(retirement savings) · annual leave · 공휴일 합산 최소 30일 · parental/maternity 20주(법정분 · 회사분을
--     원문이 가르지 않음) · 주 52시간 · 육아휴직 사용 현황(법정) · 준정년 특별 퇴직금(판단 요청 — 기본 제외) ·
--     특별퇴직 일자리 지원(법정 재취업지원 성격) · 성과평가형 주식기준보상(재량 부여) · 임원 보수 칸 복리후생 비용 ·
--     in some locations 선택 복리후생 · 학습 문화 · 멘토링(업무 교육) · 한국스탠다드차타드증권(다른 법인) 공고.
--   공고 근거 4행 / 전체 8행.
--   SORT 섹션 순서 = 정본 페이지에 행이 없어 사업보고서에 처음 나온 순서, 공고에만 있는 카테고리는 끝
--     (compensation 10 · growth 20 · flexibility 30 · health 40 · time_off 50).
-- 검증 · 감사 판정 반영(2026-10-23): 주가차액보상권 출처를 별도 재무제표 주석으로 · 의료 생명보험 한 행을 생명보험 insurance 와 의료보험 medical 로 분리 · 재무제표 주석의 준정년 특별 퇴직금(법정퇴직금 이외에 추가로)을 severance_plus 로 추가 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록 제외 줄의 준정년 특별 퇴직금과 공고 근거 4행 / 전체 8행은 이 판정으로 뒤집힘(5행 / 10행) — 최종 10행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sc_bank', '한국스탠다드차타드은행(SC제일은행)',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '은행', 'S', 'https://www.standardchartered.co.kr/np/kr/cms/cm/bi/RecruitInfo.jsp?menuId=HT02040100000000');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sc_bank');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.standardchartered.co.kr/np/kr/cms/cm/bi/RecruitInfo.jsp?menuId=HT02040100000000'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 2025 사업보고서 · 2026 반기보고서 주석 ──
  (@comp_id, 'stock_option', '적금가입형 주가차액보상권', NULL, 'compensation',
   'est', NULL, TRUE, '재직 중인 임직원이 가입가능하며, 가입 후 매월 일정금액을 적금으로 만기까지 납부하는 적금가입형 주가차액보상권, 가득기간 3년, 최상위지배회사 Standard Chartered PLC 주식의 시가와 행사가격의 차액을 현금으로 지급하는 보상제도 (2025 사업보고서 · 2026 반기보고서 재무제표 주석 주식기준보상 항목) — 월 납입 한도·회사 부담분 미기재', 10),
  (@comp_id, 'severance_plus', '준정년 특별 퇴직금', NULL, 'compensation',
   'est', NULL, TRUE, '당행의 규정 상 준정년 퇴직대상자에 해당되어 준정년 퇴직을 신청한 경우 당행의 승인을 거쳐 법정퇴직금 이외에 추가로 준정년 특별 퇴직금 지급 (2025 사업보고서 · 2026 반기보고서 재무제표 주석 순확정급여부채 항목) — 준정년 퇴직 대상 기준·지급 금액 미기재', 11),

  -- ── 성장 · 교육 (growth) — 2025 사업보고서 종업원 등에 관한 사항 ──
  (@comp_id, 'retirement_support', '특별퇴직 직원 학자금·창업자금 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 감소로 경력 전환을 구상하고 있는 직원들에게 기회와 재정적 지원을 제공하기 위해 특별퇴직 실시, 퇴직직원에게 학자금 지원 및 창업자금지원 (2025 사업보고서 사업의 내용 종업원 등에 관한 사항 항목) — 지원 대상·지원 금액·지원 기간 미기재', 20),

  -- ── 근무 유연성 (flexibility) — 2025 사업보고서 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '자율출퇴근제도 (시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '직원 개인의 업무 특성에 맞춰 출퇴근 시간을 조절하여 업무의 효율성과 생산성 향상을 도모하고자 자율출퇴근제도 시행 (2025 사업보고서 사업의 내용 종업원 등에 관한 사항 항목), 시차출퇴근제 사용자 2023년 225명 · 2024년 180명 · 2025년 305명 · 2026년 상반기 302명 (2025 사업보고서 · 2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·적용 대상 미기재', 30),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 2023년 953명 · 2024년 797명 · 2025년 1,194명 · 2026년 상반기 1,000명 (2025 사업보고서 · 2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 31),

  -- ── 건강 (health) — 그룹 채용 공고 What we offer ──
  (@comp_id, 'insurance', '생명보험 지원', NULL, 'health',
   'est', NULL, TRUE, 'Core bank funding for life insurance, 은행 부담 생명보험 (Standard Chartered 채용 공고 What we offer 항목) — 보장 범위·가족 적용 여부 미기재 (그룹 통합 채용 기준)', 40),
  (@comp_id, 'mental', '웰빙 지원 (Unmind·근로자 지원 프로그램)', NULL, 'health',
   'est', NULL, TRUE, 'Proactive wellbeing support, 디지털 웰빙 플랫폼 Unmind, 회복탄력성 개발 과정, 글로벌 근로자 지원 프로그램(Employee Assistance Programme), 정신건강 응급요원(mental health first-aiders), 자가 관리 도구 (Standard Chartered 채용 공고 What we offer 항목) — 상담 횟수·이용 조건 미기재 (그룹 통합 채용 기준)', 41),
  (@comp_id, 'medical', '의료보험 지원', NULL, 'health',
   'est', NULL, TRUE, 'Core bank funding for medical insurance, 은행 부담 의료보험 (Standard Chartered 채용 공고 What we offer 항목) — 보장 범위·가족 적용 여부 미기재 (그룹 통합 채용 기준)', 42),

  -- ── 휴가 (time_off) — 그룹 채용 공고 What we offer ──
  (@comp_id, 'refresh_leave', '안식휴가 (Sabbatical)', NULL, 'time_off',
   'est', NULL, TRUE, 'Time-off 항목의 sabbatical (12 months maximum), 최대 12개월 안식휴가 (Standard Chartered 채용 공고 What we offer 항목) — 유급 여부·근속 요건 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'leave_general', '봉사휴가 3일 · 병가', NULL, 'time_off',
   'est', NULL, TRUE, 'Time-off 항목의 volunteering leave (3 days), 봉사휴가 3일, wellbeing support 항목의 sick leave, 병가 (Standard Chartered 채용 공고 What we offer 항목) — 유급 여부·사용 조건 미기재 (그룹 통합 채용 기준)', 51)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
