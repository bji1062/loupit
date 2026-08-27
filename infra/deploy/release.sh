#!/usr/bin/env bash
# infra/deploy/release.sh — SP-INFRA-9 릴리스 파이프라인. 근거: SP-INFRA-9.1·9.2, SP-ARCH-9.
# 실행: 리포 루트에서 `bash infra/deploy/release.sh` (또는 어디서든, 스크립트가 ROOT_DIR로 cd).
#
# ── 대상: 라이브 프로덕션 ──
#   nginx 는 web/dist 를 디스크에서 직접 서빙하고(loupit.conf), loupit-api(:8000)·
#   loupit-beta-api(:8001)는 같은 서빙 DB(LOUPIT)를 읽는다. 이 스크립트는 그 서빙
#   DB·정적 dist·양 API 를 실제로 갈아끼운다. 시작 시 대상을 출력하고 RELEASE_CONFIRM=1
#   또는 대화형 [y/N] 확인을 요구한다.
#
# ── 순서(2026-07-18 재구조화, 발견 #4) ──
#   [1] 테스트 게이트 → [2] schema → [3] 서빙 적재 검증 → [4] 정적 build/스왑
#   → [5] API 재시작(양쪽) → [6] nginx reload → [7] 스모크.
#   게이트를 '서빙 상태를 바꾸는 모든 단계' 앞에 두는 것이 핵심이다. 게이트가 실패하면
#   `set -euo pipefail`로 즉시 중단되고 [2]~[7]은 실행되지 않으므로, 정적 산출물(web/dist)은
#   이전본 그대로 유지된다(이전 구조에선 build 가 게이트 앞이라 실패해도 새 정적물이 이미
#   라이브였다 — 그 허위 서술을 제거함).
#
# ── 게이트와 서빙 DB (2026-08-26 격리 전환 후) ──
#   [1] 게이트(run_tests.sh)는 격리 스키마 `loupit_test` 만 쓰고 **서빙(LOUPIT)을 만지지
#   않는다** — 구 판본의 백업/재시드/재주입 곡예와 약 10초 다운타임 창은 격리 전환으로
#   사라졌다(서빙 무접촉 계약: server/tests/test_runner_backup.py). 서빙 DB 는 릴리스
#   전후로 그대로이므로 [2] 이후는 재시드 없이 검증만 한다.
#
#   ⚠ 그래서 이 스크립트는 게이트를 호출할 때 **DB_NAME 을 넘기지 않는다**(아래 [1] 참조).
#   위 33행의 `set -a; source server/.env` 가 DB_NAME=LOUPIT 을 이 프로세스에 export 하는데,
#   run_tests.sh 의 `export DB_NAME="${DB_NAME:-loupit_test}"` 는 **이미 설정된 값을 존중**하므로
#   그대로 물려주면 격리 기본값이 적용되지 않고 게이트가 서빙을 향한다. 2026-08-27 릴리스가
#   정확히 이 경로로 C-1 안전장치에 막혔다(막힌 것이 정상 동작 — 서빙은 무사했다).
#
#   ⚠ 시드 변경은 이제 릴리스로 서빙에 반영되지 않는다. 구 판본은 게이트가 서빙을 재시드하는
#   **부작용**으로 시드 변경이 딸려 들어갔지만, 무접촉 게이트에는 그 경로가 없다. 회사·복지·
#   도메인 시드를 바꿨다면 릴리스와 별개로 명시적으로 적재하라:
#       LOUPIT_ALLOW_FRESH=1 python3 db/seed/load.py --fresh   # 서빙 대상, 의도적 실행
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

PY="${ROOT_DIR}/server/venv/bin/python"
[ -x "${PY}" ] || PY="python3"   # venv 미프로비저닝 → 시스템 python3 폴백

