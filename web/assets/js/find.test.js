// web/assets/js/find.test.js — 「복지로 찾기」(SP-FIND) 계약 테스트.
//
// 잡으려는 회귀 셋:
//   ① **코드 사전이 번들에서 파생된다는 사실**이 깨지는 것 — 대표 이름·별칭·카테고리·보유 수는
//      DB 컬럼이 아니라 집계다. 같은 이름을 쓰는 코드(통근버스 · 장기근속 포상)가 화면에서
//      구분되지 않으면 사용자는 같은 조건을 두 번 고른다.
//   ② URL 왕복이 항등이 아닌 것 — `/find?b=…` 는 공유·재현·테스트의 고정점이다.
//   ③ 접힘 컨트롤러의 흔들림 — 문턱 근처에서 접힘↔펼침이 반복되면 화면이 진동한다. 브라우저
//      스크롤 앵커링을 끄고 높이 변화를 손으로 보정하는 알고리즘이라, 보정이 만든 scroll 이벤트를
//      한 번 무시하는 규칙이 빠지면 즉시 무한 토글이 된다.

// dom.js 가 document 를 참조한다 — jsdom 이 뒤에서 교체하기 전의 최소 전역(directory.test.js 전례).
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import {
  CATEGORY_LABEL,
  CATEGORY_ORDER,
  LABEL_OVERRIDE,
  amountKind,
  amountOf,
  benefitsByCode,
  buildParams,
  codesByCategory,
  defaultState,
  deriveCodes,
  matchCompanies,
  normalizeText,
  parseParams,
  sortRows,
  suggest,
} from './find.js';

// ── 픽스처: 회사 5곳 ─────────────────────────────────────────────────────────
// 실데이터의 함정을 그대로 담았다: 같은 대표 이름을 쓰는 코드 2쌍 · 회사마다 카테고리가 다른 코드 ·
// 금액 있는 항목과 정성 항목의 혼재 · `&`/`<` 가 든 회사명(삼성E&A 실재).

const ben = (cd, nm, amt, ctgr, extra = {}) => ({
  benefit_cd: cd,
  benefit_nm: nm,
  benefit_amt: amt,
  benefit_ctgr_cd: ctgr,
  qual_yn: amt == null,
  amt_source: amt == null ? 'none' : (extra.stated ? 'stated' : 'estimated'),
  qual_desc_ctnt: extra.desc ?? null,
  badge_cd: 'official',
  ...extra,
});

const REF = {
  company_types: [
    { comp_tp_cd: 'large', comp_tp_nm: '대기업' },
    { comp_tp_cd: 'mid', comp_tp_nm: '중견기업' },
  ],
  benefit_presets: {},
  companies: [
    {
      comp_id: 1, comp_eng_nm: 'samsung_elec', comp_nm: '삼성전자', comp_tp_cd: 'large',
      industry_nm: '반도체', logo_nm: 'S', aliases: ['삼성전자', '삼성', 'Samsung'],
      benefits: [
        ben('meal', '식대 지원', 240, 'perks', { stated: true }),
        ben('welfare_point', '복지포인트', 150, 'perks'),
        ben('flex_work', '선택적 근로시간제', null, 'flexibility'),
        ben('commute_subsidy', '통근버스', null, 'perks'),
      ],
    },
    {
      comp_id: 2, comp_eng_nm: 'naver', comp_nm: '네이버', comp_tp_cd: 'large',
      industry_nm: 'IT/포털', logo_nm: 'N', aliases: ['네이버', 'NAVER'],
      benefits: [
        ben('meal', '식사 제공', 300, 'perks'),
        ben('welfare_point', '복지포인트', 200, 'perks', { stated: true }),
        ben('flex_work', '주 4.5일제', null, 'flexibility'),
        ben('transport', '통근버스', 100, 'perks'),
        ben('holiday_gift', '명절 선물', 30, 'family'),
      ],
    },
    {
      comp_id: 3, comp_eng_nm: 'samsung_ena', comp_nm: '삼성E&A', comp_tp_cd: 'large',
      industry_nm: '건설', logo_nm: 'S', aliases: ['삼성E&A', '삼성엔지니어링'],
      benefits: [
        ben('meal', '식대', null, 'perks'),
        ben('welfare_point', '복지포인트', 120, 'perks'),
        ben('long_service_leave', '장기근속 포상', null, 'time_off'),
      ],
    },
    {
      comp_id: 4, comp_eng_nm: 'kakao', comp_nm: '카카오', comp_tp_cd: 'mid',
      industry_nm: 'IT/포털', logo_nm: 'K', aliases: ['카카오', 'Kakao'],
      benefits: [
        ben('welfare_point', '복지포인트', 150, 'perks'),
        ben('long_service_bonus', '장기근속 포상', 100, 'compensation'),
        ben('holiday_gift', '명절 선물', 20, 'compensation'),
      ],
    },
    {
      comp_id: 5, comp_eng_nm: 'lg_chem', comp_nm: '<b>엘지화학</b>', comp_tp_cd: 'mid',
      industry_nm: '화학', logo_nm: 'L', aliases: ['LG화학'],
      benefits: [ben('meal', '식대 지원', 180, 'perks')],
    },
  ],
};

// ── deriveCodes ──────────────────────────────────────────────────────────────

