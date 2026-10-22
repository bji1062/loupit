// web/assets/js/compare-lazy.test.js — 비교 화면은 부팅 때 가벼운 목록만 받고, 회사 상세(복지 행)는 쓰는 순간 받는다 (2026-10-22).
//
// 가장 큰 함정: 상세 없는 회사 객체가 normalizeCompany → fillBenefits 로 흘러 「복지 0개 회사」로 조용히 그려지는 것.
// 상세가 필요한 모든 지점(초안 · 프리필 · 최근 비교 · 많이 본 조합 · 회사 고르기 · GNB 회사 페이지)을 실 셸(jsdom)에서 잰다.
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, querySelector() { return null; }, createElement() { return {}; } };
globalThis.history = { pushState() {} };
globalThis.location = { hash: '', search: '' };

import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { JSDOM } from 'jsdom';

import {
  App, createInitialState, boot, runReport, restoreFromPrefill, restoreInputDraft, pickTrendingPair, restoreComparison,
  pickTrendingPairLoaded, restoreComparisonLoaded, showCompanyPage, resolveFullCompany, bootCompanyIds,
} from './app.js';
import { selectCompany } from './inputs.js';
import { hasDetail } from './company-store.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const SHELL = readFileSync(join(HERE, '../../compare/index.html'), 'utf8');
const CASES = JSON.parse(readFileSync(join(HERE, '../../../generator/tests/data/compare_index_cases.json'), 'utf8'));
const clone = (x) => JSON.parse(JSON.stringify(x));

// 리포트 계산이 유형별 성장률 · 안정성을 읽는다 — 픽스처의 유형에 얹는다(번들 · 목록 둘 다 같은 값).
const TYPES = [
  { comp_tp_id: 1, comp_tp_cd: 'large', comp_tp_nm: '대기업', growth_rate_val: 0.04, stability_score_no: 90 },
  { comp_tp_id: 2, comp_tp_cd: 'startup', comp_tp_nm: '스타트업', growth_rate_val: 0.1, stability_score_no: 40 },
];
const REF_ALL = { ...clone(CASES.bundle), company_types: TYPES };
const REF_INDEX = { ...clone(CASES.index), company_types: TYPES };
const DETAILS = CASES.details;
const KT = 1; const NAVER = 3;

const HOOKS = { mountAdsFn: () => {}, initConsentBannerFn: () => {}, navTypeFn: () => 'reload' };
const settle = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const okJson = (body) => ({ ok: true, status: 200, json: async () => body });

/** fetch 목 — /reference/* 요청만 log 에 쌓는다. fail: 상세를 503 으로 돌려줄 id, wait: id → 지연(ms). */
function installFetch({ indexStatus = 200, fail = [], wait = {} } = {}) {
  const log = [];
  globalThis.fetch = async (url) => {
    const u = String(url);
    if (u.includes('/reference/index')) {
      log.push('index');
      return indexStatus === 200 ? okJson(clone(REF_INDEX)) : { ok: false, status: indexStatus, json: async () => ({}) };
    }
    if (u.includes('/reference/all')) { log.push('all'); return okJson(clone(REF_ALL)); }
    const m = u.match(/\/reference\/companies\/(\d+)/);
    if (m) {
      const id = Number(m[1]);
      log.push('company:' + id);
      if (wait[id]) await settle(wait[id]);
      return fail.includes(id) ? { ok: false, status: 503, json: async () => ({}) } : okJson(clone(DETAILS[String(id)]));
    }
    return okJson({ items: [] }); // 많이 본 조합 위젯 등
  };
  return log;
}

function loadShell(url = 'https://loupit.example/compare/') {
  const dom = new JSDOM(SHELL, { url, pretendToBeVisual: true });
  dom.window.scrollTo = () => {}; // jsdom 은 구현이 없다(go() 가 부른다)
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  globalThis.history = dom.window.history;
  globalThis.location = dom.window.location;
  globalThis.localStorage = dom.window.localStorage;
  globalThis.localStorage.clear();
  App.state = createInitialState();
  return dom;
}

