// web/assets/js/metricshape.js — '연도별 추이' 그래프 모양(막대/꺾은선) **선택 기억만** 한다(SP-MET-10).
//
// 이 모듈이 하지 않는 일이 하는 일보다 중요하다.
//   · 그래프를 그리지 않는다. 두 벌 모두 `generator/charts.py` 가 빌드 시점에 SVG 로 찍어 HTML 에
//     박아 두었다 — 렌더러가 파이썬 하나뿐이어야 단위·결측·부호 규칙이 두 언어로 갈라지지 않는다
//     (배지 함정: 판정이 네 렌더러로 흩어져 GNB 검색 페이지만 틀린 배지를 달고 있었다).
//   · 전환도 하지 않는다. 라디오 `:checked ~ .metric-cards` 로 **CSS** 가 한 벌을 접는다.
//     그래서 이 스크립트가 없어도, 늦게 와도, 예외로 죽어도 그래프는 그대로 보인다(NFR24).
//   · 🚨 **어떤 화면을 보여줄지 정하지 않는다.** 저장값이 고를 수 있는 것은 `bar` 와 `line` 두
//     글자뿐이고, 그 값이 닿는 곳은 라디오의 `checked` 하나뿐이다. 상태 복원 장치에 화면 결정권을
//     준 대문 사고(2026-07-31: 초안 복원이 대문을 대문이 아니게 만들었다)의 재발 방지 규약이다.
//
// 저장 접근은 전부 try/catch 다 — 사생활 보호 모드·쿠키 차단·용량 초과에서 localStorage 는
// **읽기에서도** 던진다(store.js 와 같은 규약, FR-44).

export const SHAPE_KEY = 'jobcho.metricShape';
// 허용 값 목록. 목록 밖 값은 읽을 때도 쓸 때도 버린다 — 저장소는 사용자가 직접 고칠 수 있는
// 곳이라 `document.getElementById('metric-shape-' + v)` 에 임의 문자열이 들어가게 두지 않는다.
const SHAPES = ['bar', 'line'];
const RADIO_ID = { bar: 'metric-shape-bar', line: 'metric-shape-line' };
const RADIO_SEL = 'input[name="metric-shape"]';

function storageOf(storage) {
  return storage === undefined ? globalThis.localStorage : storage;
}

export function readShape(storage) {
  try {
    const v = storageOf(storage).getItem(SHAPE_KEY);
    return SHAPES.includes(v) ? v : null;   // 없음·손상·목록 밖 → null(= HTML 기본값을 그대로 둔다)
  } catch {
    return null;
  }
}

export function writeShape(shape, storage) {
  if (!SHAPES.includes(shape)) return false;
  try {
    storageOf(storage).setItem(SHAPE_KEY, shape);
    return true;
  } catch {
    return false;                            // 저장 실패는 기능 손상이 아니다 — 이번 세션만 기억 못 한다
  }
}

// 저장값 → 라디오 `checked`. 이 함수가 건드리는 DOM 은 그 라디오 하나뿐이다.
// 저장값이 없으면 **아무것도 하지 않는다** — HTML 이 `checked` 로 정해 둔 기본(막대)이 남는다.
export function restoreShape(doc, storage) {
  const shape = readShape(storage);
  if (!shape) return null;
  const el = doc.getElementById(RADIO_ID[shape]);
  if (!el) return null;                      // 그래프가 없는 페이지 — 조용히 물러난다
  el.checked = true;
  return shape;
}

// 사용자가 고른 값을 저장한다. 반환은 배선한 라디오 수(0 = 이 페이지엔 그래프가 없다).
export function bindShape(doc, storage) {
  const inputs = doc.querySelectorAll(RADIO_SEL);
  inputs.forEach((el) => el.addEventListener('change', () => {
    if (el.checked) writeShape(el.value, storage);
  }));
  return inputs.length;
}

export function initMetricShape(doc, storage) {
  const d = doc || globalThis.document;
  try {
    restoreShape(d, storage);
    return bindShape(d, storage);
  } catch {
    return 0;                                // 어떤 실패도 본문을 건드리지 않는다(MON6)
  }
}

// 자동 초기화 가드 — 라디오가 있는 실제 페이지에서만 돈다(node:test import 부작용 0).
if (typeof document !== 'undefined' && document.querySelector(RADIO_SEL)) {
  initMetricShape();
}
