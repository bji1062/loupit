// heatmap.js — 탭 전환 순수 함수 검증(jsdom)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import { activate } from './heatmap.js';

const HTML = `<div class="hm-tabs"><button role="tab" data-mode="w" aria-selected="true">복지</button><button role="tab" data-mode="f" aria-selected="false">실적</button></div>
<section class="hm-mode" data-mode="w"></section><section class="hm-mode" data-mode="f"></section>`;

test('activate 는 선택한 모드만 보이게 하고 aria-selected 를 맞춘다', () => {
  const doc = new JSDOM(HTML).window.document;
  assert.equal(activate(doc, 'f'), 1);
  const [w, f] = doc.querySelectorAll('.hm-mode');
  assert.equal(w.hidden, true); assert.equal(f.hidden, false);
  assert.equal(doc.querySelector('[data-mode="f"][role="tab"]').getAttribute('aria-selected'), 'true');
});

test('모르는 모드는 첫 탭으로 떨어진다(빈 화면 금지)', () => {
  const doc = new JSDOM(HTML).window.document;
  assert.equal(activate(doc, 'zzz'), 1);
  assert.equal(doc.querySelector('.hm-mode[data-mode="w"]').hidden, false);
});

test('탭이 없는 문서에서는 아무것도 하지 않는다', () => {
  const doc = new JSDOM('<main></main>').window.document;
  assert.equal(activate(doc, 'w'), 0);
});

import { activatePanel } from './heatmap.js';

const CAT = `<section class="hm-mode" data-mode="c"><div class="hm-chips"><button role="tab" data-panel="perks" aria-selected="true">복리후생</button><button role="tab" data-panel="health" aria-selected="false">건강</button></div>
<div class="hm-panel" data-panel="perks"></div><div class="hm-panel" data-panel="health"></div></section>`;

test('activatePanel 은 고른 카테고리만 남기고 칩 aria-selected 를 맞춘다', () => {
  const doc = new JSDOM(CAT).window.document;
  const m = doc.querySelector('.hm-mode');
  assert.equal(activatePanel(m, 'health'), 1);
  assert.equal(doc.querySelector('.hm-panel[data-panel="perks"]').hidden, true);
  assert.equal(doc.querySelector('.hm-panel[data-panel="health"]').hidden, false);
  assert.equal(doc.querySelector('[data-panel="health"][role="tab"]').getAttribute('aria-selected'), 'true');
});

test('activatePanel — 모르는 키는 첫 카테고리, 칩 없는 모드는 0', () => {
  const doc = new JSDOM(CAT).window.document;
  assert.equal(activatePanel(doc.querySelector('.hm-mode'), 'nope'), 1);
  assert.equal(doc.querySelector('.hm-panel[data-panel="perks"]').hidden, false);
  const single = new JSDOM('<section class="hm-mode" data-mode="w"><div class="hm-panel" data-panel="all"></div></section>').window.document;
  assert.equal(activatePanel(single.querySelector('.hm-mode'), 'all'), 0);
});

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { bindMap, clearHighlight, highlight, readoutText } from './heatmap.js';

// 지도 하나: 그룹 2개(g0 반도체·g1 게임), 삼성전자가 두 묶음에 걸쳐 있다(카테고리 모드 형태)
const MAP = `<div class="hm-panel">
<p class="hm-readout" data-readout>기본 안내</p>
<div class="hm-map hm-landscape">
  <div class="hm-grp" data-g="g0" data-nm="반도체"><span>반도체 <em>2</em></span></div>
  <div class="hm-grp" data-g="g1" data-nm="게임"><span>게임 <em>1</em></span></div>
  <a class="hm-t" data-g="g0" data-c="samsung-elec" title="삼성전자 — 식대 · 240만원" href="/company/samsung-elec"><b>삼성전자</b></a>
  <a class="hm-t" data-g="g0" data-c="sk-hynix" title="SK하이닉스 — 식대 · 300만원" href="/company/sk-hynix"><b>SK하이닉스</b></a>
  <a class="hm-t" data-g="g1" data-c="samsung-elec" title="삼성전자 — 동호회 · 금액 없음" href="/company/samsung-elec"><b>삼성전자</b></a>
</div></div>`;

const mapDoc = () => new JSDOM(MAP).window.document;

