-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코리아세븐(세븐일레븐) 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.7-eleven.co.kr/about/recruit/walfare.asp
-- badge: est
--
-- 참고:
--   정본은 비상장 법인 (주)코리아세븐(종목코드 없음 · 최대주주 롯데지주 92.47%)의 자기 도메인 www.7-eleven.co.kr
--   채용안내 > 인사제도 > 복리후생 탭이다. SSR 이라 원본 HTML 에 복리후생 지원 프로그램 7블록이 다 있다.
--   같은 인사제도의 인재육성 탭(development.asp)의 자기계발 지원 프로그램 블록을 보조로 쓴다. 헤드리스 렌더 없음.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814003290) · 2025 사업보고서(접수 20260331003768)
--   직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제). 직원 1,805명(2025 말).
--   귀속: 페이지 주어는 브랜드 세븐일레븐이지만 도메인 개인정보처리방침 주체가 (주)코리아세븐, 꼬리말 KOREA SEVEN CO, LTD,
--   채용문의 FAQ 가 롯데그룹 인턴 (주)코리아세븐 채용 인원을 말하고, 롯데그룹 채용 사이트 계열사 목록이
--   코리아세븐을 이 도메인으로 잇는다. 그룹 주어 · 계열사별 상이 단서 없음 — 각주 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL(학자금 100% 는 비율).
--   제외: 법정(퇴직연금 · 육아휴직 · 육아기 단축 · 배우자 출산휴가 공시 숫자) · 업무 교육(학점이수제 ·
--     직무자격인증제 · 사내강사 양성제 · 신입사원 Restart · 승진자 교육 · 온라인 과정 중 핵심가치 · 리더십 ·
--     산업군별 특화 · 육아휴직 과정 교육 · 핵심인재 해외견학) · 공시 선택근무제 · 원격근무제(세 기간 모두 -) ·
--     가맹점 경영주 복지(법인 직원 아님) · 롯데그룹 채용 사이트 직원 인터뷰.
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(family 10 · perks 20 · compensation 30 · health 40 · work_env 50 ·
--     leisure 60), 인재육성 탭 growth 70, 공시 flexibility 80.
-- 검증 · 감사 판정 반영(2026-10-22): 명절 선물 이름에서 원문 밖 낱말 연을 걷어 명절 선물 (2회)로 · 발행일 없는 정본은 지금 메뉴 · 사이트맵의 현행 페이지라 유효 · 영업 FC FD 대출은 welfare_fund_loan 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('korea_seven', '코리아세븐(세븐일레븐)',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', '7', 'https://www.7-eleven.co.kr/about/recruit/walfare.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korea_seven');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.7-eleven.co.kr/about/recruit/walfare.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '전 임직원의 유치원, 초, 중, 고, 대학생 자녀의 학자금을 자녀 수에 제한 없이 100% 지원 (공식 채용안내 페이지 복리후생 학자금 지원 항목) — 지원 학비 범위·지급 방식 미기재', 10),
  (@comp_id, 'event', '경조금 지원 · 상조회 운영', NULL, 'family',
   'est', NULL, TRUE, '결혼, 자녀출산, 부모님 회갑, 칠순, 입원치료, 가족 사망 등 경조사 일에 경조금, 휴가, 화환, 상조용품 지급 (공식 채용안내 페이지 복리후생 경조금 지원 항목), 결혼, 자녀 돌, 자녀 입학회갑, 부모님 회갑, 결혼 10주년, 가족 사망 등 경조사일에 상조회비 지원 (공식 채용안내 페이지 복리후생 상조회 운영 항목) — 경조 유형별 금액·휴가 일수 미기재', 11),
  (@comp_id, 'parenting', '자녀 입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '전 임직원에게 자녀 입학을 축하하며 선물 지급 (공식 채용안내 페이지 복리후생 선물지급 항목) — 선물 품목·금액 미기재', 12),

  -- ── 생활 · 금융 · 주거 (perks) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '전 임직원에게 본인 생일을 축하하며 선물 지급 (공식 채용안내 페이지 복리후생 선물지급 항목) — 선물 품목·금액 미기재', 20),
  (@comp_id, 'welfare_fund_loan', '영업 FC·FD 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '영업 FC, FD 대출지원 (공식 채용안내 페이지 복리후생 차량 및 사택 지원 항목) — 대출 용도·한도·이율 미기재', 21),
  (@comp_id, 'housing_support', '전세 보조금', NULL, 'perks',
   'est', NULL, TRUE, '전세 보조금 지원 (공식 채용안내 페이지 복리후생 차량 및 사택 지원 항목) — 지원 대상·금액 미기재', 22),
  (@comp_id, 'relocation', '부임여비 지원', NULL, 'perks',
   'est', NULL, TRUE, '부임여비 지원 (공식 채용안내 페이지 복리후생 차량 및 사택 지원 항목) — 지원 대상·금액 미기재', 23),

  -- ── 보상 (compensation) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'holiday_gift', '명절 선물 (2회)', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원에게 명절(2회)을 축하하며 선물 지급 (공식 채용안내 페이지 복리후생 선물지급 항목) — 선물 품목·금액 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속 포상 (창립기념일)', NULL, 'compensation',
   'est', NULL, TRUE, '근속년수에 따라 창립기념일에 포상 (공식 채용안내 페이지 복리후생 기타복리 항목) — 근속 기준·포상 내용 미기재', 31),
  (@comp_id, 'excellence_award', '성과 포상 (창립기념일)', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 따라 창립기념일에 포상 (공식 채용안내 페이지 복리후생 기타복리 항목) — 포상 기준·포상 내용 미기재', 32),

  -- ── 건강 (health) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'health_check', '건강검진 (간부사원 이상)', NULL, 'health',
   'est', NULL, TRUE, '간부사원 이상 건강검진 지원 (공식 채용안내 페이지 복리후생 의료지원 항목) — 검진 주기·비용 지원 범위 미기재', 40),
  (@comp_id, 'insurance', '단체보험 (상해)', NULL, 'health',
   'est', NULL, TRUE, '전 직원 단체보험 (상해) 지원 (공식 채용안내 페이지 복리후생 의료지원 항목) — 보장 범위·가족 포함 여부 미기재', 41),

  -- ── 근무 환경 (work_env) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'dormitory', '사택 임대', NULL, 'work_env',
   'est', NULL, TRUE, '사택임대 지원 (공식 채용안내 페이지 복리후생 차량 및 사택 지원 항목) — 지원 대상·사택 위치 미기재', 50),

  -- ── 여가 (leisure) — 공식 채용안내 복리후생 탭 ──
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '전 임직원에게 하계 휴가비 지급 (공식 채용안내 페이지 복리후생 기타복리 항목) — 금액·지급 시기 미기재', 60),
  (@comp_id, 'resort', '직원용 콘도 이용', NULL, 'leisure',
   'est', NULL, TRUE, '직원용 콘도이용 지원 (공식 채용안내 페이지 복리후생 기타복리 항목) — 이용 횟수·지원 범위 미기재', 61),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원 (공식 채용안내 페이지 복리후생 기타복리 항목) — 지원 금액·동호회 종류 미기재', 62),

  -- ── 성장 · 교육 (growth) — 공식 채용안내 인재육성 탭 ──
  (@comp_id, 'edu_support', '온라인 학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '독서교육 등 자기주도 학습을 위한 온라인 학습 지원, 총 1,100개 과정 운영 (공식 채용안내 페이지 인재육성 온라인 학습지원 항목) — 수강 대상·비용 지원 범위 미기재', 70),
  (@comp_id, 'self_development', '정보화 자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '정보화 자격대비 교육 과정 운영 및 자격 취득 지원 (공식 채용안내 페이지 인재육성 정보화 자격대비 교육 항목) — 대상 자격 종류·비용 지원 범위 미기재', 71),
  (@comp_id, 'lang', '어학비 지원', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 우수 인재지원을 위한 어학비 지원 시스템 운영 (공식 채용안내 페이지 인재육성 어학비 지원 항목) — 지원 대상·금액 미기재', 72),
  (@comp_id, 'mba', 'MBA 지원 (핵심인재 육성)', NULL, 'growth',
   'est', NULL, TRUE, '고성과 직원의 역량향상 과정 운영과 지원을 통한 핵심인재 육성 중 MBA 지원 (공식 채용안내 페이지 인재육성 핵심인재 육성 항목) — 선발 기준·지원 범위 미기재', 73),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 2025 사업보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 사용자 수 2026년 6월 30일 기준 85명, 2025년 말 99명, 2024년 말 54명 (2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
