// web/assets/js/app.js — 엔트리·오케스트레이터(SP-FE-1·2·3·4·5·9.3·11, FR-02·03·40·42, INV-1·2·4).
// 상태(App.state) 단일 소유자. go() 라우팅·부팅 조립·엔진 호출 조립(assembleCompareState)·
// URL 프리필 소비. calc.js(SP-ENGINE)를 import해 소비만 하고(재구현 금지), report.js에 렌더를 위임한다.
import { compare } from './calc.js';
import { renderReport, saveRecentComparison } from './report.js';
import { loadReference } from './boot.js';
import { normalizeCompany, fillBenefits, initWsState, blankWs } from './inputs.js';
import { mountUI, reflectSlotLabel, maybeAdvance, bindBootRetry, renderInputView } from './ui.js';
import { mountAds } from './ads.js';
import { mountTrending, sendCompareLog } from './trending.js';
import { mountDirectory } from './directory.js';
import { findCompanies, renderCompanyView } from './company.js';
import { recent, inputDraft } from './store.js'; // 부팅 시 #report 딥링크 자동 복원(SP-FE-10.3 L-8) + 입력 초안

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
    curPri: '워라밸', // ∈ {연봉,워라밸,복지} 기본 워라밸
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

// ── SP-FE-3.3 규칙 (3) 술어: "상태가 없으면 search" ─────────────────────────
// 뷰에 들어갔을 때 보여줄 것이 실제로 있는지를 판정한다. 부팅·popstate 공통.
export function hasSlotState(state = App.state) {
  const ct = state.chosenType || {};
  const im = state.inputMode || {};
  return !!(state.matched.a || state.matched.b || ct.a || ct.b
    || im.a === 'direct' || im.b === 'direct');
}

function hasRenderedReport() {
  if (typeof document === 'undefined' || typeof document.getElementById !== 'function') return false;
  const el = document.getElementById('report-body');
  return !!(el && el.children && el.children.length > 0);
}

// 해시가 요구한 뷰 + 현재 사실 → 실제로 들어갈 뷰. 순수 함수(브라우저 무의존, UT-ROUTE-3·4).
// restore:true는 "복원을 시도하라"는 지시일 뿐이고, 이동(go)은 언제나 호출부가 소유한다.
export function resolveBootScreen({ want = null, hasSlotState: slots = false, hasReport = false, recentCount = 0 } = {}) {
  const fallback = slots ? 'input' : 'search'; // 슬롯이 차 있으면 검색보다 입력이 자연스럽다
  if (want === 'search') return { screen: 'search', restore: false };
  if (want === 'report') {
    if (hasReport) return { screen: 'report', restore: false }; // 이미 렌더돼 있음(popstate 경로)
    if (slots) return { screen: 'input', restore: false };      // 프리필 > 자동 복원(규칙 5)
    if (recentCount > 0) return { screen: 'search', restore: true }; // 복원 시도 후 성공하면 report
    return { screen: 'search', restore: false };                // 복원 재료 없음 → 강등
  }
  // 'input'(슬롯 없음)·'company'(term 없이 진입 불가)·null·미지 → 폴백
  return { screen: fallback, restore: false };
}

