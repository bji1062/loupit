-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SNT모티브 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://recruit.sntmotiv.com/recruit/personnel/welfare.html
-- badge: est
--
-- 참고:
--   정본은 상장 법인 SNT모티브(주)의 자기 도메인 채용 사이트 recruit.sntmotiv.com 인사제도 > 복리제도소개 페이지다.
--   공식 홈 www.sntmotiv.com 헤더 채용정보 메뉴가 이 호스트로 링크한다. 꼬리말 Copyright SNT Motiv Co., Ltd.
--   SSR 이라 원본 HTML 에 5블록(건강관리 · 자녀 학자금 및 교육 지원 · 생활안정 · 여가생활 · 기타) 목록이 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요. robots 는 /recruit/ 허용.
--   보조 출처는 같은 채용 사이트 인사제도 > 인사제도 페이지(hr_system.html)의 교육제도 · 임금제도 문장.
--   이 페이지는 주어가 SNT는 이고 형제 SNT다이내믹스 채용 사이트(recruit.hisntd.com)의 같은 페이지와 글자까지 같아
--   그룹 공통 문구로 보고 그 근거 2행에 SNT그룹 공통 문구 각주를 달았다.
--   복리제도소개 페이지는 형제 페이지와 항목 · 문장이 달라 법인 고유 원문이다(각주 없음).
--   공시 보조 없음: 2026 반기보고서(접수 20260818000153 정정) 유연근무제도 사용 현황은 시차출퇴근 · 선택근무 · 원격근무
--   모두 도입하지 않음, 우리사주조합은 주주 표 한 칸뿐, 직원 525명(2026-06-30).
--   지속가능경영 · ESG 보고서는 자기 도메인에 없다(ESG경영 페이지는 활동 요약뿐).
--   귀속: 형제 SNT홀딩스 · SNT다이내믹스 · SNT에너지는 코퍼스 미등록.
--   금액: 원문 원 단위 숫자 0건. 식대 1행만 추정(중식 · 석식 무상제공 2끼 × 12,000원 × 240일 = 576).
--   제외: 법정(일반건강진단 · 특수건강진단 연 1회) · 외부 강사 초빙 교육(사내 집합 교육) · 연봉제 문장(임금 구성) ·
--     임원 보수지급기준 칸 귀향비 · 선물비(임원 산정 칸) · 반기보고서 주석 장기근속원가 부채(제도 문장 없음 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 15행(진행 중 공고 0건).
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · family 20 · leisure 30 · compensation 40 · perks 50 · work_env 60),
--     보조 페이지에만 있는 growth 70.
-- 검증 · 감사 판정 반영(2026-10-15): 반기보고서 주석 장기근속원가 부채 long_service_bonus 장기근속 급부 추가(참고 블록 제외 줄의 장기근속원가 부채는 이 판정으로 뒤집힘) — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('snt_motiv', 'SNT모티브',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '자동차부품', 'S', 'https://recruit.sntmotiv.com/recruit/personnel/welfare.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_motiv');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.sntmotiv.com/recruit/personnel/welfare.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 복리제도소개 건강관리 ──
  (@comp_id, 'health_check', '종합건강진단 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강진단 비용 지원, 만40세 이상부터 본인 및 배우자 대상 (공식 채용 페이지 복리제도소개 건강관리 항목) — 검진 주기·지원 금액 미기재', 10),
  (@comp_id, 'medical', '의료비 보조', NULL, 'health',
   'est', NULL, TRUE, '의료비 보조, 본인·배우자·의료보험등재 직계존비속 대상 (공식 채용 페이지 복리제도소개 건강관리 항목) — 보조 한도·보조 비율 미기재', 11),
  -- ── 가족 (family) — 복리제도소개 자녀 학자금 및 교육 지원 · 생활안정 ──
  (@comp_id, 'child_edu', '자녀 학자금 및 교육 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원·중학교·고등학교 자녀 학자금, 대학/전문대학 입학금 및 등록금, 사원자녀 방학 중 영어캠프 및 해외어학연수 지원 (공식 채용 페이지 복리제도소개 자녀 학자금 및 교육 지원 항목) — 지원 금액·한도·자녀 수 제한 미기재', 20),
  (@comp_id, 'event', '경조사 화환 및 경조금', NULL, 'family',
   'est', NULL, TRUE, '본인/가족의 경조사 화환 및 경조금 지급 (공식 채용 페이지 복리제도소개 생활안정 항목) — 경조 종류별 금액 미기재', 21),
  -- ── 여가 (leisure) — 복리제도소개 생활안정 · 여가생활 ──
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 지급 (공식 채용 페이지 복리제도소개 생활안정 항목) — 지급 금액·지급 기준 미기재', 30),
  (@comp_id, 'resort', '하계휴양소 운영', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴양소 운영 (공식 채용 페이지 복리제도소개 여가생활 항목) — 휴양소 위치·이용 기간 미기재', 31),
  (@comp_id, 'company_event', '전사 한마음 체육대회', NULL, 'leisure',
   'est', NULL, TRUE, '전사 한마음 체육대회 실시 (공식 채용 페이지 복리제도소개 여가생활 항목) — 개최 주기·시기 미기재', 32),
  -- ── 보상 (compensation) — 복리제도소개 생활안정 · 인사제도 임금제도 ──
  (@comp_id, 'holiday_gift', '명절 귀향여비·기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀향여비 지급, 설날·추석·근로자의 날·창사기념일 선물 지급 (공식 채용 페이지 복리제도소개 생활안정 항목) — 지급 금액·선물 내용 미기재', 40),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '조직성과에 따른 성과급 별도 운영 (공식 채용 페이지 인사제도 임금제도 항목, SNT그룹 공통 문구) — 지급 기준·지급률 미기재', 41),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '기타장기종업원급여 부채 내역의 장기근속원가에 대한 부채 (2026 반기보고서 재무제표 주석 종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 42),
  -- ── 생활 (perks) — 복리제도소개 생활안정 · 기타 ──
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출, 무주택 종업원의 주택마련·전세자금 일부 지원 (공식 채용 페이지 복리제도소개 생활안정 항목) — 대출 한도·이율 미기재', 50),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (공식 채용 페이지 복리제도소개 기타 항목) — 노선·운행 시간 미기재', 51),
  (@comp_id, 'meal', '구내식당 (중식·석식 무상제공)', 576, 'perks',
   'est', '구내식당 운영, 중식 및 석식 무상제공 (공식 채용 페이지 복리제도소개 기타 항목) — 1끼 단가 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 52),
  (@comp_id, 'transport', '종업원안심귀가서비스 (기업대리운전)', NULL, 'perks',
   'est', NULL, TRUE, '종업원안심귀가서비스 (기업대리운전) 제공 (공식 채용 페이지 복리제도소개 기타 항목) — 이용 조건·이용 횟수·비용 부담 미기재', 53),
  -- ── 근무환경 (work_env) — 복리제도소개 기타 ──
  (@comp_id, 'dormitory', '독신자숙소 운영', NULL, 'work_env',
   'est', NULL, TRUE, '독신자숙소 운영 (공식 채용 페이지 복리제도소개 기타 항목) — 입주 자격·비용 부담 미기재', 60),
  -- ── 성장 (growth) — 인사제도 교육제도 ──
  (@comp_id, 'conference', '협회·기관 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '각 협회 및 기관을 통한 교육 지원 (공식 채용 페이지 인사제도 교육제도 항목, SNT그룹 공통 문구) — 지원 범위·대상 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
