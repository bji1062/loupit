// web/assets/js/dom.test.js — SP-FE-9.1·9.2 렌더 안전 유틸 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-9, TASK/06-프론트엔드.md T-06.9.1~9.3.
// 순수 유틸(escapeHtml/h/safeUrl)은 브라우저 없이 테스트. el()은 in-memory document 최소 스텁 필요.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { escapeHtml, h, safeUrl, el } from './dom.js';

// ── 최소 in-memory document 스텁(el 테스트 전용) ────────────────────────────
// dom.js는 브라우저 표준 API(document.createElement 등)만 사용하므로
// 노드 테스트 환경에서는 필요한 최소 표면만 스텁으로 주입한다.
class FakeElement {
  constructor(tag) {
    this.tagName = tag;
    this.attributes = {};
    this.className = '';
    this.textContent = '';
    this.children = [];
  }
  setAttribute(k, v) { this.attributes[k] = String(v); }
  append(...nodes) { this.children.push(...nodes); }
}
globalThis.document = {
  createElement(tag) { return new FakeElement(tag); },
};
globalThis.location = { origin: 'https://loupit.example' };

// ── T-06.9.1: escapeHtml·h 태그드 템플릿 (UT-ESC-1, Tier0) ─────────────────
describe('T-06.9.1 escapeHtml·h (UT-ESC-1, Tier0)', () => {
  test('UT-ESC-1: & < > " \' 전부 치환', () => {
    assert.equal(escapeHtml('<img src=x onerror=alert(1)>'), '&lt;img src=x onerror=alert(1)&gt;');
    assert.equal(escapeHtml('&'), '&amp;');
    assert.equal(escapeHtml('<'), '&lt;');
    assert.equal(escapeHtml('>'), '&gt;');
    assert.equal(escapeHtml('"'), '&quot;');
    assert.equal(escapeHtml("'"), '&#39;');
  });

  test('escapeHtml: null/undefined → 빈 문자열(예외 없음)', () => {
    assert.equal(escapeHtml(null), '');
    assert.equal(escapeHtml(undefined), '');
  });

  test('escapeHtml: 숫자 등 비문자열도 String() 후 처리', () => {
    assert.equal(escapeHtml(42), '42');
  });

  test('h: 정적부는 그대로, 보간값은 escapeHtml 후 결합', () => {
    const name = '<script>alert(1)</script>';
    const out = h`<span>${name}</span>`;
    assert.equal(out, '<span>&lt;script&gt;alert(1)&lt;/script&gt;</span>');
  });

  test('h: 보간값 없는 정적 템플릿은 그대로', () => {
    assert.equal(h`<div class="x"></div>`, '<div class="x"></div>');
  });

  test('h: 다중 보간값 각각 이스케이프', () => {
    const a = '<a>';
    const b = '<b>';
    assert.equal(h`${a}-${b}`, '&lt;a&gt;-&lt;b&gt;');
  });
});

// ── T-06.9.2: safeUrl 스킴 화이트리스트 (UT-ESC-2, Tier0) ──────────────────
describe('T-06.9.2 safeUrl (UT-ESC-2, Tier0)', () => {
  test('UT-ESC-2: javascript: → null / https:// → 원 URL', () => {
    assert.equal(safeUrl('javascript:alert(1)'), null);
    assert.equal(safeUrl('https://x.co/a'), 'https://x.co/a');
  });

  test('safeUrl: http:// 허용', () => {
    assert.equal(safeUrl('http://x.co/a'), 'http://x.co/a');
  });

  test('safeUrl: data: 등 기타 위험 스킴 → null', () => {
    assert.equal(safeUrl('data:text/html,<script>alert(1)</script>'), null);
  });

  test('safeUrl: 파싱 자체가 실패하는 값은 null(예: 닫히지 않은 IPv6 호스트)', () => {
    assert.equal(safeUrl('http://[::1'), null);
  });

  test('safeUrl: 빈 문자열은 location.origin 기준으로 상대 해석되어 origin 반환(파싱 실패 아님)', () => {
    assert.equal(safeUrl(''), 'https://loupit.example/');
  });
});

// ── T-06.9.3: el 안전 DOM 빌더·raw html 차단 (UT-ESC-3, Tier0) ─────────────
describe('T-06.9.3 el (UT-ESC-3, Tier0)', () => {
  test('UT-ESC-3: el(tag,{html:...}) → 예외 던짐', () => {
    assert.throws(() => el('div', { html: '<b>' }), /raw html 금지/);
  });

  test('el: text → textContent (데이터는 항상 textContent)', () => {
    const node = el('span', { text: '<img onerror=alert(1)>' });
    assert.equal(node.textContent, '<img onerror=alert(1)>');
    assert.equal(node.tagName, 'span');
  });

  test('el: class → className', () => {
    const node = el('div', { class: 'foo bar' });
    assert.equal(node.className, 'foo bar');
  });

  test('el: 그 외 속성 → setAttribute', () => {
    const node = el('a', { href: 'https://x.co', 'data-id': 5 });
    assert.equal(node.attributes.href, 'https://x.co');
    assert.equal(node.attributes['data-id'], '5');
  });

  test('el: null/undefined 값 속성은 setAttribute 호출 안 함', () => {
    const node = el('a', { href: null });
    assert.equal(node.attributes.href, undefined);
  });

  test('el: children append', () => {
    const child = el('span', { text: 'child' });
    const parent = el('div', {}, child);
    assert.equal(parent.children.length, 1);
    assert.equal(parent.children[0], child);
  });

  test('el: opts 생략 시 기본값({})', () => {
    const node = el('div');
    assert.equal(node.tagName, 'div');
  });
});
