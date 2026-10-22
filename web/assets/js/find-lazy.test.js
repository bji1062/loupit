// web/assets/js/find-lazy.test.js — 복지검색 「가벼운 묶음 + 코드별 설명」이 번들 전체와 같은 화면을 내는가 (2026-10-22, /find 경량화).
// 픽스처 `generator/tests/data/find_lazy_cases.json`(만드는 스크립트: make_find_lazy_cases.py — 손으로 고치지 마라)을
// 파이썬 서버 테스트(server/tests/test_reference_cut.py)와 같이 읽는다. 설명이 도착한 뒤 화면은 글자 하나 다르면 안 된다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';

import { amountOf, mountFind, initFind, matchCompanies, renderRow, deriveCodes, sortRows, defaultState } from './find.js';
import { createNoteStore, isLightRef, NOTE_FAILED, NOTE_LOADING, NOTE_RETRY } from './find-notes.js';
import { loadFindBundle, assertFindShape } from './boot.js';
import { ApiError } from './api.js';

const CASES = JSON.parse(readFileSync(fileURLToPath(new URL('../../../generator/tests/data/find_lazy_cases.json', import.meta.url)), 'utf8'));
const clone = (x) => JSON.parse(JSON.stringify(x));
const { bundle, find, notes: NOTES, amount_cases: AMOUNT_CASES } = CASES;

const TEMPLATE = readFileSync(new URL('../../../generator/templates/find.html', import.meta.url), 'utf8');
function toolMarkup() {
  const start = TEMPLATE.indexOf('<section class="find-tool"');
  const end = TEMPLATE.indexOf('\n  </section>', start);
  return TEMPLATE.slice(start, end + '\n  </section>'.length);
}

// 모든 비동기 작업(목 fetch 의 약속 연쇄)이 끝날 때까지 기다린다.
// renderRow 를 직접 부르는 테스트용 문서(el 이 전역 document 를 쓴다) — mount() 가 부를 때마다 새 문서로 바꾼다.
globalThis.document = new JSDOM('<main></main>').window.document;

const flush = async () => { for (let i = 0; i < 8; i += 1) await new Promise((r) => setImmediate(r)); };

function notesFetch(log, { fail = [] } = {}) {
  return async (code) => {
    log.push(code);
    if (fail.includes(code)) throw new ApiError(500, `/reference/notes/${code}`);
    return clone(NOTES[code]);
  };
}

/** 마운트 — `ref` 가 가벼운 묶음이면 설명 저장소가 붙는다. `fetchNotes` 로 설명 요청을 가로챈다. */
function mount({ search = '', ref, fetchNotes } = {}) {
  const dom = new JSDOM(`<main>${toolMarkup()}</main>`, { url: 'https://loupit.example/find' });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  const win = {
    location: { search, assign() {} }, innerWidth: 1200, scrollY: 0,
    addEventListener() {}, removeEventListener() {}, requestAnimationFrame(fn) { fn(); return 1; },
    setTimeout() { return 0; }, clearTimeout() {}, scrollBy() {},
  };
  const history = { replaceState() {} };
  const root = dom.window.document.querySelector('[data-find-tool]');
  root.hidden = false;
  const app = mountFind(root, ref, { win, history, fetchNotes });
  return { dom, doc: dom.window.document, root, app, q: (s) => root.querySelector(s), all: (s) => [...root.querySelectorAll(s)] };
}
const full = (search, extra = {}) => mount({ search, ref: clone(bundle), ...extra });
const light = (search, fetchNotes, extra = {}) => mount({ search, ref: clone(find), fetchNotes, ...extra });

/** 화면 글자 + title 전체(= root.innerHTML) — 두 부팅이 같은 화면인지. */
const screen = (env) => env.root.innerHTML;
/** 설명 칸을 뺀 화면 — 첫 그림에서 설명과 무관한 곳이 같은지. */
function screenNoNotes(env) {
  const copy = env.root.cloneNode(true);
  for (const n of copy.querySelectorAll('.find-hit-d')) n.remove();
  return copy.innerHTML;
}

