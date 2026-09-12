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

// ── 렌더 (SP-CMP-10) ────────────────────────────────────────────────────────
//
// 가짜 document 위에 노드를 쌓아 검사한다(report.test.js 와 같은 패턴). 여기서 보는 것은
// 「보기 좋은가」가 아니라 **말이 참인가**다: 0 이 「등록 없음」으로 나가는가 · 한쪽에만 있는
// 행이 남아 있는가 · 「우세」 어휘가 새지 않는가 · 데이터 문자열이 이스케이프되는가.

const { mountBenefits, buildViewModel, VERDICT_TEXT, WS_YES, WS_UNKNOWN } = await import('./benefits.js');

const NOW = Date.parse('2026-09-12T00:00:00Z');

function company(nm, eng, benefits, ws = null) {
  return { comp_id: eng.length, comp_nm: nm, comp_eng_nm: eng, benefits, work_style_val: ws };
}

/** NAVER·카카오 실측을 줄인 쌍 — 한쪽 0·양쪽 0·동값·금액 맞대결이 한 화면에 다 들어 있다. */
function stateFor() {
  const A = company('NAVER', 'naver', [
    ben('stock', { nm: '전 직원 주식 부여', cat: 'compensation', amt: 1000, src: 'stated' }),
    ben('flex', { nm: '자율 근무', cat: 'flexibility', desc: 'Type_O/R 선택' }),
    ben('checkup', { nm: '종합건강검진', cat: 'health', amt: 100, src: 'estimated' }),
    ben('meal', { nm: '사내식당', cat: 'perks', amt: 432, src: 'estimated' }),
  ], { remote: true, flex: false, overtime: null });
  const B = company('카카오 & 친구들', 'kakao', [
    ben('flex', { nm: '자율 출퇴근제', cat: 'flexibility', desc: '<b>자율</b>' }),
    ben('checkup', { nm: '종합건강검진', cat: 'health', amt: 100, src: 'estimated' }),
    ben('meal', { nm: '식대 지원', cat: 'perks', amt: 240, src: 'estimated' }),
    ben('point', { nm: '복지포인트', cat: 'perks', amt: 140, src: 'stated' }),
  ], {});
  return {
    REF: { companies: [A, B] },
    matched: { a: A, b: B },
    benS: { a: A.benefits, b: B.benefits },
  };
}

function mount(state = stateFor()) {
  const root = new FakeElement('div');
  const calls = [];
  const vm = mountBenefits(state, { mountEl: root, now: NOW, go: (v) => calls.push(v) });
  return { root, vm, calls, text: root.allText() };
}

describe('SP-CMP mountBenefits — 섹션 7개', () => {
  test('일곱 섹션이 정해진 순서로 나온다', () => {
    const { root } = mount();
    const titles = root.findAll((n) => n.tagName === 'h3').map((n) => n.textContent);
    assert.deepEqual(titles, [
      '한눈 요약', '카테고리별', '금액 맞대결', '항목 대조표', '근무형태',
      '이 비교를 얼마나 믿을 수 있나', '다음 행동',
    ]);
  });

  test('첫 헤딩은 h3 다 — 뷰의 h2 「복지 비교」에 포커스가 가야 한다', () => {
    const { root } = mount();
    assert.equal(root.findAll((n) => n.tagName === 'h2').length, 0);
  });

  test('두 슬롯이 다 차지 않으면 그리지 않는다 — 반쪽 비교는 비교가 아니다', () => {
    const s = stateFor();
    s.matched.b = null;
    const root = new FakeElement('div');
    root.append(new FakeElement('p'));
    assert.equal(mountBenefits(s, { mountEl: root, now: NOW }), null);
    assert.deepEqual(root.children, []);
  });

  test('마운트할 자리가 없으면 조용히 아무것도 하지 않는다', () => {
    assert.equal(mountBenefits(stateFor(), { mountEl: null, doc: { getElementById: () => null } }), null);
  });
});

