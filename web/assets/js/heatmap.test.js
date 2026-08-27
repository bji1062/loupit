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
