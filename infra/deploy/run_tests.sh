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

# ── C-1 안전장치(2026-07-12): 이 서버는 서빙 스키마 LOUPIT 를 테스트에도 재사용한다.
# 백엔드 테스트는 5개 참조 테이블을 DROP/CREATE 하므로, 종료 시 서빙 데이터를 재시드해
# beta/프로덕션 API 가 500/빈응답으로 남지 않게 한다. trap 으로 실패·중단(set -e) 시에도
# 재시드를 '시도'한다.
#
# ⚠ 비원자성(L-7, 2026-07-13): load.py --fresh 는 DROP TABLE(DDL) 을 쓰는데 MySQL 에서
# DDL 은 암묵 커밋이라 load.py 의 autocommit=False·try/rollback 이 이 구간엔 무력하다.
# 즉 DROP~재시드 완료 사이에 프로세스가 죽으면 서빙이 빈 채로 남을 수 있다 — 원자 '보장'
# 이 아니라 '시도'다. 그래서 재시드 후 COUNT 로 서빙 적재를 검증하고, 실패하면 조용히
# 넘기지 않고 크게 경고 + 수동 복구 명령을 출력한다. (진짜 원자 스왑이 필요하면 임시테이블
# +RENAME TABLE 로 load.py 를 전환해야 하며, 95개 시드 SQL·백필의 테이블명 하드코딩 때문에
# 범위가 커 별도 작업으로 남긴다.)
# LOUPIT_ALLOW_SERVING_SCHEMA=1 이 conftest 가드에 "복원 책임을 지는 래퍼"임을 신호한다
# (맨 pytest 직접 실행은 이 신호가 없어 차단됨).
export LOUPIT_ALLOW_SERVING_SCHEMA=1
_restore_done=0
_restore_fail_msg() {
  echo "  ⚠⚠⚠ [restore] 서빙(LOUPIT) 복원 실패 — 비었거나 깨진 상태일 수 있다. 즉시 수동 복구:" >&2
  echo "        python3 db/seed/load.py --fresh && sudo systemctl restart loupit-beta-api" >&2
}
restore_serving() {
  [ "$_restore_done" = 1 ] && return 0
  echo "  [restore] 서빙 스키마(LOUPIT) 재시드 시도(비원자) — load.py --fresh"
  if ! "$PY" "$ROOT/db/seed/load.py" --fresh; then _restore_fail_msg; return 1; fi
  # 비원자 재시드라 정상 종료여도 서빙 적재를 한 번 더 검증(회사 하한 90; 정상은 95).
  if ! LOUPIT_ROOT="$ROOT" "$PY" -c "import os,sys; sys.path.insert(0, os.path.join(os.environ['LOUPIT_ROOT'],'db','seed')); import load; c=load.connect(); cur=c.cursor(); cur.execute('SELECT COUNT(*) FROM TCOMPANY'); n=cur.fetchone()[0]; print('  [restore] 검증: TCOMPANY=%d'%n); sys.exit(0 if n>=90 else 2)"; then
    _restore_fail_msg; return 1
  fi
  _restore_done=1
  echo "  [restore] OK — 서빙 검증 통과"
}
trap restore_serving EXIT

echo "[1/5] 백엔드(API·스키마·시드) — pytest (LOUPIT, 종료 후 자동 재시드)"
"$PY" -m pytest server/tests/ -q
restore_serving   # 백엔드 테스트 직후 즉시 복원 → 서빙 다운타임 최소화(이후 단계는 DB 무접촉)

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
