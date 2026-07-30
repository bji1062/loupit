#!/usr/bin/env bash
# infra/deploy/restore-drill.sh — 최신 백업이 **정말 복원되는지** 주기적으로 증명한다.
#
# ── 왜 필요한가 ────────────────────────────────────────────────────────────
# `backup.sh` 는 gzip 무결성과 `Dump completed` 트레일러까지 본다. 그건 "파일이 온전한가"
# 이지 "**이 파일로 서비스를 되살릴 수 있는가**"가 아니다. 그 둘 사이에는 스키마 변경,
# 권한, 문자셋, FK 순서, 덤프 옵션 같은 것들이 조용히 끼어든다. 복원해 본 적 없는 백업은
# 백업이 아니라 백업이라는 믿음이다.
#
# ── 대상 DB: 왜 loupit_test 인가 ───────────────────────────────────────────
# 이 호스트의 DB 계정(APP_LOUPIT)은 `LOUPIT`·`loupit_beta`·`loupit_test` 세 곳에만 권한이
# 있고 **CREATE DATABASE 권한이 없다**(2026-07-30 실측). `LOUPIT` 은 서빙, `loupit_beta` 는
# 라이브 베타라 둘 다 금지 → 남는 것은 `loupit_test` 하나다.
#   ⚠ 그래서 훈련 중 **프로덕션 데이터가 잠시 테스트 DB 에 존재한다**(실회원 이메일 포함).
#     종료 시 트랩이 무조건 전 테이블을 지우고, 비었는지 다시 확인한다.
#   ⚠ 같은 이유로 pytest 와 겹치면 서로를 망가뜨린다 → flock 으로 상호 배제한다
#     (`server/tests/conftest.py` 가 같은 락을 잡는다).
#
# ── 훈련도 거짓 초록이 될 수 있다 ───────────────────────────────────────────
# 드롭이 조용히 실패하면 **낡은 데이터 위에서 검증이 통과**한다. 그래서 드롭 직후
# "테이블 0개"를 양성 대조군으로 확인하고 나서야 복원을 시작한다(함정 ㉙).
#
# 사용:
#   infra/deploy/restore-drill.sh                 # 최신 백업으로 훈련
#   DRILL_SRC=/path/to.sql.gz infra/deploy/restore-drill.sh
set -euo pipefail

ENV_FILE="${BACKUP_ENV_FILE:-/home/ubuntu/loupit/infra/env/backup.env}"
[ -f "${ENV_FILE}" ] && { set -a; . "${ENV_FILE}"; set +a; }

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-APP_LOUPIT}"
PROD_DB="${DB_NAME:-LOUPIT}"
DRILL_DB="${DRILL_DB:-loupit_test}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/loupit}"
MIRROR_DIR="${MIRROR_DIR:-}"
STATE_FILE="${DRILL_STATE_FILE:-/var/backups/loupit/restore-drill.json}"
LOCK_FILE="${DRILL_LOCK_FILE:-/run/loupit/testdb.lock}"
: "${DB_PASSWORD:?DB_PASSWORD 미설정 — infra/env/backup.env(EnvironmentFile)로 주입}"

fail() { echo "복원 훈련 실패: $*" >&2; STATUS_DETAIL="$*"; exit 1; }

# ── 가드 0: 대상이 절대로 라이브가 아니어야 한다 ────────────────────────────
# 대소문자 무시 비교 — 이 호스트는 lower_case_table_names=0 이라 `loupit` 과 `LOUPIT` 이
# 별개 DB 지만, 오타 한 글자로 서빙을 날리는 위험을 이름 유사성만으로도 차단한다.
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
case "$(lower "${DRILL_DB}")" in
  "$(lower "${PROD_DB}")"|loupit|loupit_beta)
    fail "대상 DB '${DRILL_DB}' 가 서빙/베타다. 훈련은 절대 라이브에 하지 않는다." ;;
esac

# ── 바이너리 해석(systemd 최소 PATH 엔 tarball 설치가 없다 — backup.sh 와 같은 함정) ──
MYSQL_BIN="${MYSQL_BIN:-$(command -v mysql || true)}"
[ -n "${MYSQL_BIN}" ] || MYSQL_BIN=/data/mysql/bin/mysql
[ -x "${MYSQL_BIN}" ] || fail "mysql 없음(PATH·/data/mysql/bin 모두)"