describe('금액 판정과 「금액 큰 3개」 — 서버 == 화면', () => {
  test('금액 판정: 픽스처 대조표(파이썬이 만든 기대값)와 JS amountOf 가 같다', () => {
    assert.ok(AMOUNT_CASES.length >= 10);
    for (const c of AMOUNT_CASES) assert.equal(amountOf(c.b), c.amount, JSON.stringify(c.b));
  });

  test('회사마다 조건 없음 3개(지금 renderRow 규칙) == 픽스처 top_notes 의 (회사, 코드) — 순서까지 같다', () => {
    const codes = deriveCodes(bundle);
    const rows = sortRows(matchCompanies(bundle, [], defaultState()), 'name');
    const want = new Map();
    for (const t of find.top_notes) {
      if (!want.has(t.comp_id)) want.set(t.comp_id, []);
      want.get(t.comp_id).push(t.benefit_cd);
    }
    let withTop = 0;
    for (const row of rows) {
      const li = renderRow(row, { codes, sel: [] }).querySelectorAll('.find-hit');
      const names = [...li].map((x) => x.querySelector('.find-hit-k').textContent);
      const shownNames = names[0] === '금액 적힌 항목 없음' ? [] : names;
      const wantCodes = want.get(row.company.comp_id) || [];
      const byName = new Map(row.company.benefits.map((b) => [b.benefit_nm, b.benefit_cd]));
      assert.deepEqual(shownNames.map((n) => byName.get(n)), wantCodes, row.company.comp_nm);
      if (wantCodes.length) withTop += 1;
    }
    assert.ok(withTop >= 30 && withTop < rows.length, '금액 있는 회사 · 없는 회사가 둘 다 있다');
  });

  test('모서리: 동률은 번들 순서 · 법정 표시 행 제외 · 정성 행 제외', () => {
    const top = (id) => find.top_notes.filter((t) => t.comp_id === id).map((t) => t.benefit_cd);
    assert.deepEqual(top(1), ['meal', 'welfare_point', 'gym']);
    assert.deepEqual(top(4), ['meal']);
    assert.deepEqual(top(3), []);
  });
});

describe('묶음 모양 검사', () => {
  test('가벼운 묶음은 통과, 번들 전체 · 손상은 거부', () => {
    assert.equal(assertFindShape(find), true);
    assert.equal(isLightRef(find), true);
    assert.equal(isLightRef(bundle), false);
    for (const bad of [null, {}, { ...find, top_notes: undefined }, { ...find, companies: [{ benefits: null }] }, { company_types: [], companies: {}, top_notes: [] }]) {
      assert.throws(() => assertFindShape(bad), /REF_SHAPE/);
    }
  });
});

describe('같은 화면 — 가벼운 묶음 + 설명 받기 완료 == 번들 전체', () => {
  const SCENARIOS = {
    '조건 없음': '',
    '코드 1개': '?b=meal',
    '코드 3개 AND': '?b=meal,welfare_point,gym',
    '코드 2개 OR (없는 회사 「없음」 줄)': '?b=meal,solo_code&m=or',
    '금액만': '?b=meal,gym&amt=1',
    '유형': '?tp=mid',
    '업종': '?ind=포털',
    '유형 + 업종 + 코드': '?b=remote&tp=large&ind=IT',
    '정렬 금액': '?b=meal&sort=amt',
    '정렬 항목 수': '?sort=total',
    '정렬 이름': '?b=remote&sort=name',
    '한 회사에만 있는 코드': '?b=solo_code',
  };
  for (const [name, search] of Object.entries(SCENARIOS)) {
    test(name, async () => {
      const log = [];
      const a = full(search);
      const b = light(search, notesFetch(log));
      assert.equal(screenNoNotes(b), screenNoNotes(a), '첫 그림: 설명 칸을 뺀 곳은 설명과 무관하게 같다');
      await flush();
      assert.equal(screen(b), screen(a), '설명이 도착한 뒤 화면 전체(글자 + title)');
      assert.equal(new Set(log).size, log.length, '같은 코드는 한 번만');
    });
  }

  test('더 보기 두 번', async () => {
    const a = full('');
    const b = light('', notesFetch([]));
    for (const env of [a, b]) {
      env.q('[data-more]').click();
      env.q('[data-more]').click();
    }
    await flush();
    assert.equal(a.all('.find-row').length, 40);
    assert.equal(screen(b), screen(a));
  });

  test('검색 제안창', async () => {
    const a = full('');
    const b = light('', notesFetch([]));
    for (const env of [a, b]) {
      env.q('[data-q]').value = '식';
      env.q('[data-q]').dispatchEvent(new env.dom.window.Event('input'));
    }
    await flush();
    assert.ok(!a.q('[data-sugg]').hidden);
    assert.equal(screen(b), screen(a));
  });

  test('칩을 눌러 조건을 더하고 빼는 흐름', async () => {
    const a = full('');
    const b = light('', notesFetch([]));
    for (const env of [a, b]) {
      const chip = (nm) => env.all('.find-chip').find((c) => c.textContent.includes(nm));
      chip('간식').click();
      env.all('[data-mode]').find((m) => m.dataset.mode === 'or').click();
      chip('복지포인트').click();
    }
    await flush();
    assert.equal(screen(b), screen(a));
  });
});

