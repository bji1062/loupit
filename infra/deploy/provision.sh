#!/usr/bin/env bash
# infra/deploy/provision.sh — SP-INFRA-2 1회 프로비저닝(패키지·계정·디렉토리·certbot/방화벽 부트스트랩).
# 전제: Ubuntu Server 22.04 LTS (aarch64, Oracle Ampere A1, SP-INFRA-2.1). root/sudo로 1회 실행.
# 근거: docs/SPEC/11-인프라-배포.md SP-INFRA-2, SP-ARCH-7(버전 pin).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_USER="ubuntu"

echo "[1/6] apt 패키지 설치 (SP-INFRA-2.2)"
sudo apt-get update -y
sudo apt-get install -y \
  nginx `# >=1.24, 엣지·정적·프록시` \
  mysql-server `# 8.0.x, 참조 DB` \
  python3 python3-venv python3-pip `# 3.11.x(최소 3.10), 앱·생성기·시드 런타임` \
  certbot python3-certbot-nginx `# Let's Encrypt` \
  git curl openssl gzip \
  nftables \
  unattended-upgrades
# Node.js(>=18 LTS)는 개발/CI 전용(node --test) — 프로덕션 산출물엔 미포함(무빌드, SP-ARCH-7).

echo "[2/6] python venv (SP-ARCH-7)"
python3 -m venv "${ROOT_DIR}/server/venv"
"${ROOT_DIR}/server/venv/bin/pip" install --upgrade pip
if [ -f "${ROOT_DIR}/server/requirements.txt" ]; then
  "${ROOT_DIR}/server/venv/bin/pip" install -r "${ROOT_DIR}/server/requirements.txt"
fi
if [ -f "${ROOT_DIR}/generator/requirements.txt" ]; then
  "${ROOT_DIR}/server/venv/bin/pip" install -r "${ROOT_DIR}/generator/requirements.txt"
fi

echo "[3/6] 디렉토리·소유권·권한 (SP-INFRA-2.3)"
sudo mkdir -p "${ROOT_DIR}/web/dist" /var/backups/loupit
sudo chown -R "${APP_USER}:${APP_USER}" "${ROOT_DIR}"
sudo chmod 755 "${ROOT_DIR}" "${ROOT_DIR}/web" "${ROOT_DIR}/web/dist" "${ROOT_DIR}/server/venv"
sudo chown "${APP_USER}:${APP_USER}" /var/backups/loupit
sudo chmod 750 /var/backups/loupit
# 백업 2차 사본(미러). `/db` 는 별도 블록 디바이스라 루트 디스크 장애와 함께 죽지 않는다.
# 전용 하위 디렉터리를 쓴다 — 미러 로테이션이 `loupit-*.sql.gz` 를 글롭으로 지우므로
# 다른 덤프가 섞인 `/db/backups` 직하를 가리키면 그것까지 삭제된다(docs/OPS-backup.md §1-1b).
# `/db` 미마운트 환경(로컬 검증 등)에서는 건너뛴다 — 미러는 선택 기능이다.
if [ -d /db ]; then
  sudo install -d -o "${APP_USER}" -g "${APP_USER}" -m 750 /db/backups/loupit
fi
# Nginx(www-data)가 /home/ubuntu/loupit/web을 읽으려면 상위 디렉토리 탐색권한 필요
sudo chmod 711 /home/ubuntu || true
# 프록시 임시버퍼 디렉터리는 반드시 워커 사용자(www-data) 소유여야 한다.
# 소유가 어긋나면 큰 업스트림 응답(reference/all 약 600KB)을 임시파일로 흘리는 순간
# open()이 EACCES로 실패하고 **응답이 조용히 잘린다** — 5xx가 아니라 200 + 절단 본문이라
# 로그를 안 보면 원인 파악이 어렵다(2026-07-20 실장애, 절단률 약 40%).
# loupit.conf의 proxy_buffers 상향으로 이 경로를 애초에 안 타게 해뒀지만, 다른 업스트림
# 응답이 커질 수 있으므로 소유권도 함께 보장한다(이중 방어).
sudo mkdir -p /var/lib/nginx/proxy
sudo chown -R www-data:www-data /var/lib/nginx/proxy
sudo chmod 700 /var/lib/nginx/proxy

