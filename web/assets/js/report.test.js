// web/assets/js/report.test.js — SP-FE-9.4 리포트 DOM 렌더 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-9.4, TASK/06-프론트엔드.md T-06.11.1~11.6.
// report.js는 calc.js를 import하지 않지만(SP-FE-1.2 규칙5), 테스트 픽스처는 실 compare()로
// 생성해 SP-ENGINE Report 실제 구조와 어긋나지 않게 한다(값 정확도는 SP-ENGINE 위임, T-ENGINE-*).
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { compare } from './calc.js';

// ── 최소 in-memory document 스텁(search.test.js와 동일 패턴) ───────────────
class FakeElement {
  constructor(tag) {
    this.tagName = tag;
    this.attributes = {};
    this.className = '';
    this.textContent = '';
    this.children = [];
    this._listeners = {};
  }
  setAttribute(k, v) { this.attributes[k] = String(v); }
  append(...nodes) { this.children.push(...nodes); }
  replaceChildren() { this.children = []; }
  addEventListener(type, fn) { (this._listeners[type] ||= []).push(fn); }
  dispatch(type, evt = {}) { (this._listeners[type] || []).forEach((fn) => fn(evt)); }
  // 재귀 텍스트 수집(단순 검증용)
  allText() {
    let out = this.textContent || '';
    for (const c of this.children) if (c && typeof c.allText === 'function') out += ' ' + c.allText();
    return out;
  }
  find(pred) {
    if (pred(this)) return this;
    for (const c of this.children) {
      if (c && typeof c.find === 'function') { const r = c.find(pred); if (r) return r; }
    }
    return null;
  }
  findAll(pred, acc = []) {
    if (pred(this)) acc.push(this);
    for (const c of this.children) if (c && typeof c.findAll === 'function') c.findAll(pred, acc);
    return acc;
  }
}
globalThis.document = { createElement(tag) { return new FakeElement(tag); } };
globalThis.location = { origin: 'https://loupit.example' };

class FakeLocalStorage {
  constructor() { this._data = new Map(); }
  getItem(key) { return this._data.has(key) ? this._data.get(key) : null; }
  setItem(key, value) { this._data.set(key, String(value)); }
  removeItem(key) { this._data.delete(key); }
  clear() { this._data.clear(); }
}
globalThis.localStorage = new FakeLocalStorage();

const {
  renderReport, renderVdCard, renderCatDelta, renderCatButterfly, renderBands,
  WARN_COPY, warnCopy, renderRecentUI, buildRecentRecord, saveRecentComparison,
  matchBenefitRows, benefitDiffSummary, renderBenefitMatrix,
  benefitTotals, renderBenefitHeadline,
} = await import('./report.js');
const { recent } = await import('./store.js');

beforeEach(() => { globalThis.localStorage.clear(); });

// ── 공용 픽스처: 실 compare() 결과 ──────────────────────────────────────────
function fixtureState(overrides = {}) {
  return {
    salStr: '5000-5000',
    selectedRate: 10,
    benS: {
      a: [{ benefit_cd: 'X1', benefit_nm: '식대', benefit_amt: 100, benefit_ctgr_cd: 'perks', checked: true, qual_yn: false, amt_source: 'stated', badge_cd: 'official', expires_dtm: null, badge_src_url_ctnt: 'https://x.co/a' }],
      b: [{ benefit_cd: 'X2', benefit_nm: '헬스비', benefit_amt: 50, benefit_ctgr_cd: 'health', checked: true, qual_yn: false, amt_source: 'estimated', badge_cd: 'est', expires_dtm: '2000-01-01T00:00:00Z', badge_src_url_ctnt: 'javascript:alert(1)' }],
    },
    wsState: { a: { ot: 'mid', wage: 'separate', remote: 'hybrid', flex: 'flexible' }, b: { ot: 'low', wage: 'inclusive', remote: null, flex: null } },
    com: { a: 30, b: 45 },
    curPri: 'wlb',
    curSacrifice: null,
    matched: { a: { comp_id: 1, comp_nm: '현재회사', comp_tp_cd: 'large', work_style_val: {} }, b: { comp_id: 2, comp_nm: '이직처회사', comp_tp_cd: 'startup', work_style_val: {} } },
    companyTypes: [
      { comp_tp_cd: 'large', growth_rate_val: 0.04, growth_label_nm: '대기업 평균 4%', stability_score_no: 90 },
      { comp_tp_cd: 'startup', growth_rate_val: 0.1, growth_label_nm: '스타트업 평균 10%', stability_score_no: 30 },
    ],
    ...overrides,
  };
}

