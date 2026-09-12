// web/assets/js/benefits.js — 모드 A 「복지 비교」(`#view-benefits`) — SPEC 19 SP-CMP.
//
// 내 숫자를 넣지 않고 두 회사 복지를 나란히 보는 화면이다. 데이터는 **부팅 번들 하나**뿐이고
// (추가 네트워크 0바이트) 새 URL·새 API·새 DB 컬럼·번들 필드 추가는 전부 0 이다.
//
// 이 파일이 지키는 규칙 넷 — 넷 다 「어기면 화면이 거짓말을 한다」 쪽이다:
//
//   ① **빈칸은 언제나 「등록 없음」**(SP-CMP-3). 스키마에 「이 회사에 이 제도가 없다」를 적을 자리가
//      없다 — 긍정 행만 있다. 그래서 A 에 있고 B 에 없는 코드는 「B 등록 없음」이지 「B 제도 없음」이
//      아니다. 임의 쌍에서 한쪽만 있는 행이 합집합의 중앙 71.4% 라, 이 낱말을 틀리면 화면 대부분이
//      거짓 진술이 된다. 0 을 말로 바꾸는 함수는 `radar.js::fmt` **하나**다.
//   ② **금액 합계·순위·「더 낫다/우세」 없음**(D-6). 등록 금액에는 대출 한도·일회성 포상이 섞여
//      있어 그 합의 우열은 무엇으로 표현하든 거짓이다. `benTotal`·`renderBenefitHeadline` 을 여기서
//      부르지 않고, 도형 넓이·막대 길이를 점수로 바꾸는 문장도 두지 않는다.
//   ③ **광고 0**. `mountAds` 호출이 이 파일에 없다(셸의 `data-page-type=input` 도 그대로).
//   ④ **데이터 문자열은 `dom.js::el` 로만**(NFR21). 회사명에 `&` 가 있고(삼성E&A) 복지 설명은
//      회사가 쓴 자유 문장이다. 유일한 예외는 9각형 SVG 인데, 그쪽은 `radar.js` 가 값마다
//      파이썬과 **같은 이스케이프**를 걸어 문자열을 만든다(바이트 일치가 그 파일의 계약이다).
//
// 배지 계보(`badge.js`)는 이 화면에 없다 — 2,032행이 전부 official 이라 모든 쌍이 같은 결과다.
// 금액 옆 칩은 **금액 출처**(`amt_source`)이지 출처 계보가 아니다. 두 축을 한 낱말로 섞지 않는다.

import { el } from './dom.js';
import { CATEGORY_ORDER, CATEGORY_LABEL } from './categories.js';
import { fmt, radarPairSvg } from './radar.js';
import { matchBenefitRows } from './report.js';
import { pairVerdict } from './calc.js';
import { companyHref } from './directory.js';

// 근무형태 5축 — 정본은 `generator/pages/combo.py::_WS_KEYS`. `true` 만 사실이고 `false`·`null` 은
// 「표기 없음」이다(overtime 은 126사 전부 null — 「야근 없음」이라고 쓰면 126번 거짓말이 된다).
export const WS_KEYS = ['remote', 'flex', 'unlimitedPTO', 'refreshLeave', 'overtime'];
export const WS_LABEL = {
  remote: '재택근무',
  flex: '유연근무',
  unlimitedPTO: '무제한 휴가',
  refreshLeave: '리프레시 휴가',
  overtime: '야근 있음(고지)',
};

/** 금액 출처 칩 문구. 정성 항목에는 금액이 없으므로 이 칩도 없다(「정성」 표식을 대신 단다). */
export const AMT_SOURCE_LABEL = { stated: '공식 수치', estimated: '추정치' };

/**
 * **두 슬롯이 확정되면 어디로 가는가** — 이 판정의 집은 여기 하나다 (SP-CMP-2).
 *
 * 부팅 폴백(`app.js::resolveBootScreen`)과 검색 뷰 전진(`ui.js::maybeAdvance`)이 같은 답을 써야
 * 한다. 두 곳에 따로 적으면 「주소로 들어오면 비교, 검색으로 고르면 입력」처럼 경로마다 다른
 * 화면이 뜨고, 그런 화면은 버그가 아니라 **설계가 둘**인 상태라 고치기 어렵다.
 *
 * `ui.js` 가 `app.js` 를 import 하면 순환이 되므로(앱이 UI 를 부른다) 집을 이 모듈에 둔다 —
 * 목적지가 곧 이 화면이기도 하다.
 */
export function pairTarget() {
  return 'benefits';
}

// 「등록 없음」의 출처도 `fmt` 하나다(SP-CMP-3) — 리터럴을 따로 두면 한쪽만 바뀌는 날이 온다.
export const NONE = fmt(0);
export const NONE_LEGEND = '‘등록 없음’은 이 사이트에 등록되지 않았다는 뜻이며, 제도가 없다는 확인이 아닙니다.';

// ── 순수 계산 ────────────────────────────────────────────────────────────────

