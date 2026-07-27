#!/usr/bin/env bash
# infra/deploy/deploy-beta.sh — beta.loupit.co 무중단 스테이징 산출물 배치(리포 → /etc).
#
# 목적: 프로덕션 provision.sh([4/6])가 프로덕션 산출물만 배치하므로, 베타 스테이징
#       (loupit-beta.conf·보안 스니펫 2종·loupit-beta-api.service)을 리포만으로
#       재구축할 수 있게 한다. 산출물은 전부 git에 커밋돼 있어야 한다(B-1 결함 수정).
#
# 전제:
#   - server/.env.beta 존재(gitignore — 새 환경에선 수동 생성; APP_LOUPIT/포트 8001 등).
#   - /etc/letsencrypt/live/beta.loupit.co/{fullchain,privkey}.pem 존재
#     (최초 발급: sudo certbot --nginx -d beta.loupit.co, :80 활성 상태에서 1회).
#   - 시스템 python3에 fastapi/uvicorn/pymysql 설치(베타는 venv 미프로비저닝).
#
# 사용: sudo bash infra/deploy/deploy-beta.sh   (각 단계 검토 후 실행 권장)
# 근거: docs/RESUME.md §A·§B-1.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[1/5] 전제조건 점검(파일 배치 전 — 전부 통과해야 진행)"
if [ ! -f "${ROOT_DIR}/server/.env.beta" ]; then
  echo "  ✗ server/.env.beta 없음 — 베타 API 환경파일을 먼저 생성하라(gitignore)." >&2
  exit 1
fi
# 인증서 부재 시 '경고 후 진행'은 반배포다(발견 #17): loupit-beta.conf 는 존재하지 않는
# 인증서 파일을 참조하므로, 심링크를 sites-enabled 에 걸어두면 이후 모든 nginx -t·reload가
# (무관한 프로덕션·certbot deploy-hook 포함) 실패한다. 그래서 배치 전에 즉시 중단한다.
if [ ! -f /etc/letsencrypt/live/beta.loupit.co/fullchain.pem ]; then
  echo "  ✗ beta.loupit.co 인증서 없음 — 파일을 배치하지 않고 중단한다." >&2
  echo "    최초 발급: sudo certbot --nginx -d beta.loupit.co (:80 활성 상태에서 1회), 후 재실행." >&2
  exit 1
fi

echo "[2/5] nginx 보안 스니펫 + http 컨텍스트 산출물 배치"
sudo mkdir -p /etc/nginx/snippets /etc/nginx/conf.d
sudo cp "${ROOT_DIR}/infra/nginx/snippets/loupit-security.conf"      /etc/nginx/snippets/loupit-security.conf
sudo cp "${ROOT_DIR}/infra/nginx/snippets/loupit-beta-security.conf" /etc/nginx/snippets/loupit-beta-security.conf
sudo chmod 644 /etc/nginx/snippets/loupit-security.conf /etc/nginx/snippets/loupit-beta-security.conf
# 레이트리밋 존 정의(http 컨텍스트 전용 → conf.d). 2026-07-27 부터 beta vhost 도
# `limit_req zone=loupit_api|loupit_mail` 로 여기에 **하드 의존**한다 — 이 파일 없이 vhost 만
# 배치하면 "unknown limit_req zone" 으로 nginx 전체가 뜨지 못한다(정의가 사용보다 앞서야 하며,
# conf.d 는 sites-enabled 보다 먼저 include 되므로 여기서 함께 배치한다).
sudo cp "${ROOT_DIR}/infra/nginx/loupit-limits.conf" /etc/nginx/conf.d/loupit-limits.conf
sudo chmod 644 /etc/nginx/conf.d/loupit-limits.conf

