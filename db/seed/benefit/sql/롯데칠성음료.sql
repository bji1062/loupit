-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데칠성음료 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://company.lottechilsung.co.kr/kor/recruit/benefits/contentsid/547/index.do
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 인재채용 > 복리후생 및 안전건강 페이지(SSR · 법정외 복리후생 제도 14항목).
--   보조 1 = 같은 도메인 인재채용 > 인사/교육제도 페이지(교육제도 · 퇴직자 지원 및 재취업 프로그램).
--   보조 2 = 롯데칠성음료 발행 2025 지속가능경영보고서(2026년 6월 발간 · 보고 기간 2025-01-01~2025-12-31 ·
--     보고 범위 롯데칠성음료 국내 사업장 전체) 87 · 89 · 92 · 93 · 95 · 97쪽.
--   보조 3 = 2026 반기보고서(OpenDART 20260813000529) 직원 등 현황 유연근무제도 사용현황 표.
--   귀속: 전부 롯데칠성음료 자기 도메인 · 자기 발행 보고서 · 자기 공시 문장 — 그룹 각주 없음.
--     롯데 형제(롯데케미칼 · 롯데정밀화학)와 출처 호스트 · 문장이 다르다.
--   금액: 금액 행 0(원문 숫자는 비율 · 1인당 활동비 · 이용 횟수뿐 — 서술에만).
--   제외: 법정(4대 보험 · 퇴직금 · 난임치료 휴가 · 배우자 출산 휴가 의무화 · 자녀 돌봄 휴직 · 창업 및 재취업 지원 서비스 —
--     직원 5,001명) · 업무 교육(입문 · 멘토링 · Grade · 직무 아카데미 · 리더십 · 사외 위탁교육 · 생성형 AI 특강) ·
--     퇴직 임원 아웃플레이스먼트(임원) · 자율복장 · 점심시간 운영 · 사내벤처(대응 코드 없음) · 이새건 펀드(기부 캠페인).
--   공고 근거 0행 / 전체 36행
--   SORT 섹션: family 10 · leisure 20 · time_off 30 · compensation 40 · health 50 · work_env 60 · perks 70 ·
--     growth 80(보조 출처) · flexibility 90(보조 출처)
-- 검증 · 감사 판정 반영(2026-10-14): 육아 행 서술에 배우자 출산 휴가 의무화 병합(리드 판정 123 — 참고 블록 법정 제외 줄의 같은 구절은 이 판정으로 뒤집힘) · 38쪽 Scope3 통근버스 운행 commute_subsidy 추가 — 최종 37행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_chilsung', '롯데칠성음료',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'L', 'https://company.lottechilsung.co.kr/kor/recruit/benefits/contentsid/547/index.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chilsung');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.lottechilsung.co.kr/kor/recruit/benefits/contentsid/547/index.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '중, 고, 대학교 자녀 학자금 전액 (공식 채용 페이지 복리후생 자녀 학자금 지원 항목), 자녀 학자금 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 교육지원 항목) — 자녀 수·지급 횟수 제한 미기재', 10),
  (@comp_id, 'parenting', '임신·출산·육아 지원 (입학축의금·보육수당·출산축하 포인트 등)', NULL, 'family',
   'est', NULL, TRUE, '유치원, 중, 고 입학축의금 지원 (공식 채용 페이지 복리후생 자녀 학자금 지원 항목), 보육수당 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 교육지원 항목), 예비맘 근로시간 단축 (임신 전 기간) · 태아보험금 지원 · 출산축하 복지포인트 지급 · 남성 육아휴직 의무화 · 배우자 출산 휴가 의무화 · 자녀입학기 맘편한케어 · 맘스푸드 서비스 포인트 지급, 자녀의 입학기 단축 근무 · 대학수학능력시험 D-100 휴직 (같은 보고서 87쪽 여성인재 항목, 95쪽 가족친화제도 항목) — 축의금·수당·포인트 금액과 휴직 기간 미기재', 11),
  (@comp_id, 'event', '경조 제도·상조서비스 지원', NULL, 'family',
   'est', NULL, TRUE, '종업원의 경조사 발생시 경조 휴가부여 및 경조금 지급, 상조 발생시 상조서비스 및 장례용품 지원 (공식 채용 페이지 복리후생 각종 경조 제도·상조서비스 지원 항목), 웨딩카 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 경조사 항목) — 경조 유형별 휴가 일수·경조금 금액 미기재', 12),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (2025 지속가능경영보고서 87쪽 여성인재 항목, 95쪽 가족친화제도 운영 항목) — 운영 사업장·정원 미기재', 13),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임시술비 지원 (2025 지속가능경영보고서 95쪽 주요 가족친화제도 프로그램 임신 항목) — 지원 금액·지원 횟수 미기재', 14),
  (@comp_id, 'disability_family_support', '장애인 보조금 지급', NULL, 'family',
   'est', NULL, TRUE, '장애인 보조금 지급 (2025 지속가능경영보고서 93쪽 복리후생제도 건강관리 항목) — 지원 대상(본인·가족)·금액 미기재', 15),
  -- ── 여가 (leisure) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'resort', '콘도미니엄 운영', NULL, 'leisure',
   'est', NULL, TRUE, '롯데, 대명, 한화 등 유명 리조트 회원권 보유, 객실 이용료 50% 회사 부담 (공식 채용 페이지 복리후생 콘도미니엄 운영 항목), 임직원 콘도 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 여가/휴가 항목) — 이용 횟수·기간 제한 미기재', 20),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지급 (공식 채용 페이지 복리후생 휴가 항목, 2025 지속가능경영보고서 93쪽 복리후생제도 여가/휴가 항목) — 지급 금액·지급 시기 미기재', 21),
  (@comp_id, 'club', '사내 동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '사내 다양한 동호회를 운영하여 월별 활동에 대한 지원금 지급 (공식 채용 페이지 복리후생 동호회 운영 항목), 사내동호회 운영 동호회 41개·총 776명 (2025 지속가능경영보고서 93쪽 복리후생제도 문화지원 항목) — 지원 금액 미기재', 22),
  (@comp_id, 'company_event', '가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '2025 롯데 패밀리 스카이런 · 2025 러브 패밀리 페스티벌 등 가족 초청 행사 진행, 롯데 임직원 및 가족 롯데월드 초청행사 (2025 지속가능경영보고서 97쪽 직원 참여 프로그램 항목) — 개최 주기·참가 비용 지원 미기재', 23),
  -- ── 휴가 (time_off) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'refresh_leave', '매년 4일 휴가 부여', NULL, 'time_off',
   'est', NULL, TRUE, '매년 4일의 휴가 부여 (공식 채용 페이지 복리후생 법정외 복리후생 제도 휴가 항목) — 휴가 명칭·사용 시기·유급 여부 미기재', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상 및 특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에 대하여 근속년수별 기념품 및 상패 지급 (공식 채용 페이지 복리후생 장기근속자 포상 항목), 장기근속자에게는 포상과 함께 특별휴가 부여 (2025 지속가능경영보고서 93쪽 복리후생제도 운영 항목) — 근속 기준·휴가 일수 미기재', 31),
  -- ── 보상 (compensation) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'holiday_gift', '귀향여비·명절/창립 기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '매년 명절(설, 추석)에 귀향여비 지급 (공식 채용 페이지 복리후생 귀향여비 지급 항목), 명절 / 창립 기념일 선물 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 생활지원 항목) — 지급 금액·선물 내용 미기재', 40),
  (@comp_id, 'excellence_award', '모범사원 해외연수·ZBB 어워즈 포상', NULL, 'compensation',
   'est', NULL, TRUE, '매년 모범사원 및 영업실적 우수자를 선발, 해외연수 기회 제공 (공식 채용 페이지 복리후생 해외연수 제도 항목), 매년 연말 ZBB 어워즈 개최 · 우수자를 선정하여 포상 (2025 지속가능경영보고서 92쪽 ZBB 프로젝트 운영 항목) — 선발 인원·포상 내용 미기재', 41),
  (@comp_id, 'profit_sharing', 'ZBB 이익 배분 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '비용 절감액과 경영 효율화 성과를 전 임직원 대상의 이익 배분(Profit Share) 인센티브 재원으로 활용, 2025년 총 4,799명의 임직원에게 ZBB 인센티브 지급 (2025 지속가능경영보고서 92쪽 ZBB 프로젝트 운영 항목) — 지급 기준·지급률 미기재', 42),
  -- ── 건강 (health) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '산재보험과 별도로 종업원의 질병, 사망, 상해 등에 대비한 복지보험 전직원 가입 (공식 채용 페이지 복리후생 단체보험 항목) — 보장 금액·가족 포함 여부 미기재', 50),
  (@comp_id, 'health_check', '건강검진 비용 지원 (40대 이상 배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '年 1회 건강검진 비용 지원, 40대 이상 배우자 포함 (공식 채용 페이지 복리후생 건강검진 항목), 종합 건강검진 건강케어 서비스 (2025 지속가능경영보고서 93쪽 복리후생제도 건강관리 항목) — 지원 금액·검진 항목 미기재', 51),
  (@comp_id, 'mental', '외부 심리상담센터 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '외부 전문 기관을 통한 심리상담센터(EAP) 운영, 임직원 월 평균 10회 이용 (2025 지속가능경영보고서 93쪽 복리후생제도 건강관리 항목) — 상담 횟수 한도·가족 이용 여부 미기재', 52),
  -- ── 근무 환경 (work_env) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'dormitory', '사택', NULL, 'work_env',
   'est', NULL, TRUE, '사택 (공식 채용 페이지 복리후생 사택 및 부임이전료 지급 항목, 2025 지속가능경영보고서 93쪽 복리후생제도 생활지원 항목) — 대상·위치·이용 조건 미기재', 60),
  (@comp_id, 'lounge', '여성 전용 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 전용 휴게실 (2025 지속가능경영보고서 87쪽 여성인재 항목) — 운영 사업장·시설 내용 미기재', 61),
  (@comp_id, 'parking', '임산부 배려 주차 구역', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 배려 주차 구역 (2025 지속가능경영보고서 87쪽 여성인재 항목) — 운영 사업장 미기재', 62),
  -- ── 생활 (perks) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'relocation', '부임이전료 지급', NULL, 'perks',
   'est', NULL, TRUE, '입사 이후 무연고지 발령자에 대해 이사비와 주거보조비 지원 (공식 채용 페이지 복리후생 사택 및 부임이전료 지급 항목), 부임 이전료 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 생활지원 항목) — 지원 금액·지원 기간 미기재', 70),
  (@comp_id, 'team_dinner', '한마음대회·송년회 단합 활동비', NULL, 'perks',
   'est', NULL, TRUE, '상, 하반기 부서별 단합대회를 위한 활동비 지급 3만원/人 (공식 채용 페이지 복리후생 한마음대회, 송년회 항목), 한마음대회 개최 · 송년회비 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 운영 항목) — 송년회비 금액 미기재', 71),
  (@comp_id, 'welfare_fund', '사내근로복지기금 운영', NULL, 'perks',
   'est', NULL, TRUE, '종업원에게 다양한 복지혜택을 제공하기 위하여 별도의 사내근로복지기금 법인을 운영 (공식 채용 페이지 복리후생 사내근로복지기금 운영 항목) — 기금 지원 사업 내용 미기재', 72),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아 운영 (2025 지속가능경영보고서 93쪽 복리후생제도 문화지원 항목) — 운영 형태·이용 비용 미기재', 73),
  (@comp_id, 'car_rental', '다자녀 가정 패밀리 밴 무상 지원', NULL, 'perks',
   'est', NULL, TRUE, '다자녀 임직원 가정을 위한 패밀리 밴 무상 지원 (2025 지속가능경영보고서 95쪽 가족친화제도 운영 항목) — 지원 방식·다자녀 기준·이용 기간 미기재', 74),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 (2025 지속가능경영보고서 38쪽 Scope3 배출량 산정 임직원 통근 항목) — 운행 사업장·노선·이용 비용 미기재', 75),
  -- ── 성장 (growth) — 채용 페이지 인사/교육제도 · 2025 지속가능경영보고서 ──
  (@comp_id, 'lang', '외국어 회화 수업 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 회화 수업 지원 (공식 채용 페이지 인사/교육제도 직무교육 항목), 외국어 교육 (2025 지속가능경영보고서 89쪽 전사 교육 프로그램 구성 항목) — 대상 언어·수강 방식·비용 지원 범위 미기재', 80),
  (@comp_id, 'self_development', '전문 자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '전문 자격증 지원 (공식 채용 페이지 인사/교육제도 핵심인재교육 항목), 직무 자격증 지원 (2025 지속가능경영보고서 89쪽 전사 교육 프로그램 구성 핵심인재 항목) — 지원 대상·지원 금액 미기재', 81),
  (@comp_id, 'mba', '사외 MBA·전문대학원 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외MBA/전문대학원 (공식 채용 페이지 인사/교육제도 핵심인재교육 항목), 대학원 지원 (2025 지속가능경영보고서 93쪽 복리후생제도 교육지원 항목) — 선발 기준·지원 범위 미기재', 82),
  (@comp_id, 'career', '사내공모제 잡 포스팅·인 커리어', NULL, 'growth',
   'est', NULL, TRUE, '사내공모제 잡 포스팅(Job Posting)을 통해 부서 이동을 희망하는 임직원에게 다양한 직무 경험과 성장 기회 제공, 그룹 내 커리어 통합 관리 플랫폼 인 커리어(IN Career) 운영 (2025 지속가능경영보고서 89쪽 사내 인사이동 제도 항목) — 지원 자격·공모 주기 미기재', 83),
  (@comp_id, 'retirement_support', '퇴직 예정자 진로 탐색 유급 휴가·퇴직자 심리 상담', NULL, 'growth',
   'est', NULL, TRUE, '퇴직 예정 임직원 진로 탐색을 위한 유급 휴가 (2025 지속가능경영보고서 95쪽 퇴직 예정자 지원 제도 항목), 퇴직자 심리 상담 프로그램 (공식 채용 페이지 인사/교육제도 퇴직자 지원 및 재취업 프로그램 항목) — 휴가 일수·상담 대상 미기재', 84),
  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출근제·선택근무제·인터벌 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출근제를 통해 업무에 몰입할 수 있는 시간대 근무 · 인터벌 제도를 통한 유연한 근로시간 활용 · 영업사원 현장 출퇴근 제도 (2025 지속가능경영보고서 92쪽 임직원 워라밸 관련 제도 항목), 시차출퇴근제 · 선택근무제 도입 및 시행 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 출근 시간대·적용 직군 미기재', 90),
  (@comp_id, 'remote_work', '원격근무제 (재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 도입 및 시행, 2026년 반기 사용자 205명 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 91),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스 운영을 통한 효율적 근무 환경 조성 (2025 지속가능경영보고서 92쪽 임직원 워라밸 관련 제도 항목), 거점오피스 운영 임직원 월 평균 117회 이용 (같은 보고서 93쪽 복리후생제도 생활지원 항목) — 거점 위치·이용 대상 미기재', 92),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF제도 적용으로 업무시간 외 PC사용 금지 (2025 지속가능경영보고서 92쪽 임직원 워라밸 관련 제도 항목) — 적용 시간·예외 기준 미기재', 93),
  (@comp_id, 'family_day', '금요일 조기 퇴근제도', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원의 워라밸을 위한 금요일 2시간 조기 퇴근제도, 영업 현장 월 2회 Happy Day로 변형하여 운영 (2025 지속가능경영보고서 92쪽 임직원 워라밸 관련 제도 항목), 금요일 4시 조기 퇴근 (같은 보고서 95쪽 주요 가족친화제도 프로그램 육아 항목) — 시행 대상 사업장·예외 기준 미기재', 94)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
