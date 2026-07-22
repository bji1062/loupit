#!/usr/bin/env bash
# infra/deploy/run_tests.sh — 전 계층 테스트 집계(로컬 전용, CI 없음). 실패 시 배포 차단.
# 근거: SP-TEST-4.2, TASK/12 T-12.1.1(MT-1). 릴리스 게이트(SP-ARCH-9 4단계)와 개발 사전검증이 동일 스크립트 호출.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$ROOT"

# python 바이너리 해석: venv 우선 → python3 → python (Ubuntu 22.04 기본은 `python3`만 존재,
# SP-INFRA-2.2 패키지 목록에 python-is-python3 없음 — `python` 단독 가정 시 배포 호스트에서 실패).
if [ -x "$ROOT/server/venv/bin/python" ]; then PY="$ROOT/server/venv/bin/python"
elif command -v python3 >/dev/null; then PY="python3"
else PY="python"; fi

# ── C-1 안전장치(2026-07-12): 이 서버는 서빙 스키마 LOUPIT 를 테스트에도 재사용한다.
# 백엔드 테스트는 5개 참조 테이블을 DROP/CREATE 하므로, 종료 시 서빙 데이터를 재시드해
# beta/프로덕션 API 가 500/빈응답으로 남지 않게 한다. trap 으로 실패·중단(set -e) 시에도
# 재시드를 '시도'한다.
#
# ⚠ 비원자성(L-7, 2026-07-13): load.py --fresh 는 DROP TABLE(DDL) 을 쓰는데 MySQL 에서
# DDL 은 암묵 커밋이라 load.py 의 autocommit=False·try/rollback 이 이 구간엔 무력하다.
# 즉 DROP~재시드 완료 사이에 프로세스가 죽으면 서빙이 빈 채로 남을 수 있다 — 원자 '보장'
# 이 아니라 '시도'다. 그래서 재시드 후 COUNT 로 서빙 적재를 검증하고, 실패하면 조용히
# 넘기지 않고 크게 경고 + 수동 복구 명령을 출력한다. (진짜 원자 스왑이 필요하면 임시테이블
# +RENAME TABLE 로 load.py 를 전환해야 하며, 95개 시드 SQL·백필의 테이블명 하드코딩 때문에
# 범위가 커 별도 작업으로 남긴다.)
# LOUPIT_ALLOW_SERVING_SCHEMA=1 이 conftest 가드에 "복원 책임을 지는 래퍼"임을 신호한다
# (맨 pytest 직접 실행은 이 신호가 없어 차단됨).
export LOUPIT_ALLOW_SERVING_SCHEMA=1
# LOUPIT_ALLOW_FRESH=1 은 load.py --fresh 파괴 가드(#14)를 통과시킨다 — run_tests.sh 는
# 재시드 + TCOMPARE_LOG 재주입으로 복원 책임을 지는 래퍼이므로 명시적으로 허용한다.
export LOUPIT_ALLOW_FRESH=1

# ── #1 안전장치(2026-07-18): TCOMPARE_LOG(트렌딩 원천, 시드로 재현 불가한 유일한 운영 데이터)는
# conftest 가 테스트 격리를 위해 DROP/CREATE 하므로 게이트 실행마다 비워진다. 참조 5테이블과 달리
# load.py --fresh 재시드로는 복원되지 않는다(오히려 --fresh 는 이 로그를 TRUNCATE 해 #15 오귀속을
# 막는다). 그래서 백엔드 pytest 이전에 원본 행을 mysqldump 로 임시 백업하고, 재시드(restore_serving)
# 이후 그 덤프를 재주입해 서빙 로그를 원상복구한다. creds 는 server/.env 파싱 — 이 계정 그랜트가
# 127.0.0.1 한정·PROCESS 권한 없음이라 mysqldump 를 --protocol=TCP -h 127.0.0.1 --no-tablespaces
# --single-transaction 로 고정한다.
command -v mysqldump >/dev/null 2>&1 && command -v mysql >/dev/null 2>&1 || export PATH="/data/mysql/bin:$PATH"  # 백업 mysqldump·존재검사/재주입 mysql 둘 다 필요(배포 호스트 비표준 경로)
_env_get() { grep -E "^$1=" "$ROOT/server/.env" | cut -d= -f2- || true; }  # .env KEY=value (키 고유)
DB_USER_V="$(_env_get DB_USER)"; DB_PASS_V="$(_env_get DB_PASSWORD)"
DB_NAME_V="$(_env_get DB_NAME)"; DB_PORT_V="$(_env_get DB_PORT)"; DB_PORT_V="${DB_PORT_V:-3306}"
CMP_DUMP="$(mktemp "${TMPDIR:-/tmp}/loupit_tcompare_log.XXXXXX.sql")"
_restore_done=0       # set -u 하에서 restore_serving 첫 호출 전 초기화 필수
_cmp_dump_ok=0
_cmp_reinject_done=0

