-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- F&F 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://homepage-static.fnf.co.kr/file_6a7c2dd04350eb.64939586.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜에프앤에프(F&F)가 자기 도메인 www.fnf.co.kr 가치경영 > 지속가능성 목록에 올린
--   F&F Sustainability Report 2026 국문(발행 2026-06 · 보고 기간 2025-01-01~2025-12-31 · 일부 2026 상반기 ·
--   전체 보고 범위 F&F홀딩스와 F&F · 사회 정보 보고 범위 F&F 별도 기준) PDF 116쪽 텍스트 레이어.
--   목록은 SSR 셸 + 키 없는 JSON /api/fo/esg/reports 가 파일 주소를 준다. 렌더 · 이미지 판독 불필요.
--   근거 쪽: 49쪽 공정한 성과평가 및 보상 · 임직원 역량 개발 · 50쪽 복리후생(모성보호 · 일과 삶의 균형 · 건강 관리 ·
--   출산·육아 관련 주요 제도 표) · 51쪽 주요 복리후생 제도 표 · 57쪽 건강증진 프로그램 · 건강 및 휴게 환경 지원.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814004123) 유연근무제도 사용 현황 주석(시차출퇴근제). 직원 620명.
--   귀속: 근거 문장 주어가 전부 F&F는 이고 복리후생 절이 F&F 별도 기준 사회 정보라 각주 없음.
--   지주 F&F홀딩스는 등록 대상이 아니며 코퍼스 · 대기 폴더에 F&F 계열 법인 0건. 회사 채용 ATS 는
--   fnf.recruiter.co.kr 이나 본문이 robots 전면 금지 API 호스트에서만 와 읽지 않았다.
--   금액: 식대 1행만 추정(조식 1끼 × 1끼 12,000원 × 연 240일 = 288만원). 원문 원 숫자는 산전 검사 비용 월 최대 50만원
--   하나(한도 — NULL). stated 0행.
--   제외: 법정(출산휴가 90일 · 배우자 출산휴가 20일 · 법정 육아휴직 · 임신 초기 근로시간 단축 · 난임 휴가 연 6일 ·
--     육아기 단축근무 · 가족돌봄 10일 휴가 · 90일 휴직 · 전 임직원 연 1회 건강검진 · 법정 의무 인권 교육) ·
--     업무 교육(AI 역량 강화 프로그램 · AX 부트캠프 · 리더십 과정) · 급여성(Salary Increase · AX 수당 · 핵심인재 수당) ·
--     업무용(사내 카셰어링 · 공용 법인 전기차) · 다른 법인(F&F엔터테인먼트 아티스트 프로그램) · 신고포상 · AIdea 공모전.
--   공고 근거 0행 / 전체 31행.
--   SORT 섹션 순서 = 정본 보고서 등장 순(compensation 10 · growth 20 · work_env 30 · flexibility 40 · time_off 50 ·
--     family 60 · health 70 · perks 80 · leisure 90).
-- 검증 · 감사 판정 반영(2026-10-14): 자기 도메인 우리의 문화 복지 연재를 보조 출처로(리드 판정 118) 자사 브랜드 · 관계사 할인 discount · 허먼밀러 의자 office_furniture 추가 · FLUNCH DAY 를 식대 행 서술에 보탬 — 최종 33행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('fnf', 'F&F',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '패션', 'F', 'https://homepage-static.fnf.co.kr/file_6a7c2dd04350eb.64939586.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'fnf');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://homepage-static.fnf.co.kr/file_6a7c2dd04350eb.64939586.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 보고서 49 · 51쪽 ──
  (@comp_id, 'incentive', '성과급 (연 2회)', NULL, 'compensation',
   'est', NULL, TRUE, '직무 성과, 사업부 경영 성과, 협업 수준 등을 종합적으로 반영한 개인 평가 결과를 바탕으로 연 2회 성과급 지급 (2026 지속가능경영보고서 49쪽 공정한 성과평가 및 보상 항목) — 지급률·금액 미기재', 10),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '연간 2회, 설·추석 명절 선물 제공 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 명절 선물 지급 항목) — 선물 품목·금액 미기재', 11),
  -- ── 성장 · 교육 (growth) — 보고서 49 · 51쪽 ──
  (@comp_id, 'self_development', '자격 취득 교육비 지원 (Level up Program)', NULL, 'growth',
   'est', NULL, TRUE, '레벨업 프로그램을 통한 직무 관련 자격증 취득 과정 지원 (2026 지속가능경영보고서 49쪽 임직원 역량 개발 항목), Level up Program 직무 관련 자격 취득 교육비 지원 (같은 보고서 51쪽 주요 복리후생 제도 표 항목) — 지원 한도·대상 자격 미기재', 20),
  (@comp_id, 'lang', '어학 강좌 수강료 지원', NULL, 'growth',
   'est', NULL, TRUE, '레벨업 프로그램을 통한 어학 강좌 수강료 지원 (2026 지속가능경영보고서 49쪽 임직원 역량 개발 항목), Level up Program 어학 강좌 수강료 지원 (같은 보고서 51쪽 주요 복리후생 제도 표 항목) — 지원 한도·과정 범위 미기재', 21),
  (@comp_id, 'edu_support', 'IT 강좌 수강료 지원·온라인 교육 플랫폼 Smart Learning', NULL, 'growth',
   'est', NULL, TRUE, '레벨업 프로그램을 통한 IT 강좌 수강료 지원 (2026 지속가능경영보고서 49쪽 임직원 역량 개발 항목), AI·디지털 중심의 실무형 콘텐츠와 리더십 및 직무 전문성 교육 강의를 언제 어디서든 수강할 수 있는 온라인 교육 플랫폼 Smart Learning (같은 보고서 49 · 51쪽 주요 복리후생 제도 표 항목) — 지원 한도·수강 조건 미기재', 22),
  (@comp_id, 'books', '도서 구매 지원 (Book Coupon)', NULL, 'growth',
   'est', NULL, TRUE, 'F&F Library Book Coupon, 회사 전략 방향 및 업무 연관성에 부합하는 도서 구매 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 항목), 레벨업 프로그램을 통한 도서 구매 비용 제공 (같은 보고서 49쪽 임직원 역량 개발 항목) — 지원 한도·주기 미기재', 23),
  -- ── 근무 환경 (work_env) — 보고서 49 · 50 · 51쪽 ──
  (@comp_id, 'work_tools', 'AI 툴·프로그램 구독 비용 지원', NULL, 'work_env',
   'est', NULL, TRUE, 'AX 전환 가속화를 위해 AI 툴 및 프로그램 구독 등 업무 생산성 향상에 필요한 비용 지원 (2026 지속가능경영보고서 49쪽 임직원 역량 개발 항목) — 지원 한도·대상 도구 미기재', 30),
  (@comp_id, 'lounge', '여성·남성 전용 휴게실·사내 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '임신 및 월경 등으로 휴식이 필요한 여성 직원을 위한 전용 휴게실과 남성 직원을 위한 별도의 휴식 공간 (2026 지속가능경영보고서 50쪽 복리후생 항목), 여성&남성 전용 개별 리프레시 공간 운영, 자유로운 휴식 및 티타임을 위한 사내 라운지 운영 (같은 보고서 51쪽 주요 복리후생 제도 표 직원 휴게실 · 직원 휴게 라운지 항목) — 공간 규모·운영 시간 미기재', 31),
  (@comp_id, 'parking', '임산부 전용 주차 공간', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 전용 주차 공간 지원 (2026 지속가능경영보고서 50쪽 출산·육아 관련 주요 제도 표 임신 및 출산 지원 항목) — 주차 면수·이용 기간 미기재', 32),
  (@comp_id, 'nap_room', '유축 공간·모유 보관 냉장고', NULL, 'work_env',
   'est', NULL, TRUE, '전용 유축 공간 운영 및 모유 보관 전용 냉장고 구비 (2026 지속가능경영보고서 50쪽 출산·육아 관련 주요 제도 표 임신 및 출산 지원 항목), 건강 관리실 내 산모 전용 유축 공간 마련 (같은 보고서 51쪽 주요 복리후생 제도 표 건강 관리실 운영 항목) — 공간 수·위치 미기재', 33),
  (@comp_id, 'office_furniture', '허먼밀러 의자', NULL, 'work_env',
   'est', NULL, TRUE, '업무에 집중할 수 있는 환경 조성을 위해 모든 임직원에게 허먼밀러 의자 제공 (공식 홈페이지 우리의 문화 임직원 맞춤형 복지 혜택 Life 편 항목) — 교체 주기 미기재', 34),
  -- ── 근무 유연성 (flexibility) — 보고서 50쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차 출퇴근제·탄력근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제와 탄력근무제를 포함한 유연근무제도 운영 (2026 지속가능경영보고서 50쪽 일과 삶의 균형 항목), 업무에 지장이 없는 범위에서 팀 부서장의 승인 및 관리하에 자율 운영되는 시차출퇴근제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대 선택 범위 미기재', 40),
  -- ── 휴가 (time_off) — 보고서 50 · 51쪽 ──
  (@comp_id, 'long_service_leave', '장기 근속자 포상·리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 기간에 따른 포상 제도로 1년 이상 근속한 임직원에게 식사권, 3년 이상 장기 근속자에게 재충전 특별휴가와 함께 항공·숙박 등 여행 경비와 휴가지원금 지원 (2026 지속가능경영보고서 50쪽 일과 삶의 균형 항목), 근속 기간별 장기 근속 리프레시 휴가 지원 (같은 보고서 51쪽 주요 복리후생 제도 표 장기 근속자 포상 항목) — 휴가 일수·지원 금액 미기재', 50),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 2시간 단위로 사용할 수 있는 제도 운영 (2026 지속가능경영보고서 50쪽 일과 삶의 균형 항목) — 사용 한도 미기재', 51),
  (@comp_id, 'birthday_leave', '생일 2시간 조기 퇴근', NULL, 'time_off',
   'est', NULL, TRUE, '생일을 맞은 임직원에게 2시간 조기 퇴근 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 생일 선물 지급 항목) — 사용 조건 미기재', 52),
  -- ── 가족 (family) — 보고서 50 · 51쪽 ──
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가·경조 물품)', NULL, 'family',
   'est', NULL, TRUE, '부모님의 환갑과 칠순에 제공하던 유급휴가 및 축하금 지원 범위를 팔순까지 확대 (2026 지속가능경영보고서 50쪽 일과 삶의 균형 항목), 경조금, 경조 휴가, 경조 물품 지원 (같은 보고서 51쪽 주요 복리후생 제도 표 경조사 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 60),
  (@comp_id, 'parenting', '임신·출산·자녀 양육 지원', NULL, 'family',
   'est', NULL, TRUE, '산전 검사 비용(월 최대 50만원) 지원, 임신·출산 축하 선물(Mom Gift Box) 제공, 만 5세 이하 자녀 대상 영유아 어린이집 보육료 지원, 유치원 및 초·중·고 입학 선물 제공 (2026 지속가능경영보고서 50쪽 출산·육아 관련 주요 제도 표 임신 및 출산 지원 · 자녀 양육 지원 항목) — 보육료 지원 금액·입학 선물 품목 미기재', 61),
  (@comp_id, 'child_edu', '대학교 학자금 지원 (최대 2자녀)', NULL, 'family',
   'est', NULL, TRUE, '최대 2자녀 대학교 학자금 지원 (2026 지속가능경영보고서 50쪽 출산·육아 관련 주요 제도 표 자녀 양육 지원 항목) — 지원 한도·지급 조건 미기재', 62),
  -- ── 건강 (health) — 보고서 50 · 51 · 57쪽 ──
  (@comp_id, 'fitness', '사내 피트니스 센터 (FIT ROOM)·소그룹 PT', NULL, 'health',
   'est', NULL, TRUE, '사옥 내 피트니스 센터(FIT ROOM) 운영 (2026 지속가능경영보고서 50쪽 임직원 건강 관리 지원 항목), 임직원 전용 운동 공간 제공 (같은 보고서 51쪽 주요 복리후생 제도 표 피트니스센터 운영 항목), 전문 트레이너가 참여하는 1:1 및 1:3 방식 주 3회 소그룹 PT 프로그램 (같은 보고서 57쪽 건강증진 프로그램 운영 항목) — 이용 시간·비용 부담 미기재', 70),
  (@comp_id, 'health_check', '본인·배우자 종합건강검진 (연 1회)', NULL, 'health',
   'est', NULL, TRUE, '연간 1회, 임직원 및 배우자의 종합 건강검진 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 종합 건강검진 지원 항목), 건강검진 항목에 스트레스 테스트 포함 (같은 보고서 50쪽 임직원 건강 관리 지원 항목) — 검진 비용 지원 한도 미기재', 71),
  (@comp_id, 'mental', 'EAP 심리상담', NULL, 'health',
   'est', NULL, TRUE, 'EAP(Employee Assistance Program)를 통한 임직원 대상 전문 심리상담 서비스 (2026 지속가능경영보고서 50쪽 임직원 건강 관리 지원 항목 · 51쪽 주요 복리후생 제도 표 웰니스 지원 항목) — 상담 횟수 미기재', 72),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '각종 질병·상해 의료비 보장을 위한 단체보험 가입 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 단체상해보험 가입 항목) — 보장 한도·보험료 부담 미기재', 73),
  (@comp_id, 'clinic', '건강 관리실', NULL, 'health',
   'est', NULL, TRUE, '임직원 상비약 제공 및 응급 처치 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 건강 관리실 운영 항목), 근로자가 상시적으로 건강 상태를 점검하고 응급 상황에 대응할 수 있도록 하는 건강관리실 운영 (같은 보고서 57쪽 건강 및 휴게 환경 지원 항목) — 의료 인력 상주 여부 미기재', 74),
  (@comp_id, 'smoking_cessation', '금연 캠페인 (금연 상담·보조제)', NULL, 'health',
   'est', NULL, TRUE, '강남보건소와 협력한 금연 캠페인 운영, 참여 임직원 대상 금연 상담 및 보조제 제공 (2026 지속가능경영보고서 57쪽 건강증진 프로그램 운영 항목) — 운영 주기 미기재', 75),
  -- ── 생활 · 편의 (perks) — 보고서 50 · 51쪽 ──
  (@comp_id, 'meal', '조식 제공·구내식당 (FRESH FARM)', 288, 'perks',
   'est', '매일 아침 조식 및 모닝커피 제공, 구내식당(FRESH FARM) 운영, 야근자 저녁 식사 무료 제공 (2026 지속가능경영보고서 50 · 51쪽 항목), 격주 금요일 점심시간 1시간 30분 FLUNCH DAY (공식 홈페이지 우리의 문화 항목) — 점심 제공 여부 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 야근 시 저녁 제외)', FALSE, NULL, 80),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '매월 전 직원을 대상으로 통신비 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 통신비 지원 항목) — 월 지원 금액 미기재', 81),
  (@comp_id, 'transport', '차량 유지비 지원', NULL, 'perks',
   'est', NULL, TRUE, '매월 정액 차량 유지비 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 차량 유지비 지원 항목) — 월 지원 금액·대상 미기재', 82),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일을 맞은 임직원에게 생일 선물 지급 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 생일 선물 지급 항목) — 선물 품목·금액 미기재', 83),
  (@comp_id, 'discount', '자사 브랜드·관계사 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사 브랜드 상품 상시 할인 구매와 입사 시·1년마다 직급별 차등 구매 포인트 지급, 브랜드별 매월 온라인 자사몰 쿠폰, 관계사 바닐라코·ARTBOX 직원가 할인 (공식 홈페이지 우리의 문화 임직원 맞춤형 복지 혜택 Life 편 항목), 자르뎅페르뒤 식사·음료 메뉴 최대 50% 할인 (같은 홈페이지 조식 서비스와 자르뎅페르뒤 글 항목) — 브랜드별 할인율·포인트 금액 미기재', 84),
  -- ── 여가 · 행사 (leisure) — 보고서 51쪽 ──
  (@comp_id, 'company_event', '창립기념일 파티 (F&F Anniversary PARTY)', NULL, 'leisure',
   'est', NULL, TRUE, '연간 1회, 창립기념일 파티 개최 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 F&F Anniversary PARTY 항목) — 행사 내용 미기재', 90),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '매월 동호회 활동비 지원 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 동호회 활동 지원 항목) — 지원 금액·동호회 종류 미기재', 91),
  (@comp_id, 'welcome_kit', '입사 선물 (Welcome Kit)', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자에 대한 환영 선물(Welcome Kit) 제공 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 입사 선물 지급 항목) — 선물 품목 미기재', 92),
  (@comp_id, 'resort', '법인 리조트·골프장 회원가 이용', NULL, 'leisure',
   'est', NULL, TRUE, '회사 보유 법인 리조트 및 골프장 회원가 이용 (2026 지속가능경영보고서 51쪽 주요 복리후생 제도 표 법인 리조트 제공 항목) — 이용 가능 시설·이용 횟수 미기재', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
