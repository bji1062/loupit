// web/assets/js/report-calc.js — 이직 계산기 결과 화면(SP-FE-14, 2026-09-23 개편).
//
// 승인 목업(loupit-evidence/2026-09-22-calc-redesign/calc-mockup-fable.html v2)의 구조·문구를 회사 이름과
// 숫자만 일반화해 옮겼다. 엔진(calc.js)이 **이미 계산한** 리포트만 그린다 — calc.js 를 import 하지 않는다
// (SP-FE-1.2 규칙 5). 세 축(연봉·워라밸·복지)은 엔진이 미리 계산해 두었으므로 세그먼트 전환은 재계산 0,
// 다시 그리기만 한다. 「빼고 다시 계산」만 app.js 로 돌아가 compare() 를 다시 돌린다(ctx.onToggle).
//
// 층 규약: L1 = 펼침 · L2 = 접힘(요약 줄이 결론 문장) · L3 = 접힘(전체 비교표·자료). 축이 L1 을 정한다.
// 문구 규칙(IMPL-BRIEF §3 — report-calc.test.js 가 DOM 으로 강제):
//  · 금지어 0건(사라짐·사라져·없어집니다·총연봉·실수령·「95% 신뢰」「95% 확률」·「가족까지 확대」 — 「차이의 95%」 같은 몫 표기는 허용) · 「신뢰구간」은 「통계적 신뢰구간이 아닙니다」 안에서만
//  · 임금 형태(포괄·비포괄)를 회사 사실처럼 말하지 않는다 — 「입력하신 대로 …라면」
//  · 결과 문장은 회사 이름으로 · 금액 없는 칸은 「금액 미등록」(「—」「0」 금지)
//  · 판단하기 어려움(unsure) 티어에서는 판정 카드·첫 타일·보조 줄에 총보상 차액 숫자를 두지 않는다
import { el } from './dom.js';
import { withJosa, fmt, fmt1, fmtSigned, fmtPct } from './josa.js';
import { badgeKind, badgeClassBem, BADGE_LABEL_SHORT } from './badge.js';
import { CATEGORY_LABEL } from './categories.js';

const AXES = [['salary', '연봉'], ['wlb', '워라밸'], ['benefits', '복지']];
const AXIS_LABEL = Object.fromEntries(AXES);
export const BLOCK_ORDER = {
  salary: { l1: ['bridge', 'robust'], l2: ['diffs', 'time', 'parts', 'ledger', 'sens', 'comp'] },
  wlb: { l1: ['time', 'excerpt'], l2: ['bridge', 'robust', 'diffs', 'ledger', 'parts', 'sens', 'comp'] },
  benefits: { l1: ['diffs', 'parts'], l2: ['bridge', 'robust', 'time', 'ledger', 'sens', 'comp'] },
};
const L3 = ['contrast', 'basis'];
const HOURS_WORD = { 40: '거의 없음', 45: '보통', 54: '잦음' };
const WAGE_WORD = { separate: '비포괄', inclusive: '포괄' };
const ASK_TOPIC = {
  compensation: '주식이나 성과 보상', growth: '교육·자기계발 지원', health: '건강·의료 지원', perks: '생활 편의 지원',
  leisure: '여가 지원', family: '가족 지원', work_env: '업무 환경 지원', time_off: '휴가 제도', flexibility: '유연근무 제도',
};

const m = (n) => fmt(n) + '만원';
// 오차 범위 표기 — 폭이 0 으로 보이면(금액 행을 전부 뺀 경우 등) 「(±0)」「X ~ X」 대신 아무것도 쓰지 않는다.
const hasBand = (band) => fmt(abs(band)) !== '0';
const pmTxt = (band) => (hasBand(band) ? '(±' + fmt(band) + ')' : '');
const abs = (n) => Math.abs(Number(n) || 0);
const cat = (c) => CATEGORY_LABEL[c] || CATEGORY_LABEL.perks;
const rate1 = (r) => (Number.isInteger(r) ? String(Math.abs(r)) : Math.abs(r).toFixed(1)) + '%';
const b = (text) => el('b', { text });
const sym = (slot) => el('span', { class: 'calc-sym calc-sym-' + slot, 'aria-hidden': 'true' });
const descOf = (it) => String((it && (it.qual_desc_ctnt || it.note_ctnt)) || '').replace(/\s*\(추정\)\s*$/, '');
const amtOf = (it) => (it && !it.qual_yn && it.benefit_amt != null && Number.isFinite(Number(it.benefit_amt)) ? Number(it.benefit_amt) : null);
const keyOf = (it) => (it ? it.benefit_cd || it.benefit_nm : null);
const directional = (tier) => tier === 'a' || tier === 'b';
const CIRCLED = ['①', '②', '③', '④', '⑤', '⑥'];

// 원문 한 줄 — 「가족·배우자·자녀」는 <mark> 로만 강조한다(해석 문장을 만들지 않는다).
function srcText(text, cls = 'calc-src') {
  const node = el('span', { class: cls });
  const parts = String(text || '').split(/(가족|배우자|자녀)/);
  for (const p of parts) {
    if (!p) continue;
    if (/^(가족|배우자|자녀)$/.test(p)) node.append(el('mark', { text: p }));
    else node.append(p);
  }
  return node;
}

// 금액 칸의 배지 — 「공식·추정」은 **금액 신뢰도(amt_source)** 다(밴드 ±5%·±20% 와 같은 기준, DEC-2). 번들의
// badge_cd 는 출처 계보라 거의 전부 official 이다. 계보가 따로 말할 것(만료·재직자 수정·등록)이 있으면 그것을 단다.
function badge(item, now) {
  const lineage = badgeKind(item, { now });
  const kind = lineage === 'expired' || lineage === 'member' || lineage === 'edited' ? lineage : (item && item.amt_source === 'stated' ? 'official' : 'est');
  return el('span', { class: badgeClassBem(kind), text: BADGE_LABEL_SHORT[kind] });
}
const byAmtDesc = (get) => (x, y) => (amtOf(get(y)) || 0) - (amtOf(get(x)) || 0);
function amountCell(item, now) {
  const v = amtOf(item);
  if (v == null) return el('span', { class: 'calc-noamt', text: '금액 미등록' });
  const s = el('span', { class: 'calc-amt' }, m(v) + ' ');
  s.append(badge(item, now));
  return s;
}

// ── 문맥(회사 이름·입력·현재 결과) ────────────────────────────────────────────
function makeCtx(report, ctx) {
  const matched = ctx.matched || {};
  const nm = {
    a: (matched.a && matched.a.comp_nm) || '현재 직장',
    b: (matched.b && matched.b.comp_nm) || '이직 후보',
  };
  const now = ctx.now != null ? ctx.now : Date.now();
  const input = ctx.input || {};
  const ws = input.ws || {};
  const benS = ctx.benS || { a: [], b: [] };
  const legalKeys = { a: new Set(((report.pairs && report.pairs.legal.a) || []).map(keyOf)), b: new Set(((report.pairs && report.pairs.legal.b) || []).map(keyOf)) };
  // 사용자가 뺀 항목(checked=false) — 법정 행은 사용자의 뺌이 아니다.
  const excluded = [];
  for (const slot of ['a', 'b']) {
    for (const it of benS[slot] || []) {
      if (it && it.checked === false && !legalKeys[slot].has(keyOf(it))) excluded.push({ slot, it });
    }
  }
  const isOff = (slot, it) => !!(it && (benS[slot] || []).some((x) => keyOf(x) === keyOf(it) && x.checked === false));
  // 「N건」은 사용자가 누른 **행** 수(엔진 exclusionSummary — 두 회사 금액 짝은 1건, LOW-4).
  const amtSum = (slot) => excluded.filter((x) => x.slot === slot).reduce((acc, x) => acc + (amtOf(x.it) || 0), 0);
  const ex = report.exclusions || { rows: excluded.length, a: { amt: amtSum('a') }, b: { amt: amtSum('b') } };
  return { report, ctx, nm, now, input, ws, benS, excluded, ex, isOff, J: withJosa };
}

// 원화 차이의 방향 말 — 이직(A→B) 관점.
const moreLess = (d) => (d < 0 ? '줄어듭니다' : '늘어납니다');

// ══ #0 조건 줄 ══════════════════════════════════════════════════════════════
function hoursWord(h) { return h ? (HOURS_WORD[h] || '주 ' + fmt1(h) + '시간') : null; }
function condLine(X) {
  const { nm, input, ws, report } = X;
  const box = el('div', { class: 'calc-cond' });
  const pair = el('span', { class: 'calc-cond-pair' }, sym('a'), b(nm.a), ' → ', sym('b'), b(nm.b));
  box.append(pair);
  const add = (text) => { box.append(el('span', { class: 'calc-cond-sep', 'aria-hidden': 'true', text: '·' }), el('span', { text })); };
  if (input.salA) add('연봉 ' + m(input.salA));
  if (input.rate != null) add('상승률 ' + (input.rate >= 0 ? '+' : '−') + rate1(input.rate));
  const side = (slot) => {
    const h = report[slot].wsHours;
    if (!h) return '미입력';
    const w = (ws[slot] || {}).wage;
    return hoursWord(h) + '(' + (WAGE_WORD[w] || '야근수당 미선택') + ')';
  };
  if (report.a.wsHours || report.b.wsHours) add('야근 ' + side('a') + ' → ' + side('b'));
  else add('야근 미입력');
  const c = input.commute || {};
  if (c.a != null || c.b != null) add('통근 ' + (c.a != null ? fmt(c.a) : '미입력') + ' → ' + (c.b != null ? fmt(c.b) + '분' : '미입력'));
  if (input.tenureYears != null) add('근속 ' + fmt1(input.tenureYears) + '년');
  const edit = el('button', { type: 'button', class: 'calc-link calc-cond-edit', text: '조건 고치기' });
  edit.addEventListener('click', () => { if (typeof X.ctx.onEdit === 'function') X.ctx.onEdit(); });
  box.append(edit);
  return box;
}

// ══ #1 축 세그먼트 ══════════════════════════════════════════════════════════
function axisBar(X, axis, onPick) {
  const wrap = el('div', { class: 'calc-axisbar' });
  const seg = el('div', { class: 'calc-chips calc-seg', role: 'radiogroup', 'aria-label': '비교 기준', id: 'calc-out-seg' });
  const btns = AXES.map(([key, label]) => {
    const btn = el('button', {
      type: 'button', class: 'calc-chip', role: 'radio', 'data-axis': key, id: 'calc-out-' + key,
      'aria-checked': String(key === axis), tabindex: key === axis ? '0' : '-1', text: label,
    });
    btn.addEventListener('click', () => { if (key !== axis) onPick(key); });
    btn.addEventListener('keydown', (e) => {
      const dir = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
      if (!dir) return;
      e.preventDefault();
      const i = AXES.findIndex(([k]) => k === key);
      onPick(AXES[(i + dir + AXES.length) % AXES.length][0]);
    });
    return btn;
  });
  seg.append(...btns);
  wrap.append(seg, el('p', { class: 'calc-help', text: '무엇을 중요하게 보느냐에 따라 결론이 달라집니다. 눌러서 바꿔 보세요.' }));
  return wrap;
}

// ══ #2 판정 카드 ════════════════════════════════════════════════════════════
function card(axis, tone, badgeText, lv1) {
  const sec = el('section', { class: 'calc-card calc-vd tone-' + tone, 'aria-label': AXIS_LABEL[axis] + (axis === 'salary' ? '으로' : '로') + ' 본 결론', 'data-axis': axis });
  const top = el('div', { class: 'calc-vd-top' });
  top.append(el('span', { class: 'calc-bd calc-bd-' + tone, text: badgeText }), el('span', { class: 'calc-lv', text: lv1 }));
  sec.append(top);
  return sec;
}
const line = (cls, ...kids) => el('p', { class: 'calc-line' + (cls ? ' ' + cls : '') }, ...kids);
function how(text) {
  const d = el('details', { class: 'calc-how' });
  d.append(el('summary', { text: '이렇게 계산했습니다' }), el('p', { text }));
  return d;
}
function chip(...kids) { return el('span', { class: 'calc-stat' }, ...kids); }
const hatch = () => el('span', { class: 'calc-hatch-sw', 'aria-hidden': 'true' });

// 총보상 차이의 원인(연봉 밖) — sign<0: 줄이는 원인, >0: 늘리는 원인. { text, note }.
// 한쪽 주 근무시간만 없으면 야근수당은 **아는 쪽만** 계산한 값이라 「야근수당 차이」가 아니다(LOW-9) — 그 회사에서
// 받는 야근수당이라 부르고, 모르는 쪽은 모른다고(note) 적는다.
function causes(X, v, sign) {
  const hit = (x) => Math.sign(x) === sign && x !== 0;
  const miss = ['a', 'b'].filter((s) => !X.report[s].wsHours);
  const benHit = hit(v.parts.ben), otHit = hit(v.parts.ot);
  if (otHit && miss.length === 1) {
    const known = miss[0] === 'a' ? 'b' : 'a';
    const ot = X.nm[known] + '에서 받는 야근수당';
    return { text: benHit ? '복지 차이와 ' + ot : ot, note: '(' + X.nm[miss[0]] + ' 쪽은 주 근무시간이 없어 계산하지 않음)' };
  }
  const out = [];
  if (benHit) out.push('복지');
  if (otHit) out.push('야근수당');
  return { text: out.length ? out.join('와 ') + ' 차이' : '복지 차이', note: '' };
}
const causeText = (X, v, sign) => { const c = causes(X, v, sign); return c.text + c.note; };

// 「NAVER에만 금액이 등록된」 — 혼합 항목이 한쪽으로만 쏠렸을 때 그 회사, 섞였으면 「한쪽 회사에만」.
function onlyRegistered(X) {
  const side = X.report.axes.benefits.mixed.side;
  if (side === 'a') return X.nm.a + '에만 금액이 등록된';
  if (side === 'b') return X.nm.b + '에만 금액이 등록된';
  return '한쪽 회사에만 금액이 등록된';
}
function otherSide(X) { // 금액이 없는 쪽
  const side = X.report.axes.benefits.mixed.side;
  return side === 'a' ? X.nm.b : side === 'b' ? X.nm.a : null;
}

function hoursMissingLine(X) {
  const { report, nm } = X;
  const miss = ['a', 'b'].filter((s) => !report[s].wsHours);
  if (!miss.length) return null;
  if (miss.length === 2) return line('calc-line-note', '입력하신 조건에 주 근무시간이 없어, 야근수당과 시간당 총보상은 계산하지 않았습니다.');
  const who = nm[miss[0]];
  return line('calc-line-note', '입력하신 조건에 ' + who + '의 주 근무시간이 없어, ' + who + '의 야근수당과 시간당 총보상은 계산하지 않았습니다.');
}

function wageCaseLabel(X, c, slots) {
  return slots.map((s) => withJosa(X.nm[s], '이/가') + ' ' + (c.wage[s] === 'separate' ? '비포괄' : '포괄')).join(' · ') + '이면';
}
function tierPhrase(c) {
  if (c.tier === 'unsure') return c.unsureBy === 'guard' ? '판단하기 어렵습니다(한쪽에만 등록된 금액을 빼면 방향이 바뀜)' : '판단하기 어렵습니다(오차 범위가 겹침)';
  if (c.tier === 'near') return '거의 같습니다(연 ' + m(abs(c.diff)) + ' 차이)';
  return '총보상 연 ' + m(abs(c.diff)) + ' ' + (c.diff < 0 ? '감소' : '증가');
}
// 야근수당 미선택(결정 4)이면 core 와 그것으로 도는 L2(총보상 흐름·확실성·협상·조건 바꿔 보기·시간당·고정 칸)는 미선택 쪽을
// **포괄(야근수당 0)** 로 본 값이다. 카드는 두 경우를 말하므로 그 가정을 밝힌다 — 밝히지 않으면 카드는 「늘지 줄지는 …에 달려
// 있습니다」인데 아래 요약은 「어느 경우에도 LS 쪽이 더 많아지지는 않습니다」처럼 반대로 말한다(재확인 R-1).
function assumeIf(X) {
  const w = X.report.wage;
  if (!w) return '';
  return w.slots.length === 2 ? '두 회사가 모두 포괄이라면' : withJosa(X.nm[w.slots[0]], '이/가') + ' 포괄이라면';
}
const withAssume = (X, text) => (X.report.wage ? assumeIf(X) + ', ' + text : text);
function assumeLine(X) {
  const w = X.report.wage;
  if (!w) return null;
  const who = w.slots.length === 2 ? '두 회사의' : X.nm[w.slots[0]] + '의';
  return el('p', {
    class: 'calc-assume',
    text: '아래 숫자는 입력하신 조건에 ' + who + ' 야근수당 여부가 없어 ' + (w.slots.length === 2 ? '둘 다 ' : '')
      + '포괄(야근수당을 따로 주지 않음)이라고 보고 계산했습니다. 따로 주는 경우는 연봉 기준 화면에 나란히 적었습니다.',
  });
}

function wageCasesBox(X) {
  const w = X.report.wage;
  if (!w) return null;
  const who = w.slots.length === 2 ? '두 회사' : X.nm[w.slots[0]];
  const box = el('div', { class: 'calc-wagecases' });
  box.append(el('p', {
    class: 'calc-wagecases-h',
    text: '입력하신 조건에 ' + who + '의 야근수당 여부(포괄·비포괄)가 없어 ' + (w.cases.length === 4 ? '네' : '두') + ' 경우를 모두 계산했습니다'
      + (X.report.axes.salary.tier === 'range'
        ? ' — 어느 쪽이든 총보상은 ' + (w.dir < 0 ? '줄어들고, 얼마나 줄지만' : '늘어나고, 얼마나 늘지만') + ' 달라집니다.'
        : w.agree ? ' — 어느 쪽이든 결론은 같습니다.' : ' — 어느 쪽이냐에 따라 결론이 달라집니다.'),
  }));
  const ul = el('ul', { class: 'calc-wagecases-list' });
  for (const c of w.cases) {
    ul.append(el('li', {}, el('span', { class: 'calc-wc-k', text: wageCaseLabel(X, c, w.slots) }), ' → ', b(tierPhrase(c))));
  }
  box.append(ul);
  return box;
}

function flipLine(X) {
  const v = X.report.axes.salary;
  const f = v.flip;
  if (!f || f.key !== 'b_wage_flip') return null;
  // 다른 슬롯의 야근수당이 미선택이면 이 줄은 그 슬롯을 포괄로 본 값이라 카드의 두 경우와 섞인다 — 「조건 바꿔 보기」(가정 머리말 아래)에만 둔다.
  if (X.report.wage) return null;
  const B = X.nm.b;
  const d2 = f.totalDiff;
  const win = d2 > 0 ? B : X.nm.a;
  const tail = f.result === 'flip'
    ? '결론이 바뀌어 ' + withJosa(win, '이/가') + ' 연 ' + m(abs(d2)) + ' 더 많아집니다.'
    : f.result === 'decide' ? withJosa(win, '이/가') + ' 연 ' + m(abs(d2)) + ' 더 많아져, 어느 쪽이 많은지 말할 수 있게 됩니다.'
      : f.tier === 'near' ? '두 회사 총보상이 거의 같아집니다(연 ' + m(abs(d2)) + ' 차이).' : '어느 쪽이 많다고 말하기 어려워집니다.';
  if (f.to === 'separate') {
    return line('calc-line-warn', '입력하신 대로 ' + withJosa(B, '이/가') + ' 포괄임금제라면 야근수당이 따로 없습니다. ',
      b('만약 야근수당을 따로 준다면 ' + tail));
  }
  return line('calc-line-warn', '입력하신 대로 ' + withJosa(B, '이/가') + ' 야근수당을 따로 준다면 연 ' + m(X.report.b.otPay) + '이 더해집니다. ',
    b('만약 포괄임금제라면 ' + tail));
}

