#!/usr/bin/env bash
# infra/deploy/stamp_assets.sh — css/js/svg 사전압축(gzip_static용) + index/compare HTML의 ?v= 스탬프.
# 근거: docs/SPEC/11-인프라-배포.md SP-INFRA-9.3. 무빌드(AS3)이므로 번들 해시가 없어 파일 내용
# sha8을 HTML 참조의 `?v=` 쿼리에 주입한다(1년 immutable 캐시 안전). `?v=PLACEHOLDER` 참조
# 규약 자체는 SP-FE 소유(위임) — 본 스크립트는 값 주입만 담당, 중복 구현 없음.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}/web"

# 1) gzip 사전압축(원본보다 크면 스킵 판단은 nginx gzip_static이 함; -k 원본 유지)
find assets -type f \( -name '*.css' -o -name '*.js' -o -name '*.svg' \) -print0 \
  | xargs -0 -I{} gzip -9kf "{}"

# 2) 각 참조 자산 sha8 → HTML ?v= 주입 (index.html, compare/index.html)
stamp() {   # $1=자산 상대경로(web기준)  $2=베이스네임 정규식
  local h; h="$(sha1sum "$1" | cut -c1-8)"
  sed -i -E "s|($2\?v=)[A-Za-z0-9]+|\1${h}|g" index.html compare/index.html
}
stamp assets/css/styles.css 'styles\.css'
for f in assets/js/*.js; do stamp "$f" "$(basename "$f" | sed 's/\./\\./g')"; done

# 3) PLACEHOLDER 잔존 가드(주입 실패 시 즉시 실패 — SP-INFRA-9.3)
if grep -Rq '?v=PLACEHOLDER' index.html compare/index.html; then
  echo "자산 버전 주입 실패: PLACEHOLDER 잔존" >&2; exit 1
fi
echo "assets stamped"