test('highlight 는 칸·소속 그룹·같은 회사의 다른 칸을 표시한다', () => {
  const doc = mapDoc();
  const map = doc.querySelector('.hm-map');
  const tile = doc.querySelector('.hm-t[data-c="samsung-elec"][data-g="g0"]');
  const res = highlight(map, tile);
  assert.equal(res.group, 1); assert.equal(res.peers, 1);
  assert.equal(res.groupEl?.dataset.nm, '반도체');
  assert.ok(tile.classList.contains('is-hot'));
  assert.ok(doc.querySelector('.hm-grp[data-g="g0"]').classList.contains('is-hot'));
  assert.equal(doc.querySelector('.hm-grp[data-g="g1"]').classList.contains('is-hot'), false);
  // 같은 회사의 다른 묶음 칸은 점선, 다른 회사는 무표시
  assert.ok(doc.querySelector('.hm-t[data-g="g1"]').classList.contains('is-peer'));
  assert.equal(doc.querySelector('.hm-t[data-c="sk-hynix"]').className, 'hm-t');
});

test('highlight 는 이전 강조를 먼저 걷어낸다(강조는 항상 한 벌)', () => {
  const doc = mapDoc();
  const map = doc.querySelector('.hm-map');
  highlight(map, doc.querySelector('.hm-t[data-c="samsung-elec"]'));
  highlight(map, doc.querySelector('.hm-t[data-c="sk-hynix"]'));
  assert.equal(map.querySelectorAll('.is-hot').length, 2);   // 칸 1 + 그룹 1
  assert.equal(map.querySelectorAll('.is-peer').length, 0);  // 하이닉스는 칸이 하나뿐
  assert.equal(clearHighlight(map), 2);
  assert.equal(map.querySelectorAll('.is-hot, .is-peer').length, 0);
});

test('readoutText 는 묶음 이름과 툴팁을 잇는다', () => {
  const doc = mapDoc();
  const tile = doc.querySelector('.hm-t');
  const grp = doc.querySelector('.hm-grp[data-g="g0"]');
  assert.equal(readoutText(tile, grp), '반도체 · 삼성전자 — 식대 · 240만원');
  assert.equal(readoutText(tile, null), '삼성전자 — 식대 · 240만원');  // 그룹을 못 찾아도 내용은 나온다
  assert.equal(readoutText(null, grp), '');
});

test('bindMap — 마우스가 닿으면 강조·판독줄, 떠나면 원복', () => {
  const doc = mapDoc();
  const map = doc.querySelector('.hm-map');
  const readout = doc.querySelector('[data-readout]');
  assert.equal(bindMap(map), true);
  const tile = doc.querySelector('.hm-t');
  tile.dispatchEvent(new doc.defaultView.MouseEvent('mouseover', { bubbles: true }));
  assert.ok(tile.classList.contains('is-hot'));
  assert.equal(readout.textContent, '반도체 · 삼성전자 — 식대 · 240만원');
  map.dispatchEvent(new doc.defaultView.MouseEvent('mouseleave'));
  assert.equal(map.querySelectorAll('.is-hot, .is-peer').length, 0);
  assert.equal(readout.textContent, '기본 안내');
});

test('bindMap — 키보드 포커스도 같은 강조를 준다(마우스 없는 사용자)', () => {
  const doc = mapDoc();
  const map = doc.querySelector('.hm-map');
  bindMap(map);
  const tile = doc.querySelector('.hm-t[data-c="sk-hynix"]');
  tile.dispatchEvent(new doc.defaultView.FocusEvent('focusin', { bubbles: true }));
  assert.ok(tile.classList.contains('is-hot'));
  assert.equal(doc.querySelector('[data-readout]').textContent, '반도체 · SK하이닉스 — 식대 · 300만원');
});


// ── 페인트 순서 가드 — jsdom 은 그리지 않으므로 CSS 텍스트로 잰다 ──
// 그룹 사각형은 타일보다 먼저 나오는 **형제**다. 강조 규칙이 그룹을 z 축으로 올리면 자기 그룹의
// 타일 전부가 배경에 덮인다(실측: 전기·전자 17칸 소실). 이 계약은 브라우저로만 보이는 종류라
// 텍스트로 못박는다.
const CSS = readFileSync(fileURLToPath(new URL('../css/heatmap.css', import.meta.url)), 'utf8');
const ruleBody = (sel) => {
  const i = CSS.indexOf(sel + ' {');
  assert.ok(i >= 0, `${sel} 규칙이 없다`);
  return CSS.slice(i, CSS.indexOf('}', i));
};

