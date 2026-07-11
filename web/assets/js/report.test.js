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
  renderReport, renderVdCard, renderCatDelta, renderBands,
  WARN_COPY, warnCopy, renderRecentUI, buildRecentRecord, saveRecentComparison,
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