// ── T-06.11.2: renderVdCard 판정카드·승자색·tie/limited ─────────────────────
describe('T-06.11.2 renderVdCard', () => {
  test('승자 클래스·tie 표기', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderVdCard(report.vdCard, mount, { sacrifice: report.sacrifice });
    const card = mount.children[0];
    assert.equal(card.attributes['data-axis'], 'wlb');
    const persps = card.findAll((n) => n.className && n.className.includes('vd-persp--'));
    assert.ok(persps.length >= 1);
  });

  test('limited(brand, 한쪽 미선택) → 주석 노출', () => {
    const state = fixtureState({ curPri: 'brand', matched: { a: null, b: { comp_id: 2, comp_nm: 'B', comp_tp_cd: 'startup', work_style_val: {} } } });
    const report = compare(state);
    const mount = new FakeElement('div');
    renderVdCard(report.vdCard, mount);
    assert.ok(mount.allText().includes('제한'));
  });

  test('멱등 재호출: 두 번 호출해도 카드 1개만 유지', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderVdCard(report.vdCard, mount);
    renderVdCard(report.vdCard, mount);
    assert.equal(mount.children.length, 1);
  });
});

// ── T-06.11.3: renderCatDelta 9카테고리 고정 순서 ───────────────────────────
describe('T-06.11.3 renderCatDelta', () => {
  test('9행 고정 순서·sumA/sumB/delta 셀', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderCatDelta(report.catDelta, mount);
    const table = mount.children[0];
    const tbody = table.children[1];
    assert.equal(tbody.children.length, 9);
    const order = tbody.children.map((tr) => tr.attributes['data-ctgr']);
    assert.deepEqual(order, ['compensation', 'flexibility', 'work_env', 'time_off', 'health', 'family', 'growth', 'leisure', 'perks']);
    // perks(a) 항목 확인: sumA=100
    const perksRow = tbody.children.find((tr) => tr.attributes['data-ctgr'] === 'perks');
    assert.equal(perksRow.children[1].textContent, '100');
  });
});

// ── renderCatButterfly — 버터플라이(back-to-back) 카테고리 차트(예전 loupit 이식) ──
describe('renderCatButterfly 버터플라이 차트', () => {
  test('범례 + 9행, 각 행에 A/B 막대(폭%)·중앙 라벨·차이 배지', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderCatButterfly(report.catDelta, mount);
    // [0]=범례, [1]=차트
    const legend = mount.children[0];
    assert.ok(legend.className.includes('bfly-legend'), '범례 렌더');
    const chart = mount.children[1];
    const rows = chart.findAll((n) => n.className && n.className.includes('bfly-row') === true);
    assert.equal(rows.length, 9, '9카테고리 행');
    // 고정 순서 유지
    const order = rows.map((r) => r.attributes['data-ctgr']);
    assert.deepEqual(order, ['compensation', 'flexibility', 'work_env', 'time_off', 'health', 'family', 'growth', 'leisure', 'perks']);
    // perks 행: sumA=100 값 노출 + A/B 막대(width style)·중앙 라벨 존재
    const perks = rows.find((r) => r.attributes['data-ctgr'] === 'perks');
    assert.equal(perks.children[0].textContent, '100', 'A값 노출');
    const bars = perks.findAll((n) => n.className && n.className.includes('bfly-bar'));
    assert.equal(bars.length, 2, 'A/B 막대 2개');
    assert.ok(bars.every((b) => /width:\s*[\d.]+%/.test(b.attributes.style || '')), '막대 폭% 인라인 스타일');
    const label = perks.find((n) => n.className && n.className.includes('bfly-label'));
    assert.ok(label && label.textContent.length > 0, '중앙 카테고리 라벨');
  });

  test('빈 catDelta도 무크래시(범례만, 행 0)', () => {
    const mount = new FakeElement('div');
    renderCatButterfly([], mount);
    const chart = mount.children[1];
    const rows = chart.findAll((n) => n.className && n.className.includes('bfly-row'));
    assert.equal(rows.length, 0);
  });
});

