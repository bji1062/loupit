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
