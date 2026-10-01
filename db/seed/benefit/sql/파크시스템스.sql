-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파크시스템스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.parksystems.com/kr/news-events/news/news-details.news0179
-- badge: est
--
-- 참고:
--   공식 홈페이지 www.parksystems.com (Adobe AEM) 에는 상시 복지 페이지가 없다. 채용 정보(/kr/company/career)는
--   핵심 가치·인재상만, 채용 공고(/bin/parksystems/careerCFList 데이터 API · 국내 공고 5건)는 근무조건만 싣는다.
--   그래서 행 근거는 헤더 메뉴 뉴스 & 이벤트 > 회사뉴스에 실린 회사 보도자료 셋이다(서버 렌더 · robots.txt 404 = 제한 없음).
--     ① news0179 2016년 경기가족친화 일하기 좋은기업 선정 (국문) — 복지 항목 7개, 정본 URL
--     ② news0178 2016년 경기도여성고용우수기업 최우수상 (국문)
--     ③ park-systems-opens-new-global-headquarters 2026-04-07 글로벌 본사 개관 (영문 보도자료,
--        국문 기사 모음 press-parksystems-new-headquaters-kr 에 같은 내용)
--   ①② 는 2016년 기준 서술이라 현행 여부를 원문이 밝히지 않는다(근거표 판단 요청).
--   귀속: 법인 자기 도메인의 법인 보도자료라 그룹 각주 없음. 직원 수(DART 2025) 392 — 재취업지원 의무 아님, 원문에 해당 문구 없음.
--   금액: 원문에 연 환산 금액 0. 구본 추정치 health_check 100 · event 50 · welfare_point 200 · telecom 30 · holiday_gift 20 은
--     같은 제도가 원문에 없어 승계하지 않았다. 구본 stated fertility_support 100 은 원문에 숫자가 없어 승계하지 않았다.
--   구본에서 뺀 행 15: incentive · stock_option · remote_work · work_tools · parking · health_check · event · edu_support ·
--     mba · library · club · welfare_point · snack_bar · telecom · holiday_gift (공식 원문에 근거 없음).
--   재코딩 1: fertility_support → parenting (원문은 출산 축하금·산후조리비용 — 난임 지원이 아니다).
--   SORT 섹션 순서 = 정본 보도자료 ① 의 항목 순서, ①에 없는 카테고리는 ③ 순서
--     (flexibility 10 · family 20 · compensation 30 · time_off 40 · health 50 · growth 60 · leisure 70 · perks 80).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 11행 전부 원문 확인 · 시드 조치 없음 · 7행은 2016년 보도자료 단독 근거라 서술에 출처 연도를 둔다 · 구본 금액 6개 미승계 — 최종 11행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('park_systems', '파크시스템스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체계측', 'P', 'https://www.parksystems.com/kr/news-events/news/news-details.news0179');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'park_systems');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.parksystems.com/kr/news-events/news/news-details.news0179'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) — 보도자료 ① · ② ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 도입 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료), 시간제(유연) 근로 제도 운영 (공식 홈페이지 회사뉴스 2016년 경기도여성고용우수기업 최우수상 보도자료) — 출퇴근 시간 선택 범위 미기재', 10),

  -- ── 가족·돌봄 (family) — 보도자료 ① · ② · ③ ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 내 어린이집 지원 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료 · 2016년 경기도여성고용우수기업 최우수상 보도자료), 과천 글로벌 본사 직원 시설인 사내 어린이집 (공식 홈페이지 회사뉴스 2026년 글로벌 본사 개관 보도자료) — 정원·이용 조건 미기재', 20),
  (@comp_id, 'parenting', '출산 축하금·산후조리비용 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 시 축하금 및 선물 지급 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료), 산후조리비용 지원 (공식 홈페이지 회사뉴스 2016년 경기도여성고용우수기업 최우수상 보도자료) — 지급액·선물 내용 미기재', 21),

  -- ── 보상·금전 (compensation) — 보도자료 ① ──
  (@comp_id, 'excellence_award', '우수사원 포상제', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상제 운영 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료) — 선정 기준·포상 내용 미기재', 30),

  -- ── 시간·휴가 (time_off) — 보도자료 ① ──
  (@comp_id, 'long_service_leave', '장기근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속휴가 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료) — 근속 기준·휴가 일수 미기재', 40),
  (@comp_id, 'leave_general', '포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '포상휴가 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료) — 부여 기준·휴가 일수 미기재', 41),

  -- ── 건강·의료 (health) — 보도자료 ① · ③ ──
  (@comp_id, 'fitness', '피트니스 센터·체련비 지원', NULL, 'health',
   'est', NULL, TRUE, '체련비 지원 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료), 과천 글로벌 본사 직원 시설인 피트니스 센터 (공식 홈페이지 회사뉴스 2026년 글로벌 본사 개관 보도자료) — 체련비 지원액 미기재', 50),
  (@comp_id, 'clinic', '의료인 사내 방문 건강상담', NULL, 'health',
   'est', NULL, TRUE, '인근 병원과 연계한 월 1회 의료인 사내 방문 건강상담 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료)', 51),

  -- ── 성장·커리어 (growth) — 보도자료 ① ──
  (@comp_id, 'lang', '어학교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육비 지원 (공식 홈페이지 회사뉴스 2016년 경기가족친화 일하기 좋은기업 선정 보도자료) — 지원 한도·대상 과정 미기재', 60),

  -- ── 여가·라이프 (leisure) — 보도자료 ③ ──
  (@comp_id, 'leisure_room', '골프 시뮬레이터 라운지', NULL, 'leisure',
   'est', NULL, TRUE, '과천 글로벌 본사 직원 시설인 골프 시뮬레이터 라운지 (공식 홈페이지 회사뉴스 2026년 글로벌 본사 개관 보도자료) — 이용 조건 미기재', 70),

  -- ── 경제적 부가혜택 (perks) — 보도자료 ③ ──
  (@comp_id, 'meal', '무료 식사 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '과천 글로벌 본사 직원 시설인 무료 식사 제공 카페테리아 (공식 홈페이지 회사뉴스 2026년 글로벌 본사 개관 보도자료) — 제공 끼니 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
