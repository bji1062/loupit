// web/assets/js/radar.js — 겹친 9각형(쌍 레이더)의 **좌표 포트** (SP-CMP-4).
//
// 🚨 이 파일은 `generator/radar.py` 의 두 번째 렌더러다. 그 파일 머리 주석이 금지하던 그것 —
// 「JS 로 한 벌 더 그리지 않는다. 렌더러가 둘이면 축 규칙·결측 처리가 두 언어로 갈라지고, 갈라진
// 판정은 반드시 어긋난다(배지 함정)」 — 인데, 모드 A 는 브라우저 도구라 피할 길이 없었다.
// 대신 셋을 못 박았다:
//
//   ① `/vs` 정적 3쪽은 여전히 **Python** 이 굽는다. 여기서 만드는 것은 도구 화면뿐이다.
//   ② 골든 픽스처 `generator/tests/data/radar_pair_cases.json` 가 같은 입력에서 **SVG 문자열
//      전체의 바이트 일치**를 고정한다(points 만이 아니라 통째로 — 조각만 걸면 순서·공백이 샌다).
//   ③ 결측 표기는 함수 하나(`fmt`)에서 나온다. 0 은 어디서나 「등록 없음」이다.
//
// ⚠ **두 언어가 갈리는 지점이 둘 있다. 둘 다 여기서 손으로 맞췄다.**
//   · `.1f` 반올림: 파이썬은 짝수 쪽, JS `toFixed` 는 위. 값이 정확히 x.25 일 때만 다르다
//     (151.25 → 파이썬 151.2 / toFixed 151.3). `f1()` 이 그 한 경우를 되돌린다.
//   · 이스케이프: 파이썬 `html.escape` 는 `'` 를 `&#x27;` 로, `dom.js::escapeHtml` 은 `&#39;` 로
//     쓴다. 여기서는 **파이썬 쪽**을 따른다(`esc()`) — 이 파일의 계약은 바이트 일치다.
//
// 문자열을 만들어 돌려주는 이유(=`el()` 로 노드를 쌓지 않는 이유): SVG 는 네임스페이스가 있어
// `createElement` 로는 만들어지지 않고, 무엇보다 **Python 과 같은 바이트**가 이 파일의 계약이다.
// 대신 데이터가 닿는 값은 하나도 빠짐없이 `esc()` 를 통과한다(회사명에 `&` 가 실제로 있다 —
// 삼성E&A). 이 파일 밖에서 이 문자열을 innerHTML 로 넣는 것은 그 전제 위에서만 안전하다.

// ── 기하 상수 — `generator/radar.py` 와 **같은 값**이어야 한다 ─────────────────
export const CX = 200.0;
export const CY = 200.0;
export const R = 130.0;
export const LABEL_R = R + 22;            // 축 라벨 반지름 — 꼭짓점 바깥
export const RINGS = [2, 4, 6, 8];        // 눈금 고리 — 이 값이 곧 "항목 수"다
export const VIEWBOX_PAIR = '0 34 416 356';
export const PAIR_W = 416;
export const BAND_RECT_Y = 369;
export const BAND_H = 18;
export const BAND_TEXT_Y = 381;
export const HIT_R_MUL = 1.16;
export const HIT_HALF_DEG = 20;
export const HIT_STEP_DEG = 10;
export const BAND_DEFAULT = '축 위에 올리거나 Tab 으로 옮기면 두 회사 값 · 중심 = 등록 없음';

const ESC = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#x27;' };

/** `html.escape(s, quote=True)` 와 **같은 치환**. dom.js 와 한 글자(`'`)가 다르다 — 위 주석 참조. */
export function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => ESC[c]);
}

/**
 * 파이썬 `f"{x:.1f}"` 와 **같은 문자열**. `toFixed(1)` 이 그대로면 안 되는 이유는 단 하나다:
 * 값이 정확히 x.25 이면 파이썬은 짝수 쪽(151.25 → "151.2"), `toFixed` 는 위(→ "151.3")로 간다.
 *
 * 정확한 동점은 x = 홀수/4 일 때만 생긴다(소수부 .25 또는 .75). 이진수로 딱 떨어지는 값만
 * 동점이 되기 때문이다 — .05·.15 같은 값은 double 로 표현되는 순간 이미 한쪽으로 기운다.
 * 그중 .75 는 두 방식이 같은 답(짝수 = 올림)을 주므로 **되돌릴 것은 .25 하나**다.
 *
 * 좌표·평균은 언제나 0 이상이라(viewBox 70~390) 음수는 다루지 않는다.
 */
