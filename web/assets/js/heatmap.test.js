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
