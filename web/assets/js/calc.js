// web/assets/js/calc.js — SP-ENGINE 비교 계산 엔진 (순수 ES 모듈).
// 근거: SPEC/05-비교-계산엔진.md(SP-ENGINE-1~17), TASK/05-계산엔진.md.
//
// 불변 계약(INV-4, 테스트로 강제 — T-ENGINE-45):
//  1) 부수효과 0: document/window/fetch/localStorage/XMLHttpRequest/전역 미접근.
//     모든 입력은 인자, 모든 출력은 반환값.
//  2) 결정성: 동일 입력 → 동일 출력. 시간 의존(만료 판정)은 now 인자로 주입
//     (Date.now()는 오케스트레이터의 기본 매개변수에서만 바인딩).
//  3) 불변 입력: 인자 객체를 mutate하지 않는다. 항상 새 객체를 반환한다.
//  4) 참조 데이터(companyTypes)는 인자로 주입받는다.
//  5) 필수값 결측은 throw 대신 missing[]/null로 표기한다.
//
// 프로파일러 벡터(pfResult 등)는 본 모듈 어디에서도 참조하지 않는다(§16, 01 §5.1).

// ─────────────────────────────────────────────────────────────────────
// 타입 정의 (JSDoc @typedef) — SP-ENGINE-2
// ─────────────────────────────────────────────────────────────────────

/** @typedef {{ min:number, max:number, mid:number }} Range  // 만원 정수, min≤max */

/** @typedef {'compensation'|'flexibility'|'work_env'|'time_off'|'health'
 *          |'family'|'growth'|'leisure'|'perks'} CtgrCode */

/** @typedef {{
 *   benefit_cd:   string,
 *   benefit_nm:   string,
 *   benefit_amt:  number|null,          // 만원. 정성이면 null
 *   benefit_ctgr_cd: CtgrCode,
 *   badge_cd:     'official'|'est',      // 출처 신뢰도(밴드에 미사용, DEC-2)
 *   amt_source:   'stated'|'estimated'|'none',  // 밴드 기준(금액 신뢰도)
 *   checked:      boolean,               // 체크 안 하면 전 합산 제외
 *   qual_yn:      boolean,               // true=정성(금액 없음)
 *   expires_dtm:  string|null,           // ISO8601. 경과 시 밴드 +0.15
 *   qual_desc?:   string,                // 정성 설명(렌더 계층이 이스케이프)
 *   note_ctnt?:   string
 * }} BenefitItem */

/** @typedef {{
 *   ot:     'low'|'mid'|'high'|null,     // 야근 빈도 → 주간근무시간
 *   wage:   'inclusive'|'separate'|null, // 포괄/비포괄
 *   remote: 'none'|'partial'|'hybrid'|'free'|null,
 *   flex:   'none'|'stagger'|'flexible'|null
 * }} WorkStyle */

/** @typedef {{
 *   comp_id:    number|null,
 *   comp_nm:    string|null,
 *   comp_tp_cd: string|null,             // 기업유형 코드 → companyTypes 조회
 *   work_style_val: { unlimitedPTO?:boolean, remote?:boolean,
 *                     flex?:boolean, refreshLeave?:string }|null
 * }} SlotMeta */

/** @typedef {{
 *   comp_tp_cd:        string,
 *   growth_rate_val:   number,           // DECIMAL 예: 0.04 (연평균 상승률)
 *   growth_label_nm:   string,
 *   stability_score_no:number            // 1~100
 * }} CompanyType */

/** @typedef {'salary'|'wlb'|'benefits'|'brand'} PriKey */  // 엔진 정규 키(§2.1)