/**
 * 파이썬 `round(x, 2)` 와 **같은 답**. 9각형 좌표가 이 평균에서 나오고 그 좌표는 정적 페이지와
 * 바이트 일치여야 하므로, 「거의 같다」로는 부족하다.
 *
 * 갈리는 지점은 **정확한 동점**뿐이다. 파이썬은 짝수 쪽으로, `Math.round` 는 위로 간다.
 * 그리고 2자리 반올림에서 정확한 동점은 `x = 홀수/8` 일 때만 생긴다 — (2n+1)/200 이 이진수로
 * 딱 떨어지려면 분자가 25 의 배수여야 하고, 그러면 x 는 m/8(m 홀수)이 된다. 회사 수가 8의
 * 배수이면 실제로 나온다(항목 1 / 8곳 = 0.125 → 파이썬 0.12).
 *
 * 🚨 **판정에 `x * 200` 을 쓰면 안 된다**(2026-09-12 검증에서 잡힌 오답). ×8 은 2의 거듭제곱이라
 * 무손실이지만 ×200 은 ×25 를 포함해 무손실이 아니다 — 비이진 값이 정수로 반올림돼 **동점으로
 * 오판**된다. 실제 오답: 3/120 = 0.025 → 0.02(파이썬 0.03) · 7/40 = 0.175 → 0.18(파이썬 0.17) ·
 * 2.675 → 2.68(파이썬 2.67). 회사 수 120·160·200·240 에서 정적과 도구의 좌표가 갈렸을 것이다.
 *
 * 동점이 아니면 `toFixed(2)` 를 그대로 쓴다. 그 연산은 **더블의 정확한 값**을 보고 가장 가까운
 * 쪽을 고르므로 동점이 아닌 한 파이썬과 같은 답이다(`Math.round(x*100)` 은 곱에서 한 번 더
 * 반올림돼 다른 답이 나올 수 있다).
 */
export function round2(x) {
  const eighths = x * 8;                    // 2의 거듭제곱 곱은 무손실 — 정확히 m/8 일 때만 정수다
  if (Number.isInteger(eighths) && Math.abs(eighths) % 2 === 1) { // x = 홀수/8 = 정확한 동점
    const lo = Math.floor(x * 100);
    return (lo % 2 === 0 ? lo : lo + 1) / 100; // 짝수 쪽(파이썬 round 의 규칙)
  }
  return Number(x.toFixed(2));
}

/** 회사 하나의 카테고리별 등록 항목 수. 빈 카테고리는 0 이다(빼지 않는다 — 없는 축도 사실이다). */
export function perCategory(benefits, order = CATEGORY_ORDER) {
  const per = {};
  for (const k of order) per[k] = 0;
  for (const b of (benefits || [])) {
    const cat = b && b.benefit_ctgr_cd;
    if (cat in per) per[cat] += 1;
  }
  return per;
}

/**
 * 9각형·나비차트의 **눈금 기준**을 번들에서 런타임에 센다 (SP-CMP-4 ③).
 *
 * `generator/corpus.py::build` 와 **같은 정의**여야 한다: 분모는 전체 등록 회사 수이고, `rmax` 는
 * 전 회사·전 카테고리를 통틀어 한 카테고리의 최댓값(최소 1)이다. 번들에 필드를 더하지 않는 이유는
 * 하나 더 있다 — 더하면 `server/models/reference.py` 에도 선언해야 하고, 빠뜨리면 Pydantic 이
 * 조용히 떨군다(실발현 이력 있음).
 *
 * ⚠ 쌍마다 최댓값을 다시 잡지 마라. 그러면 회사를 바꿀 때마다 같은 숫자가 다른 크기로 그려져
 * 도형이 거짓말을 한다. 눈금의 뜻은 회사가 바뀌어도 같아야 한다.
 */
export function categoryStats(companies, order = CATEGORY_ORDER) {
  const list = Array.isArray(companies) ? companies : [];
  const sums = {};
  for (const k of order) sums[k] = 0;
  let rmax = 0;
  for (const c of list) {
    const per = perCategory(c && c.benefits, order);
    for (const k of order) {
      sums[k] += per[k];
      if (per[k] > rmax) rmax = per[k];
    }
  }
  const avgs = {};
  for (const k of order) avgs[k] = list.length ? round2(sums[k] / list.length) : 0;
  return { total: list.length, avgs, rmax: Math.max(rmax, 1) };
}

/**
 * 항목 대조표의 행 — `benefit_cd` 로 짝지은 **합집합**(SP-CMP-6). 한쪽만 있는 행을 숨기지 않는다:
 * 그 행이 곧 차별점이고, 숨기면 거짓 동률이 된다.
 *
 * 짝짓기 키·정렬 규칙은 리포트와 **같은 함수**(`report.js::matchBenefitRows`)가 소유한다. 여기서
 * 다시 구현하면 두 화면이 같은 쌍을 다르게 짝짓는 날이 온다. 다른 것은 모집단뿐이다 — 이 화면엔
 * 체크박스가 없어 `requireChecked:false` 로 부른다.
 */
export function pairRows(benA, benB) {
  return matchBenefitRows(benA || [], benB || [], { requireChecked: false });
}

/** 스탯 타일 4 + 집계 문장이 쓰는 수. 전부 **세어서 나오는 사실**이다(추정치 없음). */
export function summaryCounts(rows) {
  const out = { a: 0, b: 0, common: 0, onlyA: 0, onlyB: 0, onlyOne: 0, union: 0 };
  for (const r of (rows || [])) {
    out.union += 1;
    if (r.a) out.a += 1;
    if (r.b) out.b += 1;
    if (r.a && r.b) out.common += 1;
    else if (r.a) out.onlyA += 1;
    else out.onlyB += 1;
  }
  out.onlyOne = out.onlyA + out.onlyB;
  return out;
}

const hasAmount = (it) => !!(it && !it.qual_yn && it.benefit_amt != null);

/**
 * 금액 맞대결 행 — **양쪽 모두 금액이 적힌** 공통 코드만 (SP-CMP-6). 임의 쌍의 41.8% 는 0건이라
 * 0 이면 표 대신 문장 하나를 낸다(호출부가 길이로 판단한다).
 */