# ── T-13.2.1(SC14 참여): 참여 7테이블 백업/재주입 확장 ──────────────────────────────
# ③ 후 conftest.TABLE_CREATE_ORDER 에 참여 테이블이 들어가면 게이트가 그것도 DROP/CREATE 하므로,
# 회원·세션·인증·재직·편집이력 등 시드로 재현 불가한 데이터가 게이트 실행마다 소실된다(TCOMPARE_LOG
# 와 동일 위험). 그래서 TCOMPARE_LOG 와 똑같이 pytest 이전 mysqldump 백업 → 재시드 이후 재주입한다.
# FK 부모→자식 순(SP-DB-17 생성순서)으로 나열해 재주입도 그 순서다.
#   ⚠ M9 의존(이 파일만으로 미완결): 실제 보존이 작동하려면 (a) db/schema.sql 에 참여 7테이블 DDL,
#     (b) load.py --fresh 가 그 DDL 을 CREATE(현재 참조 5테이블만), (c) conftest 가 참여 테이블을
#     TABLE_CREATE_ORDER 에 편입(③) 이 필요하다. 그 전(현 익명 배포)엔 테이블이 없어 존재검사로
#     걸러져 전 과정 no-op 다 — 즉 본 확장은 '안전 선행 장치'이고 데이터가 생기기 전에 자리를 잡는다.
PART_TABLES="TMEMBER TCOMPANY_EMAIL_DOMAIN TSESSION TAUTH_CODE TEMPLOY_VERIFICATION TEMPLOY_VRF_REQUEST TBENEFIT_EDIT_LOG"
PART_DUMP="$(mktemp "${TMPDIR:-/tmp}/loupit_participation.XXXXXX.sql")"
_part_dump_ok=0
_part_reinject_done=0

backup_compare_log() {
  # 트랩 무장 전에 먼저 실행 — 실패하면 아직 아무것도 파괴하지 않은 상태에서 게이트를 멈춘다
  # (데이터 보호가 게이트보다 우선). --single-transaction 일관 스냅샷, 데이터만(--no-create-info).
  echo "  [backup] TCOMPARE_LOG 덤프 → $CMP_DUMP"
  # --skip-add-locks·--skip-disable-keys: 덤프를 순수 데이터 INSERT 로 축소해 재주입이 INSERT
  # 권한만 요구하게 한다(LOCK TABLES·ALTER 불요). #6 그랜트 정합(SELECT-only 주장 vs 실제 ALL)이
  # 서버 필수 쓰기 최소권한으로 축소되더라도 재주입이 깨지지 않도록 방어.
  if ! MYSQL_PWD="$DB_PASS_V" mysqldump --protocol=TCP -h 127.0.0.1 -P "$DB_PORT_V" \
        -u "$DB_USER_V" --no-tablespaces --single-transaction --no-create-info \
        --skip-add-drop-table --skip-add-locks --skip-disable-keys --complete-insert \
        "$DB_NAME_V" TCOMPARE_LOG \
        > "$CMP_DUMP" 2>"$CMP_DUMP.err"; then
    echo "  ⚠⚠⚠ [backup] TCOMPARE_LOG 백업 실패 — 데이터 보호를 위해 게이트를 중단한다(재시드 미실행)." >&2
    sed 's/^/        /' "$CMP_DUMP.err" >&2 || true
    rm -f "$CMP_DUMP" "$CMP_DUMP.err"
    exit 4
  fi
  rm -f "$CMP_DUMP.err"
  _cmp_dump_ok=1
  if grep -q 'INSERT INTO' "$CMP_DUMP"; then
    echo "  [backup] OK — 원본 행 백업 완료(재시드 후 재주입 예정)"
  else
    echo "  [backup] OK — TCOMPARE_LOG 비어 있음(재주입 불필요)"
  fi
}

