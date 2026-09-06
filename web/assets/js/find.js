// web/assets/js/find.js — 「복지로 찾기」 탭(/find, SP-FIND). 회사 이름이 아니라 **복지 항목**으로 거른다.
//
// 데이터는 부팅 참조 번들(`reference/all`) 하나뿐이다 — 새 API 도, 새 DB 컬럼도 없다(INV: 무빌드
// 바닐라 ES 모듈 · 읽기 전용 · 무전송). 그래서 이 파일은 두 층으로 갈라져 있다:
//   ① 순수 계산(deriveCodes · parseParams/buildParams · matchCompanies · sortRows · suggest)
//   ② DOM(렌더 · 접힘 컨트롤러 · initFind)
// ①은 node:test 가 DOM 없이 직접 검사하고, ②는 `dom.js::el` 규약(textContent·setAttribute)만 쓴다.
// ⚠ 회사명에 `&` 가 들어간다(삼성E&A) — 데이터 문자열을 innerHTML 에 넣는 경로는 만들지 않는다.

import { el } from './dom.js';
import { slugOf } from './directory.js';

// ── 상수 ─────────────────────────────────────────────────────────────────────

// 카테고리 9종. **정본은 `generator/pages/company.py::CATEGORY_ORDER/CATEGORY_LABEL`** 이고 여기는
// 미러다(번들이 카테고리 라벨을 싣지 않는다 — 회사 페이지·히트맵과 같은 이유). 드리프트는
// find.test.js 가 company.py 를 읽어 문자열로 잡는다(directory.js `slugOf` 미러와 같은 방식).
export const CATEGORY_ORDER = [
  'compensation', 'flexibility', 'work_env', 'time_off', 'health', 'family', 'growth', 'leisure', 'perks',
];
export const CATEGORY_LABEL = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가', health: '건강',
  family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};

// 탭 첫 화면에 여는 카테고리. `perks`(복리후생)가 행 수가 가장 많고(470) 검색 의도도 흔하다.
export const DEFAULT_CATEGORY = 'perks';

// 같은 대표 명칭을 쓰는 코드를 사람이 읽는 이름으로 갈라 준다. 실데이터에 두 뭉치가 있다:
//   · 「통근버스」 = transport(24곳) · commute_subsidy(44곳)
//   · 「장기근속 포상」 = long_service_leave(54) · long_service_bonus(21) · long_service(1, 구 코드)
// 자동 별칭 병기(아래 `disambiguate`)만으로는 "통근버스 · 교통비" / "통근버스 · 야간 교통비" 처럼
// 둘 다 헷갈리는 이름이 나와서, 이 다섯은 손으로 못 박는다. 그 밖의 중복은 별칭이 붙는다.
export const LABEL_OVERRIDE = {
  transport: '교통비·유류비 지원',
  commute_subsidy: '통근버스·출퇴근 지원',
  long_service_leave: '장기근속 휴가',
  long_service_bonus: '장기근속 포상금',
  long_service: '장기근속 포상 (구 코드)',
};

export const MODES = ['and', 'or'];
export const SORT_KEYS = ['match', 'amt', 'total', 'name'];
export const PAGE_SIZE = 30; // 「더 보기」 한 번에 늘어나는 결과 행 수
// 덱 고정·접힘이 켜지는 최소 폭. **styles.css 의 유일한 분기(`min-width:768px`)와 같은 값이어야
// 한다** — 이 디자인 시스템은 분기가 하나이고 `max-width` 분기를 금지한다(UT-BP). 프로토타입은
// 900 이었지만 그러면 768~900 구간에서 덱이 고정된 채 접히지 않아 화면 절반을 먹는다.
export const DESKTOP_MIN = 768;

/** 화면 상태의 기본값. URL 이 없으면 이것이 첫 화면이다(조건 없음 = 전체 회사). */
export function defaultState() {
  return { sel: [], mode: 'and', tp: '', ind: '', amt: false, sort: 'match' };
}

// ── 순수 유틸 ────────────────────────────────────────────────────────────────

/** 검색 정규화 — 소문자 + 공백 제거. 「주 4.5일」과 「주4.5일」이 같은 말이 된다. */
export function normalizeText(s) {
  return String(s ?? '').toLowerCase().replace(/\s+/g, '');
}

/**
 * 복지 한 건의 연 환산 금액(만원). 금액이 없으면 0.
 * ⚠ `qual_yn`(정성)과 금액은 실데이터에서 **정확히 배타**다(2,032행 실측: 정성 1,398 = 금액 null,
 * 금액 634 = 정성 아님). 그래도 둘 다 본다 — 재직자 편집이 금액을 비운 채 저장하면 그 배타가 깨진다.
 */
export function amountOf(b) {
  if (!b || b.qual_yn) return 0;
  const n = Number(b.benefit_amt);
  return Number.isFinite(n) && n > 0 ? n : 0;
}

/** 금액 출처 3값 — 회사 페이지·히트맵과 같은 어휘(`stated` 명시 / `est` 추정 / `qual` 금액 없음). */
export function amountKind(b) {
  if (!b) return 'qual';
  if (amountOf(b) <= 0) return 'qual';
  return b.amt_source === 'stated' ? 'stated' : 'est';
}

export function formatNumber(n) {
  return Number(n || 0).toLocaleString('ko-KR');
}

/** 코드 목록(Set·배열·deriveCodes 결과 객체) 안에 이 코드가 있나 — parseParams 검증용. */
function hasKey(known, key) {
  if (!known) return true;
  if (known instanceof Set) return known.has(key);
  if (Array.isArray(known)) return known.includes(key);
  return Object.prototype.hasOwnProperty.call(known, key);
}

// ── deriveCodes — 번들에서 「고를 수 있는 복지 항목」 목록을 만든다 ──────────
//
// 번들은 회사마다 복지 행을 들고 있을 뿐 **코드 사전을 싣지 않는다**. 같은 코드라도 회사마다
// 이름이 달라(`commute_subsidy` = 통근버스 / 셔틀버스 / 야근 교통비 …) 화면에 낼 대표 이름을
// 여기서 뽑는다: 대표 = 최빈 `benefit_nm`, 나머지는 별칭(검색어가 된다).