// 「판단하기 어렵습니다」의 이유가 부호 갈림(가드)일 때의 한 문장(MED-1·2) — 「Y가 많아져」는 뺀 계산이 방향 티어일
// 때만이다. noun: 앞 절의 주어('총보상' → 「NAVER의 총보상이」, 없으면 「NAVER가」).
function guardClause(X, d, ex, n, noun = null) {
  const { nm } = X;
  const who = (s) => (noun ? nm[s] + '의 ' + withJosa(noun, '이/가') : withJosa(nm[s], '이/가'));
  const head = (X.ex && X.ex.rows ? '빼고 남은 금액 그대로 계산하면 ' : '등록된 금액 그대로 계산하면 ') + who(d < 0 ? 'a' : 'b') + ' 많지만, ' + onlyRegistered(X) + ' ' + n + '건을 빼면 ';
  if (!ex || ex.diff === 0) return head + '두 회사가 같아져';
  if (directional(ex.tier)) return head + withJosa(ex.diff < 0 ? nm.a : nm.b, '이/가') + ' 많아져';
  return head + (ex.tier === 'unsure' ? '방향이 바뀝니다(바뀐 차이는 오차 범위 안입니다). 그래서' : '방향이 바뀝니다(바뀐 차이는 크지 않습니다). 그래서');
}
// 빼고 계산한 차이가 딱 0 이면 「방향이 바뀝니다」가 아니라 「두 회사가 같아집니다」(재확인 R-3 — 카드만 그렇게 말했다).
const guardShort = (X, n, ex) => '한쪽에만 금액이 등록된 ' + n + '건을 빼면 ' + (ex && ex.diff === 0 ? '두 회사가 같아집니다' : '방향이 바뀝니다');
// 야근수당 미선택 — 누가 야근수당을 주는지(주어) · 같은 방향일 때의 범위 글자(MED-3).
function wageWho(X, w) {
  const { nm } = X;
  return w.slots.length === 2 ? '두 회사가 야근수당을 따로 주는지'
    : w.slots[0] === 'b' ? withJosa(nm.b, '이/가') + ' 야근수당을 따로 주는지' : nm.a + '에서 야근수당을 따로 받는지';
}
const spanText = (span) => fmtSigned(span[0]) + ' ~ ' + fmtSigned(span[1]);
function dirBadge(shape, dir) {
  if (shape === 'reverse') return dir < 0 ? '연봉은 오르지만 총보상은 줄어듭니다' : '연봉은 줄지만 총보상은 늘어납니다';
  if (shape === 'flat') return dir < 0 ? '총보상은 줄어듭니다' : '총보상은 늘어납니다';
  return dir > 0 ? '연봉도 총보상도 늘어납니다' : '연봉도 총보상도 줄어듭니다';
}

function salaryCard(X) {
  const { report, nm } = X;
  const v = report.axes.salary;
  const d = v.d;
  const r = X.input.rate;
  const up = v.salMid > 0, down = v.salMid < 0;
  const wageSplit = v.tier === 'depends' || v.tier === 'range';
  let tone = 'neutral', badgeText = '판단하기 어렵습니다';
  const hl = el('p', { class: 'calc-hl' });
  const salPhrase = up ? '연봉은 ' + rate1(r) + ' 올라 ' + m(v.salB) + '이 되' : down ? '연봉은 ' + rate1(r) + ' 줄어 ' + m(v.salB) + '이 되' : '연봉은 그대로(' + m(v.salB) + ')이';
  if (v.tier === 'depends' && !v.wage.anyDirectional) {
    // 어느 경우도 한쪽을 가리키지 않는다 — 「늘지 줄지는 …에 달려 있다」가 아니다.
    hl.append('입력하신 조건으로는 야근수당을 따로 주든 아니든 두 회사 총보상이 비슷해, ', b('어느 쪽이 많다고 말하기 어렵습니다.'));
  } else if (v.tier === 'depends') {
    tone = 'warn'; badgeText = '야근수당에 따라 결론이 달라집니다';
    // 경우들이 실제로 가리키는 것만 말한다(재확인 R-4) — {늘어남, 거의 같음} 은 「늘지 줄지」가 아니라 「거의 같을지 늘지」.
    const cs = v.wage.cases;
    const inc = cs.some((c) => c.tier === 'b'), dec = cs.some((c) => c.tier === 'a'), nr = cs.some((c) => c.tier === 'near');
    const q = inc && dec ? '늘지 줄지는 ' : inc ? (nr ? '거의 같을지 늘지는 ' : '늘어날지는 ') : (nr ? '거의 같을지 줄지는 ' : '줄어들지는 ');
    hl.append('입력하신 조건으로 계산하면, ' + salPhrase + '지만 총보상이 ' + q, b(wageWho(X, v.wage) + '에 달려 있습니다.'));
  } else if (v.tier === 'range') {
    // 경우마다 같은 쪽 — 「얼마나」만 야근수당에 달렸다(MED-3). 방향 배지 + 범위.
    const dir = v.wage.dir;
    tone = dir < 0 ? 'neg' : 'pos';
    badgeText = dirBadge(v.shape, dir);
    const conj = v.shape === 'same' ? '고, 총보상도 ' : v.shape === 'reverse' ? '지만 총보상은 오히려 ' : '지만 총보상은 ';
    hl.append('입력하신 조건으로 계산하면, ' + salPhrase + conj, b(moreLess(dir) + '.'),
      ' 얼마나 ' + (dir < 0 ? '줄지는 ' : '늘지는 ') + wageWho(X, v.wage) + '에 달려 있습니다 — 연 ' + spanText(v.span) + '만원.');
  } else if (v.tier === 'unsure' && v.unsureBy === 'guard') {
    hl.append(guardClause(X, d, v.guard, report.axes.benefits.mixed.count, '총보상') + ' ', b('어느 쪽이 낫다고 말하기 어렵습니다.'));
  } else if (v.tier === 'unsure') {
    hl.append('입력하신 조건으로는 어느 쪽 총보상이 더 많은지 ', b('말하기 어렵습니다.'), ' 두 회사의 오차 범위가 겹칩니다.');
  } else if (v.tier === 'near' && v.nearKind === 'weak') {
    // 오차 범위를 겨우 넘는 차이 — 금액은 작지 않을 수 있어 「거의 같다」고 부르지 않는다.
    badgeText = '차이가 크지 않습니다';
    hl.append('입력하신 조건으로 계산하면 ' + nm[d < 0 ? 'a' : 'b'] + '의 총보상이 ', b('연 ' + m(abs(d)) + ' 많지만'), ', 오차 범위(±' + fmt(v.band) + ')를 겨우 넘는 차이라 한쪽이 낫다고 말하기엔 약합니다.');
  } else if (v.tier === 'near') {
    badgeText = '거의 같습니다';
    const pct = report.a.total ? (abs(d) / report.a.total * 100).toFixed(1) : '0';
    hl.append('입력하신 조건으로 계산하면 두 회사의 총보상은 거의 같습니다 — 차이는 ', b('연 ' + m(abs(d))), '으로, ' + nm.a + ' 총보상의 ' + pct + '%입니다.');
  } else {
    tone = d < 0 ? 'neg' : 'pos';
    if (v.shape === 'reverse' && d < 0) {
      badgeText = '연봉은 오르지만 총보상은 줄어듭니다';
      hl.append('입력하신 조건으로 계산하면, ' + salPhrase + '지만 ' + causeText(X, v, -1) + ' 때문에 총보상은 오히려 ', b('연 ' + m(abs(d)) + ' 줄어듭니다.'));
    } else if (v.shape === 'reverse') {
      badgeText = '연봉은 줄지만 총보상은 늘어납니다';
      hl.append('입력하신 조건으로 계산하면, ' + salPhrase + '지만 ' + causeText(X, v, 1) + ' 덕분에 총보상은 오히려 ', b('연 ' + m(d) + ' 늘어납니다.'));
    } else if (v.shape === 'flat') {
      badgeText = d < 0 ? '총보상은 줄어듭니다' : '총보상은 늘어납니다';
      hl.append('입력하신 조건으로 계산하면, ' + salPhrase + '지만 ' + causeText(X, v, Math.sign(d)) + ' 때문에 총보상은 ', b('연 ' + m(abs(d)) + ' ' + moreLess(d) + '.'));
    } else {
      badgeText = d > 0 ? '연봉도 총보상도 늘어납니다' : '연봉도 총보상도 줄어듭니다';
      hl.append('입력하신 조건으로 계산하면, ' + salPhrase + '고, 복지와 야근수당까지 더한 총보상도 ', b('연 ' + m(abs(d)) + ' ' + moreLess(d) + '.'));
    }
  }
  const sec = card('salary', tone, badgeText, '연봉 기준');
  sec.append(hl);
  if (v.tier !== 'unsure') {
    const rates = el('div', { class: 'calc-rates' });
    rates.append(el('span', { class: 'calc-rates-k', text: '연봉 인상률' }), el('span', { class: 'calc-rates-v ' + (up ? 'calc-pos' : down ? 'calc-neg' : ''), text: fmtPct(v.salMid / v.salA) || '0.0%' }));
    if (!wageSplit && v.effRate != null) {
      rates.append(el('span', { class: 'calc-rates-k', text: '총보상 증감률' }), el('span', { class: 'calc-rates-v ' + (v.effRate < 0 ? 'calc-neg' : 'calc-pos'), text: fmtPct(v.effRate) }));
    }
    sec.append(rates);
    const ev = el('div', { class: 'calc-evid' });
    ev.append(chip('연봉 ', el('b', { class: v.salMid < 0 ? 'calc-neg' : 'calc-pos', text: fmtSigned(v.salMid) })));
    const benChip = chip('복지 ', el('b', { class: v.parts.ben < 0 ? 'calc-neg' : 'calc-pos', text: fmtSigned(v.parts.ben) }));
    const bm = report.axes.benefits.mixed;
    if (bm.count && v.parts.mixed) {
      const miss = otherSide(X);
      benChip.append(' ', el('span', { class: 'calc-muted' }, '(그중 ', hatch(), fmt(abs(v.parts.mixed)) + '은 ' + (miss ? miss + ' 금액 미등록' : '한쪽만 금액 등록') + ')'));
    }
    ev.append(benChip);
    if (!wageSplit && (report.a.otPay || report.b.otPay)) {
      ev.append(chip('야근수당 ', el('b', { class: v.parts.ot < 0 ? 'calc-neg' : 'calc-pos', text: fmtSigned(v.parts.ot) })));
    }
    sec.append(ev);
  }
  const wc = wageCasesBox(X);
  if (wc) sec.append(wc);
  const fl = flipLine(X);
  if (fl) sec.append(fl);
  const hm = hoursMissingLine(X);
  if (hm) sec.append(hm);
  const ben = report.axes.benefits;
  let howText = '실효 총보상은 연봉에 복지를 돈으로 환산한 금액(금액이 등록된 복지만)과 야근수당(입력하신 조건 기준)을 더한 값입니다. '
    + '금액이 등록되지 않은 복지(' + nm.a + ' ' + ben.noAmt.a + '개 · ' + nm.b + ' ' + ben.noAmt.b + '개)는 0으로 계산했습니다. '
    + '가치가 없다는 뜻이 아니라 금액을 알 수 없다는 뜻입니다.';
  const legalN = (report.basis.a.legal || 0) + (report.basis.b.legal || 0);
  if (legalN) howText += ' 법으로 모든 회사에 정해진 제도만 적힌 항목(' + legalN + '개)은 복지로 세지 않았습니다.';
  sec.append(how(howText));
  return sec;
}

// 워라밸 판정 문장의 재료.
function wlbHeadline(X, hl) {
  const { report, nm } = X;
  const v = report.axes.wlb;
  const h = v.hours, c = v.commute;
  const W = v.tier === 'a' ? nm.a : v.tier === 'b' ? nm.b : null;
  const conclude = W ? ' 시간으로 보면 ' + withJosa(W, '이/가') + ' 낫습니다.' : '';
  const commuteTail = (moreSlot) => {
    if (!c) return '.';
    if (c.annDiff === 0) return ', 출퇴근 시간은 같습니다.';
    const cm = c.annDiff > 0 ? 'b' : 'a';
    if (cm === moreSlot) return null; // 같은 회사가 둘 다 더 — 굵게 이어 쓴다
    return '. 출퇴근은 ' + nm[cm] + '에서 1년에 ' + fmt(abs(c.annDiff)) + '시간 더 걸립니다.';
  };
  if (v.decidedBy === 'hours') {
    const more = h.weekDiff > 0 ? 'b' : 'a';
    hl.append('입력하신 야근 시간대로라면 ' + nm[more] + '에서는 일주일에 ', b(fmt1(abs(h.weekDiff)) + '시간'),
      '(1년이면 ' + fmt(abs(h.annDiff)) + '시간, 약 ' + fmt(h.days) + '일치) 더 일하고');
    const tail = commuteTail(more);
    if (tail == null) hl.append(', 출퇴근에도 1년에 ', b(fmt(abs(c.annDiff)) + '시간'), '을 더 씁니다.' + conclude);
    else hl.append(tail + conclude);
    return;
  }
  if (v.decidedBy === 'commute') {
    const more = c.annDiff > 0 ? 'b' : 'a';
    const pre = h ? (h.weekDiff === 0 ? '입력하신 근무시간은 두 회사가 같고, ' : '입력하신 근무시간 차이는 주 ' + fmt1(abs(h.weekDiff)) + '시간뿐이고, ')
      : '주 근무시간은 입력하지 않으셨고, 입력하신 통근 시간대로라면 ';
    hl.append(pre + nm[more] + '에서 출퇴근에 1년에 ', b(fmt(abs(c.annDiff)) + '시간'), '을 더 씁니다.' + conclude);
    return;
  }
  if (v.decidedBy === 'autonomy') {
    const perks = (v.tier === 'a' ? v.autonomy.perksA : v.autonomy.perksB).join('·');
    hl.append('입력하신 조건으로는 근무시간 차이를 말할 수 없지만, 회사에 등록된 정보로는 ', b(withJosa(W, '이/가') + ' 근무 방식이 더 자유롭습니다'),
      ' — ' + W + '에는 ' + withJosa(perks, '이/가') + ' 모두 있습니다.');
    return;
  }
  if (v.decidedBy === 'count') {
    hl.append('입력하신 조건으로는 근무시간 차이를 말할 수 없지만, 등록된 항목으로는 휴가·근무제도가 ',
      b(W + '에 ' + abs(v.count.a - v.count.b) + '개 더 많습니다.'));
    return;
  }
  if (!h && !c) hl.append('입력하신 조건으로는 시간 차이를 말할 수 없습니다 — 야근 빈도와 통근을 넣으면 계산합니다.');
  else hl.append('입력하신 근무·통근 시간은 거의 같아, ', b('시간으로는 어느 쪽이 낫다고 말하기 어렵습니다.'));
}

function autonomyLine(X) {
  const { report, nm, ctx } = X;
  const a = report.axes.wlb.autonomy;
  const p = line('');
  p.append('근무 시간 자율성: ');
  const join = (arr) => arr.join('·');
  if (a.winner === 'a' || a.winner === 'b') {
    const W = nm[a.winner];
    const perks = a.winner === 'a' ? a.perksA : a.perksB;
    p.append(W + '에는 ' + withJosa(join(perks), '이/가') + (perks.length > 1 ? ' 모두' : '') + ' 있어 ', b('더 자유롭습니다.')); // 하나면 「모두」 없이
  } else if (!a.perksA.length && !a.perksB.length) {
    p.append('두 회사 모두 유연근무·재택근무가 등록되어 있지 않아 ', b('우열을 가릴 수 없습니다.'));
  } else if (join(a.perksA) === join(a.perksB)) {
    p.append('두 회사 모두 ' + withJosa(join(a.perksA), '이/가') + ' 있어 ', b('우열을 가릴 수 없습니다.'));
  } else {
    p.append(nm.a + '에는 ' + (join(a.perksA) || '등록 없음') + ', ' + nm.b + '에는 ' + (join(a.perksB) || '등록 없음') + ' — ', b('우열을 가릴 수 없습니다.'));
  }
  const hints = (ctx.remoteHints) || {};
  for (const s of ['a', 'b']) {
    const hint = hints[s];
    if (!hint) continue;
    p.append(' ', el('span', { class: 'calc-muted calc-small', text: '※ ' + nm[s] + ' 「' + hint.name + '」 설명에는 원격 근무 선택이 있는데, 등록 정보에는 재택근무가 ‘없음’으로 되어 있습니다. 실제와 다르면 조건을 고쳐 주세요.' }));
  }
  return p;
}

function moneyLine(X) {
  const { report, nm } = X;
  const v = report.axes.wlb;
  if (!directional(v.tier)) return null;
  const s = report.axes.salary;
  const W = nm[v.tier];
  const stay = v.tier === 'a';
  const lead = stay ? W + '에 남는다고' : withJosa(W, '로/으로') + ' 옮긴다고';
  if (s.tier === 'depends') return line('', '총보상은 야근수당을 따로 받는지에 따라 달라집니다(연봉 기준 화면에서 두 경우를 나란히 보여 드립니다).');
  if (s.tier === 'range') {
    const amt = '연 ' + fmt(abs(s.span[0])) + ' ~ ' + m(abs(s.span[1]));
    if ((s.wage.dir > 0 ? 'b' : 'a') === v.tier) return line('', lead + ' ', b('손해 보는 돈도 없습니다'), ' — 총보상도 ' + withJosa(W, '이/가') + ' ' + amt + ' 많습니다(야근수당에 따라 다름).');
    return line('', (stay ? W + '에 남으면' : withJosa(W, '로/으로') + ' 옮기면') + ' 그 대신 ', b('총보상 ' + amt + '을 포기하는 셈입니다'), '(야근수당에 따라 다름).');
  }
  if (s.tier === 'unsure') {
    return line('', '총보상은 어느 쪽이 많은지 말하기 어렵습니다 — '
      + (s.unsureBy === 'guard' ? guardShort(X, X.report.axes.benefits.mixed.count, s.guard) + '.' : '오차 범위가 겹칩니다.'));
  }
  if (s.tier === 'near') return line('', s.nearKind === 'weak' ? '총보상 차이(연 ' + m(abs(s.d)) + ')는 오차 범위를 겨우 넘는 정도입니다.' : '총보상은 두 회사가 거의 같습니다(연 ' + m(abs(s.d)) + ' 차이).');
  if (s.tier === v.tier) return line('', lead + ' ', b('손해 보는 돈도 없습니다'), ' — 총보상도 ' + withJosa(W, '이/가') + ' 연 ' + m(abs(s.d)) + ' 많습니다.');
  return line('', (stay ? W + '에 남으면' : withJosa(W, '로/으로') + ' 옮기면') + ' 그 대신 ', b('총보상 연 ' + m(abs(s.d)) + '을 포기하는 셈입니다.'));
}

function wlbWarnLine(X) {
  const { report, nm, ws } = X;
  const out = [];
  for (const s of ['a', 'b']) {
    const w = (ws[s] || {}).wage;
    const h = report[s].wsHours;
    if (h > 40 && w === 'inclusive') {
      out.push(line('calc-line-warn', '입력하신 대로 ' + withJosa(nm[s], '이/가') + ' 포괄임금제라면, 주 ' + fmt1(h) + '시간을 일해도 야근수당은 따로 계산하지 않았습니다.'));
    } else if (h > 40 && w == null) {
      out.push(line('calc-line-warn', '입력하신 조건에 ' + nm[s] + '의 야근수당 여부가 없어, 포괄·비포괄 두 경우는 연봉 기준 화면에 나란히 적었습니다.'));
    }
  }
  return out;
}

