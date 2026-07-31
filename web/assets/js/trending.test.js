// web/assets/js/trending.test.js — "많이 찾아본 조합" 위젯 테스트.
// 순수(parseTrending·fallbackPairs·nextIndex·pairLabel·compareLogPayload) + jsdom DOM
// (롤링·호버 펼침·클릭 onPick·실패 무해·콜드스타트 폴백). 근거: INV-1 개정 2026-07-14
// (GET /comparisons/trending + 익명 POST /comparisons/log), 콜드스타트 폴백·세션 중복
// 제거 2026-07-31, ui.test.js와 동일한 jsdom 부트스트랩 관례.

// ── dom.js가 document를 참조하므로 최소 전역 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import {
  parseTrending, fallbackPairs, nextIndex, pairLabel, compareLogPayload, sendCompareLog,
  resetSentPairs, mountTrending, ROTATE_MS, TRENDING_TITLE, SUGGEST_TITLE,
} from './trending.js';

function item(i) {
  return {
    a_comp_id: i * 2 - 1, a_comp_nm: 'A' + i + '사',
    b_comp_id: i * 2, b_comp_nm: 'B' + i + '사', cnt: 100 - i,
  };
}
const TEN = Array.from({ length: 10 }, (_, k) => item(k + 1));

// REF 번들 모양의 회사 목록(폴백 재료). industry_nm은 라이브 번들에서 102/102 채워져 있다.
function co(id, nm, industry_nm) { return { comp_id: id, comp_nm: nm, industry_nm }; }
const COMPANIES = [
  co(11, '게임가', '게임'), co(12, '게임나', '게임'), co(13, '게임다', '게임'), co(14, '게임라', '게임'),
  co(21, '반도체가', '반도체'), co(22, '반도체나', '반도체'),
  co(31, '외톨이', '조선'), // 1개짜리 업종 → 쌍 불가
  co(41, '업종없음', ''), // 업종 미상 → 제외
];

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