export function onPopState(e) {
  // e.state.screen(=go가 남긴 항목)을 우선 쓰되 **무조건 신뢰하지는 않는다**(2026-07-20 개정).
  // 뷰 DOM이 살아 있다는 보장이 없기 때문이다 — "새 비교"가 상태와 렌더를 함께 비우고 나면
  // 그 뒤 뒤로가기로 돌아온 report 항목은 보여줄 것이 없다. 신뢰하면 빈 리포트(B-1 재현)가,
  // 비우지 않으면 유령 리포트(오정보)가 된다. → 부팅과 동일한 상태 술어로 판정한다.
  const want = (e && e.state && e.state.screen) || parseHash();
  // 해시도 상태도 없으면 기존 계약대로 search. resolveBootScreen의 폴백(슬롯 있으면 input)은
  // **부팅** 규칙이라 여기 적용하면 뒤로가기가 현재 입력 뷰에 눌러앉아 먹통으로 보인다.
  if (!want) { go('search', { push: false }); return; }
  // recentCount:0 고정 — popstate는 자동 복원하지 않는다(사용자가 뒤로 간 것이지 재진입이 아니다).
  const d = resolveBootScreen({
    want, hasSlotState: hasSlotState(), hasReport: hasRenderedReport(), recentCount: 0,
  });
  go(d.screen, { push: false }); // 뒤로/앞으로 → 재푸시 없이 표시만
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
    mountAdsFn = mountAds,
  } = hooks;
  bindGlobalUIFn();
  try {
    App.state.REF = await loadReferenceFn(); // boot.js: GET /api/v1/reference/all (부팅당 1회, B-1)
  } catch (err) {
    showBootError(err); // FR-E1 — #app 밖 오류 박스 노출(#10)
    bindBootRetry(App.state, { reboot: () => boot(hooks) }); // 실패 경로에서도 재시도 버튼 배선(#10)
    return err;
  }
  // 초안 → 프리필 순서다. URL 이 지정한 슬롯만 아래에서 덮이므로, 정적 회사 페이지의
  // "이 회사로 비교하기"(`/compare/?a=<eng>`)로 돌아오면 **회사는 URL, 연봉·상승률은 초안**이
  // 된다 — 복지를 보러 다녀오는 동안 입력이 사라지지 않는다.
  // 대문(`/`)은 **항상 처음부터** 시작한다(2026-07-31 사용자 결정). 초안이 랜딩에서까지
  // 되살아나면 "새로고침했는데 회사가 이미 골라져 있다"가 된다 — 대문은 신규 방문자의 첫
  // 화면이지 이어하기 화면이 아니다. 이어서 하려면 비교 도구(`/compare/`)로 간다.
  // ⚠ 복원을 생략하는 데 그치지 않고 **지운다**. 남겨 두면 대문에서 새로고침해 "초기화"한
  //   사용자가 `/compare/` 로 갔을 때 방금 지운 값이 되살아나 약속이 깨진다.
  // ⓘ 이래도 1단계의 핵심 왕복은 그대로다: 대문에서 입력 → (pagehide 저장) → 회사 페이지 →
  //   "이 회사로 비교하기" → `/compare/?a=…` 는 **대문을 다시 로드하지 않으므로** 복원된다.
  //   지워지는 것은 "이전에 하다 만 것"뿐이고, 지금 대문에서 쓰던 입력은 지켜진다.
  const landing = isLandingShell();
  if (landing) inputDraft.clear();
  const draftRestored = landing ? false : restoreInputDraft();
  const prefilled = restoreFromPrefill(); // SP-FE-11 URL 파라미터 → 슬롯 프리필(있으면)
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
    // 양 슬롯 확정 = 기록 시점(2026-07-31 문턱 하향). 연봉·상승률까지 채운 사람만 세던
    // 이전 기준으로는 11일간 집계가 0건이었다. sendCompareLog가 세션 내 쌍 중복을
    // 스스로 걸러서 B-7(부풀림)을 막는다. 리포트 성공 시점 전송(위)은 그대로 두되,
    // 같은 쌍이면 중복 제거에 걸려 한 번만 나간다.
    onPairReady: (s) => { try { sendCompareLog(s); } catch { /* 무손상 */ } },
  };
  deps.showCompany = (term) => showCompanyPage(term, deps); // GNB 검색 → 회사 복지 페이지
  mountUI(App.state, deps);
  try { mountAdsFn(); } catch { /* 광고 마운트 실패 무손상(MON6) */ } // page_type별 광고 배선(랜딩 등, #12)
  // "많이 찾아본 조합" 위젯(우측 레일) — 실패 무해(mountTrending 내부 방어), await 안 함(부팅 비차단).
  // companies: 집계 0건일 때 같은 업종 폴백을 만들 재료(REF는 위에서 이미 로드됨 — 추가 네트워크 없음).
  mountTrending({
    companies: (App.state.REF && App.state.REF.companies) || [],
    onPick: (item) => pickTrendingPair(item, deps),
  });
  // 등록 회사 디렉토리(검색 카드 카운트 → 가나다순 목록 → 복지 펼침) — REF 재사용, 실패 무해.
  try { mountDirectory(App.state); } catch { /* 디렉토리 실패는 비교 툴 무손상 */ }
  // 부팅 뷰 결정(SP-FE-3.3 규칙 3·5): 해시가 요구한 뷰에 보여줄 상태가 없으면 강등한다.
  // 이 시점에는 restoreFromPrefill(위)이 이미 슬롯을 채웠으므로 hasSlotState가 프리필을 포함한다.
  // 🚨 초안은 **상태를 되살릴 뿐 화면을 가로채지 않는다**(2026-07-31). 부팅 화면 폴백이
  // "슬롯이 있으면 input" 이라, 초안이 슬롯을 채우면 대문(`/`)이 대문이 아니게 된다 —
  // 신규 방문자가 히어로·등록 회사 목록·광고가 있는 랜딩 대신 남이 쓰다 만 입력 화면을 본다.
  // 화면을 정할 자격은 **URL 이 시킨 것**(프리필 `?a=` · 해시 `#input` 새로고침)뿐이다.
  // 초안이 없던 시절과 동작이 같아야 하므로 `!draftRestored` 를 함께 본다(하위호환).
  const want = parseHash();
  const urlAsked = prefilled || want != null;
  const decision = resolveBootScreen({
    want,
    hasSlotState: hasSlotState() && (urlAsked || !draftRestored),
    hasReport: hasRenderedReport(),
    recentCount: recent.list().length,
  });
  let screen = decision.screen;
  if (decision.restore && restoreLatestComparison({ recentCtx })) screen = 'report';
  go(screen, { push: false }); // 부팅 경로의 유일한 go — 정확히 1회, push 금지
  bindDraftPersist();
}

