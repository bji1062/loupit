// web/assets/js/report.js — 리포트 DOM 렌더(SP-FE-9.4, FR-40·41·42·45, NFR21, SP-ENGINE-2.2·13).
// 구 SP-RPT 대역 흡수. 엔진 calc.js는 import하지 않는다(값은 이미 계산됨) — dom.js·store.js만 사용.
import { el, safeUrl } from './dom.js';
import { recent } from './store.js';

// 9카테고리 표시 라벨(SP-GEN CATEGORY_LABEL과 동일 어휘 사용 — 화면 간 용어 일관성).
const CATEGORY_LABEL = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};
const AXIS_LABEL = { salary: '연봉', wlb: '워라밸', benefits: '복지' };

// ── 경고 배너 코드→문구 매핑(본 절 소유, 엔진은 코드만 반환) ────────────────
export const WARN_COPY = {
  eff_shrink: '연봉이 올라도 복지 차이 때문에 실질 보상 차이가 줄어듭니다.',
  both_inclusive: '양측 모두 포괄임금이라 야근수당이 반영되지 않았습니다.',
  inclusive_a: '현재 직장은 포괄임금이라 야근수당이 반영되지 않았습니다.',
  inclusive_b: '이직처는 포괄임금이라 야근수당이 반영되지 않았습니다.',
};
export function warnCopy(code) { return WARN_COPY[code] || ('알 수 없는 안내(' + code + ')'); } // 미지 코드 방어

function slotLabel(slot, ctx) {
  const m = ctx.matched && ctx.matched[slot];
  if (m && m.comp_nm) return m.comp_nm;
  if (ctx.labels && ctx.labels[slot]) return ctx.labels[slot];
  return '직접 입력';
}

// ── T-06.11.2 renderVdCard — 판정카드·승자색(클래스만)·tie/limited ─────────
function perspText(p) {
  if (p.detail && 'perksA' in p.detail) return autonomyPerspText(p); // 시간 자율성: 점수 대신 보유 항목 나열(#2)
  if (p.winner === 'tie') return p.label + ': 거의 비슷합니다'; // tie/근소차 단정 회피(UC-33 3a)
  return p.label + ' 우위: ' + (p.winner === 'a' ? '현재 직장' : '이직처');
}

// 자율성 요소 라벨 배열 → 표시 문자열. 보유 0개면 '해당 없음'.
function perkListText(arr) {
  return (arr && arr.length) ? arr.join('·') : '해당 없음';
}

// 시간 자율성(p2): 양쪽 보유 항목을 나열해 승패를 문장으로 설명(#2 — 점수 표시 폐기).
function autonomyPerspText(p) {
  const body = '현재 직장 ' + perkListText(p.detail.perksA) + ', 이직처 ' + perkListText(p.detail.perksB);
  if (p.winner === 'tie') return p.label + ': ' + body;
  return p.label + ' 우위: ' + (p.winner === 'a' ? '현재 직장' : '이직처') + ' (' + body + ')';
}

function renderSacrificeNote(sacrifice) {
  if (!sacrifice) return null;
  if (!sacrifice.ok) return el('p', { class: 'vd-sacrifice-note vd-sacrifice-note--na', text: '희생요소 값을 산출할 수 없습니다(입력 부족).' });
  return el('p', { class: 'vd-sacrifice-note', text: (AXIS_LABEL[sacrifice.axis] || sacrifice.axis) + ' 희생 비용이 산출되었습니다.' });
}