describe('SP-CMP-4 한눈 요약', () => {
  test('9각형이 실리고 눈금·평균이 전 회사 기준이다', () => {
    const { root, vm } = mount();
    const fig = root.find((n) => n.className === 'cmp-rdwrap');
    assert.ok(fig.innerHTML.includes('<svg class="rdp"'), '9각형이 없다');
    assert.ok(fig.innerHTML.includes('viewBox="0 34 416 356"'));
    assert.equal(vm.rmax, 2, '전 회사 통틀어 한 카테고리 최댓값(perks 2)');
  });

  test('회사명의 & 와 태그가 그림 안에서 이스케이프된다', () => {
    const { root } = mount();
    const fig = root.find((n) => n.className === 'cmp-rdwrap');
    assert.ok(fig.innerHTML.includes('카카오 &amp; 친구들'));
    assert.ok(!fig.innerHTML.includes('카카오 & 친구들'));
  });

  test('스탯 타일 4 — A 항목·B 항목·공통·한쪽에만', () => {
    const { root, vm } = mount();
    const tiles = root.find((n) => n.className === 'cmp-stat4');
    const nums = tiles.findAll((n) => (n.className || '').includes('cmp-stat-n')).map((n) => n.textContent);
    assert.deepEqual(nums, ['4', '4', '3', '2']);
    assert.equal(vm.counts.union, 5);
  });

  test('문장 둘이 뷰모델과 같은 값을 말한다(같은 수를 두 곳에서 세지 않는다)', () => {
    const { root, vm } = mount();
    const says = root.findAll((n) => n.className === 'cmp-say').map((n) => n.textContent);
    assert.ok(says.includes(vm.axisLine));
    assert.ok(says.includes(vm.aggregateLine));
  });
});

describe('SP-CMP-5 카테고리별 나비차트', () => {
  test('행 9개 — 카테고리 정본 순서 그대로', () => {
    const { root } = mount();
    const rows = root.findAll((n) => n.className === 'cmp-bf-row');
    assert.equal(rows.length, 9);
    assert.deepEqual(rows.map((r) => r.attributes['data-cat']), CATEGORY_ORDER);
  });

  test('막대 길이는 같은 눈금(0~rmax)에서 나온다', () => {
    const { root, vm } = mount();
    const perks = root.findAll((n) => n.className === 'cmp-bf-row')
      .find((r) => r.attributes['data-cat'] === 'perks');
    const bars = perks.findAll((n) => (n.className || '').includes('cmp-bf-bar'));
    assert.equal(bars.length, 2);
    assert.equal(bars[0].attributes.style, `width:${(1 / vm.rmax * 100).toFixed(2)}%`);
    assert.equal(bars[1].attributes.style, `width:${(2 / vm.rmax * 100).toFixed(2)}%`);
  });

  test('0 인 쪽은 막대 대신 「등록 없음」 글자이고, 평균 눈금 **바깥**에 앉는다', () => {
    const { root, vm } = mount();
    const comp = root.findAll((n) => n.className === 'cmp-bf-row')
      .find((r) => r.attributes['data-cat'] === 'compensation');
    const none = comp.find((n) => (n.className || '').includes('cmp-none') && n.textContent === NONE);
    assert.ok(none, '「등록 없음」 글자가 없다 — 길이 0 막대는 눈에 안 보인다');
    const avgPct = (vm.avgs[0] / vm.rmax * 100).toFixed(2);
    assert.equal(none.attributes.style, `left:calc(${avgPct}% + 6px)`,
      '평균 눈금과 겹치면 둘 다 못 읽는다');
    assert.equal(comp.findAll((n) => (n.className || '').includes('cmp-bf-bar')).length, 1);
  });

  test('카테고리 버튼이 패널을 열고 닫는다(aria-expanded·hidden 이 함께 움직인다)', () => {
    const { root } = mount();
    const btn = root.findAll((n) => n.className === 'cmp-bf-cat')[0];
    const panel = root.find((n) => n.attributes.id === btn.attributes['aria-controls']);
    assert.equal(btn.getAttribute('aria-expanded'), 'false');
    assert.equal(panel.hidden, true);
    btn.dispatch('click');
    assert.equal(btn.getAttribute('aria-expanded'), 'true');
    assert.equal(panel.hidden, false);
    btn.dispatch('click');
    assert.equal(panel.hidden, true);
  });

  test('「모두 펼치기」는 아홉을 한 번에 열고 라벨이 「모두 접기」로 바뀐다', () => {
    const { root } = mount();
    const all = root.find((n) => (n.className || '').includes('cmp-bf-all'));
    const panels = root.findAll((n) => n.className === 'cmp-bf-panel');
    all.dispatch('click');
    assert.deepEqual(panels.map((p) => p.hidden), Array(9).fill(false));
    assert.equal(all.textContent, '모두 접기');
    all.dispatch('click');
    assert.deepEqual(panels.map((p) => p.hidden), Array(9).fill(true));
    assert.equal(all.textContent, '모두 펼치기');
  });

  test('패널 머리는 0 일 때 「등록 없음」이라 적는다(「0항목」이 아니다)', () => {
    const { root } = mount();
    const panel = root.find((n) => n.attributes.id === 'cmp-bf-p-compensation');
    const heads = panel.findAll((n) => n.tagName === 'h4').map((n) => n.allText().trim());
    assert.ok(heads[0].includes('NAVER · 보상 1항목'));
    assert.ok(heads[1].includes(`보상 ${NONE}`));
    assert.ok(!panel.allText().includes('0항목'));
  });

  test('금액 없는 항목에는 「정성」 표식이 붙는다(금액 출처 칩이 아니다)', () => {
    const { root } = mount();
    const panel = root.find((n) => n.attributes.id === 'cmp-bf-p-flexibility');
    assert.equal(panel.findAll((n) => n.className === 'cmp-qual').length, 2);
    assert.equal(panel.findAll((n) => (n.className || '').includes('cmp-chip')).length, 0);
  });
});

