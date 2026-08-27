// web/assets/js/heatmap.js — /heatmap 탭·카테고리 칩 전환(enhancement, SP-HEAT). 배치·색은 정적 HTML 에 있다.
// JS 가 없으면 모드 3개(와 카테고리 9개)가 세로로 나란히 보인다 — 여기서는 선택한 것만 남긴다.

/** 순수: 모드 탭·패널을 `mode` 로 맞춘다. 반환 = 보이는 모드 패널 수. */
export function activate(doc, mode) {
  const tabs = doc.querySelectorAll('.hm-tabs [role="tab"]');
  const panels = doc.querySelectorAll('.hm-mode');
  if (!tabs.length || !panels.length) return 0;
  const keys = Array.from(tabs, (t) => t.dataset.mode);
  const target = keys.includes(mode) ? mode : keys[0];
  tabs.forEach((t) => t.setAttribute('aria-selected', String(t.dataset.mode === target)));
  let shown = 0;
  panels.forEach((p) => { const on = p.dataset.mode === target; p.hidden = !on; if (on) shown += 1; });
  return shown;
}

/** 순수: 한 모드 안의 카테고리 칩·패널을 `key` 로 맞춘다(칩이 없는 모드는 0). */
export function activatePanel(modeEl, key) {
  const chips = modeEl?.querySelectorAll('.hm-chips [role="tab"]') || [];
  const panels = modeEl?.querySelectorAll('.hm-panel') || [];
  if (!chips.length || panels.length < 2) return 0;
  const keys = Array.from(chips, (c) => c.dataset.panel);
  const target = keys.includes(key) ? key : keys[0];
  chips.forEach((c) => c.setAttribute('aria-selected', String(c.dataset.panel === target)));
  let shown = 0;
  panels.forEach((p) => { const on = p.dataset.panel === target; p.hidden = !on; if (on) shown += 1; });
  return shown;
}

// ── 강조(SP-HEAT-7) ─────────────────────────────────────────────────────────
// prober 히트맵은 칸에 마우스를 올리면 그 칸과 **소속 그룹 테두리**를 함께 칠한다. 같은 동작에
// 하나를 더한다: 카테고리 모드에서는 한 회사가 여러 항목 묶음에 흩어져 있으므로 **같은 회사의
// 다른 칸**도 점선으로 표시한다("이 회사의 다른 복지는 어디에?"). 연결 정보(data-g·data-c)는
// 정적 HTML 에 있고 여기서는 class 만 토글한다 — 관련 요소 몇 개만 건드려 1,400칸에서도 가볍다.

const HOT = 'is-hot';
const PEER = 'is-peer';

/** 판독줄 문구 — 순수. 작은 칸은 글자가 안 들어가므로 그 내용을 문장으로 만든다.
    묶음 이름은 **그룹 요소**에서 받는다 — 칸마다 중복 출력하면 정적 HTML 이 수십 KB 커진다. */
export function readoutText(tile, group) {
  if (!tile) return '';
  const name = group?.dataset?.nm || '';
  const tip = tile.getAttribute('title') || '';
  return name ? `${name} · ${tip}` : tip;
}

/** 이 지도에서 강조를 걷어낸다. 반환 = 걷어낸 요소 수. */
export function clearHighlight(map) {
  const marked = map?.querySelectorAll?.(`.${HOT}, .${PEER}`) || [];
  marked.forEach((el) => el.classList.remove(HOT, PEER));
  return marked.length;
}

/**
 * `tile` 과 그 소속 그룹, 같은 회사의 다른 칸을 강조한다.
 * 반환 `{ group, peers }` — 강조된 그룹 수(0 또는 1)와 같은 회사 칸 수(자기 제외).
 */
export function highlight(map, tile) {
  clearHighlight(map);
  if (!map || !tile) return { group: 0, peers: 0, groupEl: null };
  tile.classList.add(HOT);
  const g = tile.dataset.g;
  const grp = g ? map.querySelector(`.hm-grp[data-g="${g}"]`) : null;
  if (grp) grp.classList.add(HOT);
  const c = tile.dataset.c;
  let peers = 0;
  if (c) {
    map.querySelectorAll(`.hm-t[data-c="${c}"]`).forEach((el) => {
      if (el !== tile) { el.classList.add(PEER); peers += 1; }
    });
  }
  return { group: grp ? 1 : 0, peers, groupEl: grp };
}

/** 지도 하나에 마우스·포커스 배선. 판독줄은 지도의 형제(`[data-readout]`)다. */
export function bindMap(map) {
  if (!map) return false;
  const readout = map.parentElement?.querySelector('[data-readout]');
  const base = readout?.textContent || '';
  const enter = (ev) => {
    const tile = ev.target.closest?.('.hm-t');
    if (!tile || !map.contains(tile)) return;
    const { groupEl } = highlight(map, tile);
    if (readout) readout.textContent = readoutText(tile, groupEl);
  };
  const leave = () => { clearHighlight(map); if (readout) readout.textContent = base; };
  map.addEventListener('mouseover', enter);
  map.addEventListener('focusin', enter);
  map.addEventListener('mouseleave', leave);
  map.addEventListener('focusout', (ev) => { if (!map.contains(ev.relatedTarget)) leave(); });
  return true;
}

function syncUrl(mode, cat) {
  const q = new URLSearchParams();
  if (mode && mode !== 'w') q.set('mode', mode);
  if (mode === 'c' && cat) q.set('cat', cat);
  const qs = q.toString();
  try { globalThis.history?.replaceState(null, '', '/heatmap' + (qs ? '?' + qs : '')); } catch { /* 무시 */ }
}

export function initHeatmap(doc = globalThis.document) {
  if (!doc?.querySelector('.hm-tabs')) return false;
  const params = new URLSearchParams(globalThis.location?.search || '');
  let mode = params.get('mode') || 'w';
  let cat = params.get('cat') || '';
  activate(doc, mode);
  doc.querySelectorAll('.hm-mode').forEach((m) => activatePanel(m, cat));
  doc.querySelectorAll('.hm-tabs [role="tab"]').forEach((t) =>
    t.addEventListener('click', () => { mode = t.dataset.mode; activate(doc, mode); syncUrl(mode, cat); }));
  doc.querySelectorAll('.hm-mode').forEach((m) =>
    m.querySelectorAll('.hm-chips [role="tab"]').forEach((c) =>
      c.addEventListener('click', () => { cat = c.dataset.panel; activatePanel(m, cat); syncUrl(mode, cat); })));
  doc.querySelectorAll('.hm-map').forEach(bindMap);
  return true;
}

if (typeof document !== 'undefined' && document.querySelector('.hm-tabs')) initHeatmap();
