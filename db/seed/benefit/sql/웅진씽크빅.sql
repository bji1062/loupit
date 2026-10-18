-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 웅진씽크빅 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://company.wjthinkbig.com/recruit/welfare.do
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 회사 사이트 인재채용 > 복리후생 페이지(SSR · 원본 HTML 에 항목 텍스트 · 렌더 없음).
--   보조 = 공식 홈 헤더에서 링크된 회사 계정 채용 사이트 thinkbig.career.greetinghr.com/ko/team (팀 문화/복지제도 · __NEXT_DATA__ 아닌 SSR 본문) ·
--          같은 도메인 인재육성(recruit/development.do) · 기업문화 신기문화(culture/singi.do) ·
--          OpenDART 2026 반기보고서(20260814004136) · 2025 사업보고서(20260318001421) 유연근무제도 사용 현황 표.
--   귀속 = 모든 문장의 주어가 웅진씽크빅(자기 도메인 · 회사 계정 채용 사이트) — 그룹 통합 채용 페이지 아님 · 각주 없음.
--   금액 = 금액 행 0 (식대는 끼니 미기재라 NULL · 휴가비 · 축하금 · 경조금은 숫자 없음).
--   제외 = 주석 처리된 스킨케어 프로그램(유령) · 입사자 · 승진자 · 팀장 · ESG 필수교육 · 비즈니스 코칭(업무 교육) ·
--          법정 인권 교육 · RSU · 우리사주조합 주주 표 한 칸 · 타운홀 미팅 · 행복마당 · 오픈이노베이션 데이(소통 행사).
--   공고 근거 0행 / 전체 29행.
--   SORT 섹션 = health 10 · perks 20 · leisure 30 · family 40 · time_off 50 · work_env 60 (정본 순) ·
--               flexibility 70 · growth 80 · compensation 90 (보조 출처에만).
-- 검증 · 감사 판정 반영(2026-10-18): 2026 반기보고서 그 밖의 우발채무 문단의 종업원 단체상해보험 insurance 추가(주어가 연결실체라 통합 보고 각주) · 자격증 과정 self_development 서술에서 다른 직무 과정 이름 걷기 · 참고 블록의 위험 표시 없음은 이 판정으로 뒤집힘 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('woongjin_thinkbig', '웅진씽크빅',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '교육', 'W', 'https://company.wjthinkbig.com/recruit/welfare.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'woongjin_thinkbig');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.wjthinkbig.com/recruit/welfare.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 복리후생 페이지 건강 지원 제도 · 채용 사이트 Health ──
  (@comp_id, 'health_check', '건강검진 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '정기건강검진(본인/가족) (공식 채용 페이지 복리후생 건강 지원 프로그램 항목), 제휴 병원을 통해 본인과 가족 1인까지 프리미엄 건강 검진 제공 (공식 채용 사이트 팀 문화/복지 Health 항목) — 검진 비용 지원 범위 미기재', 10),
  (@comp_id, 'massage', '헬스케어 프로그램 (사내 헬스 키퍼)', NULL, 'health',
   'est', NULL, TRUE, '헬스케어 프로그램 (공식 채용 페이지 복리후생 건강 지원 프로그램 항목), 사내 헬스 키퍼 운영을 통한 컨디션 관리 (공식 채용 사이트 팀 문화/복지 Health 항목) — 이용 시간·횟수 미기재', 11),
  (@comp_id, 'fitness', '사내 운동 시설 (Fitness Center·배드민턴 시설)', NULL, 'health',
   'est', NULL, TRUE, '사내 운동 시설 Fitness Center · 배드민턴 시설 (공식 채용 페이지 복리후생 건강 지원 제도 항목) — 운영 시간·이용 조건 미기재', 12),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '종업원에 대해서는 단체상해보험에 가입 (2026 반기보고서 그 밖의 우발채무 보험 가입 항목) — 보장 범위·가족 포함 여부 미기재 (웅진씽크빅 · 웅진북센 · 웅진컴퍼스 · 프라이머리제일차 통합 보고 기준)', 13),

  -- ── 생활 · 금융 (perks) — 복리후생 페이지 · 채용 사이트 Life ──
  (@comp_id, 'meal', '사내 식당·건강 샐러드 제공', NULL, 'perks',
   'est', NULL, TRUE, '건강한 식단 관리 사내 식당 · 건강 샐러드 제공 (공식 채용 페이지 복리후생 건강 지원 제도 항목), 사내 식당을 통해 신선하고 균형 잡힌 식단 제공 (공식 채용 사이트 팀 문화/복지 Health 항목) — 제공 끼니·식대 지원 범위 미기재', 20),
  (@comp_id, 'birthday_gift', '생일 축하금·자녀 생일 케이크', NULL, 'perks',
   'est', NULL, TRUE, '자녀 생일 케이크 (공식 채용 페이지 복리후생 경조사 지원 항목), 생일 당일 축하금 지급 · 자녀 생일을 위한 케이크 제공 (공식 채용 사이트 팀 문화/복지 생일 지원 · 자녀 생일 지원 항목) — 축하금 금액 미기재', 21),
  (@comp_id, 'housing_loan', '무이자 주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '생활 안정 지원 무이자 주택자금 대출 (공식 채용 페이지 복리후생 가족 친화 제도 항목), 무이자 주택 자금 대출 지원 (공식 채용 사이트 팀 문화/복지 Life 항목) — 대출 한도·자격 요건 미기재', 22),
  (@comp_id, 'relocation', '부임여비·이사비 지원', NULL, 'perks',
   'est', NULL, TRUE, '부임여비, 이사비 지원 (공식 채용 페이지 복리후생 생활 안정 지원 항목) — 지원 금액·대상 발령 범위 미기재', 23),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스 (일산·파주·서울 주요 지역)', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 셔틀버스 일산/파주 지역 · 서울 주요 지역 (공식 채용 페이지 복리후생 각종 부대 시설 항목), 출/퇴근 편의를 위한 무료 셔틀 버스 운행 (공식 채용 사이트 팀 문화/복지 Life 항목) — 운행 노선·시간 미기재', 24),
  (@comp_id, 'discount', '계열사 제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '계열사 제휴 계약사 할인 지원 (공식 채용 사이트 팀 문화/복지 Life 항목) — 할인 대상·할인율 미기재', 25),

  -- ── 여가 · 행사 (leisure) — 복리후생 페이지 여가 지원 제도 · 기업문화 페이지 ──
  (@comp_id, 'summer_vacation_subsidy', '정기 휴가비 (Refresh 휴가비)', NULL, 'leisure',
   'est', NULL, TRUE, '정기 휴가비 지급 (공식 채용 페이지 복리후생 여가 지원 항목), Refresh 휴가비 지급 (공식 채용 사이트 팀 문화/복지 Life 항목) — 지급 금액·지급 시기 미기재', 30),
  (@comp_id, 'leisure_ticket', '웅진플레이도시 자유이용권', NULL, 'leisure',
   'est', NULL, TRUE, '웅진플레이도시 자유이용권 제공 (공식 채용 페이지 복리후생 여가 지원 항목), 종합 테마파크 웅진플레이도시 자유이용권 (공식 채용 사이트 팀 문화/복지 계열사 제휴 항목) — 제공 매수·주기 미기재', 31),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '문화생활 지원 사내 동호회 지원 (공식 채용 페이지 복리후생 여가 지원 제도 항목) — 지원 금액·동호회 종류 미기재', 32),
  (@comp_id, 'resort', '제주 휘닉스 콘도 지원·전국 유명 콘도 제휴', NULL, 'leisure',
   'est', NULL, TRUE, '휴양 시설 제주 휘닉스 콘도 지원 · 전국 유명 콘도 제휴 (공식 채용 페이지 복리후생 여가 지원 제도 항목) — 이용 조건·지원 범위 미기재', 33),
  (@comp_id, 'welcome_kit', '입사일 가족 CEO 선물', NULL, 'leisure',
   'est', NULL, TRUE, '신입사원 입사 축하 및 온보딩 입사일 가족에게 CEO선물 (공식 홈페이지 기업문화 신기문화 항목) — 선물 품목 미기재', 34),
  (@comp_id, 'company_event', '자녀초청 패밀리데이·입사 1년 축하행사', NULL, 'leisure',
   'est', NULL, TRUE, '자녀초청 패밀리데이 엄마, 아빠 회사에 놀러가는 날 · 입사 1년을 기념하여 1년 축하행사 (공식 홈페이지 기업문화 신기문화 항목) — 개최 주기·참가 범위 미기재', 35),

  -- ── 가족 (family) — 복리후생 페이지 가족 친화 제도 · 채용 사이트 Family ──
  (@comp_id, 'parenting', '워킹맘 특별 휴가·자녀 생일 휴가·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '워킹맘 특별 휴가 · 자녀 생일 휴가 (공식 채용 페이지 복리후생 아주 특별한 휴가 항목), 육아 지원을 위한 워킹맘 특별 휴가 제공 · 자녀 생일을 위한 휴가 · 자녀 입학을 함께 축하하기 위해 입학 선물 지급 (공식 채용 사이트 팀 문화/복지 Family 항목) — 휴가 일수·대상 자녀 연령 미기재', 40),
  (@comp_id, 'event', '경조사 지원 (경조금·화환/상조물품)', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원금 · 화환/상조물품 (공식 채용 페이지 복리후생 경조사 지원 항목), 본인 및 가족 경조 지원(경조금, 화환/상조 물품) (공식 채용 사이트 팀 문화/복지 Family 항목) — 경조 금액·지급 기준 미기재', 41),
  (@comp_id, 'childcare', '공동 직장 어린이집 (파주출판도시)', NULL, 'family',
   'est', NULL, TRUE, '어린이집 지원 파주출판도시 내 공동 직장 어린이집 (공식 채용 페이지 복리후생 각종 부대 시설 항목), 어린이집 이용 지원 (파주사옥) (공식 채용 사이트 팀 문화/복지 Family 항목) — 정원·이용 자격 미기재', 42),

  -- ── 휴가 (time_off) — 복리후생 페이지 아주 특별한 휴가 · 채용 사이트 ──
  (@comp_id, 'birthday_leave', '생일 조기 퇴근 (오후 2시)', NULL, 'time_off',
   'est', NULL, TRUE, '생일 직원 조기 퇴근 (공식 채용 페이지 복리후생 아주 특별한 휴가 항목), 생일 당일 오후 2시 조기 퇴근 (공식 채용 사이트 팀 문화/복지 Life 생일 지원 항목)', 50),
  (@comp_id, 'leave_general', '결혼기념일·이사 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '결혼기념일, 이사 휴가 (공식 채용 페이지 복리후생 아주 특별한 휴가 항목), 특별한 날을 기념하기 위한 결혼기념일 휴가 · 이사일 휴가 지원 (공식 채용 사이트 팀 문화/복지 항목) — 휴가 일수·유급 여부 미기재', 51),

  -- ── 근무 환경 (work_env) — 복리후생 페이지 각종 부대 시설 ──
  (@comp_id, 'lounge', '휴게 공간 (여성·남성 휴게실·파우더룸)', NULL, 'work_env',
   'est', NULL, TRUE, '휴게 공간 여성 휴게실 · 남성 휴게실 · 파우더룸 (공식 채용 페이지 복리후생 각종 부대 시설 항목), 업무 중 충전을 위한 휴게공간 마련 (공식 채용 사이트 팀 문화/복지 Health 항목) — 운영 사업장 미기재', 60),

  -- ── 근무 유연성 (flexibility) — 채용 사이트 · 기업문화 페이지 · 공시 ──
  (@comp_id, 'family_day', '삼무데이 (매주 수요일 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 수요일 조기 퇴근 (회의/회식/야근 3無), 자기 계발 시간 제공을 위한 매주 수요일 16:30 조기 퇴근 (공식 채용 사이트 팀 문화/복지 항목), 삼무데이 매주 수요일은 회의, 회식, 야근 없는 날 (공식 홈페이지 기업문화 신기문화 항목)', 70),
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제·선택근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연 근무제 개인 업무 일정에 따라 근무시간을 유연하게 운영 (공식 채용 사이트 팀 문화/복지 항목), 시차출퇴근제 · 선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 71),
  (@comp_id, 'remote_work', '원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무 환경이 마련되어 있어, 전 직원이 상황에 맞게 활용 (2026 반기보고서 유연근무제도 사용 현황 항목) — 사용 횟수·사용 조건 미기재', 72),

  -- ── 성장 · 교육 (growth) — 인재육성 페이지 · 채용 사이트 ──
  (@comp_id, 'edu_support', 'Udemy 강의 무제한 수강·씽크빅특강', NULL, 'growth',
   'est', NULL, TRUE, 'Udemy 강의 무제한 수강 지원 (공식 채용 사이트 팀 문화/복지 인재 육성 항목), Global 온라인 교육 플랫폼 Udemy 콘텐츠 수강 · 씽크빅특강 대한민국 최고의 전문가들과의 만남 (공식 홈페이지 인재육성 교육 제도 항목) — 특강 주기 미기재', 80),
  (@comp_id, 'self_development', '자격증 과정 (직무역량 향상교육)', NULL, 'growth',
   'est', NULL, TRUE, '자발적 직무역량 향상 프로그램의 자격증 과정 (공식 홈페이지 인재육성 직무역량 향상교육 항목) — 대상 자격증·비용 지원 범위 미기재', 81),
  (@comp_id, 'conference', '사외교육 지원 (외부 교육·컨퍼런스)', NULL, 'growth',
   'est', NULL, TRUE, '다양한 외부 교육과 우수기업 벤치마킹, 컨퍼런스 지원 (공식 홈페이지 인재육성 사외교육 지원 항목) — 지원 금액·대상 미기재', 82),

  -- ── 보상 · 포상 (compensation) — 채용 사이트 · 기업문화 페이지 ──
  (@comp_id, 'incentive', '성과 리워드', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 따른 보상 제도 운영 (공식 채용 사이트 팀 문화/복지 성과 리워드 항목) — 지급 기준·지급률 미기재', 90),
  (@comp_id, 'excellence_award', '우수 사원 시상 (씽크빅스타)', NULL, 'compensation',
   'est', NULL, TRUE, '월/연 단위 우수 사원 시상 (공식 채용 사이트 팀 문화/복지 항목), 씽크빅스타 우수한 성과에 대해 매월 시상 (공식 홈페이지 기업문화 신기문화 항목) — 포상 내용·금액 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
