#!/usr/bin/env node
// infra/tools/calc_thresholds.mjs — 이직 계산기 판정 문턱 실측(SPEC 05 §15.7 SP-MOVE-9, 2026-09-23).
//
// 쓰임: 참조 번들을 파일로 받아 두고 이 스크립트에 넘긴다(라이브 도메인을 헤드리스로 치면 봇 방어가 403).
//   curl -s http://127.0.0.1:8000/api/v1/reference/all -o /tmp/bundle.json
//   node infra/tools/calc_thresholds.mjs /tmp/bundle.json [--now 2026-09-23]
//
// 무엇을 재나 — `AXIS_THRESHOLDS` 중 **등록 데이터로 잴 수 있는 것**만(주 근무시간 2h·통근 연 40h 는
// 사용자 입력이라 대상이 아니다):
//   1) wlbQualCount — 휴가·근무제도(time_off+flexibility) 등록 항목 수. 회사별 분포와 전 순서쌍의 차이 분포,
//      시간·통근을 넣지 않은 사용자(워라밸 축이 3·4순위까지 내려가는 경우)에서 문턱별 「등록 수로 결론」 비율.
//   2) nearBandMult · nearTotalPct — 대표 입력 시나리오 5개에서 연봉 축·복지 축의 티어 분포
//      (말할 수 없음 / 거의 같음 / 방향)를 후보 값마다.
// 엔진은 calc.js 그대로 쓴다(공식을 여기 다시 적지 않는다). 법정 행은 앱과 같이 legal.js 로 표시한다.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const calc = await import(join(ROOT, 'web', 'assets', 'js', 'calc.js'));
const { isLegalRow } = await import(join(ROOT, 'web', 'assets', 'js', 'legal.js'));
const { compare, verdictTier, AXIS_THRESHOLDS } = calc;

const bundlePath = process.argv[2];
if (!bundlePath) { console.error('usage: node infra/tools/calc_thresholds.mjs <bundle.json> [--now YYYY-MM-DD]'); process.exit(2); }
const nowArg = process.argv.indexOf('--now');
const NOW = nowArg > 0 ? Date.parse(process.argv[nowArg + 1] + 'T00:00:00+09:00') : Date.now();
const bundle = JSON.parse(readFileSync(bundlePath, 'utf8'));
const companies = bundle.companies;

const items = (c) => c.benefits.map((b) => {
  const legal = isLegalRow(c.comp_eng_nm, b.benefit_cd, b.benefit_nm);
  return { ...b, checked: !legal, legal_yn: legal || undefined };
});
const LIST = new Map(companies.map((c) => [c.comp_id, items(c)]));

const pct = (n, d) => (d ? (100 * n / d).toFixed(1) + '%' : '-');
const quant = (arr, q) => { const s = [...arr].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(q * s.length))]; };

// ── 1) wlbQualCount ──────────────────────────────────────────────────────────
const wlbCnt = (list) => list.filter((it) => !it.legal_yn && (it.benefit_ctgr_cd === 'time_off' || it.benefit_ctgr_cd === 'flexibility')).length;
const perCo = companies.map((c) => wlbCnt(LIST.get(c.comp_id)));
const hist = {};
for (const n of perCo) hist[n] = (hist[n] || 0) + 1;
console.log('# 1. 휴가·근무제도 등록 항목 수(회사별, 법정 제외)');
console.log('  회사 수', companies.length, '· 분포', JSON.stringify(hist), '· 중앙값', quant(perCo, 0.5), '· p90', quant(perCo, 0.9));

const pairs = [];
for (const a of companies) for (const b of companies) if (a.comp_id !== b.comp_id) pairs.push([a, b]);
const diffs = pairs.map(([a, b]) => Math.abs(wlbCnt(LIST.get(a.comp_id)) - wlbCnt(LIST.get(b.comp_id))));
const dh = {};
for (const d of diffs) dh[d] = (dh[d] || 0) + 1;
console.log('  순서쌍', pairs.length, '· |차이| 분포', JSON.stringify(dh));
for (const k of [1, 2, 3, 4]) console.log(`  문턱 ${k}: 차이 ≥ ${k} 인 쌍 ${pct(diffs.filter((d) => d >= k).length, diffs.length)}`);

// 워라밸 축이 등록 수까지 내려가는 사용자(시간·통근 미입력): 자율성으로 갈리지 않은 쌍 중 문턱별 결론 비율.
const autoOf = (c) => {
  const w = c.work_style_val || {};
  return [w.remote ? '재택근무' : null, w.flex ? '유연근무' : null, w.unlimitedPTO ? '무제한휴가' : null].filter(Boolean);
};
const strictSuper = (A, B) => B.every((x) => A.includes(x)) && A.length > B.length;
let reach = 0; const byK = { 1: 0, 2: 0, 3: 0, 4: 0 };
for (const [a, b] of pairs) {
  const A = autoOf(a), B = autoOf(b);
  if (strictSuper(A, B) || strictSuper(B, A)) continue; // 3순위(자율성)에서 이미 갈렸다
  reach += 1;
  const d = Math.abs(wlbCnt(LIST.get(a.comp_id)) - wlbCnt(LIST.get(b.comp_id)));
  for (const k of [1, 2, 3, 4]) if (d >= k) byK[k] += 1;
}
console.log(`  현행 wlbQualCount = ${AXIS_THRESHOLDS.wlbQualCount}`);
console.log(`  시간·통근 미입력 + 자율성 동률 쌍 ${reach}(${pct(reach, pairs.length)}) 중 등록 수로 결론 나는 비율:`,
  Object.entries(byK).map(([k, n]) => `≥${k} ${pct(n, reach)}`).join(' · '));

