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
import { pairTarget } from './benefits.js'; // 두 슬롯이 찼을 때의 목적지(SP-CMP-2) — 집은 하나다
import { onSearchInput, selectCompany, clearSlot } from './search.js';
import { tenureItems } from './calc.js'; // 근속 조건 항목 수(입력 보조문) — 순수 함수, 결과 화면과 같은 판정


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

// ── 프리필 안내(검색 뷰) ──────────────────────────────────────────────────
// 한 슬롯 프리필은 이제 검색 뷰에 머문다. 시각 사용자는 A 칸에 든 회사명과 B 칸의 포커스 링을
// 한 화면에서 같이 보지만, 스크린리더 사용자는 부팅 포커스가 곧장 B 텍스트박스에 떨어져
// "이직 후보(B), 회사명 검색, 편집창"만 듣는다 — **A 가 이미 채워졌다는 사실**을 알려면 위로
// 한 항목 되돌아가야 한다. 그래서 안내문을 하나 만들고 **포커스가 갈 입력칸의 설명**으로 묶는다.
// aria-describedby 로 묶는 이유: 갓 만든 live 영역에 같은 틱에 텍스트를 넣으면 낭독을 놓치는
// 리더가 있다. 포커스 시 label + description 은 확실히 읽힌다(role=status 는 보조 수단).
const PREFILL_NOTE_ID = 'search-prefill-note';
const SLOT_LABEL = { a: '현재 직장(A)', b: '이직 후보(B)' };
const SLOT_TOPIC = { a: '현재 직장(A)은', b: '이직 후보(B)는' };

// aria-describedby 는 **공백으로 구분한 id 목록**이다. 프리필 안내와 「비교하기」 거부 안내가 한 칸에 같이
// 걸릴 수 있어(2026-09-13), 통째로 덮거나 지우면 다른 쪽 설명이 조용히 끊긴다 — 토큰 단위로만 더하고 뺀다.
export function addDescribedBy(input, id) {
  if (!input || typeof input.getAttribute !== 'function' || typeof input.setAttribute !== 'function') return;
  const ids = (input.getAttribute('aria-describedby') || '').split(/\s+/).filter(Boolean);
  if (!ids.includes(id)) ids.push(id);
  input.setAttribute('aria-describedby', ids.join(' '));
}
export function removeDescribedBy(input, id) {
  if (!input || typeof input.getAttribute !== 'function' || typeof input.removeAttribute !== 'function') return;
  const ids = (input.getAttribute('aria-describedby') || '').split(/\s+/).filter((t) => t && t !== id);
  if (ids.length) input.setAttribute('aria-describedby', ids.join(' '));
  else input.removeAttribute('aria-describedby');
}

export function clearPrefillNote() {
  const note = byId(PREFILL_NOTE_ID);
  if (note && note.remove) note.remove();
  for (const slot of ['a', 'b']) removeDescribedBy(byId('search-input-' + slot), PREFILL_NOTE_ID);
}