/** 번들 전체 상태에서 비교를 한 번 끝까지 돌려 최근 비교 레코드를 심는다(프로덕션 저장 경로). */
function seedRecent() {
  const seed = createInitialState();
  seed.REF = clone(REF_ALL);
  seed.salS.a = { low: 5000, high: 5000 };
  seed.selectedRate = 10;
  seed.matched.a = { comp_id: KT, comp_nm: 'KT', comp_tp_cd: 'large', work_style_val: {} };
  seed.matched.b = { comp_id: NAVER, comp_nm: '네이버', comp_tp_cd: 'large', work_style_val: {} };
  runReport({ state: seed, renderReportFn: () => {}, mountEl: { fake: true } });
}

const seedDraft = (slots) => globalThis.localStorage.setItem('loupit.inputDraft', JSON.stringify({
  v: 1, savedAt: Date.now(), draft: { slots, salS: { a: { low: 4000, high: 5000 } } },
}));
const expectedN = (id) => DETAILS[String(id)].benefits.length;
const calls = (log, kind) => log.filter((x) => x === kind || x.startsWith(kind + ':'));

describe('부팅', () => {
  test('아무것도 복원할 게 없으면 목록 1회 · 상세 0회', async () => {
    const log = installFetch();
    loadShell();
    await boot(HOOKS);
    assert.deepEqual(log, ['index']);
    assert.equal(App.state.REF.companies.length, 8);
    assert.ok(App.state.REF.companies.every((c) => !hasDetail(c)), '복지 행은 목록에 없다');
    assert.equal(App.state.REF.category_stats.total, 8);
    assert.equal(document.querySelector('.dir-count-n').textContent, '8', '디렉터리 개수는 목록만으로');
    assert.match(document.querySelector('.dir-comp-meta').textContent, /복지 \d+개/, '복지 수는 미리 센 benefit_n');
  });

  test('?a=&b= 진입 → 두 상세를 받은 뒤 기존 프리필 그대로(복지 비교로)', async () => {
    const log = installFetch();
    loadShell('https://loupit.example/compare/?a=kt&b=naver');
    await boot(HOOKS);
    assert.deepEqual(log.slice().sort(), ['company:1', 'company:3', 'index']);
    assert.equal(App.state.matched.a.comp_id, KT);
    assert.equal(App.state.matched.b.comp_id, NAVER);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT), '복지 0개 회사로 그려지지 않는다');
    assert.equal(App.state.benS.b.length, expectedN(NAVER));
    assert.equal(App.state.ui.screen, 'benefits');
  });

  test('초안 복원 — 상세를 받아 두 슬롯 복지를 다시 채운다 · 화면은 가로채지 않는다', async () => {
    const log = installFetch();
    loadShell();
    seedDraft({ a: { comp_id: KT }, b: { comp_id: NAVER } });
    await boot(HOOKS);
    assert.deepEqual(calls(log, 'company').sort(), ['company:1', 'company:3']);
    assert.equal(App.state.benS.a.length, expectedN(KT));
    assert.equal(App.state.benS.b.length, expectedN(NAVER));
    assert.equal(App.state.ui.screen, 'search');
  });

  test('새 진입(navigate)이면 초안을 지우므로 상세도 안 받는다', async () => {
    const log = installFetch();
    loadShell();
    seedDraft({ a: { comp_id: KT } });
    await boot({ ...HOOKS, navTypeFn: () => 'navigate' });
    assert.deepEqual(log, ['index']);
  });

  test('#report 최근 비교 자동 복원 — 상세를 받아 리포트까지', async () => {
    const log = installFetch();
    loadShell('https://loupit.example/compare/#report');
    seedRecent();
    await boot(HOOKS);
    assert.deepEqual(calls(log, 'company').sort(), ['company:1', 'company:3']);
    assert.equal(App.state.ui.screen, 'report');
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT));
  });

  test('#report 가 아니면 최근 비교 때문에 상세를 받지 않는다', async () => {
    const log = installFetch();
    loadShell();
    seedRecent();
    await boot(HOOKS);
    assert.deepEqual(log, ['index']);
  });

  test('프리필 상세 받기 실패 → 그 슬롯만 비움 · 빈 복지로 그리지 않음 · 슬롯 오류 안내', async () => {
    const log = installFetch({ fail: [NAVER] });
    loadShell('https://loupit.example/compare/?a=kt&b=naver');
    await boot(HOOKS);
    assert.equal(App.state.matched.a.comp_id, KT);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT));
    assert.equal(App.state.matched.b, null, '상세 없는 회사는 없는 회사와 같다');
    assert.equal(App.state.benS.b.length, 0);
    assert.equal(document.querySelector('.search-error[data-slot="b"]').hidden, false, '기존 슬롯 오류 안내');
    assert.equal(document.querySelector('.search-error[data-slot="a"]').hidden, true);
    assert.equal(App.state.ui.screen, 'search', '한 슬롯만 찼으니 검색 뷰');
    assert.ok(log.includes('company:3'));
  });

  test('초안 상세 받기 실패 → 그 슬롯은 복원 안 함(복지 0개로 되살리지 않는다)', async () => {
    installFetch({ fail: [KT] });
    loadShell();
    seedDraft({ a: { comp_id: KT }, b: { comp_id: NAVER } });
    await boot(HOOKS);
    assert.equal(App.state.matched.a, null);
    assert.equal(App.state.matched.b.comp_id, NAVER);
    assert.equal(document.querySelector('.search-error[data-slot="a"]').hidden, false);
  });

  test('목록이 404 → /reference/all 폴백 부팅이 예전과 같다(상세 요청 0)', async () => {
    const log = installFetch({ indexStatus: 404 });
    loadShell('https://loupit.example/compare/?a=kt&b=naver');
    await boot(HOOKS);
    assert.deepEqual(log, ['index', 'all']);
    assert.ok(App.state.REF.companies.every(hasDetail));
    assert.equal(App.state.REF.category_stats, undefined);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT));
    assert.equal(App.state.ui.screen, 'benefits');
  });

  test('복지 비교 화면 눈금이 목록으로 부팅해도 번들 부팅과 같다', async () => {
    const run = async (indexStatus) => {
      installFetch({ indexStatus });
      loadShell('https://loupit.example/compare/?a=kt&b=naver');
      await boot(HOOKS);
      return document.getElementById('benefits-body').innerHTML;
    };
    const viaIndex = await run(200);
    const viaAll = await run(404);
    assert.ok(viaIndex.length > 200);
    assert.equal(viaIndex, viaAll, '화면 글자까지 같다');
  });
});

