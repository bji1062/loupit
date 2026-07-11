// web/assets/js/search.test.js — SP-FE-7 검색 오케스트레이션 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-7, TASK/06-프론트엔드.md T-06.7.1~7.6.
import test, { describe, beforeEach, mock } from 'node:test';
import assert from 'node:assert/strict';

// ── 최소 in-memory document 스텁(dom.test.js와 동일 패턴, addEventListener 추가) ──
class FakeElement {
  constructor(tag) {
    this.tagName = tag;
    this.attributes = {};
    this.className = '';
    this.textContent = '';
    this.children = [];
    this._listeners = {};
  }
  setAttribute(k, v) { this.attributes[k] = String(v); }
  append(...nodes) { this.children.push(...nodes); }
  replaceChildren() { this.children = []; }
  addEventListener(type, fn) { (this._listeners[type] ||= []).push(fn); }
  dispatch(type, evt = {}) { (this._listeners[type] || []).forEach((fn) => fn(evt)); }
}
function makeFakeDocument() {
  const registry = new Map();
  const doc = {
    createElement(tag) { return new FakeElement(tag); },
    getElementById(id) { return registry.get(id) || null; },
    _register(id, el2) { registry.set(id, el2); },
  };
  return doc;
}
globalThis.location = { origin: 'https://loupit.example' };

const { sortCandidates, dedupById, onSearchInput, runSearch, renderCandidates, bundleFallbackSearch, typeLabel, DEBOUNCE_MS } = await import('./search.js');

function freshState() {
  return {
    REF: { companies: [] },
    matched: { a: null, b: null },
    ui: {
      searchTimers: { a: null, b: null },
      searchAborts: { a: null, b: null },
      searchState: { a: 'idle', b: 'idle' },
    },
  };
}

// ── T-06.7.1: sortCandidates (UT-SORT-1) ────────────────────────────────────
describe('T-06.7.1 sortCandidates (UT-SORT-1)', () => {
  test('UT-SORT-1: 완전일치→접두→길이→가나다 결정적 순서', () => {
    const items = [
      { comp_id: 1, comp_nm: '삼성전자서비스' }, // 접두
      { comp_id: 2, comp_nm: '삼성' }, // 완전일치
      { comp_id: 3, comp_nm: '삼성SDS' }, // 접두, 길이 더 짧음
      { comp_id: 4, comp_nm: 'LG삼성협력사' }, // 그외
    ];
    const sorted = sortCandidates(items, '삼성');
    assert.deepEqual(sorted.map((i) => i.comp_id), [2, 3, 1, 4]);
  });

  test('타입랜덤 순서 입력에도 결정적(재정렬 안정)', () => {
    const a = [{ comp_id: 1, comp_nm: '가' }, { comp_id: 2, comp_nm: '나' }];
    const b = [{ comp_id: 2, comp_nm: '나' }, { comp_id: 1, comp_nm: '가' }];
    assert.deepEqual(sortCandidates(a, 'x').map((i) => i.comp_id), sortCandidates(b, 'x').map((i) => i.comp_id));
  });
});

// ── T-06.7.2: dedupById (UT-SORT-2) ─────────────────────────────────────────
describe('T-06.7.2 dedupById (UT-SORT-2)', () => {
  test('UT-SORT-2: 동일 comp_id 3건 → 1건만 잔존(선순위 보존)', () => {
    const items = [
      { comp_id: 5, comp_nm: 'first' },
      { comp_id: 5, comp_nm: 'dup2' },
      { comp_id: 5, comp_nm: 'dup3' },
      { comp_id: 6, comp_nm: 'other' },
    ];
    const out = dedupById(items);
    assert.equal(out.length, 2);
    assert.equal(out[0].comp_nm, 'first');
  });
});

// ── T-06.7.3: onSearchInput 디바운스·빈쿼리 가드 ────────────────────────────
describe('T-06.7.3 onSearchInput 디바운스', () => {
  test('1자 미만 → runSearch 미호출, 패널 닫힘(idle)', () => {
    const state = freshState();
    state.ui.searchState.a = 'results';
    onSearchInput(state, 'a', '  ');
    assert.equal(state.ui.searchState.a, 'idle');
  });

  test('300ms 후 runSearch 1회 호출, 연속 입력 시 타이머 리셋(fake timers)', (t) => {
    mock.timers.enable({ apis: ['setTimeout'] });
    t.after(() => mock.timers.reset());
    const state = freshState();
    let calls = 0;
    const hooks = { searchCompaniesFn: async () => { calls++; return []; } };
    onSearchInput(state, 'a', '삼', hooks);
    assert.equal(state.ui.searchState.a, 'loading');
    mock.timers.tick(200);
    onSearchInput(state, 'a', '삼성', hooks); // 타이머 리셋
    mock.timers.tick(200);
    assert.equal(calls, 0, '리셋되어 아직 실행 안 됨');
    mock.timers.tick(100);
    assert.equal(calls, 1, '리셋 후 300ms 경과 시 1회만 실행');
  });
});