/** @typedef {{
 *   salStr:        string|null,          // 슬롯 a 연봉 "lo-hi"(만원). 예 "5000-7000"
 *   selectedRate:  number|null,          // 슬롯 b 상승률(%). b = a×(1+rate/100)
 *   benS:          { a:BenefitItem[], b:BenefitItem[] },
 *   wsState:       { a:WorkStyle, b:WorkStyle },
 *   com:           { a:number, b:number },  // 편도 통근(분) ≥0
 *   curPri:        PriKey,
 *   curSacrifice:  PriKey|null,           // ≠ curPri
 *   matched:       { a:SlotMeta|null, b:SlotMeta|null },
 *   companyTypes:  CompanyType[]          // REF.company_types (브랜드 축용)
 * }} CompareState */

/** @typedef {{
 *   salRange:  Range,        // FR-30
 *   ben:       number,       // 체크된 전 복지 합(만원) FR-31
 *   net:       number,       // 체크된 비정성 복지 합(순복지) FR-31
 *   eff:       Range,        // 실효연봉 = salRange + net  FR-32
 *   wsHours:   number,       // 주간근무시간(0=미입력) FR-33
 *   otPay:     number,       // 야근수당(만원/년, ≥0) FR-34
 *   total:     number,       // eff.mid + otPay  FR-34/32
 *   hourly:    number|null,  // 원/시간(null=미산출) FR-35
 *   autonomy:  number,       // 자율성 점수 FR-36
 *   sumBand:   number,       // ± 만원(불확실성) FR-38
 *   totalRange:[number,number], // [total-sumBand, total+sumBand]
 *   commuteMin:number        // 편도 분
 * }} SlotResult */

/** @typedef {{
 *   ok:        boolean,      // false면 필수값 결측(missing 참조)
 *   missing:   string[],     // 예 ['salary']
 *   a:         SlotResult,
 *   b:         SlotResult,
 *   deltas:    { effMid:number, effMin:number, effMax:number, salMid:number,
 *                totalDiff:number, hourlyDiff:number|null, benDiff:number },
 *   catDelta:  Array<{ ctgr:CtgrCode, sumA:number, sumB:number, delta:number }>,
 *   qual:      { a:Array<{benefit_nm,benefit_ctgr_cd,qual_desc}>,
 *                b:Array<{benefit_nm,benefit_ctgr_cd,qual_desc}> },
 *   commute:   { a:number, b:number, annA:number, annB:number, winner:'a'|'b'|'tie' },
 *   vdCard:    VdCard,       // FR-39
 *   sacrifice: SacrificeCost|null, // FR-39
 *   brand:     object,       // brandProjection 반환값
 *   rest:      Array<{ axis:PriKey, winner:'a'|'b'|'tie', value:object }>,
 *   warnings:  string[]      // 규칙 코드(문구 아님). 예 ['eff_shrink','both_inclusive']
 * }} Report */

/** @typedef {{ salRange:{a:Range,b:Range}, net:{a:number,b:number},
 *              eff:{a:Range,b:Range} }} LightSummary */  // calc() 경량 반환

/** @typedef {{ label:string, winner:'a'|'b'|'tie', detail:object }} VdPersp */
/** @typedef {{ axis:PriKey, p1:VdPersp, p2:VdPersp, tie:boolean }} VdCard */
/** @typedef {{ axis:PriKey, ok:boolean, detail:object }} SacrificeCost */

// ─────────────────────────────────────────────────────────────────────
// 상수 — SP-ENGINE-3
// ─────────────────────────────────────────────────────────────────────

export const OT_HRS          = { low: 40, mid: 45, high: 54 };      // 주당 총 근무시간(h)
export const LEGAL_WEEK_HRS  = 40;                                  // 법정 기준주(초과=연장근로)
export const REMOTE_SAVE     = { none: 0, partial: 72, hybrid: 120, free: 180 }; // 연간 통근절약(만원)
export const FLEX_BONUS      = 50;   // flex≠none 자율성 가산
export const PTO_BONUS       = 80;   // unlimitedPTO 자율성 가산
export const MONTHLY_STD_HRS = 209;  // 월 소정근로시간(통상시급 분모)
export const OT_MULT         = 1.5;  // 연장근로 가산율
export const WEEKS_PER_MONTH = 4.33; // 월 평균 주수
export const WEEKS_PER_YEAR  = 52;   // 연간 근무시간 환산
export const WON_PER_MANWON  = 10000;// 만원→원
export const COMMUTE_ROUND_TRIP = 2; // 왕복 계수
export const COMMUTE_WORKDAYS   = 240; // 연 근무일(통근 연환산)
export const WORKDAY_HRS     = 8;    // 근무일 환산(연시간→근무일)
export const PROJECTION_YEARS = 3;   // 브랜드 성장 투영 연수
export const BENEFIT_SAT_THRESHOLD = 1200; // 총보상 차 ≤이면 "복지 우선" 판단(만원)
export const GROWTH_RATE_FALLBACK  = 0.04; // company_types 조회 실패 시 상승률 폴백

