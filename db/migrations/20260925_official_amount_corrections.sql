-- ══════════════════════════════════════════════════════════════════════
-- 공식 출처 대조로 드러난 금액 오류 정정 — 초기 등록 4개사 8행 (삭제 1 · 수정 7)
-- 사용자 결정: 2026-09-25 (금액 오류 수정부터 진행) · 선례: db/migrations/20260918_meal_anchor_to_qual.sql
--
-- 배경:
--   근거 URL 없이 2026-04 초기에 등록된 81개사 가운데 9개사를 공식 출처와 대조했다(재수집 아님).
--   정본 = /home/ubuntu/loupit-evidence/2026-09-25-official-compare/out/<회사>.compare.md
--   화면에서 「회사 공식 수치」로 보이던 금액 가운데 공식 출처가 뒷받침하지 않거나 반대로 말하는 것,
--   그리고 금액을 만든 근거 문구가 공식 출처와 어긋나는 것만 고친다. 이 금액들은 이직 계산기의
--   실효 총보상에 그대로 더해진다.
--   범위 밖(이번에 손대지 않는다): 공식 근거가 없을 뿐인 추정 금액(구본 금액 점검은 보류 중),
--   meal 432 앵커(SI-9 규칙), 금액이 아닌 문안·코드 문제(재수집 몫).
--
-- 무엇을 바꾸나:
--   NAVER stock_grant 1,000 → 행 삭제. 2025 통합보고서 p.108: 2019년부터 3년간 1년 이상 재직 임직원에게
--     1,000만 원 상당 스톡옵션을 매년 부여 — 끝난 제도다. 금액만 걷으면 지금 있는 복지로 계속 집계된다.
--   NAVER holiday_gift 40 → 80 (회사 공식 수치). 채용 사이트: 설과 추석, 총 80만 원 상당의 네이버페이 포인트.
--   NAVER discount 100 → 금액 없음. 공식은 이용권 패키지 지원이라고만 쓰고 금액을 밝히지 않는다.
--   NAVER work_tools 360 → 금액 없음. 공식 360만 원은 입사 시 1회 예산이다(보고서 p.150) — 해마다 받는 돈이 아니다.
--   SK텔레콤 club 24 → 금액 없음. 동호회·소모임이 공식 출처(채용 사이트·SR2025·뉴스룸)에 없다.
--   SK텔레콤 telecom 290 → 금액 없음. 공식은 통신 서비스 이용료와 단말기 할부금 지원이라고만 쓴다.
--   롯데케미칼 welfare_point 130 → 금액 없음 · 이름 복지포인트. 2025·2022 보고서에 금액이 없고
--     엘포인트는 롯데 소비자 멤버십 이름이다(공식은 복지포인트).
--   카카오페이 long_service_leave 200 → 67 (추정치, 연 환산). 공식: 만 3년 근무마다 1개월 유급휴가와
--     휴가비 200만원 — 3년에 한 번 받는 돈이 연액 칸에 그대로 들어가 3배로 부풀어 있었다.
--   금액을 걷는 행은 BENEFIT_AMT NULL · QUAL_YN TRUE · AMT_SOURCE_CD none · NOTE_CTNT NULL 이고,
--   공식 출처의 사실만 QUAL_DESC_CTNT 로 남긴다(근거 없는 세부는 걷는다).
--
-- 가드: BADGE_CD = official — 재직자가 고친 행은 건드리지 않는다.
-- 멱등: 문마다 지금 금액을 WHERE 에 건다(삭제는 1000, 수정은 40·100·360·24·290·130·200) — 두 번째 실행은 0행.
-- 시드: 같은 8행을 db/seed/benefit/sql/NAVER.sql · SK텔레콤.sql · 롯데케미칼.sql · 카카오페이.sql 에서 고쳤다.
--   금액출처는 적재 때 NOTE_CTNT 로 다시 도출되므로(backfill_dec2) 시드 NOTE 가 같은 결과를 내게 맞췄다 —
--   holiday_gift 는 추정·환산 낱말이 없어 stated, long_service_leave 는 환산이 있어 estimated.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER --no-tablespaces --single-transaction --default-character-set=utf8mb4 $DB_NAME TCOMPANY_BENEFIT > /root/loupit-pre-amount-corrections-$(date +%Y%m%d%H%M%S).sql
--   2) 적용
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysql -vv -h $DB_HOST -P $DB_PORT -u $DB_USER $DB_NAME < db/migrations/20260925_official_amount_corrections.sql
--   -vv 를 붙여야 문마다 영향 행 수가 찍힌다.
-- 기대: 삭제 1 row affected · 수정 7문 각각 Rows matched 1 Changed 1. 두 번째 실행은 전부 0.
--   다르면 멈추고 확인하라 — 회사명 오타면 @c 가 NULL 이라 오류 없이 0행이다.
-- 뒤처리: 정적 회사 페이지·항목 페이지에 반영하려면 릴리스(RELEASE_CONFIRM=1 bash infra/deploy/release.sh).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- NAVER
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
-- 전 직원 주식 부여 — 2019~2021 한정 스톡옵션, 끝난 제도
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BENEFIT_CD = 'stock_grant' AND BENEFIT_AMT = 1000
   AND BADGE_CD = 'official';
-- 명절 네이버페이 — 공식 80만 원
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = 80,
       AMT_SOURCE_CD  = 'stated',
       NOTE_CTNT      = '설·추석 총 80만원 상당 네이버페이 포인트'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'holiday_gift' AND BENEFIT_AMT = 40
   AND BADGE_CD = 'official';
-- 네이버 서비스 이용권 — 공식 금액 없음
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       NOTE_CTNT      = NULL,
       QUAL_DESC_CTNT = '네이버페이·플러스멤버십·웹툰·VIBE·MYBOX 등 네이버 서비스 이용권 패키지 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'discount' AND BENEFIT_AMT = 100
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 업무 장비 예산 — 공식 360만 원은 입사 시 1회 예산
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       NOTE_CTNT      = NULL,
       QUAL_DESC_CTNT = '입사 시 최대 360만원 장비 예산, 이후 매월 추가 예산 지원(직군별로 다름)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'work_tools' AND BENEFIT_AMT = 360
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- SK텔레콤
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skt');
-- 소모임 지원 — 공식 출처에 없음(금액만 걷는다, 행 존재는 재수집 몫)
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       NOTE_CTNT      = NULL,
       QUAL_DESC_CTNT = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'club' AND BENEFIT_AMT = 24
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';
-- 통신비 지원 — 공식 금액 없음
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       NOTE_CTNT      = NULL,
       QUAL_DESC_CTNT = '매달 구성원 명의 1회선의 통신 서비스 이용료와 단말기 할부금 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'telecom' AND BENEFIT_AMT = 290
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- 롯데케미칼
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem');
-- 복지포인트 — 공식 금액 없음, 엘포인트는 공식 명칭이 아니다
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '복지포인트',
       BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       NOTE_CTNT      = NULL,
       QUAL_DESC_CTNT = '복지포인트 지원, 임직원 롯데그룹 제휴카드(W카드)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'welfare_point' AND BENEFIT_AMT = 130
   AND QUAL_YN = FALSE AND BADGE_CD = 'official';

-- 카카오페이
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay');
-- 안식 휴가 — 3년에 한 번 휴가비 200만원을 연 환산
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = 67,
       AMT_SOURCE_CD  = 'estimated',
       NOTE_CTNT      = '만 3년 근무마다 1개월 유급휴가와 휴가비 200만원 — 휴가비 연 환산'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave' AND BENEFIT_AMT = 200
   AND BADGE_CD = 'official';
