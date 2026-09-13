// web/assets/js/app.js — 엔트리·오케스트레이터(SP-FE-1·2·3·4·5·9.3·11, FR-02·03·40·42, INV-1·2·4).
// 상태(App.state) 단일 소유자. go() 라우팅·부팅 조립·엔진 호출 조립(assembleCompareState)·
// URL 프리필 소비. calc.js(SP-ENGINE)를 import해 소비만 하고(재구현 금지), report.js에 렌더를 위임한다.
import { el } from './dom.js'; // 덱 이름표도 데이터 문자열이다(회사명에 `&` 가 있다, NFR21)
import { compare } from './calc.js';
import { renderReport, saveRecentComparison } from './report.js';
import { loadReference } from './boot.js';
import { normalizeCompany, fillBenefits, initWsState, blankWs } from './inputs.js';
import { mountUI, reflectSlotLabel, focusSlotInput, maybeAdvance, bindBootRetry, renderInputView, notePrefill } from './ui.js';
import { mountAds } from './ads.js';
import { mountTrending, sendCompareLog } from './trending.js';
import { mountDirectory } from './directory.js';
import { findCompanies, renderCompanyView } from './company.js';
import { mountBenefits, pairTarget } from './benefits.js'; // 모드 A 「복지 비교」(SP-CMP)
import { initDeckCollapse } from './deck.js';
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
      // URL(`?a=`·`?b=`)이 채운 슬롯. 「회사 바꾸기」가 **어느 칸에 커서를 둘지**를 정하는 데만
      // 쓴다 — 사용자가 고르지 않은 쪽(초안·레코드가 채운 쪽)을 먼저 가리켜야 한다(SP-CMP-8).
      prefilledSlots: [],
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
// 'benefits': 모드 A 「복지 비교」(SP-CMP) — 입력 없이 두 회사 복지를 나란히 보는 화면.
// 정본 주소는 해시 없는 `/compare/?a=&b=` 이고, `#benefits` 는 검색 뷰에서 넘어올 때 생기는
// 히스토리 항목이다(뒤로가기로 검색 뷰에 돌아갈 수 있어야 한다).
export const SCREENS = ['search', 'input', 'report', 'company', 'benefits'];

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

/**
 * 뷰 전환. `replace:true` 는 **현재 히스토리 항목을 덮는다** — 회사를 바꿀 때마다 pushState 가
 * 쌓이면 뒤로가기를 다섯 번 눌러야 도구를 빠져나간다(SP-CMP-2).
 */
export function go(screenId, { push = true, replace = false } = {}) {
  if (!SCREENS.includes(screenId)) screenId = 'search'; // 방어: 미지 뷰 → 검색
  App.state.ui.screen = screenId;
  // 모드 A 본문은 **보이기 직전에** 그린다. 9각형·나비는 viewBox·% 라 hidden 인 채 그려도
  // 깨지지 않는다(실측이 필요한 것은 덱뿐이고, 그건 뷰가 보인 뒤 아래에서 잰다).
  if (screenId === 'benefits') {
    try { renderBenefitsView(); } catch { /* 렌더 실패가 라우팅을 막지는 않는다 */ }
  }
  if (typeof document !== 'undefined' && typeof document.getElementById === 'function') {
    for (const s of SCREENS) {
      const view = document.getElementById('view-' + s);
      if (view) view.hidden = (s !== screenId);
    }
  }
  if (typeof history !== 'undefined') {
    if (replace && typeof history.replaceState === 'function') {
      history.replaceState({ screen: screenId }, '', '#' + screenId);
    } else if (push && typeof history.pushState === 'function') {
      history.pushState({ screen: screenId }, '', '#' + screenId); // 해시 + History 상태
    }
  }
  if (typeof window !== 'undefined' && typeof window.scrollTo === 'function') window.scrollTo(0, 0);
  focusFirstHeading(screenId); // 접근성: 뷰 전환 시 포커스 이동(NFR14)
  // 🚨 덱 문턱은 **뷰가 보인 뒤** 잰다. `#app`(또는 뷰)이 hidden 인 채 재면 높이가 0 으로 잡혀
  //    문턱이 무너지고, 증상이 "가끔 이상함"으로 나와 원인을 못 가리킨다.
  if (screenId === 'benefits' && benefitsDeck) {
    try { benefitsDeck.measure(); benefitsDeck.onScroll(); } catch { /* 실측 실패 무손상 */ }
  }
  return screenId;
}

