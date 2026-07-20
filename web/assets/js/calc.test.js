// web/assets/js/calc.test.js — SP-ENGINE 단위 테스트 (T-ENGINE-1~48).
// 근거: SPEC/05-비교-계산엔진.md §17(SP-ENGINE-17), TASK/05-계산엔진.md.
// 순수 함수이므로 모킹 없이 import → assert. node:test + node:assert/strict.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import {
  // 상수
  OT_HRS, LEGAL_WEEK_HRS, AUTONOMY_LABELS, MONTHLY_STD_HRS,
  OT_MULT, WEEKS_PER_MONTH, WEEKS_PER_YEAR, WON_PER_MANWON, COMMUTE_ROUND_TRIP,
  COMMUTE_WORKDAYS, WORKDAY_HRS, BENEFIT_SAT_THRESHOLD,
  BAND_BASE, BAND_EXPIRE, BENEFIT_CATEGORIES,
  // 함수
  parseSalRange, deriveOfferRange, benTotal, benByCat, benCatCompare, qualCompare,
  effSalary, getWSHours, getOTPay, hourlyValue, autonomyPerks, commuteCompare,
  bandCoeff, sumBand, buildVdCard, sacrificeCost,
  compare, calc, restSummary,
} from './calc.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const CALC_SRC = readFileSync(join(HERE, 'calc.js'), 'utf8');
// 주석(// 라인·/* */ 블록·JSDoc) 제거 후 코드만 남긴 버전 — 설명용 주석 속 금지어
// 언급(예: "localStorage 미접근"이라는 문서화 문장)이 오탐되지 않도록 코드 토큰만 검사한다.
const CALC_CODE_ONLY = CALC_SRC
  .replace(/\/\*[\s\S]*?\*\//g, '')
  .replace(/\/\/.*$/gm, '');

// 결정성 테스트용 고정 시각(만료 판정 now 인자 주입, Date.now() 직접호출 금지)
const NOW = new Date('2026-07-11T00:00:00Z').getTime();
const PAST_EXPIRED = '2020-01-01T00:00:00Z'; // NOW보다 항상 과거

// 재사용 깊은 동결 유틸(순수성 테스트 T-45용)
function deepFreeze(obj) {
  if (obj && typeof obj === 'object' && !Object.isFrozen(obj)) {
    Object.values(obj).forEach(deepFreeze);
    Object.freeze(obj);
  }
  return obj;
}

// ── T-05.1.1: 모듈 임포트 스모크 — 전 export 심볼 존재 ──────────────────────
describe('T-05.1.1 모듈 골격·상수 스모크', () => {
  test('상수 전량 export', () => {
    assert.deepEqual(OT_HRS, { low: 40, mid: 45, high: 54 });
    assert.equal(LEGAL_WEEK_HRS, 40);
    assert.deepEqual(AUTONOMY_LABELS, { remote: '재택근무', flex: '유연근무', unlimitedPTO: '무제한휴가' });
    assert.equal(MONTHLY_STD_HRS, 209);
    assert.equal(OT_MULT, 1.5);
    assert.equal(WEEKS_PER_MONTH, 4.33);
    assert.equal(WEEKS_PER_YEAR, 52);
    assert.equal(WON_PER_MANWON, 10000);
    assert.equal(COMMUTE_ROUND_TRIP, 2);
    assert.equal(COMMUTE_WORKDAYS, 240);
    assert.equal(WORKDAY_HRS, 8);
    assert.equal(BENEFIT_SAT_THRESHOLD, 1200);
    assert.deepEqual(BAND_BASE, { stated: 0.05, estimated: 0.20, none: 0 });
    assert.equal(BAND_EXPIRE, 0.15);
    assert.deepEqual(BENEFIT_CATEGORIES, ['compensation', 'flexibility', 'work_env',
      'time_off', 'health', 'family', 'growth', 'leisure', 'perks']);
  });

  test('함수 전량 export', () => {
    for (const fn of [parseSalRange, deriveOfferRange, benTotal, benByCat, benCatCompare,
      qualCompare, effSalary, getWSHours, getOTPay, hourlyValue, autonomyPerks,
      commuteCompare, bandCoeff, sumBand, buildVdCard,
      sacrificeCost, compare, calc, restSummary]) {
      assert.equal(typeof fn, 'function');
    }
  });
});

// ── T-05.2: 연봉 Range ──────────────────────────────────────────────────
describe('T-05.2 연봉 Range', () => {
  test('T-ENGINE-1: parseSalRange("5000-7000")', () => {
    assert.deepEqual(parseSalRange('5000-7000'), { min: 5000, max: 7000, mid: 6000 });
  });

  test('T-ENGINE-2: parseSalRange 미입력/파싱불가 → {0,0,0}', () => {
    assert.deepEqual(parseSalRange(''), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange(null), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange('abc'), { min: 0, max: 0, mid: 0 });
  });

  test('L-4: parseSalRange 빈 토큰 명시 거부(Number("")===0 함정)', () => {
    // '100-'·'-100'·'-'·공백 토큰이 0으로 둔갑해 {100,0,..} 같은 오범위를 만들면 안 된다.
    assert.deepEqual(parseSalRange('100-'), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange('-100'), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange('-'), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange('5000- '), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(parseSalRange(' -7000'), { min: 0, max: 0, mid: 0 });
  });

  test('L-4: parseSalRange 역전 범위(min>max) 거부', () => {
    assert.deepEqual(parseSalRange('7000-5000'), { min: 0, max: 0, mid: 0 });
    // 경계: min==max 는 유효
    assert.deepEqual(parseSalRange('5000-5000'), { min: 5000, max: 5000, mid: 5000 });
  });

  test('L-4: parseSalRange 토큰 2개 초과 거부', () => {
    assert.deepEqual(parseSalRange('1-2-3'), { min: 0, max: 0, mid: 0 });
  });

  test('T-ENGINE-3: deriveOfferRange 상승률 10%', () => {
    const base = { min: 5000, max: 7000, mid: 6000 };
    assert.deepEqual(deriveOfferRange(base, 10), { min: 5500, max: 7700, mid: 6600 });
  });

  test('T-ENGINE-4: deriveOfferRange rate=0(동결) → base와 동일', () => {
    const base = { min: 5000, max: 7000, mid: 6000 };
    assert.deepEqual(deriveOfferRange(base, 0), base);
  });

  test('T-ENGINE-5: deriveOfferRange base 미입력/rate null → {0,0,0}', () => {
    assert.deepEqual(deriveOfferRange({ min: 0, max: 0, mid: 0 }, 10), { min: 0, max: 0, mid: 0 });
    assert.deepEqual(deriveOfferRange({ min: 5000, max: 7000, mid: 6000 }, null), { min: 0, max: 0, mid: 0 });
  });

  test('T-ENGINE-5b (#8): 연봉 하한 0("0-5000") → B 연봉 붕괴 없음(min=0은 유효값)', () => {
    // 구현 전엔 !baseRange.min(0 falsy)이 결측 취급해 {0,0,0}으로 붕괴했다.
    assert.deepEqual(deriveOfferRange({ min: 0, max: 5000, mid: 2500 }, 10), { min: 0, max: 5500, mid: 2750 });
  });

  test('T-ENGINE-48: deriveOfferRange 반올림 경계', () => {
    const base = { min: 5001, max: 7005, mid: 6003 };
    const rate = 33;
    const mult = 1 + rate / 100;
    const result = deriveOfferRange(base, rate);
    assert.deepEqual(result, {
      min: Math.round(base.min * mult),
      max: Math.round(base.max * mult),
      mid: Math.round(base.mid * mult),
    });
  });
});

// ── T-05.3: 복지 합산·카테고리·정성 ───────────────────────────────────────
describe('T-05.3 복지 합산·카테고리·정성', () => {
  test('T-ENGINE-6: benTotal — 체크3(정성1 amt=null)+미체크1', () => {
    const list = [
      { benefit_amt: 100, checked: true, qual_yn: false },
      { benefit_amt: 200, checked: true, qual_yn: false },
      { benefit_amt: null, checked: true, qual_yn: true },
      { benefit_amt: 9999, checked: false, qual_yn: false },
    ];
    assert.deepEqual(benTotal(list), { ben: 300, net: 300 });
  });

  test('T-ENGINE-7: benCatCompare — a perks 200, b perks 300', () => {
    const listA = [{ checked: true, qual_yn: false, benefit_ctgr_cd: 'perks', benefit_amt: 200 }];
    const listB = [{ checked: true, qual_yn: false, benefit_ctgr_cd: 'perks', benefit_amt: 300 }];
    const result = benCatCompare(listA, listB);
    assert.equal(result.length, 9);
    const perksRow = result.find(r => r.ctgr === 'perks');
    assert.deepEqual(perksRow, { ctgr: 'perks', sumA: 200, sumB: 300, delta: 100 });
  });

  test('T-ENGINE-8: benCatCompare — 미상 카테고리 코드 폴백', () => {
    const listA = [{ checked: true, qual_yn: false, benefit_ctgr_cd: 'xxx', benefit_amt: 50 }];
    const result = benCatCompare(listA, []);
    const perksRow = result.find(r => r.ctgr === 'perks');
    assert.equal(perksRow.sumA, 50);
  });

  test('T-ENGINE-9: qualCompare — 정성 항목 a1/b0(소스 qual_desc_ctnt → 출력 qual_desc, #11)', () => {
    const listA = [{ checked: true, qual_yn: true, benefit_nm: '유연근무', benefit_ctgr_cd: 'flexibility', qual_desc_ctnt: '자율 출퇴근' }];
    const result = qualCompare(listA, []);
    assert.deepEqual(result, {
      a: [{ benefit_nm: '유연근무', benefit_ctgr_cd: 'flexibility', qual_desc: '자율 출퇴근' }],
      b: [],
    });
  });

  test('T-ENGINE-9b (#11): qual_desc_ctnt 없으면 빈 문자열, 구 qual_desc 키는 무시', () => {
    const listA = [{ checked: true, qual_yn: true, benefit_nm: '재택', benefit_ctgr_cd: 'flexibility', qual_desc: '무시되는 구필드' }];
    assert.equal(qualCompare(listA, []).a[0].qual_desc, ''); // 구 qual_desc는 소스가 아님(#11)
  });
});

// ── T-05.4: 실효연봉·근무시간·야근·시간가치 ──────────────────────────────
describe('T-05.4 실효연봉·근무시간·야근·시간가치', () => {
  test('T-ENGINE-10: effSalary', () => {
    assert.deepEqual(effSalary({ min: 5000, max: 7000, mid: 6000 }, 600), { min: 5600, max: 7600, mid: 6600 });
  });

  test('T-ENGINE-11: getWSHours 매핑', () => {
    assert.equal(getWSHours({ ot: 'low' }), 40);
    assert.equal(getWSHours({ ot: 'mid' }), 45);
    assert.equal(getWSHours({ ot: 'high' }), 54);
    assert.equal(getWSHours({ ot: null }), 0);
  });

  test('T-ENGINE-12: getOTPay 포괄 → 0', () => {
    assert.equal(getOTPay({ wage: 'inclusive', ot: 'high' }, { mid: 6000 }), 0);
  });

  test('T-ENGINE-13: getOTPay 비포괄+연장근로없음 → 0', () => {
    assert.equal(getOTPay({ wage: 'separate', ot: 'low' }, { mid: 6000 }), 0);
  });

  test('T-ENGINE-14: getOTPay 비포괄+mid → 932', () => {
    assert.equal(getOTPay({ wage: 'separate', ot: 'mid' }, { mid: 6000 }), 932);
  });

  test('T-ENGINE-15: getOTPay 연봉 미입력 → 0', () => {
    assert.equal(getOTPay({ wage: 'separate', ot: 'high' }, { mid: 0 }), 0);
  });

  test('T-ENGINE-16: hourlyValue 정상', () => {
    assert.equal(hourlyValue(6600, 0, 45), 28205);
  });

  test('T-ENGINE-17: hourlyValue 0나눗셈 방지 → null', () => {
    assert.equal(hourlyValue(6600, 0, 0), null);
  });
});

// ── T-05.5: 워라밸·통근 ───────────────────────────────────────────────
describe('T-05.5 워라밸·통근', () => {
  test('T-ENGINE-18: autonomyPerks — enum 문자열/불리언 계약 모두 수용, 3요소 전부 보유', () => {
    assert.deepEqual(autonomyPerks({ remote: 'hybrid', flex: 'flexible' }, { work_style_val: { unlimitedPTO: true } }),
      ['재택근무', '유연근무', '무제한휴가']);
    assert.deepEqual(autonomyPerks({ remote: true, flex: true }, { work_style_val: { unlimitedPTO: true } }),
      ['재택근무', '유연근무', '무제한휴가']); // 실데이터·UI 불리언 계약도 동일 결과
  });

  test('T-ENGINE-18b (#2 회귀): 불리언 remote=true가 반영(구현 전엔 항상 0/누락)', () => {
    assert.deepEqual(autonomyPerks({ remote: true, flex: false }, null), ['재택근무']);
  });

  test('T-ENGINE-19: autonomyPerks — none/false/회사없음 → 빈 배열', () => {
    assert.deepEqual(autonomyPerks({ remote: 'none', flex: 'none' }, null), []);
    assert.deepEqual(autonomyPerks({ remote: false, flex: false }, { work_style_val: { unlimitedPTO: false } }), []);
  });

  test('T-ENGINE-20: commuteCompare', () => {
    assert.deepEqual(commuteCompare(30, 60), { a: 30, b: 60, annA: 240, annB: 480, winner: 'a' });
  });
});

// ── T-05.6: 복지 불확실성 밴드 — DEC-2 ────────────────────────────────
describe('T-05.6 복지 불확실성 밴드 DEC-2', () => {
  test('T-ENGINE-21: bandCoeff stated 만료아님 → 0.05', () => {
    assert.equal(bandCoeff({ amt_source: 'stated', expires_dtm: null }, NOW), 0.05);
  });

  test('T-ENGINE-22: bandCoeff estimated 만료아님 → 0.20', () => {
    assert.equal(bandCoeff({ amt_source: 'estimated', expires_dtm: null }, NOW), 0.20);
  });

  test('T-ENGINE-23: bandCoeff none(정성) → 0', () => {
    assert.equal(bandCoeff({ amt_source: 'none' }, NOW), 0);
  });

  test('T-ENGINE-24: bandCoeff stated 만료 → 0.20(0.05+0.15)', () => {
    const result = bandCoeff({ amt_source: 'stated', expires_dtm: PAST_EXPIRED }, NOW);
    assert.ok(Math.abs(result - 0.20) < 1e-9, `기대 0.20, 실제 ${result}`);
  });

  test('T-ENGINE-25: bandCoeff estimated 만료 → 0.35(0.20+0.15)', () => {
    const result = bandCoeff({ amt_source: 'estimated', expires_dtm: PAST_EXPIRED }, NOW);
    assert.ok(Math.abs(result - 0.35) < 1e-9, `기대 0.35, 실제 ${result}`);
  });

  test('T-ENGINE-26 (Tier0/INV-5): badge_cd=official × amt_source=estimated → 0.20 (badge 무시)', () => {
    const result = bandCoeff({ badge_cd: 'official', amt_source: 'estimated' }, NOW);
    assert.ok(Math.abs(result - 0.20) < 1e-9, `기대 0.20(배지 무시), 실제 ${result}`);
  });

  test('T-ENGINE-27: sumBand — estimated200+stated100(체크) / estimated500(미체크) / 정성 제외', () => {
    const list = [
      { benefit_amt: 200, amt_source: 'estimated', checked: true, qual_yn: false, expires_dtm: null },
      { benefit_amt: 100, amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null },
      { benefit_amt: 500, amt_source: 'estimated', checked: false, qual_yn: false, expires_dtm: null },
      { benefit_amt: null, amt_source: 'none', checked: true, qual_yn: true, expires_dtm: null },
    ];
    const result = sumBand(list, NOW);
    assert.ok(Math.abs(result - 45) < 1e-9, `기대 45, 실제 ${result}`);
  });
});

// ── T-05.7: 우선순위 판정 vdCard·희생 ──────────────────────────────────
describe('T-05.7 vdCard·희생', () => {
  test('T-ENGINE-31: buildVdCard(salary) — 양쪽 hourly 산출', () => {
    const m = { totalA: 6000, totalB: 7000, hourlyA: 25000, hourlyB: 30000 };
    const card = buildVdCard('salary', m);
    assert.equal(card.p1.winner, 'b');
    assert.equal(card.p2.winner, 'b');
    assert.equal(card.p2.detail.pct, 20);
  });

  test('T-ENGINE-32: buildVdCard(salary) — hourlyA null → p2 tie/missing', () => {
    const m = { totalA: 6000, totalB: 7000, hourlyA: null, hourlyB: 30000 };
    const card = buildVdCard('salary', m);
    assert.equal(card.p2.winner, 'tie');
    assert.equal(card.p2.detail.missing, true);
  });

  test('T-ENGINE-33: buildVdCard(wlb) — 적게 일하기(a) · 시간 자율성 엄격 우세(b가 상위집합)', () => {
    const m = { wsHoursA: 40, wsHoursB: 45, autoA: ['유연근무'], autoB: ['재택근무', '유연근무'] };
    const card = buildVdCard('wlb', m);
    assert.equal(card.p1.winner, 'a');
    assert.equal(card.p2.winner, 'b');            // B가 A를 진부분집합으로 초과 → 승(#2)
    assert.deepEqual(card.p2.detail, { perksA: ['유연근무'], perksB: ['재택근무', '유연근무'] });
  });

  test('T-ENGINE-33b (#2): 시간 자율성 — 동일 집합·비교불가는 tie', () => {
    const eq = buildVdCard('wlb', { wsHoursA: 45, wsHoursB: 45, autoA: ['재택근무'], autoB: ['재택근무'] });
    assert.equal(eq.p2.winner, 'tie');            // 동일 집합
    const incomp = buildVdCard('wlb', { wsHoursA: 45, wsHoursB: 45, autoA: ['재택근무'], autoB: ['유연근무'] });
    assert.equal(incomp.p2.winner, 'tie');        // 비교불가(각자 다른 항목)
  });

  test('T-ENGINE-34: buildVdCard(wlb) — wsA=0 미입력 → p1 tie/missing', () => {
    const m = { wsHoursA: 0, wsHoursB: 45, autoA: [], autoB: ['재택근무'] };
    const card = buildVdCard('wlb', m);
    assert.equal(card.p1.winner, 'tie');
    assert.equal(card.p1.detail.missing, true);
    assert.equal(card.p2.winner, 'b');            // A 빈 집합 ⊂ B → B 승
  });

  test('T-ENGINE-35: buildVdCard(benefits) — benA>benB, |diff|<1200 satisfy', () => {
    const m = { benA: 800, benB: 500, totalA: 6000, totalB: 6500 };
    const card = buildVdCard('benefits', m);
    assert.equal(card.p1.winner, 'a');
    assert.equal(card.p2.detail.satisfy, true);
  });

  test('T-ENGINE-37: sacrificeCost(salary)', () => {
    const m = { totalA: 6000, totalB: 7200 };
    const result = sacrificeCost('salary', m);
    assert.equal(result.detail.annual, 1200);
    assert.equal(result.detail.monthly, 100);
    assert.equal(result.detail.daily, Math.round(1200 * 10000 / 365));
    assert.equal(result.detail.better, 'b');
  });

  test('T-ENGINE-38: sacrificeCost(wlb) — wsA=0 미입력 → ok:false', () => {
    const m = { wsHoursA: 0, wsHoursB: 45 };
    const result = sacrificeCost('wlb', m);
    assert.equal(result.ok, false);
    assert.equal(result.detail.missing, true);
  });

  test('T-ENGINE-39: sacrificeCost(benefits)', () => {
    const m = { benA: 800, benB: 500 };
    const result = sacrificeCost('benefits', m);
    assert.deepEqual(result.detail, { diff: 300, better: 'a' });
  });
});

// ── 통합 CompareState 픽스처(T-05.8) ─────────────────────────────────────
function makeState(overrides = {}) {
  const base = {
    salStr: '5000-7000',
    selectedRate: 10,
    benS: {
      a: [
        { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 300, benefit_ctgr_cd: 'compensation', badge_cd: 'official', amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null },
        { benefit_cd: 'gym', benefit_nm: '헬스비', benefit_amt: 100, benefit_ctgr_cd: 'health', badge_cd: 'est', amt_source: 'estimated', checked: true, qual_yn: false, expires_dtm: null },
        { benefit_cd: 'culture', benefit_nm: '자기계발', benefit_amt: null, benefit_ctgr_cd: 'growth', badge_cd: 'est', amt_source: 'none', checked: true, qual_yn: true, qual_desc_ctnt: '도서구매 지원', expires_dtm: null },
      ],
      b: [
        { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 200, benefit_ctgr_cd: 'compensation', badge_cd: 'official', amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null },
        { benefit_cd: 'snack', benefit_nm: '간식바', benefit_amt: 80, benefit_ctgr_cd: 'perks', badge_cd: 'est', amt_source: 'estimated', checked: true, qual_yn: false, expires_dtm: null },
      ],
    },
    wsState: {
      a: { ot: 'mid', wage: 'separate', remote: 'hybrid', flex: 'flexible' },
      b: { ot: 'high', wage: 'inclusive', remote: 'free', flex: 'stagger' },
    },
    com: { a: 30, b: 45 },
    curPri: 'salary',
    curSacrifice: 'wlb',
    matched: {
      a: { comp_id: 1, comp_nm: 'A사', comp_tp_cd: 'large', work_style_val: { unlimitedPTO: false } },
      b: { comp_id: 2, comp_nm: 'B사', comp_tp_cd: 'startup', work_style_val: { unlimitedPTO: true } },
    },
    companyTypes: [
      { comp_tp_cd: 'large', growth_rate_val: 0.04, growth_label_nm: '대기업 평균 4%', stability_score_no: 90 },
      { comp_tp_cd: 'startup', growth_rate_val: 0.10, growth_label_nm: '스타트업 평균 10%', stability_score_no: 40 },
    ],
  };
  return { ...base, ...overrides };
}

// ── T-05.8: 오케스트레이터 — compare·calc·restSummary ───────────────────
describe('T-05.8 오케스트레이터', () => {
  test('T-ENGINE-44: calc(state) 경량 요약 — vdCard 키 부재', () => {
    const result = calc(makeState());
    assert.deepEqual(Object.keys(result).sort(), ['eff', 'net', 'salRange']);
    assert.equal('vdCard' in result, false);
  });

  test('T-ENGINE-40: compare(state, now) 통합 정상 케이스', () => {
    const result = compare(makeState(), NOW);
    assert.equal(result.ok, true);
    assert.ok(result.a && result.b);
    assert.ok(result.deltas);
    assert.equal(result.catDelta.length, 9);
    assert.equal(result.vdCard.axis, 'salary');
    assert.equal(result.sacrifice.axis, 'wlb');
    assert.deepEqual(result.rest.map(r => r.axis), ['benefits']);
  });

  test('T-ENGINE-47: totalRange = [total-sumBand, total+sumBand]', () => {
    const state = makeState({
      salStr: '6000-6000',
      selectedRate: 10,
      benS: {
        a: [
          { benefit_amt: 500, benefit_ctgr_cd: 'compensation', amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null },
          { benefit_amt: 100, benefit_ctgr_cd: 'compensation', amt_source: 'estimated', checked: true, qual_yn: false, expires_dtm: null },
        ],
        b: [],
      },
      wsState: { a: { ot: null, wage: null, remote: 'none', flex: 'none' }, b: { ot: null, wage: null, remote: 'none', flex: 'none' } },
    });
    const result = compare(state, NOW);
    assert.equal(result.a.total, 6600);
    assert.deepEqual(result.a.totalRange, [6555, 6645]);
  });

  test('T-ENGINE-41 (Tier0): compare 필수 결측(연봉) → ok:false·missing·무크래시', () => {
    const state = makeState({ salStr: null });
    assert.doesNotThrow(() => {
      const result = compare(state, NOW);
      assert.equal(result.ok, false);
      assert.ok(result.missing.includes('salary'));
    });
  });

  test('T-ENGINE-41b (#3): 상승률 미입력(selectedRate null) → ok:false·missing raise', () => {
    const result = compare(makeState({ selectedRate: null }), NOW);
    assert.equal(result.ok, false);
    assert.ok(result.missing.includes('raise'));
  });

  test('T-ENGINE-41c (#3): 상승률 0(동결)은 유효값 → raise 결측 아님', () => {
    const result = compare(makeState({ selectedRate: 0 }), NOW);
    assert.equal(result.missing.includes('raise'), false);
  });

  test('T-ENGINE-40b (#2): compare — 슬롯 autonomy는 보유 자율성 요소 라벨 배열', () => {
    const result = compare(makeState(), NOW);
    assert.deepEqual(result.a.autonomy, ['재택근무', '유연근무']);              // hybrid+flexible, PTO false
    assert.deepEqual(result.b.autonomy, ['재택근무', '유연근무', '무제한휴가']); // free+stagger + PTO true
  });

  test('T-ENGINE-42: compare warnings — 양쪽 포괄+야근 → both_inclusive', () => {
    const state = makeState({
      salStr: '5000-6000',
      selectedRate: 5,
      wsState: {
        a: { ot: 'mid', wage: 'inclusive', remote: 'none', flex: 'none' },
        b: { ot: 'high', wage: 'inclusive', remote: 'none', flex: 'none' },
      },
    });
    const result = compare(state, NOW);
    assert.ok(result.warnings.includes('both_inclusive'));
  });

  test('T-ENGINE-43: compare warnings — 연봉↑ 실질 축소 → eff_shrink', () => {
    const state = makeState({
      salStr: '6000-6000',
      selectedRate: 10, // salB.mid = 6600, salDiffMid = 600 > 0
      benS: {
        a: [{ benefit_amt: 2000, benefit_ctgr_cd: 'compensation', amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null }],
        b: [{ benefit_amt: 500, benefit_ctgr_cd: 'compensation', amt_source: 'stated', checked: true, qual_yn: false, expires_dtm: null }],
      },
      wsState: { a: { ot: null, wage: null, remote: 'none', flex: 'none' }, b: { ot: null, wage: null, remote: 'none', flex: 'none' } },
    });
    const result = compare(state, NOW);
    // effA = 6000+2000=8000, effB=6600+500=7100, effDiffMid=-900 < salDiffMid(600), benA(2000)>benB(500)
    assert.ok(result.warnings.includes('eff_shrink'));
  });
});

// ── T-05.9: 순수성·프로파일러 제거 게이트 ────────────────────────────────
describe('T-05.9 순수성·프로파일러 제거', () => {
  test('T-ENGINE-45 (Tier0/INV-4): 순수성 — 부수효과 0·불변 입력·결정성', () => {
    // 소스(주석 제외 실코드)에 DOM/네트워크/스토리지 토큰 미등장
    for (const token of ['document.', 'window.', 'fetch(', 'localStorage', 'XMLHttpRequest']) {
      assert.equal(CALC_CODE_ONLY.includes(token), false, `금지 토큰 등장: ${token}`);
    }
    // 동결 입력 호출 시 예외 없음(불변 입력 보증)
    const frozenState = deepFreeze(makeState());
    assert.doesNotThrow(() => compare(frozenState, NOW));
    assert.doesNotThrow(() => calc(frozenState));
    // 결정성: 동일 입력 반복 호출 → deep-equal
    const r1 = compare(makeState(), NOW);
    const r2 = compare(makeState(), NOW);
    assert.deepEqual(r1, r2);
  });

  test('T-ENGINE-46: 프로파일러 벡터 제거 — pfResult 주입 무영향, 소스 토큰 0', () => {
    for (const token of ['pfResult', 'profiler', 'openAuth']) {
      assert.equal(CALC_CODE_ONLY.includes(token), false, `금지 토큰 등장: ${token}`);
    }
    const baseline = compare(makeState(), NOW);
    const withProfiler = compare(makeState({ pfResult: { some: 'weighted-vector' }, pfJob: 'dev' }), NOW);
    assert.deepEqual(withProfiler, baseline);
  });
});