test('강조된 그룹은 z 축으로 올라가지 않는다(자기 타일을 덮는다)', () => {
  assert.ok(!/z-index/.test(ruleBody('.hm-grp.is-hot')), '.hm-grp.is-hot 에 z-index 금지');
  assert.match(ruleBody('.hm-grp.is-hot'), /box-shadow:\s*inset/, '테두리로 강조해야 한다');
});

test('강조된 칸과 같은 회사 칸은 z 축으로 올라간다(테두리가 이웃에 잘리지 않게)', () => {
  assert.match(ruleBody('.hm-t.is-hot'), /z-index:\s*3/);
  assert.match(ruleBody('.hm-t.is-peer'), /z-index:\s*2/);
});


// ── 지도 늦게 그리기(2026-10-22) ─────────────────────────────────────────────
import { buildMaps, createLoader, ensurePanel, initHeatmap, loadVisible, prefetchPanels, shouldPrefetch } from './heatmap.js';

const CASES = JSON.parse(readFileSync(fileURLToPath(new URL('../../../generator/tests/data/heatmap_panel_cases.json', import.meta.url)), 'utf8'));

/** 속성 순서 · 공백뿐인 글 마디만 무시하는 정규형(그 밖에는 한 글자도 다르면 안 된다). */
const canon = (node) => {
  if (node.nodeType === 3) return node.nodeValue.trim() === '' ? '' : JSON.stringify(node.nodeValue);
  const attrs = Array.from(node.attributes).map((a) => `${a.name}=${JSON.stringify(a.value)}`).sort().join(' ');
  const kids = Array.from(node.childNodes).map(canon).join('');
  return `<${node.tagName.toLowerCase()} ${attrs}>${kids}</${node.tagName.toLowerCase()}>`;
};
const canonHtml = (html) => {
  const doc = new JSDOM(`<body>${html}</body>`).window.document;
  return Array.from(doc.body.childNodes).map(canon).join('');
};

test('서버 그림 = 브라우저 그림 — 데이터 파일로 그린 지도가 Jinja 마크업과 같다(모든 픽스처 패널)', () => {
  assert.ok(CASES.panels.length >= 4);
  for (const c of CASES.panels) {
    const doc = new JSDOM('<body></body>').window.document;
    const holder = doc.createElement('div');
    holder.appendChild(buildMaps(doc, c.data));
    assert.equal(canonHtml(holder.innerHTML), canonHtml(c.html), `${c.mode}/${c.panel}`);
  }
});

test('픽스처에는 비상장 그룹 · 좁은 그룹 · 앵커 있는 칸이 모두 들어 있다(대조가 빈 껍데기가 아니게)', () => {
  const all = CASES.panels.map((c) => c.html).join('');
  assert.match(all, /hm-grp[^"]* unlisted/);
  assert.match(all, /hm-grp narrow/);
  assert.match(all, /href="\/company\/[^"#]+#b-/);
});

const SHELL = (src = '/heatmap/c-perks.json?v=abc') => `
<div class="hm-tabs"><button role="tab" data-mode="w" aria-selected="true">복지</button><button role="tab" data-mode="f" aria-selected="false">실적</button><button role="tab" data-mode="c" aria-selected="false">카테고리</button></div>
<section class="hm-mode" id="hm-w" data-mode="w"><div class="hm-panel" data-panel="all"><p class="hm-readout" data-readout>안내</p><div class="hm-map hm-landscape"></div></div></section>
<section class="hm-mode" id="hm-f" data-mode="f"><div class="hm-panel" data-panel="all" data-src="/heatmap/f-all.json?v=abc"><p class="hm-readout" data-readout>안내</p><p class="hm-nojs">스크립트 필요</p></div></section>
<section class="hm-mode" id="hm-c" data-mode="c"><div class="hm-chips"><button role="tab" data-panel="perks" aria-selected="true">복리</button><button role="tab" data-panel="health" aria-selected="false">건강</button></div>
<div class="hm-panel" data-panel="perks" data-src="${src}"><p class="hm-readout" data-readout>안내</p></div>
<div class="hm-panel" data-panel="health" data-src="/heatmap/c-health.json?v=abc"><p class="hm-readout" data-readout>안내</p></div></section>`;

const dataOf = (mode) => CASES.panels.find((c) => c.mode === mode).data;
const json = (data) => async () => ({ ok: true, json: async () => data });
const okFetch = (log) => async (src) => { log.push(src); return { ok: true, json: async () => dataOf(src.includes('/f-') ? 'f' : 'c') }; };
const flush = () => new Promise((r) => setTimeout(r, 0));
const click = (doc, el) => el.dispatchEvent(new doc.defaultView.MouseEvent('click', { bubbles: true }));

test('탭을 처음 열 때만 받고 두 번째부터는 다시 받지 않는다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  const log = [];
  initHeatmap(doc, { fetch: okFetch(log), noPrefetch: true });
  assert.deepEqual(log, []);                                   // 복지 첫 화면은 받을 게 없다
  click(doc, doc.querySelector('[data-mode="f"][role="tab"]')); await flush();
  assert.deepEqual(log, ['/heatmap/f-all.json?v=abc']);
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2);
  assert.equal(doc.querySelector('#hm-f .hm-status'), null);
  click(doc, doc.querySelector('[data-mode="w"][role="tab"]'));
  click(doc, doc.querySelector('[data-mode="f"][role="tab"]')); await flush();
  assert.equal(log.length, 1);
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2); // 두 번 그리지 않는다
});

