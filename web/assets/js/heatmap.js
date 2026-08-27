// web/assets/js/heatmap.js — /heatmap 탭 전환(enhancement, SP-HEAT). 배치·색은 정적 HTML 에 있다.
// JS 가 없으면 두 모드가 세로로 나란히 보인다 — 여기서는 선택한 모드만 남긴다.

/** 순수: 문서 안 탭·패널을 `mode` 로 맞춘다. 반환 = 실제로 보이는 패널 수. */
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

export function initHeatmap(doc = globalThis.document) {
  if (!doc?.querySelector('.hm-tabs')) return false;
  const initial = new URLSearchParams(globalThis.location?.search || '').get('mode') || 'w';
  activate(doc, initial);
  doc.querySelectorAll('.hm-tabs [role="tab"]').forEach((t) =>
    t.addEventListener('click', () => {
      activate(doc, t.dataset.mode);
      try { globalThis.history?.replaceState(null, '', t.dataset.mode === 'w' ? '/heatmap' : '/heatmap?mode=' + t.dataset.mode); } catch { /* 무시 */ }
    }));
  return true;
}

if (typeof document !== 'undefined' && document.querySelector('.hm-tabs')) initHeatmap();
