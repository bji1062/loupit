-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NAVER 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://recruit.navercorp.com/cnts/benefits
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: stock_grant 정성 행 복원(DART 자기주식처분결정 2024·2025) · 인센티브·사내공모 OCC·웰컴키트 추가 · 서비스 이용권 discount 를 leisure_ticket 으로 재코딩 · 붙여쓰면 지원금 문안의 연차를 휴가로
--   정본은 NAVER 공식 채용 사이트 recruit.navercorp.com 의 Benefits 페이지(서버 렌더 HTML, 8절:
--     Financial Wellbeing · Refresh · Work Space · Work Tools · Meal & Snack · Growth · Wellness · Family).
--   보조 출처(같은 호스트): /cnts/wellness(의료비 보험·검진 당일 유급휴가·심리상담 횟수) ·
--     /cnts/culture(Connected Work 2026) · /cnts/workspace(공용공간 목록).
--   보조 출처(회사 IR): www.navercorp.com ESG 자료실의 NAVER 2025 통합보고서 PDF(244쪽, 2026년 6월 이사회 승인,
--     보고 기간 2025-01-01~12-31) — p.108 주식보상 프로그램 · p.109 비임금성 복리후생 표 · p.149~150 임직원 일·생활 지원 제도 표 ·
--     p.205 2025년 이사회 활동 내역.
--   원문 사본은 2026-09-25 공식 출처 대조 때 받은 것을 그대로 썼다(sha256 은 근거표). recruit.navercorp.com robots.txt 는 404(제한 없음),
--     www.navercorp.com robots.txt 는 User-agent: * / Allow: / (2026-09-26 재확인). 헤드리스 렌더 불필요.
--
--   판단 요약(상세는 근거표):
--     - 구본 stock_grant 행은 넘기지 않았다. 통합보고서 p.205 에 2025-01-02 이사회 안건 「Stock Grant 지급을 위한 자사주 처분」이
--       있으나 대상·금액·조건이 공식 출처 어디에도 없고, 같은 보고서 p.108 주식보상 프로그램 목록(스톡옵션 2019~2021 · 주식매입리워드 2020~)과
--       채용 복지 페이지에 Stock Grant 가 없다. 전 직원 대상임을 확인할 수 없어 복지 행으로 세우지 않는다.
--       p.108 스톡옵션(2019~2021, 1년 이상 재직자 매년 1,000만 원 상당)은 종료된 별개 제도라 역시 넣지 않는다.
--     - 재코딩 2: profit_sharing → stock_option(주식 매입 리워드는 자사주 매입 지원이지 이익 배분이 아니다) ·
--       medical → insurance(본인·가족 의료비 보험은 회사 가입 단체보험 상품이다).
--     - 금액: 공식 명시 4행(명절 80 · 개인업무지원비 360 · 어학 240 · Club Greeny 36) + 승계 추정 3행(검진 100 · 리조트 50 · 식사 432, 3식 명시).
--       주식 매입 리워드(매입금액의 10%, 연간 200만 원까지)는 본인 매입이 전제인 비율·상한이라 금액 칸을 비웠다.
--     - 법정 범위(육아기 단축근무 · 가족돌봄 휴직 · 배우자 출산휴가 20일 · 미숙아 출산전후휴가 · 유산·사산 휴가 · 반차)는 넣지 않았다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op, 아래 UPDATE 가 URL 을 채운다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('naver', 'NAVER',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT/포털', 'N', 'https://recruit.navercorp.com/cnts/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.navercorp.com/cnts/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '주식 매입 리워드', NULL, 'compensation',
   'est', NULL, TRUE, '네이버 주식 매입 후 6개월 이상 보유 시 매입금액의 10%를 현금 리워드로 지급, 연간 200만 원 한도 (공식 채용 페이지 Financial Wellbeing 항목 · 2025 통합보고서 주식보상 프로그램, 2020년부터 운영)', 10),
  (@comp_id, 'long_service_bonus', '근속 기념 선물', NULL, 'compensation',
   'est', NULL, TRUE, '근속 10주년, 20주년 선물 및 감사 트로피 지급 (공식 채용 페이지 Growth 항목 · 2025 통합보고서 — 선물 품목·금액 미기재)', 11),
  (@comp_id, 'excellence_award', '사내 시상식 N Awards', NULL, 'compensation',
   'est', NULL, TRUE, '훌륭한 아이디어와 기술 혁신을 선정하여 축하하고 기념하는 사내 시상식 (공식 채용 페이지 Growth 항목 — 포상 내용·금액 미기재)', 12),
  (@comp_id, 'holiday_gift', '명절 선물', 80, 'compensation',
   'est', '설과 추석 총 80만 원 상당의 네이버페이 포인트 지급 (공식 채용 페이지 Family 항목)', FALSE, NULL, 13),
  (@comp_id, 'stock_grant', '주식 지급(Stock Grant)', NULL, 'compensation',
   'est', NULL, TRUE, '보상 경쟁력 강화를 위한 직원 대상 자기주식 지급 — 2024년 1월·2025년 1월 자기주식 처분 결정 (NAVER 주요사항보고서 자기주식처분결정·2025 통합보고서 이사회 안건 — 인당 지급 규모·지급 조건 미공개)', 14),
  (@comp_id, 'incentive', '인센티브(변동보수)', NULL, 'compensation',
   'est', NULL, TRUE, '기본 보수(연봉) 외에 회사의 성과를 함께 나누기 위한 인센티브 제도 운영, 지급 여부와 총 지급 규모는 매년 이사회가 결정하고 개인별 금액은 연말 리뷰 등급과 연계 (2025 통합보고서 인적 자본 관리 보상 항목 — 지급률·평균 금액 미기재)', 15),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 및 생활 자금 마련을 위해 대출금액 이자의 1.5%를 10년간 지원, 대출금액 최대 2억 원까지 (공식 채용 페이지 Financial Wellbeing 항목)', 20),
  (@comp_id, 'meal', '사내 식당·캔틴 (조식·점심·저녁 무료)', 432, 'perks',
   'est', '매일 점심·저녁 무료 사내 식당, 각 층 캔틴의 조식 메뉴(샌드위치·김밥·과일·음료) 무료 (추정)', FALSE, NULL, 21),
  (@comp_id, 'snack_bar', '사내 카페·Lounge 5', NULL, 'perks',
   'est', NULL, TRUE, '네이버 직영 카페(커피·착즙 주스·디저트)와 사옥 내 스타벅스, 외부 식당 브랜드가 입점한 Lounge 5를 임직원 할인가로 이용, 사옥 내 이마트24 편의점 (공식 채용 페이지 Meal & Snack 항목 — 할인율 미기재)', 22),
  (@comp_id, 'commute_subsidy', '사옥-역 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 편의를 위해 정자역과 1784 사옥 간 셔틀버스 운행 (2025 통합보고서 임직원 일·생활 지원 제도 — 운행 시간·횟수 미기재)', 24),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'workation', '워케이션', NULL, 'flexibility',
   'est', NULL, TRUE, '최대 7일간 업무 공간 및 숙박(1인 1실), 식사 등 지원, 임직원 전용 공간 춘천 커넥트원·세종 워크스테이·베이스캠프 도쿄 (공식 채용 페이지 Refresh 항목 — 연간 이용 횟수 미기재)', 30),
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '고정된 출퇴근 시간 없이 평일 6시~22시 사이 자유롭게 출퇴근 (공식 채용 페이지 Culture 의 Connected Work 2026 · 2025 통합보고서 선택적 근로시간제)', 31),
  (@comp_id, 'remote_work', '원격 기반 근무 선택 (Connected Work)', NULL, 'flexibility',
   'est', NULL, TRUE, '연간 단위로 오피스 기반 근무 타입(Type_O)과 원격 기반 근무 타입(Type_R) 중 개인이 자율 선택, 소속 팀 단위 대면 근무 Co-work day 주 1회 (공식 채용 페이지 Culture 의 Connected Work 2026 · 2025 통합보고서)', 32),
  (@comp_id, 'pc_off', '시스템 오프 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '과도한 장시간 근로 예방을 위해 최대 근로 가능 시간 도달 8시간 전 모든 사내 시스템 차단 (2025 통합보고서 임직원 일·생활 지원 제도)', 33),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'summer_vacation_subsidy', '붙여쓰면 지원금 (휴가 연속 사용 시 휴가비)', NULL, 'leisure',
   'est', NULL, TRUE, '휴가를 이틀 이상 붙여 사용하면 1일당 5만 원의 휴가비 지원 (공식 채용 페이지 Refresh 항목 — 연간 지급 한도 미기재)', 40),
  (@comp_id, 'resort', '임직원 전용 휴양시설', 50, 'leisure',
   'est', '회원제로 운영되는 전국 프리미엄 리조트 40여 개, 매달 추첨으로 저렴한 비용에 이용 (추정)', FALSE, NULL, 41),
  (@comp_id, 'club', '사내 커뮤니티 (Club Greeny)', 36, 'leisure',
   'est', '동료들과 자율적으로 관심사를 공유하는 모임 활동비 연간 36만 원 상당 지원 (공식 채용 페이지 Growth 항목)', FALSE, NULL, 42),
  (@comp_id, 'company_event', '오픈새러데이·사내 행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족 및 지인을 사옥에 초대해 네이버의 문화를 함께 경험하는 오픈새러데이, 연말 전사 행사와 외부 초청 강연 (공식 채용 페이지 Family 항목 · 2025 통합보고서 사내 행사 — 운영 횟수 미기재)', 43),
  (@comp_id, 'leisure_ticket', '네이버 서비스 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '네이버페이, 플러스멤버십, 웹툰, VIBE, MYBOX, 지식iN엑스퍼트 등 네이버 서비스 이용권 패키지 지원 (공식 채용 페이지 Growth 항목 · 2025 통합보고서 6종 — 금액 미기재)', 44),
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자에게 웰컴키트 제공 (2025 통합보고서 비임금성 복리후생 신규입사자 온보딩 지원 항목 — 구성품 미기재)', 45),

  -- ── 휴가·휴직 (time_off) ──
  (@comp_id, 'long_service_leave', '리프레시 플러스 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '입사 2년 근속 시 연차 외 추가 유급휴가 15일 부여, 이후 3년마다 리프레시 휴가 (공식 채용 페이지 Refresh 항목 · 2025 통합보고서 — 3년 주기 휴가 일수 미기재)', 50),
  (@comp_id, 'leave_general', '자기돌봄 휴직', NULL, 'time_off',
   'est', NULL, TRUE, '3년 이상 근속 시 자기개발이나 휴식을 위해 최대 6개월까지 무급 휴직 (공식 채용 페이지 Refresh 항목)', 51),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '업무기기 예산', NULL, 'work_env',
   'est', NULL, TRUE, '입사와 함께 권장모델 구입이 가능한 예산 및 매월 추가 예산 지급, 예산 내 노트북·모니터·태블릿 등 자유 선택. 입사 시 최대 360만 원, 월 추가 예산은 직군별 상이 (공식 채용 페이지 Work Tools 항목 · 2025 통합보고서 — 월 추가 예산 금액 미기재)', 60),
  (@comp_id, 'office_furniture', '인체공학적 가구', NULL, 'work_env',
   'est', NULL, TRUE, '인체공학 의자 허먼밀러 에어론 기본 제공, 희망 시 스탠딩 데스크 지원 (공식 채용 페이지 Work Tools 항목)', 61),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '개인업무지원비', 360, 'growth',
   'est', '업무 몰입을 위해 통신비·도서·콘텐츠 구매비·외부 주차비 등에 쓸 수 있는 지원금 연간 360만 원 지급 (공식 채용 페이지 Growth 항목 · 2025 통합보고서)', FALSE, NULL, 70),
  (@comp_id, 'lang', '어학 지원비', 240, 'growth',
   'est', '글로벌 역량을 위해 연간 최대 240만 원의 어학 교육비 지원 (공식 채용 페이지 Growth 항목 · 2025 통합보고서 연간 240만 원 한도)', FALSE, NULL, 71),
  (@comp_id, 'conference', '외부 교육 및 연수', NULL, 'growth',
   'est', NULL, TRUE, '컨퍼런스, 포럼, 학회 등 참석 시 참가비 전액 지원, 업무 관련 온·오프라인 외부 교육 비용 전액 지원 (공식 채용 페이지 Growth 항목 · 2025 통합보고서)', 72),
  (@comp_id, 'career', '사내공모제도 OCC', NULL, 'growth',
   'est', NULL, TRUE, '회사 내 다른 조직으로 이동해 새로운 커리어로 성장할 수 있는 기회를 주는 사내공모제도 OCC(Open Career Chance) (공식 채용 페이지 Growth 항목 — 공모 주기·지원 자격 미기재)', 73),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'insurance', '본인·가족 의료비 보험', NULL, 'health',
   'est', NULL, TRUE, '직원 본인과 가족 대상 의료비 보험 — 실손 의료비, 입원·통원 의료비, 수술비, 암·심장질환·뇌혈관 진단비, 후유장해, 질병·상해 사망 보장. 상해보험은 배우자, 양가 부모, 자녀, 형제·자매까지 (공식 채용 페이지 Wellness 항목·상세 · 2025 통합보고서 — 보장 한도 미기재)', 80),
  (@comp_id, 'clinic', '부속의원 NAVER CARE·24시간 의료 상담', NULL, 'health',
   'est', NULL, TRUE, '전문의 자격 의료진이 상주하는 300평 규모 사내 부속의원에서 건강검진 상담, 물리치료, 수액치료, 만성질환 관리, 예방접종. 365일 24시간 전화 의료 상담·명의 추천·상급 병원 예약 지원 (공식 채용 페이지 Wellness 항목·상세 · 2025 통합보고서)', 81),
  (@comp_id, 'fitness', '사내 운동공간 FITNESS', NULL, 'health',
   'est', NULL, TRUE, '전문 트레이너가 상주하는 250평 규모 사내 운동 공간, 원하는 시간에 자율 이용 (공식 채용 페이지 Wellness 항목 · 2025 통합보고서)', 82),
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '매년 약 90여 개 항목 종합검진, 격년(짝수 해)으로 본인 외 가족 1인 추가, 서울·경기·부산·대구 등 30여 개 지정 병원, 검진 당일 유급휴가 1일 (추정)', FALSE, NULL, 83),
  (@comp_id, 'mental', '심리 상담·심리 건강검진', NULL, 'health',
   'est', NULL, TRUE, '전문 상담 기관 연계 상담 비용 연 10회까지 전액, 10회 이상은 80% 지원, 사옥 내 심리상담센터 운영, 매년 심리 건강검진 (공식 채용 페이지 Wellness 항목·상세 · 2025 통합보고서)', 84),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '네이버 어린이집', NULL, 'family',
   'est', NULL, TRUE, '서울·경기권 5개 지역 직장 어린이집, 오전 7시30분~오후 10시 운영 (공식 채용 페이지 Family 항목 — 정원 미기재)', 90),
  (@comp_id, 'event', '경조사·웨딩 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 환갑~구순, 출산, 장례 등 경조사 휴가 및 경조비 지원, 사옥 내 전망 좋은 공간 무료 예식 지원(1일 1예식) (공식 채용 페이지 Family 항목 — 경조비 금액 미기재)', 91),
  (@comp_id, 'parenting', '육아휴직 2년·임신기 단축근무', NULL, 'family',
   'est', NULL, TRUE, '회사 지원 추가 1년 포함 총 2년 육아휴직, 6개월 이상 휴직 후 복귀 시 리보딩 프로그램과 워킹맘·워킹대디 네트워킹 지원, 임신 전 기간 급여 삭감 없이 일 2시간 단축 근무 (공식 채용 페이지 Family 항목)', 92),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '집중적인 난임 치료가 필요한 경우 추가로 최대 6개월 무급 휴직, 난임 시술비 최대 200만 원 지원 (공식 채용 페이지 Family 항목 — 시술비 지원 주기 미기재)', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