DEFAULTS_FILE="$(mktemp "${TMPDIR:-/tmp}/loupit-drill.XXXXXX.cnf")"
chmod 600 "${DEFAULTS_FILE}"
cat > "${DEFAULTS_FILE}" <<CNF
[client]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
protocol=TCP
CNF

q()  { "${MYSQL_BIN}" --defaults-extra-file="${DEFAULTS_FILE}" -N -B -e "$1"; }
qd() { "${MYSQL_BIN}" --defaults-extra-file="${DEFAULTS_FILE}" -N -B "${DRILL_DB}" -e "$1"; }

table_count() { q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$1'"; }

drop_all_tables() {
  local list
  list="$(q "SELECT GROUP_CONCAT(CONCAT('\`',TABLE_NAME,'\`')) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DRILL_DB}'")"
  # `A || B && C` 는 `(A || B) && C` 로 묶여 읽는 사람의 의도와 어긋난다 — 명시적으로 쓴다.
  if [ -z "${list}" ] || [ "${list}" = "NULL" ]; then
    return 0
  fi
  qd "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS ${list}; SET FOREIGN_KEY_CHECKS=1;"
  return 0
}

STATUS_OK=0
STATUS_DETAIL="시작 전 종료"
SRC=""

write_state() {
  # 훈련 결과는 **일일 요약 메일**이 읽는다(server/ops.py). 실패해도 아무도 모르는 훈련은
  # 훈련이 아니다 — 이미 배달이 실증된 채널을 재사용한다.
  local tmp="${STATE_FILE}.partial.$$"
  mkdir -p "$(dirname "${STATE_FILE}")"
  printf '{"at":"%s","ok":%s,"source":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$([ "${STATUS_OK}" = 1 ] && echo true || echo false)" \
    "$(basename "${SRC:-none}")" \
    "$(printf '%s' "${STATUS_DETAIL}" | tr -d '"\\' | tr '\n' ' ')" \
    > "${tmp}" && mv -f "${tmp}" "${STATE_FILE}"
  return 0
}

cleanup() {
  # ⚠ 정리는 **무조건** 돈다. 실패로 중단돼도 프로덕션 데이터를 테스트 DB 에 남기지 않는다.
  drop_all_tables || true
  local left; left="$(table_count "${DRILL_DB}" 2>/dev/null || echo '?')"
  if [ "${left}" != "0" ]; then
    echo "⚠ 훈련 뒷정리 불완전: ${DRILL_DB} 에 ${left}개 테이블 잔존 — 손으로 확인하라" >&2
    STATUS_OK=0
    STATUS_DETAIL="뒷정리 실패(테이블 ${left}개 잔존)"
  fi
  write_state
  rm -f "${DEFAULTS_FILE}"
  return 0   # 트랩의 마지막 명령이 종료코드를 뒤집지 않게 한다(함정 ㊱)
}

# 🚨 `cleanup` 은 **락을 잡은 뒤에만** 걸어야 한다. 락 경합으로 건너뛰는 경로에서 이 트랩이
#    돌면, 지금 pytest 가 쓰고 있는 `loupit_test` 를 드롭해 버린다 — 정확히 락으로 막으려던
#    사고를 뒷정리가 저지르는 꼴이다. 그때까지는 비밀 파일만 지우는 최소 트랩을 건다
#    (defaults 파일에는 DB 비밀번호가 평문으로 들어 있어 유출시키면 안 된다).
wipe_secret() { rm -f "${DEFAULTS_FILE}"; return 0; }  # 마지막 명령이 0을 내야 한다(함정 ㊱)
trap wipe_secret EXIT

# ── 상호 배제: pytest 와 같은 DB 를 쓴다 ────────────────────────────────────
# ⚠ 락 파일을 **열지 못하는 것**과 **잠겨 있는 것**은 전혀 다른 사건이다. 둘을 한 갈래로
#   묶어 "건너뜀"으로 처리하면, 권한 문제로 락을 못 여는 호스트에서 훈련이 **영원히 조용히
#   안 돈다** — 그리고 그 침묵은 성공과 구분되지 않는다.
if ! exec 9>"${LOCK_FILE}"; then
  fail "락 파일을 열 수 없다: ${LOCK_FILE} (권한 확인. DRILL_LOCK_FILE 로 경로 변경 가능)"
