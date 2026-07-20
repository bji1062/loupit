// web/assets/js/calc.js — SP-ENGINE 비교 계산 엔진 (순수 ES 모듈).
// 근거: SPEC/05-비교-계산엔진.md(SP-ENGINE-1~17), TASK/05-계산엔진.md.
//
// 불변 계약(INV-4, 테스트로 강제 — T-ENGINE-45):
//  1) 부수효과 0: document/window/fetch/localStorage/XMLHttpRequest/전역 미접근.
//     모든 입력은 인자, 모든 출력은 반환값.
//  2) 결정성: 동일 입력 → 동일 출력. 시간 의존(만료 판정)은 now 인자로 주입
//     (Date.now()는 오케스트레이터의 기본 매개변수에서만 바인딩).
//  3) 불변 입력: 인자 객체를 mutate하지 않는다. 항상 새 객체를 반환한다.
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
 *   remote: boolean|'none'|'partial'|'hybrid'|'free'|null, // 실데이터·UI는 불리언, 레거시 enum도 수용(#2)
 *   flex:   boolean|'none'|'stagger'|'flexible'|null
 * }} WorkStyle */

/** @typedef {{
 *   comp_id:    number|null,
 *   comp_nm:    string|null,
 *   comp_tp_cd: string|null,             // 기업유형 코드(직접입력 프리셋용)
 *   work_style_val: { unlimitedPTO?:boolean, remote?:boolean,
 *                     flex?:boolean, refreshLeave?:string }|null
 * }} SlotMeta */

/** @typedef {{
 *   comp_tp_cd:        string,
 *   growth_rate_val:   number,           // DECIMAL 예: 0.04 (연평균 상승률)
 *   growth_label_nm:   string,
 *   stability_score_no:number            // 1~100
 * }} CompanyType */

/** @typedef {'salary'|'wlb'|'benefits'} PriKey */  // 엔진 정규 키(§2.1)

/** @typedef {{
 *   salStr:        string|null,          // 슬롯 a 연봉 "lo-hi"(만원). 예 "5000-7000"
 *   selectedRate:  number|null,          // 슬롯 b 상승률(%). b = a×(1+rate/100)
 *   benS:          { a:BenefitItem[], b:BenefitItem[] },
 *   wsState:       { a:WorkStyle, b:WorkStyle },
 *   com:           { a:number, b:number },  // 편도 통근(분) ≥0
 *   curPri:        PriKey,
 *   curSacrifice:  PriKey|null,           // ≠ curPri
 *   matched:       { a:SlotMeta|null, b:SlotMeta|null },
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
 *   autonomy:  string[],     // 보유 자율성 요소 라벨(#2 정성 재설계, 구 점수 폐기)
 *   sumBand:   number,       // ± 만원(불확실성) FR-38
 *   totalRange:[number,number], // [total-sumBand, total+sumBand]
 *   commuteMin:number        // 편도 분
 * }} SlotResult */

/** @typedef {{
 *   ok:        boolean,      // false면 필수값 결측(missing 참조)
 *   missing:   string[],     // 결측 필드 코드. 'salary'(슬롯 a 연봉)·'raise'(슬롯 b 상승률)
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
// 자율성 요소 라벨(#2 재설계 2026-07-18): 점수 합산을 폐기하고 보유 집합을 정성 비교한다.
export const AUTONOMY_LABELS = { remote: '재택근무', flex: '유연근무', unlimitedPTO: '무제한휴가' };
export const MONTHLY_STD_HRS = 209;  // 월 소정근로시간(통상시급 분모)
export const OT_MULT         = 1.5;  // 연장근로 가산율
export const WEEKS_PER_MONTH = 4.33; // 월 평균 주수
export const WEEKS_PER_YEAR  = 52;   // 연간 근무시간 환산
export const WON_PER_MANWON  = 10000;// 만원→원
export const COMMUTE_ROUND_TRIP = 2; // 왕복 계수
export const COMMUTE_WORKDAYS   = 240; // 연 근무일(통근 연환산)
export const WORKDAY_HRS     = 8;    // 근무일 환산(연시간→근무일)
export const BENEFIT_SAT_THRESHOLD = 1200; // 총보상 차 ≤이면 "복지 우선" 판단(만원)

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
  // 하한 0("0-5000")은 유효 연봉이므로 min·max가 모두 0(무입력 센티넬)일 때만 결측 취급(#8).
  if (!baseRange || (!baseRange.min && !baseRange.max) || selectedRate == null) return { min: 0, max: 0, mid: 0 };
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
    .map(b => ({ benefit_nm: b.benefit_nm, benefit_ctgr_cd: b.benefit_ctgr_cd, qual_desc: b.qual_desc_ctnt || '' }));
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

// 진리값 해석(#2): 불리언은 그대로, 레거시 enum 문자열은 'none'→false·그 외 truthy 문자열→true.
// 실데이터·UI는 불리언(재택 true/false)을 주고 구 프리셋·테스트는 enum('hybrid' 등)을 줄 수 있어 양쪽 계약을 모두 수용한다.
function autonomyTruthy(v) {
  if (typeof v === 'string') return v !== '' && v !== 'none';
  return !!v;
}

/** 자율성 요소 보유 목록(한국어 라벨 배열). 재택근무·유연근무·무제한휴가 순. 점수 합산 폐기(#2). */
export function autonomyPerks(ws, slotMeta) {
  const perks = [];
  if (ws && autonomyTruthy(ws.remote)) perks.push(AUTONOMY_LABELS.remote);
  if (ws && autonomyTruthy(ws.flex)) perks.push(AUTONOMY_LABELS.flex);
  const meta = slotMeta && slotMeta.work_style_val;
  if (meta && autonomyTruthy(meta.unlimitedPTO)) perks.push(AUTONOMY_LABELS.unlimitedPTO);
  return perks;
}

