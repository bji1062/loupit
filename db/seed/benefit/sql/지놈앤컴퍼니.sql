-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 지놈앤컴퍼니 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: http://www.genomecom.co.kr/career/
-- badge: est
--
-- 참고:
--   정본은 자기 도메인(genomecom.co.kr) 헤더 Careers 메뉴가 가리키는 채용소개 페이지의 복리후생 절이다.
--   정적 HTML(그누보드) — 헤드리스 렌더 없음. 항목명 15칸(두 칸은 두 줄 라벨)뿐이고 설명 문장 · 금액 · 대상이 없다.
--   HTTPS 는 호스팅 기본 자체서명 인증서라 http 주소를 정본으로 골랐다.
--   보조 = 자기 도메인 보도자료(2023-12-08 우리사주조합 무상 출연) · OpenDART 2025 사업보고서(주식 소유현황 우리사주조합).
--   헤더 메뉴 주석 속 옛 ATS(genomecom.recruiter.co.kr)는 링크가 주석 처리돼 있고 호스트도 없다 — 근거 아님.
--   귀속: 단독 법인 — 그룹 각주 없음. 직원 96명(DART 2025) — 1,000인 미만.
--   항목명 중 공기청정기 외 · 상비약 구비 · Happy Hour 는 뜻이 맞는 기존 코드가 없거나 내용이 적혀 있지 않아 싣지 않았다.
--   법정 제도: 직무발명 보상제도는 발명진흥법상 사용자 보상 의무라 싣지 않았다(구본 excellence_award 행 삭제).
--   금액: 원문 금액 0 · 구본 추정 승계 4(health_check 100 · club 10 · snack_bar 30 · holiday_gift 20 — 모두 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행 1(excellence_award) · 재코딩 0 · 신규 코드 0. 새 행 3(birthday_gift · company_event · stock_option).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): welcome_kit 이름과 서술을 원문 칸 표기 그대로 사무용품 Welcome Kit 제공으로 바꿈(두 항목이 아니라 한 칸) — 최종 11행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('genome_company', '지놈앤컴퍼니',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'G', 'http://www.genomecom.co.kr/career/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'genome_company');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.genomecom.co.kr/career/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) — 채용소개 복리후생 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 경조 범위·경조금·경조휴가 미기재', 10),

  -- ── 건강·의료 (health) — 채용소개 복리후생 ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '종합 건강검진 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 검진 주기·기관·가족 포함 여부 미기재 (추정)', FALSE, NULL, 20),

  -- ── 경제적 부가혜택 (perks) — 채용소개 복리후생 ──
  (@comp_id, 'meal', '식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '식대 지원 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 지원 금액·끼니·사내식당 여부 미기재', 30),
  (@comp_id, 'birthday_gift', '생일선물', NULL, 'perks',
   'est', NULL, TRUE, '생일선물 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 선물 종류·금액 미기재', 31),
  (@comp_id, 'snack_bar', '카페테리아·음료 및 간식·커피머신', 30, 'perks',
   'est', '카페테리아, 음료 및 간식, 커피머신 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 운영 방식·비용 미기재 (추정)', FALSE, NULL, 32),

  -- ── 성장·커리어 (growth) — 채용소개 복리후생 ──
  (@comp_id, 'edu_support', '교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육 지원 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 대상 교육·비용 지원 범위 미기재', 40),

  -- ── 여가·라이프 (leisure) — 채용소개 복리후생 ──
  (@comp_id, 'club', '동호회 지원', 10, 'leisure',
   'est', '동호회 지원 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 지원 금액·방식 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'company_event', '사내행사', NULL, 'leisure',
   'est', NULL, TRUE, '사내행사 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 행사 종류·횟수 미기재', 51),
  (@comp_id, 'welcome_kit', '사무용품 Welcome Kit 제공', NULL, 'leisure',
   'est', NULL, TRUE, '사무용품 Welcome Kit 제공 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 구성품 미기재', 52),

  -- ── 보상·금전 (compensation) — 채용소개 복리후생 · 보도자료 · 사업보고서 ──
  (@comp_id, 'holiday_gift', '명절선물', 20, 'compensation',
   'est', '명절선물 (공식 홈페이지 Careers 채용소개 복리후생 항목) — 선물 종류·금액·횟수 미기재 (추정)', FALSE, NULL, 60),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 운영 (2025 사업보고서 주식 소유현황 · 공식 홈페이지 보도자료) — 2023년 12월 대표이사 보유 주식 일부를 우리사주조합에 무상 출연, 조합 규정에 따라 조합원에게 배정 · 가입 조건·회사 지원 방식 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
