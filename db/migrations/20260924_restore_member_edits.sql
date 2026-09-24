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
--
-- 무엇을 바꾸나 (데이터 기반 — 행 번호를 박지 않는다):
--   편집 이력의 마지막 항목이 update 또는 create 이고, 지금 행이 재직자 행(verified)이 아닌 복지를
--   그 항목의 AFTER_VAL 로 되돌린다.
--     BENEFIT_NM · BENEFIT_AMT · QUAL_YN · NOTE_CTNT · AMT_SOURCE_CD = AFTER_VAL
--       JSON null 은 SQL NULL 로, JSON true 와 false 는 1 과 0 으로 바꾼다
--       (JSON_UNQUOTE 만 쓰면 JSON null 이 문자열 null 이 된다).
--     BENEFIT_CTGR_CD = AFTER_VAL — 등록(create) 이력이 있는 행만. 수정(update)은 카테고리를 쓰지 않는다.
--     BADGE_CD = verified · BADGE_SRC_CD = user_report
--     VERIFIED_DTM = 그 이력의 INS_DTM · EXPIRES_DTM = INS_DTM + 18개월 (편집 서비스와 같은 규칙)
--     MOD_ID = 그 이력의 ACTOR_MBR_ID · MOD_DTM = 그 이력의 INS_DTM (편집 직후 상태 그대로)
--   편집 서비스가 쓰지 않는 컬럼(QUAL_DESC_CTNT · SORT_ORDER_NO · BADGE_SRC_URL_CTNT)은 건드리지 않는다.
--   등록 이력도 MOD_ID · MOD_DTM 을 같은 방식으로 채운다 — 되살린 값을 마지막으로 쓴 사람과 시각이다.
--
-- 가드:
--   이력의 COMP_ID 와 AFTER_VAL 의 benefit_cd 가 지금 행과 같아야 한다 — 다시 매겨진 BENEFIT_ID 를
--     가리키는 이력(--fresh 뒤의 모양)이 엉뚱한 행을 덮지 않게.
--   BADGE_CD 가 verified 가 아닌 행만 — 되살린 행과 멀쩡한 재직자 행은 건드리지 않는다(멱등).
--   세션 시간대 UTC — 편집 서비스는 VERIFIED_DTM 을 UTC_TIMESTAMP 로 쓴다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB loupit_beta 에는 적용하지 않는다, 사용자 결정):
--   MYSQL_PWD 로 넘겨 비밀번호를 프로세스 인자에 남기지 않는다.
--   1) 백업
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER --single-transaction $DB_NAME TCOMPANY_BENEFIT TBENEFIT_EDIT_LOG > /root/loupit-pre-restore-member-edits-$(date +%Y%m%d%H%M%S).sql
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

UPDATE TCOMPANY_BENEFIT b
  JOIN (SELECT BENEFIT_ID,
               MAX(EDIT_LOG_ID)             AS LAST_LOG_ID,
               MAX(EDIT_TYPE_CD = 'create') AS HAS_CREATE
          FROM TBENEFIT_EDIT_LOG
         WHERE BENEFIT_ID IS NOT NULL
         GROUP BY BENEFIT_ID) h ON h.BENEFIT_ID = b.BENEFIT_ID
  JOIN TBENEFIT_EDIT_LOG l ON l.EDIT_LOG_ID = h.LAST_LOG_ID
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
       b.BADGE_CD        = 'verified',
       b.BADGE_SRC_CD    = 'user_report',
       b.VERIFIED_DTM    = l.INS_DTM,
       b.EXPIRES_DTM     = l.INS_DTM + INTERVAL 18 MONTH,
       b.MOD_ID          = l.ACTOR_MBR_ID,
       b.MOD_DTM         = l.INS_DTM
 WHERE l.EDIT_TYPE_CD IN ('update', 'create')
   AND b.BADGE_CD <> 'verified'
   AND b.COMP_ID = l.COMP_ID
   AND b.BENEFIT_CD = JSON_UNQUOTE(JSON_EXTRACT(l.AFTER_VAL, '$.benefit_cd'));
