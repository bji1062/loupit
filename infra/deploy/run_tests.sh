#!/usr/bin/env bash
# infra/deploy/run_tests.sh — 전 계층 테스트 집계. 실패 시 배포 차단.
# 근거: SP-TEST-4.2, TASK/12 T-12.1.1(MT-1). 릴리스 게이트(SP-ARCH-9 4단계)와 개발 사전검증이 동일 스크립트 호출.
#
# ── 2026-08-26 격리 전환: 게이트는 이제 **서빙 스키마(LOUPIT)를 절대 만지지 않는다** ──
# 구 판본(~2026-08-26)은 서빙 스키마를 테스트에 재사용해, 매 실행마다
#   TCOMPARE_LOG·참여 10테이블 mysqldump 백업 → DROP/CREATE → 재시드 → 재주입
# 의 곡예를 추었고 약 10초의 백엔드 다운타임 창과 실데이터 소실 전례(함정 ㉖ 계열,
# TCOMPANY_EMAIL_DOMAIN 이중 복원 사고 2026-07-29)를 남겼다.
#
# 이제 백엔드 테스트는 격리 스키마 `loupit_test` 만 쓴다(원 설계 SPEC/03·04·TASK/12 복귀):
#   - `infra/mysql/provision_test_db.sql` 로 프로비저닝돼 있다(관리자 1회 실행 완료, 2026-07-22).
#   - conftest 의 schema_db/seeded_db 픽스처가 DROP/CREATE·시드를 자체 수행한다 —
#     서빙이 아니므로 백업·재주입·복원 trap 이 **전부 불필요**하다.
#   - 주간 복원 훈련(restore-drill)도 같은 loupit_test 를 쓰지만, conftest 의
#     flock(/run/loupit/testdb.lock)이 둘을 상호 배제한다(2026-07-30 장치 그대로).
#   - 서빙 무접촉 계약은 server/tests/test_runner_backup.py 가 스크립트 텍스트로 강제한다.
# CI(.github/workflows/ci.yml)는 같은 커맨드를 loupit_ci 스키마로 돌린다 — 이 스크립트는
# 배포 호스트의 릴리스 게이트 겸 로컬 일괄 실행용이다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$ROOT"

# python 바이너리 해석: venv 우선 → python3 → python (Ubuntu 22.04 기본은 `python3`만 존재,
# SP-INFRA-2.2 패키지 목록에 python-is-python3 없음 — `python` 단독 가정 시 배포 호스트에서 실패).
if [ -x "$ROOT/server/venv/bin/python" ]; then PY="$ROOT/server/venv/bin/python"
elif command -v python3 >/dev/null; then PY="python3"
else PY="python"; fi

# 격리 대상 고정. 이미 export 된 DB_NAME(예: CI 의 loupit_ci)은 존중한다 — 단 서빙 이름이면
# conftest 의 C-1 가드가 LOUPIT_ALLOW_SERVING_SCHEMA 부재로 차단한다(이 스크립트는 이제
# 그 신호를 보내지 않는다: 복원 책임을 지는 래퍼가 아니게 됐기 때문이다).
export DB_NAME="${DB_NAME:-loupit_test}"
# seeded_db 픽스처의 load.main(fresh=True) 파괴 가드(#14) 통과 — 대상은 위 격리 스키마뿐이다.
export LOUPIT_ALLOW_FRESH=1

echo "[1/5] 백엔드(API·스키마·시드) — pytest (DB_NAME=$DB_NAME, 서빙 무접촉; SC14 RED 제외)"
# ③ RED 스테이징: 미구현 SC14 스펙(@pytest.mark.sc14)은 `-m "not sc14"` 로 제외해 베이스 배포
# 게이트를 그린으로 유지한다(M9 구현 후 마커 해제 또는 `-m sc14` 로 별도 실행). 마커 등록:
# server/tests/conftest.py pytest_configure. 가드: server/tests/test_runner_backup.py.
"$PY" -m pytest server/tests/ -q -m "not sc14"

echo "[2/5] 정적 생성물·정책 — pytest (fake 번들)"
"$PY" -m pytest generator/tests/ -q

# 프론트 통합 테스트(ui.test.js)는 jsdom(dev 의존)이 필요하다 — 없으면 설치 시도(무빌드 원칙은
# 프로덕션 서빙에만 적용; 테스트는 dev 의존 허용). node_modules 는 gitignore.
if [ -f "$ROOT/package.json" ] && [ ! -d "$ROOT/node_modules/jsdom" ]; then
  echo "  [deps] jsdom 미설치 — 설치 시도(npm→bun)"
  ( cd "$ROOT" && { npm install --no-audit --no-fund --silent 2>/dev/null || bun install 2>/dev/null; } ) \
    || echo "  ⚠ 의존성 설치 실패 — ui.test.js 가 실패할 수 있다(npm/bun 필요)"
fi

echo "[3/5] 프론트 순수모듈·계산엔진·광고·디자인토큰·메타·DOM통합 — node:test"
# node ≥21 glob(디렉토리 인자 대신) — node v24는 `node --test web/`를 모듈 로드로 오해. node ≥22 권장.
node --test 'web/**/*.test.js'

echo "[4/5] 테스트 하네스 자체 검증(메타) — 이미 [3]에 포함(web/test/harness.test.js)"

echo "[5/5] Nginx 설정 문법(배포 호스트에서만)"
# loupit.conf는 sites-available 드롭인(server{} 블록만)이라 -c로 단독 로드 불가 —
# events{}/http{}만 감싸는 로컬 검증 전용 래퍼(loupit.test.conf)로 문법을 검사한다(CFG-1).
if command -v nginx >/dev/null; then nginx -t -c "$ROOT/infra/nginx/loupit.test.conf"; else echo "  nginx 미설치 — 스킵(개발 로컬)"; fi

echo "ALL GREEN — 릴리스 게이트 통과"