# server/.env(있으면) 로드 — DB_HOST/PORT/USER/PASSWORD/NAME (SP-INFRA-7.1)
if [ -f "${ROOT_DIR}/server/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/server/.env"
  set +a
fi

STEP="시작 전"
_on_err() {
  local ec=$?
  {
    echo ""
    echo "✗ RELEASE 실패 (exit ${ec}) — 마지막 단계: ${STEP}"
    echo "  ── 복구 안내 ──"
    echo "  1) 서빙 DB 적재 확인:"
    echo "       mysql -h ${DB_HOST:-127.0.0.1} -P ${DB_PORT:-3306} -u ${DB_USER:-<user>} -p ${DB_NAME:-loupit} -e 'SELECT COUNT(*) FROM TCOMPANY'"
    echo "     90 미만(빈/불완전)이면 재시드(가드 계약 — env로 의도 명시):"
    echo "       LOUPIT_ALLOW_FRESH=1 ${PY} db/seed/load.py --fresh"
    echo "  2) 정적 산출물: 원자 스왑은 성공 시에만 web/dist 를 교체한다."
    echo "       - [4] 이전 실패 → 이전 dist 그대로 라이브(조치 불필요)."
    echo "       - [4] 이후 실패 → 새 dist 가 이미 라이브. 되돌리려면 web/dist.prev 존재 확인 후 수동 스왑."
    echo "  3) API(양쪽) 재시작·상태 확인:"
    echo "       sudo systemctl restart loupit-api loupit-beta-api"
    echo "       sudo systemctl status loupit-api loupit-beta-api --no-pager"
    echo "  4) nginx: sudo nginx -t && sudo systemctl reload nginx"
    echo "  5) 스모크 재실행: bash infra/deploy/smoke.sh"
  } >&2
}
trap _on_err ERR

# ── 프로덕션 가드 ──
STEP="대상 확인"
echo "══ 릴리스 대상(라이브 프로덕션) ══"
echo "  서빙 DB   : ${DB_NAME:-loupit} @ ${DB_HOST:-127.0.0.1}:${DB_PORT:-3306} (user=${DB_USER:-미설정})"
echo "  서빙 dist : ${ROOT_DIR}/web/dist (nginx 가 디스크에서 직접 서빙)"
echo "  대상 API  : loupit-api(:8000) + loupit-beta-api(:8001, 설치돼 있으면)"
echo "  ✓ [1] 게이트는 격리 스키마(loupit_test)에서 돈다 — 서빙 무접촉, 다운타임 창 없음."
if [ "${RELEASE_CONFIRM:-}" != "1" ]; then
  if [ -t 0 ]; then
    read -r -p "위 프로덕션 대상에 릴리스한다. 계속? [y/N] " _ans
    case "${_ans}" in
      y|Y|yes|YES) ;;
      *) echo "중단(사용자 미승인)."; trap - ERR; exit 1;;
    esac
  else
    echo "✗ 비대화형 실행 — RELEASE_CONFIRM=1 을 설정해 의도를 명시하라." >&2
    trap - ERR; exit 1
  fi
fi

# ── M9(SC14 참여 기능) 활성화 가드 ──────────────────────────────────────────
# [2] 의 `mysql < db/schema.sql` 은 멱등이지만 **부재 테이블은 새로 만든다**. schema.sql 에는
# SC14 참여 7테이블이 이미 들어 있고 `server/main.py` 는 member·employment·benefit_edit 라우터를
# 무조건 등록하므로, 아무 생각 없이 릴리스를 한 번 돌리면 **AdSense 게이트 전에 M9 API 가 조용히
# 활성화**된다(적대리뷰 2026-07-25 확증). 활성화는 체크리스트를 동반한 명시적 결정이어야 한다
# → 서빙 스키마에 참여 테이블이 없으면 `M9_ACTIVATE=1` 없이는 여기서 중단한다.
# (테스트 게이트[1]도 서빙 스키마를 건드리므로 그 **앞**에서 막는다.)
STEP="M9 활성화 가드"
_PARTICIPATION_TABLES="'TMEMBER','TSESSION','TAUTH_CODE','TCOMPANY_EMAIL_DOMAIN','TEMPLOY_VERIFICATION','TEMPLOY_VRF_REQUEST','TBENEFIT_EDIT_LOG'"
_npart="$(mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER:?DB_USER 미설정 — server/.env 확인}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} -N -B -e \
  "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB_NAME:-loupit}' AND TABLE_NAME IN (${_PARTICIPATION_TABLES})")"
if [ "${_npart:-0}" -eq 7 ]; then
  echo "  ✓ M9 참여 테이블 7/7 존재 — 이미 활성 스키마(추가 확인 불요)."
elif [ "${M9_ACTIVATE:-}" = "1" ]; then
  echo "  ⚠ M9_ACTIVATE=1 — 이번 릴리스가 참여 테이블(${_npart:-0}/7 존재)을 생성해 **M9 를 활성화**한다."
