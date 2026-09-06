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
export const MOBILE_MAX = 900; // 이 폭 이하에서는 덱을 고정하지도 접지도 않는다(CSS 와 같은 경계)

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

function mostCommon(counter) {
  return [...counter.entries()].sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0]), 'ko'))[0]?.[0];
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
      aliases: [...nm.entries()].sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0]), 'ko')).map(([n]) => n),
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
  const qs = params.toString();
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