// ── SP-FE-3.3 규칙 (3) 술어: "보여줄 것이 없으면 search" ────────────────────
// 슬롯 하나가 "찼다"의 정의. 회사가 매칭됐거나 직접 입력 모드면 그 슬롯은 채워진 것이다.
export function slotFilled(state, slot) {
  const ct = state.chosenType || {};
  const im = state.inputMode || {};
  return !!(state.matched[slot] || ct[slot] || im[slot] === 'direct');
}

// 입력 뷰에 들어갈 자격 = **두 슬롯이 다 찼는가**(2026-09-05 개정).
// 왜 '슬롯 하나라도'가 아니라 '쌍'인가: 입력 뷰에는 회사를 고르는 컨트롤이 없다
// (#search-input-a/b 와 후보 목록은 검색 뷰 소유이고, 검색 뷰로 돌아갈 버튼도 없다).
// 그래서 한 슬롯만 찬 채로 입력 뷰에 들어가면 나머지 회사를 영영 고를 수 없는
// 막다른 골목이 된다 — /compare/?a=skt 로 실제 재현된 고장이다. ui.js maybeAdvance 가
// 전진 조건으로 이미 쓰던 술어(matched.a && matched.b)를 프리필·부팅·popstate 에도
// 똑같이 적용한다. 판정이 화면마다 다르면 "상태는 있는데 고칠 길은 없는" 화면이 남는다.
export function hasPairState(state = App.state) {
  return slotFilled(state, 'a') && slotFilled(state, 'b');
}

// 한 슬롯만 찼을 때 **비어 있는** 쪽. 둘 다 찼거나 둘 다 비었으면 null(고를 것이 없거나,
// 어디부터 고를지 우리가 정할 일이 아니다).
export function pendingSlot(state = App.state) {
  const a = slotFilled(state, 'a');
  const b = slotFilled(state, 'b');
  if (a && !b) return 'b';
  if (b && !a) return 'a';
  return null;
}

function hasRenderedReport() {
  if (typeof document === 'undefined' || typeof document.getElementById !== 'function') return false;
  const el = document.getElementById('report-body');
  return !!(el && el.children && el.children.length > 0);
}

// 해시가 요구한 뷰 + 현재 사실 → 실제로 들어갈 뷰. 순수 함수(브라우저 무의존, UT-ROUTE-3·4).
// restore:true는 "복원을 시도하라"는 지시일 뿐이고, 이동(go)은 언제나 호출부가 소유한다.
// hasPair: **두 슬롯이 다 찼는가**(hasPairState). 이름이 내용과 어긋나면 안 되므로 인자도
// 'slot' 이 아니라 'pair' 다 — 한 슬롯만 찬 상태를 input 으로 보내던 것이 이번 고장이었다.
// hasPrefill: **URL 이 슬롯을 시켰는가**(?a=·?b=). 규칙 5("프리필 > 자동 복원")를 세는 것은
// 쌍이 아니라 이쪽이다 — 한 슬롯 프리필(?a=kakao#report)에서 pair 만 보면 false 라 자동 복원이
// 이겨서, URL 이 시킨 카카오가 최근 레코드의 다른 쌍으로 조용히 덮이고 화면과 주소가 어긋난다.
export function resolveBootScreen({
  want = null, hasPair: pair = false, hasPrefill: prefill = false, hasReport = false, recentCount = 0,
} = {}) {
  // 🚩 2026-09-12(SP-CMP-2): 두 슬롯이 다 찼을 때의 기본 목적지가 입력 뷰 → **복지 비교**로 바뀌었다.
  // `/compare/?a=&b=`(해시 없음)가 곧 모드 A 의 주소이기 때문이다. 목적지는 `pairTarget()` 하나가
  // 정한다 — 여기와 `ui.js::maybeAdvance` 가 따로 적으면 경로마다 다른 화면이 뜬다.
  const fallback = pair ? pairTarget() : 'search';
  if (want === 'search') return { screen: 'search', restore: false };
  if (want === 'report') {
    if (hasReport) return { screen: 'report', restore: false }; // 이미 렌더돼 있음(popstate 경로)
    if (pair) return { screen: fallback, restore: false };      // 프리필 > 자동 복원(규칙 5)
    if (prefill) return { screen: 'search', restore: false };   // 한 슬롯 프리필도 규칙 5 — 덮지 않는다
    if (recentCount > 0) return { screen: 'search', restore: true }; // 복원 시도 후 성공하면 report
    return { screen: 'search', restore: false };                // 복원 재료 없음 → 강등
  }
  // `#input` 은 **사용자가 명시한 모드 B** 다 — 쌍이 차 있으면 그대로 입력 뷰로 간다(폴백을 태우면
  // 새로고침할 때마다 계산기가 비교 화면으로 되돌아간다). 쌍이 없으면 예전대로 강등한다.
  if (want === 'input') return { screen: pair ? 'input' : 'search', restore: false };
  if (want === 'benefits') return { screen: pair ? 'benefits' : 'search', restore: false };
  // 'company'(term 없이 진입 불가)·null·미지 → 폴백
  return { screen: fallback, restore: false };
}