_restore_fail_msg() {
  echo "  ⚠⚠⚠ [restore] 서빙(LOUPIT) 복원 실패 — 비었거나 깨진 상태일 수 있다. 즉시 수동 복구:" >&2
  echo "        LOUPIT_ALLOW_FRESH=1 python3 db/seed/load.py --fresh && sudo systemctl restart loupit-api loupit-beta-api" >&2
}
restore_serving() {
  [ "$_restore_done" = 1 ] && return 0
  echo "  [restore] 서빙 스키마(LOUPIT) 재시드 시도(비원자) — load.py --fresh"
  if ! "$PY" "$ROOT/db/seed/load.py" --fresh; then _restore_fail_msg; return 1; fi
  # 비원자 재시드라 정상 종료여도 서빙 적재를 한 번 더 검증(회사 하한 90; 정상은 95).
  if ! LOUPIT_ROOT="$ROOT" "$PY" -c "import os,sys; sys.path.insert(0, os.path.join(os.environ['LOUPIT_ROOT'],'db','seed')); import load; c=load.connect(); cur=c.cursor(); cur.execute('SELECT COUNT(*) FROM TCOMPANY'); n=cur.fetchone()[0]; print('  [restore] 검증: TCOMPANY=%d'%n); sys.exit(0 if n>=90 else 2)"; then
    _restore_fail_msg; return 1
  fi
  _restore_done=1
  echo "  [restore] OK — 서빙 검증 통과"
}

reinject_compare_log() {
  # restore_serving(=load.py --fresh, TCOMPARE_LOG 를 TRUNCATE) 이후 원본 행을 되돌린다. 덤프는
  # 데이터만(빈 테이블에 INSERT)이라 중복 없이 정확히 복원된다. 게이트 경로는 로스터가 불변이라
  # COMP_ID 가 일치하므로 FK 검증을 켠 채 재주입한다(오귀속 행을 일부러 막는다 — 불일치 시 전량
  # 거부 후 덤프 보존).
  [ "$_cmp_reinject_done" = 1 ] && return 0
  [ "$_cmp_dump_ok" = 1 ] || { echo "  [reinject] 백업 없음 — 재주입 생략(백업 단계 미실행)"; return 0; }
  if ! grep -q 'INSERT INTO' "$CMP_DUMP"; then
    echo "  [reinject] 백업에 데이터 행 없음(빈 TCOMPARE_LOG) — 재주입 불필요"
    _cmp_reinject_done=1; rm -f "$CMP_DUMP"; return 0
  fi
  echo "  [reinject] TCOMPARE_LOG 원본 행 재주입 ← $CMP_DUMP"
  if ! MYSQL_PWD="$DB_PASS_V" mysql --protocol=TCP -h 127.0.0.1 -P "$DB_PORT_V" \
        -u "$DB_USER_V" "$DB_NAME_V" < "$CMP_DUMP" 2>"$CMP_DUMP.rerr"; then
    echo "  ⚠⚠⚠ [reinject] TCOMPARE_LOG 재주입 실패 — 트렌딩 로그가 비었거나 일부만 복원됐을 수 있다." >&2
    sed 's/^/        /' "$CMP_DUMP.rerr" >&2 || true
    echo "        백업 원본 보존됨: $CMP_DUMP" >&2
    echo "        수동 복구: MYSQL_PWD=... mysql --protocol=TCP -h 127.0.0.1 -u $DB_USER_V $DB_NAME_V < $CMP_DUMP" >&2
    echo "        복원 확인 후: sudo systemctl restart loupit-api loupit-beta-api" >&2
    rm -f "$CMP_DUMP.rerr"
    return 1
  fi
  rm -f "$CMP_DUMP.rerr"
  _cmp_reinject_done=1
  echo "  [reinject] OK — TCOMPARE_LOG 원본 복원 완료"
  rm -f "$CMP_DUMP"
}

