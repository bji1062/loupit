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
  return true;
}

if (typeof document !== 'undefined' && document.querySelector('.hm-tabs')) initHeatmap();
