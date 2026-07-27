#!/usr/bin/env bash
# infra/deploy/rollback-nginx.sh — 2026-07-27 레이트리밋 배선(커밋 4fd61a2)의 안전 롤백.
#
# 목적: `.bak-<접미사>` 백업을 **의존 순서대로** 되돌리고, 되돌린 결과가 실제로 반영됐는지
#       확인한다. 파일 단위로 손수 cp 하는 롤백이 조용히 무효화되는 사고를 막는 것이 전부다.
#
# ── 왜 이 스크립트가 따로 있어야 하나(격리 prefix 실측, 2026-07-27) ──────────────────
# 레이트리밋 배선은 두 겹이다: 존 **정의**(conf.d/loupit-limits.conf, http 컨텍스트)와
# 존 **사용**(sites-available/loupit.conf·loupit-beta.conf 의 `limit_req zone=loupit_mail`).
# 백업 3종이 전부 같은 접미사라 "파일 하나만 되돌리기"를 유도하는데, 정의만 되돌리면:
#
#   $ nginx -t
#   nginx: [emerg] zero size shared memory zone "loupit_mail"     ← 설정 로드 실패
#   $ systemctl reload nginx                                       ← ExecReload=nginx -s reload
#   $ echo $?
#   0                                                              ← **성공을 보고한다**
#
# nginx 마스터는 새 설정을 거부하고 **구 설정으로 계속 서빙**한다(워커 pid 불변, 리밋 그대로
# 429). 운영자 화면엔 "Reloaded ... nginx" 만 보인다. 즉 롤백은 안 됐는데 됐다고 믿게 되고,
# 그 상태에서 취하는 다음 조치가 진짜 사고다.
#
# 게다가 그 emerg 는 **journal 에 남지 않는다**(실측: 마스터 stderr 캡처가 비어 있음).
# nginx 는 데몬화 후 stderr 를 error_log 로 돌리므로 systemd 가 잡을 것이 없고,
# `journalctl -u nginx` 에는 systemd 의 "Reloading/Reloaded" 두 줄만 남아 오히려 오탐을 준다.
# → 이 스크립트는 error_log 증분과 워커 pid 교체를 **정본 신호**로 쓴다(§[6/6]).
#
# 사용:
#   bash infra/deploy/rollback-nginx.sh 20260727-130123          # 실제 롤백
#   DRY_RUN=1 bash infra/deploy/rollback-nginx.sh 20260727-130123 # 계획만 출력
#
# 격리 테스트 전용 오버라이드(운영에선 건드리지 말 것):
#   NGINX_ETC(기본 /etc/nginx) · NGINX_ERROR_LOG(기본 /var/log/nginx/error.log)
#   NGINX_PID_FILE(기본 /run/nginx.pid) · NGINX_TEST_CMD · NGINX_RELOAD_CMD
set -euo pipefail