export function f1(x) {
  const q = x * 4; // 소수 2비트 이하만 정수가 된다(4 곱은 무손실)
  if (x >= 0 && Number.isInteger(q) && q % 4 === 1) return `${Math.floor(x)}.2`;
  return x.toFixed(1);
}

/** 축 i(12시부터 시계방향)의 값 v 좌표. rmax 가 0 이면 중심점(무크래시). */
export function pt(i, v, n, rmax) {
  const a = -Math.PI / 2 + (2 * Math.PI * i) / n;
  const r = rmax <= 0 ? 0 : R * (v / rmax);
  return [CX + r * Math.cos(a), CY + r * Math.sin(a)];
}

/** 값 배열 → `points` 문자열. 파이썬 `_poly` 와 바이트 일치. */
export function poly(values, rmax) {
  const n = values.length;
  return values.map((v, i) => {
    const [x, y] = pt(i, v, n, rmax);
    return `${f1(x)},${f1(y)}`;
  }).join(' ');
}

/** 축 i 를 덮는 부채꼴 히트 영역. 값이 0 이면 꼭짓점이 전부 중심에 겹쳐 점으로는 못 짚는다. */
export function sector(i, n) {
  const a0 = -Math.PI / 2 + (2 * Math.PI * i) / n;
  const r = R * HIT_R_MUL;
  const pts = [`${f1(CX)},${f1(CY)}`];
  for (let deg = -HIT_HALF_DEG; deg <= HIT_HALF_DEG + 1e-9; deg += HIT_STEP_DEG) {
    const a = a0 + (deg * Math.PI) / 180;
    pts.push(`${f1(CX + r * Math.cos(a))},${f1(CY + r * Math.sin(a))}`);
  }
  return pts.join(' ');
}

/**
 * 항목 수 → 사람이 읽는 말. **0 은 「등록 없음」이다**(SP-CMP-3).
 *
 * 숫자 0 을 화면에 쓰지 않는 이유: 스키마에 긍정 행만 있어 「이 회사에 이 제도가 없다」를 적을
 * 자리가 없다. 0 은 「우리가 등록하지 않았다」일 뿐인데 「0개 = 없다」로 읽힌다. 임의 쌍에서 한쪽만
 * 있는 행이 합집합의 중앙 71.4% 라, 이 낱말을 틀리면 화면 대부분이 거짓이 된다.
 *
 * 이 함수가 **하나**인 것이 계약이다 — 판독문·막대 라벨·목록 머리·표 셀이 전부 여기서 나온다.
 */
export function fmt(v) {
  return !v ? '등록 없음' : `${v}항목`;
}

/** 축 하나의 판독문. 판독 띠·히트 aria-label 이 같은 문형을 쓴다. */
export function readout(lb, a, b, avg, aNm, bNm) {
  if (!a && !b) return `${lb} — 양쪽 등록 없음 · 평균 ${f1(avg)}`;
  return `${lb} — ${aNm} ${fmt(a)} · ${bNm} ${fmt(b)} · 평균 ${f1(avg)}`;
}

/** 축 라벨의 anchor·베이스라인 보정 — 파이썬 `radar_svg` 의 규칙 그대로. */
function labelPlacement(i, n) {
  const a = -Math.PI / 2 + (2 * Math.PI * i) / n;
  const lx = CX + LABEL_R * Math.cos(a);
  const ly = CY + LABEL_R * Math.sin(a);
  const cos = Math.cos(a);
  const sin = Math.sin(a);
  const anchor = Math.abs(cos) < 0.25 ? 'middle' : (cos > 0 ? 'start' : 'end');
  const dy = Math.abs(sin) < 0.3 ? 5 : (sin > 0 ? 11 : -1);
  return { lx, ly: ly + dy, anchor };
}

/**
 * 두 회사를 겹친 9각형 SVG **문자열**. `generator/radar.py::radar_pair_svg` 와 바이트 일치.
 *
 * 눈금(고리 2·4·6·8)은 등록 회사 전체의 카테고리별 최댓값이라 **쌍마다 다시 잡지 않는다** —
 * 쌍마다 잡으면 도형 크기가 거짓말을 한다. 겹친 넓이는 점수가 아니다: 「두 회사 모두 그 수까지
 * 등록된 범위」일 뿐 **같은 항목이라는 뜻이 아니다**(같은 항목은 「공통 N」과 항목 대조표의 몫).
 */
