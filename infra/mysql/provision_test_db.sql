-- infra/mysql/provision_test_db.sql — 격리 테스트 스키마 `loupit_test` 프로비저닝 (관리자 1회 실행).
--
-- 배경: 원 설계(SPEC/03·04, TASK/02·03·12)는 격리 테스트 DB `loupit_test`(CI docker mysql:8.0)를
--   전제했으나, 배포 호스트에서 앱 계정(APP_LOUPIT)이 CREATE DATABASE 전역권한이 없어 서빙 스키마
--   `LOUPIT` 을 테스트에 재사용하고 run_tests.sh 백업/복원(C-1)으로 방어해 왔다. M9(SC14) 참여
--   기능은 실 회원·세션 데이터를 다루므로, 서빙 스키마 뮤테이션(2026-07-20 docroot 사고 계열) 대신
--   **본래 의도했던 격리 테스트 DB 로 되돌린다**.
--
-- 효과: `loupit_test` 는 서빙(SERVING_SCHEMAS={LOUPIT,loupit}) 이 아니므로 schema_guard 의 C-1 가드가
--   복원 래퍼 없이도 허용한다. 테스트가 DROP/CREATE 를 자유로이 해도 서빙 데이터·docroot 에 무영향
--   → run_tests.sh 백업/복원 불요, 뮤테이션 위험 0.
--
-- 실행(관리자 root 필요 — APP_LOUPIT 은 전역 CREATE 권한 없음):
--   sudo /data/mysql/bin/mysql -u root -p < infra/mysql/provision_test_db.sql
--
-- 실행 후 테스트: DB_NAME=loupit_test python3 -m pytest server/tests/ -q
--   (server/.env 의 APP_LOUPIT 자격을 그대로 쓰되 DB_NAME 만 loupit_test 로 덮어쓴다 —
--    load_dotenv override=False 라 export 한 DB_NAME 이 우선.)

CREATE DATABASE IF NOT EXISTS loupit_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- 런타임 앱 계정에 테스트 스키마 전권만 추가 부여(서빙 LOUPIT 권한은 불변).
-- lower_case_table_names=0 이라 'loupit_test' 는 서빙 'LOUPIT' 과 별개 스키마다.
GRANT ALL PRIVILEGES ON loupit_test.* TO 'APP_LOUPIT'@'127.0.0.1';
FLUSH PRIVILEGES;

-- 검증(실행 후 수동 확인):
--   SHOW DATABASES LIKE 'loupit_test';
--   SHOW GRANTS FOR 'APP_LOUPIT'@'127.0.0.1';   -- LOUPIT.* + loupit_test.* 두 줄
