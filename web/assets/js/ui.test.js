// web/assets/js/ui.test.js — SPA DOM 배선 통합 테스트(jsdom, 실 DOM).
// 목적: 순수함수(node --test)만 green이고 실제 브라우저에선 비교툴이 죽어 있던 갭(bindGlobalUI
// 자리표시자·onSearchInput 미배선)을 재발 방지한다. 셸(compare/index.html)을 jsdom에 로드해
// 검색입력→onSearchInput, 후보 클릭→선택, 선택→입력뷰 전진, 입력 컨트롤 렌더·배선, 비교하기
// →runReport·go('report')를 실제 DOM 이벤트로 검증한다. (근거: SP-FE-3 이벤트 바인딩, MB-3·5·8·15.)

// ── app.js 최상위 import가 document/window를 참조하므로 최소 전역을 먼저 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, querySelector() { return null; }, createElement() { return {}; } };
globalThis.history = { pushState() {} };
globalThis.location = { hash: '', search: '' };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { JSDOM } from 'jsdom';

import {
  mountUI, renderInputView, renderInputSlot, renderPriorityPicker,
  bindSearchView, bindInputView, bindReportNav, reflectSearchUI, reflectSlotLabel, maybeAdvance,
} from './ui.js';
import { createInitialState } from './app.js';
import { setSearchState } from './search.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const SHELL = readFileSync(join(HERE, '../../compare/index.html'), 'utf8');

function loadShell(url = 'https://loupit.example/compare/') {
  const dom = new JSDOM(SHELL, { url, pretendToBeVisual: true });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  globalThis.history = dom.window.history;
  globalThis.location = dom.window.location;
  // #app 표시(부팅 성공 상태 모사)
  const app = dom.window.document.getElementById('app');
  if (app) app.hidden = false;
  return dom;
}

function fixtureCompany(id, nm) {
  return {
    comp_id: id, comp_nm: nm, comp_eng_nm: nm.toLowerCase(), comp_tp_cd: 'large', industry_nm: '반도체',
    work_style_val: { remote: true, flex: false }, aliases: [],
    benefits: [
      { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 120, benefit_ctgr_cd: 'perks', qual_yn: false, amt_source: 'stated', badge_cd: 'official' },
      { benefit_cd: 'edu', benefit_nm: '교육비', benefit_amt: 100, benefit_ctgr_cd: 'growth', qual_yn: false, amt_source: 'estimated', badge_cd: 'est' },
    ],
  };
}

function stateWithMatches() {
  const s = createInitialState();
  s.REF = { companies: [fixtureCompany(1, 'A사'), fixtureCompany(2, 'B사')], company_types: [], benefit_presets: {} };
  s.matched.a = fixtureCompany(1, 'A사');
  s.matched.b = fixtureCompany(2, 'B사');
  s.benS.a = s.matched.a.benefits.map((b) => ({ ...b, checked: true }));
  s.benS.b = s.matched.b.benefits.map((b) => ({ ...b, checked: true }));
  return s;
}

describe('UI-1 검색 입력 배선(입력 이벤트 → onSearchInput)', () => {
  beforeEach(() => loadShell());

  test('search-input-a 에 input 이벤트 → onSearchInput 발화(searchState=loading)', () => {
    const state = createInitialState();
    state.REF = { companies: [], company_types: [], benefit_presets: {} };
    bindSearchView(state, {});
    const input = document.getElementById('search-input-a');
    input.value = '삼성';
    input.dispatchEvent(new window.Event('input', { bubbles: true }));
    assert.equal(state.ui.searchState.a, 'loading', 'input 이벤트가 onSearchInput 에 도달해 loading 으로 전이해야 한다');
  });

  test('빈 입력 → 패널 닫힘(idle), 후보 미호출', () => {
    const state = createInitialState();
    bindSearchView(state, {});
    const input = document.getElementById('search-input-a');
    input.value = '   ';
    input.dispatchEvent(new window.Event('input', { bubbles: true }));
    assert.equal(state.ui.searchState.a, 'idle');
  });
});

describe('UI-2 검색 상태 → 셸 메시지 반영(무결과 vs 오류, MB-4)', () => {
  beforeEach(() => loadShell());

  test('empty → search-empty 노출·search-error 숨김', () => {
    const state = createInitialState();
    setSearchState(state, 'a', 'empty');
    reflectSearchUI(state, 'a');
    assert.equal(document.querySelector('.search-empty[data-slot="a"]').hidden, false);
    assert.equal(document.querySelector('.search-error[data-slot="a"]').hidden, true);
  });

  test('error → search-error 노출·search-empty 숨김', () => {
    const state = createInitialState();
    setSearchState(state, 'a', 'error');
    reflectSearchUI(state, 'a');
    assert.equal(document.querySelector('.search-error[data-slot="a"]').hidden, false);
    assert.equal(document.querySelector('.search-empty[data-slot="a"]').hidden, true);
  });

  test('mountUI 후 setSearchState 만으로 셸 반영(onSearchState 훅 배선)', () => {
    const state = createInitialState();
    mountUI(state, {});
    setSearchState(state, 'b', 'error');
    assert.equal(document.querySelector('.search-error[data-slot="b"]').hidden, false);
  });
});