function wlbCard(X) {
  const { report, nm } = X;
  const v = report.axes.wlb;
  const dir = directional(v.tier);
  const sec = card('wlb', dir ? v.tier : 'neutral', dir ? '워라밸로 보면 · ' + withJosa(nm[v.tier], '이/가') + ' 낫습니다' : '워라밸로 보면 · 가리기 어렵습니다', '시간으로 보면');
  const hl = el('p', { class: 'calc-hl' });
  wlbHeadline(X, hl);
  sec.append(hl);
  const ev = el('div', { class: 'calc-evid' });
  if (v.hours) ev.append(chip('주 근무 ' + fmt1(v.hours.a) + ' → ' + fmt1(v.hours.b) + '시간'));
  if (v.commute) ev.append(chip('통근 연 ' + fmt(v.commute.annA) + ' → ' + fmt(v.commute.annB) + '시간'));
  ev.append(chip('휴가·근무제도 ' + v.count.a + '개 : ' + v.count.b + '개'));
  sec.append(ev, autonomyLine(X));
  const ml = moneyLine(X);
  if (ml) sec.append(ml);
  for (const w of wlbWarnLine(X)) sec.append(w);
  sec.append(how('1년 근무시간은 주 근무시간 × 52주로 계산했습니다. 통근은 편도 시간 × 2 × 연 240일로 시간만 세고, 돈으로 바꾸지는 않았습니다. '
    + '휴가·근무제도 개수는 회사에 등록된 항목 수입니다. 판단은 근무시간(주 2시간 이상 차이) → 통근(1년 40시간 이상) → 근무 방식(유연근무·재택) → '
    + '등록된 휴가·근무제도 수(3개 이상 차이) 순서로 보고, 앞에서 갈리면 멈춥니다.'));
  return sec;
}

function benefitsCard(X) {
  const { report, nm } = X;
  const v = report.axes.benefits;
  const d = v.d;
  const dir = directional(v.tier);
  const badgeText = dir ? '복지로 보면 · 등록된 금액 기준' : v.tier === 'near' ? (v.nearKind === 'weak' ? '복지로 보면 · 차이가 크지 않습니다' : '복지로 보면 · 거의 같습니다') : '복지로 보면 · 판단하기 어렵습니다';
  const sec = card('benefits', dir ? v.tier : 'neutral', badgeText, '등록된 복지로 보면');
  const hl = el('p', { class: 'calc-hl' });
  const exSame = v.exMixed && Math.sign(v.exMixed.diff) === Math.sign(d);
  // 결과 화면에서 뺀 것이 있으면 금액은 「등록된」 것이 아니라 「빼고 남은」 것이다(재확인 R-2 — 「NAVER 0만원에서」라고 했다).
  const cut = X.ex.rows > 0;
  const regW = cut ? '빼고 남은' : '등록된';
  const yearW = cut ? '남은 1년 복지 금액' : '1년 복지 금액';
  const mixedLive = report.pairs.mixed.some((r) => !X.isOff(r.side, r[r.side])); // 한쪽만 등록 항목이 아직 계산에 들어 있나
  if (dir) {
    hl.append(regW + ' 복지 금액으로 보면 ' + withJosa(nm[v.tier], '이/가') + ' 낫습니다. ' + yearW + '이 ',
      b(fmt(v.netA) + '만원에서 ' + m(v.netB) + '으로, ' + m(abs(d))), pmTxt(v.band) + ' ' + moreLess(d) + '.');
    if (v.exMixed && exSame && mixedLive) {
      hl.append(' ' + onlyRegistered(X) + ' ' + v.mixed.count + '건을 빼고 계산해도 ' + m(abs(v.exMixed.diff)) + pmTxt(v.exMixed.band) + ' '
        + (d < 0 ? '줄어들어' : '늘어나') + (directional(v.exMixed.tier) ? ' 결론은 같습니다.' : ' 방향은 같지만, 그 차이만으로는 한쪽이 낫다고 말하기 어렵습니다.'));
    }
  } else if (v.tier === 'near' && v.nearKind === 'weak') {
    hl.append(regW + ' 복지 금액은 ' + withJosa(nm[d < 0 ? 'a' : 'b'], '이/가') + ' ', b('1년에 ' + m(abs(d)) + ' 많지만'), '(' + fmt(v.netA) + ' → ' + m(v.netB) + '), 오차 범위(±' + fmt(v.band) + ')를 겨우 넘는 차이라 한쪽이 낫다고 말하기엔 약합니다.');
  } else if (v.tier === 'near') {
    hl.append(regW + ' 복지 금액은 거의 같습니다 — ' + yearW + '이 ' + fmt(v.netA) + '만원에서 ' + m(v.netB) + '으로, 차이는 ', b(m(abs(d))), '입니다.');
  } else if (v.unsureBy === 'excluded') {
    hl.append('금액이 있는 복지를 모두 빼서, ', b('남은 금액으로는 비교할 수 없습니다.'), ' 「모두 되돌리기」를 누르면 다시 넣어 계산합니다.');
  } else if (v.unsureBy === 'none') {
    hl.append('두 회사 모두 금액이 등록된 복지가 없어, ', b('등록된 금액으로는 비교할 수 없습니다.'), ' 아래 「이직하면 달라지는 복지」에서 항목을 나란히 보세요.');
  } else if (v.unsureBy === 'guard') {
    hl.append(guardClause(X, d, v.exMixed, v.mixed.count, '복지 금액') + ' ', b('어느 쪽이 낫다고 말하기 어렵습니다.'));
  } else {
    hl.append(regW + ' 복지 금액으로는 ', b('어느 쪽이 낫다고 말하기 어렵습니다.'), ' 두 회사의 오차 범위가 겹칩니다.');
  }
  sec.append(hl);
  if (v.mixed.count) {
    const other = otherSide(X);
    const names = v.mixed.names.join(' · ');
    const p = line('calc-line-must');
    if (other) p.append('다만 그중 ' + v.mixed.count + '개(' + names + ')는 ' + other + '에도 비슷한 제도가 있는데 ', b('금액이 등록되어 있지 않습니다.'));
    else p.append('다만 ' + v.mixed.count + '개(' + names + ')는 두 회사 모두 제도가 있는데 ', b('한쪽에만 금액이 등록되어 있습니다.'));
    if (!mixedLive) p.append(' 이 ' + v.mixed.count + '개는 지금 계산에서 뺐습니다.');
    else if (v.mixed.share != null) p.append(' 이 ' + v.mixed.count + '개가 차이의 ' + Math.round(v.mixed.share * 100) + '%(' + m(abs(v.mixed.net)) + ')를 차지합니다.');
    else p.append(' 이 ' + v.mixed.count + '개의 금액은 ' + m(abs(v.mixed.net)) + '입니다.');
    sec.append(p);
  }
  const ev = el('div', { class: 'calc-evid' });
  ev.append(chip((cut ? '남은 ' : '') + '복지 금액 ' + fmt(v.netA) + ' → ' + m(v.netB)));
  if (v.mixed.count) ev.append(chip(hatch(), onlyRegistered(X).replace(' 금액이 등록된', ' 금액 등록') + ' ' + v.mixed.count + '건 · ' + (mixedLive ? fmt(abs(v.mixed.net)) : '뺌')));
  ev.append(chip('참고: ' + nm.b + ' 미등록 ' + v.counts.onlyA + '개 · 새로 생기는 복지 ' + v.counts.onlyB + '개'));
  sec.append(ev);
  if (v.tier !== 'unsure') {
    const o = v.salOffset;
    let t = null;
    if (o.salMid > 0 && o.benDiff < 0) {
      t = o.gap < 0 ? ['연봉이 ' + m(o.salMid) + ' 오르지만, ' + (cut ? '남은 ' : '') + '복지 금액 차이 ' + m(abs(o.benDiff)) + '을 메우기에는 ', b(m(abs(o.gap)) + '이 모자랍니다.')]
        : ['연봉이 ' + m(o.salMid) + ' 오르면 ' + (cut ? '남은 ' : '') + '복지 금액 차이 ' + m(abs(o.benDiff)) + '을 메우고도 ', b(m(o.gap) + '이 남습니다.')];
    } else if (o.salMid < 0 && o.benDiff > 0) {
      t = o.gap > 0 ? ['연봉은 ' + m(abs(o.salMid)) + ' 줄지만, ' + regW + ' 복지 금액이 ' + m(o.benDiff) + ' 늘어 ', b('줄어든 연봉을 메우고도 ' + m(o.gap) + '이 남습니다.')]
        : ['연봉은 ' + m(abs(o.salMid)) + ' 줄고, ' + regW + ' 복지 금액이 ' + m(o.benDiff) + ' 늘어도 ', b(m(abs(o.gap)) + '이 모자랍니다.')];
    } else if (o.salMid === 0) {
      t = ['연봉은 그대로이고, ' + regW + ' 복지 금액은 ' + m(abs(o.benDiff)) + ' ' + moreLess(o.benDiff) + '.'];
    } else {
      t = ['연봉' + (o.salMid > 0 ? '도 ' + m(o.salMid) + ' 오르고' : '도 ' + m(abs(o.salMid)) + ' 줄고') + ', ' + regW + ' 복지 금액도 ' + m(abs(o.benDiff)) + ' ' + moreLess(o.benDiff) + '.'];
    }
    sec.append(line('', ...t));
  }
  const X2 = onlyRegistered(X);
  const legalN = (report.basis.a.legal || 0) + (report.basis.b.legal || 0);
  sec.append(how('결론은 등록된 복지 금액의 합계와 그 오차 범위로만 냅니다. 복지 항목 수(' + v.counts.a + '개 → ' + v.counts.b + '개)는 회사가 얼마나 자세히 공개했느냐에 따라 '
    + '달라지므로 결론에 쓰지 않고 참고로만 보여 드립니다.'
    + (v.exMixed ? ' 그대로 계산한 값(' + fmtSigned(d) + ')과 ' + X2 + ' ' + v.mixed.count + '건을 뺀 값(' + fmtSigned(v.exMixed.diff) + ')이 서로 다른 회사를 가리키면, 어느 쪽이 낫다고 말하지 않습니다.' : '')
    + (legalN ? ' 법으로 모든 회사에 정해진 제도만 적힌 항목(' + legalN + '개)은 복지로 세지 않았습니다.' : '')));
  return sec;
}

// ══ #3 타일 3칸 ════════════════════════════════════════════════════════════
function tile(k, vKids, sText, tone = '') {
  const t = el('div', { class: 'calc-tile' + (tone ? ' calc-tile-' + tone : '') });
  t.append(el('div', { class: 'calc-tile-k', text: k }), el('div', { class: 'calc-tile-v' }, ...vKids));
  if (sText) t.append(el('div', { class: 'calc-tile-s' }, ...(Array.isArray(sText) ? sText : [sText])));
  return t;
}
const small = (text) => el('small', { text });

function tiles(X, axis) {
  const { report, nm } = X;
  const box = el('div', { class: 'calc-tiles', 'data-axis': axis });
  if (axis === 'salary') {
    const v = report.axes.salary;
    if (v.tier === 'unsure') {
      // 두 총보상을 나란히 두면 뺄셈 한 번으로 차액이 나온다 — 첫 타일에는 이유만(LOW-1).
      box.append(tile('실효 총보상 차이', ['판단하기 어렵습니다'], v.unsureBy === 'guard' ? guardShort(X, report.axes.benefits.mixed.count, v.guard) : '두 회사의 오차 범위가 겹칩니다', ''));
    } else if (v.tier === 'range') {
      box.append(tile('실효 총보상 차이', [spanText(v.span), small('만원')], v.wage.cases.map((c) => wageCaseLabel(X, c, v.wage.slots) + ' ' + fmtSigned(c.diff)).join(' · '), v.wage.dir < 0 ? 'neg' : 'pos'));
    } else if (v.tier === 'depends') {
      box.append(tile('실효 총보상 차이', ['야근수당에 따라 달라집니다'], v.wage.cases.map((c) => wageCaseLabel(X, c, v.wage.slots) + ' ' + fmtSigned(c.diff)).join(' · ')));
    } else {
      box.append(tile('실효 총보상 차이', ['약 ' + fmtSigned(v.d), small('만원')],
        (hasBand(v.band) ? '범위 ' + fmt(v.range[0]) + ' ~ ' + fmt(v.range[1]) + ' · ' : '') + '한 달로 치면 ' + fmtSigned(v.monthly) + '만원', v.d < 0 ? 'neg' : 'pos'));
    }
    const rateKids = [small('연봉 '), fmtPct(v.salMid / v.salA) || '0.0%'];
    if (v.tier !== 'unsure' && v.tier !== 'depends' && v.tier !== 'range' && v.effRate != null) rateKids.push(small(' → 총보상 '), el('span', { class: v.effRate < 0 ? 'calc-neg' : 'calc-pos', text: fmtPct(v.effRate) }));
    const rateSub = v.tier === 'unsure' ? '총보상 증감률은 오차 범위 안이라 적지 않았습니다'
      : v.tier === 'depends' || v.tier === 'range' ? '총보상 증감률은 야근수당에 따라 달라집니다'
        : (report.a.otPay || report.b.otPay) && v.effRateNoOt != null ? '야근수당을 빼고 보면 ' + fmtPct(v.effRateNoOt) : '복지 환산 가치까지 더한 값입니다';
    box.append(tile('인상률 비교', rateKids, rateSub));
    const hr = report.time.hourly;
    if (hr) box.append(tile('시간당 총보상', [fmt(hr.b), small('원')], fmt(hr.a) + ' → ' + fmt(hr.b) + '원 (' + (hr.pct < 0 ? '−' : '+') + Math.round(abs(hr.pct) * 100) + '%)' + (report.wage ? ' · ' + assumeIf(X) : '')));
    else box.append(tile('시간당 총보상', ['계산하지 않음'], '두 회사의 주 근무시간을 넣으면 계산합니다'));
    return box;
  }
  if (axis === 'wlb') {
    const v = report.axes.wlb;
    const signH = (n) => (n > 0 ? '+' : n < 0 ? '−' : '') + fmt(abs(n));
    if (v.hours) box.append(tile('1년 근무시간', [signH(v.hours.annDiff), small('시간')], '약 ' + fmt(v.hours.days) + '일치 · 주 ' + fmt1(v.hours.a) + ' → ' + fmt1(v.hours.b) + '시간'));
    else box.append(tile('1년 근무시간', ['계산하지 않음'], '두 회사의 주 근무시간을 넣으면 계산합니다'));
    if (v.commute) box.append(tile('1년 통근시간', [signH(v.commute.annDiff), small('시간')], '편도 ' + fmt(v.commute.a) + ' → ' + fmt(v.commute.b) + '분 · 약 ' + fmt(v.commute.days) + '일치'));
    else box.append(tile('1년 통근시간', ['계산하지 않음'], '두 회사의 편도 통근시간을 넣으면 계산합니다'));
    box.append(tile('휴가·근무제도', [small(nm.a + ' '), String(v.count.a), ' : ', small(nm.b + ' '), String(v.count.b)],
      v.count.tenureA ? nm.a + ' 쪽 ' + v.count.tenureA + '개는 근속 연수를 채워야 받음' : '회사에 등록된 항목 수'));
    return box;
  }
  const v = report.axes.benefits;
  const why = { guard: guardShort(X, v.mixed.count, v.exMixed), none: '두 회사 모두 금액 미등록', excluded: '금액이 있는 복지를 모두 뺐습니다', band: '오차 범위가 겹칩니다' };
  const t1s = v.tier === 'unsure' ? (why[v.unsureBy] || why.band) + ' · 항목 수는 ' + v.counts.a + ' → ' + v.counts.b + '개'
    : ['차이 ', el('b', { class: v.d < 0 ? 'calc-neg' : 'calc-pos', text: fmtSigned(v.d) }), (hasBand(v.band) ? ' ' + pmTxt(v.band) : '') + ' · 항목 수는 ' + v.counts.a + ' → ' + v.counts.b + '개'];
  const cut = X.ex.rows > 0;
  box.append(tile(cut ? '남은 1년 복지 금액' : '1년 복지 금액', [fmt(v.netA) + ' → ' + fmt(v.netB), small('만원')], t1s));
  const mixedLive = report.pairs.mixed.some((r) => !X.isOff(r.side, r[r.side]));
  if (v.mixed.count && !mixedLive) {
    box.append(tile(onlyRegistered(X) + ' 복지', [String(v.mixed.count), small('건'), ' · 뺌'], '지금 계산에서 뺐습니다'));
  } else if (v.mixed.count) {
    const sub = v.exMixed ? (v.mixed.share != null ? '차이의 ' + Math.round(v.mixed.share * 100) + '% · ' : '') + '빼고 계산하면 ' + fmtSigned(v.exMixed.diff) + (hasBand(v.exMixed.band) ? ' ' + pmTxt(v.exMixed.band) : '') : '';
    box.append(tile(onlyRegistered(X) + ' 복지', [String(v.mixed.count), small('건'), ' · ' + fmt(abs(v.mixed.net)), small('만원')], sub));
  } else {
    box.append(tile('두 회사 모두 금액이 등록된 복지', [String(report.pairs.bothAmt.length), small('건')], '같은 복지끼리의 차이 ' + fmtSigned(report.parts.sameBoth) + '만원'));
  }
  box.append(tile('금액을 알 수 없는 복지', [small(nm.a + ' '), String(v.noAmt.a), ' · ', small(nm.b + ' '), String(v.noAmt.b)], '계산에는 0으로 넣었습니다'));
  return box;
}

// ══ 보조 행(다른 축 한 줄씩) ════════════════════════════════════════════════
function auxSalary(X) {
  const s = X.report.axes.salary;
  if (s.tier === 'unsure') {
    return s.unsureBy === 'guard' ? ['총보상은 ', b('판단하기 어렵습니다'), '(한쪽에만 금액이 등록된 ' + X.report.axes.benefits.mixed.count + '건을 빼면 ' + (s.guard && s.guard.diff === 0 ? '두 회사가 같아짐)' : '방향이 바뀜)')]
      : ['총보상은 ', b('오차 범위가 겹쳐 판단하기 어렵습니다')];
  }
  if (s.tier === 'depends') return ['총보상은 ', b('야근수당에 따라 달라집니다')];
  if (s.tier === 'range') return ['총보상 ', b('연 ' + spanText(s.span) + '만원'), '(야근수당에 따라 다름)'];
  if (s.tier === 'near') return ['총보상 ', b(s.nearKind === 'weak' ? '차이가 크지 않음' : '거의 같음'), '(연 ' + m(abs(s.d)) + ' 차이)'];
  return ['총보상 ', b('연 ' + m(abs(s.d)) + ' ' + (s.d < 0 ? '감소' : '증가')), pmTxt(s.band)];
}
function auxWlb(X) {
  const { report, nm } = X;
  const v = report.axes.wlb;
  const h = v.hours, c = v.commute;
  const bits = [];
  if (h && h.weekDiff) bits.push('입력하신 야근 시간대로라면 ' + nm[h.weekDiff > 0 ? 'b' : 'a'] + '에서 주 ' + fmt1(abs(h.weekDiff)) + '시간 더 일하고');
  else if (h) bits.push('입력하신 주 근무시간은 같고');
  if (c && c.annDiff) {
    const cm = c.annDiff > 0 ? 'b' : 'a';
    bits.push(h && h.weekDiff && (h.weekDiff > 0 ? 'b' : 'a') === cm ? '통근도 1년에 ' + fmt(abs(c.annDiff)) + '시간 더' : '통근은 ' + nm[cm] + '에서 1년에 ' + fmt(abs(c.annDiff)) + '시간 더');
  }
  if (!bits.length) return ['주 근무시간·통근을 넣으면 시간으로 비교합니다'];
  return [bits.join(', ')];
}
function auxBen(X) {
  const v = X.report.axes.benefits;
  return [(X.ex.rows ? '남은 1년 복지 금액 ' : '1년 복지 금액 ') + fmt(v.netA) + ' → ' + m(v.netB)];
}
function auxRow(X, axis) {
  const box = el('div', { class: 'calc-aux', 'data-axis': axis });
  const item = (k, parts) => el('span', {}, el('span', { class: 'calc-aux-k', text: k + '로 보면 — ' }), ...parts);
  const rows = { salary: ['연봉으', auxSalary], wlb: ['워라밸', auxWlb], benefits: ['복지', auxBen] };
  for (const key of ['salary', 'wlb', 'benefits']) {
    if (key === axis) continue;
    const [k, fn] = rows[key];
    box.append(item(k, fn(X)));
  }
  return box;
}