// 최빈값. 동률은 **코드포인트 순**으로 가른다 — `localeCompare('ko')` 가 아니다. 같은 규칙이
// `generator/pages/find.py::_most_common` 에도 있어야 하고(표와 칩이 같은 이름을 불러야 한다),
// 파이썬의 문자열 비교는 코드포인트다. ICU 한국어 정렬은 그것과 달라서 동률이 갈릴 때 두 쪽이
// **다른 대표 이름**을 고르게 된다 — 화면에서만 보이고 테스트로는 잘 안 잡히는 종류의 어긋남이다.
const byCodePoint = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

function mostCommon(counter) {
  return [...counter.entries()].sort((a, b) => b[1] - a[1] || byCodePoint(String(a[0]), String(b[0])))[0]?.[0];
}

/**
 * `ref` → `{ [benefit_cd]: {code, label, baseLabel, aliases, ctgr, count, amtCount} }`.
 *   · `label`   화면에 내는 이름(중복 해소 완료 — LABEL_OVERRIDE 또는 별칭 병기)
 *   · `aliases` 이 코드로 등장한 모든 `benefit_nm`(빈도순) — 검색 색인
 *   · `ctgr`    최빈 카테고리(`holiday_gift` 처럼 회사마다 다르게 넣은 코드가 있다)
 *   · `count`   그 코드를 가진 **회사 수**(행 수가 아니다 — 회사당 코드는 UNIQUE 라 같지만 명시)
 */
export function deriveCodes(ref) {
  const names = new Map(); // code → Map(benefit_nm → n)
  const ctgrs = new Map(); // code → Map(ctgr → n)
  const comps = new Map(); // code → Set(comp_id)
  const amts = new Map(); // code → 금액이 있는 회사 수
  for (const c of (ref && ref.companies) || []) {
    for (const b of c.benefits || []) {
      const cd = b && b.benefit_cd;
      if (!cd) continue; // BENEFIT_CD 는 NOT NULL 이다 — 없는 행은 조용히 건너뛴다(코드가 검색의 축)
      if (!names.has(cd)) { names.set(cd, new Map()); ctgrs.set(cd, new Map()); comps.set(cd, new Set()); amts.set(cd, 0); }
      const nm = names.get(cd);
      nm.set(b.benefit_nm, (nm.get(b.benefit_nm) || 0) + 1);
      const ct = ctgrs.get(cd);
      ct.set(b.benefit_ctgr_cd, (ct.get(b.benefit_ctgr_cd) || 0) + 1);
      comps.get(cd).add(c.comp_id);
      if (amountOf(b) > 0) amts.set(cd, amts.get(cd) + 1);
    }
  }
  const out = {};
  for (const [cd, nm] of names) {
    const baseLabel = mostCommon(nm) || cd;
    out[cd] = {
      code: cd,
      baseLabel,
      label: baseLabel,
      aliases: [...nm.entries()].sort((a, b) => b[1] - a[1] || byCodePoint(String(a[0]), String(b[0]))).map(([n]) => n),
      ctgr: mostCommon(ctgrs.get(cd)) || '',
      count: comps.get(cd).size,
      amtCount: amts.get(cd),
    };
  }
  return disambiguate(out);
}

/** 같은 `baseLabel` 을 가진 코드가 둘 이상이면 표시명을 갈라 준다(순수, deriveCodes 내부용 + 테스트). */
export function disambiguate(codes) {
  const byLabel = new Map();
  for (const info of Object.values(codes)) {
    if (!byLabel.has(info.baseLabel)) byLabel.set(info.baseLabel, []);
    byLabel.get(info.baseLabel).push(info);
  }
  for (const group of byLabel.values()) {
    if (group.length < 2) continue;
    for (const info of group) {
      if (LABEL_OVERRIDE[info.code]) { info.label = LABEL_OVERRIDE[info.code]; continue; }
      const alias = info.aliases.find((a) => a !== info.baseLabel);
      info.label = `${info.baseLabel} · ${alias || info.code}`;
    }
  }
  // 손으로 못 박은 이름은 중복이 아니어도 존중한다(구 코드 표시 등).
  for (const [cd, label] of Object.entries(LABEL_OVERRIDE)) if (codes[cd]) codes[cd].label = label;
  return codes;
}

/** 카테고리별 코드 목록 — 보유 회사 수 내림차순. 칩 줄과 비-JS 표가 같은 순서를 쓴다. */
export function codesByCategory(codes) {
  const out = {};
  for (const ct of CATEGORY_ORDER) out[ct] = [];
  for (const info of Object.values(codes)) {
    if (!out[info.ctgr]) out[info.ctgr] = [];
    out[info.ctgr].push(info);
  }
  for (const list of Object.values(out)) {
    list.sort((a, b) => b.count - a.count || a.label.localeCompare(b.label, 'ko'));
  }
  return out;
}

// ── URL ──────────────────────────────────────────────────────────────────────
// `/find?b=코드,코드&m=or&tp=large&ind=반도체&amt=1&sort=amt`
// 기본값은 URL 에 싣지 않는다 — 공유 링크가 짧아지고, 왕복(parse→build→parse)이 항등이 된다.

/**
 * 쿼리 문자열 → 상태. **알 수 없는 값은 조용히 기본값으로 떨어진다**(빈 화면 금지).
 * `known`(선택) = `{codes, types, industries}` — 있으면 그 목록에 없는 값을 버린다. 없는 회사 유형을
 * 링크로 받으면 결과 0건이 되는데, 사용자에게는 "조건을 잘못 골랐다"로 보이기 때문이다.
 */