// 페이지를 떠나는 순간 초안을 저장한다(이동·새로고침·탭 닫기 공통).
// `beforeunload` 가 아니라 `pagehide` 인 이유: bfcache 를 깨지 않고, 모바일에서 더 자주 발화한다.
// `visibilitychange`(hidden)를 함께 거는 이유: iOS 사파리는 앱 전환 시 pagehide 없이 죽을 수 있다 —
// 저장이 멱등이라 둘 다 발화해도 무해하다(같은 값을 덮어쓸 뿐).
export function bindDraftPersist(hooks = {}) {
  const { save = (s) => inputDraft.save(snapshotInput(s)), state = App.state } = hooks;
  const persist = () => { try { save(state); } catch { /* 저장 실패는 비교 흐름에 무해 */ } };
  if (typeof window !== 'undefined' && typeof window.addEventListener === 'function') {
    window.addEventListener('pagehide', persist);
  }
  if (typeof document !== 'undefined' && typeof document.addEventListener === 'function') {
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'hidden') persist();
    });
  }
  return persist;
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
  // ⚠ "상태에 슬롯이 있나"가 아니라 **"내가 채웠나"**를 센다(2026-07-31). 초안 복원이 먼저
  // 돌므로 상태를 기준으로 재면 초안이 채운 것을 프리필의 공으로 세고, 그 결과 대문이
  // 입력 화면으로 바뀐다(초안은 화면을 가로채면 안 된다 — boot 주석 참조).
  let filled = false;
  for (const slot of ['a', 'b']) {
    const token = p.get(slot);
    if (!token) continue;
    const comp = resolveCompanyToken(token, state); // REF 우선 해석(P-1)
    if (comp) {
      state.matched[slot] = normalizeCompany(comp); // FR-14와 동일 정규화(P-2)
      fillBenefits(state, slot);
      initWsState(state, slot);
      if (typeof reflectSlotLabel === 'function') reflectSlotLabel(slot, comp.comp_nm);
      filled = true;
    }
    // 해석 실패 시 슬롯 미선택 유지(정상 검색 진입으로 폴백, P-3)
  }
  // ⚠ 여기서는 익명 쌍 로그를 **일부러 보내지 않는다**(2026-07-31). 프리필은 사람이 고른
  // 결과가 아니라 URL이 시킨 것이고, /compare/?a=…&b=… 는 JS를 실행하는 크롤러가 그대로
  // 밟는 경로다(실측: GoogleOther가 /compare/?a=<slug> 를 계속 긁는다). 여기에 로그를 걸면
  // 집계가 봇의 크롤 빈도를 재게 된다. 기록 시점은 사람이 슬롯을 채운 maybeAdvance 다.
  if (filled) goFn('input', { push: false }); // 프리필 있으면 입력 뷰
  return filled; // 부팅 화면 결정에 쓴다 — "URL 이 시킨 것"과 "초안이 되살린 것"을 가른다
}