// DEC-2 밴드 계수 — 금액 신뢰도(amt_source) 기준, 출처 배지와 디커플링(RESEARCH §4.2)
export const BAND_BASE   = { stated: 0.05, estimated: 0.20, none: 0 };
export const BAND_EXPIRE = 0.15;  // 만료 시 base에 가산(치환 아님)

export const BENEFIT_CATEGORIES = ['compensation', 'flexibility', 'work_env', 'time_off',
  'health', 'family', 'growth', 'leisure', 'perks']; // 9종 고정 순서

// ─────────────────────────────────────────────────────────────────────
// 4. 연봉 Range — SP-ENGINE-4 (FR-30)
// ─────────────────────────────────────────────────────────────────────

/** 슬롯 a 연봉 문자열 → Range. 미입력/파싱불가 → {0,0,0}. */
export function parseSalRange(salStr) {
  if (!salStr) return { min: 0, max: 0, mid: 0 };
  const parts = String(salStr).split('-');
  // 정확히 min-max 두 토큰만 허용(단일값·'1-2-3' 등 거부)
  if (parts.length !== 2) return { min: 0, max: 0, mid: 0 };
  const loStr = parts[0].trim();
  const hiStr = parts[1].trim();
  // 빈 토큰 명시 거부 — Number('')===0 함정 방지('100-'·'-'·'-100'이 0으로 둔갑하는 것 차단)
  if (loStr === '' || hiStr === '') return { min: 0, max: 0, mid: 0 };
  const lo = Number(loStr);
  const hi = Number(hiStr);
  if (!Number.isFinite(lo) || !Number.isFinite(hi)) return { min: 0, max: 0, mid: 0 };
  // 역전 범위(min>max) 거부(min==max 는 유효)
  if (lo > hi) return { min: 0, max: 0, mid: 0 };
  return { min: lo, max: hi, mid: Math.round((lo + hi) / 2) };
}

/** 슬롯 b 연봉 = 슬롯 a range × (1+rate/100). base 미입력·rate null → {0,0,0}. */
export function deriveOfferRange(baseRange, selectedRate) {
  if (!baseRange || !baseRange.min || selectedRate == null) return { min: 0, max: 0, mid: 0 };
  const mult = 1 + selectedRate / 100;
  return {
    min: Math.round(baseRange.min * mult),
    max: Math.round(baseRange.max * mult),
    mid: Math.round(baseRange.mid * mult),
  };
}

// ─────────────────────────────────────────────────────────────────────
// 5. 복지 합산·카테고리·정성 — SP-ENGINE-5 (FR-31)
// ─────────────────────────────────────────────────────────────────────

/** 슬롯 복지 합산. ben=체크 전 합, net=체크된 비정성 합(순복지). */
export function benTotal(list) {
  let ben = 0, net = 0;
  for (const b of (list || [])) {
    if (!b.checked) continue;
    const amt = Number(b.benefit_amt) || 0;   // 정성(null)→0
    ben += amt;
    if (!b.qual_yn) net += amt;
  }
  return { ben, net };
}

