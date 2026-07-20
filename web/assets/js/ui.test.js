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
  missingMessage,
} from './ui.js';
import { createInitialState, boot, App } from './app.js';
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
    assert.equal(pri.length, 3, '우선순위 라디오 3개(브랜드 축 제거 2026-07-20)');
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

describe('UI-6 헤더 검색(bindHeaderSearch — GNB 검색 → 회사 복지 페이지 직행)', () => {
  beforeEach(() => loadShell());

  test('제출 → deps.showCompany(term) 호출(트림된 검색어)', () => {
    const state = createInitialState();
    const shown = [];
    mountUI(state, { showCompany: (t) => shown.push(t) });
    const form = document.querySelector('.gnb-search');
    assert.ok(form, '셸에 GNB 검색 폼 존재');
    form.querySelector('input[type="search"]').value = '  삼성전자 ';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    assert.deepEqual(shown, ['삼성전자'], '회사 복지 페이지 훅 호출');
    assert.equal(state.ui.searchState.a, 'idle', 'A 슬롯 검색 미발화(직행 경로)');
  });

  test('showCompany 훅 부재 → 폴백: A 슬롯 주입 + onSearchInput 발화 + go("search")', () => {
    const state = createInitialState();
    state.REF = { companies: [], company_types: [], benefit_presets: {} };
    const calls = [];
    mountUI(state, { go: (s) => calls.push(s) });
    const form = document.querySelector('.gnb-search');
    form.querySelector('input[type="search"]').value = '삼성';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    assert.equal(document.getElementById('search-input-a').value, '삼성', 'A 슬롯 검색창에 주입');
    assert.equal(state.ui.searchState.a, 'loading', 'onSearchInput 경로 발화');
    assert.ok(calls.includes('search'), '검색 뷰로 전환');
  });

  test('빈 검색어 제출 → 무해(no-op)', () => {
    const state = createInitialState();
    const shown = [];
    mountUI(state, { showCompany: (t) => shown.push(t) });
    const form = document.querySelector('.gnb-search');
    form.querySelector('input[type="search"]').value = '   ';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    assert.deepEqual(shown, []);
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

  // ── 유령 리포트(2026-07-20): "새 비교"가 상태만 비우고 렌더된 DOM을 남기면,
  // 뒤로가기로 돌아왔을 때 초기화된 상태와 무관한 옛 리포트가 그대로 보인다.
  // 빈 화면(B-1)보다 위험한 **오정보**다 — 실제 회사명·숫자가 든 완전한 리포트라
  // 사용자가 현재 비교로 오인한다.
  test('UI-5c: btn-new-search → 렌더된 DOM(리포트·입력 컨트롤)까지 비운다', () => {
    const state = stateWithMatches();
    state.salS.a = { low: 5000, high: 5000 };
    state.selectedRate = 10;
    state.cmtS = { a: 30, b: 45 };
    // 리포트·입력 뷰를 실제로 렌더해 둔다(비교를 마친 사용자 상태).
    renderInputView(state, {});
    document.getElementById('report-body').append(document.createElement('div'));
    assert.ok(document.getElementById('report-body').children.length > 0, '사전조건: 리포트 렌더됨');
    assert.ok(document.getElementById('input-slot-a').children.length > 0, '사전조건: 입력 컨트롤 렌더됨');

    bindReportNav(state, { go: () => {} });
    document.getElementById('btn-new-search').dispatchEvent(new window.Event('click', { bubbles: true }));

    assert.equal(document.getElementById('report-body').children.length, 0, '리포트 본문 비움');
    assert.equal(document.getElementById('input-slot-a').children.length, 0, 'A 입력 컨트롤 비움');
    assert.equal(document.getElementById('input-slot-b').children.length, 0, 'B 입력 컨트롤 비움');
    assert.equal(document.getElementById('priority-picker').children.length, 0, '우선순위 피커 비움');
    // 눈에 안 보이는 잔존 입력도 함께 초기화되어야 "새 비교"라는 이름에 부합한다.
    assert.deepEqual(state.cmtS, { a: null, b: null }, '통근시간 초기화');
  });
});

describe('UI-7 결측 안내(#3) — 필수값 비면 리포트 이동 차단', () => {
  beforeEach(() => loadShell());

  test('runReport ok:false → go 미호출 + input-missing-alert(role=alert) 노출·값 특정', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    let went = null, ads = 0;
    bindInputView(state, {
      runReport: () => ({ ok: false, missing: ['salary', 'raise'] }),
      go: (v) => { went = v; },
      mountAds: () => { ads += 1; },
    });
    document.getElementById('btn-compare').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(went, null, '리포트 이동 차단');
    assert.equal(ads, 0, '광고 마운트도 안 함');
    const box = document.getElementById('input-missing-alert');
    assert.ok(box, '결측 안내 박스 생성');
    assert.equal(box.getAttribute('role'), 'alert');
    assert.equal(box.hidden, false);
    assert.ok(box.textContent.includes('현재 연봉'), '어느 슬롯의 어느 값이 비었는지 특정(A 연봉)');
    assert.ok(box.textContent.includes('상승률'), 'B 상승률도 안내');
  });

  test('결측 해소 후 재클릭 → 이동 허용 + 안내 숨김', () => {
    const state = stateWithMatches();
    renderInputView(state, {});
    let okReport = false, went = null;
    bindInputView(state, {
      runReport: () => (okReport ? { ok: true } : { ok: false, missing: ['salary'] }),
      go: (v) => { went = v; },
      mountAds: () => {},
    });
    const btn = document.getElementById('btn-compare');
    btn.dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(went, null);
    okReport = true;
    btn.dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(went, 'report');
    assert.equal(document.getElementById('input-missing-alert').hidden, true, '결측 해소 시 안내 숨김');
  });

  test('missingMessage: 결측 코드 → 한국어 필드 안내(pure)', () => {
    assert.ok(missingMessage(['salary']).includes('현재 연봉'));
    assert.ok(missingMessage(['raise']).includes('상승률'));
    assert.ok(missingMessage([]).length > 0);
  });
});

describe('UI-8 부트 실패 오류 UI + 재시도(#10)', () => {
  test('#boot-error는 #app(hidden) 밖에 위치(조상 hidden 무관하게 가시화 가능)', () => {
    loadShell();
    const box = document.getElementById('boot-error');
    const app = document.getElementById('app');
    assert.ok(box && app);
    assert.equal(app.contains(box), false, '#boot-error가 #app 밖에 있어야 부팅 실패 시 실제로 보인다');
  });

  test('부트 실패 → boot-error 가시 + 재시도 클릭 시 재부팅(loadReference 재호출)', async () => {
    loadShell();
    let calls = 0;
    const failing = async () => { calls += 1; throw new Error('net'); };
    await boot({ loadReferenceFn: failing, mountAdsFn: () => {}, initConsentBannerFn: () => {} });
    const box = document.getElementById('boot-error');
    assert.equal(box.hidden, false, '오류 박스 가시');
    assert.equal(calls, 1);
    document.getElementById('btn-boot-retry').dispatchEvent(new window.Event('click', { bubbles: true }));
    await new Promise((r) => setTimeout(r, 0));
    assert.equal(calls, 2, '재시도 버튼 → 재부팅');
  });
});

// ── UI-9 해시 딥링크 강등·부팅 자동 복원(B-1) — 실 DOM에서 "빈 화면 아님"을 단언 ──────────
// app.test.js의 FakeEl 스텁에는 #report-body·#input-slot-* 가 없어 "실제로 채워졌는가"를
// 원리적으로 검증할 수 없다. 이 층이 그 유일한 자동 수단이다.
describe('UI-9 해시 딥링크 강등·부팅 자동 복원(B-1)', () => {
  const REF = {
    company_types: [
      { comp_tp_cd: 'large', growth_rate_val: 0.04, stability_score_no: 90 },
      { comp_tp_cd: 'startup', growth_rate_val: 0.1, stability_score_no: 40 },
    ],
    benefit_presets: {},
    companies: [fixtureCompany(1, 'A사'), fixtureCompany(2, 'B사')],
  };
  const hooks = { loadReferenceFn: async () => REF, mountAdsFn: () => {}, initConsentBannerFn: () => {} };

  function loadShellWithStorage(url) {
    const dom = loadShell(url);
    // loadShell은 localStorage를 넘기지 않는다 — 대입하지 않으면 store.get이 항상 null이라
    // recent.list()가 늘 []가 되어 복원 경로가 통째로 검증되지 않는다(조용한 무효 테스트).
    globalThis.localStorage = dom.window.localStorage;
    globalThis.localStorage.clear();
    // App.state는 모듈 전역이라 테스트 간에 살아남는다. 리셋하지 않으면 앞 테스트가 채운
    // matched가 남아 mountUI가 입력 뷰를 렌더해 버려, 새 페이지 로드와 다른 배선이 된다.
    App.state = createInitialState();
    return dom;
  }

  async function seedRecordViaCompare() {
    // 실제 비교를 끝까지 수행해 레코드를 심는다(목 레코드가 아니라 프로덕션 저장 경로).
    const s = stateWithMatches();
    s.salS.a = { low: 5000, high: 5000 };
    s.selectedRate = 10;
    const { runReport } = await import('./app.js');
    // 분리된 노드에 렌더한다: 새 페이지 로드는 #report-body가 비어 있는 상태이므로,
    // 여기서 셸의 #report-body를 채우면 hasRenderedReport()가 true가 되어 복원 경로가
    // 통째로 건너뛰어진다(= 조용히 무효한 테스트). 프로덕션 배선과 일치시킨다.
    runReport({ state: s, mountEl: document.createElement('div') });
  }

  test('UI-9a: #report 무상태 진입 → 검색 뷰(빈 리포트 노출 안 함)', async () => {
    loadShellWithStorage('https://loupit.example/compare/#report');
    await boot(hooks);
    assert.equal(document.getElementById('view-search').hidden, false, '검색 뷰가 보인다');
    assert.equal(document.getElementById('view-report').hidden, true, '리포트 뷰는 숨김');
  });

  test('UI-9b: #company 무상태 진입 → 검색 뷰(백지 노출 안 함)', async () => {
    loadShellWithStorage('https://loupit.example/compare/#company');
    await boot(hooks);
    assert.equal(document.getElementById('view-search').hidden, false);
    assert.equal(document.getElementById('view-company').hidden, true);
  });

  test('UI-9c: #report + 레코드 → 복원되고 #report-body가 실제로 채워진다', async () => {
    loadShellWithStorage('https://loupit.example/compare/#report');
    await seedRecordViaCompare();
    await boot(hooks);
    assert.equal(document.getElementById('view-report').hidden, false, '리포트 뷰 표시');
    assert.ok(
      document.getElementById('report-body').children.length > 0,
      '#report-body가 비어 있으면 B-1이 재발한 것이다',
    );
  });

  test('UI-9d: 복원 후 "입력 수정" → 입력 뷰가 채워져 있다(빈 입력 뷰 금지)', async () => {
    loadShellWithStorage('https://loupit.example/compare/#report');
    await seedRecordViaCompare();
    await boot(hooks);
    document.getElementById('btn-edit-input').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(document.getElementById('view-input').hidden, false, '입력 뷰 표시');
    // mountUI는 마운트 시점에 슬롯이 없으면 입력 뷰를 렌더하지 않는다(ui.js). 복원이 그 뒤에
    // 상태만 채우면 컨트롤이 비어 B-1과 동일한 백지가 한 클릭 거리에 남는다.
    assert.ok(document.getElementById('input-slot-a').children.length > 0, 'A 슬롯 컨트롤 렌더');
    assert.ok(document.getElementById('input-slot-b').children.length > 0, 'B 슬롯 컨트롤 렌더');
    assert.ok(document.getElementById('priority-picker').children.length > 0, '우선순위 피커 렌더');
  });

  test('UI-9e: 부팅 자동 복원은 레코드를 재저장하지 않는다(id·순서 불변)', async () => {
    const dom = loadShellWithStorage('https://loupit.example/compare/#report');
    await seedRecordViaCompare();
    const before = dom.window.localStorage.getItem('loupit.recentComparisons');
    await boot(hooks);
    const after = dom.window.localStorage.getItem('loupit.recentComparisons');
    assert.equal(after, before, '새로고침만으로 "최근 비교" 봉투가 바뀌면 목록 순서·id가 요동친다');
  });
});