SUFFIX="${1:-}"
if [ -z "${SUFFIX}" ]; then
  echo "사용법: bash infra/deploy/rollback-nginx.sh <백업접미사>   (예: 20260727-130123)" >&2
  echo "  현재 남아 있는 백업 접미사:" >&2
  ls /etc/nginx/conf.d/*.bak-* /etc/nginx/sites-available/*.bak-* 2>/dev/null \
    | sed -e 's#.*\.bak-##' | sort -u | sed -e 's/^/    /' >&2 || true
  exit 1
fi
case "${SUFFIX}" in *[/\ ]*|.*) echo "✗ 접미사에 / · 공백 · 선행점을 쓸 수 없다: ${SUFFIX}" >&2; exit 1;; esac

NGINX_ETC="${NGINX_ETC:-/etc/nginx}"
NGINX_ERROR_LOG="${NGINX_ERROR_LOG:-/var/log/nginx/error.log}"
NGINX_PID_FILE="${NGINX_PID_FILE:-/run/nginx.pid}"
NGINX_TEST_CMD="${NGINX_TEST_CMD:-sudo nginx -t}"
NGINX_RELOAD_CMD="${NGINX_RELOAD_CMD:-sudo systemctl reload nginx}"
DRY_RUN="${DRY_RUN:-0}"

# 되돌릴 대상. **배열 순서가 곧 적용 순서**다(아래 [4/6] 참조) — 존을 쓰는 쪽이 먼저 사라져야
# 중간 상태에서도 설정이 유효하다. 이 순서를 뒤집지 말 것.
SITE_CONFS=("${NGINX_ETC}/sites-available/loupit.conf"
            "${NGINX_ETC}/sites-available/loupit-beta.conf")
LIMITS_CONF="${NGINX_ETC}/conf.d/loupit-limits.conf"
ORDERED=("${SITE_CONFS[@]}" "${LIMITS_CONF}")

_run() {  # DRY_RUN 이면 출력만, 아니면 실행
  if [ "${DRY_RUN}" = 1 ]; then echo "    [dry-run] $*"; else "$@"; fi
}

echo "[1/6] 백업 존재 확인(접미사: ${SUFFIX})"
PRESENT=(); MISSING=()
for _f in "${ORDERED[@]}"; do
  if [ -f "${_f}.bak-${SUFFIX}" ]; then PRESENT+=("${_f}"); echo "  · 있음: ${_f}.bak-${SUFFIX}"
  else MISSING+=("${_f}"); echo "  · 없음: ${_f}.bak-${SUFFIX}"; fi
done
if [ "${#PRESENT[@]}" = 0 ]; then
  echo "  ✗ 접미사 ${SUFFIX} 로 되돌릴 백업이 하나도 없다 — 아무것도 하지 않는다." >&2
  exit 1
fi
[ "${#MISSING[@]}" != 0 ] && echo "  ⚠ 부분 롤백이다 — 위 '없음' 파일은 현재 상태 그대로 남는다."

echo "[2/6] 존 정의·참조 정합성 검사(부분 롤백이 정확히 여기서 사고를 낸다)"
# nginx -t 로 잡을 수는 있지만 그건 **이미 파일을 덮어쓴 뒤**다. 되돌리기 전에 미리 계산한다:
#   롤백 후 정의될 존 ⊇ 롤백 후 참조될 존  이 성립하지 않으면 손도 대지 않고 중단.
# _resolved: 롤백 대상이면 .bak 내용을, 아니면 현재 내용을 쓴다(= 롤백 후 예상 상태).
_resolved() {
  local f="$1"
  for _p in "${PRESENT[@]}"; do [ "${_p}" = "${f}" ] && { cat "${f}.bak-${SUFFIX}"; return; }; done
  cat "${f}"
}
# 주석을 먼저 지운다 — 리포 conf 는 산문 주석에 존 이름을 자주 언급한다(오탐 방지).
_defined="$( { for _f in "${NGINX_ETC}"/conf.d/*.conf; do [ -f "${_f}" ] && _resolved "${_f}"; done; } \
             | sed -e 's/#.*//' | grep -oE 'limit_req_zone[^;]*zone=[A-Za-z0-9_]+' \
             | sed -e 's/.*zone=//' | sort -u )"
# 참조는 활성화된 vhost 전부에서 찾는다(우리가 되돌리는 2종 말고 다른 vhost 가 써도 잡히게).
_referenced="$( { for _l in "${NGINX_ETC}"/sites-enabled/*; do
                    [ -e "${_l}" ] || continue
                    _resolved "$(readlink -f "${_l}")"
                  done; } \
                | sed -e 's/#.*//' | grep -oE '(^|[^_])limit_req[[:space:]]+zone=[A-Za-z0-9_]+' \
                | sed -e 's/.*zone=//' | sort -u )"
_orphan="$(comm -23 <(echo "${_referenced}") <(echo "${_defined}") | sed -e '/^$/d')"
if [ -n "${_orphan}" ]; then
  echo "  ✗ 롤백 후 정의가 사라지는데 참조는 남는 존:" >&2
  echo "${_orphan}" | sed -e 's/^/      /' >&2
  echo "    → nginx: [emerg] zero size shared memory zone \"...\" 로 설정 로드가 실패하고," >&2
  echo "      systemctl reload 는 exit 0 을 반환하면서 **구 설정으로 계속 서빙**한다." >&2
  echo "    조치: 위 존을 참조하는 vhost 의 .bak-${SUFFIX} 백업도 함께 갖춰 다시 실행하라" >&2
  echo "          (또는 해당 vhost 에서 limit_req 줄을 먼저 제거하라)." >&2
  exit 1
