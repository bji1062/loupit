#!/usr/bin/env bash
# infra/deploy/reload-nginx.sh — SP-INFRA-4.2 certbot deploy-hook(갱신 후 nginx reload).
# 배포: sudo cp infra/deploy/reload-nginx.sh /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
#       sudo chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
# certbot이 인증서 갱신 성공 시 자동 호출(하루 2회 certbot.timer, 만료 30일 이내만 실갱신).
set -e
/usr/bin/nginx -t && /bin/systemctl reload nginx