export function amountDuels(rows, now = Date.now()) {
  return (rows || [])
    .filter((r) => hasAmount(r.a) && hasAmount(r.b))
    .map((r) => ({ ...r, verdict: pairVerdict(r.a, r.b, now) }));
}

/** `·` 로 잇는 목록. 문장 안에 들어가는 짧은 나열은 이 프로젝트 어디서나 이 구분자다. */
const joinDot = (xs) => xs.join('·');

/**
 * 축별 문장 (SP-CMP-7). `n` 이 0 이면 **그 절을 통째로 뺀다** — 「0개입니다」는 읽는 사람에게
 * 아무것도 주지 않으면서 문장을 길게 만든다.
 *
 * 「더 낫다」·「우세」는 쓰지 않는다: 항목 수는 질이 아니다(대출 한도 하나와 사내 카페 하나가
 * 같은 1 이다). 「더 많다」는 세어서 나오는 사실이라 쓴다.
 */
export function axisSentence(countsA, countsB, aNm, bNm, order = CATEGORY_ORDER) {
  const moreA = [];
  const moreB = [];
  let tied = 0;
  const bothZero = [];
  order.forEach((k, i) => {
    const a = countsA[i];
    const b = countsB[i];
    if (a > b) moreA.push(CATEGORY_LABEL[k]);
    else if (b > a) moreB.push(CATEGORY_LABEL[k]);
    else {
      tied += 1;
      if (!a) bothZero.push(CATEGORY_LABEL[k]);
    }
  });
  const clauses = [];
  if (moreA.length) clauses.push(`${aNm} 쪽 항목이 더 많은 곳은 ${moreA.length}개(${joinDot(moreA)})`);
  if (moreB.length) clauses.push(`${bNm} 쪽이 더 많은 곳은 ${moreB.length}개(${joinDot(moreB)})`);
  if (tied) clauses.push(`같은 곳은 ${tied}개`);
  const head = clauses.length
    ? `${order.length}개 카테고리 중 ${clauses.join(', ')}입니다.`
    : `${order.length}개 카테고리를 나란히 놓았습니다.`;
  // 0 대 0 을 「같다」로만 적으면 「둘 다 갖췄다」로 읽힌다 — 같은 자리가 **둘 다 빈칸**이라는
  // 사실을 따로 말한다(아티팩트 목업의 두 번째 문장).
  return bothZero.length
    ? `${head} ${joinDot(bothZero)}은 두 회사 모두 ${NONE}입니다.`
    : head;
}

/**
 * 집계 문장 (SP-CMP-7). 마지막 절은 금액이 양쪽 다 적힌 항목의 **판정 구성**인데, 이것을
 * 「종합 우세」로 합치지 않는다 — 아래 「금액 맞대결」 표가 항목마다 말하는 것을 세어 준 것뿐이다.
 */
export function aggregateSentence(counts, duels, aNm, bNm) {
  const lines = [
    `두 회사에 공통으로 등록된 복지는 ${counts.common}개이고, 합쳐서 ${counts.union}개 항목이 등록돼 있습니다.`,
  ];
  const more = [];
  if (counts.onlyA) more.push(`${aNm} 쪽에 ${counts.onlyA}개`);
  if (counts.onlyB) more.push(`${bNm} 쪽에 ${counts.onlyB}개`);
  if (more.length) lines.push(`${more.join(', ')}가 더 등록돼 있습니다.`);
  if (!duels.length) {
    lines.push('금액이 양쪽 모두 적힌 항목은 없습니다.');
    return lines.join(' ');
  }
  lines.push(`금액이 양쪽 모두 적힌 항목은 ${duels.length}개입니다.`);
  const by = { same: 0, unsure: 0, a: 0, b: 0 };
  for (const d of duels) by[d.verdict] += 1;
  const parts = [];
  if (by.same) parts.push(`금액이 같은 항목은 ${by.same}개`);
  if (by.unsure) parts.push(`오차 범위가 겹쳐 차이를 말할 수 없는 항목은 ${by.unsure}개`);
  if (by.a) parts.push(`${aNm} 쪽이 큰 항목은 ${by.a}개`);
  if (by.b) parts.push(`${bNm} 쪽이 큰 항목은 ${by.b}개`);
  if (parts.length) lines.push(`그중 ${parts.join(', ')}입니다.`);
  return lines.join(' ');
}

const DATE10 = /^(\d{4})-(\d{2})-(\d{2})/;

/**
 * ISO 문자열 → 「2026년 4월 15일」. 못 읽으면 null(문장에서 그 절이 통째로 빠진다).
 *
 * 🚨 **`Date` 를 거치지 않는다.** 확인일은 「그날 확인했다」는 사실이지 시각이 아니다 — 시간대
 * 개념이 없다. 그런데 `verified_dtm` 은 오프셋 없는 문자열(`2026-04-15T00:00:00`)이라
 * `Date.parse` 가 **로컬 시각**으로 읽고, 거기서 `getUTC*` 를 꺼내면 KST 브라우저에서 날짜가
 * 하루 앞으로 밀린다(4월 15일 → 4월 14일). 보는 사람의 시간대에 따라 사실이 달라지는 화면은
 * 틀린 화면이다.
 *
 * 그래서 앞 10자만 쓴다. 최신값 비교도 그 10자의 **사전순**이다 — `YYYY-MM-DD` 는 사전순과
 * 날짜순이 같아서 파싱 없이 안전하다.
 */
export function verifiedText(items) {
  let best = null;
  for (const it of (items || [])) {
    const m = DATE10.exec(String((it && it.verified_dtm) || ''));
    if (!m) continue;
    if (best == null || m[0] > best[0]) best = m;
  }
  if (best == null) return null;
  return `${+best[1]}년 ${+best[2]}월 ${+best[3]}일`;
}