/** 카테고리별 합(체크·비정성만). 9종 전부 키 존재(미보유=0). */
export function benByCat(list) {
  const acc = Object.fromEntries(BENEFIT_CATEGORIES.map(c => [c, 0]));
  for (const b of (list || [])) {
    if (!b.checked || b.qual_yn) continue;
    const c = BENEFIT_CATEGORIES.includes(b.benefit_ctgr_cd) ? b.benefit_ctgr_cd : 'perks';
    acc[c] += Number(b.benefit_amt) || 0;
  }
  return acc;
}

/** 9카테고리 a·b 합산 + 델타(sumB−sumA). 미상 카테고리는 perks 폴백(FR-D8). */
export function benCatCompare(listA, listB) {
  const A = benByCat(listA), B = benByCat(listB);
  return BENEFIT_CATEGORIES.map(ctgr => ({
    ctgr, sumA: A[ctgr], sumB: B[ctgr], delta: B[ctgr] - A[ctgr],
  }));
}

/** 정성 항목(체크·qual_yn) a/b 목록. 금액 없이 설명 대비(원문은 렌더 계층이 이스케이프). */
export function qualCompare(listA, listB) {
  const pick = list => (list || [])
    .filter(b => b.checked && b.qual_yn)
    .map(b => ({ benefit_nm: b.benefit_nm, benefit_ctgr_cd: b.benefit_ctgr_cd, qual_desc: b.qual_desc || '' }));
  return { a: pick(listA), b: pick(listB) };
}

// ─────────────────────────────────────────────────────────────────────
// 6. 실효연봉 — SP-ENGINE-6 (FR-32)
// ─────────────────────────────────────────────────────────────────────

/** 실효연봉 = 연봉 range + 순복지(net). 세 값에 동일 가산. */
export function effSalary(salRange, net) {
  return { min: salRange.min + net, max: salRange.max + net, mid: salRange.mid + net };
}

// ─────────────────────────────────────────────────────────────────────
// 7. 주간 근무시간 — SP-ENGINE-7 (FR-33)
// ─────────────────────────────────────────────────────────────────────

/** 주간근무시간 = OT_HRS[ot]. ot 미선택(null) → 0(미입력). */
export function getWSHours(ws) { return OT_HRS[ws && ws.ot] || 0; }

// ─────────────────────────────────────────────────────────────────────
// 8. 야근수당 — 포괄/비포괄 분기 — SP-ENGINE-8 (FR-34)
// ─────────────────────────────────────────────────────────────────────

/** 야근수당(만원/년, ≥0). 포괄임금 or ot='low' → 0. 비포괄+야근 → 시급×1.5 기반. */
export function getOTPay(ws, salRange) {
  if (!ws || ws.wage !== 'separate' || ws.ot === 'low' || ws.ot == null) return 0;
  const mid = salRange && salRange.mid;
  if (!mid) return 0;                                          // 연봉 미입력 → 0
  const hourlyBase = mid * WON_PER_MANWON / 12 / MONTHLY_STD_HRS; // 통상시급(원)
  const extraHrs   = OT_HRS[ws.ot] - LEGAL_WEEK_HRS;              // 주당 연장근로(h)
  return Math.round(extraHrs * hourlyBase * OT_MULT * WEEKS_PER_MONTH * 12 / WON_PER_MANWON);
}

// ─────────────────────────────────────────────────────────────────────
// 9. 시간당 실질 가치 — SP-ENGINE-9 (FR-35)
// ─────────────────────────────────────────────────────────────────────

/** 시간당 가치(원). 분모(연간근무시간)=0이면 null(0나눗셈 방지). */
export function hourlyValue(effMid, otPay, wsHours) {
  const annHrs = wsHours * WEEKS_PER_YEAR;
  if (annHrs <= 0) return null;                                // 근무시간 미입력 → 미산출
  return Math.round((effMid + otPay) * WON_PER_MANWON / annHrs);
}

// ─────────────────────────────────────────────────────────────────────
// 10. 워라밸·자율성 — SP-ENGINE-10 (FR-36)
// ─────────────────────────────────────────────────────────────────────