// ── T-06.11.4: renderBands 배지 라벨·만료 경고·safeUrl ──────────────────────
describe('T-06.11.4 renderBands', () => {
  test('공식/추정/만료 배지 라벨·safeUrl 링크화/위험스킴 텍스트', () => {
    const now = Date.now();
    const items = [
      { benefit_nm: '공식항목', badge_cd: 'official', expires_dtm: null, badge_src_url_ctnt: 'https://x.co/a' },
      { benefit_nm: '추정항목', badge_cd: 'est', expires_dtm: null, badge_src_url_ctnt: null },
      { benefit_nm: '만료항목', badge_cd: 'official', expires_dtm: '2000-01-01T00:00:00Z', badge_src_url_ctnt: 'javascript:alert(1)' },
    ];
    const mount = new FakeElement('div');
    renderBands({ totalRange: [100, 200] }, items, mount, now);
    const list = mount.children[0];
    assert.equal(list.children.length, 3);
    assert.equal(list.children[0].children[1].textContent, '공식');
    assert.equal(list.children[1].children[1].textContent, '추정');
    assert.equal(list.children[2].children[1].textContent, '만료');
    // safeUrl 링크: 첫 항목은 <a href=...>, 마지막은 javascript: → 비표시 텍스트
    const firstLinkNode = list.children[0].children[2];
    assert.equal(firstLinkNode.tagName, 'a');
    assert.equal(firstLinkNode.attributes.href, 'https://x.co/a');
    const lastNode = list.children[2].children[2];
    assert.equal(lastNode.tagName, 'span');
    assert.ok(lastNode.textContent.includes('비표시'));
    // 밴드 표시(계수 재계산 없이 slotResult.totalRange 그대로 표시)
    assert.ok(mount.allText().includes('100'));
    assert.ok(mount.allText().includes('200'));
  });
});

// ── T-06.11.5: 경고문구 매핑 ─────────────────────────────────────────────
describe('T-06.11.5 warnCopy', () => {
  test('코드→문구 매핑', () => {
    assert.equal(warnCopy('both_inclusive'), WARN_COPY.both_inclusive);
    assert.ok(WARN_COPY.eff_shrink.length > 0);
  });
  test('미지 코드 방어(크래시 없이 안내문 반환)', () => {
    assert.doesNotThrow(() => warnCopy('unknown_code_xyz'));
    assert.match(warnCopy('unknown_code_xyz'), /unknown_code_xyz/);
  });
});