backup_participation() {
  # 존재하는 참여 테이블만 골라 데이터만 덤프(FK 부모→자식 순, PART_TABLES). 하나도 없으면 no-op.
  # ⚠ 존재 조회 자체가 실패하면 '무엇을 보호해야 할지 모른다'는 뜻이라, 데이터 보호를 위해 게이트를
  #   멈춘다(exit 5) — backup_compare_log 의 exit 4 와 동일한 '파괴 전 정지' 원칙.
  local in_list="" t ordered=""
  for t in $PART_TABLES; do in_list="$in_list,'$t'"; done
  in_list="${in_list#,}"
  local existing
  if ! existing="$(MYSQL_PWD="$DB_PASS_V" mysql --protocol=TCP -h 127.0.0.1 -P "$DB_PORT_V" \
        -u "$DB_USER_V" -N -B "$DB_NAME_V" 2>"$PART_DUMP.qerr" \
        -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB_NAME_V' AND TABLE_NAME IN ($in_list)")"; then
    echo "  ⚠⚠⚠ [backup] 참여 테이블 존재 조회 실패 — 데이터 보호를 위해 게이트 중단(재시드 미실행)." >&2
    sed 's/^/        /' "$PART_DUMP.qerr" >&2 || true
    rm -f "$PART_DUMP" "$PART_DUMP.qerr"
    exit 5
  fi
  rm -f "$PART_DUMP.qerr"
  for t in $PART_TABLES; do                       # FK 부모→자식 순으로 존재하는 것만 선별
    if printf '%s\n' "$existing" | grep -qx "$t"; then ordered="$ordered $t"; fi
  done
  if [ -z "$ordered" ]; then
    echo "  [backup] 참여 테이블 없음(현 익명 배포·M9 이전) — 백업 생략(no-op)"
    rm -f "$PART_DUMP"   # 무장 전 mktemp 한 빈 파일 정리(no-op 경로 누수 방지, TCOMPARE_LOG 경로와 대칭)
    return 0
  fi
  echo "  [backup] 참여 테이블 덤프 → $PART_DUMP :$ordered"
  # shellcheck disable=SC2086  # $ordered 는 의도적 단어분할(테이블 인자 목록)
  if ! MYSQL_PWD="$DB_PASS_V" mysqldump --protocol=TCP -h 127.0.0.1 -P "$DB_PORT_V" \
        -u "$DB_USER_V" --no-tablespaces --single-transaction --no-create-info \
        --skip-add-drop-table --skip-add-locks --skip-disable-keys --complete-insert \
        "$DB_NAME_V" $ordered \
        > "$PART_DUMP" 2>"$PART_DUMP.err"; then
    echo "  ⚠⚠⚠ [backup] 참여 테이블 백업 실패 — 데이터 보호를 위해 게이트 중단(재시드 미실행)." >&2
    sed 's/^/        /' "$PART_DUMP.err" >&2 || true
    rm -f "$PART_DUMP" "$PART_DUMP.err"
    exit 5
  fi
  rm -f "$PART_DUMP.err"
  _part_dump_ok=1
  if grep -q 'INSERT INTO' "$PART_DUMP"; then
    echo "  [backup] OK — 참여 테이블 원본 백업 완료(재시드 후 재주입 예정)"
  else
    echo "  [backup] OK — 참여 테이블 비어 있음(재주입 불필요)"
  fi
}