/** 자율성 점수 = REMOTE_SAVE[remote] + (flex≠none?50) + (unlimitedPTO?80). */
export function autonomyScore(ws, slotMeta) {
  const remote = (ws && REMOTE_SAVE[ws.remote]) || 0;
  const flex   = (ws && ws.flex && ws.flex !== 'none') ? FLEX_BONUS : 0;
  const pto    = (slotMeta && slotMeta.work_style_val && slotMeta.work_style_val.unlimitedPTO)
    ? PTO_BONUS : 0;
  return remote + flex + pto;
}

// ─────────────────────────────────────────────────────────────────────
// 11. 통근 — SP-ENGINE-11 (FR-37)
// ─────────────────────────────────────────────────────────────────────

/** 편도 통근(분) a/b 비교 + 연환산 시간(round(min×2×240/60)). 더 짧은 쪽 winner. */
export function commuteCompare(comA, comB) {
  const ann = m => Math.round((m || 0) * COMMUTE_ROUND_TRIP * COMMUTE_WORKDAYS / 60); // 연간 시간
  const a = comA || 0, b = comB || 0;
  return { a, b, annA: ann(a), annB: ann(b), winner: a === b ? 'tie' : a < b ? 'a' : 'b' };
}

// ─────────────────────────────────────────────────────────────────────
// 12. 복지 불확실성 밴드 — DEC-2 — SP-ENGINE-12 (FR-38, INV-5)
// ─────────────────────────────────────────────────────────────────────

/** 항목 밴드 계수. 정성(none)→0. 만료면 base+0.15. now 주입(결정성).
 *  DEC-2 핵심: amt_source(금액 신뢰도)만 참조 — badge_cd(출처 배지)는 읽지 않는다(INV-5 디커플링). */
export function bandCoeff(item, now) {
  if (!item) return 0;
  const base = BAND_BASE[item.amt_source];
  if (base == null) return item.amt_source === 'none' ? 0 : BAND_BASE.estimated; // 미상→estimated 폴백
  if (item.amt_source === 'none') return 0;
  const expired = item.expires_dtm != null && Date.parse(item.expires_dtm) < now;
  return base + (expired ? BAND_EXPIRE : 0);
}

/** 체크·비정성 항목의 ± 절대 합(만원). = Σ |amt| × bandCoeff (항목별 산정 후 합산, 일괄 % 금지). */
export function sumBand(list, now) {
  return (list || [])
    .filter(b => b.checked && !b.qual_yn)
    .reduce((acc, b) => acc + (Number(b.benefit_amt) || 0) * bandCoeff(b, now), 0);
}

// ─────────────────────────────────────────────────────────────────────
// 13. 우선순위 판정 vdCard — SP-ENGINE-13 (FR-39)
// ─────────────────────────────────────────────────────────────────────

function vdSalary(m) {
  const diff = m.totalB - m.totalA;
  const p1 = {
    label: '총액', winner: diff > 0 ? 'b' : diff < 0 ? 'a' : 'tie',
    detail: { totalA: m.totalA, totalB: m.totalB, diff },
  };
  let p2;
  if (m.hourlyA != null && m.hourlyB != null) {
    const hd = m.hourlyB - m.hourlyA;
    const pct = Math.round(Math.abs(hd) / Math.min(m.hourlyA, m.hourlyB) * 100);
    p2 = {
      label: '시간당 가치', winner: hd > 0 ? 'b' : hd < 0 ? 'a' : 'tie',
      detail: { hourlyA: m.hourlyA, hourlyB: m.hourlyB, diff: hd, pct },
    };
  } else {
    p2 = { label: '시간당 가치', winner: 'tie', detail: { missing: true } };
  }
  return { axis: 'salary', p1, p2, tie: p1.winner === 'tie' && p2.winner === 'tie' };
}

