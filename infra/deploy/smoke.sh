#!/usr/bin/env bash
# infra/deploy/smoke.sh — SP-INFRA-11.2 라이브 스모크(SM-1~14). 실패 시 비0 종료(릴리스 게이트).
# 근거: docs/SPEC/11-인프라-배포.md SP-INFRA-11.2·11.3, SP-ARCH-10 T7·T8.
# 전제: 로컬/배포 전체 스택(nginx+uvicorn+mysql) 기동 상태 — release.sh 7단계에서 호출(재시작·reload 이후).
# BASE=https://jobcho.wiki(기본, 배포) 또는 BASE=http://127.0.0.1(로컬 스택 검증) 환경변수로 오버라이드.
set -uo pipefail
BASE="${BASE:-https://jobcho.wiki}"
fail=0
# 헤더 덤프용 임시 디렉터리 — 고정 /tmp 파일명은 sticky-bit /tmp에서 타 사용자 잔존 파일을
# 못 덮어 영구 false-FAIL을 만들고(sudo↔일반 교차 실행), `curl | tee | grep -q`는 pipefail
# 아래 SIGPIPE 플레이크 창이 있다 — mktemp + 파이프 분해로 회피(2026-07-19 검수).
SMOKE_TMP="$(mktemp -d)"; trap 'rm -rf "${SMOKE_TMP}"' EXIT

chk(){ # $1=이름 $2=조건(0/1 반환 명령)
  if eval "$2" >/dev/null 2>&1; then echo "  OK  $1"; else echo "  FAIL $1" >&2; fail=1; fi
}
code(){ curl -s -o /dev/null -w '%{http_code}' "$1"; }

# ── 기본 라우팅(SM-1·2·3·6·13) ──
chk "SM-1 landing 200"      "[ \"\$(code ${BASE}/)\" = 200 ]"
chk "SM-2 http->https 301"  "[ \"\$(curl -s -o /dev/null -w '%{http_code}' http://jobcho.wiki/)\" = 301 ]"
# SM-3: release.sh가 [5/7] API 재시작 직후 스모크를 호출하므로 uvicorn 기동 창(1~2초)을
# 흡수하는 유한 재시도(최대 10회×1초) — 무한 대기 아님, 10초 내 미기동이면 실패가 맞다.
# (chk의 eval은 현재 셸에서 돌므로 exit 금지 — 플래그+최종 [ ] 판정으로 실패를 전달한다.)
chk "SM-3 health ok"        "_ok=0; for _i in 1 2 3 4 5 6 7 8 9 10; do curl -s ${BASE}/api/v1/health | grep -q '\"status\":\"ok\"' && { _ok=1; break; }; sleep 1; done; [ \"\$_ok\" = 1 ]"
chk "SM-6 privacy 200"      "[ \"\$(code ${BASE}/privacy)\" = 200 ]"
chk "SM-13 404"             "[ \"\$(code ${BASE}/nonexistent-xyz)\" = 404 ]"

# ── 전송·보안 헤더 + 확장(SM-4·5·7·8·9) ──
# SM-4: HEAD로 참조 엔드포인트의 Cache-Control을 검사한다. L-1(2026-07-13, GET 라우트는
# HEAD도 수락 — api_route methods=["GET","HEAD"]) 반영 후 HEAD가 200 + 동일 헤더를 반환하므로,
# f9459f9의 GET-헤더덤프 우회(HEAD→405 회피)는 더 이상 불필요하다. HEAD는 본문을 안 받아 더 가볍다.
chk "SM-4 ref cache-header" "curl -sI -H 'X-Loupit-Client: web' ${BASE}/api/v1/reference/all | grep -qi 'cache-control: public, max-age=3600'"

# SM-16: reference/all의 **본문 무결성**. SM-4는 HEAD로 헤더만 보므로 본문이 잘려도 통과한다 —
# 2026-07-20 실장애가 정확히 그 사각지대였다. nginx가 약 600KB 응답을 proxy_buffers에 못 담아
# /var/lib/nginx/proxy/ 임시파일로 흘리는데 권한이 어긋나면 open()이 EACCES로 실패하고 응답이
# 조용히 잘렸다(Content-Length는 이미 전체 길이로 나간 뒤). 절단률 약 40%, 사용자에겐
# "비교 도구를 불러오지 못했습니다"로 보였고 어떤 스모크도 이를 잡지 못했다.
# 간헐 실패라 1회 검사로는 놓친다 → 5회 연속 전부 완전한 JSON이어야 통과.
chk "SM-16 ref body intact(5x)" "for _i in 1 2 3 4 5; do curl -s -H 'X-Loupit-Client: web' ${BASE}/api/v1/reference/all -o ${SMOKE_TMP}/ref.json || exit 1; python3 -c \"
import json,sys
d=json.load(open('${SMOKE_TMP}/ref.json'))
assert isinstance(d.get('companies'),list) and len(d['companies'])>0, 'companies 비었음'
assert isinstance(d.get('company_types'),list), 'company_types 없음'
assert isinstance(d.get('benefit_presets'),dict), 'benefit_presets 없음'
\" || exit 1; done"