export function onPopState(e) {
  // e.state.screen(=go가 남긴 항목)을 우선 쓰되 **무조건 신뢰하지는 않는다**(2026-07-20 개정).
  // 뷰 DOM이 살아 있다는 보장이 없기 때문이다 — "새 비교"가 상태와 렌더를 함께 비우고 나면
  // 그 뒤 뒤로가기로 돌아온 report 항목은 보여줄 것이 없다. 신뢰하면 빈 리포트(B-1 재현)가,
  // 비우지 않으면 유령 리포트(오정보)가 된다. → 부팅과 동일한 상태 술어로 판정한다.
  const want = (e && e.state && e.state.screen) || parseHash();
  // 해시도 상태도 없으면 기존 계약대로 search. resolveBootScreen의 폴백(쌍이 차면 input)은
  // **부팅** 규칙이라 여기 적용하면 뒤로가기가 현재 입력 뷰에 눌러앉아 먹통으로 보인다.
  if (!want) { go('search', { push: false }); return; }
  // recentCount:0 고정 — popstate는 자동 복원하지 않는다(사용자가 뒤로 간 것이지 재진입이 아니다).
  const d = resolveBootScreen({
    want, hasPair: hasPairState(), hasReport: hasRenderedReport(), recentCount: 0,
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
    navTypeFn = navigationType, // 새 진입인가(navigate) — 테스트는 주입한다(node 에는 navigation 항목이 없다)
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
  // 화면이지 이어하기 화면이 아니다. (2026-09-13 부터 비교 도구도 **새 진입**이면 처음부터다 — 아래 🚩)
  // ⚠ 복원을 생략하는 데 그치지 않고 **지운다**. 남겨 두면 대문에서 새로고침해 "초기화"한
  //   사용자가 `/compare/` 로 갔을 때 방금 지운 값이 되살아나 약속이 깨진다.
  // ⓘ 이래도 1단계의 핵심 왕복은 그대로다: 대문에서 입력 → (pagehide 저장) → 회사 페이지 →
  //   "이 회사로 비교하기" → `/compare/?a=…` 는 **대문을 다시 로드하지 않으므로** 복원된다.
  //   지워지는 것은 "이전에 하다 만 것"뿐이고, 지금 대문에서 쓰던 입력은 지켜진다.
  // ⚠ 2026-09-13 확인: 대문 1단계(PR #43) 이후 대문(`web/index.html`)은 app.js 를 **싣지 않는다** → 위
  //   `isLandingShell()` 분기는 실행되지 않는 관성이다. 이번 사고의 진짜 원인이 이것이었다 — 대문이 초안을
  //   지워 주던 장치가 대문과 함께 조용히 죽었다. 실효 판정은 아래 `isFreshEntry` 다.
  // 🚩 2026-09-13 확장(사용자 결정): 대문이 비교 도구를 품지 않게 된 뒤로(대문 1단계) 대문의 「복지 비교」·
  //   「이직 계산기」 카드가 `/compare/` 로 **새로 들어오는** 문이 됐다. 그 문으로 들어왔는데 24시간 초안이
  //   두 회사 칸을 채워 두면 「누르자마자 어제 본 회사가 골라져 있고, 넘어갈 버튼도 없는」 검색 뷰가 된다
  //   (라이브 재현). 그래서 「처음부터」의 자격을 셸만이 아니라 **진입 방식**으로도 준다.
  //   · 새 진입(navigate) + URL 이 회사를 지정하지 않음 → 대문과 같이 초안을 지우고 빈 칸에서 시작
  //   · 새로고침·뒤로/앞으로(reload·back_forward) → 종전대로 이어하기
  //   · `?a=`/`?b=` 가 있으면 → 종전대로(회사 페이지 「이 회사로 비교하기」 왕복이 초안의 존재 이유다)
  const fresh = isLandingShell() || isFreshEntry({
    navType: navTypeFn(),
    search: typeof location !== 'undefined' ? (location.search || '') : '',
  });
  if (fresh) inputDraft.clear();
  const draftRestored = fresh ? false : restoreInputDraft();
  // reflectSlotLabel 훅을 넘긴다: 프리필이 검색 뷰에 남을 수 있게 된 뒤로, 훅이 없으면
  // 상태에는 A 가 들어 있는데 #search-input-a 는 비어 보인다(사용자에겐 프리필 실패로 읽힌다).
  const prefilled = restoreFromPrefill(App.state, { reflectSlotLabel }); // SP-FE-11 URL → 슬롯 프리필
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
  bindBenefitsView(App.state, deps); // 모드 A 덱 배선(렌더는 go('benefits') 가 한다)
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
  // 이 시점에는 restoreFromPrefill(위)이 이미 슬롯을 채웠으므로 hasPairState가 프리필을 포함한다.
  // 🚨 초안은 **상태를 되살릴 뿐 화면을 가로채지 않는다**(2026-07-31). 부팅 화면 폴백이
  // "슬롯이 있으면 input" 이라, 초안이 슬롯을 채우면 대문(`/`)이 대문이 아니게 된다 —
  // 신규 방문자가 히어로·등록 회사 목록·광고가 있는 랜딩 대신 남이 쓰다 만 입력 화면을 본다.
  // 화면을 정할 자격은 **URL 이 시킨 것**(프리필 `?a=` · 해시 `#input` 새로고침)뿐이다.
  // 초안이 없던 시절과 동작이 같아야 하므로 `!draftRestored` 를 함께 본다(하위호환).
  const want = parseHash();
  const urlAsked = prefilled || want != null;
  const decision = resolveBootScreen({
    want,
    hasPair: hasPairState() && (urlAsked || !draftRestored),
    hasPrefill: prefilled, // 초안이 아니라 **URL 이 시킨 슬롯**만 규칙 5 의 방패가 된다
    hasReport: hasRenderedReport(),
    recentCount: recent.list().length,
  });
  let screen = decision.screen;
  if (decision.restore && restoreLatestComparison({ recentCtx, viewDeps: deps })) screen = 'report';
  go(screen, { push: false }); // 부팅 경로의 유일한 go — 정확히 1회, push 금지
  stampBootEntry(screen);
  if (screen === 'benefits') noteBorrowedSlot(App.state); // 초안이 채운 슬롯을 소리로도 알린다
  // ⚠ go() 는 접근성용으로 뷰의 첫 헤딩에 포커스를 옮긴다(focusFirstHeading). 그래서
  //   restoreFromPrefill 이 빈 슬롯에 잡아 둔 포커스를 **부팅의 마지막 go 가 도로 뺏는다**.
  //   프리필 판정을 restoreFromPrefill 에 두고 이동은 boot 이 독점하는 구조(B-6)를 지키려면
  //   여기서 한 번 더 잡는 수밖에 없다 — 순서를 바꾸면 이중 go 가 된다.
  if (prefilled && screen === 'search') {
    const pending = pendingSlot(App.state);
    if (pending) {
      // 안내문을 **포커스 전에** 만든다: aria-describedby 로 묶인 설명은 포커스가 오는 순간
      // label 과 함께 읽힌다. 순서가 뒤집히면 스크린리더는 "이직 후보(B), 편집창"만 듣고
      // A 가 이미 채워졌다는 사실을 놓친다(시각 사용자는 A 칸 값으로 한눈에 안다).
      const filled = pending === 'a' ? 'b' : 'a';
      const m = App.state.matched[filled];
      if (m) notePrefill(filled, m.comp_nm, pending);
      focusSlotInput(pending);
    }
  }
  bindDraftPersist();
}

/**
 * 부팅으로 들어온 **첫 히스토리 항목에 어느 화면인지 적어 둔다** (SP-CMP-2).
 *
 * 🚨 왜 필요한가: 모드 A 의 정본 주소는 해시가 없다(`/compare/?a=&b=`). 그래서 그 항목은
 * `history.state` 도 `location.hash` 도 비어 있고, 거기서 「이직 계산기 →」로 `#input` 을 push 한
 * 뒤 뒤로가기를 누르면 `onPopState` 가 받는 것은 **state null + hash 빈 문자열**이다 — 둘 다
 * 없으면 검색 뷰로 보내는 기존 분기에 걸려 비교 화면으로 못 돌아온다(「뒤로가기로 비교 화면에
 * 돌아올 수 있어야 한다」는 약속이 깨진다).
 *
 * 해시를 붙여 해결하지 않는 이유: 그러면 주소가 정본이 아니게 되고, 공유된 링크가 `#benefits` 를
 * 달고 돌아다닌다. 주소는 그대로 두고 **항목에만** 표식을 남긴다.
 */
export function stampBootEntry(screen, win = (typeof globalThis !== 'undefined' ? globalThis : null)) {
  const h = win && win.history;
  const loc = win && win.location;
  if (!h || typeof h.replaceState !== 'function' || !loc) return false;
  if (h.state && h.state.screen) return false;   // 이미 표식이 있으면 덮지 않는다
  if (loc.hash) return false;                    // 해시가 말하고 있으면 표식이 필요 없다
  h.replaceState({ screen }, '', loc.href);
  return true;
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
  const { reflectSlotLabel, goFn = go, focusSlot = focusSlotInput } = hooks;
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
      if (state.ui && Array.isArray(state.ui.prefilledSlots) && !state.ui.prefilledSlots.includes(slot)) {
        state.ui.prefilledSlots.push(slot); // 이 슬롯은 **URL 이** 시켰다(사용자가 고른 게 아니다)
      }
    }
    // 해석 실패 시 슬롯 미선택 유지(정상 검색 진입으로 폴백, P-3)
  }
  // ⚠ 여기서는 익명 쌍 로그를 **일부러 보내지 않는다**(2026-07-31). 프리필은 사람이 고른
  // 결과가 아니라 URL이 시킨 것이고, /compare/?a=…&b=… 는 JS를 실행하는 크롤러가 그대로
  // 밟는 경로다(실측: GoogleOther가 /compare/?a=<slug> 를 계속 긁는다). 여기에 로그를 걸면
  // 집계가 봇의 크롤 빈도를 재게 된다. 기록 시점은 사람이 슬롯을 채운 maybeAdvance 다.
  // 화면은 **채운 개수**가 정한다(2026-09-05 개정, hasPairState 주석 참조).
  //  · 두 슬롯 → 입력 뷰(전진 자격 충족 — maybeAdvance 와 같은 술어)
  //  · 한 슬롯 → 검색 뷰. 나머지 회사를 고를 컨트롤이 거기에만 있다. 예전처럼 입력 뷰로
  //    보내면 "이직 후보(B) — 직접 입력 / 복지 항목 없음" 만 있는 막다른 화면이 뜬다
  //    (/compare/?a=skt — 회사 상세의 "이 회사로 비교하기" 가 항상 밟던 경로다).
  //    빈 슬롯 입력칸에 커서를 넣어 "여기서 나머지를 고르면 된다"를 손가락으로 가리킨다.
  if (filled) {
    const pending = pendingSlot(state);
    if (pending) {
      goFn('search', { push: false });
      focusSlot(pending);
    } else {
      goFn(pairTarget(), { push: false }); // 두 슬롯 프리필 = 모드 A 의 정본 주소(SP-CMP-2)
    }
  }
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

/**
 * 이 문서가 어떻게 열렸는가 — Navigation Timing 의 `type`(navigate · reload · back_forward · prerender).
 * 알 수 없으면(구형 브라우저·테스트 환경) `null` 이고, 부팅은 null 을 **종전 동작(이어하기)** 으로 읽는다
 * — 모르는 환경에서 사용자의 입력을 지우는 쪽으로 틀리지 않기 위해서다.
 */
export function navigationType(perf = (typeof performance !== 'undefined' ? performance : null)) {
  try {
    const entry = perf && typeof perf.getEntriesByType === 'function' ? perf.getEntriesByType('navigation')[0] : null;
    return entry && typeof entry.type === 'string' ? entry.type : null;
  } catch { return null; }
}

/**
 * 비교 도구에 **새로 들어왔는가** = 초안을 되살리지 않고 빈 칸에서 시작할 진입인가(순수 함수, 2026-09-13).
 * - URL 이 회사를 지정했으면(`?a=`·`?b=`) 새 진입이 아니다 — 회사 페이지 왕복이 초안을 쓴다.
 * - navigate·prerender 만 새 진입이다. reload·back_forward·null(모름)은 이어하기.
 * - 해시는 보지 않는다: 대문 「이직 계산기」 카드(`/compare/#input`)도 새 진입이고, 계산기 화면의
 *   새로고침은 reload 라 이어진다 — 둘을 가르는 것은 해시가 아니라 진입 방식이다.
 */
export function isFreshEntry({ navType = null, search = '' } = {}) {
  const p = new URLSearchParams(search || '');
  if (p.get('a') || p.get('b')) return false;
  return navType === 'navigate' || navType === 'prerender';
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

// ── 모드 A 「복지 비교」 배선 (SP-CMP-2·8) ───────────────────────────────────

let benefitsDeck = null; // 덱 접힘 컨트롤러(뷰가 보인 뒤 go() 가 measure 한다)

function qsAll(root, sel) {
  return root && typeof root.querySelectorAll === 'function' ? [...root.querySelectorAll(sel)] : [];
}

/** 덱·미니바에 지금 고른 두 회사를 적는다. 표식(원·네모)은 9각형·막대와 **같은 모양**이다. */
function reflectDeck(state = App.state) {
  if (typeof document === 'undefined') return;
  const view = document.getElementById('view-benefits');
  if (!view) return;
  const a = state.matched.a;
  const b = state.matched.b;
  const slots = view.querySelector('[data-cmp-slots]');
  if (slots) {
    slots.replaceChildren();
    const slot = (key, label, comp) => {
      const box = el('div', { class: 'cmp-slot' });
      const lb = el('span', { class: 'cmp-slot-l' });
      lb.append(el('i', { class: `cmp-key cmp-key-${key}`, 'aria-hidden': 'true' }), el('span', { text: label }));
      box.append(lb, el('span', { class: 'cmp-slot-nm', text: comp ? comp.comp_nm : '고르는 중' }));
      return box;
    };
    slots.append(slot('a', '회사 A', a), el('span', { class: 'cmp-vs', text: 'vs' }), slot('b', '회사 B', b));
  }
  const hero = view.querySelector('[data-cmp-hero]');
  if (hero) {
    hero.replaceChildren();
    hero.append(
      el('i', { class: 'cmp-key cmp-key-a', 'aria-hidden': 'true' }),
      el('span', { text: a ? a.comp_nm : '고르는 중' }),
      el('span', { class: 'cmp-vs', text: ' vs ' }),
      el('i', { class: 'cmp-key cmp-key-b', 'aria-hidden': 'true' }),
      el('span', { text: b ? b.comp_nm : '고르는 중' }),
    );
  }
}

/**
 * 주소를 **화면과 같게** 맞춘다 — `?a=&b=` 가 지금 보이는 두 회사를 가리켜야 새로고침·공유가
 * 같은 것을 연다. 언제나 `replaceState` 다: 회사를 바꿀 때마다 항목이 쌓이면 뒤로가기를 다섯 번
 * 눌러야 나간다(SP-CMP-2).
 */
export function syncPairUrl(state = App.state) {
  if (typeof location === 'undefined' || typeof history === 'undefined') return null;
  if (typeof history.replaceState !== 'function') return null;
  const a = state.matched.a;
  const b = state.matched.b;
  if (!a || !b || !a.comp_eng_nm || !b.comp_eng_nm) return null;
  const url = new URL(location.href);
  if (url.searchParams.get('a') === a.comp_eng_nm && url.searchParams.get('b') === b.comp_eng_nm) return null;
  url.searchParams.set('a', a.comp_eng_nm);
  url.searchParams.set('b', b.comp_eng_nm);
  // `history.state` 를 그대로 넘긴다 — 부팅 항목에 찍어 둔 화면 표식(stampBootEntry)을
  // 여기서 지우면 뒤로가기가 다시 검색 뷰로 떨어진다.
  history.replaceState(history.state, '', url.pathname + url.search + url.hash);
  return url.search;
}

/** 덱 + 본문을 그린다. 두 슬롯이 다 차 있을 때만 본문이 나온다(반쪽 비교는 비교가 아니다). */
export function renderBenefitsView(state = App.state, deps = {}) {
  if (typeof document === 'undefined') return null;
  if (!document.getElementById('view-benefits')) return null;
  reflectDeck(state);
  syncPairUrl(state);
  return mountBenefits(state, { go, ...deps });
}

/**
 * A·B 를 맞바꾼다. **색·표식은 슬롯을 따르므로**(A 초록 원 / B 파랑 네모) 바꾼 뒤에는 같은 회사가
 * 다른 색을 입는다 — 그 사실을 `aria-live` 로 말해 준다. 화면만 보는 사람에게는 이름이 자리를
 * 옮긴 것이 보이지만, 안 보는 사람에게는 아무 일도 일어나지 않은 것과 같기 때문이다.
 *
 * 회사에 딸린 상태만 바꾼다 — 연봉·상승률은 **내 숫자**라 슬롯이 아니라 사람을 따라간다.
 */
export function swapSlots(state = App.state, deps = {}) {
  for (const key of ['matched', 'benS', 'wsState', 'chosenType', 'inputMode', 'cmtS']) {
    const box = state[key];
    if (!box) continue;
    const keep = box.a;
    box.a = box.b;
    box.b = keep;
  }
  for (const slot of ['a', 'b']) {
    const m = state.matched[slot];
    reflectSlotLabel(slot, m ? m.comp_nm : '');
  }
  renderBenefitsView(state, deps);
  if (typeof document !== 'undefined') {
    const live = document.querySelector('[data-cmp-live]');
    const a = state.matched.a;
    const b = state.matched.b;
    if (live && a && b) {
      live.textContent = `이제 회사 A 는 ${a.comp_nm}(초록 원), 회사 B 는 ${b.comp_nm}(파랑 네모)입니다.`;
    }
  }
  return state.matched;
}

/**
 * 「이 슬롯은 내가 고른 게 아니다」를 말해 준다 (SP-CMP-8).
 *
 * `/compare/?a=naver` 처럼 한 슬롯만 주소에 있고 나머지를 **초안이 되살리면** 비교 화면이 곧장
 * 뜬다(예전에는 입력 뷰였다). 화면을 보는 사람은 B 칸에 낯선 회사가 앉아 있는 것을 보지만,
 * 안 보는 사람에게는 아무 설명이 없다 — 어디서 온 이름인지 말해 줘야 바꿀 생각을 할 수 있다.
 */
export function noteBorrowedSlot(state = App.state) {
  // 이 파일의 다른 DOM 접근과 같은 방어 — 셸마다 있는 것이 다르고, 없는 API 를 부르면
  // 부팅 전체가 죽는다(여기서 죽으면 화면이 통째로 안 뜬다).
  if (typeof document === 'undefined' || typeof document.querySelector !== 'function') return null;
  const live = document.querySelector('[data-cmp-live]');
  if (!live) return null;
  const asked = (state.ui && state.ui.prefilledSlots) || [];
  if (asked.length !== 1) return null;              // 둘 다 주소가 시켰거나, 둘 다 아니면 할 말이 없다
  const borrowed = asked[0] === 'a' ? 'b' : 'a';
  const comp = state.matched[borrowed];
  if (!comp) return null;
  const label = borrowed === 'a' ? '회사 A' : '회사 B';
  live.textContent = `${label} 는 이전 비교에서 가져온 ${comp.comp_nm} 입니다. 「회사 바꾸기」로 다시 고를 수 있습니다.`;
  return live.textContent;
}

/**
 * 「회사 바꾸기」를 눌렀을 때 **커서를 둘 칸**.
 *
 * 빈 슬롯이 있으면 당연히 그쪽이다. 둘 다 차 있으면 「사용자가 고르지 않은 쪽」을 가리킨다 —
 * URL 이 `?a=` 로 A 를 시켰고 B 는 초안·레코드가 되살린 상태라면, 사람이 바꾸고 싶은 것은
 * 십중팔구 B 다(고른 적이 없으니까). 단서가 없으면 A 로 간다.
 */
export function slotToChange(state = App.state) {
  const pending = pendingSlot(state);
  if (pending) return pending;
  const asked = (state.ui && state.ui.prefilledSlots) || [];
  if (asked.length === 1) return asked[0] === 'a' ? 'b' : 'a';
  return 'a';
}

/** 덱 버튼·접힘 배선. 부팅에서 한 번만 부른다(렌더는 `renderBenefitsView` 가 따로 한다). */
export function bindBenefitsView(state = App.state, deps = {}) {
  if (typeof document === 'undefined') return null;
  const view = document.getElementById('view-benefits');
  if (!view) return null;
  for (const btn of qsAll(view, '[data-cmp-search]')) {
    // 회사를 바꾸러 검색 뷰로 — **항목을 쌓지 않는다**(SP-CMP-2). 돌아올 때도 같은 자리를 덮는다.
    btn.addEventListener('click', () => {
      go('search', { replace: true });
      focusSlotInput(slotToChange(state));
    });
  }
  for (const btn of qsAll(view, '[data-cmp-input]')) {
    // 모드 전환은 **항목을 남긴다** — 뒤로가기로 비교 화면에 돌아올 수 있어야 한다.
    btn.addEventListener('click', () => { renderInputView(state, { go, ...deps }); go('input'); });
  }
  for (const btn of qsAll(view, '[data-cmp-swap]')) {
    btn.addEventListener('click', () => swapSlots(state, deps));
  }
  benefitsDeck = initDeckCollapse({
    wrap: view.querySelector('[data-cmp-deck]'),
    anchorEl: view,
    minibar: view.querySelector('[data-cmp-minibar]'),
    win: typeof window !== 'undefined' ? window : undefined,
    // 헤더 높이는 **실측**이다 — 360px 에서 GNB 가 두 줄(97px)이 되면 `--header-h:57px` 는 거짓이고,
    // 그때 미니바 위 40px 이 헤더 밑에 묻혀 버튼이 안 눌린다(되돌릴 길 없는 상태).
    headerEl: document.querySelector('header'),
  });
  return benefitsDeck;
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
  // deps 를 넘긴다: REF 에서 사라진 comp_id 는 슬롯 미선택으로 복원되는데(위), 그 슬롯 머리의
  // "회사 선택" 버튼이 검색 뷰로 돌아가려면 deps.go 가 필요하다(없으면 눌러도 아무 일도 없다).
  // ⚠ 다만 **이동 억제와 버튼 배선은 다른 것**이다. 부팅 자동 복원은 이동을 boot 에 넘기려고
  //   go 를 no-op 으로 주입하는데(restoreLatestComparison, B-6), 그 no-op 이 버튼 핸들러까지
  //   물려가면 "회사 선택"이 눌러도 아무 일도 안 하는 죽은 버튼이 된다 — 같은 레코드를 리포트
  //   뷰 '불러오기'로 복원하면 멀쩡하고 부팅 복원에서만 죽는, 경로마다 다른 화면이 된다.
  //   그래서 **뷰 배선용 deps 를 따로 받는다**(viewDeps). 안 주면 지금까지처럼 deps 그대로.
  const viewDeps = deps.viewDeps || deps;
  try { renderInputView(state, viewDeps); } catch { /* 렌더 실패는 복원 자체를 막지 않는다 */ }
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
//  · viewDeps 는 **억제하지 않는다**: 이동만 boot 이 독점할 뿐, 복원된 입력 뷰의 "회사 선택"
//    버튼은 사용자가 나중에 누르는 것이므로 진짜 go 가 필요하다(no-op 을 물려주면 죽은 버튼).
export function restoreLatestComparison({ recentCtx, viewDeps } = {}, state = App.state) {
  const rec = recent.list()[0]; // store가 전 경로 try/catch(L-5) — 손상 봉투는 빈 배열로 온다
  if (!rec) return false;
  return restoreComparison(rec, {
    go: () => {},
    viewDeps: viewDeps || { go },
    runReport: (h) => runReport({ ...h, recentCtx, save: false }),
  }, state);
}