describe('SP-CMP-6 금액 맞대결 · 항목 대조표', () => {
  test('양쪽 금액이 있는 공통 코드만 오르고, 판정 문구가 정해져 있다', () => {
    const { root, vm } = mount();
    const sec = root.find((n) => (n.className || '').includes('cmp-duels'));
    const body = sec.findAll((n) => n.tagName === 'tbody')[0];
    assert.equal(body.children.length, 2, 'checkup(같음) · meal(차이) 둘');
    const texts = body.children.map((tr) => tr.allText());
    assert.ok(texts.some((t) => t.includes(VERDICT_TEXT.same)));
    assert.ok(texts.some((t) => t.includes('NAVER 가 큼')), vm.duels.map((d) => d.verdict).join(','));
  });

  test('맞대결 0건이면 표 대신 문장 하나 — 빈 표를 그리지 않는다', () => {
    const s = stateFor();
    s.matched.a = company('가', 'ga', [ben('q1', { nm: '정성1' })]);
    s.matched.b = company('나', 'na', [ben('q1', { nm: '정성1' })]);
    s.benS = { a: s.matched.a.benefits, b: s.matched.b.benefits };
    s.REF.companies = [s.matched.a, s.matched.b];
    const { root } = mount(s);
    const sec = root.find((n) => (n.className || '').includes('cmp-duels'));
    assert.equal(sec.findAll((n) => n.tagName === 'table').length, 0);
    assert.ok(sec.allText().includes('맞댈 수 있는 숫자가 없습니다'));
  });

  test('대조표는 합집합이고 한쪽 셀은 「등록 없음」이다 — 행을 숨기지 않는다', () => {
    const { root, vm } = mount();
    const sec = root.find((n) => (n.className || '').includes('cmp-matrix'));
    const body = sec.findAll((n) => n.tagName === 'tbody')[0];
    assert.equal(body.children.length, vm.counts.union);
    assert.ok(sec.allText().includes(NONE), '한쪽에만 있는 행의 빈 칸이 비어 있다');
  });

  test('정성 행의 값은 설명 원문이고, 그 원문이 태그로 새지 않는다', () => {
    const { root } = mount();
    const sec = root.find((n) => (n.className || '').includes('cmp-matrix'));
    const cell = sec.find((n) => n.textContent === '<b>자율</b>');
    assert.ok(cell, '설명 원문이 textContent 로 들어가야 한다(el() 만 쓴다)');
  });

  test('범례가 「등록 없음」의 뜻을 못 박는다 — 이 한 줄이 화면의 전제다', () => {
    const { root } = mount();
    const legends = root.findAll((n) => n.className === 'cmp-legend').map((n) => n.textContent);
    assert.ok(legends.some((t) => t.includes(NONE_LEGEND)));
  });
});

