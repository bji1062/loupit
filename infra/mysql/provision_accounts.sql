-- infra/mysql/provision_accounts.sql — SP-INFRA-6.2 DB·계정 프로비저닝(최소권한 SELECT/DDL 분리).
-- 배포 호스트에서 1회 root/관리 계정으로 실행. 비밀번호는 실행 시 치환(본 파일에 실값 없음, CFG-6 정합).
CREATE DATABASE IF NOT EXISTS loupit
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- 런타임(앱): 읽기 전용 — defense-in-depth(NFR20). server/.env 에는 이 계정 자격만 넣는다.
CREATE USER IF NOT EXISTS 'loupit'@'127.0.0.1' IDENTIFIED BY '<RUNTIME_PW>';
GRANT SELECT ON loupit.* TO 'loupit'@'127.0.0.1';

-- 시드/DDL(빌드타임 전용, .env와 분리 보관): DDL+DML — release.sh 1~2단계·backup.sh가 사용.
CREATE USER IF NOT EXISTS 'loupit_seed'@'127.0.0.1' IDENTIFIED BY '<SEED_PW>';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX, REFERENCES
  ON loupit.* TO 'loupit_seed'@'127.0.0.1';

FLUSH PRIVILEGES;

-- 검증: SHOW GRANTS FOR 'loupit'@'127.0.0.1';  → SELECT만 나와야 함(NFR20).
-- 인증 플러그인이 caching_sha2_password면 aiomysql에 cryptography 필요(SP-ARCH-7 조건부, DG-4 확정).
