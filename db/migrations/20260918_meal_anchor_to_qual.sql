-- ══════════════════════════════════════════════════════════════════════
-- meal 432 앵커 규칙 위반 22행 → 정성 항목 전환 (금액 제거) — 22행
-- 사용자 결정: 2026-09-18 · 선례: db/migrations/20260905_cj_housing_loan_to_qual.sql
--
-- 규칙(복지 배치1 확립 ②, 2026-08-31): meal 432 앵커는 **3식 이상 명시**일 때만 쓴다.
--   432 = 일 18,000원 x 240일. 회사가 밝힌 금액이 아니라 **환산 공식값**이다.
--   3식이 명시되지 않은 행에 이 값을 붙이면 근거 없는 432가 비교 합계에 그대로 들어간다.
--   meal=432 43개사 중 항목명·설명 어디에도 3식 표기가 없는 행이 22개였다
--   (항목명까지 본다 — LIG 「조/중/석식 제공」·유진테크 「3끼」는 충족이라 대상 아님).
--
-- 무엇을 바꾸나: BENEFIT_AMT NULL · QUAL_YN TRUE · AMT_SOURCE_CD none · NOTE_CTNT NULL.
--   설명의 사실(「인근 제휴식당 중식/석식 무상」 등)은 QUAL_DESC_CTNT 로 옮겨 남긴다.
--   설명에서 걷는 것은 두 가지뿐 — 「(추정)」(금액이 없어지면 가리킬 대상이 없다)과
--   「일 18,000원 x 240일」(앵커 공식을 적어 둔 것이지 회사 사실이 아니다).
--   남는 사실이 없으면 NULL — 항목명(「중식 제공」「식대 지원」)이 이미 말한다.
--
-- 2식·1식 행(HMM·보로노이·케어젠·파크시스템스·한미반도체 = 2식, 레인보우로보틱스 = 1식)에
--   더 작은 금액을 새로 매기지 않는다. 그건 새 추정을 만드는 일이라 별도 결정이 필요하다.
--   이번엔 근거 없는 432를 걷는 것까지만 한다.
--
-- 적용: mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260918_meal_anchor_to_qual.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
-- 기대 영향 행 수: 22 (문마다 1). 적으면 멈추고 확인하라 — 회사명 오타면 @c 가 NULL 이라
--   오류 없이 0행이고, BADGE_CD 가 official 이 아니면(재직자 수정) 가드가 일부러 건너뛴 것이다.
-- 멱등: WHERE 에 QUAL_YN = FALSE AND BENEFIT_AMT = 432 — 두 번째 실행은 0행.
-- 가드: BADGE_CD = 'official' — 재직자가 고친 행은 조용히 덮지 않는다.
-- 시드: 같은 22행을 db/seed/benefit/sql/*.sql 에서도 고쳤다(업서트라 재적용해도 같은 종착 상태).
-- ══════════════════════════════════════════════════════════════════════

-- DB손해보험 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'db_insurance');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- HMM — 「제휴식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hmm');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '인근 제휴식당 중식/석식 무상',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- LG전자 — 「사내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_elec');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- SK텔레콤 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skt');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = 'The Table 한식/아시안/양식/샐러드',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 대한항공 — 「구내식당 식사 제공」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '전 사옥 구내식당 운영, 식당 미설치 지역은 인근 식당 계약',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 레인보우로보틱스 — 「중식 제공」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'rainbow_robotics');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 리노공업 — 「구내 식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lino');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 리메드 — 「식대 지원」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'remed');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 보로노이 — 「점심/저녁식사 제공」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'voronoi');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '점심 및 저녁식사 제공',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 삼성바이오로직스 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_bio');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '건강식 무료 제공',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 솔브레인 — 「사내 식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 오스코텍 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'oscotec');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 지놈앤컴퍼니 — 「식대 지원」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'genome_company');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 카카오뱅크 — 「사내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 케어젠 — 「점심/저녁식사 제공」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '점심식사 및 저녁식사 제공',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 클래시스 — 「식비 지원」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'classys');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 테크윙 — 「사내 직영 식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'techwing');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 파크시스템스 — 「중식/석식 지원」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'park_systems');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = NULL,
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 한미반도체 — 「점심/저녁 무상 제공」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '대기업 전문 케이터링(아워홈) 입점',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 현대무벡스 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_muvex');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '구내식당 운영',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 현대오토에버 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_autoever');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '구내식당 운영',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 현대자동차 — 「구내식당」
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '위생적 영양 식사',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'meal' AND BENEFIT_AMT = 432
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
