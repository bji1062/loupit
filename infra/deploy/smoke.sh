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

# ── SC14 메일 경로 회귀 가드(SM-21·SM-22, 2026-07-28 신설. SPEC §11.2) ──
#
# 🚨🚨 **이 두 검사는 메일을 한 통도 보내지 않는다. 아래 규칙을 깨면 릴리스마다 실제 메일이 나간다.** 🚨🚨
#   이메일 필드에 **`@` 가 없는** 문자열을 준다 → pydantic 이 **발송 전에** 422 로 끊는다.
#   ⚠ "잘못된 이메일이면 된다"는 기준은 **틀렸다**. `_EMAIL_RE`(`server/models/member.py:14`
#     = `^[^@\s]+@[^@\s]+\.[^@\s]+$`)가 느슨해서 실측(2026-07-27) 결과가 이렇다:
#         x@example.invalid → 통과 ⚠ 발송 경로 진입(존재하지 않는 TLD 로 하드 바운스)
#         a@b.c             → 통과 ⚠ 발송 경로 진입
#         smoke-no-mail     → 422 ✓ 안전   /   not-a-valid-email → 422 ✓   /   no-mail@ → 422 ✓
#     **`@` 유무가 유일하게 안전한 기준이다.** prod 는 지금 M9 OFF(404)라 우연히 안전할 뿐이고,
#     `M9_ENABLED=1` 을 켜는 순간 이 규칙이 유일한 방어선이 된다.
#   `limit_req` 는 PREACCESS 라 앱보다 **먼저** 판정한다 → M9 ON(422)·OFF(404) 어느 쪽이든
#   429 관측에는 영향이 없다(2026-07-27 prod 실측: 헤더 포함 연타 → 404…404·429).
MAIL_EP="${BASE}/api/v1/members/login-code"
MAIL_BODY='{"email":"smoke-no-mail"}'   # ← `@` 없음. **고치지 마라**(위 주석 참조).

# SM-21: CSRF/Layer A 게이트 — 무헤더 POST 는 앱에 닿기 전 403.
#   `if` 는 REWRITE 페이즈라 PREACCESS 의 limit_req 보다 먼저 돈다 → **토큰을 소비하지 않는다**
#   (그래서 SM-22 앞에 둬도 버킷에 영향이 없다).
chk "SM-21 무헤더 login-code → 403" \
  "[ \"\$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '${MAIL_BODY}' ${MAIL_EP})\" = 403 ]"

# SM-22: 메일 발송 리밋이 살아 있는가 — 헤더 포함 연타 중 429 가 나오는지.
#
#   ⚠ **판정을 "정확히 N번째부터 429"로 하지 않는다** — SPEC §11.2 표의 기대값에서 **의도적으로
#     완화**했다. `loupit_mail` 은 `login-code`·`verify-code`·prod·beta 가 **IP 단위로 공유하는
#     단일 버킷**이라(§3.4.1) 직전 트래픽에 따라 통과 건수가 달라진다. SPEC 자신도 "실행 전 약
#     60초 유휴를 둬라"고 적고 있는데, 그런 전제를 요구하는 릴리스 게이트는 간헐 실패하고
#     **간헐 실패하는 게이트는 곧 무시된다 — 그게 게이트가 없는 것보다 나쁘다.**
#     막으려는 회귀는 "메일 리밋이 사라졌다"이고, 그건 **"연타해도 429가 없다"로 정확히 잡힌다.**
#     (`loupit_api` 는 burst=60 이라 10연타로는 429 가 안 난다 → 429 가 났다면 `loupit_mail` 이다.)
#   통과 건수는 참고로 출력한다 — `burst` 드리프트가 눈에 보이게 하되 실패 사유로는 쓰지 않는다.
#   ⚠ 이 검사는 **러너 IP 의 공유 메일 버킷을 약 2분 비운다**(`rate 3r/m` = 20초당 1토큰 회복).
#     서버 자신의 IP 라 실사용자 영향은 없으나, 직후 이 호스트에서 로그인을 시험하면 429 다.
sm22(){
  _p=0
  for _i in 1 2 3 4 5 6 7 8 9 10; do
    _c=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
         -H 'Content-Type: application/json' -H 'X-Loupit-Client: web' \
         -d "${MAIL_BODY}" "${MAIL_EP}")
    [ "$_c" = 429 ] && { echo "$_p" > "${SMOKE_TMP}/sm22.pass"; return 0; }
    _p=$((_p+1))
  done
  echo "$_p" > "${SMOKE_TMP}/sm22.pass"
  return 1
}
chk "SM-22 메일 리밋 429 도달" "sm22"
echo "       · 통과 $(cat "${SMOKE_TMP}/sm22.pass" 2>/dev/null || echo '?')건 후 429 (정본 기대 6 = 1+burst; 공유 버킷이라 더 적을 수 있음)"

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
