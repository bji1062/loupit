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
  bandCoeff, pairVerdict, sumBand, buildVdCard, sacrificeCost,
  compare, calc, restSummary,
  // 이직 계산기 개편(2026-09-23, SPEC 05 §15.7 SP-MOVE)
  compareCore, AXIS_THRESHOLDS, deltaBand, verdictTier, classifyPairs, benDiffParts,
  cappedRows, facetOf, tenureItems, tenureGate, catProfile, hourlyWithCommute, breakevenRate,
  weeklyHours, overtimePay, timeSheet, wageScenarios, sensitivity, robustness, askList,
  buildAllVdCards, calculatorExtras, unsureCause, BREAKEVEN_BOUNDS,
} from './calc.js';
import { isLegalRow } from './legal.js';

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
      commuteCompare, bandCoeff, pairVerdict, sumBand, buildVdCard,
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

  // ── SP-CMP-6 pairVerdict — 항목 하나의 금액 맞대결 ────────────────────────
  //
  // 계수를 여기 다시 적지 않는다: `bandCoeff` 를 그대로 쓰는지 자체를 검사한다. 계수가 두 곳에
  // 적히면 한쪽만 바뀌는 날이 오고, 그날 화면과 문서가 다른 판정을 말한다.

  test('T-CMP-1: 값이 같으면 「같음」 — 밴드를 보기 전에 결정된다', () => {
    const a = { amt_source: 'stated', benefit_amt: 100 };
    const b = { amt_source: 'estimated', benefit_amt: 100 };
    assert.equal(pairVerdict(a, b, NOW), 'same');
  });

  test('T-CMP-2: 밴드가 겹치면 「말할 수 없음」 — 기본값이 여기다(실측 중앙 66.7%)', () => {
    // 100 추정 → [80,120], 110 추정 → [88,132]. 겹친다.
    assert.equal(pairVerdict(
      { amt_source: 'estimated', benefit_amt: 100 },
      { amt_source: 'estimated', benefit_amt: 110 }, NOW), 'unsure');
  });

  test('T-CMP-3: 겹치지 않으면 큰 쪽', () => {
    const big = { amt_source: 'stated', benefit_amt: 400 };
    const small = { amt_source: 'stated', benefit_amt: 100 };
    assert.equal(pairVerdict(big, small, NOW), 'a');
    assert.equal(pairVerdict(small, big, NOW), 'b');
  });

  test('T-CMP-4: 만료는 밴드를 넓혀 판정을 「말할 수 없음」으로 되돌린다(+15%p)', () => {
    // 만료 전: 100 공식[95,105] vs 130 공식[123.5,136.5] → 안 겹쳐 B 가 큼.
    const fresh = { amt_source: 'stated', benefit_amt: 100, expires_dtm: null };
    const other = { amt_source: 'stated', benefit_amt: 130, expires_dtm: null };
    assert.equal(pairVerdict(fresh, other, NOW), 'b');
    // 만료 후: 100 → 0.05+0.15 = 0.20 → [80,120]. 130 쪽 하한 123.5 보다 낮지만 위쪽이 닿는다.
    const stale = { amt_source: 'stated', benefit_amt: 100, expires_dtm: PAST_EXPIRED };
    const otherStale = { amt_source: 'stated', benefit_amt: 130, expires_dtm: PAST_EXPIRED };
    assert.equal(pairVerdict(stale, otherStale, NOW), 'unsure');
  });

  test('T-CMP-5: 금액이 없거나 정성이면 「말할 수 없음」 — 없는 값을 0 으로 세지 않는다', () => {
    const amt = { amt_source: 'stated', benefit_amt: 100 };
    assert.equal(pairVerdict(amt, { qual_yn: true, benefit_amt: null }, NOW), 'unsure');
    assert.equal(pairVerdict(amt, { amt_source: 'stated', benefit_amt: null }, NOW), 'unsure');
    assert.equal(pairVerdict(null, amt, NOW), 'unsure');
  });

  test('T-CMP-6: 계수를 amt_source 에서 읽는다 — 같은 금액 쌍이 출처에 따라 다르게 판정된다', () => {
    // 100 대 125 는 공식(±5%)이면 [95,105] vs [118.75,131.25] 로 안 겹치고,
    // 추정(±20%)이면 [80,120] vs [100,150] 으로 겹친다. 계수를 여기 상수로 적지 않고도
    // 「bandCoeff 를 그대로 쓴다」가 검사된다 — 계수를 두 곳에 적으면 한쪽만 바뀐다.
    const pair = (src) => pairVerdict(
      { amt_source: src, benefit_amt: 100 }, { amt_source: src, benefit_amt: 125 }, NOW);
    assert.equal(pair('stated'), 'b');
    assert.equal(pair('estimated'), 'unsure');
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

  test('T-ENGINE-31b: buildVdCard(salary) — 시간당 % 분모는 현재 직장(A)', () => {
    // A 가 클 때 min(A,B) 분모는 감소율을 부풀린다 — 골든 쌍(NAVER→카카오) 42,521 → 27,561 은 35% 다(54% 아님).
    const card = buildVdCard('salary', { totalA: 9950, totalB: 7739, hourlyA: 42521, hourlyB: 27561 });
    assert.equal(card.p2.winner, 'a');
    assert.equal(card.p2.detail.pct, 35);
    const down = buildVdCard('salary', { totalA: 6000, totalB: 5000, hourlyA: 30000, hourlyB: 25000 });
    assert.equal(down.p2.detail.pct, 17, '5,000 / 30,000 = 16.7% → 17 (min 분모였다면 20)');
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

// ═════════════════════════════════════════════════════════════════════════════
// 이직 계산기 개편(2026-09-23) — SPEC 05 §15.7(SP-MOVE) · FINAL-DESIGN §8-3 ⓐ~ⓓ·ⓖ·ⓗ + IMPL-BRIEF 결정 1·4·6
// 문구 회귀(ⓔ·ⓕ)는 렌더가 소유하므로 report-calc.test.js 에 있다.
// ═════════════════════════════════════════════════════════════════════════════
const G = JSON.parse(readFileSync(join(HERE, '../../test/fixtures/calc-golden-naver-kakao.json'), 'utf8'));
const NOW_CALC = new Date('2026-09-22T00:00:00+09:00').getTime();

const items = (c) => c.benefits.map((b) => ({ ...b, checked: true }));

// 골든 시나리오(FINAL-DESIGN 전 절 공통): NAVER → 카카오 · 연봉 6,000 · +15% · A 주 45h 비포괄 · B 주 54h 포괄
// · 통근 40/60분 · 근속 3년.
function goldenState(over = {}) {
  return {
    salStr: '6000-6000', selectedRate: 15,
    benS: { a: items(G.naver), b: items(G.kakao) },
    wsState: {
      a: { ot: 'mid', hours: 45, wage: 'separate', remote: false, flex: true },
      b: { ot: 'high', hours: 54, wage: 'inclusive', remote: false, flex: true },
    },
    com: { a: 40, b: 60 }, commuteIn: { a: 40, b: 60 }, tenureYears: 3,
    curPri: 'salary', curSacrifice: null,
    matched: { a: G.naver, b: G.kakao },
    ...over,
  };
}

// ── 결정적 의사난수(시드 고정) — 「랜덤 쌍 100개」를 매번 같은 쌍으로 ──────────────
function rng(seed) {
  let s = seed >>> 0;
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 2 ** 32; };
}
const CATS = ['compensation', 'flexibility', 'work_env', 'time_off', 'health', 'family', 'growth', 'leisure', 'perks'];
const CODES = Array.from({ length: 24 }, (_, i) => 'cd' + i);
function randomList(r) {
  const n = Math.floor(r() * 14) + 1;
  const pool = [...CODES].sort(() => r() - 0.5).slice(0, n);
  return pool.map((cd) => {
    const qual = r() < 0.5;
    return {
      benefit_cd: cd, benefit_nm: '항목 ' + cd, benefit_ctgr_cd: CATS[Math.floor(r() * 9)],
      qual_yn: qual, benefit_amt: qual ? null : Math.round(r() * 800) + 10,
      amt_source: qual ? 'none' : (r() < 0.3 ? 'stated' : 'estimated'),
      expires_dtm: r() < 0.2 ? '2020-01-01T00:00:00Z' : null,
      checked: r() < 0.9, note_ctnt: r() < 0.15 ? '연간 최대 100만원' : null,
    };
  });
}
function randomState(r) {
  const ot = ['low', 'mid', 'high', null];
  const wage = ['inclusive', 'separate', null];
  return {
    salStr: (() => { const v = Math.round(r() * 8000) + 2500; return v + '-' + v; })(),
    selectedRate: Math.round(r() * 40) - 5,
    benS: { a: randomList(r), b: randomList(r) },
    wsState: {
      a: { ot: ot[Math.floor(r() * 4)], wage: wage[Math.floor(r() * 3)], remote: r() < 0.5, flex: r() < 0.5 },
      b: { ot: ot[Math.floor(r() * 4)], wage: wage[Math.floor(r() * 3)], remote: r() < 0.5, flex: r() < 0.5 },
    },
    com: { a: 30, b: 50 }, commuteIn: { a: r() < 0.5 ? 30 : null, b: 50 }, tenureYears: r() < 0.5 ? 2 : null,
    curPri: 'salary', curSacrifice: null, matched: { a: null, b: null },
  };
}

// ── ⓗ 골든 픽스처 ─────────────────────────────────────────────────────────────
describe('CALC-G 골든 픽스처 NAVER → 카카오(FINAL-DESIGN §6-0)', () => {
  const r = compare(goldenState(), NOW_CALC);

  test('실효 총보상 9,950 / 7,739 / 차이 −2,211 · 폭 ±452', () => {
    assert.equal(r.a.total, 9950);
    assert.equal(r.b.total, 7739);
    assert.equal(r.deltas.totalDiff, -2211);
    assert.equal(Math.round(r.band.delta), 452);
    assert.equal(r.deltas.otDiff, -932);
    assert.equal(Math.round(r.deltas.effRate * 1000) / 10, -22.2);
  });

  test('짝짓기: 현재 직장에만 12 · 새로 생김 5 · 공통 11(금액 4 · 한쪽만 금액 4 · 둘 다 금액 없음 3)', () => {
    assert.equal(r.pairs.onlyA.length, 12);
    assert.equal(r.pairs.onlyB.length, 5);
    assert.equal(r.pairs.bothAmt.length + r.pairs.mixed.length + r.pairs.bothQual.length, 11);
    assert.equal(r.pairs.bothAmt.length, 4);
    assert.equal(r.pairs.mixed.length, 4);
    assert.equal(r.pairs.bothQual.length, 3);
  });

  test('4분해 −1,540 · +434 · −217 · −856 = −2,179', () => {
    assert.deepEqual(
      [r.parts.onlyA, r.parts.onlyB, r.parts.sameBoth, r.parts.mixed, r.parts.total],
      [-1540, 434, -217, -856, -2179],
    );
    assert.equal(r.parts.total, r.deltas.benDiff);
  });

  test('튼튼함: 한쪽만 등록 제외 −1,355(±355) · 복지 0 이면 −32(거의 같음)', () => {
    assert.equal(r.robust.exMixed.diff, -1355);
    assert.equal(Math.round(r.robust.exMixed.band), 355);
    assert.equal(r.robust.noBenefit.diff, -32);
    assert.equal(r.robust.noBenefit.tier, 'near');
  });

  test('감도 ①~⑤: +791(뒤집힘) · −1,355 · −1,411 · −915(±333) · −32', () => {
    const by = Object.fromEntries(r.sens.rows.map((x) => [x.key, x]));
    assert.equal(by.b_wage_flip.totalDiff, 791);
    assert.equal(by.b_wage_flip.flips, true);
    assert.equal(by.b_wage_flip.otB, 3002);
    assert.equal(by.b_wage_flip.hourlyBase, 27512);
    assert.equal(by.b_wage_flip.breakeven.sal, 6349);
    assert.equal(by.drop_mixed.totalDiff, -1355);
    assert.equal(by.drop_mixed.amount, 856);
    assert.equal(by.drop_capped.totalDiff, -1411);
    assert.equal(by.drop_capped.amount, 800);
    assert.equal(by.drop_both.totalDiff, -915);
    assert.equal(by.drop_both.count, 6);
    assert.equal(by.drop_both.amount, 1296);
    assert.equal(Math.round(by.drop_both.band), 333);
    assert.equal(by.no_benefits.totalDiff, -32);
    assert.equal(by.no_benefits.result, 'near');
    assert.deepEqual(r.sens.rows.filter((x) => x.flips).map((x) => x.key), ['b_wage_flip']);
  });

  test('같아지는 연봉 9,111(+51.9%) · 8,255(+37.6%) · 6,932(+15.5%)', () => {
    assert.equal(r.breakeven.full.sal, 9111);
    assert.equal(Math.round(r.breakeven.full.rate * 10000) / 100, 51.85);
    assert.equal(r.breakeven.exMixed.sal, 8255);
    assert.equal(r.breakeven.noBenefit.sal, 6932);
  });

  test('시간: 주 +9h · 연 +468h(59일) · 통근 +160h(20일) · 시간당 42,521 → 27,561(−35%) · 통근 포함 37,406 → 23,537', () => {
    const t = r.time;
    assert.deepEqual([t.hours.weekDiff, t.hours.annDiff, t.hours.days], [9, 468, 59]);
    assert.deepEqual([t.commute.annA, t.commute.annB, t.commute.days], [320, 480, 20]);
    assert.deepEqual([t.hourly.a, t.hourly.b], [42521, 27561]);
    assert.equal(Math.round(t.hourly.pct * 100), -35);
    assert.deepEqual([t.hourlyCommute.a, t.hourlyCommute.b], [37406, 23537]);
  });

  test('축 3벌: 연봉 = 현재 직장(연봉은 오르지만 줄어듦) · 워라밸 = 시간으로 현재 직장 · 복지 = 금액으로 현재 직장', () => {
    assert.equal(r.axes.salary.tier, 'a');
    assert.equal(r.axes.salary.shape, 'reverse');
    assert.equal(r.axes.salary.flip.key, 'b_wage_flip');
    assert.equal(r.axes.wlb.tier, 'a');
    assert.equal(r.axes.wlb.decidedBy, 'hours');
    assert.deepEqual([r.axes.wlb.count.a, r.axes.wlb.count.b, r.axes.wlb.count.tenureA], [3, 1, 2]);
    assert.equal(r.axes.benefits.tier, 'a');
    assert.equal(r.axes.benefits.d, -2179);
    assert.equal(r.axes.benefits.exMixed.diff, -1323);
    assert.equal(Math.round(r.axes.benefits.mixed.share * 100), 39);
    assert.equal(r.axes.benefits.salOffset.gap, -1279);
    assert.deepEqual(r.axes.benefits.mixed.names, ['개인 업무 지원비', '업무 장비 예산', '네이버 서비스 이용권', 'Club Greeny']);
  });

  test('ⓖ 카테고리: 생활·편의는 폭이 겹쳐 「비슷함」, 보상·건강·여가는 현재 직장, 성장·근무환경은 한쪽만 금액', () => {
    const v = Object.fromEntries(r.cat.map((c) => [c.ctgr, c.verdict]));
    assert.equal(v.perks, 'similar');
    assert.equal(v.compensation, 'a');
    assert.equal(v.health, 'a');
    assert.equal(v.leisure, 'a');
    assert.equal(v.growth, 'aOnly');
    assert.equal(v.work_env, 'aOnly');
    assert.equal(v.family, 'countOnly');
    const perks = r.cat.find((c) => c.ctgr === 'perks');
    assert.deepEqual([perks.sumA, perks.sumB], [532, 644]);
  });

  test('근속 3년: 받는 중 2(리프레시 2년 · 자기돌봄 3년) · 아직 1(근속 기념 선물 10년, 7년 남음) · 이직 후보 0', () => {
    assert.deepEqual(r.tenure.earned.map((x) => [x.item.benefit_nm, x.years]), [['리프레시 플러스 휴가', 2], ['자기돌봄 휴직', 3]]);
    assert.deepEqual(r.tenure.pending.map((x) => [x.item.benefit_nm, x.years, x.left]), [['근속 기념 선물', 10, 7]]);
    assert.equal(r.tenure.otherSideCount, 0);
  });

  test('물어볼 것 3줄: 임금 형태(3,002만원) · 금액 미등록 2건 · 주식 1,000만원(46%)', () => {
    assert.deepEqual(r.ask.map((x) => x.kind), ['wage', 'mixed', 'topOnlyA']);
    assert.equal(r.ask[0].amount, 3002);
    assert.deepEqual(r.ask[1].names, ['자기계발비', '최신 업무장비']);
    assert.equal(r.ask[2].nm, '전 직원 주식 부여');
    assert.equal(Math.round(r.ask[2].share * 100), 46);
  });

  test('자료 근거: 금액 20건(공식 9 · 추정 11) · 금액 없음 19 · 최대·한도 3건(NAVER)', () => {
    assert.equal(r.basis.a.amt + r.basis.b.amt, 20);
    assert.equal(r.basis.a.stated + r.basis.b.stated, 9);
    assert.equal(r.basis.a.qual + r.basis.b.qual, 19);
    assert.deepEqual(r.basis.a.capped.map((x) => x.amt).sort((x, y) => x - y), [200, 240, 360]);
    assert.equal(r.warnings.includes('inclusive_b'), true);
  });
});

// ── ⓐ 브리지 항등식 · ⓑ 4분해 항등식 + 통 배타성 ──────────────────────────────
describe('CALC-ID 항등식(시드 고정 랜덤 쌍 100개)', () => {
  const r = rng(20260923);
  const states = Array.from({ length: 100 }, () => randomState(r));

  test('ⓐ totalDiff === salMid + benDiff + otDiff (오차 0)', () => {
    for (const st of states) {
      const rep = compare(st, NOW_CALC);
      if (!rep.ok) continue;
      assert.equal(rep.deltas.totalDiff, rep.deltas.salMid + rep.deltas.benDiff + rep.deltas.otDiff);
    }
  });

  test('ⓑ benDiffParts 합 === benDiff, 통은 배타(항목 수 보존)', () => {
    for (const st of states) {
      const rep = compareCore(st, NOW_CALC);
      const parts = benDiffParts(st.benS.a, st.benS.b);
      assert.equal(parts.total, rep.deltas.benDiff);
      const p = classifyPairs(st.benS.a, st.benS.b);
      const nA = p.onlyA.length + p.bothAmt.length + p.mixed.length + p.bothQual.length;
      const nB = p.onlyB.length + p.bothAmt.length + p.mixed.length + p.bothQual.length;
      assert.equal(nA, st.benS.a.length);
      assert.equal(nB, st.benS.b.length);
      for (const m of p.mixed) assert.notEqual(m.a.qual_yn, m.b.qual_yn);
    }
  });

  test('compare 는 입력을 바꾸지 않는다(감도·시나리오가 복제본에서 돈다)', () => {
    const st = goldenState();
    const snap = JSON.stringify(st);
    compare(st, NOW_CALC);
    assert.equal(JSON.stringify(st), snap);
  });
});

// ── ⓒ 판정 티어 경계 ───────────────────────────────────────────────────────────
describe('CALC-TIER verdictTier', () => {
  test('|d| ≤ 폭 → unsure, 폭 < |d| ≤ max(폭×1.5, 기준×3%) → near, 그 밖 → 방향', () => {
    assert.equal(verdictTier(-452, 452, 9950), 'unsure');
    assert.equal(verdictTier(-453, 452, 9950), 'near');
    assert.equal(verdictTier(-678, 452, 9950), 'near');
    assert.equal(verdictTier(-679, 452, 9950), 'a');
    assert.equal(verdictTier(679, 452, 9950), 'b');
    // 폭이 작으면 기준의 3% 가 near 상한이 된다
    assert.equal(verdictTier(-290, 10, 10000), 'near');
    assert.equal(verdictTier(-301, 10, 10000), 'a');
  });
  test('가드: 「그대로」와 「한쪽만 금액 등록 제외」의 부호가 갈리면 unsure', () => {
    assert.equal(verdictTier(-2000, 100, 9000, 300), 'unsure');
    assert.equal(verdictTier(-2000, 100, 9000, -300), 'a');
  });
  test('폭 0 · 차이 0 은 near(차이가 없다) — 「말할 수 없음」이 아니다', () => {
    assert.equal(verdictTier(0, 0, 9000), 'near');
  });
  test('near 는 두 갈래 — 기준값 3% 안(small) · 오차 범위를 겨우 넘음(weak)', () => {
    const mk = (amt) => ({ benefit_cd: 'x', benefit_nm: 'x', benefit_amt: amt, qual_yn: false, amt_source: 'estimated', benefit_ctgr_cd: 'perks', checked: true, expires_dtm: null });
    const st = (a, b) => ({ salStr: '5000-5000', selectedRate: 0, benS: { a: [mk(a)], b: [{ ...mk(b), benefit_cd: 'y' }] }, wsState: { a: {}, b: {} }, com: { a: 0, b: 0 }, commuteIn: { a: null, b: null }, tenureYears: null, curPri: 'salary', matched: { a: null, b: null } });
    // 폭 = (1000+1300)×0.2 = 460 · 차이 300 ≤ 460 → unsure / 폭 = (1000+1600)×0.2 = 520 · 차이 600 → near(≤780), 600 > 5,000×… → weak
    assert.equal(compare(st(1000, 1300), NOW_CALC).axes.salary.tier, 'unsure');
    const w = compare(st(1000, 1600), NOW_CALC).axes.salary;
    assert.equal(w.tier, 'near');
    assert.equal(w.nearKind, 'weak');
    const sm = compare({ ...st(0, 0), benS: { a: [], b: [] }, selectedRate: 2 }, NOW_CALC).axes.salary;
    assert.equal(sm.tier, 'near');
    assert.equal(sm.nearKind, 'small', '연봉 2% 차이(100) ≤ 총보상 3%(150)');
  });
  test('AXIS_THRESHOLDS 는 동결된 설계 상수', () => {
    assert.equal(Object.isFrozen(AXIS_THRESHOLDS), true);
    assert.deepEqual(Object.keys(AXIS_THRESHOLDS).sort(), ['nearBandMult', 'nearTotalPct', 'wlbCommuteAnnHrs', 'wlbQualCount', 'wlbWeekHrs']);
  });
  test('deltaBand = 두 폭의 합(제곱합 아님)', () => {
    assert.equal(deltaBand({ sumBand: 300 }, { sumBand: 400 }), 700);
  });
});

// ── ⓓ 브레이크이븐 왕복 ────────────────────────────────────────────────────────
describe('CALC-BE breakevenRate 왕복', () => {
  for (const wageB of ['inclusive', 'separate']) {
    test(`구한 연봉을 넣으면 총보상 차이 ≈ 0 (B ${wageB})`, () => {
      const st = goldenState({ wsState: { ...goldenState().wsState, b: { ot: 'high', hours: 54, wage: wageB } } });
      const rep = compare(st, NOW_CALC);
      const be = rep.breakeven.full;
      const back = compareCore({ ...st, selectedRate: be.rate * 100 }, NOW_CALC);
      assert.ok(Math.abs(back.deltas.totalDiff) <= 2, `왕복 오차 ${back.deltas.totalDiff}`);
      if (wageB === 'separate') assert.ok(rep.breakeven.k > 0.4 && rep.breakeven.k < 0.44);
    });
  }
  test('연봉 미입력이면 null', () => {
    assert.equal(breakevenRate({ a: { salRange: { mid: 0 } } }, null, {}), null);
  });
});

// ── 결정 4: 주 근무시간 직접 입력 · 임금 형태 미선택 → 두 경우 병치 ─────────────────
describe('CALC-WS 주 근무시간 · 임금 형태(결정 4)', () => {
  test('weeklyHours: 직접 입력이 칩보다 우선, ot 만 있으면 getWSHours 와 같다', () => {
    assert.equal(weeklyHours({ ot: 'mid', hours: 44 }), 44);
    assert.equal(weeklyHours({ ot: 'mid' }), getWSHours({ ot: 'mid' }));
    assert.equal(weeklyHours({ ot: null, hours: null }), 0);
    assert.equal(weeklyHours({ ot: 'high', hours: '' }), OT_HRS.high);
  });
  test('overtimePay: ot 만 주면 getOTPay 와 같고, 주 44h 는 4시간분', () => {
    const sal = { mid: 6000 };
    for (const ot of ['low', 'mid', 'high']) {
      assert.equal(overtimePay({ ot, wage: 'separate' }, sal), getOTPay({ ot, wage: 'separate' }, sal));
    }
    assert.equal(overtimePay({ hours: 44, wage: 'separate' }, sal), Math.round(4 * (6000 * 10000 / 12 / 209) * 1.5 * 4.33 * 12 / 10000));
    assert.equal(overtimePay({ hours: 38, wage: 'separate' }, sal), 0, '40시간 미만은 0(음수 아님)');
    assert.equal(overtimePay({ hours: 54, wage: null }, sal), 0, '미선택은 이 함수에서 0 — 병치는 wageScenarios 몫');
  });
  test('임금 형태 미선택(B, 주 54h) → wage_unknown_b 경고 + 포괄/비포괄 두 경우', () => {
    const st = goldenState();
    st.wsState = { ...st.wsState, b: { ot: 'high', hours: 54, wage: null } };
    const rep = compare(st, NOW_CALC);
    assert.ok(rep.warnings.includes('wage_unknown_b'));
    assert.deepEqual(rep.wage.slots, ['b']);
    const byWage = Object.fromEntries(rep.wage.cases.map((c) => [c.wage.b, c.diff]));
    assert.equal(byWage.inclusive, -2211);
    assert.equal(byWage.separate, 791);
    assert.equal(rep.wage.agree, false);
    assert.equal(rep.axes.salary.tier, 'depends', '두 경우의 결론이 갈리면 연봉 축은 「야근수당에 따라 달라진다」');
    assert.equal(rep.sens.rows.some((x) => x.key === 'b_wage_flip'), false, '미선택이면 ① 대신 병치가 그 일을 한다');
    assert.equal(rep.ask[0].kind, 'wage');
  });
  test('양쪽 미선택 → 네 가지 조합', () => {
    const st = goldenState();
    st.wsState = { a: { hours: 45, wage: null }, b: { hours: 54, wage: null } };
    const rep = compare(st, NOW_CALC);
    assert.equal(rep.wage.cases.length, 4);
  });
  test('주 근무시간 미입력 → 시간당·야근수당 미산출, 시간 계산서 null', () => {
    const st = goldenState();
    st.wsState = { a: { ot: null, wage: 'separate' }, b: { ot: null, wage: 'inclusive' } };
    const rep = compare(st, NOW_CALC);
    assert.equal(rep.a.hourly, null);
    assert.equal(rep.a.otPay, 0);
    assert.equal(rep.time.hours, null);
    assert.equal(rep.time.hourly, null);
    assert.equal(rep.wage, null, '야근이 없으면 임금 형태는 결과를 바꾸지 않는다');
    assert.notEqual(rep.axes.wlb.decidedBy, 'hours');
  });
  test('포괄 경고는 야근이 있을 때만(주 40h 이하·미선택이면 경고 없음)', () => {
    const st = goldenState();
    st.wsState = { a: { ot: null, wage: 'inclusive' }, b: { ot: 'low', wage: 'inclusive' } };
    const rep = compare(st, NOW_CALC);
    assert.equal(rep.warnings.some((w) => w.startsWith('inclusive') || w === 'both_inclusive'), false);
  });
});

// ── 결정 1: 복지 축 = 등록 금액 합의 차이 ± 폭 · 가드 ───────────────────────────
describe('CALC-BEN 복지 축 금액 판정(결정 1)', () => {
  const mk = (cd, amt, src = 'stated', extra = {}) => ({
    benefit_cd: cd, benefit_nm: cd, benefit_amt: amt, qual_yn: amt == null, amt_source: amt == null ? 'none' : src,
    benefit_ctgr_cd: 'perks', checked: true, expires_dtm: null, ...extra,
  });
  const base = (a, b) => ({
    salStr: '5000-5000', selectedRate: 10, benS: { a, b },
    wsState: { a: { ot: null, wage: null }, b: { ot: null, wage: null } },
    com: { a: 0, b: 0 }, commuteIn: { a: null, b: null }, tenureYears: null, curPri: 'benefits', matched: { a: null, b: null },
  });

  test('항목 수가 많아도 금액이 적으면 금액 쪽이 이긴다(항목 수는 판정에 안 쓴다)', () => {
    const a = [mk('x1', null), mk('x2', null), mk('x3', null), mk('x4', null), mk('m', 100)];
    const b = [mk('m', 1000)];
    const rep = compare(base(a, b), NOW_CALC);
    assert.equal(rep.axes.benefits.tier, 'b');
    assert.equal(rep.axes.benefits.counts.a, 5);
  });
  test('두 회사 모두 금액이 등록된 복지가 없으면 「거의 같음」이 아니라 말할 수 없음', () => {
    const rep = compare(base([mk('x', null)], [mk('y', null)]), NOW_CALC);
    assert.equal(rep.axes.benefits.noAmounts, true);
    assert.equal(rep.axes.benefits.tier, 'unsure');
  });
  test('오차 범위가 겹치면 unsure', () => {
    const rep = compare(base([mk('m', 500, 'estimated')], [mk('m', 560, 'estimated')]), NOW_CALC);
    assert.equal(rep.axes.benefits.tier, 'unsure');
  });
  test('가드: 한쪽만 금액이 등록된 항목을 빼면 방향이 뒤집히는 쌍 → unsure', () => {
    // A: 혼합 1,000(B 는 제도만) + 공통 200 / B: 공통 900 → 그대로는 A +300, 혼합 빼면 B +700
    const a = [mk('mix', 1000), mk('same', 200)];
    const b = [mk('mix', null), mk('same', 900)];
    const rep = compare(base(a, b), NOW_CALC);
    assert.equal(rep.axes.benefits.d, -300);
    assert.equal(rep.axes.benefits.exMixed.diff, 700);
    assert.equal(rep.axes.benefits.tier, 'unsure');
  });
});

// ── 결정 6: 행별 「빼고 다시 계산」 = checked 계약 ─────────────────────────────────
describe('CALC-EX 행별 빼기(checked=false) 재계산', () => {
  test('주식 1,000 을 빼면 A 총보상이 1,000 줄고 분류(목록)는 그대로다', () => {
    const st = goldenState();
    st.benS.a = st.benS.a.map((b) => (b.benefit_cd === 'stock_grant' ? { ...b, checked: false } : b));
    const rep = compare(st, NOW_CALC);
    assert.equal(rep.a.total, 8950);
    assert.equal(rep.deltas.totalDiff, -1211);
    assert.equal(rep.pairs.onlyA.length, 12, '뺀 항목도 목록에는 남는다(등록 기준 분류)');
    assert.equal(rep.parts.onlyA, -540);
    assert.equal(rep.parts.total, rep.deltas.benDiff);
  });
});

// ── 표식 · 근속 · 법정 ─────────────────────────────────────────────────────────
describe('CALC-FACET 표식(표시 전용)', () => {
  const it = (nm, desc, amt = null) => ({ benefit_nm: nm, qual_desc_ctnt: amt == null ? desc : null, note_ctnt: amt == null ? null : desc, benefit_amt: amt, qual_yn: amt == null });
  test('근속 연수 — 나열은 가장 작은 값, 연도 숫자는 연수가 아니다', () => {
    assert.deepEqual(facetOf(it('CREATIVE WEEK', '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가')).tenure, { years: 3 });
    assert.deepEqual(facetOf(it('근속 포상', '5, 10, 15, 20년 근속 포상')).tenure, { years: 5 });
    assert.deepEqual(facetOf(it('리프레시 플러스 휴가', '2년 근속 시 15일 추가 유급휴가')).tenure, { years: 2 });
    assert.deepEqual(facetOf(it('근속 기념 선물', '근속 10주년/20주년 선물 지급')).tenure, { years: 10 });
    assert.deepEqual(facetOf(it('장기근속 포상', '장기근속자 포상 (2025년 보고서)')).tenure, { years: null });
  });
  test('수집 메모(「… 미기재」)의 「근속」은 조건이 아니다', () => {
    assert.equal(facetOf(it('주택 담보 대출', '무이자 대출 (공식 페이지 — 대출 한도·근속 요건 미기재)')).tenure, null);
  });
  test('가족 언급 · 최대/한도', () => {
    assert.equal(facetOf(it('단체상해보험', '직원 및 가족 단체상해보험', 30)).familyMention, true);
    assert.equal(facetOf(it('어학', '연간 최대 240만원 어학 교육비', 240)).capped, true);
    assert.equal(facetOf(it('어학', '연간 최대 240만원 어학 교육비')).capped, false, '정성 행은 상한 표식이 없다');
    assert.equal(cappedRows(items(G.naver)).length, 3);
  });
  test('근속 미입력이면 판정하지 않는다(받는 중/아직 없음)', () => {
    const g = tenureGate(items(G.naver), items(G.kakao), null);
    assert.equal(g.tenureYears, null);
    assert.deepEqual([g.earned.length, g.pending.length, g.unjudged.length], [0, 0, 3]);
    assert.equal(tenureItems(items(G.naver)).length, 3);
  });
  test('법정 행(legal_yn)은 짝짓기·카테고리·근속·항목 수에서 빠진다', () => {
    const a = items(G.naver).concat([{ benefit_cd: 'parenting2', benefit_nm: '육아휴직', qual_yn: true, benefit_amt: null, benefit_ctgr_cd: 'family', legal_yn: true, checked: false }]);
    const p = classifyPairs(a, items(G.kakao));
    assert.equal(p.onlyA.length, 12);
    assert.equal(p.legal.a.length, 1);
    const fam = catProfile(a, items(G.kakao), NOW_CALC).find((c) => c.ctgr === 'family');
    assert.equal(fam.cntA, 3);
  });
});

describe('CALC-WLB 워라밸 축 순서(시간 → 통근 → 자율성 → 등록 수)', () => {
  const qual = (cd, ctgr) => ({ benefit_cd: cd, benefit_nm: cd, qual_yn: true, benefit_amt: null, amt_source: 'none', benefit_ctgr_cd: ctgr, checked: true });
  const st = (a, b, over = {}) => ({
    salStr: '5000-5000', selectedRate: 5, benS: { a, b },
    wsState: { a: { remote: true, flex: true }, b: { remote: true, flex: true } },
    com: { a: 0, b: 0 }, commuteIn: { a: null, b: null }, tenureYears: null, curPri: 'wlb', matched: { a: null, b: null }, ...over,
  });
  const leave = (n, p) => Array.from({ length: n }, (_, i) => qual(p + i, 'time_off'));
  test(`등록 수 차이가 문턱(${AXIS_THRESHOLDS.wlbQualCount}) 미만이면 말할 수 없음, 이상이면 많은 쪽`, () => {
    const k = AXIS_THRESHOLDS.wlbQualCount;
    const below = compare(st(leave(k - 1, 'x'), []), NOW_CALC);
    assert.equal(below.axes.wlb.tier, 'unsure');
    const at = compare(st(leave(k, 'x'), []), NOW_CALC);
    assert.equal(at.axes.wlb.tier, 'a');
    assert.equal(at.axes.wlb.decidedBy, 'count');
  });
  test('주 근무시간 차(2h 이상)가 있으면 등록 수보다 먼저 결론', () => {
    const r = compare(st([], leave(5, 'y'), { wsState: { a: { hours: 52, remote: true, flex: true }, b: { hours: 45, remote: true, flex: true } } }), NOW_CALC);
    assert.equal(r.axes.wlb.decidedBy, 'hours');
    assert.equal(r.axes.wlb.tier, 'b');
  });
  test('통근 연 40시간 이상 차이 — 시간이 같을 때 2순위', () => {
    const r = compare(st([], [], { commuteIn: { a: 60, b: 50 } }), NOW_CALC);
    assert.equal(r.axes.wlb.decidedBy, 'commute');
    assert.equal(r.axes.wlb.tier, 'b');
  });
});

describe('CALC-HWC hourlyWithCommute', () => {
  test('통근은 분모에만(시간당 가치가 줄어든다) · 미입력이면 null', () => {
    assert.equal(hourlyWithCommute(9018, 932, 45, 40), 37406);
    assert.equal(hourlyWithCommute(9018, 932, 45, null), null);
    assert.equal(hourlyWithCommute(9018, 932, 0, 40), null);
  });
});

describe('CALC-SURF 산출 묶음 구성(calculatorExtras = compare 의 덧붙임)', () => {
  test('compare 결과의 새 키는 calculatorExtras 가 만든 것과 같다(timeSheet·wageScenarios·sensitivity·robustness·askList·buildAllVdCards 경유)', () => {
    const st = goldenState();
    const core = compareCore(st, NOW_CALC);
    const ex = calculatorExtras(st, core, NOW_CALC);
    const full = compare(st, NOW_CALC);
    for (const k of ['band', 'pairs', 'parts', 'cat', 'time', 'robust', 'sens', 'wage', 'tenure', 'breakeven', 'ask', 'axes', 'basis']) {
      assert.deepEqual(full[k], ex[k], k);
    }
    assert.deepEqual(timeSheet(core, st.commuteIn), ex.time);
    assert.equal(wageScenarios(st, core, NOW_CALC), null);
    assert.deepEqual(sensitivity(st, core, NOW_CALC).rows.map((r) => r.key), ex.sens.rows.map((r) => r.key));
    assert.equal(robustness(st, core, NOW_CALC).exMixed.diff, -1355);
    assert.equal(askList(core, { sens: ex.sens, wage: null, pairs: ex.pairs }).length, 3);
    assert.equal(buildAllVdCards({ core: { ...core, _benA: st.benS.a, _benB: st.benS.b }, band: ex.band.delta, parts: ex.parts, pairs: ex.pairs, time: ex.time, robust: { ...ex.robust }, sens: ex.sens, wage: null, tenure: ex.tenure, now: NOW_CALC }).salary.d, -2211);
  });
});

// ── 적대 검증(2026-09-23 VERIFY-REPORT) 재현 쌍 — 보고서의 실제 쌍·입력 그대로 ─────────────────────
// 공통 입력: 현재 연봉 6,000 · +10% · A 주 45h 비포괄 · B 주 54h 포괄 · 통근 40/60분 · 근속 3년 · now 2026-09-23.
const VP = JSON.parse(readFileSync(join(HERE, '../../test/fixtures/calc-verify-pairs.json'), 'utf8'));
const NOW_VERIFY = Date.parse('2026-09-23T00:00:00+09:00');
const vpc = (nm) => VP.companies.find((c) => c.comp_nm === nm);
// 앱의 조립(assembleCompareState)과 같다: 전부 체크 · 법정 행은 legal_yn + checked:false(SP-LEGAL-5).
function verifyState(an, bn, o = {}) {
  const side = (c) => c.benefits.map((b) => (isLegalRow(c.comp_eng_nm, b.benefit_cd, b.benefit_nm) ? { ...b, legal_yn: true, checked: false } : { ...b, checked: true }));
  const A = vpc(an), B = vpc(bn);
  const sal = o.sal ?? 6000;
  const ws = (c) => ({ remote: !!(c.work_style_val && c.work_style_val.remote), flex: !!(c.work_style_val && c.work_style_val.flex) });
  return {
    salStr: sal + '-' + sal, selectedRate: o.rate ?? 10, benS: { a: side(A), b: side(B) },
    wsState: { a: { ot: 'mid', hours: 45, wage: 'separate', ...ws(A), ...(o.wsA || {}) }, b: { ot: 'high', hours: 54, wage: 'inclusive', ...ws(B), ...(o.wsB || {}) } },
    com: { a: 40, b: 60 }, commuteIn: { a: 40, b: 60 }, tenureYears: o.tenure ?? 3, curPri: 'salary', curSacrifice: null,
    matched: { a: A, b: B },
  };
}

describe('CALC-UNSURE 「판단하기 어렵다」의 원인(MED-1)', () => {
  test('unsureCause: 오차 범위 안이면 band · 범위 밖인데 부호가 갈리면 guard · 둘 다면 band · 아니면 null', () => {
    assert.equal(unsureCause(870, 319.9, -80), 'guard');
    assert.equal(unsureCause(-300, 452, 100), 'band', '둘 다 맞으면 오차 범위가 충분한 이유다');
    assert.equal(unsureCause(-300, 452), 'band');
    assert.equal(unsureCause(-2000, 100, -300), null);
    assert.equal(unsureCause(0, 0), null, '폭 0 · 차이 0 은 near 다');
  });
  test('verdictTier 가 unsure ⇔ unsureCause 가 원인을 낸다(격자 전수)', () => {
    for (const d of [-900, -452, -300, 0, 120, 452, 453, 900]) {
      for (const band of [0, 100, 452]) {
        for (const g of [null, -500, 0, 500]) {
          assert.equal(verdictTier(d, band, 9000, g) === 'unsure', unsureCause(d, band, g) != null, `d=${d} band=${band} g=${g}`);
        }
      }
    }
  });
  test('CJ올리브네트웍스 → 더블유게임즈: d +870 · 폭 ±320 · 가드 −80 → 연봉 축 unsure 의 원인은 guard(오차 범위는 겹치지 않는다)', () => {
    const r = compare(verifyState('CJ올리브네트웍스', '더블유게임즈'), NOW_VERIFY);
    assert.equal(r.axes.salary.d, 870);
    assert.equal(Math.round(r.axes.salary.band), 320);
    assert.equal(r.robust.exMixed.diff, -80);
    assert.equal(r.axes.salary.tier, 'unsure');
    assert.equal(r.axes.salary.unsureBy, 'guard');
    assert.equal(r.robust.full.unsureBy, 'guard');
  });
  test('CJ올리브네트웍스 → 롯데케미칼: 복지 축 d −240 · 폭 ±173 · 가드 +10 → unsure(guard)', () => {
    const v = compare(verifyState('CJ올리브네트웍스', '롯데케미칼'), NOW_VERIFY).axes.benefits;
    assert.equal(v.d, -240);
    assert.equal(Math.round(v.band), 173);
    assert.equal(v.exMixed.diff, 10);
    assert.equal(v.tier, 'unsure');
    assert.equal(v.unsureBy, 'guard');
    assert.equal(v.exMixed.tier, 'unsure', '빼고 계산한 값 +10 도 오차 범위 안');
  });
});

describe('CALC-ONE 티어 원천은 하나(MED-2 · LOW-12)', () => {
  test('CJ올리브네트웍스 → CJ ENM 커머스부문: 카드·튼튼함·감도가 모두 가드 포함 unsure — 감도 줄은 「뒤집힘」이 아니라 「말할 수 있게 됨」', () => {
    const r = compare(verifyState('CJ올리브네트웍스', 'CJ ENM 커머스부문'), NOW_VERIFY);
    assert.equal(r.axes.salary.d, -332);
    assert.equal(r.robust.exMixed.diff, 168);
    assert.equal(r.axes.salary.baseTier, 'unsure');
    assert.equal(r.robust.full.tier, 'unsure');
    assert.equal(r.sens.baseTier, 'unsure');
    assert.equal(r.robust.exMixed.tier, 'near', '빼면 방향은 바뀌지만 차이가 작다');
    const w = r.sens.rows.find((x) => x.key === 'b_wage_flip');
    assert.equal(w.result, 'decide');
    assert.equal(w.flips, false);
    assert.equal(w.decides, true);
    assert.equal(r.axes.salary.flip.key, 'b_wage_flip');
  });
  test('재현 쌍 12곳 × 11곳 전부: robust.full.tier === salary.baseTier === sens.baseTier', () => {
    const names = VP.companies.map((c) => c.comp_nm);
    let n = 0;
    for (const a of names) {
      for (const b of names) {
        if (a === b) continue;
        const r = compare(verifyState(a, b), NOW_VERIFY);
        assert.equal(r.robust.full.tier, r.axes.salary.baseTier, a + ' → ' + b);
        assert.equal(r.sens.baseTier, r.axes.salary.baseTier, a + ' → ' + b);
        for (const row of r.sens.rows) assert.ok(!(row.flips && !['a', 'b'].includes(r.sens.baseTier)), '방향 없는 기준에서 「뒤집힘」은 없다');
        n += 1;
      }
    }
    assert.equal(n, 132);
  });
  test('NAVER → NAVER(같은 회사): 기준이 오차 범위 안(unsure)이면 비포괄 가정은 「결론 바뀜」이 아니라 「말할 수 있게 됨」', () => {
    const r = compare(verifyState('NAVER', 'NAVER'), NOW_VERIFY);
    assert.equal(r.sens.baseTier, 'unsure');
    assert.equal(r.sens.rows.find((x) => x.key === 'b_wage_flip').result, 'decide');
  });
  test('기준이 방향이면 반대 방향 줄은 여전히 flip(골든 NAVER → 카카오)', () => {
    const r = compare(goldenState(), NOW_CALC);
    assert.equal(r.sens.rows.find((x) => x.key === 'b_wage_flip').result, 'flip');
  });
});

describe('CALC-WAGE 야근수당 미선택 — 「달라진다」는 부호가 갈릴 때만(MED-3)', () => {
  test('CJ올리브네트웍스 → LG디스플레이(B 54h 미선택): 포괄 near +518 · 비포괄 b +3,389 → 같은 방향이라 range', () => {
    const r = compare(verifyState('CJ올리브네트웍스', 'LG디스플레이', { wsB: { wage: null } }), NOW_VERIFY);
    assert.deepEqual(r.wage.cases.map((c) => [c.wage.b, c.tier, c.diff]), [['inclusive', 'near', 518], ['separate', 'b', 3389]]);
    assert.equal(r.wage.dir, 1);
    assert.deepEqual(r.wage.span, [518, 3389]);
    assert.equal(r.axes.salary.tier, 'range');
    assert.equal(r.axes.salary.shape, 'same');
  });
  test('골든 NAVER → 카카오(B 미선택): 포괄 −2,211 · 비포괄 +791 → 부호가 갈려 depends', () => {
    const st = goldenState({ wsState: { ...goldenState().wsState, b: { ot: 'high', hours: 54, wage: null } } });
    const r = compare(st, NOW_CALC);
    assert.equal(r.wage.dir, 0);
    assert.equal(r.axes.salary.tier, 'depends');
  });
});

describe('CALC-NEAR 「결론이 얼마나 확실한가」 재료 — near 쌍(LOW-10)', () => {
  test('리메드 → CJ올리브네트웍스: +148(±144) 은 near(small) — 튼튼함 ① 도 같은 near', () => {
    const r = compare(verifyState('리메드', 'CJ올리브네트웍스'), NOW_VERIFY);
    assert.equal(r.axes.salary.tier, 'near');
    assert.equal(r.axes.salary.nearKind, 'small');
    assert.equal(r.robust.full.tier, 'near');
  });
});

describe('CALC-BEB 같아지는 연봉의 범위 표식(MED-4)', () => {
  test('BREAKEVEN_BOUNDS 는 동결된 설계 상수 — 현재 연봉의 절반 미만 · 두 배 초과', () => {
    assert.equal(Object.isFrozen(BREAKEVEN_BOUNDS), true);
    assert.deepEqual({ ...BREAKEVEN_BOUNDS }, { low: 0.5, high: 2 });
  });
  test('리메드 → NAVER(현재 연봉 2,500): 등록 그대로 −10만원 → low · 한쪽만 등록 제외 422 → low · 복지 0 은 2,888 → 범위 안', () => {
    const be = compare(verifyState('리메드', 'NAVER', { sal: 2500 }), NOW_VERIFY).breakeven;
    assert.deepEqual([be.full.sal, be.full.bound], [-10, 'low']);
    assert.deepEqual([be.exMixed.sal, be.exMixed.bound], [422, 'low']);
    assert.deepEqual([be.noBenefit.sal, be.noBenefit.bound], [2888, null]);
  });
  test('카카오 → NAVER(2,500): 709만원(−71.6%)도 절반 미만 → low', () => {
    assert.equal(compare(verifyState('카카오', 'NAVER', { sal: 2500 }), NOW_VERIFY).breakeven.full.bound, 'low');
  });
  test('반대 방향 상한 — NAVER → 리메드(2,500): 5,786만원(+131%) → high', () => {
    const be = compare(verifyState('NAVER', '리메드', { sal: 2500 }), NOW_VERIFY).breakeven;
    assert.deepEqual([be.full.sal, be.full.bound], [5786, 'high']);
  });
  test('골든(6,000)은 세 눈금 모두 범위 안', () => {
    const be = compare(goldenState(), NOW_CALC).breakeven;
    assert.deepEqual([be.full.bound, be.exMixed.bound, be.noBenefit.bound], [null, null, null]);
  });
});