// ── 입력 초안(2026-07-31) — 페이지를 떠나도 작성 중이던 값을 지킨다 ──────────
// 계기: 회사 복지를 보러 가면(헤더 검색·디렉터리) 전체 페이지 이동이라 입력하던 연봉·
// 상승률이 통째로 날아간다. '최근 비교'는 **완료된** 리포트만 담아 이걸 못 지킨다.
// 저장은 comp_id·유형·체크 목록 같은 **식별자만** 담는다 — 복지 항목 자체는 REF 최신본에서
// 다시 채운다(스냅샷에 복지를 통째로 넣으면 시드가 갱신돼도 낡은 값이 되살아난다).
export function snapshotInput(state = App.state) {
  const slots = {};
  for (const slot of ['a', 'b']) {
    const m = state.matched && state.matched[slot];
    const entry = {};
    if (m && Number.isInteger(m.comp_id)) entry.comp_id = m.comp_id;
    const tp = state.chosenType && state.chosenType[slot];
    if (typeof tp === 'string' && tp) entry.comp_tp_cd = tp;
    // 체크 해제는 사용자의 명시적 선택이다(기본은 전부 체크) — 되살리지 않으면 조용히 뒤집힌다.
    const items = (state.benS && state.benS[slot]) || [];
    entry.checked = items.filter((b) => b.checked).map((b) => b.benefit_cd).filter(Boolean);
    slots[slot] = entry;
  }
  const ws = state.wsState || {};
  return {
    slots,
    inputMode: { ...(state.inputMode || {}) },
    salS: { a: { ...((state.salS && state.salS.a) || {}) } },
    selectedRate: state.selectedRate ?? null,
    cmtS: { ...(state.cmtS || {}) },
    wsState: { a: { ...(ws.a || {}) }, b: { ...(ws.b || {}) } },
    curPri: state.curPri,
    curSacrifice: state.curSacrifice ?? null,
  };
}

// 대문 셸인가 — 셸이 스스로 밝히는 `data-page-type` 을 쓴다(경로 파싱 금지: `/`·`/index.html`·
// 트레일링 슬래시 변형을 다 맞춰야 하고, 셸이 늘면 조용히 틀린다). 이 값은 광고 마운트가
// 이미 쓰던 마커라 새 계약을 만들지 않는다.
export function isLandingShell(doc = (typeof document !== 'undefined' ? document : null)) {
  const body = doc && doc.body;
  return !!(body && body.dataset && body.dataset.pageType === 'landing');
}

// 초안 → 상태. 슬롯은 REF 로 다시 해석하므로 초안이 낡아도(회사 삭제 등) 조용히 건너뛴다.
export function restoreInputDraft(state = App.state, hooks = {}) {
  const { draft = inputDraft.load(), reflect = reflectSlotLabel } = hooks;
  if (!draft) return false;
  let touched = false;

  for (const slot of ['a', 'b']) {
    const s = (draft.slots && draft.slots[slot]) || {};
    if (Number.isInteger(s.comp_id)) {
      const comp = resolveCompanyToken(String(s.comp_id), state);
      if (comp) {
        state.matched[slot] = normalizeCompany(comp); // 프리필과 동일 정규화 경로(P-2)
        fillBenefits(state, slot);
        initWsState(state, slot);
        if (typeof reflect === 'function') reflect(slot, comp.comp_nm);
        touched = true;
      }
    } else if (typeof s.comp_tp_cd === 'string' && s.comp_tp_cd) {
      state.chosenType[slot] = s.comp_tp_cd; // 직접 입력 모드(프리셋 복사)
      state.inputMode[slot] = 'direct';
      fillBenefits(state, slot);
      touched = true;
    }
    // 체크 상태는 목록을 다시 채운 **뒤에** 덮는다(cd 기준 — 항목이 늘거나 줄어도 안전).
    const items = state.benS[slot] || [];
    if (Array.isArray(s.checked) && items.length) {
      const on = new Set(s.checked);
      for (const b of items) b.checked = on.has(b.benefit_cd);
    }
  }

  // 스칼라 입력. wsState 는 initWsState(회사 기반 제안) **뒤에** 덮어야 사용자의 답이 이긴다.
  if (draft.salS && draft.salS.a) state.salS.a = { low: null, high: null, ...draft.salS.a };
  if (draft.selectedRate != null) state.selectedRate = draft.selectedRate;
  if (draft.cmtS) state.cmtS = { a: null, b: null, ...draft.cmtS };
  if (draft.wsState) {
    for (const slot of ['a', 'b']) {
      if (draft.wsState[slot]) state.wsState[slot] = { ...state.wsState[slot], ...draft.wsState[slot] };
    }
  }
  if (typeof draft.curPri === 'string' && draft.curPri) state.curPri = draft.curPri;
  if (draft.curSacrifice !== undefined) state.curSacrifice = draft.curSacrifice;

  return touched;
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
  // 양 슬롯 채움 → 입력뷰 렌더 + go('input'). **onPairReady는 일부러 끊는다**:
  // 위젯이 보여준 조합을 클릭했다고 그 조합을 다시 집계에 넣으면 1위가 자기 자신을
  // 계속 밀어올리는 자기강화 루프가 된다(한 사람이 클릭만 반복해도 순위가 굳는다).
  maybeAdvance(state, { ...deps, onPairReady: null });
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
export const PRI_KEY = { 연봉: 'salary', 워라밸: 'wlb', 복지: 'benefits' };

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
  };
}

