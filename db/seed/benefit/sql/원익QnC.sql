-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 원익QnC 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.wonikqnc.com/ko/recruit/system.php
-- badge: est
--
-- 참고:
--   정본은 상장 법인 원익큐엔씨(주)의 자기 도메인 www.wonikqnc.com 인재채용 > 인사제도 페이지다.
--   SSR 이라 원본 HTML 에 복지제도 탭(hr2) 21개 항목이 다 있다 — 헤드리스 렌더 없음.
--   같은 페이지 인사제도 탭(hr0) 보상제도는 이미지 안 글자라 판독 사본으로 인센티브 1행(SORT 10).
--   보조 출처: 같은 도메인 ESG 데이터 페이지에 올라 있는 법인 단독 발행 2026 지속가능경영보고서
--   (발행 2026년 9월 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 원익큐엔씨 국내사업장) 51 · 56 · 57쪽,
--   같은 도메인 미디어룸 뉴스센터 회사 기사(2024-01 · 2025-01 · 2025-05 · 2025-07 · 2025-11),
--   OpenDART 2026 반기보고서(접수 20260814001542) · 2025 사업보고서(접수 20260323001246) 유연근무제도 사용 현황 ·
--   재무제표 주석 기타장기종업원급여. 직원 1,212명(2025 사업보고서).
--   귀속: 인사제도 탭 주어가 원익큐엔씨는 이고 복지제도 탭은 주어 없는 법인 페이지 목록이다 — 각주 없음.
--   인재육성체계 탭만 원익은 주어(그룹 문구)라 그 탭에서는 행을 세우지 않았다.
--   형제 원익IPS(대기 시드 · ips.co.kr) 서술과 글자까지 같은 문장 0 — 항목 구성 · 문구가 다르다.
--   금액: stated 1행(복지포인트 년 100만원 포인트 지급 = 100) · 추정 1행(식대 864 = 하루 3끼 식) · 나머지 NULL.
--   숙소보조금 월 20만원은 2년간 기간 상한이 있어 조건부라 NULL.
--   제외: 신입사원 1:1 멘토링(온보딩) · 인재육성체계 표 업무 교육(입문 · OJT · 리더십 · 직무 · 법정의무 · 원익아카데미) ·
--     명장 선발 제도(선발형 기술인력 육성) · 안전환경 부문 포상(EHS) · 이사 보수 칸(임원 전용) ·
--     공시 선택근무제 · 원격근무제 줄(세 기간 모두 사용자 없음) · 법정(출산휴가 · 육아휴직 · 배우자 출산휴가 사용 현황).
--   공고 근거 0행 / 전체 28행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · family 20 · perks 30 · leisure 40 · health 50 ·
--     time_off 60 · growth 70 · work_env 80), 보조 출처에만 있는 flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-15): 2023년 7월 뉴스센터 기사의 사내 복지차원 세차 직무와 2026 보고서 78쪽 사내 세차 car_wash 추가 · 인재육성체계 공통 교육 Work Smart OA 과정을 자기개발지원 edu_support 행에 병합(참고 블록의 인재육성체계 탭 행 없음 문장은 이 판정으로 뒤집힘 · 원익은 = 회사 약칭) · 참고 블록의 공고 근거 0행 / 전체 28행은 전체 29행 — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wonik_qnc', '원익QnC',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'W', 'https://www.wonikqnc.com/ko/recruit/system.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wonik_qnc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.wonikqnc.com/ko/recruit/system.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 정본 페이지 보상제도 이미지 · 복지제도 탭 · 보고서 · 뉴스센터 ──
  (@comp_id, 'profit_sharing', '인센티브 (경영성과 성과급)', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영성과에 따른 성과급 지급 (공식 채용 페이지 인사제도 보상제도 인센티브 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기근속자 포상 (5/10/20/30년)', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 5/10/20/30년, 순금 및 부부동반 해외여행권 (공식 채용 페이지 복지제도 장기근속자 포상 항목), 주로 5년 이상 근무한 장기 근속 임직원에게 장기종업원급여 제공 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 연수별 포상 구성·금액 미기재', 11),
  (@comp_id, 'excellence_award', 'WQnC 모범사원 특별상', NULL, 'compensation',
   'est', NULL, TRUE, 'WQnC 모범사원 특별상 (2026 지속가능경영보고서 57쪽 SHE 주요 프로그램 항목), 시무식 모범사원 시상 (공식 홈페이지 뉴스센터 2025년 1월 시무식 기사 항목) — 선발 기준·포상 내용 미기재', 12),

  -- ── 가족 (family) — 정본 페이지 복지제도 탭 · 뉴스센터 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원, 등록금 지원 (공식 채용 페이지 복지제도 자녀 학자금 지원 항목) — 지원 학령·한도 미기재', 20),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 상조지원, 경조금 및 경조휴가 지급 (공식 채용 페이지 복지제도 경조사 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 21),
  (@comp_id, 'parenting', '임신·출산·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 중 입학축하금 (공식 채용 페이지 복지제도 자녀 학자금 지원 항목), 임신 축하금, 자녀출산 축하금 (공식 홈페이지 뉴스센터 2025년 11월 일·생활 균형 우수 기업 선정 기사 항목) — 축하금 금액 미기재', 22),

  -- ── 생활 · 금융 · 주거 (perks) — 정본 페이지 복지제도 탭 ──
  (@comp_id, 'housing_loan', '융자 지원 (주택자금·생활안정자금)', NULL, 'perks',
   'est', NULL, TRUE, '융자 지원, 주택자금 및 생활안정자금 지원 (공식 채용 페이지 복지제도 융자 지원 항목) — 융자 한도·이율·자격 미기재', 30),
  (@comp_id, 'welfare_point', '복지포인트', 100, 'perks',
   'est', '년 100만원 포인트 지급 (공식 채용 페이지 복지제도 복지포인트 항목) — 지급 시기·사용처 미기재', FALSE, NULL, 31),
  (@comp_id, 'meal', '사내식당 운영', 864, 'perks',
   'est', '사내식당 운영, 조/중/석/야식 및 간식 무료 (공식 채용 페이지 복지제도 사내식당 운영 항목) — 운영 사업장 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식·간식 제외)', FALSE, NULL, 32),
  (@comp_id, 'housing_support', '숙소보조금 지급', NULL, 'perks',
   'est', NULL, TRUE, '숙소보조금 지급, 월 20만원, 2년간 지원 (공식 채용 페이지 복지제도 숙소보조금 지급 항목) — 지급 대상·자격 미기재', 33),
  (@comp_id, 'commute_subsidy', '통근버스 운행', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 (공식 채용 페이지 복지제도 통근버스 운행 항목) — 노선·운행 사업장 미기재', 34),
  (@comp_id, 'snack_bar', '스낵바 운영', NULL, 'perks',
   'est', NULL, TRUE, '스낵바 운영, 쿠키, 스낵, 음료, 아이스크림 등 무료 제공 (공식 채용 페이지 복지제도 스낵바 운영 항목) — 운영 사업장 미기재', 35),
  (@comp_id, 'car_wash', '사내 세차', NULL, 'perks',
   'est', NULL, TRUE, '기업문화 활성화 및 사내 복지차원에서 시작된 세차 직무 (공식 홈페이지 뉴스센터 2023년 7월 장애인 사회공헌 기사 항목), 사내 세차 직무를 신설하여 장애인 직원 채용 (2026 지속가능경영보고서 78쪽 지역사회 항목) — 이용 대상·비용·운영 사업장 미기재', 36),

  -- ── 여가 (leisure) — 정본 페이지 복지제도 탭 · 뉴스센터 ──
  (@comp_id, 'resort', '휴양시설·하계휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설, 전국 한화 콘도, 대명콘도 (공식 채용 페이지 복지제도 휴양시설 항목), 하계휴양소 이용자 추첨으로 7월말~8월말 1개월간 전국 13개 숙박업체에서 숙박 혜택 (공식 홈페이지 뉴스센터 2025년 7월 하계휴양소 기사 항목), 하계휴가 숙소 지원 (공식 홈페이지 뉴스센터 2025년 11월 기사 항목) — 이용 일수·본인 부담 미기재', 40),
  (@comp_id, 'travel_support', 'Refresh 해외배낭여행', NULL, 'leisure',
   'est', NULL, TRUE, 'Refresh 해외배낭여행, 15일, 500만원 지원 (공식 채용 페이지 복지제도 Refresh 해외배낭여행 항목) — 대상·선발 여부·지원 주기 미기재', 41),
  (@comp_id, 'club', '동우회 지원 및 활성화', NULL, 'leisure',
   'est', NULL, TRUE, '동우회 지원 및 활성화, 정기지원 월 1회, 특별지원 년 2회 (공식 채용 페이지 복지제도 동우회 지원 및 활성화 항목) — 지원 금액 미기재', 42),
  (@comp_id, 'company_event', '직원가족 참여 문화 행사', NULL, 'leisure',
   'est', NULL, TRUE, '직원가족 참여 문화 행사 (공식 채용 페이지 복지제도 직원가족 참여 문화 행사 항목), 2025 가족초청행사 「원익 가족과 함께하는 행복한 여행」 임직원과 가족 약 400명 참여 (공식 홈페이지 뉴스센터 2025년 5월 기사 항목) — 개최 주기 미기재', 43),

  -- ── 건강 (health) — 정본 페이지 복지제도 탭 · 보고서 · 뉴스센터 ──
  (@comp_id, 'fitness', '사내 체육시설 운영', NULL, 'health',
   'est', NULL, TRUE, '사내 체육시설 운영, 농구, 풋살, 배구, 족구장/당구, 탁구장/체력단련실, 샤워실 등 (공식 채용 페이지 복지제도 사내 체육시설 운영 항목) — 운영 사업장·이용 시간 미기재', 50),
  (@comp_id, 'insurance', '종업원 상해 보험', NULL, 'health',
   'est', NULL, TRUE, '종업원 상해 보험 가입 (공식 채용 페이지 복지제도 상해 보험·종합검진 항목) — 보장 범위·가입 대상 미기재', 51),
  (@comp_id, 'health_check', '종합검진 지원', NULL, 'health',
   'est', NULL, TRUE, '종합검진 지원 (공식 채용 페이지 복지제도 상해 보험·종합검진 항목) — 검진 주기·비용 지원 범위 미기재', 52),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '2024년 건강관리실 구축, 혈압·혈당·스트레스 측정 장비 구비, 건강한 사업장 프로그램·비만관리 프로그램 운영 (2026 지속가능경영보고서 56쪽 보건 관리 항목) — 운영 사업장·이용 시간 미기재', 53),
  (@comp_id, 'mental', '정신건강 관리 프로그램 (마음job 다)', NULL, 'health',
   'est', NULL, TRUE, '2025년 구미보건소와 업무협약을 맺고 정신건강 관리를 위한 「마음job 다」 프로그램 운영 (2026 지속가능경영보고서 56쪽 보건 관리 항목) — 상담 방식·이용 횟수 미기재', 54),
  (@comp_id, 'smoking_cessation', '금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '2024년 1월부터 임직원 건강 증진을 위해 금연클리닉 운영, 총 6개월 과정, 지역 보건소 연계 전문 상담사 관리 (공식 홈페이지 뉴스센터 2024년 1월 금연클리닉 기사 항목), 금연 프로그램 운영 (2026 지속가능경영보고서 56쪽 보건 관리 항목) — 운영 주기·지원 내용 미기재', 55),

  -- ── 휴가 (time_off) — 정본 페이지 복지제도 탭 · 뉴스센터 ──
  (@comp_id, 'summer_leave', '하계정기휴가 (유급 4일)', NULL, 'time_off',
   'est', NULL, TRUE, '하계정기휴가, 유급휴가 4일 (공식 채용 페이지 복지제도 하계정기휴가 항목), 법적 기준을 뛰어넘는 휴가제도로 하계휴가 운영 (공식 홈페이지 뉴스센터 2025년 11월 기사 항목) — 대상·사용 시기 미기재', 60),

  -- ── 성장 (growth) — 정본 페이지 복지제도 탭 · 보고서 ──
  (@comp_id, 'edu_support', '자기개발지원 (사외 교육프로그램)·Work Smart OA 과정', NULL, 'growth',
   'est', NULL, TRUE, '자기개발지원, 사외 교육프로그램 지원 (공식 채용 페이지 복지제도 자기개발지원 항목), 공통 교육 Work Smart (OA) 과정 (공식 채용 페이지 인재육성체계 공통 교육 항목) — 지원 한도·대상 과정 미기재', 70),
  (@comp_id, 'lang', 'PRODA 사내 어학교육프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'PRODA 사내 어학교육프로그램 (공식 채용 페이지 복지제도 PRODA 항목), 사내 클래스, 전화 외국어, 자기개발 지원제도 등 어학 교육 프로그램 운영 (2026 지속가능경영보고서 51쪽 PRODA 항목) — 비용 부담·수강 대상 미기재', 71),
  (@comp_id, 'books', '독서 장려 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '독서 장려 프로그램, 매월 신규도서 비치, 우수 서평 포상 (공식 채용 페이지 복지제도 독서 장려 프로그램 항목) — 비치 장소·포상 내용 미기재', 72),

  -- ── 근무환경 (work_env) — 정본 페이지 복지제도 탭 ──
  (@comp_id, 'dormitory', '기숙사/사택 운영', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사/사택 운영 (공식 채용 페이지 복지제도 기숙사/사택 운영 항목) — 입주 자격·운영 사업장 미기재', 80),

  -- ── 근무 유연성 (flexibility) — 공시 · 뉴스센터 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '의무근무시간(Core time)을 지정한 유연근무제도(시차출퇴근제) 도입 및 운영, 적용 직원 1,239명 2026년 6월 30일 기준 (2026 반기보고서 유연근무제도 사용 현황 항목), 유연한 근로 시간제 운영 (공식 홈페이지 뉴스센터 2025년 11월 기사 항목) — 출퇴근 시간 선택 범위 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
