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

export const PRIORITIES = ['연봉', '워라밸', '복지'];
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

// 슬롯 검색 입력칸으로 커서를 옮긴다(+ 화면 가운데로 스크롤). "다음에 할 일은 여기"를
// 손가락으로 가리키는 장치 — 프리필이 한 슬롯만 채웠을 때·"회사 선택" 버튼을 눌렀을 때 쓴다.
// scrollIntoView 는 jsdom 에 없을 수 있어 존재 확인 후 호출한다(테스트 무손상).
export function focusSlotInput(slot) {
  const input = byId('search-input-' + slot);
  if (!input) return null;
  if (typeof input.focus === 'function') input.focus();
  if (typeof input.scrollIntoView === 'function') input.scrollIntoView({ block: 'center' });
  return input;
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
// deps.onPairReady: 두 회사가 확정된 시점 훅(app.js가 익명 쌍 로그를 건다, 2026-07-31).
// 여기가 문턱인 이유 — 이전에는 "비교하기 성공"에서만 기록해 연봉·상승률까지 다 채운
// 사용자만 집계에 잡혔고, 그 결과 11일간 집계가 0건이 됐다. 회사 둘을 고른 것 자체가
// 이미 관심 신호다. 훅이 없으면(구 호출부·위젯 클릭) 아무 일도 하지 않는다.
export function maybeAdvance(state, deps) {
  if (state.matched.a && state.matched.b) {
    renderInputView(state, deps);
    if (typeof deps.go === 'function') deps.go('input');
    if (typeof deps.onPairReady === 'function') {
      try { deps.onPairReady(state); } catch { /* 로그 실패는 비교 흐름에 무해 */ }
    }
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
  // 야근 빈도 — 첫 옵션은 안내용 placeholder(선택 불가): disabled+hidden으로 재선택 방지
  const otSel = el('select', { 'aria-label': '야근 빈도(' + slot + ')' });
  OT_OPTS.forEach(([v, t]) => { const o = el('option', { value: v, text: t }); if (v === '') { o.disabled = true; o.hidden = true; } if (ws.ot === v || (ws.ot == null && v === '')) o.selected = true; otSel.append(o); });
  otSel.addEventListener('change', () => { state.wsState[slot].ot = otSel.value || null; });
  wrap.append(otSel);
  // 임금 형태 — 첫 옵션은 안내용 placeholder(선택 불가): disabled+hidden으로 재선택 방지
  const wageSel = el('select', { 'aria-label': '임금 형태(' + slot + ')' });
  WAGE_OPTS.forEach(([v, t]) => { const o = el('option', { value: v, text: t }); if (v === '') { o.disabled = true; o.hidden = true; } if (ws.wage === v || (ws.wage == null && v === '')) o.selected = true; wageSel.append(o); });
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

// 미선택 슬롯의 머리는 예전에 "… — 직접 입력"이었다. 직접 입력 모드(setDirectType, FR-17)는
// UI 진입점이 한 번도 만들어지지 않은 죽은 모드라, 그 라벨은 사용자에게 "여기서 뭘 어떻게
// 하라는 것인지 알 수 없는" 막다른 골목이었다. 대신 **검색 뷰로 돌아가는 길**을 화면 안에 둔다
// (안전망 — 프리필은 이제 한 슬롯이면 검색 뷰에 머물지만, REF 에서 사라진 comp_id 를 담은
//  '최근 비교' 복원처럼 한 슬롯만 찬 입력 뷰가 만들어지는 경로가 남아 있다).
function slotHeader(state, slot) {
  const m = state.matched[slot];
  const label = slot === 'a' ? '현재 직장(A)' : '이직 후보(B)';
  return el('h3', { class: 'in-slot-title', text: label + ' — ' + (m ? m.comp_nm : '미선택') });
}

// 미선택 슬롯에서 검색 뷰로 돌아가는 길. 클래스 `btn` 을 함께 다는 이유: 이 저장소의 버튼
// 스타일은 styles.css(SP-DSN 소유)의 `.btn` 규칙이 정본이고, 새 규칙을 추가하지 않고
// 기존 규칙을 재사용해야 h3 의 serif 를 물려받은 이질적인 버튼이 생기지 않는다.
function slotPickButton(slot, deps = {}) {
  const btn = el('button', {
    type: 'button', class: 'in-slot-pick btn', 'data-pick-slot': slot, text: '회사 선택',
  });
  btn.addEventListener('click', () => {
    if (typeof deps.go === 'function') deps.go('search');
    focusSlotInput(slot); // 돌아간 검색 뷰에서 바로 타이핑할 수 있게
  });
  return btn;
}

export function renderInputSlot(state, slot, deps = {}) {
  const host = byId('input-slot-' + slot);
  if (!host) return;
  host.replaceChildren();
  host.append(slotHeader(state, slot));
  if (!state.matched[slot]) host.append(slotPickButton(slot, deps));
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

export function renderInputView(state, deps = {}) {
  renderInputSlot(state, 'a', deps);
  renderInputSlot(state, 'b', deps);
  renderPriorityPicker(state);
}

// ── 결측 안내(#3): 어느 슬롯의 어느 필수값이 비었는지 특정해 안내(role="alert") ──────────────
export const MISSING_LABEL = {
  salary: '현재 직장(A)의 현재 연봉',
  raise: '이직 후보(B)의 연봉 상승률',
};

// 결측 코드 배열 → 사용자 안내 문구.
export function missingMessage(missing) {
  const names = (missing || []).map((k) => MISSING_LABEL[k] || k);
  return names.length
    ? names.join(', ') + '을(를) 입력해야 비교할 수 있습니다.'
    : '필수 입력값이 비어 있습니다.';
}

function showMissingAlert(missing) {
  if (typeof document === 'undefined') return;
  let box = byId('input-missing-alert');
  if (!box) { // 셸에 없으면 비교하기 버튼 앞에 동적 생성(index/compare 공통 — JS 소유)
    box = el('p', { id: 'input-missing-alert', role: 'alert', class: 'input-missing-alert' });
    const btn = byId('btn-compare');
    if (btn && btn.parentNode && typeof btn.parentNode.insertBefore === 'function') btn.parentNode.insertBefore(box, btn);
    else { const view = byId('view-input'); if (view && view.append) view.append(box); }
  }
  box.textContent = missingMessage(missing);
  box.hidden = false;
}

function clearMissingAlert() {
  const box = byId('input-missing-alert');
  if (box) { box.textContent = ''; box.hidden = true; }
}

// ── 입력 뷰 배선(비교하기) ───────────────────────────────────────────────────
export function bindInputView(state, deps) {
  const btn = byId('btn-compare');
  if (btn) {
    btn.addEventListener('click', () => {
      const report = (typeof deps.runReport === 'function') ? deps.runReport({ state, mountEl: byId('report-body') }) : null;
      if (report && report.ok === false) { showMissingAlert(report.missing); return; } // 결측 → 리포트 이동 차단·안내(#3)
      clearMissingAlert();
      if (typeof deps.go === 'function') deps.go('report');
      if (typeof deps.mountAds === 'function') { try { deps.mountAds('result'); } catch { /* 광고 실패 무손상(MON6) */ } }
    });
  }
}

// 렌더된 뷰 콘텐츠를 비운다("새 비교" 등 상태 초기화와 짝). 상태와 DOM이 어긋나면
// 뒤로가기 시 유령 리포트가 남으므로, 상태를 비우는 쪽이 DOM도 함께 책임진다.
// 셸 컨테이너 자체는 남기고 내용만 비운다(광고 슬롯·버튼은 셸 소유, SP-ADS-9.2).
export function clearRenderedViews() {
  for (const id of ['report-body', 'input-slot-a', 'input-slot-b', 'priority-picker']) {
    const el = byId(id);
    if (el && typeof el.replaceChildren === 'function') el.replaceChildren();
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
    state.cmtS = { a: null, b: null }; // 눈에 안 보이는 잔존 입력도 초기화("새" 비교)
    // 렌더된 DOM까지 비운다. 상태만 비우면 뒤로가기로 돌아왔을 때 초기화된 상태와 무관한
    // 옛 리포트가 그대로 보인다 — 빈 화면보다 위험한 오정보다(유령 리포트, 2026-07-20).
    clearRenderedViews();
    if (typeof deps.go === 'function') deps.go('search');
  });
}

// ── GNB 헤더 검색 — 은퇴(2026-09-01) ────────────────────────────────────────
// 랜딩·비교 셸에만 `.gnb-search` 가 있어 상단이 페이지마다 달라 보였다(사용자 신고).
// 같은 기능은 본문 A/B 슬롯 검색(#search-input-a·b)에 그대로 있고, 생성 페이지·커뮤니티는
// 이 모듈을 싣지 않아 폼을 넣으면 죽은 UI 가 된다 — 그래서 폼과 배선을 함께 걷어냈다.
// 되살리려면 **모든** 헤더에 폼을 넣고 ui.js 없는 페이지의 제출 처리부터 정해라
// (generator/tests/test_header_markup.py 가 부활을 막고 있다 — 그 테스트도 함께 고칠 것).

export function bindBootRetry(state, deps) {
  const btn = byId('btn-boot-retry');
  if (!btn || typeof deps.reboot !== 'function') return;
  if (btn.dataset && btn.dataset.bootRetryBound === '1') return; // 재시도 반복 시 중복 리스너 방지(#10)
  if (btn.dataset) btn.dataset.bootRetryBound = '1';
  btn.addEventListener('click', () => deps.reboot());
}

// ── 진입점 ───────────────────────────────────────────────────────────────────
export function mountUI(state, deps = {}) {
  // 검색 상태 변화를 셸 메시지에 반영(setSearchState 단일 지점이 호출).
  if (state.ui) state.ui.onSearchState = (slot) => reflectSearchUI(state, slot);
  bindSearchView(state, deps);
  bindInputView(state, deps);
  bindReportNav(state, deps);
  bindBootRetry(state, deps);
  // 프리필·초안으로 이미 슬롯이 채워졌다면 입력 뷰 컨트롤을 렌더한다.
  // chosenType 도 보는 이유(2026-07-31): 직접 입력 모드는 matched 가 null 이라 회사 조건만
  // 보면 초안 복원 후 입력 뷰가 비어 보인다(hasSlotState 는 이미 chosenType 을 센다 — 두 판정이
  // 어긋나면 "상태는 있는데 화면은 빈" 상태가 된다).
  const hasSlot = state.matched && (state.matched.a || state.matched.b);
  const hasType = state.chosenType && (state.chosenType.a || state.chosenType.b);
  if (hasSlot || hasType) renderInputView(state, deps);
}