/**
 * 신뢰도 문장 (SP-CMP-7). 수는 전부 번들에서 **센다** — 「대부분」·「대체로」 같은 말을 쓰지 않는다.
 * 공식/추정 비율이 쌍마다 크게 달라서(NAVER 공식 7·추정 5 / 카카오 공식 2·추정 6) 뭉뚱그리면
 * 읽는 사람이 두 회사를 같은 신뢰도로 오해한다.
 */
export function trustSentence(items, nm) {
  const list = items || [];
  const amt = list.filter(hasAmount);
  const stated = amt.filter((b) => b.amt_source === 'stated').length;
  const est = amt.length - stated;
  const when = verifiedText(list);
  const head = when
    ? `${nm} 의 ${list.length}개 항목은 회사 공식 페이지에서 수집했고 ${when}에 확인했습니다.`
    : `${nm} 의 ${list.length}개 항목은 회사 공식 페이지에서 수집했습니다.`;
  if (!amt.length) return `${head} 금액이 적힌 항목은 없습니다.`;
  return `${head} 금액이 적힌 항목은 ${amt.length}개이며 그중 공식 수치는 ${stated}개, 추정치는 ${est}개입니다.`;
}

/** 근무형태 5축 대조. `true` 만 「제공」이고 나머지는 전부 「표기 없음」이다(허위 표기 금지). */
export function workStyleRows(wsA, wsB) {
  const a = wsA || {};
  const b = wsB || {};
  return WS_KEYS.map((k) => ({
    key: k,
    label: WS_LABEL[k],
    a: a[k] === true,
    b: b[k] === true,
  }));
}

/** 카테고리 하나의 회사별 목록(펼침 패널). 코드로 짝짓지 않는다 — 짝짓기는 항목 대조표의 몫이다. */
export function categoryItems(benefits, cat) {
  return (benefits || []).filter((b) => b && b.benefit_ctgr_cd === cat);
}

/** 「120만원」 · 정성이면 null. 금액은 **만원 단위 정수**라 소수점이 없다. */
export function amountText(item) {
  if (!hasAmount(item)) return null;
  return `${Number(item.benefit_amt).toLocaleString('ko-KR')}만원`;
}

/** 항목 하나의 값 표기 — 금액이 있으면 금액, 정성이면 설명 원문, 둘 다 없으면 「등록 없음」. */
export function valueText(item) {
  if (!item) return NONE;
  const amt = amountText(item);
  if (amt) return amt;
  return item.qual_desc_ctnt || item.benefit_nm || NONE;
}

export { fmt };

// ── 렌더 ─────────────────────────────────────────────────────────────────────
//
// 전부 `dom.js::el`(textContent·setAttribute)로만 만든다. 회사명에 `&`(삼성E&A)가 있고 복지
// 설명은 회사가 쓴 자유 문장이다 — 데이터 문자열이 innerHTML 에 닿는 경로는 9각형 하나뿐이고,
// 그쪽은 `radar.js` 가 값마다 이스케이프를 걸어 문자열을 만든다(바이트 일치가 그 파일의 계약).

/** 섹션 껍데기 — 제목은 h3 다(뷰의 첫 헤딩 h2 「복지 비교」에 포커스가 가야 하므로). */
function section(title, cls) {
  const s = el('section', { class: `cmp-sec ${cls}` });
  s.append(el('h3', { text: title }));
  return s;
}

/** 슬롯 표식 — 색만으로 정체성을 주지 않는다(A 원·B 네모). 화면 읽는 사람에겐 이름이 따라붙는다. */
function slotKey(slot) {
  return el('i', { class: `cmp-key cmp-key-${slot}`, 'aria-hidden': 'true' });
}

/** 금액 출처 칩. 정성 항목에는 붙이지 않는다 — 없는 금액의 출처는 없다. */
function sourceChip(item) {
  const label = AMT_SOURCE_LABEL[item && item.amt_source];
  if (!label) return null;
  return el('span', { class: `cmp-chip${item.amt_source === 'estimated' ? ' est' : ''}`, text: label });
}

/** 조건부 클래스. `el()` 은 `class` 를 className 에 그대로 넣어서 null 이 문자열 "null" 이 된다. */
function cls(on, name) {
  return on ? { class: name } : {};
}

/** 금액 셀 한 칸 — 「120만원 + 출처 칩」 / 정성이면 설명 원문 / 없으면 「등록 없음」. */
function valueCell(item) {
  const td = el('td', cls(!item, 'cmp-none'));
  if (!item) { td.append(el('span', { text: NONE })); return td; }
  const amt = amountText(item);
  if (amt) {
    td.append(el('span', { class: 'num', text: amt }));
    const chip = sourceChip(item);
    if (chip) td.append(chip);
  } else {
    td.append(el('span', { text: valueText(item) }));
  }
  return td;
}

/**
 * 항목 이름 칸. 두 회사가 같은 코드에 **다른 이름**을 쓰는 일이 흔하다(실측: 공통 행의 다수).
 * 한쪽 이름만 쓰면 A 의 낱말로 B 의 항목까지 부르게 되고, 「A·B 바꾸기」를 누르면 표의 이름이
 * 통째로 바뀐다 — 같은 화면이 같은 사실을 두 가지로 말하는 셈이다. 그래서 다르면 병기한다.
 */