test('받는 동안 「불러오는 중…」, 실패하면 안내, 다시 누르면 다시 받는다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  let fail = true; let calls = 0; let release;
  const gate = new Promise((r) => { release = r; });
  const fetchFn = async () => { calls += 1; await gate; if (fail) return { ok: false, status: 500 }; return { ok: true, json: async () => dataOf('f') }; };
  initHeatmap(doc, { fetch: fetchFn, noPrefetch: true });
  const tab = doc.querySelector('[data-mode="f"][role="tab"]');
  click(doc, tab); await flush();
  assert.equal(doc.querySelector('#hm-f .hm-status').textContent, '불러오는 중…');
  release(); await flush(); await flush();
  assert.equal(doc.querySelector('#hm-f .hm-status').textContent, '지도를 받지 못했습니다. 다시 누르면 다시 받습니다.');
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 0);
  fail = false;
  click(doc, tab); await flush(); await flush();
  assert.equal(calls, 2);
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2);
  assert.equal(doc.querySelector('#hm-f .hm-status'), null);
});

test('?mode=c&cat=health 로 곧장 들어오면 그 패널만 받아 연다', async () => {
  const dom = new JSDOM(SHELL(), { url: 'https://jobcho.wiki/heatmap?mode=c&cat=health' });
  globalThis.location = dom.window.location;
  try {
    const log = [];
    initHeatmap(dom.window.document, { fetch: okFetch(log), noPrefetch: true });
    await flush();
    assert.deepEqual(log, ['/heatmap/c-health.json?v=abc']);
    assert.equal(dom.window.document.querySelector('.hm-panel[data-panel="health"]').hidden, false);
    assert.equal(dom.window.document.querySelectorAll('.hm-panel[data-panel="health"] .hm-map').length, 2);
  } finally { delete globalThis.location; }
});

test('늦게 그린 지도에도 강조 · 판독줄이 똑같이 동작한다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  const panel = doc.querySelector('#hm-f .hm-panel');
  await ensurePanel(panel, createLoader(okFetch([])));
  const map = panel.querySelector('.hm-map');
  const tile = map.querySelector('.hm-t');
  tile.dispatchEvent(new doc.defaultView.MouseEvent('mouseover', { bubbles: true }));
  assert.ok(tile.classList.contains('is-hot'));
  assert.ok(map.querySelector(`.hm-grp[data-g="${tile.dataset.g}"]`).classList.contains('is-hot'));
  assert.match(panel.querySelector('[data-readout]').textContent, / · /);
});

test('미리 받기 — 실적과 카테고리 첫 칩만 받고, 그리지는 않는다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  activate(doc, 'w');
  const log = [];
  const loader = createLoader(okFetch(log));
  assert.equal(prefetchPanels(doc, loader, { connection: { effectiveType: '4g' } }), 2);
  await flush();
  assert.deepEqual(log.sort(), ['/heatmap/c-perks.json?v=abc', '/heatmap/f-all.json?v=abc']);
  assert.equal(doc.querySelectorAll('.hm-map').length, 1);       // 복지 지도 하나뿐 — 아직 안 그렸다
  await loadVisible(doc, loader);                                  // 눌렀을 때는 받은 것을 재사용
  assert.equal(log.length, 2);
});

test('미리 받기 — 데이터 절약 모드 · 2G 에서는 받지 않는다', () => {
  const doc = new JSDOM(SHELL()).window.document;
  for (const connection of [{ saveData: true }, { effectiveType: '2g' }, { effectiveType: 'slow-2g' }]) {
    const log = [];
    assert.equal(shouldPrefetch({ connection }), false);
    assert.equal(prefetchPanels(doc, createLoader(okFetch(log)), { connection }), 0);
    assert.deepEqual(log, []);
  }
  assert.equal(shouldPrefetch({}), true);                          // 정보가 없으면 받는다
});