// ══ 블록(L1/L2/L3) — <details>, 요약 줄이 곧 결론 문장 ══════════════════════
function blk(id, summaryText, lv, bodyKids, extraClass = '') {
  const d = el('details', { class: 'calc-card calc-blk' + (extraClass ? ' ' + extraClass : ''), id: 'calc-b-' + id });
  const s = el('summary');
  s.append(el('span', { class: 'calc-blk-t', text: summaryText }), el('span', { class: 'calc-blk-lv', text: lv }));
  const body = el('div', { class: 'calc-blk-body' }, ...bodyKids.filter(Boolean));
  d.append(s, body);
  return d;
}

// ── 총보상 흐름(브리지) ─────────────────────────────────────────────────────
function bridgeSteps(X) {
  const { report, nm, input } = X;
  const v = report.axes.salary;
  const steps = [{ k: 'start', label: [sym('a'), nm.a], sub: '실효 총보상', v: report.a.total, band: report.a.sumBand }];
  steps.push({ k: 'd', label: [v.salMid >= 0 ? '+ 연봉 인상' : '− 연봉 감소'], sub: '(' + (input.rate >= 0 ? '+' : '−') + rate1(input.rate || 0) + ')', v: v.salMid });
  steps.push({ k: 'd', label: [v.parts.ben >= 0 ? '+ 복지 차이' : '− 복지 차이'], sub: '(금액 등록분만)', v: v.parts.ben, band: report.band.delta, hatch: report.axes.benefits.mixed.count ? abs(v.parts.mixed) : 0 });
  if (report.a.otPay || report.b.otPay) steps.push({ k: 'd', label: [v.parts.ot >= 0 ? '+ 야근수당 차이' : '− 야근수당 차이'], sub: '(입력하신 조건)', v: v.parts.ot });
  steps.push({ k: 'end', label: [sym('b'), nm.b], sub: '실효 총보상', v: report.b.total, band: report.b.sumBand });
  let run = 0;
  for (const s of steps) {
    if (s.k === 'd') { s.from = run; s.to = run + s.v; run = s.to; } else { s.from = null; s.to = s.v; run = s.v; }
  }
  return steps;
}
function niceStep(range) {
  const raw = range / 5;
  const pow = 10 ** Math.floor(Math.log10(Math.max(raw, 1)));
  return [1, 2, 2.5, 5, 10].map((k) => k * pow).find((st) => st >= raw) || pow * 10;
}
function bridgeScale(steps) {
  const pts = [];
  for (const s of steps) {
    pts.push(s.to);
    if (s.from != null) pts.push(s.from);
    if (s.band) pts.push(s.to - s.band, s.to + s.band);
  }
  const min = Math.min(...pts), max = Math.max(...pts);
  const span = Math.max(max - min, 1);
  const st = niceStep(span * 1.6);
  const lo = Math.max(0, Math.floor((min - span * 0.25) / st) * st);
  const hi = Math.ceil((max + span * 0.1) / st) * st;
  return { lo, hi, st };
}
const pctOf = (v, sc) => ((v - sc.lo) / (sc.hi - sc.lo)) * 100;
const pctStr = (n) => Math.max(0, Math.min(100, n)).toFixed(2) + '%';

function bridgeAria(X, steps) {
  return '총보상 흐름: ' + steps.map((s) => (s.k === 'd' ? fmtSigned(s.v) : (s.k === 'start' ? X.nm.a : X.nm.b) + ' 실효 총보상 ' + m(s.v))).join(', ');
}

function bridgeColumns(X, steps, sc) {
  const box = el('div', { class: 'calc-br-h', role: 'img', 'aria-label': bridgeAria(X, steps) });
  const axis = el('div', { class: 'calc-br-axis', 'aria-hidden': 'true' });
  const plot = el('div', { class: 'calc-br-plot', 'aria-hidden': 'true' });
  for (let g = Math.ceil(sc.lo / sc.st) * sc.st; g <= sc.hi; g += sc.st) {
    plot.append(el('span', { class: 'calc-br-grid', style: 'bottom:' + pctStr(pctOf(g, sc)) }));
    axis.append(el('span', { class: 'calc-br-tick', style: 'bottom:' + pctStr(pctOf(g, sc)), text: fmt(g) }));
  }
  axis.append(el('span', { class: 'calc-br-unit', text: '만원' }));
  steps.forEach((s, i) => {
    const col = el('div', { class: 'calc-br-col' });
    const lo = s.k === 'd' ? Math.min(s.from, s.to) : sc.lo;
    const hi = s.k === 'd' ? Math.max(s.from, s.to) : s.to;
    const tone = s.k === 'd' ? (s.v < 0 ? 'neg' : 'pos') : 'tot';
    const bar = el('span', { class: 'calc-br-bar calc-br-' + tone, style: 'bottom:' + pctStr(pctOf(lo, sc)) + ';height:' + pctStr(pctOf(hi, sc) - pctOf(lo, sc)) });
    if (s.hatch && s.v) {
      const hh = Math.min(100, (s.hatch / abs(s.v)) * 100);
      bar.append(el('span', { class: 'calc-br-hatch', style: 'height:' + hh.toFixed(2) + '%' }, el('span', { text: '▨ ' + fmt(s.hatch) })));
    }
    col.append(bar);
    if (s.band) {
      const edge = s.to;
      col.append(el('span', { class: 'calc-br-band calc-br-band-' + (s.k === 'd' ? 'neg' : 'tot'), style: 'bottom:' + pctStr(pctOf(edge - s.band, sc)) + ';height:' + pctStr(pctOf(edge + s.band, sc) - pctOf(edge - s.band, sc)) }));
    }
    const valTop = s.k === 'd' && s.v < 0;
    const vlab = el('span', {
      class: 'calc-br-val calc-br-val-' + tone + (valTop ? ' calc-br-below' : ''),
      style: valTop ? 'top:' + pctStr(100 - pctOf(lo, sc)) : 'bottom:' + pctStr(pctOf(hi, sc)),
    }, s.k === 'd' ? fmtSigned(s.v) : fmt(s.v));
    if (s.band) vlab.append(el('small', { text: ' ±' + fmt(s.band) }));
    col.append(vlab);
    if (i < steps.length - 1) col.append(el('span', { class: 'calc-br-link', style: 'bottom:' + pctStr(pctOf(s.to, sc)) }));
    plot.append(col);
  });
  const labels = el('div', { class: 'calc-br-labels', 'aria-hidden': 'true' });
  for (const s of steps) labels.append(el('div', { class: 'calc-br-lab' }, el('b', {}, ...s.label), el('span', { text: s.sub })));
  box.append(axis, plot, el('span', { class: 'calc-br-gap', 'aria-hidden': 'true' }), labels);
  return box;
}

function bridgeBars(X, steps, sc) {
  const box = el('div', { class: 'calc-br-v', role: 'img', 'aria-label': bridgeAria(X, steps) });
  for (const s of steps) {
    const lo = s.k === 'd' ? Math.min(s.from, s.to) : sc.lo;
    const hi = s.k === 'd' ? Math.max(s.from, s.to) : s.to;
    const tone = s.k === 'd' ? (s.v < 0 ? 'neg' : 'pos') : 'tot';
    const row = el('div', { class: 'calc-brv-row', 'aria-hidden': 'true' });
    const head = el('div', { class: 'calc-brv-head' });
    const val = el('b', { class: 'calc-br-val-' + tone, text: s.k === 'd' ? fmtSigned(s.v) : fmt(s.v) });
    if (s.band) val.append(el('small', { text: ' ±' + fmt(s.band) }));
    head.append(el('span', {}, el('b', {}, ...s.label), ' ', el('span', { class: 'calc-muted', text: s.sub })), val);
    const trk = el('div', { class: 'calc-brv-trk' });
    const bar = el('span', { class: 'calc-brv-bar calc-br-' + tone, style: 'left:' + pctStr(pctOf(lo, sc)) + ';width:' + pctStr(pctOf(hi, sc) - pctOf(lo, sc)) });
    trk.append(bar);
    if (s.hatch && s.v) trk.append(el('span', { class: 'calc-brv-hatch', style: 'left:' + pctStr(pctOf(lo, sc)) + ';width:' + pctStr(pctOf(lo + s.hatch, sc) - pctOf(lo, sc)) }));
    if (s.band) trk.append(el('span', { class: 'calc-brv-band calc-br-band-' + (s.k === 'd' ? 'neg' : 'tot'), style: 'left:' + pctStr(pctOf(s.to - s.band, sc)) + ';width:' + pctStr(pctOf(s.to + s.band, sc) - pctOf(s.to - s.band, sc)) }));
    row.append(head, trk);
    box.append(row);
  }
  box.append(el('div', { class: 'calc-brv-axis', 'aria-hidden': 'true' }, el('span', { text: fmt(sc.lo) }), el('span', { text: fmt((sc.lo + sc.hi) / 2) }), el('span', { text: fmt(sc.hi) + ' 만원' })));
  return box;
}

// 화면 밖 표 — 표 자체에 sr-only 를 주면 표 레이아웃이 1px 폭을 무시하고 문서를 옆으로 넓힌다(390px 실측 +82px).
// 그래서 **감싸는 div** 를 숨긴다.
const srOnly = (table) => el('div', { class: 'sr-only' }, table);
function bridgeTable(X, steps) {
  const t = el('table');
  t.append(el('caption', { text: '총보상 흐름 데이터' }));
  const th = el('tr', {}, el('th', { scope: 'col', text: '단계' }), el('th', { scope: 'col', text: '값(만원)' }), el('th', { scope: 'col', text: '오차 범위' }));
  t.append(el('thead', {}, th));
  const tb = el('tbody');
  const other = otherSide(X);
  for (const s of steps) {
    let name = s.k === 'start' ? X.nm.a + ' 실효 총보상' : s.k === 'end' ? X.nm.b + ' 실효 총보상' : s.label.join('').replace(/^[+−] /, '') + ' ' + s.sub;
    if (s.hatch) name = s.label.join('').replace(/^[+−] /, '') + ' (금액이 등록된 것만, 그중 ' + fmt(s.hatch) + '은 ' + (other ? other + ' 금액 미등록' : '한쪽에만 금액 등록') + ')';
    // 끝 막대는 목업처럼 범위까지 — 「±145 (7,594 ~ 7,884)」.
    const bandTxt = !s.band ? '없음' : '±' + fmt(s.band) + (s.k === 'end' ? ' (' + fmt(s.v - s.band) + ' ~ ' + fmt(s.v + s.band) + ')' : '');
    tb.append(el('tr', {}, el('td', { text: name }), el('td', { text: s.k === 'd' ? fmtSigned(s.v) : fmt(s.v) }), el('td', { text: bandTxt })));
  }
  t.append(tb);
  return srOnly(t);
}

function bridgeSummary(X) {
  const v = X.report.axes.salary;
  const sal = v.salMid > 0 ? '연봉은 ' + m(v.salMid) + ' 오르' : v.salMid < 0 ? '연봉은 ' + m(abs(v.salMid)) + ' 줄' : '연봉은 그대로이';
  if (v.tier === 'range') return sal + (v.shape === 'same' ? '고, ' : '지만, ') + '복지·야근수당까지 더한 총보상은 야근수당에 따라 연 ' + fmt(abs(v.span[0])) + ' ~ ' + m(abs(v.span[1])) + ' ' + moreLess(v.wage.dir);
  if (!directional(v.tier)) return sal + '고, 복지·야근수당까지 더한 총보상은 ' + (v.tier === 'near' ? '거의 같습니다' : v.tier === 'depends' ? '야근수당에 따라 달라집니다' : '어느 쪽이 많은지 말하기 어렵습니다');
  const same = (v.salMid > 0 && v.d > 0) || (v.salMid < 0 && v.d < 0);
  return sal + (same ? '고, ' : '지만, ') + withJosa(causes(X, v, Math.sign(v.d)).text, '로/으로') + ' 총보상은 ' + moreLess(v.d);
}

function bridgeBlock(X) {
  const { report, nm } = X;
  const steps = bridgeSteps(X);
  const sc = bridgeScale(steps);
  const ben = report.axes.benefits;
  const caps = el('ul', { class: 'calc-cap' });
  if (ben.mixed.count && report.parts.mixed) {
    const other = otherSide(X);
    caps.append(el('li', {}, hatch(), '빗금 친 ' + m(abs(report.parts.mixed)) + '은 두 회사 모두 제도가 있지만 ' + onlyRegistered(X) + ' ' + ben.mixed.count + '개 항목입니다.'
      + (other ? ' ' + other + '에 그 복지가 없다는 뜻은 아닙니다.' : '')));
  }
  const expired = (report.basis.a.expired || 0) + (report.basis.b.expired || 0);
  caps.append(el('li', { text: '흐리게 번진 부분은 오차 범위입니다. 회사가 밝힌 금액은 ±5%, 추정한 금액은 ±20%로 잡았습니다(통계적 신뢰구간이 아닙니다).'
    + (expired ? ' 유효기간이 지난 자료 ' + expired + '건은 15%p 더 넓혔습니다.' : '') }));
  caps.append(el('li', { text: '계산에 넣은 것: 연봉 · 금액이 등록된 복지 · 야근수당(입력하신 조건). 넣지 않은 것: 통근(시간으로만 비교) · 금액을 알 수 없는 복지 '
    + (ben.noAmt.a + ben.noAmt.b) + '개(' + nm.a + ' ' + ben.noAmt.a + ' · ' + nm.b + ' ' + ben.noAmt.b + ') · 법정 연차(두 회사의 연차 일수를 확인하지 못함).' }));
  if (report.deltas.otDiff) caps.append(el('li', { class: 'calc-xs', text: '야근수당을 빼고 연봉과 복지만 비교하면 ' + fmtSigned(report.deltas.effMid) + '만원입니다.' }));
  const qa = report.pairs.onlyA.filter((it) => amtOf(it) == null).length;
  const qb = report.pairs.onlyB.filter((it) => amtOf(it) == null).length;
  const ghost = el('p', { class: 'calc-ghost' });
  ghost.append(b('금액을 몰라 이 그래프에 넣지 못한 복지가 ' + (ben.noAmt.a + ben.noAmt.b) + '개 있습니다'),
    ' — ' + nm.b + '에 등록되지 않은 ' + report.pairs.onlyA.length + '개 중 ' + qa + '개, 새로 생기는 ' + report.pairs.onlyB.length + '개 중 ' + qb + '개도 여기에 해당합니다 ');
  const go = el('a', { href: '#calc-b-diffs', class: 'calc-ghost-go', text: '보기 →' });
  go.addEventListener('click', (e) => {
    e.preventDefault();
    const d = typeof document !== 'undefined' ? document.getElementById('calc-b-diffs') : null;
    if (d) { d.open = true; if (typeof d.scrollIntoView === 'function') d.scrollIntoView({ block: 'start' }); }
  });
  ghost.append(go);
  // 야근수당 미선택이면 막대는 포괄 가정 값이다(R-1) — 머리말. 요약은 range/depends 면 이미 두 경우를 말하고, 아니면 가정을 붙인다.
  const tier = report.axes.salary.tier;
  const sum = tier === 'range' || tier === 'depends' ? bridgeSummary(X) : withAssume(X, bridgeSummary(X));
  return blk('bridge', sum, '총보상 흐름', [assumeLine(X), bridgeColumns(X, steps, sc), bridgeBars(X, steps, sc), bridgeTable(X, steps), caps, ghost], 'calc-bridge');
}

