// web/assets/js/compare-index.test.js — 「가벼운 목록 + 회사별 상세」가 번들 전체와 같은 결과를 내는가 (2026-10-22, /compare 경량화).
// 픽스처 `generator/tests/data/compare_index_cases.json`(만드는 스크립트: make_compare_index_cases.py — 손으로 고치지 마라)을
// 파이썬 서버 테스트(server/tests/test_reference_cut.py)와 같이 읽는다. 화면 · 계산 결과는 글자 하나 다르면 안 된다.
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, querySelector() { return null; }, createElement() { return {}; } };

import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { categoryStats, statsFromIndex, buildViewModel } from './benefits.js';
import { countable } from './marks.js';
import { rowMeta } from './directory.js';
import { fallbackPairs } from './trending.js';
import { findCompanies } from './company.js';
import { bundleFallbackSearch } from './search.js';
import { normalizeCompany, fillBenefits } from './inputs.js';
import { hasDetail, loadDetail, ensureCompanies } from './company-store.js';
import { assertRefShape, loadReferenceIndex } from './boot.js';
import { ApiError } from './api.js';

const CASES = JSON.parse(readFileSync(fileURLToPath(new URL('../../../generator/tests/data/compare_index_cases.json', import.meta.url)), 'utf8'));
const clone = (x) => JSON.parse(JSON.stringify(x));
const { bundle, index, details } = CASES;

describe('눈금 통계: 서버가 보낸 합 == 번들로 센 값', () => {
  test('statsFromIndex(index.category_stats) 는 categoryStats(번들 회사) 와 깊은 동등(소수점까지)', () => {
    assert.deepEqual(statsFromIndex(index.category_stats), categoryStats(bundle.companies));
  });

  test('.125 · .375 평균(round2 의 짝수 반올림 지점)이 픽스처에 실제로 들어 있다', () => {
    const s = statsFromIndex(index.category_stats);
    assert.equal(s.avgs.flexibility, 0.12);
    assert.equal(s.avgs.health, 0.38);
  });

  test('빈 목록 · 분모 0 도 죽지 않는다', () => {
    assert.deepEqual(statsFromIndex({ total: 0, sums: {}, rmax: 1 }).avgs.perks, 0);
    assert.equal(statsFromIndex(undefined).rmax, 1);
  });
});

describe('복지 수: benefit_n == countable(번들 회사).length', () => {
  test('회사마다 같다(표시 행은 빼고 검색 요약 행은 센다)', () => {
    for (const [i, c] of bundle.companies.entries()) {
      assert.equal(index.companies[i].comp_id, c.comp_id);
      assert.equal(index.companies[i].benefit_n, countable(c).length, c.comp_nm);
    }
  });

  test('rowMeta 문자열이 가벼운 객체 · 번들 객체에서 같다', () => {
    for (const [i, c] of bundle.companies.entries()) assert.equal(rowMeta(index.companies[i]), rowMeta(c), c.comp_nm);
  });
});

describe('목록만으로 도는 곳은 번들과 같은 결과', () => {
  test('많이 본 조합 폴백(fallbackPairs)', () => {
    assert.deepEqual(fallbackPairs(index.companies), fallbackPairs(bundle.companies));
  });

  test('GNB 검색(findCompanies) — 이름 · 별칭 · 영문 · 부분 일치', () => {
    for (const term of ['KT', '케이티', 'naver', '네이버', '상사', 'SK', '대시', 'tiny', '없는회사']) {
      assert.deepEqual(findCompanies(index.companies, term).map((c) => c.comp_id), findCompanies(bundle.companies, term).map((c) => c.comp_id), term);
    }
  });

  test('검색 API 실패 시 번들 폴백(bundleFallbackSearch)', () => {
    const run = (REF, q) => bundleFallbackSearch({ REF, ui: { searchState: {} } }, 'a', q, { doc: null }).map((c) => c.comp_id);
    for (const q of ['kt', '네이버', '상사', 'tiny', 'zzz']) assert.deepEqual(run(index, q), run(bundle, q), q);
  });
});

describe('가벼운 목록 + 상세를 합치면 번들과 같은 화면 재료', () => {
  function stateWith(REF, ids) {
    const state = {
      REF, matched: { a: null, b: null }, benS: { a: [], b: [] }, chosenType: { a: null, b: null },
    };
    ['a', 'b'].forEach((slot, i) => {
      state.matched[slot] = normalizeCompany(REF.companies.find((c) => c.comp_id === ids[i]));
      fillBenefits(state, slot);
    });
    return state;
  }

  test('buildViewModel 이 깊은 동등(통계 · 짝짓기 · 문장 전부)', async () => {
    const light = clone(index);
    const fetched = [];
    const fetchFn = async (id) => { fetched.push(id); return clone(details[String(id)]); };
    const failed = await ensureCompanies({ REF: light }, [1, 3], fetchFn);
    assert.deepEqual(failed, []);
    assert.deepEqual(fetched.sort(), [1, 3]);
    const now = Date.parse('2026-10-22T00:00:00Z');
    const viaIndex = buildViewModel(stateWith(light, [1, 3]), { now });
    const viaBundle = buildViewModel(stateWith(clone(bundle), [1, 3]), { now });
    assert.deepEqual(viaIndex, viaBundle);
  });
});

