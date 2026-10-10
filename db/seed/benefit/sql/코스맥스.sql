-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코스맥스 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://cosmax.recruiter.co.kr/career/welfare
-- badge: est
--
-- 참고:
--   정본은 코스맥스그룹 통합 채용 사이트(jobflex ATS cosmax.recruiter.co.kr)의 복리후생 페이지다.
--     귀속 경로: 자기 도메인 www.cosmax.com (운영 주체 코스맥스(주) — 개인정보처리방침) About us > Careers
--     > Recruitment portal 버튼 > cosmax.recruiter.co.kr. 포털 개인정보 처리자도 코스맥스(주).
--     자기 도메인에는 복지 항목이 0개다(웨이브 4 프로브 2026-09-20 내부 링크 전수).
--   렌더 방식: Next.js CSR. 16항목은 전부 페이지에 걸린 JPEG 1장 안에 있다
--     (infra1-static.recruiter.co.kr/builder/2025/07/17/2c7507a1-6f5d-4ba2-a8fd-6f55413f1a39.jpg ·
--      파일명 2025 코스맥스 복리후생_가로.jpg · 2352x1323 · sha256 53f8ccf6…84078).
--     리드가 2026-10-10 1회 GET 한 사본을 썼다(웨이브 4 프로브 사본과 sha256 동일). 4x4 격자 판독.
--     본문 API 호스트 api-recruiter.recruiter.co.kr 는 robots Disallow / 라 요청하지 않았다.
--   귀속 판단: 페이지 제목 · author · 본문 주어가 전부 코스맥스그룹이고 법인 구분 · 계열사별 상이 단서가 없다.
--     같은 페이지를 코스맥스 · 코스맥스비티아이 · 코스맥스엔비티 · 코스맥스바이오 · 코스맥스파마가 공유한다.
--     사원 판매 항목의 화장품/건강기능식품/제약 은 그룹 전체 제품군이다.
--     → 리드 판정 W5-2: 기등록 형제 0 이라 진입하되 채용 사이트 출처 15행 전부 서술 끝에 (그룹 통합 채용 기준) 각주.
--       자기 도메인 보조 출처 2행(SORT 80 · 81)은 채용 사이트가 아니라 규칙 6-3 꼴(출처 괄호 안 코스맥스그룹 공통 문구).
--     이 페이지로 형제 법인(코스맥스비티아이 · 코스맥스엔비티 등)을 추가 등록하지 말 것.
--   금액: 추정 1행(meal 하루 3끼 x 1끼 12,000원 x 연 240일 = 864, 간편식 제외). 회사 공식 수치 0행.
--     출산장려금 1천/2천/3천만원은 1회성 지급이라 금액 미등록(서술에만).
--   보조 출처: 자기 도메인 www.cosmax.com/sustainability/Improvement-of-Employee-Value/ (국문 기본 라우트 ·
--     eyebrow 인재개발 · 2026-02-26 게시) 본문 이미지 employeevalue_kr.jpg (a.storyblok.com · 2800x2648 ·
--     sha256 20b96b0c…09100) 의 코스맥스 그룹 교육 시스템 표. 그룹 이름 표라 출처 괄호에 코스맥스그룹 공통 문구 (규칙 6-3).
--     여기서 lang · edu_support 2행만 세웠다. 나머지(조직 활성화 교육 · 부서별 워크숍 · 멘토링 · 신입 합숙 ·
--     직무별 전문가 양성)는 업무 교육이라 제외.
--   제외: 자동 육아휴직 제도(법정 육아휴직의 운영 방식 — 기간 연장 · 급여 보전 없음) ·
--     배우자 출산휴가 유급 20일(법정 — 무급 10일 추가분만 실음) · 연차/반차 제도(법정) ·
--     여성가족부 가족친화 기업 인증(인증 사실 — 제도 아님).
--   공고 근거 0행 / 전체 17행. SORT 섹션 = 가족 10 · 휴가 20 · 생활 30 · 건강 40 · 여가 50 · 보상 60 · 근무환경 70
--     (이미지 격자 읽기 순서에서 그 카테고리가 처음 나온 순서) · 성장 80 (보조 출처에만 있는 카테고리 — 끝).
-- 검증 · 감사 판정 반영(2026-10-10): 출산장려금 행 서술 앞 두 구절에 원문 항목명 출산장려금 · 배우자 출산휴가를 본문으로 — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cosmax', '코스맥스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'C', 'https://cosmax.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cosmax');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://cosmax.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'parenting', '출산장려금·배우자 출산휴가 추가·위탁보육료·자녀돌봄 휴가', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산 시 출산장려금 첫째 1천만원, 둘째 2천만원, 셋째 이상 3천만원 지원 (코스맥스그룹 채용 사이트 복리후생 출산장려금 지원 항목), 배우자 출산휴가 희망 시 최대 무급 10일 사용 가능 (법정 20일에 무급 10일 추가) (출산휴가 제도 확대 항목), 어린이집 보육료 지원 (위탁보육료 지급 항목), 초등 2학년 이하 자녀 대상 법정 기본 연차 외에 별도의 휴가 부여 (유급 2일) (자녀돌봄 휴가 도입 항목) — 보육료 지원 금액·자녀돌봄 휴가 부여 주기 미기재 (그룹 통합 채용 기준)', 10),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '본인/가족 결혼, 회갑 등 각종 경조사 경조금/경조휴가 부여 (코스맥스그룹 채용 사이트 복리후생 경조금/경조휴가 부여 항목) — 경조 구분별 금액·휴가 일수 미기재 (그룹 통합 채용 기준)', 11),

  -- ── 휴가·휴식 (time_off) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 운영 (코스맥스그룹 채용 사이트 복리후생 항목) — 사용 한도·신청 방법 미기재 (그룹 통합 채용 기준)', 20),
  (@comp_id, 'summer_leave', '여름휴가 3일', NULL, 'time_off',
   'est', NULL, TRUE, '법정 휴가 외 여름휴가 3일 제공 (코스맥스그룹 채용 사이트 복리후생 항목) — 유급 여부·사용 시기 미기재 (그룹 통합 채용 기준)', 21),

  -- ── 경제적 부가혜택 (perks) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'meal', '사내 식당 (조식·중식·석식)', 864, 'perks',
   'est', '사내 식당 조식/중식/석식/간편식 제공 (코스맥스그룹 채용 사이트 복리후생 사내 식당 운영 항목) — 운영 사업장 미기재 (그룹 통합 채용 기준) (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 간편식 제외)', FALSE, NULL, 30),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아 운영 (코스맥스그룹 채용 사이트 복리후생 사내 식당 운영 항목) — 운영 사업장·무료 여부 미기재 (그룹 통합 채용 기준)', 31),
  (@comp_id, 'team_dinner', '부서별 문화행사 지원', NULL, 'perks',
   'est', NULL, TRUE, '부서별 문화행사 지원 (코스맥스그룹 채용 사이트 복리후생 문화활동 지원 항목) — 지원 금액·행사 주기 미기재 (그룹 통합 채용 기준)', 32),
  (@comp_id, 'discount', '사원 판매 (자사 제품 할인)', NULL, 'perks',
   'est', NULL, TRUE, '자사 제조 제품에 대한 할인 판매 (화장품/건강기능식품/제약) (코스맥스그룹 채용 사이트 복리후생 사원 판매 제도 운영 항목) — 할인율·구매 한도 미기재 (그룹 통합 채용 기준)', 33),
  (@comp_id, 'commute_subsidy', '통근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '공장 인근 거점 중심으로 셔틀버스 운행 (코스맥스그룹 채용 사이트 복리후생 통근 셔틀버스 운행 항목) — 운행 노선·운행 사업장 미기재 (그룹 통합 채용 기준)', 34),

  -- ── 건강·의료 (health) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 종합건강검진 비용 지원 (코스맥스그룹 채용 사이트 복리후생 종합건강검진 지원 항목) — 검진 주기·비용 지원 범위·가족 포함 여부 미기재 (그룹 통합 채용 기준)', 40),

  -- ── 여가·라이프 (leisure) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회(축구, 맛집 탐방 등) 지원 (코스맥스그룹 채용 사이트 복리후생 문화활동 지원 항목) — 활동비 지원 금액·동호회 수 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'resort', '향약원·제휴 리조트 이용', NULL, 'leisure',
   'est', NULL, TRUE, '법인 근로복지시설 향약원 무료이용 및 리솜리조트, 대명리조트, 금호리조트, 해비치호텔/리조트, 휘닉스파크 등 (코스맥스그룹 채용 사이트 복리후생 리조트 이용 지원 항목) — 제휴 리조트 이용 요금·이용 횟수·향약원 위치 미기재 (그룹 통합 채용 기준)', 51),

  -- ── 보상·금전 (compensation) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자에 대한 다양한 포상 실시 (코스맥스그룹 채용 사이트 복리후생 장기근속 포상 항목) — 근속 기준 연수·포상 내용 미기재 (그룹 통합 채용 기준)', 60),
  (@comp_id, 'excellence_award', '제안 제도 시상금', NULL, 'compensation',
   'est', NULL, TRUE, '업무 개선 제안에 따른 시상금 제공 (코스맥스그룹 채용 사이트 복리후생 제안 제도 운영 항목) — 시상 기준·시상금 금액 미기재 (그룹 통합 채용 기준)', 61),

  -- ── 근무환경 (work_env) — 그룹 채용 사이트 복리후생 이미지 ──
  (@comp_id, 'dormitory', '기숙사 (공장 근무자)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 제공(공장 근무자) (코스맥스그룹 채용 사이트 복리후생 기숙사 제공 항목) — 기숙사 위치·입주 조건·비용 부담 미기재 (그룹 통합 채용 기준)', 70),

  -- ── 성장·교육 (growth) — 보조 출처 www.cosmax.com 지속가능경영 인재개발 페이지 이미지 ──
  (@comp_id, 'lang', '사내·온라인 언어 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '사내 및 온라인 언어 프로그램 운영 (코스맥스 공식 홈페이지 지속가능경영 인재개발 페이지 코스맥스 그룹 교육 시스템 글로벌 인재 개발 항목, 코스맥스그룹 공통 문구) — 대상 언어·수강 대상·비용 지원 범위 미기재', 80),
  (@comp_id, 'edu_support', '저명 연사 초청 강연', NULL, 'growth',
   'est', NULL, TRUE, '저명한 연사들의 강연 (코스맥스 공식 홈페이지 지속가능경영 인재개발 페이지 코스맥스 그룹 교육 시스템 자긍심 함양 항목, 코스맥스그룹 공통 문구) — 강연 주기·참여 대상 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
