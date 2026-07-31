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
// C1 최근 비교 저장/복원 테스트용 in-memory localStorage(store.test/report.test와 동일 패턴).
class FakeLocalStorage {
  constructor() { this._data = new Map(); }
  getItem(k) { return this._data.has(k) ? this._data.get(k) : null; }
  setItem(k, v) { this._data.set(k, String(v)); }
  removeItem(k) { this._data.delete(k); }
  clear() { this._data.clear(); }
}
globalThis.localStorage = new FakeLocalStorage();

const {
  App, createInitialState, SCREENS, parseHash, go, boot, showBootError,
  resolveCompanyToken, restoreFromPrefill, assembleCompareState, salToStr, PRI_KEY, runReport,
  pickTrendingPair, restoreComparison,
  resolveBootScreen, hasSlotState, restoreLatestComparison, onPopState,
  snapshotInput, restoreInputDraft, bindDraftPersist,
} = await import('./app.js');
const { recent, inputDraft } = await import('./store.js');
const { COMPARE_LOG_URL } = await import('./trending.js');

beforeEach(() => {
  App.state = createInitialState();
  globalThis.localStorage.clear();
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
    assert.equal(cs.selectedRate, 10);
    assert.equal('salB' in cs, false); // 슬롯 b 절대연봉 미전달(selectedRate만)
  });

  test('salToStr: 한쪽 null → null', () => {
    assert.equal(salToStr({ low: null, high: 5000 }), null);
    assert.equal(salToStr({ low: 100, high: 200 }), '100-200');
  });

  test('PRI_KEY: 3축 한→영 매핑(브랜드 축 제거 2026-07-20)', () => {
    assert.deepEqual(PRI_KEY, { 연봉: 'salary', 워라밸: 'wlb', 복지: 'benefits' });
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

  // 자기강화 루프 차단(2026-07-31): 위젯이 보여준 조합을 클릭했다는 이유로 그 조합을
  // 다시 집계에 넣으면 1위가 스스로를 계속 밀어올린다. 클릭 경로만 onPairReady를 끊는다.
  test('위젯 클릭은 익명 쌍 로그를 남기지 않는다(onPairReady 미호출)', () => {
    const state = refState();
    const logged = [];
    pickTrendingPair(ITEM, { go: () => {}, onPairReady: () => logged.push(1) }, state);
    assert.equal(state.matched.b.comp_id, 2, '프리필 자체는 정상 동작');
    assert.equal(logged.length, 0, '위젯 클릭이 집계를 밀어올리면 순위가 자기 자신으로 굳는다');
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

  test('#3: 필수값 결측(ok:false) → 렌더·저장 차단, report 반환', () => {
    const state = createInitialState(); // salS 미입력·selectedRate null → salary·raise 결측
    state.REF = { company_types: [], benefit_presets: {}, companies: [] };
    let rendered = 0;
    const report = runReport({ state, renderReportFn: () => { rendered += 1; }, mountEl: { fake: true } });
    assert.equal(report.ok, false);
    assert.equal(rendered, 0, '결측 시 렌더 차단');
    assert.equal(recent.list().length, 0, '결측 시 저장 안 함');
  });
});

// ── C1: 최근 비교 배선(저장 자동 호출·recentCtx 주입·복원) ───────────────────
describe('C1 최근 비교 배선', () => {
  function reportReadyState() {
    const state = createInitialState();
    state.salS.a = { low: 5000, high: 5000 };
    state.selectedRate = 10;
    state.REF = {
      company_types: [
        { comp_tp_cd: 'large', growth_rate_val: 0.04, stability_score_no: 90 },
        { comp_tp_cd: 'startup', growth_rate_val: 0.1, stability_score_no: 40 },
      ],
      benefit_presets: {},
      companies: [
        { comp_id: 1, comp_nm: 'A사', comp_tp_cd: 'large', benefits: [] },
        { comp_id: 2, comp_nm: 'B사', comp_tp_cd: 'startup', benefits: [] },
      ],
    };
    state.matched.a = { comp_id: 1, comp_nm: 'A사', comp_tp_cd: 'large', work_style_val: {} };
    state.matched.b = { comp_id: 2, comp_nm: 'B사', comp_tp_cd: 'startup', work_style_val: {} };
    return state;
  }

  test('runReport(성공) → recent 자동 저장 + recentCtx 렌더 주입', () => {
    const state = reportReadyState();
    const rc = { onRestore() {} };
    let ctxSeen = null;
    runReport({ state, recentCtx: rc, renderReportFn: (r, m, ctx) => { ctxSeen = ctx; }, mountEl: { fake: true } });
    assert.equal(ctxSeen.recentCtx, rc, 'recentCtx가 렌더 컨텍스트에 주입됨');
    assert.equal(recent.list().length, 1, '성공 비교 1건 저장');
    assert.equal(recent.list()[0].slots.a.comp_id, 1);
  });

  test('restoreComparison — 레코드 입력 복원 + 리포트 재실행·이동', () => {
    const state = reportReadyState();
    const record = {
      id: 'r1', savedAt: '2026-07-18T00:00:00Z',
      slots: { a: { comp_id: 1 }, b: { comp_id: 2 } },
      input: {
        salS: { a: { low: 4000, high: 6000 } }, selectedRate: 7, cmtS: { a: 10, b: 20 },
        wsState: { a: { ot: 'mid', wage: 'separate', remote: true, flex: false }, b: { ot: 'low', wage: 'inclusive', remote: false, flex: false } },
        curPri: '연봉', curSacrifice: null, chosenType: { a: null, b: null }, inputMode: { a: 'company', b: 'company' },
      },
      result: {},
    };
    let ran = 0, dest = null;
    const ok = restoreComparison(record, { runReport: () => { ran += 1; }, go: (v) => { dest = v; } }, state);
    assert.equal(ok, true);
    assert.deepEqual(state.salS, { a: { low: 4000, high: 6000 } });
    assert.equal(state.selectedRate, 7);
    assert.equal(state.curPri, '연봉');
    assert.equal(state.matched.a.comp_id, 1, 'A 슬롯 REF에서 복원');
    assert.equal(state.matched.b.comp_id, 2, 'B 슬롯 REF에서 복원');
    assert.equal(ran, 1, '리포트 재실행');
    assert.equal(dest, 'report', '리포트 뷰 이동');
  });

  test('restoreComparison — 레코드/입력 없으면 false(무크래시)', () => {
    assert.equal(restoreComparison(null, {}, createInitialState()), false);
    assert.equal(restoreComparison({}, {}, createInitialState()), false);
  });

  test('UT-C1-4: 재실행 리포트가 ok:false면 이동하지 않고 false(빈 리포트 방지)', () => {
    const state = reportReadyState();
    const record = {
      id: 'r2', savedAt: '2026-07-18T00:00:00Z',
      slots: { a: { comp_id: 1 }, b: { comp_id: 2 } },
      input: { salS: { a: { low: null, high: null } }, selectedRate: null },
      result: {},
    };
    let dest = null;
    const ok = restoreComparison(record, {
      runReport: () => ({ ok: false, missing: ['salary'] }),
      go: (v) => { dest = v; },
    }, state);
    assert.equal(ok, false, '렌더 불가 레코드로는 리포트 뷰에 들어가지 않는다');
    assert.equal(dest, null, 'go 미호출');
  });
});

// ── T-06.3.3: 부팅 뷰 결정·상태 없는 해시 딥링크 강등(B-1) ────────────────────
// SP-FE-3.3 규칙 (3)("상태가 없으면 search")의 술어를 코드로 옮긴 지점. 결정은 순수 함수가
// 소유하므로 브라우저 없이 검증한다.
describe('T-06.3.3 resolveBootScreen (UT-ROUTE-3·4)', () => {
  test('UT-ROUTE-3: 해시별 결정표', () => {
    // #report — 상태도 레코드도 없으면 강등(빈 #report-body 방지, B-1의 본체)
    assert.deepEqual(resolveBootScreen({ want: 'report' }), { screen: 'search', restore: false });
    // #report + 복원 재료 있음 → 검색으로 두되 복원을 시도하라고 지시(이동은 boot이 소유)
    assert.deepEqual(resolveBootScreen({ want: 'report', recentCount: 1 }), { screen: 'search', restore: true });
    // #report + 이미 렌더된 리포트(popstate 경로) → 그대로 유지
    assert.deepEqual(resolveBootScreen({ want: 'report', hasReport: true }), { screen: 'report', restore: false });
    // 프리필 > 자동 복원(규칙 5): 슬롯이 이미 차 있으면 레코드가 있어도 복원하지 않는다
    assert.deepEqual(
      resolveBootScreen({ want: 'report', hasSlotState: true, recentCount: 1 }),
      { screen: 'input', restore: false },
    );
    // #input — 슬롯 없으면 막다른 입력 뷰가 되므로 강등
    assert.deepEqual(resolveBootScreen({ want: 'input' }), { screen: 'search', restore: false });
    assert.deepEqual(resolveBootScreen({ want: 'input', hasSlotState: true }), { screen: 'input', restore: false });
    // #search — 항상 search(프리필이 있어도 현행 동작 보존)
    assert.deepEqual(resolveBootScreen({ want: 'search', hasSlotState: true }), { screen: 'search', restore: false });
    // 해시 없음/미지 — 기존 폴백 계약 유지
    assert.deepEqual(resolveBootScreen({ want: null }), { screen: 'search', restore: false });
    assert.deepEqual(resolveBootScreen({ want: null, hasSlotState: true }), { screen: 'input', restore: false });
    assert.deepEqual(resolveBootScreen(), { screen: 'search', restore: false }); // 인자 없음 방어
  });

  test('UT-ROUTE-4: #company는 상태와 무관하게 딥링크 진입 불가', () => {
    // company 뷰는 GNB 검색어(term)로만 렌더되므로 복원 가능한 상태가 원리적으로 없다.
    assert.deepEqual(resolveBootScreen({ want: 'company' }), { screen: 'search', restore: false });
    assert.deepEqual(resolveBootScreen({ want: 'company', recentCount: 5 }), { screen: 'search', restore: false });
    assert.deepEqual(
      resolveBootScreen({ want: 'company', hasSlotState: true }),
      { screen: 'input', restore: false },
    );
  });

  test('UT-ROUTE-5: hasSlotState — 직접 입력 슬롯도 상태로 인정', () => {
    const s = createInitialState();
    assert.equal(hasSlotState(s), false, '초기 상태는 상태 없음(기존 prefilled와 동일)');
    s.matched.a = { comp_id: 1 };
    assert.equal(hasSlotState(s), true);
    const s2 = createInitialState();
    s2.inputMode.a = 'direct';
    assert.equal(hasSlotState(s2), true, '직접 입력 모드는 matched가 null이어도 상태');
    const s3 = createInitialState();
    s3.chosenType.b = 'startup';
    assert.equal(hasSlotState(s3), true);
  });
});

// ── B-1: 해시 딥링크 강등·자동 복원(boot·popstate 통합) ──────────────────────
describe('B-1 해시 딥링크 강등', () => {
  const REF = {
    company_types: [
      { comp_tp_cd: 'large', growth_rate_val: 0.04, stability_score_no: 90 },
      { comp_tp_cd: 'startup', growth_rate_val: 0.1, stability_score_no: 40 },
    ],
    benefit_presets: {},
    companies: [
      { comp_id: 1, comp_nm: 'A사', comp_tp_cd: 'large', benefits: [] },
      { comp_id: 2, comp_nm: 'B사', comp_tp_cd: 'startup', benefits: [] },
    ],
  };
  const bootHooks = {
    loadReferenceFn: async () => REF,
    mountAdsFn: () => {},
    initConsentBannerFn: () => {},
  };

  // 레코드를 목으로 만들지 않고 실제 저장 경로(runReport → saveRecentComparison)로 심는다.
  function seedRecord() {
    const seed = createInitialState();
    seed.REF = REF;
    seed.salS.a = { low: 5000, high: 5000 };
    seed.selectedRate = 10;
    seed.matched.a = { comp_id: 1, comp_nm: 'A사', comp_tp_cd: 'large', work_style_val: {} };
    seed.matched.b = { comp_id: 2, comp_nm: 'B사', comp_tp_cd: 'startup', work_style_val: {} };
    runReport({ state: seed, renderReportFn: () => {}, mountEl: { fake: true } });
    assert.equal(recent.list().length, 1, '사전조건: 복원 재료 1건');
  }

  test('UT-BOOT-1: #report + 레코드 없음 → search 강등(빈 리포트 금지)', async () => {
    globalThis.location.hash = '#report';
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'search');
  });

  test('UT-BOOT-2: #company 직접 진입 → search 강등(백지 금지)', async () => {
    globalThis.location.hash = '#company';
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'search');
  });

  test('UT-BOOT-3: #report + 레코드 있음 → 복원 후 report 유지', async () => {
    seedRecord();
    globalThis.location.hash = '#report';
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'report');
    // 화면 이름만 보면 결함 코드도 우연히 통과하므로 상태 복원까지 단언한다.
    assert.equal(App.state.matched.a.comp_id, 1);
    assert.equal(App.state.matched.b.comp_id, 2);
    assert.equal(App.state.selectedRate, 10);
    assert.equal(globalThis.history._calls.length, 0, '부팅 복원은 pushState를 발생시키지 않는다');
  });

  test('UT-BOOT-4: 프리필(?a=1&b=2) → input 진입(기존 계약 보존)', async () => {
    globalThis.location.search = '?a=1&b=2';
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'input');
  });

  test('UT-BOOT-5: 프리필 + #report → input(프리필 우선, 자동 복원 미시도)', async () => {
    seedRecord();
    globalThis.location.search = '?a=1&b=2';
    globalThis.location.hash = '#report';
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'input');
    assert.equal(App.state.selectedRate, null, '레코드(10)가 프리필 슬롯을 덮지 않음');
  });

  test('UT-BOOT-6: 해시 없음 → search(기존 폴백 계약 유지)', async () => {
    await boot(bootHooks);
    assert.equal(App.state.ui.screen, 'search');
  });

  test('INV-1: 부팅 자동 복원은 새 비교가 아니므로 비교 로그를 보내지 않는다', async () => {
    // sendCompareLog의 실제 전송 경로(navigator.sendBeacon → fetch)를 프로덕션과 동일하게 탄다.
    seedRecord();
    const origFetch = globalThis.fetch;
    const sent = [];
    globalThis.fetch = (url) => { sent.push(String(url)); return Promise.resolve({ ok: true }); };
    try {
      globalThis.location.hash = '#report';
      await boot(bootHooks);
    } finally {
      globalThis.fetch = origFetch;
    }
    // 복원이 실제로 일어났음을 먼저 확인해야 이 테스트가 공허하지 않다.
    assert.equal(App.state.ui.screen, 'report', '사전조건: 복원 성공');
    assert.equal(App.state.matched.a.comp_id, 1);
    const logs = sent.filter((u) => u.includes(COMPARE_LOG_URL));
    assert.deepEqual(logs, [], '새로고침마다 실시간 TOP 10 집계가 오염되면 안 됨');
  });

  test('restoreLatestComparison — 레코드 없으면 false(무크래시)', () => {
    assert.equal(restoreLatestComparison({}, createInitialState()), false);
  });

  // 개정(2026-07-20, 유령 리포트): e.state.screen을 무조건 신뢰하던 계약을 폐기한다.
  // "새 비교"가 상태를 비우고 렌더된 DOM까지 지우면, 그 뒤 뒤로가기로 돌아온 report 항목은
  // 보여줄 것이 없다. 무조건 신뢰하면 빈 리포트(B-1 재현)가, 지우지 않으면 유령 리포트(오정보)가
  // 된다. → e.state가 있어도 부팅과 동일한 상태 술어로 판정한다.
  test('UT-POP-1: popstate — e.state가 있어도 보여줄 상태가 없으면 강등', () => {
    onPopState({ state: { screen: 'report' } }); // 상태 비어 있음(초기 App.state)
    assert.equal(App.state.ui.screen, 'search');
    assert.equal(globalThis.history._calls.length, 0, '재푸시 금지');
  });

  test('UT-POP-1b: popstate — 슬롯이 살아 있으면 input 항목은 그대로 복원(정상 뒤로가기 보존)', () => {
    App.state.matched.a = { comp_id: 1, comp_nm: 'A사' };
    onPopState({ state: { screen: 'input' } });
    assert.equal(App.state.ui.screen, 'input', '세션 내 정상 뒤로/앞으로는 회귀하면 안 된다');
    assert.equal(globalThis.history._calls.length, 0);
  });

  test('UT-POP-3: popstate — 해시 없는 무상태 항목은 슬롯이 있어도 search(뒤로가기 먹통 방지)', () => {
    App.state.matched.a = { comp_id: 1, comp_nm: 'A사' };
    globalThis.location.hash = '';
    onPopState({});
    // 부팅 폴백(슬롯 있으면 input)을 popstate에 적용하면 입력 뷰에 눌러앉아 뒤로가기가 죽는다.
    assert.equal(App.state.ui.screen, 'search');
  });

  test('UT-POP-2: popstate — e.state 없는 #report는 강등, 자동 복원 미시도', () => {
    seedRecord();
    globalThis.location.hash = '#report';
    onPopState({});
    assert.equal(App.state.ui.screen, 'search');
    assert.equal(App.state.matched.a, null, 'popstate는 자동 복원하지 않는다');
  });
});

