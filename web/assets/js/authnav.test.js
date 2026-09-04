// web/assets/js/authnav.test.js — 전역 헤더 로그인 진입점(SP-AUTH·SP-FE, SC14).
// 순수 판정(authStateFrom·navTargetFor)은 DOM 없이, 반영(applyAuthNav)·초기화(initAuthNav)는
// 최소 DOM 스텁으로 검증한다. jsdom 미설치 트리에서도 도는 자족 테스트.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import { authStateFrom, navTargetFor, applyAuthNav, applyEditLinks, initAuthNav, OFF_CACHE_KEY } from './authnav.js';

// ── 최소 DOM 스텁(jsdom 불필요) ──────────────────────────────────────────────
function stubDoc({ withSlot = true, withLabel = true } = {}) {
  const label = { textContent: '' };
  const slot = {
    hidden: true, attrs: {},
    setAttribute(k, v) { this.attrs[k] = v; },
    querySelector: (sel) => (withLabel && sel === '[data-authnav-label]' ? label : null),
  };
  return {
    _slot: slot, _label: label,
    querySelector: (sel) => (withSlot && sel === '[data-authnav]' ? slot : null),
  };
}
function stubStore() {
  const m = new Map();
  return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, v), _m: m };
}

describe('authStateFrom — 3값 프로브 판정', () => {
  test('404 → off (M9 라우터 미등록)', () => {
    assert.equal(authStateFrom(null, new ApiError(404, '/members/me', null)), 'off');
  });
  test('401 → anon (켜짐·비로그인)', () => {
    assert.equal(authStateFrom(null, new ApiError(401, '/members/me', null)), 'anon');
  });
  test('200 + 닉네임 → member', () => {
    assert.equal(authStateFrom({ status: 200, data: { nickname: '직장인-123456' } }, null), 'member');
  });
  test('200 인데 닉네임이 없으면 member 로 단정하지 않는다', () => {
    assert.equal(authStateFrom({ status: 200, data: {} }, null), 'anon');
  });
  test('네트워크 오류·타임아웃 → null(판단 보류)', () => {
    assert.equal(authStateFrom(null, new TypeError('Failed to fetch')), null);
    assert.equal(authStateFrom(null, new Error('aborted')), null);
  });
  test('500 같은 그 외 상태도 판단 보류 — 열람을 막지 않는다', () => {
    assert.equal(authStateFrom(null, new ApiError(500, '/members/me', null)), null);
  });
});

describe('navTargetFor', () => {
  test('anon → /login "로그인"', () => {
    assert.deepEqual(navTargetFor('anon'), { href: '/login', label: '로그인' });
  });
  test('member → /mypage 닉네임', () => {
    assert.deepEqual(navTargetFor('member', '직장인-999999'), { href: '/mypage', label: '직장인-999999' });
  });
  test('off·null → 노출 안 함', () => {
    assert.equal(navTargetFor('off'), null);
    assert.equal(navTargetFor(null), null);
  });
});

describe('applyEditLinks — 복지 원장 편집 진입(회사 페이지)', () => {
  const stubEditDoc = (n = 3) => {
    const links = Array.from({ length: n }, () => ({ hidden: true }));
    return {
      _links: links,
      querySelector: () => null,
      querySelectorAll: (sel) => (sel === '[data-authnav-edit]' ? links : []),
    };
  };
  test('anon·member 면 링크를 연다', () => {
    for (const st of ['anon', 'member']) {
      const doc = stubEditDoc();
      assert.equal(applyEditLinks(doc, st), 3);
      assert.ok(doc._links.every((l) => l.hidden === false), st);
    }
  });
  test('off·판단 보류면 숨긴 채 둔다 — M9 꺼진 prod 에서 /edit 은 404 다', () => {
    for (const st of ['off', null]) {
      const doc = stubEditDoc();
      applyEditLinks(doc, st);
      assert.ok(doc._links.every((l) => l.hidden === true), String(st));
    }
  });
  test('링크가 없는 페이지·doc 없음에서도 죽지 않는다', () => {
    assert.equal(applyEditLinks(stubEditDoc(0), 'anon'), 0);
    assert.equal(applyEditLinks(null, 'anon'), 0);
  });
  test('applyAuthNav 가 같은 프로브 결과로 함께 연다(판정 자리는 하나)', () => {
    const doc = stubDoc();
    const links = [{ hidden: true }];
    doc.querySelectorAll = (sel) => (sel === '[data-authnav-edit]' ? links : []);
    applyAuthNav(doc, 'anon');
    assert.equal(links[0].hidden, false);
  });
});