function nameCell(row) {
  const td = el('td');
  const { nmA, nmB } = row;
  if (nmA && nmB && nmA !== nmB) {
    td.append(el('span', { text: nmA }));
    td.append(el('span', { class: 'cmp-nm-b', text: ` / ${nmB}` }));
  } else {
    td.append(el('span', { text: nmA || nmB || row.nm }));
  }
  return td;
}

/** 표 하나(머리 + 몸통). 폭이 넘치면 가로 스크롤은 CSS 가 `.cmp-tw` 에서 맡는다. */
function table(headCells, rows) {
  const wrap = el('div', { class: 'cmp-tw' });
  const t = el('table', { class: 'cmp-t' });
  const thead = el('thead');
  const tr = el('tr');
  for (const c of headCells) tr.append(c instanceof Object && c.tagName ? c : el('th', { text: c }));
  thead.append(tr);
  t.append(thead);
  const tbody = el('tbody');
  for (const r of rows) tbody.append(r);
  t.append(tbody);
  wrap.append(t);
  return wrap;
}

/** 회사 이름이 붙은 표 머리 — 슬롯 표식을 함께 단다(9각형·막대와 같은 모양). */
function companyTh(slot, nm) {
  const th = el('th');
  th.append(slotKey(slot), el('span', { text: nm }));
  return th;
}

const frac = (v, rmax) => (rmax ? v / rmax : 0);
const pct = (v, rmax) => `${(frac(v, rmax) * 100).toFixed(2)}%`;

/** 라벨을 막대 안쪽에 넣기 시작하는 지점 — 이보다 길면 바깥에 둘 자리가 없다. */
export const LABEL_INSIDE_FROM = 0.85;

/**
 * 나비차트 숫자 라벨의 자리 (SP-CMP-5).
 *
 * 규칙 셋, 전부 「겹치면 둘 다 못 읽는다」에서 나온다:
 *   1. 막대 끝 바깥 6px 이 기본이다.
 *   2. 그 자리가 **평균 세로 눈금보다 안쪽**이면 눈금 바깥으로 민다 — 막대가 짧은 카테고리에서
 *      숫자가 눈금 위에 얹혀 둘 다 안 읽혔다(360px 실측: 건강·가족의 B 「2」).
 *      「등록 없음」이 이미 쓰던 규칙과 **같은 규칙**이다(길이 0 은 이 규칙의 한 경우일 뿐이다).
 *   3. 막대가 날개를 거의 다 채우면(≥ 85%) 바깥에 자리가 없다 — 날개 밖으로 4px 삐져나갔다
 *      (복리후생 「7」). 그때는 막대 **안쪽 끝**에 흰 글자로 넣는다.
 *
 * 반환 `{ pos, inside }` — `pos` 는 0~1 비율(호출부가 `calc(pos% ± 6px)` 로 쓴다).
 */
export function valueLabelPlacement(n, avg, rmax) {
  const bar = frac(n, rmax);
  if (n > 0 && bar >= LABEL_INSIDE_FROM) return { pos: bar, inside: true };
  return { pos: Math.max(bar, frac(avg, rmax)), inside: false };
}

// ① 한눈 요약 — 9각형 겹침 + 타일 4 + 문장 2
function renderSummary(vm) {
  const sec = section('한눈 요약', 'cmp-summary');
  const cols = el('div', { class: 'cmp-sum2' });

  const fig = el('div', { class: 'cmp-rdwrap' });
  // 유일한 innerHTML 경로. `radar.js` 가 회사명·라벨을 전부 이스케이프한 문자열을 만든다 —
  // 그 계약이 깨지면 여기가 구멍이 되므로 radar.test.js 가 `<script>` 회사명으로 지킨다.
  fig.innerHTML = radarPairSvg(vm.countsA, vm.countsB, vm.avgs, vm.labels, vm.rmax, vm.aNm, vm.bNm);

  const key = el('div', { class: 'cmp-rdkey' });
  key.append(
    el('span', {}, slotKey('a'), el('span', { text: vm.aNm })),
    el('span', {}, slotKey('b'), el('span', { text: vm.bNm })),
    el('span', {}, el('i', { class: 'cmp-key cmp-key-avg', 'aria-hidden': 'true' }),
      el('span', { text: `${vm.total}개사 평균` })),
    el('span', {}, el('i', { class: 'cmp-key cmp-key-tie', 'aria-hidden': 'true' }),
      el('span', { text: '겹친 표식 = 같은 값' })),
  );
  fig.append(key);
  // 도형이 말할 수 있는 것과 없는 것을 여기서 못 박는다 — 겹친 넓이는 「같은 항목」이 아니다.
  fig.append(el('p', {
    class: 'cmp-rdcap',
    text: `축 = 카테고리별 등록 항목 수(금액 아님) · 눈금 ${vm.rmax} = ${vm.total}개사 중 한 카테고리 `
      + '최댓값(회사 상세와 같은 눈금) · 겹친 곳 = 두 회사 모두 그 수까지 등록된 범위(같은 항목이라는 '
      + `뜻은 아니다 — 공통 항목은 옆의 「공통 ${vm.counts.common}」이 센다) · 중심 = ${NONE}`,
  }));
  cols.append(fig);

  const right = el('div', { class: 'cmp-sumright' });
  const tiles = el('div', { class: 'cmp-stat4' });
  const tile = (n, labelNode) => {
    const d = el('div');
    d.append(el('span', { class: 'cmp-stat-n num', text: String(n) }));
    d.append(labelNode);
    return d;
  };
  const withKey = (slot, text) => {
    const s = el('span', { class: 'cmp-stat-l' });
    s.append(slotKey(slot), el('span', { text }));
    return s;
  };
  tiles.append(
    tile(vm.counts.a, withKey('a', `${vm.aNm} 항목`)),
    tile(vm.counts.b, withKey('b', `${vm.bNm} 항목`)),
    tile(vm.counts.common, el('span', { class: 'cmp-stat-l', text: '공통' })),
    tile(vm.counts.onlyOne, el('span', { class: 'cmp-stat-l', text: '한쪽에만' })),
  );
  right.append(tiles);
  right.append(el('p', { class: 'cmp-say', text: vm.axisLine }));
  right.append(el('p', { class: 'cmp-say', text: vm.aggregateLine }));
  cols.append(right);

  sec.append(cols);
  return sec;
}

