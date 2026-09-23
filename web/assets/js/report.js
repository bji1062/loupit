// web/assets/js/report.js — 리포트 DOM 렌더(SP-FE-9.4, FR-40·41·42·45, NFR21, SP-ENGINE-2.2·13).
// 구 SP-RPT 대역 흡수. 엔진 calc.js는 import하지 않는다(값은 이미 계산됨) — dom.js·store.js만 사용.
import { el } from './dom.js';
import { recent } from './store.js';
import { renderCalcReport } from './report-calc.js'; // 이직 계산기 결과 화면(SP-FE-14, 2026-09-23 개편)

// 9카테고리 표시 라벨(SP-GEN CATEGORY_LABEL과 동일 어휘 사용 — 화면 간 용어 일관성).
const CATEGORY_LABEL = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};

// ── 경고 코드→문구(엔진은 코드만 반환). 계산기 결과 화면(2026-09-23)은 이 내용을 판정 카드 안의 줄로
// 회사 이름을 넣어 말하므로 배너로 따로 그리지 않는다. 임금 형태는 회사 사실이 아니라 **입력한 조건**이다.
export const WARN_COPY = {
  eff_shrink: '연봉이 올라도 복지 차이 때문에 실효 총보상 차이가 줄어듭니다.',
  both_inclusive: '입력하신 대로 두 회사 모두 포괄임금이면 야근수당은 0으로 계산됩니다.',
  inclusive_a: '입력하신 대로 현재 직장이 포괄임금이면 야근수당은 0으로 계산됩니다.',
  inclusive_b: '입력하신 대로 이직 후보가 포괄임금이면 야근수당은 0으로 계산됩니다.',
  wage_unknown_a: '입력하신 조건에 현재 직장의 야근수당 여부가 없어 포괄·비포괄 두 경우를 모두 계산했습니다.',
  wage_unknown_b: '입력하신 조건에 이직 후보의 야근수당 여부가 없어 포괄·비포괄 두 경우를 모두 계산했습니다.',
};
export function warnCopy(code) { return WARN_COPY[code] || ('알 수 없는 안내(' + code + ')'); } // 미지 코드 방어

// ── T-06.11.3 renderCatDelta — 9카테고리 델타표(고정 순서는 엔진 catDelta가 보장) ──
export function renderCatDelta(catDelta, mountEl) {
  mountEl.replaceChildren();
  const table = el('table', { class: 'cat-delta-table' });
  const thead = el('thead');
  const headRow = el('tr');
  headRow.append(el('th', { text: '카테고리' }), el('th', { text: '현재 직장' }), el('th', { text: '이직처' }), el('th', { text: '차이' }));
  thead.append(headRow);
  table.append(thead);
  const tbody = el('tbody');
  for (const row of (catDelta || [])) {
    const tr = el('tr', { 'data-ctgr': row.ctgr });
    tr.append(
      el('td', { class: 'cat-delta-nm', text: CATEGORY_LABEL[row.ctgr] || row.ctgr }),
      el('td', { class: 'cat-delta-a', text: String(row.sumA) }),
      el('td', { class: 'cat-delta-b', text: String(row.sumB) }),
      el('td', { class: 'cat-delta-diff', text: String(row.delta) }),
    );
    tbody.append(tr);
  }
  table.append(tbody);
  mountEl.append(table);
  return mountEl;
}

// ── renderCatButterfly — 카테고리별 총액 back-to-back(버터플라이) 차트 ──────────
// 예전 loupit(job_change) 리포트 디자인 이식: 각 카테고리 행에서 현재 직장(A)은 중앙축
// 기준 왼쪽으로, 이직처(B)는 오른쪽으로 막대가 뻗어 두 회사를 한눈에 대칭 비교한다.
// 폭은 전 카테고리 중 최대 sum 대비 정규화(%). 순수 CSS/DOM(무외부라이브러리), 값은 표(renderCatDelta)가 정밀 제공.
function bflyWing(side, pct) {
  const w = el('div', { class: 'bfly-wing ' + side });
  w.append(el('div', { class: 'bfly-bar ' + side, style: 'width:' + pct + '%' }));
  return w;
}
function bflyCenter(row) {
  const c = el('div', { class: 'bfly-center' });
  c.append(el('span', { class: 'bfly-label', text: CATEGORY_LABEL[row.ctgr] || row.ctgr }));
  const d = row.delta || 0;
  const cls = d > 0 ? 'bfly-diff b' : d < 0 ? 'bfly-diff a' : 'bfly-diff eq';
  const txt = d > 0 ? '+' + d : d < 0 ? String(d) : '±0';
  c.append(el('span', { class: cls, text: txt }));
  return c;
}
export function renderCatButterfly(catDelta, mountEl) {
  mountEl.replaceChildren();
  const rows = catDelta || [];
  const maxSum = Math.max(1, ...rows.map((r) => Math.max(r.sumA || 0, r.sumB || 0)));
  // 범례
  const legend = el('div', { class: 'bfly-legend' });
  legend.append(
    el('span', { class: 'bfly-key a', text: '현재 직장(A)' }),
    el('span', { class: 'bfly-key b', text: '이직처(B)' }),
  );
  mountEl.append(legend);
  const chart = el('div', {
    class: 'bfly', role: 'img',
    'aria-label': '카테고리별 복지 총액 비교 — 왼쪽 현재 직장(A), 오른쪽 이직처(B)',
  });
  for (const r of rows) {
    const pctA = (r.sumA || 0) > 0 ? Math.max(4, (r.sumA / maxSum) * 100) : 0;
    const pctB = (r.sumB || 0) > 0 ? Math.max(4, (r.sumB / maxSum) * 100) : 0;
    const rowEl = el('div', { class: 'bfly-row', 'data-ctgr': r.ctgr });
    rowEl.append(
      el('span', { class: 'bfly-val a', text: (r.sumA || 0) > 0 ? String(r.sumA) : '-' }),
      bflyWing('a', pctA),
      bflyCenter(r),
      bflyWing('b', pctB),
      el('span', { class: 'bfly-val b', text: (r.sumB || 0) > 0 ? String(r.sumB) : '-' }),
    );
    chart.append(rowEl);
  }
  mountEl.append(chart);
  return mountEl;
}