describe('동기 경로의 「상세 있음」 확인 — 상세 없는 회사는 없는 회사와 같다', () => {
  const light = () => { const s = createInitialState(); s.REF = clone(REF_INDEX); return s; };

  test('resolveFullCompany: 목록의 회사는 null, 상세가 붙으면 객체', () => {
    const s = light();
    assert.equal(resolveFullCompany('kt', s), null);
    s.REF.companies[0].benefits = [];
    assert.equal(resolveFullCompany('kt', s).comp_id, KT);
  });

  test('restoreFromPrefill 은 슬롯을 채우지 않는다', () => {
    const s = light();
    globalThis.location = { hash: '', search: '?a=kt&b=naver' };
    assert.equal(restoreFromPrefill(s, { goFn: () => assert.fail('이동하면 안 된다') }), false);
    assert.equal(s.matched.a, null);
    assert.equal(s.benS.a.length, 0);
  });

  test('restoreInputDraft 는 그 슬롯을 건너뛴다', () => {
    const s = light();
    assert.equal(restoreInputDraft(s, { draft: { slots: { a: { comp_id: KT } } }, reflect: () => {} }), false);
    assert.equal(s.matched.a, null);
  });

  test('pickTrendingPair 는 false · 상태 불변', () => {
    const s = light();
    assert.equal(pickTrendingPair({ a_comp_id: KT, b_comp_id: NAVER }, { go: () => assert.fail('이동') }, s), false);
    assert.equal(s.matched.a, null);
  });

  test('restoreComparison 은 상세 없는 슬롯을 비운다', () => {
    const s = light();
    const record = { slots: { a: { comp_id: KT }, b: { comp_id: NAVER } }, input: {} };
    restoreComparison(record, { runReport: () => ({ ok: false }), go: () => {} }, s);
    assert.equal(s.matched.a, null);
    assert.equal(s.benS.a.length, 0);
  });

  test('bootCompanyIds: 초안 · URL · (#report 일 때만) 최근 비교', () => {
    loadShell('https://loupit.example/compare/?a=naver');
    seedDraft({ a: { comp_id: KT } });
    seedRecent();
    const s = light();
    assert.deepEqual(bootCompanyIds(s).map((f) => f.id).sort(), [1, 3]);
    assert.deepEqual(bootCompanyIds(s, { fresh: true }).map((f) => f.id), [3], '새 진입이면 초안은 쓰지 않는다');
    window.location.hash = '#report';
    assert.deepEqual(bootCompanyIds(s).map((f) => f.id).sort(), [1, 1, 3, 3]);
  });
});

