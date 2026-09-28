-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 기아 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://worldwide.kia.com/ko/company/sustainability/social/people-and-culture
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 기아 글로벌 브랜드 사이트 지속가능경영 Social 조직문화/인재경영 페이지(worldwide.kia.com, 법인 자기 도메인).
--     서버 응답 HTML 에 복리후생 절(휴가 · 건강지원 제도 · 가정생활 균형)이 그대로 있다 — 헤드리스 불필요.
--     robots.txt = User-agent: * / Allow: / (2026-09-28 확인). 본문 sha256 1788b1c5…1b548.
--   보조 1 = Kia Sustainability Report 2026 국문 PDF p.66 · 72 · 73 · 74 · 75 · 81 (같은 도메인 /files/ 경로, sha256 95b8193c…cdf7).
--     복리후생 제도 · 지원제도 표 · 주거지원 · 단체상해보험 · 우리사주조합 · 학위 및 자격증 취득 지원 · 임직원 건강관리 활동은 여기에만 있다.
--   보조 2 = 기아 탤런트 라운지 career.kia.com 가족친화인증(supprt/family.kc) · 일생활 균형 우수기업(supprt/excellentCompany.kc) · Career(life/career.kc).
--     robots.txt = Allow: / 에 개별 Disallow 목록 — 세 경로는 허용. 서버 렌더 HTML.
--   현대자동차그룹 계열이나 출처가 전부 기아 법인 자기 문서라 그룹 통합 각주 없음. 현대자동차 행은 섞지 않았다.
--   법정 제도 제외: 출산 전후 휴가 · 배우자 출산휴가 · 임신기 단축 · 육아기 단축 · 가족돌봄휴직 · 난임휴가 연 6일 · 수유시간 · 일반검진 연 1회 · 퇴직금 ·
--     미래설계 과정(퇴직 예정자 교육 — 1,000인 이상 사업주 재취업지원서비스)은 행이 아니다. 육아휴직은 회사 상회분(최대 2년 · 한부모 만 12세)만.
--   금액: 원문 명시 금액 0건. 구본 추정치 3행(insurance 30 · child_edu 200 · resort 50)은 구본이 다른 법인 데이터라 승계하지 않는다(R6 ②, 리드 판정).
--     구본의 회사 공식 수치 3행(health_check 60 · welfare_point 200 · meal 312)은 원문에 숫자가 없어 승계하지 않았다.
--   구본 12행 중 원문 근거 없는 4행(welfare_point · meal · snack_bar · transport) 삭제 · 8개 코드 유지 · 기존 어휘 코드 20개 추가 · 재코딩 0 · 신규 코드 0.
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): family_day 삭제(정시퇴근은 조기퇴근이 아님) · 정년퇴직 위로 휴가를 retirement_support 로 분리 · incentive 정성 행 추가(보고서 p.72 차등 인센티브) · self_development 서술에서 60세 이상 자격증 문구 제거 — 최종 29행
-- 리드 판정(2026-09-28, 독립 검토 MED-2): 구본 추정치 3행(resort 50 · insurance 30 · child_edu 200)은 구본이 다른 법인 데이터라 R6 ② 로 승계하지 않는다 — 금액을 비우고 정성 행으로 둔다

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kia', '기아',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차', 'K', 'https://worldwide.kia.com/ko/company/sustainability/social/people-and-culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kia');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://worldwide.kia.com/ko/company/sustainability/social/people-and-culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ── 보고서 p.74 근무제도 · 가족친화인증 · 일생활 균형 우수기업
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 평균 주 52시간 내 자율 근무가 가능한 유연근무제, 시차출퇴근제와 선택근로제 운영', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무제 운영 — 재택근무 활용 가능', 11),
  (@comp_id, 'satellite_office', '거점근무', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스 활용 가능한 거점근무 운영', 12),

  -- ── 시간·휴가 (time_off) ── 조직문화/인재경영 페이지 복리후생 휴가 · 보고서 p.74 휴가
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '전 직원 연 5일 유급 하계휴가 추가 제공', 20),
  (@comp_id, 'leave_general', '프로드림 휴가·유급 보건휴가', NULL, 'time_off',
   'est', NULL, TRUE, '관리자급 승진 인원(선임관리자 승진 직원) 유급휴가 10일 추가 제공(프로드림 휴가), 여직원 유급 보건휴가 부여', 21),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속 20년 직원 유급휴가 5일 제공', 22),

  -- ── 여가·라이프 (leisure) ── 보고서 p.74 · 일생활 균형 우수기업 · 가족친화인증
  (@comp_id, 'summer_vacation_subsidy', '3주 휴가 독려 여가포인트', NULL, 'leisure',
   'est', NULL, TRUE, '3주 휴가 사용 독려 제도 — 휴가 5일 사용 시 여가포인트 제공, 포인트 금액 미기재', 30),
  (@comp_id, 'resort', '사계절 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '8개 호텔 및 리조트 회원가 숙박 혜택을 주는 사계절 휴양소 운영, 가족 휴양시설 제공', 31),
  (@comp_id, 'company_event', '가족초청행사·가족캠프', NULL, 'leisure',
   'est', NULL, TRUE, '가족초청행사와 가족캠프 등 가족참여 프로그램 운영', 32),

  -- ── 건강·의료 (health) ── 조직문화/인재경영 페이지 건강지원 제도 · 보고서 p.66 · 74 · 81
  (@comp_id, 'health_check', '종합검진', NULL, 'health',
   'est', NULL, TRUE, '근속 10년 또는 만 35세 이상 직원 3년 주기 종합검진(가족 1인 검진비 50% 지원), 만 40세 이상 직원 갑상선·혈액암 등 추가 검진, 예방접종 지원', 40),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '직군 불문 전 임직원 대상 단체상해보험 — 상해입원일당, 상해사망, 질병사망, 암 진단, 유사암 진단, 상해후유장애 등 보장', 41),
  (@comp_id, 'fitness', '피트니스·스포츠센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터와 스포츠센터(수영장, 헬스장, GX장) 운영, 본사 피트니스 시설은 평일과 주말 별도 신청 없이 가족과 함께 이용 가능', 42),
  (@comp_id, 'clinic', '사내 의료시설·산업보건센터', NULL, 'health',
   'est', NULL, TRUE, '근무 중 진료와 처방이 가능한 사내 의료시설 및 약국, 산업보건센터(양/한방 진료실, 운동치료실, 물리치료실, 심리상담실, 엑스레이실) 운영, 본사 헬스체크룸과 전문 상담가 맞춤형 건강 가이드, 사내의원 금연치료(의사상담, 금연치료의약품 지급)', 43),
  (@comp_id, 'mental', '심리상담센터(EAP)', NULL, 'health',
   'est', NULL, TRUE, '온/오프라인 심리상담센터 운영, EAP 프로그램으로 직원 및 가족 대상 1:1 심리 상담 지원, 전문 상담사 1:1 상담과 심리검사 무상 제공', 44),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 복리후생 제공 — 지원 대상·한도 미기재', 45),

  -- ── 가족·돌봄 (family) ── 보고서 p.74 · 가족친화인증 · 일생활 균형 우수기업
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '계약직 및 시간제 직원을 포함한 전 임직원 경조휴가, 출생 경조금 지급 — 경조금 금액 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 — 지원 범위·한도 미기재', 51),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 1인당 육아휴직 최대 2년(한부모 가정은 만 12세 자녀까지 대상), 보육수당 지급, 임산부 지원 프로그램 운영', 52),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '본사 및 사업장 등 총 5개 직장 어린이집 운영', 53),

  -- ── 근무환경 (work_env) ── 보고서 p.74 · 가족친화인증
  (@comp_id, 'dormitory', '기숙사/사택', NULL, 'work_env',
   'est', NULL, TRUE, '계약직 및 시간제 직원을 포함한 전 임직원 대상 기숙사/사택 지원', 60),
  (@comp_id, 'nap_room', '수유시설·산모휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '수유시설 및 산모휴게실 운영', 61),

  -- ── 경제적 부가혜택 (perks) ── 보고서 p.74 주거지원
  (@comp_id, 'housing_loan', '주택 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금을 통한 전세 대출과 주택 구입 대출(연 1% 이자율), 근속 만 2년 이상·무주택 기간 만 1년 이상 직원 대상 — 신규 대출자·근속년수·신혼부부 등 우선순위 적용', 70),

  -- ── 성장·커리어 (growth) ── 보고서 p.73 · Career 페이지
  (@comp_id, 'self_development', '사외교육·자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '정규직 직원 대상 직무 특성을 고려한 사외교육 수강과 자격증 취득 본부별 지원 — 지게차기능사, 소방안전관리자, 전기·용접기능사, 자동차 진단평가사 등', 80),
  (@comp_id, 'mba', '석사휴직 제도', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 전일제 석사학위 취득을 위해 진학하는 근속 3년 이상 일반·연구직 직원에게 최대 2년 휴직 기회 제공', 81),
  (@comp_id, 'career', 'Career Move', NULL, 'growth',
   'est', NULL, TRUE, '경력개발 플랫폼 Career Move로 사내 Job Posting을 통한 타 본부 이동(OJM), 사내FA, 사내인턴(OXM) 운영, 글로벌 구성원 간 업무교류 프로그램 Global OXM', 82),
  (@comp_id, 'retirement_support', '정년퇴직 위로 휴가', NULL, 'growth',
   'est', NULL, TRUE, '근속 20년 이상 정년퇴직자 유급휴가 30일 제공', 83),

  -- ── 보상·금전 (compensation) ── 보고서 p.72 · 75
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원(정규직) 대상 가입 가능한 우리사주조합 운영', 90),
  (@comp_id, 'profit_sharing', '성과금', NULL, 'compensation',
   'est', NULL, TRUE, '노사 합의를 통해 경영활동 초과 이익을 성과금으로 직원들에게 배분 — 지급률·금액 미기재', 91),
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 따른 차등 인센티브 제도를 계약직을 포함한 전 임직원에게 적용 — 지급 기준·지급 수준 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
