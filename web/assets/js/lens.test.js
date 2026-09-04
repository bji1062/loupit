// lens.js — 출처 렌즈가 **강조만** 하는지 검증(SP-GEN-5.7, jsdom).
//
// 여기서 잡으려는 회귀는 metricshape.test.js 와 같은 종류다.
//   ① 🚨 이 모듈이 **행을 다시 판정하기 시작하는 것.** "이 행이 추정인가"는 빌드 시점에
//      `generator/format.py::amount_kind` 가 이미 정했고 행의 `data-lens` 에 박혀 있다. JS 가
//      건드리는 DOM 은 최상위 `data-lens-on` 한 글자와 칩의 `aria-pressed` 뿐이어야 한다.
//   ② 렌즈가 **필터가 되는 것.** 행을 숨기면 본문이 DOM 에서 빠져 색인이 깎이고 "복지가
//      8개뿐"으로 읽힌다. 이 모듈은 어떤 요소도 지우거나 hidden 으로 만들지 않는다.
//   ③ 선택을 **기억하는 것.** 상태 복원 장치에 화면 결정권을 준 대문 사고(2026-07-31)의
//      재발 방지 — 렌즈의 기본은 언제나 '전체'다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import { LENS_KEYS, ROOT_ATTR, initLens } from './lens.js';

// 실제 `_stat_card.html` 산출물 그대로 — 칩은 `hidden` 으로 나가고 행은 이미 키를 지녔다.
const HTML = `<section class="stat-card">
<div class="sc-main">
  <div class="sc-lens" hidden data-lens-chips>
    <ul class="sc-lens-chips" aria-label="출처 렌즈">
      <li><button class="sc-lens-chip" type="button" data-lens-key="all" aria-pressed="true">전체 <b>4</b></button></li>
      <li><button class="sc-lens-chip" type="button" data-lens-key="stated" aria-pressed="false">회사 공식 수치 <b>1</b></button></li>
      <li><button class="sc-lens-chip" type="button" data-lens-key="est" aria-pressed="false">추정치 <b>1</b></button></li>
      <li><button class="sc-lens-chip" type="button" data-lens-key="qual" aria-pressed="false">정성 <b>2</b></button></li>
    </ul>
    <p class="sc-lens-bar" data-lens-for="est">추정치 1항목을…</p>
  </div>
  <ul><li><a class="sc-row has-amt" href="#b-meal" data-lens="est"><span class="sc-nm">식대</span></a></li>
      <li><a class="sc-row" href="#b-rest" data-lens="qual"><span class="sc-nm">휴가</span></a></li></ul>
</div></section>
<div class="benefits"><article class="led-row" id="b-meal" data-amt="estimated" data-lens="est"><p>전문</p></article></div>`;

function doc(html = HTML) {
  return new JSDOM(html).window.document;
}

const chip = (d, key) => d.querySelector(`[data-lens-key="${key}"]`);
const pressed = (d) => [...d.querySelectorAll('[data-lens-key]')]
  .filter((b) => b.getAttribute('aria-pressed') === 'true')
  .map((b) => b.getAttribute('data-lens-key'));

// ── 배선 ────────────────────────────────────────────────────────────────────
describe('initLens', () => {
  test('칩을 드러내고 배선한 칩 수를 돌려준다 — JS 가 오기 전에는 죽은 컨트롤이 없다', () => {
    const d = doc();
    assert.equal(d.querySelector('[data-lens-chips]').hasAttribute('hidden'), true);
    assert.equal(initLens(d), 4);
    assert.equal(d.querySelector('[data-lens-chips]').hasAttribute('hidden'), false);
  });

  test('칩이 없는 페이지(조합·정성만 회사)에서는 조용히 0 — 예외 없음', () => {
    const d = doc('<main><p>렌즈 없는 페이지</p></main>');
    assert.equal(initLens(d), 0);
    assert.equal(d.documentElement.hasAttribute(ROOT_ATTR), false);
  });

  test('기본은 언제나 전체 — 초기화만으로는 어떤 렌즈도 켜지지 않는다', () => {
    const d = doc();
    initLens(d);
    assert.equal(d.documentElement.hasAttribute(ROOT_ATTR), false);
    assert.deepEqual(pressed(d), ['all']);
  });

  test('어떤 실패에서도 본문을 건드리지 않고 0 을 돌려준다(MON6)', () => {
    assert.equal(initLens({ querySelector() { throw new Error('boom'); } }), 0);
  });
});