// ② 카테고리별 — 나비차트 + 카테고리 클릭 펼침
function categoryPanel(vm, cat, label) {
  const panel = el('div', { class: 'cmp-bf-panel', id: `cmp-bf-p-${cat}` });
  panel.hidden = true; // 속성이 아니라 프로퍼티로 — 토글도 프로퍼티라 한 벌로 맞춘다
  const grid = el('div', { class: 'cmp-bfp2' });
  for (const slot of ['a', 'b']) {
    const items = categoryItems(vm.ben[slot], cat);
    const col = el('div', { class: `cmp-bfp-col cmp-bfp-${slot}` });
    const head = el('h4');
    head.append(slotKey(slot), el('span', { text: `${vm[`${slot}Nm`]} · ${label} ${fmt(items.length)}` }));
    col.append(head);
    const ul = el('ul');
    if (!items.length) {
      ul.append(el('li', { class: 'cmp-none', text: NONE }));
    } else {
      for (const it of items) {
        const li = el('li');
        li.append(el('b', { text: it.benefit_nm }));
        const amt = amountText(it);
        if (amt) {
          li.append(el('span', { class: 'cmp-amt num', text: amt }));
          const chip = sourceChip(it);
          if (chip) li.append(chip);
        } else {
          // 「정성」은 금액 출처가 아니라 **금액이 없다**는 표식이다(칩과 모양을 달리한다).
          li.append(el('span', { class: 'cmp-qual', text: '정성' }));
        }
        ul.append(li);
      }
    }
    col.append(ul);
    grid.append(col);
  }
  panel.append(grid);
  return panel;
}

function renderButterfly(vm) {
  const sec = section('카테고리별', 'cmp-butterfly');
  sec.append(el('p', {
    class: 'cmp-say',
    text: `9각형과 같은 숫자를 나비차트로 — 왼쪽 막대가 ${vm.aNm}, 오른쪽 막대가 ${vm.bNm}, 가운데가 `
      + `카테고리입니다. 눈금은 양쪽 모두 0~${vm.rmax} 로 같고 세로 눈금이 ${vm.total}개사 평균입니다. `
      + '카테고리를 누르면 그 카테고리에 각 회사가 등록한 복지 목록이 펼쳐지고, 다시 누르면 접힙니다.',
  }));

  const bf = el('div', { class: 'cmp-bf' });
  const head = el('div', { class: 'cmp-bf-head' });
  const hl = el('span', { class: 'cmp-bf-hl' });
  hl.append(slotKey('a'), el('span', { text: `${vm.aNm} 항목 수` }));
  const hr = el('span', { class: 'cmp-bf-hr' });
  hr.append(slotKey('b'), el('span', { text: `${vm.bNm} 항목 수` }));
  head.append(hl, el('span', { class: 'cmp-bf-hc', text: '카테고리 (누르면 펼침)' }), hr);
  bf.append(head);

  // 눈금 — 양쪽 0~rmax 로 같다. 같은 자를 쓰지 않으면 좌우 길이를 비교할 수 없다.
  const scale = el('div', { class: 'cmp-bf-scale' });
  const ticks = (side) => {
    const box = el('div', { class: `cmp-bf-s${side === 'a' ? 'l' : 'r'}` });
    for (const k of [0, 2, 4, 6, 8]) {
      if (k > vm.rmax) continue;
      box.append(el('span', {
        style: `${side === 'a' ? 'right' : 'left'}:${pct(k, vm.rmax)}`, text: String(k),
      }));
    }
    return box;
  };
  const mid = el('div', { class: 'cmp-bf-sc' });
  mid.append(el('i', { class: 'cmp-key cmp-key-avg-v', 'aria-hidden': 'true' }),
    el('span', { text: `${vm.total}개사 평균` }));
  // 평균의 **실제 값**은 지금 세로 눈금의 자리와 `title` 에만 있다 — 터치 기기에는 호버가 없어
  // 그 숫자에 닿을 길이 없다. 아홉 값을 글로도 한 번 적어 둔다(화면에는 안 보인다).
  mid.append(el('span', {
    class: 'sr-only',
    text: ` — ${vm.labels.map((lb, k) => `${lb} ${vm.avgs[k]}`).join(', ')}`,
  }));
  scale.append(ticks('a'), mid, ticks('b'));
  bf.append(scale);

  const panels = [];
  vm.labels.forEach((label, i) => {
    const cat = vm.order[i];
    const row = el('div', { class: 'cmp-bf-row', 'data-cat': cat });
    const wing = (slot, n) => {
      const side = slot === 'a' ? 'right' : 'left';
      const box = el('div', { class: `cmp-bf-${slot === 'a' ? 'l' : 'r'}` });
      box.append(el('span', {
        class: 'cmp-bf-avg', style: `${side}:${pct(vm.avgs[i], vm.rmax)}`,
        title: `${vm.total}개사 평균 ${vm.avgs[i]}`,
      }));
      if (n > 0) {
        box.append(el('span', { class: `cmp-bf-bar cmp-bf-bar-${slot}`, style: `width:${pct(n, vm.rmax)}` }));
      }
      // 길이 0 막대는 눈에 안 보인다 — 그때도 **글자는 찍는다**(그 빈칸이 이 화면에서 가장
      // 흔한 사실이다). 자리는 길이와 무관하게 같은 규칙으로 정한다.
      const { pos, inside } = valueLabelPlacement(n, vm.avgs[i], vm.rmax);
      const at = `${(pos * 100).toFixed(2)}%`;
      box.append(el('span', {
        class: `cmp-bf-val${n > 0 ? ' num' : ' cmp-none'}${inside ? ' cmp-bf-val-in' : ''}`,
        style: `${side}:calc(${at} ${inside ? '-' : '+'} 6px)`,
        text: n > 0 ? String(n) : NONE,
      }));
      return box;
    };
    const btn = el('button', {
      type: 'button', class: 'cmp-bf-cat',
      'aria-expanded': 'false', 'aria-controls': `cmp-bf-p-${cat}`,
    });
    btn.append(el('span', { text: label }), el('span', { class: 'cmp-bf-chev', 'aria-hidden': 'true', text: '▾' }));
    row.append(wing('a', vm.countsA[i]), btn, wing('b', vm.countsB[i]));
    bf.append(row);
    const panel = categoryPanel(vm, cat, label);
    bf.append(panel);
    panels.push({ btn, panel });
  });

  const foot = el('div', { class: 'cmp-bf-foot' });
  const all = el('button', { type: 'button', class: 'cmp-btn cmp-bf-all', text: '모두 펼치기' });
  foot.append(all, el('span', {
    class: 'cmp-bf-note',
    text: `막대 = 등록 항목 수(금액 아님) · 눈금 ${vm.rmax} = ${vm.total}개사 중 한 카테고리 최댓값 · ${NONE_LEGEND}`,
  }));
  bf.append(foot);
  sec.append(bf);

  // 배선: 버튼 ↔ 패널. JS 가 죽어도 막대·숫자·「등록 없음」은 그대로 보이고 항목은 아래 대조표가
  // 대신한다(패널은 닫힌 채) — 그래서 여는 것만 JS 가 한다.
  const setOpen = (p, open) => {
    p.btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    p.panel.hidden = !open;
  };
  const syncAll = () => {
    const n = panels.filter((p) => p.btn.getAttribute('aria-expanded') === 'true').length;
    all.textContent = n === panels.length ? '모두 접기' : '모두 펼치기';
  };
  for (const p of panels) {
    p.btn.addEventListener('click', () => {
      setOpen(p, p.btn.getAttribute('aria-expanded') !== 'true');
      syncAll();
    });
  }
  all.addEventListener('click', () => {
    const open = all.textContent === '모두 펼치기';
    for (const p of panels) setOpen(p, open);
    syncAll();
  });
  return sec;
}

