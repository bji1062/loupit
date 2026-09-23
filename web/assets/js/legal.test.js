// web/assets/js/legal.test.js — 법정 행 클라이언트 사본(SP-LEGAL-5). 정본 대조는 파이썬 쪽
// (generator/tests/test_legal_rows_client_copy.py)이 하고, 여기서는 판정 함수의 계약만 본다.
import test from 'node:test';
import assert from 'node:assert/strict';
import { LEGAL_ROWS, isLegalRow } from './legal.js';

test('LEGAL-1: 3튜플이 모두 맞아야 법정 행이다(코드만 같으면 아니다)', () => {
  assert.equal(isLegalRow('kt', 'parenting', '출산/육아 지원'), true);
  assert.equal(isLegalRow('kt', 'parenting', '육아휴직 2년'), false, '같은 코드의 진짜 복지는 남는다');
  assert.equal(isLegalRow('naver', 'parenting', '출산/육아 지원'), false);
  assert.equal(isLegalRow(null, undefined, ''), false);
});

test('LEGAL-2: 목록은 동결 · 중복 없음', () => {
  assert.equal(Object.isFrozen(LEGAL_ROWS), true);
  const keys = LEGAL_ROWS.map((r) => r.join('|'));
  assert.equal(new Set(keys).size, keys.length);
  assert.ok(LEGAL_ROWS.every((r) => r.length === 3));
});