// ── 리포트 진입·재계산(FR-42): 조립 → 계산 → 렌더 ───────────────────────────
export function runReport(hooks = {}) {
  const { state = App.state, compareFn = compare, renderReportFn = renderReport, mountEl, recentCtx, save = true } = hooks;
  const report = compareFn(assembleCompareState(state)); // SP-ENGINE-2.2 Report
  if (report && report.ok === false) return report; // 필수값 결측 → 렌더·이동 차단(호출부가 안내, #3)
  // 성공 비교 자동 저장(C1) — 저장 불가 시 store가 조용히 무시.
  // save:false는 이미 저장된 레코드의 재실행(부팅 자동 복원)용 — 재저장하면 id·savedAt이 새로
  // 발급되어 새로고침만으로 "최근 비교" 목록의 순서와 식별자가 요동친다.
  if (save) saveRecentComparison(state, report);
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
  // 폐기된 축('브랜드')이 담긴 옛 레코드는 기본값으로 정규화한다 — 그대로 두면 우선순위
  // 라디오 어느 항목과도 일치하지 않아 선택이 비어 보인다(브랜드 축 제거, 2026-07-20).
  state.curPri = PRI_KEY[inp.curPri] ? inp.curPri : '워라밸';
  if (inp.curSacrifice && !PRI_KEY[inp.curSacrifice]) inp.curSacrifice = null;
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
  // 입력 뷰 컨트롤 재렌더: mountUI는 마운트 시점에 슬롯이 없으면 입력 뷰를 렌더하지 않는다(ui.js).
  // 복원이 상태만 바꾸고 끝나면 "입력 수정" 한 번에 빈 입력 뷰가 나온다 — B-1과 같은 증상.
  try { renderInputView(state); } catch { /* 렌더 실패는 복원 자체를 막지 않는다 */ }
  const goFn = typeof deps.go === 'function' ? deps.go : go;
  const report = typeof deps.runReport === 'function'
    ? deps.runReport({ state, mountEl: null })
    : runReport({ state });
  // 재실행이 필수값 결측이면 렌더가 차단된다(runReport #3) — 그대로 이동하면 빈 리포트가 남는다.
  // 엄격 비교: runReport 목이 undefined를 반환하는 기존 호출부는 성공으로 유지된다.
  if (report && report.ok === false) return false;
  goFn('report');
  return true;
}

// ── 부팅 시 #report 딥링크 자동 복원(SP-FE-10.3 L-8, SP-FE-5.1 B-6·B-7) ──────
// 최신 레코드 1건만 대상. 자동 복원은 "새 비교"가 아니므로 세 가지를 일부러 하지 않는다:
//  · 이동(go) — boot이 독점한다(이중 go·부팅 중 pushState 방지, B-6)
//  · 비교 로그 전송 — deps.runReport(로그 래퍼) 대신 순수 runReport를 쓴다. 로그를 보내면
//    새로고침마다 "실시간 비교 TOP 10" 집계가 실제 비교 없이 부풀어 오른다(B-7)
//  · 레코드 재저장 — save:false. 재저장하면 id·savedAt이 새로 발급돼 목록 순서가 요동친다(B-7)
export function restoreLatestComparison({ recentCtx } = {}, state = App.state) {
  const rec = recent.list()[0]; // store가 전 경로 try/catch(L-5) — 손상 봉투는 빈 배열로 온다
  if (!rec) return false;
  return restoreComparison(rec, {
    go: () => {},
    runReport: (h) => runReport({ ...h, recentCtx, save: false }),
  }, state);
}