// ③ 금액 맞대결
export const VERDICT_TEXT = { same: '같음', unsure: '말할 수 없음' };

function renderDuels(vm) {
  const sec = section('금액 맞대결', 'cmp-duels');
  if (!vm.duels.length) {
    // 임의 쌍의 41.8% 가 여기다 — 빈 표를 그리지 않고 왜 없는지 말한다.
    sec.append(el('p', {
      class: 'cmp-say',
      text: `두 회사 모두 금액이 적힌 공통 항목이 없어 맞댈 수 있는 숫자가 없습니다. `
        + '항목이 겹치는지는 아래 「항목 대조표」가 보여 줍니다.',
    }));
    return sec;
  }
  sec.append(el('p', { class: 'cmp-say', text: '양쪽 모두 금액이 적힌 항목만 놓습니다.' }));
  const rows = vm.duels.map((d) => {
    const tr = el('tr');
    tr.append(nameCell(d));
    tr.append(valueCell(d.a));
    tr.append(valueCell(d.b));
    const txt = VERDICT_TEXT[d.verdict] || `${d.verdict === 'a' ? vm.aNm : vm.bNm} 가 큼`;
    tr.append(el('td', { ...cls(!!VERDICT_TEXT[d.verdict], 'cmp-none'), text: txt }));
    return tr;
  });
  sec.append(table(['항목', companyTh('a', vm.aNm), companyTh('b', vm.bNm), '판정'], rows));
  sec.append(el('p', {
    class: 'cmp-legend',
    text: '판정 = 두 구간 [금액×(1−c), 금액×(1+c)] 의 겹침. c 는 공식 수치 ±5%·추정치 ±20%'
      + '(이직 계산기의 밴드 계수와 같은 값, 새 계수 없음). 겹치면 「말할 수 없음」(값이 같으면 「같음」), '
      + '겹치지 않으면 큰 쪽. 총액 판정은 만들지 않습니다.',
  }));
  return sec;
}

// ④ 항목 대조표 — 합집합. 한쪽만 있는 행이 곧 차별점이라 숨기지 않는다.
function renderMatrix(vm) {
  const sec = section('항목 대조표', 'cmp-matrix');
  if (!vm.rows.length) {
    sec.append(el('p', { class: 'cmp-say', text: '두 회사 모두 등록된 복지가 없습니다.' }));
    return sec;
  }
  const rows = vm.rows.map((r) => {
    const tr = el('tr');
    tr.append(nameCell(r));
    tr.append(valueCell(r.a));
    tr.append(valueCell(r.b));
    return tr;
  });
  sec.append(table(['항목', companyTh('a', vm.aNm), companyTh('b', vm.bNm)], rows));
  sec.append(el('p', {
    class: 'cmp-legend',
    text: `${NONE_LEGEND} 「공식 수치」「추정치」는 금액 출처입니다.`,
  }));
  return sec;
}

