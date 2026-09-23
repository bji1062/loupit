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
 *   hours?: number|null,                  // 주 근무시간 직접 입력(h). 있으면 ot 보다 우선(2026-09-23)
 *   wage:   'inclusive'|'separate'|null, // 포괄/비포괄. null = 미선택(두 경우를 모두 계산)
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
 *   commuteIn?:    { a:number|null, b:number|null }, // 편도 통근 원입력(null=미입력 ≠ 0분, 2026-09-23)
 *   tenureYears?:  number|null,           // 현재 직장 근속(년). null=미입력(판정하지 않는다)
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

/**
 * 주 근무시간(h) — 직접 입력(`ws.hours`)이 있으면 그것, 없으면 칩(`ws.ot` → OT_HRS). 미입력 0.
 * 계산기 입력(2026-09-23)은 칩 3개(40·45·54h)와 숫자 칸이 양방향으로 묶여 있어, 44시간처럼 칩에
 * 없는 값도 들어온다. `ot` 만 주는 옛 상태에서는 `getWSHours` 와 값이 같다.
 */
export function weeklyHours(ws) {
  const h = ws && ws.hours != null && ws.hours !== '' ? Number(ws.hours) : NaN;
  if (Number.isFinite(h) && h > 0) return h;
  return OT_HRS[ws && ws.ot] || 0;
}

/**
 * 야근수당(만원/년, ≥0) — `getOTPay` 와 같은 공식, 시간만 `weeklyHours` 에서 읽는다.
 * 비포괄(`separate`)이고 주 40시간을 넘길 때만 발생한다. 임금 형태 미선택(null)은 0 — 두 경우를
 * 모두 보이는 일은 `wageScenarios`(§15.7)가 한다.
 */