// ── 튼튼함 + 협상 ──────────────────────────────────────────────────────────
// 나머지 눈금(한쪽만 등록 제외 · 복지 0)의 같아지는 연봉 — 숫자가 뜻을 가지는 것은 이어 쓰고, 범위 밖은 숫자 없이 한 문장(MED-4).
function negoMore(X, be, salB) {
  const { report, nm } = X;
  const items = [];
  if (be.exMixed) items.push([onlyRegistered(X) + ' ' + report.axes.benefits.mixed.count + '건을 빼', be.exMixed]);
  if (be.noBenefit) items.push(['복지를 아예 빼', be.noBenefit]);
  const sentences = [];
  let run = [];
  const flush = () => { if (run.length) sentences.push(run.join(', ') + '입니다.'); run = []; };
  let numeric = false;
  for (const [label, x] of items) {
    if (x.bound === 'low' && salB >= x.sal) { flush(); sentences.push(label + '도 연봉 협상과 상관없이 ' + nm.b + ' 쪽이 큽니다.'); }
    else if (x.bound === 'high' && salB < x.sal) { flush(); sentences.push(label + '면 ' + nm.b + ' 연봉이 현재 연봉의 두 배가 되어도 모자랍니다.'); }
    else { run.push(label + '면 ' + m(x.sal) + '(' + fmtPct(x.rate) + ')'); numeric = true; }
  }
  flush();
  if (numeric) sentences.push('연봉 협상 때 참고하세요.');
  return sentences;
}
// slot 쪽으로 기우는 차이(연봉 밖) — 「복지와 야근수당 차이」 · 「복지 차이」 · 「야근수당 차이」.
function edgeOf(X, slot) {
  const p = X.report.axes.salary.parts;
  const favors = (v) => (slot === 'b' ? v > 0 : v < 0);
  const bits = [];
  if (favors(p.ben)) bits.push('복지');
  if (favors(p.ot)) bits.push('야근수당');
  return (bits.length ? bits.join('와 ') : '복지') + ' 차이';
}
function robustBlock(X) {
  const { report, nm } = X;
  const rb = report.robust;
  const d = rb.full.diff;
  const loser = d < 0 ? nm.b : nm.a;
  const winner = d < 0 ? nm.a : nm.b;
  const scales = [rb.full, rb.exMixed, rb.noBenefit].filter(Boolean);
  const flips = scales.some((s) => directional(s.tier) && Math.sign(s.diff) !== Math.sign(d));
  const allDir = scales.every((s) => directional(s.tier) && Math.sign(s.diff) === Math.sign(d));
  // 요약은 판정 카드와 **같은** 티어(가드 포함)로 말한다 — 거의 같음은 「거의 같습니다」, 판단 어려움만 「말하기 어렵습니다」.
  const sv = report.axes.salary;
  const n = report.axes.benefits.mixed.count;
  let summary;
  if (rb.full.tier === 'unsure' && rb.full.unsureBy === 'guard') summary = '한쪽에만 금액이 등록된 ' + n + '건을 빼면 ' + (rb.exMixed && rb.exMixed.diff === 0 ? '두 회사가 같아져' : '앞서는 회사가 바뀌어') + ', 어느 쪽 총보상이 많은지 말하기 어렵습니다';
  else if (rb.full.tier === 'unsure') summary = '두 회사의 오차 범위가 겹쳐, 어느 쪽 총보상이 많은지 말하기 어렵습니다';
  else if (rb.full.tier === 'near') summary = sv.nearKind === 'weak' ? '총보상 차이가 오차 범위를 겨우 넘는 정도라, 한쪽이 낫다고 말하기엔 약합니다' : '등록된 금액으로는 두 회사 총보상이 거의 같습니다';
  else if (flips) summary = '복지 금액을 어떻게 잡느냐에 따라 결론이 달라집니다';
  else if (allDir) summary = '복지 금액을 어떻게 잡아도 ' + winner + '의 총보상이 더 많습니다';
  else summary = '복지 금액을 어떻게 잡아도 ' + loser + ' 쪽 총보상이 더 많아지지는 않습니다';
  summary = withAssume(X, summary);
  const scale = el('div', { class: 'calc-scale' });
  const part = (label, s) => el('span', {}, label + ' ', el('b', { class: s.diff < 0 ? 'calc-neg' : s.diff > 0 ? 'calc-pos' : '', text: fmtSigned(s.diff) }), s.band ? '(±' + fmt(s.band) + ')' : '');
  scale.append(part('① 등록된 금액 그대로', rb.full));
  if (rb.exMixed) scale.append(el('span', { class: 'calc-muted', 'aria-hidden': 'true', text: '·' }), part('② ' + onlyRegistered(X) + ' ' + report.axes.benefits.mixed.count + '건을 빼면', rb.exMixed));
  scale.append(el('span', { class: 'calc-muted', 'aria-hidden': 'true', text: '·' }), part((rb.exMixed ? '③' : '②') + ' 복지를 아예 빼면', rb.noBenefit));
  const nb = rb.noBenefit;
  let arrow;
  if (rb.full.tier === 'unsure' && rb.full.unsureBy === 'guard') {
    const ex = rb.exMixed;
    arrow = ex.diff === 0 ? '→ ②에서는 두 회사가 같아집니다. 그래서 어느 쪽이 낫다고 말하지 않습니다.'
      : directional(ex.tier)
      ? '→ ①에서는 ' + withJosa(d < 0 ? nm.a : nm.b, '이/가') + ', ②에서는 ' + withJosa(ex.diff < 0 ? nm.a : nm.b, '이/가') + ' 많습니다. 그래서 어느 쪽이 낫다고 말하지 않습니다.'
      : '→ ②에서는 방향이 바뀌지만 ' + (ex.tier === 'unsure' ? '그 차이는 오차 범위 안입니다' : '그 차이는 크지 않습니다') + '. 그래서 어느 쪽이 낫다고 말하지 않습니다.';
  } else if (rb.full.tier === 'unsure') arrow = '→ ①의 차이가 오차 범위 안이라 어느 쪽이 많다고 말하지 않습니다.';
  else if (rb.full.tier === 'near') arrow = sv.nearKind === 'weak' ? '→ ①의 차이는 오차 범위를 겨우 넘는 정도입니다.' : '→ ①의 차이가 작아 두 회사 총보상은 거의 같습니다.';
  else if (flips) arrow = '→ 복지를 어떻게 세느냐에 따라 앞서는 회사가 바뀝니다.';
  else {
    arrow = '→ 어느 경우에도 ' + loser + ' 쪽 총보상이 더 많아지지는 않습니다.';
    if (nb.tier === 'near') arrow += ' 복지를 아예 빼고 연봉과 야근수당만 보면 ' + m(nb.diff) + '으로 거의 같습니다.';
  }
  if (report.wage) arrow = '→ ' + assumeIf(X) + ' ' + arrow.slice(2);
  const be = report.breakeven;
  const kids = [assumeLine(X), scale, el('p', { class: 'calc-arrow', text: arrow })].filter(Boolean);
  const w = report.wage;
  if (be && be.full && w && w.cases.every((c) => c.breakeven && c.breakeven.full)) {
    // 야근수당 미선택 — 같아지는 연봉을 경우마다 나란히(R-1). 범위 밖은 숫자 없이(MED-4).
    const salB = report.b.salRange.mid;
    const nego = el('p', { class: 'calc-nego' });
    const caseTxt = (f) => (f.bound === 'low' && salB >= f.sal ? '연봉과 상관없이 ' + nm.b + ' 쪽이 큼'
      : f.bound === 'high' && salB < f.sal ? '현재 연봉의 두 배로도 모자람' : m(f.sal) + '(' + fmtPct(f.rate) + ')');
    nego.append(b('총보상이 같아지는 ' + nm.b + ' 연봉'), ' — ' + w.cases.map((c) => wageCaseLabel(X, c, w.slots) + ' ' + caseTxt(c.breakeven.full)).join(' · ')
      + '. 입력하신 조건은 ' + m(salB) + '입니다.');
    const more = negoMore(X, be, salB);
    if (more.length) nego.append(el('br'), el('span', { class: 'calc-muted', text: assumeIf(X) + ', ' + more.join(' ') }));
    if (w.cases.some((c) => c.wage.b === 'separate' && c.breakeven.k > 0)) {
      nego.append(el('br'), el('span', { class: 'calc-muted calc-small', text: withJosa(nm.b, '이/가') + ' 비포괄이면 연봉이 오를수록 야근수당도 함께 오르는 것까지 넣어 계산했습니다.' }));
    }
    kids.push(nego);
  } else if (be && be.full) {
    const salB = report.b.salRange.mid;
    const rateTxt = (r) => fmtPct(r);
    const nego = el('p', { class: 'calc-nego' });
    const f = be.full;
    // 같아지는 연봉이 현재 연봉의 절반 미만(0 이하 포함)·두 배 초과면 %·만원을 내지 않는다 — 협상 조언이 아니다(MED-4).
    if (f.bound === 'low' && salB >= f.sal) {
      nego.append(b(withJosa(nm.b, '은/는') + ' ' + edgeOf(X, 'b') + '만으로 이미 총보상이 더 많습니다'), ' — 연봉 협상과 상관없이 ' + nm.b + ' 쪽이 큽니다.');
    } else if (f.bound === 'high' && salB < f.sal) {
      nego.append(b(withJosa(nm.a, '은/는') + ' ' + edgeOf(X, 'a') + '만으로 총보상이 훨씬 많아, ' + nm.b + ' 연봉이 현재 연봉의 두 배가 되어도 따라잡지 못합니다'), ' — 등록된 복지 금액 그대로 계산했을 때입니다.');
    } else if (salB < f.sal) {
      nego.append(b('총보상이 같아지려면 ' + nm.b + ' 연봉이 ' + m(f.sal) + '(' + rateTxt(f.rate) + ')은 되어야 합니다'), ' — 등록된 복지 금액 그대로 계산했을 때입니다.');
    } else {
      nego.append(b(nm.b + ' 연봉이 ' + m(f.sal) + '(' + rateTxt(f.rate) + ')만 돼도 총보상이 같아집니다'), ' — 입력하신 조건(' + m(salB) + ')은 그보다 ' + m(salB - f.sal) + ' 높습니다.');
    }
    const sentences = negoMore(X, be, salB);
    if (sentences.length) nego.append(el('br'), el('span', { class: 'calc-muted', text: sentences.join(' ') }));
    if (be.k > 0) nego.append(el('br'), el('span', { class: 'calc-muted calc-small', text: '입력하신 대로 ' + withJosa(nm.b, '이/가') + ' 야근수당을 따로 준다면 연봉이 오를수록 야근수당도 함께 오르는 것까지 넣어 계산했습니다.' }));
    kids.push(nego);
  }
  return blk('robust', summary, '결론이 얼마나 확실한가', [el('div', { class: 'calc-robust' }, ...kids)]);
}

// ── 시간 계산서 ────────────────────────────────────────────────────────────
function tbl(cls, head, rows, headCls = []) {
  const t = el('table', { class: 'calc-tbl' + (cls ? ' ' + cls : '') });
  const tr = el('tr');
  head.forEach((h, i) => tr.append(el('th', { scope: 'col', class: headCls[i] || '' }, ...(Array.isArray(h) ? h : [h]))));
  t.append(el('thead', {}, tr));
  const tb = el('tbody');
  for (const r of rows) tb.append(r);
  t.append(tb);
  return el('div', { class: 'calc-tblwrap' }, t);
}
const td = (kids, cls = '') => el('td', cls ? { class: cls } : {}, ...(Array.isArray(kids) ? kids : [kids]));

function timeBlock(X) {
  const { report, nm } = X;
  const t = report.time;
  const none = '입력 없음';
  const hIn = t.hoursIn, cIn = t.commuteIn;
  const hrs = (v) => (v ? fmt1(v) + '시간' : none);
  const signed = (n, unit) => (n > 0 ? '+' : n < 0 ? '−' : '') + fmt(abs(n)) + unit;
  const signed1 = (n, unit) => (n > 0 ? '+' : n < 0 ? '−' : '') + fmt1(abs(n)) + unit;
  const rows = [
    el('tr', {}, td('주 근무시간(입력)'), td(hrs(hIn.a)), td(hrs(hIn.b)), td(t.hours ? [b(signed1(t.hours.weekDiff, '시간'))] : '')),
    el('tr', {}, td('1년 근무시간'), td(t.hours ? fmt(t.hours.annA) + '시간' : none), td(t.hours ? fmt(t.hours.annB) + '시간' : none),
      td(t.hours ? [b(signed(t.hours.annDiff, '시간') + '(약 ' + fmt(t.hours.days) + '일치)')] : '')),
    el('tr', {}, td('편도 통근(입력)'), td(cIn.a != null ? fmt(cIn.a) + '분' : none), td(cIn.b != null ? fmt(cIn.b) + '분' : none),
      td(t.commute ? signed(t.commute.b - t.commute.a, '분') : '')),
    el('tr', {}, td('1년 통근시간'), td(t.commute ? fmt(t.commute.annA) + '시간' : none), td(t.commute ? fmt(t.commute.annB) + '시간' : none),
      td(t.commute ? [b(signed(t.commute.annDiff, '시간') + '(약 ' + fmt(t.commute.days) + '일치)')] : '')),
    el('tr', {}, td('시간당 총보상(근무시간 기준)'), td(report.a.hourly != null ? fmt(report.a.hourly) + '원' : '계산하지 않음'),
      td(report.b.hourly != null ? fmt(report.b.hourly) + '원' : '계산하지 않음'),
      td(t.hourly ? [el('b', { class: t.hourly.diff < 0 ? 'calc-neg' : 'calc-pos', text: fmtSigned(t.hourly.diff) + '원 (' + (t.hourly.pct < 0 ? '−' : '+') + Math.round(abs(t.hourly.pct) * 100) + '%)' })] : '')),
  ];
  if (t.hourlyCommute) {
    const hc = t.hourlyCommute;
    rows.push(el('tr', {}, td('통근 시간까지 넣으면'), td(fmt(hc.a) + '원'), td(fmt(hc.b) + '원'),
      td(fmtSigned(hc.diff) + '원 (' + (hc.pct < 0 ? '−' : '+') + Math.round(abs(hc.pct) * 100) + '%)', hc.diff < 0 ? 'calc-neg' : 'calc-pos')));
  }
  const table = tbl('calc-time', ['', [sym('a'), nm.a], [sym('b'), nm.b], '차이'], rows, ['', 'calc-ca', 'calc-cb', '']);
  const helpText = t.hourlyCommute
    ? '통근 시간은 돈으로 바꾸지 않았습니다. 출퇴근 1시간이 얼마의 가치인지 정할 근거가 없어서, 시간당 총보상을 계산할 때 시간에만 더했습니다.'
    : '통근 시간은 돈으로 바꾸지 않습니다. 두 회사의 주 근무시간과 편도 통근시간을 넣으면 통근까지 넣은 시간당 총보상 줄이 생깁니다.';
  let summary;
  const bits = [];
  if (t.hours && t.hours.annDiff) bits.push(nm[t.hours.annDiff > 0 ? 'b' : 'a'] + '에서 1년에 ' + fmt(abs(t.hours.annDiff)) + '시간 더 일하고');
  if (t.commute && t.commute.annDiff) {
    const cm = t.commute.annDiff > 0 ? 'b' : 'a';
    bits.push((bits.length && (t.hours.annDiff > 0 ? 'b' : 'a') === cm ? '' : nm[cm] + '에서 ') + fmt(abs(t.commute.annDiff)) + '시간 더 출퇴근합니다');
  }
  if (!t.hours && !t.commute) summary = '근무·통근 시간 — 입력하신 조건에 근무·통근 시간이 없습니다';
  else if (!bits.length) summary = '근무·통근 시간 — 입력하신 조건이면 두 회사가 같습니다';
  else summary = '근무·통근 시간 — 입력하신 조건이면 ' + bits.join(', ').replace(/일하고$/, '일합니다');
  return blk('time', summary, '시간 비교', [t.hourly ? assumeLine(X) : null, table, el('p', { class: 'calc-help', text: helpText })]);
}

// ── 근속 태그(표시 전용) ────────────────────────────────────────────────────
function tenureInfo(X, slot, item) {
  if (slot !== 'a') return null;
  const tg = X.report.tenure;
  const hit = (tg.a || []).find((x) => x.item === item || keyOf(x.item) === keyOf(item));
  if (!hit) return null;
  const cond = hit.years != null ? '근속 ' + hit.years + '년 이상' : '근속 조건';
  if (tg.tenureYears == null || hit.years == null) return { cond, state: null };
  if (tg.tenureYears >= hit.years) return { cond, state: '지금 받는 중 — 이직하면 처음부터', earned: true };
  return { cond, state: fmt(hit.years - tg.tenureYears) + '년 뒤부터 받을 수 있음', earned: false };
}

// ── 휴가·근무제도 발췌(워라밸 축 L1) ─────────────────────────────────────────
function excerptBlock(X) {
  const { report, nm } = X;
  const isW = (it) => it && (it.benefit_ctgr_cd === 'time_off' || it.benefit_ctgr_cd === 'flexibility');
  const p = report.pairs;
  const rows = [];
  const catBd = (it) => el('span', { class: 'calc-bd calc-bd-q', text: cat(it.benefit_ctgr_cd) });
  for (const it of p.onlyA.filter(isW)) {
    const ti = tenureInfo(X, 'a', it);
    const nmCell = [catBd(it), ' ' + it.benefit_nm];
    if (ti) nmCell.push(' ', el('span', { class: 'calc-tagm', text: ti.cond + (ti.state ? ' · ' + (ti.earned ? '지금 받는 중' : ti.state) : '') }));
    rows.push(el('tr', {}, td(nmCell), td([srcText(descOf(it))]), td('등록 없음', 'calc-muted')));
  }
  for (const it of p.onlyB.filter(isW)) rows.push(el('tr', {}, td([catBd(it), ' ' + it.benefit_nm]), td('등록 없음', 'calc-muted'), td([srcText(descOf(it))])));
  for (const r of [...p.bothQual, ...p.mixed, ...p.bothAmt].filter((r) => isW(r.a) || isW(r.b))) {
    const name = r.a.benefit_nm === r.b.benefit_nm ? r.a.benefit_nm : r.a.benefit_nm + ' ↔ ' + r.b.benefit_nm;
    rows.push(el('tr', {}, td([catBd(r.a), ' ' + name + ' · ', b('서로 다른 제도라 비교하지 않음')]), td([srcText(descOf(r.a))]), td([srcText(descOf(r.b))])));
  }
  const w = report.axes.wlb.count;
  const kids = [];
  if (w.tenureA) kids.push(el('p', { class: 'calc-small', text: nm.a + ' 쪽 ' + w.tenureA + '개는 근속 연수를 채워야 받는 복지라, 이직하면 처음부터 다시 쌓아야 합니다.' }));
  if (rows.length) kids.push(tbl('calc-excerpt calc-mtab', ['항목', [sym('a'), nm.a], [sym('b'), nm.b]], rows, ['', 'calc-ca', 'calc-cb']));
  else kids.push(el('p', { class: 'calc-small calc-muted', text: '두 회사 모두 휴가·근무제도로 등록된 항목이 없습니다.' }));
  return blk('excerpt', '휴가·근무제도는 ' + nm.a + ' ' + w.a + '개, ' + nm.b + ' ' + w.b + '개가 등록되어 있습니다', '휴가·근무제도', kids);
}

// ── 이직하면 달라지는 복지(3덩이) ───────────────────────────────────────────
function sortForAxis(items, axis, catCount) {
  const amt = (it) => amtOf(it) ?? -1;
  const w = (it) => (it.benefit_ctgr_cd === 'time_off' || it.benefit_ctgr_cd === 'flexibility' ? 0 : 1);
  return [...items].sort((x, y) => {
    if (axis === 'wlb') { const d = w(x) - w(y); if (d) return d; }
    if (axis === 'benefits') { const d = (catCount[y.benefit_ctgr_cd] || 0) - (catCount[x.benefit_ctgr_cd] || 0); if (d) return d; }
    return amt(y) - amt(x);
  });
}
function drow(X, slot, it) {
  const row = el('div', { class: 'calc-drow' + (X.isOff(slot, it) ? ' calc-off' : '') });
  const f = facetTags(X, slot, it);
  const nmSpan = el('span', { class: 'calc-dnm', text: it.benefit_nm });
  for (const t of f.inline) nmSpan.append(' ', el('span', { class: 'calc-tagm', text: t }));
  row.append(el('span', { class: 'calc-dcat', text: cat(it.benefit_ctgr_cd) }), nmSpan, amountCell(it, X.now));
  if (f.tenure) row.append(el('span', { class: 'calc-dtag' }, el('span', { class: 'calc-bd calc-bd-q', text: f.tenure.cond }), f.tenure.state || '근속 연수를 넣으면 받는지 나눠 보여 드립니다'));
  const desc = descOf(it);
  if (desc) {
    row.append(srcText(desc, 'calc-src calc-dsrc'));
    const m2 = el('details', { class: 'calc-dmore' });
    m2.append(el('summary', { text: '설명 보기' }), srcText(desc, 'calc-src'));
    row.append(m2);
  }
  return row;
}
// 표식 — 최대·한도(금액 행), 가족 언급(원문 단어 강조와 함께), 근속 조건.
function facetTags(X, slot, it) {
  const desc = descOf(it);
  const inline = [];
  if (amtOf(it) != null && /최대|한도|상한/.test(desc)) inline.push(/한도/.test(desc) ? '한도액 기준' : '최대치 기준');
  if (/가족|배우자|자녀/.test(desc)) inline.push('설명에 ‘가족’ 언급');
  return { inline, tenure: tenureInfo(X, slot, it) };
}

function lump(id, sign, title, open, kids) {
  const d = el('details', { class: 'calc-lump', id: 'calc-lump-' + id });
  if (open) d.open = true;
  const s = el('summary', {}, el('span', { class: 'calc-sign calc-sign-' + id, 'aria-hidden': 'true', text: sign }), title);
  d.append(s, el('div', { class: 'calc-rows' }, ...kids));
  return d;
}

function pairVerdictText(X, r) {
  if (r.verdict === 'same') return '같음';
  if (r.verdict === 'unsure') return '비슷함(오차 범위 겹침)';
  const diff = amtOf(r.a) - amtOf(r.b);
  return el('b', { class: r.verdict === 'a' ? 'calc-mark-a' : 'calc-mark-b', text: X.nm[r.verdict] + ' +' + fmt(abs(diff)) });
}
const rangeTxt = (rg) => el('span', { class: 'calc-muted calc-xs', text: ' [' + fmt(rg[0]) + '~' + fmt(rg[1]) + ']' });