// ── 고르기 ──────────────────────────────────────────────────────────────────
describe('칩 클릭', () => {
  test('최상위에 data-lens-on 한 글자를 세팅한다 — 그게 전부다', () => {
    const d = doc();
    initLens(d);
    chip(d, 'est').click();
    assert.equal(d.documentElement.getAttribute(ROOT_ATTR), 'est');
    assert.deepEqual(pressed(d), ['est']);
  });

  test('켠 칩을 다시 누르면 전체로 돌아온다(속성 제거)', () => {
    const d = doc();
    initLens(d);
    chip(d, 'est').click();
    chip(d, 'est').click();
    assert.equal(d.documentElement.hasAttribute(ROOT_ATTR), false);
    assert.deepEqual(pressed(d), ['all']);
  });

  test("'전체' 칩은 언제나 렌즈를 끈다", () => {
    const d = doc();
    initLens(d);
    chip(d, 'qual').click();
    chip(d, 'all').click();
    assert.equal(d.documentElement.hasAttribute(ROOT_ATTR), false);
    assert.deepEqual(pressed(d), ['all']);
  });

  test('한 번에 하나만 켜진다 — 렌즈는 조합이 아니라 관점이다', () => {
    const d = doc();
    initLens(d);
    chip(d, 'stated').click();
    chip(d, 'qual').click();
    assert.equal(d.documentElement.getAttribute(ROOT_ATTR), 'qual');
    assert.deepEqual(pressed(d), ['qual']);
  });

  test('목록 밖 키는 무시한다 — 마크업이 바뀌어도 임의 문자열이 최상위에 박히지 않는다', () => {
    const d = doc(HTML.replace('data-lens-key="est"', 'data-lens-key="__proto__"'));
    initLens(d);
    chip(d, '__proto__').click();
    assert.equal(d.documentElement.hasAttribute(ROOT_ATTR), false);
  });

  test('LENS_KEYS 는 생성기의 통 목록과 같은 6개다(company.py::LENS_BUCKETS)', () => {
    assert.deepEqual(LENS_KEYS, ['stated', 'est', 'qual', 'blank', 'edited', 'expired']);
  });
});

// ── 하지 않는 일 ────────────────────────────────────────────────────────────
describe('렌즈가 하지 않는 일', () => {
  test('🚨 행을 한 글자도 건드리지 않는다 — 판정은 빌드가 이미 끝냈다', () => {
    const d = doc();
    initLens(d);
    const before = [...d.querySelectorAll('[data-lens]')].map((el) => el.outerHTML);
    chip(d, 'est').click();
    chip(d, 'qual').click();
    chip(d, 'all').click();
    const after = [...d.querySelectorAll('[data-lens]')].map((el) => el.outerHTML);
    assert.deepEqual(after, before);
  });

  test('🚨 행을 숨기지 않는다 — 어떤 렌즈에서도 27행은 27행이다', () => {
    const d = doc();
    initLens(d);
    chip(d, 'est').click();
    assert.equal(d.querySelectorAll('[data-lens]').length, 3);
    for (const el of d.querySelectorAll('[data-lens]')) {
      assert.equal(el.hasAttribute('hidden'), false);
    }
  });

  test('🚨 저장하지 않는다 — localStorage 에 손대는 경로가 없다', () => {
    const d = doc();
    let touched = 0;
    const spy = { getItem() { touched += 1; return null; }, setItem() { touched += 1; } };
    const prev = globalThis.localStorage;
    Object.defineProperty(globalThis, 'localStorage', { value: spy, configurable: true });
    try {
      initLens(d);
      chip(d, 'est').click();
    } finally {
      if (prev === undefined) delete globalThis.localStorage;
      else Object.defineProperty(globalThis, 'localStorage', { value: prev, configurable: true });
    }
    assert.equal(touched, 0);
  });
});
