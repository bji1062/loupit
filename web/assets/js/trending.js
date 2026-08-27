// web/assets/js/trending.js — "많이 찾아본 조합" 우측 위젯 + 익명 비교 로그 전송.
//
// 데이터: GET /api/v1/comparisons/trending (최근 7일 회사쌍 COUNT 상위 10, INV-1 개정
// 2026-07-14). 전송: POST /api/v1/comparisons/log — 회사쌍 comp_id만(사용자 식별자·
// 연봉 등 입력값 절대 미전송; 직접 입력 모드 쌍은 전송 자체를 하지 않는다).
//
// ── 콜드스타트(2026-07-31) ──────────────────────────────────────────────────
// 집계가 비면 위젯은 **숨는 대신 폴백 조합을 보여준다**. 이전 판본은 집계 0건 → hidden
// 이었는데, 실제로 그 일이 일어났다: 마지막 로그가 2026-07-20, 7일 윈도우가 07-27에
// 비면서 위젯이 통째로 화면에서 사라졌다(레일 공백 + GNB 앵커가 죽은 링크로 남음).
// 폴백은 서버 집계가 아니라 **REF 번들의 같은 업종 묶음**이라 인기를 지어내지 않는다 —
// 제목·캡션이 두 모드를 명시적으로 구분한다(집계 있음: "많이 찾아본 조합 TOP 10" /
// 폴백: "이렇게 비교해 보세요"). 집계가 쌓이면 자동으로 원래 모드로 돌아온다.
//
// 동작: 접힘 상태에서 1~10위를 ROTATE_MS 간격 순차 롤링, 마우스 호버/키보드 포커스 시
// 전체 목록 펼침(.trend-expanded). **호버가 없는 기기(터치)는 롤링 없이 처음부터 펼친다**
// (2026-08-27 오조준 수정 — 아래 isHoverless 주석). 클릭 → onPick(item)
// (배선은 app.js 소유 — 양 슬롯 프리필). 위젯 실패는 비교 툴에 무해해야 한다(광고 MON6과 동일 원칙): fetch 실패·
// 빈 목록·host 부재 → 폴백 시도 후에도 빈손이면 host hidden 유지, throw 없음.
import { el } from './dom.js';

export const ROTATE_MS = 3000;
export const TRENDING_URL = '/api/v1/comparisons/trending';
export const COMPARE_LOG_URL = '/api/v1/comparisons/log';
const MAX_ITEMS = 10;

// 모드별 문안. 폴백은 집계가 아니므로 "TOP"·"인기"를 쓰지 않는다(과장 금지).
export const TRENDING_TITLE = '많이 찾아본 조합 TOP 10';
export const TRENDING_CAPTION = '현재 직장(A) vs 이직 후보(B)';
export const SUGGEST_TITLE = '이렇게 비교해 보세요';
export const SUGGEST_CAPTION = '같은 업종끼리 묶었습니다';

// ── 순수: 응답 shape 검증(무효 필터·10개 캡). 손상 입력 → [] ────────────────
export function parseTrending(data) {
  if (!data || !Array.isArray(data.items)) return [];
  const out = [];
  for (const it of data.items) {
    if (!it || typeof it !== 'object') continue;
    if (!Number.isInteger(it.a_comp_id) || !Number.isInteger(it.b_comp_id)) continue;
    if (typeof it.a_comp_nm !== 'string' || !it.a_comp_nm.trim()) continue;
    if (typeof it.b_comp_nm !== 'string' || !it.b_comp_nm.trim()) continue;
    out.push({
      a_comp_id: it.a_comp_id, a_comp_nm: it.a_comp_nm,
      b_comp_id: it.b_comp_id, b_comp_nm: it.b_comp_nm,
      cnt: Number.isFinite(it.cnt) ? it.cnt : 0,
    });
    if (out.length >= MAX_ITEMS) break;
  }
  return out;
}