// ── #12: 광고·동의 배너 배선(dead code 해소) ────────────────────────────────
describe('#12 boot() 광고·동의 배선', () => {
  test('boot 성공 → mountAds·initConsentBanner 각 1회 호출', async () => {
    const ref = { company_types: [], benefit_presets: {}, companies: [] };
    let ads = 0, consent = 0;
    await boot({
      loadReferenceFn: async () => ref,
      mountAdsFn: () => { ads += 1; },
      initConsentBannerFn: () => { consent += 1; },
    });
    assert.equal(ads, 1, 'mountAds 배선(랜딩 등 page_type)');
    assert.equal(consent, 1, 'initConsentBanner 배선');
  });
});

// ── 입력 초안(2026-07-31) — 복지를 보러 다녀와도 입력이 살아 있어야 한다 ──────
// 2단계(디렉터리 클릭 → 정적 페이지 이동)가 이 보호 없이는 사용자 입력을 날린다.
describe('입력 초안 snapshotInput·restoreInputDraft', () => {
  function refState() {
    const st = createInitialState();
    st.REF = {
      company_types: [], benefit_presets: { large: [] },
      companies: [
        { comp_id: 1, comp_nm: '삼성전자', comp_eng_nm: 'samsung_elec', comp_tp_cd: 'large',
          benefits: [{ benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 240, benefit_ctgr_cd: 'perks', badge_cd: 'official', amt_source: 'stated', qual_yn: false },
                     { benefit_cd: 'bus', benefit_nm: '통근버스', benefit_amt: 120, benefit_ctgr_cd: 'perks', badge_cd: 'est', amt_source: 'estimated', qual_yn: false }] },
        { comp_id: 2, comp_nm: 'SK하이닉스', comp_eng_nm: 'sk_hynix', comp_tp_cd: 'large', benefits: [] },
      ],
    };
    return st;
  }
  beforeEach(() => { globalThis.localStorage.clear(); });

  test('snapshotInput 은 식별자만 담는다(복지 배열을 통째로 넣지 않는다)', () => {
    const st = refState();
    restoreInputDraft(st, { draft: { slots: { a: { comp_id: 1 } } }, reflect: () => {} });
    st.salS.a = { low: 4000, high: 6000 };
    st.selectedRate = 10;
    const snap = snapshotInput(st);
    assert.equal(snap.slots.a.comp_id, 1);
    assert.deepEqual(snap.slots.a.checked, ['meal', 'bus'], '체크 상태는 cd 목록으로');
    assert.equal(JSON.stringify(snap).includes('benefit_nm'), false, '복지 본문이 스냅샷에 새면 낡은 값이 되살아난다');
    assert.deepEqual(snap.salS.a, { low: 4000, high: 6000 });
    assert.equal(snap.selectedRate, 10);
  });

  test('왕복 — 회사·연봉·상승률·우선순위가 되살아난다', () => {
    const a = refState();
    restoreInputDraft(a, { draft: { slots: { a: { comp_id: 1 }, b: { comp_id: 2 } } }, reflect: () => {} });
    a.salS.a = { low: 4000, high: 6000 };
    a.selectedRate = 12;
    a.curPri = '연봉';
    a.cmtS = { a: 30, b: 50 };
    inputDraft.save(snapshotInput(a), 1000);

    const b = refState();
    assert.equal(restoreInputDraft(b, { draft: inputDraft.load(1000), reflect: () => {} }), true);
    assert.equal(b.matched.a.comp_id, 1);
    assert.equal(b.matched.b.comp_id, 2);
    assert.deepEqual(b.salS.a, { low: 4000, high: 6000 });
    assert.equal(b.selectedRate, 12);
    assert.equal(b.curPri, '연봉');
    assert.deepEqual(b.cmtS, { a: 30, b: 50 });
    assert.equal(b.benS.a.length, 2, '복지는 REF 최신본에서 다시 채운다');
  });

  test('체크 해제가 보존된다(기본은 전부 체크라 복원 안 하면 조용히 뒤집힌다)', () => {
    const st = refState();
    restoreInputDraft(st, { draft: { slots: { a: { comp_id: 1, checked: ['meal'] } } }, reflect: () => {} });
    assert.deepEqual(st.benS.a.map((b) => [b.benefit_cd, b.checked]), [['meal', true], ['bus', false]]);
  });

  test('REF 에 없는 회사(시드에서 사라진 초안) → 조용히 건너뛴다', () => {
    const st = refState();
    const ok = restoreInputDraft(st, { draft: { slots: { a: { comp_id: 999 } }, selectedRate: 5 }, reflect: () => {} });
    assert.equal(ok, false, '되살린 슬롯이 없다');
    assert.equal(st.matched.a, null);
    assert.equal(st.selectedRate, 5, '스칼라는 그래도 복원된다');
  });

  test('직접 입력 유형도 복원된다(프리셋 경로)', () => {
    const st = refState();
    restoreInputDraft(st, { draft: { slots: { b: { comp_tp_cd: 'large' } } }, reflect: () => {} });
    assert.equal(st.chosenType.b, 'large');
    assert.equal(st.inputMode.b, 'direct');
  });

  test('초안 없음 → no-op(false)', () => {
    const st = refState();
    assert.equal(restoreInputDraft(st, { draft: null }), false);
  });

  test('bindDraftPersist — 저장이 throw 해도 삼킨다(비교 흐름 무손상)', () => {
    const persist = bindDraftPersist({ save: () => { throw new Error('quota'); }, state: refState() });
    assert.doesNotThrow(persist);
  });
});

