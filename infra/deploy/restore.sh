#!/usr/bin/env bash
# infra/deploy/restore.sh — backup.sh 산출물(gz mysqldump)을 서빙 DB로 복원. 파괴적 작업이라
# 반드시 확인 가드를 통과해야 실행된다. 크레덴셜은 backup.sh와 동일 백업 env(infra/env/backup.env)를 읽는다.
#
# ── 실환경 주의(docs/OPS-backup.md 참고) ──
#   · 그랜트가 '@127.0.0.1' 한정 → --protocol=TCP 강제(소켓 접속은 Access denied).
#   · 서빙 스키마는 대문자 LOUPIT. DB_NAME 미주입 시 기본 LOUPIT.
#
# 사용:
#   infra/deploy/restore.sh <백업파일.sql.gz> [테이블 ...]
#   RESTORE_CONFIRM=1 infra/deploy/restore.sh <백업파일>        # 비대화형(프롬프트 생략)
# 예:
#   infra/deploy/restore.sh /var/backups/loupit/loupit-20260718.sql.gz                 # 전체 복원
#   infra/deploy/restore.sh /var/backups/loupit/loupit-20260718.sql.gz TCOMPARE_LOG    # 단일 테이블만
set -euo pipefail

usage() {
  echo "사용: $0 <백업파일.sql.gz> [테이블 ...]" >&2
  echo "  RESTORE_CONFIRM=1 을 주면 확인 프롬프트를 생략한다." >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
SRC="$1"; shift
TABLES=("$@")            # 비어 있으면 전체 복원

# backup.env(EnvironmentFile) 자동 로드 — restore.sh는 systemd가 아니라 수동 실행이므로 여기서 읽는다.
ENV_FILE="${BACKUP_ENV_FILE:-/home/ubuntu/loupit/infra/env/backup.env}"
if [ -f "${ENV_FILE}" ]; then
  set -a; . "${ENV_FILE}"; set +a
fi

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-APP_LOUPIT}"
DB_NAME="${DB_NAME:-LOUPIT}"
: "${DB_PASSWORD:?DB_PASSWORD 미설정 — infra/env/backup.env 생성 후 재실행(또는 export)}"

[ -f "${SRC}" ] || { echo "복원 실패: 백업 파일 없음 — ${SRC}" >&2; exit 1; }

# 무결성 검증: 손상된 gz로 서빙 DB를 덮어쓰지 않도록 사전 차단.
if ! gunzip -t "${SRC}" 2>/dev/null; then
  echo "복원 실패: gzip 무결성 검증 실패 — ${SRC}" >&2
  exit 1
fi

# ── 확인 가드 ──
echo "──────────────────────────────────────────────"
echo " 복원 대상 DB : ${DB_NAME} @ ${DB_HOST}:${DB_PORT} (사용자 ${DB_USER})"
echo " 백업 파일    : ${SRC}"
if [ "${#TABLES[@]}" -gt 0 ]; then
  echo " 범위         : 지정 테이블만 → ${TABLES[*]} (DROP+재생성)"
else
  echo " 범위         : 전체 DB — 덤프에 포함된 모든 테이블 DROP+재생성"
fi
echo "──────────────────────────────────────────────"
if [ "${RESTORE_CONFIRM:-}" != "1" ]; then
  read -r -p "위 DB를 덮어씁니다. 계속하려면 'yes' 입력: " ANS
  case "${ANS}" in
    y|Y|yes|YES) : ;;
    *) echo "취소됨(입력: '${ANS}')"; exit 1 ;;
  esac
fi

# 비밀을 프로세스 목록에 노출하지 않도록 임시 defaults 파일(mode 600)로 전달.
DEFAULTS_FILE="$(mktemp "${TMPDIR:-/tmp}/loupit-restore.XXXXXX.cnf")"
PART_SQL=""
chmod 600 "${DEFAULTS_FILE}"
cleanup() { rm -f "${DEFAULTS_FILE}"; [ -n "${PART_SQL}" ] && rm -f "${PART_SQL}"; }
trap cleanup EXIT
cat > "${DEFAULTS_FILE}" <<CNF
[client]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
protocol=TCP
CNF

if [ "${#TABLES[@]}" -eq 0 ]; then
  # 전체 복원: 덤프는 단일 DB(positional)라 CREATE DATABASE/USE 문이 없음 → 대상 DB를 명시해 주입.
  gunzip -c "${SRC}" | mysql --defaults-extra-file="${DEFAULTS_FILE}" "${DB_NAME}"
else
  # 부분 복원(best-effort): 덤프에서 지정 테이블 섹션(구조+데이터)만 추출.
  # 대상 테이블의 부모(FK 참조 대상, 예: TCOMPARE_LOG→TCOMPANY)는 이미 존재한다고 가정한다.
  # 부분 적용(2번째 테이블 결측 시 1번째만 반영)을 막기 위해 전 섹션을 임시 파일에 조립·검증 후 일괄 주입.
  extract_table() {
    # '-- Table structure for table `TBL`' 부터 다음 테이블 구조 주석 직전까지 출력.
    awk -v tbl="$1" '
      BEGIN { start = "-- Table structure for table `" tbl "`" }
      index($0, "-- Table structure for table `") == 1 {
        if ($0 == start) { grab = 1 } else if (grab) { grab = 0 }
      }
      grab { print }
    '
  }
  PART_SQL="$(mktemp "${TMPDIR:-/tmp}/loupit-restore.XXXXXX.sql")"
  chmod 600 "${PART_SQL}"
  {
    echo "SET FOREIGN_KEY_CHECKS=0;"
    echo "SET NAMES utf8mb4;"
  } > "${PART_SQL}"
  for tbl in "${TABLES[@]}"; do
    section="$(gunzip -c "${SRC}" | extract_table "${tbl}")"
    if [ -z "${section}" ]; then
      echo "복원 실패: 덤프에서 테이블 '${tbl}' 섹션을 찾지 못함(아무것도 반영하지 않음)" >&2
      exit 1
    fi
    printf '%s\n' "${section}" >> "${PART_SQL}"
  done
  echo "SET FOREIGN_KEY_CHECKS=1;" >> "${PART_SQL}"
  mysql --defaults-extra-file="${DEFAULTS_FILE}" "${DB_NAME}" < "${PART_SQL}"
fi

echo "restore done: ${SRC} → ${DB_NAME}"
echo
echo "다음 단계(캐시·커넥션 갱신) — API를 재시작해 stale 참조 캐시를 비운다:"
echo "  sudo systemctl restart loupit-api loupit-beta-api"
