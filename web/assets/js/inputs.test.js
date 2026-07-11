// web/assets/js/inputs.test.js — SP-FE-8 선택·정규화·프리셋 채움 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-8, TASK/06-프론트엔드.md T-06.8.1~8.5.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  normalizeCompany, normalizeBenefit, fillBenefits, initWsState,
  selectCompany, sameCompanyGuard, setDirectType, clearSlot, blankWs,
} from './inputs.js';

function freshState(overrides = {}) {
  return {
    REF: { company_types: [], benefit_presets: {}, companies: [] },
    matched: { a: null, b: null },
    benS: { a: [], b: [] },
    wsState: { a: blankWs(), b: blankWs() },
    chosenType: { a: null, b: null },
    inputMode: { a: 'company', b: 'company' },
    ...overrides,
  };
}

// ── T-06.8.1: normalizeCompany·normalizeBenefit (UT-NORM-1·2) ──────────────
describe('T-06.8.1 normalizeCompany·normalizeBenefit (UT-NORM-1·2)', () => {
  test('UT-NORM-1: 카테고리 미상·배지 미상·qual_yn=1 → perks·est·true·benefit_amt=null', () => {
    const raw = {
      comp_id: 1, comp_nm: '테스트', benefits: [
        { benefit_cd: 'B1', benefit_nm: '식대', benefit_ctgr_cd: 'unknown_ctgr', badge_cd: 'weird', qual_yn: 1, benefit_amt: 100 },
      ],
    };
    const norm = normalizeCompany(raw);
    const b = norm.benefits[0];
    assert.equal(b.benefit_ctgr_cd, 'perks');
    assert.equal(b.badge_cd, 'est');
    assert.equal(b.qual_yn, true);
    assert.equal(b.benefit_amt, null);
  });

  test('UT-NORM-2: amt_source 미상 + 비정성 → estimated 폴백, 정성이면 none', () => {
    const nonQual = normalizeBenefit({ benefit_cd: 'B2', qual_yn: false, benefit_amt: 50 });
    assert.equal(nonQual.amt_source, 'estimated');
    const qual = normalizeBenefit({ benefit_cd: 'B3', qual_yn: true });
    assert.equal(qual.amt_source, 'none');
  });

  test('amt_source가 유효값(stated)이면 그대로 유지', () => {
    const b = normalizeBenefit({ benefit_cd: 'B4', qual_yn: false, amt_source: 'stated' });
    assert.equal(b.amt_source, 'stated');
  });

  test('normalizeCompany: 결측 필드는 안전 폴백(빈 문자열/빈 배열/null)', () => {
    const norm = normalizeCompany({ comp_id: 5 });
    assert.equal(norm.comp_nm, '');
    assert.deepEqual(norm.aliases, []);
    assert.deepEqual(norm.benefits, []);
    assert.equal(norm.work_style_val, null);
  });
});

// ── T-06.8.2: fillBenefits (UT-FILL-1·2) ────────────────────────────────────
describe('T-06.8.2 fillBenefits (UT-FILL-1·2)', () => {
  test('UT-FILL-1: 회사 지정 슬롯 → 각 항목 checked===true·value_source==="real"', () => {
    const state = freshState();
    state.matched.a = normalizeCompany({
      comp_id: 1, comp_nm: 'A사',
      benefits: [{ benefit_cd: 'X', qual_yn: false, benefit_amt: 10 }],
    });
    fillBenefits(state, 'a');
    assert.equal(state.benS.a.length, 1);
    assert.equal(state.benS.a[0].checked, true);
    assert.equal(state.benS.a[0].value_source, 'real');
  });

  test('UT-FILL-2: 직접입력+유형(프리셋) → checked=default_checked_yn·value_source==="preset"', () => {
    const state = freshState();
    state.REF.benefit_presets = {
      startup: [
        { benefit_cd: 'P1', qual_yn: false, benefit_amt: 20, default_checked_yn: true },
        { benefit_cd: 'P2', qual_yn: false, benefit_amt: 5, default_checked_yn: false },
      ],
    };
    state.chosenType.a = 'startup';
    fillBenefits(state, 'a');
    assert.equal(state.benS.a.length, 2);
    assert.equal(state.benS.a[0].checked, true);
    assert.equal(state.benS.a[0].value_source, 'preset');
    assert.equal(state.benS.a[1].checked, false);
  });

  test('회사도 유형도 없으면 빈 배열', () => {
    const state = freshState();
    fillBenefits(state, 'a');
    assert.deepEqual(state.benS.a, []);
  });
});

