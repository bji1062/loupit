-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 씨젠 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://seegene.recruiter.co.kr/career/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 두 곳이다. 3자 사이트 인용 0건.
--       S1 정본 = 회사명 전용 채용 서브도메인 seegene.recruiter.co.kr/career/welfare
--         (제목 「복리후생 | 씨젠 채용」, author 「씨젠」). 라벨 20개뿐, 설명·금액 0.
--       S2 보강 = 자기 도메인 kr.seegene.com/sustainability/social (제목 「사회 | ESG | Seegene」)
--         「복리후생 프로그램」 4영역(가족·건강·리프레시·자기계발) 12항목 + 보건 및 안전 절의
--         건강검진·단체 상해보험·독감 예방접종·중대 질환 지원·부속의원 서술. SSR 텍스트.
--       ⚠ 프로브는 공식 회사 사이트에 복지가 없다고 봤으나 ESG 사회 페이지에 복지 절이 있다.
--         채용·careers 경로만 확인하고 ESG 경로는 안 본 것. S2 는 S1 을 뒷받침하고 2항목을 더한다.
--       ⚠ S1 은 Next.js CSR 이라 원본 HTML 에 항목 0. 항목은 잡플렉스 빌더 JSON
--         (infra1-static.recruiter.co.kr/builder/recruiter/2026/06/02/042a16c6-….json) 에 있다.
--         그 주소를 주는 api-recruiter.recruiter.co.kr 은 robots 전면 금지라 호출하지 않았고,
--         프로브가 렌더 중 받아 둔 주소로 JSON 을 직접 GET 했다. 헤드리스 렌더 0회.
--         JSON 은 프로브 사본과 바이트 동일, 샘플 템플릿 표지 0건(KAI 오염 선례 점검).
--       ⚠ 공식 사이트(kr.seegene.com)에서 채용 서브도메인으로 가는 링크는 없다. 귀속 근거는
--         채용사이트 메타·기업소개 사실값(설립 2000.09·코스닥 2010.09)과 헤더의 공식 홈 링크.
--       S1 20 라벨 → 법정 1개(산전후휴가/육아휴직) 제외 · E-Learning 1개 제외(학습 플랫폼 제공,
--         비용 지원 문구 없음) → 18 라벨. 장기근속자 포상/포상휴가 1라벨 → 2행 분리(+1).
--         독감 예방접종은 S2 가 부속의원을 통해 지원한다고 밝혀 clinic 행에 합침(-1).
--         Nursing Room 은 휴식공간과 같은 lounge 행에 합침(-1) → 17행.
--         S2 에만 있는 씨젠 어린이집 운영(childcare)·온마음 프로그램(mental) 2행 추가 → 19행.
--       신규 코드 0. 금액: 두 출처 모두 원 단위 금액 0건 → 19행 전부 BENEFIT_AMT NULL.
--       SORT 섹션 순서는 S1 페이지에서 그 카테고리가 처음 나온 순서
--         (leisure 10 · perks 20 · compensation 30 · time_off 40 · health 50 · work_env 60 · family 70).
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 수 19 그대로. SORT 41 힐링데이·돌봄데이는 원문에 휴가 부여 문구가 없어
--       refresh_leave 에서 leave_general 로 재코딩했다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 72 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('seegene', '씨젠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'S', 'https://seegene.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'seegene');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://seegene.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '웰컴패키지', NULL, 'leisure',
   'est', NULL, TRUE, '웰컴패키지 (공식 채용 페이지 복리후생 항목) — 구성품·지급 시점·금액 미기재', 10),
  (@comp_id, 'library', '사내 북카페', NULL, 'leisure',
   'est', NULL, TRUE, '사내 북카페 (공식 채용 페이지 복리후생 항목) — 보유 도서·대출 가능 여부·운영 사업장 미기재', 11),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '자기계발 포인트', NULL, 'perks',
   'est', NULL, TRUE, '자기개발포인트 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 자기계발 영역: 개인 성장을 위한 자기계발 포인트 지원 (복지몰 및 복지카드 통해 이용 가능) — 연간 포인트 금액·사용처 세부 미기재', 20),
  (@comp_id, 'housing_loan', '주택·생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금/생활안정자금 대출 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 가족 영역: 주택/생활 안정 자금 대출 — 대출 한도·이율·자격 요건 미기재', 21),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상/포상휴가 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 리프레시 영역: 장기근속자 포상 및 리프레쉬 휴가 — 근속 연수 기준·포상 내용·금액 미기재', 30),
  (@comp_id, 'holiday_gift', '명절선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 임직원 소통 항목: 2025년 명절 선물 상품권 옵션 확대 — 선물 품목·금액·연간 지급 횟수 미기재', 31),

  -- ── 휴가·휴직 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속자 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상/포상휴가 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 리프레시 영역: 장기근속자 포상 및 리프레쉬 휴가 — 근속 연수 기준·휴가 일수·유급 여부 미기재', 40),
  (@comp_id, 'leave_general', '힐링데이·돌봄데이', NULL, 'time_off',
   'est', NULL, TRUE, '힐링데이/돌봄데이 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 리프레시 영역: 돌봄 Day & 힐링 Day — 부여 일수·사용 주기·유급 여부·사용 조건 미기재', 41),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'clinic', '사내의원', NULL, 'health',
   'est', NULL, TRUE, '사내의원 (공식 채용 페이지 복리후생 항목), 씨젠 클리닉 (부속의원) (ESG 사회 페이지 복리후생 프로그램 건강 영역). ESG 사회 페이지 보건 및 안전 항목: 씨젠 부속의원은 전 임직원을 대상으로 운영되며 만성 피로 관리, 스트레스 관련 증상 관리, 항노화 케어 프로그램, 개인 맞춤형 치료 및 예방접종 서비스를 함께 제공. 독감 예방접종 (공식 채용 페이지 복리후생 항목)도 씨젠 부속의원을 통해 지원 — 운영 사업장·진료 시간·이용료 부담 여부 미기재', 50),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스센터 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 건강 영역: 씨젠 피트니스 — 운영 사업장·이용료·운영 시간 미기재', 51),
  (@comp_id, 'insurance', '임직원 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원단체상해보험 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 보건 및 안전 항목: 임직원이 안정적인 근무 환경에서 업무에 집중할 수 있도록 단체 상해보험을 제공 — 보장 범위·보험료·가족 포함 여부 미기재', 52),
  (@comp_id, 'medical', '중증질환 지원', NULL, 'health',
   'est', NULL, TRUE, '중증질환 지원 (공식 채용 페이지 복리후생 항목), 중증질환 위로금 (ESG 사회 페이지 복리후생 프로그램 가족 영역). ESG 사회 페이지 보건 및 안전 항목: 중대 질환을 겪는 임직원 본인뿐만 아니라 배우자 및 직계 가족에게도 필요한 의료 지원을 제공 — 대상 질환 범위·위로금 액수·지원 한도 미기재', 53),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 보건 및 안전 항목: 임직원의 건강 보호를 위해 정기적인 종합 건강검진을 제공 — 검진 주기·검진 금액·가족 포함 여부 미기재', 54),
  (@comp_id, 'mental', '온마음 프로그램 (심리상담)', NULL, 'health',
   'est', NULL, TRUE, '온(溫, ON)마음 프로그램 (심리치료) (ESG 사회 페이지 복리후생 프로그램 건강 영역). 같은 페이지: 임직원 정신건강을 지원하기 위해 심리 상담 프로그램 운영, 2025년 연간 총 139회 상담 진행 — 1인당 이용 횟수·비용 부담·가족 이용 여부 미기재', 55),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '휴식공간·Nursing Room', NULL, 'work_env',
   'est', NULL, TRUE, '휴식공간, Nursing Room (공식 채용 페이지 복리후생 항목 2건) — 설치 사업장·시설 구성·이용 시간 미기재', 60),
  (@comp_id, 'smart_office', '스마트오피스', NULL, 'work_env',
   'est', NULL, TRUE, '스마트오피스 (공식 채용 페이지 복리후생 항목) — 공간 구성·운영 사업장 미기재', 61),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 유치원비 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀유치원비 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 가족 영역: 자녀 유치원비 지원 — 지원 금액·지원 기간·자녀 수 제한 미기재', 70),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금/경조휴가 (공식 채용 페이지 복리후생 항목). ESG 사회 페이지 복리후생 프로그램 가족 영역: 경조사 지원 — 경조 유형별 금액·휴가 일수 미기재', 71),
  (@comp_id, 'childcare', '씨젠 어린이집', NULL, 'family',
   'est', NULL, TRUE, '씨젠 어린이집 운영 (ESG 사회 페이지 복리후생 프로그램 가족 영역 — 정원·대상 연령·운영 사업장 미기재)', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