export function parseParams(search, known = null) {
  const q = String(search ?? '');
  const params = new URLSearchParams(q.startsWith('?') ? q.slice(1) : q);
  const st = defaultState();
  const seen = new Set();
  for (const raw of (params.get('b') || '').split(',')) {
    const cd = raw.trim();
    if (!cd || seen.has(cd)) continue;
    if (known && known.codes && !hasKey(known.codes, cd)) continue;
    seen.add(cd);
    st.sel.push(cd);
  }
  const mode = params.get('m');
  if (MODES.includes(mode)) st.mode = mode;
  const tp = params.get('tp') || '';
  if (tp && (!known || !known.types || hasKey(known.types, tp))) st.tp = tp;
  const ind = params.get('ind') || '';
  if (ind && (!known || !known.industries || hasKey(known.industries, ind))) st.ind = ind;
  st.amt = params.get('amt') === '1';
  const sort = params.get('sort');
  if (SORT_KEYS.includes(sort)) st.sort = sort;
  return st;
}

/** 상태 → 쿼리 문자열(기본값은 생략). 조건이 하나도 없으면 빈 문자열. */
export function buildParams(state) {
  const st = { ...defaultState(), ...(state || {}) };
  const params = new URLSearchParams();
  if (Array.isArray(st.sel) && st.sel.length) params.set('b', st.sel.join(','));
  if (st.mode === 'or') params.set('m', 'or');
  if (st.tp) params.set('tp', st.tp);
  if (st.ind) params.set('ind', st.ind);
  if (st.amt) params.set('amt', '1');
  if (st.sort && st.sort !== 'match') params.set('sort', st.sort);
  // 쉼표는 쿼리 값에서 합법(RFC 3986 sub-delims)인데 URLSearchParams 는 %2C 로 굽는다 —
  // `?b=meal%2Cwelfare_point` 는 공유 링크로 읽히지 않는다. 되돌려도 왕복은 그대로다.
  const qs = params.toString().replace(/%2C/g, ',');
  return qs ? `?${qs}` : '';
}

// ── 매칭 ─────────────────────────────────────────────────────────────────────

/** 회사 한 곳의 `{코드: 복지행}`. 회사 안에서 코드는 UNIQUE(`uq_comp_benefit`)라 충돌이 없다. */
export function benefitsByCode(company) {
  const map = {};
  for (const b of (company && company.benefits) || []) if (b && b.benefit_cd && !map[b.benefit_cd]) map[b.benefit_cd] = b;
  return map;
}

/**
 * 조건에 맞는 회사 행 — `[{company, hits, byCode, amtSum, total}]`(정렬 전).
 *
 *   · `mode='and'`(기본) 고른 코드를 **전부** 가진 회사만. `'or'` 는 하나라도.
 *   · `tp`·`ind` 는 회사 축 필터라 조건이 없어도 걸린다.
 *   · `amt=true` = 「금액 적힌 항목만」 — 고른 항목 중 금액이 있는 것만 hit 로 세므로, AND 에서는
 *     **고른 항목 전부에 금액이 있는 회사**만 남는다(프로토타입 결정, SP-FIND-4). 고른 조건이
 *     없으면 셀 hit 자체가 없어 이 체크는 아무 일도 하지 않는다.
 */
export function matchCompanies(ref, codes, state = {}) {
  const sel = Array.isArray(codes) ? codes : [];
  const { mode = 'and', tp = '', ind = '', amt = false } = state;
  const out = [];
  for (const c of (ref && ref.companies) || []) {
    if (tp && c.comp_tp_cd !== tp) continue;
    if (ind && c.industry_nm !== ind) continue;
    const byCode = benefitsByCode(c);
    let hits = sel.map((cd) => byCode[cd]).filter(Boolean);
    if (amt) hits = hits.filter((b) => amountOf(b) > 0);
    if (sel.length) {
      if (mode === 'and' && hits.length < sel.length) continue;
      if (mode === 'or' && !hits.length) continue;
    }
    out.push({
      company: c,
      hits,
      byCode,
      amtSum: hits.reduce((s, b) => s + amountOf(b), 0),
      total: (c.benefits || []).length,
    });
  }
  return out;
}

/**
 * 정렬(사본 반환 — 원본 불변). 동률은 **언제나 회사명**으로 끝나 순서가 흔들리지 않는다.
 *   match  맞는 항목 수 → 금액 합 → 전체 항목 수 → 이름
 *   amt    금액 합 → 맞는 항목 수 → 이름
 *   total  전체 항목 수 → 이름
 *   name   이름
 */
export function sortRows(rows, key = 'match') {
  const name = (r) => String(r.company?.comp_nm ?? '');
  const byName = (x, y) => name(x).localeCompare(name(y), 'ko');
  const cmp = {
    match: (x, y) => y.hits.length - x.hits.length || y.amtSum - x.amtSum || y.total - x.total || byName(x, y),
    amt: (x, y) => y.amtSum - x.amtSum || y.hits.length - x.hits.length || byName(x, y),
    total: (x, y) => y.total - x.total || byName(x, y),
    name: byName,
  };
  return [...(rows || [])].sort(cmp[key] || cmp.match);
}

// ── 검색 제안 ────────────────────────────────────────────────────────────────

/**
 * 검색어 → `{codes: [코드정보 ≤8], companies: [회사 ≤5]}`.
 * 코드는 라벨·별칭·코드 id 를 다 훑고 **보유 회사 수 내림차순**(흔한 항목이 먼저 = 고를 값이 있다).
 * 회사는 정식명·별칭·영문 식별자를 훑는다. 빈 검색어는 양쪽 다 빈 배열(제안창을 열지 않는다).
 */
export function suggest(ref, codes, q) {
  const key = normalizeText(q);
  if (!key) return { codes: [], companies: [] };
  const hitCodes = Object.values(codes || {})
    .filter((i) => [i.label, i.baseLabel, ...(i.aliases || []), i.code].some((k) => normalizeText(k).includes(key)))
    .sort((a, b) => b.count - a.count || a.label.localeCompare(b.label, 'ko'))
    .slice(0, 8);
  const hitComps = ((ref && ref.companies) || [])
    .filter((c) => [c.comp_nm, c.comp_eng_nm, ...(c.aliases || [])].some((k) => normalizeText(k).includes(key)))
    .slice(0, 5);
  return { codes: hitCodes, companies: hitComps };
}

