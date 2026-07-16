#!/usr/bin/env bash
# infra/deploy/smoke.sh — SP-INFRA-11.2 라이브 스모크(SM-1~14). 실패 시 비0 종료(릴리스 게이트).
# 근거: docs/SPEC/11-인프라-배포.md SP-INFRA-11.2·11.3, SP-ARCH-10 T7·T8.
# 전제: 로컬/배포 전체 스택(nginx+uvicorn+mysql) 기동 상태 — release.sh 7단계에서 호출(재시작·reload 이후).
# BASE=https://jobcho.wiki(기본, 배포) 또는 BASE=http://127.0.0.1(로컬 스택 검증) 환경변수로 오버라이드.
set -uo pipefail
BASE="${BASE:-https://jobcho.wiki}"
fail=0

chk(){ # $1=이름 $2=조건(0/1 반환 명령)
  if eval "$2" >/dev/null 2>&1; then echo "  OK  $1"; else echo "  FAIL $1" >&2; fail=1; fi
}
code(){ curl -s -o /dev/null -w '%{http_code}' "$1"; }

# ── 기본 라우팅(SM-1·2·3·6·13) ──
chk "SM-1 landing 200"      "[ \"\$(code ${BASE}/)\" = 200 ]"
chk "SM-2 http->https 301"  "[ \"\$(curl -s -o /dev/null -w '%{http_code}' http://jobcho.wiki/)\" = 301 ]"
chk "SM-3 health ok"        "curl -s ${BASE}/api/v1/health | grep -q '\"status\":\"ok\"'"
chk "SM-6 privacy 200"      "[ \"\$(code ${BASE}/privacy)\" = 200 ]"
chk "SM-13 404"             "[ \"\$(code ${BASE}/nonexistent-xyz)\" = 404 ]"

# ── 전송·보안 헤더 + 확장(SM-4·5·7·8·9) ──
# SM-4: HEAD로 참조 엔드포인트의 Cache-Control을 검사한다. L-1(2026-07-13, GET 라우트는
# HEAD도 수락 — api_route methods=["GET","HEAD"]) 반영 후 HEAD가 200 + 동일 헤더를 반환하므로,
# f9459f9의 GET-헤더덤프 우회(HEAD→405 회피)는 더 이상 불필요하다. HEAD는 본문을 안 받아 더 가볍다.
chk "SM-4 ref cache-header" "curl -sI ${BASE}/api/v1/reference/all | grep -qi 'cache-control: public, max-age=3600'"
chk "SM-5 company static"   "[ \"\$(code ${BASE}/company/${SAMPLE_SLUG:-samsung_elec})\" = 200 ]"  # SAMPLE_SLUG로 실 slug 지정(기본값은 예시)
chk "SM-7 http2"            "curl -sI --http2 ${BASE}/ | grep -qi '^HTTP/2 200'"
chk "SM-8 hsts"             "curl -sI ${BASE}/ | grep -qi 'strict-transport-security: max-age=15768000; includesubdomains'"
chk "SM-9 gzip_static"      "curl -sI -H 'Accept-Encoding: gzip' ${BASE}/assets/js/app.js | grep -qi 'content-encoding: gzip'"

# ── TLS 유효성(SM-10) ──
chk "SM-10 tls valid" "echo | openssl s_client -connect jobcho.wiki:443 -servername jobcho.wiki 2>/dev/null | openssl x509 -noout -checkend 0"

# ── SM-11·SM-12(MySQL/uvicorn 외부차단)은 반드시 '외부 호스트'에서 실행해야 의미가 있다
#    (로컬/loopback에서는 항상 열려 보여 오탐). 배포 호스트 자체에서는 스킵하고 안내만 출력.
echo "  SKIP SM-11 mysql-external-block (외부 호스트에서 실행: nc -vz <PUBLIC_IP> 3306 → 실패 기대)"
echo "  SKIP SM-12 uvicorn-external-block (외부 호스트에서 실행: nc -vz <PUBLIC_IP> 8000 → 실패 기대)"

# ── SM-14(자동재시작)는 파괴적(uvicorn kill)이라 기본 미실행 — RUN_SM14=1로 명시 옵트인 ──
if [ "${RUN_SM14:-0}" = "1" ]; then
  chk "SM-14 auto-restart" "sudo pkill -f 'uvicorn server.main'; sleep 7; curl -s ${BASE}/api/v1/health | grep -q '\"status\":\"ok\"'"
else
  echo "  SKIP SM-14 auto-restart (파괴적 — RUN_SM14=1로 옵트인)"
fi

[ "$fail" = 0 ] && echo "SMOKE PASS" || { echo "SMOKE FAIL" >&2; exit 1; }
