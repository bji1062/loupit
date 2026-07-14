// web/assets/js/trending.test.js — "실시간 비교 TOP 10" 위젯 테스트.
// 순수(parseTrending·nextIndex·pairLabel·compareLogPayload) + jsdom DOM(롤링·호버 펼침·
// 클릭 onPick·실패 무해). 근거: INV-1 개정 2026-07-14(GET /comparisons/trending +
// 익명 POST /comparisons/log), ui.test.js와 동일한 jsdom 부트스트랩 관례.

// ── dom.js가 document를 참조하므로 최소 전역 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import {
  parseTrending, nextIndex, pairLabel, compareLogPayload, sendCompareLog, mountTrending, ROTATE_MS,
} from './trending.js';

function item(i) {
  return {
    a_comp_id: i * 2 - 1, a_comp_nm: 'A' + i + '사',
    b_comp_id: i * 2, b_comp_nm: 'B' + i + '사', cnt: 100 - i,
  };
}
const TEN = Array.from({ length: 10 }, (_, k) => item(k + 1));

// ── 순수: parseTrending ─────────────────────────────────────────────────────
describe('parseTrending — shape 검증·무효 필터·10개 캡', () => {
  test('정상 items → 그대로(최대 10)', () => {
    const out = parseTrending({ items: TEN });
    assert.equal(out.length, 10);
    assert.equal(out[0].a_comp_nm, 'A1사');
  });

  test('11개 이상 → 10개 캡', () => {
    const out = parseTrending({ items: [...TEN, item(11)] });
    assert.equal(out.length, 10);
  });

  test('무효 항목(이름 공백·comp_id 비정수) 필터', () => {
    const bad = [
      { a_comp_id: 1, a_comp_nm: ' ', b_comp_id: 2, b_comp_nm: 'B', cnt: 1 },
      { a_comp_id: 'x', a_comp_nm: 'A', b_comp_id: 2, b_comp_nm: 'B', cnt: 1 },
      null,
      item(1),
    ];
    const out = parseTrending({ items: bad });
    assert.equal(out.length, 1);
    assert.equal(out[0].a_comp_id, 1);
  });

  test('손상 입력(null·items 아님) → []', () => {
    assert.deepEqual(parseTrending(null), []);
    assert.deepEqual(parseTrending({}), []);
    assert.deepEqual(parseTrending({ items: 'x' }), []);
  });
});

// ── 순수: nextIndex·pairLabel ───────────────────────────────────────────────
describe('nextIndex·pairLabel', () => {
  test('nextIndex: 순환(9→0), len 0 → 0', () => {
    assert.equal(nextIndex(0, 10), 1);
    assert.equal(nextIndex(9, 10), 0);
    assert.equal(nextIndex(3, 0), 0);
  });

  test('pairLabel: "A vs B"', () => {
    assert.equal(pairLabel(item(1)), 'A1사 vs B1사');
  });
});

// ── 순수: compareLogPayload(익명 쌍만 — 직접 입력 제외) ─────────────────────
describe('compareLogPayload — 회사쌍만, 직접 입력·동일쌍 제외', () => {
  test('양 슬롯 회사 매칭 → {a,b} comp_id', () => {
    const state = { matched: { a: { comp_id: 1 }, b: { comp_id: 2 } } };
    assert.deepEqual(compareLogPayload(state), { a: 1, b: 2 });
  });

  test('한쪽 직접 입력(comp_id 없음) → null', () => {
    const state = { matched: { a: { comp_id: 1 }, b: null } };
    assert.equal(compareLogPayload(state), null);
    const state2 = { matched: { a: { comp_id: 1 }, b: { comp_nm: '직접' } } };
    assert.equal(compareLogPayload(state2), null);
  });

  test('동일 회사쌍 → null', () => {
    const state = { matched: { a: { comp_id: 1 }, b: { comp_id: 1 } } };
    assert.equal(compareLogPayload(state), null);
  });
});

describe('sendCompareLog — beacon 전송(무크래시)', () => {
  test('유효 쌍 → beaconFn(url, blob) 1회, true', () => {
    const calls = [];
    const state = { matched: { a: { comp_id: 3 }, b: { comp_id: 7 } } };
    const ok = sendCompareLog(state, { beaconFn: (url, body) => { calls.push({ url, body }); return true; } });
    assert.equal(ok, true);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, '/api/v1/comparisons/log');
  });

  test('직접 입력 쌍 → 미전송·false', () => {
    const calls = [];
    const state = { matched: { a: { comp_nm: '직접' }, b: { comp_id: 7 } } };
    const ok = sendCompareLog(state, { beaconFn: (u, b) => { calls.push(u); return true; } });
    assert.equal(ok, false);
    assert.equal(calls.length, 0);
  });

  test('beaconFn throw → false(무크래시)', () => {
    const state = { matched: { a: { comp_id: 1 }, b: { comp_id: 2 } } };
    const ok = sendCompareLog(state, { beaconFn: () => { throw new Error('x'); } });
    assert.equal(ok, false);
  });
});

