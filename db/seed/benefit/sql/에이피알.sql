-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에이피알 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://apr-careers.com/benefit
-- badge: est
--
-- 참고:
--   정본은 회사 공식 홈 www.apr-in.com 의 GNB 채용정보 링크가 가리키는 회사 채용 도메인 apr-careers.com 의
--   Benefit 페이지(/benefit)다. 채용 사이트 상단 메뉴 Main · Culture · Benefit · Jobs · FAQ · Blog 의 Benefit 이다.
--   APR Benefits 한 섹션에 8개 블록(Performance Benefits · Work Time and Refresh · Brand Experience ·
--   Meal and Refreshments · Growing Up · Wellness and Health · Family · Maternity)이 SSR HTML 본문으로 나온다 —
--   헤드리스 렌더 불필요. HTML 주석 0 · template 0. 페이지 말미 주의문 = 복리후생은 근무지 및 고용 형태에 따라 차이가 있을 수 있다.
--   robots: apr-careers.com 은 User-agent: * 묶음에서 /api · /admin 등만 막고 /benefit 은 허용. www.apr-in.com 은 전면 허용.
--   보조 출처(같은 회사 자기 도메인): www.apr-in.com/social_people.html ESG Social 페이지의 임직원을 위한 차별화된
--   복리후생 문단 — 회식비 · 생일 축하 휴가 및 선물 두 행은 이 문단에서만 나온다.
--   사이트 빌더 데이터(__NEXT_DATA__)에 메뉴에 없는 옛 · 초안 · 신규입사자 안내 페이지 본문이 함께 실려 온다.
--   그 페이지들은 행 근거로 쓰지 않았다(메뉴 · 사이트맵에 없음). 구본 문구는 그중 Culture-sketch 초안 페이지와 같다.
--
--   금액: 명시값 3행(health_check 15 · welfare_point 100 · meal 240 환산). 승계 추정치 1행(insurance 30 — NOTE 끝 추정).
--     구본 공식 수치 4개 가운데 wedding 100 · welcome_kit 100 은 1회성, books 36 은 월 한도라 금액 칸에서 뺐고
--     meal 180 은 원문 월 20만원으로 바뀌었다.
--   재코딩 없음. 구본에서 뺀 행: pc_off · wedding(경조사 행에 흡수) · career 멘토링(같은 코드로 사내공모제도 행 신설).
--   제외: 법정 제도(출산 전후 90일 · 배우자 출산 20일 · 임신기 단축 근무 · 육아 휴직 · 태아 검진 시간) ·
--     온보딩 프로그램(멘토링 · 버디 · 신입 교육) · 온보딩 기간 자사 제품 체험 · Udemy 온라인 강의 플랫폼 · OKR · 1:1 미팅.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (compensation 10 · flexibility 20 · time_off 30 · leisure 40 · perks 50 · growth 60 · health 70 · work_env 80 · family 90).
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3 레인 5): discount 행 추가(자사 브랜드 상시 40~50% 할인 — 복지몰 라벨의 두 혜택 분리) · welfare_point NOTE 에 포인트 단위 환산 표기 — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('apr', '에이피알',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '뷰티/화장품', 'A', 'https://apr-careers.com/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'apr');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://apr-careers.com/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과 인센티브 (Performance Incentive)', NULL, 'compensation',
   'est', NULL, TRUE, '조직별·개인별 OKR 평가에 따른 성과급 연 2회 지급 (공식 채용 페이지 Benefit의 Performance Benefits 항목 — 지급률·산정 기준 미기재)', 10),
  (@comp_id, 'profit_sharing', 'Profit Sharing', NULL, 'compensation',
   'est', NULL, TRUE, '영업 이익에 대한 전사 임직원 보상 연 1회 지급 (공식 채용 페이지 Benefit의 Performance Benefits 항목 — 산정 기준·지급률 미기재)', 11),
  (@comp_id, 'excellence_award', '우수사원 시상·사내추천 리워드', NULL, 'compensation',
   'est', NULL, TRUE, '매월 인재상별 우수사원 선정, 백화점상품권 및 휴가 지급. 사내추천제도로 추천한 지원자 입사 시 추천인과 피추천인에게 리워드 합산 최대 700만원 (공식 채용 페이지 Benefit의 Growing Up 항목 — 상품권 금액·휴가 일수 미기재)', 12),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설과 추석 명절 선물세트 지급 (공식 채용 페이지 Benefit의 Family 항목 — 선물 내용 미기재)', 13),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '시차 출퇴근제도', NULL, 'flexibility',
   'est', NULL, TRUE, '매일 오전 8시~11시 사이 출근시간 30분 단위 자율 설정 (공식 채용 페이지 Benefit의 Work Time and Refresh 항목)', 20),
  (@comp_id, 'family_day', '패밀리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 마지막 주 금요일 2시간 조기 퇴근 (공식 채용 페이지 Benefit의 Family 항목)', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '셀프 승인 휴가·2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '별도 승인 절차 없이 쓰는 셀프 승인 휴가, 2시간 단위 휴가 분할 사용 (공식 채용 페이지 Benefit의 Work Time and Refresh 항목)', 30),
  (@comp_id, 'long_service_leave', '리프레시 휴가 (3/6/9년)', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속자 대상, 근속 3·6·9년마다 3·6·9일의 별도 리프레시 휴가 (공식 채용 페이지 Benefit의 Work Time and Refresh 항목)', 31),
  (@comp_id, 'birthday_leave', '생일 축하 휴가·선물', NULL, 'time_off',
   'est', NULL, TRUE, '생일 축하 휴가 및 선물 (공식 홈페이지 ESG Social 페이지의 임직원을 위한 차별화된 복리후생 항목 — 휴가 시간·선물 내용 미기재)', 32),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '입사 웰컴 기프트', NULL, 'leisure',
   'est', NULL, TRUE, '입사 시 총 100만원 상당의 다양한 자사 브랜드 제품 패키지 배송 (공식 채용 페이지 Benefit의 Brand Experience 항목 — 입사 시 1회)', 40),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '임직원 전용 복지몰 포인트', 100, 'perks',
   'est', '임직원 전용 복지몰 적립금 연간 100만 포인트 별도 지급, 재직 기간에 따라 상향 (공식 채용 페이지 Benefit의 Brand Experience 항목 — 1포인트 1원 기준 환산)', FALSE, NULL, 50),
  (@comp_id, 'snack_bar', '사내 카페·무제한 스낵바', NULL, 'perks',
   'est', NULL, TRUE, '전문 바리스타 커피와 20가지 이상 시즌별 음료를 무제한 무료로 이용하는 사내 카페(Peak Coffee), 아침·점심·저녁 식사 대용 간편 음식과 음료·스낵 매일 무료 제공 (공식 채용 페이지 Benefit의 Meal and Refreshments 항목)', 51),
  (@comp_id, 'meal', '점심 식사 지원 (식권 포인트)', 240, 'perks',
   'est', '오피스 인근 식당·카페에서 쓰는 식권 포인트 월 20만원 별도 지급, 연 240만원 환산 (공식 채용 페이지 Benefit의 Meal and Refreshments 항목)', FALSE, NULL, 52),
  (@comp_id, 'team_dinner', '회식비', NULL, 'perks',
   'est', NULL, TRUE, '현금성 복지로 회식비 제공 (공식 홈페이지 ESG Social 페이지의 임직원을 위한 차별화된 복리후생 항목 — 지원 금액·주기 미기재)', 53),
  (@comp_id, 'discount', '자사 브랜드 제품 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 복지몰에서 모든 자사 브랜드 제품 상시 40~50% 할인 (공식 채용 페이지 Benefit의 Brand Experience 항목)', 54),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'conference', '외부 교육 및 연수', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 컨퍼런스·포럼 등 참석 시 참가비 전액 지원 (공식 채용 페이지 Benefit의 Growing Up 항목)', 60),
  (@comp_id, 'career', '사내공모제도', NULL, 'growth',
   'est', NULL, TRUE, '사내공모 대상 포지션 공지, 다른 부서로 이동하는 성장 기회 제공 (공식 채용 페이지 Benefit의 Growing Up 항목)', 61),
  (@comp_id, 'books', '도서구매비 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 도서 구매비용 매월 3만원 한도 지원 (공식 채용 페이지 Benefit의 Growing Up 항목)', 62),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강 검진', 15, 'health',
   'est', '기업 연계 병원 종합 건강 검진 매년 15만원 상당 무료 지원 (공식 채용 페이지 Benefit의 Wellness and Health 항목)', FALSE, NULL, 70),
  (@comp_id, 'mental', '심리 진단 및 상담 서비스 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '마음의 건강 상태를 정기적으로 점검하는 전문가 심리상담 지원 (공식 채용 페이지 Benefit의 Wellness and Health 항목 — 이용 횟수 미기재)', 71),
  (@comp_id, 'massage', '사내 마사지실·안마의자실', NULL, 'health',
   'est', NULL, TRUE, '전문 마사지사가 상주하는 사내 마사지실 업무시간 내 예약 이용, 안마의자실 운영 (공식 채용 페이지 Benefit의 Wellness and Health 항목)', 72),
  (@comp_id, 'insurance', '본인 및 가족 단체보험', 30, 'health',
   'est', '직원 본인과 가족 보험(진단비 등) 지원 (공식 채용 페이지 Benefit의 Family 항목 — 보장 금액 미기재) (추정)', FALSE, NULL, 73),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택 지원', NULL, 'work_env',
   'est', NULL, TRUE, '신축 사택 무상 지원, 평택 캠퍼스 근무자 한정 (공식 채용 페이지 Benefit의 Wellness and Health 항목)', 80),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 축하금·위로금과 경조 휴가 지급 (공식 채용 페이지 Benefit의 Family 항목 — 금액·일수 미기재)', 90),
  (@comp_id, 'parenting', '출산 축하·보육료 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 시 백화점 상품권 30만원과 과일바구니 지급, 만 0세~5세 어린이집 위탁 보육료 별도 지원 (공식 채용 페이지 Benefit의 Maternity 항목)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