describe('applyAuthNav — 슬롯 반영', () => {
  test('anon 이면 href·라벨 설정 후 노출', () => {
    const doc = stubDoc();
    assert.equal(applyAuthNav(doc, 'anon'), true);
    assert.equal(doc._slot.attrs.href, '/login');
    assert.equal(doc._label.textContent, '로그인');
    assert.equal(doc._slot.hidden, false);
  });
  test('member 면 /mypage + 닉네임', () => {
    const doc = stubDoc();
    applyAuthNav(doc, 'member', '직장인-123456');
    assert.equal(doc._slot.attrs.href, '/mypage');
    assert.equal(doc._label.textContent, '직장인-123456');
  });
  test('off 면 숨긴 채로 둔다 — prod 에 진입점이 새지 않는다', () => {
    const doc = stubDoc();
    assert.equal(applyAuthNav(doc, 'off'), false);
    assert.equal(doc._slot.hidden, true);
    assert.equal(doc._slot.attrs.href, undefined);
  });
  test('판단 보류(null)도 숨김 유지', () => {
    const doc = stubDoc();
    assert.equal(applyAuthNav(doc, null), false);
    assert.equal(doc._slot.hidden, true);
  });
  test('슬롯이 없는 페이지에서도 죽지 않는다', () => {
    assert.equal(applyAuthNav(stubDoc({ withSlot: false }), 'anon'), false);
    assert.equal(applyAuthNav(null, 'anon'), false);
  });
  test('닉네임은 textContent 로만 들어간다(XSS)', () => {
    const doc = stubDoc();
    applyAuthNav(doc, 'member', '<img src=x onerror=alert(1)>');
    assert.equal(doc._label.textContent, '<img src=x onerror=alert(1)>'); // 문자열 그대로, 파싱 안 됨
  });
});

describe('initAuthNav — 네트워크 회피 조건', () => {
  test('슬롯이 없으면 프로브하지 않는다', async () => {
    const state = await initAuthNav({ doc: stubDoc({ withSlot: false }), store: stubStore(), path: '/' });
    assert.equal(state, null);
  });
  test('로그인 화면 자신에는 진입점을 띄우지 않는다', async () => {
    const doc = stubDoc();
    const state = await initAuthNav({ doc, store: stubStore(), path: '/login' });
    assert.equal(state, null);
    assert.equal(doc._slot.hidden, true);
  });
  test('M9 꺼짐이 캐시돼 있으면 요청 없이 off', async () => {
    const store = stubStore();
    store.setItem(OFF_CACHE_KEY, '1');
    const doc = stubDoc();
    const state = await initAuthNav({ doc, store, path: '/' });
    assert.equal(state, 'off');
    assert.equal(doc._slot.hidden, true);
  });
  test('sessionStorage 가 막혀 있어도 죽지 않는다', async () => {
    const blocked = { getItem() { throw new Error('denied'); }, setItem() { throw new Error('denied'); } };
    const prev = globalThis.fetch;
    globalThis.fetch = async () => new Response('', { status: 404 });
    try {
      const state = await initAuthNav({ doc: stubDoc(), store: blocked, path: '/' });
      assert.equal(state, 'off');
    } finally { globalThis.fetch = prev; }
  });
});

describe('initAuthNav — 실제 프로브 경로(fetch 목)', () => {
  async function withFetch(status, body, fn) {
    const prev = globalThis.fetch;
    globalThis.fetch = async () => new Response(body ? JSON.stringify(body) : '', {
      status, headers: { 'Content-Type': 'application/json' },
    });
    try { return await fn(); } finally { globalThis.fetch = prev; }
  }

  test('404 → off, 그리고 세션 캐시에 기록해 다음 페이지는 요청 0회', async () => {
    const store = stubStore(); const doc = stubDoc();
    await withFetch(404, null, () => initAuthNav({ doc, store, path: '/' }));
    assert.equal(store.getItem(OFF_CACHE_KEY), '1');
    assert.equal(doc._slot.hidden, true);
  });
  test('401 → "로그인" 노출, off 캐시는 남기지 않는다', async () => {
    const store = stubStore(); const doc = stubDoc();
    const state = await withFetch(401, { detail: 'unauthorized' }, () => initAuthNav({ doc, store, path: '/' }));
    assert.equal(state, 'anon');
    assert.equal(doc._slot.attrs.href, '/login');
    assert.equal(doc._slot.hidden, false);
    assert.equal(store.getItem(OFF_CACHE_KEY), null);
  });
  test('200 → 닉네임 노출 + /mypage', async () => {
    const doc = stubDoc();
    const state = await withFetch(200, { nickname: '직장인-424242' }, () =>
      initAuthNav({ doc, store: stubStore(), path: '/companies' }));
    assert.equal(state, 'member');
    assert.equal(doc._label.textContent, '직장인-424242');
    assert.equal(doc._slot.attrs.href, '/mypage');
  });
});
