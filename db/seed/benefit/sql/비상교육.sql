-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 비상교육 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://www.visang.com/pageLoad?page_id=/kr/people/hrm
-- badge: est
--
-- 참고:
--   정본은 KOSPI 상장 법인 (주)비상교육(종목 100220)의 자기 도메인 www.visang.com 비상의 사람 > 인사제도 페이지다.
--   SSR 이라 원본 HTML 에 동기부여를 위한 보상(기본급 · 인사평가 가산금 · 경영성과급 · 우리사주제 · 기타)과
--   복지제도 9구분 목록(li strong 구분 + p 항목)이 다 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처: 같은 도메인 비상의 문화 페이지(비바 힐링 안마 서비스) ·
--   OpenDART 2026 반기보고서(접수 20260814002214 — 유연근무제도 사용 현황 표 · 재무제표 주석 임직원 대여금) ·
--   2025 사업보고서 기재정정(접수 20260625000299 — 유연근무 표 같은 문구 · 재무제표 주석 장기종업원급여 5 · 10 · 15 · 20년).
--   채용 사이트 career.visang.com 은 Vercel 보안 확인 화면(429)이라 받지 못했고 visang.recruiter.co.kr 은 본문 없는 셸.
--   귀속: 페이지 주어가 비상 · 비상교육 단수이고 그룹 · 계열사 단서 없음 — 각주 없음. 기등록 형제 없음.
--   금액: 원문 원 단위 숫자는 교육비상문화비 연 최대 120만원 하나 — 한도라 NULL. 전 행 BENEFIT_AMT NULL.
--   제외: 법정(4대 보험 · 연차 반차 · 보건 · 산전 산후 · 공가 · 육아휴직 · 출산휴가 유급 남성 10일(법정 20일 미만) ·
--     임직원정기건강검진 · 직무발명 보상제) · 기본급 · 기타(교육적 보상 · 직무 전환 — 내용 없음) ·
--     VIVA AM(내용 미상) · 업무 교육(리더십 교육체계 · 입문 · OJT · 직무역량 · 사내 학점제도) ·
--     자기주식 임직원 성과급 지급 예정(예정 문장) · 문화 페이지 간식어택 · 매칭그랜트.
--   공고 근거 0행 / 전체 27행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · family 20 · perks 30 · time_off 40 · work_env 50 ·
--     health 60 · leisure 70 · growth 80), 공시에만 있는 flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-20): 프랭클린플래너 work_tools 행 삭제(대응 코드 없음 · 근무 환경 섹션 머리 주석에서 기타 걷음) · 임직원정기건강검진을 health_check 이름과 서술에 병합(감사 · 정기 건강검진 라벨은 법정 검진 이름이 아님) · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록 제외 줄의 임직원정기건강검진은 이 판정으로 뒤집힘 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('visang_edu', '비상교육',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '교육', 'V', 'https://www.visang.com/pageLoad?page_id=/kr/people/hrm');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'visang_edu');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.visang.com/pageLoad?page_id=/kr/people/hrm'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 인사제도 동기부여를 위한 보상 · 복지제도 경조사 기념일 · 포상 · 2026 반기보고서 · 2025 사업보고서 ──
  (@comp_id, 'incentive', '인사평가 가산금', NULL, 'compensation',
   'est', NULL, TRUE, '업무 몰입도를 높이기 위한 성과급으로 조직의 성과 및 인사평가 결과에 따라 차등 지급 (공식 홈페이지 인사제도 동기부여를 위한 보상 항목) — 지급률·지급 시기 미기재', 10),
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '연봉에 포함되지 않는 성과보너스로 회사의 성과에 따라 이익을 나누는 제도 (공식 홈페이지 인사제도 동기부여를 위한 보상 항목) — 지급 기준·지급률 미기재', 11),
  (@comp_id, 'stock_option', '우리사주제', NULL, 'compensation',
   'est', NULL, TRUE, '회사와 조직원 공통으로 출연 조성된 기금, 기업 경영성 제고와 직원의 재산 형성 목적 (공식 홈페이지 인사제도 동기부여를 위한 보상 항목), 임직원에 대한 우리사주 취득자금 대출 (2026 반기보고서 재무제표 주석 특수관계자 거래 항목) — 출연 비율·대출 한도·이율 미기재', 12),
  (@comp_id, 'holiday_gift', '명절선물 · 근로자의 날 축하금', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물, 근로자의 날 축하금 (공식 홈페이지 인사제도 복지제도 경조사, 기념일 항목) — 선물 품목·축하금 금액 미기재', 13),
  (@comp_id, 'long_service_bonus', '근속포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속포상 (공식 홈페이지 인사제도 복지제도 포상 항목), 장기근속임직원에게 장기종업원급여 제공, 5년, 10년, 15년, 20년 이상의 장기간 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 급부 형태·금액 미기재', 14),
  (@comp_id, 'excellence_award', '우수사원 포상 · 프로젝트 성과 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상, 프로젝트 성과 포상 (공식 홈페이지 인사제도 복지제도 포상 항목) — 포상 기준·포상 내용 미기재', 15),

  -- ── 가족 (family) — 복지제도 경조사 기념일 ──
  (@comp_id, 'event', '경조휴가 · 경조금 · 경조화환', NULL, 'family',
   'est', NULL, TRUE, '경조휴가, 경조금, 경조화환 (공식 홈페이지 인사제도 복지제도 경조사, 기념일 항목) — 경조 범위·휴가 일수·금액 미기재', 20),

  -- ── 생활 · 금융 (perks) — 복지제도 경조사 기념일 · 업무보조 직원 · 사원 대출제 · 2026 반기보고서 ──
  (@comp_id, 'birthday_gift', '생일문화상품권', NULL, 'perks',
   'est', NULL, TRUE, '생일문화상품권 (공식 홈페이지 인사제도 복지제도 경조사, 기념일 항목) — 상품권 금액 미기재', 30),
  (@comp_id, 'transport', '사내교통비', NULL, 'perks',
   'est', NULL, TRUE, '사내교통비 (공식 홈페이지 인사제도 복지제도 업무보조, 직원 항목) — 지급 대상·금액 미기재', 31),
  (@comp_id, 'telecom', '통신비', NULL, 'perks',
   'est', NULL, TRUE, '통신비 (공식 홈페이지 인사제도 복지제도 업무보조, 직원 항목) — 지원 대상·금액 미기재', 32),
  (@comp_id, 'meal', '야근식대', NULL, 'perks',
   'est', NULL, TRUE, '야근식대 (공식 홈페이지 인사제도 복지제도 업무보조, 직원 항목) — 지원 기준·금액 미기재', 33),
  (@comp_id, 'team_dinner', '부서운영비', NULL, 'perks',
   'est', NULL, TRUE, '부서운영비 (공식 홈페이지 인사제도 복지제도 업무보조, 직원 항목) — 용도·금액 미기재', 34),
  (@comp_id, 'housing_loan', '주택자금대출 (구입 및 전세대금 대출)', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출(구입 및 전세대금 대출) (공식 홈페이지 인사제도 복지제도 사원 대출제 항목), 임직원에 대한 주택구입 및 전세자금 대출 (2026 반기보고서 재무제표 주석 특수관계자 거래 항목) — 대출 한도·이율 미기재', 35),
  (@comp_id, 'welfare_fund_loan', '긴급자금대출', NULL, 'perks',
   'est', NULL, TRUE, '긴급자금대출 (공식 홈페이지 인사제도 복지제도 사원 대출제 항목) — 대출 요건·한도·이율 미기재', 36),

  -- ── 휴가 (time_off) — 복지제도 휴가 휴직 ──
  (@comp_id, 'leave_general', '병가 · 특별휴가(교육) · 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '병가, 특별휴가(교육), 포상휴가 (공식 홈페이지 인사제도 복지제도 휴가, 휴직 항목) — 휴가 일수·유급 여부·부여 조건 미기재', 40),
  (@comp_id, 'refresh_leave', '안식 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '안식 휴가제 (공식 홈페이지 인사제도 복지제도 휴가, 휴직 항목) — 휴가 일수·부여 조건 미기재', 41),

  -- ── 근무 환경 (work_env) — 복지제도 업무보조 직원 ──
  (@comp_id, 'parking', '주차권', NULL, 'work_env',
   'est', NULL, TRUE, '주차권 (공식 홈페이지 인사제도 복지제도 업무보조, 직원 항목) — 지원 대상·지원 범위 미기재', 50),

  -- ── 건강 (health) — 복지제도 건강관리 · 비상의 문화 ──
  (@comp_id, 'health_check', '정기 건강검진·특별 건강 검진비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원정기건강검진, 특별 건강 검진비 지원 (공식 홈페이지 인사제도 복지제도 건강관리 항목) — 검진 주기·지원 금액·대상 미기재', 60),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 (공식 홈페이지 인사제도 복지제도 건강관리 항목) — 보장 내용·가입 대상 미기재', 61),
  (@comp_id, 'massage', '비바 힐링 안마 서비스', NULL, 'health',
   'est', NULL, TRUE, '시각장애인 전문 안마사 4명이 전문 헬스 키퍼로 상주하여 근무 시간에 피로를 풀어주는 안마 서비스인 비바 힐링 제도 운영 (공식 홈페이지 비상의 문화 휴식이 필요할 땐 비바 힐링 항목) — 이용 횟수·이용 시간 미기재', 62),

  -- ── 여가 (leisure) — 복지제도 커뮤니케이션 활성화 ──
  (@comp_id, 'company_event', '체육대회 · 창립기념일 행사 · 야유회', NULL, 'leisure',
   'est', NULL, TRUE, '체육대회, 창립기념일 행사, 야유회 (공식 홈페이지 인사제도 복지제도 커뮤니케이션 활성화 항목) — 개최 주기·참여 대상 미기재', 70),
  (@comp_id, 'club', '사내동호회지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회지원 (공식 홈페이지 인사제도 복지제도 커뮤니케이션 활성화 항목) — 지원 금액·동호회 종류 미기재', 71),
  (@comp_id, 'resort', '콘도이용권 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도이용권 지원 (공식 홈페이지 인사제도 복지제도 커뮤니케이션 활성화 항목) — 이용 횟수·지원 범위 미기재', 72),

  -- ── 성장 (growth) — 복지제도 기타 ──
  (@comp_id, 'self_development', '교육비상문화비 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육비상문화비 연 최대 120만원 지원 (공식 홈페이지 인사제도 복지제도 기타 항목) — 사용 범위·지급 방식 미기재', 80),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 사용자 수 전직원, 전직원에 대해 시차출퇴근제 시행 중 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·운영 방식 미기재', 90),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 전직원, 전직원에 대해 원격근무제 시행 중 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 근무 일수·사용 조건 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