// ── 순수: 콜드스타트 폴백 조합(REF 번들 → 같은 업종 쌍) ──────────────────────
// 서버 집계가 아니라 번들에 이미 있는 industry_nm 묶음이다 — "인기"가 아니라 "제안".
// 결정론적이어야 한다(Math.random 금지): 같은 번들이면 새로고침해도 같은 목록이 나와야
// 사용자가 방금 본 조합을 다시 찾을 수 있고, 테스트도 고정할 수 있다.
//   1. industry_nm 별로 묶고(빈 값·1개짜리 업종 제외)
//   2. 업종 내부는 comp_id 오름차순으로 인접 2개씩 짝지어(0-1, 2-3, …)
//   3. 업종을 (회사 수 내림차순, 업종명 오름차순)으로 정렬한 뒤 라운드로빈으로 뽑는다
//      — 한 업종이 목록을 독식하지 않게 한다(게임 7곳이 3쌍을 연속 차지하는 것 방지).
export function fallbackPairs(companies, limit = MAX_ITEMS) {
  if (!Array.isArray(companies)) return [];
  const groups = new Map();
  for (const c of companies) {
    if (!c || typeof c !== 'object') continue;
    if (!Number.isInteger(c.comp_id)) continue;
    if (typeof c.comp_nm !== 'string' || !c.comp_nm.trim()) continue;
    const ind = typeof c.industry_nm === 'string' ? c.industry_nm.trim() : '';
    if (!ind) continue; // 업종 미상 → 묶을 근거가 없다
    if (!groups.has(ind)) groups.set(ind, []);
    groups.get(ind).push(c);
  }

  const buckets = [...groups.entries()]
    .filter(([, cs]) => cs.length >= 2) // 혼자인 업종은 쌍을 못 만든다
    .sort((x, y) => (y[1].length - x[1].length) || (x[0] < y[0] ? -1 : x[0] > y[0] ? 1 : 0))
    .map(([, cs]) => {
      const sorted = [...cs].sort((p, q) => p.comp_id - q.comp_id);
      const pairs = [];
      for (let i = 0; i + 1 < sorted.length; i += 2) {
        pairs.push({
          a_comp_id: sorted[i].comp_id, a_comp_nm: sorted[i].comp_nm,
          b_comp_id: sorted[i + 1].comp_id, b_comp_nm: sorted[i + 1].comp_nm,
          cnt: 0, // 폴백은 집계값이 없다(0) — 화면에도 노출하지 않는다
        });
      }
      return pairs;
    });

  const out = [];
  const cap = Number.isInteger(limit) && limit > 0 ? limit : MAX_ITEMS;
  for (let round = 0; out.length < cap; round += 1) {
    let took = false;
    for (const pairs of buckets) {
      if (round >= pairs.length) continue;
      out.push(pairs[round]);
      took = true;
      if (out.length >= cap) break;
    }
    if (!took) break; // 모든 업종 소진
  }
  return out;
}

export function nextIndex(i, len) { // 순차 롤링 순환
  return len > 0 ? (i + 1) % len : 0;
}

export function pairLabel(item) {
  return item.a_comp_nm + ' vs ' + item.b_comp_nm;
}

// ── 순수: 익명 로그 페이로드 — 양 슬롯 모두 회사 매칭일 때만(FR-07 예외 한정) ──
export function compareLogPayload(state) {
  const a = state && state.matched && state.matched.a;
  const b = state && state.matched && state.matched.b;
  if (!a || !b || !Number.isInteger(a.comp_id) || !Number.isInteger(b.comp_id)) return null; // 직접 입력 제외
  if (a.comp_id === b.comp_id) return null;
  return { a: a.comp_id, b: b.comp_id };
}

// ── 세션 내 중복 제거(2026-07-31) ───────────────────────────────────────────
// 기록 시점을 "비교하기 성공"에서 "양 슬롯 확정"으로 낮추면(app.js onPairReady) 같은 쌍이
// 한 세션에서 여러 번 발사된다: 슬롯을 바꿨다 되돌리기, 입력 수정 후 재비교, 리포트 왕복.
// 그대로 두면 B-7(집계 부풀림)이 그대로 재현된다 — 실제로 지금 DB 최다 조합인
// "CJ올리브네트웍스 vs DB손해보험 22회"가 한 사람의 반복 클릭이 만든 숫자다.
// 페이지 수명 동안 쌍당 1회만 보낸다(사용자가 다르면 세션이 달라 정상 집계된다).
const _sentPairs = new Set();
const pairKey = (p) => p.a + ':' + p.b;

export function resetSentPairs() { _sentPairs.clear(); } // 테스트 격리용