export function overtimePay(ws, salRange) {
  if (!ws || ws.wage !== 'separate') return 0;
  const extraHrs = weeklyHours(ws) - LEGAL_WEEK_HRS;
  if (!(extraHrs > 0)) return 0;
  const mid = salRange && salRange.mid;
  if (!mid) return 0;
  const hourlyBase = mid * WON_PER_MANWON / 12 / MONTHLY_STD_HRS;
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

/**
 * **항목 하나**의 금액 맞대결 판정 (SP-CMP-6). 반환 `'same' | 'a' | 'b' | 'unsure'`.
 *
 * 두 밴드 `[amt×(1−c), amt×(1+c)]` 가 겹치면 「말할 수 없음」이고, 겹치지 않으면 큰 쪽이다.
 * 계수 `c` 는 **새로 만들지 않는다** — `bandCoeff`(공식 ±5% · 추정 ±20% · 만료 +15%p)를 그대로
 * 쓴다. 계수를 문서와 JS 두 곳에 적으면 한쪽만 바뀌는 날이 오고, 그날 판정이 조용히 갈린다.
 *
 * 🚨 **총액 판정은 만들지 않는다.** 등록 금액에는 대출 한도(1억)·일회성 포상처럼 연간 환산이
 * 아닌 값이 섞여 있어 그 합의 우열은 무엇으로 표현하든 거짓이다(D-6). 이 함수는 **항목 단위**
 * 로만 쓰고, 결과를 더하거나 세어 「종합 우세」를 만들지 마라.
 *
 * 금액이 한쪽이라도 없으면 `'unsure'` 다 — 「금액 맞대결」 표는 애초에 양쪽 금액이 있는 공통
 * 코드만 싣지만, 없는 값을 0 으로 취급해 「큰 쪽」을 말하는 경로를 열어 두지 않는다.
 */
export function pairVerdict(a, b, now) {
  // ⚠ `Number(null)` 은 0 이고 0 은 유한하다 — `!= null` 로 먼저 거르지 않으면 「금액 미기재」가
  // 「0원」이 되어 상대가 무조건 큰 쪽으로 판정된다(없는 값을 0 으로 세지 않는다, SP-CMP-3).
  const amt = (it) => (it && !it.qual_yn && it.benefit_amt != null ? Number(it.benefit_amt) : NaN);
  const amtA = amt(a);
  const amtB = amt(b);
  if (!Number.isFinite(amtA) || !Number.isFinite(amtB)) return 'unsure';
  if (amtA === amtB) return 'same';
  const ca = bandCoeff(a, now);
  const cb = bandCoeff(b, now);
  const loA = amtA * (1 - ca), hiA = amtA * (1 + ca);
  const loB = amtB * (1 - cb), hiB = amtB * (1 + cb);
  if (loA <= hiB && loB <= hiA) return 'unsure'; // 밴드가 겹친다 = 차이를 말할 수 없다
  return amtA > amtB ? 'a' : 'b';
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
    // 분모는 **현재 직장(A)** 이다 — 「지금보다 몇 % 줄어드나」가 이 숫자의 뜻이다. 예전에는
    // `Math.min(A, B)` 라 A 가 클 때 감소율이 부풀었다(NAVER→카카오 −14,960원: 54% → 35%).
    const pct = Math.round(Math.abs(hd) / m.hourlyA * 100);
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

/**
 * 전체 리포트(FR-30). 필수값(연봉) 결측이면 ok:false + missing(부분 미산출, throw 없음).
 * 이직 계산기 개편(2026-09-23): 핵심 수치(`compareCore`) 위에 축 3벌·총보상 흐름·복지 변화 분류를
 * 얹는다(`calculatorExtras`, SPEC 05 §15.7). 기존 키는 한 글자도 바뀌지 않고 새 키만 더해진다.
 */
export function compare(state, now = Date.now()) {
  const core = compareCore(state, now);
  if (!core.ok) return core; // 결측이면 화면이 리포트로 가지 않는다 — 덧붙일 것도 없다
  return { ...core, ...calculatorExtras(state, core, now) };
}

/** 핵심 수치만(§15). 감도·임금 형태 시나리오가 상태를 바꿔 다시 부르는 단위다(재귀 방지). */
export function compareCore(state, now = Date.now()) {
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
    const wsHours = weeklyHours(ws);     // 직접 입력(hours) 우선, 없으면 칩(ot) — ot 만 주면 getWSHours 와 같다
    const otPay   = overtimePay(ws, sal); // 〃 getOTPay 와 같은 공식, 시간만 hours 에서 읽는다
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
  // 「포괄이라 야근수당 0」은 **야근을 한다고 입력했을 때만** 말할 거리다(주 40시간 초과). 예전에는
  // 야근 빈도 미선택(ot null)도 `!== 'low'` 에 걸려 경고가 떴다.
  const incA = R.a.otPay === 0 && state.wsState.a.wage === 'inclusive' && R.a.wsHours > LEGAL_WEEK_HRS;
  const incB = R.b.otPay === 0 && state.wsState.b.wage === 'inclusive' && R.b.wsHours > LEGAL_WEEK_HRS;
  if (incA && incB) warnings.push('both_inclusive');
  else if (incA) warnings.push('inclusive_a');
  else if (incB) warnings.push('inclusive_b');
  // 임금 형태 미선택 + 야근 → 두 경우를 모두 계산했다(계산기가 「포괄이면 / 비포괄이면」을 나란히 보인다).
  for (const s of ['a', 'b']) {
    const ws = state.wsState[s] || {};
    if (ws.wage == null && R[s].wsHours > LEGAL_WEEK_HRS) warnings.push('wage_unknown_' + s);
  }

  const hourlyDiff = (R.a.hourly != null && R.b.hourly != null) ? R.b.hourly - R.a.hourly : null;

  return {
    ok: missing.length === 0, missing,
    a: R.a, b: R.b,
    deltas: {
      effMid: effDiffMid, effMin: R.b.eff.min - R.a.eff.min, effMax: R.b.eff.max - R.a.eff.max,
      salMid: salDiffMid, totalDiff: R.b.total - R.a.total, hourlyDiff,
      benDiff: R.b.ben - R.a.ben,
      // 2026-09-23 추가 — 총보상 흐름(브리지)의 세 조각은 salMid + benDiff + otDiff = totalDiff(오차 0)
      otDiff: R.b.otPay - R.a.otPay,
      effRate: R.a.total ? (R.b.total - R.a.total) / R.a.total : null,
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

// ─────────────────────────────────────────────────────────────────────
// 15.7 이직 계산기 개편(2026-09-23) — 축 3벌 · 총보상 흐름 · 복지 변화 분류 — SP-MOVE-1~10
// ─────────────────────────────────────────────────────────────────────
// 근거: loupit-evidence/2026-09-22-calc-redesign/FINAL-DESIGN.md §3·§4·§5·§8-2 + IMPL-BRIEF §2(사용자 결정).
// 전부 순수 함수(now 주입)이고 **데이터만** 돌려준다 — 문장은 report.js 가 만든다(SP-FE-1.2 규칙 5).
// 분류(혼합·상한·짝짓기·4분해)를 여기 두는 이유: 감도(`sensitivity`)가 그 분류로 상태를 바꿔
// compareCore 를 다시 불러야 한다(렌더 계층에 두면 계산이 두 벌이 된다).

/**
 * 축 판정 문턱 — **설계 상수**. 데이터로 잴 수 있는 것은 전체 회사 쌍으로 실측해 정했다
 * (SPEC 05 §15.7 SP-MOVE-9 · `infra/tools/calc_thresholds.mjs`). 주 근무시간·통근은 사용자 입력이라 실측 대상이 아니다.
 */
export const AXIS_THRESHOLDS = Object.freeze({
  wlbWeekHrs: 2,         // 주 근무시간 차(h) ≥ 이면 워라밸 축 1순위가 결론을 낸다(입력)
  wlbCommuteAnnHrs: 40,  // 연 통근시간 차(h) ≥ 이면 2순위(입력)
  // 휴가·근무제도 등록 항목 수 차 ≥ 이면 4순위(등록 데이터). 실측 2026-09-23: 회사별 중앙값 2(0~6)라 차이 2 는
  // 수집 깊이 안의 흔들림이다(전 순서쌍의 49%) — 3 이면 상위 25% 쌍만, 시간·통근 미입력 사용자의 7% 만 등록 수로 결론.
  wlbQualCount: 3,
  // 「거의 같음」 상한 = max(오차 폭 × 1.5, 기준값 × 3%). 기준값은 연봉 축 = 현재 총보상, 복지 축 = 복지 금액 합(큰 쪽).
  // 실측: 연봉 축 거의 같음 6~7%(연봉 동결 이동 17% · 야근수당이 인상분을 상쇄하는 고연봉 23%), 복지 축 13%.
  nearBandMult: 1.5,
  nearTotalPct: 0.03,
});

export const CAPPED_RE = /최대|한도|상한/;          // 금액 행 설명에 이 말이 있으면 실제로 받는 돈은 더 적을 수 있다
export const FAMILY_RE = /가족|배우자|자녀/;        // 표시 전용 — 「가족까지 확대」 같은 해석 문장을 만들지 않는다
const TENURE_RE = /근속|주년/;
// 「근속 3·5·7·10년」·「5, 10, 15, 20년」처럼 나열된 연수는 **가장 작은 값**이 첫 자격이다. `2025년` 의 25 를
// 연수로 읽지 않도록 앞자리가 숫자면 거른다.
const TENURE_YEARS_RE = /(?<![\d.])((?:\d{1,2}\s*[·,/]\s*)*\d{1,2})\s*(?:년|주년)/;
// 수집 메모(「(… 근속 연수 기준 미기재)」·「— … 미기재」)는 회사가 밝힌 조건이 아니다 — 근속 판정에서 뺀다.
const ANNOTATION_RE = /\([^()]*미기재[^()]*\)|—[^—]*미기재[^—]*$/g;

const CAT_SET = new Set(BENEFIT_CATEGORIES);
const catOf = (it) => (CAT_SET.has(it && it.benefit_ctgr_cd) ? it.benefit_ctgr_cd : 'perks'); // benByCat 과 같은 폴백

/** 등록된 금액(정성·미기재면 null). 체크 여부와 무관 — 「회사에 등록된 것」의 분류용. */
function amtOf(it) {
  if (!it || it.qual_yn || it.benefit_amt == null) return null;
  const n = Number(it.benefit_amt);
  return Number.isFinite(n) ? n : null;
}
/** 합산에 들어가는 금액 — benTotal 과 같은 규칙(체크된 비정성). 행별 「빼고 다시 계산」이 checked 로 끈다. */
function effAmt(it) { return it && it.checked && !it.qual_yn ? (Number(it.benefit_amt) || 0) : 0; }
function descOf(it) { return [it && it.qual_desc_ctnt, it && it.note_ctnt].filter(Boolean).join(' '); }
const sumBy = (arr, f) => (arr || []).reduce((acc, x) => acc + f(x), 0);
const live = (list) => (list || []).filter((it) => it && !it.legal_yn); // 법정 행은 표시만, 비교·집계에서 뺀다(SP-LEGAL-5)

/** 차이의 흔들림 폭 = 두 회사 폭의 **합**(구간 산술 — 제곱합 금지: 추정 금액은 독립 오차가 아니다). */
export function deltaBand(a, b) { return (Number(a && a.sumBand) || 0) + (Number(b && b.sumBand) || 0); }

/**
 * 판정 티어 — 세 축이 같은 함수를 쓴다(사용자 결정 1). `'unsure' | 'near' | 'a' | 'b'`.
 * - 가드: 「그대로」(d)와 「한쪽만 금액 등록 제외」(guardD)의 부호가 갈리면 unsure.
 * - |d| ≤ band(>0) → unsure(두 회사의 오차 범위가 겹친다). 이 티어에서는 화면이 차액 숫자를 내지 않는다.
 * - |d| ≤ max(band × nearBandMult, |base| × nearTotalPct) → near.
 * - 그 밖에는 큰 쪽(d = B − A 이므로 d > 0 → 'b').
 */
export function verdictTier(d, band, base, guardD = null, T = AXIS_THRESHOLDS) {
  const diff = Number(d) || 0;
  const bd = Math.max(0, Number(band) || 0);
  if (guardD != null && Math.sign(guardD) !== Math.sign(diff)) return 'unsure';
  if (bd > 0 && Math.abs(diff) <= bd) return 'unsure';
  const nearHi = Math.max(bd * T.nearBandMult, Math.abs(Number(base) || 0) * T.nearTotalPct);
  if (Math.abs(diff) <= nearHi) return 'near';
  return diff > 0 ? 'b' : 'a';
}

/**
 * unsure 의 **원인** — 화면이 원인에 맞는 문장만 쓰게 한다(적대 검증 MED-1: 부호 갈림으로 unsure 가 된 쌍에
 * 「오차 범위가 겹칩니다」라고 말했다). `'band'`(차이가 오차 범위 안) · `'guard'`(차이는 범위 밖인데 한쪽만 금액이
 * 등록된 항목을 빼면 부호가 갈림) · null(unsure 아님). 둘 다 맞으면 `'band'` — 그것만으로 충분한 이유다.
 * `verdictTier(...) === 'unsure'` ⇔ `unsureCause(...) != null`(같은 입력).
 */
export function unsureCause(d, band, guardD = null) {
  const diff = Number(d) || 0;
  const bd = Math.max(0, Number(band) || 0);
  if (bd > 0 && Math.abs(diff) <= bd) return 'band';
  if (guardD != null && Math.sign(guardD) !== Math.sign(diff)) return 'guard';
  return null;
}

/**
 * benefit_cd 1:1 짝짓기 — 통 5개는 **배타**다(한 항목은 정확히 한 통). 법정 행(`legal_yn`)은 `legal` 로 빠진다.
 * 분류는 **등록** 기준(금액 유무)이라 행별 「빼고 다시 계산」으로 checked 가 바뀌어도 목록은 흔들리지 않는다.
 * 같은 회사에 같은 코드가 둘 이상이면 뒤의 것은 `cd#2` 로 따로 센다(현 데이터 0건, 방어).
 */
export function classifyPairs(listA, listB) {
  const keyed = (list) => {
    const seen = new Map();
    return live(list).map((it) => {
      const base = String(it.benefit_cd || it.benefit_nm || '');
      const n = (seen.get(base) || 0) + 1;
      seen.set(base, n);
      return [n > 1 ? base + '#' + n : base, it];
    });
  };
  const out = {
    bothAmt: [], mixed: [], bothQual: [], onlyA: [], onlyB: [],
    legal: { a: (listA || []).filter((it) => it && it.legal_yn), b: (listB || []).filter((it) => it && it.legal_yn) },
  };
  const B = new Map(keyed(listB));
  const used = new Set();
  for (const [key, a] of keyed(listA)) {
    const b = B.get(key);
    if (!b) { out.onlyA.push(a); continue; }
    used.add(key);
    const ha = amtOf(a) != null, hb = amtOf(b) != null;
    if (ha && hb) out.bothAmt.push({ key, a, b });
    else if (ha || hb) out.mixed.push({ key, a, b, side: ha ? 'a' : 'b' }); // side = 금액이 등록된 쪽
    else out.bothQual.push({ key, a, b });
  }
  for (const [key, b] of B) if (!used.has(key)) out.onlyB.push(b);
  return out;
}

/**
 * 복지 환산 가치 차이(B − A)의 4분해 — 항등식 `onlyA + onlyB + sameBoth + mixed (+ legal) === benDiff`.
 * onlyA 는 음수(이직 후보에 등록 없음), onlyB 는 양수(새로 생김), mixed 는 「한쪽만 금액 등록」의 몫.
 */
export function benDiffParts(listA, listB, pairs = classifyPairs(listA, listB)) {
  const onlyA = -sumBy(pairs.onlyA, effAmt);
  const onlyB = sumBy(pairs.onlyB, effAmt);
  const sameBoth = sumBy(pairs.bothAmt, (r) => effAmt(r.b) - effAmt(r.a));
  const mixed = sumBy(pairs.mixed, (r) => effAmt(r.b) - effAmt(r.a));
  const legal = sumBy(pairs.legal.b, effAmt) - sumBy(pairs.legal.a, effAmt); // 법정 행은 정성이라 현재 0
  return { onlyA, onlyB, sameBoth, mixed, legal, total: onlyA + onlyB + sameBoth + mixed + legal };
}

/** 설명에 「최대·한도·상한」이 적힌 금액 행 — 실제로 받는 돈은 더 적을 수 있다(감도 ③). */
export function cappedRows(list) {
  return live(list).filter((it) => amtOf(it) != null && CAPPED_RE.test(descOf(it)));
}

/**
 * 항목 표식 — **표시 전용**, 판정에 쓰지 않는다.
 * tenure: 이름·설명에 「근속·주년」이 있으면 `{ years }`(연수를 못 뽑으면 null). familyMention: 설명에 가족·배우자·자녀.
 * capped: 금액 행이고 설명에 최대·한도·상한.
 */
export function facetOf(item) {
  const desc = descOf(item);
  const hay = String((item && item.benefit_nm) || '') + ' ' + desc.replace(ANNOTATION_RE, ' ');
  let tenure = null;
  if (TENURE_RE.test(hay)) {
    const m = hay.match(TENURE_YEARS_RE);
    const ys = m ? m[1].split(/[·,/\s]+/).map(Number).filter((n) => Number.isFinite(n) && n > 0 && n <= 40) : [];
    tenure = { years: ys.length ? Math.min(...ys) : null };
  }
  return { tenure, familyMention: FAMILY_RE.test(desc), capped: amtOf(item) != null && CAPPED_RE.test(desc) };
}

/** 근속 조건이 붙은 항목(법정 행 제외). 입력 화면 보조문(「근속 연수에 따라 받는 복지가 N개」)도 이것을 센다. */
export function tenureItems(list) {
  return live(list).map((item) => ({ item, facet: facetOf(item) })).filter((x) => x.facet.tenure)
    .map((x) => ({ item: x.item, years: x.facet.tenure.years }));
}

/**
 * 근속 장부 — 이직하면 근속은 0 부터다. A 의 근속 조건 항목을 「받는 중 / 아직 / 연수 모름」으로 가른다.
 * 근속 입력이 없으면(null) 판정하지 않는다 — 기본값으로 「받고 있습니다」를 지어내지 않는다(J3).
 */
export function tenureGate(listA, listB, tenureYears) {
  const A = tenureItems(listA);
  const B = tenureItems(listB);
  const ty = tenureYears != null && tenureYears !== '' && Number.isFinite(Number(tenureYears)) && Number(tenureYears) >= 0
    ? Number(tenureYears) : null;
  if (ty == null) return { tenureYears: null, a: A, earned: [], pending: [], unjudged: A, b: B, otherSideCount: B.length };
  return {
    tenureYears: ty, a: A,
    earned: A.filter((x) => x.years != null && ty >= x.years),
    pending: A.filter((x) => x.years != null && ty < x.years).map((x) => ({ ...x, left: x.years - ty })),
    unjudged: A.filter((x) => x.years == null),
    b: B, otherSideCount: B.length,
  };
}

/**
 * 카테고리 9칸 — 금액·폭·항목 수 + verdict:
 * 'a'|'b'(양쪽 금액, 폭 안 겹침) · 'similar'(겹침 — 차액을 말하지 않는다) · 'aOnly'|'bOnly'(한쪽만 금액) ·
 * 'countOnly'(양쪽 금액 없음 — 항목 수만) · 'empty'(양쪽 등록 없음).
 */
export function catProfile(listA, listB, now) {
  const A = live(listA), B = live(listB);
  return BENEFIT_CATEGORIES.map((ctgr) => {
    const a = A.filter((it) => catOf(it) === ctgr);
    const b = B.filter((it) => catOf(it) === ctgr);
    const sumA = sumBy(a, effAmt), sumB = sumBy(b, effAmt);
    const bandA = sumBy(a, (it) => effAmt(it) * bandCoeff(it, now));
    const bandB = sumBy(b, (it) => effAmt(it) * bandCoeff(it, now));
    const amtCntA = a.filter((it) => amtOf(it) != null).length;
    const amtCntB = b.filter((it) => amtOf(it) != null).length;
    let verdict;
    if (!a.length && !b.length) verdict = 'empty';
    else if (sumA > 0 && sumB > 0) {
      const overlap = sumA - bandA <= sumB + bandB && sumB - bandB <= sumA + bandA;
      verdict = overlap ? 'similar' : (sumA > sumB ? 'a' : 'b');
    } else if (sumA > 0) verdict = 'aOnly';
    else if (sumB > 0) verdict = 'bOnly';
    else verdict = 'countOnly';
    return {
      ctgr, cntA: a.length, cntB: b.length, amtCntA, amtCntB, qualA: a.length - amtCntA, qualB: b.length - amtCntB,
      sumA, sumB, bandA, bandB, delta: sumB - sumA, verdict,
    };
  });
}

/** 통근까지 넣은 시간당 가치(원) — 통근은 돈으로 바꾸지 않고 **분모에만** 더한다. */
export function hourlyWithCommute(effMid, otPay, wsHours, commuteMin) {
  if (!(wsHours > 0) || commuteMin == null || !Number.isFinite(Number(commuteMin))) return null;
  const ann = wsHours * WEEKS_PER_YEAR + commuteCompare(Number(commuteMin), 0).annA;
  return ann > 0 ? Math.round((effMid + otPay) * WON_PER_MANWON / ann) : null;
}

// 상태 변형(불변) — 조건에 맞는 항목을 체크 해제한 **새** 상태. 감도·튼튼함이 compareCore 를 다시 부르는 재료다.
function withExcluded(state, predA, predB = predA) {
  const map = (list, pred) => (list || []).map((it) => (it && it.checked && pred(it) ? { ...it, checked: false } : it));
  return { ...state, benS: { a: map(state.benS.a, predA), b: map(state.benS.b, predB) } };
}
function withWage(state, slot, wage) {
  return { ...state, wsState: { ...state.wsState, [slot]: { ...(state.wsState[slot] || {}), wage } } };
}
const inSet = (set) => (it) => set.has(it);

// 가드 값 — 한쪽만 금액이 등록된 항목을 뺀 총보상 차이(그런 항목이 없으면 null). 티어는 **언제나** 이것과 함께 낸다:
// 판정 카드·「결론이 얼마나 확실한가」·감도·야근수당 병치가 같은 티어를 써야 한 리포트가 서로 반대로 말하지 않는다(MED-2).
function guardOf(state, pairs, now) {
  if (!pairs.mixed.length) return null;
  const set = new Set(pairs.mixed.map((r) => (r.side === 'a' ? r.a : r.b)));
  return coreDiff(compareCore(withExcluded(state, inSet(set)), now), now).diff;
}

// B 연봉 1만원이 B 야근수당을 얼마나 움직이나 — 비포괄·야근이면 otPay = 연장h × 연봉 × 1.5 × 4.33 / 209.
function otSlope(ws) {
  if (!ws || ws.wage !== 'separate') return 0;
  const extra = weeklyHours(ws) - LEGAL_WEEK_HRS;
  return extra > 0 ? extra * OT_MULT * WEEKS_PER_MONTH / MONTHLY_STD_HRS : 0;
}

/**
 * 같아지는 연봉이 현재 연봉의 이 배수 밖이면 화면은 %·만원을 내지 않는다 — 「−10만원(−100.4%)만 돼도」는 협상
 * 조언으로 읽히지 않는다(적대 검증 MED-4). 실측(2026-09-23, 순서쌍 1/5 표본 · +10% · 45h/54h): 현재 연봉 2,500 에서
 * 절반 미만 2.3%(0 이하 0.2%) · 두 배 초과 1.0%, 6,000·15,000 에서는 0.
 */
export const BREAKEVEN_BOUNDS = Object.freeze({ low: 0.5, high: 2 });

/**
 * 총보상이 같아지는 B 연봉 — B 가 비포괄·야근이면 연봉이 오를수록 야근수당도 오르므로 선형 역산이 아니라
 * `(totalA − netB) / (1 + k)` 다(k = otSlope). 눈금 세 개(등록 그대로 · 한쪽만 등록 제외 · 복지 0)를 함께 낸다.
 * 눈금마다 bound: 'low'(현재 연봉의 절반 미만 — 0 이하 포함) · 'high'(두 배 초과) · null.
 */
export function breakevenRate(core, exMixedCore, wsB) {
  const salA = core && core.a && core.a.salRange ? core.a.salRange.mid : 0;
  if (!salA) return null;
  const k = otSlope(wsB);
  const at = (totalA, netB) => {
    const sal = (totalA - netB) / (1 + k);
    const bound = sal < salA * BREAKEVEN_BOUNDS.low ? 'low' : sal > salA * BREAKEVEN_BOUNDS.high ? 'high' : null;
    return { sal: Math.round(sal), rate: sal / salA - 1, bound };
  };
  return {
    full: at(core.a.total, core.b.net),
    exMixed: exMixedCore ? at(exMixedCore.a.total, exMixedCore.b.net) : null,
    noBenefit: at(core.a.salRange.mid + core.a.otPay, 0),
    k,
  };
}

/** 시간 계산서 — 근무·통근을 시간 그대로(통근은 금액으로 바꾸지 않는다). 미입력 칸은 null. */
export function timeSheet(core, commuteIn) {
  const hA = core.a.wsHours || null, hB = core.b.wsHours || null;
  const cin = commuteIn || {};
  const num = (v) => (v != null && v !== '' && Number.isFinite(Number(v)) && Number(v) >= 0 ? Number(v) : null);
  const cA = num(cin.a), cB = num(cin.b);
  const hours = hA && hB ? {
    a: hA, b: hB, weekDiff: hB - hA, annA: hA * WEEKS_PER_YEAR, annB: hB * WEEKS_PER_YEAR,
    annDiff: (hB - hA) * WEEKS_PER_YEAR, days: Math.round(Math.abs(hB - hA) * WEEKS_PER_YEAR / WORKDAY_HRS),
  } : null;
  let commute = null;
  if (cA != null && cB != null) {
    const cc = commuteCompare(cA, cB);
    commute = { a: cA, b: cB, annA: cc.annA, annB: cc.annB, annDiff: cc.annB - cc.annA, days: Math.round(Math.abs(cc.annB - cc.annA) / WORKDAY_HRS) };
  }
  const ha = core.a.hourly, hb = core.b.hourly;
  const hourly = ha != null && hb != null ? { a: ha, b: hb, diff: hb - ha, pct: ha ? (hb - ha) / ha : null } : null;
  let hourlyCommute = null;
  if (hours && commute) {
    const wa = hourlyWithCommute(core.a.eff.mid, core.a.otPay, hA, cA);
    const wb = hourlyWithCommute(core.b.eff.mid, core.b.otPay, hB, cB);
    if (wa != null && wb != null) hourlyCommute = { a: wa, b: wb, diff: wb - wa, pct: wa ? (wb - wa) / wa : null };
  }
  return { hours, hoursIn: { a: hA, b: hB }, commute, commuteIn: { a: cA, b: cB }, hourly, hourlyCommute };
}

// 감도 한 줄의 결과 — 'same'(결론 그대로) · 'flip'(결론이 반대로) · 'decide'(기준이 「거의 같음·판단하기 어려움」이라
// 뒤집을 결론이 없었는데 한쪽이 앞서게 됨 — LOW-12: 이때 「결론이 바뀌어」라고 하지 않는다) · 'near' · 'unsure'.
function scenarioResult(tier, baseTier) {
  if (tier === 'unsure' || tier === 'near') return tier;
  if (baseTier !== 'a' && baseTier !== 'b') return 'decide';
  return tier === baseTier ? 'same' : 'flip';
}
function coreDiff(c, now) {
  return { diff: c.b.total - c.a.total, band: c.a.sumBand + c.b.sumBand, totalA: c.a.total };
}

/**
 * 임금 형태 미선택 + 야근(주 40h 초과)인 슬롯마다 포괄·비포괄 두 경우를 계산한다(사용자 결정 4).
 * 미선택 슬롯이 없으면 null. 결과는 「포괄이면 / 비포괄이면」 병치의 재료다. 경우마다 티어는 가드를 포함한다(MED-2).
 * - agree: 모든 경우의 티어가 같다.
 * - dir: 모든 경우가 같은 쪽을 가리키면 그 부호(+1 = 이직 후보가 많다), 아니면 0. 「판단하기 어려움」이 하나라도
 *   있으면 0 이다(그 경우엔 방향이 없다). **「결론이 달라진다」는 부호가 갈릴 때만**이다(MED-3) — 같은 방향이면
 *   「얼마나」만 달라지므로 span(작은 차이 → 큰 차이)을 함께 낸다.
 */
export function wageScenarios(state, core, now, ctx = {}) {
  const need = ['a', 'b'].filter((s) => {
    const ws = state.wsState[s] || {};
    return ws.wage == null && weeklyHours(ws) > LEGAL_WEEK_HRS;
  });
  if (!need.length) return null;
  const pairs = ctx.pairs || classifyPairs(state.benS.a, state.benS.b);
  const combos = need.reduce((acc, s) => acc.flatMap((c) => [{ ...c, [s]: 'inclusive' }, { ...c, [s]: 'separate' }]), [{}]);
  const cases = combos.map((w) => {
    let st = state;
    for (const s of need) st = withWage(st, s, w[s]);
    const c = compareCore(st, now);
    const { diff, band, totalA } = coreDiff(c, now);
    const g = guardOf(st, pairs, now);
    return { wage: w, diff, band, totalA, tier: verdictTier(diff, band, totalA, g), unsureBy: unsureCause(diff, band, g), otA: c.a.otPay, otB: c.b.otPay };
  });
  const tiers = new Set(cases.map((c) => c.tier));
  const dirs = cases.map((c) => (c.tier === 'unsure' ? 0 : Math.sign(c.diff)));
  const dir = dirs.every((x) => x !== 0 && x === dirs[0]) ? dirs[0] : 0;
  const byMag = [...cases].sort((x, y) => Math.abs(x.diff) - Math.abs(y.diff));
  return {
    slots: need, cases, agree: tiers.size === 1, dir,
    anyDirectional: cases.some((c) => c.tier === 'a' || c.tier === 'b'),
    span: [byMag[0].diff, byMag[byMag.length - 1].diff],
  };
}

/**
 * 「이 결론을 뒤집는 것」 — 전부 실제 재계산(compareCore). 조건이 없으면 그 줄은 만들지 않는다.
 * ① b_wage_flip: 이직 후보 임금 형태를 반대로(입력돼 있고 야근이 있을 때) ② drop_mixed: 한쪽만 금액이 등록된 항목을 빼면
 * ③ drop_capped: 최대·한도 금액을 빼면 ④ drop_both: ②+③ 합집합 ⑤ no_benefits: 복지를 하나도 세지 않으면.
 */
export function sensitivity(state, core, now, ctx = {}) {
  const pairs = ctx.pairs || classifyPairs(state.benS.a, state.benS.b);
  const base = coreDiff(core, now);
  // 기준 티어 = 판정 카드와 **같은** 티어(가드 포함, MED-2). calculatorExtras 는 튼튼함에서 이미 구한 가드를 넘긴다.
  const guardD = ctx.guardD !== undefined ? ctx.guardD : guardOf(state, pairs, now);
  const baseTier = verdictTier(base.diff, base.band, base.totalA, guardD);
  const out = [];
  // guarded: 한쪽만 금액 등록 항목이 남아 있는 줄(①·③)은 그 줄의 티어도 가드를 포함한다.
  const push = (key, st, extra = {}, guarded = false) => {
    const c = compareCore(st, now);
    const r = coreDiff(c, now);
    const g = guarded ? guardOf(st, pairs, now) : null;
    const tier = verdictTier(r.diff, r.band, r.totalA, g);
    const result = scenarioResult(tier, baseTier);
    out.push({
      key, totalDiff: r.diff, band: r.band, tier, unsureBy: unsureCause(r.diff, r.band, g), result,
      flips: result === 'flip', decides: result === 'decide', ...extra, core: { otB: c.b.otPay, totalB: c.b.total },
    });
  };
  const wsB = state.wsState.b || {};
  if ((wsB.wage === 'inclusive' || wsB.wage === 'separate') && weeklyHours(wsB) > LEGAL_WEEK_HRS) {
    const to = wsB.wage === 'inclusive' ? 'separate' : 'inclusive';
    const st = withWage(state, 'b', to);
    const flipped = compareCore(st, now);
    const be = breakevenRate(core, null, { ...wsB, wage: to });
    push('b_wage_flip', st, {
      to, extraHrs: weeklyHours(wsB) - LEGAL_WEEK_HRS,
      hourlyBase: Math.round((core.b.salRange.mid * WON_PER_MANWON) / 12 / MONTHLY_STD_HRS),
      otB: flipped.b.otPay, breakeven: be ? be.full : null,
    }, true);
  }
  const mixedA = new Set(pairs.mixed.filter((r) => r.side === 'a').map((r) => r.a).filter((it) => it.checked));
  const mixedB = new Set(pairs.mixed.filter((r) => r.side === 'b').map((r) => r.b).filter((it) => it.checked));
  const capA = new Set(cappedRows(state.benS.a).filter((it) => it.checked));
  const capB = new Set(cappedRows(state.benS.b).filter((it) => it.checked));
  const listed = (setA, setB) => [...[...setA].map((it) => ({ side: 'a', nm: it.benefit_nm, amt: amtOf(it) })),
    ...[...setB].map((it) => ({ side: 'b', nm: it.benefit_nm, amt: amtOf(it) }))];
  const amountOf = (items) => sumBy(items, (x) => x.amt || 0);
  if (mixedA.size + mixedB.size) {
    const items = listed(mixedA, mixedB);
    push('drop_mixed', withExcluded(state, inSet(mixedA), inSet(mixedB)), { count: items.length, amount: amountOf(items), items });
  }
  if (capA.size + capB.size) {
    const items = listed(capA, capB);
    push('drop_capped', withExcluded(state, inSet(capA), inSet(capB)), { count: items.length, amount: amountOf(items), items }, true);
  }
  const uA = new Set([...mixedA, ...capA]), uB = new Set([...mixedB, ...capB]);
  const union = uA.size + uB.size;
  if ((mixedA.size + mixedB.size) && (capA.size + capB.size) && union > Math.max(mixedA.size + mixedB.size, capA.size + capB.size)) {
    const items = listed(uA, uB);
    push('drop_both', withExcluded(state, inSet(uA), inSet(uB)), { count: items.length, amount: amountOf(items), items });
  }
  if (core.a.net || core.b.net) push('no_benefits', withExcluded(state, () => true));
  return { baseTier, rows: out };
}

/** 튼튼함 눈금 3단 — ① 등록 금액 그대로 ② 한쪽만 등록된 항목을 빼면(없으면 null) ③ 복지를 하나도 세지 않으면. */
export function robustness(state, core, now, ctx = {}) {
  const pairs = ctx.pairs || classifyPairs(state.benS.a, state.benS.b);
  const full = coreDiff(core, now);
  let exMixed = null, exMixedCore = null;
  if (pairs.mixed.length) {
    const mixedSet = new Set(pairs.mixed.map((r) => (r.side === 'a' ? r.a : r.b)));
    exMixedCore = compareCore(withExcluded(state, inSet(mixedSet)), now);
    exMixed = coreDiff(exMixedCore, now);
  }
  const noCore = compareCore(withExcluded(state, () => true), now);
  const noBenefit = coreDiff(noCore, now);
  const tierOf = (x) => (x ? verdictTier(x.diff, x.band, x.totalA) : null);
  // ① 의 티어는 판정 카드와 같은 가드 포함 티어다(MED-2) — ②·③ 은 한쪽만 등록된 항목이 이미 빠져 가드가 없다.
  const g = exMixed ? exMixed.diff : null;
  return {
    full: { ...full, tier: verdictTier(full.diff, full.band, full.totalA, g), unsureBy: unsureCause(full.diff, full.band, g) },
    exMixed: exMixed && { ...exMixed, tier: tierOf(exMixed) },
    noBenefit: { ...noBenefit, tier: tierOf(noBenefit) }, exMixedCore,
  };
}

/**
 * 「이직 후보에 물어볼 것」 — 조건을 못 채우면 그 줄은 없다(빈 배열 가능). 데이터만, 문장은 report.js.
 * wage: 임금 형태 하나로 결론이 뒤집히거나(①이 flip) 미선택 병치가 갈릴 때 · mixed: 이직 후보 쪽 금액이 없는
 * 혼합 항목 상위 2건 · topOnlyA: 현재 직장에만 있는 금액 항목 최댓값(복지 차이가 현재 직장 쪽으로 기울 때).
 */
export function askList(core, ctx) {
  const out = [];
  const { sens, wage, pairs } = ctx;
  const flip = sens && sens.rows.find((r) => r.key === 'b_wage_flip' && (r.flips || r.decides));
  if (flip) out.push({ kind: 'wage', amount: Math.abs(flip.otB - core.b.otPay) });
  else if (wage && wage.slots.includes('b') && (!wage.agree || wage.dir !== 0)) {
    const sep = wage.cases.find((c) => c.wage.b === 'separate');
    const inc = wage.cases.find((c) => c.wage.b === 'inclusive');
    if (sep && inc) out.push({ kind: 'wage', amount: Math.abs(sep.otB - inc.otB) });
  }
  const mixedAside = pairs.mixed.filter((r) => r.side === 'a').sort((x, y) => (amtOf(y.a) || 0) - (amtOf(x.a) || 0));
  if (mixedAside.length) out.push({ kind: 'mixed', names: mixedAside.slice(0, 2).map((r) => r.b.benefit_nm) });
  const benDiff = core.deltas.benDiff;
  if (benDiff < 0) {
    const top = pairs.onlyA.filter((it) => effAmt(it) > 0).sort((x, y) => effAmt(y) - effAmt(x))[0];
    if (top) out.push({ kind: 'topOnlyA', nm: top.benefit_nm, ctgr: catOf(top), amt: effAmt(top), share: effAmt(top) / Math.abs(benDiff) });
  }
  return out;
}

// 워라밸 축 4순위 재료 — 휴가(time_off)·근무제도(flexibility) 등록 항목(법정 제외).
function wlbItems(list) { return live(list).filter((it) => catOf(it) === 'time_off' || catOf(it) === 'flexibility'); }

/**
 * 세 축 판정 카드(데이터) — 세그먼트 전환은 재계산 0, 이 셋 중 하나를 고를 뿐이다.
 * 축마다 **판정 기준이 다르다**(요청 5): 연봉 = 실효 총보상 차 ± 폭 · 워라밸 = 입력 시간 → 통근 → 자율성 → 등록 수
 * · 복지 = 등록 금액 합 차 ± 폭(항목 수는 참고 표기만, 사용자 결정 1).
 */
export function buildAllVdCards(ctx) {
  const { core, band, parts, pairs, time, robust, sens, wage, tenure } = ctx;
  const T = AXIS_THRESHOLDS;
  const d = core.deltas.totalDiff;
  const guard = robust.exMixed ? robust.exMixed.diff : null;
  const salTier = verdictTier(d, band, core.a.total, guard);
  const salMid = core.deltas.salMid;
  const flip = sens.rows.find((r) => r.flips || r.decides) || null;
  // near 의 두 갈래 — 'small'(기준값의 3% 안: 정말 작다) · 'weak'(오차 범위를 겨우 넘었을 뿐 금액은 작지 않을 수 있다).
  const nearKind = (tier, diff, base) => (tier !== 'near' ? null : Math.abs(diff) <= Math.abs(base) * T.nearTotalPct ? 'small' : 'weak');
  // 야근수당 미선택(결정 4): 경우들이 같은 쪽을 가리키면 'range'(얼마나만 다르다) · 부호가 갈리거나 방향이 없는 경우가
  // 섞이면 'depends'(결론이 달라진다) · 모든 경우가 같은 비방향 티어면 그 티어 그대로(MED-3).
  let salAxisTier = salTier;
  if (wage && (!wage.agree || wage.anyDirectional)) salAxisTier = wage.dir !== 0 && wage.anyDirectional ? 'range' : 'depends';
  const dirSign = salAxisTier === 'range' ? wage.dir : Math.sign(d);
  const salary = {
    axis: 'salary', tier: salAxisTier, baseTier: salTier, unsureBy: unsureCause(d, band, guard), nearKind: nearKind(salTier, d, core.a.total),
    shape: salMid === 0 ? 'flat' : Math.sign(salMid) === dirSign ? 'same' : 'reverse',
    span: salAxisTier === 'range' ? wage.span : null,
    d, band, range: [d - band, d + band], guard: robust.exMixed,
    salA: core.a.salRange.mid, salB: core.b.salRange.mid, salMid,
    effRate: core.deltas.effRate,
    effRateNoOt: core.a.eff.mid ? (core.b.eff.mid - core.a.eff.mid) / core.a.eff.mid : null,
    monthly: Math.round(d / 12),
    parts: { sal: salMid, ben: core.deltas.benDiff, mixed: parts.mixed, ot: core.deltas.otDiff },
    hourly: time.hourly, flip, wage,
  };

  // 워라밸 — 위에서부터 보고 승패가 갈리면 멈춘다(FINAL-DESIGN §3-3 나).
  const cntA = wlbItems(core._benA).length, cntB = wlbItems(core._benB).length;
  const autoW = autonomyWinner(core.a.autonomy, core.b.autonomy);
  const steps = [
    ['hours', time.hours && Math.abs(time.hours.weekDiff) >= T.wlbWeekHrs ? (time.hours.weekDiff > 0 ? 'a' : 'b') : null],
    ['commute', time.commute && Math.abs(time.commute.annDiff) >= T.wlbCommuteAnnHrs ? (time.commute.annDiff > 0 ? 'a' : 'b') : null],
    ['autonomy', autoW === 'tie' ? null : autoW],
    ['count', Math.abs(cntA - cntB) >= T.wlbQualCount ? (cntA > cntB ? 'a' : 'b') : null],
  ];
  const hit = steps.find(([, w]) => w);
  const wlb = {
    axis: 'wlb', tier: hit ? hit[1] : 'unsure', decidedBy: hit ? hit[0] : null,
    hours: time.hours, hoursIn: time.hoursIn, commute: time.commute, commuteIn: time.commuteIn,
    autonomy: { perksA: core.a.autonomy, perksB: core.b.autonomy, winner: autoW },
    count: { a: cntA, b: cntB, tenureA: wlbItems(core._benA).filter((it) => facetOf(it).tenure).length },
    money: { tier: salTier, d },
  };

  // 복지 — 등록 금액 합의 차이 ± 폭, 가드 = 한쪽만 금액 등록 제외 값(사용자 결정 1).
  const bd = core.deltas.benDiff;
  const mixedBand = sumBy(pairs.mixed, (r) => {
    const it = r.side === 'a' ? r.a : r.b;
    return effAmt(it) * bandCoeff(it, ctx.now);
  });
  // 기준값 = 복지 금액 합(큰 쪽) — 총보상을 쓰면 연봉 렌즈가 섞여 고연봉자에게 복지 250만원 차이도 「거의 같음」이 된다(실측).
  const benBase = Math.max(core.a.net, core.b.net);
  const exMixedBen = pairs.mixed.length ? { diff: bd - parts.mixed, band: Math.max(0, band - mixedBand) } : null;
  if (exMixedBen) exMixedBen.tier = verdictTier(exMixedBen.diff, exMixedBen.band, benBase);
  // 두 회사 모두 금액이 등록된 복지가 없으면(합 0 · 0) 「거의 같음」이 아니라 금액으로는 말할 수 없다.
  const noAmounts = !core.a.net && !core.b.net;
  const benGuard = exMixedBen ? exMixedBen.diff : null;
  const benTier = noAmounts ? 'unsure' : verdictTier(bd, band, benBase, benGuard);
  const liveA = live(core._benA), liveB = live(core._benB);
  const mixedSides = new Set(pairs.mixed.map((r) => r.side));
  const benefits = {
    axis: 'benefits', tier: benTier, unsureBy: noAmounts ? 'none' : unsureCause(bd, band, benGuard), noAmounts,
    nearKind: nearKind(benTier, bd, benBase), d: bd, band, exMixed: exMixedBen,
    netA: core.a.net, netB: core.b.net,
    counts: { a: liveA.length, b: liveB.length, onlyA: pairs.onlyA.length, onlyB: pairs.onlyB.length,
      both: pairs.bothAmt.length + pairs.mixed.length + pairs.bothQual.length },
    noAmt: { a: liveA.filter((it) => amtOf(it) == null).length, b: liveB.filter((it) => amtOf(it) == null).length },
    mixed: {
      count: pairs.mixed.length, net: parts.mixed, side: mixedSides.size === 1 ? [...mixedSides][0] : (mixedSides.size ? 'both' : null),
      names: pairs.mixed.map((r) => (r.side === 'a' ? r.a : r.b))
        .sort((x, y) => (amtOf(y) || 0) - (amtOf(x) || 0)).map((it) => it.benefit_nm), // 금액 큰 순
      share: bd && Math.sign(parts.mixed) === Math.sign(bd) ? Math.abs(parts.mixed) / Math.abs(bd) : null,
    },
    salOffset: { salMid, benDiff: bd, gap: salMid + bd },
    tenure: { a: tenure.a.length, b: tenure.otherSideCount },
  };
  return { salary, wlb, benefits };
}

/** 자료 근거(와플·배지 설명) — 금액 출처(공식/추정)·금액 없음·최대/한도·만료 여부. */
function basisOf(listA, listB, now) {
  const side = (list) => {
    const L = live(list);
    const amt = L.filter((it) => amtOf(it) != null);
    return {
      total: L.length, amt: amt.length, qual: L.length - amt.length,
      stated: amt.filter((it) => it.amt_source === 'stated').length,
      estimated: amt.filter((it) => it.amt_source !== 'stated').length,
      capped: cappedRows(L).map((it) => ({ nm: it.benefit_nm, amt: amtOf(it) })),
      expired: amt.filter((it) => it.expires_dtm != null && Date.parse(it.expires_dtm) < now).length,
      legal: (list || []).filter((it) => it && it.legal_yn).length,
    };
  };
  const all = [...live(listA), ...live(listB)].filter((it) => amtOf(it) != null && it.expires_dtm);
  const earliest = all.map((it) => it.expires_dtm).sort()[0] || null;
  return { a: side(listA), b: side(listB), earliestExpiry: earliest };
}

/**
 * 계산기 전용 산출 묶음 — compare() 가 핵심 수치에 덧붙인다. 감도·임금 시나리오는 compareCore 만 다시 부른다.
 */
export function calculatorExtras(state, core, now = Date.now()) {
  const benA = state.benS.a || [], benB = state.benS.b || [];
  const pairs = classifyPairs(benA, benB);
  // 양쪽 다 금액인 짝은 항목 단위 판정(pairVerdict — 폭이 겹치면 「비슷함」)과 두 폭을 함께 싣는다(표시용).
  const range = (it) => { const v = amtOf(it), c = bandCoeff(it, now); return [v * (1 - c), v * (1 + c)]; };
  pairs.bothAmt = pairs.bothAmt.map((r) => ({ ...r, verdict: pairVerdict(r.a, r.b, now), rangeA: range(r.a), rangeB: range(r.b) }));
  const parts = benDiffParts(benA, benB, pairs);
  const band = deltaBand(core.a, core.b);
  const time = timeSheet(core, state.commuteIn);
  const robust = robustness(state, core, now, { pairs });
  const sens = sensitivity(state, core, now, { pairs, guardD: robust.exMixed ? robust.exMixed.diff : null });
  const wage = wageScenarios(state, core, now, { pairs });
  const tenure = tenureGate(benA, benB, state.tenureYears);
  const breakeven = breakevenRate(core, robust.exMixedCore, state.wsState.b);
  const axes = buildAllVdCards({ core: { ...core, _benA: benA, _benB: benB }, band, parts, pairs, time, robust, sens, wage, tenure, now });
  const { exMixedCore: _drop, ...robustOut } = robust; // 코어 통째는 브레이크이븐 재료일 뿐 — 반환하지 않는다
  return {
    band: { a: core.a.sumBand, b: core.b.sumBand, delta: band },
    pairs, parts, cat: catProfile(benA, benB, now), time, robust: robustOut, sens, wage, tenure, breakeven,
    ask: askList(core, { sens, wage, pairs }), axes, basis: basisOf(benA, benB, now),
  };
}