function isoBox(X) {
  const { report, nm } = X;
  const p = report.pairs;
  if (!p.mixed.length) return null;
  const ben = report.axes.benefits;
  const box = el('div', { class: 'calc-iso', id: 'calc-iso' });
  box.append(el('h4', { text: '⚠ 두 회사 모두 있지만 ' + onlyRegistered(X).replace(' 금액이 등록된', ' 금액이 등록된') + ' 복지 (' + p.mixed.length + '건)' }));
  const other = otherSide(X);
  const shareTxt = ben.mixed.share != null ? '(' + Math.round(ben.mixed.share * 100) + '%)' : '';
  box.append(el('p', { text: '복지 금액 차이 ' + m(abs(report.deltas.benDiff)) + ' 중 ' + m(abs(report.parts.mixed)) + shareTxt + '이 이 ' + p.mixed.length + '건에서 나옵니다.'
    + (other ? ' ' + other + ' 쪽 금액이 확인되면 차이는 그만큼 줄어듭니다.' : '') }));
  const rows = [...p.mixed].sort(byAmtDesc((r) => r[r.side])).map((r) => {
    const cellFor = (slot) => {
      const it = r[slot];
      if (r.side === slot) {
        const f = facetTags(X, slot, it);
        const kids = [amountCell(it, X.now)];
        for (const t of f.inline) kids.push(' ', el('span', { class: 'calc-tagm', text: t }));
        return td(kids, slot === 'a' ? 'calc-ca' : 'calc-cb');
      }
      return td([b('금액 미등록'), ' ', srcText(descOf(it))], slot === 'a' ? 'calc-ca' : 'calc-cb');
    };
    const name = r.a.benefit_nm === r.b.benefit_nm ? r.a.benefit_nm : r[r.side].benefit_nm;
    return el('tr', { class: X.isOff(r.side, r[r.side]) ? 'calc-off' : '' }, td(name), cellFor('a'), cellFor('b'));
  });
  box.append(tbl('calc-mtab', ['항목', [sym('a'), nm.a], [sym('b'), nm.b]], rows, ['', 'calc-ca', 'calc-cb']));
  const items = p.mixed.map((r) => ({ slot: r.side, cd: keyOf(r[r.side]) }));
  const allOff = p.mixed.every((r) => X.isOff(r.side, r[r.side]));
  const btn = el('button', { type: 'button', class: 'calc-btn', id: 'calc-iso-btn', 'aria-pressed': String(allOff), text: allOff ? '이 ' + p.mixed.length + '건을 다시 넣기' : '이 ' + p.mixed.length + '건을 빼고 다시 계산' });
  btn.addEventListener('click', () => { if (typeof X.ctx.onToggle === 'function') X.ctx.onToggle(items, !allOff); });
  let res;
  if (allOff) res = '→ 지금 보이는 결과가 이 ' + p.mixed.length + '건을 뺀 결과입니다.';
  else {
    const s = report.sens.rows.find((x) => x.key === 'drop_mixed');
    if (s) {
      const band = s.band ? '(' + fmt(s.totalDiff - s.band) + ' ~ ' + fmt(s.totalDiff + s.band) + ')' : '';
      const tail = {
        same: '결론은 같습니다', flip: '결론이 바뀝니다', near: '두 회사가 거의 같아집니다', unsure: '어느 쪽이 많다고 말하기 어려워집니다',
        decide: withJosa(s.totalDiff > 0 ? nm.b : nm.a, '이/가') + ' 많아집니다',
      }[s.result];
      res = '→ 빼고 계산하면 총보상 차이는 ' + m(s.totalDiff) + band + '으로, ' + tail;
    }
  }
  box.append(el('div', { class: 'calc-iso-act' }, btn, el('span', { class: 'calc-iso-res', text: res || '' })));
  return box;
}

function diffsBlock(X, axis) {
  const { report, nm } = X;
  const p = report.pairs;
  const catCount = {};
  for (const it of [...p.onlyA, ...p.onlyB]) catCount[it.benefit_ctgr_cd] = (catCount[it.benefit_ctgr_cd] || 0) + 1;
  const bothN = p.bothAmt.length + p.mixed.length + p.bothQual.length;
  const view = X.ctx.view || {};
  const ctrl = el('div', { class: 'calc-ctrl' });
  const tog = el('div', { class: 'calc-tog', role: 'group', 'aria-label': '보기 방식' });
  const bOnly = el('button', { type: 'button', 'aria-pressed': String(!view.diffAll), id: 'calc-diff-only', text: '달라지는 것만' });
  const bAll = el('button', { type: 'button', 'aria-pressed': String(!!view.diffAll), id: 'calc-diff-all', text: '전체' });
  tog.append(bOnly, bAll);
  ctrl.append(el('span', { class: 'calc-muted', text: '보기' }), tog, el('span', { class: 'calc-muted calc-xs', text: '「전체」를 누르면 두 회사 모두 있는 ' + bothN + '개도 펼쳐집니다' }));
  const lumpNew = lump('new', '＋', '새로 생깁니다 (' + p.onlyB.length + ')', true, sortForAxis(p.onlyB, axis, catCount).map((it) => drow(X, 'b', it)));
  // 두 회사 모두 — 금액 대 금액 · 둘 다 금액 미등록(비교하지 않음)
  const bothKids = [];
  if (p.bothAmt.length) {
    bothKids.push(el('h4', { class: 'calc-small', text: '두 회사 모두 금액이 등록된 ' + p.bothAmt.length + '개' }));
    const gap = (r) => abs(amtOf(r.a) - amtOf(r.b));
    const bothSorted = [...p.bothAmt].sort((x, y) => gap(y) - gap(x) || (amtOf(y.a) || 0) - (amtOf(x.a) || 0));
    bothKids.push(tbl('calc-mtab', ['항목', [sym('a'), nm.a], [sym('b'), nm.b], '비교'], bothSorted.map((r) => el('tr', { class: X.isOff('a', r.a) ? 'calc-off' : '' },
      td(r.a.benefit_nm === r.b.benefit_nm ? r.a.benefit_nm : r.a.benefit_nm + ' ↔ ' + r.b.benefit_nm),
      td([amountCell(r.a, X.now), rangeTxt(r.rangeA)], 'calc-ca'), td([amountCell(r.b, X.now), rangeTxt(r.rangeB)], 'calc-cb'), td([pairVerdictText(X, r)]))), ['', 'calc-ca', 'calc-cb', '']));
    const sameN = p.bothAmt.filter((r) => r.verdict === 'same').length;
    const rest = abs(report.parts.onlyA + report.parts.onlyB + report.parts.mixed);
    bothKids.push(el('p', { class: 'calc-foot', text: '두 회사 모두 금액이 등록된 항목은 ' + p.bothAmt.length + '개' + (sameN ? '이고, 그중 ' + sameN + '개는 금액이 같습니다.' : '입니다.')
      + ' 같은 복지끼리 비교한 차이는 ' + m(abs(report.parts.sameBoth)) + '이고, 나머지 ' + m(rest) + '은 한쪽에만 금액이 있는 항목에서 생깁니다.' }));
  }
  if (p.bothQual.length) {
    bothKids.push(el('h4', { class: 'calc-small', text: '둘 다 금액이 등록되지 않은 ' + p.bothQual.length + '개 — 비교하지 않음' }));
    bothKids.push(el('p', { class: 'calc-foot', text: '내용이 서로 달라 우열을 가리지 않았습니다. 설명을 나란히 놓았으니 직접 비교해 보세요.' }));
    bothKids.push(tbl('calc-mtab', ['항목', [sym('a'), nm.a], [sym('b'), nm.b]], p.bothQual.map((r) => el('tr', {},
      td(r.a.benefit_nm === r.b.benefit_nm ? r.a.benefit_nm : r.a.benefit_nm + ' ↔ ' + r.b.benefit_nm),
      td([srcText(descOf(r.a))], 'calc-ca'), td([srcText(descOf(r.b))], 'calc-cb'))), ['', 'calc-ca', 'calc-cb']));
  }
  const lumpBoth = lump('both', '＝', '두 회사 모두 있습니다 (' + bothN + ')', !!view.diffAll, bothKids);
  lumpBoth.querySelector('summary').append(el('span', { class: 'calc-muted calc-xs calc-lump-meta', text: '금액 비교 가능 ' + p.bothAmt.length + ' · 둘 다 금액 미등록 ' + p.bothQual.length + ' · 한쪽만 금액 등록 ' + p.mixed.length + (p.mixed.length ? '(아래)' : '') }));
  const lostItems = sortForAxis(p.onlyA, axis, catCount);
  const lumpLost = lump('lost', '－', nm.b + '에는 등록되어 있지 않습니다 (' + p.onlyA.length + ')', true, lostItems.map((it) => drow(X, 'a', it)));
  const setAll = (all) => {
    view.diffAll = all;
    lumpBoth.open = all;
    bOnly.setAttribute('aria-pressed', String(!all));
    bAll.setAttribute('aria-pressed', String(all));
  };
  bOnly.addEventListener('click', () => setAll(false));
  bAll.addEventListener('click', () => setAll(true));
  const qa = p.onlyA.filter((it) => amtOf(it) == null).length;
  const kids = [ctrl, lumpNew, lumpBoth, isoBox(X), lumpLost];
  if (p.onlyA.length) kids.push(el('p', { class: 'calc-foot', text: '이 ' + p.onlyA.length + '개 중 ' + qa + '개는 금액을 알 수 없어 계산에 0으로 넣었습니다.' }));
  const legal = [...p.legal.a.map((it) => [nm.a, it]), ...p.legal.b.map((it) => [nm.b, it])];
  if (legal.length) {
    const lp = el('p', { class: 'calc-foot' }, '법으로 모든 회사에 정해진 제도만 적혀 있어 비교에서 뺀 항목: ');
    legal.forEach(([who, it], i) => { if (i) lp.append(' · '); lp.append(el('span', { class: 'calc-bd calc-bd-legal', text: '법정' }), ' ' + it.benefit_nm + '(' + who + ')'); });
    kids.push(lp);
  }
  return blk('diffs', '이직하면 달라지는 복지 — 새로 생기는 것 ' + p.onlyB.length + ' · 두 회사 모두 있는 것 ' + bothN + ' · ' + nm.b + '에 등록되지 않은 것 ' + p.onlyA.length, '복지 변화', kids, 'calc-diffs');
}

// ── 근속 장부 ──────────────────────────────────────────────────────────────
function ledgerBlock(X) {
  const { report, nm } = X;
  const tg = report.tenure;
  const dl = el('dl', { class: 'calc-ledger' });
  const dd = (x, state) => el('dd', {}, sym('a'), x.item.benefit_nm + ' — ' + (x.years != null ? '근속 ' + x.years + '년 이상' : '근속 조건') + (state ? ' · ' : ''), state ? b(state) : '', srcText(descOf(x.item), 'calc-src calc-block'));
  let summary;
  if (tg.tenureYears != null) {
    if (tg.earned.length) { dl.append(el('dt', { text: '이미 받고 있는 것(이직하면 처음부터)' })); for (const x of tg.earned) dl.append(dd(x, '받는 중')); }
    if (tg.pending.length) { dl.append(el('dt', { text: '아직 못 받은 것' })); for (const x of tg.pending) dl.append(dd(x, fmt(x.left) + '년 남음')); }
    if (tg.unjudged.length) { dl.append(el('dt', { text: '근속 연수가 적혀 있지 않은 것' })); for (const x of tg.unjudged) dl.append(dd(x, null)); }
    summary = tg.earned.length ? '근속 ' + fmt(tg.tenureYears) + '년 덕분에 지금 받는 복지 ' + tg.earned.length + '개 — 이직하면 처음부터 다시 쌓아야 합니다'
      : tg.a.length ? '근속 ' + fmt(tg.tenureYears) + '년으로는 아직 받지 못한 근속 복지 ' + tg.a.length + '개 — 이직하면 처음부터 다시 쌓아야 합니다'
        : '근속 연수에 따라 받는 복지 — ' + nm.a + ' 등록 없음';
  } else {
    if (tg.a.length) {
      dl.append(el('dt', { text: nm.a + '에서 근속 연수에 따라 받는 복지' }));
      for (const x of tg.a) dl.append(dd(x, null));
      const tip = el('dd', { class: 'calc-muted' }, '근속 연수를 넣으면 지금 받고 있는 것과 아직 아닌 것을 갈라 드립니다 ');
      const go = el('button', { type: 'button', class: 'calc-link', text: '조건 고치기' });
      go.addEventListener('click', () => { if (typeof X.ctx.onEdit === 'function') X.ctx.onEdit(); });
      tip.append(go);
      dl.append(tip);
    }
    summary = '근속 연수에 따라 받는 복지 — ' + nm.a + ' ' + tg.a.length + '개 · ' + nm.b + ' ' + tg.otherSideCount + '개';
  }
  dl.append(el('dt', { text: nm.b + '에서 근속 연수에 따라 받는 복지' }));
  if (tg.b && tg.b.length) for (const x of tg.b) dl.append(el('dd', {}, sym('b'), x.item.benefit_nm + ' — ' + (x.years != null ? '근속 ' + x.years + '년 이상' : '근속 조건')));
  else dl.append(el('dd', { class: 'calc-muted', text: '등록 없음' }));
  return blk('ledger', summary, '근속 복지', [dl]);
}