else
  {
    echo ""
    echo "✗ 중단: 이 릴리스는 M9(로그인·재직인증·복지편집)를 활성화하게 된다."
    echo "  서빙 스키마 ${DB_NAME:-loupit} 의 참여 테이블: ${_npart:-0}/7 존재"
    echo "  [2] schema 단계의 db/schema.sql 이 나머지를 생성하고, 등록된 라우터가 즉시 공개된다."
    echo "  ── 의도한 릴리스라면 ──"
    echo "     M9 활성화 체크리스트(docs/HANDOFF-로그인기능-ML-A.md·TASK/13)를 먼저 확인하고"
    echo "     M9_ACTIVATE=1 RELEASE_CONFIRM=1 bash infra/deploy/release.sh"
    echo "  ── 아니라면 ──"
    echo "     M9 는 AdSense 심사 이후로 게이트돼 있다. 이 릴리스는 취소하라."
  } >&2
  trap - ERR; exit 1
fi

echo "[1/7] test gate (SP-TEST-4 집계 — G1~G3) — 실패 시 즉시 중단(2~7 미실행, 서빙 정적물 유지)"
STEP="[1/7] 테스트 게이트"
# `env -u DB_NAME` 이 이 호출의 핵심이다 — 위에서 server/.env 를 `set -a` 로 읽어 DB_NAME=LOUPIT
# 이 export 돼 있고, run_tests.sh 는 이미 설정된 DB_NAME 을 존중하므로(CI 의 loupit_ci 를 위해)
# 그대로 물려주면 격리 기본값이 죽고 게이트가 서빙을 향한다. 지워서 넘겨 callee 의 기본값
# (loupit_test)이 서게 한다. DB_HOST/PORT/USER/PASSWORD 는 접속에 필요하므로 그대로 넘긴다.
# 가드: server/tests/test_runner_backup.py::test_release_does_not_leak_serving_db_name_into_gate
env -u DB_NAME bash "${SCRIPT_DIR}/run_tests.sh"

echo "[2/7] schema (SP-DB) — mysql < db/schema.sql (멱등 CREATE TABLE IF NOT EXISTS)"
echo "      격리 전환 후 게이트는 서빙에 손대지 않는다 — 서빙 스키마를 실제로 적용하는 곳은 여기뿐이다."
STEP="[2/7] schema"
mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER:?DB_USER 미설정 — server/.env 확인}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} "${DB_NAME:-loupit}" < "${ROOT_DIR}/db/schema.sql"

echo "[3/7] 서빙 적재 검증 — 서빙 DB 가 온전한지 COUNT 로 확인(재시드 아님; 시드 변경은 별도 적재)"
STEP="[3/7] 서빙 적재 검증"
_ncomp="$(mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} -N -B -e "SELECT COUNT(*) FROM TCOMPANY" "${DB_NAME:-loupit}")"
if [ "${_ncomp:-0}" -lt 90 ]; then
  echo "  ✗ 서빙 TCOMPANY=${_ncomp:-?} (<90) — 서빙 DB 가 비었거나 불완전하다(복구 안내 참조)." >&2
  false   # ERR 트랩이 복구 안내(재시드 등)를 출력하고 set -e 로 종료
fi
echo "  ✓ 서빙 TCOMPANY=${_ncomp}"

echo "[4/7] static generate (SP-GEN-1.4/11) — generator.build → web/dist (원자적 스왑, 게이트 뒤라 실패해도 이전본 유지)"
STEP="[4/7] 정적 build/스왑"
"${PY}" -m generator.build --out web/dist

echo "[5/7] restart API — loupit-api + loupit-beta-api (양쪽 참조 캐시 무효화, 동일 서빙 DB)"
STEP="[5/7] API 재시작"
sudo systemctl restart loupit-api
if systemctl cat loupit-beta-api.service >/dev/null 2>&1; then
  # 베타는 스테이징이라 실패가 프로덕션을 막지 않도록 best-effort.
  if sudo systemctl restart loupit-beta-api; then
    echo "  ✓ loupit-api + loupit-beta-api 재시작"
  else
    echo "  ⚠ loupit-beta-api 재시작 실패(프로덕션 무관 — 수동 확인)." >&2
  fi
else
  echo "  ✓ loupit-api 재시작 (loupit-beta-api 미설치 — 스킵)"
fi

echo "[6/7] reload nginx (SP-INFRA-3)"
STEP="[6/7] nginx reload"
sudo nginx -t && sudo systemctl reload nginx

echo "[7/7] smoke (SP-INFRA-11)"
STEP="[7/7] 스모크"
bash "${SCRIPT_DIR}/smoke.sh"

trap - ERR
echo "RELEASE OK"
