-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 비에이치 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.bhe.co.kr/sub07/sub02.php
-- badge: est
--
-- 참고:
--   정본은 비에이치 공식 홈페이지 www.bhe.co.kr 헤더 메뉴 채용정보 → 복지제도(/sub07/sub02.php)다. 서버 렌더 HTML 에
--   법정 복리후생 제도 5개(행 아님)와 사내 복리후생 제도 4블록(교육지원 · 포상제도 · 휴가제도 · 사내식당 운영)이 글로 있다
--   (꼬리말 Copyright 2017 BH Co., Ltd. · 블록 이미지 4장은 100x75 아이콘).
--   보조 출처: 같은 사이트 ESG경영 페이지에서 받는 2025년 비에이치 ESG 보고서 72쪽 비에이치 조직문화 표
--     (근무환경 지원 · 임직원 소통 프로그램). 2024년 보고서 68쪽 표와 문장이 같다.
--   채용공고 게시판(bbs73)은 게시물 0건. robots: www.bhe.co.kr robots.txt 404(제한 없음).
--   금액: 구본 추정 승계 1(health_check 100 — 틀 값, NOTE 끝에 (추정)). meal 288 은 구본 전제가 중식 식대 현금 지원이라
--     원문(4식 사내식당 무상 제공)과 구조가 달라 승계하지 않았다.
--   제외 항목: 교육지원 블록의 신입사원 입문교육 · OJT · 직무 · 계층 교육(회사 주도 업무 교육 — e-러닝 · 독서통신 · 사내외국어 교육은 2026-10-04 규칙 8 개정으로 되살림) ·
--     법정 복리후생 제도(4대 보험 · 퇴직금) · 휴가제도 블록의 법정 휴가 · 기숙사(보고서가 해외사업장 한정으로 적음) ·
--     월 1회 사내 소통프로그램 · 소통 게시판(조직문화 프로그램 — 혜택 미기재).
--   구본에서 뺀 행: family_day · event · self_development · welfare_point · telecom · holiday_gift(공식 원문에 없음). 재코딩 없음.
--   SORT 섹션 순서 = 홈페이지 사내 복리후생 제도 블록 순서, 보고서에만 있는 카테고리는 끝
--     (compensation 10 · time_off 20 · perks 30 · health 40 · leisure 50).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): meal 구본 추정 288 을 비움(구본 전제 중식 식대 현금 지원 vs 원문 4식 사내식당 무상 제공 — 구조가 다름) · 2025 보고서 비에이치 조직문화 표의 창립기념행사·종무식·시무식을 company_event 행으로 보탬 — 최종 7행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 2(lang · edu_support) — 최종 9행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('bh', '비에이치',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전자부품', 'B', 'https://www.bhe.co.kr/sub07/sub02.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'bh');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.bhe.co.kr/sub07/sub02.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 홈페이지 포상제도 / 2025 보고서 BH인 시상 ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 홈페이지 복지제도 포상제도 항목) — 근속연수 기준·포상 내용·금액 미기재', 10),
  (@comp_id, 'excellence_award', '모범사원·올해의 BH인 포상·제안 시상', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원 포상, 올해의 BH인 포상, 제안 시상 (공식 홈페이지 복지제도 포상제도 항목), 업무개선 및 리더십을 보인 개인에게 「BH인」을 시상함으로써 임직원의 격려 및 보상 제공 (2025 비에이치 ESG 보고서 비에이치 조직문화 BH인 시상 항목) — 포상 기준·금액 미기재', 11),

  -- ── 시간·휴가 (time_off) — 홈페이지 휴가제도 ──
  (@comp_id, 'leave_general', '경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '경조휴가 부여 (공식 홈페이지 복지제도 휴가제도 항목) — 경조 종류별 휴가 일수·유급 여부 미기재', 20),

  -- ── 경제적 부가혜택 (perks) — 홈페이지 사내식당 운영 / 2025 보고서 구내식당 · 휴게장소 ──
  (@comp_id, 'meal', '사내식당 조식·중식·석식·야식 무상 제공', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영(조식, 중식, 석식, 야식 제공) (공식 홈페이지 복지제도 항목), 임직원 식사 무상제공 (2025 비에이치 ESG 보고서 근무환경 지원 구내식당) — 식대 단가 미기재', 30),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '휴게 장소로 사내 카페테리아 운영 (2025 비에이치 ESG 보고서 비에이치 조직문화 근무환경 지원 휴게장소 항목) — 이용 비용·운영 시간 미기재', 31),

  -- ── 건강·의료 (health) — 2025 보고서 건강관리 ──
  (@comp_id, 'health_check', '건강검진 (연 1회 · 지역병원 연계)', 100, 'health',
   'est', '지역병원과 연계한 건강검진 서비스 연 1회 제공 (2025 비에이치 ESG 보고서 근무환경 지원 건강관리 항목) — 검진 항목·지원 한도 미기재 (추정)', FALSE, NULL, 40),

  -- ── 여가·라이프 (leisure) — 2025 보고서 임직원 소통 프로그램 ──
  (@comp_id, 'company_event', '창립기념행사·종무식·시무식', NULL, 'leisure',
   'est', NULL, TRUE, '창립기념행사, 종무식, 시무식 운영 (2025 비에이치 ESG 보고서 비에이치 조직문화 임직원 소통 프로그램 항목) — 행사 내용·기념품·휴무 여부 미기재', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '사내외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '사내외국어 교육 (공식 홈페이지 복지제도 교육지원 항목) — 대상 언어·수강 방식·비용 부담 미기재', 60),
  (@comp_id, 'edu_support', '독서통신교육·e-러닝교육', NULL, 'growth',
   'est', NULL, TRUE, '독서통신교육, e-러닝교육 (공식 홈페이지 복지제도 교육지원 항목) — 과정 내용·수강 대상·비용 부담 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