// 양 슬롯이 회사로 확정되면 1회 전송(fire-and-forget). 실패는 조용히 무시 — 비교 리포트 무손상.
export function sendCompareLog(state, { beaconFn, fetchFn } = {}) {
  const payload = compareLogPayload(state);
  if (!payload) return false;
  const key = pairKey(payload);
  if (_sentPairs.has(key)) return false; // 이 세션에서 이미 보낸 쌍 — 재전송하지 않는다
  const body = JSON.stringify(payload);
  try {
    const beacon = beaconFn
      || (typeof navigator !== 'undefined' && navigator.sendBeacon && navigator.sendBeacon.bind(navigator));
    if (beacon) {
      beacon(COMPARE_LOG_URL, new Blob([body], { type: 'application/json' }));
      _sentPairs.add(key); // 발사에 성공한 뒤에만 기록 — throw 경로는 다음 기회에 재시도된다
      return true;
    }
    const f = fetchFn || (typeof fetch !== 'undefined' ? fetch : null);
    if (!f) return false;
    f(COMPARE_LOG_URL, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body, credentials: 'omit', keepalive: true,
    }).catch(() => { /* 미전송 폴백 — 무손상 */ });
    _sentPairs.add(key);
    return true;
  } catch { return false; }
}

// ── DOM: 항목 버튼(접힘 행·목록 공용 구조) ──────────────────────────────────
// showRank=false(폴백)면 순위 번호를 아예 만들지 않는다 — 제안 목록에 1·2·3이 붙으면
// 집계 순위처럼 읽힌다. 제목만 바꾸고 번호를 남기면 문구로 부인하면서 숫자로 주장하는 꼴이다.
function itemButton(item, rank, onPick, showRank = true) {
  const btn = el('button', { type: 'button', class: 'trend-item' });
  if (showRank) btn.append(el('span', { class: 'trend-rank', text: String(rank) }));
  const pair = el('span', { class: 'trend-pair' });
  pair.append(el('span', { class: 'trend-a', text: item.a_comp_nm }));
  pair.append(el('span', { class: 'trend-vs', text: 'vs' }));
  pair.append(el('span', { class: 'trend-b', text: item.b_comp_nm }));
  btn.append(pair);
  if (typeof onPick === 'function') btn.addEventListener('click', () => onPick(item));
  return btn;
}

function prefersReducedMotion() {
  try {
    return typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
  } catch { return false; }
}

// ── 터치 기기: 롤링이 곧 오조준이다(2026-08-27, HANDOFF-2026-07-31 §3-7) ─────
// 접힘 행은 ROTATE_MS마다 노드를 통째로 교체한다. 데스크톱은 mouseenter가 롤링을 멈춰
// 주므로 사실상 안전하지만, **터치 기기에는 호버가 없다** — 멈출 방법 자체가 없어
// ㉠ 행을 읽고 손가락을 내리는 사이에 내용이 바뀌고(다른 조합이 열린다), ㉡ pointerdown~
// pointerup 사이에 교체되면 click 이 아예 발생하지 않는다(Playwright 클릭 타임아웃이
// 같은 이유였다). 게다가 펼칠 수단이 없어 터치에서는 10개 중 1개만 도달 가능했다.
//
// 그래서 호버 없는 기기에서는 **처음부터 펼친 목록으로 렌더하고 롤링을 걸지 않는다**.
// 접힘 행이 없으면 움직이는 과녁도 없다 — 결함의 원인(호버 부재)과 판정 기준이 같고,
// 데스크톱 경로는 한 줄도 건드리지 않으며, CSS 는 이미 있는 .trend-expanded 를 쓴다.
// `(pointer: coarse)` 가 아니라 `(hover: none)` 을 보는 이유: 멈추는 수단이 호버라서,
// "호버가 없다"가 이 결함의 성립 조건 그 자체다.
function isHoverless() {
  try {
    return typeof matchMedia === 'function' && matchMedia('(hover: none)').matches;
  } catch { return false; }
}

