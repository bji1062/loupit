#!/usr/bin/env bash
# infra/deploy/backup.sh — SP-INFRA-10.2 mysqldump 백업(기본 14일 보관). 참조 5테이블은 시드에서
# 재현 가능하나 TCOMPARE_LOG(익명 비교 로그 — 트렌딩 원천)는 시드 재현 불가 → 백업이 유일한 복구 수단.
# loupit-backup.timer(systemd, 일 1회 03:00)가 스케줄한다. 크레덴셜은 EnvironmentFile로 주입
# (infra/env/backup.env — 미커밋, server/.env엔 미상주. SP-INFRA-6.2·7.2, CFG-6 정합).
#
# ── 실환경 주의(감사 2026-07-17, docs/OPS-backup.md 참고) ──
#   · 서빙 스키마는 대문자 LOUPIT(lower_case_table_names=0) — 소문자 loupit는 별개 DB라 DB_NAME 기본은 LOUPIT.
#   · mysqldump 8.0.42는 --no-tablespaces 없으면 PROCESS(전역권한) 필요 — DB 계정엔 없어 항상 실패 → --no-tablespaces 필수.
#   · 그랜트가 '@127.0.0.1' 한정이라 소켓 접속은 Access denied → --protocol=TCP 강제 필수.
set -euo pipefail

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-APP_LOUPIT}"     # 실환경 정합 기본값(ALL ON LOUPIT.*). 실값은 backup.env로 주입.
DB_NAME="${DB_NAME:-LOUPIT}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/loupit}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
: "${DB_PASSWORD:?DB_PASSWORD 미설정 — infra/env/backup.env(EnvironmentFile)로 주입}"

TS="$(date +%Y%m%d)"
OUT="${BACKUP_DIR}/loupit-${TS}.sql.gz"
TMP="${OUT}.partial.$$"              # 원자성: 완성·검증 통과 후에만 최종 이름으로 mv
DEFAULTS_FILE=""

cleanup() {
  # 부분 산출물·비밀 파일 정리(성공/실패 무관). mv 성공 시 TMP는 이미 없으므로 rm -f는 무해.
  [ -n "${DEFAULTS_FILE}" ] && rm -f "${DEFAULTS_FILE}"
  rm -f "${TMP}"
}
trap cleanup EXIT

mkdir -p "${BACKUP_DIR}"

# 비밀을 프로세스 목록(ps)·CLI 경고에 노출하지 않도록 임시 defaults 파일(mode 600)로 전달.
# --defaults-extra-file 은 mysqldump 의 첫 인자여야 한다.
DEFAULTS_FILE="$(mktemp "${TMPDIR:-/tmp}/loupit-backup.XXXXXX.cnf")"
chmod 600 "${DEFAULTS_FILE}"
cat > "${DEFAULTS_FILE}" <<CNF
[mysqldump]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
protocol=TCP
CNF

# mysqldump 경로 해석: systemd 최소 PATH엔 tarball 설치(/data/mysql/bin)가 없다(첫 설치 검증에서 실발현).
# PATH 탐색 → tarball 경로 폴백, 둘 다 없으면 명확히 실패.
MYSQLDUMP="${MYSQLDUMP:-$(command -v mysqldump || true)}"
[ -n "${MYSQLDUMP}" ] || MYSQLDUMP=/data/mysql/bin/mysqldump
[ -x "${MYSQLDUMP}" ] || { echo "backup FAILED: mysqldump 없음(PATH·/data/mysql/bin 모두) — MYSQLDUMP env로 지정" >&2; exit 1; }

# 덤프 → 임시 파일. --no-tablespaces(PROCESS 권한 회피)·--single-transaction(InnoDB 일관 스냅숏, 락 없음).
# 파이프 실패(mysqldump 비0)는 pipefail+set -e로 즉시 중단되고 trap이 TMP를 정리한다.
"${MYSQLDUMP}" --defaults-extra-file="${DEFAULTS_FILE}" \
  --no-tablespaces --single-transaction --default-character-set=utf8mb4 \
  "${DB_NAME}" | gzip -9 > "${TMP}"

# 무결성 검증 1: gzip 스트림이 온전한가.
if ! gunzip -t "${TMP}" 2>/dev/null; then
  echo "backup FAILED: gzip 무결성 검증 실패 — ${TMP} 폐기" >&2
  exit 1
fi
# 무결성 검증 2: mysqldump 정상 종료 트레일러('-- Dump completed …')가 있는가(부분 덤프 차단).
TRAILER="$(gunzip -c "${TMP}" | tail -c 4096)"
if ! grep -q 'Dump completed' <<< "${TRAILER}"; then
  echo "backup FAILED: 'Dump completed' 트레일러 없음(부분 덤프 의심) — ${TMP} 폐기" >&2
  exit 1
fi

# 검증 통과 → 원자적으로 최종 이름 확정.
mv -f "${TMP}" "${OUT}"

# 보관 로테이션: 정상 파일(loupit-*.sql.gz)만 대상. .partial.* 은 매칭되지 않는다.
find "${BACKUP_DIR}" -maxdepth 1 -name 'loupit-*.sql.gz' -mtime "+${RETENTION_DAYS}" -delete
# SIGKILL 등으로 trap을 못 탄 옛 부분 파일도 하루 지나면 청소.
find "${BACKUP_DIR}" -maxdepth 1 -name 'loupit-*.sql.gz.partial.*' -mtime +1 -delete

echo "backup done: ${OUT} ($(du -h "${OUT}" | cut -f1))"