describe('deriveCodes — 번들에서 코드 사전을 만든다', () => {
  const codes = deriveCodes(REF);

  test('보유 회사 수는 행이 아니라 회사를 센다', () => {
    assert.equal(codes.meal.count, 4);
    assert.equal(codes.welfare_point.count, 4);
    assert.equal(codes.holiday_gift.count, 2);
    assert.equal(codes.long_service_bonus.count, 1);
  });

  test('대표 이름 = 최빈 benefit_nm, 별칭은 빈도순 전량', () => {
    assert.equal(codes.meal.baseLabel, '식대 지원'); // 2회(삼성·엘지) > 식사 제공·식대 각 1
    assert.deepEqual(codes.meal.aliases, ['식대 지원', '식대', '식사 제공']);
    assert.equal(codes.flex_work.aliases.length, 2);
  });

  test('카테고리는 최빈값 — 회사마다 다르게 넣은 코드가 실제로 있다', () => {
    // holiday_gift: 네이버 family 1 · 카카오 compensation 1 → 동률은 이름순으로 결정적
    assert.ok(['family', 'compensation'].includes(codes.holiday_gift.ctgr));
    assert.equal(codes.meal.ctgr, 'perks');
    assert.equal(codes.flex_work.ctgr, 'flexibility');
  });

  test('금액 있는 회사 수(amtCount)는 정성 항목을 세지 않는다', () => {
    assert.equal(codes.meal.amtCount, 3); // 삼성E&A 는 금액 없음
    assert.equal(codes.flex_work.amtCount, 0);
  });

  test('같은 대표 이름을 쓰는 코드는 override 로 갈라진다(통근버스·장기근속)', () => {
    assert.equal(codes.transport.baseLabel, '통근버스');
    assert.equal(codes.commute_subsidy.baseLabel, '통근버스');
    assert.equal(codes.transport.label, LABEL_OVERRIDE.transport);
    assert.equal(codes.commute_subsidy.label, LABEL_OVERRIDE.commute_subsidy);
    assert.notEqual(codes.transport.label, codes.commute_subsidy.label);
    assert.equal(codes.long_service_leave.label, '장기근속 휴가');
    assert.equal(codes.long_service_bonus.label, '장기근속 포상금');
  });

  test('override 가 없는 중복은 별칭을 병기해 서로 다른 이름이 된다', () => {
    const ref = {
      companies: [
        { comp_id: 1, comp_nm: 'A', benefits: [ben('aa', '지원금', 10, 'perks'), ben('bb', '지원금', 20, 'perks')] },
        { comp_id: 2, comp_nm: 'B', benefits: [ben('bb', '지원금', 20, 'perks')] },
        { comp_id: 3, comp_nm: 'C', benefits: [ben('bb', '주택 지원금', 20, 'perks')] },
      ],
    };
    const c = deriveCodes(ref);
    assert.notEqual(c.aa.label, c.bb.label);
    assert.equal(c.bb.label, '지원금 · 주택 지원금'); // 별칭이 있으면 별칭
    assert.equal(c.aa.label, '지원금 · aa'); // 별칭이 없으면 코드 id
  });

  test('동률 대표 이름은 코드포인트 순 — 파이썬 쪽(find.py)과 같은 규칙', () => {
    // 로케일 정렬을 쓰면 동률이 갈릴 때 표(파이썬)와 칩(JS)이 다른 이름을 고른다.
    const c = deriveCodes({ companies: [
      { comp_id: 1, benefits: [ben('x', '힣나', null, 'perks')] },
      { comp_id: 2, benefits: [ben('x', '가나', null, 'perks')] },
    ] });
    assert.equal(c.x.baseLabel, '가나');
    assert.deepEqual(c.x.aliases, ['가나', '힣나']);
  });

  test('코드 없는 행은 건너뛴다(코드가 검색의 축이다)', () => {
    const c = deriveCodes({ companies: [{ comp_id: 1, benefits: [{ benefit_nm: '이름만', benefit_ctgr_cd: 'perks' }] }] });
    assert.deepEqual(Object.keys(c), []);
  });

  test('빈 번들·없는 번들에도 죽지 않는다', () => {
    assert.deepEqual(deriveCodes(null), {});
    assert.deepEqual(deriveCodes({ companies: [] }), {});
  });
});

describe('codesByCategory', () => {
  test('9 카테고리 전부 키가 있고 보유 회사 수 내림차순', () => {
    const byCat = codesByCategory(deriveCodes(REF));
    assert.deepEqual(Object.keys(byCat).slice(0, 9), CATEGORY_ORDER);
    const perks = byCat.perks.map((i) => i.count);
    assert.deepEqual(perks, [...perks].sort((a, b) => b - a));
  });
});

