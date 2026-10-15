-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한일시멘트 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.hanilcement.com/html/recruit/rb_01.html
-- badge: est
--
-- 참고:
--   정본은 상장 법인 한일시멘트(주)(DART 01319808)의 자기 도메인 www.hanilcement.com 인재채용 > 복리후생 페이지다.
--   SSR 이라 원본 HTML 에 복리후생 8블록 텍스트가 다 있다(블록 아이콘 gif 는 장식 — 이미지 판독 불필요).
--   페이지 주어는 한일시멘트는 으로 법인 단수 · 그룹 공통 단서 없음 — 각주 없음.
--   보조 출처: 같은 도메인 ESG경영 > 지속가능경영보고서 목록의 최신 판 한일 2025 지속가능경영보고서
--   (발행 2026-06 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 한일홀딩스 + 한일시멘트, 2025-11 한일현대시멘트 흡수합병 반영).
--   보고서 문장 중 주어가 한일시멘트는 또는 한일홀딩스와 한일시멘트는 인 것은 각주 없이,
--   주어가 한일은(두 법인 통합) 이고 법인 구분이 없는 문장이 근거인 행은 끝에 통합 보고 각주를 단다.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814003685) 직원 등 현황 유연근무제도 사용 현황 주석 ·
--   별도재무제표 주석 기타장기종업원급여(장기근속포상 제도). 직원 916명(2026-06-30).
--   금액: 원문 숫자는 출산 축하금(1회성)과 장기근속 포상(1회성)뿐 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(정부지정 공휴일 · 특수 · 배치 전 · 수시 건강진단 · 임신기 근로시간 단축 · 육아휴직 · 육아기 근로시간 단축 ·
--     퇴직연금) · 업무 교육(직무교육 · 신입 밸류업 캠프 · 멘토링 · 승진자 레벨업 캠프 · 리더십 · 법정의무교육 · 직급별 리텐션) ·
--     안전 포상(무재해 포상금 · 안전포상제도) · 임원 보수 칸(자가운전보조금 등) · 가족수당(급여성 수당) ·
--     연봉제 개인별 보상체계(급여 체계) · 각종 보조금 지급(내용 없음) · 블레저(본인 휴가 사용) · 협력사 대상 시설 · 지원.
--   공고 근거 0행 / 전체 32행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · family 20 · leisure 30 · health 40 · work_env 50 · time_off 60 ·
--     growth 70 · compensation 80), 보고서 · 공시에만 있는 flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-15): 이사 지원비 행에서 직원 숙소 구절 걷기 · 근속 가산 휴가 서술에 법정 가산 상회 구조 · 76쪽 품질분임조 포상을 우수 사원 포상 행에 병합 · 89쪽 Job Posting career · 90쪽 자격취득·학위과정 self_development · 92쪽 블레저 workation 추가(참고 블록 제외 줄의 블레저는 이 판정으로 뒤집힘) — 최종 35행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanil_cement', '한일시멘트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '시멘트', 'H', 'https://www.hanilcement.com/html/recruit/rb_01.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanil_cement');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hanilcement.com/html/recruit/rb_01.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 · 주거 (perks) — 공식 채용 페이지 복리후생 1 · 5 · 7번 · 보고서 92쪽 ──
  (@comp_id, 'welfare_fund_loan', '복지기금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '업계 최고 수준의 사내근로복지 기금, 복지기금 대출 지원 (공식 채용 페이지 복리후생 1번 항목) — 대출 용도·한도·이율 미기재', 10),
  (@comp_id, 'welfare_point', '여가활동비 지원', NULL, 'perks',
   'est', NULL, TRUE, '여가활동비 지원 (공식 채용 페이지 복리후생 5번 기타 복리후생 항목) — 지급 금액·지급 방식·사용처 미기재', 11),
  (@comp_id, 'birthday_gift', '생일선물 지급', NULL, 'perks',
   'est', NULL, TRUE, '생일선물 지급 (공식 채용 페이지 복리후생 5번 기타 복리후생 항목) — 선물 품목·금액 미기재', 12),
  (@comp_id, 'housing_support', '주택 취득 지원금', NULL, 'perks',
   'est', NULL, TRUE, '주택 취득 지원금 지급 (공식 채용 페이지 복리후생 7번 주택 지원금 지급, 대출 지원 항목) — 지원 금액·지급 대상 미기재', 13),
  (@comp_id, 'housing_loan', '주택자금·생활안정 자금 저리 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금, 생활안정 자금 저리 대출 가능 (공식 채용 페이지 복리후생 7번 주택 지원금 지급, 대출 지원 항목) — 대출 한도·이율 미기재', 14),
  (@comp_id, 'relocation', '이사 지원비·부임 휴가', NULL, 'perks',
   'est', NULL, TRUE, '이사 지원비 및 부임 휴가를 제공하여 새로운 환경에 적응할 수 있도록 지원 (2025 지속가능경영보고서 92쪽 복리후생 항목) — 지원 금액·휴가 일수·대상 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 15),
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 1 · 3 · 6번 ──
  (@comp_id, 'child_edu', '학자금', NULL, 'family',
   'est', NULL, TRUE, '학자금 (공식 채용 페이지 복리후생 1번 사내근로복지 기금 항목) — 지원 대상·범위·금액 미기재', 20),
  (@comp_id, 'event', '경조금 지원·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 지원 (공식 채용 페이지 복리후생 1번 사내근로복지 기금 항목), 경조휴가 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 경조 사유별 금액·휴가 일수 미기재', 21),
  (@comp_id, 'parenting', '출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 지급 첫째 200만원, 둘째 300만원, 셋째 이상 각 500만원 (공식 채용 페이지 복리후생 6번 출산 축하금 지급 항목) — 지급 시기 미기재', 22),
  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 1 · 5번 · 보고서 93 · 97쪽 ──
  (@comp_id, 'club', '사내써클 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내써클 활동 지원 (공식 채용 페이지 복리후생 1번 사내근로복지 기금 항목) — 지원 금액·방식 미기재', 30),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '매년 휴가비 지급 (공식 채용 페이지 복리후생 5번 기타 복리후생 항목) — 지급 금액 미기재', 31),
  (@comp_id, 'resort', '숙박시설 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과 그 가족들이 전국 다양한 지역의 숙박시설을 신청하여 이용할 수 있도록 지원 (2025 지속가능경영보고서 93쪽 일과 가정의 양립 항목) — 숙박시설 지점·이용 한도·비용 부담 미기재', 32),
  (@comp_id, 'company_event', '가족 문화체험 프로그램·노사화합 체육 대회', NULL, 'leisure',
   'est', NULL, TRUE, '가족이 함께하는 문화체험 프로그램 「특별한 하루」(수제청 만들기, 과일따기 체험 등)와 「문화 탐구생활」(뮤지컬, 연극, 콘서트 등 공연 관람) 운영 (2025 지속가능경영보고서 93쪽 일과 가정의 양립 항목), 노사화합 체육 대회 (2025 지속가능경영보고서 97쪽 건전한 노사관계 구축 항목) — 운영 횟수·참여 대상 미기재', 33),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 1 · 8번 · 보고서 67쪽 ──
  (@comp_id, 'health_check', '직원 및 배우자 종합건강 검진', NULL, 'health',
   'est', NULL, TRUE, '직원 및 배우자 종합건강 검진 실시 (공식 채용 페이지 복리후생 1번 사내근로복지 기금 항목), 모든 임직원과 배우자를 대상으로 2년에 한번 건강검진 시행 · 2025년부터 건강검진 항목에 폐 CT 추가 · 이상 소견 시 사후관리 프로그램 (2025 지속가능경영보고서 67쪽 임직원 건강관리 항목) — 검진 비용 지원 범위 미기재', 40),
  (@comp_id, 'insurance', '임직원 단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체 상해보험 지원 (공식 채용 페이지 복리후생 8번 단체 상해보험 지원 항목) — 보장 범위·가족 포함 여부 미기재', 41),
  (@comp_id, 'mental', '한일 마음케어 프로그램', NULL, 'health',
   'est', NULL, TRUE, '일반 직원을 대상으로 치유 심리상담 서비스를 대면 및 비대면으로 제공, 안전업무 담당자 매 분기 외부 전문가 1:1 심리상담, 업무 중 사고나 재난으로 스트레스를 겪는 직원에게 긴급 심리지원 (2025 지속가능경영보고서 67쪽 한일 마음케어 프로그램 항목) — 이용 횟수 한도·비용 부담 미기재', 42),
  -- ── 근무 환경 (work_env) — 공식 채용 페이지 복리후생 1 · 2 · 5번 · 보고서 97쪽 ──
  (@comp_id, 'dormitory', '사택·독신자 숙소 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '공장 근무시 사택 및 독신자 숙소 신청 가능, 부대시설 테니스장, 천연잔디 축구장, 농구, 족구장, 탁구장, 사우나실, 헬스장 등 (공식 채용 페이지 복리후생 2번 사택 및 독신자 숙소 운영 항목), 기숙사 운영비 (공식 채용 페이지 복리후생 1번 사내근로복지 기금 항목) — 입주 조건·비용 부담 미기재', 50),
  (@comp_id, 'uniform', '피복 제공', NULL, 'work_env',
   'est', NULL, TRUE, '피복 제공 (공식 채용 페이지 복리후생 5번 기타 복리후생 항목) — 지급 품목·주기 미기재', 51),
  (@comp_id, 'nap_room', '모성보호 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 직원들이 회사 생활에 불편함을 느끼지 않도록 모성보호 휴게실 등 편의시설 확충 (2025 지속가능경영보고서 97쪽 여성인력 현황 항목) — 설치 사업장·시설 구성 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 52),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 3번 · 보고서 91쪽 ──
  (@comp_id, 'summer_leave', '하계휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 5일 지급 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 사용 시기·유급 여부 미기재', 60),
  (@comp_id, 'birthday_leave', '본인 생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 생일 휴가 지급 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 휴가 일수 미기재', 61),
  (@comp_id, 'leave_general', '결혼기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '결혼기념일 휴가 지급 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 휴가 일수 미기재', 62),
  (@comp_id, 'refresh_leave', '리프레쉬 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레쉬 휴가 제도 시행 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 휴가 일수·부여 조건 미기재', 63),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 휴무 (공식 채용 페이지 복리후생 3번 휴무제도 항목) — 휴무 일자 미기재', 64),
  (@comp_id, 'long_service_leave', '근속 연동 휴가 가산', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에 대한 예우와 보상 차원에서 근속 2년 후부터 상한 없이 매년 휴가 1일씩 가산(법정 2년마다 1일·총 25일 한도보다 상위) (2025 지속가능경영보고서 91쪽 장기근속 우대 항목) — 기본 부여 일수 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 65),
  -- ── 성장 · 교육 (growth) — 공식 채용 페이지 복리후생 4번 · 보고서 90 · 91쪽 ──
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 지원 (공식 채용 페이지 복리후생 4번 교육훈련 항목), 영어, 일본어, 중국어 등 자발적인 외국어 교육 지원 (2025 지속가능경영보고서 91쪽 자기계발 지원 항목), 전화 외국어 교육 (2025 지속가능경영보고서 90쪽 한일 L&D System 체계 공통교육 항목) — 지원 금액·수강 방식 미기재', 70),
  (@comp_id, 'edu_support', '온라인 자기계발 교육·한일 콘서트', NULL, 'growth',
   'est', NULL, TRUE, '자기혁신, 관계, 변화, 인문학 등 다양한 분야의 온라인 자기계발 교육 제공, 인문사회 교양강의 한일 콘서트 사업장별 연 2회 운영 · 유튜브 실시간 스트리밍 (2025 지속가능경영보고서 91쪽 자기계발 지원 항목) — 수강 한도·비용 지원 범위 미기재', 71),
  (@comp_id, 'retirement_support', '정년퇴직예정자 프로그램 (Restart Program)', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직예정자 Program (Restart Program) (2025 지속가능경영보고서 90쪽 한일 L&D System 체계 오프보딩 항목) — 프로그램 내용·대상 연령·기간 미기재', 72),
  (@comp_id, 'career', 'Job Posting 제도', NULL, 'growth',
   'est', NULL, TRUE, '공석 발생 시 Job Posting 제도를 통해 내부 인재를 우선 선발, 임직원에게 자율적인 경력 개발 기회 제공 · 2025년 최초 도입 (2025 지속가능경영보고서 89쪽 보직순환제도 및 JOB POSTING 제도 항목) — 지원 자격·운영 주기 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 73),
  (@comp_id, 'self_development', '자격취득·학위과정', NULL, 'growth',
   'est', NULL, TRUE, '자격취득·학위과정 (2025 지속가능경영보고서 90쪽 한일 L&D System 체계 공통교육 항목) — 지원 방식·지원 금액·대상 미기재', 74),
  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 4번 · 보고서 18 · 91쪽 · 2026 반기보고서 ──
  (@comp_id, 'excellence_award', '모범사원·우수공로자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원 해외산업시찰 (공식 채용 페이지 복리후생 4번 교육훈련 항목), 매년 근로자의 날 모범사원 선정, 매년 말 우수공로자 선정 표창 · 매년 우수사원에게 해외 산업현장 시찰 기회 제공 (2025 지속가능경영보고서 91쪽 우수 사원 포상 항목), 전국 품질분임조 경진대회 수상 분임조에게 포상금과 국내외 연수 등 자체 포상 (2025 지속가능경영보고서 76쪽 품질분임조 경진대회 항목) — 선정 인원·포상 금액 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속 특별 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속포상 제도 운영 (2026 반기보고서 재무제표 주석 기타장기종업원급여 항목), 10년 근속부터 장기근속 특별 포상 10년 금 3돈, 15년 금 5돈 + 50만 원, 20년 금 10돈, 25년 금 15돈 + 100만 원, 30년 금 20돈 + 250만 원, 40년 500만 원 · 근속연수는 계열사 근무기간 포함 (2025 지속가능경영보고서 91쪽 장기근속 특별 포상 항목) — 지급 시기 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 81),
  (@comp_id, 'profit_sharing', '경영실적 평가 연동 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '사업회사별 경영실적 평가 결과를 사업회사 임직원의 성과급 지급기준으로 활용 (2025 지속가능경영보고서 18쪽 ESG 경영활동 성과평가 항목) — 지급 기준·지급률 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 82),
  -- ── 근무 유연성 (flexibility) — 보고서 92쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '2020년부터 시차출퇴근제, 선택적 근로시간제, 탄력적 근로시간제 등 다양한 유연근무제 도입 · 생산공장인 단양공장(2024년)과 영월공장(2025년)에 임금 감소 없는 격주 4일제 (2025 지속가능경영보고서 92쪽 격주 4일 근무제 도입 항목), 유연근무제로 시차출퇴근제 및 탄력근무제(2주, 3개월 단위) 활용 · 탄력근무제에 격주 4일제 포함 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 제도별 대상 직무 미기재', 90),
  (@comp_id, 'workation', '블레저 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '국외 출장 시 출장일정 전후로 휴가 등을 사용하여 체류 기간을 연장할 수 있는 블레저(Business와 Leisure의 합성어) 제도, 동일 도시라면 항공권 등의 교통편 일정 조정 가능 · 2023년 도입 (2025 지속가능경영보고서 92쪽 업무와 휴식을 함께하는 블레저 항목) — 연장 가능 일수·체류 비용 부담 미기재 (한일홀딩스 · 한일시멘트 통합 보고 기준)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