test('같은 패널을 받는 중에 또 눌러도 받기 1번 · 지도 2개', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  let calls = 0; let release;
  const gate = new Promise((r) => { release = r; });
  initHeatmap(doc, { fetch: async () => { calls += 1; await gate; return { ok: true, json: async () => dataOf('f') }; }, noPrefetch: true });
  const tab = doc.querySelector('[data-mode="f"][role="tab"]');
  click(doc, tab); click(doc, tab); await flush();
  release(); await flush(); await flush();
  assert.equal(calls, 1);
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2);
});

test('404 는 「새로고침」 안내, 그 밖의 실패는 다시 누르라는 안내', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  initHeatmap(doc, { fetch: async () => ({ ok: false, status: 404 }), noPrefetch: true });
  click(doc, doc.querySelector('[data-mode="f"][role="tab"]')); await flush(); await flush();
  assert.equal(doc.querySelector('#hm-f .hm-status').textContent, '지도가 새로 바뀌었어요. 새로고침해 주세요.');
  const doc2 = new JSDOM(SHELL()).window.document;
  initHeatmap(doc2, { fetch: async () => ({ ok: false, status: 500 }), noPrefetch: true });
  click(doc2, doc2.querySelector('[data-mode="f"][role="tab"]')); await flush(); await flush();
  assert.equal(doc2.querySelector('#hm-f .hm-status').textContent, '지도를 받지 못했습니다. 다시 누르면 다시 받습니다.');
});

test('시간 초과도 실패 — 안내가 뜨고 다음 클릭에 다시 받는다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  let calls = 0; let hang = true;
  const fetchFn = (src, init) => {
    calls += 1;
    if (!hang) return Promise.resolve({ ok: true, json: async () => dataOf('f') });
    return new Promise((_, rej) => init?.signal?.addEventListener('abort', () => rej(new Error('abort'))));
  };
  initHeatmap(doc, { fetch: fetchFn, timeoutMs: 20, noPrefetch: true });
  const tab = doc.querySelector('[data-mode="f"][role="tab"]');
  click(doc, tab);
  await new Promise((r) => setTimeout(r, 60));
  assert.equal(doc.querySelector('#hm-f .hm-status').textContent, '지도를 받지 못했습니다. 다시 누르면 다시 받습니다.');
  hang = false;
  click(doc, tab); await flush(); await flush();
  assert.equal(calls, 2);
  assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2);
});

test('200 인데 모양이 틀리면(형식 번호 · 깨진 내용) 안내 + 다음 클릭에 다시 받는다', async () => {
  for (const bad of [{ ...dataOf('f'), v: 99 }, { v: 1, groups: [], tiles: [] }]) {
    const doc = new JSDOM(SHELL()).window.document;
    let calls = 0; let body = bad;
    initHeatmap(doc, { fetch: async () => { calls += 1; return { ok: true, json: async () => body }; }, noPrefetch: true });
    const tab = doc.querySelector('[data-mode="f"][role="tab"]');
    click(doc, tab); await flush(); await flush();
    assert.equal(doc.querySelector('#hm-f .hm-status').textContent, '지도를 받지 못했습니다. 다시 누르면 다시 받습니다.');
    assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 0);
    body = dataOf('f');
    click(doc, tab); await flush(); await flush();
    assert.equal(calls, 2);
    assert.equal(doc.querySelectorAll('#hm-f .hm-map').length, 2);
  }
});

test('스크립트가 맡으면 정적 「자바스크립트가 필요합니다」 안내를 걷는다', async () => {
  const doc = new JSDOM(SHELL()).window.document;
  const panel = doc.querySelector('#hm-f .hm-panel');
  assert.ok(panel.querySelector('.hm-nojs'));
  await ensurePanel(panel, createLoader(json(dataOf('f'))));
  assert.equal(panel.querySelector('.hm-nojs'), null);
});

test('지도 div 에 aria-hidden 을 두지 않는다(보이는 배치가 스크린리더에서 지워지면 안 된다)', () => {
  const doc = new JSDOM('<body></body>').window.document;
  const holder = doc.createElement('div');
  holder.appendChild(buildMaps(doc, dataOf('f')));
  assert.equal(holder.querySelectorAll('[aria-hidden]').length, 0);
});
