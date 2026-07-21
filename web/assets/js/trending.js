// web/assets/js/trending.js — "실시간 비교 TOP 10" 우측 위젯 + 익명 비교 로그 전송.
//
// 데이터: GET /api/v1/comparisons/trending (최근 7일 회사쌍 COUNT 상위 10, INV-1 개정
// 2026-07-14). 전송: POST /api/v1/comparisons/log — 회사쌍 comp_id만(사용자 식별자·
// 연봉 등 입력값 절대 미전송; 직접 입력 모드 쌍은 전송 자체를 하지 않는다).
//
// 동작: 접힘 상태에서 1~10위를 ROTATE_MS 간격 순차 롤링, 마우스 호버/키보드 포커스 시
// 전체 목록 펼침(.trend-expanded). 클릭 → onPick(item) (배선은 app.js 소유 — 양 슬롯
// 프리필). 위젯 실패는 비교 툴에 무해해야 한다(광고 MON6과 동일 원칙): fetch 실패·
// 빈 목록·host 부재 → host hidden 유지, throw 없음.
import { el } from './dom.js';

export const ROTATE_MS = 3000;
export const TRENDING_URL = '/api/v1/comparisons/trending';
export const COMPARE_LOG_URL = '/api/v1/comparisons/log';
const MAX_ITEMS = 10;

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

// 비교하기 실행 시 1회 전송(fire-and-forget). 실패는 조용히 무시 — 비교 리포트 무손상.
export function sendCompareLog(state, { beaconFn, fetchFn } = {}) {
  const payload = compareLogPayload(state);
  if (!payload) return false;
  const body = JSON.stringify(payload);
  try {
    const beacon = beaconFn
      || (typeof navigator !== 'undefined' && navigator.sendBeacon && navigator.sendBeacon.bind(navigator));
    if (beacon) {
      beacon(COMPARE_LOG_URL, new Blob([body], { type: 'application/json' }));
      return true;
    }
    const f = fetchFn || (typeof fetch !== 'undefined' ? fetch : null);
    if (!f) return false;
    f(COMPARE_LOG_URL, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body, credentials: 'omit', keepalive: true,
    }).catch(() => { /* 미전송 폴백 — 무손상 */ });
    return true;
  } catch { return false; }
}

// ── DOM: 항목 버튼(접힘 행·목록 공용 구조) ──────────────────────────────────
function itemButton(item, rank, onPick) {
  const btn = el('button', { type: 'button', class: 'trend-item' });
  btn.append(el('span', { class: 'trend-rank', text: String(rank) }));
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

// ── 마운트: fetch → 검증 → 렌더 → 롤링/펼침 배선. 항상 무해(throw 없음). ──
export async function mountTrending(deps = {}) {
  const { fetchFn, onPick, rotateMs = ROTATE_MS } = deps;
  const host = (typeof document !== 'undefined' && document.getElementById)
    ? document.getElementById('trending') : null;
  if (!host) return null; // 위젯 호스트 없는 페이지 → no-op

  let items = [];
  try {
    const f = fetchFn || (typeof fetch !== 'undefined' ? fetch : null);
    if (!f) return null;
    // 스크래핑 방어(2026-07-21): 데이터 GET은 nginx가 X-Loupit-Client 헤더를 요구(apiFetch와 동일).
    // 빠지면 이 위젯이 403으로 조용히 사라진다(위젯 실패는 무해하나 기능 손실).
    const res = await f(TRENDING_URL, { credentials: 'omit', headers: { 'X-Loupit-Client': 'web' } });
    items = parseTrending(await res.json());
  } catch { return null; } // 로드 실패 → hidden 유지(무크래시)
  if (!items.length) return null; // 집계 0건 → 미노출

  host.replaceChildren();
  host.append(el('h2', { class: 'trend-title', text: '실시간 비교 TOP 10' }));
  host.append(el('p', { class: 'trend-caption', text: '현재 직장(A) vs 이직 후보(B)' }));

  const current = el('div', { class: 'trend-current', 'aria-live': 'off' });
  host.append(current);

  const list = el('ol', { class: 'trend-list', 'aria-label': '비교 조합 순위 전체' });
  items.forEach((item, i) => {
    const li = el('li', {});
    li.append(itemButton(item, i + 1, onPick));
    list.append(li);
  });
  host.append(list);

  let idx = 0;
  function renderCurrent() {
    current.replaceChildren(itemButton(items[idx], idx + 1, onPick));
  }
  renderCurrent();

  // 롤링(접힘 상태 전용). prefers-reduced-motion이면 자동 롤링 없음(NFR 모션 배려).
  let timer = null;
  const canRotate = !prefersReducedMotion() && typeof setInterval === 'function';
  function start() {
    if (!canRotate || timer != null) return;
    timer = setInterval(() => { idx = nextIndex(idx, items.length); renderCurrent(); }, rotateMs);
    // Node(테스트 러너)에서 이벤트 루프를 붙들지 않게 unref(브라우저는 number 반환 → no-op).
    if (timer && typeof timer.unref === 'function') timer.unref();
  }
  function stop() {
    if (timer != null) { clearInterval(timer); timer = null; }
  }

  // 호버/키보드 포커스 → 펼침 + 롤링 정지. 이탈 → 접힘 + 재개.
  const expand = () => { host.classList.add('trend-expanded'); stop(); };
  const collapse = () => { host.classList.remove('trend-expanded'); start(); };
  host.addEventListener('mouseenter', expand);
  host.addEventListener('mouseleave', collapse);
  host.addEventListener('focusin', expand);
  host.addEventListener('focusout', collapse);

  start();
  host.hidden = false;
  return { items, stop };
}