fi
echo "  ✓ 롤백 후 정의: [$(echo ${_defined} | tr '\n' ' ')] ⊇ 참조: [$(echo ${_referenced} | tr '\n' ' ')]"

echo "[3/6] 현재 파일 스냅샷(= 롤백 실패 시 되돌아갈 지점)"
# nginx -t 가 실패하면 '방금 되돌린 것을 다시 앞으로' 감아야 한다. .bak 을 신뢰하지 않고
# **지금 이 순간의 라이브 내용**을 별도로 뜬다(.bak 은 이미 과거 시점이라 복구 지점이 못 된다).
SNAP="$(mktemp -d)"
trap 'rm -rf "${SNAP}"' EXIT
for _f in "${PRESENT[@]}"; do
  echo "  · ${_f} → ${SNAP}/$(basename "${_f}")"
  _run sudo cp -a "${_f}" "${SNAP}/$(basename "${_f}")"
done

echo "[4/6] 의존 순서대로 되돌리기(사이트 vhost → conf.d 존 정의)"
# 존을 **쓰는** 쪽(vhost)이 먼저 사라져야 한다. 반대로 하면 중간 상태가 곧 위 emerg 상태다.
APPLIED=()
for _f in "${ORDERED[@]}"; do
  for _p in "${PRESENT[@]}"; do
    if [ "${_p}" = "${_f}" ]; then
      echo "  · ${_f}.bak-${SUFFIX} → ${_f}"
      _run sudo install -o root -g root -m 644 "${_f}.bak-${SUFFIX}" "${_f}"
      APPLIED+=("${_f}")
    fi
  done
done

if [ "${DRY_RUN}" = 1 ]; then
  echo "[5/6] [dry-run] ${NGINX_TEST_CMD}"
  echo "[6/6] [dry-run] ${NGINX_RELOAD_CMD} → error_log 증분·워커 pid 교체로 실반영 확인"
  echo "  ✓ dry-run 종료 — 실제로 바뀐 파일은 없다."
  exit 0
fi