// 정본 드리프트 가드 — 카테고리 9종은 `generator/pages/company.py` 가 소유한다.
describe('카테고리 정본 동기화', () => {
  const py = readFileSync(new URL('../../../generator/pages/company.py', import.meta.url), 'utf8');

  test('CATEGORY_ORDER 가 company.py 와 같은 순서', () => {
    const block = py.match(/CATEGORY_ORDER = \[([\s\S]*?)\]/)[1];
    const order = [...block.matchAll(/"([a-z_]+)"/g)].map((m) => m[1]);
    assert.deepEqual(CATEGORY_ORDER, order);
  });

  test('CATEGORY_LABEL 이 company.py 와 같은 라벨', () => {
    const block = py.match(/CATEGORY_LABEL = \{([\s\S]*?)\n\}/)[1];
    const pairs = Object.fromEntries([...block.matchAll(/"([a-z_]+)":\s*"([^"]+)"/g)].map((m) => [m[1], m[2]]));
    assert.deepEqual(CATEGORY_LABEL, pairs);
  });
});

// ── URL 왕복 ─────────────────────────────────────────────────────────────────

describe('parseParams / buildParams', () => {
  test('기본 상태는 빈 쿼리 — 공유 링크에 기본값을 싣지 않는다', () => {
    assert.equal(buildParams(defaultState()), '');
    assert.deepEqual(parseParams(''), defaultState());
  });

  test('왕복이 항등이다(조건 전부)', () => {
    const st = { sel: ['meal', 'welfare_point'], mode: 'or', tp: 'large', ind: '반도체', amt: true, sort: 'amt' };
    const qs = buildParams(st);
    assert.deepEqual(parseParams(qs), st);
    assert.equal(buildParams(parseParams(qs)), qs);
  });

  test('물음표가 있어도 없어도 같게 읽는다', () => {
    assert.deepEqual(parseParams('?b=meal'), parseParams('b=meal'));
  });

  test('알 수 없는 모드·정렬은 기본값으로 떨어진다(빈 화면 금지)', () => {
    const st = parseParams('?b=meal&m=xor&sort=random');
    assert.equal(st.mode, 'and');
    assert.equal(st.sort, 'match');
    assert.deepEqual(st.sel, ['meal']);
  });

  test('중복 코드·빈 코드는 걸러진다', () => {
    assert.deepEqual(parseParams('?b=meal,,meal,welfare_point').sel, ['meal', 'welfare_point']);
  });

  test('known 을 주면 없는 코드·유형·업종을 버린다', () => {
    const known = { codes: deriveCodes(REF), types: ['large', 'mid'], industries: ['반도체'] };
    const st = parseParams('?b=meal,zzz&tp=alien&ind=우주', known);
    assert.deepEqual(st.sel, ['meal']);
    assert.equal(st.tp, '');
    assert.equal(st.ind, '');
  });

  test('한글 업종이 인코딩을 왕복한다', () => {
    const qs = buildParams({ ...defaultState(), ind: 'IT/포털' });
    assert.ok(!qs.includes('포털')); // 인코딩됨
    assert.equal(parseParams(qs).ind, 'IT/포털');
  });

  test('amt 는 1 일 때만 참', () => {
    assert.equal(parseParams('?amt=1').amt, true);
    assert.equal(parseParams('?amt=0').amt, false);
    assert.equal(parseParams('?amt=true').amt, false);
  });
});

// ── 매칭 ─────────────────────────────────────────────────────────────────────

const names = (rows) => rows.map((r) => r.company.comp_nm);

describe('matchCompanies', () => {
  test('조건이 없으면 전체 회사(첫 화면)', () => {
    assert.equal(matchCompanies(REF, [], defaultState()).length, 5);
  });

  test('AND — 고른 항목을 전부 가진 회사만', () => {
    const rows = matchCompanies(REF, ['meal', 'welfare_point'], { mode: 'and' });
    assert.deepEqual(names(rows).sort(), ['네이버', '삼성E&A', '삼성전자']);
    for (const r of rows) assert.equal(r.hits.length, 2);
  });

  test('OR — 하나라도 있으면 남는다', () => {
    const rows = matchCompanies(REF, ['transport', 'long_service_bonus'], { mode: 'or' });
    assert.deepEqual(names(rows).sort(), ['네이버', '카카오']);
  });

  test('유형·업종 필터는 조건이 없어도 걸린다', () => {
    assert.deepEqual(names(matchCompanies(REF, [], { tp: 'mid' })).sort(), ['<b>엘지화학</b>', '카카오']);
    assert.deepEqual(names(matchCompanies(REF, [], { ind: 'IT/포털' })).sort(), ['네이버', '카카오']);
    assert.deepEqual(names(matchCompanies(REF, ['welfare_point'], { tp: 'mid', ind: 'IT/포털' })), ['카카오']);
  });

  test('금액 적힌 항목만 — AND 는 고른 항목 전부에 금액이 있어야 남는다', () => {
    const plain = matchCompanies(REF, ['meal', 'welfare_point'], { mode: 'and' });
    const onlyAmt = matchCompanies(REF, ['meal', 'welfare_point'], { mode: 'and', amt: true });
    assert.equal(plain.length, 3);
    // 삼성E&A 의 식대는 금액이 없다 → 빠진다
    assert.deepEqual(names(onlyAmt).sort(), ['네이버', '삼성전자']);
  });

  test('금액 적힌 항목만 — OR 는 금액 있는 hit 가 하나라도 있으면 남는다', () => {
    const rows = matchCompanies(REF, ['meal', 'flex_work'], { mode: 'or', amt: true });
    assert.deepEqual(names(rows).sort(), ['<b>엘지화학</b>', '네이버', '삼성전자']);
  });

  test('조건이 없으면 amt 는 아무 일도 하지 않는다(hit 가 없다)', () => {
    assert.equal(matchCompanies(REF, [], { amt: true }).length, 5);
  });

  test('행에 금액 합계·전체 항목 수가 실린다', () => {
    const [naver] = matchCompanies(REF, ['meal', 'welfare_point'], { mode: 'and' })
      .filter((r) => r.company.comp_nm === '네이버');
    assert.equal(naver.amtSum, 500);
    assert.equal(naver.total, 5);
    assert.equal(naver.byCode.transport.benefit_nm, '통근버스');
  });

  test('정성 항목은 금액 0 으로 센다', () => {
    const [samsung] = matchCompanies(REF, ['flex_work'], { mode: 'and' });
    assert.equal(samsung.amtSum, 0);
  });
});

describe('amountOf / amountKind', () => {
  test('정성 항목·음수·문자열 쓰레기는 0', () => {
    assert.equal(amountOf(ben('x', 'x', null, 'perks')), 0);
    assert.equal(amountOf({ benefit_amt: -5 }), 0);
    assert.equal(amountOf({ benefit_amt: 'abc' }), 0);
    assert.equal(amountOf(null), 0);
  });

  test('출처 3값 — 금액이 없으면 언제나 qual', () => {
    assert.equal(amountKind(ben('a', 'a', 240, 'perks', { stated: true })), 'stated');
    assert.equal(amountKind(ben('a', 'a', 240, 'perks')), 'est');
    assert.equal(amountKind(ben('a', 'a', null, 'perks')), 'qual');
    // 금액을 비운 채 저장된 행은 amt_source 가 stated 여도 qual 이다(재직자 편집이 만드는 상태)
    assert.equal(amountKind({ benefit_amt: null, amt_source: 'stated', qual_yn: false }), 'qual');
  });
});

describe('benefitsByCode', () => {
  test('코드 → 행 매핑, 빈 회사·없는 회사에 안전', () => {
    assert.equal(Object.keys(benefitsByCode(REF.companies[1])).length, 5);
    assert.deepEqual(benefitsByCode(null), {});
    assert.deepEqual(benefitsByCode({ benefits: [] }), {});
  });
});

// ── 정렬 ─────────────────────────────────────────────────────────────────────

describe('sortRows', () => {
  const rows = matchCompanies(REF, ['meal', 'welfare_point'], { mode: 'or' });

  test('match — 맞는 수 → 금액합 → 항목 수 → 이름', () => {
    const sorted = sortRows(rows, 'match');
    // 엘지화학(180만원)이 카카오(150만원)보다 앞이다 — 맞는 수가 같으면 금액 합이 가른다
    assert.deepEqual(names(sorted), ['네이버', '삼성전자', '삼성E&A', '<b>엘지화학</b>', '카카오']);
  });

  test('amt — 금액 합계 큰 순', () => {
    assert.deepEqual(names(sortRows(rows, 'amt')).slice(0, 3), ['네이버', '삼성전자', '<b>엘지화학</b>']);
  });

  test('total — 전체 복지 항목 많은 순', () => {
    assert.deepEqual(names(sortRows(rows, 'total')).slice(0, 2), ['네이버', '삼성전자']);
  });

  test('name — 한국어 가나다순', () => {
    assert.deepEqual(names(sortRows(rows, 'name')), ['<b>엘지화학</b>', '네이버', '삼성전자', '삼성E&A', '카카오']);
  });

  test('원본을 건드리지 않고 모르는 키는 match 로 떨어진다', () => {
    const before = names(rows);
    const out = sortRows(rows, 'nope');
    assert.deepEqual(names(rows), before);
    assert.deepEqual(names(out), names(sortRows(rows, 'match')));
  });

  test('동률은 언제나 이름으로 끝나 순서가 흔들리지 않는다', () => {
    const tie = [
      { company: { comp_nm: '나' }, hits: [], amtSum: 0, total: 1 },
      { company: { comp_nm: '가' }, hits: [], amtSum: 0, total: 1 },
    ];
    assert.deepEqual(names(sortRows(tie, 'match')), ['가', '나']);
    assert.deepEqual(names(sortRows([...tie].reverse(), 'match')), ['가', '나']);
  });
});

// ── 검색 제안 ────────────────────────────────────────────────────────────────

describe('suggest', () => {
  const codes = deriveCodes(REF);

  test('빈 검색어는 아무것도 제안하지 않는다', () => {
    assert.deepEqual(suggest(REF, codes, ''), { codes: [], companies: [] });
    assert.deepEqual(suggest(REF, codes, '   '), { codes: [], companies: [] });
  });

  test('별칭으로 코드를 찾는다 — 「주4.5일」은 flex_work 의 별칭', () => {
    const r = suggest(REF, codes, '주 4.5일');
    assert.deepEqual(r.codes.map((i) => i.code), ['flex_work']);
  });

  test('코드 id 로도 찾는다', () => {
    assert.deepEqual(suggest(REF, codes, 'welfare_point').codes.map((i) => i.code), ['welfare_point']);
  });

  test('코드 순위는 보유 회사 수 내림차순', () => {
    const r = suggest(REF, codes, '복지');
    assert.ok(r.codes.length >= 1);
    const counts = r.codes.map((i) => i.count);
    assert.deepEqual(counts, [...counts].sort((a, b) => b - a));
  });

  test('회사는 정식명·별칭·영문 식별자로 찾고 5개까지', () => {
    // comp_eng_nm 도 색인이라 `samsung` 은 samsung_ena 도 잡는다(영문으로 찾는 사람의 기대)
    assert.deepEqual(suggest(REF, codes, 'samsung').companies.map((c) => c.comp_nm), ['삼성전자', '삼성E&A']);
    assert.deepEqual(suggest(REF, codes, '삼성').companies.map((c) => c.comp_nm), ['삼성전자', '삼성E&A']);
    assert.deepEqual(suggest(REF, codes, 'NAVER').companies.map((c) => c.comp_nm), ['네이버']);
  });

  test('코드 상한 8 · 회사 상한 5', () => {
    const many = { companies: [] };
    for (let i = 0; i < 20; i += 1) {
      many.companies.push({
        comp_id: i, comp_nm: `테스트회사${i}`, comp_eng_nm: `t${i}`, aliases: [],
        benefits: [ben(`code_${i}`, `테스트 항목 ${i}`, 10, 'perks')],
      });
    }
    const r = suggest(many, deriveCodes(many), '테스트');
    assert.equal(r.codes.length, 8);
    assert.equal(r.companies.length, 5);
  });

  test('공백·대소문자를 무시한다', () => {
    assert.equal(normalizeText(' 주 4.5일 '), '주4.5일');
    assert.deepEqual(suggest(REF, codes, 'SAMSUNG').companies.map((c) => c.comp_id), [1, 3]);
  });

  test('맞는 것이 없으면 양쪽 다 빈 배열', () => {
    assert.deepEqual(suggest(REF, codes, '없는말'), { codes: [], companies: [] });
  });
});

// ── 접힘 컨트롤러 ────────────────────────────────────────────────────────────
//
// 가짜 window 로 검사하는 이유: 이 알고리즘의 버그는 "화면이 떨린다" 라는 모양으로만 나타나고
// 그건 jsdom 이 재현하지 못한다(레이아웃이 없다). 여기서 재는 것은 좌표 산수 네 가지다 —
// 문턱 · 높이 보정 · 보정이 만든 이벤트의 무시 · 좁은 화면 해제.

import { initDeckCollapse, DESKTOP_MIN } from './find.js';

function fakeClassList() {
  const set = new Set();
  return {
    contains: (c) => set.has(c),
    add: (...cs) => cs.forEach((c) => set.add(c)),
    remove: (...cs) => cs.forEach((c) => set.delete(c)),
    toggle(c, on) {
      const next = on === undefined ? !set.has(c) : !!on;
      if (next) set.add(c); else set.delete(c);
      return next;
    },
  };
}

function fakeNode({ height = () => 0, top = () => 0 } = {}) {
  const node = {
    classList: fakeClassList(),
    hidden: false,
    attrs: {},
    handlers: {},
    setAttribute(k, v) { node.attrs[k] = String(v); },
    getAttribute(k) { return node.attrs[k] ?? null; },
    addEventListener(t, fn) { (node.handlers[t] = node.handlers[t] || []).push(fn); },
    removeEventListener(t, fn) { node.handlers[t] = (node.handlers[t] || []).filter((f) => f !== fn); },
    click() { (node.handlers.click || []).forEach((f) => f()); },
    getBoundingClientRect: () => ({ height: height(node), top: top(node) }),
  };
  return node;
}

/**
 * 덱 하나 + 가짜 window. `drive(delta, n)` 는 사람의 스크롤을 **상대 이동**으로 흉내낸다 —
 * 절대 좌표로 밀면 우리가 만든 보정이 없던 일이 돼 진동 버그가 테스트를 통과해 버린다.
 */
function deckEnv({ expandedH = 200, collapsedH = 48, openH = 220, anchorTop = 300, innerWidth = 1200 } = {}) {
  const win = {
    scrollY: 0,
    innerWidth,
    scrollByCalls: 0,
    handlers: {},
    addEventListener(t, fn) { (win.handlers[t] = win.handlers[t] || []).push(fn); },
    removeEventListener(t, fn) { win.handlers[t] = (win.handlers[t] || []).filter((f) => f !== fn); },
    requestAnimationFrame(fn) { fn(); return 1; },
    emit(t) { (win.handlers[t] || []).forEach((f) => f()); },
    scrollTo(y) { win.scrollY = Math.max(0, y); win.emit('scroll'); },
    scrollBy(_x, dy) { win.scrollByCalls += 1; win.scrollTo(win.scrollY + dy); },
  };
  const wrap = fakeNode({
    height: (n) => (n.classList.contains('collapsed') ? (n.classList.contains('open') ? openH : collapsedH) : expandedH),
  });
  const anchorEl = fakeNode({ top: () => anchorTop - win.scrollY }); // 뷰포트 기준 좌표(브라우저와 같다)
  const minibar = fakeNode();
  minibar.hidden = true; // 실제 마크업과 같다 — 한 줄은 접혔을 때만 나온다
  const expandBtn = fakeNode();
  const collapseBtn = fakeNode();
  const ctl = initDeckCollapse({ wrap, anchorEl, minibar, expandBtn, collapseBtn, win });

  const log = [];
  let last = ctl.isCollapsed();
  const record = () => { const now = ctl.isCollapsed(); if (now !== last) { log.push(now); last = now; } };
  const drive = (delta, times = 1) => { for (let i = 0; i < times; i += 1) { win.scrollTo(win.scrollY + delta); record(); } };
  return { win, wrap, minibar, expandBtn, collapseBtn, ctl, drive, log, anchorTop, expandedH, collapsedH, openH };
}

describe('initDeckCollapse', () => {
  test('요소가 없으면 아무 일도 하지 않는다(마크업이 바뀌어도 페이지는 산다)', () => {
    const ctl = initDeckCollapse({});
    assert.equal(ctl.ok, false);
    assert.equal(ctl.isCollapsed(), false);
    assert.doesNotThrow(() => { ctl.onScroll(); ctl.measure(); ctl.setCollapsed(true); ctl.setOpen(true); });
  });

  test('처음에는 펼친 상태 — 맨 위에서 한 줄이 보이면 안 된다', () => {
    const env = deckEnv();
    assert.equal(env.ctl.isCollapsed(), false);
    assert.equal(env.minibar.hidden, true); // 한 줄은 접혔을 때만 나온다
  });

  test('느린 스크롤에서 전환은 딱 한 번', () => {
    const env = deckEnv();
    env.drive(20, 40);
    assert.deepEqual(env.log, [true], '접힘 전환이 1회가 아니다');
    assert.equal(env.ctl.isCollapsed(), true);
    assert.equal(env.minibar.hidden, false);
  });

  test('문턱을 천천히 오르내려도 흔들리지 않는다(내려가며 1회, 올라오며 1회)', () => {
    const env = deckEnv();
    env.drive(6, 120); // 아래로
    env.drive(-6, 200); // 위로
    assert.deepEqual(env.log, [true, false], `전환 기록: ${JSON.stringify(env.log)}`);
    assert.equal(env.ctl.isCollapsed(), false);
  });

  test('접히는 순간 보던 내용이 제자리에 남는다(높이 차이만큼 스크롤 보정)', () => {
    const env = deckEnv();
    env.win.scrollTo(520); // 문턱(300+200+8=508) 바로 밖
    assert.equal(env.ctl.isCollapsed(), true);
    assert.equal(env.win.scrollY, 520 - (env.expandedH - env.collapsedH));
    assert.equal(env.win.scrollByCalls, 1);
  });

  test('보정이 만든 스크롤은 판정을 부르지 않는다(무시 1회)', () => {
    const env = deckEnv();
    env.win.scrollTo(520);
    const after = env.win.scrollY;
    assert.equal(env.ctl.isCollapsed(), true);
    // 보정으로 간 368 은 펼침 문턱(308)보다 아래다 — 무시가 없어도 안전해야 하고, 있으면 더 안전하다
    assert.ok(after > env.anchorTop + 8);
    assert.equal(env.win.scrollByCalls, 1, '보정이 두 번 일어났다 = 판정이 재귀했다');
  });

  test('맨 위 근처에서는 보정하지 않는다(아래 내용이 올라오는 게 자연스럽다)', () => {
    const env = deckEnv({ anchorTop: 0, expandedH: 100 });
    env.ctl.setCollapsed(true); // scrollY 0 == anchorTop → 보정 없음
    assert.equal(env.win.scrollY, 0);
    assert.equal(env.win.scrollByCalls, 0);
  });

  test('좁은 화면(<768)에서는 접히지 않는다 — CSS 의 유일한 분기와 같은 경계', () => {
    const env = deckEnv({ innerWidth: DESKTOP_MIN - 1 });
    env.drive(50, 40);
    assert.equal(env.ctl.isCollapsed(), false);
    assert.deepEqual(env.log, []);
    assert.equal(env.minibar.hidden, true);
  });

  test('접힌 채로 좁아지면 고정이 풀린다(회전·창 줄이기)', () => {
    const env = deckEnv();
    env.drive(20, 40);
    assert.equal(env.ctl.isCollapsed(), true);
    env.win.innerWidth = 480;
    env.win.emit('resize');
    assert.equal(env.ctl.isCollapsed(), false);
    assert.equal(env.minibar.hidden, true);
    assert.equal(env.expandBtn.getAttribute('aria-expanded'), 'false');
  });

  test('한 줄에서 「검색·조건 바꾸기」를 누르면 임시로 펼쳐지고, 접기로 되돌아온다', () => {
    const env = deckEnv();
    env.drive(20, 40);
    const y0 = env.win.scrollY;
    env.expandBtn.click();
    assert.equal(env.ctl.isOpen(), true);
    assert.equal(env.expandBtn.getAttribute('aria-expanded'), 'true');
    assert.equal(env.collapseBtn.hidden, false);
    assert.equal(env.win.scrollY, y0 + (env.openH - env.collapsedH));
    env.collapseBtn.click();
    assert.equal(env.ctl.isOpen(), false);
    assert.equal(env.expandBtn.getAttribute('aria-expanded'), 'false');
    assert.equal(env.collapseBtn.hidden, true);
    assert.equal(env.win.scrollY, y0);
    assert.equal(env.ctl.isCollapsed(), true, '접기는 한 줄로 돌아가는 것이지 고정 해제가 아니다');
  });

  test('펼친 상태에서 「접기」는 아무 일도 하지 않는다', () => {
    const env = deckEnv();
    env.collapseBtn.click();
    assert.equal(env.ctl.isOpen(), false);
    assert.equal(env.win.scrollByCalls, 0);
  });

  test('덱이 커지면(조건 칩이 늘면) 문턱도 따라 커진다 — measure 재호출', () => {
    let expanded = 200;
    const env = deckEnv({ expandedH: 200 });
    env.win.scrollTo(400); // 508 문턱 안 → 아직 펼침
    assert.equal(env.ctl.isCollapsed(), false);
    // 덱이 100 더 커졌다고 치고 다시 재면 문턱은 608 이 된다
    expanded = 300;
    env.wrap.getBoundingClientRect = () => ({
      height: env.wrap.classList.contains('collapsed')
        ? (env.wrap.classList.contains('open') ? env.openH : env.collapsedH) : expanded,
      top: 0,
    });
    env.ctl.measure();
    env.win.scrollTo(560);
    assert.equal(env.ctl.isCollapsed(), false, '문턱이 옛 높이에 묶여 있다');
    env.win.scrollTo(620);
    assert.equal(env.ctl.isCollapsed(), true);
  });

  test('destroy 뒤에는 스크롤에 반응하지 않는다', () => {
    const env = deckEnv();
    env.ctl.destroy();
    env.drive(50, 40);
    assert.equal(env.ctl.isCollapsed(), false);
  });
});

// ── 렌더·마운트(jsdom) ───────────────────────────────────────────────────────
//
// 픽스처 마크업을 손으로 적지 않고 **실제 템플릿에서 잘라 온다**. 도구 절(`.find-tool`)에는
// Jinja 식이 하나도 없어서 그대로 HTML 이고, 이렇게 하면 템플릿의 `data-*` 훅을 하나 지웠을 때
// 여기서 즉시 빨개진다 — 훅 이름은 템플릿과 이 모듈 사이의 계약이라 조용히 어긋나면 화면이
// 아무 말 없이 절반만 그려진다.

import { JSDOM } from 'jsdom';
import { mountFind, initFind, renderRow, renderAmount } from './find.js';

const TEMPLATE = readFileSync(new URL('../../../generator/templates/find.html', import.meta.url), 'utf8');

function toolMarkup() {
  const start = TEMPLATE.indexOf('<section class="find-tool"');
  assert.ok(start > 0, '템플릿에서 도구 절을 찾지 못했다');
  const end = TEMPLATE.indexOf('\n  </section>', start);
  assert.ok(end > start, '도구 절의 닫는 태그를 찾지 못했다');
  const html = TEMPLATE.slice(start, end + '\n  </section>'.length);
  assert.ok(!/\{\{|\{%/.test(html), '도구 절에 Jinja 식이 들어왔다 — 이 픽스처가 더 이상 실제 마크업이 아니다');
  return html;
}

function mount({ search = '', ref = REF } = {}) {
  const dom = new JSDOM(`<main>${toolMarkup()}</main>`, { url: 'https://loupit.example/find' });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  const urls = [];
  const win = {
    location: { search },
    innerWidth: 1200,
    scrollY: 0,
    addEventListener() {}, removeEventListener() {},
    requestAnimationFrame(fn) { fn(); return 1; },
    scrollBy() {},
  };
  const history = { replaceState(_s, _t, url) { urls.push(url); } };
  const root = dom.window.document.querySelector('[data-find-tool]');
  root.hidden = false;
  const app = mountFind(root, ref, { win, history });
  const q = (s) => root.querySelector(s);
  const all = (s) => [...root.querySelectorAll(s)];
  return { dom, doc: dom.window.document, root, app, urls, q, all, rows: () => all('.find-row') };
}

const rowNames = (env) => env.rows().map((r) => r.querySelector('.find-row-ttl a, .find-row-nm').textContent);

describe('mountFind — 첫 화면', () => {
  test('조건이 없으면 전체 회사가 나온다', () => {
    const env = mount();
    assert.equal(env.rows().length, 5);
    assert.equal(env.q('[data-count]').textContent, '5');
    assert.equal(env.q('[data-count-sub]').textContent, ' / 5 회사');
    assert.match(env.q('[data-desc]').textContent, /조건이 없으면 전체 회사/);
  });

  test('조건이 없는 행은 금액 큰 항목 3개를 보여준다(해시태그가 아니라 근거)', () => {
    const env = mount();
    const naver = env.rows().find((r) => r.textContent.includes('네이버'));
    const hits = [...naver.querySelectorAll('.find-hit-k')].map((n) => n.textContent);
    assert.deepEqual(hits, ['식사 제공', '복지포인트', '통근버스']); // 300 · 200 · 100
  });

  test('유형·업종 선택지는 있는 값만 — 0곳짜리 막다른 길을 만들지 않는다', () => {
    const env = mount();
    assert.deepEqual([...env.q('[data-facet-tp]').options].map((o) => o.value), ['', 'large', 'mid']);
    assert.equal([...env.q('[data-facet-ind]').options].length, 1 + 4);
  });

  test('스크롤 앵커링을 끈다 — 접힘 보정과 겹치면 화면이 두 번 움직인다', () => {
    const env = mount();
    assert.equal(env.doc.documentElement.style.overflowAnchor, 'none');
  });

  test('카테고리 탭과 칩 줄이 그려진다', () => {
    const env = mount();
    assert.ok(env.all('.find-tab').length >= 3);
    const on = env.q('.find-tab.on');
    assert.equal(on.textContent.startsWith('복리후생'), true, '기본 카테고리는 복리후생');
    assert.ok(env.all('.find-chips .find-chip').length >= 3);
  });
});

describe('mountFind — 조건 고르기', () => {
  test('칩을 누르면 걸러지고 URL 이 따라간다', () => {
    const env = mount();
    const chip = env.all('.find-chips .find-chip').find((c) => c.textContent.startsWith('복지포인트'));
    chip.dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.rows().length, 4);
    assert.equal(env.urls.at(-1), '/find?b=welfare_point');
    assert.equal(env.q('[data-sel-count]').textContent, '1개');
    assert.equal(env.all('[data-sel] .find-chip').length, 1);
  });

  test('모두 갖춘 회사 ↔ 하나라도', () => {
    const env = mount({ search: '?b=meal,long_service_leave' });
    assert.equal(env.rows().length, 1); // 삼성E&A 만 둘 다 있다
    env.q('[data-mode="or"]').dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.rows().length, 4);
    assert.equal(env.urls.at(-1), '/find?b=meal,long_service_leave&m=or');
    assert.equal(env.q('[data-mode="or"]').getAttribute('aria-pressed'), 'true');
  });

  test('맞는 회사가 없으면 빈 결과 안내가 나온다', () => {
    const env = mount({ search: '?b=transport,long_service_bonus' });
    assert.equal(env.rows().length, 0);
    assert.equal(env.q('[data-empty]').hidden, false);
  });

  test('OR 모드에서 없는 항목은 「없음」으로 남는다(왜 걸렸는지 보인다)', () => {
    const env = mount({ search: '?b=meal,transport&m=or' });
    const samsung = env.rows().find((r) => r.textContent.includes('삼성전자'));
    assert.equal(samsung.querySelectorAll('.find-hit-k.dim').length, 1);
    assert.match(samsung.textContent, /해당 항목이 없습니다/);
  });

  test('지우기는 조건·필터·정렬을 한 번에 되돌린다', () => {
    const env = mount({ search: '?b=meal&m=or&tp=mid&amt=1&sort=name' });
    env.q('[data-reset]').dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.rows().length, 5);
    assert.equal(env.urls.at(-1), '/find');
    assert.equal(env.q('[data-facet-tp]').value, '');
    assert.equal(env.q('[data-facet-amt]').checked, false);
  });

  test('URL 프리필 — 링크로 들어오면 그 조건으로 시작한다', () => {
    const env = mount({ search: '?b=welfare_point&tp=mid&sort=name' });
    assert.deepEqual(rowNames(env), ['카카오']); // 중견기업 중 복지포인트가 있는 곳
    assert.equal(env.q('[data-facet-tp]').value, 'mid');
    assert.equal(env.q('[data-sort]').value, 'name');
  });
});

describe('mountFind — 렌더 안전(이스케이프)', () => {
  test('회사명의 & 와 <b> 가 글자로 남는다', () => {
    const env = mount();
    const html = env.q('[data-list]').innerHTML;
    assert.ok(html.includes('삼성E&amp;A'), '& 가 이스케이프되지 않았다');
    assert.ok(html.includes('&lt;b&gt;엘지화학&lt;/b&gt;'), '태그가 마크업으로 새어 들어갔다');
    assert.equal(env.q('[data-list] b > b'), null, '데이터 문자열이 요소가 됐다');
    assert.ok(rowNames(env).includes('삼성E&A'));
  });

  test('renderRow 는 문서 없이도 텍스트를 그대로 보존한다', () => {
    const evil = {
      company: {
        comp_id: 9, comp_nm: '<img src=x onerror=alert(1)>&', comp_eng_nm: 'evil', comp_tp_cd: 'large',
        industry_nm: '"><script>', benefits: [],
      },
      hits: [], byCode: {}, amtSum: 0, total: 0,
    };
    const node = renderRow(evil, {});
    assert.equal(node.querySelector('.find-row-ttl a').textContent, '<img src=x onerror=alert(1)>&');
    assert.equal(node.querySelector('img'), null);
    assert.equal(node.querySelector('script'), null);
  });

  test('금액 칸은 명시와 추정을 다르게 표시한다', () => {
    const stated = renderAmount({ benefit_amt: 240, amt_source: 'stated', qual_yn: false });
    const est = renderAmount({ benefit_amt: 240, amt_source: 'estimated', qual_yn: false });
    const qual = renderAmount({ benefit_amt: null, amt_source: 'none', qual_yn: true });
    assert.match(stated.textContent, /연 240만원명시/);
    assert.match(est.textContent, /추정/);
    assert.match(qual.textContent, /금액 미기재조건형/);
    assert.ok(stated.querySelector('.find-tag-stated'));
    assert.ok(est.querySelector('.find-tag-est'));
  });
});

describe('mountFind — 결과·비교·제안', () => {
  test('회사명은 정적 상세 페이지로 간다', () => {
    const env = mount();
    for (const a of env.all('.find-row-ttl a')) {
      assert.match(a.getAttribute('href'), /^\/company\/[a-z0-9]+(-[a-z0-9]+)*$/);
    }
  });

  test('A·B 를 고르면 비교 툴 링크가 열린다(같은 회사는 못 고른다)', () => {
    const env = mount();
    const click = (row, slot) => row.querySelectorAll('.find-pick')[slot].dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    click(env.rows()[0], 0);
    assert.equal(env.q('[data-cmp]').hidden, false);
    assert.equal(env.q('[data-cmp-link]').hidden, true, '한 곳만 골랐을 때는 비교 링크를 열지 않는다');
    assert.equal(env.rows()[0].querySelectorAll('.find-pick')[1].disabled, true);
    click(env.rows()[1], 1);
    const link = env.q('[data-cmp-link]');
    assert.equal(link.hidden, false);
    assert.match(link.getAttribute('href'), /^\/\?a=[a-z_]+&b=[a-z_]+$/);
  });

  test('검색 제안 — 항목은 조건이 되고 회사는 회사 페이지로', () => {
    const env = mount();
    const input = env.q('[data-q]');
    input.value = '주4.5일';
    input.dispatchEvent(new env.dom.window.Event('input', { bubbles: true }));
    const sugg = env.q('[data-sugg]');
    assert.equal(sugg.hidden, false);
    const first = sugg.querySelector('button');
    assert.match(first.textContent, /주 4.5일제|선택적 근로시간제/);
    first.dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.urls.at(-1), '/find?b=flex_work');
    assert.equal(input.value, '');
  });

  test('맞는 것이 없으면 다른 말을 권한다(빈 상자를 열지 않는다)', () => {
    const env = mount();
    const input = env.q('[data-q]');
    input.value = '없는말입니다';
    input.dispatchEvent(new env.dom.window.Event('input', { bubbles: true }));
    assert.match(env.q('[data-sugg]').textContent, /다른 말로 찾아보세요/);
  });

  test('30개를 넘으면 「더 보기」가 나온다', () => {
    const many = { company_types: REF.company_types, benefit_presets: {}, companies: [] };
    for (let i = 0; i < 71; i += 1) {
      many.companies.push({
        comp_id: 100 + i, comp_nm: `회사${String(i).padStart(2, '0')}`, comp_eng_nm: `co_${i}`,
        comp_tp_cd: 'large', industry_nm: 'IT', aliases: [],
        benefits: [ben('meal', '식대', 100 + i, 'perks')],
      });
    }
    const env = mount({ ref: many });
    assert.equal(env.rows().length, 30);
    const more = env.q('[data-more]');
    assert.equal(more.hidden, false);
    assert.match(more.textContent, /41개 남음/);
    more.dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.rows().length, 60);
    more.dispatchEvent(new env.dom.window.Event('click', { bubbles: true }));
    assert.equal(env.rows().length, 71);
    assert.equal(env.q('[data-more]').hidden, true);
  });

  test('보유율 막대는 분모를 숨기지 않는다', () => {
    const env = mount({ search: '?b=meal' });
    const meter = env.q('.find-meter');
    assert.match(meter.textContent, /4곳 · 80%/);
    assert.equal(meter.querySelector('.find-meter-fi').getAttribute('style'), 'width:80%');
  });
});