describe('설명 받기 — 언제 무엇을 받나', () => {
  test('부팅(조건 없음) = 설명 요청 0, 3개 행의 설명은 이미 있다', async () => {
    const log = [];
    const env = light('', notesFetch(log));
    await flush();
    assert.deepEqual(log, []);
    assert.ok(!env.root.textContent.includes(NOTE_LOADING));
    assert.match(env.root.textContent, /월 20만원/);
  });

  test('?b=a,b 로 들어오면 두 코드가 병렬로 한 번씩', async () => {
    const started = [];
    const gates = {};
    const fetchNotes = (code) => { started.push(code); return new Promise((res) => { gates[code] = () => res(clone(NOTES[code])); }); };
    const env = light('?b=solo_code,gym&m=or', fetchNotes);
    await flush();
    assert.deepEqual(started.sort(), ['gym', 'solo_code'], '하나가 끝나기 전에 둘 다 시작');
    assert.match(env.root.textContent, new RegExp(NOTE_LOADING));
    gates.gym(); gates.solo_code();
    await flush();
    assert.ok(!env.root.textContent.includes(NOTE_LOADING));
    assert.match(env.root.textContent, /이 회사에만/);
  });

  test('칩을 누르면 그 코드 한 번 · 같은 코드를 빼고 다시 눌러도 0', async () => {
    const log = [];
    const env = light('', notesFetch(log));
    const chip = () => env.all('.find-chip').find((c) => c.textContent.includes('간식'));
    chip().click();
    await flush();
    assert.deepEqual(log, ['snack']);
    chip().click(); // 빼기
    chip().click(); // 다시 더하기
    await flush();
    assert.deepEqual(log, ['snack']);
  });

  test('같은 코드 동시 두 번 = 요청 1회', async () => {
    const log = [];
    const env = light('', notesFetch(log));
    await Promise.all([env.app.notes.ensure(['gym']), env.app.notes.ensure(['gym', 'gym'])]);
    assert.deepEqual(log, ['gym']);
  });

  test('모르는 코드 · 응답에 없는 회사 · 응답의 모르는 comp_id', async () => {
    const log = [];
    const fetchNotes = async (code) => { log.push(code); return { benefit_cd: code, notes: [{ comp_id: 999, qual_desc_ctnt: 'x', note_ctnt: null }] }; };
    const env = light('?b=gym', fetchNotes);
    await flush();
    await env.app.notes.ensure(['zzz_unknown']);
    assert.deepEqual(log, ['gym']);
    // 응답에 없는 회사의 gym 행 = 「설명 없음」(—)으로 ok
    assert.ok(!env.root.textContent.includes(NOTE_LOADING));
    assert.ok(env.all('.find-hit-d').some((n) => n.textContent === '—' && n.getAttribute('title') === '—'));
  });
});