export function radarPairSvg(countsA, countsB, avgs, labels, rmaxIn, aNm = '', bNm = '') {
  const n = countsA.length;
  if (n !== countsB.length || n !== avgs.length || n !== labels.length || n < 3) {
    throw new Error(`radarPairSvg: 길이 불일치 a=${countsA.length} b=${countsB.length} `
      + `avgs=${avgs.length} labels=${labels.length}`);
  }
  const rmax = Math.max(rmaxIn, ...countsA, ...countsB, 1);

  const rings = RINGS.filter((k) => k <= rmax)
    .map((k) => `<polygon class="rdp-ring" points="${poly(Array(n).fill(k), rmax)}"></polygon>`).join('');
  const axes = Array.from({ length: n }, (_, i) => {
    const [x, y] = pt(i, rmax, n, rmax);
    return `<line class="rdp-ax" x1="${CX.toFixed(0)}" y1="${CY.toFixed(0)}" `
      + `x2="${f1(x)}" y2="${f1(y)}"></line>`;
  }).join('');
  const ticks = RINGS.filter((k) => k <= rmax)
    .map((k) => `<text class="rdp-tick" x="${(CX + 6).toFixed(0)}" `
      + `y="${f1(CY - (R * k) / rmax + 4)}">${k}</text>`).join('');

  const lbs = labels.map((text, i) => {
    const { lx, ly, anchor } = labelPlacement(i, n);
    return `<text class="rdp-lb" x="${f1(lx)}" y="${f1(ly)}" text-anchor="${anchor}">${esc(text)}</text>`;
  }).join('');

  // B 는 네모(9×9), A 는 원(r=5). 같은 값이면 A 원을 **속 빈 링**으로 얹어 네모가 비친다 —
  // 꽉 찬 원이 네모를 덮으면 색 외의 두 번째 채널(모양)이 겹칠 때마다 사라진다.
  const marksB = countsB.map((v, i) => {
    const [x, y] = pt(i, v, n, rmax);
    return `<rect class="rdp-db" x="${f1(x - 4.5)}" y="${f1(y - 4.5)}" width="9" height="9"></rect>`;
  }).join('');
  const marksA = countsA.map((v, i) => {
    const [x, y] = pt(i, v, n, rmax);
    const tie = countsA[i] === countsB[i] ? ' rdp-tie' : '';
    return `<circle class="rdp-da${tie}" cx="${f1(x)}" cy="${f1(y)}" r="5"></circle>`;
  }).join('');

  const aWho = esc(aNm);
  const bWho = esc(bNm);
  const hits = Array.from({ length: n }, (_, i) => {
    const line = readout(esc(labels[i]), countsA[i], countsB[i], avgs[i], aWho, bWho);
    const [ax, ay] = pt(i, rmax, n, rmax);
    return `<g class="rdp-hit" tabindex="0" role="img" aria-label="${line}">`
      + `<polygon class="rdp-hitc" points="${sector(i, n)}"></polygon>`
      + `<line class="rdp-hl" x1="${CX.toFixed(0)}" y1="${CY.toFixed(0)}" x2="${f1(ax)}" y2="${f1(ay)}"></line>`
      + `<rect class="rdp-hvbg" x="0" y="${BAND_RECT_Y}" width="${PAIR_W}" height="${BAND_H}"></rect>`
      + `<text class="rdp-hv" x="${PAIR_W / 2}" y="${BAND_TEXT_Y}" text-anchor="middle">${line}</text></g>`;
  }).join('');

  const desc = labels.map((lb, i) => `${esc(lb)} ${aWho} ${fmt(countsA[i])}·${bWho} `
    + `${fmt(countsB[i])}(평균 ${f1(avgs[i])})`).join(' · ');

  return `<svg class="rdp" viewBox="${VIEWBOX_PAIR}" role="group" `
    + `aria-label="${aWho}·${bWho} 카테고리별 복지 항목 수 — ${desc}. `
    + '같은 숫자가 아래 「카테고리별」 표에 있다">'
    + '<g aria-hidden="true">'
    + rings + axes + ticks
    // B → A → 평균 순. 평균 점선이 맨 위라야 14% 채움 두 장(겹친 곳 26%) 아래로 잠기지 않는다.
    + `<polygon class="rdp-b" points="${poly(countsB, rmax)}"></polygon>`
    + `<polygon class="rdp-a" points="${poly(countsA, rmax)}"></polygon>`
    + `<polygon class="rdp-avg" points="${poly(avgs, rmax)}"></polygon>`
    + marksB + marksA + lbs
    + `<text class="rdp-hv0" x="${PAIR_W / 2}" y="${BAND_TEXT_Y}" text-anchor="middle">`
    + `${esc(BAND_DEFAULT)}</text>`
    + `</g>${hits}</svg>`;
}