// ── 접힘 컨트롤러 ────────────────────────────────────────────────────────────
//
// 스크롤을 내리면 검색·조건 덱이 **한 줄(minibar)** 로 접히고, 맨 위로 돌아오면 펼쳐진다.
// 순진하게 구현하면 문턱 근처에서 무한 토글이 난다. 네 가지가 함께 있어야 조용하다:
//
//   ① `html { overflow-anchor: none }` — 브라우저의 스크롤 앵커링을 끈다. 켜져 있으면 브라우저도
//      우리도 같은 스크롤을 보정해 두 번 움직인다(CSS 쪽에 있다).
//   ② 접힘·펼침으로 **바뀐 높이만큼 스크롤을 직접 보정**해 화면 내용이 제자리에 남게 한다.
//   ③ 그 보정이 만든 scroll 이벤트는 **한 번 무시**한다(`suppress`). 안 그러면 보정이 또 판정을
//      부르고, 그 판정이 또 보정한다.
//   ④ 접힘 문턱을 「덱 위쪽 + 펼친 높이 + 8px」 밖에 둔다. 보정으로 되돌아간 위치(문턱 − 높이차)가
//      펼침 문턱(덱 위쪽 + 8px)보다 **항상 아래**여야 하기 때문이다. 이 여유가 없으면 접자마자
//      펼침 문턱 안으로 들어가 진동한다.
//
// `win` 을 주입받는 이유는 이 네 규칙을 DOM 없이 테스트하기 위해서다(가짜 window 로 느린 스크롤·
// 문턱 왕복·보정 후 위치·모바일 해제를 전부 검사한다).

const noopController = {
  measure() {}, onScroll() {}, setCollapsed() {}, setOpen() {},
  isCollapsed: () => false, isOpen: () => false, destroy() {}, ok: false,
};

function heightOf(node) {
  const rect = node && typeof node.getBoundingClientRect === 'function' ? node.getBoundingClientRect() : null;
  return rect ? rect.height || 0 : 0;
}

/**
 * 덱 접힘 배선. 반환 = 컨트롤러(`measure`·`onScroll`·`setCollapsed`·`setOpen`·`destroy`).
 * 요소가 하나라도 없으면 아무것도 하지 않는 컨트롤러를 돌려준다(마크업이 바뀌어도 페이지는 산다).
 *
 * @param {object}  o
 * @param {Element} o.wrap        `position:sticky` 인 덱 바깥 상자 — `collapsed`·`open` class 를 받는다
 * @param {Element} o.anchorEl    덱이 놓인 자리(문턱 계산 기준). 보통 덱을 감싼 섹션
 * @param {Element} o.minibar     접혔을 때 보이는 한 줄
 * @param {Element} o.expandBtn   한 줄에서 「검색·조건 바꾸기」
 * @param {Element} o.collapseBtn 임시로 펼친 상태에서 「접기」
 * @param {Window}  [o.win]       주입점(테스트용 가짜 window)
 */
export function initDeckCollapse({ wrap, anchorEl, minibar, expandBtn, collapseBtn, win = globalThis } = {}) {
  if (!wrap || !anchorEl || !minibar || !expandBtn || !collapseBtn || !win) return noopController;

  let anchorTop = 0; // 덱 위쪽의 문서 절대 좌표
  let expandedH = 0; // 펼친 덱의 높이(접힌 동안에는 마지막으로 잰 값을 유지한다)
  let suppress = 0; // 우리가 만든 스크롤 이벤트를 무시할 횟수(위 ③)
  let ticking = false;

  const isCollapsed = () => wrap.classList.contains('collapsed');
  const isOpen = () => wrap.classList.contains('open');

  /** 문턱을 다시 잰다. 조건이 바뀌어 덱 높이가 달라질 때마다(= 매 렌더) 호출한다. */
  function measure() {
    anchorTop = anchorEl.getBoundingClientRect().top + win.scrollY;
    if (!isCollapsed()) expandedH = heightOf(wrap);
  }

  /** 높이 변화만큼 스크롤을 보정하고, 그 보정이 만들 scroll 이벤트 1회를 예약 무시한다. */
  function compensate(delta) {
    if (!delta) return;
    suppress += 1;
    win.scrollBy(0, delta);
  }

  function setCollapsed(on) {
    if (on === isCollapsed()) return;
    const before = heightOf(wrap);
    wrap.classList.toggle('collapsed', on);
    wrap.classList.remove('open'); // 임시로 펼쳐 둔 상태는 상태 전환과 함께 걷는다
    collapseBtn.hidden = true;
    minibar.hidden = !on;
    expandBtn.setAttribute('aria-expanded', 'false');
    // 덱 **위쪽보다 아래**를 보고 있을 때만 보정한다 — 맨 위에서는 아래 내용이 올라오는 게 자연스럽다
    if (win.scrollY > anchorTop) compensate(heightOf(wrap) - before);
  }

  /** 접힌 상태에서 덱을 임시로 펼친다(스크롤 위치는 그대로 두고 내용만 밀어낸다). */
  function setOpen(on) {
    if (!isCollapsed()) return;
    const before = heightOf(wrap);
    wrap.classList.toggle('open', on);
    collapseBtn.hidden = !on;
    expandBtn.setAttribute('aria-expanded', on ? 'true' : 'false');
    compensate(heightOf(wrap) - before);
  }

  /** 좁은 화면에서는 고정도 접힘도 없다 — 덱이 그냥 문서의 일부다(CSS 와 같은 경계). */
  function releaseForMobile() {
    if (!isCollapsed() && !isOpen()) return;
    wrap.classList.remove('collapsed', 'open');
    collapseBtn.hidden = true;
    minibar.hidden = true;
    expandBtn.setAttribute('aria-expanded', 'false');
  }

  function evaluate() {
    if (suppress > 0) { suppress -= 1; return; } // 우리가 만든 스크롤(위 ③)
    if (win.innerWidth < DESKTOP_MIN) { releaseForMobile(); return; }
    const y = win.scrollY;
    if (!isCollapsed() && y > anchorTop + expandedH + 8) setCollapsed(true);
    else if (isCollapsed() && y <= anchorTop + 8) setCollapsed(false);
  }

  function onScroll() {
    if (ticking) return;
    ticking = true;
    const run = () => { ticking = false; evaluate(); };
    if (typeof win.requestAnimationFrame === 'function') win.requestAnimationFrame(run);
    else run();
  }

  const onResize = () => { measure(); onScroll(); };
  const onExpand = () => setOpen(true);
  const onCollapse = () => setOpen(false);

  win.addEventListener('scroll', onScroll, { passive: true });
  win.addEventListener('resize', onResize);
  expandBtn.addEventListener('click', onExpand);
  collapseBtn.addEventListener('click', onCollapse);
  measure();
  onScroll();

  return {
    measure,
    onScroll,
    setCollapsed,
    setOpen,
    isCollapsed,
    isOpen,
    ok: true,
    destroy() {
      win.removeEventListener('scroll', onScroll);
      win.removeEventListener('resize', onResize);
      expandBtn.removeEventListener('click', onExpand);
      collapseBtn.removeEventListener('click', onCollapse);
    },
  };
}

