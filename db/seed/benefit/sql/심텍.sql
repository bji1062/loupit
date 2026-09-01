-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 심텍 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://www.simmtech.com/recruit/welfare_system.aspx
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 심텍 공식 도메인(simmtech.com) CAREERS > 복리후생 페이지.
--       ⚠ 이 페이지는 카테고리 헤딩 4개(건강/가족/회사생활/여가문화)만 HTML 텍스트이고
--       개별 항목명 16개는 전부 PNG 이미지 내부 텍스트다. HTML 파싱으로는 0건이 나온다.
--       16개 라벨은 이미지 4장을 내려받아 직접 판독해 추출했다(evidence 에 해시 기록).
--       페이지에 설명 문장·금액·조건·대상이 일절 없다 — 라벨뿐이다.
--       따라서 17행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE 이며, 신규 회사라
--       승계할 앵커도 없어 타사 금액을 끌어오지 않았다(금액 stated 0건).
--       16 라벨 중 2개가 두 제도를 병기한 복합 라벨이라 4행으로 분리했다
--       (장기근속 및 우수/공로 포상 → long_service_bonus + excellence_award,
--        콘도 및 야유회 → resort + company_event). 16 라벨 → 18행.
--       ⚠ 검증 판정 반영(2026-09-01): 자녀입학축하금을 child_edu 에 병합해 17행
--         (기아·아이센스 선례). SORT 도 10단위 섹션 규칙으로 재배열했다.
--       ⚠ apex 도메인(simmtech.com)은 무응답 — 반드시 www 를 붙여야 한다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('simmtech', '심텍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체기판', 'S', 'https://www.simmtech.com/recruit/welfare_system.aspx');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'simmtech');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.simmtech.com/recruit/welfare_system.aspx'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 및 우수/공로 포상 (공식 페이지 회사생활 항목명 그대로 — 근속 연차·포상 금액 미기재)', 10),
  (@comp_id, 'excellence_award', '우수/공로 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 및 우수/공로 포상 (공식 페이지 회사생활 항목명 그대로 — 포상 기준·금액 미기재)', 11),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 (공식 페이지 건강 항목명 그대로 — 주기·대상·금액 미기재)', 40),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (공식 페이지 건강 항목명 그대로 — 보장 범위·보험료 미기재)', 41),
  (@comp_id, 'blood_bank', '혈액은행', NULL, 'health',
   'est', NULL, TRUE, '혈액은행 (공식 페이지 건강 항목명 그대로 — 운영 방식·이용 대상 미기재)', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 (공식 페이지 가족 항목명 그대로 — 정원·대상 연령 미기재)', 50),
  (@comp_id, 'child_edu', '자녀 학자금·입학축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀대학교 학자금, 자녀입학축하금 (공식 페이지 가족 항목명 그대로 — 지원 한도·자녀 수 제한·대상 학교급·금액 미기재)', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 페이지 가족 항목명 그대로 — 경조금·경조휴가 구분 미기재)', 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 (공식 페이지 여가문화 항목명 그대로 — 활동비 지원 여부 미기재)', 70),
  (@comp_id, 'resort', '콘도', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 야유회 (공식 페이지 여가문화 항목명 그대로 — 제휴처·이용 조건 미기재)', 71),
  (@comp_id, 'company_event', '야유회', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 야유회 (공식 페이지 여가문화 항목명 그대로 — 행사 주기·규모 미기재)', 72),
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 (공식 페이지 여가문화 항목명 그대로 — 지급액·지급 시기 미기재)', 73),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 (공식 페이지 회사생활 항목명 그대로 — 제공 끼니·식대 미기재)', 80),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 (공식 페이지 회사생활 항목명 그대로 — 노선·운행 지역 미기재)', 81),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (공식 페이지 여가문화 항목명 그대로 — 연간 포인트 금액 미기재)', 82),
  (@comp_id, 'housing_loan', '주택자금이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금이자 지원 (공식 페이지 가족 항목명 그대로 — 한도·이율·대상 미기재)', 83),
  (@comp_id, 'housing_support', '숙소임차비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '숙소임차비용 지원 (공식 페이지 회사생활 항목명 그대로 — 지원 한도·대상 미기재)', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
