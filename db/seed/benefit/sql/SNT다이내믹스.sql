-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SNT다이내믹스 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://recruit.hisntd.com/recruit/personnel/welfare.html
-- badge: est
--
-- 참고:
--   정본은 상장 법인 SNT다이내믹스(주)의 자기 도메인 채용 사이트 recruit.hisntd.com 인사제도 > 복리제도소개 페이지다.
--   공식 홈 www.hisntd.com 헤더 채용 링크가 이 호스트로 간다. 꼬리말 Copyright SNT Dynamcs Co., Ltd.(원문 철자).
--   페이지 머리 문장 주어가 SNT다이내믹스는 이고 4블록(건강한 생활 · 풍요로운 생활 · 활기찬 생활 · 안정된 생활) 목록이
--   형제 SNT모티브 복리제도소개 페이지와 항목 · 문장이 달라 법인 고유 원문이다(각주 없음).
--   SSR 이라 원본 HTML 에 목록이 다 있다. 헤드리스 렌더 · 이미지 판독 불필요. robots 는 /recruit/ 허용.
--   HTML 주석으로 막힌 기타 블록(구내식당 · 독신자숙소 · 안심귀가서비스 — SNT모티브 기타 블록과 같은 글)은 공개 원문이 아니라 싣지 않았다.
--   보조 출처는 같은 채용 사이트 인사제도 > 인사제도 페이지(hr_system.html)의 교육제도 · 임금제도 문장.
--   이 페이지는 주어가 SNT는 이고 SNT모티브 같은 페이지와 글자까지 같아 그룹 공통 문구로 보고 그 근거 2행에 SNT그룹 공통 문구 각주를 달았다.
--   공시 보조 없음: 2026 반기보고서(접수 20260812000083) 유연근무제 활용 여부 부 · 우리사주조합은 주주 표 한 칸뿐 ·
--   직원 359명(2026-06-30) · 재무제표 주석 기타장기종업원급여는 근속 낱말 없음(근거표 판단 요청).
--   www.hisntd.com 은 robots 가 메인 페이지만 허용해 지속가능경영 · 뉴스 페이지는 받지 않았다.
--   귀속: 형제 SNT모티브(대기 시드) — 복리제도소개 문장 겹침 0 · 인사제도 2행만 같은 그룹 문구.
--   금액: 원문 원 단위 숫자 0건 — 금액 행 0.
--   제외: 법정(건강보험 · 국민연금 · 산재보험 · 일반 건강진단 연 1회 · 특수건강진단 연 2회) · 외부 강사 초빙 교육(사내 집합 교육) ·
--     연봉제 문장(임금 구성) · 임원 보수지급기준 칸 귀향비 · 선물비(임원 산정 칸) · 주석 처리된 기타 블록.
--   공고 근거 0행 / 전체 16행(진행 중 공고 0건).
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · compensation 20 · family 30 · leisure 40 · perks 50 · work_env 60),
--     보조 페이지에만 있는 growth 70.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 신규 코드 barber_shop 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('snt_dynamics', 'SNT다이내믹스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '방산', 'S', 'https://recruit.hisntd.com/recruit/personnel/welfare.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_dynamics');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.hisntd.com/recruit/personnel/welfare.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 복리제도소개 건강한 생활 · 활기찬 생활 ──
  (@comp_id, 'clinic', '건강관리실·물리치료실 운영', NULL, 'health',
   'est', NULL, TRUE, '사원건강 관리 지원, 건강관리실·물리치료실 운영, 간호사·물리치료사 상주 (공식 채용 페이지 복리제도소개 건강한 생활 항목) — 운영 시간·이용 범위 미기재', 10),
  (@comp_id, 'health_check', '종합건강진단 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강진단 비용 지원 (공식 채용 페이지 복리제도소개 건강한 생활 항목) — 검진 주기·지원 대상·지원 금액 미기재', 11),
  (@comp_id, 'fitness', '사내 테니스장·헬스장·운동장', NULL, 'health',
   'est', NULL, TRUE, '사내 테니스장(2조) 및 헬스장 설치 운영, 사내 운동장 (공식 채용 페이지 복리제도소개 활기찬 생활 항목) — 이용 시간·이용 조건 미기재', 12),
  -- ── 보상 (compensation) — 복리제도소개 풍요로운 생활 · 인사제도 임금제도 ──
  (@comp_id, 'holiday_gift', '명절·근로자의 날 기념품·귀향여비', NULL, 'compensation',
   'est', NULL, TRUE, '기념품 지급 설날·추석·근로자의 날, 귀향여비 지급 설날·추석 (공식 채용 페이지 복리제도소개 풍요로운 생활 항목) — 지급 금액·기념품 내용 미기재', 20),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '조직성과에 따른 성과급 별도 운영 (공식 채용 페이지 인사제도 임금제도 항목, SNT그룹 공통 문구) — 지급 기준·지급률 미기재', 21),
  -- ── 가족 (family) — 복리제도소개 풍요로운 생활 · 안정된 생활 ──
  (@comp_id, 'child_edu', '자녀 학자금·대학 등록금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교 취학자녀 학자금, 대학 등록금 지원 (공식 채용 페이지 복리제도소개 풍요로운 생활 학자금·장학금 지급 항목) — 지원 금액·자녀 수 제한 미기재', 30),
  (@comp_id, 'parenting', '대학입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '대학입학 축하금 (공식 채용 페이지 복리제도소개 풍요로운 생활 학자금·장학금 지급 항목) — 지급 금액·지급 대상 미기재', 31),
  (@comp_id, 'event', '경조사 화환·상조팀 운영 지원', NULL, 'family',
   'est', NULL, TRUE, '본인/가족의 경조사 화환 및 상조팀 운영 지원 (공식 채용 페이지 복리제도소개 안정된 생활 경조사 지원 항목) — 경조 종류별 지원 내용 미기재', 32),
  -- ── 여가 (leisure) — 복리제도소개 풍요로운 생활 · 활기찬 생활 ──
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 지급 (공식 채용 페이지 복리제도소개 풍요로운 생활 항목) — 지급 금액·지급 기준 미기재', 40),
  (@comp_id, 'resort', '하계휴양소·휴양시설 운영', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴양소 운영, 휴양시설 운영 (공식 채용 페이지 복리제도소개 활기찬 생활 항목) — 휴양시설 위치·이용 기간 미기재', 41),
  (@comp_id, 'company_event', '체육대회', NULL, 'leisure',
   'est', NULL, TRUE, '체육대회 실시, 10월 중 (공식 채용 페이지 복리제도소개 활기찬 생활 항목) — 개최 장소·참가 대상 미기재', 42),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 적극 지원, 사내 단체 사회대회 참여시 행사비 등 보조 (공식 채용 페이지 복리제도소개 활기찬 생활 항목) — 지원 금액·동호회 종류 미기재', 43),
  -- ── 생활 (perks) — 복리제도소개 활기찬 생활 · 안정된 생활 ──
  (@comp_id, 'barber_shop', '사내 이용원', NULL, 'perks',
   'est', NULL, TRUE, '사내 이용원 설치 운영 (공식 채용 페이지 복리제도소개 활기찬 생활 항목) — 이용 요금·운영 시간 미기재', 50),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (공식 채용 페이지 복리제도소개 안정된 생활 항목) — 노선·운행 시간 미기재', 51),
  -- ── 근무환경 (work_env) — 복리제도소개 안정된 생활 ──
  (@comp_id, 'dormitory', '사택 및 기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '사택 및 기숙사 운영 (공식 채용 페이지 복리제도소개 안정된 생활 항목) — 입주 자격·비용 부담 미기재', 60),
  -- ── 성장 (growth) — 인사제도 교육제도 ──
  (@comp_id, 'conference', '협회·기관 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '각 협회 및 기관을 통한 교육 지원 (공식 채용 페이지 인사제도 교육제도 항목, SNT그룹 공통 문구) — 지원 범위·대상 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
