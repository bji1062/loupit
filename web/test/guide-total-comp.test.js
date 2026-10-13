// web/test/guide-total-comp.test.js — 가이드 B편 「복지를 연봉에 더해 보는 법」 예시 숫자 지킴 장치 (SP-GUIDE-10, 2026-10-13).
// 글의 예시 숫자(`generator/data/guide/total-compensation.json` 의 output · K)가 지금 이직 계산기(calc.js)가 내는 값과 같은지 다시 계산해 대조한다.
// 계산 함수는 생성 스크립트와 하나를 나눠 쓴다(`computeExample`) — 스크립트와 테스트가 어긋날 수 없다.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { computeExample, JSON_PATH } from '../../generator/tools/guide_total_comp.mjs';

const MSG = '이직 계산기 계산 방식이 바뀌었다 — `node generator/tools/guide_total_comp.mjs` 로 가이드 B편 예시를 다시 계산하고 글 문장이 여전히 맞는지 확인하라';

test('가이드 B편 예시 JSON 의 output · K 는 지금 calc.js 가 낸 값과 같다', () => {
  const doc = JSON.parse(readFileSync(JSON_PATH, 'utf8'));
  const fresh = computeExample(doc.input);
  assert.deepStrictEqual(doc.output, fresh.output, MSG);
  assert.deepStrictEqual(doc.K, fresh.K, MSG);
});