describe('initFind — 부팅', () => {
  test('번들을 받으면 도구가 열린다', async () => {
    const dom = new JSDOM(`<main>${toolMarkup()}</main>`, { url: 'https://loupit.example/find' });
    globalThis.document = dom.window.document;
    globalThis.window = dom.window;
    const app = await initFind(dom.window.document, async () => REF);
    assert.ok(app);
    assert.equal(dom.window.document.querySelector('[data-find-tool]').hidden, false);
    assert.ok(dom.window.document.querySelectorAll('.find-row').length > 0);
  });

  test('번들을 못 받으면 도구는 닫힌 채 안내만 나온다(정적 표는 그대로)', async () => {
    const dom = new JSDOM(`<main>${toolMarkup()}<p data-find-error hidden></p></main>`, { url: 'https://loupit.example/find' });
    globalThis.document = dom.window.document;
    globalThis.window = dom.window;
    const app = await initFind(dom.window.document, async () => { throw new Error('boom'); });
    assert.equal(app, null);
    assert.equal(dom.window.document.querySelector('[data-find-tool]').hidden, true);
    assert.equal(dom.window.document.querySelector('[data-find-error]').hidden, false);
  });

  test('도구가 없는 문서에서는 아무것도 하지 않는다', async () => {
    const dom = new JSDOM('<main></main>');
    assert.equal(await initFind(dom.window.document, async () => REF), null);
  });
});