echo "[3/5] beta vhost 배치·활성화"
# ── docroot 결정 (2026-07-27 blocker 수정) ─────────────────────────────────────
# 리포의 loupit-beta.conf 는 "m9-frontend 가 main 에 병합된 뒤" 상태, 즉 docroot=${ROOT_DIR}/web
# 를 담는다. 그런데 병합 전인 현재 라이브 베타는 **별도 체크아웃**(/home/ubuntu/loupit-fe/web)을
# 서빙한다. 여기서 리포 파일을 통째 cp 하면 docroot 가 뒤바뀌어 베타 M9 페이지
# (/login·/mypage·/verify·/edit·/edits — main 체크아웃엔 존재하지 않는다)가 **전부 404** 가 된다.
# 게다가 nginx 는 root 디렉터리·파일의 존재를 검사하지 않으므로 [5/5] 의 `nginx -t` 롤백 가드가
# 이 사고를 **못 잡는다**(문법은 완벽히 유효하다). 그래서 두 겹으로 막는다:
#   (1) 라이브에 이미 vhost 가 있으면 그 docroot 를 보존한다(BETA_DOCROOT 로 명시 오버라이드 가능).
#   (2) 배치 **전에** 그 docroot 가 실제로 베타가 서빙해야 할 페이지를 갖고 있는지 확인한다.
# 병합이 끝나면 라이브 docroot 를 ${ROOT_DIR}/web 으로 되돌리면 (1)이 자동으로 그 값을 따른다.
BETA_DOCROOT="${BETA_DOCROOT:-}"
if [ -z "${BETA_DOCROOT}" ] && [ -f /etc/nginx/sites-available/loupit-beta.conf ]; then
  # ⚠ ACME 블록의 root 는 반드시 건너뛴다(2026-07-27 세션 C). 그 root 는 certbot 의 webroot_path
  #   와 묶여 있어 docroot 치환에서 제외되므로, 파일에서 **먼저 나오는** `root …/web` 이다.
  #   순진하게 첫 줄을 집으면 앱 docroot 대신 ACME root 를 docroot 로 오인한다.
  #   마커 + 블록 범위 두 겹으로 거른다(누가 마커를 지워도 블록 판정이 받아준다).
  BETA_DOCROOT="$(awk '
    /acme-challenge/  {inacme=1; next}
    inacme && /}/     {inacme=0; next}
    inacme            {next}
    /ACME-NO-REWRITE/ {next}
    $1=="root" {sub(/;$/,"",$2); if ($2 ~ /\/web$/) {print $2; exit}}
  ' /etc/nginx/sites-available/loupit-beta.conf)"
  [ -n "${BETA_DOCROOT}" ] && echo "  · 기존 라이브 docroot 보존: ${BETA_DOCROOT}"
fi
BETA_DOCROOT="${BETA_DOCROOT:-${ROOT_DIR}/web}"
BETA_CHECKOUT="$(dirname "${BETA_DOCROOT}")"   # web/ 의 형제 경로(infra/beta-test) 기준

# nginx -t 가 못 잡는 것을 여기서 잡는다: docroot 에 실제로 페이지가 있는가.
_miss=0
for _f in index.html login.html mypage.html verify.html edit.html edits.html; do
  if [ ! -f "${BETA_DOCROOT}/${_f}" ]; then
    echo "  ✗ 없음: ${BETA_DOCROOT}/${_f}" >&2
    _miss=1
  fi
done
if [ "${_miss}" = 1 ]; then
  echo "  ✗ docroot(${BETA_DOCROOT})에 베타가 서빙해야 할 페이지가 없다 — 배치하지 않고 중단한다." >&2
  echo "    (통째 cp 했다면 nginx -t 는 통과하고 베타만 조용히 404 가 됐을 상황이다.)" >&2
  echo "    명시 지정: sudo BETA_DOCROOT=/home/ubuntu/loupit-fe/web bash infra/deploy/deploy-beta.sh" >&2
  exit 1
fi

_staged="$(mktemp)"
trap 'rm -f "${_staged}"' EXIT
# `ACME-NO-REWRITE` 마커가 붙은 줄은 치환에서 제외한다(`b` = 이 줄에 대한 나머지 -e 를 건너뜀).
# 이유: ACME 챌린지 root 는 앱 docroot 와 무관하며 certbot 의 webroot_path 와 **정확히 일치**해야
# 한다. 일괄 치환이 그 줄까지 베타 체크아웃으로 바꿔 놓아 베타 인증서 자동갱신이 조용히 실패했다
# (2026-07-27 세션 C 실측: `certbot renew --dry-run` → beta 만 404. 만료 시 베타가 HTTPS 를 잃는다).
sed -e '/ACME-NO-REWRITE/b' \
    -e "s#${ROOT_DIR}/web#${BETA_DOCROOT}#g" \
    -e "s#${ROOT_DIR}/infra/beta-test#${BETA_CHECKOUT}/infra/beta-test#g" \
    "${ROOT_DIR}/infra/nginx/loupit-beta.conf" > "${_staged}"

