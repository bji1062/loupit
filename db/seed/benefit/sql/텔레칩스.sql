-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 텔레칩스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: https://www.telechips.com/view/sustainability/esg02/
-- badge: est
--
-- 참고:
--   주 근거는 법인 공식 채용 사이트(careers.telechips.com — 자기 도메인 www.telechips.com 헤더 메뉴 CAREERS 링크)의
--     Culture and Life 복리후생 본문이다. 자동 수집기는 robots.txt 부터 Vercel 보안 확인 화면이라 읽지 못했고(우회 안 함),
--     브라우저로 페이지를 열어 붙여 넣은 화면 본문을 근거로 썼다
--     (사본 telechips/user_paste_careers_2026-10-04.txt · sha256 21365fc0…ae8d). 5구역 21항목.
--   보조: 자기 도메인 SUSTAINABILITY 의 LABOR and HUMAN RIGHTS 페이지(/view/sustainability/esg02/, Nuxt SPA — 헤드리스 렌더로
--     가시 텍스트 확인) 조직문화 슬라이드 3개 — 장기근속 포상 · 동호회 · Hof Day · 경조사 · 입학 선물 · 명절 선물 · 생일 선물 · 독감 예방주사.
--     같은 사이트 SUSTAINABILITY MANAGEMENT 페이지 UN SDGs 카드 — 임직원 및 가족 대상 건강검진.
--   보조: OpenDART 2025 사업보고서(접수 20260323001001) · 2026 반기보고서(접수 20260814001756).
--     유연근무제도 사용 현황 주석(전 직원 선택근무제 · 필요에 따라 재택근무) — flex_work · remote_work 근거.
--     별도재무제표 주석 충당부채(종업원에게 지급하게 될 성과급) — incentive 근거. 주주 현황 우리사주조합 한 칸은 행 근거로 쓰지 않았다.
--   귀속: 법인 채용 사이트 · 법인 자기 도메인 · 법인 공시만. 그룹 각주 없음. 직원 489명(2025 사업보고서) — 재취업지원 의무 대상 아님.
--   제외: 리더십 교육 지원(회사 주도 교육 과정) · 업계 최고 수준의 임금정책(급여) · 자율복장제도(맞는 코드 없음).
--   금액: 원문 연 금액 0(주택 취득 자금 최대 3천만원은 대출 한도). 구본 추정 승계 2(health_check 100 · insurance 30 — 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행: profit_sharing. 재코딩 0. 신규 코드 0.
--   SORT 섹션 순서 = 채용 사이트 본문에서 카테고리가 처음 나온 순서, 채용 사이트에 없는 카테고리는 끝
--     (work_env 10 · growth 20 · flexibility 30 · time_off 40 · leisure 50 · perks 60 · health 70 · family 80 · compensation 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): health_check 이름과 NOTE 에 공식 홈페이지 SUSTAINABILITY MANAGEMENT 페이지의 임직원 및 가족 대상 건강검진을 보탬 · 주주 현황 표 한 칸뿐인 stock_option 행을 뺌 — 19행
-- 붙여넣기 반영(2026-10-04): 공식 채용 사이트 복리후생 본문으로 정본을 옮기고 10행을 그 문장으로 고침 · 새 행 7 — 최종 26행
-- 증분 검증(2026-10-04, RV-3-7): refresh_leave 서술에 홈페이지 LABOR and HUMAN RIGHTS 페이지의 정기 유급휴가 문장을 되살리고 유급 미기재 표기를 걷음 — 최종 26행
-- 주 출처: 사용자 붙여넣기 careers.telechips.com 사본(2026-10-04 · sha256 21365fc0…ae8d) — 점검기 429 헛경보로 정본 URL 은 esg02
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 서술 · 이름 수정 2(edu_support · housing_loan) — 최종 27행
-- 코퍼스 정리(2026-10-11 · 수면실 휴게실 경계): 캡슐 수면실·안마의자 nap_room → lounge 재코딩 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('telechips', '텔레칩스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체/자동차칩', 'T', 'https://www.telechips.com/view/sustainability/esg02/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'telechips');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.telechips.com/view/sustainability/esg02/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 채용 사이트 AI-BASED · EFFICIENT WORKING · FINANCIAL AID · FUN OFFICE LIFE ──
  (@comp_id, 'work_tools', 'AI 도구·개인별 AI API 크레딧·업무 장비', NULL, 'work_env',
   'est', NULL, TRUE, '사내 AI Assistant 상시 운영, Claude·ChatGPT·Gemini 등 원하는 AI 도구를 쓸 수 있도록 개인별 AI API Credit 지급, 업무에 필요한 신규 AI Tool 추가 도입 지원 (공식 채용 사이트 복리후생 AI-BASED ENVIRONMENT 항목), 최고급 장비와 소프트웨어 제공 (같은 페이지 EFFICIENT WORKING ENVIRONMENT 항목) — 크레딧 금액·장비 사양 미기재', 10),
  (@comp_id, 'office_furniture', '허먼밀러 의자', NULL, 'work_env',
   'est', NULL, TRUE, '업계 최고 수준의 장비 및 소프트웨어 제공, 허먼밀러 의자를 비롯한 최고급 장비 (공식 채용 사이트 복리후생 EFFICIENT WORKING ENVIRONMENT 항목) — 지급 대상·다른 가구 미기재', 11),
  (@comp_id, 'dormitory', '역세권 사택', NULL, 'work_env',
   'est', NULL, TRUE, '역세권 인근 거주를 위한 사택 지원 (공식 채용 사이트 복리후생 FINANCIAL AID & HEALTHCARE 항목), 사택(기숙사) 지원 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 항목) — 위치·입주 대상·본인 부담 미기재', 12),
  (@comp_id, 'lounge', '캡슐 수면실·안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '재충전을 위한 캡슐 수면실 및 안마의자 운영 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목), 사내 휴식공간 제공 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 항목) — 이용 시간·좌석 수 미기재', 13),

  -- ── 성장·교육 (growth) — 채용 사이트 AI-BASED · CAREER DEVELOPMENT ──
  (@comp_id, 'conference', '외부 교육·세미나·AI 컨퍼런스 참가 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부 교육 및 세미나 참가 비용 전액 지원 (공식 채용 사이트 복리후생 CAREER DEVELOPMENT 항목), 최신 AI 트렌드를 배울 수 있는 AI 컨퍼런스 참가 지원 (같은 페이지 AI-BASED ENVIRONMENT 항목) — 연간 한도·대상 과정 미기재', 20),
  (@comp_id, 'edu_support', '직무교육 이러닝 전액 지원·이러닝/북러닝 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무 역량 강화를 위한 이러닝 비용 전액 지원 (공식 채용 사이트 복리후생 CAREER DEVELOPMENT 항목), 기존 재직자 대상 이러닝/북러닝 교육 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 인재육성 항목) — 대상 과정·연간 한도 미기재', 21),
  (@comp_id, 'books', '사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, '임직원 자기계발을 위한 사내 도서관 운영 (공식 채용 사이트 복리후생 CAREER DEVELOPMENT 항목) — 장서 규모·도서 구입비 지원 여부 미기재', 22),
  (@comp_id, 'lang', '전화 외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '기존 재직자 대상 전화 외국어 교육 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 인재육성 항목) — 대상 언어·비용 부담·수강 조건 미기재', 23),

  -- ── 근무 유연성 (flexibility) — 채용 사이트 EFFICIENT WORKING · 사업보고서 ──
  (@comp_id, 'flex_work', '완전 선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '완전 선택적 근로시간제(자유로운 출퇴근 시간) (공식 채용 사이트 복리후생 EFFICIENT WORKING ENVIRONMENT 항목), 전 직원 선택근무제 시행 (2025 사업보고서 유연근무제도 사용 현황 주석) — 정산 기간·의무 근무시간대 미기재', 30),
  (@comp_id, 'remote_work', '재택근무 (필요 시)', NULL, 'flexibility',
   'est', NULL, TRUE, '필요에 따라 재택근무 운영 (2025 사업보고서·2026 반기보고서 유연근무제도 사용 현황 주석) — 적용 대상·사용 횟수 미기재', 31),

  -- ── 시간·휴가 (time_off) — 채용 사이트 EFFICIENT WORKING · LABOR & HUMAN RIGHTS ──
  (@comp_id, 'refresh_leave', '정기휴가 5일 추가', NULL, 'time_off',
   'est', NULL, TRUE, '1년마다 자유롭게 사용 가능한 5일의 정기휴가 추가 지급 (공식 채용 사이트 복리후생 EFFICIENT WORKING ENVIRONMENT 항목), 정기 유급휴가 5일 추가 제공 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 항목) — 이월 여부 미기재', 40),
  (@comp_id, 'long_service_leave', '장기근속 포상 (휴가·휴가비·포상금·순금 명함)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 (휴가, 휴가비, 포상금, 순금 명함) (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 WORK-LIFE BALANCE 항목) — 근속 연수 기준·휴가 일수·포상금 금액 미기재', 41),

  -- ── 여가·라이프 (leisure) — 채용 사이트 EFFICIENT WORKING · LABOR & HUMAN RIGHTS ──
  (@comp_id, 'resort', '프리미엄 콘도·호텔 지원', NULL, 'leisure',
   'est', NULL, TRUE, '프리미엄 콘도 및 호텔 이용 지원 (공식 채용 사이트 복리후생 EFFICIENT WORKING ENVIRONMENT 항목) — 시설 이름·지원 한도·이용 횟수 미기재', 50),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 fun-office life 항목) — 활동비 금액·동호회 종류 미기재', 51),
  (@comp_id, 'company_event', 'Hof Day·케이터링 서비스', NULL, 'leisure',
   'est', NULL, TRUE, 'Hof Day & Catering 서비스 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 fun-office life 항목) — 개최 주기·대상 미기재', 52),

  -- ── 경제적 부가혜택 (perks) — 채용 사이트 FINANCIAL AID · FUN OFFICE LIFE ──
  (@comp_id, 'commute_subsidy', '서울·수도권 거점 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '서울 및 수도권 주요 거점 출퇴근 셔틀버스 운영 (공식 채용 사이트 복리후생 FINANCIAL AID & HEALTHCARE 항목) — 노선·운행 횟수 미기재', 60),
  (@comp_id, 'housing_loan', '무이자 주택 취득 자금 대출 (최대 3천만원)', NULL, 'perks',
   'est', NULL, TRUE, '무이자/저금리 사내대출 제도 운영, 최대 3천만원까지 무이자로 주택 취득 자금 지원 (공식 채용 사이트 복리후생 FINANCIAL AID & HEALTHCARE 항목), 사원대여금 제도 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 financial aid 항목) — 상환 기간·대상 조건·저금리 대출 용도 미기재', 61),
  (@comp_id, 'meal', '구내식당 조식·중식·석식 무료', 864, 'perks',
   'est', '구내식당 조식/중식/석식 무료 제공, 삼시세끼 무료 지원 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목) — 사업장 범위·운영 시간 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 62),
  (@comp_id, 'snack_bar', '사내 카페 (바리스타 상주)·임직원 혜택가', NULL, 'perks',
   'est', NULL, TRUE, '바리스타 상주 사내 카페 및 임직원 혜택가 운영 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목) — 이용 요금·운영 시간 미기재', 63),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일자 선물제공 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 fun-office life 항목) — 선물 품목·금액 미기재', 64),

  -- ── 건강·의료 (health) — 채용 사이트 FINANCIAL AID · FUN OFFICE LIFE ──
  (@comp_id, 'insurance', '임직원 단체보험', 30, 'health',
   'est', '사고에 대한 경제적 손실 최소화를 위한 임직원 단체보험 지원 (공식 채용 사이트 복리후생 FINANCIAL AID & HEALTHCARE 항목) — 보장 범위·가족 포함 여부 미기재 (추정)', FALSE, NULL, 70),
  (@comp_id, 'health_check', '임직원 종합검진·가족 건강검진·독감 예방접종', 100, 'health',
   'est', '종합검진 지원, 최고의 시설에서 받는 구성원 건강검진 지원 (공식 채용 사이트 복리후생 항목), 독감 예방주사 지원 (홈페이지 LABOR & HUMAN RIGHTS 페이지), 임직원 및 가족 대상 건강검진 (SUSTAINABILITY MANAGEMENT 페이지) — 비용 한도 미기재 (추정)', FALSE, NULL, 71),
  (@comp_id, 'fitness', '사내 헬스장·무료 PT 클래스', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 자유 이용 및 무료 PT 클래스 운영 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목) — 운영 시간·PT 횟수 미기재', 72),

  -- ── 가족·돌봄 (family) — LABOR & HUMAN RIGHTS 조직문화 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 WORK-LIFE BALANCE 항목) — 경조금 금액·경조 범위 미기재', 80),
  (@comp_id, 'parenting', '자녀 초등학교 입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '초등학교입학 축하 선물 제공 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 WORK-LIFE BALANCE 항목) — 선물 품목·금액 미기재', 81),

  -- ── 보상 (compensation) — LABOR & HUMAN RIGHTS 조직문화 · 사업보고서 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 제공 (공식 홈페이지 LABOR & HUMAN RIGHTS 페이지 조직문화 WORK-LIFE BALANCE 항목) — 선물 품목·금액 미기재', 90),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '종업원에게 지급하게 될 성과급을 충당부채로 계상 (2025 사업보고서 별도재무제표 주석 충당부채 항목) — 지급 기준·지급률·지급 시기 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
