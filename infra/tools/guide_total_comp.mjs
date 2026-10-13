// infra/tools/guide_total_comp.mjs — 가이드 B편 「복지를 연봉에 더해 보는 법」 예시 숫자 생성기 (SP-GUIDE-10, 2026-10-13).
//
// 예시 입력은 `generator/data/guide/total-compensation.json` 의 `input` 이 정본이다(이 파일에 숫자를 박지 않는다).
// 이 스크립트는 그 입력을 이직 계산기(`web/assets/js/calc.js`)에 넣어 나온 값을 JSON 의 `output` · `K` 에 다시 쓴다.
// 빌드(파이썬)는 JSON 만 읽는다 — 빌드에 node 를 들이지 않는다.
//
//   node infra/tools/guide_total_comp.mjs          # output · K 를 다시 쓴다(input 은 손대지 않는다)
//
// `computeExample` 은 프런트 테스트(`web/test/guide-total-comp.test.js`)가 같은 계산을 다시 돌리려고 가져다 쓴다
// — 계산 함수가 하나라서 스크립트와 테스트가 어긋나지 않는다.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import * as C from '../../web/assets/js/calc.js';

export const JSON_PATH = fileURLToPath(new URL('../../generator/data/guide/total-compensation.json', import.meta.url));

function item(b, expires) {
  return {
    checked: true, benefit_nm: b.name, benefit_amt: b.amount, qual_yn: b.amount == null,
    amt_source: b.amount == null ? 'none' : b.source, benefit_ctgr_cd: b.category,
    expires_dtm: expires, benefit_cd: b.name, badge_cd: 'official',
  };
}

export function stateOf(input) {
  const ben = (s) => input.benefits[s].map((b) => item(b, input.expires));
  return {
    salStr: input.salary, selectedRate: input.raise_pct,
    wsState: { a: { ...input.work.a }, b: { ...input.work.b } },
    benS: { a: ben('a'), b: ben('b') },
    com: { ...input.commute_min }, commuteIn: { ...input.commute_min }, matched: { a: null, b: null },
    curPri: input.priority, curSacrifice: null, tenureYears: input.tenure_years,
  };
}

/** 입력 → { output, K }. 키 순서를 정렬해 결정적으로 만든다(생성 시각 없음). */
export function computeExample(input) {
  const now = Date.parse(input.now);
  const state = stateOf(input);
  const core = C.compareCore(state, now);
  const r = C.compare(state, now);
  const side = (s) => ({
    band: core[s].sumBand, hourly: core[s].hourly, hours: core[s].wsHours,
    net: core[s].net, ot: core[s].otPay, sal: core[s].salRange.mid, total: core[s].total,
  });
  const sal = r.axes.salary;
  const flip = sal.flip ? { result: sal.flip.result, totalDiff: sal.flip.totalDiff, key: sal.flip.key } : null;
  const output = {
    a: side('a'), b: side('b'),
    breakeven: {
      full: r.breakeven.full, noBenefit: r.breakeven.noBenefit,
    },
    deltas: core.deltas,
    hourlyPct: r.time.hourly.pct,
    monthly: sal.monthly,
    range: sal.range,
    tier: sal.tier,
    flip,
  };
  const K = {
    AXIS_THRESHOLDS: { ...C.AXIS_THRESHOLDS }, BAND_BASE: { ...C.BAND_BASE }, BAND_EXPIRE: C.BAND_EXPIRE,
    COMMUTE_WORKDAYS: C.COMMUTE_WORKDAYS, LEGAL_WEEK_HRS: C.LEGAL_WEEK_HRS, MONTHLY_STD_HRS: C.MONTHLY_STD_HRS,
    OT_MULT: C.OT_MULT, WEEKS_PER_MONTH: C.WEEKS_PER_MONTH, WEEKS_PER_YEAR: C.WEEKS_PER_YEAR,
  };
  return JSON.parse(JSON.stringify({ output, K }));
}

/** 키 정렬 직렬화(들여쓰기 2 · 끝 줄바꿈 하나). */
export function dumps(obj) {
  const sort = (v) => {
    if (Array.isArray(v)) return v.map(sort);
    if (v && typeof v === 'object') return Object.fromEntries(Object.keys(v).sort().map((k) => [k, sort(v[k])]));
    return v;
  };
  return JSON.stringify(sort(obj), null, 2) + '\n';
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const doc = JSON.parse(readFileSync(JSON_PATH, 'utf8'));
  const { output, K } = computeExample(doc.input);
  writeFileSync(JSON_PATH, dumps({ input: doc.input, output, K }));
  console.log(`wrote ${JSON_PATH}`);
}
