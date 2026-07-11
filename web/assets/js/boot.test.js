// web/assets/js/boot.test.js — SP-FE-5 부팅 reference/all 로드·shape 검증 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-5, TASK/06-프론트엔드.md T-06.5.1(UT-REF-1).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { loadReference, assertRefShape } from './boot.js';

function validRef() {
  return { company_types: [{ comp_tp_cd: 'x' }], benefit_presets: { x: [] }, companies: [] };
}

// ── T-06.5.1: assertRefShape 3키 검증 (UT-REF-1) ────────────────────────────
describe('T-06.5.1 assertRefShape (UT-REF-1)', () => {
  test('UT-REF-1a: 3키 정상 → 통과(예외 없음)', () => {
    assert.doesNotThrow(() => assertRefShape(validRef()));
  });

  test('UT-REF-1b: companies 결측 → throw(REF_SHAPE)', () => {
    const ref = validRef();
    delete ref.companies;
    assert.throws(() => assertRefShape(ref), /REF_SHAPE/);
  });

  test('company_types가 배열 아님 → throw', () => {
    const ref = validRef();
    ref.company_types = {};
    assert.throws(() => assertRefShape(ref), /REF_SHAPE/);
  });

  test('benefit_presets가 배열(object 아님 요구 위반) → throw', () => {
    const ref = validRef();
    ref.benefit_presets = [];
    assert.throws(() => assertRefShape(ref), /REF_SHAPE/);
  });

  test('ref 자체가 null → throw', () => {
    assert.throws(() => assertRefShape(null), /REF_SHAPE/);
  });
});

// ── T-06.5.1: loadReference (getReference→assertRefShape) ──────────────────
describe('T-06.5.1 loadReference', () => {
  test('정상 REF → 그대로 반환', async () => {
    globalThis.fetch = async () => ({ ok: true, status: 200, json: async () => validRef() });
    const ref = await loadReference();
    assert.deepEqual(ref, validRef());
  });

  test('손상 REF(companies 결측) → throw(REF_SHAPE), 부팅 오류 전이', async () => {
    const bad = validRef();
    delete bad.companies;
    globalThis.fetch = async () => ({ ok: true, status: 200, json: async () => bad });
    await assert.rejects(() => loadReference(), /REF_SHAPE/);
  });

  test('네트워크/비-200 실패 → ApiError 전파(boot() catch에서 흡수될 대상)', async () => {
    globalThis.fetch = async () => ({ ok: false, status: 500, json: async () => ({}) });
    await assert.rejects(() => loadReference());
  });
});
