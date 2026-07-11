// web/assets/js/store.test.js — SP-FE-10.1·10.2 localStorage 래퍼 + "최근 비교" 봉투 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-10, TASK/06-프론트엔드.md T-06.12.1~12.3.
// in-memory localStorage 목(실 브라우저 스토리지 미사용) — 각 테스트 전 초기화(격리).
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

// ── in-memory localStorage 목(Web Storage API 최소 표면) ───────────────────
class FakeLocalStorage {
  constructor() { this._data = new Map(); this._throwOnSet = false; }
  getItem(key) { return this._data.has(key) ? this._data.get(key) : null; }
  setItem(key, value) {
    if (this._throwOnSet) throw new Error('QuotaExceededError(mock)');
    this._data.set(key, String(value));
  }
  removeItem(key) { this._data.delete(key); }
  clear() { this._data.clear(); }
}

globalThis.localStorage = new FakeLocalStorage();

const { store, recent } = await import('./store.js');

beforeEach(() => {
  globalThis.localStorage.clear();
  globalThis.localStorage._throwOnSet = false;
});

// ── T-06.12.1: store 저수준 래퍼 try/catch 흡수 (UT-STORE-4) ───────────────
describe('T-06.12.1 store 저수준 래퍼 (UT-STORE-4)', () => {
  test('get/set 라운드트립', () => {
    assert.equal(store.set('k', { a: 1 }), true);
    assert.deepEqual(store.get('k'), { a: 1 });
  });

  test('get: 키 없음 → null', () => {
    assert.equal(store.get('missing'), null);
  });

  test('get: 손상된 JSON → null(예외 흡수)', () => {
    globalThis.localStorage.setItem('bad', '{not json');
    assert.equal(store.get('bad'), null);
  });

  test('UT-STORE-4: setItem throw 목 → set false 반환(앱 계속, QuotaExceeded 흡수)', () => {
    globalThis.localStorage._throwOnSet = true;
    assert.equal(store.set('k', { a: 1 }), false);
  });

  test('remove: 예외 없이 삭제', () => {
    store.set('k', 1);
    store.remove('k');
    assert.equal(store.get('k'), null);
  });

  test('remove: removeItem이 던져도 예외 전파 없음', () => {
    globalThis.localStorage.removeItem = () => { throw new Error('deny'); };
    assert.doesNotThrow(() => store.remove('k'));
    // 원상복구(다른 테스트 오염 방지)
    globalThis.localStorage = new FakeLocalStorage();
  });

  test('available: 정상 환경 → true', () => {
    assert.equal(store.available(), true);
  });

  test('available: setItem 차단(사생활 모드 모사) → false', () => {
    globalThis.localStorage._throwOnSet = true;
    assert.equal(store.available(), false);
  });
});