describe('UI-3 입력 뷰 컨트롤 렌더·상태 배선(MB-5·15)', () => {
  beforeEach(() => loadShell());

  test('renderInputView: 슬롯 a 연봉·복지 체크박스, 슬롯 b 상승률, 우선순위 라디오 렌더', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    assert.ok(document.getElementById('sal-low'), '슬롯 a 연봉 최소 입력 렌더');
    assert.ok(document.getElementById('sal-high'), '슬롯 a 연봉 최대 입력 렌더');
    assert.ok(document.getElementById('offer-rate'), '슬롯 b 상승률 입력 렌더');
    const benA = document.querySelectorAll('#input-slot-a .in-ben-row input[type="checkbox"]');
    assert.equal(benA.length, 2, '슬롯 a 복지 체크박스 2개');
    const pri = document.querySelectorAll('#priority-picker input[type="radio"]');
    assert.equal(pri.length, 4, '우선순위 라디오 4개');
    const checkedPri = document.querySelector('#priority-picker input[type="radio"]:checked');
    assert.equal(checkedPri.value, '워라밸', '기본 우선순위 워라밸 체크');
  });

  test('연봉 입력 변경 → state.salS.a 반영', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    const low = document.getElementById('sal-low');
    const high = document.getElementById('sal-high');
    low.value = '5000'; low.dispatchEvent(new window.Event('input', { bubbles: true }));
    high.value = '7000'; high.dispatchEvent(new window.Event('input', { bubbles: true }));
    assert.deepEqual(state.salS.a, { low: 5000, high: 7000 });
  });

  test('복지 체크박스 해제 → state.benS.a[i].checked=false', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    const cb = document.querySelector('#input-slot-a .in-ben-row input[type="checkbox"]');
    cb.checked = false; cb.dispatchEvent(new window.Event('change', { bubbles: true }));
    assert.equal(state.benS.a[0].checked, false);
  });

  test('우선순위 라디오 변경 → state.curPri', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    const rb = document.getElementById('pri-복지');
    rb.checked = true; rb.dispatchEvent(new window.Event('change', { bubbles: true }));
    assert.equal(state.curPri, '복지');
  });
});

describe('UI-4 선택 → 입력뷰 전진 + 비교하기 배선(MB-8·15)', () => {
  beforeEach(() => loadShell());

  test('maybeAdvance: 양 슬롯 matched → 입력뷰 렌더 + go("input")', () => {
    const state = stateWithMatches();
    const calls = [];
    maybeAdvance(state, { go: (v) => calls.push(v) });
    assert.deepEqual(calls, ['input']);
    assert.ok(document.getElementById('sal-low'), '입력뷰 컨트롤이 렌더됨');
  });

  test('한쪽만 matched → 전진 안 함(검색뷰 유지)', () => {
    const state = stateWithMatches();
    state.matched.b = null;
    const calls = [];
    maybeAdvance(state, { go: (v) => calls.push(v) });
    assert.deepEqual(calls, []);
  });

  test('btn-compare 클릭 → runReport 호출 + go("report")', () => {
    const state = stateWithMatches();
    state.salS.a = { low: 5000, high: 7000 };
    renderInputView(state, {});
    const seen = { report: 0, go: null, ads: null };
    bindInputView(state, {
      runReport: () => { seen.report += 1; },
      go: (v) => { seen.go = v; },
      mountAds: (t) => { seen.ads = t; },
    });
    document.getElementById('btn-compare').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(seen.report, 1, 'runReport 1회 호출');
    assert.equal(seen.go, 'report');
    assert.equal(seen.ads, 'result', 'result 뷰 광고 마운트(MON9)');
  });
});

describe('UI-6 헤더 검색(bindHeaderSearch — GNB 검색창 → A 슬롯)', () => {
  beforeEach(() => loadShell());

  test('제출 → A 슬롯 값 주입 + onSearchInput 발화(loading) + go("search")', () => {
    const state = createInitialState();
    state.REF = { companies: [], company_types: [], benefit_presets: {} };
    const calls = [];
    mountUI(state, { go: (s) => calls.push(s) });
    const form = document.querySelector('.gnb-search');
    assert.ok(form, '셸에 GNB 검색 폼 존재');
    const q = form.querySelector('input[type="search"]');
    q.value = '삼성';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    assert.equal(document.getElementById('search-input-a').value, '삼성', 'A 슬롯 검색창에 주입');
    assert.equal(state.ui.searchState.a, 'loading', 'onSearchInput 경로 발화');
    assert.ok(calls.includes('search'), '검색 뷰로 전환');
  });

  test('빈 검색어 제출 → 무해(no-op, 상태 idle 유지)', () => {
    const state = createInitialState();
    mountUI(state, {});
    const form = document.querySelector('.gnb-search');
    form.querySelector('input[type="search"]').value = '   ';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    assert.equal(state.ui.searchState.a, 'idle');
  });
});

describe('UI-5 리포트 내비 배선', () => {
  beforeEach(() => loadShell());

  test('btn-new-search → 슬롯 초기화 + go("search")', () => {
    const state = stateWithMatches();
    let dest = null;
    bindReportNav(state, { go: (v) => { dest = v; } });
    document.getElementById('btn-new-search').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(dest, 'search');
    assert.equal(state.matched.a, null);
    assert.equal(state.matched.b, null);
  });

  test('btn-edit-input → go("input")', () => {
    const state = stateWithMatches();
    let dest = null;
    bindReportNav(state, { go: (v) => { dest = v; } });
    document.getElementById('btn-edit-input').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(dest, 'input');
  });
});