// ── 초안이 화면을 가로채지 않는다(2026-07-31) ────────────────────────────────
// 부팅 폴백이 "슬롯 있으면 input" 이라, 초안 복원이 대문을 입력 화면으로 바꿔 버렸다.
// 신규 방문자가 히어로·등록 회사 목록·광고가 있는 랜딩 대신 남의 입력을 본다.
describe('boot — 초안은 상태만 되살리고 화면은 URL 이 정한다', () => {
  const REF = {
    company_types: [], benefit_presets: {},
    companies: [{ comp_id: 1, comp_nm: '삼성전자', comp_eng_nm: 'samsung_elec', comp_tp_cd: 'large', benefits: [] }],
  };
  function seedDraft() {
    globalThis.localStorage.setItem('loupit.inputDraft', JSON.stringify({
      v: 1, savedAt: Date.now(), draft: { slots: { a: { comp_id: 1 } }, salS: { a: { low: 4000, high: 5000 } } },
    }));
  }

  test('초안만 있고 URL 이 조용하면 → 대문은 search 유지', async () => {
    seedDraft();
    await boot({ loadReferenceFn: async () => REF });
    assert.equal(App.state.ui.screen, 'search', '대문이 입력 화면으로 바뀌면 랜딩이 사라진다');
    assert.equal(App.state.matched.a.comp_id, 1, '상태는 되살아나 있어야 한다');
    assert.deepEqual(App.state.salS.a, { low: 4000, high: 5000 });
  });

  test('URL 프리필이 있으면 → input(기존 계약 유지)', async () => {
    seedDraft();
    globalThis.location.search = '?a=samsung_elec';
    await boot({ loadReferenceFn: async () => REF });
    assert.equal(App.state.ui.screen, 'input');
  });

  test('#input 새로고침이면 → input(사용자가 그 화면에 있었다)', async () => {
    seedDraft();
    globalThis.location.hash = '#input';
    await boot({ loadReferenceFn: async () => REF });
    assert.equal(App.state.ui.screen, 'input');
  });

  test('초안이 없으면 종전과 동일(하위호환)', async () => {
    await boot({ loadReferenceFn: async () => REF });
    assert.equal(App.state.ui.screen, 'search');
  });
});