echo "[4/6] infra/ 산출물 배치"
sudo mkdir -p /etc/nginx/snippets /etc/nginx/conf.d
# ── http 컨텍스트 산출물(conf.d) — sites-enabled 보다 **먼저** 배치·로드돼야 한다 ──
# 2026-07-27 발견(적대검토, 3개 렌즈 수렴): 이 두 파일을 배치하는 스크립트가 리포에 **하나도
# 없었다**. loupit.conf 는 `limit_req zone=loupit_api|loupit_log|loupit_mail` 과 서버 레벨
# `if ($loupit_bad_bot)` 로 둘 다에 하드 의존하는데, 존·맵은 http 컨텍스트 전용이라
# server{} 안에 둘 수 없어 이 파일들에만 있다. 즉 신규 호스트를 리포만으로 프로비저닝하면
# "unknown limit_req zone" / "unknown variable" 로 **nginx -t 가 실패해 nginx 가 아예 뜨지
# 못했다**(수동 배치로 가려져 있던 잠복 결함 — 실호스트는 사람이 손으로 복사해 둔 상태였다).
# nginx.conf 의 http{} 는 conf.d/*.conf 를 sites-enabled/* 보다 먼저 include 하므로,
# 여기서 배치해 두면 정의가 사용보다 앞선다(순서 보장).
sudo cp "${ROOT_DIR}/infra/nginx/loupit-limits.conf"     /etc/nginx/conf.d/loupit-limits.conf
sudo cp "${ROOT_DIR}/infra/nginx/loupit-botdefense.conf" /etc/nginx/conf.d/loupit-botdefense.conf
sudo chmod 644 /etc/nginx/conf.d/loupit-limits.conf /etc/nginx/conf.d/loupit-botdefense.conf
sudo cp "${ROOT_DIR}/infra/nginx/loupit.conf" /etc/nginx/sites-available/loupit.conf
sudo cp "${ROOT_DIR}/infra/nginx/snippets/loupit-security.conf" /etc/nginx/snippets/loupit-security.conf
sudo ln -sf /etc/nginx/sites-available/loupit.conf /etc/nginx/sites-enabled/loupit.conf
sudo cp "${ROOT_DIR}/infra/systemd/loupit-api.service" /etc/systemd/system/loupit-api.service
sudo cp "${ROOT_DIR}/infra/systemd/loupit-backup.service" /etc/systemd/system/loupit-backup.service
sudo cp "${ROOT_DIR}/infra/systemd/loupit-backup.timer" /etc/systemd/system/loupit-backup.timer
# MySQL 설정: apt 설치 경로만 /etc/mysql/mysql.conf.d 를 읽는다. 이 호스트처럼 tarball 설치
# (/data/mysql, /etc/my.cnf 만 읽음)면 디렉토리가 없어 cp 가 set -e 로 전체 abort 하므로 스킵·경고.
if [ -d /etc/mysql/mysql.conf.d ]; then
  sudo cp "${ROOT_DIR}/infra/mysql/loupit.cnf" /etc/mysql/mysql.conf.d/loupit.cnf
else
  echo "  ⚠ /etc/mysql/mysql.conf.d 부재(tarball 설치 추정) — loupit.cnf 복사 스킵."
  echo "    실호스트는 /etc/my.cnf 만 읽으므로 infra/mysql/loupit.cnf 항목을 수동 반영할 것."
fi
sudo cp "${ROOT_DIR}/infra/deploy/sshd-hardening.conf" /etc/ssh/sshd_config.d/loupit.conf
sudo systemctl daemon-reload
# 백업 타이머 가동(일 1회 03:00). 전제: /var/backups/loupit 는 [3/6]에서 생성·chown 완료 +
# infra/env/backup.env(크레덴셜)가 이미 존재해야 첫 실행이 성공한다(docs/OPS-backup.md 설치 순서 참고).
sudo systemctl enable --now loupit-backup.timer

echo "[5/6] certbot·방화벽 부트스트랩 호출 (SP-INFRA-4·8, 별도 스크립트)"
echo "  최초 인증서 발급은 :80이 활성화된 뒤 수동 실행: infra/deploy 문서(SP-INFRA-4.1) 참고"
bash "${ROOT_DIR}/infra/deploy/firewall.sh" || echo "  firewall.sh 수동 검토 필요(방화벽 정책은 신중히 적용)"
sudo sshd -t

echo "[6/6] 버전 확인(수동 pin 대조, SP-ARCH-7) — CFG 케이스 없음"
nginx -v || true
mysql --version || true
python3 --version || true

echo "PROVISION SCRIPT READY (실제 적용은 각 단계를 검토 후 수동/CI로 실행 권장)"
