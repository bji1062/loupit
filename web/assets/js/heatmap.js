// web/assets/js/heatmap.js — /heatmap 탭·카테고리 칩 전환 + 지도 늦게 그리기(SP-HEAT). 배치·색은 빌드 시점에 정해진다.
// 정적 HTML 에는 복지 지도만 있다. 실적·카테고리 지도는 패널마다 데이터 파일(`data-src`)로 나가고, 처음 여는 순간
// 받아 **정적 마크업과 같은 모양**으로 그린다(`buildMaps` ↔ `_hm_maps.html` — 픽스처 대조 테스트가 잰다).
// JS 가 없으면 복지 지도만 보이고 나머지 자리에는 안내가 보인다 — 여기서는 선택한 것만 남긴다.

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

// ── 지도 늦게 그리기 ─────────────────────────────────────────────────────────
// 데이터 파일 모양은 `generator/pages/heatmap.py panel_data` 가 정한다(그룹 표 · 칸 표 · 배치별 순서와 좌표).
// 좌표는 서버가 찍은 글자 그대로의 문자열이라 숫자로 바꾸지 않고 style 에 붙인다.

const ORIENTS = ['landscape', 'portrait']; // 템플릿 매크로의 순서
const MSG_LOADING = '불러오는 중…';
const MSG_FAILED = '지도를 받지 못했습니다. 다시 누르면 다시 받습니다.';

/** 순수: 데이터 파일 → 지도 div 둘(가로·세로)을 담은 DocumentFragment. 텍스트는 textContent·속성으로만 넣는다. */
export function buildMaps(doc, data) {
  const frag = doc.createDocumentFragment();
  const el = (tag, cls, text) => {
    const n = doc.createElement(tag);
    if (cls) n.className = cls;
    if (text !== undefined) n.textContent = text;
    return n;
  };
  const style = (coords) => {
    const [x, y, w, h] = coords.split(' ');
    return `left:${x}%;top:${y}%;width:${w}%;height:${h}%`;
  };
  const nameOf = {};
  data.groups.forEach(([gkey, name]) => { nameOf[gkey] = name; });
  ORIENTS.forEach((orient) => {
    const lay = data[orient];
    const map = el('div', `hm-map hm-${orient}`);
    map.setAttribute('aria-hidden', orient === 'landscape' ? 'false' : 'true');
    lay.g.forEach(([gi, narrow, coords]) => {
      const [gkey, name, count, unlisted] = data.groups[gi];
      const g = el('div', 'hm-grp' + (narrow ? ' narrow' : '') + (unlisted ? ' unlisted' : ''));
      g.setAttribute('data-g', gkey);
      g.setAttribute('data-nm', name);
      g.setAttribute('style', style(coords));
      g.setAttribute('title', `${name} ${count}곳`);
      const span = el('span', '', `${name} `);
      span.appendChild(el('em', '', String(count)));
      g.appendChild(span);
      map.appendChild(g);
    });
    lay.t.forEach(([ti, size, coords]) => {
      const [nm, industry, gkey, ckey, cls, sub, tip, anchor] = data.tiles[ti];
      const a = el('a', `hm-t ${cls} ${size}`);
      a.setAttribute('href', `/company/${ckey}${anchor}`);
      a.setAttribute('data-g', gkey);
      a.setAttribute('data-c', ckey);
      a.setAttribute('style', style(coords));
      a.setAttribute('title', `${nm} — ${industry} · ${nameOf[gkey]} — ${tip}`);
      a.appendChild(el('b', '', nm));
      a.appendChild(el('i', '', sub));
      map.appendChild(a);
    });
    frag.appendChild(map);
  });
  return frag;
}

/** 데이터 파일 받기 — 같은 주소는 한 번만(받는 중·받은 것 공유). 실패는 기억하지 않는다(다음 클릭에 다시). */
export function createLoader(fetchFn) {
  const seen = new Map();
  return {
    has: (src) => seen.has(src),
    load(src) {
      if (seen.has(src)) return seen.get(src);
      const p = Promise.resolve().then(() => fetchFn(src)).then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      });
      seen.set(src, p);
      p.catch(() => seen.delete(src));
      return p;
    },
  };
}

function setStatus(panel, text) {
  let st = panel.querySelector(':scope > .hm-status');
  if (!text) { st?.remove(); return; }
  if (!st) {
    st = panel.ownerDocument.createElement('p');
    st.className = 'hm-status';
    st.setAttribute('role', 'status');
    panel.appendChild(st);
  }
  st.textContent = text;
}

