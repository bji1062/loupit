-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 해성디에스 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.haesungds.com/recruit/system.php
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 RECRUIT 인사제도 페이지(SSR) 임금제도 · 복리후생 4묶음 · 교육제도 · 교육체계 그림(SVG 판독).
--   보조 = 자기 도메인 IR HDS스토리 「해성디에스와 ESG」(2026.06.26 게시) 건강관리 프로그램 문장 ·
--          SUSTAINABILITY 안전경영 페이지 보건증진활동 · 2026 반기보고서(2026.08.14 접수) 유연근무제도 사용 현황.
--   귀속 = 법인 자기 도메인 · 법인 주어 문장만 — 각주 없음. 해성그룹 형제(한국제지 · 계양전기 · 한국팩키지 · 해성산업)는 코퍼스에 없음.
--   금액 = 금액 행 0(원문에 연 금액 없음 · 사내식당은 끼니 미기재라 NULL).
--   제외 = 업무성과급(차년도 연봉 반영) · 핵심가치 · 인권윤리 · Compliance · 직무 · 리더십 · 입문 교육 · 온보딩 멘토링 ·
--          재취업지원 서비스 교육(직원 1,382명 · 법정) · 임신기 휴직(법정 육아휴직과 구분 미기재) · 사내 은행 · 편의점(시설 이름) ·
--          소주 법인 행사(다른 법인) · 2024 보도자료의 절주 · 저염식단 문장.
--   공고 근거 0행 / 전체 31행 · SORT 섹션 = compensation · health · perks · family · leisure · work_env · time_off · flexibility · growth
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('haesung_ds', '해성디에스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체기판', 'H', 'https://www.haesungds.com/recruit/system.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'haesung_ds');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.haesungds.com/recruit/system.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 정본 임금제도 ──
  (@comp_id, 'incentive', '목표인센티브(TAI)', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과를 공유하는 인센티브 시스템의 하나로, 경영, 인적자원, 설비, 기술 등의 효율적 운영 결과로 발생된 잉여가치 중 일부를 종업원의 업무효율 증대에 대한 보상으로 지급하는 별도의 성과급 제도 (공식 채용 페이지 인사제도 임금제도 목표인센티브 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'profit_sharing', '이익배분제(PS)', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과를 공유하는 인센티브 시스템의 하나로, 경영성과가 좋을 경우 초과 수익의 일부분을 임직원에게 배분하는 제도 (공식 채용 페이지 인사제도 임금제도 이익배분제 항목) — 지급 기준·배분율 미기재', 11),

  -- ── 건강 (health) — 정본 복리후생 Healthcare · Family, HDS스토리 · 안전경영 페이지 ──
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)·예방 접종', NULL, 'health',
   'est', NULL, TRUE, '매년 종합건강검진 지원, 본인 및 배우자 (공식 채용 페이지 인사제도 복리후생 건강검진 항목), 예방 접종 지원 (공식 홈페이지 HDS스토리 해성디에스와 ESG 게시글 항목) — 검진 항목·지원 한도 미기재', 20),
  (@comp_id, 'medical', '실손보험 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족의 건강과 의료비로 인한 경제적 부담을 덜기 위한 실손의료비 지원, 본인·배우자·자녀 (공식 채용 페이지 인사제도 복리후생 실손보험 항목) — 보장 한도·회사 부담 범위 미기재', 21),
  (@comp_id, 'mental', '심리상담서비스', NULL, 'health',
   'est', NULL, TRUE, '전문심리상담사가 상주하는 사외 심리상담센터 운영 (공식 채용 페이지 인사제도 복리후생 심리상담서비스 항목) — 이용 횟수·비용 지원 범위 미기재', 22),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '근무 중 갑작스러운 통증 및 질병의 예방·치료를 위한 사내 의료진 상주, 건강증진실과 물리치료실 운영 (공식 채용 페이지 인사제도 복리후생 건강관리실 항목), 임직원 건강관리 프로그램으로 비만 관리 서비스·건강 상담 운영 (공식 홈페이지 HDS스토리 해성디에스와 ESG 게시글 항목) — 운영 시간·의료진 구성 미기재', 23),
  (@comp_id, 'fitness', '체육시설', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강증진을 위한 사내 헬스장, 풋살장, 테니스장, 탁구장 등 운영 (공식 채용 페이지 인사제도 복리후생 체육시설 항목) — 이용 시간·운영 사업장 미기재', 24),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '질병 및 불의의 사고 발생 시 개인에게는 재활에 도움을 주고 가족에게는 생활 안전책을 마련하기 위한 단체보험 가입 지원 (공식 채용 페이지 인사제도 복리후생 단체보험 항목) — 보장 범위·회사 부담 미기재', 25),
  (@comp_id, 'smoking_cessation', '금연 클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연 클리닉 (공식 홈페이지 안전경영 보건증진활동 항목), 임직원 건강관리 프로그램으로 금연 클리닉 운영 (공식 홈페이지 HDS스토리 해성디에스와 ESG 게시글 항목) — 운영 방식·지원 내용 미기재', 26),

  -- ── 생활 · 금융 (perks) — 정본 복리후생 Family · Corporate life ──
  (@comp_id, 'housing_loan', '주택자금 (무이자)', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 임차에 필요한 자금을 한도 내 무이자로 근로복지기금에서 지원 (공식 채용 페이지 인사제도 복리후생 주택자금 항목) — 한도·상환 조건 미기재', 30),
  (@comp_id, 'pension_support', '개인연금', NULL, 'perks',
   'est', NULL, TRUE, '노후생활 대비를 위한 회사 차원의 개인연금보험 가입 지원 (공식 채용 페이지 인사제도 복리후생 개인연금 항목) — 회사 부담액·지원 방식 미기재', 31),
  (@comp_id, 'meal', '사내식당 (무료)', NULL, 'perks',
   'est', NULL, TRUE, '일반식, 건강식, 다이어트식 등 모든 식사 무료 제공 (공식 채용 페이지 인사제도 복리후생 사내식당 항목) — 제공 끼니·운영 사업장 미기재', 32),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 편리한 출퇴근을 위한 통근버스 운영 (공식 채용 페이지 인사제도 복리후생 통근버스 항목) — 노선·운행 사업장 미기재', 33),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '임직원을 위한 사내 카페 운영 (공식 채용 페이지 인사제도 복리후생 편의시설 항목) — 이용 방식·비용 지원 미기재', 34),

  -- ── 가족 (family) — 정본 복리후생 Family ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '영유아 자녀 대상 사내 어린이집 운영 (공식 채용 페이지 인사제도 복리후생 직장 어린이집 항목) — 정원·운영 사업장 미기재', 40),
  (@comp_id, 'child_edu', '자녀학자금 (유치원·중·고·대학)', NULL, 'family',
   'est', NULL, TRUE, '유치원 자녀의 1년간 지원비와 중·고·대학생 자녀의 학자금을 자녀 수 제한 없이 전액 지원 (공식 채용 페이지 인사제도 복리후생 자녀학자금 항목) — 지원 기준·성적 요건 미기재', 41),
  (@comp_id, 'parenting', '출산패키지 (출산용품 지원)', NULL, 'family',
   'est', NULL, TRUE, '임직원의 출산 장려를 위한 출산 패키지로 출산용품 지원 (공식 채용 페이지 인사제도 복리후생 출산패키지 항목) — 용품 구성·지원 금액 미기재', 42),
  (@comp_id, 'fertility_support', '난임 집중치료기간 휴직', NULL, 'family',
   'est', NULL, TRUE, '출산 패키지로 난임 집중치료기간 휴직 부여 (공식 채용 페이지 인사제도 복리후생 출산패키지 항목) — 휴직 기간·유급 여부 미기재', 43),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 휴가 및 경조금 지원, 축하화환·근조화환·장례서비스 지원 (공식 채용 페이지 인사제도 복리후생 경조사 항목) — 경조 휴가 일수·경조금 금액 미기재', 44),

  -- ── 여가 (leisure) — 정본 복리후생 Corporate life · Leisure Activities · 교육체계 ──
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규입사자 조기 적응을 위한 웰컴키트 제공 (공식 채용 페이지 인사제도 복리후생 온보딩 항목) — 구성품 미기재', 50),
  (@comp_id, 'library', '사내 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '임직원을 위한 사내 도서관 운영 (공식 채용 페이지 인사제도 복리후생 편의시설 항목) — 운영 사업장·보유 장서 미기재', 51),
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 및 가족 구성원의 여가를 위한 전국 각지의 리조트(프리미엄 등급)와 콘도 지원 (공식 채용 페이지 인사제도 복리후생 휴양시설 항목) — 이용 일수·비용 부담 미기재', 52),
  (@comp_id, 'summer_vacation_subsidy', '리프레쉬 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '정기적인 리프레쉬 휴가비 지원 (공식 채용 페이지 인사제도 복리후생 리프레쉬 항목) — 지급 주기·금액 미기재', 53),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '건강한 여가생활을 위한 다양한 사내 동호회 활동 지원 (공식 채용 페이지 인사제도 복리후생 동호회 항목) — 지원 금액·동호회 종류 미기재', 54),
  (@comp_id, 'company_event', '임직원자녀 성년식', NULL, 'leisure',
   'est', NULL, TRUE, '임직원자녀 성년식 (공식 채용 페이지 인사제도 교육체계 생애가치 항목) — 대상 연령·행사 내용 미기재', 55),

  -- ── 근무 환경 (work_env) — 정본 복리후생 Corporate life ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '미혼 임직원을 위한 사내외 기숙사 운영 (공식 채용 페이지 인사제도 복리후생 기숙사 항목) — 입주 조건·비용 부담 미기재', 60),

  -- ── 휴가 (time_off) — 정본 복리후생 Leisure Activities ──
  (@comp_id, 'long_service_leave', '장기근속 휴가·휴가비·순금메달', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에게 휴가, 휴가비, 순금메달 지원 (공식 채용 페이지 인사제도 복리후생 리프레쉬 항목) — 근속 기준·휴가 일수·휴가비 금액 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 정본 복리후생 Leisure Activities, 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출근제, 시차출근제 등 다양한 유연근무제 도입 운영 (공식 채용 페이지 인사제도 복리후생 유연근무제 항목), 유연근무제 활용 여부 예 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 80),

  -- ── 성장 (growth) — 정본 교육제도 · 교육체계 ──
  (@comp_id, 'mba', 'HDS양성 프로그램 (MBA·석사·박사·학사·전문학사 진학과정)', NULL, 'growth',
   'est', NULL, TRUE, '자기개발과 직무역량 향상을 위한 다양한 진학과정 운영, High performer Course (MBA, 석사, 박사), Differentiated Course (학사), Specialized Course (전문학사) (공식 채용 페이지 인사제도 교육제도 HDS양성 프로그램 항목) — 선발 기준·학비 지원 범위 미기재', 90),
  (@comp_id, 'lang', '사내외 어학과정', NULL, 'growth',
   'est', NULL, TRUE, '다양한 사외 외국어 역량 향상과정과 영어, 중국어 등의 사내어학과정 운영 (공식 채용 페이지 인사제도 교육제도 Global 인재육성 항목) — 수강 대상·비용 지원 범위 미기재', 91),
  (@comp_id, 'edu_support', '교양특강·자기개발 교육·e-campus', NULL, 'growth',
   'est', NULL, TRUE, '교양특강, 자기개발 (공식 채용 페이지 인사제도 교육체계 생애가치 항목), e-campus 운영 (같은 페이지 교육제도 직무역량 및 자기개발 교육 프로그램 항목) — 과정 구성·수강 대상 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
