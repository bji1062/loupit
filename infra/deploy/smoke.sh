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
chk "SM-5 company static"   "[ \"\$(code ${BASE}/company/${SAMPLE_SLUG:-samsung-elec})\" = 200 ]"  # SAMPLE_SLUG로 실 slug 지정(기본값은 실재 slug)
chk "SM-7 http2"            "curl -sI --http2 ${BASE}/ | grep -qi '^HTTP/2 200'"
chk "SM-8 hsts"             "curl -sI ${BASE}/ | grep -qi 'strict-transport-security: max-age=15768000; includesubdomains'"
# SM-9: 반드시 200과 gzip을 함께 검사한다 — 404 폴백(/404.html)도 gzip으로 나와서
# 경로 검사를 빼면 자산 404가 통과해 버린다(2026-07-19 설계 반증에서 발견된 false-pass).
# 대상은 v2 세대 경로(자산 캐시버스팅 — nginx alias /assets/v2/ → web/assets/, 런타임 gzip).
chk "SM-9 asset gzip(runtime)" "curl -s -o /dev/null -H 'Accept-Encoding: gzip' -w '%{http_code} %{content_type}' -D /tmp/loupit-sm9.h ${BASE}/assets/v2/js/app.js | grep -q '^200 ' && grep -qi 'content-encoding: gzip' /tmp/loupit-sm9.h"

# ── 자산 v2 세대 검증(SM-15, 2026-07-19 캐시버스팅) ──
# v2 자산이 200 + no-cache(재검증 캐시)로 서빙되는지 — nginx conf 미배치·alias 오타는
# 문법검사(-t)로 안 잡히므로 스모크가 유일한 라이브 검증선이다.
chk "SM-15a v2 css 200+no-cache"  "curl -sI ${BASE}/assets/v2/css/styles.css | tee /tmp/loupit-sm15a.h | grep -q '^HTTP.* 200' && grep -qi 'cache-control: no-cache' /tmp/loupit-sm15a.h"
chk "SM-15b v2 json 200+no-cache" "curl -sI ${BASE}/assets/v2/data/affiliate.json | tee /tmp/loupit-sm15b.h | grep -q '^HTTP.* 200' && grep -qi 'cache-control: no-cache' /tmp/loupit-sm15b.h"
chk "SM-15c 구경로 no-cache 강등"  "curl -sI ${BASE}/assets/js/app.js | tee /tmp/loupit-sm15c.h | grep -q '^HTTP.* 200' && grep -qi 'cache-control: no-cache' /tmp/loupit-sm15c.h"
chk "SM-15d HTML의 v2 참조"       "curl -s ${BASE}/compare/ | grep -q '/assets/v2/js/app.js'"

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