// 템플릿이 이 모듈의 훅을 모두 들고 있는지 — 한쪽만 바뀌면 화면이 조용히 절반만 그려진다.
describe('템플릿 훅 계약', () => {
  test('find.js 가 찾는 data-* 훅이 템플릿에 전부 있다', () => {
    const src = readFileSync(new URL('./find.js', import.meta.url), 'utf8');
    const used = [...src.matchAll(/\[data-([a-z-]+)[\]=]/g)].map((m) => m[1]);
    assert.ok(used.length >= 20, `훅을 못 찾았다(${used.length}개)`);
    const missing = [...new Set(used)].filter((h) => !TEMPLATE.includes(`data-${h}`));
    assert.deepEqual(missing, []);
  });
});

// ── CSS 계약(UT-FIND-CSS) ────────────────────────────────────────────────────
//
// 왜 필요한가: 접힘의 **실체는 CSS 다**. `find.js` 는 class 를 토글할 뿐이고 "접히면 작아진다"를
// 만드는 것은 스타일이다. 위의 가짜 window 테스트는 그 높이를 픽스처에 적어 두므로(collapsedH=48)
// 규칙이 통째로 없어도 13개가 초록으로 남는다 — 실제로 2026-09-06 검증에서 그 상태가 잡혔다
// (덱이 안 숨어 고정 블록이 385→447px 로 오히려 커졌다). 여기서 파일을 직접 읽어 계약을 지킨다.

