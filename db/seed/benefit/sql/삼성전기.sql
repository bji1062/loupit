-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성전기 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.samsungsem.com/kr/careers/company-life.do
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 법인 자기 도메인 samsungsem.com 헤더 메뉴 채용정보 > 회사생활(/kr/careers/company-life.do).
--     복지 절 3묶음(가족 · 의료 · 소득 지원 / 자기 개발 지원 / 사내 문화 및 편의) 30항목. 서버 렌더 HTML, robots 는 Allow 전체.
--   같은 30항목이 삼성 채용사이트의 삼성전기 법인 전용 페이지 /subsid/detail/C40 의 section id=a6
--     (삼성전기의 근무 환경과 복지 제도)에도 있다. 항목 수가 같아 법인 자기 도메인을 정본으로 골랐다.
--     C40 이 이 법인 것임은 같은 페이지 상세정보가 밝힌다(주소 경기도 수원시 영통구 매영로 150 ·
--     주요 업무 IT/산업/전장용 핵심부품 개발/제조업 · 홈페이지 www.samsungsem.com · 채용 문의 sem.recruit@samsung.com).
--   보조 출처 = 같은 도메인 지속가능경영 > People > 임직원(/kr/sustainability/people/employees.do)의 자세히 보기 본문.
--     생애주기 복리후생 · 육아 및 가족 케어 · 마음건강 · 역량 강화 · 수평적 소통 절에서 정성 행 4개와 서술 보강.
--   원문 30항목 → 회사 주도 교육 2(SW / 직무 교육 · 외국어 생활관 — 외국어 생활관은 2026-10-05 보류 결정으로 lang 서술에 되살림) · 타운홀미팅 1 제외 · 모성보호 항목은 법정 제도를 걷고
--     남은 회사 제도를 parenting 서술로 · 복합 라벨 4 분해(어린이집/학자금 · 장기근속 휴가/포상 · 피트니스/동호회 · 통근버스/기숙사)
--     · 파견형 3을 career 에, 학위형 3을 mba 에 흡수 → 27행 + 보조 출처 4행(insurance · fertility_support · excellence_award ·
--     company_event) = 31행. 재코딩 0 · 신규 코드 0. 구본 edu_support 는 회사 주도 교육이라 뺐다.
--   법정 제도 제외: 육아휴직 · 출산전후휴가 · 난임휴가 · 모성 근로시간단축 · 배우자 출산휴가 20일 · 가족 돌봄 휴직 · 보건휴가 ·
--     태아검진휴가 · 퇴직 연금 · 50대 이상 은퇴 설계(재취업지원, 직원 12,173명으로 의무 대상)는 행에도 서술에도 넣지 않았다.
--   금액: 원문에 원 단위 금액 0건. 구본 추정 승계 6(health_check 100 · medical 100 · child_edu 300 · welfare_point 200 ·
--     pension_support 50 · resort 100 — 전부 틀 값, 구본 행은 모두 이 법인 원문과 맞는 A). event 50 은 1회성이라 NULL.
--   그룹 귀속: 삼성전자 DX · 삼성SDS · 삼성생명 등 형제 법인 정본 문장은 옮기지 않았다. 행 근거는 전부 이 법인 두 페이지다.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 리프레쉬 데이(선택근로 대상 월 1회 출근 면제)를 leave_general 에서 flex_work 서술로 옮김 · 지속가능경영 임직원 페이지의 모성보호실 · 명상실(nap_room)과 평가보상 성과금(incentive) 2행 추가 — 최종 33행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 1(lang) — 최종 33행
-- 후속 정리 5(2026-10-05, 보류 · 붙여넣기): 보류에서 넣기로 정한 줄(사용자 결정 2026-10-05) — lang 서술에 회사생활 외국어 생활관 · 지속가능경영 임직원 인텐시브 과정 보탬 · 꼬리에 선발 기준 — 최종 33행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_electro', '삼성전기',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전자부품', 'S', 'https://www.samsungsem.com/kr/careers/company-life.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_electro');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungsem.com/kr/careers/company-life.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ── 가족 · 의료 · 소득 지원 · 사내 문화 및 편의 · 지속가능경영 임직원
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '주기별 건강검진 지원, 본인은 물론 배우자까지 건강검진 혜택 (공식 채용 페이지 회사생활 건강검진 항목 — 검진 주기·지원 금액 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '임직원과 가족 대상 의료비 지원, 3대 중증질환(뇌졸중, 암, 심장병) 치료비 지원 (공식 채용 페이지 회사생활 의료비 지원 항목 · 지속가능경영 임직원 페이지 — 지원 한도 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '회사, 자녀, 부부 등 애로사항을 전문 상담사에게 상담하는 심리상담센터, 마음건강센터의 개인·부부·자녀 상담과 명상 프로그램, 심리상담 전용 메신저·모바일 앱, 긴급 시 24시간 전화 상담 (공식 채용 페이지 회사생활 심리상담센터 항목 · 지속가능경영 임직원 페이지 — 상담 횟수 미기재)', 12),
  (@comp_id, 'clinic', '사내 병원', NULL, 'health',
   'est', NULL, TRUE, '사내 병원 시설에 의료전문의가 상주해 필요할 때 의료 서비스 이용 (공식 채용 페이지 회사생활 사내 병원 항목 — 진료 과목·운영 사업장 미기재)', 13),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사업장별 피트니스 및 스포츠 시설(축구·테니스 등) 운영, 1:1 개인 맞춤형 운동 처방과 식이 관리·PT(Personal Training) 지원 (공식 채용 페이지 회사생활 사내 피트니스 · 동호회 항목 · 지속가능경영 임직원 건강관리 항목 — 이용 조건 미기재)', 14),
  (@comp_id, 'insurance', '보장성 보험', NULL, 'health',
   'est', NULL, TRUE, '생애주기에 따른 복리후생 재무설계 항목의 보장성 보험 (공식 홈페이지 지속가능경영 임직원 생애주기에 따른 복리후생 항목 — 가입 대상·보장 내용·회사 부담 미기재)', 15),

  -- ── 가족·돌봄 (family) ── 가족 · 의료 · 소득 지원 · 지속가능경영 임직원
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '일과 육아를 병행할 수 있도록 사업장별 어린이집 운영 (공식 채용 페이지 회사생활 사내 어린이집 · 자녀 학자금 항목 — 위치·정원 미기재)', 20),
  (@comp_id, 'child_edu', '자녀 학자금', 300, 'family',
   'est', '자녀 교육 관련 비용 지원, 유치원비·중/고등/대학교 학자금, 장애 자녀 학자금 전액 (공식 채용 페이지 회사생활 · 지속가능경영 임직원 페이지 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'parenting', '출산·입학 축하 지원', NULL, 'family',
   'est', NULL, TRUE, '출산·입양 기념 선물과 자녀 출생·입양 경조금, 출산 축하용품, 초등학교 입학·수능 선물, 임신 단계의 마미휴직 (공식 채용 페이지 회사생활 경조사 · 기념일 지원 항목 · 지속가능경영 임직원 육아 및 가족 케어 지원 항목 — 지원 금액·휴직 기간 미기재)', 22),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 의료비 지원과 난임휴직 (공식 홈페이지 지속가능경영 임직원 육아 및 가족 케어 지원 항목 — 지원 한도·휴직 기간 미기재)', 23),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가, 경조금, 조사용품 등 지원 서비스 운영 (공식 채용 페이지 회사생활 경조사 · 기념일 지원 항목 — 경조 유형별 금액·휴가 일수 미기재)', 24),

  -- ── 경제적 부가혜택 (perks) ── 가족 · 의료 · 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'housing_support', '주거 안정 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 주거 안정을 위한 관련 비용 지원, 삼성 채용사이트의 같은 항목은 대상을 입사자로 적음 (공식 채용 페이지 회사생활 주거 안정 지원 항목 — 지원 금액·조건 미기재)', 30),
  (@comp_id, 'welfare_point', '선택적 복리후생 제도', 200, 'perks',
   'est', '건강·여행·쇼핑·공연 등 다양한 서비스를 스스로 선택해 사용, 복지포인트는 의류·식료품·여행 등에 선택 사용 (공식 채용 페이지 회사생활 선택적 복리후생 제도 항목 — 연간 포인트 금액 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'pension_support', '개인 연금', 50, 'perks',
   'est', '노후 복지생활 마련과 안정적인 소득 보장을 위해 매월 일정 수준의 연금 지원 (공식 채용 페이지 회사생활 개인 연금 항목 — 지원 금액 미기재) (추정)', FALSE, NULL, 32),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '조식·중식·석식 다양한 메뉴(Take-Out 포함) 무료 제공 (공식 채용 페이지 회사생활 사내 식당 항목 — 식대 단가 미기재)', 33),
  (@comp_id, 'snack_bar', '힘내Bar', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 에너지 충전을 위한 다양한 음료 무료 제공 (공식 채용 페이지 회사생활 힘내Bar 항목 — 운영 사업장 미기재)', 34),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '3개 사업장별 다양한 통근버스 노선 운행 (공식 채용 페이지 회사생활 통근버스 · 기숙사 항목 — 노선·이용 조건 미기재)', 35),

  -- ── 시간·휴가 (time_off) ── 가족 · 의료 · 소득 지원 · 사내 문화 및 편의 · 지속가능경영 임직원
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속한 임직원에게 재충전의 기회를 주는 장기근속 휴가 (공식 채용 페이지 회사생활 장기근속휴가 · 포상 항목 중 휴가 부분 — 근속 연수 기준·휴가 일수 미기재)', 40),
  (@comp_id, 'refresh_leave', '덧셈(SEM) 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '기존 휴가일수에 더해 활력 충전과 에너지를 더할 수 있는 추가 휴가 제도 (공식 채용 페이지 회사생활 덧셈(SEM) 휴가 항목 — 부여 일수·사용 조건 미기재)', 41),
  (@comp_id, 'leave_general', '시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 시간 단위로 나눠 쓰는 제도 (공식 홈페이지 지속가능경영 임직원 일과 삶의 균형 항목 — 사용 단위 시간 미기재)', 42),

  -- ── 보상·금전 (compensation) ── 가족 · 의료 · 소득 지원 · 지속가능경영 임직원
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속한 임직원에게 감사를 표하는 시상금 지원 (공식 채용 페이지 회사생활 장기근속휴가 · 포상 항목 중 포상 부분 — 근속 연수 기준·시상금 금액 미기재)', 50),
  (@comp_id, 'excellence_award', '소중한 리더·동료상', NULL, 'compensation',
   'est', NULL, TRUE, '소통과 협업으로 조직문화 조성에 기여한 모범 직원을 창립기념일에 시상, 상금·상패/액자·꽃다발 수여와 인사 가점 부여 (공식 홈페이지 지속가능경영 임직원 수평적 소통의 문화 항목 — 상금 금액·선발 인원 미기재)', 51),
  (@comp_id, 'incentive', '성과금', NULL, 'compensation',
   'est', NULL, TRUE, '업무 성과에 대한 업적평가와 업무 수행 능력·태도에 대한 역량평가 결과를 반영하는 성과금 (공식 홈페이지 지속가능경영 임직원 평가보상 항목 — 지급 기준·지급률 미기재)', 52),

  -- ── 성장·커리어 (growth) ── 자기 개발 지원 · 지속가능경영 임직원
  (@comp_id, 'mba', '학술연수·MBA·EMBA', NULL, 'growth',
   'est', NULL, TRUE, '이공계 석박사 진학을 지원하는 학술연수(국내외 석사 2년·박사 4년), MBA(해외)·EMBA(국내), 제조/현장 사원 대상 당사 기술 유관 맞춤형 정규 학사 과정인 소재부품융합공학과 운영 (공식 채용 페이지 회사생활 자기 개발 지원 항목 · 지속가능경영 임직원 역량 강화 프로그램 항목 — 선발 기준·학비 부담 범위 미기재)', 60),
  (@comp_id, 'career', '사내 직무 전환·지역전문가·주재원', NULL, 'growth',
   'est', NULL, TRUE, '사내 커리어 포털의 주기적 Job Posting/Marketing으로 직무 전환 기회, 전략 국가·현지 법인에 파견하는 지역전문가(1년간)·현장전문가, 해외 법인에서 근무하는 주재원 기회 (공식 채용 페이지 회사생활 자기 개발 지원 항목 · 지속가능경영 임직원 역량 강화 프로그램 항목 — 선발 기준·파견 인원 미기재)', 61),
  (@comp_id, 'lang', '외국어 교육 지원·사내 어학 과정', NULL, 'growth',
   'est', NULL, TRUE, '상위등급 취득을 목적으로 하는 임직원에게 사내 어학과 외부 어학원 수강료 지원 (공식 채용 페이지 회사생활 외국어 교육 지원 항목), 해외 법인과 연관된 외국어 교육 등을 집중 수강하는 외국어 생활관 (공식 채용 페이지 회사생활 외국어 생활관 항목), 업무와 분리된 환경의 집중 교육 과정인 외국어 생활관·인텐시브 과정, 점심/저녁시간을 활용한 사내 어학 과정·온라인 외국어 교육 과정(e-learning)·사내 어학 평가 응시 지원 (지속가능경영 임직원 글로벌 역량 교육 항목) — 지원 한도·대상 어종·선발 기준 미기재', 62),
  (@comp_id, 'books', '도서 구입 지원', NULL, 'growth',
   'est', NULL, TRUE, '다독다독 프로그램으로 매월 임직원 도서 구입비 지원 (공식 채용 페이지 회사생활 도서 구입 지원 항목 — 월 지원 금액 미기재)', 63),

  -- ── 근무유연성 (flexibility) ── 사내 문화 및 편의
  (@comp_id, 'flex_work', '유연근무제·리프레쉬 데이', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제로 월 평균 주 40시간을 일하며 출퇴근 시간과 근로시간을 자유롭게 조절, 선택적 근무시간제 대상 월 1회 출근 의무를 면제하는 리프레쉬 데이 (공식 채용 페이지 회사생활 유연근무제 · 리프레쉬 데이 항목)', 70),

  -- ── 여가·라이프 (leisure) ── 사내 문화 및 편의 · 지속가능경영 임직원
  (@comp_id, 'resort', '테마파크 · 휴양소', 100, 'leisure',
   'est', '에버랜드, 캐리비안 베이를 포함한 유명 휴양소·리조트 회원가 지원 (공식 채용 페이지 회사생활 테마파크 · 휴양소 항목 — 이용 횟수·할인율 미기재) (추정)', FALSE, NULL, 80),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 사내 동호회 활동 지원 (공식 채용 페이지 회사생활 사내 피트니스 · 동호회 항목 — 지원 금액 미기재)', 81),
  (@comp_id, 'company_event', '가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '어린이날 행사, 가족 캠프 등 임직원 가족을 초청하는 행사 개최 (공식 홈페이지 지속가능경영 임직원 육아 및 가족 케어 지원 항목 — 참가 대상·비용 부담 미기재)', 82),

  -- ── 근무환경 (work_env) ── 사내 문화 및 편의
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 거주 임직원 대상 기숙사 시설 지원 (공식 채용 페이지 회사생활 통근버스 · 기숙사 항목 — 입주 조건·비용 미기재)', 90),
  (@comp_id, 'nap_room', '모성보호실·명상실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 임직원의 휴식 및 수유를 위한 모성보호실, 사내 명상실 (공식 홈페이지 지속가능경영 임직원 육아 및 가족 케어 지원 · 임직원 마음건강 케어 항목 — 설치 사업장·이용 시간 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