describe('실패 — 안내 + 다시 시도 · 자동 재시도 없음', () => {
  test('실패하면 안내와 버튼, 렌더가 다시 불러도 자동 재요청이 없다', async () => {
    const log = [];
    const env = light('?b=gym', notesFetch(log, { fail: ['gym'] }));
    await flush();
    assert.deepEqual(log, ['gym']);
    assert.ok(env.root.textContent.includes(NOTE_FAILED));
    assert.ok(env.all('.find-note-retry').length > 0);
    for (let i = 0; i < 3; i += 1) env.app.render();
    await flush();
    assert.deepEqual(log, ['gym'], '렌더가 자동으로 다시 받지 않는다');
    assert.ok(env.root.textContent.includes(NOTE_FAILED));
  });

  test('「다시 시도」는 그 코드만 한 번 다시 — 성공하면 설명이 나온다', async () => {
    const log = [];
    let broken = true;
    const fetchNotes = async (code) => { log.push(code); if (broken) throw new Error('down'); return clone(NOTES[code]); };
    const env = light('?b=gym', fetchNotes);
    await flush();
    broken = false;
    env.all('.find-note-retry')[0].click();
    await flush();
    assert.deepEqual(log, ['gym', 'gym']);
    assert.ok(!env.root.textContent.includes(NOTE_FAILED));
    assert.match(env.root.textContent, /평일 이용/);
  });

  test('실패한 코드를 칩으로 다시 누르면 다시 받는다', async () => {
    const log = [];
    let broken = true;
    const fetchNotes = async (code) => { log.push(code); if (broken) throw new Error('down'); return clone(NOTES[code]); };
    const env = light('', fetchNotes);
    const chip = () => env.all('.find-chip').find((c) => c.textContent.includes('간식'));
    chip().click();
    await flush();
    broken = false;
    chip().click(); // 빼기
    chip().click(); // 다시 더하기 = 다시 시도
    await flush();
    assert.deepEqual(log, ['snack', 'snack']);
    assert.ok(!env.root.textContent.includes(NOTE_FAILED));
  });

  test('실패한 코드가 있어도 다른 코드의 설명은 나온다', async () => {
    const env = light('?b=gym,solo_code&m=or', notesFetch([], { fail: ['gym'] }));
    await flush();
    assert.ok(env.root.textContent.includes(NOTE_FAILED));
    assert.match(env.root.textContent, /이 회사에만/);
  });
});

describe('설명이 도착해도 목록 밖은 흔들리지 않는다', () => {
  test('칩 버튼 노드 · 초점 · 검색창 글 · 더 보기 상태가 그대로', async () => {
    const gates = {};
    const fetchNotes = (code) => new Promise((res) => { gates[code] = () => res(clone(NOTES[code])); });
    const env = light('?b=gym', fetchNotes);
    await flush();
    const chips = env.all('.find-chip');
    const focused = chips.find((c) => c.textContent.includes('사내 체육관'));
    focused.focus();
    env.q('[data-q]').value = '식';
    const rowsBefore = env.all('.find-row');
    const rangeBefore = env.q('[data-range]').textContent;
    gates.gym();
    await flush();
    assert.deepEqual(env.all('.find-chip'), chips, '칩 버튼 노드가 그대로');
    assert.equal(env.doc.activeElement, focused, '초점 유지');
    assert.equal(env.q('[data-q]').value, '식');
    assert.equal(env.q('[data-range]').textContent, rangeBefore);
    assert.deepEqual(env.all('.find-row'), rowsBefore, '행 노드도 그대로 — 설명 칸만 바뀐다');
    assert.ok(!env.root.textContent.includes(NOTE_LOADING));
  });

  test('설명 도착은 render() 전체를 돌리지 않는다(URL 동기화가 늘지 않는다)', async () => {
    const urls = [];
    const gates = {};
    const dom = new JSDOM(`<main>${toolMarkup()}</main>`, { url: 'https://loupit.example/find' });
    globalThis.document = dom.window.document;
    globalThis.window = dom.window;
    const win = {
      location: { search: '?b=gym', assign() {} }, innerWidth: 1200, scrollY: 0,
      addEventListener() {}, removeEventListener() {}, requestAnimationFrame(fn) { fn(); return 1; },
      setTimeout() { return 0; }, clearTimeout() {}, scrollBy() {},
    };
    const root = dom.window.document.querySelector('[data-find-tool]');
    mountFind(root, clone(find), {
      win, history: { replaceState(_s, _t, u) { urls.push(u); } },
      fetchNotes: (code) => new Promise((res) => { gates[code] = () => res(clone(NOTES[code])); }),
    });
    const n = urls.length;
    gates.gym();
    await flush();
    assert.equal(urls.length, n);
  });
});

