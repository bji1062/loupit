-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파마리서치 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.pharmaresearch.com/sub/people.html
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 파마리서치 공식 홈페이지 인재 채용 > 인재상 · 인사제도 (www.pharmaresearch.com, 법인 자기 도메인 · 헤더 메뉴 인재 채용 첫 항목).
--     서버 렌더 HTML 본문에 인사제도(성과보상 5항목)와 복리후생 6블록이 들어 있다(헤드리스 불필요). robots.txt 404 = 전면 허용.
--   보조 1 = 공식 홈 헤더의 채용공고 링크가 가리키는 브랜드 ATS pharmaresearch_hr.career.greetinghr.com/ko/home 의
--     복지 문화 6블록(서버 응답 HTML) — 장기근속휴가 및 포상 · 주택대출 · 생계대출 · 안마의자 · 마스크 및 검사 Kit 는 여기에만 있다.
--   보조 2 = 같은 도메인 ESG 게시판의 2025 지속가능경영보고서 국문 PDF 47 · 48 · 49쪽 — 복지포인트 연 100만원 · 양육지원금 월액 · 자격증 응시료 · 사내 도서관.
--   보조 3 = 같은 도메인 보도자료 2건(2024-01-24 출산축하금 · 2024-08-09 건강 플러스 프로그램) — 의료비 지원 · 종합검진 주기.
--   그룹 통합 채용 사이트 없음(법인 자기 페이지라 각주 없음). 직원 526명(DART 2025) — 1,000인 미만.
--   법정 제도: 하계 및 연말 단체 휴가 사용 · 남성 육아휴직 신청 · 자녀 12세 이하 부모 선택적 단축근로는 싣지 않았다.
--   금액: 원문 연액 1(welfare_point 100) · 월액 환산 1(parenting 120) · 구본 추정 승계 8 · 미승계(excellence_award 1회성 · child_edu · event · edu_support).
--   재코딩 1: massage → lounge. 신규 코드 0.
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): 하계 및 연말 단체 휴가를 leave_general 정성 행으로 되살림(부여 조건이 불명한 집중휴가 · 구본 refresh_leave 재코딩 · 법정 등록 해제) — 최종 25행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('pharma_research', '파마리서치',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'P', 'https://www.pharmaresearch.com/sub/people.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pharma_research');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.pharmaresearch.com/sub/people.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── 인사제도 성과보상 · 복리후생 블록 1
  (@comp_id, 'incentive', '경영성과급', 100, 'compensation',
   'est', '회사의 연간 경영실적 목표 달성 시 내부 지급기준에 따라 경영성과급 지급 (공식 홈페이지 인사제도 성과보상 항목 — 지급률·금액 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'excellence_award', 'POP 어워즈·기타 포상', NULL, 'compensation',
   'est', NULL, TRUE, '분기 또는 연간 POP 성과관리 결과에 따른 포상금 지급, 성공 사례 또는 우수 사원 선정 시 소정의 포상금 지급 (공식 홈페이지 인사제도 성과보상 항목 — 금액 미기재)', 11),
  (@comp_id, 'holiday_gift', '명절선물', 20, 'compensation',
   'est', '명절선물 (공식 홈페이지 복리후생 항목 — 품목·금액 미기재) (추정)', FALSE, NULL, 12),

  -- ── 경제적 부가혜택 (perks) ── 복리후생 블록 1·2·4 · 채용 사이트
  (@comp_id, 'birthday_gift', '생일·결혼기념일 특별 포인트', NULL, 'perks',
   'est', NULL, TRUE, '생일 특별포인트 (공식 홈페이지 복리후생 항목), 생일·결혼기념일 특별 포인트 (공식 채용 사이트 복지 문화 항목) — 포인트 금액 미기재', 20),
  (@comp_id, 'welfare_point', '복지포인트', 100, 'perks',
   'est', '복지포인트 연간 100만원 지급 — 2025 지속가능경영보고서: 복지포인트를 연간 65만원에서 100만원으로 확대', FALSE, NULL, 21),
  (@comp_id, 'discount', '자사몰 지원할인', NULL, 'perks',
   'est', NULL, TRUE, '자사몰 지원할인 (공식 홈페이지 복리후생 항목 — 할인율 미기재)', 22),
  (@comp_id, 'snack_bar', '사내 카페·간식', 30, 'perks',
   'est', '사내 카페 운영 및 이용비 지원, 간식 및 음료 제공 — 이용비 금액 미기재 (추정)', FALSE, NULL, 23),
  (@comp_id, 'meal', '조식·중식·석식 제공', 432, 'perks',
   'est', '조식, 중식, 석식 제공 (공식 홈페이지 복리후생 항목 — 식대 단가 미기재) (추정)', FALSE, NULL, 24),
  (@comp_id, 'housing_loan', '주택대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '최대 7천만원 주택대출 지원 (공식 채용 사이트 복지 문화 항목 — 금리·자격 미기재)', 25),
  (@comp_id, 'welfare_fund_loan', '생계대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '최대 1천만원 생계대출 지원 (공식 채용 사이트 복지 문화 항목 — 금리·자격 미기재)', 26),

  -- ── 가족·돌봄 (family) ── 복리후생 블록 1·2·3
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 시 휴가, 경조금, 화환, 물품 지원 (공식 홈페이지 복리후생 항목 — 금액·일수 미기재)', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 홈페이지 복리후생 항목 — 지원 학년·금액 미기재)', 31),
  (@comp_id, 'parenting', '든든 출산·육아 지원프로그램', 120, 'family',
   'est', '양육지원금 자녀 1인 월 10만원, 2인 월 30만원, 3인 월 50만원, 추가 자녀 1인당 월 20만원(자녀 1인 기준 연 120만원 환산, 2024 보도자료 기준 만 8세까지). 출산 축하금 자녀 1명당 1천만원(1회), 30만원 상당 출산 축하 선물, 자녀 첫돌 축하 금 2돈(공식 홈페이지 복리후생 · 2025 지속가능경영보고서)', FALSE, NULL, 32),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '든든 출산·육아 지원프로그램의 난임 지원 (공식 홈페이지 복리후생 항목 — 지원 내용·금액 미기재)', 33),

  -- ── 여가·라이프 (leisure) ── 복리후생 블록 1·2·6 · 지속가능경영보고서
  (@comp_id, 'resort', '법인 리조트·게스트하우스·휴양소', 50, 'leisure',
   'est', '법인 리조트 회원권 지원 및 자체 게스트하우스 운영, 휴양소 복지몰 운영, 휴양소포인트 지급 — 포인트 금액 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'club', '사내 동호회', 10, 'leisure',
   'est', '사내 동호회 활동 (공식 홈페이지 복리후생 항목 — 지원 금액 미기재) (추정)', FALSE, NULL, 41),
  (@comp_id, 'library', '사내 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '사내 도서관(파道) 운영 (2025 지속가능경영보고서 복리후생 제도 최적의 근무환경 항목)', 42),

  -- ── 유연근무 (flexibility) ── 복리후생 블록 3 · 지속가능경영보고서
  (@comp_id, 'flex_work', '탄력근무 (자녀를 둔 부·모)', NULL, 'flexibility',
   'est', NULL, TRUE, '만 12세 이하 또는 초등학교 6학년 이하 자녀를 둔 부·모 대상 탄력근무 (공식 홈페이지 복리후생 출산·육아 지원프로그램 항목 · 2025 지속가능경영보고서)', 50),

  -- ── 근무환경 (work_env) ── 복리후생 블록 4 · 채용 사이트
  (@comp_id, 'lounge', '휴식 공간 (포켓볼·안마의자)', NULL, 'work_env',
   'est', NULL, TRUE, '카페테리아, 포켓볼, 안마의자 등 휴식 공간 제공 (공식 채용 사이트 복지 문화 항목 · 공식 홈페이지 복리후생 항목)', 60),

  -- ── 건강·의료 (health) ── 복리후생 블록 5 · 보도자료
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '전 직원 단체 상해보험 가입 — 보장 금액 미기재 (추정)', FALSE, NULL, 70),
  (@comp_id, 'health_check', '종합검진 지원', 100, 'health',
   'est', '종합검진 지원, 2024 보도자료: 40세 미만 임직원과 배우자에게 격년 지원하던 종합검진을 필요 시 매년 지원. 독감 예방 접종 지원, 마스크 및 검사 키트 지원 — 검진 금액 미기재 (추정)', FALSE, NULL, 71),
  (@comp_id, 'medical', '의료비 지원 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인과 가족 구성원에게 100만원 이상 발생하는 의료비를 연간 3천만원 한도로 지원 (2024 보도자료 건강 플러스 프로그램 · 2025 지속가능경영보고서)', 72),

  -- ── 성장·커리어 (growth) ── 복리후생 블록 6 · 지속가능경영보고서
  (@comp_id, 'self_development', '자격증 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 교육 수강 뒤 자격시험 응시료를 전액 또는 기준에 따라 지원 (2025 지속가능경영보고서 구성원 성장 항목 — 연간 한도 미기재)', 80),

  -- ── 시간·휴가 (time_off) ── 채용 사이트
  (@comp_id, 'long_service_leave', '장기근속 휴가·포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속휴가 및 포상 (공식 채용 사이트 복지 문화 항목 — 근속 기준·휴가 일수·포상 내용 미기재)', 90),
  (@comp_id, 'leave_general', '하계·연말 단체 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계 및 연말 단체 휴가 사용 (공식 홈페이지 복리후생 항목 · 공식 채용 사이트 복지 문화 항목은 하계 및 연말 단체 Refresh 휴가 — 휴가 일수·별도 부여 여부 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