# ── 스크래핑 방어 회귀 가드(2026-07-21) ──
# SM-17: Layer A — 사이트 헤더 없는 맨 curl은 reference/all에서 403(벌크 덤프 차단).
#   ⚠ 이게 200이면 "1회 호출 = 600KB 전체"가 다시 열린 것. SM-4·16은 헤더를 보내니 별개.
chk "SM-17 A: 무헤더 ref → 403" "[ \"\$(code ${BASE}/api/v1/reference/all)\" = 403 ]"
# SM-18: Layer B — 악성 봇 UA는 정적 페이지에서도 403.
chk "SM-18 B: 봇UA landing → 403" "[ \"\$(curl -s -o /dev/null -w '%{http_code}' -A 'python-requests/2.31' ${BASE}/)\" = 403 ]"
# SM-19: 화이트리스트 — Googlebot·AdSense 크롤러는 절대 차단 금지(SEO/수익 생명줄).
chk "SM-19 googlebot 허용(≠403)" "[ \"\$(curl -s -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' ${BASE}/)\" != 403 ]"
chk "SM-19b AdSense 크롤러 허용" "[ \"\$(curl -s -o /dev/null -w '%{http_code}' -A 'Mediapartners-Google' ${BASE}/)\" != 403 ]"
# SM-20: health는 Layer A 예외(무헤더 curl로도 200) — 모니터링 생존.
chk "SM-20 health 무헤더 200" "curl -s ${BASE}/api/v1/health | grep -q '\"status\":\"ok\"'"

chk "SM-5 company static"   "[ \"\$(code ${BASE}/company/${SAMPLE_SLUG:-samsung-elec})\" = 200 ]"  # SAMPLE_SLUG로 실 slug 지정(기본값은 실재 slug)
chk "SM-7 http2"            "curl -sI --http2 ${BASE}/ | grep -qi '^HTTP/2 200'"
chk "SM-8 hsts"             "curl -sI ${BASE}/ | grep -qi 'strict-transport-security: max-age=15768000; includesubdomains'"
# SM-9: 반드시 200과 gzip을 함께 검사한다 — 404 폴백(/404.html)도 gzip으로 나와서
# 경로 검사를 빼면 자산 404가 통과해 버린다(2026-07-19 설계 반증에서 발견된 false-pass).
# 대상은 v2 세대 경로(자산 캐시버스팅 — nginx alias /assets/v2/ → web/assets/, 런타임 gzip).
chk "SM-9 asset gzip(runtime)" "curl -s -o /dev/null -H 'Accept-Encoding: gzip' -D ${SMOKE_TMP}/sm9.h ${BASE}/assets/v2/js/app.js && grep -q '^HTTP.* 200' ${SMOKE_TMP}/sm9.h && grep -qi 'content-encoding: gzip' ${SMOKE_TMP}/sm9.h"

# ── 자산 v2 세대 검증(SM-15, 2026-07-19 캐시버스팅) ──
# v2 자산이 200 + no-cache(재검증 캐시)로 서빙되는지 — nginx conf 미배치·alias 오타는
# 문법검사(-t)로 안 잡히므로 스모크가 유일한 라이브 검증선이다.
sm15(){ # $1=파일명 $2=URL — 헤더를 파일로 받아 200 + no-cache 를 파이프 없이 판정
  curl -s -o /dev/null -D "${SMOKE_TMP}/$1" "$2" && grep -q '^HTTP.* 200' "${SMOKE_TMP}/$1" && grep -qi 'cache-control: no-cache' "${SMOKE_TMP}/$1"
}
chk "SM-15a v2 css 200+no-cache"  "sm15 a.h ${BASE}/assets/v2/css/styles.css"
chk "SM-15b v2 json 200+no-cache" "sm15 b.h ${BASE}/assets/v2/data/affiliate.json"
chk "SM-15c 구경로 no-cache 강등"  "sm15 c.h ${BASE}/assets/js/app.js"
chk "SM-15d HTML의 v2 참조"       "curl -s ${BASE}/compare/ | grep -q '/assets/v2/js/app.js'"
chk "SM-15e v2 font 200+no-cache" "sm15 e.h ${BASE}/assets/v2/fonts/PretendardVariable.woff2"

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