describe('누를 때 상세 받기', () => {
  async function booted(opts) {
    const log = installFetch(opts);
    loadShell();
    await boot(HOOKS);
    log.length = 0;
    return log;
  }

  test('selectCompany: 목록의 회사는 받아서 채운다 · 이미 받은 회사는 요청 0', async () => {
    const log = await booted();
    assert.equal(await selectCompany(App.state, 'a', KT, {}), true);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT));
    assert.equal(App.state.benS.a.length, expectedN(KT));
    assert.deepEqual(log, ['company:1']);
    await selectCompany(App.state, 'b', KT, { notify: () => {} }); // 같은 회사 가드가 막지만 상세는 이미 있다
    assert.deepEqual(log, ['company:1'], '다시 받지 않는다');
  });

  test('selectCompany: 같은 회사를 동시에 두 번 눌러도 요청 1', async () => {
    const log = await booted({ wait: { [NAVER]: 20 } });
    await Promise.all([selectCompany(App.state, 'a', NAVER, {}), selectCompany(App.state, 'b', NAVER, { notify: () => {} })]);
    assert.deepEqual(log, ['company:3']);
  });

  test('selectCompany: 연타하면 늦은 응답은 폐기 — 마지막 선택만 반영', async () => {
    await booted({ wait: { [KT]: 40 } });
    const slow = selectCompany(App.state, 'a', KT, {});
    const fast = selectCompany(App.state, 'a', NAVER, {});
    assert.equal(await fast, true);
    assert.equal(await slow, false);
    assert.equal(App.state.matched.a.comp_id, NAVER);
  });

  test('selectCompany: 받기 실패 → 슬롯 오류 · 미선택 유지', async () => {
    await booted({ fail: [KT] });
    let shown = null;
    assert.equal(await selectCompany(App.state, 'a', KT, { showSlotError: (slot) => { shown = slot; } }), false);
    assert.equal(shown, 'a');
    assert.equal(App.state.matched.a, null);
  });

  test('많이 본 조합 클릭 → 두 상세를 받고 프리필', async () => {
    const log = await booted();
    let went = null;
    const ok = await pickTrendingPairLoaded({ a_comp_id: KT, b_comp_id: NAVER }, { go: (s) => { went = s; } }, App.state);
    assert.equal(ok, true);
    assert.deepEqual(log.slice().sort(), ['company:1', 'company:3']);
    assert.equal(App.state.matched.b.benefits.length, expectedN(NAVER));
    assert.equal(went, 'benefits');
  });

  test('많이 본 조합 클릭 — 받기 실패하면 상태 불변 + 짧은 안내', async () => {
    await booted({ fail: [NAVER] });
    const ok = await pickTrendingPairLoaded({ a_comp_id: KT, b_comp_id: NAVER }, { go: () => assert.fail('이동') }, App.state);
    assert.equal(ok, false);
    assert.equal(App.state.matched.a, null, '반쪽 프리필도 하지 않는다');
    assert.equal(document.getElementById('ui-notify').textContent, '회사 정보를 불러오지 못했습니다. 다시 눌러 주세요.');
  });

  test('많이 본 조합 연타 — 마지막 클릭만 반영', async () => {
    await booted({ wait: { [KT]: 40 } });
    const wentTo = [];
    const first = pickTrendingPairLoaded({ a_comp_id: KT, b_comp_id: NAVER }, { go: (s) => wentTo.push('first:' + s) }, App.state);
    const second = pickTrendingPairLoaded({ a_comp_id: 2, b_comp_id: NAVER }, { go: (s) => wentTo.push('second:' + s) }, App.state);
    assert.equal(await second, true);
    assert.equal(await first, false);
    assert.deepEqual(wentTo, ['second:benefits']);
    assert.equal(App.state.matched.a.comp_id, 2);
  });

  test('최근 비교 「불러오기」 — 상세를 받은 뒤 복원 · 실패하면 상태 불변', async () => {
    await booted();
    seedRecent();
    const { recent } = await import('./store.js');
    const record = recent.list()[0];
    let ran = 0;
    const deps = { runReport: () => { ran += 1; }, go: () => {} };
    assert.equal(await restoreComparisonLoaded(record, deps, App.state), true);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT));
    assert.equal(ran, 1);

    // 실패 갈래: 새 상태 · 새 서버(네이버 503)
    installFetch({ fail: [NAVER] });
    const s2 = createInitialState();
    s2.REF = clone(REF_INDEX);
    assert.equal(await restoreComparisonLoaded(record, deps, s2), false);
    assert.equal(s2.matched.a, null, '일부만 복원하지 않는다');
    assert.equal(ran, 1, '리포트를 다시 돌리지 않는다');
  });
});