function vdWlb(m) {
  const both = m.wsHoursA > 0 && m.wsHoursB > 0;
  const wd = Math.abs(m.wsHoursA - m.wsHoursB), annDiff = wd * WEEKS_PER_YEAR;
  const p1 = {
    label: '적게 일하기',
    winner: !both ? 'tie' : m.wsHoursA < m.wsHoursB ? 'a' : m.wsHoursB < m.wsHoursA ? 'b' : 'tie',
    detail: both
      ? { wsA: m.wsHoursA, wsB: m.wsHoursB, weekDiff: wd, annDiff, annDays: Math.round(annDiff / WORKDAY_HRS) }
      : { missing: true },
  };
  const p2 = {
    label: '시간 자율성',
    winner: m.autoA > m.autoB ? 'a' : m.autoB > m.autoA ? 'b' : 'tie',
    detail: { autoA: m.autoA, autoB: m.autoB },
  };
  return { axis: 'wlb', p1, p2, tie: p1.winner === 'tie' && p2.winner === 'tie' };
}

function vdBenefits(m) {
  const bd = m.benB - m.benA, td = m.totalB - m.totalA;
  const p1 = {
    label: '복지 항목', winner: bd < 0 ? 'a' : bd > 0 ? 'b' : 'tie',
    detail: { benA: m.benA, benB: m.benB },
  };
  const p2 = {
    label: '총보상 포함', winner: td > 0 ? 'b' : td < 0 ? 'a' : 'tie',
    detail: { totalA: m.totalA, totalB: m.totalB, diff: td, satisfy: Math.abs(td) < BENEFIT_SAT_THRESHOLD },
  };
  return { axis: 'benefits', p1, p2, tie: false };
}

function vdBrand(m) {
  const br = m.brand;
  const p1 = {
    label: '성장성',
    winner: br.cumDiff > 0 ? 'b' : br.cumDiff < 0 ? 'a' : 'tie',
    detail: { cumDiff: br.cumDiff, grA: br.grA, grB: br.grB, projA: br.projA, projB: br.projB },
  };
  const p2 = {
    label: '안정성',
    winner: br.stabA > br.stabB ? 'a' : br.stabB > br.stabA ? 'b' : 'tie',
    detail: { stabA: br.stabA, stabB: br.stabB },
  };
  return { axis: 'brand', p1, p2, tie: p1.winner === 'tie' && p2.winner === 'tie', limited: br.limited };
}

/** 4축 vdCard 판정. 승자·수치만 반환 — 문구·색은 SP-RPT가 구성. */
export function buildVdCard(axis, m) {
  switch (axis) {
    case 'salary':   return vdSalary(m);
    case 'wlb':      return vdWlb(m);
    case 'benefits': return vdBenefits(m);
    case 'brand':    return vdBrand(m);
    default:         return vdWlb(m);   // 안전 폴백(기본 워라밸)
  }
}

// ─────────────────────────────────────────────────────────────────────
// 13.4 브랜드 축 데이터 — SP-ENGINE-13b (FR-39)
// ─────────────────────────────────────────────────────────────────────

/** REF company_types에서 comp_tp_cd로 기업유형 조회. 없으면 null. */
export function getCompanyType(companyTypes, compTpCd) {
  return (companyTypes || []).find(t => t.comp_tp_cd === compTpCd) || null;
}

/** 3년 성장 투영 + 안정성. proj[0]=salMid; proj[y]=round(proj[y-1]×(1+gr)). */
export function brandProjection(salMidA, salMidB, typeA, typeB) {
  const grA = typeA ? typeA.growth_rate_val : GROWTH_RATE_FALLBACK;
  const grB = typeB ? typeB.growth_rate_val : GROWTH_RATE_FALLBACK;
  const projA = [salMidA], projB = [salMidB];
  let cumDiff = 0;
  for (let y = 1; y <= PROJECTION_YEARS; y++) {
    projA.push(Math.round(projA[y - 1] * (1 + grA)));
    projB.push(Math.round(projB[y - 1] * (1 + grB)));
    cumDiff += projB[y] - projA[y];
  }
  return {
    projA, projB, cumDiff, grA, grB,
    stabA: typeA ? typeA.stability_score_no : 0,
    stabB: typeB ? typeB.stability_score_no : 0,
    limited: !typeA || !typeB,   // 한쪽 미선택이면 브랜드 판정 제한
  };
}