// ── T-06.7.4: runSearch 경합 폐기·무결과/오류 구분 ──────────────────────────
describe('T-06.7.4 runSearch', () => {
  test('빈 배열 응답 → searchState empty', async () => {
    const state = freshState();
    await runSearch(state, 'a', 'x', { searchCompaniesFn: async () => [] });
    assert.equal(state.ui.searchState.a, 'empty');
  });

  test('오류(throw) → REF 폴백 시도(폴백도 0건이면 error)', async () => {
    const state = freshState();
    state.REF.companies = [];
    await runSearch(state, 'a', 'x', { searchCompaniesFn: async () => { throw new Error('500'); } });
    assert.equal(state.ui.searchState.a, 'error');
  });

  test('오류 + REF 폴백 매칭 있음 → results 전이(FR-E2)', async () => {
    const state = freshState();
    state.REF.companies = [{ comp_id: 1, comp_nm: '삼성전자' }];
    await runSearch(state, 'a', '삼성', { searchCompaniesFn: async () => { throw new Error('500'); } });
    assert.equal(state.ui.searchState.a, 'results');
  });

  test('경합: 이전 요청 abort 후 최신 응답만 반영(stale 폐기)', async () => {
    const state = freshState();
    let resolveFirst;
    const first = new Promise((r) => { resolveFirst = r; });
    let firstAborted = false;
    const seq = [];
    const searchCompaniesFn = async (q, { signal }) => {
      if (q === 'stale') {
        signal.addEventListener('abort', () => { firstAborted = true; });
        await first;
        seq.push('stale-resolved');
        return [{ comp_id: 1, comp_nm: 'stale-item' }];
      }
      seq.push('fresh-resolved');
      return [{ comp_id: 2, comp_nm: 'fresh-item' }];
    };
    const p1 = runSearch(state, 'a', 'stale', { searchCompaniesFn });
    const p2 = runSearch(state, 'a', 'fresh', { searchCompaniesFn }); // 최신 요청(이전 abort)
    await p2;
    resolveFirst(); // stale 응답 뒤늦게 도착
    await p1;
    assert.equal(firstAborted, true);
    assert.equal(state.ui.searchState.a, 'results');
  });
});

// ── T-06.7.5: renderCandidates 안전 렌더·20 상한·키보드 ─────────────────────
describe('T-06.7.5 renderCandidates', () => {
  test('20건 상한·textContent 삽입·comp_id 클릭 바인딩', () => {
    const doc = makeFakeDocument();
    const list = new FakeElement('ul');
    doc._register('cand-a', list);
    globalThis.document = doc;

    const state = freshState();
    state.REF.companies = [{ comp_id: 42, comp_nm: '회사42', benefits: [] }];
    const items = Array.from({ length: 25 }, (_, i) => ({ comp_id: i, comp_nm: '회사' + i, comp_tp_cd: 'large', industry_nm: 'IT' }));
    renderCandidates(state, 'a', items, 'q');
    assert.equal(list.children.length, 20, '20건 상한');
    assert.equal(list.children[0].children[0].textContent, '회사0');
    assert.equal(state.ui.searchState.a, 'results');

    // XSS 안전성: 위험 문자열도 textContent로만 삽입
    const xssItems = [{ comp_id: 99, comp_nm: '<img onerror=alert(1)>', comp_tp_cd: 'large', industry_nm: '' }];
    renderCandidates(state, 'a', xssItems, 'q');
    assert.equal(list.children[0].children[0].textContent, '<img onerror=alert(1)>');
  });
});

// ── T-06.7.6: bundleFallbackSearch (UT-SEARCH-FB-1) ─────────────────────────
describe('T-06.7.6 bundleFallbackSearch (UT-SEARCH-FB-1)', () => {
  test('UT-SEARCH-FB-1a: 이름/별칭 일치 후보 반환·results 전이', () => {
    const state = freshState();
    globalThis.document = undefined; // DOM 없이도 동작(hooks.doc 생략 시 무 렌더 경로)
    state.REF.companies = [
      { comp_id: 1, comp_nm: '삼성전자', aliases: ['삼전'] },
      { comp_id: 2, comp_nm: 'LG전자', aliases: [] },
    ];
    const out = bundleFallbackSearch(state, 'a', '삼전');
    assert.equal(out.length, 1);
    assert.equal(out[0].comp_id, 1);
    assert.equal(state.ui.searchState.a, 'results');
  });

  test('UT-SEARCH-FB-1b: 폴백 0건 → error', () => {
    const state = freshState();
    state.REF.companies = [{ comp_id: 1, comp_nm: '삼성전자', aliases: [] }];
    const out = bundleFallbackSearch(state, 'a', '없는회사이름');
    assert.equal(out.length, 0);
    assert.equal(state.ui.searchState.a, 'error');
  });

  test('comp_eng_nm 일치도 매칭', () => {
    const state = freshState();
    state.REF.companies = [{ comp_id: 3, comp_nm: '삼성전자', comp_eng_nm: 'samsung', aliases: [] }];
    const out = bundleFallbackSearch(state, 'a', 'samsung');
    assert.equal(out.length, 1);
  });
});

// ── typeLabel 스모크 ─────────────────────────────────────────────────────
describe('typeLabel', () => {
  test('6종 코드 라벨 매핑, 미상은 기타', () => {
    assert.equal(typeLabel('large'), '대기업');
    assert.equal(typeLabel('startup'), '스타트업');
    assert.equal(typeLabel('unknown'), '기타');
  });
});