describe('company-store', () => {
  const fresh = () => ({ REF: clone(index) });

  test('hasDetail: 복지 배열이 있으면(빈 배열도) 상세다 · 가벼운 목록 객체는 아니다', () => {
    assert.equal(hasDetail(index.companies[0]), false);
    assert.equal(hasDetail({ comp_id: 1, benefits: [] }), true);
    assert.equal(hasDetail(null), false);
  });

  test('받으면 REF 의 그 객체에 합친다(다른 곳이 쥔 참조가 그대로 상세를 본다)', async () => {
    const state = fresh();
    const held = state.REF.companies[0];
    const got = await loadDetail(state, 1, async () => clone(details['1']));
    assert.equal(got, held);
    assert.equal(hasDetail(held), true);
    assert.equal(held.benefits.length, details['1'].benefits.length);
    assert.equal(held.benefit_n, index.companies[0].benefit_n, '목록 필드는 그대로 남는다');
  });

  test('이미 상세가 있으면 요청 0', async () => {
    const state = fresh();
    await loadDetail(state, 1, async () => clone(details['1']));
    let calls = 0;
    await loadDetail(state, 1, async () => { calls += 1; return clone(details['1']); });
    assert.equal(calls, 0);
  });

  test('같은 id 를 동시에 두 번 받지 않는다(진행 중 약속 공유)', async () => {
    const state = fresh();
    let calls = 0;
    const fetchFn = async () => { calls += 1; await new Promise((r) => setTimeout(r, 5)); return clone(details['2']); };
    const [x, y] = await Promise.all([loadDetail(state, 2, fetchFn), loadDetail(state, 2, fetchFn)]);
    assert.equal(calls, 1);
    assert.equal(x, y);
  });

  test('실패는 기억하지 않는다 — 다음에 다시 시도한다', async () => {
    const state = fresh();
    let calls = 0;
    await assert.rejects(() => loadDetail(state, 3, async () => { calls += 1; throw new Error('503'); }));
    assert.equal(hasDetail(state.REF.companies[2]), false, '실패하면 상세 없는 채로 남는다(빈 복지로 합쳐지지 않는다)');
    await loadDetail(state, 3, async () => { calls += 1; return clone(details['3']); });
    assert.equal(calls, 2);
    assert.equal(hasDetail(state.REF.companies[2]), true);
  });

  test('복지 배열이 없거나 다른 회사의 응답은 합치지 않고 실패로 본다', async () => {
    const state = fresh();
    await assert.rejects(() => loadDetail(state, 1, async () => ({ comp_id: 1, comp_nm: 'KT' })), /COMPANY_SHAPE/);
    await assert.rejects(() => loadDetail(state, 1, async () => clone(details['2'])), /COMPANY_SHAPE/);
    assert.equal(hasDetail(state.REF.companies[0]), false);
  });

  test('ensureCompanies: 병렬 · 실패한 id 만 돌려준다 · REF 에 없는 id 는 건너뛴다', async () => {
    const state = fresh();
    const asked = [];
    const failed = await ensureCompanies(state, [1, 2, 2, 999, null], async (id) => {
      asked.push(id);
      if (id === 2) throw new Error('boom');
      return clone(details[String(id)]);
    });
    assert.deepEqual(asked.sort(), [1, 2], '중복 · 없는 회사 · 비정수는 요청하지 않는다');
    assert.deepEqual(failed, [2]);
  });
});

describe('부팅 로더 loadReferenceIndex · assertRefShape', () => {
  test('가벼운 목록 모양을 받는다(눈금 통계 포함)', () => {
    assert.equal(assertRefShape(clone(index)), true);
    assert.equal(assertRefShape(clone(bundle)), true, '번들 모양(눈금 통계 없음)도 받는다');
  });

  test('눈금 통계가 있는데 모양이 깨졌으면 REF_SHAPE', () => {
    const bad = clone(index);
    bad.category_stats = { total: 'x' };
    assert.throws(() => assertRefShape(bad), /REF_SHAPE/);
  });

  test('index 가 성공하면 /reference/all 은 부르지 않는다', async () => {
    let all = 0;
    const ref = await loadReferenceIndex({ indexFn: async () => clone(index), allFn: async () => { all += 1; return clone(bundle); } });
    assert.equal(all, 0);
    assert.equal(ref.category_stats.total, 8);
  });

  test('index 가 404 · 네트워크 오류(응답 없음)면 /reference/all 로 한 번 되돌아간다', async () => {
    for (const err of [new ApiError(404, '/reference/index'), new TypeError('Failed to fetch')]) {
      let all = 0;
      const ref = await loadReferenceIndex({ indexFn: async () => { throw err; }, allFn: async () => { all += 1; return clone(bundle); } });
      assert.equal(all, 1);
      assert.equal(ref.companies.every(hasDetail), true, '폴백 부팅은 모든 회사가 이미 상세를 가진다');
    }
  });

  test('429 · 5xx · 시간 초과 · 손상은 되돌아가지 않고 부팅 오류로 던진다(검토 L5)', async () => {
    const abort = Object.assign(new Error('aborted'), { name: 'AbortError' });
    const cases = [new ApiError(429, '/reference/index'), new ApiError(500, '/reference/index'), new ApiError(503, '/reference/index'), abort];
    for (const err of cases) {
      let all = 0;
      await assert.rejects(() => loadReferenceIndex({ indexFn: async () => { throw err; }, allFn: async () => { all += 1; return clone(bundle); } }));
      assert.equal(all, 0, String(err.status || err.name));
    }
    let all = 0;
    await assert.rejects(() => loadReferenceIndex({ indexFn: async () => ({ companies: [] }), allFn: async () => { all += 1; return clone(bundle); } }), /REF_SHAPE/);
    assert.equal(all, 0);
  });

  test('둘 다 실패하면 던진다(부팅 오류 전이)', async () => {
    await assert.rejects(() => loadReferenceIndex({ indexFn: async () => { throw new Error('x'); }, allFn: async () => { throw new Error('y'); } }));
  });
});
