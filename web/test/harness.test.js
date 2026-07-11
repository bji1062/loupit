// web/test/harness.test.js — SP-TEST 메타 검증(MT-1~4). 근거: SP-TEST-10, TASK/12 T-12.1.1·T-12.2.1~3(Tier0).
// 전 케이스 부수효과 없이 소스/파일시스템 정적 파싱만 사용 — 러너·DB·서버 불요.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const runTests = readFileSync(join(ROOT, 'infra', 'deploy', 'run_tests.sh'), 'utf8');

test('MT-1: run_tests.sh — 4 서브스위트 호출 + set -euo pipefail', () => {
  assert.match(runTests, /set -euo pipefail/, 'set -euo pipefail 누락(실패 전파)');
  assert.match(runTests, /pytest server\/tests/, 'pytest server/tests 호출 누락');
  assert.match(runTests, /pytest generator\/tests/, 'pytest generator/tests 호출 누락');
  assert.match(runTests, /node --test\s+['"]?web/, 'node --test web 호출 누락');
  assert.match(runTests, /nginx -t/, 'nginx -t 호출 누락');
});

// ── MT-2: 필수 테스트 파일 존재·명명 규약 린트 (SP-TEST-3, TASK/12 T-12.2.1, Tier0) ──
// 각 도메인 SP-* 스위트가 실제 랜딩했는지 파일 존재로 간접 강제(케이스 본문은 각 도메인 위임 — 중복 정의 없음).
test('MT-2: 필수 테스트 파일 존재·명명 규약 린트', () => {
  const required = [
    'server/tests/test_surface.py',
    'server/tests/test_health.py',
    'server/tests/test_reference.py',
    'server/tests/test_search.py',
    'server/tests/test_company_detail.py',
    'server/tests/test_schema_load.py',
    'server/tests/test_constraints.py',
    'server/tests/test_data_contract.py',
    'server/tests/test_seed_counts.py',
    'server/tests/test_seed_integrity.py',
    'server/tests/test_seed_badge_backfill.py',
    'server/tests/test_seed_idempotency.py',
    'generator/tests/test_policy_content.py',
    'generator/tests/test_policy_pages.py',
    'generator/tests/test_footer_links.py',
    'web/assets/js/calc.test.js',
  ];
  const missing = required.filter((rel) => !existsSync(join(ROOT, ...rel.split('/'))));
  assert.deepEqual(missing, [], `누락된 필수 테스트 파일: ${missing.join(', ')}`);
});

// ── MT-3: release.sh 게이트 차단 배선·early-exit 린트 (SP-TEST-8·10, TASK/12 T-12.2.2, Tier0) ──
// release.sh 실구현은 SP-INFRA 소유(위임) — 본 케이스는 배선(테스트 게이트 호출 + non-zero 시
// 후속 재시작/reload 미실행) 회귀만 소스 파싱으로 검증한다.
test('MT-3: release.sh — 테스트 게이트 호출 + non-zero 시 재시작/reload early-exit 배선', () => {
  const releasePath = join(ROOT, 'infra', 'deploy', 'release.sh');
  assert.ok(existsSync(releasePath), 'infra/deploy/release.sh 부재');
  const release = readFileSync(releasePath, 'utf8');

  assert.match(release, /set -euo pipefail/, 'set -euo pipefail 누락 — non-zero 실패가 전파되지 않으면 early-exit 보장 안 됨');
  assert.match(release, /run_tests\.sh|pytest\s+server\/tests|node --test/, '테스트 게이트(run_tests.sh 또는 동등 pytest/node) 호출 누락');
  assert.match(release, /systemctl restart/, 'systemctl restart(API 재시작) 호출 누락');
  assert.match(release, /systemctl reload/, 'systemctl reload(nginx) 호출 누락');

  // early-exit 배선: 테스트 게이트 호출이 재시작·reload 호출보다 소스상 먼저 등장해야
  // set -e 전파 시 재시작·reload가 실행되지 않는다(선형 bash 스크립트 = 텍스트 순서 = 실행 순서).
  const gateIdx = release.search(/run_tests\.sh/);
  const restartIdx = release.search(/systemctl restart/);
  const reloadIdx = release.search(/systemctl reload/);
  assert.ok(gateIdx !== -1, 'run_tests.sh 호출 위치를 찾을 수 없음');
  assert.ok(gateIdx < restartIdx, '테스트 게이트가 재시작(systemctl restart)보다 먼저 실행되어야 early-exit 배선이 유효');
  assert.ok(gateIdx < reloadIdx, '테스트 게이트가 reload(systemctl reload)보다 먼저 실행되어야 early-exit 배선이 유효');

  // 게이트 호출에 실패를 삼키는 패턴(|| true 등)이 곧바로 붙어있지 않아야 한다(가짜 통과 방지).
  assert.doesNotMatch(release, /run_tests\.sh[^\n]*\|\|\s*true/, 'run_tests.sh 실패를 무시하는 패턴(|| true) 발견 — early-exit 위반');
});

// ── MT-4: calc.js export 커버리지 하한 린트 (SP-TEST-7·10, TASK/12 T-12.2.3, Tier0) ──
// calc.js/calc.test.js 실구현은 SP-ENGINE 소유(위임) — 본 케이스는 export 커버리지 하한만 강제.
test('MT-4: calc.js export function 커버리지 하한(미커버=0)', () => {
  const calcPath = join(ROOT, 'web', 'assets', 'js', 'calc.js');
  const calcTestPath = join(ROOT, 'web', 'assets', 'js', 'calc.test.js');
  assert.ok(existsSync(calcPath), 'web/assets/js/calc.js 부재');
  assert.ok(existsSync(calcTestPath), 'web/assets/js/calc.test.js 부재');

  const calcSrc = readFileSync(calcPath, 'utf8');
  const testSrc = readFileSync(calcTestPath, 'utf8');

  const exportRe = /export\s+function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\(/g;
  const exported = new Set();
  let m;
  while ((m = exportRe.exec(calcSrc)) !== null) exported.add(m[1]);
  assert.ok(exported.size > 0, 'calc.js에서 export function을 찾지 못함(파싱 실패 가능성)');

  const uncovered = [...exported].filter((name) => !new RegExp(`\\b${name}\\b`).test(testSrc));
  assert.deepEqual(uncovered, [], `calc.test.js에 미참조된 export 함수: ${uncovered.join(', ')}`);
});
