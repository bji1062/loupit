-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이마트 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://job.shinsegae.com/api/rcrut/5365
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 신세계그룹 통합 채용사이트 job.shinsegae.com 의 (주)이마트 채용공고다.
--       3자 사이트 인용 0건.
--       정본 = 공고 5365 「(주)이마트 27년 신입사원 채용」의 공고문 JPEG 안
--       「Chapter 2. 이마트 복리후생」 10항목 / 하위 불릿 24개.
--         경로: GET /api/rcrut/5365 → imgFilePath
--               → https://job.shinsegae.com/upload/pbancUpendImg/QLjXpPwHNpqgODw1o8paMB.jpg
--               (image/jpeg 8,318,735B · 2001×20136px · 복지 구획 y≈13,070~17,000)
--         sha256 = 4e1faaa2a925131991a0feb9680f49f8db67b27479a2bc8f82a74c884724ad61
--       보조 = 공고 5369 「(주)이마트 Data Scientist 경력사원 모집」의 sprtGdCn 「[복리후생]」 5항목.
--         보조는 정본의 부분집합이라 새 행을 만들지 않았고, 연중휴가 5일/年 · 주35시간(일 7시간)
--         두 수치만 해당 행 서술에 보탰다.
--       ⚠ CAREERS_BENEFIT_URL 은 공고 permalink 가 아니라 포털 루트다.
--         정본 공고는 마감이 있다(5365 = 2026-10-12 18시 · 5369 = 2026-09-28).
--         마감 뒤 공고가 내려가면 permalink 가 404 가 되어 회사 페이지의 출처 링크가 죽는다.
--         원본 JPEG·상세 JSON 사본과 해시는 evidence 와 scratchpad/wave4/emart/ 에 보존했다.
--       ⚠ 절대 붙으면 안 되는 도메인: company.emart.com · store.emart.com · careers.shinsegae.com.
--         셋 다 robots 에서 User-agent: * 에 Disallow: / 이고 AI 봇 전용 레코드가 없다.
--         company.emart.com 이 이마트 공식 회사 사이트지만 그래서 본문을 한 번도 요청하지 않았다.
--         나중에 「공식 홈페이지」라는 이유로 출처 URL 을 그쪽으로 바꿔 달면 안 된다.
--       ⚠ 그룹 공통 각주를 붙이지 않은 이유: 형제 법인 (주)신세계 공고 5336 의 공고문
--         이미지에는 복리후생 섹션이 아예 없다(디자인도 다르다). 즉 포털이 찍어 주는 템플릿이
--         아니라 이마트가 자기 법인용으로 만든 자료다. 코퍼스에 신세계그룹 법인은 0개다.
--         04·06 항목명에 들어 있는 「신세계그룹」 한정어는 서술에 그대로 보존했다.
--       ⚠ 포털 홈의 그룹 공통 4항목(계열사 할인 혜택·교육 및 경조사 지원·건강한 생활 지원·
--         여가활동 지원)은 주어가 「신세계 그룹의 임직원」이라 한 건도 섞지 않았다.
--       10항목 → 24불릿. 항목명은 카피라 행으로 쓰지 않고 불릿 단위로 코드를 매겼다.
--       제외 4불릿(신입 초봉·SSG EDU 온라인 학습 플랫폼 2건 성격) 사유는 evidence 참조.
--       복합 불릿 3건 분해(의료비 및 심리상담 → medical + mental · 명절 및 생일 마일리지 →
--       holiday_gift + birthday_gift · 자녀 학자금 및 가족농장 → child_edu + company_event),
--       같은 코드로 귀결되는 6불릿 병합 → 23행. 신규 코드 0.
--       금액: 공고문 전체에 원 단위 금액이 0건이다. 정량 표현은 시간·일수·횟수뿐이고
--       (하루 7시간 · 주 35시간 · 월 1회 · 연차 외 5일) 이는 금액이 아니다.
--       → 23행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없다.
--       법정 제도 미수록: 주5일·법정 연차·법정 출산휴가·육아휴직은 행으로 만들지 않았다.
--       「연차 휴가 외 추가 5일 연중 휴가」는 원문이 상회 조건을 스스로 밝힌 문장이라 수록했다.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 23행 그대로. SORT 60·61 코드 맞바꿈(리프레시 데이 = 월 1회 본사
--       휴무일이라 leave_general · 연중휴가 = 연차 외 추가 5일이라 refresh_leave) · SORT 30 표시명을
--       「사내 문화예술 프로그램」으로 교체(가족농장 서술은 QUAL_DESC 에 유지).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 12·62 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('emart', '이마트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'E', 'https://job.shinsegae.com/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'emart');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://job.shinsegae.com/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 공고문 01·07 항목 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 별도 지급 (공식 채용 공고 이마트 복리후생 01 항목 — 지급 주기·지급률·지급액 미기재)', 10),
  (@comp_id, 'holiday_gift', '명절 복지 마일리지', NULL, 'compensation',
   'est', NULL, TRUE, '명절 및 생일 등 현금성 복지 마일리지 지급 (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목) 중 명절 지급분 — 지급 마일리지 액수 미기재', 11),
  (@comp_id, 'long_service_bonus', '장기근속 축하금', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 축하금 지급 (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목) — 대상 근속 연수·축하금 액수 미기재', 12),

  -- ── 성장·커리어 (growth) — 공고문 02 항목 ──
  (@comp_id, 'edu_support', '직무·외부 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내 다양한 직무 교육 및 외부 교육 지원 (공식 채용 공고 이마트 복리후생 02 임직원 성장 서포트 항목) — 외부 교육 지원 한도·대상 과정 미기재', 20),

  -- ── 여가·라이프 (leisure) — 공고문 02·04·06·10 항목 ──
  (@comp_id, 'company_event', '사내 문화예술 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '신세계 남산 아카데미를 통한 문화예술 활동과 신세계 파트너스 나이트 클래식 콘서트 운영 (공식 채용 공고 이마트 복리후생 02 임직원 성장 서포트 항목), 가족농장 지원 (09 가족을 위한 복지 항목) — 개최 주기·참여 인원·신청 방법 미기재', 30),
  (@comp_id, 'sports_ticket', 'SSG랜더스 홈경기 혜택', NULL, 'leisure',
   'est', NULL, TRUE, 'SSG랜더스 야구 홈경기 임직원 혜택 제공 (공식 채용 공고 이마트 복리후생 04 신세계그룹 임직원 할인 항목) — 혜택 형태·연간 횟수·동반 가능 인원 미기재', 31),
  (@comp_id, 'resort', '신세계그룹 휴양시설·제휴 호텔', NULL, 'leisure',
   'est', NULL, TRUE, '신세계 그룹 휴양 시설 무료 숙박(조선호텔, 레스케이프, 포포인츠 by 쉐라톤, JW메리어트 등)과 국내 최상급 호텔·리조트 제휴 할인가 제공 (공식 채용 공고 이마트 복리후생 06 신세계그룹 호텔 혜택 항목) — 연간 이용 한도·성수기 조건 미기재', 32),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '골프, 뮤지컬, 수영, 테니스, 클라이밍, 꽃꽂이 등 다양한 사내 동호회 지원 (공식 채용 공고 이마트 복리후생 10 동호회 활동 지원 항목) — 동호회 수·활동비 지원액 미기재', 33),

  -- ── 근무 유연성 (flexibility) — 공고문 03 항목 ──
  (@comp_id, 'flex_work', '9 to 5 근무제·유연근무', NULL, 'flexibility',
   'est', NULL, TRUE, '하루 7시간, 주 35시간 근무의 9 to 5 근무제와 시차출근, 유연근무 등 다양한 근무제 운영 (공식 채용 공고 이마트 복리후생 03 9 to 5 근무제 항목, 경력 채용 공고 근무형태도 주35시간 근무(일 7시간)) — 코어타임·신청 절차·적용 직군 미기재', 40),

  -- ── 경제적 부가혜택 (perks) — 공고문 04·07·09 항목 ──
  (@comp_id, 'discount', '신세계그룹 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '이마트, 스타벅스, 신세계백화점, 스타필드, 조선호텔, 면세점 등 그룹사 할인 (공식 채용 공고 이마트 복리후생 04 신세계그룹 임직원 할인 항목) — 할인율·연간 한도 미기재', 50),
  (@comp_id, 'birthday_gift', '생일 복지 마일리지', NULL, 'perks',
   'est', NULL, TRUE, '명절 및 생일 등 현금성 복지 마일리지 지급 (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목) 중 생일 지급분 — 지급 마일리지 액수 미기재', 51),
  (@comp_id, 'housing_loan', '주택자금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대출 지원 (공식 채용 공고 이마트 복리후생 09 가족을 위한 복지 항목) — 대출 한도·이율·근속 조건 미기재', 52),

  -- ── 휴가·휴직 (time_off) — 공고문 05 항목 ──
  (@comp_id, 'leave_general', '리프레시 데이', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 데이로 월 1회 본사 휴무일 지정 (공식 채용 공고 이마트 복리후생 05 다양한 휴가 제도 항목) — 지정 요일·본사 외 사업장 적용 여부 미기재', 60),
  (@comp_id, 'refresh_leave', '연중휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 휴가 외 추가 5일 연중 휴가 (공식 채용 공고 이마트 복리후생 05 다양한 휴가 제도 항목, 경력 채용 공고 복리후생도 연중휴가 5일/年) — 사용 단위·이월 여부 미기재', 61),
  (@comp_id, 'long_service_leave', '근속 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 포상 휴가 (공식 채용 공고 이마트 복리후생 05 다양한 휴가 제도 항목) — 대상 근속 연수·부여 일수 미기재', 62),

  -- ── 가족·돌봄 (family) — 공고문 05·07·09 항목 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 지원(결혼, 수연, 조의, 출산 등) (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목)과 경조휴가 (05 다양한 휴가 제도 항목) — 경조금 액수·경조휴가 일수 미기재', 70),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (공식 채용 공고 이마트 복리후생 09 가족을 위한 복지 항목) — 설치 사업장·정원·대상 연령 미기재', 71),
  (@comp_id, 'parenting', '임신·출산 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '임신·출산 축하 선물 제공 (공식 채용 공고 이마트 복리후생 09 가족을 위한 복지 항목) — 선물 품목·금액·자녀 수 조건 미기재', 72),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 공고 이마트 복리후생 09 가족을 위한 복지 항목) — 대상 학교급·지원 한도·자녀 수 제한 미기재', 73),

  -- ── 건강·의료 (health) — 공고문 08 항목 ──
  (@comp_id, 'fitness', '사내 피트니스·PT', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 이용 및 무료 PT 지원 (공식 채용 공고 이마트 복리후생 08 든든한 건강 지원 항목) — 설치 사업장·PT 횟수 미기재', 80),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '매년 건강검진 지원 (공식 채용 공고 이마트 복리후생 08 든든한 건강 지원 항목) — 검진 항목·대상 가족 범위·지원 금액 미기재', 81),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 및 심리상담 지원 (공식 채용 공고 이마트 복리후생 08 든든한 건강 지원 항목) 중 의료비 지원 — 지원 범위·연간 한도·가족 포함 여부 미기재', 82),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 및 심리상담 지원 (공식 채용 공고 이마트 복리후생 08 든든한 건강 지원 항목) 중 심리상담 지원 — 상담 횟수·외부 기관 연계 여부 미기재', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
