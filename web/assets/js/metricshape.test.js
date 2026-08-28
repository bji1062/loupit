// metricshape.js — 그래프 모양 선택 **기억만** 하는지 검증(SP-MET-10, jsdom).
//
// 여기서 잡으려는 회귀는 두 종류다.
//   ① 저장소가 던지는 환경(사생활 보호 모드·쿠키 차단)에서 예외가 새어 본문 스크립트를 죽이는 것.
//   ② 🚨 이 모듈이 **화면을 결정하기 시작하는 것.** 저장값이 닿는 곳은 라디오의 `checked` 하나뿐이고,
//      카드·섹션의 마크업은 한 글자도 바뀌지 않아야 한다(대문 사고 2026-07-31 재발 방지).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import {
  SHAPE_KEY, readShape, writeShape, restoreShape, bindShape, initMetricShape,
} from './metricshape.js';

// 실제 `_metrics.html` 의 구조 그대로 — 라디오·라벨·카드가 **형제**여야 CSS 전환이 닿는다.
const HTML = `<section class="metrics"><h2>연도별 추이</h2><fieldset class="mshape">
<input class="mshape-in" type="radio" name="metric-shape" id="metric-shape-bar" value="bar" checked>
<label class="mshape-lb" for="metric-shape-bar">막대</label>
<input class="mshape-in" type="radio" name="metric-shape" id="metric-shape-line" value="line">
<label class="mshape-lb" for="metric-shape-line">꺾은선</label>
<div class="metric-cards"><div class="metric-card" data-metric="salary">
<div class="mchart mchart-bar"><svg></svg></div><div class="mchart mchart-line"><svg></svg></div>
</div></div></fieldset></section>`;

function doc(html = HTML) {
  return new JSDOM(html).window.document;
}

class FakeStorage {
  constructor(data = {}) { this._d = new Map(Object.entries(data)); this.throwOn = null; }
  getItem(k) { if (this.throwOn === 'get') throw new Error('blocked'); return this._d.has(k) ? this._d.get(k) : null; }
  setItem(k, v) { if (this.throwOn === 'set') throw new Error('quota'); this._d.set(k, String(v)); }
}

const THROWS = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('blocked'); } };

// ── 읽기: 목록 밖 값과 예외를 같은 자리에서 흡수한다 ─────────────────────────
describe('readShape', () => {
  test('저장값이 없으면 null — HTML 이 정한 기본값을 그대로 둔다는 뜻이다', () => {
    assert.equal(readShape(new FakeStorage()), null);
  });

  test("'bar'·'line' 만 통과한다", () => {
    assert.equal(readShape(new FakeStorage({ [SHAPE_KEY]: 'line' })), 'line');
    assert.equal(readShape(new FakeStorage({ [SHAPE_KEY]: 'bar' })), 'bar');
  });

  test('목록 밖 값은 버린다 — 저장소는 사용자가 직접 고칠 수 있는 곳이다', () => {
    for (const bad of ['pie', '', 'BAR', '__proto__', '<script>']) {
      assert.equal(readShape(new FakeStorage({ [SHAPE_KEY]: bad })), null, bad);
    }
  });

  test('읽기에서 던지는 저장소(사생활 보호 모드)도 null 로 흡수한다', () => {
    assert.equal(readShape(THROWS), null);
  });
});

// ── 쓰기 ────────────────────────────────────────────────────────────────────
describe('writeShape', () => {
  test('허용 값만 저장한다', () => {
    const s = new FakeStorage();
    assert.equal(writeShape('line', s), true);
    assert.equal(s.getItem(SHAPE_KEY), 'line');
  });

  test('목록 밖 값은 저장소에 닿지도 않는다', () => {
    const s = new FakeStorage();
    assert.equal(writeShape('pie', s), false);
    assert.equal(s.getItem(SHAPE_KEY), null);
  });

  test('저장 실패는 false 일 뿐 예외가 아니다 — 이번 세션만 기억 못 한다', () => {
    const s = new FakeStorage(); s.throwOn = 'set';
    assert.equal(writeShape('bar', s), false);
  });
});

// ── 복원: 건드리는 것은 라디오 하나뿐 ────────────────────────────────────────
describe('restoreShape', () => {
  test("저장값 'line' 이면 꺾은선 라디오가 켜진다", () => {
    const d = doc();
    assert.equal(restoreShape(d, new FakeStorage({ [SHAPE_KEY]: 'line' })), 'line');
    assert.equal(d.getElementById('metric-shape-line').checked, true);
    assert.equal(d.getElementById('metric-shape-bar').checked, false);
  });

  test('저장값이 없으면 기본(막대)이 그대로 남는다', () => {
    const d = doc();
    assert.equal(restoreShape(d, new FakeStorage()), null);
    assert.equal(d.getElementById('metric-shape-bar').checked, true);
  });

  test('🚨 마크업은 한 글자도 바뀌지 않는다 — 이 모듈은 그래프 모양만 정한다', () => {
    const d = doc();
    const before = d.querySelector('section.metrics').outerHTML;
    restoreShape(d, new FakeStorage({ [SHAPE_KEY]: 'line' }));
    assert.equal(d.querySelector('section.metrics').outerHTML, before,
      '저장값이 checked 말고 다른 것을 건드렸다 — 화면 결정권이 새고 있다');
    assert.equal(d.querySelectorAll('.metric-card').length, 1);
    assert.equal(d.querySelectorAll('.mchart').length, 2, '두 벌 다 HTML 에 남아 있어야 CSS 가 고른다');
  });

  test('그래프가 없는 페이지에서는 아무것도 하지 않는다', () => {
    assert.equal(restoreShape(doc('<main></main>'), new FakeStorage({ [SHAPE_KEY]: 'line' })), null);
  });
});

// ── 배선·진입점 ──────────────────────────────────────────────────────────────
describe('bindShape · initMetricShape', () => {
  test('라디오를 바꾸면 그 값이 저장된다', () => {
    const d = doc(); const s = new FakeStorage();
    assert.equal(bindShape(d, s), 2);
    const line = d.getElementById('metric-shape-line');
    line.checked = true;
    line.dispatchEvent(new d.defaultView.Event('change'));
    assert.equal(s.getItem(SHAPE_KEY), 'line');
  });

  test('꺼진 라디오의 change 는 저장하지 않는다(라디오는 짝으로 발화할 수 있다)', () => {
    const d = doc(); const s = new FakeStorage();
    bindShape(d, s);
    const bar = d.getElementById('metric-shape-bar');
    bar.checked = false;
    bar.dispatchEvent(new d.defaultView.Event('change'));
    assert.equal(s.getItem(SHAPE_KEY), null);
  });

  test('복원 → 배선 순서로 돌고, 저장소가 통째로 던져도 예외가 새지 않는다', () => {
    const d = doc();
    assert.equal(initMetricShape(d, THROWS), 2, '읽기 실패해도 배선은 살아 있어야 한다');
    assert.equal(d.getElementById('metric-shape-bar').checked, true);
  });

  test('라디오가 없는 문서에서는 0 을 돌려주고 조용히 끝난다', () => {
    assert.equal(initMetricShape(doc('<main></main>'), new FakeStorage()), 0);
  });
});
