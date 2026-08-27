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
