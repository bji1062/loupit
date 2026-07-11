#!/usr/bin/env bash
# infra/deploy/backup.sh — SP-INFRA-10.2 mysqldump 백업(14일 보관). 참조 DB는 시드에서 재현
# 가능하므로 백업은 보조 안전장치. loupit-backup.timer(systemd, 일 1회) 또는 cron으로 스케줄.
# SEED_PW는 오퍼레이터 환경변수(server/.env엔 미상주 — SP-INFRA-6.2·7.2, CFG-6 정합).
set -euo pipefail
TS="$(date +%Y%m%d)"
OUT="/var/backups/loupit/loupit-${TS}.sql.gz"
mkdir -p /var/backups/loupit
mysqldump --single-transaction --default-character-set=utf8mb4 \
  -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" \
  -u "${SEED_DB_USER:-loupit_seed}" -p"${SEED_PW:?SEED_PW 미설정 — 오퍼레이터 환경변수로 주입}" \
  "${DB_NAME:-loupit}" | gzip -9 > "${OUT}"
# 14일 보관
find /var/backups/loupit -name 'loupit-*.sql.gz' -mtime +14 -delete
echo "backup done: ${OUT}"