reinject_participation() {
  # restore_serving(참여 테이블은 M9 의 load.py --fresh 가 schema.sql 로 재생성) 이후 원본 행을 되돌린다.
  # 데이터만 덤프라 빈 테이블에 INSERT. 덤프는 FK 부모→자식 순(TMEMBER 선두, --complete-insert 로 원본
  # ID 보존)이고 참조 부모(TCOMPANY·TCOMPANY_BENEFIT 등)는 재시드로 존재하므로 **FK 검사를 켠 채**
  # 재주입한다 — reinject_compare_log 과 동일 fail-safe: 게이트 로스터가 불변이라 정상 일치, 로스터
  # 드리프트로 FK 불일치 시 전량 거부 후 덤프 보존(오귀속/고아행 방지). 스키마는 무변경(데이터만).
  [ "$_part_reinject_done" = 1 ] && return 0
  [ "$_part_dump_ok" = 1 ] || { echo "  [reinject] 참여 백업 없음 — 재주입 생략"; return 0; }
  if ! grep -q 'INSERT INTO' "$PART_DUMP"; then
    echo "  [reinject] 참여 테이블 데이터 행 없음 — 재주입 불필요"
    _part_reinject_done=1; rm -f "$PART_DUMP"; return 0
  fi
  echo "  [reinject] 참여 테이블 원본 행 재주입 ← $PART_DUMP"
  if ! MYSQL_PWD="$DB_PASS_V" mysql --protocol=TCP -h 127.0.0.1 -P "$DB_PORT_V" \
        -u "$DB_USER_V" "$DB_NAME_V" < "$PART_DUMP" 2>"$PART_DUMP.rerr"; then
    echo "  ⚠⚠⚠ [reinject] 참여 테이블 재주입 실패 — 회원·세션·이력이 비었거나 일부만 복원됐을 수 있다." >&2
    sed 's/^/        /' "$PART_DUMP.rerr" >&2 || true
    echo "        백업 원본 보존됨: $PART_DUMP (FK 불일치면 로스터 드리프트 — 수동 확인)" >&2
    echo "        수동 복구: MYSQL_PWD=... mysql --protocol=TCP -h 127.0.0.1 -u $DB_USER_V $DB_NAME_V < $PART_DUMP" >&2
    rm -f "$PART_DUMP.rerr"
    return 1
  fi
  rm -f "$PART_DUMP.rerr"
  _part_reinject_done=1
  echo "  [reinject] OK — 참여 테이블 원본 복원 완료"
  rm -f "$PART_DUMP"
}

# 트랩: 실패·중단(set -e) 시에도 (1) 참조 5테이블 재시드 → (2) TCOMPARE_LOG 원본 재주입 →
# (3) 참여 테이블 원본 재주입 순서로 서빙을 원상복구 '시도'한다(기존 trap 의미 유지). 세 단계 모두
# 자체 done-가드로 멱등하다.
_on_exit() { restore_serving || true; reinject_compare_log || true; reinject_participation || true; }

backup_compare_log      # 반드시 트랩 무장 전에(백업 실패 시 파괴 경로 진입 금지 — exit 4)
backup_participation    # 참여 테이블도 트랩 무장 전 백업(T-13.2.1, 존재 시만; 실패 시 exit 5)
trap _on_exit EXIT

echo "[1/5] 백엔드(API·스키마·시드) — pytest (LOUPIT, 종료 후 자동 재시드 + 로그 재주입)"
"$PY" -m pytest server/tests/ -q
restore_serving       # 백엔드 테스트 직후 즉시 복원 → 서빙 다운타임 최소화(이후 단계는 DB 무접촉)
reinject_compare_log  # 재시드로 비워진 TCOMPARE_LOG 에 원본 행 재주입(#1)
reinject_participation # 참여 테이블 원본 재주입(T-13.2.1, 백업 존재 시만)

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
# node ≥21 glob(디렉토리 인자 대신) — node v24는 `node --test web/`를 모듈 로드로 오해. node ≥20 권장.
node --test 'web/**/*.test.js'

echo "[4/5] 테스트 하네스 자체 검증(메타) — 이미 [3]에 포함(web/test/harness.test.js)"

echo "[5/5] Nginx 설정 문법(배포 호스트에서만)"
# loupit.conf는 sites-available 드롭인(server{} 블록만)이라 -c로 단독 로드 불가 —
# events{}/http{}만 감싸는 로컬 검증 전용 래퍼(loupit.test.conf)로 문법을 검사한다(CFG-1).
if command -v nginx >/dev/null; then nginx -t -c "$ROOT/infra/nginx/loupit.test.conf"; else echo "  nginx 미설치 — 스킵(개발 로컬)"; fi

echo "ALL GREEN — 릴리스 게이트 통과"
