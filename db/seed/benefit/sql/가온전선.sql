-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 가온전선 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://gaoncable.recruiter.co.kr/appsite/company/callSubPage?code1=4000&code2=4600
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 가온전선 법인명 전용 채용 서브도메인(gaoncable.recruiter.co.kr) 인사제도 > 복리후생
--       페이지 한 곳이다. 자기 도메인 www.gaoncable.com 의 GNB 「인재/채용」이 이 서브도메인으로 직결하고,
--       사이트 회사 정보가 companyName 가온전선(주), 리드 문구가 「가온전선은 구성원이 업무에만 몰입할 수
--       있게 다양한 복리후생을 지원하고 있습니다.」라 법인 전용이다 → 그룹 통합 각주 해당 없음.
--       렌더 방식: 원본 HTML(5,546 B)에는 항목 0개(JS 렌더). 헤드리스 렌더는 하지 않았다 — 렌더가 robots
--       금지 경로(/resources-2.0.3a/*.js · /app/*)를 끌어온다. 대신 허용 경로 데이터 API
--       POST /appsite/company/getMainView (appsiteSn=2331, settingType=B, 쿠키 없음) 1회 호출 JSON 에서
--       menuCode 4600(useYn 1) 메뉴의 contents 만 읽었다(h2 = 카테고리 6, li = 항목 13).
--       robots 판정(RFC 9309 가장 긴 일치): * 레코드 Disallow: / 보다 Allow: /appsite/ 가 길어 허용.
--       파이썬 urllib.robotparser 는 첫 일치라 금지로 오판한다.
--       ⚠ 같은 JSON 의 비활성 메뉴 4400 직급체계 · 4500 평가 및 보상에는 ATS 벤더(마이다스아이티) 샘플 문구
--         (연봉 4,000만원 · 자동승진 등)가 남아 있다 — 유령이라 한 건도 쓰지 않았다.
--       ⚠ LS 그룹 공통 복리후생(www.lsholdings.com)은 계열사별 차이 면책이 붙은 그룹 서술이고 항목도 달라
--         한 건도 섞지 않았다(이번 세션 요청 0회).
--       원문 13항목, 전부 항목명뿐(설명 문장 없음). 코드 기준 분해 1건 · 같은 코드 병합 1건 → 13행.
--         분해: 기념일 선물(생일선물, 추석선물) → birthday_gift + holiday_gift
--         병합: 경조 휴가 및 경조금 지급 + 경조물품 지원 → event 1행
--         하기휴가, 하기휴가비 지급 은 한 항목이라 summer_leave 1행에 휴가비까지 담았다(한국항공우주산업 동일 라벨).
--         집중 휴가제(休weeks)는 부여 일수·방식이 원문에 없어 leave_general(검증·감사 판정 — refresh_leave 아님).
--       신규 코드 0. 금액: 원 단위 표기 0건 → 13행 전부 NULL. 정량 조건은 종합 검진의 만 35세 이상 1건.
--       법정 제도 문구는 페이지에 없다. 경조 휴가는 회사 재량 휴가라 event 서술에 원문대로 남겼다.
--       표기 정규화: 원문 팬션 → 펜션, 줄바꿈 없는 공백(nbsp) → 일반 공백.
--       ⚠ 게재 시점 불명 — 메뉴 수정일 필드가 없고 채용 사이트 생성일이 2018-08-02 다.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 수 13 그대로. SORT 60 休weeks 는 부여 일수가 없어 refresh_leave 에서
--       leave_general 로 재코딩했다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gaon_cable', '가온전선',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전선/전력', 'G', 'https://gaoncable.recruiter.co.kr/appsite/company/callSubPage?code1=4000&code2=4600');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gaon_cable');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://gaoncable.recruiter.co.kr/appsite/company/callSubPage?code1=4000&code2=4600'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 원문 주거 지원 ──
  (@comp_id, 'dormitory', '지방근무자 사택 지원', NULL, 'work_env',
   'est', NULL, TRUE, '지방근무자 사택지원 (공식 채용 페이지 복리후생 주거 지원 항목 — 지방근무자 대상, 지방 근무 기준·사택 형태·본인 부담 미기재)', 10),

  -- ── 경제적 부가혜택 (perks) — 원문 주거 지원 · 생활 지원 ──
  (@comp_id, 'housing_loan', '주택구입·전세자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입자금 및 전세자금 지원 (공식 채용 페이지 복리후생 주거 지원 항목 — 대출·이자 지원 등 지원 방식, 한도, 자격 요건 미기재)', 20),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '기념일 선물 중 생일선물 (공식 채용 페이지 복리후생 생활 지원 항목 — 선물 품목·금액 미기재)', 21),
  (@comp_id, 'discount', '임직원 할인몰', NULL, 'perks',
   'est', NULL, TRUE, '임직원 할인몰 운영 (공식 채용 페이지 복리후생 생활 지원 항목 — 입점 상품·할인율·이용 한도 미기재)', 22),

  -- ── 보상·금전 (compensation) — 원문 생활 지원 ──
  (@comp_id, 'holiday_gift', '추석 선물', NULL, 'compensation',
   'est', NULL, TRUE, '기념일 선물 중 추석선물 (공식 채용 페이지 복리후생 생활 지원 항목 — 선물 품목·금액 미기재, 추석 외 명절 선물 미기재)', 30),

  -- ── 가족·돌봄 (family) — 원문 학비 지원 · 경조 지원 ──
  (@comp_id, 'child_edu', '자녀 학비 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교/대학교 자녀 학비지원 (공식 채용 페이지 복리후생 학비 지원 항목 — 고등학교·대학교 자녀 대상, 지원 한도·자녀 수 제한·금액 미기재)', 40),
  (@comp_id, 'event', '경조 휴가·경조금·경조물품', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가 및 경조금 지급, 경조물품 지원 (공식 채용 페이지 복리후생 경조 지원 항목 — 경조 구분별 휴가 일수·경조금액·물품 종류 미기재)', 41),

  -- ── 여가·라이프 (leisure) — 원문 여가 지원 ──
  (@comp_id, 'resort', '콘도미니엄·펜션', NULL, 'leisure',
   'est', NULL, TRUE, '콘도미니엄, 펜션 운영 (공식 채용 페이지 복리후생 여가 지원 항목 — 보유 시설·이용 한도·본인 부담 미기재)', 50),
  (@comp_id, 'club', '사내동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 지원 (공식 채용 페이지 복리후생 여가 지원 항목 — 지원 내용·활동비 금액 미기재)', 51),

  -- ── 시간·휴가 (time_off) — 원문 여가 지원 ──
  (@comp_id, 'leave_general', '집중 휴가제 (休weeks)', NULL, 'time_off',
   'est', NULL, TRUE, '집중 휴가제 (休weeks) (공식 채용 페이지 복리후생 여가 지원 항목 — 휴가 기간·부여 일수·사용 방식 미기재)', 60),
  (@comp_id, 'summer_leave', '하기휴가·하기휴가비', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가, 하기휴가비 지급 (공식 채용 페이지 복리후생 여가 지원 항목 — 휴가 일수·유급 여부·사용 시기·휴가비 금액 미기재)', 61),

  -- ── 건강·의료 (health) — 원문 의료 지원 ──
  (@comp_id, 'medical', '본인 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 의료비 지원 (공식 채용 페이지 복리후생 의료 지원 항목 — 본인 대상, 지원 한도·지원 비율·금액 미기재)', 70),
  (@comp_id, 'health_check', '정기 종합검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '본인과 배우자에 대한 정기 종합 검진 (공식 채용 페이지 복리후생 의료 지원 항목 — 대상 조건 만 35세 이상, 검진 주기·검진 기관·지원 금액 미기재)', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