// ── T-06.11.1: renderReport 골격·멱등 재구성·카드 순서 ──────────────────────
describe('T-06.11.1 renderReport', () => {
  test('블록 존재(판정→총보상→시간조정→워라밸→카테고리→정성→경고→최근비교)', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderReport(report, mount, { benS: fixtureState().benS, matched: fixtureState().matched });
    const classes = mount.children.map((c) => c.className);
    assert.ok(classes.some((c) => c.includes('rp-vdcard')));
    assert.ok(classes.some((c) => c.includes('rp-total')));
    assert.ok(classes.some((c) => c.includes('rp-hourly')));
    assert.ok(classes.some((c) => c.includes('rp-wlb')));
    assert.ok(classes.some((c) => c.includes('rp-catdelta')));
    assert.ok(classes.some((c) => c.includes('rp-qual')));
  });

  test('replaceChildren 멱등 재호출 — 두 번 호출해도 중복 누적 없음', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    renderReport(report, mount);
    const firstCount = mount.children.length;
    renderReport(report, mount);
    assert.equal(mount.children.length, firstCount);
  });

  test('hourly===null(근무시간 미입력) → "미산출" 표시(무효화 금지, FR-40 2a)', () => {
    const state = fixtureState({ wsState: { a: { ot: null, wage: null, remote: null, flex: null }, b: { ot: null, wage: null, remote: null, flex: null } } });
    const report = compare(state);
    const mount = new FakeElement('div');
    renderReport(report, mount);
    assert.ok(mount.allText().includes('미산출'));
  });

  test('경고 배너: warnings 있으면 rp-warnings 블록, 없으면 생략', () => {
    // both_inclusive 유도: 양측 포괄임금 + ot!=='low'
    const state = fixtureState({ wsState: { a: { ot: 'mid', wage: 'inclusive', remote: null, flex: null }, b: { ot: 'mid', wage: 'inclusive', remote: null, flex: null } } });
    const report = compare(state);
    assert.ok(report.warnings.includes('both_inclusive'));
    const mount = new FakeElement('div');
    renderReport(report, mount);
    const warnBlock = mount.children.find((c) => c.className && c.className.includes('rp-warnings'));
    assert.ok(warnBlock);
    assert.ok(warnBlock.allText().includes(WARN_COPY.both_inclusive));
  });
});

// ── T-06.11.6: 최근 비교 저장/불러오기 UI ───────────────────────────────────
describe('T-06.11.6 최근 비교 저장/불러오기 UI', () => {
  test('목록 표시·복원 클릭 콜백', () => {
    const state = fixtureState();
    const report = compare(state);
    saveRecentComparison(state, report);
    const mount = new FakeElement('div');
    let restored = null;
    renderRecentUI(mount, { onRestore: (r) => { restored = r; } });
    const items = mount.find((n) => n.className === 'rp-recent-list');
    assert.ok(items);
    assert.equal(items.children.length, 1);
    const restoreBtn = items.children[0].children.find((c) => c.className === 'rp-recent-restore');
    restoreBtn.dispatch('click');
    assert.ok(restored);
    assert.equal(restored.slots.a.comp_id, 1);
  });

  test('빈 목록이면 안내 문구', () => {
    const mount = new FakeElement('div');
    renderRecentUI(mount, { listFn: () => [] });
    assert.ok(mount.allText().includes('저장된 비교가 없습니다'));
  });

  test('buildRecentRecord: isValidRecord 통과 형태(id/savedAt string, slots/input/result 존재)', () => {
    const state = fixtureState();
    const report = compare(state);
    const rec = buildRecentRecord(state, report);
    assert.equal(typeof rec.id, 'string');
    assert.equal(typeof rec.savedAt, 'string');
    assert.ok(rec.slots && rec.input && rec.result);
  });

  test('삭제 클릭 → recent에서 제거되고 UI 재렌더', () => {
    const state = fixtureState();
    const report = compare(state);
    saveRecentComparison(state, report);
    const mount = new FakeElement('div');
    renderRecentUI(mount, {});
    const items = mount.find((n) => n.className === 'rp-recent-list');
    const removeBtn = items.children[0].children.find((c) => c.className === 'rp-recent-remove');
    removeBtn.dispatch('click');
    assert.equal(recent.list().length, 0);
  });
});

// ── 복지 항목 매트릭스(매트릭스+diff 요약 하이브리드, FR-40 개편 2026-07-15) ──
function benItem(over = {}) {
  return {
    benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 100, benefit_ctgr_cd: 'perks',
    checked: true, qual_yn: false, amt_source: 'stated', badge_cd: 'official', expires_dtm: null,
    ...over,
  };
}