describe('부팅 로더 — 404 · 네트워크 오류에만 /reference/all 로 한 번', () => {
  const okFind = async () => clone(find);
  const okAll = async () => clone(bundle);
  test('성공하면 묶음만, /all 은 0', async () => {
    let allCalls = 0;
    const ref = await loadFindBundle({ findFn: okFind, allFn: async () => { allCalls += 1; return okAll(); } });
    assert.ok(isLightRef(ref));
    assert.equal(allCalls, 0);
  });

  for (const [name, err] of [['404', new ApiError(404, '/reference/find')], ['네트워크 오류(TypeError)', new TypeError('Failed to fetch')]]) {
    test(`${name} → /reference/all 로 한 번`, async () => {
      let allCalls = 0;
      const ref = await loadFindBundle({ findFn: async () => { throw err; }, allFn: async () => { allCalls += 1; return okAll(); } });
      assert.equal(allCalls, 1);
      assert.ok(!isLightRef(ref));
    });
  }

  for (const [name, err] of [['429', new ApiError(429, 'x')], ['500', new ApiError(500, 'x')], ['시간 초과', Object.assign(new Error('abort'), { name: 'AbortError' })]]) {
    test(`${name} → 되돌아가지 않고 오류`, async () => {
      await assert.rejects(() => loadFindBundle({ findFn: async () => { throw err; }, allFn: async () => assert.fail('폴백하면 안 된다') }), (e) => e === err);
    });
  }

  test('손상된 묶음 → REF_SHAPE, 되돌아가지 않는다', async () => {
    await assert.rejects(() => loadFindBundle({ findFn: async () => ({ company_types: [] }), allFn: async () => assert.fail('폴백하면 안 된다') }), /REF_SHAPE/);
  });
});

describe('통째 부팅(initFind + fetch) — 가벼운 길과 폴백 길', () => {
  function installFetch({ findStatus = 200 } = {}) {
    const log = [];
    globalThis.fetch = async (url) => {
      const u = String(url);
      const json = (body, status = 200) => ({ ok: status < 400, status, headers: { get: () => null }, json: async () => clone(body) });
      if (u.endsWith('/reference/find')) { log.push('find'); return findStatus === 200 ? json(find) : json({}, findStatus); }
      if (u.endsWith('/reference/all')) { log.push('all'); return json(bundle); }
      const m = u.match(/\/reference\/notes\/([a-z0-9_]+)$/);
      if (m) { log.push(`notes:${m[1]}`); return json(NOTES[m[1]]); }
      throw new Error(`예상 밖 요청 ${u}`);
    };
    return log;
  }
  async function boot(search) {
    const dom = new JSDOM(`<main>${toolMarkup()}<p data-find-error hidden></p></main>`, { url: `https://loupit.example/find${search}` });
    globalThis.document = dom.window.document;
    globalThis.window = dom.window;
    const app = await initFind(dom.window.document);
    await flush();
    return { dom, app, root: dom.window.document.querySelector('[data-find-tool]') };
  }

  test('부팅 = find 1회 · 설명 0회(조건 없음)', async () => {
    const log = installFetch();
    const { app } = await boot('');
    assert.ok(app);
    assert.deepEqual(log, ['find']);
  });

  test('find 404 → /reference/all 폴백 부팅이 번들 부팅과 같은 화면 · 설명 요청 0', async () => {
    const log = installFetch({ findStatus: 404 });
    const { root, app } = await boot('?b=meal,gym');
    assert.deepEqual(log, ['find', 'all']);
    assert.equal(app.notes, null);
    const ref = full('?b=meal,gym');
    assert.equal(root.innerHTML, ref.root.innerHTML);
  });

  test('가벼운 길 + ?b= → 그 코드 설명만 받고 화면이 번들 부팅과 같다', async () => {
    const log = installFetch();
    const { root } = await boot('?b=meal,gym');
    assert.deepEqual(log.filter((x) => x.startsWith('notes:')).sort(), ['notes:gym', 'notes:meal']);
    assert.equal(log.filter((x) => x === 'all').length, 0);
    assert.equal(root.innerHTML, full('?b=meal,gym').root.innerHTML);
  });
});

describe('저장소 단위', () => {
  test('top_notes 는 만들 때 반영, 나머지 행은 설명 키가 없다(loading)', () => {
    const ref = clone(find);
    const store = createNoteStore(ref, { fetchFn: async () => assert.fail('요청 없음') });
    const kt = ref.companies[0].benefits;
    assert.equal(store.state(kt.find((b) => b.benefit_cd === 'meal')), 'ok');
    assert.equal(store.state(kt.find((b) => b.benefit_cd === 'snack')), 'loading');
  });
});
