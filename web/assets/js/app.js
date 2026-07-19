// web/assets/js/app.js — 엔트리·오케스트레이터(SP-FE-1·2·3·4·5·9.3·11, FR-02·03·40·42, INV-1·2·4).
// 상태(App.state) 단일 소유자. go() 라우팅·부팅 조립·엔진 호출 조립(assembleCompareState)·
// URL 프리필 소비. calc.js(SP-ENGINE)를 import해 소비만 하고(재구현 금지), report.js에 렌더를 위임한다.
import { compare } from './calc.js';
import { renderReport, saveRecentComparison } from './report.js';
import { loadReference } from './boot.js';
import { normalizeCompany, fillBenefits, initWsState, blankWs } from './inputs.js';
import { mountUI, reflectSlotLabel, maybeAdvance, bindBootRetry } from './ui.js';
import { mountAds, initConsentBanner } from './ads.js';
import { mountTrending, sendCompareLog } from './trending.js';
import { mountDirectory } from './directory.js';
import { findCompanies, renderCompanyView } from './company.js';

// ── SP-FE-4.1 전역 클라이언트 상태 모델(프로파일러 상태 없음, SP-FE-4.3) ───
export function createInitialState() {
  return {
    REF: null, // 참조 번들(SP-FE-5). {company_types, benefit_presets, companies}
    matched: { a: null, b: null }, // 회사 객체(정규화됨) 또는 null (FR-D8)
    benS: { a: [], b: [] }, // 복지 항목[] (FR-D8.1: +checked +value_source)
    wsState: { a: blankWs(), b: blankWs() }, // {ot,wage,remote,flex} 각 null
    salS: { a: { low: null, high: null } }, // 만원 — 슬롯 a만
    selectedRate: null, // b 상승률(%) 또는 null
    cmtS: { a: null, b: null }, // 통근시간(분) 또는 null
    curPri: '워라밸', // ∈ {연봉,워라밸,복지,브랜드} 기본 워라밸
    curSacrifice: null, // ≠ curPri 또는 null
    chosenType: { a: null, b: null }, // 직접 입력 모드 선택 유형(comp_tp_cd) 또는 null (FR-17)
    inputMode: { a: 'company', b: 'company' }, // 'company' | 'direct'
    ui: {
      screen: 'search',
      searchTimers: { a: null, b: null },
      searchAborts: { a: null, b: null },
      searchState: { a: 'idle', b: 'idle' },
    },
  };
}
// pfShuffled/pfCur/pfAnswers/pfResult/pfJob 키는 절대 추가하지 않는다(SP-FE-4.3, INV-2).

export const App = { state: createInitialState() };

// ── SP-FE-3 화면 라우팅(go·해시/History) ────────────────────────────────────
// 'company': 회사 복지 페이지(GNB 검색 직행, 2026-07-16) — REF 기반, 서버 라우트 없음.
export const SCREENS = ['search', 'input', 'report', 'company'];