// ── T-06.12.2: recent.save FIFO·dedup·봉투 v:1 (UT-STORE-1·2) ──────────────
describe('T-06.12.2 recent.save FIFO·dedup (UT-STORE-1·2)', () => {
  function mkRecord(id, compA, compB, priAxis = 'salary') {
    return {
      id,
      savedAt: new Date().toISOString(),
      label: `record-${id}`,
      slots: { a: { comp_id: compA }, b: { comp_id: compB } },
      input: {},
      result: { priAxis },
    };
  }

  test('UT-STORE-1: 11건 저장 → 길이 10, 최오래건 축출, 최신 선두', () => {
    for (let i = 1; i <= 11; i++) {
      recent.save(mkRecord(String(i), i, i + 100));
    }
    const items = recent.list();
    assert.equal(items.length, 10);
    assert.equal(items[0].id, '11');            // 최신 선두
    assert.ok(!items.some(r => r.id === '1'));   // 가장 오래된 1번 축출
  });

  test('UT-STORE-2: 동일 시그니처 재저장 → 추가 없이 갱신·선두 이동, 길이 불변', () => {
    recent.save(mkRecord('a', 1, 2, 'salary'));
    recent.save(mkRecord('b', 3, 4, 'salary'));
    assert.equal(recent.list().length, 2);

    // 'a'와 동일 시그니처(comp_id a=1,b=2,priAxis=salary)를 다른 id로 재저장
    recent.save(mkRecord('a2', 1, 2, 'salary'));
    const items = recent.list();
    assert.equal(items.length, 2, '동일 시그니처는 추가가 아니라 갱신');
    assert.equal(items[0].id, 'a2', '갱신된 레코드가 선두로 이동');
  });

  test('봉투는 v:1로 저장된다', () => {
    recent.save(mkRecord('x', 1, 2));
    const raw = JSON.parse(globalThis.localStorage.getItem('loupit.recentComparisons'));
    assert.equal(raw.v, 1);
    assert.ok(Array.isArray(raw.items));
  });

  test('save: localStorage 불가 시(available=false) false 반환·생략(FR-44)', () => {
    globalThis.localStorage._throwOnSet = true;
    assert.equal(recent.save(mkRecord('x', 1, 2)), false);
  });

  test('direct 입력(comp_id 없음) 슬롯도 시그니처 구분(direct)', () => {
    const rec = mkRecord('d1', null, 2);
    rec.slots.a = null; // 직접입력 슬롯은 matched null(N-4)
    recent.save(rec);
    assert.equal(recent.list().length, 1);
  });
});

// ── T-06.12.3: recent.list 손상 폐기 (UT-STORE-3) ───────────────────────────
describe('T-06.12.3 recent.list 손상 폐기 (UT-STORE-3)', () => {
  test('UT-STORE-3a: 불량 레코드 포함 → 불량만 제외', () => {
    const good = {
      id: 'g1', savedAt: new Date().toISOString(), label: 'ok',
      slots: { a: null, b: null }, input: {}, result: { priAxis: 'salary' },
    };
    const bad = { id: 'b1' }; // 필수 필드 결측
    globalThis.localStorage.setItem('loupit.recentComparisons',
      JSON.stringify({ v: 1, items: [good, bad] }));
    const items = recent.list();
    assert.equal(items.length, 1);
    assert.equal(items[0].id, 'g1');
  });

  test('UT-STORE-3b: 봉투 버전 불일치(v:2) → 폐기, 빈 배열', () => {
    globalThis.localStorage.setItem('loupit.recentComparisons',
      JSON.stringify({ v: 2, items: [{ id: 'x' }] }));
    assert.deepEqual(recent.list(), []);
    // 폐기 후 원본 키도 정리됨(손상 봉투 재사용 방지)
    assert.equal(globalThis.localStorage.getItem('loupit.recentComparisons'), null);
  });

  test('UT-STORE-3c: 비-JSON(파싱 실패) → 빈 배열, 무크래시', () => {
    globalThis.localStorage.setItem('loupit.recentComparisons', 'not-json{{{');
    assert.doesNotThrow(() => recent.list());
    assert.deepEqual(recent.list(), []);
  });

  test('recent.removeById: 지정 id만 제거', () => {
    const r1 = { id: '1', savedAt: 't', label: 'a', slots: {}, input: {}, result: {} };
    const r2 = { id: '2', savedAt: 't', label: 'b', slots: {}, input: {}, result: {} };
    globalThis.localStorage.setItem('loupit.recentComparisons',
      JSON.stringify({ v: 1, items: [r1, r2] }));
    recent.removeById('1');
    const items = recent.list();
    assert.equal(items.length, 1);
    assert.equal(items[0].id, '2');
  });

  test('recent.clear: 전체 삭제', () => {
    globalThis.localStorage.setItem('loupit.recentComparisons',
      JSON.stringify({ v: 1, items: [{ id: '1', savedAt: 't', label: 'a', slots: {}, input: {}, result: {} }] }));
    recent.clear();
    assert.equal(globalThis.localStorage.getItem('loupit.recentComparisons'), null);
    assert.deepEqual(recent.list(), []);
  });
});