const CSS = readFileSync(new URL('../css/styles.css', import.meta.url), 'utf8');
const DESKTOP_BLOCK = CSS.slice(CSS.indexOf(`@media (min-width: ${DESKTOP_MIN}px)`));

describe('UT-FIND-CSS — 접힘·고정 계약', () => {
  test('CSS 분기와 find.js 의 경계가 같은 값이다', () => {
    assert.ok(CSS.includes(`@media (min-width: ${DESKTOP_MIN}px)`), `CSS 에 ${DESKTOP_MIN}px 분기가 없다`);
    assert.ok(DESKTOP_BLOCK.length > 0);
  });

  test('접힌 덱은 본체와 요약 띠를 숨긴다 — 이 규칙이 없으면 한 줄이 덧붙어 더 커진다', () => {
    const squashed = DESKTOP_BLOCK.replace(/\s+/g, ' ');
    assert.match(squashed, /\.find-deckwrap\.collapsed:not\(\.open\) \.find-deck, ?\.find-deckwrap\.collapsed:not\(\.open\) \.find-summary \{[^}]*display:none/);
  });

  test('접힌 덱은 한 줄을 보이고, 임시로 펼치면 그 한 줄을 감춘다', () => {
    const squashed = DESKTOP_BLOCK.replace(/\s+/g, ' ');
    assert.match(squashed, /\.find-deckwrap\.collapsed:not\(\.open\) \.find-minibar \{[^}]*display:flex/);
    assert.match(squashed, /\.find-deckwrap\.collapsed\.open \.find-minibar \{[^}]*display:none/);
  });

  test('덱은 사이트 헤더 아래에 붙는다 — top:0 이면 한 줄과 되돌리기 버튼이 헤더에 가린다', () => {
    assert.match(DESKTOP_BLOCK, /\.find-deckwrap \{[^}]*top:var\(--header-h\)/);
    assert.ok(!/\.find-deckwrap \{[^}]*top:0/.test(DESKTOP_BLOCK), 'top:0 이 남아 있다');
    assert.match(CSS, /:root \{ --header-h:\d+px; \}/, '--header-h 토큰이 :root 에 없다');
  });

  test('접힘 규칙은 768 블록 안에만 있다 — 좁은 화면에는 접힘이 없다', () => {
    const beforeBreakpoint = CSS.slice(0, CSS.indexOf(`@media (min-width: ${DESKTOP_MIN}px)`));
    assert.ok(!beforeBreakpoint.includes('.find-deckwrap.collapsed'), '모바일 기본형에 접힘 규칙이 새어 들어갔다');
  });
});