// ── 복지 항목 매트릭스(매트릭스+diff 요약 하이브리드, FR-40 개편 2026-07-15) ──
// 같은 복지(benefit_cd)를 같은 행에 정렬해 두 회사를 대조한다. checked 항목만
// 대상(엔진 합계와 동일 모집단). 카테고리 순서는 CATEGORY_LABEL 키 순서(9종 고정,
// 엔진 BENEFIT_CATEGORIES와 동일 어휘 — calc.js import 금지 규칙 유지).
// `requireChecked:false` 는 **모드 A 「복지 비교」**(SP-CMP-6)가 쓴다. 그 화면에는 체크박스가
// 없다 — 사용자가 고른 것이 아니라 회사에 등록된 것 전부를 나란히 놓는 자리라, 「체크된 항목만」
// 이라는 모드 B 의 모집단 규칙이 거기서는 뜻을 잃는다. 기본값은 true 그대로라 리포트 쪽 계약은
// 한 글자도 바뀌지 않는다(짝짓기 키·정렬 규칙을 두 벌로 만들지 않으려고 옵션으로 열었다).
export function matchBenefitRows(benA, benB, { requireChecked = true } = {}) {
  const cats = Object.keys(CATEGORY_LABEL);
  const norm = (c) => (cats.includes(c) ? c : 'perks'); // 미지 카테고리 → perks(엔진과 동일 규칙)
  const map = new Map(); // key → row
  const add = (item, side) => {
    if (!item) return;
    if (requireChecked && item.checked !== true) return;
    const key = item.benefit_cd || item.benefit_nm;
    let row = map.get(key);
    if (!row) {
      // `nm` 은 **먼저 본 쪽**(= A)의 명칭이다. 예전부터 그랬고 리포트는 그대로 쓴다.
      row = { ctgr: norm(item.benefit_ctgr_cd), key, nm: item.benefit_nm, nmA: null, nmB: null, a: null, b: null };
      map.set(key, row);
    }
    row[side] = item;
    // 같은 코드라도 두 회사가 다른 이름을 쓴다(welfare_point = 「개인 업무 지원비」/「복지포인트」).
    // `nm` 하나만 내보내면 **A 의 이름으로 B 의 항목까지 부르게** 되고, A·B 를 맞바꾸면 표의
    // 이름이 통째로 바뀐다. 두 이름을 다 실어 보내고 어떻게 보일지는 화면이 정한다.
    if (side === 'a') row.nmA = item.benefit_nm;
    else row.nmB = item.benefit_nm;
  };
  for (const it of (benA || [])) add(it, 'a'); // a 먼저 — 공통 행의 이름·카테고리는 A 기준
  for (const it of (benB || [])) add(it, 'b');
  const rows = [...map.values()];
  const amt = (r) => Math.max(
    (r.a && !r.a.qual_yn && r.a.benefit_amt != null) ? r.a.benefit_amt : -1,
    (r.b && !r.b.qual_yn && r.b.benefit_amt != null) ? r.b.benefit_amt : -1,
  );
  const isQual = (r) => !!((r.a && r.a.qual_yn) || (r.b && r.b.qual_yn));
  rows.sort((x, y) => {
    const c = cats.indexOf(x.ctgr) - cats.indexOf(y.ctgr);
    if (c !== 0) return c;
    const q = (isQual(x) ? 1 : 0) - (isQual(y) ? 1 : 0); // 정성은 카테고리 내 마지막
    if (q !== 0) return q;
    const d = amt(y) - amt(x); // 금액 내림차순
    if (d !== 0) return d;
    return String(x.nm).localeCompare(String(y.nm), 'ko');
  });
  return rows;
}

