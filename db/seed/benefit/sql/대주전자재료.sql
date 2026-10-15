-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대주전자재료 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://daejoo.sustainability-report.kr/2025/ko/social/employees
-- badge: est
--
-- 참고:
--   정본은 대주전자재료(주)가 발행한 2025 지속가능경영보고서 웹판 Social > 임직원 장이다
--   (공식 홈 www.daejoo.co.kr 상단 메뉴 ESG > 지속가능경영 링크 · 보고 기간 2025-01-01~2025-12-31 ·
--   일부 성과 2026년 6월까지 · 보고 범위 국내 본사 및 배터리캠퍼스 · 문의처 대주전자재료 전략·ESG팀 · 쪽 번호 없는 웹판).
--   SSR 이라 본문 문단은 원본 HTML 에 있다. 복리후생 정책 표(6칸)와 복리후생 고도화 표 · 근로자 건강 증진 프로그램 표는
--   이미지 안에만 있어 내려받아 판독했다(1059~1085px 폭 · 판독 가능).
--   보조 출처: 같은 보고서 안전보건경영 장(금연 프로그램) · 인권경영 장(사내 동호회 활동) ·
--   자기 도메인 ESG > 사회 > 임직원 페이지(의료서비스 — 기혼자 배우자 종합검진) ·
--   자기 도메인 채용공고 게시판의 사업부별 수시채용 모집 공고(작성 2023-07-14 · 지금도 채용중 표시 · 더 새 공고 없음) 복리후생 블록 ·
--   OpenDART 2026 반기보고서(접수 20260814000559) 유연근무제도 사용 현황 · 임원 보수 산정기준 칸의 임직원 적용 문장.
--   귀속: 보고서 · 자기 도메인 모두 대주전자재료 단수 주어 · 법인 단독 발행 · 형제 코퍼스 0 — 각주 없음.
--   금액: 식대 1행만 추정(공고 조식 · 중식 · 석식 제공 3끼 × 1끼 12,000원 × 240일 = 864). 출산 장려금은 1회성이라 NULL.
--   제외: 법정(4대 보험 · 주 5일 근무 · 연차 · 퇴직금 · 퇴직연금 · 야근수당 · 휴일수당 · 일반 · 특수검진 · 소음작업 청력보존프로그램) ·
--     업무 교육(온보딩 · 리더십 · 안전 · 법정 의무 교육) · 스톡옵션 지급 · 근속수당(급여성) · 상여금 400%(근무방식 칸 임금 구성) ·
--     임원 한정 자녀 대학 학자금 전액 지원(복리후생 고도화 표 — 근거표 판단 요청) · 2021 제조직 채용 공고에만 있는 항목(옛 출처).
--   공고 근거 9행 / 전체 26행(공고만이 근거인 행 2 — 통근버스 · 근무복).
--   SORT 섹션 순서 = 정본 복리후생 정책 표 등장 순(leisure 10 · health 20 · perks 30 · family 40 · work_env 50 ·
--     flexibility 60 · compensation 70), 본문 교육 절 growth 80.
-- 검증 · 감사 판정 반영(2026-10-15): 외국어 교육 서술에 보고서 교육 대상별 교육 내용 표 이미지의 영어 · 일본어 · 중국어(꼬리의 교육 언어 미기재는 이 판정으로 뒤집힘) · 게시 중 채용공고 복리후생 휴일/휴가 칸의 정기 휴가 leave_general 추가(새 time_off 섹션) · 참고 블록의 공고 근거 9행 / 전체 26행은 10행 / 전체 27행 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daejoo_electronic', '대주전자재료',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전자부품', 'D', 'https://daejoo.sustainability-report.kr/2025/ko/social/employees');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daejoo_electronic');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://daejoo.sustainability-report.kr/2025/ko/social/employees'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 보고서 복리후생 정책 표 여가 및 문화 생활 · 근무 환경 칸 ──
  (@comp_id, 'resort', '제휴 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '제휴 콘도 지원 (2025 지속가능경영보고서 임직원 복리후생 정책 여가 및 문화 생활 항목) — 이용 횟수·지원 범위 미기재', 10),
  (@comp_id, 'club', '사내 동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 (2025 지속가능경영보고서 임직원 복리후생 정책 여가 및 문화 생활 항목), 사내 동호회 활동을 통해 임직원들 간의 유대감 강화 (같은 보고서 인권경영 사내 동호회 활동 항목) — 동호회 종류·지원 금액 미기재', 11),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지급 (2025 지속가능경영보고서 임직원 복리후생 정책 여가 및 문화 생활 항목) — 지급 시기·금액 미기재', 12),
  (@comp_id, 'company_event', '사내이벤트 진행', NULL, 'leisure',
   'est', NULL, TRUE, '사내이벤트 진행 (2025 지속가능경영보고서 임직원 복리후생 정책 근무 환경 항목) — 행사 종류·시기 미기재', 13),

  -- ── 건강 (health) — 보고서 복리후생 정책 표 건강 관리 칸 · 직장 의료 서비스 · 안전보건경영 장 ──
  (@comp_id, 'clinic', '한의사 방문진료·벌침진료', NULL, 'health',
   'est', NULL, TRUE, '벌침진료, 한의사 방문진료 (2025 지속가능경영보고서 임직원 복리후생 정책 건강 관리 항목), 임직원 건강관리를 위한 진료 (한의사 방문상담 및 물리치료) 연24회 (같은 보고서 직장 의료 서비스 근로자 건강 증진 프로그램 항목) — 진료 장소·비용 부담 미기재', 20),
  (@comp_id, 'health_check', '종합건강검진 (기혼자 배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 실시 (2025 지속가능경영보고서 임직원 복리후생 정책 건강 관리 항목), 기혼자에 대해서는 배우자까지 정기적으로 종합검진 (공식 홈페이지 ESG 임직원 의료서비스 항목) — 검진 주기·비용 지원 범위 미기재', 21),
  (@comp_id, 'medical', '협약 병원 진료비 감면', NULL, 'health',
   'est', NULL, TRUE, '협약 병원 진료비 감면 (2025 지속가능경영보고서 임직원 복리후생 정책 건강 관리 항목) — 협약 병원·감면 범위 미기재', 22),
  (@comp_id, 'smoking_cessation', '금연 프로그램', NULL, 'health',
   'est', NULL, TRUE, '흡연자들이 금연을 실천할 수 있도록 6개월간의 교육과 상담 제공, 금연 성공 시 건강용품 또는 격려금 지원 (2025 지속가능경영보고서 안전보건경영 안전보건 문화 확산 활동 항목) — 격려금 금액 미기재', 23),

  -- ── 생활 · 편의 (perks) — 보고서 복리후생 정책 표 가족 생활 지원 · 경조사 지원 · 근무 환경 칸 · 채용공고 ──
  (@comp_id, 'welfare_fund_loan', '사내 대여금', NULL, 'perks',
   'est', NULL, TRUE, '사내 대여금 (2025 지속가능경영보고서 임직원 복리후생 정책 가족 생활 지원 항목) — 대여 용도·한도·이율 미기재', 30),
  (@comp_id, 'birthday_gift', '결혼 기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '결혼 기념일 선물 (2025 지속가능경영보고서 임직원 복리후생 정책 경조사 지원 항목) — 선물 종류·금액 미기재', 31),
  (@comp_id, 'snack_bar', '카페테리아 운영', NULL, 'perks',
   'est', NULL, TRUE, '카페테리아 운영 (2025 지속가능경영보고서 임직원 복리후생 정책 근무 환경 항목) — 운영 사업장·이용 비용 미기재', 32),
  (@comp_id, 'meal', '사내 식당 조식·중식·석식 제공', 864, 'perks',
   'est', '사내 식당 운영 (2025 지속가능경영보고서 복리후생 정책 근무 환경 항목), 조식제공, 중식제공, 석식제공 (공식 채용공고 복리후생 항목) — 1끼 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 33),
  (@comp_id, 'commute_subsidy', '통근버스 운행', NULL, 'perks',
   'est', NULL, TRUE, '생활편의 지원 통근버스 운행 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 노선·운행 사업장 미기재', 34),

  -- ── 가족 (family) — 보고서 복리후생 정책 표 가족 생활 지원 · 경조사 지원 칸 · 출산 및 육아 지원 제도 ──
  (@comp_id, 'parenting', '출산 장려금 (첫째 300만원·둘째 500만원·셋째 1,000만원)', NULL, 'family',
   'est', NULL, TRUE, '2024년 1월 1일부터 시행되는 출산 지원금 정책은 모든 임직원을 대상으로 하며, 첫째 아이 출산 시 300만 원, 둘째 아이는 500만 원, 셋째 아이는 1,000만 원의 지원금 제공 (2025 지속가능경영보고서 임직원 출산 및 육아 지원 제도 항목), 출산 장려금 (같은 보고서 복리후생 정책 가족 생활 지원 항목)', 40),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (2025 지속가능경영보고서 임직원 복리후생 정책 가족 생활 지원 항목) — 지원 대상 학년·금액 미기재', 41),
  (@comp_id, 'event', '경조사비 지원·상조회·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '상조회 운영, 경조사비 지원 (2025 지속가능경영보고서 임직원 복리후생 정책 경조사 지원 항목), 각종 경조금, 경조휴가제 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 경조 금액·휴가 일수 미기재', 42),

  -- ── 근무 환경 (work_env) — 보고서 복리후생 정책 표 근무 환경 칸 · 채용공고 ──
  (@comp_id, 'lounge', '직원휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '직원휴게실 운영 (2025 지속가능경영보고서 임직원 복리후생 정책 근무 환경 항목), 사내 편의시설 휴게실 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 설치 사업장·시설 구성 미기재', 50),
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원 (2025 지속가능경영보고서 임직원 복리후생 정책 근무 환경 항목), 생활안정 지원 기숙사 운영 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 입주 자격·비용 부담 미기재', 51),
  (@comp_id, 'uniform', '근무복 지급', NULL, 'work_env',
   'est', NULL, TRUE, '생활편의 지원 근무복 지급 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 지급 주기·대상 미기재', 52),

  -- ── 근무 유연성 (flexibility) — 보고서 복리후생 정책 표 근무 환경 칸 · 유연 근무 제도 · 공시 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택근무제 운영 (2025 지속가능경영보고서 임직원 복리후생 정책 근무 환경 항목), 2021년 부터 임직원이 자율적으로 근무 시간을 조율하고 선택할 수 있는 유연근무제 운영 (같은 보고서 유연 근무 제도 항목), 선택근무제 사용자 수 185명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 의무 근무 시간대·정산 기간 미기재', 60),

  -- ── 보상 (compensation) — 보고서 복리후생 정책 표 포상 칸 · 복리후생 고도화 표 · 채용공고 · 공시 ──
  (@comp_id, 'incentive', '성과급 (사업부 실적·개인 성과 등급)', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급 (2025 지속가능경영보고서 임직원 복리후생 정책 포상 항목), 개인의 성과 등급에 따라 개인 성과금 차등지급 시행 (같은 보고서 복리후생 고도화 개인 성과금 지원 확대 항목), 성과급 사업부 실적 평가하여 사업부의 임직원과 동일 지급 (2026 반기보고서 보수 산정기준 항목) — 지급률 미기재', 70),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (2025 지속가능경영보고서 임직원 복리후생 정책 포상 항목), 보상제도 장기근속자 포상 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 근속 기준·포상 내용 미기재', 71),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (2025 지속가능경영보고서 임직원 복리후생 정책 포상 항목), 우수사원 표창/포상 (공식 채용공고 사업부별 수시채용 복리후생 항목) — 선정 기준·포상 내용 미기재', 72),
  (@comp_id, 'holiday_gift', '명절 귀향비·명절상여', NULL, 'compensation',
   'est', NULL, TRUE, '생활안정 지원 명절 귀향비 지급 (공식 채용공고 사업부별 수시채용 복리후생 항목), 명절상여 임직원과 동일한 기준으로 지급 (2026 반기보고서 보수 산정기준 항목) — 지급 금액·기준 미기재', 73),

  -- ── 성장 (growth) — 보고서 임직원 역량개발 교육 프로그램 절 ──
  (@comp_id, 'lang', '외국어 교육·사내 영어 그룹 스터디', NULL, 'growth',
   'est', NULL, TRUE, '희망하는 지원자에 한하여 외국어 교육 실시 (2025 지속가능경영보고서 임직원 교육 프로그램 항목), 전체 인원 대상 외국어 교육(영어, 일본어, 중국어) (같은 보고서 교육 대상별 교육 내용 표 항목), 사내 영어 그룹 스터디 매주 운영 (같은 보고서 사내 영어 그룹 스터디 항목) — 비용 지원 범위 미기재', 80),
  (@comp_id, 'edu_support', '사내 특강·온라인 학습 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '분야별 전문가를 초청하여 사내 특강 진행 (2025 지속가능경영보고서 임직원 대주전자재료 사내 특강 항목), 언제 어디서나 학습할 수 있도록 온라인 학습 프로그램 운영 (같은 보고서 온라인 학습 프로그램 운영 항목) — 과정 종류·비용 지원 미기재', 81),
  -- ── 휴가 (time_off) — 채용공고 ──
  (@comp_id, 'leave_general', '정기 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '정기 휴가 (공식 채용공고 사업부별 수시채용 복리후생 휴일/휴가 항목) — 연차 사용일인지·일수·유급 여부 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
