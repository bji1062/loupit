-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오뱅크 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://recruit.kakaobank.com/welfare
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 카카오뱅크 인재영입 사이트 복리후생 페이지(recruit.kakaobank.com/welfare). 법인 자기 도메인이다.
--     Next.js 정적 내보내기라 서버 응답 HTML 본문에 5섹션 18항목이 전부 들어 있다(헤드리스 렌더 0회).
--     섹션 = 유연한 근로시간과 휴식 4 · 건강 지원 4 · 가족 지원 4 · 성장 지원 2 · 생활 밀착형 지원 4 (+ 판교 오피스 주소 1, 복지 아님).
--     robots.txt = User-agent: * / Allow: / (2026-09-28 확인). 본문 sha256 e9bfe979…0a612c4.
--   보조 = 같은 사이트 지원 가이드 FAQ 데이터(recruit.kakaobank.com/api/guides, JSON) 회사 생활 절 —
--     통근버스 1행의 근거. 같은 절의 재택근무 문답은 오피스 출근이 기본 원칙이라고 답해 구본 재택근무 행을 뺐다.
--   www.kakaobank.com 은 robots 가 일반 UA 에 Disallow: / 라 쓰지 않았다. 채용 ATS kakaobank.recruiter.co.kr 도
--     /appsite/ 밖은 Disallow 라 쓰지 않았다.
--   귀속: 카카오 어린이집 · 카카오 공동체 포인트 · 카카오프렌즈샵 할인 · 춘식도락 · 공동체 통근버스는 그룹 자산이지만
--     카카오뱅크 자기 페이지가 카카오뱅크 구성원에게 준다고 적었다. 그룹 통합 채용 페이지가 아니라 각주 없음.
--     카카오 본사 careers.kakao.com 과 다른 계열사 페이지는 보지 않았고 섞지 않았다.
--   금액: 원문 연액 1(welfare_point 자기주도 마일리지 연 600만 원) · 구본 추정 승계 2(health_check 100 · insurance 30).
--     구본 공식 수치 200(안식휴가비) · 120(영유아지원금)은 원문에 그 숫자가 없어 승계하지 않았다.
--     안식휴가비 300만 원은 부여 주기가 원문에 없어 연 환산하지 않았다(정성).
--   구본에서 뺀 행: stock_option(원문 없음 · 스톡옵션은 복지 아님) · remote_work(FAQ 가 오피스 출근 원칙이라 답함).
--   재코딩: self_development → welfare_point(자기주도 마일리지 포인트 — 성장·취미·운동·선물 자유 사용) ·
--     work_tools → office_furniture(전동 스탠딩 데스크 · 허먼밀러 체어는 IT 장비가 아니라 사무가구).
--   법정 제도 제외: 구본 parenting 행의 임신기 근무단축 · 산전후휴가 · 육아휴직 · 난임휴가는 법정이라 걷고,
--     parenting 코드는 원문 영유아지원금으로 다시 세웠다. 원문에 재취업지원서비스 문구 없음.
--   SORT 섹션 순서 = 페이지에서 카테고리가 처음 나온 순서
--     (flexibility 10 · time_off 20 · health 30 · work_env 40 · family 50 · perks 60 · growth 70 · leisure 80).
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): birthday_leave 서술의 원문 항목명 인용에서 반차 낱말 제거 · 재코딩 2(886 self_development→welfare_point · 891 work_tools→office_furniture) 확정 · parenting 행은 legal_rows 등록 해제 동반 — 최종 21행