// ── T-06.11.6 최근 비교 저장/불러오기 UI(리포트 하단, RP-6) ────────────────
// RecentComparison의 input/result 필드 구성은 FR-43(FRD 06) 소유 — 본 모듈은 렌더+봉투 연동만.
function slotSummary(state, slot) {
  const m = state.matched && state.matched[slot];
  if (m) return { comp_id: m.comp_id, comp_nm: m.comp_nm };
  return { comp_id: null, comp_nm: null, comp_tp_cd: (state.chosenType && state.chosenType[slot]) || null };
}

function genId() {
  if (globalThis.crypto && typeof globalThis.crypto.randomUUID === 'function') return globalThis.crypto.randomUUID();
  return Date.now().toString(36) + Math.random().toString(36).slice(2);
}

export function buildRecentRecord(state, report, ctx = {}) {
  const a = slotSummary(state, 'a'), b = slotSummary(state, 'b');
  return {
    id: ctx.id || genId(),
    savedAt: new Date().toISOString(),
    label: (a.comp_nm || '직접 입력') + ' vs ' + (b.comp_nm || '직접 입력'),
    slots: { a, b },
    input: {
      salS: state.salS, selectedRate: state.selectedRate, cmtS: state.cmtS,
      wsState: state.wsState, curPri: state.curPri, curSacrifice: state.curSacrifice,
      chosenType: state.chosenType, inputMode: state.inputMode,
      // 계산기 개편(2026-09-23) — 옛 레코드에는 없다(복원 쪽이 기본값으로 채운다)
      rateMode: state.rateMode || 'rate', offerSal: state.offerSal ?? null, tenureYears: state.tenureYears ?? null,
    },
    result: {
      priAxis: (report && report.vdCard && report.vdCard.axis) || null,
      winner: (report && report.vdCard && report.vdCard.p1 && report.vdCard.p1.winner) || null,
      effMidDiff: (report && report.deltas) ? report.deltas.effMid : null,
    },
  };
}

export function saveRecentComparison(state, report, ctx = {}) {
  const record = buildRecentRecord(state, report, ctx);
  return recent.save(record) ? record : null; // FR-44: 저장 불가 시 false→null(무크래시)
}

// 복원된 문자열(label 등)은 신뢰 불가로 간주해 el({text})로만 삽입(L-6·FR-45).
export function renderRecentUI(mountEl, ctx = {}) {
  const { listFn = recent.list, onRestore, onRemove } = ctx;
  mountEl.replaceChildren();
  const section = el('div', { class: 'rp-recent' });
  section.append(el('h3', { text: '최근 비교' }));
  const items = listFn();
  if (!items.length) {
    section.append(el('p', { class: 'rp-recent-empty', text: '저장된 비교가 없습니다.' }));
  } else {
    const ul = el('ul', { class: 'rp-recent-list' });
    for (const r of items) {
      const li = el('li', { class: 'rp-recent-item', 'data-id': r.id });
      li.append(el('span', { class: 'rp-recent-label', text: r.label || '' }));
      const restoreBtn = el('button', { type: 'button', class: 'rp-recent-restore', text: '불러오기' });
      restoreBtn.addEventListener('click', () => { if (typeof onRestore === 'function') onRestore(r); });
      const removeBtn = el('button', { type: 'button', class: 'rp-recent-remove', text: '삭제' });
      removeBtn.addEventListener('click', () => {
        recent.removeById(r.id);
        if (typeof onRemove === 'function') onRemove(r.id);
        renderRecentUI(mountEl, ctx); // 재렌더(멱등)
      });
      li.append(restoreBtn, removeBtn);
      ul.append(li);
    }
    section.append(ul);
  }
  mountEl.append(section);
  return mountEl;
}

// ── renderReport — 이직 계산기 결과 화면(SP-FE-14, 2026-09-23 개편) ─────────────────
// 판정 카드·총보상 카드·정성 칩 벽을 늘어놓던 옛 7블록을 걷고, 축(연봉·워라밸·복지)이 판정 기준과 첫 화면을
// 정하는 결과 화면으로 바꿨다. 본문은 report-calc.js 가 그린다 — 여기는 셸 헤딩과 「최근 비교」만 잇는다.
export function renderReport(report, mountEl, ctx = {}) {
  // 새 JS 가 옛 셸(「비교 리포트」 헤딩)을 만나도 목업의 제목·공식을 단다(머지~pull 틈).
  const view = mountEl && mountEl.parentNode;
  const h2 = view && typeof view.querySelector === 'function' ? view.querySelector('h2') : null;
  if (h2 && !h2.querySelector('.calc-h2-note') && typeof document !== 'undefined') {
    h2.textContent = '비교 결과 ';
    h2.append(el('small', { class: 'calc-h2-note', text: '실효 총보상 = 연봉 + 복지 환산 가치 + 야근수당' }));
  }
  return renderCalcReport(report, mountEl, {
    ...ctx,
    renderRecent: (mount) => renderRecentUI(mount, ctx.recentCtx || {}),
  });
}
