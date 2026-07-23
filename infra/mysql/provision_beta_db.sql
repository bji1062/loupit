-- infra/mysql/provision_beta_db.sql — 베타 스테이징 전용 격리 스키마 `loupit_beta` 프로비저닝 (관리자 1회 실행).
--
-- 배경: beta.loupit.co 스테이징 인스턴스(loupit-beta-api.service, :8001)가
--   M9(SC14) 로그인·참여 기능을 실사용 없이 시험할 수 있도록, **프로덕션 스키마 `LOUPIT` 이 아닌
--   격리 DB `loupit_beta`** 를 둔다. `.env.beta` 의 DB_NAME 을 이 스키마로 가리켜(구 LOUPIT 지뢰 제거)
--   로그인/세션/재직/복지편집 쓰기가 프로덕션 데이터에 절대 닿지 않게 한다.
--
-- 효과: `loupit_beta` 는 서빙(SERVING_SCHEMAS={LOUPIT,loupit}) 이 아니라 뮤테이션 위험 0.
--   loupit_test(테스트 스위트가 DROP/CREATE) 와도 분리돼 테스트와 베타가 서로 간섭하지 않는다.
--
-- 실행(관리자 root 필요 — APP_LOUPIT 은 전역 CREATE 권한 없음):
--   sudo /data/mysql/bin/mysql -u root -p < infra/mysql/provision_beta_db.sql
--
-- 이후(자동화 측 수행): 스키마·시드 적재 → `.env.beta` DB_NAME=loupit_beta 로 변경 → 서비스 재시작.
--   시드 적재: DB_NAME=loupit_beta LOUPIT_ALLOW_FRESH=1 python3 db/seed/load.py --fresh --yes

CREATE DATABASE IF NOT EXISTS loupit_beta
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- 런타임 앱 계정(APP_LOUPIT)에 베타 스키마 전권만 추가 부여(서빙 LOUPIT 권한은 불변).
-- .env.beta 는 DB_HOST=127.0.0.1 로 접속하므로 호스트는 '127.0.0.1'(provision_test_db.sql 과 동일).
-- lower_case_table_names=0 이라 'loupit_beta' 는 서빙 'LOUPIT' 과 완전 별개 스키마다.
GRANT ALL PRIVILEGES ON loupit_beta.* TO 'APP_LOUPIT'@'127.0.0.1';
FLUSH PRIVILEGES;

-- 검증(실행 후 수동 확인):
--   SHOW DATABASES LIKE 'loupit_beta';
--   SHOW GRANTS FOR 'APP_LOUPIT'@'127.0.0.1';   -- LOUPIT.* + loupit_test.* + loupit_beta.* 세 줄