-- 1) 회사 등록 (기존 회사 — 이 INSERT 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_bank', '카카오뱅크',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '핀테크/은행', 'K', 'https://recruit.kakaobank.com/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.kakaobank.com/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) — 유연한 근로시간과 휴식 ──
  (@comp_id, 'flex_work', '유연근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간을 스스로 조율하는 선택적 근로시간제 운영, 오전 11시부터 오후 4시까지 집중 근로시간이고 그 외 시간은 자율 관리 (공식 채용 사이트 복리후생 페이지 유연근로시간제 항목)', 10),

  -- ── 시간·휴가 (time_off) — 유연한 근로시간과 휴식 ──
  (@comp_id, 'long_service_leave', '안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '3년을 근속한 구성원에게 한 달 유급 안식휴가와 휴가비 300만 원, 제주 최고급 휴양 시설 할인가 이용 기회 제공 (공식 채용 사이트 복리후생 페이지 안식휴가 항목 — 3년마다 다시 주는지 여부 미기재)', 20),
  (@comp_id, 'leave_general', '2시간 단위 휴가 사용', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 2시간 단위로 나누어 필요한 순간에 사용 (공식 채용 사이트 복리후생 페이지 2시간 단위 휴가 사용 항목)', 21),
  (@comp_id, 'birthday_leave', '생일 반일 휴가·축하금', NULL, 'time_off',
   'est', NULL, TRUE, '생일에 반일 휴가와 축하금 지원 (공식 채용 사이트 복리후생 페이지 생일 항목 — 축하금 액수 미기재)', 22),

  -- ── 건강·의료 (health) — 건강 지원 ──
  (@comp_id, 'insurance', '단체상해보험 (본인·배우자·자녀·부모님·배우자 부모님)', 30, 'health',
   'est', '본인과 배우자, 자녀, 부모님, 배우자 부모님까지 단체상해보험으로 의료비와 진단금 지원 (공식 채용 사이트 복리후생 페이지 단체상해보험 항목 — 보장 한도 미기재) (추정)', FALSE, NULL, 30),
  (@comp_id, 'health_check', '종합 건강검진 (본인·가족 1인)', 100, 'health',
   'est', '본인과 가족 1인의 건강검진 매년 전액 지원, 검진 날 휴가 부여 (공식 채용 사이트 복리후생 페이지 종합 건강검진 항목 — 검진 비용 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'mental', '전문 심리상담', NULL, 'health',
   'est', NULL, TRUE, '업무 스트레스, 관계 고민 등 심리적 어려움이 생겼을 때 전문 상담 기관을 통한 1:1 심리 상담 (공식 채용 사이트 복리후생 페이지 전문 심리상담 항목 — 지원 횟수 미기재)', 32),

  -- ── 근무환경 (work_env) — 건강 지원 ──
  (@comp_id, 'office_furniture', '전동 스탠딩 데스크·허먼밀러 체어', NULL, 'work_env',
   'est', NULL, TRUE, '오래 앉아서 일하는 구성원의 건강과 집중력을 위해 전 좌석에 전동 스탠딩 데스크와 허먼밀러 체어 비치 (공식 채용 사이트 복리후생 페이지 근무 환경 항목)', 40),

  -- ── 가족·돌봄 (family) — 가족 지원 ──
  (@comp_id, 'childcare', '카카오 어린이집', NULL, 'family',
   'est', NULL, TRUE, '카카오 어린이집(늘예솔, 아지뜰, 별이든) 전액 지원 (공식 채용 사이트 복리후생 페이지 어린이집 항목 — 입소 기준·정원 미기재)', 50),
  (@comp_id, 'parenting', '영유아지원금', NULL, 'family',
   'est', NULL, TRUE, '만 3세~6세 자녀를 둔 구성원에게 영유아 지원금 24개월간 지원 (공식 채용 사이트 복리후생 페이지 영유아지원금 항목 — 지원 금액 미기재)', 51),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀가 대학생이면 대학교 등록금 지원 (공식 채용 사이트 복리후생 페이지 자녀 학자금 항목 — 지원 한도·자녀 수 미기재)', 52),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '구성원의 경조사에 경조 휴가와 경조금, 화환, 경조 용품 지원 (공식 채용 사이트 복리후생 페이지 경조사 지원 항목 — 경조금 액수 미기재)', 53),

  -- ── 경제적 부가혜택 (perks) — 성장 지원 · 생활 밀착형 지원 · 지원 가이드 ──
  (@comp_id, 'welfare_point', '자기주도 마일리지', 600, 'perks',
   'est', '성장, 취미, 운동, 나에게 주는 선물 등 자유롭게 활용하는 자기주도 마일리지 포인트 연 600만 원 지급 (공식 채용 사이트 복리후생 페이지 자기주도 마일리지 항목)', FALSE, NULL, 60),
  (@comp_id, 'housing_loan', '주거 목적 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택을 거주 목적으로 임차 혹은 구입하면서 대출을 받는 경우 대출이자 지원 (공식 채용 사이트 복리후생 페이지 주거 목적 대출 이자 지원 항목 — 지원 한도·이자율 미기재)', 61),
  (@comp_id, 'discount', '카카오프렌즈샵 20% 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오프렌즈샵 20% 할인 (공식 채용 사이트 복리후생 페이지 카카오 공동체 혜택 항목 — 연간 한도 미기재)', 62),
  (@comp_id, 'meal', '사내 식당 춘식도락·야근 식대', NULL, 'perks',
   'est', NULL, TRUE, '카카오 공동체 사내 식당 춘식도락에서 건강한 한 끼를 합리적인 가격으로 제공(공식 채용 사이트 복리후생 페이지 식사 및 간식 항목), 늦게까지 일한 날 야근 식대 지원(같은 페이지 야근 지원 항목) — 끼니·식대 단가 미기재', 63),
  (@comp_id, 'transport', '야근 교통비', NULL, 'perks',
   'est', NULL, TRUE, '늦게까지 일한 날 안전한 귀가를 위한 야근 교통비 지원 (공식 채용 사이트 복리후생 페이지 야근 지원 항목 — 지원 한도·적용 시각 미기재)', 64),
  (@comp_id, 'snack_bar', '카뱅 마트·사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '카뱅 마트와 사내 카페에서 간식과 음료를 합리적인 가격으로 제공 (공식 채용 사이트 복리후생 페이지 식사 및 간식 항목 — 할인율 미기재)', 65),
  (@comp_id, 'commute_subsidy', '통근버스 (카카오 공동체)', NULL, 'perks',
   'est', NULL, TRUE, '판교 오피스 근무자 대상 카카오 공동체 통근버스 지원 (공식 채용 사이트 지원 가이드 회사 생활 통근버스 문답 — 운행 노선·정류장 미기재)', 66),

  -- ── 성장·커리어 (growth) — 성장 지원 ──
  (@comp_id, 'edu_support', '외부 교육·해외 컨퍼런스 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부 교육과 해외 컨퍼런스 참가 적극 지원 (공식 채용 사이트 복리후생 페이지 사내외 교육 항목 — 지원 한도 미기재)', 70),

  -- ── 여가·라이프 (leisure) — 생활 밀착형 지원 ──
  (@comp_id, 'leisure_ticket', '카카오 공동체 포인트', NULL, 'leisure',
   'est', NULL, TRUE, '이모티콘, 톡클라우드, 멜론 등 카카오 계열사 서비스를 이용할 수 있는 공동체 포인트 매월 지급 (공식 채용 사이트 복리후생 페이지 카카오 공동체 혜택 항목 — 월 지급 포인트 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
