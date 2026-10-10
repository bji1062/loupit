-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한온시스템 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://hanonsystems.recruiter.co.kr/career/welfare
-- badge: est
--
-- 참고:
--   정본은 한온시스템 회사 계정 채용 사이트(jobflex ATS hanonsystems.recruiter.co.kr)의 복리후생 페이지다.
--     자기 도메인 www.hanonsystems.com 국문 GNB 회사소개 > 입사지원 이 이 ATS 로 나간다. 자기 도메인에는 복지 항목 페이지가 없다.
--   렌더 방식: Next.js CSR — 원본 HTML 에 본문이 없고 본문 API 호스트(api-recruiter · api-builder)는 robots Disallow /.
--     그래서 사용자가 2026-10-10 브라우저로 열어 붙여 넣은 화면 본문을 썼다
--     (사본 loupit-evidence/2026-10-10-wave5/hanon/user_paste_2026-10-10.txt · sha256 b801f6ba…f417f). 5구역 21항목.
--   보조 출처 없음. 국문 ESG 보고서 PDF 는 자기 도메인 robots 금지 경로(/Kor/) 아래라 요청하지 않았다.
--     자기 도메인 Workplace · Citizen 페이지는 독일 · 멕시코 · 터키 법인 사례가 섞인 글로벌 서술이라 근거로 쓰지 않았다.
--   귀속: 본문 주어 「한온시스템은」 · 푸터 「ⓒ 2025 Copyright 한온시스템」 — 법인 단독 채용 사이트, 그룹 각주 없음.
--     기등록 형제 한국타이어앤테크놀로지와 다른 ATS 계정 · 다른 문장(그룹 템플릿 아님). 타이어 할인 한 줄만 겹친다.
--   금액: 추정 1행(meal 하루 2끼 × 1끼 12,000원 × 연 240일 = 576). 회사 공식 수치 0행. 그 밖의 원문에는 원 단위 숫자가 없다.
--   제외: 업계 최고 수준의 대졸 초임(급여성) · 퇴직 연금제도 IRP 제도 운영(법정 퇴직급여).
--   공고 근거 0행 / 전체 19행. SORT 섹션 = 보상 10 · 건강 20 · 여가 30 · 생활 40 · 휴가 50 · 가족 60 (페이지에 처음 나온 순서).
-- 검증 · 감사 판정 반영(2026-10-10): 경영실적 성과급을 incentive 에서 profit_sharing 으로 재코딩 · 식대 576 유지 — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanon_systems', '한온시스템',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'H', 'https://hanonsystems.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanon_systems');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hanonsystems.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 공식 채용 페이지 복리후생 급여 ──
  (@comp_id, 'profit_sharing', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '경영실적에 따른 성과급 지급 (공식 채용 페이지 복리후생 급여 항목) — 지급 기준·지급률·지급 시기 미기재', 10),

  -- ── 건강·의료 (health) — 건강지원 · 복지시설 · 생활지원 ──
  (@comp_id, 'health_check', '정기건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기건강검진, 임직원 종합검진 지원 (공식 채용 페이지 복리후생 건강지원 항목) — 종합검진 대상·검진 주기·비용 지원 범위 미기재', 20),
  (@comp_id, 'medical', '의료비 단체보험(실비보험)·재활치료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 단체보험(실비보험) 지원, 본인, 배우자, 부모 및 자녀 치료비 병실료 등 지원 (공식 채용 페이지 복리후생 건강지원 항목), 재활치료비 지원 (생활지원 항목) — 보장 한도·재활치료비 지원 대상·금액 미기재', 21),
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 운영, 다양한 임직원 건강 캠페인(독감 예방접종 등) (공식 채용 페이지 복리후생 건강지원 항목) — 건강관리실 운영 사업장·상주 인력 미기재', 22),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터 운영 (공식 채용 페이지 복리후생 복지시설 항목) — 운영 사업장·이용 시간 미기재', 23),

  -- ── 여가·라이프 (leisure) — 복지시설 · 임직원 가족 이벤트 ──
  (@comp_id, 'resort', '법인 콘도·호텔/휴양 시설·하계휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '법인 콘도 및 국내 호텔/휴양 시설을 합리적인 가격으로 이용할 수 있도록 지원 (공식 채용 페이지 복리후생 복지시설 항목), 하계휴양소 운영 (임직원 가족 이벤트 항목) — 이용 요금·이용 횟수·휴양소 위치 미기재', 30),
  (@comp_id, 'club', '사내 취미반', NULL, 'leisure',
   'est', NULL, TRUE, '사내 취미반 운영 (공식 채용 페이지 복리후생 복지시설 항목) — 취미반 종류·활동비 지원 여부 미기재', 31),
  (@comp_id, 'company_event', '춘계행사·체육대회·주말 농장', NULL, 'leisure',
   'est', NULL, TRUE, '춘계행사, 체육대회 (공식 채용 페이지 복리후생 임직원 가족 이벤트 항목), 주말 농장 운영 (복지시설 항목) — 행사 개최 주기·가족 참여 범위·농장 위치·이용 방법 미기재', 32),

  -- ── 경제적 부가혜택 (perks) — 복지시설 · 생활지원 ──
  (@comp_id, 'meal', '사내식당 (판교/대전/평택)', 576, 'perks',
   'est', '판교/대전/평택 사내식당 운영, 조식, 중식 외 필요한 식사 무료 제공 (공식 채용 페이지 복리후생 복지시설 항목) — 그 밖의 사업장 식당 운영 여부 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정, 그 외 필요한 식사 제외)', FALSE, NULL, 40),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 주요 지역 통근버스 운영 (공식 채용 페이지 복리후생 복지시설 항목) — 운행 노선·운행 사업장 미기재', 41),
  (@comp_id, 'welfare_point', '복지카드', NULL, 'perks',
   'est', NULL, TRUE, '복지카드 지급, 근속년수 및 직급에 따른 지원 (공식 채용 페이지 복리후생 생활지원 복지카드/유류카드 항목) — 지급 금액·사용처 미기재', 42),
  (@comp_id, 'transport', '유류카드', NULL, 'perks',
   'est', NULL, TRUE, '유류카드 지급, 근속년수 및 직급에 따른 지원 (공식 채용 페이지 복리후생 생활지원 복지카드/유류카드 항목) — 지급 금액·지급 주기 미기재', 43),
  (@comp_id, 'housing_loan', '사내 대출 (주택·생활안정 자금)', NULL, 'perks',
   'est', NULL, TRUE, '사내 대출, 주택 자금 대출, 생활안정 자금 대출, 재해지원 (공식 채용 페이지 복리후생 생활지원 항목) — 대출 한도·이율·재해지원 내용 미기재', 44),
  (@comp_id, 'discount', '타이어 할인', NULL, 'perks',
   'est', NULL, TRUE, '타이어 할인 (공식 채용 페이지 복리후생 생활지원 항목) — 할인율·대상 제품·구매 한도 미기재', 45),

  -- ── 휴가·휴식 (time_off) — 복지시설 ──
  (@comp_id, 'long_service_leave', '장기근속휴가 (근속 5년부터)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속휴가제도 (근속 5년부터 지원), 5년단위로 최장 35년까지 휴가 및 휴가비 지원 (공식 채용 페이지 복리후생 복지시설 항목) — 근속 단계별 휴가 일수·휴가비 금액 미기재', 50),
  (@comp_id, 'leave_general', '특별 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '특별 휴가 (공식 채용 페이지 복리후생 복지시설 항목) — 휴가 사유·일수·유급 여부 미기재', 51),

  -- ── 가족·돌봄 (family) — 생활지원 ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지원, 경조휴가, 경조사비, 전문 조사 지원인력, 화환, 용품 등 (공식 채용 페이지 복리후생 생활지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 60),
  (@comp_id, 'parenting', '어린이집 위탁보육료 지원', NULL, 'family',
   'est', NULL, TRUE, '어린이집 영유아 위탁보육료 지원 (공식 채용 페이지 복리후생 생활지원 항목) — 지원 금액·대상 자녀 연령 미기재', 61),
  (@comp_id, 'child_edu', '자녀 학자금·유치원비 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (자녀수 제한 없음), 국내대학 기준 정규학기 등록금 전액 지원, 유치원비 지원 (공식 채용 페이지 복리후생 생활지원 항목) — 지원 학령 범위·유치원비 지원 금액 미기재', 62)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
