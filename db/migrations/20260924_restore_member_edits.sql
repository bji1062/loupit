-- ══════════════════════════════════════════════════════════════════════
-- 재직자 편집 되살리기 — 웨이브 4 적재가 시드 값으로 되돌린 재직자 수정 — 운영 기준 2행
-- 결정: 2026-09-24 · 원인 수정: db/seed/load.py · db/seed/backfill_dec2.py (SP-SEED-12)
--
-- 무슨 일이 있었나:
--   2026-09-20 06:17:36 UTC 웨이브 4 멱등 적재(python3 db/seed/load.py)가 운영의 재직자 수정 2행을
--   시드 값으로 되돌렸다. 복지 SQL 의 ON DUPLICATE KEY UPDATE 가 BADGE_CD 까지 덮어 est 로 만들고,
--   백필이 그 행을 official 로 올린 뒤 출처(BADGE_SRC_CD)와 신선도(VERIFIED_DTM·EXPIRES_DTM)까지
--   시드 파일 헤더 것으로 바꿨다. MOD_ID 는 재직자로 남아, 편집 이력에서 파생하는 배지
--   「공식·재직자 수정」이 시드 값 위에 달렸다(허위 표시).
--     BENEFIT_ID 971  크래프톤 휴양시설 지원          편집 이력 1번 (2026-09-15 05:21:26 UTC)
--       재직자 값 = 금액 없음 · 비고 2회 · 금액출처 none · 정성 아님
--     BENEFIT_ID 1400 CJ ENM 커머스부문 통신비 지원   편집 이력 2번 (2026-09-18 05:31:19 UTC)
--       재직자 값 = 연 60만원 · 비고 1인당 월 5만원 · 금액출처 estimated · 정성 아님
--       (정성 행을 금액 행으로 바꾼 수정이라 시드 설명과 공식 출처 URL 은 비운다 — 아래 예외)
--
-- 무엇을 바꾸나 (데이터 기반 — 행 번호를 박지 않는다):
--   편집 이력의 마지막 항목이 update 또는 create 이고, 지금 행이 재직자 행(verified)이 아닌 복지를
--   그 항목의 AFTER_VAL 로 되돌린다.
--     BENEFIT_NM · BENEFIT_AMT · QUAL_YN · NOTE_CTNT · AMT_SOURCE_CD = AFTER_VAL
--       JSON null 은 SQL NULL 로, JSON true 와 false 는 1 과 0 으로 바꾼다
--       (JSON_UNQUOTE 만 쓰면 JSON null 이 문자열 null 이 된다).
--     BADGE_CD = verified · BADGE_SRC_CD = user_report
--     VERIFIED_DTM = 그 이력의 INS_DTM · EXPIRES_DTM = INS_DTM + 18개월 (편집 서비스와 같은 규칙)
--     MOD_ID = 그 이력의 ACTOR_MBR_ID · MOD_DTM = 그 이력의 INS_DTM
--   목표는 편집 직후 상태 그대로다. 그래서 행이 어떻게 생겼는지에 따라 나머지가 갈린다.
--     수정(update) 이력만 있는 행(시드에서 온 행): 편집 서비스의 수정이 쓰지 않는 컬럼
--       (BENEFIT_CTGR_CD · QUAL_DESC_CTNT · SORT_ORDER_NO · BADGE_SRC_URL_CTNT)은 건드리지 않는다.
--     등록(create) 이력이 있는 행(재직자가 만든 행): 등록이 쓴 그대로 — BENEFIT_CTGR_CD = AFTER_VAL,
--       QUAL_DESC_CTNT 와 BADGE_SRC_URL_CTNT 는 NULL, SORT_ORDER_NO 는 0. 시드 충돌이 채운 시드 설명과
--       공식 출처 URL 을 재직자가 등록한 행에 남기지 않는다(회사 페이지가 그 URL 을 출처 링크로 보인다).
--       마지막 이력이 등록이면 MOD_ID · MOD_DTM 도 NULL 이다(등록은 MOD 를 쓰지 않는다).
--   운영에는 수정 이력 2건뿐이라 등록 갈래는 쓰이지 않는다(테스트가 두 갈래를 다 본다).
--   예외 하나(사용자 결정 2026-09-25): 이력에 정성 행을 금액 행으로 바꾼 수정이 있고 마지막 상태가
--     금액 행이면 QUAL_DESC_CTNT 와 BADGE_SRC_URL_CTNT 도 NULL 로 비운다. 시드의 정성 설명
--     (예: 1400 의 금액은 CJ 공식 출처에서 확인되지 않아 미기재)과 공식 출처 URL 이 재직자가 넣은 금액
--     옆에 남아 서로 모순되게 보이지 않게 한다. 원래 설명은 시드 파일에 남아 있다. 전환 여부는 행이 아니라
--     편집 이력 전체로 판정한다 — 전환한 뒤 금액만 다시 고치면 마지막 이력만으로는 전환이 보이지 않는다.
--     다중 테이블 UPDATE 는 대입 순서를 보장하지 않으므로 같은 문장에서 바뀌는 b.QUAL_YN 을 조건으로 읽지 않는다.
--     운영에서는 1400 한 행이 여기에 든다.
--
-- 가드:
--   이력의 COMP_ID 와 AFTER_VAL 의 benefit_cd 가 지금 행과 같아야 한다 — 다시 매겨진 BENEFIT_ID 를
--     가리키는 이력(--fresh 뒤의 모양)이 엉뚱한 행을 덮지 않게.
--   BADGE_CD 가 verified 가 아닌 행만 — 되살린 행과 멀쩡한 재직자 행은 건드리지 않는다(멱등).
--   세션 시간대 UTC — 편집 서비스는 VERIFIED_DTM 을 UTC_TIMESTAMP 로 쓴다.
--   시드 적재(load.py)와 겹쳐도 된다 — 적재가 이력이 가리키는 행을 커밋 때까지 잠가 이 UPDATE 는
--     적재 커밋 뒤에 돈다(SP-SEED-12 ②). 적재가 먼저 돌던 판본은 되살린 행을 다시 덮을 수 있었다.
--   조인은 STRAIGHT_JOIN 으로 이력부터 읽는다 — TCOMPANY_BENEFIT 은 이력이 가리키는 행만 기본키로 연다.
--     복지 표를 먼저 훑으면 지나간 행마다 잠금을 쥔 채 적재가 쥔 행을 기다려, 적재가 그 행들을 업서트할 때
--     교착이 난다(실측 — 이 마이그레이션이 희생돼 롤백됐다). 이력이 가리키는 행은 적재가 이미 전부 잠갔으므로
--     이 UPDATE 는 첫 행에서 기다릴 뿐 적재가 필요한 잠금을 쥐지 않는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB loupit_beta 에는 적용하지 않는다, 사용자 결정):
--   MYSQL_PWD 로 넘겨 비밀번호를 프로세스 인자에 남기지 않는다.
--   1) 백업 (--no-tablespaces 필수 — 이 계정엔 전역 PROCESS 권한이 없다, infra/deploy/backup.sh 와 같은 옵션)
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER --no-tablespaces --single-transaction --default-character-set=utf8mb4 $DB_NAME TCOMPANY_BENEFIT TBENEFIT_EDIT_LOG > /root/loupit-pre-restore-member-edits-$(date +%Y%m%d%H%M%S).sql
--   2) 적용
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysql -vv -h $DB_HOST -P $DB_PORT -u $DB_USER $DB_NAME < db/migrations/20260924_restore_member_edits.sql
--   -vv 를 붙여야 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
-- 기대: Rows matched 2 · Changed 2 (BENEFIT_ID 971 · 1400). 두 번째 실행은 0.
--   다르면 멈추고 아래 확인 쿼리로 본다.
--
-- 확인 (읽기 전용 — 적용 전에는 두 행이 official, 적용 뒤에는 verified):
--   SELECT b.BENEFIT_ID, c.COMP_NM, b.BENEFIT_CD, b.BENEFIT_NM, b.BENEFIT_AMT, b.QUAL_YN, b.NOTE_CTNT,
--          b.BADGE_CD, b.AMT_SOURCE_CD, b.BADGE_SRC_CD, b.VERIFIED_DTM, b.EXPIRES_DTM, b.MOD_ID, b.MOD_DTM
--     FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
--    WHERE b.BENEFIT_ID IN (SELECT BENEFIT_ID FROM TBENEFIT_EDIT_LOG)
--
-- 뒤처리: 정적 회사 페이지(크래프톤 · CJ ENM 커머스부문)에 되살린 값이 나오려면 릴리스가 필요하다
--   (RELEASE_CONFIRM=1 bash infra/deploy/release.sh).
-- 시드: 고치지 않는다 — 재직자 값의 정본은 시드가 아니라 편집 이력이고, 이제 적재는 재직자 행을
--   건드리지 않는다(SP-SEED-12).
-- 테스트: server/tests/test_migration_restore_member_edits.py (사고를 실제 경로로 재현한 뒤 2회 적용).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET time_zone = '+00:00';

