-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 기업은행 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://ibk.incruit.com/introduce/ibk_welfare.html
-- badge: est
--
-- 참고:
--   정본은 IBK기업은행 채용전용 홈페이지 ibk.incruit.com 헤더 메뉴 은행소개 → 복지제도(/introduce/ibk_welfare.html)다.
--   서버 렌더 HTML(EUC-KR)에 항목 7개(급여 · 주거안정지원 · 직원건강 증진 지원 · 휴양시설 제공 · 일·가정 양립 ·
--   자기개발 지원 · 기타)가 제목+한 줄 설명으로 있다. 귀속: 중소기업은행이 공공기관 경영정보 공시(ALIO)에 직접 올린
--   2026년 하반기 일반직원 수시채용 공고가 접수방법을 채용전용 홈페이지(http://ibk.incruit.com)로 밝히고, 그 사이트가
--   IBK기업은행 홈페이지로 링크한다.
--   법인 고유 근거(기관 자기 공시): ALIO 중소기업은행(apbaId C0127) 정기공시 2026년 1분기분(기준일 2025-12-31) —
--     13 복리후생비(항목별 복리후생비 · 지급기준 · 1인당 복리후생비), 14-1 그 밖의 복리후생제도 등의 운영현황(휴직급여 ·
--     휴가 운영기준 · 장기근속 휴가), 26 일·가정 양립 지원제도 및 양성평등 운영현황(유연근무 · 직장어린이집),
--     11 직원 평균보수(성과상여금 — incentive 근거).
--   robots: www.ibk.co.kr 은 전체 금지(Allow 1경로뿐)라 읽지 않았다 · ibk.incruit.com 은 /introduce/ 허용 ·
--     www.alio.go.kr 전체 허용. 단체협약 · 노사합의 공시와 보도는 쓰지 않았다.
--   금액: holiday_gift 40 은 창립기념품 20만원 + 근로자의 날 격려품 20만원 합산(회사 공식 수치).
--     구본 추정 승계 2(resort 50 · welfare_point 200 — 틀 값, (추정)). welfare_point 는 공시 지급기준이
--     사용액을 1인당 복지포인트 한도(2025년 220만원) 안에서 지원한다고 적어 한도 숫자를 금액 칸에 넣지 않았다.
--     구본 health_check 100 은 공시 건강진단비 1인당 30만원 이하와 어긋나 승계하지 않았다.
--   제외: 자녀 유치원비(공시상 2024년 제도 폐지) · 의료비(2021~2025 공시 지급 실적 없음) · 해외 주재직원 자녀 학자금
--     (주재원 한정) · 준정년 특별퇴직금 · 명령휴가 · 법정 휴가와 휴직. 임직원 신용대출(용도 미기재)은 2026-10-04 기준 13 폐기로 housing_loan 서술에 되살렸다.
--   재코딩: edu_support → self_development(학원수강료 등 자기개발 비용 지원).
--   SORT 섹션 순서 = 채용 사이트 복지제도 항목에서 카테고리가 처음 나온 순서, 공시에만 있는 카테고리는 끝
--     (work_env 10 · perks 20 · health 30 · leisure 40 · family 50 · growth 60 · compensation 70 · time_off 80 ·
--     flexibility 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): welfare_point 공시 한도 220 대신 틀 값 200 (추정) · ALIO 직원 평균보수 근거 incentive 행 추가 · 문안 2 — 최종 24행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 1(housing_loan) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ibk', '기업은행',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '은행', 'I', 'https://ibk.incruit.com/introduce/ibk_welfare.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ibk');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://ibk.incruit.com/introduce/ibk_welfare.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 채용 사이트 주거안정지원 / 공시 주택자금 ──
  (@comp_id, 'dormitory', '직원합숙소·사택·임차사택', NULL, 'work_env',
   'est', NULL, TRUE, '무주택자를 위한 임차주택 대여, 독신자 합숙소 운영 (채용전용 홈페이지 복지제도 주거안정지원 항목), 격지근무 직원의 숙식편의를 위한 직원합숙소 운영, 동일 시군구에 주택이 없고 근무지와 거리가 40km 이상인 부점장급 이상 직원 사택 운영, 근무지에 자택이 없는 부양가족 동반직원 임차사택 제공(연 611만8천원 한도) (공공기관 경영정보 공시 2025년 복리후생비 주택자금 항목) — 개인생활비 성격의 관리비는 입주직원 부담', 10),

  -- ── 경제적 부가혜택 (perks) — 채용 사이트 주거안정지원 · 기타 / 공시 주택자금 · 생활안정자금 · 선택적복지 · 직원기념일 ──
  (@comp_id, 'housing_loan', '주택자금·주택임차자금 대출·임직원 신용대출', NULL, 'perks',
   'est', NULL, TRUE, '임직원 신용대출 (채용전용 홈페이지 복지제도 주거안정지원 항목), 무주택 임직원의 주택 구입 대출(한도 5,000만원)과 주택임차자금 대출(한도 3,000만원), 금리는 한국은행 공표 은행가계자금대출금리 적용, 주택자금은 거치기간 포함 30년 이내·임차자금은 3년 이내 (공공기관 경영정보 공시 복리후생비 주택자금 지급기준) — 신용대출 한도·금리 미기재', 20),
  (@comp_id, 'welfare_fund_loan', '생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '임직원 생활안정자금 대출 한도 2,000만원, 금리는 한국은행 공표 은행가계자금대출금리 적용(2025년 최저 4.24%), 10년 상환 (공공기관 경영정보 공시 복리후생비 생활안정자금 항목)', 21),
  (@comp_id, 'welfare_point', '선택적 복지제도', 200, 'perks',
   'est', '직원이 지원항목에 맞게 사용한 금액을 1인당 복지포인트 한도(2025년 220만원) 내에서 지원, 직원 단체보험료 포함 (공공기관 경영정보 공시 복리후생비 · 채용전용 홈페이지 복지제도) — 1인당 배정액 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'birthday_gift', '직원기념일 카드', NULL, 'perks',
   'est', NULL, TRUE, '직원 기념일에 영화관람권 등 지급, 1인당 3만9,500원 상당 (공공기관 경영정보 공시 2025년 복리후생비 기타 항목)', 23),

  -- ── 건강·의료 (health) — 채용 사이트 직원건강 증진 지원 / 공시 건강진단비 · 예방접종 ──
  (@comp_id, 'health_check', '종합건강진단·직원가족건강진단·예방접종', NULL, 'health',
   'est', NULL, TRUE, '종합건강진단, 직원가족건강진단 (채용전용 홈페이지 복지제도 직원건강 증진 지원 항목), 매년 1회 건강검진(1인당 30만원 이하), 전염성 질환 예방을 위한 독감 접종(1인당 4만원 이내) (공공기관 경영정보 공시 2025년 복리후생비 항목) — 가족 검진 범위 미기재', 30),

  -- ── 여가·라이프 (leisure) — 채용 사이트 휴양시설 제공 / 공시 문화여가비 · 행사지원비 ──
  (@comp_id, 'resort', '휴양시설 (호텔·콘도 무료 이용)', 50, 'leisure',
   'est', '국내 호텔 및 콘도 무료이용 (채용전용 홈페이지 복지제도), 휴가철 임시휴양소 운영, 은행 콘도회원권 이용 시 연간 2박 범위 실비 지원 (공공기관 경영정보 공시) — 1인당 지원 한도(콘도 76만6천원 · 임시휴양소 70만1천원)만 기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '행내 동호회원의 체력증진, 친목도모를 위한 써클부 지원 (공공기관 경영정보 공시 복리후생비 문화여가비 지급기준) — 동호회별 지원 금액 미기재', 41),
  (@comp_id, 'company_event', '체육행사·직원화합행사·IBK한마음가족행사', NULL, 'leisure',
   'est', NULL, TRUE, '직원의 체력증진 및 화합을 위한 체육행사 상하반기 각 1회 행사비 지원, 전직원 일체감 조성을 위한 직원화합행사 행사비 지원, 직원·직원가족과 함께하는 IBK한마음가족행사 비용 지원, 직원의 소통과 화합을 위한 여가지원 행사 (공공기관 경영정보 공시 복리후생비 행사지원비 · 문화여가비 지급기준)', 42),

  -- ── 가족·돌봄 (family) — 채용 사이트 일·가정 양립 · 기타 / 공시 경조비 · 직장어린이집 · 기타 ──
  (@comp_id, 'parenting', '육아휴직 최대 3년·출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '금융권 최초 육아휴직 3년 (채용전용 홈페이지 복지제도 일·가정 양립 항목), 직원 자녀 출산 시 출산 축하금(1인당 최대 300만원), 입양 휴가 20일, 배우자 임신검진 동행휴가 10일 (공공기관 경영정보 공시 복리후생비 · 휴가 운영기준) — 육아휴직 기간은 무급', 50),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 13개소(은행이 직접 설치·인가 후 운영 위탁), 어린이집에 입소한 6세 미만 직원자녀 대상 (공공기관 경영정보 공시 2025년 일·가정 양립 지원제도 직장어린이집 운영 현황) — 개소별 위치·정원 미기재', 51),
  (@comp_id, 'event', '경조금·재해부조금·장례지원', NULL, 'family',
   'est', NULL, TRUE, '재해부조금 및 각종 경조금 지원 (채용전용 홈페이지 복지제도 기타 항목), 결혼·출산·회갑·칠순·팔순 축의금과 본인·배우자·부모 사망 조의금(건당 최대 100만원), 직원 상사 시 장례지원 전담반 운영과 장례용품·조화 지원, 본인 및 자녀 결혼 축하 화환, 소유주택 재해 시 재해부조, 경조사 휴가(본인 결혼 5일, 배우자·부모 사망 5일, 조부모·형제자매 사망 3일 등) (공공기관 경영정보 공시)', 52),
  (@comp_id, 'fertility_support', '난임 치료 출산장려금', NULL, 'family',
   'est', NULL, TRUE, '난임진단을 받아 치료(시술)한 직원에게 출산장려금 지원, 연간 최대 600만원 (공공기관 경영정보 공시 2025년 복리후생비 기타 항목)', 53),
  (@comp_id, 'disability_family_support', '장애인보조비', NULL, 'family',
   'est', NULL, TRUE, '장애인으로 등록된 직원 및 장애자녀를 둔 직원에 대한 생활 원조 지원, 장애자녀 월 최대 50만원·장애 직원 본인 월 최대 20만원 (공공기관 경영정보 공시 2025년 복리후생비 기타 항목)', 54),
  (@comp_id, 'child_edu', '대학생 자녀 학자금 무상 융자', NULL, 'family',
   'est', NULL, TRUE, '직원의 대학생 자녀 등록금(입학금·수업료·학생회비 등) 100%를 사내근로복지기금에서 무상 융자하고, 직원 급여에서 매월 갹출한 회비로 운영하는 기은장학상조회가 5년 만기 일시상환 (공공기관 경영정보 공시 복리후생비 학자금 항목)', 55),

  -- ── 성장·교육 (growth) — 채용 사이트 자기개발 지원 / 공시 유학 휴직 ──
  (@comp_id, 'self_development', '자기개발 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '학원수강료 등 자기개발 비용 지원 (채용전용 홈페이지 복지제도 자기개발 지원 항목) — 지원 한도·대상 과정 미기재', 60),
  (@comp_id, 'mba', '유학 휴직', NULL, 'growth',
   'est', NULL, TRUE, '유학 휴직 중 월기준급여의 50% 지급, 최대 2년 (공공기관 경영정보 공시 그 밖의 복리후생제도 운영현황 휴직급여 지급기준) — 대상 과정·선발 기준 미기재', 61),

  -- ── 보상·금전 (compensation) — 공시 기념품비 · 포상품비 · 우리사주 ──
  (@comp_id, 'holiday_gift', '창립기념품·근로자의 날 격려품', 40, 'compensation',
   'est', '창립기념품 1인당 20만원, 근로자의 날 격려품 1인당 20만원, 온누리상품권 또는 중소기업제품으로 지급 (공공기관 경영정보 공시 2025년 복리후생비 기념품비 항목)', FALSE, NULL, 70),
  (@comp_id, 'excellence_award', '실적 우수직원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '영업 및 마케팅 실적 우수직원에 대한 포상, 캠페인 및 실적우수자 등 해당 건별 포상 (공공기관 경영정보 공시 복리후생비 기타 항목) — 포상 금액은 캠페인마다 상이', 71),
  (@comp_id, 'stock_option', '우리사주', NULL, 'compensation',
   'est', NULL, TRUE, '조합원의 사기진작과 노사협력 증진을 위한 사주 지급, 연간 최대 50만원 (공공기관 경영정보 공시 2025년 복리후생비 기타 항목) — 조합 가입 조건 미기재', 72),
  (@comp_id, 'incentive', '성과상여금', NULL, 'compensation',
   'est', NULL, TRUE, '업적·성과에 따라 차등 지급하는 성과상여금, 정규직과 무기계약직 직원 보수 항목 (공공기관 경영정보 공시 2026년 1분기 직원 평균보수 항목) — 지급 기준·지급률 미기재', 73),

  -- ── 시간·휴가 (time_off) — 공시 장기근속 휴가 · 휴가 운영기준 · 휴직급여 ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이상 근무자 5일, 20년 이상 근무자 7일 (공공기관 경영정보 공시 그 밖의 복리후생제도 운영현황 장기근속 휴가 운영기준) — 부여 주기 미기재', 80),
  (@comp_id, 'leave_general', '인병휴가·질병 휴직 급여·포상 휴가 등', NULL, 'time_off',
   'est', NULL, TRUE, '비업무상 질병·부상 인병휴가 연간 60일 이내, 업무외 질병 휴직 시 1년 이내 월기준급여의 70%·1년 초과 2년 이내 50% 지급, 포상 휴가 10일, 심리안정휴가 4일, 재해구호휴가 5일 (공공기관 경영정보 공시 그 밖의 복리후생제도 운영현황 휴가 운영기준 · 휴직급여 지급기준) — 인병휴가 유급 여부 미기재', 81),

  -- ── 근무 유연성 (flexibility) — 공시 유연근무 현황 ──
  (@comp_id, 'flex_work', '탄력근무제 (시차출퇴근형)', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력근무제 시차출퇴근형 운영, 2025년 사용 인원 남 1,225명·여 1,694명 (공공기관 경영정보 공시 일·가정 양립 지원제도 유연근무 현황) — 선택 가능한 출퇴근 시간대 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
