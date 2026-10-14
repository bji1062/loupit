-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 금호타이어 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.kumhotire.com/ko/ESG/Social/Employees/
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 ESG 임직원 페이지(SSR · 교육 체계 · Work & Life Balance · Life & House · Health & Family · Culture & Leisure 목록).
--   보조 = 자기 도메인 2026 지속가능경영보고서(2026-08 발행 · 보고 기간 2025년 · 42쪽 건강 증진 · 73쪽 포상 · 74쪽 교육 체계 · 75쪽 생애주기 맞춤 복리후생 제도 표).
--   교육 체계는 페이지 이미지 + 같은 내용의 대체 텍스트 블록. 채용 사이트 kumhotire.recruiter.co.kr 은 CSR(본문은 벤더 API 호스트) 이라 쓰지 않았다.
--   귀속: 전 행 금호타이어가 주어인 자기 도메인 문장 · 보고서 보고 범위는 연결 종속회사 포함이나 금호타이어 문장만 골라 각주 없음.
--   북미기술연구소 KATC 박스 · 해외 · 중국 법인 문장은 쓰지 않았다. 금호석유화학 · 금호아시아나와 다른 법인(형제 아님).
--   금액: 원문에 숫자 없음 → 전 행 금액 NULL(stated 0 · 추정 0).
--   제외: 타이어 Academy(교양 — 직무별 역량과정) · 법정(난임 휴가 · 태아검진 휴가 · 출산전후 휴가 90일 · 배우자 출산휴가 20일 · 유급 육아휴직 최대 1년 6개월 · 근로시간 단축제도 · 퇴직 예정자 재취업 · 창업 교육 · 정기 · 특수 건강검진 사후조치) ·
--     업무 교육(직무 · 계층별 · 신입 · 멘토링 · 리더십 · 러닝센터 · 법정필수) · 사우회 운영(내용 미기재) · 연봉 인상률 연계(급여 조정).
--   공고 근거 0행 / 전체 30행 · SORT 섹션 순서 = growth · flexibility · time_off · health · work_env · perks · family · compensation · leisure
-- 검증 · 감사 판정 반영(2026-10-14): 개인사외교육 conference 삭제(업무 교육) · 국내영업 지점근무 주택 임차금 지원을 housing_support 로 갈라 추가 · 71쪽 동등급여 표 주석의 인센티브 incentive 추가 — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kumho_tire', '금호타이어',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '타이어', 'K', 'https://www.kumhotire.com/ko/ESG/Social/Employees/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kumho_tire');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kumhotire.com/ko/ESG/Social/Employees/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — ESG 임직원 페이지 교육 체계 · 2026 지속가능경영보고서 74쪽 ──
  (@comp_id, 'edu_support', 'E-LEARNING·독서교육', NULL, 'growth',
   'est', NULL, TRUE, 'E-LEARNING(이러닝) 도서, 경영 과정 (공식 홈페이지 ESG 임직원 페이지 교육 체계 기본역량과정 항목), 독서교육 (2026 지속가능경영보고서 74쪽 임직원 교육 프로그램 공통 항목) — 과정 내용·수강 대상·비용 지원 범위 미기재', 10),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, 'E-LEARNING(이러닝) 어학 과정 (공식 홈페이지 ESG 임직원 페이지 교육 체계 기본역량과정 항목), 어학교육 (2026 지속가능경영보고서 74쪽 임직원 교육 프로그램 공통 항목) — 지원 언어·수강 대상·비용 지원 범위 미기재', 11),
  (@comp_id, 'mba', 'MBA과정·연구소 학위지원', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재과정의 MBA과정(국내, 해외), 연구소 학위지원(국내외 석박사) (공식 홈페이지 ESG 임직원 페이지 교육 체계 항목) — 선발 기준·지원 범위·의무 근무 조건 미기재', 12),
  (@comp_id, 'self_development', 'AI 자격증 취득 지원 (IT부문)', NULL, 'growth',
   'est', NULL, TRUE, 'IT 부문 임직원 대상 AI 역량 자격증(AI Certificate for Everyone, AICE) 취득 지원 제도 (2026 지속가능경영보고서 74쪽 AI 역량 강화 지원 항목) — 지원 비용·응시 횟수 미기재', 14),

  -- ── 근무 유연성 (flexibility) — ESG 임직원 페이지 Work & Life Balance · 보고서 75쪽 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '핵심근무시간 외에 출퇴근 시간을 자유롭게 조절 (공식 홈페이지 ESG 임직원 페이지 Work & Life Balance 유연근무제 항목), 핵심 근무시간을 제외한 출퇴근 시간은 임직원이 스스로 조정 (2026 지속가능경영보고서 75쪽 유연한 근무 환경 항목) — 핵심근무시간대·적용 직군 미기재', 20),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '휴식시간 알람과 근무 시작 및 종료에 대한 자동시스템, 임직원의 정시근무 보장 및 저녁시간 존중 (공식 홈페이지 ESG 임직원 페이지 Work & Life Balance PC-OFF제도 항목) — 적용 시각·대상 미기재', 21),

  -- ── 휴가 (time_off) — ESG 임직원 페이지 Work & Life Balance · Culture & Leisure · 보고서 75쪽 ──
  (@comp_id, 'leave_general', '휴가 셀프 승인·리더스 데이 (조직장)', NULL, 'time_off',
   'est', NULL, TRUE, '본인의 휴가를 직접 승인하는 휴가 셀프 승인 제도, 매월 둘째 주 조직장의 정기 의무휴가를 운영하는 리더스 데이 (공식 홈페이지 ESG 임직원 페이지 Work & Life Balance 항목, 2026 지속가능경영보고서 75쪽 복리제도 항목) — 리더스 데이 휴가 일수·유급 여부·별도 부여 여부 미기재', 30),
  (@comp_id, 'refresh_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '일할 때 확실히 일하고 쉴 때 확실히 쉬는 문화 조성을 위한 Refresh 휴가 (공식 홈페이지 ESG 임직원 페이지 Work & Life Balance 항목, 2026 지속가능경영보고서 75쪽 복리제도 항목) — 휴가 일수·부여 조건 미기재', 31),
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 시행 (공식 홈페이지 ESG 임직원 페이지 Culture & Leisure 항목), 여름 휴가 (2026 지속가능경영보고서 75쪽 복리제도 항목) — 본인 휴가 사용일인지·휴가 일수·유급 여부 미기재', 32),

  -- ── 건강 (health) — ESG 임직원 페이지 Life & House · Health & Family · 보고서 42쪽 · 75쪽 ──
  (@comp_id, 'medical', '의료비 지원·질병 시 생계비 지원', NULL, 'health',
   'est', NULL, TRUE, '생계비 지원(본인 질병 및 산재요양 시), 의료비 지원(배우자·자녀 포함) (공식 홈페이지 ESG 임직원 페이지 Life & House · Health & Family 항목, 2026 지속가능경영보고서 75쪽 복리제도 항목) — 지원 한도·생계비 지급 기간 미기재', 40),
  (@comp_id, 'health_check', '임직원 건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강 검진 (공식 홈페이지 ESG 임직원 페이지 Health & Family 항목) — 검진 주기·비용 지원 범위 미기재', 41),
  (@comp_id, 'fitness', '사내 체력단련 시설', NULL, 'health',
   'est', NULL, TRUE, '사내 체력단련 시설 운영, 체성분 분석기 도입, 다이어트 챌린지 프로그램 목표 달성 임직원 포상 (2026 지속가능경영보고서 42쪽 임직원 건강 증진 프로그램 항목) — 시설 위치·이용 시간·포상 내용 미기재', 42),
  (@comp_id, 'smoking_cessation', '금연 챌린지', NULL, 'health',
   'est', NULL, TRUE, '금연 챌린지 프로그램 목표 달성 임직원 포상 (2026 지속가능경영보고서 42쪽 임직원 건강 증진 프로그램 항목) — 포상 내용·참여 조건 미기재', 43),

  -- ── 근무 환경 (work_env) — ESG 임직원 페이지 Life & House ──
  (@comp_id, 'dormitory', '사원아파트 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '사원아파트(공장) (공식 홈페이지 ESG 임직원 페이지 Life & House 항목) — 입주 자격·비용 부담 미기재', 50),

  -- ── 생활 · 금융 (perks) — ESG 임직원 페이지 Life & House · Culture & Leisure · 보고서 73쪽 · 75쪽 ──
  (@comp_id, 'housing_loan', '주택구입·임차 자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 임차 자금 융자 (2026 지속가능경영보고서 75쪽 생애주기 맞춤 복리후생 제도 결혼 항목) — 융자 한도·이율·자격 요건 미기재', 60),
  (@comp_id, 'discount', '타이어 할인쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '타이어 할인쿠폰 제공 (공식 홈페이지 ESG 임직원 페이지 Culture & Leisure 항목, 2026 지속가능경영보고서 75쪽 복리제도 항목) — 할인율·지급 수량 미기재', 61),
  (@comp_id, 'welfare_fund_loan', '결혼·생활 안정자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '결혼·생활 안정자금 융자지원 (2026 지속가능경영보고서 75쪽 생애주기 맞춤 복리후생 제도 결혼 항목) — 융자 한도·이율 미기재', 62),
  (@comp_id, 'team_dinner', '부서별 워크숍·문화·스포츠 활동 지원', NULL, 'perks',
   'est', NULL, TRUE, '부서별 자율적인 워크숍·문화·스포츠 활동 지원 (2026 지속가능경영보고서 73쪽 팀워크 강화 항목) — 지원 금액·횟수 미기재', 63),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 지급 (2026 지속가능경영보고서 75쪽 복리제도 명절 및 생일 선물 지급 항목) — 선물 품목·금액 미기재', 64),
  (@comp_id, 'housing_support', '주택 임차금 지원 (국내영업 지점근무)', NULL, 'perks',
   'est', NULL, TRUE, '주택 임차금 지원(국내영업 지점근무) (공식 홈페이지 ESG 임직원 페이지 Life & House 항목) — 지원 방식·금액·지원 기간 미기재', 65),

  -- ── 가족 (family) — ESG 임직원 페이지 Health & Family · 보고서 75쪽 ──
  (@comp_id, 'event', '경조휴가·경조비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조비 지원 (공식 홈페이지 ESG 임직원 페이지 Health & Family 항목) — 경조 범위·경조비 금액·휴가 일수 미기재', 70),
  (@comp_id, 'childcare', '사내 어린이집 (광주·곡성)', NULL, 'family',
   'est', NULL, TRUE, '어린이집 운영(공장) (공식 홈페이지 ESG 임직원 페이지 Health & Family 항목), 사내 어린이집(광주·곡성) (2026 지속가능경영보고서 75쪽 생애주기 맞춤 복리후생 제도 육아 항목) — 입소 대상·정원 미기재', 71),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금(유치원 ~대학교) (공식 홈페이지 ESG 임직원 페이지 Health & Family 항목), 자녀 학자금 지원 (2026 지속가능경영보고서 75쪽 생애주기 맞춤 복리후생 제도 교육 항목) — 지원 금액·자녀 수 한도 미기재', 72),
  (@comp_id, 'parenting', '출산 축하키트·보육비 지원·부모 성장 프로그램', NULL, 'family',
   'est', NULL, TRUE, '출산 축하키트, 육아휴직 복귀자 리보딩 프로그램, 부모 성장 프로그램 (2026 지속가능경영보고서 75쪽 생애주기 맞춤 복리후생 제도 임신·출산 · 육아 · 교육 항목), 결혼·출산기 보육비 지원 (같은 쪽 생애주기 맞춤 복리후생 제도 본문) — 키트 구성·보육비 금액·프로그램 내용 미기재', 73),

  -- ── 보상 (compensation) — ESG 임직원 페이지 Health & Family · 보고서 73쪽 · 75쪽 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 홈페이지 ESG 임직원 페이지 Health & Family 항목), 모든 임직원을 대상으로 5년마다 포상금 지급 (2026 지속가능경영보고서 73쪽 장기 근속 포상 제도 항목) — 포상금 금액 미기재', 80),
  (@comp_id, 'excellence_award', '조직·개인 포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '핵심 KPI 성과·주요 프로젝트 추진 성과 기준 우수 조직 포상, 뛰어난 기여를 이룬 임직원에게 유급 휴가와 포상금 정기 및 수시 제공, 매년 CEO 포상 및 본부장 포상 (2026 지속가능경영보고서 73쪽 조직 및 개인 포상 제도 항목) — 포상금 금액·휴가 일수 미기재', 81),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 지급 (2026 지속가능경영보고서 75쪽 복리제도 명절 및 생일 선물 지급 항목) — 선물 품목·금액 미기재', 82),
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '기본급과 함께 연봉총액을 이루는 인센티브 (2026 지속가능경영보고서 71쪽 동등급여 표 주석 항목) — 지급 대상·지급 기준·지급률 미기재', 83),

  -- ── 여가 (leisure) — ESG 임직원 페이지 Culture & Leisure · 보고서 74쪽 · 75쪽 ──
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 지급 (공식 홈페이지 ESG 임직원 페이지 Culture & Leisure 항목), 여름 휴가비 지원 (2026 지속가능경영보고서 75쪽 복리제도 항목) — 지급 금액·대상 미기재', 90),
  (@comp_id, 'club', 'Kumho Runners Club 등 액티비티 활동', NULL, 'leisure',
   'est', NULL, TRUE, '구성원 간 자발적인 교류와 소통을 위한 Kumho Runners Club 같은 관심사 기반 액티비티 활동 운영 (2026 지속가능경영보고서 75쪽 구성원 액티비티 활동 지원 항목) — 활동비 지원 여부·운영 모임 수 미기재', 91),
  (@comp_id, 'company_event', '가족행사 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '가족행사 프로그램 (2026 지속가능경영보고서 74쪽 임직원 교육 프로그램 조직문화 항목) — 행사 내용·횟수·참여 대상 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
