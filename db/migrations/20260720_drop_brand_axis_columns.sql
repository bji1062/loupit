-- ══════════════════════════════════════════════════════════════════════
-- 브랜드 축(성장성·안정성) 제거 — TCOMPANY_TYPE 3컬럼 드랍
-- 근거: docs/ANALYSIS-성장성-용어-2026-07-20.md 시나리오 (c) · HANDOFF §K
-- 선행 조건(반드시 이 순서):
--   1) 코드에서 컬럼 소비 제거 완료 (커밋 bb45d8d — calc.js/ui.js/report.js/app.js,
--      server/services/reference.py _SQL_TYPES, server/models/reference.py CompanyType)
--   2) db/seed/company_types.sql 갱신 완료 (INSERT 컬럼 목록에서 3종 제거)
--      ← 안 하면 다음 release.sh의 [3/7] seed 단계가 Unknown column 으로 실패한다
--   3) db/schema.sql 갱신 완료 (신규 프로비저닝 시 애초에 생성 안 됨)
--
-- ⚠️ 되돌릴 수 없다. 적용 전 백업 필수:
--      sudo systemctl start loupit-backup.service
--      sudo zcat /var/backups/loupit/loupit-YYYYMMDD.sql.gz | tail -1  # Dump completed 확인
--    복원이 필요하면 TCOMPANY_TYPE 전체를 백업본에서 되살려야 한다(컬럼만 복원 불가).
--
-- 멱등: information_schema 확인 후 존재할 때만 DROP — 재실행 안전.
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

-- MySQL은 DROP COLUMN IF EXISTS를 지원하지 않으므로 동적 SQL로 멱등성을 만든다.
SET @db := DATABASE();

SET @sql := (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE TCOMPANY_TYPE DROP COLUMN GROWTH_RATE_VAL',
    'SELECT "skip: GROWTH_RATE_VAL 이미 없음"')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'TCOMPANY_TYPE' AND COLUMN_NAME = 'GROWTH_RATE_VAL');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE TCOMPANY_TYPE DROP COLUMN GROWTH_LABEL_NM',
    'SELECT "skip: GROWTH_LABEL_NM 이미 없음"')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'TCOMPANY_TYPE' AND COLUMN_NAME = 'GROWTH_LABEL_NM');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE TCOMPANY_TYPE DROP COLUMN STABILITY_SCORE_NO',
    'SELECT "skip: STABILITY_SCORE_NO 이미 없음"')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'TCOMPANY_TYPE' AND COLUMN_NAME = 'STABILITY_SCORE_NO');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