export function parseHash() { // '#input' → 'input'
  const h = (typeof location !== 'undefined' ? location.hash : '').replace(/^#/, '');
  return SCREENS.includes(h) ? h : null;
}

function focusFirstHeading(screenId) {
  if (typeof document === 'undefined') return;
  const view = document.getElementById && document.getElementById('view-' + screenId);
  const heading = view && typeof view.querySelector === 'function' ? view.querySelector('h1,h2,h3') : null;
  if (heading && typeof heading.focus === 'function') {
    if (typeof heading.setAttribute === 'function') heading.setAttribute('tabindex', '-1');
    heading.focus();
  }
}

export function go(screenId, { push = true } = {}) {
  if (!SCREENS.includes(screenId)) screenId = 'search'; // 방어: 미지 뷰 → 검색
  App.state.ui.screen = screenId;
  if (typeof document !== 'undefined' && typeof document.getElementById === 'function') {
    for (const s of SCREENS) {
      const view = document.getElementById('view-' + s);
      if (view) view.hidden = (s !== screenId);
    }
  }
  if (push && typeof history !== 'undefined' && typeof history.pushState === 'function') {
    history.pushState({ screen: screenId }, '', '#' + screenId); // 해시 + History 상태
  }
  if (typeof window !== 'undefined' && typeof window.scrollTo === 'function') window.scrollTo(0, 0);
  focusFirstHeading(screenId); // 접근성: 뷰 전환 시 포커스 이동(NFR14)
  return screenId;
}

function onPopState(e) {
  const screen = (e.state && e.state.screen) || parseHash() || 'search';
  go(screen, { push: false }); // 뒤로/앞으로 → 재푸시 없이 표시만
}
if (typeof window !== 'undefined' && typeof window.addEventListener === 'function') {
  window.addEventListener('popstate', onPopState);
}

// ── SP-FE-5.1 부팅 시퀀스 ────────────────────────────────────────────────────
function bindGlobalUI() { /* 헤더/푸터/동의배너 위임(정적 즉시) — SP-ADS·정적 셸이 소유 */ }

export function showBootError(err) {
  if (typeof document !== 'undefined' && typeof document.getElementById === 'function') {
    const box = document.getElementById('boot-error');
    if (box) box.hidden = false; // #boot-error 표시, #app 계속 hidden(B-3)
  }
  return err;
}

export async function boot(hooks = {}) {
  const {
    loadReferenceFn = loadReference, bindGlobalUIFn = bindGlobalUI,
    mountAdsFn = mountAds, initConsentBannerFn = initConsentBanner,
  } = hooks;
  bindGlobalUIFn();
  try {
    App.state.REF = await loadReferenceFn(); // boot.js: GET /api/v1/reference/all (부팅당 1회, B-1)
  } catch (err) {
    showBootError(err); // FR-E1 — #app 밖 오류 박스 노출(#10)
    bindBootRetry(App.state, { reboot: () => boot(hooks) }); // 실패 경로에서도 재시도 버튼 배선(#10)
    return err;
  }
  restoreFromPrefill(); // SP-FE-11 URL 파라미터 → 슬롯 프리필(있으면)
  if (typeof document !== 'undefined' && typeof document.getElementById === 'function') {
    const appEl = document.getElementById('app');
    if (appEl) appEl.hidden = false;
    const errEl = document.getElementById('boot-error');
    if (errEl) errEl.hidden = true; // 재시도 성공 시 오류 박스 숨김(#10)
  }
  // 최근 비교 복원 컨텍스트(C1): '불러오기' 클릭 → 레코드로 상태 복원 후 리포트 재실행·이동.
  const recentCtx = { onRestore: (record) => restoreComparison(record, deps) };
  // 통합 계층 마운트: 검색/입력/리포트 DOM 이벤트 배선 + 입력 뷰 컨트롤 렌더(SP-FE-3 이벤트 바인딩).
  // runReport 래핑: 성공 비교만 익명 쌍 로그 1회 전송(fire-and-forget — 직접 입력 쌍은 sendCompareLog가
  // 자체 제외. INV-1 개정 2026-07-14). 결측(ok:false)이면 로그 미전송(#3).
  const deps = {
    go,
    runReport: (h) => {
      const report = runReport({ ...h, recentCtx });
      if (report && report.ok !== false) { try { sendCompareLog(App.state); } catch { /* 무손상 */ } }
      return report;
    },
    mountAds: mountAdsFn,
    reboot: () => boot(hooks),
  };
  deps.showCompany = (term) => showCompanyPage(term, deps); // GNB 검색 → 회사 복지 페이지
  mountUI(App.state, deps);
  try { initConsentBannerFn(); } catch { /* 동의 배너 실패 무손상 */ } // 광고 동의 배너 배선(#12)
  try { mountAdsFn(); } catch { /* 광고 마운트 실패 무손상(MON6) */ } // page_type별 광고 배선(랜딩 등, #12)
  // 실시간 비교 TOP 10 위젯(우측 레일) — 실패 무해(mountTrending 내부 방어), await 안 함(부팅 비차단).
  mountTrending({ onPick: (item) => pickTrendingPair(item, deps) });
  // 등록 회사 디렉토리(검색 카드 카운트 → 가나다순 목록 → 복지 펼침) — REF 재사용, 실패 무해.
  try { mountDirectory(App.state); } catch { /* 디렉토리 실패는 비교 툴 무손상 */ }
  // 프리필로 슬롯이 채워졌으면 입력 뷰로(restoreFromPrefill의 go('input')이 아래 최종 go로 덮이지 않게 보정).
  const prefilled = !!(App.state.matched.a || App.state.matched.b);
  go(parseHash() || (prefilled ? 'input' : 'search'), { push: false });
}
if (typeof document !== 'undefined' && typeof document.addEventListener === 'function') {
  document.addEventListener('DOMContentLoaded', () => boot());
}

// ── SP-FE-11 URL 파라미터 프리필(정적 CTA → 비교 툴) ────────────────────────
export function resolveCompanyToken(token, state = App.state) {
  const cs = (state.REF && state.REF.companies) || [];
  if (/^\d+$/.test(token)) return cs.find((c) => c.comp_id === Number(token)) || null; // comp_id
  const t = token.toLowerCase();
  return cs.find((c) => (c.comp_eng_nm || '').toLowerCase() === t) // 영문 식별자
    || cs.find((c) => c.comp_nm === token) // 정식명 완전일치
    || cs.find((c) => (c.aliases || []).includes(token)) // 별칭
    || null;
}

export function restoreFromPrefill(state = App.state, hooks = {}) {
  const { reflectSlotLabel, goFn = go } = hooks;
  const search = typeof location !== 'undefined' ? (location.search || '') : '';
  const p = new URLSearchParams(search);
  for (const slot of ['a', 'b']) {
    const token = p.get(slot);
    if (!token) continue;
    const comp = resolveCompanyToken(token, state); // REF 우선 해석(P-1)
    if (comp) {
      state.matched[slot] = normalizeCompany(comp); // FR-14와 동일 정규화(P-2)
      fillBenefits(state, slot);
      initWsState(state, slot);
      if (typeof reflectSlotLabel === 'function') reflectSlotLabel(slot, comp.comp_nm);
    }
    // 해석 실패 시 슬롯 미선택 유지(정상 검색 진입으로 폴백, P-3)
  }
  if (state.matched.a || state.matched.b) goFn('input', { push: false }); // 프리필 있으면 입력 뷰
}

// ── 실시간 비교 TOP 10 위젯 클릭 → 양 슬롯 프리필(프리필과 동일 정규화 경로) ──
export function pickTrendingPair(item, deps = {}, state = App.state) {
  const compA = resolveCompanyToken(String(item.a_comp_id), state);
  const compB = resolveCompanyToken(String(item.b_comp_id), state);
  if (!compA || !compB) return false; // REF에 없는 쌍 → 무시(위젯은 서버 집계, 프리필은 REF 기준)
  for (const [slot, comp] of [['a', compA], ['b', compB]]) {
    state.matched[slot] = normalizeCompany(comp); // FR-14와 동일 정규화(P-2)
    fillBenefits(state, slot);
    initWsState(state, slot);
    reflectSlotLabel(slot, comp.comp_nm);
  }
  maybeAdvance(state, deps); // 양 슬롯 채움 → 입력뷰 렌더 + go('input')
  return true;
}

// ── 회사 복지 페이지(GNB 검색 직행, #company 뷰) ─────────────────────────────
export function showCompanyPage(term, deps = {}, state = App.state) {
  const mountEl = (typeof document !== 'undefined' && document.getElementById)
    ? document.getElementById('company-page') : null;
  if (!mountEl) return false;
  const matches = findCompanies((state.REF && state.REF.companies) || [], term);
  renderCompanyView({ term: String(term || '').trim(), matches }, mountEl, {
    onCompare: (company) => { // "이 회사와 비교 시작" → A 슬롯 프리필 후 검색 뷰(B 선택 유도)
      state.matched.a = normalizeCompany(company);
      fillBenefits(state, 'a');
      initWsState(state, 'a');
      reflectSlotLabel('a', company.comp_nm);
      const goFn = typeof deps.go === 'function' ? deps.go : go;
      goFn('search');
    },
  });
  const goFn = typeof deps.go === 'function' ? deps.go : go;
  goFn('company');
  return true;
}

// ── SP-FE-9.3 엔진 호출·상태 조립(assembleCompareState) ─────────────────────
export const PRI_KEY = { 연봉: 'salary', 워라밸: 'wlb', 복지: 'benefits', 브랜드: 'brand' };

export function salToStr(s) { // {low,high} → "lo-hi" | null
  if (!s || s.low == null || s.high == null) return null;
  return s.low + '-' + s.high;
}

export function assembleCompareState(state) { // App.state → CompareState(SP-ENGINE-2) — 유일 변환점(A-1)
  return {
    salStr: salToStr(state.salS.a), // 슬롯 a만; 슬롯 b는 rate 파생(A-2)
    selectedRate: state.selectedRate,
    benS: state.benS, // 구조 동일(pass-through)
    wsState: state.wsState,
    com: { a: state.cmtS.a ?? 0, b: state.cmtS.b ?? 0 }, // null→0(A-4)
    curPri: PRI_KEY[state.curPri] || 'wlb', // 라벨→PriKey(방어 폴백 wlb, A-3)
    curSacrifice: state.curSacrifice ? (PRI_KEY[state.curSacrifice] || null) : null,
    matched: state.matched,
    companyTypes: (state.REF && state.REF.company_types) || [], // 브랜드 축용 참조 주입
  };
}

// ── 리포트 진입·재계산(FR-42): 조립 → 계산 → 렌더 ───────────────────────────
export function runReport(hooks = {}) {
  const { state = App.state, compareFn = compare, renderReportFn = renderReport, mountEl, recentCtx } = hooks;
  const report = compareFn(assembleCompareState(state)); // SP-ENGINE-2.2 Report
  if (report && report.ok === false) return report; // 필수값 결측 → 렌더·이동 차단(호출부가 안내, #3)
  saveRecentComparison(state, report); // 성공 비교 자동 저장(C1) — 저장 불가 시 store가 조용히 무시
  // 마운트 지점: #report-body(리포트 콘텐츠 전용) — #view-report 자체는 광고 슬롯·버튼·헤딩을
  // 포함하므로 replaceChildren 대상에서 제외한다(compare/index.html 셸 계약).
  const el2 = mountEl || (typeof document !== 'undefined' && document.getElementById ? document.getElementById('report-body') : null);
  if (el2) {
    renderReportFn(report, el2, { benS: state.benS, matched: state.matched, recentCtx }); // 배지·표시명·최근비교 콜백(SP-FE-9.4, C1)
  }
  return report;
}

// 최근 비교 저장 진입점(외부 호출용) — 필드 구성은 report.js(FR-43 경계) 소유.
// 통상 저장은 runReport가 자동 수행(C1). 이 헬퍼는 명시 저장이 필요한 호출부용으로 유지.
export function saveCurrentComparison(state = App.state, report) {
  const r = report || runReport({ state, mountEl: null });
  return saveRecentComparison(state, r);
}

// ── 최근 비교 복원(C1): 저장 레코드 → App.state 재구성 후 리포트 재실행·이동 ────────────────
// 레코드(FR-43)는 benS(체크 상태·금액)를 저장하지 않으므로, 회사 슬롯은 REF에서 복지를 재적재한다
// (전체 체크). REF에 없는 comp_id(직접입력 등)는 슬롯 미선택으로 복원한다.
export function restoreComparison(record, deps = {}, state = App.state) {
  if (!record || !record.input) return false;
  const inp = record.input;
  state.salS = inp.salS || { a: { low: null, high: null } };
  state.selectedRate = inp.selectedRate ?? null;
  state.cmtS = inp.cmtS || { a: null, b: null };
  state.wsState = inp.wsState || { a: blankWs(), b: blankWs() };
  state.curPri = inp.curPri || '워라밸';
  state.curSacrifice = inp.curSacrifice || null;
  state.chosenType = inp.chosenType || { a: null, b: null };
  state.inputMode = inp.inputMode || { a: 'company', b: 'company' };
  for (const slot of ['a', 'b']) {
    const s = record.slots && record.slots[slot];
    const comp = (s && s.comp_id != null) ? resolveCompanyToken(String(s.comp_id), state) : null;
    if (comp) {
      state.matched[slot] = normalizeCompany(comp); // FR-14와 동일 정규화(P-2)
      fillBenefits(state, slot); // benS 재적재(레코드 미저장분 — 전체 체크로 복원)
    } else {
      state.matched[slot] = null;
      state.benS[slot] = [];
    }
    reflectSlotLabel(slot, state.matched[slot] ? state.matched[slot].comp_nm : '');
  }
  const goFn = typeof deps.go === 'function' ? deps.go : go;
  if (typeof deps.runReport === 'function') deps.runReport({ state, mountEl: null });
  else runReport({ state });
  goFn('report');
  return true;
}