describe('SP-CMP-3 근무형태 — true 만 사실', () => {
  test('false·null 은 「표기 없음」이고 「없음」이라고 쓰지 않는다', () => {
    const { root } = mount();
    const sec = root.find((n) => (n.className || '').includes('cmp-ws'));
    const body = sec.findAll((n) => n.tagName === 'tbody')[0];
    assert.equal(body.children.length, 5);
    const first = body.children[0].allText();
    assert.ok(first.includes(WS_YES), '재택근무 true 가 「제공」으로 안 나온다');
    assert.equal(sec.findAll((n) => n.textContent === WS_UNKNOWN).length, 9);
    assert.ok(!sec.allText().includes('미제공'));
  });
});

describe('SP-CMP 다음 행동 · 광고 없음', () => {
  test('「이직 계산기 →」가 입력 뷰로 간다', () => {
    const { root, calls } = mount();
    const btn = root.find((n) => n.textContent === '이직 계산기 →');
    btn.dispatch('click');
    assert.deepEqual(calls, ['input']);
  });

  test('회사 상세·복지검색으로 나가는 링크가 있다', () => {
    const { root } = mount();
    const hrefs = root.findAll((n) => n.attributes.href).map((n) => n.attributes.href);
    assert.ok(hrefs.includes('/company/naver'));
    assert.ok(hrefs.includes('/company/kakao'));
    assert.ok(hrefs.includes('/find'));
  });

  // 주석에는 「mountAds 를 부르지 않는다」 같은 설명이 있어야 하므로 **코드만** 남겨 검사한다
  // (calc.test.js 의 CALC_CODE_ONLY 와 같은 방식 — 설명 문장이 금지어로 오탐되면 주석을 못 쓴다).
  const SRC_CODE_ONLY = readFileSync(new URL('./benefits.js', import.meta.url), 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*$/gm, '');

  test('광고 자리를 만들지 않는다 — 모드 A 는 마운트 호출 자체가 없다', () => {
    const { root } = mount();
    assert.equal(root.findAll((n) => n.attributes['data-ad-position']).length, 0);
    assert.ok(!SRC_CODE_ONLY.includes('mountAds'), 'benefits.js 가 광고를 부른다');
  });

  test('금지 호출이 코드에 없다(D-6) — 부르기 쉬운 자리에 있는 것들이다', () => {
    for (const banned of ['benTotal', 'renderBenefitHeadline', 'badgeKind', 'badgeClassBem']) {
      assert.ok(!SRC_CODE_ONLY.includes(banned), `${banned} 를 부르면 안 된다`);
    }
  });

  test('화면에 우열 어휘가 없다 — 항목 수도 금액 합도 순위가 되지 않는다', () => {
    const text = mount().root.allText();
    for (const banned of ['우세', '더 낫다', '순위', '합계']) {
      assert.ok(!text.includes(banned), `화면에 「${banned}」가 나왔다`);
    }
    // 「총액」이 나오는 곳은 딱 하나 — **만들지 않는다는 선언**이다.
    const totals = text.split('총액').length - 1;
    assert.equal(totals, 1);
    assert.ok(text.includes('총액 판정은 만들지 않습니다'));
  });
});

