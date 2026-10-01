-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 컴투스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.com2us.com/ko/esg/esg-contents-reports-list
-- badge: est
--
-- 참고:
--   정본은 컴투스 기업 사이트(www.com2us.com) 상단 메뉴 ESG > ESG 보고서 목록이다. 행 근거의 중심은
--   그 목록이 주는 컴투스 ESG 보고서 2026(국문 PDF, /api/files/3055/download, 112쪽) p.33 · 36~38 · 43 이다.
--   보고서 머리말: 비재무 성과의 범위는 본사에 한정 — 계열사(컴투스홀딩스 · 컴투스플랫폼 등) 제도가 섞이지 않는다.
--   보조 출처: 같은 목록의 ESG 보고서 2025(p.36~38 — 사내식당 3식 무료 · 2024년 경영협의회 안건)와
--     기업 사이트 회사소개 메뉴가 링크한 공식 사보 컴투스온(on.com2us.com, WordPress REST API 로 본문 수신) 제도 소개 기사.
--     사보는 컴투스 그룹 공용이라 컴투스 제도라고 밝힌 기사만 썼다.
--   채용 사이트 com2us.recruiter.co.kr/career/welfare(컴투스그룹 채용, 상단 메뉴 채용 링크)는 Next.js CSR 이고
--     본문을 주는 api-recruiter.recruiter.co.kr 이 robots 전면 금지라 쓰지 않았다(헤드리스 렌더도 그 API 를 부른다).
--   robots: www.com2us.com · on.com2us.com 허용. 헤드리스 렌더 0회.
--   금액: 명시값 1행(welfare_point 연 250) · 승계 추정치 4행(meal 432 · insurance 30 · resort 50 ·
--     commute_subsidy 120 — NOTE 끝에 (추정)). health_check 100 은 원문이 2년 주기라 승계하지 않았다.
--   구본에서 뺀 행: event · holiday_gift · birthday_gift(현행 공식 원문 없음).
--   재코딩: leave_general → foundation_day_leave(창립기념일 대체 휴가) · refresh_leave → flex_work(리커버리데이, flex_work 에 합침).
--   SORT 섹션 순서 = ESG 보고서 2026 에서 카테고리가 처음 나온 순서
--     (compensation 10 · flexibility 20 · time_off 30 · family 40 · health 50 · leisure 60 · growth 70 · perks 80).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 수집 21행 원문 확인 · 컴투북스 books → library(사내 카페 안 도서공간 = 북카페 코드, leisure) · ESG 보고서 2026 기후변화 리스크 관리 항목의 재택근무 제도로 remote_work 1행 추가 · 인프런 교육비 edu_support 1행 추가 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('com2us', '컴투스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'C', 'https://www.com2us.com/ko/esg/esg-contents-reports-list');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'com2us');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.com2us.com/ko/esg/esg-contents-reports-list'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — ESG 보고서 2026 p.33 ──
  (@comp_id, 'incentive', '장·단기 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '연봉과 함께 장·단기 인센티브를 보상 체계로 운영 (컴투스 ESG 보고서 2026 평가 및 보상 항목 — 지급 기준·지급 수준 미기재)', 10),

  -- ── 근무유연성 (flexibility) — ESG 보고서 2026 p.36 ──
  (@comp_id, 'flex_work', '선택적 근로시간제·리커버리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '월 단위로 근무시간을 관리하는 선택적 근로시간제 — 출근 시간 오전 9시~10시 30분 사이 선택, 코어타임 오전 10시 30분~오후 3시, 업무 상황에 따라 코어타임 면제 신청 가능(컴투스 ESG 보고서 2026 유연근무제 항목 · 사보 컴투스온 2026년 8월 근무 제도 기사). 리커버리데이: 매월 두 번째 금요일 출근 여부를 선택하는 제도로 신청 시 휴무, 월 기준 근무시간은 유지, 공휴일과 겹치면 날짜 조정(같은 보고서 · 사보 컴투스온 2026년 2월 리커버리데이 기사)', 20),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원 통근에 따른 탄소 배출을 줄이기 위해 통근버스 운영과 함께 재택근무 제도를 병행 (컴투스 ESG 보고서 2026 기후변화 리스크 관리 항목) — 대상·사용 일수·횟수 미기재', 21),

  -- ── 시간·휴가 (time_off) — ESG 보고서 2026 p.36 · 사보 ──
  (@comp_id, 'leave_general', '1시간 단위 휴가 분할 사용', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 1시간 단위로 나눠 필요한 시간만큼 사용하는 시간 단위 휴가 제도 (컴투스 ESG 보고서 2026 유연근무제 항목 · 사보 컴투스온 2026년 8월 근무 제도 기사)', 30),
  (@comp_id, 'long_service_leave', '장기근속 휴가 (만 3년마다 5일·휴가 지원금)', NULL, 'time_off',
   'est', NULL, TRUE, '입사 후 만 3년마다 장기근속 휴가 5일과 휴가 지원금 부여 (컴투스 ESG 보고서 2026 유연근무제 항목). 사보 컴투스온 2024년 10월 장기근속자 기사 기준 컴투스 그룹 휴가 지원금 60만원 — 보고서에는 지원금 금액 미기재', 31),
  (@comp_id, 'foundation_day_leave', '창립기념일 대체 유급 휴가 (12월 26일)', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일(7월 31일)을 2023년부터 12월 26일로 대체해 유급 휴가 부여 (사보 컴투스온 2023년 12월 연말 이벤트 안내 기사 — 2024년 이후 시행 여부 미기재)', 32),

  -- ── 가족·돌봄 (family) — ESG 보고서 2026 p.36 · 2025 p.38 ──
  (@comp_id, 'parenting', '임신기 근로시간 단축 확대·자녀 교육비·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '임신 전 기간 1일 2시간 유급 근로시간 단축(단축 기간 급여 100% 보전), 자녀 어린이집·유치원 교육 비용 지원, 자녀 초·중·고·대학교 입학 축하금 지급 (컴투스 ESG 보고서 2026 가족친화제도 항목), 임신 축하 선물 (ESG 보고서 2025 2024년 경영협의회 안건) — 지원 금액 미기재', 40),

  -- ── 건강·의료 (health) — ESG 보고서 2026 p.36 · 37 · 43 · 사보 ──
  (@comp_id, 'insurance', '실손보험 (본인·배우자·자녀)', 30, 'health',
   'est', '본인·배우자·자녀 전원 실손보험 제공, 자녀 수 제한 없음 (컴투스 ESG 보고서 2026 가족 지원 복지제도 항목) — 보험료 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'fitness', '제휴 피트니스 센터 무료 이용', NULL, 'health',
   'est', NULL, TRUE, '본사 인근 피트니스 센터와 제휴해 운동 시설 무료 이용 (컴투스 ESG 보고서 2026 임직원 건강증진 활동 항목 · ESG 보고서 2025 제휴 헬스장 운영 항목)', 51),
  (@comp_id, 'mental', '심리상담 해피민트 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '전문 심리 상담 프로그램 해피민트(EAP 서비스) — 전국 1,955개 전문 상담기관과 연계한 온라인·오프라인 상담, 정밀 심리검사, 테마별 집단 프로그램 (컴투스 ESG 보고서 2026 임직원 건강증진 활동 항목) — 이용 횟수 미기재', 52),
  (@comp_id, 'health_check', '종합건강검진 (2년 주기·본인+동반 가족 1인)', NULL, 'health',
   'est', NULL, TRUE, '2년에 한 번 제휴 검진기관에서 종합건강검진, 임직원 본인과 동반 가족 1인(형제·친척 제외) 기본 항목 전액 지원, 검진 당일 근무시간 최대 4시간 인정, 추가 가족 검진은 제휴 할인가 (사보 컴투스온 2026년 1월 건강검진 제도 소개 기사) — 수면 내시경·추가 항목은 본인 부담', 53),

  -- ── 여가·라이프 (leisure) — ESG 보고서 2026 p.36 · 38 · 2025 p.38 · 사보 ──
  (@comp_id, 'company_event', '플레이 그라운드 가족 행사·한가위 미니게임 한마당', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과 가족을 위한 플레이 그라운드 가족 행사, 반려동물을 키우는 임직원을 위한 반려동물 수제간식 만들기 체험 (컴투스 ESG 보고서 2026 가족 참여 프로그램 항목), 추석 맞이 사내 이벤트 미니게임 한마당 2025년·2026년 개최 (같은 보고서 경영협의회 항목 · 사보 컴투스온 2026년 9월 기사) — 개최 주기 미기재', 60),
  (@comp_id, 'resort', '휴양소 회원권·제휴 호텔·리조트', 50, 'leisure',
   'est', '휴양소 회원권 운영(ESG 보고서 2025, 2024년 경영협의회 신규 휴양소 회원권 구매), 제휴 호텔·리조트 임직원 전용 할인·성수기 추첨(사보 컴투스온 2026년 2월) — 지원액 미기재 (추정)', FALSE, NULL, 61),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원금 — esports 동호회 정기 모임 1인당 최대 17,000원 지원과 분기별 e스포츠 직관 관람비 지원(사보 컴투스온 2026년 5월 동호회 기사), 독서 동호회 지원금으로 도서 구매(같은 사보 2025년 1월 기사) — 동호회별 지원 기준 미기재', 62),

  (@comp_id, 'library', '사내 도서공간 컴투북스', NULL, 'leisure',
   'est', NULL, TRUE, '2025년 신설한 사내 도서 지원 프로그램 컴투북스(Com2Books) — 사내 카페 안 도서공간에서 도서 대여·반납, 큐레이션존과 독서 공간 운영 (컴투스 ESG 보고서 2026 복지제도 항목 · 사보 컴투스온 2025년 9월 컴투북스 오픈 기사)', 63),
  (@comp_id, 'edu_support', '직무 온라인 강의 교육비 지원 (연 100만원 한도)', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 온라인 강의(인프런) 수강 교육비를 1인당 연간 100만 원까지 지원, 교육훈련 신청서 결재 후 수강 — 취업·창업·직무 무관 자격증 과정 제외, 미수료 시 1년간 사내 교육 신청 제한 (사보 컴투스온 2025년 11월 · 2024년 2월 · 2023년 4월 교육 복지 기사)', 70),

  -- ── 경제적 부가혜택 (perks) — ESG 보고서 2026 p.37 · 38 · 2025 p.37 · 사보 ──
  (@comp_id, 'meal', '사내식당 Cooking (조식·중식·석식 무료)', 432, 'perks',
   'est', '조식, 중식, 석식 모두 무료로 제공하는 사내 식당 Cooking (컴투스 ESG 보고서 2025 복지제도 항목 · 2026 구내식당 운영) — 1식 단가 미기재 (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '스낵바 Snacking·사내 카페 Healing·야간매점', NULL, 'perks',
   'est', NULL, TRUE, '각 층 사내 탕비실에 다양한 간식을 갖춘 스낵바 Snacking, 음료를 저렴한 가격에 제공하는 사내 카페 Healing (컴투스 ESG 보고서 2025 복지제도 항목 · 2026 스낵바·사내 카페 운영), 오후 8시 이후 근무자를 위한 사내 야간매점 (사보 컴투스온 2023년 5월 · 2025년 9월 기사) — 카페 음료 가격 미기재', 81),
  (@comp_id, 'welfare_point', '복지카드 (연 250만원)', 250, 'perks',
   'est', '연간 250만 원 상당의 복지카드 제공 (컴투스 ESG 보고서 2026 복지제도 항목 — 2025년 경영협의회에서 200만 원에서 250만 원으로 상향)', FALSE, NULL, 82),
  (@comp_id, 'commute_subsidy', '임직원 전용 셔틀버스 (판교역·미금역)', 120, 'perks',
   'est', '판교역, 미금역에서 사옥까지 운행하는 임직원 전용 셔틀버스 (컴투스 ESG 보고서 2026 복지제도 항목) — 운행 횟수·본인 부담 여부 미기재 (추정)', FALSE, NULL, 83),
  (@comp_id, 'welfare_fund', '사내근로복지기금', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 안정적이고 지속적인 복리후생 기반을 위해 2025년 11월 경영협의회에서 사내근로복지기금 설립 의결 (컴투스 ESG 보고서 2026 건전한 노사관계 형성 항목) — 기금 사업 내용 미기재', 84),
  (@comp_id, 'housing_loan', '주택자금대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출 이자지원 제도 (사보 컴투스온 2023년 2월 복지 소개 기사 — 지원 한도·이자율·현행 여부 미기재)', 85),
  (@comp_id, 'discount', '여기어때·쏘카 비즈니스 계정 할인', NULL, 'perks',
   'est', NULL, TRUE, '여기어때 비즈니스 계정 예약 시 할인·페이백, 쏘카 비즈니스 계정 전용 쿠폰으로 주중·주말 할인 (사보 컴투스온 2026년 2월 리커버리데이 기사 — 할인율 미기재, 제휴 내용은 시기와 제휴처에 따라 변동)', 86)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
