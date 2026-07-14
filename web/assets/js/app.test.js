// web/assets/js/app.test.js — SP-FE-1~5·9.3·11 앱 오케스트레이터 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-1~5·9.3·11, TASK/06-프론트엔드.md T-06.1~06.5·06.10·06.13.
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

// ── 최소 in-memory 브라우저 전역 스텁(app.js 최상위 addEventListener 등록 대비, import 전 세팅) ──
class FakeEl { constructor() { this.hidden = false; } querySelector() { return null; } }
const INITIAL_HIDDEN = { app: true, 'view-search': false, 'view-input': true, 'view-report': true, 'boot-error': true };
function makeDocument() {
  const registry = new Map();
  for (const id of Object.keys(INITIAL_HIDDEN)) {
    const e = new FakeEl();
    e.hidden = INITIAL_HIDDEN[id];
    registry.set(id, e);
  }
  return {
    _registry: registry,
    getElementById(id) { return registry.get(id) || null; },
    addEventListener() {},
    removeEventListener() {},
  };
}
globalThis.document = makeDocument();
globalThis.history = { _calls: [], pushState(state, title, url) { this._calls.push({ state, title, url }); } };
globalThis.location = { origin: 'https://loupit.example', hash: '', search: '' };
globalThis.window = globalThis;

const {
  App, createInitialState, SCREENS, parseHash, go, boot, showBootError,
  resolveCompanyToken, restoreFromPrefill, assembleCompareState, salToStr, PRI_KEY, runReport,
  pickTrendingPair,
} = await import('./app.js');

beforeEach(() => {
  App.state = createInitialState();
  globalThis.location.hash = '';
  globalThis.location.search = '';
  globalThis.history._calls = [];
  for (const id of Object.keys(INITIAL_HIDDEN)) {
    const e = new FakeEl();
    e.hidden = INITIAL_HIDDEN[id];
    globalThis.document._registry.set(id, e);
  }
});

// ── T-06.4.1: App.state 초기 shape·프로파일러 키 부재 (UT-STATE-1) ─────────
describe('T-06.4.1 App.state 초기 shape (UT-STATE-1)', () => {
  test('UT-STATE-1: 프로파일러 키 부재, curPri==="워라밸"', () => {
    const state = createInitialState();
    const keys = Object.keys(state);
    for (const forbidden of ['pfShuffled', 'pfCur', 'pfAnswers', 'pfResult', 'pfJob']) {
      assert.ok(!keys.includes(forbidden), forbidden + ' 키가 존재하면 안 됨(INV-2·SP-FE-4.3)');
    }
    assert.equal(state.curPri, '워라밸');
    assert.equal(state.curSacrifice, null);
  });

  test('salS는 슬롯 a만 보유(슬롯 b는 selectedRate로 파생, 중복 없음)', () => {
    const state = createInitialState();
    assert.deepEqual(Object.keys(state.salS), ['a']);
  });

  test('REF에 profiles/job_groups/questions 키 없음(INV-2)', () => {
    const state = createInitialState();
    assert.equal(state.REF, null); // 부팅 전 — 로드 후에도 서버가 3키만 반환(SP-API 위임)
  });

  test('App.state는 위와 동일 shape로 초기화되어 있다', () => {
    assert.equal(App.state.curPri, '워라밸');
    assert.deepEqual(App.state.matched, { a: null, b: null });
  });
});

// ── T-06.3.1: parseHash (UT-ROUTE-1) ────────────────────────────────────────
describe('T-06.3.1 parseHash (UT-ROUTE-1)', () => {
  test('UT-ROUTE-1: #input→"input", #zzz→null, 빈문자→null', () => {
    globalThis.location.hash = '#input';
    assert.equal(parseHash(), 'input');
    globalThis.location.hash = '#zzz';
    assert.equal(parseHash(), null);
    globalThis.location.hash = '';
    assert.equal(parseHash(), null);
  });
});