// ─────────────────────────────────────────────────────────────────────
// 14. 희생요소 포기비용 — SP-ENGINE-14 (FR-39)
// ─────────────────────────────────────────────────────────────────────

/** curSacrifice 선택 시 포기 비용 정량화. 데이터만 반환. */
export function sacrificeCost(sacrifice, m) {
  switch (sacrifice) {
    case 'salary': {
      const td = Math.abs(m.totalB - m.totalA);
      return {
        axis: 'salary', ok: true,
        detail: {
          annual: td, monthly: Math.round(td / 12),
          daily: Math.round(td * WON_PER_MANWON / 365),   // 원
          better: m.totalB > m.totalA ? 'b' : 'a',
        },
      };
    }
    case 'wlb': {
      if (!(m.wsHoursA > 0 && m.wsHoursB > 0)) {
        return { axis: 'wlb', ok: false, detail: { missing: true } }; // 야근 미입력
      }
      const wd = Math.abs(m.wsHoursA - m.wsHoursB), ann = wd * WEEKS_PER_YEAR;
      return {
        axis: 'wlb', ok: true,
        detail: {
          weekDiff: wd, annHours: ann, annDays: Math.round(ann / WORKDAY_HRS),
          more: m.wsHoursA > m.wsHoursB ? 'a' : 'b',
        },
      };
    }
    case 'benefits': {
      const d = Math.abs(m.benA - m.benB);
      return { axis: 'benefits', ok: true, detail: { diff: d, better: m.benA > m.benB ? 'a' : 'b' } };
    }
    case 'brand': {
      const br = m.brand;
      return {
        axis: 'brand', ok: !br.limited,
        detail: { cumDiff: br.cumDiff, stabDiff: br.stabB - br.stabA, grA: br.grA, grB: br.grB, limited: br.limited },
      };
    }
    default: return null;
  }
}

// ─────────────────────────────────────────────────────────────────────
// 15. 오케스트레이터 — compare · calc · restSummary — SP-ENGINE-15 (FR-30, FR-42)
// ─────────────────────────────────────────────────────────────────────