fi
if ! flock -n 9; then
  echo "건너뜀: ${LOCK_FILE} 이 잠겨 있다(pytest 실행 중으로 보임). 다음 주기에 재시도한다."
  STATUS_DETAIL="락 경합으로 건너뜀 — 훈련 자체는 돌지 않았다"
  exit 0   # 경합은 실패가 아니다. 실패로 올리면 매번 늑대소년이 된다.
           # ⚠ 상태 파일을 **건드리지 않는다** — 건너뜀을 실패로 기록하면 직전 성공을 덮어
           #   "훈련이 깨졌다"는 오보가 된다. 대신 상태가 낡아 가고, 일일 요약이 경과일로
           #   "N일째 훈련 없음"을 잡아낸다. 이쪽이 침묵보다 정직하다.
fi

# 여기서부터는 우리가 대상 DB 의 유일한 사용자다 — 이제 뒷정리 트랩을 걸어도 안전하다.
trap cleanup EXIT

# ── 1. 대상 백업 선택 ───────────────────────────────────────────────────────
if [ -n "${DRILL_SRC:-}" ]; then
  SRC="${DRILL_SRC}"
else
  SRC="$(find "${BACKUP_DIR}" -maxdepth 1 -name 'loupit-*.sql.gz' -printf '%T@ %p\n' 2>/dev/null \
         | sort -rn | head -1 | cut -d' ' -f2-)"
  # 1차가 비었으면 미러에서 찾는다 — 미러가 있는데도 "백업 없음"으로 실패하면 오진이다.
  [ -n "${SRC}" ] || [ -z "${MIRROR_DIR}" ] || \
    SRC="$(find "${MIRROR_DIR}" -maxdepth 1 -name 'loupit-*.sql.gz' -printf '%T@ %p\n' 2>/dev/null \
           | sort -rn | head -1 | cut -d' ' -f2-)"
fi
[ -n "${SRC}" ] && [ -f "${SRC}" ] || fail "복원할 백업 파일을 찾지 못했다(${BACKUP_DIR}${MIRROR_DIR:+, ${MIRROR_DIR}})"
gunzip -t "${SRC}" 2>/dev/null || fail "gzip 무결성 검증 실패 — ${SRC}"

echo "복원 훈련 시작: ${SRC} → ${DRILL_DB}"

# ── 2. 대상 비우기 + **양성 대조군** ────────────────────────────────────────
drop_all_tables
BEFORE="$(table_count "${DRILL_DB}")"
[ "${BEFORE}" = "0" ] || fail "대상을 비우지 못했다(테이블 ${BEFORE}개 잔존). 이 상태의 검증은 낡은 데이터를 재는 것이다."

# ── 3. 복원 ────────────────────────────────────────────────────────────────
gunzip -c "${SRC}" | "${MYSQL_BIN}" --defaults-extra-file="${DEFAULTS_FILE}" "${DRILL_DB}" \
  || fail "복원 중 mysql 이 실패했다 — 이 백업으로는 되살릴 수 없다"

# ── 4. 검증: "에러가 없었다"가 아니라 "쓸 수 있는 상태인가" ──────────────────
RESTORED="$(table_count "${DRILL_DB}")"
[ "${RESTORED}" -gt 0 ] || fail "복원 후에도 테이블이 0개다"