describe('GNB 검색 → 회사 복지 페이지', () => {
  const page = () => document.getElementById('company-page');

  async function booted(opts) {
    const log = installFetch(opts);
    loadShell();
    await boot(HOOKS);
    log.length = 0;
    return log;
  }

  test('한 곳 일치 — 받는 동안 「불러오는 중…」 → 상세', async () => {
    const log = await booted({ wait: { [KT]: 20 } });
    assert.equal(showCompanyPage('KT', {}, App.state), true);
    assert.match(page().textContent, /불러오는 중/);
    assert.doesNotMatch(page().textContent, /등록된 복지 정보가 없습니다/);
    await settle(60);
    assert.deepEqual(log, ['company:1']);
    assert.match(page().textContent, /사내 체육관/);
    assert.doesNotMatch(page().textContent, /불러오는 중/);
  });

  test('한 곳 일치 — 받기 실패하면 안내 · 빈 복지로 그리지 않는다', async () => {
    await booted({ fail: [KT] });
    showCompanyPage('KT', {}, App.state);
    await settle(30);
    assert.match(page().textContent, /회사 정보를 불러오지 못했습니다\. 다시 눌러 주세요\./);
    assert.doesNotMatch(page().textContent, /등록된 복지 정보가 없습니다/);
  });

  test('여러 곳 일치 — 목록은 바로(요청 0) · 후보 클릭 때 받고 그린다', async () => {
    const log = await booted();
    showCompanyPage('상사', {}, App.state); // 마지막상사 · 몰빵상사
    assert.deepEqual(log, [], '후보 목록은 목록만으로');
    const cands = page().querySelectorAll('.cp-cand');
    assert.equal(cands.length, 2);
    const target = [...cands].find((b) => b.textContent.includes('마지막상사'));
    target.click();
    await settle(30);
    assert.deepEqual(log, ['company:8']);
    assert.match(page().textContent, /마지막상사/);
    assert.match(page().textContent, /사내 체육관/);
  });

  test('후보 클릭 실패 — 목록은 그대로 두고 안내만', async () => {
    await booted({ fail: [8] });
    showCompanyPage('상사', {}, App.state);
    [...page().querySelectorAll('.cp-cand')].find((b) => b.textContent.includes('마지막상사')).click();
    await settle(30);
    assert.equal(page().querySelectorAll('.cp-cand').length, 2, '다시 누를 수 있다');
    assert.match(page().querySelector('.cp-error').textContent, /다시 눌러 주세요/);
  });

  test('후보 연타 — 늦은 응답은 폐기, 마지막으로 누른 회사만 그린다', async () => {
    await booted({ wait: { 8: 50 } });
    showCompanyPage('상사', {}, App.state);
    const btns = [...page().querySelectorAll('.cp-cand')];
    btns.find((b) => b.textContent.includes('마지막상사')).click(); // 느림
    btns.find((b) => b.textContent.includes('몰빵상사')).click();   // 빠름
    await settle(90);
    assert.match(page().querySelector('.cp-nm').textContent, /몰빵상사/);
    assert.doesNotMatch(page().textContent, /마지막상사/);
  });

  test('「이 회사와 비교 시작」 — 이미 받은 상세로 A 슬롯을 채운다(추가 요청 0)', async () => {
    const log = await booted();
    let went = null;
    showCompanyPage('KT', { go: (s) => { went = s; } }, App.state);
    await settle(30);
    assert.deepEqual(log, ['company:1']);
    page().querySelector('.cp-compare-cta').click();
    assert.deepEqual(log, ['company:1']);
    assert.equal(App.state.matched.a.benefits.length, expectedN(KT), '복지 0개 회사가 아니다');
    assert.equal(went, 'search');
  });
});