// ── 복지 차이는 어디서 생기나(4분해 + 분야별 나비 차트) ─────────────────────
function partsBlock(X) {
  const { report, nm } = X;
  const pr = report.parts;
  const p = report.pairs;
  const vals = [pr.onlyA, pr.onlyB, pr.sameBoth, pr.mixed, pr.total];
  const maxNeg = Math.max(0, ...vals.map((v) => -v)), maxPos = Math.max(0, ...vals.map((v) => v));
  const span = maxNeg + maxPos || 1;
  const z = (maxNeg / span) * 100;
  const bar = (v, extra = '') => {
    const trk = el('div', { class: 'calc-pt-trk' }, el('span', { class: 'calc-pt-z', style: 'left:' + z.toFixed(2) + '%' }));
    if (v) {
      const w = (abs(v) / span) * 100;
      trk.append(el('span', { class: 'calc-pt-bar calc-pt-' + (v < 0 ? 'neg' : 'pos') + extra, style: (v < 0 ? 'right:' + (100 - z).toFixed(2) + '%' : 'left:' + z.toFixed(2) + '%') + ';width:' + w.toFixed(2) + '%' }));
    }
    return trk;
  };
  // 뺀 항목은 「(뺌)」 — 합계는 뺀 뒤의 값이라 목록만 보면 숫자가 안 맞는다.
  const cut = (slot, it) => (X.isOff(slot, it) ? '(뺌)' : '');
  const list = (items, slot) => items.filter((it) => amtOf(it) != null).map((it) => it.benefit_nm + ' ' + fmt(amtOf(it)) + cut(slot, it)).join(' · ');
  const aAmt = p.onlyA.filter((it) => amtOf(it) != null).length, bAmt = p.onlyB.filter((it) => amtOf(it) != null).length;
  const row = (label, v, items, extra = '', total = false) => el('div', { class: 'calc-pt-row' + (total ? ' calc-pt-total' : '') },
    el('span', { class: 'calc-pt-lbl' }, ...(Array.isArray(label) ? label : [label])), bar(v, extra),
    el('span', { class: 'calc-pt-v ' + (v < 0 ? 'calc-neg' : v > 0 ? 'calc-pos' : ''), text: fmtSigned(v) }), el('span', { class: 'calc-pt-items', text: items }));
  const partsBox = el('div', { class: 'calc-parts' },
    row(nm.b + '에 등록되지 않은 복지(금액 있는 ' + aAmt + '개)', pr.onlyA, list(p.onlyA, 'a')),
    row('새로 생기는 복지(금액 있는 ' + bAmt + '개)', pr.onlyB, list(p.onlyB, 'b')),
    row('같은 복지의 금액 차이', pr.sameBoth, p.bothAmt.map((r) => r.a.benefit_nm + ' ' + fmt(amtOf(r.b)) + '−' + fmt(amtOf(r.a)) + ' = ' + fmtSigned(amtOf(r.b) - amtOf(r.a)) + (cut('a', r.a) || cut('b', r.b))).join(' · ')));
  if (p.mixed.length) partsBox.append(row([hatch(), onlyRegistered(X) + ' 복지'], pr.mixed, [...p.mixed].sort(byAmtDesc((r) => r[r.side])).map((r) => r[r.side].benefit_nm + ' ' + fmt(amtOf(r[r.side])) + cut(r.side, r[r.side])).join(' · '), ' calc-pt-hatch'));
  const rest = abs(pr.onlyA + pr.onlyB + pr.mixed);
  partsBox.append(row(el('b', { text: '합계' }), pr.total, '= 복지 금액 차이 · 같은 복지끼리의 차이는 ' + m(abs(pr.sameBoth)) + '뿐이고, 나머지 ' + m(rest) + '은 한쪽에만 금액이 있는 항목에서 생깁니다', '', true));

  // 분야별 — 양쪽 금액(방향·비슷함) → 한쪽만 금액 → 항목 수만.
  const cats = report.cat.filter((c) => c.verdict !== 'empty');
  const both = cats.filter((c) => c.verdict === 'a' || c.verdict === 'b').sort((x, y) => abs(y.delta) - abs(x.delta));
  const sim = cats.filter((c) => c.verdict === 'similar');
  const one = cats.filter((c) => c.verdict === 'aOnly' || c.verdict === 'bOnly');
  const exc = cats.filter((c) => c.verdict === 'excluded');
  const cnt = cats.filter((c) => c.verdict === 'countOnly');
  // 금액이 없는 쪽의 말 — 뺀 것(빼고 계산함)과 등록되지 않은 것(금액 미등록)은 다른 사실이다(MED-5).
  const exOf = (c, slot) => (slot === 'a' ? c.exclA : c.exclB);
  const missTxt = (c, slot) => {
    const n = slot === 'a' ? c.cntA : c.cntB;
    return nm[slot] + ' ' + (exOf(c, slot) ? '빼고 계산함 · 항목 ' + n + '개' : n ? '금액 미등록 · 항목 ' + n + '개' : '등록 없음');
  };
  const missSlot = (c) => (c.verdict === 'aOnly' ? 'b' : 'a');
  const MAX = Math.max(100, ...cats.map((c) => Math.max(c.sumA + c.bandA, c.sumB + c.bandB)));
  const scaleMax = Math.ceil(MAX / 100) * 100;
  const pc = (v) => ((v / scaleMax) * 100).toFixed(2) + '%';
  const side = (cls, v, band, txt) => {
    const s = el('div', { class: 'calc-bf-side calc-bf-' + cls });
    if (v == null || v <= 0) { s.append(el('span', { class: 'calc-bf-txt', text: txt })); return s; }
    s.append(el('span', { class: 'calc-bf-bar', style: 'width:' + pc(v) }));
    if (band) s.append(el('span', { class: 'calc-bf-band', style: (cls === 'l' ? 'right:' : 'left:') + pc(Math.max(0, v - band)) + ';width:' + pc(band * 2) }));
    // 막대가 칸의 절반을 넘으면 값을 막대 **안**(축 쪽)에 쓴다 — 밖에 두면 좁은 폭에서 칸 끝을 넘어 잘린다.
    const inside = v / scaleMax > 0.45;
    s.append(el('span', {
      class: 'calc-bf-val' + (inside ? ' calc-bf-in' : ''),
      style: (cls === 'l' ? 'right:' : 'left:') + (inside ? '6px' : 'calc(' + pc(v) + ' + 6px)'), text: fmt(v),
    }));
    return s;
  };
  const dots = (cls, n) => {
    const s = el('div', { class: 'calc-bf-side calc-bf-' + cls }, el('div', { class: 'calc-bf-cnt' }));
    const c = s.firstChild;
    if (cls === 'rt') c.append(el('span', { text: String(n) }));
    for (let i = 0; i < Math.min(n, 12); i++) c.append(el('i'));
    if (cls === 'l') c.append(el('span', { text: String(n) }));
    return s;
  };
  const ariaSide = (c, slot) => {
    const sum = slot === 'a' ? c.sumA : c.sumB;
    return sum > 0 ? fmt(sum) : exOf(c, slot) ? nm[slot] + ' 빼고 계산함' : nm[slot] + ' 금액 미등록';
  };
  const bfly = el('div', { class: 'calc-bf', role: 'img', 'aria-label': '분야별 복지 금액 비교: ' + cats.map((c) => cat(c.ctgr) + ' ' + (c.verdict === 'countOnly' ? '항목 ' + c.cntA + ' 대 ' + c.cntB : ariaSide(c, 'a') + ' 대 ' + ariaSide(c, 'b') + (c.verdict === 'similar' ? '(비슷함)' : ''))).join(', ') });
  bfly.append(el('div', { class: 'calc-bf-hd', 'aria-hidden': 'true' }, el('span', { class: 'calc-bf-ha' }, sym('a'), nm.a + ' (만원)'), el('span', { class: 'calc-bf-hc', text: '분야' }), el('span', { class: 'calc-bf-hb' }, sym('b'), nm.b + ' (만원)'), el('span', { class: 'calc-bf-hd4', text: '차이' })));
  const addRow = (c) => {
    const r = el('div', { class: 'calc-bf-row calc-bf-' + c.verdict, 'aria-hidden': 'true' });
    if (c.verdict === 'countOnly') {
      r.append(dots('l', c.cntA), el('span', { class: 'calc-bf-cat', text: cat(c.ctgr) }), dots('rt', c.cntB), el('span', { class: 'calc-bf-diff calc-muted', text: '항목 수 ' + c.cntA + ' : ' + c.cntB }));
    } else if (c.verdict === 'aOnly' || c.verdict === 'bOnly' || c.verdict === 'excluded') {
      const aSide = c.verdict === 'aOnly' ? side('l', c.sumA, c.bandA) : side('l', null, 0, missTxt(c, 'a'));
      const bSide = c.verdict === 'bOnly' ? side('rt', c.sumB, c.bandB) : side('rt', null, 0, missTxt(c, 'b'));
      const cutHere = c.verdict === 'excluded' || exOf(c, missSlot(c));
      r.append(aSide, el('span', { class: 'calc-bf-cat', text: cat(c.ctgr) }), bSide, el('span', { class: 'calc-bf-diff calc-muted', text: cutHere ? '빼고 계산함' : '비교 불가' }));
    } else {
      r.append(side('l', c.sumA, c.bandA), el('span', { class: 'calc-bf-cat', text: cat(c.ctgr) }), side('rt', c.sumB, c.bandB),
        c.verdict === 'similar' ? el('span', { class: 'calc-bf-diff' }, el('span', { class: 'calc-stat', text: '비슷함' })) : el('span', { class: 'calc-bf-diff ' + (c.delta < 0 ? 'calc-neg' : 'calc-pos'), text: fmtSigned(c.delta) }));
    }
    bfly.append(r);
  };
  [...both, ...sim, ...one, ...exc].forEach(addRow);
  if (cnt.length) {
    bfly.append(el('div', { class: 'calc-bf-sub', 'aria-hidden': 'true', text: '금액이 등록되지 않은 분야 — 항목 수만 표시(결론에는 쓰지 않음)' }));
    cnt.forEach(addRow);
  }
  bfly.append(el('div', { class: 'calc-bf-axis', 'aria-hidden': 'true' }, el('span', { class: 'calc-bf-al' }, el('span', { text: fmt(scaleMax) }), el('span', { text: '0' })), el('span'), el('span', { class: 'calc-bf-ar' }, el('span', { text: '0' }), el('span', { text: fmt(scaleMax) })), el('span')));
  const tenureLine = el('p', { class: 'calc-small', text: '근속 연수에 따라 받는 복지: ' + nm.a + ' ' + report.tenure.a.length + '개 · ' + nm.b + ' ' + report.tenure.otherSideCount + '개' });
  // 요약 줄
  const bits = [];
  if (both[0]) bits.push(cat(both[0].ctgr) + ' 분야에서 ' + m(abs(both[0].delta)));
  const noReg = { a: [], b: [] }, cutOut = { a: [], b: [] };
  for (const c of one) (exOf(c, missSlot(c)) ? cutOut : noReg)[missSlot(c)].push(cat(c.ctgr));
  if (noReg.b.length) bits.push(withJosa(noReg.b.join('·'), '은/는') + ' ' + nm.b + ' 금액 미등록');
  if (noReg.a.length) bits.push(withJosa(noReg.a.join('·'), '은/는') + ' ' + nm.a + ' 금액 미등록');
  if (cutOut.b.length) bits.push(withJosa(cutOut.b.join('·'), '은/는') + ' ' + nm.b + ' 금액을 빼고 계산');
  if (cutOut.a.length) bits.push(withJosa(cutOut.a.join('·'), '은/는') + ' ' + nm.a + ' 금액을 빼고 계산');
  if (exc.length) bits.push(withJosa(exc.map((c) => cat(c.ctgr)).join('·'), '은/는') + ' 금액을 모두 빼고 계산');
  if (sim.length) bits.push(withJosa(sim.map((c) => cat(c.ctgr)).join('·'), '은/는') + ' 비슷함');
  const summary = '복지 차이는 어디서 생기나' + (bits.length ? ' — ' + bits.join(' · ') : '');
  return blk('parts', summary, '차이 나누어 보기', [
    el('h3', { class: 'calc-h3' }, '복지 금액 차이 ' + fmtSigned(pr.total) + '만원은 어디서 왔나 ',
      ...(maxNeg || maxPos ? [el('small', { text: '막대 눈금 ' + (maxNeg ? '−' + fmt(maxNeg) : '0') + ' ~ ' + (maxPos ? '+' + fmt(maxPos) : '0') + '만원 · 가운데 세로선이 0' })] : [])), partsBox, // 전부 0(금액 행을 모두 뺌)이면 「0 ~ 0」 눈금을 쓰지 않는다
    el('h3', { class: 'calc-h3 calc-gap-top' }, '분야별 복지 금액 ', el('small', { text: '● ' + nm.a + ' 왼쪽 · ■ ' + nm.b + ' 오른쪽 · 같은 눈금 0~' + fmt(scaleMax) + '만원 · 막대 끝 흐린 부분은 오차 범위' })),
    bfly, catTable(X, cats),
    el('p', { class: 'calc-note', text: '오차 범위가 겹치는 분야는 어느 쪽이 많다고 하지 않았습니다. 한쪽에만 금액이 있는 분야는 막대를 하나만, 금액이 없는 분야는 항목 수만 표시했습니다. 항목 수는 회사가 얼마나 자세히 공개했는지에 따라 달라지므로 결론에 쓰지 않습니다.' }),
    tenureLine,
  ]);
}
function catTable(X, cats) {
  const t = el('table');
  t.append(el('caption', { text: '분야별 복지 금액(만원)' }));
  t.append(el('thead', {}, el('tr', {}, el('th', { text: '분야' }), el('th', { text: X.nm.a }), el('th', { text: X.nm.b }), el('th', { text: '차이' }))));
  const tb = el('tbody');
  for (const c of cats) {
    const cell = (sum, band, cnt, excl) => (sum > 0 ? fmt(sum) + ' (±' + fmt(band) + ')' : excl ? '빼고 계산함 · 항목 ' + cnt + '개' : cnt ? '금액 미등록 · 항목 ' + cnt + '개' : '등록 없음');
    const cutHere = c.verdict === 'excluded' || (c.verdict === 'aOnly' && c.exclB) || (c.verdict === 'bOnly' && c.exclA);
    const diff = c.verdict === 'similar' ? '비슷함(오차 범위 겹침)' : c.verdict === 'countOnly' ? '항목 수만' : cutHere ? '빼고 계산함'
      : (c.verdict === 'aOnly' || c.verdict === 'bOnly') ? '비교 불가' : fmtSigned(c.delta);
    tb.append(el('tr', {}, el('td', { text: cat(c.ctgr) }), el('td', { text: c.verdict === 'countOnly' ? '항목 ' + c.cntA : cell(c.sumA, c.bandA, c.cntA, c.exclA) }),
      el('td', { text: c.verdict === 'countOnly' ? '항목 ' + c.cntB : cell(c.sumB, c.bandB, c.cntB, c.exclB) }), el('td', { text: diff })));
  }
  t.append(tb);
  return srOnly(t);
}

// ── 결론이 바뀌는 경우 + 물어볼 것 ─────────────────────────────────────────
function sensText(X, s) {
  const { nm, report } = X;
  if (s.key === 'b_wage_flip') {
    if (s.to === 'separate') {
      const main = el('span', {}, withJosa(nm.b, '이/가') + ' ', b('야근수당을 따로 준다면'), '(주 40시간을 넘는 ' + fmt1(s.extraHrs) + '시간분 → 연 ' + m(s.otB) + ')');
      const sub = el('div', { class: 'calc-sens-sub', text: '계산: 시급 ' + fmt(s.hourlyBase) + '원(' + m(report.b.salRange.mid) + ' ÷ 12개월 ÷ 209시간) × ' + fmt1(s.extraHrs) + '시간 × 1.5배 × 4.33주 × 12개월 = ' + m(s.otB) + '.'
        + beSensText(X, s.breakeven) });
      return [main, sub];
    }
    return [el('span', {}, withJosa(nm.b, '이/가') + ' ', b('포괄임금제라면'), '(입력하신 야근수당 연 ' + m(report.b.otPay) + '을 빼고 계산)')];
  }
  const items = [...(s.items || [])].sort((x, y) => y.amt - x.amt).map((x) => x.nm + ' ' + fmt(x.amt)).join(' · ');
  if (s.key === 'drop_mixed') return [onlyRegistered(X) + ' ' + s.count + '건(' + m(s.amount) + ')을 빼면'];
  if (s.key === 'drop_capped') return ['‘최대’·‘한도’ 금액으로 적힌 ' + s.count + '건(' + items + ' = ' + m(s.amount) + ')을 빼면'];
  if (s.key === 'drop_both') return ['위 두 경우(한쪽에만 금액 등록 · 최대·한도)를 모두 빼면(' + s.count + '건, ' + m(s.amount) + ')'];
  return ['복지를 아예 빼면'];
}
// 비포괄 가정의 같아지는 연봉 — 범위 밖이면 숫자 없이(MED-4).
function beSensText(X, be) {
  if (!be) return '';
  const { nm, report } = X;
  const salB = report.b.salRange.mid;
  if (be.bound === 'low' && salB >= be.sal) return ' 이 경우 ' + withJosa(nm.b, '은/는') + ' 연봉 협상과 상관없이 총보상이 더 많습니다.';
  if (be.bound === 'high' && salB < be.sal) return ' 이 경우에도 ' + nm.b + ' 연봉이 현재 연봉의 두 배가 되어도 총보상이 같아지지 않습니다.';
  return ' 이 경우 ' + nm.b + ' 연봉이 ' + m(be.sal) + '(' + fmtPct(be.rate) + ')' + (salB >= be.sal ? '만 돼도' : '은 되어야') + ' 총보상이 같아집니다.';
}
function sensFlipSentence(X, s) {
  const win = s.totalDiff > 0 ? X.nm.b : X.nm.a;
  const lead = s.key === 'b_wage_flip' ? (s.to === 'separate' ? withJosa(X.nm.b, '이/가') + ' 야근수당을 따로 준다면' : withJosa(X.nm.b, '이/가') + ' 포괄임금제라면')
    : sensText(X, s)[0];
  return lead + ' ' + withJosa(win, '이/가') + ' 연 ' + m(abs(s.totalDiff)) + ' 많아집니다';
}

function askBlock(X) {
  const { report, nm } = X;
  if (!report.ask.length) return null;
  const ol = el('ol');
  for (const a of report.ask) {
    if (a.kind === 'wage') ol.append(el('li', { text: '포괄임금제인지, 야근수당을 따로 주는지 — 이것 하나로 총보상이 ' + m(a.amount) + ' 달라집니다.' }));
    if (a.kind === 'mixed') ol.append(el('li', {}, a.names.join('·') + ' 지원이 ', b('1년에 얼마인지'), ' — 제도는 있는데 금액이 등록되어 있지 않습니다.'));
    if (a.kind === 'topOnlyA') {
      const topic = ASK_TOPIC[a.ctgr] || '비슷한 복지';
      ol.append(el('li', { text: withJosa(topic, '이/가') + ' 있는지 — ' + nm.a + ' 「' + a.nm + '」 ' + m(a.amt) + '이 복지 금액 차이의 ' + Math.round(a.share * 100) + '%를 차지합니다.' }));
    }
  }
  return el('div', { class: 'calc-ask' }, el('h4', { text: nm.b + '에 물어볼 것' }), ol);
}

function sensBlock(X) {
  const { report } = X;
  const rows = report.sens.rows;
  const resultBd = (r) => ({
    flip: el('span', { class: 'calc-bd calc-bd-warn', text: '결론 바뀜' }),
    decide: el('span', { class: 'calc-bd calc-bd-warn', text: withJosa(r.totalDiff > 0 ? X.nm.b : X.nm.a, '이/가') + ' 많아짐' }),
    same: '그대로', near: '거의 같습니다', unsure: '판단하기 어려움',
  }[r.result]);
  const trs = rows.map((r, i) => el('tr', {}, td(CIRCLED[i] || String(i + 1)), td(sensText(X, r)),
    td([el('b', { class: directional(r.tier) ? (r.totalDiff < 0 ? 'calc-neg' : 'calc-pos') : '', text: fmtSigned(r.totalDiff) + '만원' }), r.band && r.key !== 'b_wage_flip' && r.key !== 'no_benefits' ? ' (±' + fmt(r.band) + ')' : ''], 'calc-r'),
    td([resultBd(r)])));
  // 기준(판정 카드와 같은 티어)이 방향이 아니면 뒤집을 결론이 없다 — 「결론이 바뀌는」이 아니라 「말할 수 있게 되는」(LOW-12).
  const flip = rows.find((r) => r.flips);
  const dec = rows.find((r) => r.decides);
  let summary;
  if (flip) summary = '결론이 바뀌는 경우 — ' + sensFlipSentence(X, flip);
  else if (dec) summary = '어느 쪽이 많은지 말할 수 있게 되는 경우 — ' + sensFlipSentence(X, dec);
  else if (!directional(report.sens.baseTier)) summary = '조건을 바꿔 봐도 어느 한쪽이 분명하게 앞서지 않습니다';
  else if (rows.some((r) => r.result !== 'same')) summary = '조건에 따라 차이가 줄어들 수는 있지만 결론이 뒤집히지는 않습니다';
  else summary = '조건을 바꿔 봐도 결론은 그대로입니다';
  summary = withAssume(X, summary);
  const kids = [assumeLine(X)].filter(Boolean);
  if (rows.length) kids.push(tbl('calc-sens', ['', '이렇게 바뀐다면(모두 다시 계산한 값)', '총보상 차이', '결과'], trs, ['', '', 'calc-r', '']));
  kids.push(askBlock(X));
  return blk('sens', summary, '조건 바꿔 보기', kids);
}

// ── 총보상 구성 ────────────────────────────────────────────────────────────
function compBlock(X) {
  const { report, nm, ws } = X;
  const row = (slot) => {
    const r = report[slot];
    const tot = r.total || 1;
    const segs = [['calc-cs1', r.salRange.mid, '연봉'], ['calc-cs2', r.net, '복지'], ['calc-cs3', r.otPay, '야근수당']];
    const bar = el('div', { class: 'calc-comp-bar', 'aria-hidden': 'true' });
    for (const [cls, v] of segs) if (v > 0) bar.append(el('i', { class: cls, style: 'width:' + ((v / tot) * 100).toFixed(1) + '%', text: (v / tot) > 0.12 ? fmt(v) : '' }));
    const cap = segs.map(([, v, k]) => k + ' ' + fmt(v) + (v > 0 ? ' (' + ((v / tot) * 100).toFixed(1) + '%)' : '')).join(' │ ');
    return el('div', { class: 'calc-comp-row calc-comp-' + slot }, el('span', {}, sym(slot), nm[slot]), bar, el('span', { class: 'calc-comp-tot', text: '= ' + fmt(r.total) }), el('span', { class: 'calc-comp-cap', text: cap }));
  };
  const lg = el('div', { class: 'calc-comp-lg', 'aria-hidden': 'true' }, el('span', {}, el('i', { class: 'calc-cs1' }), '연봉'), el('span', {}, el('i', { class: 'calc-cs2' }), '복지(금액 환산)'), el('span', {}, el('i', { class: 'calc-cs3' }), '야근수당'));
  const share = (slot) => (report[slot].total ? Math.round((report[slot].net / report[slot].total) * 100) : 0);
  const notes = [];
  for (const s of ['a', 'b']) {
    const w = (ws[s] || {}).wage;
    const h = report[s].wsHours;
    if (!h) notes.push(nm[s] + ' 야근수당은 주 근무시간을 넣지 않아 계산하지 않았습니다.');
    else if (h > 40 && w === 'inclusive') notes.push(nm[s] + ' 야근수당은 입력하신 대로 포괄임금제라 0으로 계산했습니다.');
    else if (h > 40 && w == null) notes.push(nm[s] + ' 야근수당은 입력하신 조건에 포괄·비포괄이 없어 여기서는 0으로 두었습니다(두 경우는 연봉 기준 화면에).');
  }
  return blk('comp', withJosa(nm.a, '은/는') + ' 총보상의 ' + share('a') + '%가 복지, ' + withJosa(nm.b, '은/는') + ' ' + share('b') + '%입니다', '총보상 구성',
    [el('div', { class: 'calc-comp' }, lg, row('a'), row('b'), ...notes.map((t) => el('p', { class: 'calc-help', text: t })))]);
}