// ── 2) nearBandMult · nearTotalPct ─────────────────────────────────────────
const SCEN = [
  { id: 'S1', label: '6,000 · +10% · 양쪽 주 45h 비포괄', sal: 6000, rate: 10, a: { hours: 45, wage: 'separate' }, b: { hours: 45, wage: 'separate' } },
  { id: 'S2', label: '6,000 · +10% · 야근 미입력', sal: 6000, rate: 10, a: {}, b: {} },
  { id: 'S3', label: '4,000 · +5% · 야근 미입력', sal: 4000, rate: 5, a: {}, b: {} },
  { id: 'S4', label: '9,000 · +15% · A 45h 비포괄 → B 54h 포괄', sal: 9000, rate: 15, a: { hours: 45, wage: 'separate' }, b: { hours: 54, wage: 'inclusive' } },
  { id: 'S5', label: '6,000 · 0%(연봉 동결 이동) · 야근 미입력', sal: 6000, rate: 0, a: {}, b: {} },
];
const MULTS = [1.0, 1.5, 2.0];
const AXIS_LABEL = { sal: '연봉 축(기준 = 현재 총보상)', benNet: '복지 축(기준 = 복지 금액 합 큰 쪽, 채택)', benTotal: '복지 축(기준 = 현재 총보상, 기각)' };
const PCTS = [0.01, 0.03, 0.05, 0.10];
console.log('\n# 2. 티어 분포 — 순서쌍', pairs.length, '· 칸 = 말할 수 없음 / 거의 같음 / 방향 (현행 값 ★)');
const rows = [];
for (const s of SCEN) {
  const obs = [];
  for (const [a, b] of pairs) {
    const r = compare({
      salStr: s.sal + '-' + s.sal, selectedRate: s.rate,
      benS: { a: LIST.get(a.comp_id), b: LIST.get(b.comp_id) },
      wsState: { a: { ...s.a, remote: false, flex: false }, b: { ...s.b, remote: false, flex: false } },
      com: { a: 0, b: 0 }, commuteIn: { a: null, b: null }, tenureYears: null,
      curPri: 'salary', curSacrifice: null, matched: { a, b },
    }, NOW);
    obs.push({
      sal: { d: r.deltas.totalDiff, band: r.band.delta, base: r.a.total, guard: r.robust.exMixed ? r.robust.exMixed.diff : null },
      // 복지 축 기준값: 채택 = 복지 금액 합(큰 쪽) · 비교용 = 현재 총보상(기각 — 연봉 렌즈가 섞인다)
      benNet: { d: r.deltas.benDiff, band: r.band.delta, base: Math.max(r.a.net, r.b.net), guard: r.axes.benefits.exMixed ? r.axes.benefits.exMixed.diff : null },
      benTotal: { d: r.deltas.benDiff, band: r.band.delta, base: r.a.total, guard: r.axes.benefits.exMixed ? r.axes.benefits.exMixed.diff : null },
    });
  }
  console.log(`\n## ${s.id} ${s.label}`);
  for (const axis of ['sal', 'benNet', 'benTotal']) {
    const guardUnsure = obs.filter((o) => o[axis].guard != null && Math.sign(o[axis].guard) !== Math.sign(o[axis].d)).length;
    const bandUnsure = obs.filter((o) => o[axis].band > 0 && Math.abs(o[axis].d) <= o[axis].band).length;
    console.log(`  [${AXIS_LABEL[axis]}] 가드(부호 갈림) ${pct(guardUnsure, obs.length)} · 폭 안 ${pct(bandUnsure, obs.length)} · |d| 중앙값 ${Math.round(quant(obs.map((o) => Math.abs(o[axis].d)), 0.5))}만원 · 폭 중앙값 ${Math.round(quant(obs.map((o) => o[axis].band), 0.5))}만원`);
    for (const m of MULTS) {
      const cells = PCTS.map((p) => {
        const T = { ...AXIS_THRESHOLDS, nearBandMult: m, nearTotalPct: p };
        const c = { unsure: 0, near: 0, dir: 0 };
        for (const o of obs) {
          const t = verdictTier(o[axis].d, o[axis].band, o[axis].base, o[axis].guard, T);
          c[t === 'unsure' ? 'unsure' : t === 'near' ? 'near' : 'dir'] += 1;
        }
        const star = m === AXIS_THRESHOLDS.nearBandMult && p === AXIS_THRESHOLDS.nearTotalPct ? '★' : ' ';
        rows.push({ s: s.id, axis, m, p, ...c, n: obs.length });
        return `${star}${(p * 100).toFixed(0)}% ${pct(c.unsure, obs.length)}/${pct(c.near, obs.length)}/${pct(c.dir, obs.length)}`;
      });
      console.log(`    ×${m.toFixed(1)}  ` + cells.join('   '));
    }
  }
}

// 현행 값에서 「거의 같음」이 몇 %인가 — 한 줄 요약(SPEC 05 에 옮겨 적는 값).
const cur = rows.filter((r) => r.m === AXIS_THRESHOLDS.nearBandMult && r.p === AXIS_THRESHOLDS.nearTotalPct);
console.log('\n# 요약(현행 ★) — 시나리오별 거의 같음 비율');
for (const r of cur) console.log(`  ${r.s} ${AXIS_LABEL[r.axis]}: 말할 수 없음 ${pct(r.unsure, r.n)} · 거의 같음 ${pct(r.near, r.n)} · 방향 ${pct(r.dir, r.n)}`);
