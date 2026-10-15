-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코스메카코리아 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.cosmecca.com/ko/recruit
-- badge: est
--
-- 참고:
--   정본: 자기 도메인 www.cosmecca.com 인재채용 페이지(인재경영 메뉴). SSR — 원본 HTML 에 항목 텍스트가 있다.
--     블록 순서 = 인재육성 · 성과보상제도 · 복리후생 · 모성보호제도. 항목은 이름만 있는 아이콘 목록.
--   보조: 2026 반기보고서(접수 20260814003595) 직원 등 현황 유연근무제도 사용현황 표 주석 — flex_work 1행.
--   귀속: 주어 · 꼬리말이 모두 주식회사 코스메카코리아. 자회사 잉글우드랩 문장 없음. 기등록 형제 0 — 각주 없음.
--   금액: 금액 행 0(전 행 정성). 숫자가 적힌 항목이 없다.
--   제외: 법정(4대보험 · 산전후휴가 · 배우자출산휴가 · 육아휴직 · 육아기 단축근무 · 임신기 단축근무와 근로시간변경 ·
--     태아검진 유급휴가 = 근로기준법 74조의2 임산부 정기건강진단 시간) · 업무 교육(인재육성 4과정) ·
--     임원 보수 산정 칸 문장(공시 상여 · 기타 근로소득 칸).
--   공고 근거 0행 / 전체 16행.
--   SORT 섹션 순서: compensation 10 · perks 20 · leisure 30 · family 40 · health 50 · work_env 60 · time_off 70 ·
--     flexibility 80(공시에만 있는 카테고리 — 끝).
-- 검증 · 감사 판정 반영(2026-10-14): 상급학교 학비 지원을 child_edu 에서 self_development 로 재코딩(리드 판정 122 · growth SORT 90) — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cosmecca_korea', '코스메카코리아',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품', 'C', 'https://www.cosmecca.com/ko/recruit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cosmecca_korea');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.cosmecca.com/ko/recruit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 공식 채용 페이지 성과보상제도 · 복리후생 ──
  (@comp_id, 'incentive', '개별성과 인센티브제', NULL, 'compensation',
   'est', NULL, TRUE, '개별성과 인센티브제 실시 (공식 채용 페이지 성과보상제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', '불량적발·제안제도·분임조 포상·우수사원 해외연수', NULL, 'compensation',
   'est', NULL, TRUE, '클레임 제로화를 위한 불량적발 포상, 제안제도 운영 및 포상, 분임조 운영 및 포상, 우수사원 해외연수제도 (공식 채용 페이지 성과보상제도 항목) — 포상 기준·포상 내용·연수 기간 미기재', 11),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 채용 페이지 복리후생 항목) — 근속 기준·포상 내용 미기재', 12),
  -- ── 생활 지원 (perks) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'commute_subsidy', '통근버스 운행 (공장)', NULL, 'perks',
   'est', NULL, TRUE, '공장 통근버스 운행 (공식 채용 페이지 복리후생 항목) — 노선·운행 시간 미기재', 20),
  (@comp_id, 'birthday_gift', '생일·결혼기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '직원 생일 및 결혼기념일 선물 (공식 채용 페이지 복리후생 항목) — 선물 내용·금액 미기재', 21),
  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'resort', '콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 지원 (공식 채용 페이지 복리후생 항목) — 이용 조건·지원 범위 미기재', 30),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 채용 페이지 복리후생 항목) — 지원 금액·운영 동호회 미기재', 31),
  (@comp_id, 'welcome_kit', '신입사원 Welcome-kit', NULL, 'leisure',
   'est', NULL, TRUE, '신입사원 Welcome-kit (공식 채용 페이지 복리후생 항목) — 구성품 미기재', 32),
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 · 모성보호제도 ──
  (@comp_id, 'event', '경조휴가·경조사금', NULL, 'family',
   'est', NULL, TRUE, '각종 경조휴가 및 경조사금 제공 (공식 채용 페이지 복리후생 항목) — 경조 범위·금액·휴가 일수 미기재', 40),
  (@comp_id, 'parenting', '출산장려금', NULL, 'family',
   'est', NULL, TRUE, '출산장려금 지원 (공식 채용 페이지 출산장려금 항목) — 지급 금액·조건 미기재', 42),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'smoking_cessation', '금연 수당', NULL, 'health',
   'est', NULL, TRUE, '금연 수당 지급 (공식 채용 페이지 복리후생 항목) — 지급 금액·조건 미기재', 50),
  (@comp_id, 'health_check', '종합검진·건강검진비·독감예방 접종비 지원', NULL, 'health',
   'est', NULL, TRUE, '종합검진 실시, 건강검진비, 독감예방 접종비 지원 (공식 채용 페이지 복리후생 항목) — 검진 주기·대상·지원 금액 미기재', 51),
  -- ── 근무 환경 (work_env) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'dormitory', '기숙사 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '공장 기숙사 제공 (공식 채용 페이지 복리후생 항목) — 입주 대상·비용 미기재', 60),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'leave_general', '우수사원 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '우수사원 포상휴가 (공식 채용 페이지 복리후생 항목) — 휴가 일수·선정 기준 미기재', 70),
  -- ── 유연 근무 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제(시차출퇴근제) 시행 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 출퇴근 시간대·대상 미기재', 80),
  -- ── 성장 (growth) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'self_development', '상급학교 학비 지원', NULL, 'growth',
   'est', NULL, TRUE, '상급학교 학비 지원 (공식 채용 페이지 복리후생 항목) — 지원 대상·학교 범위·금액 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