// ── 렌더 ─────────────────────────────────────────────────────────────────────
// 전부 `dom.js::el`(textContent·setAttribute)로만 만든다. 회사명에 `&`(삼성E&A)·`<` 가 들어올 수
// 있고, 복지 설명은 회사가 쓴 자유 문장이다 — 데이터 문자열이 innerHTML 에 닿는 경로가 없어야 한다.

const AMOUNT_TAG = { stated: '명시', est: '추정' };

/** 조건 칩 하나. `removable` 이면 × 를 붙인다(고른 조건 줄). */
export function renderChip(info, { on = false, removable = false, onToggle } = {}) {
  const btn = el('button', {
    type: 'button',
    class: `find-chip${on ? ' on' : ''}`,
    'aria-pressed': on ? 'true' : 'false',
    title: info.aliases && info.aliases.length > 1 ? `다른 이름: ${info.aliases.slice(0, 4).join(' · ')}` : null,
  });
  btn.append(el('span', { class: 'find-chip-nm', text: info.label }));
  btn.append(el('small', { class: 'num', text: String(info.count) }));
  if (removable) btn.append(el('span', { class: 'find-chip-x', 'aria-hidden': 'true', text: '×' }));
  if (onToggle) btn.addEventListener('click', () => onToggle(info.code));
  return btn;
}

/** 금액 칸 — 「연 240만원 명시」 / 「금액 미기재 조건형」. 추정치를 명시처럼 보이게 하지 않는다. */
export function renderAmount(b) {
  const wrap = el('span', { class: 'find-amt' });
  const kind = amountKind(b);
  if (kind === 'qual') {
    wrap.append(el('span', { text: '금액 미기재' }));
    wrap.append(el('span', { class: 'find-tag find-tag-ql', text: '조건형' }));
    return wrap;
  }
  wrap.append(el('b', { class: 'num', text: `연 ${formatNumber(amountOf(b))}만원` }));
  wrap.append(el('span', { class: `find-tag find-tag-${kind}`, text: AMOUNT_TAG[kind] }));
  return wrap;
}

/** 복지 한 건의 설명 한 줄 — 조건 문장이 있으면 그것, 없으면 비고, 둘 다 없으면 `—`. */
export function benefitNote(b) {
  return (b && (b.qual_desc_ctnt || b.note_ctnt)) || '—';
}

/**
 * 결과 행 하나. 고른 조건이 있으면 **그 항목들**을(없는 회사는 OR 모드에서 「없음」으로),
 * 없으면 금액 큰 항목 3개를 보여준다 — 해시태그가 아니라 실제 명칭·금액·조건이 근거다.
 */
export function renderRow(row, { codes = {}, sel = [], types = {}, compare = null, onCompare = null } = {}) {
  const c = row.company;
  const slug = slugOf(c.comp_eng_nm);
  const href = slug ? `/company/${slug}` : null;

  const title = el('div', { class: 'find-row-ttl' });
  // slug 를 만들 수 없는 회사는 링크를 만들지 않는다(404 로 가는 링크는 링크 없는 것보다 나쁘다).
  title.append(href ? el('a', { href, text: c.comp_nm }) : el('span', { class: 'find-row-nm', text: c.comp_nm }));
  const tpName = types[c.comp_tp_cd];
  if (tpName) title.append(el('span', { class: 'find-tp', text: tpName }));
  title.append(el('span', {
    class: 'find-row-meta',
    text: [c.industry_nm, `복지 ${row.total}개`].filter(Boolean).join(' · '),
  }));

  const hits = el('ul', { class: 'find-hits' });
  const shown = sel.length
    ? sel.map((cd) => ({ cd, b: row.byCode[cd] }))
    : (c.benefits || []).filter((b) => amountOf(b) > 0).sort((x, y) => amountOf(y) - amountOf(x)).slice(0, 3)
      .map((b) => ({ cd: b.benefit_cd, b }));
  for (const { cd, b } of shown) {
    const li = el('li', { class: 'find-hit' });
    if (!b) {
      li.append(el('span', { class: 'find-hit-k dim', text: (codes[cd] && codes[cd].label) || cd }));
      li.append(el('span', { class: 'find-amt', text: '없음' }));
      li.append(el('span', { class: 'find-hit-d', text: '이 회사 페이지에 해당 항목이 없습니다' }));
    } else {
      li.append(el('span', { class: 'find-hit-k', text: b.benefit_nm }));
      li.append(renderAmount(b));
      li.append(el('span', { class: 'find-hit-d', title: benefitNote(b), text: benefitNote(b) }));
    }
    hits.append(li);
  }
  if (!shown.length) {
    const li = el('li', { class: 'find-hit' });
    li.append(el('span', { class: 'find-hit-k dim', text: '금액 적힌 항목 없음' }));
    li.append(el('span', { class: 'find-amt', text: `조건형 ${row.total}개` }));
    li.append(el('span', {
      class: 'find-hit-d',
      text: (c.benefits || []).slice(0, 4).map((b) => b.benefit_nm).join(' · ') || '등록된 복지 없음',
    }));
    hits.append(li);
  }

  const act = el('div', { class: 'find-act' });
  for (const slot of ['A', 'B']) {
    const other = slot === 'A' ? 'B' : 'A';
    const picked = compare && compare[slot] === c.comp_id;
    const taken = compare && compare[other] === c.comp_id; // 같은 회사를 A·B 로 둘 다 고를 수 없다
    const btn = el('button', {
      type: 'button',
      class: `find-pick${picked ? ' on' : ''}`,
      'aria-pressed': picked ? 'true' : 'false',
      title: taken ? `이미 ${other}로 고른 회사입니다` : null,
    });
    btn.textContent = `비교 ${slot}${picked ? ' ✓' : ''}`;
    if (taken) btn.disabled = true;
    else if (onCompare) btn.addEventListener('click', () => onCompare(slot, c.comp_id));
    act.append(btn);
  }
  if (href) act.append(el('a', { class: 'find-go', href, text: '회사 페이지 →' }));

  const body = el('div', { class: 'find-row-body' });
  body.append(title, hits);
  const logo = el('div', { class: 'find-logo', 'aria-hidden': 'true', text: c.logo_nm || (c.comp_nm || '·').slice(0, 1) });
  return el('div', { class: 'find-row' }, logo, body, act);
}

