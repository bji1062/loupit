// web/assets/js/lens.js — 복지 스탯 카드의 **출처 렌즈**. 최상위에 `data-lens-on` 한 글자를
// 세팅하는 것이 전부다(SP-GEN-5.7).
//
// 이 모듈이 하지 않는 일이 하는 일보다 중요하다.
//   · **판정하지 않는다.** "이 행이 추정치인가"는 빌드 시점에 `generator/format.py::amount_kind`
//     (금액 축)와 `badge_state`(계보 축)가 이미 정했고, `company.py::lens_keys` 가 그 둘을 행의
//     `data-lens` 로 투영해 두었다. 여기서 다시 판단하면 같은 복지가 화면마다 다른 통에 들어간다
//     (배지 함정 2026-07-31: 판정이 네 렌더러로 흩어져 GNB 검색만 틀린 배지를 달고 있었다).
//   · **칠하지 않는다.** 띠와 감쇠는 `styles.css` 의 `[data-lens-on=…] [data-lens~=…]` 가 한다.
//   · **숨기지 않는다.** 어떤 렌즈에서도 27행은 27행이다 — 행을 지우면 본문이 DOM 에서 빠져
//     색인이 깎이고, 남은 8행이 "이 회사 복지는 8개"라는 없는 사실로 읽힌다.
//   · **기억하지 않는다.** 기본은 언제나 '전체'. 상태 복원 장치에 화면 결정권을 준 대문 사고
//     (2026-07-31)의 재발 방지 규약이라 저장소에 손대는 경로 자체를 두지 않는다.
//
// 그래서 이 스크립트가 없어도·늦게 와도·예외로 죽어도 화면은 **지금 배포된 그대로**다(NFR24).
// 칩은 `hidden` 으로 나가고 여기서만 벗겨진다 — 눌러도 아무 일 없는 죽은 컨트롤을 남기지 않는
// `data-authnav-edit` 와 같은 규약이다.

// 생성기의 통 목록과 같은 6개(`company.py::LENS_BUCKETS`) + 'all'. 목록 밖 값은 무시한다 —
// 마크업이 바뀌어도 임의 문자열이 최상위 속성에 박히지 않게 하는 화이트리스트다.
export const LENS_KEYS = ['stated', 'est', 'qual', 'blank', 'edited', 'expired'];
export const ROOT_ATTR = 'data-lens-on';

const LIST_SEL = '[data-lens-chips]';
const CHIP_SEL = '[data-lens-key]';
const KEY_ATTR = 'data-lens-key';
const BAR_ATTR = 'data-lens-bar';
const OUT_SEL = '[data-lens-bar-out]';

// 켠 렌즈(null = 전체). 최상위 속성 하나와 칩의 `aria-pressed`, 그리고 설명 띠 한 줄만 만진다.
//
// 설명 띠는 **비어서 나간다**(A안 2026-09-16). 예전에는 6벌을 본문에 박고 CSS 로 하나만
// 드러냈는데, 사람은 하나씩 보지만 크롤러는 전부 읽어 회사 138쪽에서 반복 문장 717개가 됐다.
// 문장은 여기서 짓지 않는다 — 칩의 `data-lens-bar` 에 실려 온 것을 옮길 뿐이고,
// 출처는 여전히 `company.py::LENS_BUCKETS` 하나다(판정도 문장도 이 모듈이 만들지 않는다).
function apply(root, chips, key, out) {
  if (key) root.setAttribute(ROOT_ATTR, key);
  else root.removeAttribute(ROOT_ATTR);
  let bar = '';
  for (const c of chips) {
    const k = c.getAttribute(KEY_ATTR);
    const on = key ? k === key : k === 'all';
    c.setAttribute('aria-pressed', String(on));
    if (on && key) bar = c.getAttribute(BAR_ATTR) || '';
  }
  if (out) {
    out.textContent = bar;                   // '전체'면 빈 문자열 — 띠가 사라진다
    out.hidden = !bar;
  }
}

export function initLens(doc) {
  const d = doc || globalThis.document;
  try {
    const list = d.querySelector(LIST_SEL);
    if (!list) return 0;                       // 렌즈가 없는 페이지 — 조용히 물러난다
    const chips = [...list.querySelectorAll(CHIP_SEL)];
    if (!chips.length) return 0;
    const root = d.documentElement;
    const out = d.querySelector(OUT_SEL);   // 없어도 돈다(띠 없는 마크업 허용)
    list.hidden = false;                       // 여기서 처음 드러난다
    let on = null;
    for (const c of chips) {
      c.addEventListener('click', () => {
        const k = c.getAttribute(KEY_ATTR);
        if (k !== 'all' && !LENS_KEYS.includes(k)) return;
        // 켠 칩을 다시 누르면 전체로 — 렌즈는 조합이 아니라 관점이라 한 번에 하나만 켜진다.
        on = (k === 'all' || k === on) ? null : k;
        apply(root, chips, on, out);
      });
    }
    return chips.length;
  } catch {
    return 0;                                  // 어떤 실패도 본문을 건드리지 않는다(MON6)
  }
}

// 자동 초기화 가드 — 칩이 있는 실제 페이지에서만 돈다(node:test import 부작용 0).
if (typeof document !== 'undefined' && document.querySelector(LIST_SEL)) {
  initLens();
}
