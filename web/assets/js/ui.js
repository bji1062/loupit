// web/assets/js/ui.js — SPA DOM 배선·입력뷰 렌더 (SP-FE-3 "이벤트 바인딩" 구현).
//
// 배경: 순수 로직(search/inputs/calc/report)은 자동 리프로 구현·테스트됐으나, 이들을
// compare/index.html 셸의 DOM 이벤트·컨트롤에 잇는 통합 계층은 TASK/06(§미배선 항목)에서
// "후속 통합 과제"로 미뤄져 `bindGlobalUI()`가 자리표시자로 남아 있었다(비교툴 비인터랙티브).
// 본 모듈이 그 통합을 구현한다: 검색입력→onSearchInput, 후보클릭→selectCompany(search.js가
// 자체 배선), 선택→입력뷰 전진, 입력뷰 컨트롤 렌더·상태배선, 비교하기→runReport, 리포트 내비.
//
// 경계: 상태(App.state)는 app.js 단일 소유(인자로 주입받음). 순수 계산·렌더는 재구현하지 않고
// 호출·마운트만 한다(SP-FE-9.2). app.js가 boot()에서 mountUI(App.state, deps)를 호출한다.
import { el } from './dom.js';
import { onSearchInput, selectCompany, clearSlot } from './search.js';

export const PRIORITIES = ['연봉', '워라밸', '복지', '브랜드'];
const OT_OPTS = [['', '야근 빈도'], ['low', '거의 없음'], ['mid', '보통'], ['high', '잦음']];
const WAGE_OPTS = [['', '임금 형태'], ['inclusive', '포괄임금'], ['separate', '비포괄(야근수당 별도)']];

function byId(id) {
  return (typeof document !== 'undefined' && typeof document.getElementById === 'function') ? document.getElementById(id) : null;
}
function qs(sel) {
  return (typeof document !== 'undefined' && typeof document.querySelector === 'function') ? document.querySelector(sel) : null;
}

// ── 반영 헬퍼(상태 → DOM) ──────────────────────────────────────────────────
export function reflectSlotLabel(slot, name) {
  const input = byId('search-input-' + slot);
  if (input) input.value = name || '';
}

export function clearCandidatesDom(slot) {
  const list = byId('cand-' + slot);
  if (list) list.replaceChildren();
}

// 검색 상태(state.ui.searchState[slot]) → 셸의 empty/error 메시지 토글(FR-13 무결과 vs 오류)
export function reflectSearchUI(state, slot) {
  const st = state.ui.searchState[slot];
  const empty = qs('.search-empty[data-slot="' + slot + '"]');
  const error = qs('.search-error[data-slot="' + slot + '"]');
  if (empty) empty.hidden = (st !== 'empty');
  if (error) error.hidden = (st !== 'error');
  if (st === 'empty' || st === 'idle') clearCandidatesDom(slot);
}

function notify(msg) {
  let box = byId('ui-notify');
  if (!box && typeof document !== 'undefined') {
    const app = byId('app');
    box = el('p', { id: 'ui-notify', role: 'alert', class: 'ui-notify' });
    if (app && app.prepend) app.prepend(box); else if (app) app.appendChild(box);
  }
  if (box) box.textContent = msg || '';
}

// ── 검색 뷰 hooks(onSearchInput→runSearch→renderCandidates→selectCompany 로 흐름) ──
export function searchHooks(state, deps) {
  return {
    reflectSlotLabel,
    closeCandidates: (slot) => { clearCandidatesDom(slot); reflectSearchUI(state, slot); },
    notify,
    showSlotError: (slot) => reflectSearchUI(state, slot),
    onRendered: () => {},
    maybeAdvance: () => maybeAdvance(state, deps),
  };
}

// 양 슬롯 모두 채워지면 입력 뷰로 전진(회사 검색 기본 경로). 한쪽만이면 검색 뷰 유지.
export function maybeAdvance(state, deps) {
  if (state.matched.a && state.matched.b) {
    renderInputView(state, deps);
    if (typeof deps.go === 'function') deps.go('input');
  }
}

// ── 검색 뷰 배선 ────────────────────────────────────────────────────────────
export function bindSearchView(state, deps) {
  if (typeof document === 'undefined') return;
  const hooks = searchHooks(state, deps);
  for (const slot of ['a', 'b']) {
    const input = byId('search-input-' + slot);
    if (input) {
      input.addEventListener('input', (e) => {
        onSearchInput(state, slot, e.target.value, hooks);
        reflectSearchUI(state, slot);
      });
    }
    const retry = qs('[data-retry="' + slot + '"]');
    if (retry) {
      retry.addEventListener('click', () => {
        const val = input ? input.value : '';
        onSearchInput(state, slot, val, hooks);
        reflectSearchUI(state, slot);
      });
    }
  }
}