// ⑤ 근무형태 — true 만 사실, 그 외는 「표기 없음」
export const WS_YES = '제공';
export const WS_UNKNOWN = '표기 없음';

function renderWorkStyle(vm) {
  const sec = section('근무형태', 'cmp-ws');
  const rows = vm.ws.map((w) => {
    const tr = el('tr');
    tr.append(el('td', { text: w.label }));
    for (const slot of ['a', 'b']) {
      tr.append(el('td', { ...cls(!w[slot], 'cmp-none'), text: w[slot] ? WS_YES : WS_UNKNOWN }));
    }
    return tr;
  });
  sec.append(table(['항목', companyTh('a', vm.aNm), companyTh('b', vm.bNm)], rows));
  sec.append(el('p', {
    class: 'cmp-legend',
    text: '「표기 없음」은 회사가 밝히지 않았거나 우리가 등록하지 않았다는 뜻입니다 — 제도가 없다는 확인이 아닙니다.',
  }));
  return sec;
}

// ⑥ 신뢰도·출처
function renderTrust(vm) {
  const sec = section('이 비교를 얼마나 믿을 수 있나', 'cmp-trust');
  sec.append(el('p', { class: 'cmp-say', text: trustSentence(vm.ben.a, vm.aNm) }));
  sec.append(el('p', { class: 'cmp-say', text: trustSentence(vm.ben.b, vm.bNm) }));
  return sec;
}

// ⑦ 다음 행동
function renderNext(vm, deps) {
  const sec = section('다음 행동', 'cmp-next');
  const nav = el('div', { class: 'cmp-next-row' });
  const toInput = el('button', { type: 'button', class: 'cmp-btn cmp-btn-primary', text: '이직 계산기 →' });
  toInput.addEventListener('click', () => { if (typeof deps.go === 'function') deps.go('input'); });
  nav.append(toInput);
  for (const slot of ['a', 'b']) {
    // slug 를 만들 수 없는 회사는 링크를 만들지 않는다(404 로 가는 링크는 링크 없는 것보다 나쁘다).
    const href = companyHref(vm.company[slot] && vm.company[slot].comp_eng_nm);
    if (href) nav.append(el('a', { class: 'cmp-btn', href, text: `${vm[`${slot}Nm`]} 복지 자세히 →` }));
  }
  nav.append(el('a', { class: 'cmp-btn', href: '/find', text: '복지검색으로 →' }));
  sec.append(nav);
  return sec;
}

/**
 * 화면 하나가 쓰는 사실을 **한 번에** 만든다. 렌더 함수들은 이 뷰모델만 읽는다 — 같은 수를 두
 * 곳에서 따로 세면 타일이 「공통 11」이라 말하고 표가 10행을 그리는 날이 온다.
 */
export function buildViewModel(state, { now = Date.now(), order = CATEGORY_ORDER } = {}) {
  const company = { a: state.matched.a, b: state.matched.b };
  const ben = {
    a: (state.benS && state.benS.a && state.benS.a.length ? state.benS.a : (company.a.benefits || [])),
    b: (state.benS && state.benS.b && state.benS.b.length ? state.benS.b : (company.b.benefits || [])),
  };
  const stats = categoryStats((state.REF && state.REF.companies) || [], order);
  const perA = perCategory(ben.a, order);
  const perB = perCategory(ben.b, order);
  const countsA = order.map((k) => perA[k]);
  const countsB = order.map((k) => perB[k]);
  const rows = pairRows(ben.a, ben.b);
  const counts = summaryCounts(rows);
  const duels = amountDuels(rows, now);
  const aNm = company.a.comp_nm;
  const bNm = company.b.comp_nm;
  return {
    order,
    labels: order.map((k) => CATEGORY_LABEL[k]),
    company,
    ben,
    aNm,
    bNm,
    countsA,
    countsB,
    avgs: order.map((k) => stats.avgs[k]),
    rmax: stats.rmax,
    total: stats.total,
    rows,
    counts,
    duels,
    ws: workStyleRows(company.a.work_style_val, company.b.work_style_val),
    axisLine: axisSentence(countsA, countsB, aNm, bNm, order),
    aggregateLine: aggregateSentence(counts, duels, aNm, bNm),
  };
}

/**
 * 모드 A 본문을 그린다. 두 슬롯이 다 차 있을 때만 그린다(한쪽만이면 비운다 — 반쪽 비교는
 * 비교가 아니다). 광고는 **마운트 호출 자체가 없다**(SP-CMP-2).
 *
 * ⚠ 9각형·나비는 viewBox·% 라 크기를 실측하지 않는다 — `#app` 이 hidden 인 채 그려도 깨지지
 * 않는다. 실측이 필요한 것은 덱뿐이고, 그것은 뷰가 보인 뒤 `app.js` 가 `measure()` 한다.
 */
export function mountBenefits(state, deps = {}) {
  const doc = deps.doc || (typeof document !== 'undefined' ? document : null);
  const root = deps.mountEl || (doc && doc.getElementById ? doc.getElementById('benefits-body') : null);
  if (!root) return null;
  if (!state.matched || !state.matched.a || !state.matched.b) {
    root.replaceChildren();
    return null;
  }
  const vm = buildViewModel(state, { now: deps.now || Date.now() });
  root.replaceChildren(
    renderSummary(vm),
    renderButterfly(vm),
    renderDuels(vm),
    renderMatrix(vm),
    renderWorkStyle(vm),
    renderTrust(vm),
    renderNext(vm, deps),
  );
  return vm;
}
