// web/test/harness.test.js — SP-TEST 메타 검증(MT-1). 근거: SP-TEST-10, TASK/12 T-12.1.1(Tier0).
// 집계 러너 run_tests.sh가 4개 서브스위트를 호출하고 set -euo pipefail로 실패를 전파하는지 소스 파싱으로 검증.
// (부수효과 없이 스크립트 텍스트만 검사 — 러너·DB 불요.)
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
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