// ── 입력 뷰 컨트롤 렌더(빈 #input-slot-a/b·#priority-picker 채움) ──────────────
function benefitCheckboxes(state, slot) {
  const wrap = el('fieldset', { class: 'in-benefits' });
  wrap.append(el('legend', { text: '복지 항목' }));
  const items = state.benS[slot] || [];
  items.forEach((b, i) => {
    const id = 'ben-' + slot + '-' + i;
    const row = el('label', { class: 'in-ben-row', for: id });
    const cb = el('input', { type: 'checkbox', id });
    cb.checked = !!b.checked;
    cb.addEventListener('change', () => { state.benS[slot][i].checked = cb.checked; });
    row.append(cb);
    row.append(el('span', { text: b.benefit_nm + (b.benefit_amt != null ? ' (' + b.benefit_amt + '만원)' : '') }));
    wrap.append(row);
  });
  if (!items.length) wrap.append(el('p', { class: 'in-ben-empty', text: '복지 항목 없음' }));
  return wrap;
}

function workStyleControls(state, slot) {
  const wrap = el('fieldset', { class: 'in-ws' });
  wrap.append(el('legend', { text: '근무 형태' }));
  const ws = state.wsState[slot] || {};
  // 야근 빈도
  const otSel = el('select', { 'aria-label': '야근 빈도(' + slot + ')' });
  OT_OPTS.forEach(([v, t]) => { const o = el('option', { value: v, text: t }); if (ws.ot === v || (ws.ot == null && v === '')) o.selected = true; otSel.append(o); });
  otSel.addEventListener('change', () => { state.wsState[slot].ot = otSel.value || null; });
  wrap.append(otSel);
  // 임금 형태
  const wageSel = el('select', { 'aria-label': '임금 형태(' + slot + ')' });
  WAGE_OPTS.forEach(([v, t]) => { const o = el('option', { value: v, text: t }); if (ws.wage === v || (ws.wage == null && v === '')) o.selected = true; wageSel.append(o); });
  wageSel.addEventListener('change', () => { state.wsState[slot].wage = wageSel.value || null; });
  wrap.append(wageSel);
  // 재택·유연근무(회사 제안값 초기 반영)
  for (const key of ['remote', 'flex']) {
    const id = 'ws-' + key + '-' + slot;
    const row = el('label', { class: 'in-ws-row', for: id });
    const cb = el('input', { type: 'checkbox', id });
    cb.checked = !!ws[key];
    cb.addEventListener('change', () => { state.wsState[slot][key] = cb.checked; });
    row.append(cb);
    row.append(el('span', { text: key === 'remote' ? '재택근무' : '유연근무' }));
    wrap.append(row);
  }
  return wrap;
}

function commuteInput(state, slot) {
  const id = 'cmt-' + slot;
  const wrap = el('div', { class: 'in-commute' });
  wrap.append(el('label', { for: id, text: '편도 통근시간(분)' }));
  const inp = el('input', { type: 'number', id, min: '0', step: '5' });
  if (state.cmtS[slot] != null) inp.value = String(state.cmtS[slot]);
  inp.addEventListener('input', () => { const n = Number(inp.value); state.cmtS[slot] = inp.value.trim() === '' || !Number.isFinite(n) ? null : n; });
  wrap.append(inp);
  return wrap;
}

function salaryControls(state) {
  // 슬롯 a: 현재 연봉 범위(만원). 필수(compare가 salary 결측 판정).
  const wrap = el('fieldset', { class: 'in-salary' });
  wrap.append(el('legend', { text: '현재 연봉(만원)' }));
  const cur = state.salS.a || { low: null, high: null };
  const low = el('input', { type: 'number', id: 'sal-low', min: '0', step: '100', placeholder: '최소', 'aria-label': '연봉 최소(만원)' });
  const high = el('input', { type: 'number', id: 'sal-high', min: '0', step: '100', placeholder: '최대', 'aria-label': '연봉 최대(만원)' });
  if (cur.low != null) low.value = String(cur.low);
  if (cur.high != null) high.value = String(cur.high);
  const upd = () => {
    state.salS.a = {
      low: low.value.trim() === '' ? null : Number(low.value),
      high: high.value.trim() === '' ? null : Number(high.value),
    };
  };
  low.addEventListener('input', upd);
  high.addEventListener('input', upd);
  wrap.append(low, el('span', { text: ' ~ ' }), high);
  return wrap;
}

function rateControl(state) {
  // 슬롯 b: 이직 후보 상승률(%). b 연봉은 a에서 파생(deriveOfferRange).
  const wrap = el('div', { class: 'in-rate' });
  wrap.append(el('label', { for: 'offer-rate', text: '이직 후보 연봉 상승률(%)' }));
  const inp = el('input', { type: 'number', id: 'offer-rate', step: '1', placeholder: '예: 10' });
  if (state.selectedRate != null) inp.value = String(state.selectedRate);
  inp.addEventListener('input', () => { state.selectedRate = inp.value.trim() === '' ? null : Number(inp.value); });
  wrap.append(inp);
  return wrap;
}

function slotHeader(state, slot) {
  const m = state.matched[slot];
  const label = slot === 'a' ? '현재 직장(A)' : '이직 후보(B)';
  return el('h3', { class: 'in-slot-title', text: label + ' — ' + (m ? m.comp_nm : '직접 입력') });
}

