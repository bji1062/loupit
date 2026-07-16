#!/usr/bin/env bash
# infra/deploy/deploy-beta.sh — beta.jobcho.wiki 무중단 스테이징 산출물 배치(리포 → /etc).
#
# 목적: 프로덕션 provision.sh([4/6])가 프로덕션 산출물만 배치하므로, 베타 스테이징
#       (loupit-beta.conf·보안 스니펫 2종·loupit-beta-api.service)을 리포만으로
#       재구축할 수 있게 한다. 산출물은 전부 git에 커밋돼 있어야 한다(B-1 결함 수정).
#
# 전제:
#   - server/.env.beta 존재(gitignore — 새 환경에선 수동 생성; APP_LOUPIT/포트 8001 등).
#   - /etc/letsencrypt/live/beta.jobcho.wiki/{fullchain,privkey}.pem 존재
#     (최초 발급: sudo certbot --nginx -d beta.jobcho.wiki, :80 활성 상태에서 1회).
#   - 시스템 python3에 fastapi/uvicorn/pymysql 설치(베타는 venv 미프로비저닝).
#
# 사용: sudo bash infra/deploy/deploy-beta.sh   (각 단계 검토 후 실행 권장)
# 근거: docs/RESUME.md §A·§B-1.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[1/5] 전제조건 점검"
if [ ! -f "${ROOT_DIR}/server/.env.beta" ]; then
  echo "  ✗ server/.env.beta 없음 — 베타 API 환경파일을 먼저 생성하라(gitignore)." >&2
  exit 1
fi
if [ ! -f /etc/letsencrypt/live/beta.jobcho.wiki/fullchain.pem ]; then
  echo "  ⚠ beta.jobcho.wiki 인증서 없음 — certbot 최초 발급 필요(위 헤더 참고)." >&2
  echo "    인증서 없이도 nginx -t는 실패하므로, 발급 후 재실행하라." >&2
fi

echo "[2/5] nginx 보안 스니펫 배치(base + beta noindex)"
sudo mkdir -p /etc/nginx/snippets
sudo cp "${ROOT_DIR}/infra/nginx/snippets/loupit-security.conf"      /etc/nginx/snippets/loupit-security.conf
sudo cp "${ROOT_DIR}/infra/nginx/snippets/loupit-beta-security.conf" /etc/nginx/snippets/loupit-beta-security.conf
sudo chmod 644 /etc/nginx/snippets/loupit-security.conf /etc/nginx/snippets/loupit-beta-security.conf

echo "[3/5] beta vhost 배치·활성화"
sudo cp "${ROOT_DIR}/infra/nginx/loupit-beta.conf" /etc/nginx/sites-available/loupit-beta.conf
sudo ln -sf /etc/nginx/sites-available/loupit-beta.conf /etc/nginx/sites-enabled/loupit-beta.conf

echo "[4/5] beta systemd 서비스 배치"
sudo cp "${ROOT_DIR}/infra/systemd/loupit-beta-api.service" /etc/systemd/system/loupit-beta-api.service
sudo systemctl daemon-reload
sudo systemctl enable loupit-beta-api.service

echo "[5/5] 검증·적용(nginx -t 통과 시에만 reload/restart)"
if sudo nginx -t; then
  sudo systemctl restart loupit-beta-api.service
  sudo systemctl reload nginx
  echo "  ✓ 베타 스테이징 적용 완료 — https://beta.jobcho.wiki"
else
  echo "  ✗ nginx -t 실패 — 설정 검토 후 수동 reload. 서비스는 재시작하지 않았다." >&2
  exit 1
fi