// ── CSS 계약 (UT-CMP-CSS) ───────────────────────────────────────────────────
//
// find 쪽에서 배운 것 그대로다: **접힘의 실체는 CSS 다.** 컨트롤러는 class 를 토글할 뿐이고
// 「접히면 작아진다」를 만드는 것은 스타일이라, 규칙이 통째로 없어도 가짜 window 테스트는 전부
// 초록으로 남는다(2026-09-06 에 실제로 그 상태가 잡혔다). 여기서 파일을 직접 읽어 지킨다.

const CSS = readFileSync(new URL('../css/styles.css', import.meta.url), 'utf8');
const CSS_DESKTOP = CSS.slice(CSS.indexOf('@media (min-width: 768px)'));

describe('UT-CMP-CSS — 덱·색 계약', () => {
  test('접힌 덱은 본체를 숨기고 한 줄을 보인다(없으면 한 줄이 덧붙어 더 커진다)', () => {
    const squashed = CSS_DESKTOP.replace(/\s+/g, ' ');
    assert.match(squashed, /\.cmp-deckwrap\.collapsed:not\(\.open\) \.cmp-deck \{[^}]*display:none/);
    assert.match(squashed, /\.cmp-deckwrap\.collapsed:not\(\.open\) \.cmp-minibar \{[^}]*display:flex/);
    assert.match(squashed, /\.cmp-deckwrap\.collapsed\.open \.cmp-minibar \{[^}]*display:none/);
  });

  test('덱은 사이트 헤더 아래에 붙는다 — top:0 이면 한 줄이 헤더에 가린다', () => {
    assert.match(CSS_DESKTOP, /\.cmp-deckwrap \{[^}]*top:var\(--header-h\)/);
    assert.ok(!/\.cmp-deckwrap \{[^}]*top:0/.test(CSS_DESKTOP), 'top:0 이 남아 있다');
  });

  test('접힘 규칙은 768 블록 안에만 있다 — 좁은 화면에는 접힘이 없다', () => {
    const before = CSS.slice(0, CSS.indexOf('@media (min-width: 768px)'));
    assert.ok(!before.includes('.cmp-deckwrap.collapsed'), '모바일 기본형에 접힘 규칙이 새어 들어갔다');
  });

  test('find 절을 재사용하지 않고 복제했다 — 합치면 find 계약 테스트 5개가 깨진다', () => {
    assert.ok(CSS_DESKTOP.includes('.find-deckwrap.collapsed:not(.open) .find-deck'), 'find 규칙이 사라졌다');
    assert.ok(!CSS.includes('.find-deckwrap, .cmp-deckwrap'), '두 절을 합쳤다');
    assert.ok(!CSS.includes('.cmp-deckwrap, .find-deckwrap'), '두 절을 합쳤다');
  });

  test('슬롯 B 파랑은 **토큰**이다 — 컴포넌트 규칙에 색 리터럴을 두지 않는다', () => {
    assert.match(CSS, /--slot-b:#2a78d6/);
    assert.match(CSS, /--slot-b-fill:rgb\(42 120 214 \/ \.14\)/);
    assert.match(CSS, /\.rdp-b \{[^}]*fill:var\(--slot-b-fill\)/);
    assert.match(CSS, /\.rdp-b \{[^}]*stroke:var\(--slot-b\)/);
    assert.match(CSS, /\.cmp-bf-bar-b \{[^}]*background:var\(--slot-b\)/);
  });

  test('회사 상세 레이더도 포커스로 라벨이 뜬다(호버 전용은 키보드를 배제한다)', () => {
    assert.match(CSS.replace(/\s+/g, ' '), /\.rd-hit:focus \.rd-hv \{[^}]*display:block/);
  });

  test('겹침 채움은 각 14% 다 — 겹친 곳이 저절로 26% 로 진해진다', () => {
    assert.match(CSS, /--slot-a-fill:rgb\(47 125 67 \/ \.14\)/);
    assert.match(CSS, /--radar-fill:rgb\(47 125 67 \/ \.18\)/, '단일 레이더는 18% 그대로여야 한다');
  });
});