// ── 마운트: fetch → 검증 → 렌더 → 롤링/펼침 배선. 항상 무해(throw 없음). ──
export async function mountTrending(deps = {}) {
  const { fetchFn, onPick, rotateMs = ROTATE_MS, companies = [] } = deps;
  const host = (typeof document !== 'undefined' && document.getElementById)
    ? document.getElementById('trending') : null;
  if (!host) return null; // 위젯 호스트 없는 페이지 → no-op

  let items = [];
  try {
    const f = fetchFn || (typeof fetch !== 'undefined' ? fetch : null);
    // 스크래핑 방어(2026-07-21): 데이터 GET은 nginx가 X-Loupit-Client 헤더를 요구(apiFetch와 동일).
    // 빠지면 이 위젯이 403으로 조용히 사라진다(위젯 실패는 무해하나 기능 손실).
    if (f) {
      const res = await f(TRENDING_URL, { credentials: 'omit', headers: { 'X-Loupit-Client': 'web' } });
      items = parseTrending(await res.json());
    }
  } catch { items = []; } // 로드 실패 → 폴백으로 넘어간다(REF는 이미 로드돼 네트워크가 필요 없다)

  // 집계 0건(콜드스타트)·API 실패 → 같은 업종 제안으로 대체. 둘 다 빈손일 때만 숨는다.
  const isFallback = !items.length;
  if (isFallback) items = fallbackPairs(companies);
  if (!items.length) return null; // 집계도 번들도 없음 → 미노출(기존 동작 유지)

  const title = isFallback ? SUGGEST_TITLE : TRENDING_TITLE;
  host.replaceChildren();
  host.dataset.mode = isFallback ? 'suggest' : 'trending'; // CSS·테스트가 두 모드를 구분하는 지점
  host.setAttribute('aria-label', title); // 셸의 정적 라벨이 모드와 어긋나지 않게 여기서 확정한다
  host.append(el('h2', { class: 'trend-title', text: title }));
  host.append(el('p', { class: 'trend-caption', text: isFallback ? SUGGEST_CAPTION : TRENDING_CAPTION }));

  const current = el('div', { class: 'trend-current', 'aria-live': 'off' });
  host.append(current);

  const list = el('ol', {
    class: 'trend-list',
    'aria-label': isFallback ? '추천 비교 조합 전체' : '비교 조합 순위 전체', // 폴백은 순위가 아니다
  });
  items.forEach((item, i) => {
    const li = el('li', {});
    li.append(itemButton(item, i + 1, onPick, !isFallback));
    list.append(li);
  });
  host.append(list);

  let idx = 0;
  function renderCurrent() {
    current.replaceChildren(itemButton(items[idx], idx + 1, onPick, !isFallback));
  }
  renderCurrent();

  // 롤링(접힘 상태 전용). prefers-reduced-motion이면 자동 롤링 없음(NFR 모션 배려).
  let timer = null;
  // 잠기면 영구히 펼친 채로 둔다 — 되돌릴 길을 남기면(합성 mouseleave 등) 결함이 되살아난다.
  let pinnedOpen = isHoverless();
  const canRotate = !prefersReducedMotion() && typeof setInterval === 'function';
  function start() {
    if (pinnedOpen || !canRotate || timer != null) return;
    timer = setInterval(() => { idx = nextIndex(idx, items.length); renderCurrent(); }, rotateMs);
    // Node(테스트 러너)에서 이벤트 루프를 붙들지 않게 unref(브라우저는 number 반환 → no-op).
    if (timer && typeof timer.unref === 'function') timer.unref();
  }
  function stop() {
    if (timer != null) { clearInterval(timer); timer = null; }
  }

  // 호버/키보드 포커스 → 펼침 + 롤링 정지. 이탈 → 접힘 + 재개.
  const expand = () => { host.classList.add('trend-expanded'); stop(); };
  const collapse = () => {
    if (pinnedOpen) return; // 터치로 잠긴 뒤에는 접지 않는다(모바일 브라우저가 mouseleave를 합성한다)
    host.classList.remove('trend-expanded');
    start();
  };
  // 하이브리드(터치 되는 노트북)는 주 입력이 마우스라 (hover: none)에 걸리지 않는다.
  // 실제 손가락이 닿는 그 순간 잠근다 — pointerdown은 click보다 먼저 오므로 최소한
  // 그 탭부터는 누르고 있는 노드가 교체되지 않는다.
  host.addEventListener('pointerdown', (e) => {
    if (pinnedOpen || !e || e.pointerType !== 'touch') return;
    pinnedOpen = true;
    expand();
  });
  host.addEventListener('mouseenter', expand);
  host.addEventListener('mouseleave', collapse);
  host.addEventListener('focusin', expand);
  host.addEventListener('focusout', collapse);

  if (pinnedOpen) expand(); // 호버가 없는 기기 → 접힘 행 없이 시작
  start();
  host.hidden = false;
  return { items, stop, mode: isFallback ? 'suggest' : 'trending', rolling: timer != null };
}