// ── T-06.3.2: go 가드·전이 (UT-ROUTE-2) ─────────────────────────────────────
describe('T-06.3.2 go 가드 (UT-ROUTE-2)', () => {
  test('UT-ROUTE-2: go("nope") → screen "search"로 정규화', () => {
    const result = go('nope');
    assert.equal(result, 'search');
    assert.equal(App.state.ui.screen, 'search');
  });

  test('go("input") → view-input hidden=false, 나머지 hidden=true', () => {
    go('input');
    assert.equal(globalThis.document.getElementById('view-input').hidden, false);
    assert.equal(globalThis.document.getElementById('view-search').hidden, true);
    assert.equal(globalThis.document.getElementById('view-report').hidden, true);
  });

  test('push:true(기본) → history.pushState 호출, push:false → 미호출', () => {
    go('report');
    assert.equal(globalThis.history._calls.length, 1);
    assert.equal(globalThis.history._calls[0].url, '#report');
    go('search', { push: false });
    assert.equal(globalThis.history._calls.length, 1, 'push:false는 pushState 미호출');
  });
});

// ── T-06.5.2: boot() 오케스트레이션·showBootError(재시도) ──────────────────
describe('T-06.5.2 boot()', () => {
  test('정상 REF 로드 → #app 표시, search 뷰 진입', async () => {
    const ref = { company_types: [], benefit_presets: {}, companies: [] };
    await boot({ loadReferenceFn: async () => ref });
    assert.deepEqual(App.state.REF, ref);
    assert.equal(globalThis.document.getElementById('app').hidden, false);
    assert.equal(App.state.ui.screen, 'search');
  });

  test('REF 로드 실패 → showBootError, #app 계속 hidden, 크래시 없음(FR-E1)', async () => {
    await boot({ loadReferenceFn: async () => { throw new Error('network'); } });
    assert.equal(globalThis.document.getElementById('boot-error').hidden, false);
    assert.equal(globalThis.document.getElementById('app').hidden, true); // 계속 hidden(B-3)
  });

  test('showBootError: #boot-error 표시', () => {
    showBootError(new Error('x'));
    assert.equal(globalThis.document.getElementById('boot-error').hidden, false);
  });
});

// ── T-06.13.1: resolveCompanyToken (UT-PRE-1) ───────────────────────────────
describe('T-06.13.1 resolveCompanyToken (UT-PRE-1)', () => {
  function refState() {
    return {
      REF: {
        companies: [
          { comp_id: 42, comp_nm: '삼성전자', comp_eng_nm: 'samsung', aliases: ['삼전'] },
        ],
      },
    };
  }
  test('UT-PRE-1: comp_id/영문식별자/정식명/별칭/미존재', () => {
    const state = refState();
    assert.equal(resolveCompanyToken('42', state).comp_id, 42);
    assert.equal(resolveCompanyToken('samsung', state).comp_id, 42);
    assert.equal(resolveCompanyToken('삼성전자', state).comp_id, 42);
    assert.equal(resolveCompanyToken('삼전', state).comp_id, 42);
    assert.equal(resolveCompanyToken('없는회사', state), null);
  });
});

// ── T-06.13.2: restoreFromPrefill ───────────────────────────────────────────
describe('T-06.13.2 restoreFromPrefill', () => {
  function refState() {
    return createInitialState();
  }
  test('유효 지시자 → 슬롯 반영·go("input") 호출', () => {
    const state = refState();
    state.REF = { company_types: [], benefit_presets: {}, companies: [{ comp_id: 1, comp_nm: '삼성전자', benefits: [] }] };
    globalThis.location.search = '?a=삼성전자';
    let went = null;
    restoreFromPrefill(state, { goFn: (screen, opts) => { went = { screen, opts }; } });
    assert.equal(state.matched.a.comp_id, 1);
    assert.deepEqual(went, { screen: 'input', opts: { push: false } });
  });

  test('무효 지시자 → 미선택 유지, go 미호출', () => {
    const state = refState();
    state.REF = { company_types: [], benefit_presets: {}, companies: [] };
    globalThis.location.search = '?a=없는회사';
    let went = false;
    restoreFromPrefill(state, { goFn: () => { went = true; } });
    assert.equal(state.matched.a, null);
    assert.equal(went, false);
  });

  test('a·b 둘 다 지정 시 두 슬롯 반영', () => {
    const state = refState();
    state.REF = { company_types: [], benefit_presets: {}, companies: [{ comp_id: 1, comp_nm: 'A' }, { comp_id: 2, comp_nm: 'B' }] };
    globalThis.location.search = '?a=1&b=2';
    restoreFromPrefill(state, { goFn: () => {} });
    assert.equal(state.matched.a.comp_id, 1);
    assert.equal(state.matched.b.comp_id, 2);
  });
});