describe('matchBenefitRows — 항목 정렬 매칭', () => {
  test('동일 benefit_cd → 같은 행에 a·b 정렬', () => {
    const rows = matchBenefitRows(
      [benItem({ benefit_amt: 240 })],
      [benItem({ benefit_amt: 180 })],
    );
    assert.equal(rows.length, 1);
    assert.equal(rows[0].a.benefit_amt, 240);
    assert.equal(rows[0].b.benefit_amt, 180);
    assert.equal(rows[0].nm, '식대');
  });

  test('단독 항목 → 반대편 null', () => {
    const rows = matchBenefitRows(
      [benItem({ benefit_cd: 'bus', benefit_nm: '통근버스', benefit_amt: 120 })],
      [benItem({ benefit_cd: 'edu', benefit_nm: '자기계발비', benefit_amt: 300, benefit_ctgr_cd: 'growth' })],
    );
    const bus = rows.find((r) => r.key === 'bus');
    const edu = rows.find((r) => r.key === 'edu');
    assert.ok(bus.a && bus.b === null, '통근버스는 A만');
    assert.ok(edu.b && edu.a === null, '자기계발비는 B만');
  });

  test('unchecked 항목 제외(엔진 합계와 동일 모집단)', () => {
    const rows = matchBenefitRows([benItem({ checked: false })], []);
    assert.equal(rows.length, 0);
  });

  test('카테고리 고정 순서 그룹 + 미지 카테고리 → perks', () => {
    const rows = matchBenefitRows(
      [
        benItem({ benefit_cd: 'p1', benefit_ctgr_cd: 'perks' }),
        benItem({ benefit_cd: 'c1', benefit_ctgr_cd: 'compensation' }),
        benItem({ benefit_cd: 'zz', benefit_ctgr_cd: 'unknown_cat' }),
      ],
      [],
    );
    assert.equal(rows[0].ctgr, 'compensation', 'compensation이 perks보다 먼저');
    assert.deepEqual(rows.slice(1).map((r) => r.ctgr), ['perks', 'perks'], '미지 카테고리는 perks로 정규화');
  });

  test('카테고리 내: 금액 내림차순, 정성은 마지막', () => {
    const rows = matchBenefitRows(
      [
        benItem({ benefit_cd: 'q1', benefit_nm: '수평 문화', benefit_amt: null, qual_yn: true }),
        benItem({ benefit_cd: 'small', benefit_nm: '소액', benefit_amt: 10 }),
        benItem({ benefit_cd: 'big', benefit_nm: '고액', benefit_amt: 500 }),
      ],
      [],
    );
    assert.deepEqual(rows.map((r) => r.key), ['big', 'small', 'q1']);
  });
});

describe('benefitDiffSummary — 새로 생김/사라짐 집계', () => {
  test('gained·lost 개수/합계, 정성은 count만·common 집계', () => {
    const rows = matchBenefitRows(
      [
        benItem({ benefit_cd: 'meal', benefit_amt: 240 }),                       // 공통
        benItem({ benefit_cd: 'bus', benefit_nm: '통근버스', benefit_amt: 120 }), // lost(금액)
        benItem({ benefit_cd: 'daycare', benefit_nm: '어린이집', benefit_amt: null, qual_yn: true }), // lost(정성)
      ],
      [
        benItem({ benefit_cd: 'meal', benefit_amt: 180 }),
        benItem({ benefit_cd: 'edu', benefit_nm: '자기계발비', benefit_amt: 300, benefit_ctgr_cd: 'growth' }), // gained
      ],
    );
    const s = benefitDiffSummary(rows);
    assert.deepEqual(s, { gained: { count: 1, sum: 300 }, lost: { count: 2, sum: 120 }, common: 1 });
  });
});

