-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SNT에너지 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: http://www.hisnt.com/kor/about/benefits.html
-- badge: est
--
-- 참고:
--   정본은 상장 법인 SNT에너지(주)의 자기 도메인 www.hisnt.com 회사소개 > 채용정보 > 복리후생 페이지다.
--   꼬리말 Copyright SNT Energy Co., Ltd. · 헤더 메뉴 채용정보 아래 채용공고 · SNT인재상 · 인사제도 · 복리후생.
--   SSR 이라 원본 HTML 에 5블록(건강관리 · 자녀 학자금 및 교육 지원 · 생활안정 · 여가생활 · 기타) 목록이 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요. robots 는 /board_utf8/ · /bbsDown/ 만 금지(http · https 같은 내용).
--   정본 URL 을 http 로 둔 이유: https 는 서버 DH 키가 작아 주간 출처 점검기가 TLS 오류(error)를 낸다.
--   http 응답은 본문 목록 전체를 싣고 브라우저만 https 로 옮기는 스크립트를 앞에 둔다(사이트 canonical 도 http). 점검기 ok.
--   복리후생 페이지는 형제 SNT모티브 · SNT다이내믹스 채용 사이트 복리 페이지와 항목 구성이 달라 법인 고유 원문이다(각주 없음).
--   보조 출처는 같은 도메인 채용정보 > 인사제도 페이지(hr_system.html). 이 페이지 머리 주어가 SNT는 이고
--   교육제도 문장이 형제 2사 인사제도 페이지와 글자까지 같아 그 근거 1행에 SNT그룹 공통 문구 각주를 달았다.
--   같은 페이지 임금제도 칸은 당사는 주어에 형제와 문장이 달라 법인 원문으로 보고 각주 없이 썼다.
--   공시 보조 없음: 2026 반기보고서(접수 20260812000070) 유연근무제 활용 여부 부 · 우리사주조합은 주주 표 한 칸뿐 ·
--   기타장기종업원급여부채 숫자 표만 있고 장기근속 문장 없음 · 직원 238명(2026-06-30).
--   지속가능경영 · ESG 보고서는 자기 도메인에 없다(ESG경영 메뉴는 사회공헌 · HSE 소개뿐).
--   귀속: 형제 SNT모티브는 대기 시드(웨이브 8) · 문장 겹침은 근거표 머리.
--   금액: 원문 원 단위 숫자 0건 · 구내식당 끼니 미기재라 식대도 NULL — 금액 행 0.
--   제외: 법정(일반건강진단 · 특수건강진단 연 1회) · 외부 강사 초빙 교육(사내 집합 교육) · 임금제도 상여율(임금 구성) ·
--     임원 보수지급기준 칸 귀향비 · 선물비(임원 산정 칸) · 기타장기종업원급여부채(장기근속 문장 없음 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 15행(게시판 공고 1건은 2025-07 마감 · 복리후생 블록 없음).
--   SORT 섹션 순서 = 정본 페이지 등장 순(work_env 10 · health 20 · family 30 · leisure 40 · compensation 50 · perks 60),
--     보조 페이지에만 있는 growth 70.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 15행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('snt_energy', 'SNT에너지',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '에너지/발전', 'S', 'http://www.hisnt.com/kor/about/benefits.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_energy');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.hisnt.com/kor/about/benefits.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 복리후생 건강관리 ──
  (@comp_id, 'lounge', '휴게실·샤워장 운영', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실 및 샤워장 운영 (공식 홈페이지 채용정보 복리후생 건강관리 항목) — 운영 사업장·이용 시간 미기재', 10),
  -- ── 건강 (health) — 복리후생 건강관리 ──
  (@comp_id, 'health_check', '종합건강진단 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강진단 비용 지원 (공식 홈페이지 채용정보 복리후생 건강관리 항목) — 검진 대상·주기·지원 금액 미기재', 20),
  (@comp_id, 'fitness', '탁구장·체력단련장 운영', NULL, 'health',
   'est', NULL, TRUE, '탁구장, 체력단련장 등 운영 (공식 홈페이지 채용정보 복리후생 건강관리 항목) — 운영 사업장·이용 시간 미기재', 21),
  -- ── 가족 (family) — 복리후생 자녀 학자금 및 교육 지원 · 생활안정 ──
  (@comp_id, 'child_edu', '자녀 학자금 및 교육 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원·중학교·고등학교 자녀 학자금, 대학 등록금 일부 지원, 사원자녀 방학 중 영어캠프 및 해외어학연수 지원 (공식 홈페이지 채용정보 복리후생 자녀 학자금 및 교육 지원 항목) — 지원 금액·한도·자녀 수 제한 미기재', 30),
  (@comp_id, 'parenting', '대학입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '대학입학 축하금 (공식 홈페이지 채용정보 복리후생 자녀 학자금 및 교육 지원 항목) — 지급 금액·지급 기준 미기재', 31),
  (@comp_id, 'event', '경조사 화환·상조팀 운영', NULL, 'family',
   'est', NULL, TRUE, '본인/가족의 경조사 화환 및 상조팀 운영 (공식 홈페이지 채용정보 복리후생 생활안정 항목) — 경조 종류별 지원 범위 미기재', 32),
  -- ── 여가 (leisure) — 복리후생 생활안정 · 여가생활 ──
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 지급 (공식 홈페이지 채용정보 복리후생 생활안정 항목) — 지급 금액·지급 기준 미기재', 40),
  (@comp_id, 'resort', '하계휴양소 운영', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴양소 운영 (공식 홈페이지 채용정보 복리후생 여가생활 항목) — 휴양소 위치·이용 기간 미기재', 41),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 적극 지원, 자기계발 및 취미써클 행사비 보조 (공식 홈페이지 채용정보 복리후생 여가생활 항목) — 지원 금액·동호회 수 미기재', 42),
  (@comp_id, 'company_event', '전사 한마음 체육대회·야유회', NULL, 'leisure',
   'est', NULL, TRUE, '전사 한마음 체육대회 및 야유회 실시 (공식 홈페이지 채용정보 복리후생 여가생활 항목) — 개최 주기·시기 미기재', 43),
  -- ── 보상 (compensation) — 복리후생 생활안정 · 인사제도 임금제도 ──
  (@comp_id, 'holiday_gift', '명절 귀향여비·기념품', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀향여비 지급, 설날·추석·근로자의 날 기념품 지급 (공식 홈페이지 채용정보 복리후생 생활안정 항목) — 지급 금액·기념품 내용 미기재', 50),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '사무직 연봉제 + 성과급, 생산직 기본급·상여급 + 성과급 (공식 홈페이지 채용정보 인사제도 임금제도 항목) — 성과급 지급 기준·지급률 미기재', 51),
  -- ── 생활 (perks) — 복리후생 기타 ──
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (공식 홈페이지 채용정보 복리후생 기타 항목) — 노선·운행 시간 미기재', 60),
  (@comp_id, 'meal', '구내식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영 (공식 홈페이지 채용정보 복리후생 기타 항목) — 제공 끼니·식비 부담 미기재', 61),
  -- ── 성장 (growth) — 인사제도 교육제도 ──
  (@comp_id, 'conference', '협회·기관 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '각 협회 및 기관을 통한 교육 지원 (공식 홈페이지 채용정보 인사제도 교육제도 항목, SNT그룹 공통 문구) — 지원 범위·대상 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
