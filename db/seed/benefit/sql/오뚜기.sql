-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 오뚜기 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.otoki.com/about/personnel-system
-- badge: est
--
-- 참고:
--   정본은 상장 법인 주식회사 오뚜기의 자기 도메인 www.otoki.com 회사소개 > 인재채용 > 탭 인사제도
--   페이지의 블록 일과 삶의 행복(6카테고리 39항목, 라벨만 · 금액 0건)이다. SSR 이라 원본 HTML 에
--   항목 텍스트가 전부 있다(헤드리스 렌더 없음 · 이미지 안 항목 없음 · 주석 속 옛 블록 없음).
--   보조 출처는 법인이 직접 발행한 2026 지속가능경영보고서(자기 도메인 PDF) 67쪽 인사제도 · 복리후생
--   인포그래픽과 같은 쪽 조직문화 글, 66쪽 잡포스팅이다. 보고서 2쪽 보고 범위가 사회 성과는
--   주식회사 오뚜기의 국내 전 사업장이라고 밝혀 복지 서술은 이 법인 것이다.
--   귀속: 페이지 문장 주어가 오뚜기는 이고 계열사 · 그룹 · 상이 단서가 0회다. 종속기업(오뚜기라면 ·
--   조흥 · 오뚜기제유 등)은 코퍼스에 미등록이고 그 법인 문장은 끌어오지 않았다 → 그룹 각주 없음.
--   금액: 금액 행 1(meal 288 추정 — 원문 중식비 1끼 × 1끼 12,000원 × 연 240일). stated 0.
--     출산 축하 마일리지는 보고서에 2025년 69명 총 4,830만 원 총액만 있어 금액 칸을 비웠다.
--   제외: 법정(출산휴가 · 육아휴직 · 임신/육아기 단축근무 · 휴직제도 · 안전보호장비 · 휴가 사용 중 법정분 ·
--     보고서 근로시간 단축 제도) · 선발교육(사내MBA · 쿠킹클래스 · 글로벌 인재육성 프로그램) ·
--     업무 교육(사내 계층 · 승진자 · 입문 · 온보딩 · 리더십) · 자율복장(대응 코드 없음) ·
--     영업 배상 책임보험(대응 코드 없음 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 30행. 신규 코드 0.
--   SORT 섹션 순서 = 정본 페이지 첫 등장 순: perks 10 · work_env 20 · leisure 30 · time_off 40 ·
--     growth 50 · compensation 60 · health 70 · family 80 · flexibility 90(보고서에만 있음).
-- 검증 · 감사 판정 반영(2026-10-10): 영업용 차량 work_tools 삭제 · 지방사업장 근무자 주거 지원금 housing_support 추가 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ottogi', '오뚜기',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'O', 'https://www.otoki.com/about/personnel-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ottogi');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.otoki.com/about/personnel-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 정본 업무지원 · 여가 · 생활안정 + 보고서 67쪽 ──
  (@comp_id, 'meal', '사내식당·중식비', 288, 'perks',
   'est', '사내식당/중식비 (공식 홈페이지 인사제도 업무지원 항목) — 식대 단가·조식·석식 제공 여부 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 10),
  (@comp_id, 'team_dinner', '부서 단합비', NULL, 'perks',
   'est', NULL, TRUE, '부서 단합비 (공식 홈페이지 인사제도 업무지원 항목) — 지원 금액·지급 주기 미기재', 11),
  (@comp_id, 'discount', '렌터카·숙박업체 제휴·브랜드경험 공간 할인·임직원몰', NULL, 'perks',
   'est', NULL, TRUE, '렌터카 할인, 브랜드경험 공간 「롤리폴리 꼬또」·「르밀」 할인, 숙박업체 제휴 할인 (공식 홈페이지 인사제도 여가 항목), 임직원 온·오프라인몰 (같은 페이지 생활안정 항목) — 할인율·이용 한도 미기재', 12),
  (@comp_id, 'housing_loan', '주택구입·생활안정자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/생활안정자금 (공식 홈페이지 인사제도 생활안정 항목), 사내복지기금 대부제도로 주택구입·전세자금·생활안전자금을 저금리로 대출 지원 (2026 지속가능경영보고서 67쪽 복리후생 생활지원 항목) — 대출 한도·이율 미기재', 13),
  (@comp_id, 'relocation', '전보자금 (무이자 대부)', NULL, 'perks',
   'est', NULL, TRUE, '전보자금 (공식 홈페이지 인사제도 생활안정 항목), 전보사원 대부 제도로 업무상 거주지 변경 필요시 직원 주거 안정화를 위한 무이자 대부 지원 (2026 지속가능경영보고서 67쪽 복리후생 생활지원 항목) — 대부 한도·상환 조건 미기재', 14),
  (@comp_id, 'housing_support', '지방사업장 근무자 주거 지원금', NULL, 'perks',
   'est', NULL, TRUE, '지방사업장 근무자 주거 지원금 규정, 지원 기준의 합리성 재검토 및 필요시 규정 개정 예정 (2026 지속가능경영보고서 63~64쪽 인권영향평가 개선조치 항목) — 지원 금액·지급 대상 기준 미기재', 15),

  -- ── 근무환경 (work_env) — 정본 업무지원 · 생활안정 + 보고서 67쪽 ──
  (@comp_id, 'smart_office', '스마트오피스', NULL, 'work_env',
   'est', NULL, TRUE, '스마트오피스 (공식 홈페이지 인사제도 업무지원 항목), 기업 전용 전화앱 사용·시스템 부스 마련 (2026 지속가능경영보고서 67쪽 스마트 오피스 항목) — 공간 구성·적용 사업장 미기재', 20),
  (@comp_id, 'dormitory', '사택 지원 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '사택지원(공장) (공식 홈페이지 인사제도 생활안정 항목) — 사택 규모·입주 조건 미기재', 22),
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '자율 좌석제 실시 (2026 지속가능경영보고서 67쪽 스마트 오피스 항목) — 적용 사업장 미기재', 23),

  -- ── 여가 (leisure) — 정본 업무지원 · 여가 + 보고서 67쪽 ──
  (@comp_id, 'welcome_kit', '신입사원 웰컴 키트', NULL, 'leisure',
   'est', NULL, TRUE, '신입사원 웰컴 키트 (공식 홈페이지 인사제도 업무지원 항목) — 구성품 미기재', 30),
  (@comp_id, 'resort', '콘도', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 (공식 홈페이지 인사제도 여가 항목), 직원들의 여가생활을 위해 전국 각지의 휴양시설 이용 지원 (2026 지속가능경영보고서 67쪽 복리후생 휴양지 콘도 지원 항목) — 이용 횟수·본인 부담 미기재', 31),
  (@comp_id, 'club', '사내 커뮤니티', NULL, 'leisure',
   'est', NULL, TRUE, '6개의 사내 커뮤니티 운영, 세계의 글로벌 식문화를 경험하는 「Let’s G.O.」·직접 음식을 만들어 보는 「Let’s COOK」 등 임직원이 자발적으로 참여해 커뮤니티 구성 (2026 지속가능경영보고서 67쪽 소통 문화 사내 커뮤니티 운영 항목) — 활동비 지원 여부·금액 미기재', 32),

  -- ── 휴가 (time_off) — 정본 여가 + 보고서 67쪽 ──
  (@comp_id, 'long_service_leave', '장기근속 리프레시 휴가·휴가비', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 리프레시 휴가, 휴가비 (공식 홈페이지 인사제도 여가 항목), 리프레시 휴가 30년 15일·20년 10일·10년 5일 휴가 및 휴가비 지급, 2025년 117명 지원 (2026 지속가능경영보고서 67쪽 장기근속자 웰니스 지원 항목) — 휴가비 금액·유급 여부 미기재', 40),
  (@comp_id, 'leave_general', '2시간 단위 휴가·연중휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위까지 나눠 쓰는 자유로운 휴가 사용, 연중휴가 (공식 홈페이지 인사제도 여가 항목) — 연중휴가의 부여 일수·유급 여부·본인 휴가 차감 여부 미기재', 41),

  -- ── 성장 (growth) — 정본 인재육성 · 인재교육 체계 + 보고서 66쪽 ──
  (@comp_id, 'edu_support', '온라인 교육·주제별 명사특강', NULL, 'growth',
   'est', NULL, TRUE, '온라인 교육, 주제별 명사특강 (공식 홈페이지 인사제도 인재육성 항목), 온라인교육으로 자기주도 학습문화 조성 (같은 페이지 인재교육 체계) — 수강 과정·비용 지원 범위 미기재', 50),
  (@comp_id, 'conference', '사외 교육·세미나', NULL, 'growth',
   'est', NULL, TRUE, '사외 교육·세미나 (공식 홈페이지 인사제도 인재육성 항목), 사외교육으로 직무관련 전문 교육·세미나 등 개인별 교육·공통역량 개발 (같은 페이지 인재교육 체계) — 교육비 지원 범위·횟수 미기재', 51),
  (@comp_id, 'career', '잡포스팅 (사내 직원 공모)', NULL, 'growth',
   'est', NULL, TRUE, '사내 직원 공모 제도 「잡포스팅」으로 직원의 경력 개발 및 자기 계발 기회 제공, 2023년부터 2025년까지 직원 8명이 부서 이동 (2026 지속가능경영보고서 66쪽 잡포스팅 항목) — 공모 주기·지원 자격 미기재', 52),

  -- ── 보상 (compensation) — 정본 생활안정 + 보고서 67쪽 ──
  (@comp_id, 'holiday_gift', '오뚜기 온라인몰 마일리지 (창립기념일·명절)', NULL, 'compensation',
   'est', NULL, TRUE, '오뚜기 온라인몰 마일리지(창립기념일, 명절) (공식 홈페이지 인사제도 생활안정 항목) — 지급 마일리지 금액 미기재', 60),
  (@comp_id, 'severance_plus', '퇴직금 가산제도', NULL, 'compensation',
   'est', NULL, TRUE, '퇴직금 가산제도 (공식 홈페이지 인사제도 생활안정 항목) — 가산율·적용 조건 미기재', 61),
  (@comp_id, 'long_service_bonus', '장기근속자 웰니스 시설 이용 지원', NULL, 'compensation',
   'est', NULL, TRUE, '25년·15년·5년 근속자 대상 힐링 프로그램, 객실 식사 제공, 2025년 웰니스 시설 3곳 추가 지정(전국 총 8개 시설 이용 지원) (2026 지속가능경영보고서 67쪽 장기근속자 웰니스 지원 항목) — 이용 기간·본인 부담 미기재', 62),

  -- ── 건강 (health) — 정본 건강 + 보고서 67쪽 ──
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '건강검진(본인 및 배우자 종합검진) (공식 홈페이지 인사제도 건강 항목), 2년 주기로 전국 25개 검진센터에서 종합검진 비용 지원, 임직원 가족은 범위 제한 없이 우대가로 수검, 2025년 종합검진 지원 범위를 35세 이상 임직원 및 40세 이상 임직원의 배우자 또는 부모 중 1명으로 확대 (2026 지속가능경영보고서 67쪽 복리후생 항목) — 1인당 검진비 한도 미기재', 70),
  (@comp_id, 'insurance', '단체보험·해외파견자보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험, 해외파견자보험 (공식 홈페이지 인사제도 건강 항목) — 보장 내용·가입 대상 미기재', 71),
  (@comp_id, 'mental', '직원상담프로그램·오케어 정신 건강 관리', NULL, 'health',
   'est', NULL, TRUE, '직원상담프로그램 지원 (공식 홈페이지 인사제도 건강 항목), 임직원 정신 건강 관리 오케어(O’care) 서비스 운영, 오뚜기센터·안양지역(중앙연구소, 품질보증본부, 안양공장) 월 2회 정기 사내 명상 Class, 2026년 심리·건강 분야 특강 운영 (2026 지속가능경영보고서 67쪽 건강 지원 항목) — 상담 횟수·비용 지원 범위 미기재', 72),

  -- ── 가족 (family) — 정본 가족 + 보고서 67쪽 ──
  (@comp_id, 'childcare', '직장어린이집 (오뚜기센터)', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집(오뚜기센터) (공식 홈페이지 인사제도 가족 항목), 사내 어린이집 운영, 원어민 영어 수업·가을 소풍 등 프로그램 운영, 어린이집 평가 A등급 획득 (2026 지속가능경영보고서 67쪽 복리후생 가족 항목) — 정원·이용 대상 사업장 미기재', 80),
  (@comp_id, 'parenting', '출산·입학 축하금·출산 축하 마일리지', NULL, 'family',
   'est', NULL, TRUE, '출산/입학 축하금 (공식 홈페이지 인사제도 가족 항목), 자녀 출산 축하 오뚜기몰 마일리지 지급, 2025년 자녀 69명 대상 총 4,830만 원 (2026 지속가능경영보고서 67쪽 복리후생 가족 항목) — 1인당 축하금·마일리지 금액 미기재', 81),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 홈페이지 인사제도 가족 항목), 임직원들의 자녀들이 미래의 인재로 성장할 수 있도록 장학금 지원 (2026 지속가능경영보고서 67쪽 복리후생 생활지원 자녀 장학금 지원 항목) — 지원 학령·금액 미기재', 82),
  (@comp_id, 'event', '경상조비·경상조휴가·상조 용품', NULL, 'family',
   'est', NULL, TRUE, '경상조비/경상조휴가, 상조 용품 (공식 홈페이지 인사제도 가족 항목), 축하와 조의의 마음을 전하고자 화환 및 상조용품 지원 (2026 지속가능경영보고서 67쪽 복리후생 경조화환 및 상조용품 지원 항목) — 경조금 금액·휴가 일수 미기재', 83),

  -- ── 근무 유연성 (flexibility) — 보고서 67쪽에만 있음 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근 제도로 오전 7시 30분부터 9시까지 30분 단위로 희망 시간에 출근 가능, 2025년 기준 총 336명의 직원이 사용 (2026 지속가능경영보고서 67쪽 유연하고 즐거운 근로환경 조성 항목) — 적용 직무·사업장 미기재', 90),
  (@comp_id, 'remote_work', '원격근무 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무 제도 (2026 지속가능경영보고서 67쪽 유연하고 즐거운 근로환경 조성 항목) — 대상·횟수·운영 방식 미기재', 91),
  (@comp_id, 'satellite_office', '거점 오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점 오피스 운영 (2026 지속가능경영보고서 67쪽 스마트 오피스 항목) — 거점 위치·이용 대상 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
