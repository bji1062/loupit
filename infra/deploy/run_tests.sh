#!/usr/bin/env bash
# infra/deploy/run_tests.sh — 전 계층 테스트 집계(로컬 전용, CI 없음). 실패 시 배포 차단.
# 근거: SP-TEST-4.2, TASK/12 T-12.1.1(MT-1). 릴리스 게이트(SP-ARCH-9 4단계)와 개발 사전검증이 동일 스크립트 호출.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$ROOT"

# python 바이너리 해석: venv 우선 → python3 → python (Ubuntu 22.04 기본은 `python3`만 존재,
# SP-INFRA-2.2 패키지 목록에 python-is-python3 없음 — `python` 단독 가정 시 배포 호스트에서 실패).
if [ -x "$ROOT/server/venv/bin/python" ]; then PY="$ROOT/server/venv/bin/python"
elif command -v python3 >/dev/null; then PY="python3"
else PY="python"; fi

echo "[1/5] 백엔드(API·스키마·시드) — pytest (+ loupit_test MySQL)"
"$PY" -m pytest server/tests/ -q

echo "[2/5] 정적 생성물·정책 — pytest (fake 번들)"
"$PY" -m pytest generator/tests/ -q

echo "[3/5] 프론트 순수모듈·계산엔진·광고·디자인토큰·메타 — node:test"
# node ≥21 glob(디렉토리 인자 대신) — node v24는 `node --test web/`를 모듈 로드로 오해. node ≥20 권장.
node --test 'web/**/*.test.js'

echo "[4/5] 테스트 하네스 자체 검증(메타) — 이미 [3]에 포함(web/test/harness.test.js)"

echo "[5/5] Nginx 설정 문법(배포 호스트에서만)"
# loupit.conf는 sites-available 드롭인(server{} 블록만)이라 -c로 단독 로드 불가 —
# events{}/http{}만 감싸는 로컬 검증 전용 래퍼(loupit.test.conf)로 문법을 검사한다(CFG-1).
if command -v nginx >/dev/null; then nginx -t -c "$ROOT/infra/nginx/loupit.test.conf"; else echo "  nginx 미설치 — 스킵(개발 로컬)"; fi

echo "ALL GREEN — 릴리스 게이트 통과"
