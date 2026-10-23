-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 우리은행 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://jrs.jobkorea.co.kr/wooribank
-- badge: est
--
-- 참고:
--   정본 = 우리은행 채용 사이트(jrs.jobkorea.co.kr/wooribank · 2026 하반기 신입행원 채용 회차 화면) WOORI 복지 · WOORI 인재 절.
--     자기 도메인 spot.wooribank.com 은행소개 > 인재채용 > 신입행원 채용 메뉴가 이 주소로 링크한다 · 경로 /wooribank · 전용 CSS · 제목 우리은행 채용 — 법인 전용 채용 사이트.
--     복지 절 주어 = 우리은행만의 복지 — 그룹 주어 아님 · 각주 없음. 꼬리말 패밀리사이트 목록은 그룹사 링크일 뿐.
--   보조 = 자기 도메인 인재개발제도(spot.wooribank.com BPBKI0046 · MBA · 연수포털 · 학자금 · 자격증 · HRD 시상) ·
--     우리은행 2025 ESG보고서(자기 도메인 PDF · 2026년 6월 발행 · 법인 단독 · 68쪽 근로자 지원 프로그램 · 81쪽 재채용조건부 육아퇴직) ·
--     2026 반기보고서(접수 20260814003574) · 2025 사업보고서(접수 20260313000815) 유연근무제도 사용현황 표(시차출퇴근제 사용자 수).
--   렌더 = SSR 원본 HTML(정본 · 홈페이지) · PDF 텍스트 · OpenDART 원문 XML.
--   금액 = 복지 포인트 1행(매월 50만 원 · 원문이 연 600만 원 상당을 함께 적음 → 600 · stated). 출산 축하금 5백만 원 · 자녀 학자금 총 900만 원 · 해외 문화 체험 3백만 원(추첨자 한정)은 1회성 · 누계 · 조건부라 NULL.
--   제외 = 신입행원 멘토링 · 경력개발(CDP) · 직무별 전문인력 양성 · 글로벌전문가 사전양성과정 · 디지털 · 데이터 과정(업무 · 선발형 교육) · 전직지원제도(조기퇴직) · 우리사주조합(주주 표 칸뿐) · 임원 보수 칸 · 원격근무(공시 세 기간 모두 -).
--   공고 근거 0행 / 전체 22행(정본은 채용 사이트 상시 주소 — 회차 화면이라 다음 회차에 바뀔 수 있음 · 근거표 판단 요청).
--   SORT 섹션 순서 = growth 10 · family 20 · perks 30 · leisure 40 · time_off 50 · health 60 · flexibility 70 · compensation 80(보조 출처에만).
-- 검증 · 감사 판정 반영(2026-10-23): 반반차 원문을 2시간 단위 휴가 꼴로 · 직원만족 프로그램 셋째 줄(취미계발 및 소양 증진 프로그램)을 연수포털 edu_support 행에 병합 · 유연근무 꼬리 교체 · ESG보고서 82쪽 보수 지표의 관리직 현금 성과급을 incentive 로 추가 · 정본 채용 사이트는 회차 공고 화면이라 공고 근거 21행 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록의 공고 근거 0행 / 전체 22행은 이 판정으로 뒤집힘(21행 / 23행) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('woori_bank', '우리은행',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '은행', 'W', 'https://jrs.jobkorea.co.kr/wooribank');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'woori_bank');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://jrs.jobkorea.co.kr/wooribank'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) — 채용 사이트 WOORI 인재 · 홈페이지 인재개발제도 ──
  (@comp_id, 'mba', '국내외 MBA 파견', NULL, 'growth',
   'est', NULL, TRUE, '국내외 MBA 파견 (공식 채용 사이트 WOORI 인재 인재양성 프로그램 항목), 국내 Top랭킹 MBA 파견 프로그램을 운영하며 필요한 일체의 비용 지원 (공식 홈페이지 인재개발제도 MBA 및 학위취득 과정 항목) — 선발 기준·파견 인원 미기재', 10),
  (@comp_id, 'lang', '외국어 연수 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 연수 지원 (공식 채용 사이트 WOORI 인재 글로벌 WOORI 人 항목) — 지원 방식·대상·지원 금액 미기재', 11),
  (@comp_id, 'self_development', '본인 학자금·자격증 취득 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 비용 지원, 본인 학자금 지원 (공식 채용 사이트 WOORI 인재 자기계발제도 항목), 전문대/대학교/대학원 본인 학자금 지원 (공식 채용 사이트 WOORI 복지 본인 대학(원) 지원 항목), 국내 학위과정(대학원, 사이버대학 등) 학자금 지원, 금융/디지털 분야 자격증 취득비용 및 관련 연수 수강 지원 (공식 홈페이지 인재개발제도 비용지원 항목) — 지원 한도·지원 조건 미기재', 12),
  (@comp_id, 'edu_support', '연수포털(WEZ)·취미계발 및 소양 증진 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '우리은행 연수포털(WEZ)를 통해 직무, 자격증 강좌 및 지식 콘텐츠를 제공하여 자기주도 학습 지원 (공식 홈페이지 인재개발제도 연수지원 항목), 취미계발 및 소양 증진 프로그램(테니스, 마라톤, 위스키 도슨트, 쿠킹클래스 등) 진행 (공식 채용 사이트 WOORI 복지 직원만족 프로그램 운영 항목) — 과정 수·수강 조건 미기재', 13),
  -- ── 가족 (family) — 채용 사이트 WOORI 복지 ──
  (@comp_id, 'event', '경조금 지원·행내 예식장', NULL, 'family',
   'est', NULL, TRUE, '본인 및 자녀 결혼, 부모 및 배우자의 부모 회갑·칠순·팔순 등 경조금 지원 (공식 채용 사이트 WOORI 복지 각종 경조금 지원 항목), 행내 예식장 운영, 본인 및 자녀 예식장 무료 이용 (공식 채용 사이트 WOORI 복지 직장어린이집, 행내 예식장 운영 항목) — 경조금액·경조휴가 미기재', 20),
  (@comp_id, 'parenting', '출산 축하금·출산 축하 물품', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금 중 출산 시 자녀 1인당 5백만 원 지급 및 출산 축하 물품 배송 (공식 채용 사이트 WOORI 복지 각종 경조금 지원 항목), 재채용조건부 육아퇴직 (2025 ESG보고서 81쪽 이직률 주석 항목) — 축하 물품 구성·육아퇴직 기간·재채용 조건 미기재', 21),
  (@comp_id, 'child_edu', '자녀 학자금·도서비 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀 학자금 총 900만 원 및 도서비 총 60만 원 지급, 국내외 대학교 학자금 지원 (공식 채용 사이트 WOORI 복지 자녀 학자금 및 도서비 지원 항목) — 지급 기간·대학교 학자금 한도 미기재', 22),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 운영 (공식 채용 사이트 WOORI 복지 직장어린이집, 행내 예식장 운영 항목) — 어린이집 위치·정원 미기재', 23),
  -- ── 생활·편의 (perks) — 채용 사이트 WOORI 복지 ──
  (@comp_id, 'birthday_gift', '생일·결혼기념일 축하 꿀머니', NULL, 'perks',
   'est', NULL, TRUE, '본인 생일 및 결혼기념일 축하 꿀머니 지급 (공식 채용 사이트 WOORI 복지 각종 경조금 지원 항목) — 지급액·사용처 미기재', 30),
  (@comp_id, 'welfare_point', '복지 포인트', 600, 'perks',
   'est', '복지 포인트 매월 50만 원 지급, 연 600만 원 상당 (공식 채용 사이트 WOORI 복지 복지 포인트 항목) — 사용처 미기재', FALSE, NULL, 31),
  -- ── 여가 (leisure) — 채용 사이트 WOORI 복지 ──
  (@comp_id, 'resort', '콘도 및 휴양소 운영', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 휴양소 운영, 롯데시그니엘, 그랜드하얏트, 파라다이스시티, 인스파이어, 파크하얏트, 아난티제주 등 (공식 채용 사이트 WOORI 복지 콘도 및 휴양소 운영 항목) — 이용 기준·비용 지원 범위 미기재', 40),
  (@comp_id, 'company_event', '직원만족 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '뮤지컬, 스포츠 공연(뮤지컬, 프로야구 등) 관람, 체험 및 여행 프로그램(농촌 생활 체험, 스키/보드 캠프 등) 운영 (공식 채용 사이트 WOORI 복지 직원만족 프로그램 운영 항목) — 운영 횟수·참여 대상·비용 부담 미기재', 41),
  (@comp_id, 'travel_support', '해외 문화 체험 비용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '호텔, 항공권 등 인당 3백만 원 비용 지원(추첨자 한정) (공식 채용 사이트 WOORI 복지 해외 문화 체험 비용 지원 항목) — 추첨 인원·시행 주기 미기재', 42),
  -- ── 휴가 (time_off) — 채용 사이트 WOORI 복지 ──
  (@comp_id, 'birthday_leave', '본인 생일 특별 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 생일 특별 휴가 제공 (공식 채용 사이트 WOORI 복지 특별 휴가 제공 항목) — 휴가 일수·유급 여부 미기재', 50),
  (@comp_id, 'leave_general', '특별 휴가·2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '결혼기념일, 건강검진, 이사 청원휴가 등 특별 휴가 제공 (공식 채용 사이트 WOORI 복지 특별 휴가 제공 항목), 2시간 단위 휴가 사용 가능 (공식 채용 사이트 WOORI 복지 유연근무제도, PC-OFF 시스템 항목) — 사유별 휴가 일수 미기재', 51),
  -- ── 건강 (health) — 채용 사이트 WOORI 복지 · 2025 ESG보고서 ──
  (@comp_id, 'health_check', '본인·가족 건강검진·예방접종 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 건강검진 비용 지원, 예방접종(독감, 대상포진 등) 비용 지원 (공식 채용 사이트 WOORI 복지 임직원 건강검진, 의료비 지원 항목) — 검진 주기·지원 한도 미기재', 60),
  (@comp_id, 'medical', '본인 및 가족 의료비 보조', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 의료비 보조 (공식 채용 사이트 WOORI 복지 임직원 건강검진, 의료비 지원 항목) — 지원 한도·대상 범위 미기재', 61),
  (@comp_id, 'insurance', '단체상해보험 (치아보험 등)', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험(치아보험 등)으로 치료비 지원 (공식 채용 사이트 WOORI 복지 임직원 건강검진, 의료비 지원 항목) — 보장 범위·보험료 부담 미기재', 62),
  (@comp_id, 'mental', '심리상담·외부 상담 지원', NULL, 'health',
   'est', NULL, TRUE, '전문 상담사를 통한 1:1 대면 심리상담 및 심리검사 실시, 본인 및 가족 외부 상담(직무 스트레스, 가정/양육, 법률/재무) 지원 (공식 채용 사이트 WOORI 복지 상담 지원 서비스 항목), 근로자 지원 프로그램 (2025 ESG보고서 68쪽 인권경영 고충처리 임직원 채널 항목) — 상담 횟수·비용 지원 범위 미기재', 63),
  -- ── 근무 유연성 (flexibility) — 채용 사이트 WOORI 복지 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제도 (출근시간 자율선택)', NULL, 'flexibility',
   'est', NULL, TRUE, '일과 가정의 균형을 위한 출근시간(8:00 ~ 10:30) 자율선택 (공식 채용 사이트 WOORI 복지 유연근무제도, PC-OFF 시스템 항목), 시차출퇴근제 사용자 수 2026년 반기 10,816명 · 2025년 12,557명 (2026 반기보고서 유연근무제도 사용현황 항목) — 적용 대상·사용 조건 미기재', 70),
  (@comp_id, 'pc_off', 'PC-OFF 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC 사용시간에 따른 PC 차단 기능 도입 (공식 채용 사이트 WOORI 복지 유연근무제도, PC-OFF 시스템 항목) — 차단 시각 미기재', 71),
  -- ── 보상 (compensation) — 홈페이지 인재개발제도 ──
  (@comp_id, 'excellence_award', 'HRD 시상제도', NULL, 'compensation',
   'est', NULL, TRUE, '직무역량 인증과정(WLT) 우수직원, 우리 엘리트(Elite) 등 자기주도학습 문화 조성을 위한 다양한 시상 제도 운영 (공식 홈페이지 인재개발제도 HRD 시상제도 항목) — 포상 내용·선정 인원 미기재', 80),
  (@comp_id, 'incentive', '현금 성과급 (관리직)', NULL, 'compensation',
   'est', NULL, TRUE, '관리직 평균 보상(기본급+현금 성과급), 기본급 외 현금으로 지급되는 모든 인센티브 (2025 ESG보고서 82쪽 보수 지표 항목) — 지급 기준·지급률·비관리직 적용 여부 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
