-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 달바글로벌 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://dalba.career.greetinghr.com/ko/benefit
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)달바글로벌의 회사 계정 그리팅 채용 사이트 베네핏 페이지다.
--   공식 홈 www.dalbaglobal.com 첫 화면 채용 블록의 채용 확인하기 링크가 dalba.career.greetinghr.com/dalbaglobal 로 간다.
--   자기 도메인에는 복리후생 페이지가 없다(ESG 페이지에 직원 심리상담 프로세스 운영 한 구절뿐).
--   SSR 이라 원본 HTML 에 베네핏 4묶음(업무 몰입 · 몸과 마음 건강 · 성장 · 리프레쉬)과 복지 혜택 카드 13개가 다 있다.
--   __NEXT_DATA__ 와 렌더 글이 같다 — 헤드리스 렌더 · 이미지 판독 불필요. 꼬리말 법인명 dAlba Global Co., Ltd.
--   보조 출처: 같은 그리팅 사이트 오피스 페이지(라운지 · 간식 · 스탠워크 · 듀얼 모니터 · 레스토랑 할인) ·
--     채용 홈(목표 초과이익에 대한 분기별 인센티브) · 공식 홈 ESG 페이지(직원 심리상담 프로세스) ·
--     OpenDART 2025 사업보고서 정정본(접수 20260407001978 — 유연근무제도 주석 · 이사회 의결사항 · 개인별 보수 산정기준) ·
--     2026 반기보고서(접수 20260814001262 — 유연근무제도 사용현황 · 이사회 의결사항). 직원 248명(2026-06-30).
--   귀속: 그리팅 페이지 주어는 이 법인 하나이고 그룹 · 계열 단서 없음. 코퍼스 · 대기 폴더에 형제 법인 없음. 각주 없음.
--   금액: 생일축하금 20만원 1행만 stated(20). 근속 포상 · 휴가비 · 대출 · 비율 · 한도 내 지원은 전부 NULL.
--   제외: 중소기업 청년 소득세 감면(세법 제도 · 회사 급부 아님) · 자유로운 복장(대응 코드 없음) · 고음질 노동요(형태 미상 · 판단 요청) ·
--     주택 전세 및 구입금 · 우리사주 취득자금 대출 지원 대상 특별승인(대상 미상 · 판단 요청) · 자기주식 성과급 지급(대표이사 경영성과급) · 스톡옵션 · RSU(재량 부여) ·
--     임원 보수 칸 · 육아지원제도 사용현황(법정).
--   공고 근거 0행 / 전체 28행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(flexibility 10 · time_off 20 · perks 30 · leisure 40 · health 50 ·
--     compensation 60 · family 70 · growth 80), 오피스 페이지에만 있는 work_env 90.
-- 검증 · 감사 판정 반영(2026-10-15): 신규 코드 own_product 행을 discount 행에 병합(신규 코드 0) · 이사회 주택 전세 및 구입금 지원 housing_loan 추가 · 우리사주 취득자금 대출을 우리사주 행에 병합(참고 블록 제외 줄의 이사회 안건은 이 판정으로 뒤집힘) — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dalba_global', '달바글로벌',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품', 'D', 'https://dalba.career.greetinghr.com/ko/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dalba_global');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://dalba.career.greetinghr.com/ko/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 베네핏 업무 몰입 · 2025 사업보고서 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '10:00까지 여유로운 출근 · 시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '10:00까지 여유로운 출근 (공식 채용 페이지 베네핏 업무 몰입 항목), 시차출퇴근 제도 도입 운영 (2025 사업보고서 직원 등 현황 유연근무제도 사용현황 항목), 2026년 상반기 시차출퇴근제 사용자 238명 (2026 반기보고서 같은 항목) — 출근 시간 선택 범위·적용 대상 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제 (재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무(재택근무) 제도 도입 운영 (2025 사업보고서 직원 등 현황 유연근무제도 사용현황 항목), 2026년 상반기 원격근무제(재택근무 포함) 사용자 6명 (2026 반기보고서 같은 항목) — 대상 직무·사용 조건 미기재', 11),
  -- ── 휴가 (time_off) — 베네핏 업무 몰입 · 몸과 마음 건강 · 리프레쉬 ──
  (@comp_id, 'leave_general', '30분 단위 휴가 · 유급 여성보건휴가', NULL, 'time_off',
   'est', NULL, TRUE, '30분 단위 휴가 사용 가능 (공식 채용 페이지 베네핏 업무 몰입 항목), 여성보건휴가 유급 (같은 페이지 몸과 마음 건강 항목) — 보건휴가 사용 조건 미기재', 20),
  (@comp_id, 'long_service_leave', '장기근속 유급휴일·항공권 (6년·10년 만근)', NULL, 'time_off',
   'est', NULL, TRUE, '6년 만근 시 유급휴일 5일·비즈니스 항공권 지원, 10년 만근 시 유급휴일 10일·비즈니스 항공권·휴가비 200만원 지원 (공식 채용 페이지 베네핏 리프레쉬 항목) — 항공권 노선·지급 횟수 미기재', 21),
  -- ── 생활 · 금융 (perks) — 베네핏 업무 몰입 · 복지 혜택 · 오피스 · 사업보고서 ──
  (@comp_id, 'meal', '야근 식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '야근 식대 지원 (공식 채용 페이지 베네핏 업무 몰입 항목) — 지원 금액·야근 기준 미기재', 30),
  (@comp_id, 'transport', '야근 택시비 · 외근·출장 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '야근 택시비 지원, 외근 및 출장 시 교통비 지원 (공식 채용 페이지 베네핏 업무 몰입 항목) — 지원 한도·야근 기준 미기재', 31),
  (@comp_id, 'snack_bar', '간식과 음료 · 특별간식 Day', NULL, 'perks',
   'est', NULL, TRUE, '다양한 간식과 음료, 매일 달라지는 간식 (공식 채용 페이지 베네핏 복지 혜택 항목), 라운지의 다양한 간식과 여러 종류의 티, 커피머신 3대, 매월 둘째 주 수요일 특별간식 Day (공식 채용 페이지 오피스 간식 항목) — 운영 시간 미기재', 32),
  (@comp_id, 'discount', '자사 제품 직원가 · 신제품 전사 제공 · 트러플 디 알바 할인', NULL, 'perks',
   'est', NULL, TRUE, '써보고 싶었던 제품 직원가 구매, 매월 판매가 기준 100만원 이상 (공식 채용 페이지 베네핏 복지 혜택 자사 제품 직원가 항목), 신제품 출시 시 전사 제공, 누구보다 빠르게 써볼 수 있는 기회 (같은 페이지 복지 혜택 신제품 출시시 전사 제공 항목), 자사 브랜드 레스토랑 Truffle di Alba 임직원 방문 시 20% 할인 (공식 채용 페이지 오피스 항목) — 직원가 할인율·신제품 제공 수량 미기재', 33),
  (@comp_id, 'birthday_gift', '생일 파티 · 생일축하금 20만원', 20, 'perks',
   'est', '생일파티, 생일축하금 20만원 지급 (공식 채용 페이지 베네핏 복지 혜택 생일 파티 항목)', FALSE, NULL, 35),
  (@comp_id, 'welfare_fund_loan', '임직원 사내대출 제도', NULL, 'perks',
   'est', NULL, TRUE, '임직원 사내대출 제도 신설 (2025 사업보고서 이사회 주요 의결사항 항목), 임직원 사내대출 규정 일부 개정 (2026 반기보고서 이사회 주요 의결사항 항목) — 대출 용도·한도·이율 미기재', 36),
  (@comp_id, 'housing_loan', '주택 전세 및 구입금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 전세 및 구입금 지원 대상 특별승인 의결 (2025 사업보고서 이사회 주요 의결사항 항목) — 지원 방식·한도·대상 기준 미기재', 37),
  -- ── 여가 (leisure) — 베네핏 업무 몰입 ──
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '빠른 적응을 위한 웰컴키트 제공 (공식 채용 페이지 베네핏 업무 몰입 항목) — 구성품 미기재', 40),
  -- ── 건강 (health) — 베네핏 몸과 마음 건강 · 성장 · 복지 혜택 · 공식 홈 ESG ──
  (@comp_id, 'health_check', '종합검진', NULL, 'health',
   'est', NULL, TRUE, '종합검진 제공 (공식 채용 페이지 베네핏 몸과 마음 건강 항목) — 검진 주기·비용 지원 범위 미기재', 50),
  (@comp_id, 'mental', '심리 상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리 상담 지원 (공식 채용 페이지 베네핏 몸과 마음 건강 항목), 직원 심리상담 프로세스 운영 (공식 홈페이지 ESG 페이지 Social 항목) — 상담 횟수·운영 방식 미기재', 51),
  (@comp_id, 'fitness', '체력증진비 50% 지원', NULL, 'health',
   'est', NULL, TRUE, '체력증진비 50% 지원, 한도 내 (공식 채용 페이지 베네핏 몸과 마음 건강 항목), 체력 증진 운동비 지원, 한도 내 (같은 페이지 복지 혜택 체력증진비 지원 항목) — 지원 한도 금액 미기재', 52),
  (@comp_id, 'massage', '에스테틱 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '에스테틱 50% 지원, 한도 내 (공식 채용 페이지 베네핏 성장 항목), 고급 화장품 및 에스테틱 체험 지원, 한도 내 (같은 페이지 복지 혜택 에스테틱 비용 지원 항목) — 지원 한도 금액 미기재', 53),
  -- ── 보상 (compensation) — 베네핏 몸과 마음 건강 · 리프레쉬 · 복지 혜택 · 채용 홈 · 사업보고서 ──
  (@comp_id, 'holiday_gift', '명절 선물 · 귀향비', NULL, 'compensation',
   'est', NULL, TRUE, '명절 고급선물 제공 (공식 채용 페이지 베네핏 몸과 마음 건강 항목), 추석·설날 귀향비 및 고급선물세트 지급 (같은 페이지 복지 혜택 명절 선물, 귀향비 항목) — 귀향비 금액·선물 품목 미기재', 60),
  (@comp_id, 'long_service_bonus', '장기근속 포상 (1년·3년 만근)', NULL, 'compensation',
   'est', NULL, TRUE, '1년 만근 시 리프레쉬 휴가비 100만원 지원, 3년 만근 시 이탈리아 알바 여행 전액 지원 (공식 채용 페이지 베네핏 리프레쉬 항목) — 여행 일정·휴가 부여 여부 미기재', 61),
  (@comp_id, 'incentive', '분기별 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '1년에 최대 4번 인센티브 지급 (공식 채용 페이지 베네핏 복지 혜택 인센티브 지급 항목), 목표 초과이익에 대한 분기별 인센티브 (공식 채용 페이지 홈 경쟁력 있는 베네핏 항목), 전사 경영목표 및 성과 인센티브 지급 기준에 따른 목표 달성 장려금과 경영 목표 대비 초과이익의 20% 한도 내 사업부·개인별 성과에 따른 차등 초과 이익 성과금 (2025 사업보고서 개인별 보수 산정기준 항목) — 지급률 미기재', 62),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 설립 (2025 사업보고서 이사회 보고사항 항목), 유가증권시장 상장 시 우리사주조합에 공모주 의무배정 (같은 보고서 의무보유 현황 항목), 우리사주 취득자금 대출 지원 및 대여금 집행 (같은 보고서 이사회 주요 의결사항 항목) — 조합원 범위·회사 출연 여부·대출 한도 미기재', 63),
  -- ── 가족 (family) — 베네핏 몸과 마음 건강 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 경조휴가 제공 (공식 채용 페이지 베네핏 몸과 마음 건강 항목) — 경조금액·휴가 일수 미기재', 70),
  -- ── 성장 · 교육 (growth) — 베네핏 성장 · 복지 혜택 ──
  (@comp_id, 'edu_support', '업무 관련 교육비 전액 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 교육비 전액 지원 (공식 채용 페이지 베네핏 성장 항목), 업무 발전 교육비 지원, 한도 내 (같은 페이지 복지 혜택 교육비 지원 항목) — 지원 한도·대상 과정 미기재', 80),
  (@comp_id, 'books', '업무 관련 도서 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 도서 지원 (공식 채용 페이지 베네핏 성장 항목) — 지원 한도 미기재', 81),
  (@comp_id, 'self_development', '업무 관련 자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 자격증 취득 지원 (공식 채용 페이지 베네핏 성장 항목) — 지원 범위·한도 미기재', 82),
  (@comp_id, 'lang', '외국어 교육비 50% 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 교육비 50% 지원, 한도 내 (공식 채용 페이지 베네핏 성장 항목), 외국어 교육비 지원, 한도 내 (같은 페이지 복지 혜택 교육비 지원 항목) — 지원 한도 금액 미기재', 83),
  -- ── 근무 환경 (work_env) — 오피스 페이지 ──
  (@comp_id, 'lounge', '라운지', NULL, 'work_env',
   'est', NULL, TRUE, '업무 도중 잠깐의 휴식을 취하거나 점심시간을 즐기는 공간으로 활용되는 회사 내부 라운지, 15층 추가 임대로 직원들의 소통과 휴식을 위한 라운지 확대 (공식 채용 페이지 오피스 라운지 및 회의실 항목) — 운영 시간 미기재', 90),
  (@comp_id, 'office_furniture', '스탠워크', NULL, 'work_env',
   'est', NULL, TRUE, '직원 개인의 건강을 위해 스탠워크 제공 (공식 채용 페이지 오피스 항목) — 제공 범위 미기재', 91),
  (@comp_id, 'work_tools', '듀얼 모니터', NULL, 'work_env',
   'est', NULL, TRUE, '직원 개인의 건강을 위해 듀얼 모니터 제공 (공식 채용 페이지 오피스 항목) — 제공 범위 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