// filled: 이미 정해진 슬롯, pending: 사용자가 이제 골라야 할 슬롯.
export function notePrefill(filled, name, pending) {
  clearPrefillNote();
  const view = byId('view-search');
  const input = byId('search-input-' + pending);
  if (!view || !input) return null;
  const note = el('p', {
    id: PREFILL_NOTE_ID, class: 'search-prefill-note', role: 'status',
    text: SLOT_TOPIC[filled] + ' 이미 정해졌습니다(' + (name || '') + '). '
      + SLOT_LABEL[pending] + ' 회사를 골라 주세요.',
  });
  const h2 = view.querySelector ? view.querySelector('h2') : null;
  if (h2 && h2.after) h2.after(note); else view.prepend(note);
  addDescribedBy(input, PREFILL_NOTE_ID);
  // 사용자가 타이핑을 시작하면 안내는 제 역할을 다했다. 남겨 두면 A 를 바꾸는 순간 거짓이 된다.
  for (const slot of ['a', 'b']) {
    const box = byId('search-input-' + slot);
    if (box && box.addEventListener) box.addEventListener('input', clearPrefillNote, { once: true });
  }
  return note;
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

// 양 슬롯 모두 채워지면 전진(회사 검색 기본 경로). 한쪽만이면 검색 뷰 유지.
// 🚩 목적지는 **pairTarget(state) 하나**가 정한다(SP-CMP-2). 2026-09-12: input → benefits,
// 2026-09-13: 흐름(state.ui.mode)이 계산기면 input — 이직 계산기로 들어온 사람은 복지 비교를 거치지 않는다.
// 부팅 폴백과 여기가 따로 적으면 "주소로 들어오면 비교, 검색으로 고르면 입력"처럼 경로마다
// 다른 화면이 뜬다 — 버그가 아니라 설계가 둘인 상태라 고치기 어렵다.
// 입력 뷰는 **그래도 미리 그린다**: 덱의 「이직 계산기 →」가 그 화면을 바로 연다.
// deps.onPairReady: 두 회사가 확정된 시점 훅(app.js가 익명 쌍 로그를 건다, 2026-07-31).
// 여기가 문턱인 이유 — 이전에는 "비교하기 성공"에서만 기록해 연봉·상승률까지 다 채운
// 사용자만 집계에 잡혔고, 그 결과 11일간 집계가 0건이 됐다. 회사 둘을 고른 것 자체가
// 이미 관심 신호다. 훅이 없으면(구 호출부·위젯 클릭) 아무 일도 하지 않는다.
export function maybeAdvance(state, deps) {
  if (state.matched.a && state.matched.b) {
    // 「비교하기」 거부 안내는 **어느 경로로 전진하든** 여기서 수명이 끝난다. 목록 선택(selectCompany)은
    // input 이벤트 없이 값을 넣어 「타이핑하면 지운다」를 비껴가므로, 지우는 곳이 여기가 아니면
    // 「회사 바꾸기」로 돌아왔을 때 두 칸이 찬 화면에 「골라 주세요」가 남는다(적대 검증 MED, 재현됨).
    clearSearchGoHint();
    renderInputView(state, deps);
    if (typeof deps.go === 'function') deps.go(pairTarget(state));
    if (typeof deps.onPairReady === 'function') {
      try { deps.onPairReady(state); } catch { /* 로그 실패는 비교 흐름에 무해 */ }
    }
  }
}

// ── 검색 뷰 「비교하기」(2026-09-13 사용자 요청) ──────────────────────────────
// 목록에서 두 번째 회사를 고르면 곧바로 전진한다(maybeAdvance). 그런데 **두 칸이 이미 찬 채로** 검색 뷰에
// 서는 경로가 있다 — 복지 비교의 「회사 바꾸기」로 왔다가 안 바꾸기로 한 경우, 새로고침으로 초안이 두 칸을
// 되살린 경우. 그 화면에는 넘어갈 버튼이 없어 막다른 골목이었다(라이브 재현).
// 전진은 **maybeAdvance 한 경로**로만 한다 — 목적지(pairTarget)·입력 뷰 선렌더·쌍 로그가 선택 경로와
// 같아야 「고르면 가는 곳」과 「눌러서 가는 곳」이 갈리지 않는다.
const GO_HINT_ID = 'search-go-hint';

// 슬롯이 **확정**됐는가 = 회사가 골라져 있고, 입력칸에 보이는 글자가 그 회사명이다.
// 글자를 지우거나 고쳐도 matched 는 남는다(onSearchInput 은 선택을 풀지 않는다) — 글자를 보지 않으면
// 빈 칸이 보이는데 옛 회사로 넘어가는 화면이 된다.
export function slotConfirmed(state, slot) {
  const m = state.matched && state.matched[slot];
  if (!m) return false;
  const input = byId('search-input-' + slot);
  if (!input) return true; // 셸 밖(구 호출부) — 상태만으로 판정
  return String(input.value || '').trim() === String(m.comp_nm || '').trim();
}

export function clearSearchGoHint() {
  const hint = byId(GO_HINT_ID);
  if (hint) hint.textContent = '';
  for (const slot of ['a', 'b']) removeDescribedBy(byId('search-input-' + slot), GO_HINT_ID);
}

// 두 칸이 확정이면 전진, 아니면 이동하지 않고 **첫 미확정 칸**으로 커서를 옮겨 무엇이 모자란지 말한다.
export function searchGo(state, deps = {}) {
  const missing = ['a', 'b'].filter((slot) => !slotConfirmed(state, slot));
  if (missing.length) {
    const target = missing[0];
    const hint = byId(GO_HINT_ID);
    if (hint) {
      hint.textContent = missing.length === 2
        ? '비교할 회사 두 곳을 목록에서 골라 주세요.'
        : SLOT_LABEL[target] + ' 회사를 목록에서 골라 주세요.';
      // 포커스 **전에** 그 칸의 설명으로 묶는다 — notePrefill 과 같은 이유다. 같은 틱의 live 갱신은 포커스
      // 낭독과 경합해 탈락하는 리더가 있고, label + description 은 포커스 순간 확실히 읽힌다.
      for (const slot of ['a', 'b']) {
        const box = byId('search-input-' + slot);
        if (slot === target) addDescribedBy(box, GO_HINT_ID); else removeDescribedBy(box, GO_HINT_ID);
      }
    }
    focusSlotInput(target);
    return false;
  }
  maybeAdvance(state, deps); // 안내 정리는 maybeAdvance 가 한다(전진 경로 공통)
  return true;
}

// ── 검색 뷰 배선 ────────────────────────────────────────────────────────────
export function bindSearchView(state, deps) {
  if (typeof document === 'undefined') return;
  const hooks = searchHooks(state, deps);
  for (const slot of ['a', 'b']) {
    const input = byId('search-input-' + slot);
    if (input) {
      input.addEventListener('input', (e) => {
        clearSearchGoHint(); // 고치기 시작했으면 안내는 제 역할을 다했다
        onSearchInput(state, slot, e.target.value, hooks);
        reflectSearchUI(state, slot);
      });
      // Enter = 「비교하기」(적대 검증 LOW): <form> 이 아니라 submit 이 없어 키보드 사용자는 버튼까지 탭해야 했다.
      // ⚠ 한글 조합을 끝내는 Enter 는 무시한다(isComposing · keyCode 229) — 「카카오」를 치고 Enter 로 조합을
      //   확정하는 순간 거부 안내가 튀어나오거나 화면이 넘어가면 입력이 끊긴다.
      input.addEventListener('keydown', (e) => {
        if (e.key !== 'Enter' || e.isComposing || e.keyCode === 229) return;
        searchGo(state, deps);
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
  const goBtn = byId('btn-search-go');
  if (goBtn) goBtn.addEventListener('click', () => searchGo(state, deps));
}

// ── 입력 뷰(이직 계산기 개편 2026-09-23 — SPEC 06 §SP-FE-14) ─────────────────────
// 승인 목업(calc-mockup-fable v2) 그대로: 맨 위 「어떤 기준으로 볼까요?」 → A·B 칸이 **한 줄씩 맞는** 두 열
// (현재 연봉 | 연봉 상승률 → 야근 → 야근수당 → 회사 등록 정보 → 통근 → 근속) → 고정된 「비교 결과 보기」.
// 복지 체크박스 39개는 없앴다(사용자 결정 6) — 빼고 싶은 복지는 결과 화면 비교표에서 뺀다(같은 checked 계약).
// 두 열은 각자 한 덩어리의 DOM(A 전부 → B 전부)이라 읽기·탭 순서가 사람이 읽는 순서와 같고, 줄 맞춤은
// CSS subgrid 가 한다(모바일은 한 열로 A 다음 B).
export const PRIORITIES = ['연봉', '워라밸', '복지'];
const HOURS_CHIPS = [[40, 'low', '거의 없음(주 40h)'], [45, 'mid', '보통(주 45h)'], [54, 'high', '잦음(주 54h)']];
const WAGE_CHIPS = [['separate', '따로 받음(비포괄)'], ['inclusive', '연봉에 포함(포괄)']];
const RAISE_CHIPS = [10, 13, 15, 20];
const SLOT_TITLE = { a: '현재 직장(A)', b: '이직 후보(B)' };
const SLOT_SUB = { a: '지금 다니는 회사', b: '옮길지 고민하는 회사' };
const CALC_PRIVACY = '계산은 브라우저 안에서만 이뤄지고, 입력값은 어디로도 전송되지 않습니다.';

// 숫자 칸 파싱 — 쉼표·공백을 무시한다. 빈칸은 null(0 아님: 통근·근속 「미입력」은 「0」과 다르다).
export function parseNum(v, { decimal = false, signed = false } = {}) {
  const t = String(v == null ? '' : v).replace(/[,\s]/g, '');
  if (t === '') return null;
  const re = decimal ? (signed ? /^-?\d*\.?\d+$/ : /^\d*\.?\d+$/) : (signed ? /^-?\d+$/ : /^\d+$/);
  if (!re.test(t)) return null;
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
}
const won = (n) => Math.round(n).toLocaleString('ko-KR');

/** 현재 연봉(만원) — 단일 칸. 옛 초안의 범위(최소~최대)는 가운데 값으로 보여 준다(엔진도 mid 를 쓴다). */
export function currentSalary(state) {
  const s = (state.salS && state.salS.a) || {};
  if (s.low == null && s.high == null) return null;
  if (s.low == null || s.high == null) return s.low ?? s.high;
  return s.low === s.high ? s.low : Math.round((s.low + s.high) / 2);
}

/** 이직 후보 연봉을 직접 넣었으면 그 값에서 상승률을 되짚는다(엔진 계약은 상승률 하나). */
export function effectiveRate(state) {
  if (state.rateMode === 'salary') {
    const sal = currentSalary(state);
    return sal && state.offerSal != null ? (state.offerSal / sal - 1) * 100 : null;
  }
  return state.selectedRate ?? null;
}

// 역할 radio 인 칩 묶음 — 이미 고른 칩을 다시 누르면 선택이 풀린다(기본값 없음 · 미선택 허용).
// 방향키로 이웃 칩으로 옮겨 고른다(WAI-ARIA radiogroup). 탭 멈춤은 고른 칩 하나(없으면 첫 칩).
function chipGroup({ id, labelledby, options, selected, onPick }) {
  const g = el('div', { class: 'calc-chips', role: 'radiogroup', id, 'aria-labelledby': labelledby });
  const btns = options.map(([v, text]) => {
    const b = el('button', { type: 'button', class: 'calc-chip', role: 'radio', 'data-v': String(v), text });
    b.addEventListener('click', () => {
      const on = b.getAttribute('aria-checked') === 'true';
      setChecked(g, on ? null : String(v));
      onPick(on ? null : v);
    });
    b.addEventListener('keydown', (e) => {
      const dir = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
      if (!dir) return;
      e.preventDefault();
      const i = btns.indexOf(b);
      const next = btns[(i + dir + btns.length) % btns.length];
      next.focus();
      // 방향키는 **고르기만** 한다 — 이미 고른 칩에 도착했을 때 click 하면 선택이 풀린다(라디오답지 않다).
      if (next.getAttribute('aria-checked') !== 'true') next.click();
    });
    return b;
  });
  g.append(...btns);
  setChecked(g, selected == null ? null : String(selected));
  return g;
}
function setChecked(group, value) {
  if (!group) return;
  const btns = [...group.querySelectorAll('[role="radio"]')];
  btns.forEach((b) => b.setAttribute('aria-checked', String(b.getAttribute('data-v') === value)));
  const on = btns.find((b) => b.getAttribute('aria-checked') === 'true') || btns[0];
  btns.forEach((b) => b.setAttribute('tabindex', b === on ? '0' : '-1'));
}

function label(text, { req = false, opt = false, forId = null, id = null } = {}) {
  const attrs = { class: 'calc-fl' };
  if (forId) attrs.for = forId;
  if (id) attrs.id = id;
  const node = el(forId ? 'label' : 'div', attrs, text);
  if (req) node.append(' ', el('span', { class: 'calc-req', text: '★ 필수' }));
  if (opt) node.append(' ', el('span', { class: 'calc-opt', text: '(선택)' }));
  return node;
}
const help = (text, id) => el('p', id ? { class: 'calc-help', id, text } : { class: 'calc-help', text });
function numInput(id, { value = null, mode = 'numeric', placeholder = '', aria = null, short = true, describedby = null } = {}) {
  const attrs = { id, class: short ? 'calc-num calc-num-short' : 'calc-num', type: 'text', inputmode: mode, autocomplete: 'off' };
  if (placeholder) attrs.placeholder = placeholder;
  if (aria) attrs['aria-label'] = aria;
  if (describedby) attrs['aria-describedby'] = describedby;
  const inp = el('input', attrs);
  if (value != null) inp.value = String(value);
  return inp;
}
const cell = (slot, extra = '') => el('div', { class: 'calc-pc calc-p' + slot + (extra ? ' ' + extra : '') });

function companyName(state, slot) {
  const m = state.matched && state.matched[slot];
  return m && m.comp_nm ? m.comp_nm : '';
}

// 회사 로고 자리 — 글자 배지(목업). 로고 파일이 없는 회사가 대부분이라 이름 첫 글자를 쓴다.
function logoLetter(name) {
  const ch = String(name || '').trim().charAt(0);
  return ch ? ch.toUpperCase() : '?';
}

// 검색 뷰로 돌아가는 길(「회사 변경」·미선택이면 「회사 선택」). **선택된 슬롯에도 단다**(2026-09-05): 24시간
// 초안이 B 를 들고 있으면 「이 회사로 비교하기」(`/compare/?a=lg_elec`)가 사용자가 고른 적 없는 B 와 짝지어진
// 입력 뷰를 띄운다 — 화면 안에 회사를 바꿀 길이 없으면 그것은 막다른 골목이다. REF 에서 사라진 comp_id 를
// 담은 「최근 비교」 복원처럼 한 슬롯만 찬 입력 뷰가 만들어지는 경로의 안전망이기도 하다.
function slotPickButton(slot, deps = {}, picked = false) {
  const btn = el('button', {
    type: 'button', class: 'in-slot-pick calc-btn-sm', 'data-pick-slot': slot,
    text: picked ? '회사 변경' : '회사 선택',
  });
  btn.addEventListener('click', () => {
    clearPrefillNote(); // 부팅 안내는 여기서 수명이 끝난다(사용자가 직접 검색 뷰로 돌아왔다)
    if (typeof deps.go === 'function') deps.go('search');
    focusSlotInput(slot); // 돌아간 검색 뷰에서 바로 타이핑할 수 있게
  });
  return btn;
}

function slotHeaderCell(state, slot, deps) {
  const c = cell(slot, 'calc-top');
  const nm = companyName(state, slot);
  const head = el('div', { class: 'calc-ph' });
  head.append(el('span', { class: 'calc-logo', 'aria-hidden': 'true', text: logoLetter(nm) }));
  const title = el('h3', { class: 'calc-pt' });
  title.append(el('span', { class: 'calc-sym calc-sym-' + slot, 'aria-hidden': 'true' }),
    SLOT_TITLE[slot] + ' — ' + (nm || '미선택'), el('small', { text: SLOT_SUB[slot] }));
  head.append(title, slotPickButton(slot, deps, !!(state.matched && state.matched[slot])));
  c.append(head);
  return c;
}

function eqText(state) {
  const sal = currentSalary(state);
  if (state.rateMode === 'salary') {
    const r = effectiveRate(state);
    if (r == null) return '= 연봉을 넣으면 상승률을 계산합니다';
    return '= 지금보다 ' + (r >= 0 ? '+' : '−') + Math.abs(r).toFixed(1) + '%';
  }
  const r = state.selectedRate;
  if (!sal || r == null) return '= 상승률을 고르면 계산합니다';
  return '= ' + won(sal * (1 + r / 100)) + '만원';
}

function salaryCell(state, refresh) {
  const c = cell('a');
  c.append(label('현재 연봉(만원)', { req: true, forId: 'calc-sal' }));
  const row = el('div', { class: 'calc-numrow' });
  const inp = numInput('calc-sal', { value: currentSalary(state), short: false, placeholder: '예: 6000', describedby: 'calc-sal-help' });
  const set = (n) => { state.salS.a = n == null ? { low: null, high: null } : { low: n, high: n }; refresh(); };
  inp.addEventListener('input', () => set(parseNum(inp.value)));
  row.append(inp, el('span', { class: 'calc-unit', text: '만원' }));
  for (const [d, t, aria] of [[-100, '−100', '100만원 줄이기'], [100, '+100', '100만원 늘리기'], [500, '+500', '500만원 늘리기']]) {
    const b = el('button', { type: 'button', class: 'calc-step', 'aria-label': aria, text: t });
    b.addEventListener('click', () => {
      const v = Math.max(0, (parseNum(inp.value) || 0) + d);
      inp.value = String(v);
      set(v);
    });
    row.append(b);
  }
  c.append(row, help('세전 연봉을 만원 단위로 적어 주세요.', 'calc-sal-help'));
  return c;
}

function raiseCell(state, refresh) {
  const c = cell('b');
  const lbl = label(state.rateMode === 'salary' ? '이직 후보 연봉(만원)' : '연봉 상승률(%)', { req: true, id: 'calc-rate-lbl' });
  c.append(lbl);
  const chips = chipGroup({
    id: 'calc-raise', labelledby: 'calc-rate-lbl',
    options: RAISE_CHIPS.map((v) => [v, '+' + v]),
    selected: state.rateMode !== 'salary' && RAISE_CHIPS.includes(state.selectedRate) ? state.selectedRate : null,
    onPick: (v) => { state.selectedRate = v; inp.value = ''; refresh(); },
  });
  chips.hidden = state.rateMode === 'salary';
  c.append(chips);
  const row = el('div', { class: 'calc-numrow calc-gap' });
  const direct = state.rateMode === 'salary' ? state.offerSal
    : (state.selectedRate != null && !RAISE_CHIPS.includes(state.selectedRate) ? state.selectedRate : null);
  const inp = numInput('calc-rate', {
    value: direct, mode: 'decimal',
    placeholder: state.rateMode === 'salary' ? '예: 6900' : '예: 12',
    aria: state.rateMode === 'salary' ? '이직 후보 연봉 직접 입력(만원)' : '연봉 상승률 직접 입력(%)',
  });
  const directLbl = el('label', { class: 'calc-unit', for: 'calc-rate', text: state.rateMode === 'salary' ? '연봉' : '직접 입력' });
  const unit = el('span', { class: 'calc-unit', text: state.rateMode === 'salary' ? '만원' : '%' });
  const eq = el('span', { class: 'calc-eq', id: 'calc-eq', 'aria-live': 'polite', text: eqText(state) });
  inp.addEventListener('input', () => {
    if (state.rateMode === 'salary') {
      state.offerSal = parseNum(inp.value);
      state.selectedRate = effectiveRate(state);
    } else {
      state.selectedRate = parseNum(inp.value, { decimal: true, signed: true });
      setChecked(chips, RAISE_CHIPS.includes(state.selectedRate) ? String(state.selectedRate) : null);
    }
    refresh();
  });
  const toggle = el('button', {
    type: 'button', class: 'calc-link', id: 'calc-rate-mode',
    text: state.rateMode === 'salary' ? '상승률로 넣기' : '연봉으로 직접 넣기',
  });
  toggle.addEventListener('click', () => {
    const sal = currentSalary(state);
    if (state.rateMode === 'salary') {
      state.rateMode = 'rate';
      state.selectedRate = effectiveRate(state) == null ? null : Math.round(effectiveRate(state) * 10) / 10;
    } else {
      state.rateMode = 'salary';
      state.offerSal = sal && state.selectedRate != null ? Math.round(sal * (1 + state.selectedRate / 100)) : null;
      state.selectedRate = effectiveRate(state);
    }
    const fresh = raiseCell(state, refresh);
    c.replaceWith(fresh);
    const t = fresh.querySelector('#calc-rate-mode');
    if (t) t.focus();
  });
  row.append(directLbl, inp, unit, eq, toggle);
  c.append(row, help('잡코리아 설문에서 직장인이 가장 많이 꼽은 희망 인상률은 13%입니다. 값을 미리 채워 두지는 않았습니다.'));
  return c;
}

function hoursCell(state, slot) {
  const c = cell(slot);
  const ws = state.wsState[slot] || (state.wsState[slot] = {});
  const lblId = 'calc-ot-lbl-' + slot;
  c.append(el('div', { class: 'calc-rule' }), label('야근은 얼마나 하세요?', { id: lblId }));
  const hoursNow = ws.hours != null ? Number(ws.hours) : (HOURS_CHIPS.find(([, k]) => k === ws.ot) || [null])[0];
  const inp = numInput('calc-hours-' + slot, {
    value: hoursNow, aria: (slot === 'a' ? '현재 직장' : '이직 후보') + ' 주 근무시간 직접 입력',
  });
  const chips = chipGroup({
    id: 'calc-ot-' + slot, labelledby: lblId,
    options: HOURS_CHIPS.map(([h, , t]) => [h, t]),
    selected: HOURS_CHIPS.some(([h]) => h === hoursNow) ? hoursNow : null,
    onPick: (h) => {
      ws.hours = h;
      ws.ot = h == null ? null : HOURS_CHIPS.find(([x]) => x === h)[1];
      inp.value = h == null ? '' : String(h);
    },
  });
  inp.addEventListener('input', () => {
    const h = parseNum(inp.value, { decimal: true });
    ws.hours = h;
    const hit = HOURS_CHIPS.find(([x]) => x === h);
    ws.ot = hit ? hit[1] : null;
    setChecked(chips, hit ? String(h) : null);
  });
  const row = el('div', { class: 'calc-numrow calc-gap' });
  row.append(el('label', { class: 'calc-unit', for: 'calc-hours-' + slot, text: '또는 주 근무시간 직접 입력' }), inp, el('span', { class: 'calc-unit', text: '시간' }));
  c.append(chips, row, help('회사별 야근 정보가 없어 직접 골라 주셔야 합니다. 비워 두면 시간당 총보상과 야근수당은 계산하지 않습니다.'));
  return c;
}

function wageCell(state, slot) {
  const c = cell(slot);
  const ws = state.wsState[slot] || (state.wsState[slot] = {});
  const lblId = 'calc-wage-lbl-' + slot;
  c.append(el('div', { class: 'calc-rule' }), label('야근수당은?', { id: lblId }));
  c.append(chipGroup({
    id: 'calc-wage-' + slot, labelledby: lblId, options: WAGE_CHIPS,
    selected: ws.wage === 'separate' || ws.wage === 'inclusive' ? ws.wage : null,
    onPick: (v) => { ws.wage = v; },
  }));
  c.append(help('고르지 않으면 포괄·비포괄 두 경우의 결과를 나란히 보여 드립니다.'));
  return c;
}

// 재택 플래그는 `remote_work` 행 유무의 파생이라 틀릴 수 있다(NAVER: 「Type_R(원격) 개인 선택」인데 false).
// 우리가 판단하지 않고 **원문을 보여 주고** 사용자가 고친다(FINAL-DESIGN §2-6).
export function remoteHint(state, slot) {
  const m = state.matched && state.matched[slot];
  const ws = state.wsState[slot] || {};
  if (!m || ws.remote) return null;
  for (const b of (state.benS && state.benS[slot]) || []) {
    const text = b.qual_desc_ctnt || b.note_ctnt || '';
    if (/재택|원격|Type_R/.test(text)) return { name: b.benefit_nm, text };
  }
  return null;
}

function fillSummaryText(ws) {
  return (ws.flex ? '유연근무 있음' : '유연근무 없음') + ' · ' + (ws.remote ? '재택 있음' : '재택 없음');
}

function prefillCell(state, slot) {
  const c = cell(slot);
  const ws = state.wsState[slot] || (state.wsState[slot] = {});
  const d = el('details', { class: 'calc-fill', id: 'calc-fill-' + slot });
  const sum = el('summary');
  const b = el('b', { text: fillSummaryText(ws) });
  sum.append(el('span', {}, '회사에 등록된 정보로 미리 채웠습니다 — ', b), el('span', { class: 'calc-fix', 'aria-hidden': 'true', text: '고치기' }));
  d.append(sum);
  const body = el('div', { class: 'calc-fill-body' });
  for (const [key, text] of [['flex', '유연근무'], ['remote', '재택근무']]) {
    const id = 'ws-' + key + '-' + slot;
    const cb = el('input', { type: 'checkbox', id });
    cb.checked = !!ws[key];
    cb.addEventListener('change', () => { ws[key] = cb.checked; b.textContent = fillSummaryText(ws); });
    body.append(el('label', { class: 'calc-check', for: id }, cb, ' ' + text));
  }
  const hint = remoteHint(state, slot);
  if (hint) {
    const p = el('p', { class: 'calc-fill-note' });
    p.append('다만 ' + companyName(state, slot) + '의 「' + hint.name + '」 설명에는 원격 근무를 고를 수 있다고 되어 있습니다. ',
      el('q', { text: hint.text }), ' 실제와 다르면 고쳐 주세요.');
    body.append(p);
  }
  d.append(body);
  c.append(el('div', { class: 'calc-rule' }), d);
  return c;
}

function commuteCell(state, slot) {
  const c = cell(slot);
  const id = 'calc-commute-' + slot;
  c.append(el('div', { class: 'calc-rule' }), label('편도 통근시간(분)', { opt: true, forId: id }));
  const inp = numInput(id, { value: state.cmtS[slot] });
  inp.addEventListener('input', () => { state.cmtS[slot] = parseNum(inp.value); });
  c.append(el('div', { class: 'calc-numrow' }, inp, el('span', { class: 'calc-unit', text: '분' })),
    help('비워 두면 통근 시간은 계산에서 뺍니다(0분으로 치지 않습니다).'));
  return c;
}

function tenureCell(state) {
  const c = cell('a', 'calc-bot');
  c.append(el('div', { class: 'calc-rule' }), label('현재 직장 근속(년)', { opt: true, forId: 'calc-tenure' }));
  const inp = numInput('calc-tenure', { value: state.tenureYears, mode: 'decimal' });
  inp.addEventListener('input', () => { state.tenureYears = parseNum(inp.value, { decimal: true }); });
  c.append(el('div', { class: 'calc-numrow' }, inp, el('span', { class: 'calc-unit', text: '년' })));
  const n = tenureItems(state.benS.a || []).length;
  if (n) {
    c.append(help(companyName(state, 'a') + '에는 근속 연수에 따라 받는 복지가 ' + n + '개 있습니다. '
      + '근속 연수를 넣으면 지금 받는 것과 아직 못 받는 것을 나눠 보여 드립니다.'));
  }
  return c;
}

function tenureNoteCell() {
  const c = cell('b', 'calc-bot');
  c.append(el('div', { class: 'calc-rule' }), el('div', { class: 'calc-fl calc-muted', text: '근속' }),
    el('p', { class: 'calc-muted calc-note', text: '이직하면 근속 연수는 처음부터 다시 셉니다.' }));
  return c;
}

/** 입력·결과 화면의 「어떤 기준으로 볼까요?」 — 고른 축이 결과의 결론과 먼저 보이는 내용을 정한다(결정 5). */
function axisCard(state) {
  const card = el('div', { class: 'calc-card calc-axis', id: 'calc-axis' });
  card.append(el('div', { class: 'calc-lbl', id: 'calc-axis-lbl', text: '어떤 기준으로 볼까요?' }));
  const seg = chipGroup({
    id: 'calc-axis-seg', labelledby: 'calc-axis-lbl',
    options: PRIORITIES.map((p) => [p, p]),
    selected: PRIORITIES.includes(state.curPri) ? state.curPri : '연봉',
    onPick: (v) => {
      state.curPri = v || '연봉';
      if (!v) setChecked(seg, '연봉'); // 기준은 언제나 하나 — 다시 눌러도 풀리지 않는다
    },
  });
  seg.classList.add('calc-seg');
  card.append(seg, help('고른 기준에 따라 결론과 먼저 보여 드리는 내용이 달라집니다. 결과 화면에서도 언제든 바꿔 볼 수 있습니다.'));
  return card;
}

/** 결과 화면에서 기준을 바꾸면 입력 화면의 세그먼트도 따라온다(같은 상태 하나). */
export function syncAxisSegment(state) {
  setChecked(byId('calc-axis-seg'), PRIORITIES.includes(state.curPri) ? state.curPri : '연봉');
}

// 새 JS 가 **옛 셸**(#input-slot-a/b · #priority-picker · 맨몸의 #btn-compare)을 만나도 죽지 않게 — 머지 뒤
// pull 과 캐시된 HTML 사이 틈. 옛 빈 칸은 걷고(아이디 중복 방지) #calc-form·고정 버튼 띠를 만든다.
export function ensureInputScaffold() {
  if (typeof document === 'undefined' || typeof document.createElement !== 'function') return null;
  const view = byId('view-input');
  if (!view || typeof view.append !== 'function') return null;
  let form = byId('calc-form');
  const btn = byId('btn-compare');
  if (!form) {
    form = el('div', { id: 'calc-form', class: 'calc-form' });
    if (btn && btn.parentNode === view) view.insertBefore(form, btn); else view.append(form);
  }
  for (const id of ['priority-picker']) {
    const old = byId(id);
    if (old && old.parentNode && !form.contains(old)) old.remove();
  }
  for (const id of ['input-slot-a', 'input-slot-b']) {
    const old = byId(id);
    if (old && old.parentNode && !form.contains(old)) old.remove();
  }
  if (btn && !(btn.parentNode && btn.parentNode.classList && btn.parentNode.classList.contains('calc-cta'))) {
    const cta = el('div', { class: 'calc-cta' });
    btn.parentNode.insertBefore(cta, btn);
    cta.append(btn, el('p', { class: 'calc-privacy', text: CALC_PRIVACY }));
  }
  if (btn && btn.textContent !== '비교 결과 보기') btn.textContent = '비교 결과 보기';
  return form;
}

export function renderInputView(state, deps = {}) {
  const form = ensureInputScaffold();
  if (!form) return;
  form.replaceChildren();
  // 「= 6,900만원」은 상승률 칸이 모드 전환으로 새로 그려질 수 있어 매번 찾아 쓴다.
  const refresh = () => {
    const eq = form.querySelector('#calc-eq');
    if (eq) eq.textContent = eqText(state);
    clearMissingAlert();
  };
  const colA = el('div', { class: 'calc-col calc-col-a', id: 'input-slot-a', 'data-slot': 'a' });
  const colB = el('div', { class: 'calc-col calc-col-b', id: 'input-slot-b', 'data-slot': 'b' });
  colA.append(slotHeaderCell(state, 'a', deps), salaryCell(state, refresh), hoursCell(state, 'a'),
    wageCell(state, 'a'), prefillCell(state, 'a'), commuteCell(state, 'a'), tenureCell(state));
  colB.append(slotHeaderCell(state, 'b', deps), raiseCell(state, refresh), hoursCell(state, 'b'),
    wageCell(state, 'b'), prefillCell(state, 'b'), commuteCell(state, 'b'), tenureNoteCell());
  const pair = el('div', { class: 'calc-pair' });
  pair.append(colA, colB);
  form.append(axisCard(state), pair);
}

// ── 결측 안내(#3): 비었을 때 무엇을 넣어야 하는지 한 줄(role="alert") ────────────────
export const MISSING_LABEL = {
  salary: '현재 연봉',
  raise: '연봉 상승률',
};

// 결측 코드 배열 → 사용자 안내 문구. 입력 화면의 말이라 칸 이름으로 부른다.
export function missingMessage(missing, state = null) {
  const names = (missing || []).map((k) => {
    if (k === 'raise' && state && state.rateMode === 'salary') return '이직 후보 연봉';
    return MISSING_LABEL[k] || k;
  });
  if (!names.length) return '필수 입력값이 비어 있습니다.';
  return names.join('과 ') + '을 입력해 주세요.';
}

function showMissingAlert(missing, state) {
  if (typeof document === 'undefined') return;
  let box = byId('input-missing-alert');
  if (!box) { // 셸에 없으면 비교하기 버튼 앞에 동적 생성(index/compare 공통 — JS 소유)
    box = el('p', { id: 'input-missing-alert', role: 'alert', class: 'input-missing-alert' });
    const btn = byId('btn-compare');
    if (btn && btn.parentNode && typeof btn.parentNode.insertBefore === 'function') btn.parentNode.insertBefore(box, btn);
    else { const view = byId('view-input'); if (view && view.append) view.append(box); }
  }
  box.textContent = missingMessage(missing, state);
  box.hidden = false;
  // 무엇이 비었는지 손가락으로 — 첫 결측 칸으로 커서를 옮긴다.
  const first = (missing || [])[0];
  const target = first === 'salary' ? byId('calc-sal')
    : first === 'raise' ? (state && state.rateMode === 'salary' ? byId('calc-rate') : (qs('#calc-raise [role="radio"]') || byId('calc-rate')))
      : null;
  if (target && typeof target.focus === 'function') target.focus();
}

function clearMissingAlert() {
  const box = byId('input-missing-alert');
  if (box) { box.textContent = ''; box.hidden = true; }
}

// 결과의 첫 화면은 결론이다 — 대문 히어로(제목·소개 ~280px)를 지나 「비교 결과」 머리로 내려간다(폰 390×844 에서
// 결론 + 타일이 첫 화면에 들어오게, FINAL-DESIGN §3-0). 고정 헤더 높이는 실측한다(360px 에서 두 줄이 된다).
export function scrollToReport() {
  if (typeof window === 'undefined' || typeof window.scrollTo !== 'function') return;
  const view = byId('view-report');
  if (!view || typeof view.getBoundingClientRect !== 'function') return;
  const header = qs('header');
  const headH = header && typeof header.getBoundingClientRect === 'function' ? header.getBoundingClientRect().height : 0;
  const top = view.getBoundingClientRect().top + (window.scrollY || 0) - headH;
  if (top > 0) window.scrollTo(0, top);
}

// ── 입력 뷰 배선(비교하기) ───────────────────────────────────────────────────
export function bindInputView(state, deps) {
  const btn = byId('btn-compare');
  if (btn) {
    btn.addEventListener('click', () => {
      const report = (typeof deps.runReport === 'function') ? deps.runReport({ state, mountEl: byId('report-body') }) : null;
      if (report && report.ok === false) { showMissingAlert(report.missing, state); return; } // 결측 → 리포트 이동 차단·안내(#3)
      clearMissingAlert();
      if (typeof deps.go === 'function') deps.go('report');
      scrollToReport();
      if (typeof deps.mountAds === 'function') { try { deps.mountAds('result'); } catch { /* 광고 실패 무손상(MON6) */ } }
    });
  }
}

// 렌더된 뷰 콘텐츠를 비운다("새 비교" 등 상태 초기화와 짝). 상태와 DOM이 어긋나면
// 뒤로가기 시 유령 리포트가 남으므로, 상태를 비우는 쪽이 DOM도 함께 책임진다.
// 셸 컨테이너 자체는 남기고 내용만 비운다(광고 슬롯·버튼은 셸 소유, SP-ADS-9.2).
export function clearRenderedViews() {
  for (const id of ['report-body', 'calc-form', 'input-slot-a', 'input-slot-b', 'priority-picker']) {
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
    state.rateMode = 'rate';
    state.offerSal = null;
    state.tenureYears = null;
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
  // 보면 초안 복원 후 입력 뷰가 비어 보인다(app.js slotFilled 도 chosenType 을 센다 — 두 판정이
  // 어긋나면 "상태는 있는데 화면은 빈" 상태가 된다).
  const hasSlot = state.matched && (state.matched.a || state.matched.b);
  const hasType = state.chosenType && (state.chosenType.a || state.chosenType.b);
  if (hasSlot || hasType) renderInputView(state, deps);
}