describe('renderBenefitMatrix — 표 렌더·마커·우세 하이라이트', () => {
  function fixtureRows() {
    return matchBenefitRows(
      [
        benItem({ benefit_cd: 'meal', benefit_amt: 240 }),
        benItem({ benefit_cd: 'bus', benefit_nm: '통근버스', benefit_amt: 120 }),
      ],
      [
        benItem({ benefit_cd: 'meal', benefit_amt: 180, badge_cd: 'est' }),
        benItem({ benefit_cd: 'edu', benefit_nm: '자기계발비', benefit_amt: 300, benefit_ctgr_cd: 'growth' }),
      ],
    );
  }

  test('헤더(회사명) + 카테고리 소계(엔진 catDelta 표기) + 차이 열 헤더', () => {
    const mount = new FakeElement('div');
    renderBenefitMatrix(fixtureRows(), mount, {
      labels: { a: '삼성전자', b: '네이버' },
      catDelta: [{ ctgr: 'perks', sumA: 360, sumB: 180, delta: -180 }, { ctgr: 'growth', sumA: 0, sumB: 300, delta: 300 }],
    });
    const text = mount.allText();
    assert.ok(text.includes('삼성전자') && text.includes('네이버'), '헤더 회사명');
    assert.ok(text.includes('360만원'), '카테고리 소계(엔진 값)');
    assert.ok(text.includes('차이'), '차이 열 헤더');
  });

  test('차이 칩: 항목별 승자 방향(A/B)·카테고리 행은 엔진 delta', () => {
    const mount = new FakeElement('div');
    renderBenefitMatrix(fixtureRows(), mount, {
      catDelta: [{ ctgr: 'perks', sumA: 360, sumB: 180, delta: -180 }, { ctgr: 'growth', sumA: 0, sumB: 300, delta: 300 }],
    });
    const chips = mount.findAll((n) => n.className && String(n.className).includes('ben-delta')).map((c) => c.textContent);
    assert.ok(chips.includes('A +60'), '식대(240 vs 180) → A +60');
    assert.ok(chips.includes('A +120'), '통근버스(A만) → A +120');
    assert.ok(chips.includes('B +300'), '자기계발비(B만) → B +300');
    assert.ok(chips.includes('A +180'), '복리후생 카테고리 행(엔진 delta -180)');
  });

  test('동일 금액 → "=" 칩', () => {
    const rows = matchBenefitRows([benItem({ benefit_amt: 60 })], [benItem({ benefit_amt: 60 })]);
    const mount = new FakeElement('div');
    renderBenefitMatrix(rows, mount, {});
    const chips = mount.findAll((n) => n.className && String(n.className).includes('ben-delta')).map((c) => c.textContent);
    assert.ok(chips.includes('='), '동일 금액 항목 행');
  });

  test('행내 미니바: 금액 셀에 폭% 인라인 바(최대 금액 = 100%)', () => {
    const mount = new FakeElement('div');
    renderBenefitMatrix(fixtureRows(), mount, {});
    const bars = mount.findAll((n) => n.className && String(n.className).includes('ben-bar'));
    assert.ok(bars.length >= 3, '금액 항목마다 바');
    const widths = bars.map((b) => b.attributes.style || '');
    assert.ok(widths.some((w) => /width:\s*100(\.0)?%/.test(w)), '최대 금액(자기계발비 300) = 100%');
    assert.ok(widths.every((w) => /width:\s*[\d.]+%/.test(w)), '전부 폭% 스타일');
  });

  test('단독 항목: 빈 셀 "—" + 사라짐/새로 생김 마커', () => {
    const mount = new FakeElement('div');
    renderBenefitMatrix(fixtureRows(), mount, {});
    const marks = mount.findAll((n) => n.className && String(n.className).includes('ben-mark'));
    const markTexts = marks.map((m) => m.textContent);
    assert.ok(markTexts.includes('사라짐'));
    assert.ok(markTexts.includes('새로 생김'));
    assert.ok(mount.findAll((n) => n.className && String(n.className).includes('ben-none')).length >= 2, '빈 셀 —');
  });

  test('만료 항목 → 만료 배지(기존 badgeLabel 재사용)', () => {
    const rows = matchBenefitRows([benItem({ expires_dtm: '2000-01-01T00:00:00Z' })], []);
    const mount = new FakeElement('div');
    renderBenefitMatrix(rows, mount, {});
    assert.ok(mount.allText().includes('만료'));
  });

  test('빈 rows → 무크래시·표 생략', () => {
    const mount = new FakeElement('div');
    assert.doesNotThrow(() => renderBenefitMatrix([], mount, {}));
    assert.equal(mount.children.length, 0);
  });
});