// ── 순수: fallbackPairs(콜드스타트 — 서버 집계 없이 같은 업종 제안) ─────────
describe('fallbackPairs — 같은 업종 쌍, 결정론적', () => {
  test('업종 내부 comp_id 오름차순 인접 짝 + 라운드로빈(한 업종 독식 방지)', () => {
    const out = fallbackPairs(COMPANIES);
    // 게임 4곳 → 2쌍, 반도체 2곳 → 1쌍. 라운드로빈이라 게임·반도체·게임 순.
    assert.deepEqual(out.map((p) => [p.a_comp_nm, p.b_comp_nm]), [
      ['게임가', '게임나'], ['반도체가', '반도체나'], ['게임다', '게임라'],
    ]);
  });

  test('1개짜리 업종·업종 미상은 제외(쌍을 만들 근거가 없다)', () => {
    const names = fallbackPairs(COMPANIES).flatMap((p) => [p.a_comp_nm, p.b_comp_nm]);
    assert.ok(!names.includes('외톨이'));
    assert.ok(!names.includes('업종없음'));
  });

  test('결정론: 같은 입력 → 같은 출력(새로고침해도 방금 본 조합이 그대로)', () => {
    assert.deepEqual(fallbackPairs(COMPANIES), fallbackPairs(COMPANIES));
  });

  test('limit 캡', () => {
    assert.equal(fallbackPairs(COMPANIES, 2).length, 2);
    assert.ok(fallbackPairs(COMPANIES, 99).length <= 3); // 재료가 3쌍뿐
  });

  test('손상 입력(null·배열 아님·필드 결측) → [] 또는 무시(무크래시)', () => {
    assert.deepEqual(fallbackPairs(null), []);
    assert.deepEqual(fallbackPairs('x'), []);
    assert.deepEqual(fallbackPairs([]), []);
    assert.deepEqual(fallbackPairs([null, { comp_id: 'x', comp_nm: 'A', industry_nm: 'IT' },
      { comp_id: 1, comp_nm: ' ', industry_nm: 'IT' }]), []);
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
  beforeEach(() => resetSentPairs()); // 세션 중복 제거는 모듈 전역 — 테스트마다 격리한다

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

  // B-7 재발 방지: 기록 시점을 "양 슬롯 확정"으로 낮췄으므로(2026-07-31) 같은 쌍이
  // 한 세션에서 여러 번 발사될 수 있다 — 그대로 두면 한 사람의 왕복이 순위를 만든다.
  test('같은 쌍 반복 → 세션당 1회만 전송(집계 부풀림 차단)', () => {
    const calls = [];
    const beaconFn = (url) => { calls.push(url); return true; };
    const state = { matched: { a: { comp_id: 3 }, b: { comp_id: 7 } } };
    assert.equal(sendCompareLog(state, { beaconFn }), true);
    assert.equal(sendCompareLog(state, { beaconFn }), false);
    assert.equal(sendCompareLog(state, { beaconFn }), false);
    assert.equal(calls.length, 1);
  });

  test('다른 쌍은 각각 전송(중복 제거가 쌍 단위인지)', () => {
    const calls = [];
    const beaconFn = (url) => { calls.push(url); return true; };
    sendCompareLog({ matched: { a: { comp_id: 3 }, b: { comp_id: 7 } } }, { beaconFn });
    sendCompareLog({ matched: { a: { comp_id: 3 }, b: { comp_id: 9 } } }, { beaconFn });
    assert.equal(calls.length, 2);
  });

  test('발사 실패(throw)는 기록되지 않는다 → 다음 기회에 재시도 가능', () => {
    const state = { matched: { a: { comp_id: 5 }, b: { comp_id: 6 } } };
    assert.equal(sendCompareLog(state, { beaconFn: () => { throw new Error('x'); } }), false);
    const calls = [];
    assert.equal(sendCompareLog(state, { beaconFn: (u) => { calls.push(u); return true; } }), true);
    assert.equal(calls.length, 1);
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
    assert.match(host.querySelector('.trend-title').textContent, new RegExp(TRENDING_TITLE));
    assert.equal(host.dataset.mode, 'trending');
  });

  test('스크래핑 방어: trending fetch가 X-Loupit-Client 헤더를 보낸다(제거 시 위젯 403)', async () => {
    let seen = null;
    await mountTrending({ fetchFn: async (url, opt) => { seen = opt; return { ok: true, json: async () => ({ items: TEN }) }; } });
    assert.equal(seen?.headers?.['X-Loupit-Client'], 'web',
      '헤더가 빠지면 nginx가 comparisons/trending을 403 처리해 위젯이 조용히 사라진다');
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

  test('fetch 실패 + 폴백 재료 없음 → host 계속 hidden(무크래시)', async () => {
    await mountTrending({ fetchFn: async () => { throw new Error('network'); } });
    assert.equal(document.getElementById('trending').hidden, true);
  });

  test('빈 items + 폴백 재료 없음 → host 계속 hidden', async () => {
    await mountTrending({ fetchFn: okFetch([]) });
    assert.equal(document.getElementById('trending').hidden, true);
  });

  test('host 부재(다른 페이지) → no-op', async () => {
    document.getElementById('trending').remove();
    await assert.doesNotReject(mountTrending({ fetchFn: okFetch() }));
  });
});

// ── 콜드스타트 폴백(2026-07-31) ─────────────────────────────────────────────
// 회귀 근거: 마지막 비교 로그가 2026-07-20 → 7일 윈도우가 07-27에 비면서 위젯이
// 통째로 사라졌다. "집계 0건이면 숨는다"가 사양대로 동작한 결과였다.
describe('mountTrending — 집계 0건이면 같은 업종 제안으로 대체', () => {
  beforeEach(() => loadDom());

  test('집계 0건 + companies → 폴백 렌더(숨지 않는다)', async () => {
    const res = await mountTrending({ fetchFn: okFetch([]), companies: COMPANIES });
    const host = document.getElementById('trending');
    assert.equal(host.hidden, false, '집계가 비어도 위젯이 화면에서 사라지면 안 된다');
    assert.equal(host.dataset.mode, 'suggest');
    assert.equal(res.mode, 'suggest');
    assert.equal(host.querySelectorAll('.trend-list .trend-item').length, 3);
    assert.match(host.querySelector('.trend-current').textContent, /게임가/);
  });

  test('폴백 제목·캡션은 집계를 주장하지 않는다(TOP·인기 문구 금지)', async () => {
    await mountTrending({ fetchFn: okFetch([]), companies: COMPANIES });
    const host = document.getElementById('trending');
    const title = host.querySelector('.trend-title').textContent;
    assert.equal(title, SUGGEST_TITLE);
    assert.ok(!/TOP|인기/.test(title), '서버 집계가 아닌데 인기를 주장하면 과장이다');
    assert.equal(host.getAttribute('aria-label'), SUGGEST_TITLE);
    assert.equal(host.querySelectorAll('.trend-rank').length, 0,
      '제목으로 부인하면서 1·2·3 번호로 순위를 주장하면 안 된다');
  });

  test('집계 모드에서는 순위 번호가 그대로 있다', async () => {
    await mountTrending({ fetchFn: okFetch(), companies: COMPANIES });
    const host = document.getElementById('trending');
    assert.equal(host.querySelectorAll('.trend-list .trend-rank').length, 10);
  });

  test('API 실패 + companies → 폴백(REF는 이미 로드돼 네트워크 불필요)', async () => {
    await mountTrending({ fetchFn: async () => { throw new Error('network'); }, companies: COMPANIES });
    const host = document.getElementById('trending');
    assert.equal(host.hidden, false);
    assert.equal(host.dataset.mode, 'suggest');
  });

  test('집계가 있으면 폴백을 쓰지 않는다(집계 우선)', async () => {
    const res = await mountTrending({ fetchFn: okFetch(), companies: COMPANIES });
    const host = document.getElementById('trending');
    assert.equal(res.mode, 'trending');
    assert.equal(host.querySelector('.trend-title').textContent, TRENDING_TITLE);
    assert.match(host.querySelector('.trend-current').textContent, /A1사/);
  });

  test('폴백 항목 클릭도 onPick으로 이어진다(같은 프리필 경로)', async () => {
    const picked = [];
    await mountTrending({ fetchFn: okFetch([]), companies: COMPANIES, onPick: (it) => picked.push(it) });
    const host = document.getElementById('trending');
    host.querySelectorAll('.trend-list .trend-item')[0]
      .dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(picked.length, 1);
    assert.equal(picked[0].a_comp_id, 11);
    assert.equal(picked[0].b_comp_id, 12);
  });
});
