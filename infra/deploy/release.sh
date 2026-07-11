#!/usr/bin/env bash
# infra/deploy/release.sh — SP-INFRA-9 릴리스 파이프라인(7단계, SP-ARCH-9 정본 순서).
# 순서: schema → seed → generator → 검증(테스트 게이트) → API 재시작 → nginx reload → 스모크.
# 실행: 리포 루트에서 `bash infra/deploy/release.sh` (또는 어디서든, 스크립트가 ROOT_DIR로 cd).
# 근거: docs/SPEC/11-인프라-배포.md SP-INFRA-9.1·9.2, docs/TASK/00 §6.2, SP-ARCH-9.
#
# early-exit 계약(SP-TEST MT-3가 검증): [4/7] 테스트 게이트가 non-zero로 실패하면
# `set -euo pipefail`에 의해 스크립트가 그 즉시 중단되며, [5/7]~[7/7](재시작·reload·스모크)은
# 실행되지 않는다 — 실패한 산출물이 서비스에 반영되지 않는다(무중단 지향, 이전 산출물 유지).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

PY="${ROOT_DIR}/server/venv/bin/python"
[ -x "${PY}" ] || PY="python3"   # venv 미프로비저닝 개발 환경 폴백

# server/.env(있으면) 로드 — DB_HOST/PORT/USER/PASSWORD/NAME (SP-INFRA-7.1)
if [ -f "${ROOT_DIR}/server/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/server/.env"
  set +a
fi

echo "[1/7] schema (SP-DB) — mysql < db/schema.sql (idempotent CREATE TABLE IF NOT EXISTS)"
mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER:?DB_USER 미설정 — server/.env 확인}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} "${DB_NAME:-loupit}" < "${ROOT_DIR}/db/schema.sql"

echo "[2/7] seed+backfill (SP-SEED-9) — db/seed/load.py (기업유형→프리셋→~95 복지 SQL→메타→DEC-2 백필)"
"${PY}" "${ROOT_DIR}/db/seed/load.py"

echo "[3/7] static generate (SP-GEN-1.4/11) — generator.build → web/dist (원자적 스왑)"
"${PY}" -m generator.build --out web/dist

echo "[4/7] test gate (SP-TEST-4 집계 — G1~G3) — 실패 시 즉시 중단(5~7 미실행)"
bash "${SCRIPT_DIR}/run_tests.sh"

echo "[5/7] restart API (SP-INFRA-5)"
sudo systemctl restart loupit-api

echo "[6/7] reload nginx (SP-INFRA-3)"
sudo nginx -t && sudo systemctl reload nginx

echo "[7/7] smoke (SP-INFRA-11)"
bash "${SCRIPT_DIR}/smoke.sh"

echo "RELEASE OK"