describe('benefitTotals·renderBenefitHeadline — 총액 헤드라인(결론 먼저)', () => {
  const CAT_DELTA = [
    { ctgr: 'perks', sumA: 360, sumB: 180, delta: -180 },
    { ctgr: 'growth', sumA: 0, sumB: 300, delta: 300 },
  ];

  test('benefitTotals: catDelta 표시용 합산(엔진 값 그대로)', () => {
    assert.deepEqual(benefitTotals(CAT_DELTA), { a: 360, b: 480, delta: 120 });
    assert.deepEqual(benefitTotals([]), { a: 0, b: 0, delta: 0 });
    assert.deepEqual(benefitTotals(null), { a: 0, b: 0, delta: 0 });
  });

  test('헤드라인: 양사 총액·판정문·분할 바 폭%·diff 요약 포함', () => {
    const rows = matchBenefitRows(
      [benItem({ benefit_cd: 'bus', benefit_nm: '통근버스', benefit_amt: 120 })],
      [benItem({ benefit_cd: 'edu', benefit_nm: '자기계발비', benefit_amt: 300, benefit_ctgr_cd: 'growth' })],
    );
    const mount = new FakeElement('div');
    renderBenefitHeadline(CAT_DELTA, rows, mount, { labels: { a: '삼성전자', b: '네이버' } });
    const text = mount.allText();
    assert.ok(text.includes('360만원') && text.includes('480만원'), '양사 총액');
    assert.ok(text.includes('네이버') && text.includes('120만원 더'), 'B 우위 판정문');
    assert.ok(text.includes('새로 생기는 복지 1개'), 'diff 요약 흡수');
    const segs = mount.findAll((n) => n.className && String(n.className).includes('ben-split-'));
    assert.equal(segs.length, 2, '분할 바 2조각');
    assert.ok(segs.every((s) => /width:\s*[\d.]+%/.test(s.attributes.style || '')), '비중 폭%');
  });

  test('총액 동일 → "비슷" 판정문', () => {
    const even = [{ ctgr: 'perks', sumA: 100, sumB: 100, delta: 0 }];
    const mount = new FakeElement('div');
    renderBenefitHeadline(even, [], mount, {});
    assert.ok(mount.allText().includes('비슷'));
  });
});

describe('renderReport — 복지 비교 섹션에 매트릭스 포함', () => {
  test('ctx.benS 전달 시 rp-catdelta 블록 안에 ben-matrix 렌더', () => {
    const state = fixtureState();
    const report = compare(state);
    const mount = new FakeElement('div');
    renderReport(report, mount, { benS: state.benS, matched: state.matched });
    const block = mount.children.find((c) => c.className && c.className.includes('rp-catdelta'));
    assert.ok(block, 'rp-catdelta 블록 존재');
    assert.ok(block.find((n) => n.className && String(n.className).includes('ben-headline')), '총액 헤드라인 존재');
    assert.ok(block.find((n) => n.className && String(n.className).includes('ben-matrix')), '매트릭스 표 존재');
    assert.equal(block.find((n) => n.className && String(n.className).includes('bfly')), null, '버터플라이 제거(세로 중복 해소)');
  });

  test('ctx 없이 호출해도 무크래시(매트릭스 생략)', () => {
    const report = compare(fixtureState());
    const mount = new FakeElement('div');
    assert.doesNotThrow(() => renderReport(report, mount));
  });
});
