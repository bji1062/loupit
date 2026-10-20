-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 비바리퍼블리카(토스) 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://toss.im/career/culture
-- badge: est
--
-- 참고:
--   비상장 법인(종목코드 없음) · DART corp_code 01212921 · 브랜드 토스 = 법인 (주)비바리퍼블리카.
--   정본은 토스 채용 사이트 toss.im 의 팀 문화 페이지 — 사용자 붙여넣기 사본(2026-10-20 · sha256 47c5e998)으로 읽었다.
--     본문이 robots 가 막는 정적 호스트 번들에서만 그려져 수집기는 읽지 못했던 페이지(원본 HTML 에 복지 낱말 없음).
--   귀속: 팀 문화 페이지 주어는 토스커뮤니티(토스 계열 법인 전체) — 이 법인 자기 도메인 toss.im 의 그룹 주어 페이지라
--     이 페이지 근거 문구마다 출처 괄호 안 토스커뮤니티 공통 문구 각주. 기등록 형제 없음.
--     법인별 단서는 주택자금 한 항목뿐(토스뱅크 · 토스인슈어런스 = 대출 이자 지원, 토스씨엑스 = 제외) — 이 법인은 예외 법인이 아니라 1억 무이자 대출 적용, 행 서술에는 다른 법인 몫을 적지 않음.
--   보조 출처 1 = OpenDART 2025 사업보고서(접수 20260331003713) · 2026 반기보고서(접수 20260814003318).
--   보조 출처 2 = 토스피드 보도자료 2026-03-03 토스 첫 사내 어린이집 개원 https://toss.im/tossfeed/article/45941 (직장 어린이집 행).
--   보조 출처 3 = 같은 사이트의 이 법인 소속 채용 공고(소속 칸 토스) Barista 4071178003 · Childcare Teacher 7509161003(서류 마감 2026-10-25).
--     공고 소속 토스 = 비바리퍼블리카(같은 사이트 공고 문장 비바리퍼블리카(토스코어) · 토스(비바리퍼블리카)) — 공고 근거 행은 각주 없음.
--   금액: 원문에 연 금액 숫자 0건 — 전 행 BENEFIT_AMT NULL(주택자금 1억 원 = 대출 원금 한도).
--   제외: 업계 최고 수준의 연봉(임금) · 법정(육아휴직 · 배우자 출산휴가 · 육아기 단축근무 사용현황 표) ·
--     스톡옵션 · RSU 주식기준보상 · 임원 보수 칸 현금성 복리후생 금액 · 다른 법인(토스씨엑스 · 토스뱅크 등) 공고 문장.
--   공고 근거 3행 / 전체 21행(단독 2 = 생일축하금 · 명절상여 — 10-25 마감 공고, 보조 1 = 사내 카페 운영 시간).
--   SORT 섹션 순서 = 팀 문화 페이지 등장 순(flexibility 10 · time_off 20 · compensation 30 · perks 40 · growth 50 · work_env 60 · health 70 · family 80).
-- 붙여넣기 보강(2026-10-20): 출발본 = 웨이브 13 감사 모의 최종본 11행. 8행 추가 · 8행 출처 보강 · 3행 그대로 → 19행 · 정본 URL 을 community/toss 에서 팀 문화로 교체.
-- 검증 V8 반영: 주택자금 서술에서 다른 법인 몫 걷음 · 도서 몫 books 분리 · 업무 집중 공간 smart_office 추가 → 최종 21행.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('toss', '비바리퍼블리카(토스)',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '핀테크', 'T', 'https://toss.im/career/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'toss');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://toss.im/career/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 팀 문화 페이지 · 공시 ──
  (@comp_id, 'flex_work', '자율 출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연한 출퇴근 시간, 자율 출퇴근제로 업무 스타일에 따라 직접 근무 시간을 자유롭게 조정 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구), 선택근무제, 재직 중인 전 직원 대상 운영(임원·단시간 근로자·교대근무 적용자 등 제외) (2026 반기보고서 유연근무제도 사용현황 항목) — 의무 근무시간대·사용 조건 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격 근무 가능, 자율 출퇴근제로 근무 장소(출근 또는 원격 등)를 자유롭게 조정 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구), 원격근무제(재택근무 포함), 근무시스템을 통해 근로자가 자율적으로 사내 공간 외부(재택근무 포함)에서 근무할 수 있도록 지원 (2026 반기보고서 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 11),
  -- ── 휴가 (time_off) — 팀 문화 페이지 · 공시 재무제표 주석 ──
  (@comp_id, 'leave_general', '자율 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '승인 없는 자율 휴가, 휴가의 핵심은 승인이 아닌 공유, 보고나 승인 없이 자유롭게 휴가 사용 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 휴가 일수·부여 기준 미기재', 20),
  (@comp_id, 'long_service_leave', '장기근속 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 3년마다 리프레시 유급 휴가 1개월 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구), 장기근속(3년 이상) 임직원에게 안식휴가 등 장기종업원급여 제공, 근속기간에 따라 지급하는 장기유급휴가 (2025 사업보고서 재무제표 주석 장기종업원급여 항목) — 사용 조건 미기재', 21),
  -- ── 보상 (compensation) — 팀 문화 페이지 · 공시 · 채용 공고 ──
  (@comp_id, 'incentive', '반기별 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '반기별 성과급 지급 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구), 성과인센티브 등 인센티브 및 복지 프로그램 운영 (2025 사업보고서 환경 및 종업원 등에 관한 사항 항목), 모든 임직원과 동일한 지급률을 반영한 인센티브 (2026 반기보고서 보수 산정기준 항목) — 지급 기준·지급률 미기재', 30),
  (@comp_id, 'holiday_gift', '명절상여', NULL, 'compensation',
   'est', NULL, TRUE, '계약직 Childcare Teacher 채용 공고 기준 연봉 외 명절상여 등 기타 현금성 복리후생 별도 지급 (공식 채용 공고 Childcare Teacher 처우 항목) — 금액·지급 시기·다른 직무 적용 미기재', 31),
  -- ── 생활 · 편의 (perks) — 팀 문화 페이지 · 채용 공고 ──
  (@comp_id, 'meal', '식대 (개인 법인카드)', NULL, 'perks',
   'est', NULL, TRUE, '개인 법인카드 지급, 식대 등에 자율 사용 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 한도·사용 기준 미기재', 40),
  (@comp_id, 'transport', '야근교통비 (개인 법인카드)', NULL, 'perks',
   'est', NULL, TRUE, '개인 법인카드 지급, 야근교통비 등에 자율 사용 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 한도·사용 기준 미기재', 41),
  (@comp_id, 'housing_loan', '주택자금 무이자 대출 (최대 1억 원)', NULL, 'perks',
   'est', NULL, TRUE, '1억 무이자 주택자금 지원, 주거 걱정 없이 일할 수 있도록 최대 1억 원의 주택자금 대출을 무이자로 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 대상 요건·상환 조건 미기재', 42),
  (@comp_id, 'snack_bar', '사내 카페 커피 사일로·무인 편의점', NULL, 'perks',
   'est', NULL, TRUE, '전문 바리스타가 운영하는 사내 카페 커피 사일로(Coffee Silo), 모든 팀원들이 가장 즐겨찾는 공간, 언제나 열려있는 무인 편의점에서 다양한 간식부터 각종 비상약품, 문구류까지 모두 무료로 이용 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구), 사내카페 운영 시간 오전 9시~오후 9시 (공식 채용 공고 Barista 항목) — 카페 이용 비용 미기재', 43),
  (@comp_id, 'barber_shop', '사내 헤어살롱', NULL, 'perks',
   'est', NULL, TRUE, '전문 미용사가 상주하는 사내 헤어살롱 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 이용 요금·운영 시간 미기재', 44),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '매월 통신비 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 금액·지급 기준 미기재', 45),
  (@comp_id, 'birthday_gift', '생일축하금', NULL, 'perks',
   'est', NULL, TRUE, '계약직 Childcare Teacher 채용 공고 기준 연봉 외 생일축하금 등 기타 현금성 복리후생 별도 지급 (공식 채용 공고 Childcare Teacher 처우 항목) — 금액·다른 직무 적용 미기재', 46),
  -- ── 성장 · 교육 (growth) — 팀 문화 페이지 ──
  (@comp_id, 'edu_support', '워크샵·세미나 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '워크샵, 세미나 등 업무 교육비 100% 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 연간 한도·신청 절차 미기재', 50),
  (@comp_id, 'books', '도서 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 등 업무 교육비 100% 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 연간 한도·신청 절차 미기재', 51),
  -- ── 근무 환경 (work_env) — 팀 문화 페이지 ──
  (@comp_id, 'work_tools', '최고급 하드웨어·업무용 소프트웨어', NULL, 'work_env',
   'est', NULL, TRUE, '최고급 하드웨어 및 업무용 소프트웨어 제공 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 장비 종류·교체 주기 미기재', 60),
  (@comp_id, 'smart_office', '업무 집중 공간', NULL, 'work_env',
   'est', NULL, TRUE, '아무런 방해 없이 일에만 집중하고 싶을 때 혼자 만의 공간 활용, 사무실 곳곳에 오픈형이 아닌 벽으로 분리된 자리, 방음이 잘 되는 폰부스 등 마련 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 설치 사무실·이용 방식 미기재', 61),
  -- ── 건강 (health) — 팀 문화 페이지 ──
  (@comp_id, 'insurance', '직장단체보험 (가족 포함)', NULL, 'health',
   'est', NULL, TRUE, '직장단체보험(가족 포함) 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 보장 내용·보험 종류 미기재', 70),
  (@comp_id, 'fitness', '체력단련비 지원', NULL, 'health',
   'est', NULL, TRUE, '매월 체력단련비 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 금액·사용처 미기재', 71),
  -- ── 가족 (family) — 팀 문화 페이지 · 토스피드 보도자료 ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사비 지원 (공식 채용 페이지 팀 문화 항목, 토스커뮤니티 공통 문구) — 경조 범위·금액 미기재', 80),
  (@comp_id, 'childcare', '직장 어린이집 (토스 이음 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '토스 임직원 대상 첫 사내 어린이집 토스 이음 어린이집 2026년 3월 개원, 역삼동 본사 사옥 인근, 정원 43명, 0세부터 5세까지 영유아 대상, 오전 8시부터 오후 9시까지 운영, 야간 연장 보육 및 석식 지원, 아픈 원아를 위한 돌봄 체계, 타사 어린이집과의 공동 운영으로 제휴한 보육시설 24곳을 포함해 총 25개 어린이집 중 근무지와 거주지 여건에 맞는 시설 선택 (2026년 3월 토스 공식 보도자료 사내 어린이집 개원 항목) — 이용 비용·입소 순서 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