// ── DOM: mountTrending(jsdom) ───────────────────────────────────────────────
function loadDom() {
  const dom = new JSDOM(
    '<main><aside id="trending" class="rail" hidden aria-label="실시간 비교 TOP 10"></aside></main>',
    { url: 'https://loupit.example/', pretendToBeVisual: true },
  );
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  return dom;
}

function okFetch(items = TEN) {
  return async () => ({ ok: true, json: async () => ({ items }) });
}

describe('mountTrending — 렌더·롤링·호버 펼침·클릭', () => {
  beforeEach(() => loadDom());

  test('성공 로드 → host 표시, 목록 10행, 접힘 행=1위', async () => {
    await mountTrending({ fetchFn: okFetch() });
    const host = document.getElementById('trending');
    assert.equal(host.hidden, false);
    assert.equal(host.querySelectorAll('.trend-list .trend-item').length, 10);
    assert.match(host.querySelector('.trend-current .trend-rank').textContent, /^1$/);
    assert.match(host.querySelector('.trend-current').textContent, /A1사/);
    assert.match(host.querySelector('.trend-title').textContent, /실시간 비교 TOP 10/);
  });

  test('롤링: ROTATE_MS 경과 → 접힘 행이 2위로 전진(순환)', async (t) => {
    t.mock.timers.enable({ apis: ['setInterval'] });
    await mountTrending({ fetchFn: okFetch() });
    const host = document.getElementById('trending');
    t.mock.timers.tick(ROTATE_MS);
    assert.match(host.querySelector('.trend-current .trend-rank').textContent, /^2$/);
    assert.match(host.querySelector('.trend-current').textContent, /A2사/);
    // 10틱 더(총 11틱) → 10개를 완전 순환해 다시 2위
    t.mock.timers.tick(ROTATE_MS * 10);
    assert.match(host.querySelector('.trend-current .trend-rank').textContent, /^2$/);
  });

  test('mouseenter → 펼침(.trend-expanded) + 롤링 정지, mouseleave → 접힘·재개', async (t) => {
    t.mock.timers.enable({ apis: ['setInterval'] });
    await mountTrending({ fetchFn: okFetch() });
    const host = document.getElementById('trending');
    host.dispatchEvent(new window.Event('mouseenter'));
    assert.ok(host.classList.contains('trend-expanded'));
    t.mock.timers.tick(ROTATE_MS * 3);
    assert.match(host.querySelector('.trend-current .trend-rank').textContent, /^1$/, '펼침 중 롤링 정지');
    host.dispatchEvent(new window.Event('mouseleave'));
    assert.ok(!host.classList.contains('trend-expanded'));
    t.mock.timers.tick(ROTATE_MS);
    assert.match(host.querySelector('.trend-current .trend-rank').textContent, /^2$/, '접힘 후 롤링 재개');
  });

  test('focusin/focusout(키보드) → 펼침/접힘', async () => {
    await mountTrending({ fetchFn: okFetch() });
    const host = document.getElementById('trending');
    host.dispatchEvent(new window.Event('focusin'));
    assert.ok(host.classList.contains('trend-expanded'));
    host.dispatchEvent(new window.Event('focusout'));
    assert.ok(!host.classList.contains('trend-expanded'));
  });

  test('항목 클릭 → onPick(item) 호출', async () => {
    const picked = [];
    await mountTrending({ fetchFn: okFetch(), onPick: (it) => picked.push(it) });
    const host = document.getElementById('trending');
    const third = host.querySelectorAll('.trend-list .trend-item')[2];
    third.dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(picked.length, 1);
    assert.equal(picked[0].a_comp_nm, 'A3사');
  });

  test('fetch 실패 → host 계속 hidden(무크래시)', async () => {
    await mountTrending({ fetchFn: async () => { throw new Error('network'); } });
    assert.equal(document.getElementById('trending').hidden, true);
  });

  test('빈 items → host 계속 hidden', async () => {
    await mountTrending({ fetchFn: okFetch([]) });
    assert.equal(document.getElementById('trending').hidden, true);
  });

  test('host 부재(다른 페이지) → no-op', async () => {
    document.getElementById('trending').remove();
    await assert.doesNotReject(mountTrending({ fetchFn: okFetch() }));
  });
});