UPDATE (SELECT BENEFIT_ID,
               MAX(EDIT_LOG_ID)             AS LAST_LOG_ID,
               MAX(EDIT_TYPE_CD = 'create') AS HAS_CREATE,
               MAX(EDIT_TYPE_CD = 'update'
                   AND JSON_UNQUOTE(JSON_EXTRACT(BEFORE_VAL, '$.qual_yn')) = 'true'
                   AND JSON_UNQUOTE(JSON_EXTRACT(AFTER_VAL, '$.qual_yn')) = 'false') AS HAS_QUAL_TO_AMT
          FROM TBENEFIT_EDIT_LOG
         WHERE BENEFIT_ID IS NOT NULL
         GROUP BY BENEFIT_ID) h
  STRAIGHT_JOIN TBENEFIT_EDIT_LOG l ON l.EDIT_LOG_ID = h.LAST_LOG_ID
  STRAIGHT_JOIN TCOMPANY_BENEFIT b ON b.BENEFIT_ID = h.BENEFIT_ID
   SET b.BENEFIT_NM      = JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_nm')),
       b.BENEFIT_AMT     = CASE WHEN JSON_TYPE(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_amt')) = 'NULL' THEN NULL
                                ELSE CAST(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_amt') AS SIGNED) END,
       b.QUAL_YN         = CASE JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.qual_yn'))
                                WHEN 'true' THEN 1 WHEN 'false' THEN 0 END,
       b.NOTE_CTNT       = CASE WHEN JSON_TYPE(JSON_EXTRACT(l.AFTER_VAL, '$.note_ctnt')) = 'NULL' THEN NULL
                                ELSE JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.note_ctnt')) END,
       b.AMT_SOURCE_CD   = JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.amt_source')),
       b.BENEFIT_CTGR_CD = IF(h.HAS_CREATE = 1,
                              JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_ctgr_cd')),
                              b.BENEFIT_CTGR_CD),
       b.QUAL_DESC_CTNT  = IF(h.HAS_CREATE = 1
                              OR (h.HAS_QUAL_TO_AMT = 1
                                  AND JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.qual_yn')) = 'false'),
                              NULL, b.QUAL_DESC_CTNT),
       b.SORT_ORDER_NO   = IF(h.HAS_CREATE = 1, 0, b.SORT_ORDER_NO),
       b.BADGE_SRC_URL_CTNT = IF(h.HAS_CREATE = 1
                                 OR (h.HAS_QUAL_TO_AMT = 1
                                     AND JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.qual_yn')) = 'false'),
                                 NULL, b.BADGE_SRC_URL_CTNT),
       b.BADGE_CD        = 'verified',
       b.BADGE_SRC_CD    = 'user_report',
       b.VERIFIED_DTM    = l.INS_DTM,
       b.EXPIRES_DTM     = l.INS_DTM + INTERVAL 18 MONTH,
       b.MOD_ID          = IF(l.EDIT_TYPE_CD = 'create', NULL, l.ACTOR_MBR_ID),
       b.MOD_DTM         = IF(l.EDIT_TYPE_CD = 'create', NULL, l.INS_DTM)
 WHERE l.EDIT_TYPE_CD IN ('update', 'create')
   AND b.BADGE_CD <> 'verified'
   AND b.COMP_ID = l.COMP_ID
   AND b.BENEFIT_CD = JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_cd'));
