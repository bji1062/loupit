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
# ── 게이트의 서빙 다운타임 창(정직 서술) ──
#   이 서버는 서빙 스키마 LOUPIT 를 테스트에도 재사용한다(별도 TEST DB 불가, C-1).
#   그래서 [1] 게이트(run_tests.sh)의 백엔드 테스트 구간에서 참조 5테이블이 일시
#   DROP/CREATE 되었다가 게이트 종료 시 재시드로 복원된다 — 약 10초 내외의 백엔드
#   다운타임 창이 매 릴리스마다 존재한다. 이는 공유 스키마 구조상 불가피하며, 게이트가
#   통과하면 종료 시점에 서빙 DB(참조 5테이블 + TCOMPARE_LOG)가 최신 리포 시드로 이미
#   복원돼 있다(run_tests.sh 복원 계약). 그래서 [2] 이후는 재시드하지 않고 검증만 한다.
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
echo "  ⚠ [1] 게이트 백엔드 테스트 구간에 약 10초 서빙 다운타임 창이 있다(위 헤더 참조)."
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

echo "[1/7] test gate (SP-TEST-4 집계 — G1~G3) — 실패 시 즉시 중단(2~7 미실행, 서빙 정적물 유지)"
echo "      ⚠ 백엔드 테스트가 참조 5테이블을 일시 DROP/CREATE 후 종료 시 재시드한다(~10초 창)."
STEP="[1/7] 테스트 게이트"
bash "${SCRIPT_DIR}/run_tests.sh"

echo "[2/7] schema (SP-DB) — mysql < db/schema.sql (멱등 CREATE TABLE IF NOT EXISTS)"
echo "      게이트 복원이 이미 schema 를 적용했다 — 이 단계는 존재 보장을 위한 멱등 no-op 가드."
STEP="[2/7] schema"
mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER:?DB_USER 미설정 — server/.env 확인}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} "${DB_NAME:-loupit}" < "${ROOT_DIR}/db/schema.sql"

echo "[3/7] 서빙 적재 검증 — 게이트 복원이 최신 시드를 적재했음을 COUNT 로 확인(재시드 아님, 중복 쓰기 회피)"
STEP="[3/7] 서빙 적재 검증"
_ncomp="$(mysql -h "${DB_HOST:-127.0.0.1}" -P "${DB_PORT:-3306}" -u "${DB_USER}" \
  ${DB_PASSWORD:+-p"${DB_PASSWORD}"} -N -B -e "SELECT COUNT(*) FROM TCOMPANY" "${DB_NAME:-loupit}")"
if [ "${_ncomp:-0}" -lt 90 ]; then
  echo "  ✗ 서빙 TCOMPANY=${_ncomp:-?} (<90) — 게이트 복원 실패 의심." >&2
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
