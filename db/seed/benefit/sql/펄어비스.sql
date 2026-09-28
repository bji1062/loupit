-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 펄어비스 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://www.pearlabyss.com/ko-KR/Company/Brand/Welfare
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 펄어비스 공식 홈 www.pearlabyss.com 의 문화 > 복지 페이지(ko-KR). 서버 렌더 HTML 본문에
--     5개 절 47항목(직원의 삶 16 · 직원의 가족 13 · 성장 4 · 최고의 예우 4 · 행복한 일터 10)이 들어 있다. 헤드리스 불필요.
--     robots.txt 는 404(RFC 9309 4xx = 허용). Imperva CDN 이지만 주간 점검 UA 로도 200 과 복지 낱말을 확인했다.
--     로케일 없는 /Company/Brand/Welfare 는 이 주소로 302 한다 — 정본은 튕기지 않는 ko-KR 주소다.
--   보조 = 2025 펄어비스 ESG 보고서(국문 PDF 108쪽, 공식 홈 IR > 지속가능경영 게시 2026-06-30) p.26~28 근무제도 및
--     복리후생 표 · p.35 주요 보상 및 지원 제도. 금액 상세(난임 회당 100만원 · 출산 축하금 100만원)와 복지 페이지에 없는
--     항목(유연근무제 · 의류지원제도 · 자사주 지급 · 내일채움공제)의 근거다.
--   채용 소개 페이지(Careers/Intro)는 복지 라벨 15개만 있고 삼시세끼 무료 제공 표기를 확인하는 데만 썼다.
--   법인 자기 도메인이라 그룹 각주 없음. 직원 733명(DART 2025)이라 재취업지원서비스 의무 대상이 아니지만 원문에 해당 항목이 없다.
--   법정 제도 제외: 출산전후휴가 · 배우자 출산휴가 20일 · 난임치료휴가 3일 · 육아휴직 1년 · 가족돌봄휴직 90일 · 주 최대 근무시간.
--   금액: 원문 연액 3(medical 315 · child_edu 700 · welfare_point 204) · 월액 환산 3(housing_support 600 · parenting 600 ·
--     parent_care 480) · 구본 추정 승계 3(health_check 100 · insurance 30 · meal 432).
--   재코딩 2(conference → edu_support · lounge 의 안마 서비스 → massage) · 구본 housing_loan 은 거주비 현금과 대출 이자로 나눴다.
--   신규 코드 0. 어휘에 없는 원문 항목 7개(미용 · 은행 출장 · 세무 · 법률 · 가사청소 · 자전거 정비 · 반려동물 보험)는 싣지 않았다.
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): L6 한도 금액 3행 AMT NULL(medical 315 · child_edu 700 · parent_care 480) · birthday_leave 문안 반차 → 반일 — 최종 40행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('pearl_abyss', '펄어비스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'P', 'https://www.pearlabyss.com/ko-KR/Company/Brand/Welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.pearlabyss.com/ko-KR/Company/Brand/Welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 복지 페이지 직원의 삶 1 · 직원의 가족 8 · 성장 2 · 행복한 일터 2·3·9·10 · ESG p.27·28
  (@comp_id, 'housing_support', '거주비 지원', 600, 'perks',
   'est', '안양·과천·의왕·군포시에 거주하는 임직원에게 매달 거주비 50만원 지원 (연 600만원 환산)', FALSE, NULL, 10),
  (@comp_id, 'housing_loan', '대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '안양·과천·의왕·군포시 외 지역에 거주하는 임직원에게 대출 이자를 매달 실비로 지원 (2025 ESG 보고서 기준 37만 5천 원 한도)', 11),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 기념일 축하 선물을 원하는 날짜에 원하는 곳으로 배송', 12),
  (@comp_id, 'welfare_point', '복지카드 지원', 204, 'perks',
   'est', '자기계발을 위해 업종 제한 없이 쓰는 복지카드를 매년 204만원(월 17만원) 한도 안에서 제공', FALSE, NULL, 13),
  (@comp_id, 'meal', '먹거리 지원 (삼시세끼 무료)', 432, 'perks',
   'est', '사내식당 조식·중식·석식 무료 제공 (추정)', FALSE, NULL, 14),
  (@comp_id, 'snack_bar', '무료 카페테리아·캔틴', NULL, 'perks',
   'est', NULL, TRUE, '숙련된 바리스타가 만든 커피와 음료 무료 제공, 간식·비타민·신선한 과일을 비치한 업무 층별 캔틴과 간편식을 제한 없이 무료로 쓰는 메인 캔틴 운영', 15),
  (@comp_id, 'commute_subsidy', '셔틀버스 운행', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 편의를 위해 평촌역과 인덕원역에서 셔틀버스 운행', 16),
  (@comp_id, 'transport', '야간 및 비상 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '심야시간과 비상 상황에 출근이 필요한 직원에게 야간·비상근무 시 택시비 지원', 17),

  -- ── 가족·돌봄 (family) ── 복지 페이지 직원의 삶 2 · 직원의 가족 1~7·11~13 · ESG p.26·28
  (@comp_id, 'event', '경조금 및 상조서비스', NULL, 'family',
   'est', NULL, TRUE, '결혼·출산·장례·환갑 등 경조사에 경조금·경조 휴가·경조화환 지원과 임직원 가족을 위한 상조서비스 제공', 20),
  (@comp_id, 'parenting', '양육비 지원·자녀 생애주기별 선물', 600, 'family',
   'est', '미성년 자녀 1인당 매월 양육지원금 50만원 실비 지원 (자녀 1인 기준 연 600만원 환산), 자녀 출산 축하금 100만원과 출산·첫돌·초중고 입학 생애주기별 선물', FALSE, NULL, 21),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀의 국내외 대학 등록금 연 최대 700만원까지 지원', 22),
  (@comp_id, 'parent_care', '부모 요양 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원과 배우자의 부모 요양치료비 매월 최대 40만원까지 지원', 23),
  (@comp_id, 'fertility_support', '난임부부·난자 동결·임신 사전 검사 지원', NULL, 'family',
   'est', NULL, TRUE, '난임부부 시술비를 횟수 제한 없이 회당 최대 100만원 지원, 결혼 여부와 관계없이 여성 임직원의 난자 동결 시술 비용 지원, 기혼 임직원의 임신 사전 검사 비용 지원', 24),
  (@comp_id, 'childcare', '사내 어린이집·자녀 돌봄 프로그램', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집(깊은 바다 고래 어린이집) 운영, 초등학교 저학년 자녀 방학 돌봄 프로그램과 초등생 자녀 주말 돌봄 프로그램·1박 2일 캠프 운영', 25),

  -- ── 보상·금전 (compensation) ── 복지 페이지 직원의 삶 2 · 최고의 예우 2 · ESG p.28·35
  (@comp_id, 'holiday_gift', '명절 상여금·선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 상여금과 명절 선물·백화점 상품권 지급', 30),
  (@comp_id, 'excellence_award', '포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '임직원의 기여에 따른 표창 및 포상제도 운영', 31),
  (@comp_id, 'stock_grant', '자사주 지급 프로그램', NULL, 'compensation',
   'est', NULL, TRUE, '직급·직무에 관계없이 전 임직원 대상 자사주 지급 — 지급 수량은 개인별 워크레벨에 따라 산정, 지급 여부와 규모는 경영상황에 따라 검토 (2025 ESG 보고서 주요 보상 및 지원 제도 항목)', 32),
  (@comp_id, 'youth_savings', '청년 내일채움공제', NULL, 'compensation',
   'est', NULL, TRUE, '청년 재직자를 위한 내일채움공제 운영 (2025 ESG 보고서 현금성 복지제도 항목)', 33),

  -- ── 건강·의료 (health) ── 복지 페이지 직원의 삶 4·5·6·11·12·13 · 행복한 일터 6·8 · ESG p.26·27
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '본인·배우자·부모님·배우자의 부모님·자녀 단체상해보험 가입과 의료비 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '치과 치료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인의 치과 치료 비용을 연간 최대 315만원까지 회사가 직접 지원', 41),
  (@comp_id, 'health_check', '종합 건강 검진', 100, 'health',
   'est', '매년 1회 종합건강검진 무료 지원과 검진 휴가 제공 (추정)', FALSE, NULL, 42),
  (@comp_id, 'clinic', '사내 부속 의원 및 약국', NULL, 'health',
   'est', NULL, TRUE, '사내 부속 의원과 물리치료실 운영, 사내 약국에서 각종 의약품 구매 가능', 43),
  (@comp_id, 'fitness', '피트니스·회복운동센터', NULL, 'health',
   'est', NULL, TRUE, '사내 고급 피트니스 센터와 개인PT·필라테스 등 GX 프로그램 운영, 회복운동센터에서 근골격계 질환 예방과 통증 완화 운동 1:1 지도', 44),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '심리상담센터 1:1 맞춤 상담 제공 (2025년 비대면 심리상담실 추가 운영)', 45),
  (@comp_id, 'massage', '안마의자 & 전문 마사지 서비스', NULL, 'health',
   'est', NULL, TRUE, '최고급형 안마의자와 전문 안마사가 피로를 풀어주는 Healing Room 운영', 46),

  -- ── 휴가·휴식 (time_off) ── 복지 페이지 직원의 삶 14 · 최고의 예우 3·4 · ESG p.27·28
  (@comp_id, 'birthday_leave', '임직원 생일 축하', NULL, 'time_off',
   'est', NULL, TRUE, '임직원 생일에 백화점 상품권과 유급 반일 휴가 지원', 50),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기간 함께한 임직원의 재충전을 위해 최대 20일 휴가와 최대 2,000만원 휴가비, 장기근속 트로피 지급 (근속 기준 미기재)', 51),
  (@comp_id, 'refresh_leave', '리프레시 휴가 지원', NULL, 'time_off',
   'est', NULL, TRUE, '5일 휴가와 최대 500만원 휴가 지원금, 맞춤형 여행 키트 제공 (부여 주기·대상 조건 미기재)', 52),

  -- ── 여가·라이프 (leisure) ── 복지 페이지 직원의 삶 16 · 직원의 가족 9 · 행복한 일터 4·5 · ESG p.27·28
  (@comp_id, 'resort', '제휴 리조트 할인', NULL, 'leisure',
   'est', NULL, TRUE, '휴식과 재충전을 위해 회사 제휴 리조트를 할인가로 제공', 60),
  (@comp_id, 'company_event', '패밀리데이·특식 & 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '가족과 함께하는 가족 참여 프로그램 패밀리데이와 정기 특식·사내 이벤트 진행', 61),
  (@comp_id, 'leisure_room', '건강한 문화 공간', NULL, 'leisure',
   'est', NULL, TRUE, '풋살장·다목적실·스크린골프룸 등 여가 공간 조성', 62),

  -- ── 성장·커리어 (growth) ── 복지 페이지 성장 1·3·4 · ESG p.27
  (@comp_id, 'edu_support', '최신 기술 스터디·직무교육 지원', NULL, 'growth',
   'est', NULL, TRUE, 'AI·3D 그래픽스·PBR·DB 등 최신 기술 스터디 장려와 Python·JavaScript·SQL 등 온라인 코딩 교육비 지원, 온/오프라인 직무교육 이수 비용 지원', 70),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무에 필요한 도서 구입비 지원', 71),

  -- ── 근무환경 (work_env) ── 복지 페이지 최고의 예우 1 · 행복한 일터 4·7·9 · ESG p.27
  (@comp_id, 'work_tools', '최고 수준 업무 장비', NULL, 'work_env',
   'est', NULL, TRUE, '동종업계 최고 수준의 장비 지원과 3D 스캐너·모션캡처·VR 등 최신 고급 장비 운영', 80),
  (@comp_id, 'lounge', '리프레쉬룸·휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '충분한 휴식을 위한 리프레쉬룸과 편안한 분위기의 휴게실 운영', 81),
  (@comp_id, 'nap_room', '여성휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '임신 중 휴식과 출산 후 모유 수유를 돕는 여성 전용 휴게·수유 공간 운영', 82),
  (@comp_id, 'parking', '주차 지원', NULL, 'work_env',
   'est', NULL, TRUE, '사옥 내 주차 공간 무료 제공', 83),
  (@comp_id, 'uniform', '의류지원제도', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 편안하게 입을 수 있는 의류 지원 (2025 ESG 보고서 소속감/교류 항목, 2025년 신설)', 84),

  -- ── 근무유연성 (flexibility) ── 복지 페이지 행복한 일터 1 · ESG p.26
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '등록한 근무시간 안에서만 PC·노트북을 쓸 수 있는 PC-OFF 제도 운영 (공식 복지 페이지 업계 최초 포괄임금제 폐지 항목)', 90),
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 상황상 필요한 부서·인원 대상 탄력근무제와 선택근무제, 10세 이하 또는 초등학교 3학년 이하 자녀를 둔 직원 대상 시차 출퇴근제 운영 (2025 ESG 보고서 근무제도 항목)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