export function renderInputSlot(state, slot) {
  const host = byId('input-slot-' + slot);
  if (!host) return;
  host.replaceChildren();
  host.append(slotHeader(state, slot));
  if (slot === 'a') host.append(salaryControls(state)); else host.append(rateControl(state));
  host.append(benefitCheckboxes(state, slot));
  host.append(workStyleControls(state, slot));
  host.append(commuteInput(state, slot));
}

export function renderPriorityPicker(state) {
  const host = byId('priority-picker');
  if (!host) return;
  host.replaceChildren();
  const fs = el('fieldset', {});
  fs.append(el('legend', { text: '가장 중요한 것' }));
  PRIORITIES.forEach((p) => {
    const id = 'pri-' + p;
    const row = el('label', { class: 'pri-row', for: id });
    const rb = el('input', { type: 'radio', name: 'priority', id, value: p });
    rb.checked = (state.curPri === p);
    rb.addEventListener('change', () => { if (rb.checked) state.curPri = p; });
    row.append(rb);
    row.append(el('span', { text: p }));
    fs.append(row);
  });
  host.append(fs);
}

export function renderInputView(state, deps) {
  renderInputSlot(state, 'a');
  renderInputSlot(state, 'b');
  renderPriorityPicker(state);
}

// ── 입력 뷰 배선(비교하기) ───────────────────────────────────────────────────
export function bindInputView(state, deps) {
  const btn = byId('btn-compare');
  if (btn) {
    btn.addEventListener('click', () => {
      if (typeof deps.runReport === 'function') deps.runReport({ state, mountEl: byId('report-body') });
      if (typeof deps.go === 'function') deps.go('report');
      if (typeof deps.mountAds === 'function') { try { deps.mountAds('result'); } catch { /* 광고 실패 무손상(MON6) */ } }
    });
  }
}

// ── 리포트 뷰 배선(입력 수정·새 비교) ───────────────────────────────────────
export function bindReportNav(state, deps) {
  const edit = byId('btn-edit-input');
  if (edit) edit.addEventListener('click', () => { if (typeof deps.go === 'function') deps.go('input'); });
  const fresh = byId('btn-new-search');
  if (fresh) fresh.addEventListener('click', () => {
    for (const slot of ['a', 'b']) { clearSlot(state, slot, reflectSlotLabel); clearCandidatesDom(slot); }
    state.salS = { a: { low: null, high: null } };
    state.selectedRate = null;
    if (typeof deps.go === 'function') deps.go('search');
  });
}

// ── GNB 헤더 검색(나무위키식 상단 바) — 제출 → A 슬롯 주입·검색 뷰 전환 ────────
export function bindHeaderSearch(state, deps) {
  const form = qs('.gnb-search');
  if (!form) return;
  form.addEventListener('submit', (e) => {
    if (e && typeof e.preventDefault === 'function') e.preventDefault(); // 페이지 리로드 방지
    const q = form.querySelector('input[type="search"]');
    const target = byId('search-input-a');
    if (!q || !target) return;
    const term = String(q.value || '').trim();
    if (!term) return; // 빈 검색어 → 무해 no-op
    if (typeof deps.go === 'function') deps.go('search'); // 입력/리포트 뷰에 있어도 검색 뷰로
    target.value = term;
    // 대상 문서의 Event 생성자 사용(jsdom 포함) — 기존 검색 배선(onSearchInput) 재사용
    const win = (target.ownerDocument && target.ownerDocument.defaultView)
      || (typeof window !== 'undefined' ? window : null);
    const EventCtor = (win && typeof win.Event === 'function') ? win.Event
      : (typeof Event === 'function' ? Event : null);
    if (EventCtor) target.dispatchEvent(new EventCtor('input', { bubbles: true }));
    if (typeof target.focus === 'function') target.focus();
    if (typeof target.scrollIntoView === 'function') target.scrollIntoView({ block: 'center' });
  });
}

// ── 부팅 재시도 ──────────────────────────────────────────────────────────────
export function bindBootRetry(state, deps) {
  const btn = byId('btn-boot-retry');
  if (btn && typeof deps.reboot === 'function') btn.addEventListener('click', () => deps.reboot());
}

// ── 진입점 ───────────────────────────────────────────────────────────────────
export function mountUI(state, deps = {}) {
  // 검색 상태 변화를 셸 메시지에 반영(setSearchState 단일 지점이 호출).
  if (state.ui) state.ui.onSearchState = (slot) => reflectSearchUI(state, slot);
  bindSearchView(state, deps);
  bindInputView(state, deps);
  bindReportNav(state, deps);
  bindBootRetry(state, deps);
  bindHeaderSearch(state, deps);
  // 프리필로 이미 양 슬롯이 채워졌다면 입력 뷰 컨트롤을 렌더한다.
  if (state.matched && (state.matched.a || state.matched.b)) renderInputView(state, deps);
}