// 색은 SP-DSN 토큰(--green/--red/--t3/--purple)이 CSS에서 클래스에 매핑; 본 절은 클래스명만 부여.
export function renderVdCard(vdCard, mountEl, opts = {}) {
  mountEl.replaceChildren(); // 멱등(FR-42 curPri 전환 시 판정카드만 재호출 가능, RP-5)
  const card = el('div', { class: 'vd-card', 'data-axis': vdCard.axis });
  card.append(el('h3', { class: 'vd-axis-label', text: (AXIS_LABEL[vdCard.axis] || vdCard.axis) + ' 비교' }));
  for (const p of [vdCard.p1, vdCard.p2]) {
    const persp = el('div', {
      class: 'vd-persp vd-persp--' + p.winner,
      'data-winner': p.winner,
    });
    persp.append(el('span', { class: 'vd-persp-label', text: p.label }));
    persp.append(el('span', { class: 'vd-persp-text', text: perspText(p) }));
    card.append(persp);
  }
  if (vdCard.tie) card.append(el('p', { class: 'vd-tie-note', text: '이 축은 근소한 차이라 단정하기 어렵습니다.' }));
  const sacNote = renderSacrificeNote(opts.sacrifice);
  if (sacNote) card.append(sacNote);
  mountEl.append(card);
  return mountEl;
}

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
export function matchBenefitRows(benA, benB) {
  const cats = Object.keys(CATEGORY_LABEL);
  const norm = (c) => (cats.includes(c) ? c : 'perks'); // 미지 카테고리 → perks(엔진과 동일 규칙)
  const map = new Map(); // key → row
  const add = (item, side) => {
    if (!item || item.checked !== true) return;
    const key = item.benefit_cd || item.benefit_nm;
    let row = map.get(key);
    if (!row) {
      row = { ctgr: norm(item.benefit_ctgr_cd), key, nm: item.benefit_nm, a: null, b: null };
      map.set(key, row);
    }
    row[side] = item;
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

// diff 요약(이직 관점): gained = B에만(새로 생김), lost = A에만(사라짐). sum은 금액 항목만.
export function benefitDiffSummary(rows) {
  const s = { gained: { count: 0, sum: 0 }, lost: { count: 0, sum: 0 }, common: 0 };
  for (const r of (rows || [])) {
    if (r.a && r.b) { s.common += 1; continue; }
    const side = r.b ? 'gained' : 'lost';
    const item = r.b || r.a;
    s[side].count += 1;
    if (!item.qual_yn && item.benefit_amt != null) s[side].sum += item.benefit_amt;
  }
  return s;
}

// 표시용 총액 합산(엔진 catDelta 값 그대로 더함 — 원시 항목 재계산 없음, RP-1)
export function benefitTotals(catDelta) {
  const t = { a: 0, b: 0, delta: 0 };
  for (const r of (catDelta || [])) { t.a += r.sumA || 0; t.b += r.sumB || 0; t.delta += r.delta || 0; }
  return t;
}

// 차이 칩: delta(B-A) → "A +N"(파랑)/"B +N"(코랄)/"="(muted). null → 빈 칩 없음.
function deltaChip(delta) {
  if (delta == null) return null;
  if (delta === 0) return el('span', { class: 'ben-delta ben-delta--eq', text: '=' });
  const side = delta > 0 ? 'b' : 'a';
  return el('span', {
    class: 'ben-delta ben-delta--' + side,
    text: (side === 'a' ? 'A +' : 'B +') + Math.abs(delta),
  });
}

// diff 요약 한 줄(헤드라인에 흡수) — 새로 생김/사라짐
function diffSummaryLine(rows) {
  const s = benefitDiffSummary(rows);
  if (!s.gained.count && !s.lost.count) return null;
  const sum = el('p', { class: 'ben-diff-summary' });
  if (s.gained.count) {
    sum.append(el('span', {
      class: 'ben-diff ben-diff--gained',
      text: '＋ 새로 생기는 복지 ' + s.gained.count + '개' + (s.gained.sum ? ' (+' + s.gained.sum + '만원)' : ''),
    }));
  }
  if (s.lost.count) {
    sum.append(el('span', {
      class: 'ben-diff ben-diff--lost',
      text: '－ 사라지는 복지 ' + s.lost.count + '개' + (s.lost.sum ? ' (−' + s.lost.sum + '만원)' : ''),
    }));
  }
  return sum;
}

// ── 총액 헤드라인(결론 먼저): 양사 총액 + 분할 바 + 한 줄 판정 + diff 요약 ──
export function renderBenefitHeadline(catDelta, rows, mountEl, ctx = {}) {
  mountEl.replaceChildren();
  const t = benefitTotals(catDelta);
  const nmA = (ctx.labels && ctx.labels.a) || '현재 직장';
  const nmB = (ctx.labels && ctx.labels.b) || '이직처';
  const head = el('div', { class: 'ben-headline' });

  const vals = el('div', { class: 'ben-headline-vals' });
  const sideA = el('span', { class: 'ben-headline-side ben-headline-side--a' });
  sideA.append(el('span', { class: 'ben-headline-nm', text: nmA }));
  sideA.append(el('strong', { class: 'ben-headline-amt', text: t.a + '만원' }));
  const sideB = el('span', { class: 'ben-headline-side ben-headline-side--b' });
  sideB.append(el('span', { class: 'ben-headline-nm', text: nmB }));
  sideB.append(el('strong', { class: 'ben-headline-amt', text: t.b + '만원' }));
  vals.append(sideA, el('span', { class: 'ben-headline-vs', text: 'vs' }), sideB);
  head.append(vals);

  const total = t.a + t.b;
  if (total > 0) { // 비중 분할 바(A 파랑/B 코랄 — 구 버터플라이 범례 색 계승)
    const bar = el('div', { class: 'ben-split', role: 'img', 'aria-label': '복지 총액 비중 — 왼쪽 ' + nmA + ', 오른쪽 ' + nmB });
    bar.append(el('span', { class: 'ben-split-a', style: 'width:' + ((t.a / total) * 100).toFixed(1) + '%' }));
    bar.append(el('span', { class: 'ben-split-b', style: 'width:' + ((t.b / total) * 100).toFixed(1) + '%' }));
    head.append(bar);
  }

  const verdict = t.delta === 0
    ? '두 회사의 복지 총액이 비슷합니다.'
    : (t.delta > 0 ? nmB : nmA) + ' 복지가 연 ' + Math.abs(t.delta) + '만원 더 큽니다.';
  head.append(el('p', { class: 'ben-headline-verdict', text: verdict }));

  const diff = diffSummaryLine(rows);
  if (diff) head.append(diff);
  mountEl.append(head);
  return mountEl;
}

function benCell(item, now, side, maxAmt, mark) {
  const td = el('td', { class: item ? 'ben-cell' : 'ben-cell ben-none' });
  if (!item) {
    td.append(el('span', { text: '—' }));
    if (mark) td.append(mark); // 빈 셀 마커(사라짐 등) — 인라인
    return td;
  }
  if (item.qual_yn) {
    td.append(el('span', { class: 'ben-qual', text: '✓ 정성' }));
    if (mark) td.append(mark);
    return td;
  }
  const top = el('span', { class: 'ben-cell-top' });
  top.append(el('span', { class: 'ben-amt', text: item.benefit_amt != null ? '연 ' + item.benefit_amt + '만원' : '—' }));
  top.append(el('span', { class: badgeClass(item, now), text: badgeLabel(item, now) })); // 공식/추정/만료(FR-41 재사용)
  if (mark) top.append(mark); // 마커는 금액과 같은 줄(미니바 아래로 밀리지 않게)
  td.append(top);
  if (item.benefit_amt != null && maxAmt > 0) { // 행내 미니바 — 표 최대 금액 대비 폭%(별도 차트 대체)
    const pct = Math.max(3, (item.benefit_amt / maxAmt) * 100);
    td.append(el('span', { class: 'ben-bar ben-bar--' + side, style: 'width:' + pct.toFixed(1) + '%' }));
  }
  return td;
}

export function renderBenefitMatrix(rows, mountEl, ctx = {}) {
  mountEl.replaceChildren(); // 멱등
  if (!rows || !rows.length) return mountEl; // 항목 없음 → 표 생략(무크래시)
  const now = ctx.now != null ? ctx.now : Date.now();
  // 행내 미니바 정규화 기준 — 표 전체 최대 금액(버터플라이 maxSum 방식 계승)
  const maxAmt = Math.max(0, ...rows.flatMap((r) => [
    (r.a && !r.a.qual_yn && r.a.benefit_amt != null) ? r.a.benefit_amt : 0,
    (r.b && !r.b.qual_yn && r.b.benefit_amt != null) ? r.b.benefit_amt : 0,
  ]));

  const table = el('table', { class: 'ben-matrix' });
  table.append(el('caption', { class: 'sr-only', text: '복지 항목별 비교 — 같은 복지는 같은 행, 차이 열에 우세 방향이 표시됩니다.' }));
  const thead = el('thead');
  const hr = el('tr');
  hr.append(
    el('th', { scope: 'col', text: '복지 항목' }),
    el('th', { scope: 'col', class: 'ben-col', text: (ctx.labels && ctx.labels.a) || '현재 직장' }),
    el('th', { scope: 'col', class: 'ben-col', text: (ctx.labels && ctx.labels.b) || '이직처' }),
    el('th', { scope: 'col', class: 'ben-col-delta', text: '차이' }),
  );
  thead.append(hr);
  table.append(thead);

  const catSum = new Map((ctx.catDelta || []).map((r) => [r.ctgr, r])); // 엔진 소계(재계산 금지, RP-1)
  const byCat = new Map();
  for (const r of rows) { if (!byCat.has(r.ctgr)) byCat.set(r.ctgr, []); byCat.get(r.ctgr).push(r); }

  for (const [ctgr, catRows] of byCat) {
    const tbody = el('tbody', { 'data-ctgr': ctgr });
    const catTr = el('tr', { class: 'ben-cat-row' });
    catTr.append(el('th', { scope: 'rowgroup', class: 'ben-cat-nm', text: CATEGORY_LABEL[ctgr] || ctgr }));
    const cd = catSum.get(ctgr);
    catTr.append(
      el('td', { class: 'ben-cat-sum', text: cd ? cd.sumA + '만원' : '' }),
      el('td', { class: 'ben-cat-sum', text: cd ? cd.sumB + '만원' : '' }),
    );
    const catDeltaTd = el('td', { class: 'ben-cat-delta' });
    const catChip = cd ? deltaChip(cd.delta) : null;
    if (catChip) catDeltaTd.append(catChip);
    catTr.append(catDeltaTd);
    tbody.append(catTr);
    for (const r of catRows) {
      const tr = el('tr', { class: 'ben-row' });
      tr.append(el('th', { scope: 'row', class: 'ben-nm', text: r.nm }));
      const markB = (r.a && !r.b) ? el('span', { class: 'ben-mark ben-mark--lost', text: '사라짐' })
        : (!r.a && r.b) ? el('span', { class: 'ben-mark ben-mark--gained', text: '새로 생김' }) : null;
      const tdA = benCell(r.a, now, 'a', maxAmt, null);
      const tdB = benCell(r.b, now, 'b', maxAmt, markB);
      tr.append(tdA, tdB);
      // 차이 열: 세로로 훑으면 전 항목 승부가 보인다. 정성-정성 행은 공백.
      const amtA = (r.a && !r.a.qual_yn && r.a.benefit_amt != null) ? r.a.benefit_amt : null;
      const amtB = (r.b && !r.b.qual_yn && r.b.benefit_amt != null) ? r.b.benefit_amt : null;
      const deltaTd = el('td', { class: 'ben-row-delta' });
      if (amtA != null || amtB != null) {
        const chip = deltaChip((amtB != null ? amtB : 0) - (amtA != null ? amtA : 0));
        if (chip) deltaTd.append(chip);
      }
      tr.append(deltaTd);
      tbody.append(tr);
    }
    table.append(tbody);
  }
  mountEl.append(table);
  return mountEl;
}

// ── T-06.11.4 renderBands — 항목 배지·밴드 표시·safeUrl 출처(FR-41) ────────
function badgeLabel(item, now) {
  const expired = item.expires_dtm != null && Date.parse(item.expires_dtm) < now;
  if (expired) return '만료'; // RP-2 만료 경고색
  return item.badge_cd === 'official' ? '공식' : '추정';
}
function badgeClass(item, now) {
  const expired = item.expires_dtm != null && Date.parse(item.expires_dtm) < now;
  if (expired) return 'badge badge--expired';
  return item.badge_cd === 'official' ? 'badge badge--official' : 'badge badge--est';
}

export function renderBands(slotResult, benItems, mountEl, now = Date.now()) {
  mountEl.replaceChildren();
  const list = el('ul', { class: 'band-list' });
  for (const item of (benItems || [])) {
    const li = el('li', { class: 'band-item' });
    li.append(el('span', { class: 'band-item-nm', text: item.benefit_nm })); // RP-4 textContent
    li.append(el('span', { class: badgeClass(item, now), text: badgeLabel(item, now) }));
    if (item.badge_src_url_ctnt) {
      const href = safeUrl(item.badge_src_url_ctnt); // RP-3: http/https만 링크화
      if (href) li.append(el('a', { class: 'band-src', href, target: '_blank', rel: 'noopener', text: '출처' }));
      else li.append(el('span', { class: 'band-src band-src--unsafe', text: '출처(비표시)' }));
    }
    list.append(li);
  }
  mountEl.append(list);
  if (slotResult && Array.isArray(slotResult.totalRange)) {
    const [lo, hi] = slotResult.totalRange; // RP-1: 표시만, 계수 재계산 금지
    mountEl.append(el('div', { class: 'band-total', text: '불확실성 범위: ' + lo + ' ~ ' + hi + ' 만원' }));
  }
  return mountEl;
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

// ── T-06.11.1 renderReport — 골격·멱등 재구성·카드 순서(FR-40) ─────────────
function commuteText(commute, ctx) {
  if (!commute || (!commute.a && !commute.b)) return null; // 통근 미입력(0)이면 생략
  const winnerNm = commute.winner === 'tie' ? '동일' : slotLabel(commute.winner, ctx);
  return '편도 통근 ' + commute.a + '분 vs ' + commute.b + '분 — 더 짧음: ' + winnerNm;
}

export function renderReport(report, mountEl, ctx = {}) {
  mountEl.replaceChildren(); // 멱등 재구성(재호출 시 전체 재빌드)

  // 1) 판정 카드
  const vdSection = el('section', { class: 'rp-block rp-vdcard' });
  mountEl.append(vdSection);
  renderVdCard(report.vdCard, vdSection, { sacrifice: report.sacrifice });

  // 2) 총보상 카드 + 불확실성 밴드
  const totalSection = el('section', { class: 'rp-block rp-total' });
  totalSection.append(el('h3', { text: '총보상 비교' }));
  for (const slot of ['a', 'b']) {
    const r = report[slot];
    const row = el('div', { class: 'rp-total-slot', 'data-slot': slot });
    row.append(el('span', { class: 'rp-slot-label', text: slotLabel(slot, ctx) }));
    row.append(el('span', { class: 'rp-slot-total', text: r.total + ' 만원' }));
    totalSection.append(row);
    const bandBody = el('div', { class: 'rp-band-body', 'data-slot': slot });
    totalSection.append(bandBody);
    renderBands(r, (ctx.benS && ctx.benS[slot]) || [], bandBody);
  }
  totalSection.append(el('p', { class: 'rp-total-delta', text: '실효연봉 차이(이직처-현재): ' + report.deltas.effMid + ' 만원' }));
  mountEl.append(totalSection);

  // 3) 시간조정 가치 카드
  const hourlySection = el('section', { class: 'rp-block rp-hourly' });
  hourlySection.append(el('h3', { text: '시간조정 가치' }));
  for (const slot of ['a', 'b']) {
    const r = report[slot];
    const txt = r.hourly == null ? '미산출' : (r.hourly + ' 원/시간'); // hourly===null → "미산출"(FR-40 2a, 무효화 금지)
    hourlySection.append(el('p', { class: 'rp-hourly-slot', 'data-slot': slot, text: slotLabel(slot, ctx) + ': ' + txt }));
  }
  mountEl.append(hourlySection);

  // 4) 워라밸·자율성 카드
  const wlbSection = el('section', { class: 'rp-block rp-wlb' });
  wlbSection.append(el('h3', { text: '워라밸·자율성' }));
  for (const slot of ['a', 'b']) {
    const perks = report[slot].autonomy || [];   // #2: 점수 폐기 → 보유 자율성 요소 나열(재택·유연·무제한휴가)
    const txt = perks.length ? perks.join('·') : '해당 없음';
    wlbSection.append(el('p', { class: 'rp-wlb-slot', 'data-slot': slot, text: slotLabel(slot, ctx) + ' 자율성 요소: ' + txt }));
  }
  const commuteTxt = commuteText(report.commute, ctx);
  if (commuteTxt) wlbSection.append(el('p', { class: 'rp-commute', text: commuteTxt }));
  mountEl.append(wlbSection);

  // 5) 복지 비교 — "한눈에" v2(2026-07-15): 총액 헤드라인(결론 먼저) + 항목 매트릭스
  // (차이 열·행내 미니바). 버터플라이·숫자 델타표는 정보가 헤드라인/매트릭스에 흡수되어
  // 미사용 — renderCatButterfly/renderCatDelta 함수·테스트는 SP-GEN 재사용 여지로 유지.
  const catSection = el('section', { class: 'rp-block rp-catdelta' });
  catSection.append(el('h3', { text: '복지 비교' }));
  const benRows = matchBenefitRows((ctx.benS && ctx.benS.a) || [], (ctx.benS && ctx.benS.b) || []);
  const labels = { a: slotLabel('a', ctx), b: slotLabel('b', ctx) };
  if (benRows.length) { // 항목 없으면 헤드라인·표 모두 생략(무크래시)
    const headBody = el('div', { class: 'rp-benheadline' });
    catSection.append(headBody);
    renderBenefitHeadline(report.catDelta, benRows, headBody, { labels });
    const matrixBody = el('div', { class: 'rp-benmatrix' });
    catSection.append(matrixBody);
    renderBenefitMatrix(benRows, matrixBody, {
      labels,
      catDelta: report.catDelta, // 엔진 소계 표기(재계산 금지)
    });
  }
  mountEl.append(catSection);

  // 6) 정성 복지 표
  const qualSection = el('section', { class: 'rp-block rp-qual' });
  qualSection.append(el('h3', { text: '정성 복지' }));
  for (const slot of ['a', 'b']) {
    const items = (report.qual && report.qual[slot]) || [];
    if (!items.length) continue;
    const ul = el('ul', { class: 'rp-qual-list', 'data-slot': slot });
    for (const it of items) {
      const li = el('li', { class: 'rp-qual-item' });
      li.append(el('span', { class: 'rp-qual-nm', text: it.benefit_nm })); // FR-45 이스케이프
      if (it.qual_desc) li.append(el('span', { class: 'rp-qual-desc', text: it.qual_desc }));
      ul.append(li);
    }
    qualSection.append(ul);
  }
  mountEl.append(qualSection);

  // 7) 경고 배너
  if (report.warnings && report.warnings.length) {
    const warnSection = el('div', { class: 'rp-warnings', role: 'alert' });
    for (const code of report.warnings) {
      warnSection.append(el('p', { class: 'rp-warning-item', 'data-code': code, text: warnCopy(code) }));
    }
    mountEl.append(warnSection);
  }

  // 8) "최근 비교" 저장/불러오기 UI(RP-6)
  if (ctx.recent !== false) {
    const recentBody = el('div', { class: 'rp-recent-body' });
    mountEl.append(recentBody);
    renderRecentUI(recentBody, ctx.recentCtx || {});
  }

  return mountEl;
}