// ── 복지 전체 비교표(L3) + 행별 「빼고 다시 계산」 ───────────────────────────
function contrastRows(X) {
  const p = X.report.pairs;
  const rows = [];
  const gap = (r) => abs(amtOf(r.a) - amtOf(r.b));
  for (const r of [...p.bothAmt].sort((x, y) => gap(y) - gap(x))) rows.push({ sec: 1, r, a: r.a, b: r.b, same: r.verdict === 'same', items: [{ slot: 'a', cd: keyOf(r.a) }, { slot: 'b', cd: keyOf(r.b) }] });
  for (const r of [...p.mixed].sort(byAmtDesc((x) => x[x.side]))) rows.push({ sec: 2, r, a: r.a, b: r.b, items: [{ slot: r.side, cd: keyOf(r[r.side]) }] });
  for (const it of [...p.onlyA].sort(byAmtDesc((x) => x))) rows.push({ sec: 3, a: it, b: null, items: amtOf(it) != null ? [{ slot: 'a', cd: keyOf(it) }] : [] });
  for (const it of [...p.onlyB].sort(byAmtDesc((x) => x))) rows.push({ sec: 3, a: null, b: it, items: amtOf(it) != null ? [{ slot: 'b', cd: keyOf(it) }] : [] });
  for (const r of p.bothQual) rows.push({ sec: 4, r, a: r.a, b: r.b, items: [] });
  return rows;
}
function ctCell(X, it, slot) {
  const cls = slot === 'a' ? 'calc-ca' : 'calc-cb';
  const lab = el('span', { class: 'calc-ct-who', 'aria-hidden': 'true' }, sym(slot), X.nm[slot]);
  if (!it) return td([lab, el('span', { class: 'calc-muted', text: '등록 없음' })], cls);
  const desc = descOf(it);
  if (amtOf(it) == null) return td([lab, '✓ 제도 있음 · 금액 미등록', desc ? srcText(desc, 'calc-src calc-block') : ''], cls);
  return td([lab, amountCell(it, X.now), desc ? srcText(desc, 'calc-src calc-block') : ''], cls);
}
function contrastBlock(X) {
  const { report, nm, ex } = X;
  const view = X.ctx.view || {};
  const filter = view.ctFilter || 'diff';
  const rows = contrastRows(X);
  const SEC = {
    1: '두 회사 모두 금액이 등록된 복지 (' + rows.filter((r) => r.sec === 1).length + ')',
    2: '두 회사 모두 있지만 ' + onlyRegistered(X) + ' 복지 (' + rows.filter((r) => r.sec === 2).length + ')',
    3: '한쪽 회사에만 있는 복지 (' + rows.filter((r) => r.sec === 3).length + ')',
    4: '두 회사 모두 있지만 금액이 등록되지 않은 복지 (' + rows.filter((r) => r.sec === 4).length + ')',
  };
  // 다시 계산한 결과 칸 — 빼기 전(baseline)과 견준다.
  const d = report.deltas.totalDiff, band = report.band.delta;
  const tier = report.axes.salary.baseTier;
  const base = X.ctx.baseline;
  const baseTier = base && base.axes ? base.axes.salary.baseTier : tier;
  const recalc = el('div', { class: 'calc-recalc', id: 'calc-recalc', tabindex: '-1' }); // 「모두 되돌리기」 뒤 포커스 자리(LOW-5)
  recalc.append(el('span', { class: 'calc-muted calc-small', text: '다시 계산한 총보상 차이' + (report.wage ? ' · ' + assumeIf(X) : '') }),
    el('span', { class: 'calc-small', text: ex.rows ? ex.rows + '건 뺌 · ' + nm.a + ' ' + m(ex.a.amt) + ' · ' + nm.b + ' ' + m(ex.b.amt) + ' 제외' : '뺀 항목 없음' }));
  // 판단하기 어려움이면 차액도 범위도 두지 않는다 — 범위 두 끝이면 차액이 나온다(LOW-1: 결론 카드·첫 타일·보조 행·이 칸).
  if (tier === 'unsure') recalc.append(el('span', { class: 'calc-recalc-v calc-recalc-na', text: '판단 불가' }));
  else {
    recalc.append(el('span', { class: 'calc-recalc-v' }, fmtSigned(d), el('small', { text: '만원' })));
    if (hasBand(band)) recalc.append(el('span', { class: 'calc-small calc-muted', text: '범위 ' + fmt(d - band) + ' ~ ' + fmt(d + band) }));
  }
  let st;
  if (!ex.rows) st = null;
  else if (tier === 'unsure') st = el('span', { class: 'calc-bd calc-bd-q', text: report.axes.salary.unsureBy === 'guard' ? '한쪽만 등록된 금액에 따라 갈립니다' : '오차 범위가 겹칩니다' });
  else if (tier === baseTier) st = el('span', { class: 'calc-bd calc-bd-neutral', text: '결론 그대로' });
  else st = el('span', { class: 'calc-bd calc-bd-warn', text: '결론 바뀜' });
  if (st) recalc.append(el('span', { class: 'calc-recalc-st' }, st));
  const reset = el('button', { type: 'button', class: 'calc-btn-sm', id: 'calc-ct-reset', text: '모두 되돌리기' });
  reset.disabled = !ex.rows;
  reset.addEventListener('click', () => { if (typeof X.ctx.onReset === 'function') X.ctx.onReset(); });
  recalc.append(reset);

  const ctrl = el('div', { class: 'calc-ctrl' });
  const tog = el('div', { class: 'calc-tog', role: 'group', 'aria-label': '비교표 보기' });
  const fbtns = [['all', '전체'], ['diff', '달라지는 것만'], ['common', '두 회사 모두 있는 것']].map(([f, t]) => {
    const btn = el('button', { type: 'button', 'data-f': f, id: 'calc-ctf-' + f, 'aria-pressed': String(f === filter), text: t });
    btn.addEventListener('click', () => applyFilter(f));
    return btn;
  });
  tog.append(...fbtns);
  ctrl.append(el('span', { class: 'calc-muted', text: '보기' }), tog, el('span', { class: 'calc-muted calc-xs', text: '빼면 그 항목의 금액과 오차 범위가 함께 빠집니다' }));

  const table = el('table', { class: 'calc-tbl calc-ct' });
  table.append(el('caption', { class: 'sr-only', text: '복지 전체 비교표 — 행마다 「빼고 다시 계산」 스위치가 있습니다.' }));
  table.append(el('thead', {}, el('tr', {}, el('th', { scope: 'col', text: '항목' }), el('th', { scope: 'col', class: 'calc-ca' }, sym('a'), nm.a), el('th', { scope: 'col', class: 'calc-cb' }, sym('b'), nm.b), el('th', { scope: 'col', text: '비교 · 계산에서 빼기' }))));
  const tb = el('tbody');
  let cur = 0;
  for (const row of rows) {
    if (row.sec !== cur) { cur = row.sec; tb.append(el('tr', { class: 'calc-ct-sec', 'data-sec': String(cur) }, el('th', { colspan: '4', scope: 'rowgroup', text: SEC[cur] }))); }
    const off = row.items.length && row.items.every((x) => X.isOff(x.slot, x.slot === 'a' ? row.a : row.b));
    const tr = el('tr', { 'data-sec': String(row.sec), class: off ? 'calc-off' : '' });
    if (row.same) tr.setAttribute('data-same', '1');
    const name = row.a && row.b && row.a.benefit_nm !== row.b.benefit_nm ? row.a.benefit_nm + ' ↔ ' + row.b.benefit_nm : (row.a || row.b).benefit_nm;
    const it0 = row.a || row.b;
    tr.append(el('td', { class: 'calc-ct-nm' }, el('span', { class: 'calc-dcat', text: cat(it0.benefit_ctgr_cd) }), el('span', { class: 'calc-dnm', text: name })));
    tr.append(ctCell(X, row.a, 'a'), ctCell(X, row.b, 'b'));
    let vd;
    if (row.sec === 1) vd = pairVerdictText(X, row.r);
    else if (row.sec === 2) vd = el('span', {}, hatch(), (otherSide(X) || '한쪽') + ' 금액 미등록');
    else if (row.sec === 3) vd = row.a ? nm.b + ' 미등록' : '새로 생김';
    else vd = '비교 불가';
    const vc = el('td', { class: 'calc-ct-vc' }, el('span', {}, vd));
    if (row.items.length) {
      const id = 'calc-sw-' + row.items.map((x) => x.slot + '-' + x.cd).join('_').replace(/[^0-9A-Za-z_-]/g, '');
      const sw = el('button', { type: 'button', class: 'calc-sw', id, 'aria-pressed': String(!!off) }, el('i', { 'aria-hidden': 'true' }), '빼고 다시 계산');
      sw.setAttribute('aria-label', name + ' — 빼고 다시 계산');
      sw.addEventListener('click', () => { if (typeof X.ctx.onToggle === 'function') X.ctx.onToggle(row.items, !off); });
      vc.append(sw);
    } else vc.append(el('span', { class: 'calc-noamt', text: '금액 미등록' }));
    tr.append(vc);
    tb.append(tr);
  }
  table.append(tb);
  const wrap = el('div', { class: 'calc-tblwrap calc-ct-wrap' }, table);
  function applyFilter(f) {
    view.ctFilter = f;
    for (const btn of fbtns) btn.setAttribute('aria-pressed', String(btn.getAttribute('data-f') === f));
    for (const tr of table.querySelectorAll('tbody tr')) {
      const sec = Number(tr.getAttribute('data-sec'));
      let hide = false;
      if (f === 'diff') hide = sec === 4 || tr.getAttribute('data-same') === '1';
      else if (f === 'common') hide = sec === 3;
      tr.classList.toggle('calc-hidden-row', hide);
    }
  }
  applyFilter(filter);
  // 법정 행은 이 표에 없다(SP-LEGAL-5) — 제목이 「전체」라고 거짓말하지 않게 적고, 아래에 무엇을 뺐는지 남긴다.
  const legal = [...report.pairs.legal.a.map((it) => [nm.a, it]), ...report.pairs.legal.b.map((it) => [nm.b, it])];
  const kids = [recalc, ctrl, wrap];
  if (legal.length) {
    const lp = el('p', { class: 'calc-foot' }, '법으로 모든 회사에 정해진 제도만 적혀 있어 이 표와 계산에서 뺀 항목: ');
    legal.forEach(([who, it], i) => { if (i) lp.append(' · '); lp.append(el('span', { class: 'calc-bd calc-bd-legal', text: '법정' }), ' ' + it.benefit_nm + '(' + who + ')'); });
    kids.push(lp);
  }
  return blk('contrast', '복지 전체 비교표' + (legal.length ? '(법정 복지 제외)' : '') + ' — ' + nm.a + ' ' + report.axes.benefits.counts.a + '개 · ' + nm.b + ' ' + report.axes.benefits.counts.b + '개 · 안 쓸 복지는 빼고 다시 계산해 보세요',
    '전체 목록', kids, 'calc-ct-blk');
}

// ── 이 비교에 쓴 자료(L3) ──────────────────────────────────────────────────
function basisBlock(X) {
  const { report, nm } = X;
  const bs = report.basis;
  const waffle = (slot) => {
    const s = bs[slot];
    const g = el('div', { class: 'calc-waffle-g', 'aria-hidden': 'true' });
    for (let i = 0; i < s.total; i++) g.append(el('i', { class: i < s.amt ? 'calc-wf-f' : '' }));
    return el('div', { class: 'calc-waffle-' + slot }, el('div', { class: 'calc-waffle-k' }, sym(slot), nm[slot] + ' 복지 ' + s.total + '개', el('span', { text: '■ 금액 있음 ' + s.amt + ' · □ 금액 미등록 ' + s.qual })), g);
  };
  const ul = el('ul', { class: 'calc-basis' });
  const li = (...kids) => el('li', {}, ...kids);
  ul.append(li(el('span', { class: badgeClassBem('official'), text: BADGE_LABEL_SHORT.official }), ' 회사가 직접 밝힌 금액(' + nm.a + ' ' + bs.a.stated + ' · ' + nm.b + ' ' + bs.b.stated + ')'));
  ul.append(li(el('span', { class: badgeClassBem('est'), text: BADGE_LABEL_SHORT.est }), ' 비슷한 제도의 일반적인 금액을 기준으로 추정한 금액(' + nm.a + ' ' + bs.a.estimated + ' · ' + nm.b + ' ' + bs.b.estimated + ')'));
  const capped = [...bs.a.capped.map((x) => [nm.a, x]), ...bs.b.capped.map((x) => [nm.b, x])];
  if (capped.length) ul.append(li(el('span', { class: 'calc-tagm', text: '최대치·한도액 기준' }), ' 설명에 ‘최대’나 ‘한도’가 적혀 있어 실제로 받는 돈은 더 적을 수 있는 금액(' + capped.map(([w, x]) => w + ' ' + x.nm + ' ' + fmt(x.amt)).join(' · ') + ')'));
  const expired = (bs.a.expired || 0) + (bs.b.expired || 0);
  const exp = expired ? '이번 비교에서는 ' + expired + '건이 유효기간을 넘겨 범위를 넓혔습니다' : bs.earliestExpiry ? '이번 비교는 해당 없음 — 가장 빠른 유효기간이 ' + String(bs.earliestExpiry).slice(0, 10) + '입니다' : '이번 비교는 해당 없음';
  ul.append(li('오차 범위: 공식 금액 ±5% · 추정 금액 ±20%. 자료가 유효기간을 넘기면 범위를 15%p 넓힙니다(' + exp + ').'));
  ul.append(li('계산하지 않은 것: 세금·4대보험(모두 세전 기준) · 통근 시간의 금액 환산 · 법정 연차(두 회사의 연차 일수를 확인하지 못함) · 금액을 알 수 없는 복지 ' + (bs.a.qual + bs.b.qual) + '개 · 퇴직금·주가 변동'));
  const legalN = (bs.a.legal || 0) + (bs.b.legal || 0);
  if (legalN) ul.append(li(el('span', { class: 'calc-bd calc-bd-legal', text: '법정' }), ' 법으로 모든 회사에 정해진 제도만 적힌 항목 ' + legalN + '개는 표시만 하고 비교에서 뺐습니다.'));
  ul.append(li('복지 금액에는 대출 한도나 한 번만 주는 포상처럼 1년 단위가 아닌 값이 섞여 있을 수 있어서, 위에서 여러 경우로 나눠 다시 계산해 보였습니다. 또 복지는 연봉과 세금 방식이 달라, 실제로 손에 쥐는 금액은 이보다 작을 수 있습니다.'));
  const amtN = bs.a.amt + bs.b.amt;
  return blk('basis', '이 비교에 쓴 자료 — 금액 ' + amtN + '건(회사 공개 ' + (bs.a.stated + bs.b.stated) + ' · 추정 ' + (bs.a.estimated + bs.b.estimated) + ') · 금액을 알 수 없는 복지 ' + (bs.a.qual + bs.b.qual) + '건',
    '자료 출처', [el('div', { class: 'calc-waffle' }, waffle('a'), waffle('b')), ul]);
}

// ══ 조립 ════════════════════════════════════════════════════════════════════
const BUILD = {
  bridge: bridgeBlock, robust: robustBlock, time: timeBlock, excerpt: excerptBlock, diffs: diffsBlock,
  ledger: ledgerBlock, parts: partsBlock, sens: sensBlock, comp: compBlock, contrast: contrastBlock, basis: basisBlock,
};
const CARD = { salary: salaryCard, wlb: wlbCard, benefits: benefitsCard };

/** 판정 카드 헤드라인의 글자만 — aria-live 한 줄(결론만 읽는다, FINAL-DESIGN §8-4). */
export function headlineText(report, ctx, axis) {
  const X = makeCtx(report, ctx);
  const c = CARD[axis](X);
  const hl = c.querySelector ? c.querySelector('.calc-hl') : null;
  return AXIS_LABEL[axis] + (axis === 'salary' ? '으로' : '로') + ' 보면: ' + (hl ? hl.textContent : '');
}

function liveRegion(mountEl) {
  if (typeof document === 'undefined' || typeof document.getElementById !== 'function') return null;
  let live = document.getElementById('calc-live');
  if (live) return live;
  live = el('p', { id: 'calc-live', class: 'sr-only', 'aria-live': 'polite' });
  // 다시 그리는 #report-body 밖에 둔다 — 갓 만든 live 영역의 첫 글자는 읽히지 않는 리더가 있다.
  const parent = mountEl && mountEl.parentNode;
  if (parent && typeof parent.insertBefore === 'function') parent.insertBefore(live, mountEl); else if (mountEl) mountEl.append(live);
  return live;
}

/**
 * 계산기 결과를 그린다. ctx.preserve = 「빼고 다시 계산」으로 다시 그리는 중 — 열린 칸·스크롤 자리·포커스를 지킨다.
 * ctx.renderRecent(mount) 는 report.js 가 넘기는 「최근 비교」 렌더러(순환 import 방지).
 */
export function renderCalcReport(report, mountEl, ctx = {}) {
  const view = ctx.view || (ctx.view = { open: {}, ctFilter: 'diff', diffAll: false });
  const doc = typeof document !== 'undefined' ? document : null;
  // 다시 그리기 전의 자리 — 포커스 요소와 화면 위치(스크롤 보정), 열린 칸.
  let anchorId = null, anchorTop = null;
  if (ctx.preserve && mountEl.querySelectorAll) {
    for (const d of mountEl.querySelectorAll('details[id]')) view.open[d.id] = d.open;
    const act = doc && doc.activeElement;
    if (act && act.id && mountEl.contains(act) && typeof act.getBoundingClientRect === 'function') { anchorId = act.id; anchorTop = act.getBoundingClientRect().top; }
  }
  const axis = ctx.axis && CARD[ctx.axis] ? ctx.axis : 'salary';
  const X = makeCtx(report, ctx);
  mountEl.replaceChildren();
  const root = el('div', { class: 'calc-rp', 'data-axis': axis });
  if (X.ex.rows) {
    const n = el('p', { class: 'calc-excl', role: 'status' }, X.ex.rows + '건을 빼고 다시 계산한 결과입니다 · ');
    const reset = el('button', { type: 'button', class: 'calc-link', id: 'calc-excl-reset', text: '모두 되돌리기' });
    reset.addEventListener('click', () => { if (typeof ctx.onReset === 'function') ctx.onReset(); });
    n.append(reset);
    root.append(n);
  }
  root.append(condLine(X));
  const pick = (next) => {
    if (typeof ctx.onAxis === 'function') ctx.onAxis(next);
    view.open = {}; // 축을 바꾸면 그 축의 기본 펼침(L1 열림 · L2 닫힘)으로
    renderCalcReport(report, mountEl, { ...ctx, axis: next, preserve: false });
    const btn = doc && doc.getElementById('calc-out-' + next);
    if (btn && typeof btn.focus === 'function') btn.focus();
    const live = liveRegion(mountEl);
    if (live) live.textContent = headlineText(report, ctx, next);
  };
  root.append(axisBar(X, axis, pick));
  root.append(CARD[axis](X), tiles(X, axis), auxRow(X, axis));
  const order = BLOCK_ORDER[axis];
  const l1 = el('div', { class: 'calc-l1' }), l2 = el('div', { class: 'calc-l2' }), l3 = el('div', { class: 'calc-l3' });
  const place = (host, ids, defOpen) => {
    for (const id of ids) {
      const node = BUILD[id](X, axis);
      if (!node) continue;
      const key = 'calc-b-' + id;
      node.open = Object.prototype.hasOwnProperty.call(view.open, key) ? !!view.open[key] : defOpen;
      host.append(node);
    }
  };
  place(l1, order.l1, true);
  place(l2, order.l2, false);
  place(l3, L3, false);
  if (ctx.recent !== false && typeof ctx.renderRecent === 'function') {
    const rec = el('section', { class: 'calc-card calc-recent' });
    ctx.renderRecent(rec);
    l3.append(rec);
  }
  root.append(l1, l2, l3);
  mountEl.append(root);
  // 다시 그린 뒤 — 같은 요소로 포커스·화면 자리를 되돌린다(토글한 행이 눈앞에서 사라지지 않게).
  // 「모두 되돌리기」는 누른 뒤 사라지거나(상단 알림) 잠긴다(고정 칸) — 그대로 두면 포커스가 문서 몸통으로 떨어진다(LOW-5).
  // 고정 칸의 버튼이면 그 칸으로(자리 유지), 상단 알림의 버튼이면 비교표 제목으로(화면이 그리로 옮겨 간다).
  if (anchorId && doc) {
    let back = doc.getElementById(anchorId);
    let jump = false;
    if (anchorId === 'calc-ct-reset') back = doc.getElementById('calc-recalc');
    else if (anchorId === 'calc-excl-reset') { back = doc.querySelector('#calc-b-contrast > summary'); jump = true; }
    if (back && typeof back.focus === 'function') {
      back.focus({ preventScroll: !jump });
      if (!jump && anchorTop != null && typeof back.getBoundingClientRect === 'function' && typeof window !== 'undefined' && typeof window.scrollBy === 'function') {
        window.scrollBy(0, back.getBoundingClientRect().top - anchorTop);
      }
    }
  }
  if (ctx.preserve) {
    const live = liveRegion(mountEl);
    if (live) live.textContent = (X.ex.rows ? X.ex.rows + '건을 빼고 다시 계산했습니다. ' : '다시 계산했습니다. ') + headlineText(report, ctx, axis);
  }
  return mountEl;
}