/** 보유율 막대 — 「고른 조건이 얼마나 흔한가」. 분모(전체 회사 수)를 숨기지 않는다. */
export function renderMeter(info, total) {
  const pct = total ? Math.round((info.count / total) * 100) : 0;
  const wrap = el('div', { class: 'find-meter' });
  wrap.append(el('span', { class: 'find-meter-l', title: info.label, text: info.label }));
  const track = el('div', { class: 'find-meter-tr' });
  track.append(el('div', { class: 'find-meter-fi', style: `width:${pct}%` }));
  wrap.append(track);
  wrap.append(el('span', { class: 'find-meter-v num', text: `${info.count}곳 · ${pct}%` }));
  return wrap;
}

// ── 페이지 배선 ──────────────────────────────────────────────────────────────

const pick = (root, sel) => root.querySelector(sel);

/**
 * 도구를 마운트한다(동기 — 번들은 이미 받은 상태). 반환 = `{ render, state, destroy }` 또는 null.
 * `initFind` 가 번들을 받아 이걸 부르고, 테스트는 픽스처 번들로 직접 부른다.
 */
export function mountFind(root, ref, opts = {}) {
  // 브라우저에서는 `globalThis === window` 지만 테스트(node)에서는 아니다 — jsdom 이 심어 둔
  // `globalThis.window` 를 먼저 본다. 이게 없으면 스크롤 배선이 부팅 자체를 깨뜨린다.
  const win = opts.win || globalThis.window || globalThis;
  const history = opts.history || win.history;
  if (!root || !ref) return null;
  const codes = deriveCodes(ref);
  const byCat = codesByCategory(codes);
  const companies = (ref && ref.companies) || [];
  const types = Object.fromEntries((ref.company_types || []).map((t) => [t.comp_tp_cd, t.comp_tp_nm]));
  const industries = [...new Set(companies.map((c) => c.industry_nm).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'ko'));
  const total = companies.length;

  const state = parseParams(win.location ? win.location.search : '', { codes, types, industries });
  let cat = state.sel.length ? (codes[state.sel[state.sel.length - 1]] || {}).ctgr || DEFAULT_CATEGORY : DEFAULT_CATEGORY;
  let shown = PAGE_SIZE;
  const compare = { A: null, B: null };

  const $ = (s) => pick(root, s);
  const nodes = {
    q: $('[data-q]'), sugg: $('[data-sugg]'), sel: $('[data-sel]'), selCount: $('[data-sel-count]'),
    tabs: $('[data-tabs]'), chips: $('[data-chips]'), chipHint: $('[data-chip-hint]'),
    tp: $('[data-facet-tp]'), ind: $('[data-facet-ind]'), amt: $('[data-facet-amt]'), reset: $('[data-reset]'),
    count: $('[data-count]'), countSub: $('[data-count-sub]'), desc: $('[data-desc]'),
    meters: $('[data-meters]'), range: $('[data-range]'), sort: $('[data-sort]'),
    list: $('[data-list]'), more: $('[data-more]'), empty: $('[data-empty]'),
    cmp: $('[data-cmp]'), cmpA: $('[data-cmp-a]'), cmpB: $('[data-cmp-b]'), cmpLink: $('[data-cmp-link]'),
    minibar: $('[data-minibar]'), miniCount: $('[data-minibar-count]'), miniSub: $('[data-minibar-sub]'),
    miniSel: $('[data-minibar-sel]'), miniMode: $('[data-minibar-mode]'), miniSort: $('[data-minibar-sort]'),
    deck: $('[data-deck]'), expand: $('[data-expand]'), collapse: $('[data-collapse]'),
  };

  // 유형·업종 select 는 **있는 값만** 채운다(0곳짜리 선택지는 막다른 길이다).
  for (const [cd, nm] of Object.entries(types)) {
    const n = companies.filter((c) => c.comp_tp_cd === cd).length;
    if (n && nodes.tp) nodes.tp.append(el('option', { value: cd, text: `${nm} · ${n}` }));
  }
  for (const ind of industries) {
    const n = companies.filter((c) => c.industry_nm === ind).length;
    if (nodes.ind) nodes.ind.append(el('option', { value: ind, text: `${ind} · ${n}` }));
  }
  if (nodes.tp) nodes.tp.value = state.tp;
  if (nodes.ind) nodes.ind.value = state.ind;
  if (nodes.amt) nodes.amt.checked = state.amt;
  if (nodes.sort) nodes.sort.value = state.sort;
  if (nodes.miniSort) nodes.miniSort.value = state.sort;

  function syncUrl() {
    try { history.replaceState(null, '', '/find' + buildParams(state)); } catch { /* 무시 */ }
  }

  function toggleCode(cd) {
    const i = state.sel.indexOf(cd);
    if (i >= 0) state.sel.splice(i, 1);
    else { state.sel.push(cd); cat = (codes[cd] || {}).ctgr || cat; }
    shown = PAGE_SIZE;
    render();
  }

  function onCompare(slot, compId) {
    compare[slot] = compare[slot] === compId ? null : compId;
    render();
  }

  function renderTabs() {
    if (!nodes.tabs) return;
    nodes.tabs.replaceChildren();
    for (const ct of CATEGORY_ORDER) {
      const list = byCat[ct] || [];
      if (!list.length) continue;
      const nSel = list.filter((i) => state.sel.includes(i.code)).length;
      const btn = el('button', {
        type: 'button', role: 'tab', class: `find-tab${cat === ct ? ' on' : ''}`,
        'aria-selected': cat === ct ? 'true' : 'false',
      });
      btn.append(root.ownerDocument.createTextNode(CATEGORY_LABEL[ct] || ct));
      btn.append(el('small', { class: 'num', text: String(list.length) }));
      if (nSel) btn.append(el('span', { class: 'find-tab-dot', title: `고른 조건 ${nSel}개` }));
      btn.addEventListener('click', () => { cat = ct; render(); });
      nodes.tabs.append(btn);
    }
    if (nodes.chips) {
      nodes.chips.replaceChildren();
      for (const info of byCat[cat] || []) {
        nodes.chips.append(renderChip(info, { on: state.sel.includes(info.code), onToggle: toggleCode }));
      }
    }
    if (nodes.chipHint) nodes.chipHint.textContent = `${CATEGORY_LABEL[cat] || cat} · 숫자는 보유 회사 수`;
  }

  function renderSelected() {
    for (const [box, mini] of [[nodes.sel, false], [nodes.miniSel, true]]) {
      if (!box) continue;
      box.replaceChildren();
      if (!state.sel.length) {
        box.append(el('span', {
          class: 'find-sel-empty',
          text: mini ? '조건 없음 — 전체' : '없음 — 검색하거나 아래 항목을 누르면 조건이 됩니다.',
        }));
        continue;
      }
      for (const cd of state.sel) {
        const info = codes[cd] || { code: cd, label: cd, count: 0, aliases: [] };
        box.append(renderChip(info, { on: true, removable: true, onToggle: toggleCode }));
      }
    }
    if (nodes.selCount) nodes.selCount.textContent = state.sel.length ? `${state.sel.length}개` : '';
    for (const btn of root.querySelectorAll('[data-mode]')) {
      const on = btn.dataset.mode === state.mode;
      btn.classList.toggle('on', on);
      btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    }
    if (nodes.miniMode) {
      nodes.miniMode.textContent = state.sel.length > 1 ? (state.mode === 'and' ? '모두 갖춘' : '하나라도') : '';
    }
  }

  function describe() {
    if (!state.sel.length) return '조건이 없으면 전체 회사가 나옵니다 — 항목 수와 금액 큰 항목으로 훑어보는 상태입니다.';
    const base = state.mode === 'and'
      ? `고른 ${state.sel.length}개 조건을 모두 갖춘 회사`
      : '고른 조건 중 하나라도 있는 회사';
    return [base, state.amt ? '금액 적힌 항목만 인정' : '', types[state.tp] || '', state.ind || '']
      .filter(Boolean).join(' · ');
  }

  function renderSummary(n) {
    if (nodes.count) nodes.count.textContent = formatNumber(n);
    if (nodes.countSub) nodes.countSub.textContent = ` / ${formatNumber(total)} 회사`;
    if (nodes.miniCount) nodes.miniCount.textContent = formatNumber(n);
    if (nodes.miniSub) nodes.miniSub.textContent = ` / ${formatNumber(total)}`;
    if (nodes.desc) nodes.desc.textContent = describe();
    if (nodes.range) nodes.range.textContent = n ? `1–${Math.min(shown, n)} / ${formatNumber(n)}개 표시` : '';
    if (!nodes.meters) return;
    nodes.meters.replaceChildren();
    const list = state.sel.length
      ? state.sel.map((cd) => codes[cd]).filter(Boolean)
      : Object.values(codes).sort((a, b) => b.count - a.count).slice(0, 4);
    if (!state.sel.length) nodes.meters.append(el('span', { class: 'find-meter-hint', text: '흔한 항목 4개 보유율' }));
    for (const info of list) nodes.meters.append(renderMeter(info, total));
  }

  function renderCompare() {
    if (!nodes.cmp) return;
    const a = companies.find((c) => c.comp_id === compare.A);
    const b = companies.find((c) => c.comp_id === compare.B);
    nodes.cmp.hidden = !(a || b);
    if (nodes.cmpA) nodes.cmpA.textContent = a ? a.comp_nm : '고르는 중';
    if (nodes.cmpB) nodes.cmpB.textContent = b ? b.comp_nm : '고르는 중';
    if (!nodes.cmpLink) return;
    if (a && b) {
      nodes.cmpLink.setAttribute('href', `/?a=${encodeURIComponent(a.comp_eng_nm)}&b=${encodeURIComponent(b.comp_eng_nm)}`);
      nodes.cmpLink.textContent = `${a.comp_nm} vs ${b.comp_nm} 비교하기 →`;
      nodes.cmpLink.hidden = false;
    } else {
      nodes.cmpLink.hidden = true; // 한 곳만 고른 상태에서 누르면 입력 뷰로 떨어진다(비교 툴 규약)
    }
  }

  function renderSuggest() {
    if (!nodes.sugg) return;
    const res = suggest(ref, codes, nodes.q ? nodes.q.value : '');
    nodes.sugg.replaceChildren();
    if (!res.codes.length && !res.companies.length) {
      if (!normalizeText(nodes.q ? nodes.q.value : '')) { nodes.sugg.hidden = true; return; }
      nodes.sugg.append(el('p', { class: 'find-sugg-none', text: '맞는 복지 항목이나 회사가 없습니다. 다른 말로 찾아보세요(예: 기숙사 → 사택).' }));
      nodes.sugg.hidden = false;
      return;
    }
    if (res.codes.length) {
      nodes.sugg.append(el('h3', { text: '복지 항목 — 조건에 추가' }));
      for (const info of res.codes) {
        const btn = el('button', { type: 'button', class: 'find-sugg-item' });
        btn.append(el('span', { text: info.label }));
        btn.append(el('small', { text: `${CATEGORY_LABEL[info.ctgr] || ''} · ${info.count}곳` }));
        btn.addEventListener('click', () => {
          if (nodes.q) nodes.q.value = '';
          nodes.sugg.hidden = true;
          toggleCode(info.code);
        });
        nodes.sugg.append(btn);
      }
    }
    if (res.companies.length) {
      nodes.sugg.append(el('h3', { text: '회사 — 회사 페이지로' }));
      for (const c of res.companies) {
        const slug = slugOf(c.comp_eng_nm);
        const item = slug
          ? el('a', { class: 'find-sugg-item', href: `/company/${slug}` })
          : el('span', { class: 'find-sugg-item' });
        item.append(el('span', { text: c.comp_nm }));
        item.append(el('small', { text: `${c.industry_nm || ''} · 복지 ${(c.benefits || []).length}개` }));
        nodes.sugg.append(item);
      }
    }
    nodes.sugg.hidden = false;
  }

  let collapse = null;

  function render() {
    renderTabs();
    renderSelected();
    const rows = sortRows(matchCompanies(ref, state.sel, state), state.sort);
    renderSummary(rows.length);
    if (nodes.list) {
      nodes.list.replaceChildren();
      for (const row of rows.slice(0, shown)) {
        nodes.list.append(renderRow(row, { codes, sel: state.sel, types, compare, onCompare }));
      }
    }
    if (nodes.empty) nodes.empty.hidden = rows.length > 0;
    if (nodes.more) {
      nodes.more.hidden = rows.length <= shown;
      nodes.more.textContent = `더 보기 (${Math.max(0, rows.length - shown)}개 남음)`;
    }
    renderCompare();
    syncUrl();
    if (collapse) collapse.measure(); // 덱 높이가 바뀌었을 수 있다 → 문턱 다시 재기
  }

  // ── 이벤트 ──
  if (nodes.q) {
    nodes.q.addEventListener('input', renderSuggest);
    nodes.q.addEventListener('keydown', (ev) => {
      if (ev.key === 'Enter') { const first = nodes.sugg && nodes.sugg.querySelector('button'); if (first) first.click(); }
      if (ev.key === 'Escape' && nodes.sugg) nodes.sugg.hidden = true;
    });
  }
  root.ownerDocument.addEventListener('click', (ev) => {
    if (nodes.sugg && ev.target && typeof ev.target.closest === 'function' && !ev.target.closest('.find-search')) {
      nodes.sugg.hidden = true;
    }
  });
  for (const btn of root.querySelectorAll('[data-mode]')) {
    btn.addEventListener('click', () => { state.mode = btn.dataset.mode; shown = PAGE_SIZE; render(); });
  }
  if (nodes.tp) nodes.tp.addEventListener('change', () => { state.tp = nodes.tp.value; shown = PAGE_SIZE; render(); });
  if (nodes.ind) nodes.ind.addEventListener('change', () => { state.ind = nodes.ind.value; shown = PAGE_SIZE; render(); });
  if (nodes.amt) nodes.amt.addEventListener('change', () => { state.amt = !!nodes.amt.checked; shown = PAGE_SIZE; render(); });
  for (const s of [nodes.sort, nodes.miniSort]) {
    if (!s) continue;
    s.addEventListener('change', () => {
      state.sort = SORT_KEYS.includes(s.value) ? s.value : 'match';
      if (nodes.sort) nodes.sort.value = state.sort;
      if (nodes.miniSort) nodes.miniSort.value = state.sort;
      render();
    });
  }
  if (nodes.more) nodes.more.addEventListener('click', () => { shown += PAGE_SIZE; render(); });
  if (nodes.reset) {
    nodes.reset.addEventListener('click', () => {
      Object.assign(state, defaultState());
      shown = PAGE_SIZE;
      if (nodes.tp) nodes.tp.value = '';
      if (nodes.ind) nodes.ind.value = '';
      if (nodes.amt) nodes.amt.checked = false;
      if (nodes.sort) nodes.sort.value = 'match';
      if (nodes.miniSort) nodes.miniSort.value = 'match';
      if (nodes.q) nodes.q.value = '';
      if (nodes.sugg) nodes.sugg.hidden = true;
      render();
    });
  }

  // 브라우저 스크롤 앵커링을 끈다 — 접힘·펼침 보정과 겹치면 화면이 두 번 움직인다. CSS 가 아니라
  // 여기서 붙이는 이유: 필요한 것은 **이 페이지에서 JS 가 켜졌을 때**뿐이고, html 전역 규칙으로
  // 두면 다른 페이지의 스크롤 동작까지 바뀐다.
  const html = root.ownerDocument && root.ownerDocument.documentElement;
  if (html && html.style) html.style.overflowAnchor = 'none';

  render();
  collapse = initDeckCollapse({
    wrap: nodes.deck, anchorEl: root, minibar: nodes.minibar,
    expandBtn: nodes.expand, collapseBtn: nodes.collapse, win,
  });
  return { render, state, codes, collapse, destroy() { if (collapse) collapse.destroy(); } };
}

/** 페이지 진입 — 번들을 받아 도구를 켠다. 실패해도 정적 본문(카테고리 표)은 그대로 남는다. */
export async function initFind(doc = globalThis.document, loader = null) {
  const root = doc && doc.querySelector('[data-find-tool]');
  if (!root) return null;
  const load = loader || (await import('./boot.js')).loadReference;
  let ref;
  try {
    ref = await load();
  } catch {
    const err = doc.querySelector('[data-find-error]');
    if (err) err.hidden = false;
    return null;
  }
  root.hidden = false;
  return mountFind(root, ref);
}

if (typeof document !== 'undefined' && document.querySelector('[data-find-tool]')) initFind();