# 4-a. 완결성 — **덤프가 담고 있다고 주장하는 테이블이 전부 실제로 생겼는가.**
#
#      ⚠ 처음엔 "서빙에 있는 테이블이 전부 복원됐는가"로 짰다가 첫 실행에서 스스로 틀렸다.
#        서빙 스키마는 배포와 함께 **앞으로 나아가고** 백업은 그 시점에 고정돼 있어서,
#        스키마를 추가한 날엔 다음 03:00 백업 전까지 반드시 빨개진다(2026-07-30 실발현:
#        `TMAIL_SEND_RATE`). 시점이 다른 두 값을 비교한 것 — 함정 ㊵ 을 주석으로 경계해 놓고
#        같은 줄에서 밟았다. 덤프 자신을 기준으로 삼으면 그 표류가 사라진다.
DUMP_TABLES="$(gunzip -c "${SRC}" | sed -n 's/^CREATE TABLE `\([^`]*\)`.*/\1/p' | sort -u)"
[ -n "${DUMP_TABLES}" ] || fail "덤프에 CREATE TABLE 이 하나도 없다 — 구조가 없는 덤프다"
while read -r t; do
  [ -n "${t}" ] || continue
  n="$(q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DRILL_DB}' AND TABLE_NAME='${t}'")"
  [ "${n}" = "1" ] || fail "덤프에 CREATE TABLE 이 있는데 복원되지 않은 테이블: ${t}"
done <<< "${DUMP_TABLES}"
DUMP_TABLE_CNT="$(printf '%s\n' "${DUMP_TABLES}" | wc -l)"

# 4-a2. 서빙에만 있고 백업엔 없는 테이블은 **경고**지 실패가 아니다. 스키마를 추가한 당일엔
#       정상이고 다음 백업이 자동으로 해소한다. 다만 며칠씩 지속되면 백업이 서빙을 못 따라간다는
#       뜻이므로, 상태에 남겨 일일 요약이 사람 눈에 띄게 한다.
NEWER="$(q "SELECT GROUP_CONCAT(TABLE_NAME) FROM information_schema.TABLES p
            WHERE p.TABLE_SCHEMA='${PROD_DB}'
              AND NOT EXISTS (SELECT 1 FROM information_schema.TABLES d
                              WHERE d.TABLE_SCHEMA='${DRILL_DB}' AND d.TABLE_NAME=p.TABLE_NAME)")"
NOTE=""
if [ -n "${NEWER}" ] && [ "${NEWER}" != "NULL" ]; then
  NOTE=" · ⚠백업이후신설 ${NEWER}"
  echo "  ⚠ 서빙에는 있으나 이 백업에는 없는 테이블: ${NEWER}" >&2
  echo "    (백업 이후 스키마를 추가했다면 정상이다. 며칠 지속되면 백업 경로를 의심하라.)" >&2
fi

# 4-b. 비어 있으면 안 되는 테이블 — 덤프가 구조만 담고 데이터를 잃은 경우를 잡는다.
for t in TCOMPANY TCOMPANY_BENEFIT TCOMPANY_TYPE TBENEFIT_PRESET; do
  n="$(qd "SELECT COUNT(*) FROM \`${t}\`" 2>/dev/null || echo 0)"
  [ "${n}" -gt 0 ] || fail "${t} 가 비었다 — 구조만 복원되고 데이터를 잃었다"
done

# 4-c. 참조 무결성 — 덤프 주입은 FK 검사를 끄고 돌기 때문에, 순서가 틀어져 생긴 고아 행이
#      조용히 들어올 수 있다. 복원 직후에 확인하지 않으면 아무도 확인하지 않는다.
ORPHAN="$(qd "SELECT COUNT(*) FROM TCOMPANY_BENEFIT b
              LEFT JOIN TCOMPANY c ON c.COMP_ID=b.COMP_ID WHERE c.COMP_ID IS NULL")"
[ "${ORPHAN}" = "0" ] || fail "복지 ${ORPHAN}행이 존재하지 않는 회사를 가리킨다(고아 행)"

COMPANIES="$(qd "SELECT COUNT(*) FROM TCOMPANY")"
BENEFITS="$(qd "SELECT COUNT(*) FROM TCOMPANY_BENEFIT")"
MEMBERS="$(qd "SELECT COUNT(*) FROM TMEMBER" 2>/dev/null || echo 0)"

STATUS_OK=1
STATUS_DETAIL="테이블 ${DUMP_TABLE_CNT} · 회사 ${COMPANIES} · 복지 ${BENEFITS} · 회원 ${MEMBERS}${NOTE}"
echo "복원 훈련 성공: ${STATUS_DETAIL}"
echo "  (뒷정리로 ${DRILL_DB} 를 다시 비운다 — 프로덕션 데이터를 테스트 DB 에 남기지 않는다)"