# 배치 **전** 검증: nginx 가 읽을 ACME root 와 certbot 이 쓸 webroot_path 가 같은가.
# `nginx -t` 는 이 불일치를 절대 못 잡는다(문법은 유효하고 갱신은 90일 뒤에야 실패한다).
_acme_root="$(awk '/acme-challenge/{f=1} f && $1=="root"{sub(/;$/,"",$2); print $2; exit}' "${_staged}")"
_renewal=/etc/letsencrypt/renewal/beta.loupit.co.conf
if sudo test -f "${_renewal}"; then
  _cb_webroot="$(sudo awk -F'=' '/^[[:space:]]*webroot_path/{split($2,a,","); gsub(/^[[:space:]]+|[[:space:]]+$/,"",a[1]); print a[1]; exit}' "${_renewal}")"
  if [ -n "${_cb_webroot}" ] && [ "${_acme_root}" != "${_cb_webroot}" ]; then
    echo "  ✗ ACME 경로 불일치 — 배치하지 않고 중단한다." >&2
    echo "    nginx 가 읽을 곳 : ${_acme_root}" >&2
    echo "    certbot 이 쓸 곳 : ${_cb_webroot}  (${_renewal})" >&2
    echo "    이대로 두면 베타 인증서 자동갱신이 조용히 실패하고 만료 시 HTTPS 가 끊긴다." >&2
    echo "    확인: loupit-beta.conf 의 ACME root 줄에 'ACME-NO-REWRITE' 마커가 살아 있는가." >&2
    exit 1
  fi
  echo "  · ACME 경로 일치 확인: ${_acme_root}"
else
  echo "  ⚠ ${_renewal} 없음 — ACME 경로 일치 검사 생략(최초 발급 전이면 정상)." >&2
fi

sudo install -o root -g root -m 644 "${_staged}" /etc/nginx/sites-available/loupit-beta.conf
sudo ln -sf /etc/nginx/sites-available/loupit-beta.conf /etc/nginx/sites-enabled/loupit-beta.conf

echo "[4/5] beta systemd 서비스 배치"
sudo cp "${ROOT_DIR}/infra/systemd/loupit-beta-api.service" /etc/systemd/system/loupit-beta-api.service
sudo systemctl daemon-reload
sudo systemctl enable loupit-beta-api.service

echo "[5/5] 검증·적용(nginx -t 통과 시에만 reload/restart)"
if sudo nginx -t; then
  sudo systemctl restart loupit-beta-api.service
  sudo systemctl reload nginx
  echo "  ✓ 베타 스테이징 적용 완료 — https://beta.loupit.co"
else
  # 이 실행이 방금 배치한 beta vhost 심링크가 sites-enabled 에 남으면 이후 모든 nginx -t·
  # reload 가 막힌다(반배포). 프로덕션·공유 스니펫은 건드리지 않고 beta 전용 아티팩트만 롤백.
  echo "  ✗ nginx -t 실패 — 방금 배치한 beta vhost 를 롤백한다(프로덕션 무영향)." >&2
  sudo rm -f /etc/nginx/sites-enabled/loupit-beta.conf /etc/nginx/sites-available/loupit-beta.conf
  if sudo nginx -t; then
    echo "  ✓ 롤백 후 nginx -t 통과 — beta 미적용. 설정 수정 후 재실행하라. 서비스 재시작 안 함." >&2
  else
    echo "  ⚠ 롤백 후에도 nginx -t 실패 — beta 외 기존 설정 문제일 수 있다. 즉시 수동 점검." >&2
  fi
  exit 1
fi
