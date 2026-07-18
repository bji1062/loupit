-- infra/mysql/provision_accounts.sql — SP-INFRA-6.2 DB·계정 프로비저닝(최소권한 SELECT/DDL 분리).
-- 배포 호스트에서 1회 root/관리 계정으로 실행. 비밀번호는 실행 시 치환(본 파일에 실값 없음, CFG-6 정합).
--
-- 스키마명은 LOUPIT(대문자) — 실서빙 스키마다(schema.sql:3, server/.env DB_NAME=LOUPIT).
-- 이 호스트는 lower_case_table_names=0이라 'loupit'과 'LOUPIT'은 별개 스키마다. 소문자로
-- 프로비저닝하면 서버가 접속하는 스키마와 어긋나 전 쿼리가 빈/없는 DB를 향하므로, 반드시
-- 대문자 LOUPIT로 생성·그랜트한다(2026-07-17 감사 #6·#13 — 이전 소문자 표기 전면 정정).
--
-- ⚠ 실환경 드리프트(감사 #6·#13, 정직 기록): 현 라이브는 이 파일의 2계정 분리가 아니라
--   단일 계정 APP_LOUPIT(GRANT ALL ON LOUPIT.*)이 런타임·DDL·시드를 모두 수행한다. 즉
--   server/.env가 쥔 런타임 자격이 서빙 스키마 DROP/ALTER 권한까지 보유하는 상태로,
--   커밋된 최소권한 설계가 실환경에서 미이행이다(#13).
--   · 이 파일로 (재)프로비저닝하려면 server/.env의 DB_USER/DB_PASSWORD를 아래 런타임 계정
--     ('loupit')으로 교체해야 한다(교체 없이 재프로비저닝만 하면 라이브가 여전히 APP_LOUPIT).
--   · 그런데 현 릴리스·테스트 파이프라인(release.sh 1~2단계·conftest DROP/CREATE·load.py
--     --fresh)이 server/.env의 동일 계정으로 DDL을 수행하도록 짜여 있어(#13), 런타임을
--     SELECT+로그쓰기로 좁히는 순간 그 파이프라인이 권한 오류로 깨진다. 따라서 계정 분리는
--     빌드타임 도구가 loupit_seed 자격을 쓰도록 파이프라인을 개편하는 후속 과제이며, 이 파일
--     단독 적용만으로 완결되지 않는다 — 본 파일은 도달해야 할 목표(최소권한) 상태를 정의한다.
CREATE DATABASE IF NOT EXISTS LOUPIT
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- 런타임(앱): 읽기 + 익명 비교 로그 쓰기/보존만(defense-in-depth, NFR20). server/.env 에는
-- 이 계정 자격만 넣는다. 전 테이블 SELECT + TCOMPARE_LOG 한정 INSERT·DELETE만 부여한다:
--   INSERT — POST /comparisons/log (database.insert_compare_log, INV-1 개정 2026-07-14).
--   DELETE — 보존 퍼지 (database.purge_compare_log, #7b — 보존기간 초과 익명 로그 배치 삭제).
-- 그 외 테이블·DML 권한은 주지 않는다(서빙 스키마 DROP/ALTER 불가 = 침해 시 읽기+로그쓰기로 한정).
CREATE USER IF NOT EXISTS 'loupit'@'127.0.0.1' IDENTIFIED BY '<RUNTIME_PW>';
GRANT SELECT ON LOUPIT.* TO 'loupit'@'127.0.0.1';
GRANT INSERT, DELETE ON LOUPIT.TCOMPARE_LOG TO 'loupit'@'127.0.0.1';

-- 시드/DDL(빌드타임 전용, .env와 분리 보관): DDL+DML — release.sh 1~2단계·backup.sh가 사용.
CREATE USER IF NOT EXISTS 'loupit_seed'@'127.0.0.1' IDENTIFIED BY '<SEED_PW>';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX, REFERENCES
  ON LOUPIT.* TO 'loupit_seed'@'127.0.0.1';

FLUSH PRIVILEGES;

-- 검증: SHOW GRANTS FOR 'loupit'@'127.0.0.1';  → 정확히 두 줄이어야 함(NFR20·#6):
--   GRANT SELECT ON `LOUPIT`.* TO ...
--   GRANT INSERT, DELETE ON `LOUPIT`.`TCOMPARE_LOG` TO ...
--   (SELECT 전면 + TCOMPARE_LOG 한정 쓰기 2종 외 권한이 보이면 최소권한 위반.)
-- 인증 플러그인이 caching_sha2_password면 aiomysql에 cryptography 필요(SP-ARCH-7 조건부, DG-4 확정).
