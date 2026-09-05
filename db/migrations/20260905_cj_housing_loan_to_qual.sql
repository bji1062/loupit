-- ══════════════════════════════════════════════════════════════════════
-- CJ 5개사 housing_loan 행 → 정성 항목 전환 (금액 제거, 한도 사실은 설명으로 보존) — 5행
-- 사용자 결정: 2026-09-05 · 문서: docs/handoff/2026-09-05-CJ-주택자금대출-정성전환.md
--
-- 왜 필요한가: TCOMPANY_BENEFIT.BENEFIT_AMT 의 정의는 **연간 환산 금액(만원)**
--   (db/schema.sql). 카드 힌트도 비교 계산(web/assets/js/calc.js)도 이 값을 연간 가치로
--   합산한다. 그런데 CJ 5개사의 housing_loan 행에는 **대출 원금 한도**가 들어가 있었다
--   (커머스부문 10000 = 1억, 나머지 4사 2000). 원금은 연간 가치가 아니다 —
--   CJ ENM 커머스부문 카드의 「등록 금액 합 1억 600만원」은 94% 가 이 한 행이었고,
--   비교 리포트의 연간 총액이 그만큼 부풀려졌다.
--   SPEC 07 D-6(금액 순위 가드)은 **증상만** 눌렀을 뿐 원인 행은 그대로였다.
--   이번 마이그레이션은 원인 행 자체를 정성(QUAL_YN=TRUE, 금액 NULL)으로 바꾼다.
--   한도·무이자라는 사실은 버리지 않고 QUAL_DESC_CTNT 로 옮긴다.
--
-- 선례(같은 그룹, 같은 코드가 이미 정성으로 들어와 있다):
--   db/seed/benefit/sql/CJENM엔터테인먼트부문.sql · CJ.sql · CJ프레시웨이.sql
-- 건드리지 않는 것: 펄어비스 housing_loan 600 은 매월 50만원 = 진짜 연간 환산이라 유지.
--   다른 회사의 housing_loan(대부분 이미 NULL)도 대상이 아니다.
--
-- 왜 마이그레이션 파일로 남기나: 서빙 DB 변경을 **명시적·감사 가능한 파일**로 남기는
--   저장소 관례를 따른다. **실행 순서는 무관하고 종착 상태도 같다** —
--   TCOMPANY_BENEFIT 시드는 INSERT IGNORE 가 아니라
--   INSERT ... ON DUPLICATE KEY UPDATE(업서트)라서, 마이그레이션 없이
--   고친 시드로 load.py 를 재적용(--fresh 아님)해도 같은 5행이 그대로 덮인다.
--   (INSERT IGNORE 는 TCOMPANY 회사 행에만 쓰인다.)
--   ⚠ 그 뒤집힌 함의: **시드 수정은 재적용 한 번에 곧장 서빙 행을 덮는다.**
--   같은 키(COMP_ID + BENEFIT_CD)라면 재직자가 고친 행도 시드 값으로 되돌아간다 —
--   아래 BADGE_CD 가드는 이 마이그레이션만 지킬 뿐, 재적용까지 막지는 못한다.
--   (재적용 정책 차원의 미해결 문제. handoff 문서 「되돌리기·재적용 함정」 참고)
--
-- 적용: mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260905_cj_housing_loan_to_qual.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
-- 기대 영향 행 수: 5 (cj_cgv · cj_enm_com · cj_logistics · cj_oliveyoung · cj_cheiljedang)
--   5보다 적으면 멈추고 확인하라 — 회사명 오타로 @c 가 NULL 이면 오류 없이 0행이고,
--   BADGE_CD 가 official 이 아니면(재직자 수정) 가드가 일부러 건너뛴 것이다.
-- 멱등: WHERE 에 QUAL_YN = FALSE 를 두었다 — 두 번째 실행은 0행.
-- 가드: WHERE 에 BADGE_CD = 'official' 을 두었다 — 재직자가 고친 행(verified)은
--   조용히 덮지 않는다(선례 20260831 의 BADGE_SRC_CD = 'ai_parse' 가드와 같은 취지).
-- ══════════════════════════════════════════════════════════════════════

-- CJ ENM 커머스부문 — 그룹 정본 2천만원 대비 상향된 1억 한도(원금)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_com');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '주택자금 최대 1억원 대출 지원 — 한도는 부문별로 다름(그룹 정본 2천만원)',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan'
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- CJ CGV
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_cgv');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan'
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- CJ대한통운
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_logistics');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan'
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- CJ올리브영
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_oliveyoung');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan'
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- CJ제일제당
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_cheiljedang');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan'
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