/** 전체 리포트(FR-30). 필수값(연봉) 결측이면 ok:false + missing(부분 미산출, throw 없음). */
export function compare(state, now = Date.now()) {
  const salA = parseSalRange(state.salStr);
  const salB = deriveOfferRange(salA, state.selectedRate);
  const missing = [];
  if (!salA.min && !salA.max) missing.push('salary');   // 연봉 필수(UC-30 2a)

  const R = {};   // 슬롯 원시 결과
  for (const s of ['a', 'b']) {
    const sal = s === 'a' ? salA : salB;
    const ws  = state.wsState[s];
    const { ben, net } = benTotal(state.benS[s]);
    const eff = effSalary(sal, net);
    const wsHours = getWSHours(ws);
    const otPay   = getOTPay(ws, sal);
    const total   = eff.mid + otPay;
    const hourly  = hourlyValue(eff.mid, otPay, wsHours);
    const auto    = autonomyScore(ws, state.matched[s]);
    const band    = sumBand(state.benS[s], now);
    R[s] = {
      salRange: sal, ben, net, eff, wsHours, otPay, total, hourly,
      autonomy: auto, sumBand: band,
      totalRange: [total - band, total + band], commuteMin: state.com[s] || 0,
    };
  }

  // 브랜드 축 데이터(항상 산출 — vdCard/rest/희생 재사용)
  const typeA = getCompanyType(state.companyTypes, state.matched.a && state.matched.a.comp_tp_cd);
  const typeB = getCompanyType(state.companyTypes, state.matched.b && state.matched.b.comp_tp_cd);
  const brand = brandProjection(salA.mid, salB.mid, typeA, typeB);

  const m = {
    totalA: R.a.total, totalB: R.b.total, hourlyA: R.a.hourly, hourlyB: R.b.hourly,
    wsHoursA: R.a.wsHours, wsHoursB: R.b.wsHours, autoA: R.a.autonomy, autoB: R.b.autonomy,
    benA: R.a.ben, benB: R.b.ben, brand,
  };

  const warnings = [];
  const effDiffMid = R.b.eff.mid - R.a.eff.mid, salDiffMid = salB.mid - salA.mid;
  if (salDiffMid > 0 && effDiffMid < salDiffMid && R.a.ben > R.b.ben) warnings.push('eff_shrink');
  const incA = R.a.otPay === 0 && state.wsState.a.wage === 'inclusive' && state.wsState.a.ot !== 'low';
  const incB = R.b.otPay === 0 && state.wsState.b.wage === 'inclusive' && state.wsState.b.ot !== 'low';
  if (incA && incB) warnings.push('both_inclusive');
  else if (incA) warnings.push('inclusive_a');
  else if (incB) warnings.push('inclusive_b');

  const hourlyDiff = (R.a.hourly != null && R.b.hourly != null) ? R.b.hourly - R.a.hourly : null;

  return {
    ok: missing.length === 0, missing,
    a: R.a, b: R.b,
    deltas: {
      effMid: effDiffMid, effMin: R.b.eff.min - R.a.eff.min, effMax: R.b.eff.max - R.a.eff.max,
      salMid: salDiffMid, totalDiff: R.b.total - R.a.total, hourlyDiff,
      benDiff: R.b.ben - R.a.ben,
    },
    catDelta: benCatCompare(state.benS.a, state.benS.b),
    qual:     qualCompare(state.benS.a, state.benS.b),
    commute:  commuteCompare(state.com.a, state.com.b),
    vdCard:   buildVdCard(state.curPri, m),
    sacrifice: state.curSacrifice ? sacrificeCost(state.curSacrifice, m) : null,
    brand,
    rest:     restSummary(state.curPri, state.curSacrifice, m, R),
    warnings,
  };
}

/** 경량 실시간 요약(FR-30). 편집 중 salRange/net/eff만. vdCard·밴드·투영 미산출. */
export function calc(state) {
  const salA = parseSalRange(state.salStr);
  const salB = deriveOfferRange(salA, state.selectedRate);
  const nA = benTotal(state.benS.a).net, nB = benTotal(state.benS.b).net;
  return {
    salRange: { a: salA, b: salB }, net: { a: nA, b: nB },
    eff: { a: effSalary(salA, nA), b: effSalary(salB, nB) },
  };
}

/** 나머지 기준 요약(curPri·curSacrifice 아닌 축). */
export function restSummary(pri, sac, m, R) {
  const keys = ['salary', 'wlb', 'benefits', 'brand'].filter(k => k !== pri && k !== sac);
  return keys.map(axis => {
    if (axis === 'salary') {
      const d = m.totalB - m.totalA;
      return { axis, winner: d > 0 ? 'b' : d < 0 ? 'a' : 'tie', value: { diff: d } };
    }
    if (axis === 'wlb') {
      const both = m.wsHoursA > 0 && m.wsHoursB > 0;
      return {
        axis,
        winner: both ? (m.wsHoursA < m.wsHoursB ? 'a' : m.wsHoursB < m.wsHoursA ? 'b' : 'tie') : 'tie',
        value: both
          ? { wsA: m.wsHoursA, wsB: m.wsHoursB }
          : { commuteA: R.a.commuteMin, commuteB: R.b.commuteMin, missing: true },
      };
    }
    if (axis === 'benefits') {
      const d = m.benB - m.benA;
      return { axis, winner: d > 0 ? 'b' : d < 0 ? 'a' : 'tie', value: { diff: d } };
    }
    // brand
    return {
      axis, winner: m.brand.cumDiff > 0 ? 'b' : m.brand.cumDiff < 0 ? 'a' : 'tie',
      value: { cumDiff: m.brand.cumDiff },
    };
  });
}
