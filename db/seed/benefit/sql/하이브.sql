-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 하이브 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://careers.hybecorp.com/ko/benefits
-- badge: est
--
-- 참고:
--   정본은 하이브 채용 사이트 HYBE Careers(careers.hybecorp.com, 그리팅 ATS · 회사 자기 도메인)의 복리후생 페이지다.
--   공식 홈 hybecorp.com 헤더의 지원하기 메뉴가 careers.hybecorp.com/ko/home 으로 이어진다(렌더 1회로 확인).
--   서버 응답 HTML(SSR)에 9항목 본문이 그대로 있다 — 항목 옆 그림 9장은 글자 없는 아이콘(2장 내려받아 확인).
--   robots: careers.hybecorp.com/robots.txt 는 Allow / + 지원서 · /m/ · /a/ 경로만 Disallow — /ko/benefits 허용.
--   귀속: 이 사이트는 하이브 · 위버스컴퍼니 · 하이브 IPX · 쏘스뮤직 · ABD · 드리마지 공고를 함께 싣는 그룹 통합 채용 사이트이고
--   복리후생 페이지 머리에 국가별/법인별 복리후생은 차이가 있을 수 있다는 각주가 있다 — 전 행 QUAL_DESC 말미에
--   (그룹 통합 채용 기준) 각주를 단다. 레이블 · 자회사 전용 페이지의 복지는 싣지 않았다.
--   보조 출처: 같은 사이트 HOW WE WORK 컬처 프로그램 페이지(/ko/culture)의 하이브 컬처데이 1항목.
--   제외: 수평적 커뮤니케이션 · 님 호칭(조직문화) · 타운홀 · 히트맨과 수다 · 사다리 · 치어스 데이(소통 · 축하 행사) ·
--     Win Together Program(신규 입사자 온보딩) · HI HIGH(외부 청년 교육 사업) · 육아휴직 지원(법정).
--   금액: 원문에 금액이 없다 — 전 행 정성. 구본 추정치는 다른 회사 데이터라 승계하지 않았다.
--   구본 폐기: 구본 9행은 게임사 하이브로(드래곤빌리지) 데이터였다 — 전부 버리고 하이브 공식 원문으로 다시 세웠다.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (flexibility 10 · time_off 20 · work_env 30 · health 40 · perks 50 · family 60 · leisure 70).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): 수집 12행 원문 확인 · 하이브 2025 지속가능경영보고서(hybecorp.com 지속가능경영보고서 게시판 첨부 PDF p.65~67) 복리후생 제도 현황에서 누락 11행 추가(long_service_leave · leave_general · parking · clinic · snack_bar · transport · team_dinner · event · resort · company_event · summer_vacation_subsidy) · mental · insurance · parenting 서술 보강 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hybe', '하이브',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '엔터테인먼트', 'H', 'https://careers.hybecorp.com/ko/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hybe');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.hybecorp.com/ko/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 복리후생 1번째 항목 ──
  (@comp_id, 'flex_work', '자율 출퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '자율 출퇴근에 기반한 자율적인 업무 시간 관리 (공식 채용 사이트 복리후생 자율적인 업무 시간 관리 항목 — 코어타임 여부 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 10),

  -- ── 시간·휴가 (time_off) — 복리후생 1번째 항목 ──
  (@comp_id, 'refresh_leave', '무제한 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '무제한 휴가제에 기반한 자율적인 업무 시간 관리 (공식 채용 사이트 복리후생 자율적인 업무 시간 관리 항목 — 사용 승인 절차 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 20),
  (@comp_id, 'long_service_leave', '리프레시 휴가 (근속 3·6·9년)', NULL, 'time_off',
   'est', NULL, TRUE, '근속기간 3년, 6년, 9년 구성원 대상 리프레시 휴가 및 휴가비 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 리프레시 휴가제도 항목 — 휴가 일수·휴가비 금액 미기재)', 21),
  (@comp_id, 'leave_general', '토요일 근무 보상 휴가 (STO)', NULL, 'time_off',
   'est', NULL, TRUE, '휴무일(토요일) 근무 시 익월 휴가 지급 (공식 지속가능경영보고서 2025 복리후생 제도 현황 STO(Saturday Time Off) 항목 — 휴가 일수 미기재)', 22),

  -- ── 근무환경 (work_env) — 복리후생 3 · 4번째 항목 ──
  (@comp_id, 'work_tools', '직무별 최적화 장비·소프트웨어', NULL, 'work_env',
   'est', NULL, TRUE, '일에 몰입할 수 있는 사무공간 및 직무별 최적화된 장비와 소프트웨어 제공 (공식 채용 사이트 복리후생 사무공간·장비 항목 — 장비 종류 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 30),
  (@comp_id, 'lounge', '다양한 컨셉의 휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '마사지 체어, 음악감상, 게임존, 라이브러리 등 창의력이 샘솟는 다양한 컨셉의 휴게 공간 (공식 채용 사이트 복리후생 휴게 공간 항목 — 이용 시간 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 31),
  (@comp_id, 'parking', '사옥별 주차 지원', NULL, 'work_env',
   'est', NULL, TRUE, '구성원의 출퇴근 편의를 위한 사옥별 주차 구역 이용 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 주차지원 항목 — 주차비 부담 여부 미기재)', 32),

  -- ── 건강·의료 (health) — 복리후생 5 · 9번째 항목 ──
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '구성원의 신체적 건강을 책임지는 피트니스 센터 운영 (공식 채용 사이트 복리후생 피트니스 센터와 심리상담 서비스 항목 — 이용 요금 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 40),
  (@comp_id, 'mental', '심리상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '구성원의 심리적 건강을 책임지는 심리상담 서비스 운영 — 연간 8회 심리상담 지원(대면·화상·전화), 용산 사옥 내 찾아오는 심리상담 운영 (공식 채용 사이트 복리후생 피트니스 센터와 심리상담 서비스 항목 · 공식 지속가능경영보고서 2025 복리후생 제도 현황 심리상담서비스 항목) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 41),
  (@comp_id, 'health_check', '종합검진 (연 1회)', NULL, 'health',
   'est', NULL, TRUE, '건강하고 행복한 삶을 위한 종합검진 연 1회 지원 (공식 채용 사이트 복리후생 종합검진과 실손보험 항목 — 검진 기관·지원 금액·가족 포함 여부 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 42),
  (@comp_id, 'insurance', '실손보험 지원', NULL, 'health',
   'est', NULL, TRUE, '건강하고 행복한 삶을 위한 실손보험 지원 — 단체상해보험으로 실손보험 혹은 치과보험 지원 (공식 채용 사이트 복리후생 종합검진과 실손보험 항목 · 공식 지속가능경영보고서 2025 복리후생 제도 현황 단체상해보험 항목 — 가족 포함 여부 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 43),
  (@comp_id, 'clinic', '사내 의원 (Health Care Center)', NULL, 'health',
   'est', NULL, TRUE, '의사 1인 및 간호사 2인이 상주하는 사내 의원 운영 — 내과·외과·정신건강의학과 진료, 주사처치, 상비약 지급, 회복실 운영, 독감·자궁경부암·대상포진 예방접종 (공식 지속가능경영보고서 2025 복리후생 제도 현황 사내 의원 항목 · 사내 의원 운영 현황)', 44),

  -- ── 경제적 부가혜택 (perks) — 복리후생 6 · 7번째 항목 ──
  (@comp_id, 'meal', '중석식비 보조', NULL, 'perks',
   'est', NULL, TRUE, '음료 제공 및 사내식당 등을 활용한 중석식비 보조 (공식 채용 사이트 복리후생 중석식비 보조 항목 — 보조 금액 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 50),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '구성원의 라이프 스타일에 따라 자율적으로 활용할 수 있는 복지포인트 지급 (공식 채용 사이트 복리후생 복지포인트 항목 — 지급 금액 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 51),
  (@comp_id, 'snack_bar', '사내 카페·캔틴', NULL, 'perks',
   'est', NULL, TRUE, '용산 사옥 최상층 사내 카페 하이브 프릳츠에서 저렴한 비용으로 음료 제공, 캔틴 음료 분기별 교체, 24시간 스마트 자판기 운영 (공식 지속가능경영보고서 2025 사내 식당·카페 및 캔틴 항목 — 무료 품목 미기재)', 52),
  (@comp_id, 'transport', '야근·휴일 교통비', NULL, 'perks',
   'est', NULL, TRUE, '야근 및 휴일 출근 시 교통비 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 야근·휴일 교통비 항목 — 지원 한도 미기재)', 53),
  (@comp_id, 'team_dinner', '회식비·팀 워크숍 지원', NULL, 'perks',
   'est', NULL, TRUE, '팀원 2/3 이상 참여 시 월 1회 회식비 지원, 반기 1회 팀 워크숍 비용 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 회식비 · 팀 워크숍 지원 항목 — 1인당 금액 미기재)', 54),

  -- ── 가족·돌봄 (family) — 복리후생 8번째 항목 ──
  (@comp_id, 'parenting', '출산휴가 최대 180일·급여 100%', NULL, 'family',
   'est', NULL, TRUE, '새로운 가족의 탄생을 축하하는 출산휴가 최대 180일, 급여 100% 제공, 출산 시 축하금·출산선물 지원, 본인 혹은 배우자 자연유산 시 위로금 지원, 만 5세 이하 자녀 어린이집 교육비 지원(정부보육료의 50% 및 추가 복지포인트 지급) (공식 채용 사이트 복리후생 출산 지원 항목 · 공식 지속가능경영보고서 2025 복리후생 제도 현황 출산 · 영유아 보육료 지원 항목 — 축하금·위로금 금액 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 60),
  (@comp_id, 'event', '상조 서비스·경조사 화환', NULL, 'family',
   'est', NULL, TRUE, '부모, 형제, 자녀 대상 상조 지원 및 조부모 대상 상조물품 지원, 가족 결혼·칠순·팔순·사망 등 경조사 시 화환 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 상조서비스 · 경조사화환 항목 — 경조금 미기재)', 61),

  -- ── 여가·라이프 (leisure) — HOW WE WORK 컬처 프로그램 ──
  (@comp_id, 'culture_day', '하이브 컬처데이', NULL, 'leisure',
   'est', NULL, TRUE, '구성원의 문화 콘텐츠 체험과 리프레시를 위해 하이브에서 진행하는 공식적인 노는 날 (공식 채용 사이트 HOW WE WORK 컬처 프로그램 하이브 컬처데이 항목 — 횟수·주기 미기재) (그룹 통합 채용 기준) 국가별·법인별 일부 상이 가능', 70),
  (@comp_id, 'resort', '제휴 휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '할인된 요금의 제휴 휴양시설(리조트, 호텔 등) 이용 지원 (공식 지속가능경영보고서 2025 복리후생 제도 현황 휴양시설 항목 — 할인율 미기재)', 71),
  (@comp_id, 'company_event', '가족 초청 행사 (HYBE Family Night)', NULL, 'leisure',
   'est', NULL, TRUE, '2023년부터 구성원의 가족을 초청해 회사 공간을 체험하는 HYBE Family Night 행사 운영(2025년 용산 사옥 여의도 불꽃축제 관람), 가족 초청 사옥 가이드 투어, 가족 초청 행사 연 2회 (공식 지속가능경영보고서 2025 HYBE Family Day 항목 · 지속가능경영위원회 메시지)', 72),
  (@comp_id, 'summer_vacation_subsidy', '휴가 전부 사용 보너스', NULL, 'leisure',
   'est', NULL, TRUE, '연말 기준 개인에게 부여된 휴가를 모두 사용한 구성원 대상 보너스 50만 원 지급 (공식 지속가능경영보고서 2025 복리후생 제도 현황 휴가 사용 보너스 항목)', 73)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
