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

export const NONE = '등록 없음';
export const NONE_LEGEND = '‘등록 없음’은 이 사이트에 등록되지 않았다는 뜻이며, 제도가 없다는 확인이 아닙니다.';

// ── 순수 계산 ────────────────────────────────────────────────────────────────

/**
 * 파이썬 `round(x, 2)` 와 **같은 답**. `Math.round` 를 그냥 쓰면 정확한 동점에서 갈린다.
 *
 * 동점은 x 가 k/200(k 홀수)일 때만 생긴다 — 회사 수가 8의 배수이면 실제로 나온다(항목 1 / 8곳
 * = 0.125 → 파이썬 0.12, `Math.round` 0.13). 지금 126곳에서는 안 나오지만, 안 나오는 값에
 * 기대는 것과 규칙을 맞추는 것은 다르다: 9각형 좌표가 이 평균에서 나오고 그 좌표는 정적 페이지와
 * **바이트 일치**여야 한다.
 */
export function round2(x) {
  const q = x * 200;                       // 소수 비트가 적은 값만 정수가 된다(200 곱은 그때 무손실)
  if (Number.isInteger(q) && q % 2 !== 0) { // 정확히 .xx5 → 짝수 쪽
    const lo = Math.floor(x * 100);
    return (lo % 2 === 0 ? lo : lo + 1) / 100;
  }
  return Math.round(x * 100) / 100;
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

/** ISO 문자열 → 「2026년 4월 15일」. 못 읽으면 null(문장에서 그 절이 통째로 빠진다). */
export function verifiedText(items) {
  let best = null;
  for (const it of (items || [])) {
    const raw = it && it.verified_dtm;
    if (!raw) continue;
    const t = Date.parse(raw);
    if (Number.isNaN(t)) continue;
    if (best == null || t > best) best = t;
  }
  if (best == null) return null;
  const d = new Date(best);
  return `${d.getUTCFullYear()}년 ${d.getUTCMonth() + 1}월 ${d.getUTCDate()}일`;
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