/** 패널 하나의 지도가 아직이면 받아서 그린다(정적으로 구운 패널·이미 그린 패널은 그대로). 반환 = 그렸는가. */
export async function ensurePanel(panel, loader) {
  const src = panel?.dataset?.src;
  if (!src || panel.dataset.drawn) return false;
  if (panel.dataset.loading) return false; // 받는 중 — 같은 패널을 두 번 그리지 않는다
  panel.dataset.loading = '1';
  setStatus(panel, MSG_LOADING);
  try {
    const data = await loader.load(src);
    const frag = buildMaps(panel.ownerDocument, data);
    const maps = Array.from(frag.children);
    setStatus(panel, '');
    panel.appendChild(frag);
    maps.forEach(bindMap);
    panel.dataset.drawn = '1';
    return true;
  } catch {
    setStatus(panel, MSG_FAILED);
    return false;
  } finally {
    delete panel.dataset.loading;
  }
}

/** 지금 보이는 패널들(탭 하나 · 칩 하나)을 그린다. 이미 그렸으면 아무 일도 없다. */
export function loadVisible(doc, loader) {
  const jobs = [];
  doc.querySelectorAll('.hm-mode:not([hidden]) .hm-panel:not([hidden])').forEach((p) => jobs.push(ensurePanel(p, loader)));
  return Promise.all(jobs);
}

/** 미리 받아도 되는 회선인가 — 데이터 절약 모드 · 2G 는 아니다. */
export function shouldPrefetch(nav = globalThis.navigator) {
  const conn = nav?.connection;
  if (conn?.saveData) return false;
  return !['slow-2g', '2g'].includes(conn?.effectiveType);
}

/** 한가할 때 실적 · 카테고리 첫 칩 데이터를 **받아만** 둔다(그리는 것은 눌렀을 때). 반환 = 받기 시작한 수. */
export function prefetchPanels(doc, loader, nav = globalThis.navigator) {
  if (!shouldPrefetch(nav)) return 0;
  const srcs = ['f', 'c'].map((k) => doc.querySelector(`.hm-mode[data-mode="${k}"] .hm-panel[data-src]`)?.dataset.src).filter(Boolean);
  srcs.forEach((src) => { loader.load(src).catch(() => { /* 미리 받기 실패는 조용히 — 누르면 다시 받는다 */ }); });
  return srcs.length;
}

function whenIdle(fn) {
  const ric = globalThis.requestIdleCallback;
  if (ric) ric(fn, { timeout: 4000 });
  else setTimeout(fn, 1500);
}

function syncUrl(mode, cat) {
  const q = new URLSearchParams();
  if (mode && mode !== 'w') q.set('mode', mode);
  if (mode === 'c' && cat) q.set('cat', cat);
  const qs = q.toString();
  try { globalThis.history?.replaceState(null, '', '/heatmap' + (qs ? '?' + qs : '')); } catch { /* 무시 */ }
}

export function initHeatmap(doc = globalThis.document, opts = {}) {
  if (!doc?.querySelector('.hm-tabs')) return false;
  const loader = createLoader(opts.fetch || ((src) => globalThis.fetch(src)));
  const params = new URLSearchParams(globalThis.location?.search || '');
  let mode = params.get('mode') || 'w';
  let cat = params.get('cat') || '';
  activate(doc, mode);
  doc.querySelectorAll('.hm-mode').forEach((m) => activatePanel(m, cat));
  doc.querySelectorAll('.hm-tabs [role="tab"]').forEach((t) =>
    t.addEventListener('click', () => { mode = t.dataset.mode; activate(doc, mode); syncUrl(mode, cat); loadVisible(doc, loader); }));
  doc.querySelectorAll('.hm-mode').forEach((m) =>
    m.querySelectorAll('.hm-chips [role="tab"]').forEach((c) =>
      c.addEventListener('click', () => { cat = c.dataset.panel; activatePanel(m, cat); syncUrl(mode, cat); loadVisible(doc, loader); })));
  doc.querySelectorAll('.hm-map').forEach(bindMap);
  loadVisible(doc, loader); // 주소로 곧장 들어온 패널(?mode=c&cat=…)은 바로 받는다
  if (!opts.noPrefetch) {
    const start = () => whenIdle(() => prefetchPanels(doc, loader));
    if (doc.readyState === 'complete') start(); else globalThis.addEventListener?.('load', start, { once: true });
  }
  return true;
}

if (typeof document !== 'undefined' && document.querySelector('.hm-tabs')) initHeatmap();