echo "[5/6] 검증(${NGINX_TEST_CMD})"
if ! ${NGINX_TEST_CMD}; then
  echo "  ✗ 롤백 후 nginx -t 실패 — 방금 되돌린 것을 다시 앞으로 감는다(원상복구)." >&2
  # 앞으로 감을 때는 적용의 **역순**이다: 존 정의를 먼저 되살려야 vhost 가 참조할 대상이 생긴다.
  for (( _i=${#APPLIED[@]}-1; _i>=0; _i-- )); do
    _f="${APPLIED[_i]}"
    sudo install -o root -g root -m 644 "${SNAP}/$(basename "${_f}")" "${_f}"
    echo "  · 복구: ${_f}" >&2
  done
  if ${NGINX_TEST_CMD}; then
    echo "  ✓ 원상복구 후 nginx -t 통과 — 롤백 미적용. reload 하지 않았다(라이브 무영향)." >&2
  else
    echo "  ⚠ 원상복구 후에도 nginx -t 실패 — 롤백과 무관한 기존 설정 문제다. 즉시 수동 점검." >&2
  fi
  exit 1
fi

echo "[6/6] 적용(${NGINX_RELOAD_CMD}) — exit 0 을 신뢰하지 않는다"
# reload 전 상태 고정: error_log 크기(증분만 읽는다 — --since 는 시계·버퍼링에 취약)와 워커 pid.
# 읽기 판정도 sudo 로 한다 — error_log·pid 는 보통 root 전용이라 맨 `[ -r ]` 은 비root 운영자에게
# 항상 false 를 주고, 그러면 검사를 '조용히 건너뛰어' 이 스크립트의 존재 이유가 사라진다.
_log_readable=0; _log_before=0
if sudo test -r "${NGINX_ERROR_LOG}"; then
  _log_readable=1
  _log_before="$(sudo stat -c %s "${NGINX_ERROR_LOG}" 2>/dev/null || echo 0)"
fi
_master=""; _workers_before=""
if sudo test -r "${NGINX_PID_FILE}"; then
  _master="$(sudo cat "${NGINX_PID_FILE}")"
  _workers_before="$(pgrep -P "${_master}" 2>/dev/null | sort | tr '\n' ' ')"
fi
_silent_fail=0
# reload 가 **비영점**을 주는 경우도 있다(마스터 부재 등). set -e 로 여기서 즉사시키면 아래
# "파일은 이미 롤백됐다"는 안내를 못 주므로, 실패를 삼키지 말고 기록만 하고 진단을 계속한다.
if ! ${NGINX_RELOAD_CMD}; then
  echo "  ✗ reload 명령이 비영점으로 끝났다 — 아래 진단을 함께 보라." >&2
  _silent_fail=1
fi
sleep 2   # 마스터가 새 설정을 파싱하고 워커를 교체할 시간

# (a) 정본 신호 1 — error_log 증분의 [emerg]. journal 에는 안 남으므로 이쪽이 실제 근거다.
if [ "${_log_readable}" = 1 ]; then
  _new="$(sudo tail -c "+$((_log_before + 1))" "${NGINX_ERROR_LOG}" 2>/dev/null | grep -i 'emerg' || true)"
  if [ -n "${_new}" ]; then
    echo "  ✗ reload 후 error_log 에 emerg — 새 설정이 거부됐고 구 설정으로 계속 서빙 중이다:" >&2
    echo "${_new}" | sed -e 's/^/      /' >&2
    _silent_fail=1
  fi
else
  echo "  ⚠ ${NGINX_ERROR_LOG} 를 읽을 수 없다 — emerg 검사를 건너뛴다(신호 1 상실)." >&2
fi
# (b) 정본 신호 2 — 워커 pid 교체. 로그와 무관한 독립 증거다(성공: 전원 교체, 거부: 그대로).
if [ -n "${_workers_before}" ]; then
  _workers_after="$(pgrep -P "${_master}" 2>/dev/null | sort | tr '\n' ' ')"
  if [ "${_workers_before}" = "${_workers_after}" ]; then
    echo "  ✗ 워커 pid 가 그대로다(${_workers_after}) — reload 가 실제로는 반영되지 않았다." >&2
    _silent_fail=1
  else
    echo "  · 워커 교체 확인: [${_workers_before}] → [${_workers_after}]"
  fi
else
  echo "  ⚠ ${NGINX_PID_FILE} 를 읽을 수 없다 — 워커 교체 검사를 건너뛴다(신호 2 상실)." >&2
fi
# (c) 보조 — journal. 위 실측대로 여기엔 emerg 가 **안 남는 게 정상**이라 무소식이 무죄가 아니다.
#     error_log 를 stderr 로 돌린 변형 배치에서만 잡히므로 참고용으로만 본다.
if command -v journalctl >/dev/null 2>&1; then
  _j="$(sudo journalctl -u nginx --since -1min --no-pager 2>/dev/null | grep -i 'emerg' || true)"
  [ -n "${_j}" ] && { echo "  ✗ journal emerg:" >&2; echo "${_j}" | sed -e 's/^/      /' >&2; _silent_fail=1; }
fi

if [ "${_silent_fail}" = 1 ]; then
  echo "  ✗ 롤백이 조용히 무효화됐다 — 파일은 되돌아갔지만 nginx 는 구 설정을 물고 있다." >&2
  echo "    파일은 이미 .bak-${SUFFIX} 상태이므로, 원인 제거 후 '${NGINX_RELOAD_CMD}' 만 다시 하면 된다." >&2
  echo "    (스냅샷은 ${SNAP} — 이 프로세스 종료와 함께 사라지니 필요하면 지금 복사하라.)" >&2
  exit 1
fi
echo "  ✓ 롤백 적용·반영 확인 완료(접미사 ${SUFFIX})."
[ "${#MISSING[@]}" != 0 ] && {
  echo "  ⚠ 다만 아래는 백업이 없어 되돌리지 않았다 — 롤백은 부분적이다:"
  printf '      %s\n' "${MISSING[@]}"
}
exit 0