/** '시간 자율성' 판정 — 엄격 우세만 승(#2): 한쪽 보유 집합이 상대를 진부분집합으로 초과(모두 포함+더 보유)할 때만 승.
 *  집합 동일 → tie, 서로 비교불가(각자 다른 항목 보유) → tie. */
function autonomyWinner(perksA, perksB) {
  const A = new Set(Array.isArray(perksA) ? perksA : []); // 비배열 방어(무크래시)
  const B = new Set(Array.isArray(perksB) ? perksB : []);
  const aCoversB = [...B].every((x) => A.has(x)); // A ⊇ B
  const bCoversA = [...A].every((x) => B.has(x)); // B ⊇ A
  if (aCoversB && !bCoversA) return 'a';           // A가 B를 전부 포함 + 더 보유
  if (bCoversA && !aCoversB) return 'b';
  return 'tie';                                    // 동일 집합 또는 비교불가
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
    winner: autonomyWinner(m.autoA, m.autoB),                 // #2: 점수 비교 폐기 → 보유 집합 엄격 우세
    detail: { perksA: m.autoA || [], perksB: m.autoB || [] }, // 한국어 라벨 배열(렌더가 문장화)
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

/** 4축 vdCard 판정. 승자·수치만 반환 — 문구·색은 SP-RPT가 구성. */
export function buildVdCard(axis, m) {
  switch (axis) {
    case 'salary':   return vdSalary(m);
    case 'wlb':      return vdWlb(m);
    case 'benefits': return vdBenefits(m);
    default:         return vdWlb(m);   // 안전 폴백(기본 워라밸)
  }
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
  if (!salA.min && !salA.max) missing.push('salary');    // 슬롯 a 현재 연봉 필수(UC-30 2a)
  if (state.selectedRate == null) missing.push('raise'); // 슬롯 b 상승률 필수(#3) — 0(동결)은 유효값이라 == null 만 결측

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
    const auto    = autonomyPerks(ws, state.matched[s]);   // #2: 보유 자율성 요소 라벨 배열
    const band    = sumBand(state.benS[s], now);
    R[s] = {
      salRange: sal, ben, net, eff, wsHours, otPay, total, hourly,
      autonomy: auto, sumBand: band,
      totalRange: [total - band, total + band], commuteMin: state.com[s] || 0,
    };
  }

  const m = {
    totalA: R.a.total, totalB: R.b.total, hourlyA: R.a.hourly, hourlyB: R.b.hourly,
    wsHoursA: R.a.wsHours, wsHoursB: R.b.wsHours, autoA: R.a.autonomy, autoB: R.b.autonomy,
    benA: R.a.ben, benB: R.b.ben,
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
  const keys = ['salary', 'wlb', 'benefits'].filter(k => k !== pri && k !== sac);
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
    // benefits(남는 유일한 축)
    const d = m.benB - m.benA;
    return { axis, winner: d > 0 ? 'b' : d < 0 ? 'a' : 'tie', value: { diff: d } };
  });
}