// ── T-06.10.1: assembleCompareState·salToStr·PRI_KEY (UT-ASM-1) ────────────
describe('T-06.10.1 assembleCompareState (UT-ASM-1)', () => {
  test('UT-ASM-1: 필드 매핑 정본', () => {
    const state = createInitialState();
    state.salS.a = { low: 5000, high: 7000 };
    state.cmtS = { a: null, b: 30 };
    state.curPri = '워라밸';
    state.selectedRate = 10;
    state.REF = { company_types: [{ comp_tp_cd: 'large' }], benefit_presets: {}, companies: [] };
    const cs = assembleCompareState(state);
    assert.equal(cs.salStr, '5000-7000');
    assert.equal(cs.com.a, 0);
    assert.equal(cs.com.b, 30);
    assert.equal(cs.curPri, 'wlb');
    assert.equal(cs.companyTypes, state.REF.company_types);
    assert.equal(cs.selectedRate, 10);
    assert.equal('salB' in cs, false); // 슬롯 b 절대연봉 미전달(selectedRate만)
  });

  test('salToStr: 한쪽 null → null', () => {
    assert.equal(salToStr({ low: null, high: 5000 }), null);
    assert.equal(salToStr({ low: 100, high: 200 }), '100-200');
  });

  test('PRI_KEY: 4축 한→영 매핑', () => {
    assert.deepEqual(PRI_KEY, { 연봉: 'salary', 워라밸: 'wlb', 복지: 'benefits', 브랜드: 'brand' });
  });

  test('curSacrifice: 라벨→PriKey, null이면 null', () => {
    const state = createInitialState();
    state.curSacrifice = '연봉';
    state.REF = { company_types: [], benefit_presets: {}, companies: [] };
    assert.equal(assembleCompareState(state).curSacrifice, 'salary');
    state.curSacrifice = null;
    assert.equal(assembleCompareState(state).curSacrifice, null);
  });
});

// ── 실시간 비교 TOP 10: pickTrendingPair(위젯 클릭 → 양 슬롯 프리필) ────────
describe('pickTrendingPair (트렌딩 위젯 클릭 배선)', () => {
  function refState() {
    const state = createInitialState();
    state.REF = {
      company_types: [], benefit_presets: {},
      companies: [
        { comp_id: 1, comp_nm: '삼성전자', benefits: [] },
        { comp_id: 2, comp_nm: 'SK하이닉스', benefits: [] },
      ],
    };
    return state;
  }
  const ITEM = { a_comp_id: 1, a_comp_nm: '삼성전자', b_comp_id: 2, b_comp_nm: 'SK하이닉스', cnt: 5 };

  test('REF 해석 성공 → 양 슬롯 매칭 + go("input")', () => {
    const state = refState();
    let went = null;
    const ok = pickTrendingPair(ITEM, { go: (s) => { went = s; } }, state);
    assert.equal(ok, true);
    assert.equal(state.matched.a.comp_id, 1);
    assert.equal(state.matched.b.comp_id, 2);
    assert.equal(went, 'input');
  });

  test('REF에 없는 comp_id → 미프리필·false·go 미호출', () => {
    const state = refState();
    let went = false;
    const ok = pickTrendingPair({ ...ITEM, b_comp_id: 99 }, { go: () => { went = true; } }, state);
    assert.equal(ok, false);
    assert.equal(state.matched.a, null);
    assert.equal(went, false);
  });
});

// ── T-06.10.2: runReport 재계산 오케스트레이션 ──────────────────────────────
describe('T-06.10.2 runReport', () => {
  test('조립→계산→렌더 호출 순서·인자', () => {
    const state = createInitialState();
    state.salS.a = { low: 5000, high: 5000 };
    state.REF = { company_types: [], benefit_presets: {}, companies: [] };
    let compareArg = null, renderArgs = null;
    const fakeReport = { vdCard: { axis: 'wlb' }, a: {}, b: {} };
    const report = runReport({
      state,
      compareFn: (cs) => { compareArg = cs; return fakeReport; },
      renderReportFn: (r, mountEl, ctx) => { renderArgs = { r, mountEl, ctx }; },
      mountEl: { fake: true },
    });
    assert.equal(report, fakeReport);
    assert.equal(compareArg.salStr, '5000-5000');
    assert.equal(renderArgs.r, fakeReport);
    assert.deepEqual(renderArgs.mountEl, { fake: true });
    assert.equal(renderArgs.ctx.benS, state.benS);
  });
});
