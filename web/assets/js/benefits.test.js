// web/assets/js/benefits.test.js — 모드 A 「복지 비교」 (SPEC 19 SP-CMP-10).
//
// 이 화면의 버그는 「죽는다」가 아니라 「조용히 거짓말한다」 쪽이라, 테스트도 그쪽을 겨눈다:
// 0 이 「등록 없음」으로 나가는가 · 눈금 기준이 정적 페이지와 같은 셈인가 · 한쪽에만 있는 행이
// 숨지 않는가 · 「우세」 어휘가 새지 않는가.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

// 순수 계산만 부르는 동안에도 모듈 최상위 side-effect(find.js 의 자동 초기화)를 만나지 않도록
// 최소 document 를 세워 둔다. 렌더 테스트는 아래에서 같은 스텁 위에 노드를 쌓는다.
class FakeElement {
  constructor(tag) {
    this.tagName = tag;
    this.attributes = {};
    this.className = '';
    this.textContent = '';
    this.children = [];
    this.hidden = false;
    this._listeners = {};
  }
  setAttribute(k, v) { this.attributes[k] = String(v); }
  getAttribute(k) { return this.attributes[k] ?? null; }
  removeAttribute(k) { delete this.attributes[k]; }
  append(...nodes) { this.children.push(...nodes); }
  replaceChildren(...nodes) { this.children = [...nodes]; }
  addEventListener(type, fn) { (this._listeners[type] ||= []).push(fn); }
  dispatch(type, evt = {}) { (this._listeners[type] || []).forEach((fn) => fn(evt)); }
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
globalThis.document = { createElement: (tag) => new FakeElement(tag), querySelector: () => null };
globalThis.location = { origin: 'https://loupit.example' };

const {
  categoryStats, perCategory, round2, pairRows, summaryCounts, amountDuels,
  axisSentence, aggregateSentence, trustSentence, verifiedText, workStyleRows,
  categoryItems, amountText, valueText, fmt, NONE, NONE_LEGEND, WS_KEYS,
} = await import('./benefits.js');
const { CATEGORY_ORDER } = await import('./categories.js');

const STATS = JSON.parse(readFileSync(
  new URL('../../../generator/tests/data/category_stats_cases.json', import.meta.url), 'utf8'));

// ── 픽스처 헬퍼 ─────────────────────────────────────────────────────────────
const ben = (cd, over = {}) => ({
  benefit_cd: cd,
  benefit_nm: over.nm || cd,
  benefit_ctgr_cd: over.cat || 'perks',
  benefit_amt: over.amt ?? null,
  qual_yn: over.amt == null,
  qual_desc_ctnt: over.desc || null,
  amt_source: over.src || (over.amt == null ? 'none' : 'estimated'),
  // `?? 기본값` 으로 쓰면 `verified: null`(확인일 없음)을 표현할 길이 없다 — 키 유무로 가른다.
  verified_dtm: 'verified' in over ? over.verified : '2026-04-15T00:00:00',
  expires_dtm: over.expires || null,
});

// ── 눈금 기준: 정적 페이지와 같은 셈인가 ────────────────────────────────────

describe('SP-CMP-4 categoryStats — corpus.build 와 같은 셈', () => {
  test('픽스처가 세 케이스를 싣고 있다', () => {
    assert.deepEqual(STATS.cases.map((c) => c.name),
      ['mixed_three', 'eight_companies_quarter_avg', 'empty_bundle']);
    assert.deepEqual(STATS.category_order, CATEGORY_ORDER);
  });

  for (const c of STATS.cases) {
    test(`${c.name}: 평균·축 최댓값·회사 수가 파이썬과 같다 — ${c.why}`, () => {
      const got = categoryStats(c.companies, CATEGORY_ORDER);
      assert.equal(got.total, c.total, '회사 수');
      assert.equal(got.rmax, c.rmax, '축 최댓값');
      assert.deepEqual(got.avgs, c.avgs, '카테고리별 평균');
    });
  }

  test('round2 는 파이썬 round(x, 2) 처럼 정확한 동점에서 짝수 쪽으로 간다', () => {
    assert.equal(round2(0.125), 0.12);
    assert.equal(Math.round(0.125 * 100) / 100, 0.13); // 왜 손으로 맞췄는지의 증거
    assert.equal(round2(0.375), 0.38);
    assert.equal(round2(1.0277777777777777), 1.03);
  });

  test('쌍마다 최댓값을 다시 잡지 않는다 — 눈금은 전 회사 기준 하나다', () => {
    const all = [
      { benefits: [ben('x', { cat: 'perks' }), ben('y', { cat: 'perks' }), ben('z', { cat: 'perks' })] },
      { benefits: [ben('w', { cat: 'health' })] },
    ];
    const stats = categoryStats(all, CATEGORY_ORDER);
    assert.equal(stats.rmax, 3, '전 회사 통틀어 한 카테고리 최댓값');
  });

  test('회사 0곳이어도 죽지 않고 rmax 는 1 이다(중심으로 무너지지 않는다)', () => {
    const s = categoryStats([], CATEGORY_ORDER);
    assert.equal(s.total, 0);
    assert.equal(s.rmax, 1);
  });

  test('정본 9종 밖 카테고리는 세지 않는다 — 없는 축을 만들지 않는다', () => {
    const per = perCategory([ben('a', { cat: 'perks' }), ben('b', { cat: '없는키' })], CATEGORY_ORDER);
    assert.equal(per.perks, 1);
    assert.equal(Object.keys(per).length, 9);
  });
});

// ── 짝짓기·집계 ─────────────────────────────────────────────────────────────

describe('SP-CMP-6 pairRows — 합집합이고 한쪽만 있는 행을 숨기지 않는다', () => {
  const A = [ben('meal', { amt: 100 }), ben('onlyA', { cat: 'health' })];
  const B = [ben('meal', { amt: 80 }), ben('onlyB', { cat: 'family' })];

  test('공통 + 한쪽에만 = 합집합 3행', () => {
    const rows = pairRows(A, B);
    assert.equal(rows.length, 3);
    const only = rows.filter((r) => !r.a || !r.b);
    assert.equal(only.length, 2, '한쪽만 있는 행이 곧 차별점이다 — 숨기면 거짓 동률');
  });

  test('체크 여부를 묻지 않는다 — 이 화면엔 체크박스가 없다', () => {
    // 모드 B 는 `checked===true` 만 센다. 그 규칙을 그대로 가져오면 여기서는 표가 통째로 빈다.
    const rows = pairRows(A.map((x) => ({ ...x, checked: false })), B);
    assert.equal(rows.length, 3);
  });

  test('summaryCounts 는 세어서 나오는 사실만 낸다', () => {
    const s = summaryCounts(pairRows(A, B));
    assert.deepEqual(
      { a: s.a, b: s.b, common: s.common, onlyOne: s.onlyOne, union: s.union },
      { a: 2, b: 2, common: 1, onlyOne: 2, union: 3 },
    );
  });
});

describe('SP-CMP-6 amountDuels — 양쪽 금액이 있는 공통 코드만', () => {
  const now = Date.parse('2026-09-12T00:00:00Z');

  test('정성·한쪽 금액 행은 맞대결에 오르지 않는다', () => {
    const A = [ben('meal', { amt: 100 }), ben('gym'), ben('edu', { amt: 50 })];
    const B = [ben('meal', { amt: 100 }), ben('gym'), ben('edu')];
    const duels = amountDuels(pairRows(A, B), now);
    assert.deepEqual(duels.map((d) => d.key), ['meal']);
  });

  test('값이 같으면 「같음」, 밴드가 겹치면 「말할 수 없음」, 아니면 큰 쪽', () => {
    const mk = (amt, src) => [ben('x', { amt, src })];
    const one = (aAmt, aSrc, bAmt, bSrc) =>
      amountDuels(pairRows(mk(aAmt, aSrc), mk(bAmt, bSrc)), now)[0].verdict;
    assert.equal(one(100, 'stated', 100, 'stated'), 'same');
    assert.equal(one(100, 'estimated', 110, 'estimated'), 'unsure'); // ±20% 가 겹친다
    assert.equal(one(100, 'stated', 200, 'stated'), 'b');
    assert.equal(one(400, 'stated', 100, 'stated'), 'a');
  });

  test('임의 쌍의 41.8% 는 0건이다 — 빈 배열이 정상이고 터지지 않는다', () => {
    assert.deepEqual(amountDuels(pairRows([ben('q')], [ben('q')]), now), []);
    assert.deepEqual(amountDuels(null, now), []);
  });
});

// ── 문형 (SP-CMP-7) ─────────────────────────────────────────────────────────

describe('SP-CMP-7 축별 문장', () => {
  test('목업과 같은 문장을 만든다(NAVER vs 카카오 실측)', () => {
    const a = [2, 1, 0, 3, 4, 3, 2, 2, 6];
    const b = [0, 1, 0, 0, 2, 2, 2, 2, 7];
    assert.equal(
      axisSentence(a, b, 'NAVER', '카카오'),
      '9개 카테고리 중 NAVER 쪽 항목이 더 많은 곳은 4개(보상·휴가·건강·가족), '
      + '카카오 쪽이 더 많은 곳은 1개(복리후생), 같은 곳은 4개입니다. '
      + '근무환경은 두 회사 모두 등록 없음입니다.',
    );
  });

  test('n 이 0 인 절은 통째로 빠진다', () => {
    const s = axisSentence([1, 1, 1], [0, 0, 0], 'A', 'B', ['compensation', 'flexibility', 'work_env']);
    assert.ok(s.includes('A 쪽 항목이 더 많은 곳은 3개'));
    assert.ok(!s.includes('B 쪽이 더 많은 곳은'), '0 개 절이 남았다');
    assert.ok(!s.includes('같은 곳은'), '0 개 절이 남았다');
  });

  test('0 대 0 은 「같다」로만 적지 않는다 — 둘 다 빈칸이라고 말한다', () => {
    const s = axisSentence([0, 0, 0], [0, 0, 0], 'A', 'B', ['compensation', 'flexibility', 'work_env']);
    assert.ok(s.includes('두 회사 모두 등록 없음'));
  });

  test('「더 낫다」·「우세」 어휘가 없다 — 항목 수는 질이 아니다', () => {
    const s = axisSentence([8, 8, 8], [0, 0, 0], 'A', 'B', ['compensation', 'flexibility', 'work_env']);
    for (const banned of ['우세', '더 낫다', '승', '점수']) assert.ok(!s.includes(banned), banned);
  });
});

describe('SP-CMP-7 집계 문장', () => {
  const now = Date.parse('2026-09-12T00:00:00Z');

  test('공통·합집합·한쪽에만·금액 맞대결 수를 말한다', () => {
    const A = [ben('meal', { amt: 400, src: 'stated' }), ben('onlyA')];
    const B = [ben('meal', { amt: 100, src: 'stated' }), ben('onlyB'), ben('onlyB2')];
    const rows = pairRows(A, B);
    const s = aggregateSentence(summaryCounts(rows), amountDuels(rows, now), 'A사', 'B사');
    assert.ok(s.startsWith('두 회사에 공통으로 등록된 복지는 1개이고, 합쳐서 4개 항목이 등록돼 있습니다.'));
    assert.ok(s.includes('A사 쪽에 1개, B사 쪽에 2개가 더 등록돼 있습니다.'));
    assert.ok(s.includes('금액이 양쪽 모두 적힌 항목은 1개입니다.'));
    assert.ok(s.includes('A사 쪽이 큰 항목은 1개입니다.'));
  });

  test('맞대결 0건이면 그렇게 말한다(표 대신 문장 하나)', () => {
    const rows = pairRows([ben('q')], [ben('q')]);
    const s = aggregateSentence(summaryCounts(rows), [], 'A사', 'B사');
    assert.ok(s.includes('금액이 양쪽 모두 적힌 항목은 없습니다.'));
  });

  test('총액·순위 어휘가 없다(D-6)', () => {
    const A = [ben('meal', { amt: 400, src: 'stated' })];
    const B = [ben('meal', { amt: 100, src: 'stated' })];
    const rows = pairRows(A, B);
    const s = aggregateSentence(summaryCounts(rows), amountDuels(rows, now), 'A사', 'B사');
    for (const banned of ['총액', '합계', '우세', '더 낫다', '순위']) assert.ok(!s.includes(banned), banned);
  });
});

describe('SP-CMP-7 신뢰도 문장', () => {
  test('수를 전부 세어서 말한다 — 「대부분」 같은 말을 쓰지 않는다', () => {
    const items = [
      ben('a', { amt: 100, src: 'stated' }),
      ben('b', { amt: 50, src: 'estimated' }),
      ben('c'),
    ];
    assert.equal(
      trustSentence(items, 'NAVER'),
      'NAVER 의 3개 항목은 회사 공식 페이지에서 수집했고 2026년 4월 15일에 확인했습니다. '
      + '금액이 적힌 항목은 2개이며 그중 공식 수치는 1개, 추정치는 1개입니다.',
    );
  });

  test('확인 날짜가 없으면 그 절만 빠진다(없는 날짜를 지어내지 않는다)', () => {
    const s = trustSentence([ben('a', { verified: null })], 'A사');
    assert.ok(!s.includes('확인했습니다'));
    assert.ok(s.includes('금액이 적힌 항목은 없습니다.'));
  });

  test('여러 날짜가 섞이면 가장 최근 확인일을 쓴다', () => {
    assert.equal(verifiedText([
      ben('a', { verified: '2026-01-02T00:00:00' }),
      ben('b', { verified: '2026-08-30T00:00:00' }),
    ]), '2026년 8월 30일');
  });
});

// ── 근무형태·값 표기 ────────────────────────────────────────────────────────

describe('SP-CMP-3 근무형태 — true 만 사실이다', () => {
  test('false·null·undefined 는 전부 「표기 없음」 쪽이다', () => {
    const rows = workStyleRows({ remote: true, flex: false, overtime: null }, {});
    assert.deepEqual(rows.map((r) => [r.key, r.a, r.b]), [
      ['remote', true, false],
      ['flex', false, false],
      ['unlimitedPTO', false, false],
      ['refreshLeave', false, false],
      ['overtime', false, false],
    ]);
    assert.deepEqual(rows.map((r) => r.key), WS_KEYS);
  });
});

describe('SP-CMP-3 값 표기', () => {
  test('0 은 어디서나 「등록 없음」이다', () => {
    assert.equal(fmt(0), NONE);
    assert.equal(valueText(null), NONE);
  });

  test('금액은 만원 단위로 자릿수를 끊는다', () => {
    assert.equal(amountText(ben('x', { amt: 1000 })), '1,000만원');
    assert.equal(amountText(ben('q')), null, '정성 항목에는 금액이 없다');
  });

  test('정성 행의 값은 설명 원문이다(없으면 항목명)', () => {
    assert.equal(valueText(ben('x', { desc: '2년 근속 시 15일' })), '2년 근속 시 15일');
    assert.equal(valueText(ben('x', { nm: '자율 근무' })), '자율 근무');
  });

  test('범례 문구가 고정돼 있다 — 이 한 줄이 화면 전체의 전제다', () => {
    assert.equal(NONE_LEGEND, '‘등록 없음’은 이 사이트에 등록되지 않았다는 뜻이며, 제도가 없다는 확인이 아닙니다.');
  });

  test('카테고리 목록은 코드로 짝짓지 않는다 — 그 회사가 등록한 것만 그대로', () => {
    const items = categoryItems([ben('a', { cat: 'health' }), ben('b', { cat: 'perks' })], 'health');
    assert.deepEqual(items.map((i) => i.benefit_cd), ['a']);
  });
});