// ── T-06.8.3: initWsState (UT-WS-1) ─────────────────────────────────────────
describe('T-06.8.3 initWsState (UT-WS-1)', () => {
  test('UT-WS-1: work_style_val.remote="hybrid" → remote 제안값 세팅, ot/wage=null', () => {
    const state = freshState();
    state.matched.a = normalizeCompany({ comp_id: 1, comp_nm: 'A', work_style_val: { remote: 'hybrid' } });
    initWsState(state, 'a');
    assert.equal(state.wsState.a.remote, 'hybrid');
    assert.equal(state.wsState.a.ot, null);
    assert.equal(state.wsState.a.wage, null);
    assert.equal(state.wsState.a.flex, null);
  });

  test('matched 없음(직접입력) → 전부 null(제안 없음)', () => {
    const state = freshState();
    initWsState(state, 'a');
    assert.deepEqual(state.wsState.a, { ot: null, wage: null, remote: null, flex: null });
  });
});

// ── T-06.8.4: selectCompany·sameCompanyGuard·clearSlot ──────────────────────
describe('T-06.8.4 selectCompany·sameCompanyGuard·clearSlot', () => {
  test('REF 인라인 매칭 → matched 반영, benS/wsState 초기화', async () => {
    const state = freshState();
    state.REF.companies = [{ comp_id: 7, comp_nm: '회사7', benefits: [] }];
    const ok = await selectCompany(state, 'a', 7);
    assert.equal(ok, true);
    assert.equal(state.matched.a.comp_id, 7);
    assert.equal(state.inputMode.a, 'company');
    assert.equal(state.chosenType.a, null);
  });

  test('양 슬롯 동일 comp_id → 반영 보류(matched 미변경), notify 호출', async () => {
    const state = freshState();
    state.REF.companies = [{ comp_id: 7, comp_nm: '회사7', benefits: [] }];
    state.matched.b = normalizeCompany({ comp_id: 7, comp_nm: '회사7' });
    let notified = false;
    const ok = await selectCompany(state, 'a', 7, { notify: () => { notified = true; } });
    assert.equal(ok, false);
    assert.equal(state.matched.a, null);
    assert.equal(notified, true);
  });

  test('REF 미존재 → getCompany 폴백 성공 시 반영', async () => {
    const state = freshState();
    const ok = await selectCompany(state, 'a', 99, {
      getCompanyFn: async (id) => ({ comp_id: id, comp_nm: '원격회사', benefits: [] }),
    });
    assert.equal(ok, true);
    assert.equal(state.matched.a.comp_id, 99);
  });

  test('REF 미존재 + getCompany 폴백도 실패 → 미선택 유지(크래시 없음)', async () => {
    const state = freshState();
    let errMsg = null;
    const ok = await selectCompany(state, 'a', 99, {
      getCompanyFn: async () => { throw new Error('404'); },
      showSlotError: (slot, msg) => { errMsg = msg; },
    });
    assert.equal(ok, false);
    assert.equal(state.matched.a, null);
    assert.ok(errMsg);
  });

  test('sameCompanyGuard: 반대 슬롯 다른 회사면 false', () => {
    const state = freshState();
    state.matched.b = normalizeCompany({ comp_id: 1, comp_nm: 'X' });
    assert.equal(sameCompanyGuard(state, 'a', 2), false);
  });

  test('clearSlot: 초기값 복귀', () => {
    const state = freshState();
    state.matched.a = normalizeCompany({ comp_id: 1, comp_nm: 'X' });
    state.chosenType.a = 'startup';
    state.inputMode.a = 'direct';
    let labelSlot, labelVal;
    clearSlot(state, 'a', (slot, val) => { labelSlot = slot; labelVal = val; });
    assert.equal(state.matched.a, null);
    assert.deepEqual(state.benS.a, []);
    assert.deepEqual(state.wsState.a, blankWs());
    assert.equal(state.chosenType.a, null);
    assert.equal(state.inputMode.a, 'company');
    assert.equal(labelSlot, 'a');
    assert.equal(labelVal, '');
  });
});

// ── T-06.8.5: setDirectType (FR-17) ─────────────────────────────────────────
describe('T-06.8.5 setDirectType', () => {
  test('inputMode==="direct"·matched===null·chosenType 세팅', () => {
    const state = freshState();
    state.matched.a = normalizeCompany({ comp_id: 1, comp_nm: 'X' }); // 사전 회사 선택 상태였다고 가정
    setDirectType(state, 'a', 'startup');
    assert.equal(state.inputMode.a, 'direct');
    assert.equal(state.matched.a, null);
    assert.equal(state.chosenType.a, 'startup');
  });

  test('프리셋 채움 회귀(UT-FILL-2와 동일 경로)', () => {
    const state = freshState();
    state.REF.benefit_presets = { startup: [{ benefit_cd: 'P1', qual_yn: false, benefit_amt: 1, default_checked_yn: true }] };
    setDirectType(state, 'a', 'startup');
    assert.equal(state.benS.a.length, 1);
    assert.equal(state.benS.a[0].value_source, 'preset');
  });
});
