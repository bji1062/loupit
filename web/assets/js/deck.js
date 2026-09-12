// web/assets/js/deck.js — 스크롤하면 한 줄로 접히는 「덱」 컨트롤러(SP-FIND-6 → SP-CMP-8).
//
// 「복지검색」이 먼저 쓰던 장치를 **모드 A 복지 비교**가 같이 쓰게 되면서 find.js 에서 떼어 냈다.
// find.js 는 이 파일을 그대로 재수출하므로 그쪽 호출부·테스트는 손대지 않았다.
//
// 이 모듈은 DOM 표준 API(`classList`·`hidden`·`getBoundingClientRect`)와 주입받은 `win` 만 쓴다 —
// 앱 모듈 import 0. 덕분에 가짜 window 로 스크롤 왕복을 전부 단위 테스트할 수 있다.
//
// 일반화로 더한 것은 둘뿐이고, 둘 다 **선택이 아니라 필요**였다:
//   · `minWidth` — 접힘이 켜지는 폭. find 는 768(CSS 분기와 같은 값)을 쓴다. 하드코딩을 풀지
//     않으면 다른 화면이 다른 분기를 가질 수 없다.
//   · `headerEl` — sticky 덱이 붙을 높이를 **런타임에 실측**한다. `--header-h` 토큰은 57px 고정인데
//     360px 폭에서 GNB 가 두 줄로 꺾이면 헤더가 97px 이 된다. 그때 `top:var(--header-h)` 를 그대로
//     믿으면 미니바 위 40px 이 헤더(z-index:40 > 덱 15) 밑에 묻혀 **버튼이 안 눌린다** — 되돌릴
//     길이 없는 상태다(styles.css:1145-1148 이 이 형태를 기록해 뒀다).

// 덱 고정·접힘이 켜지는 기본 최소 폭. **styles.css 의 유일한 분기(`min-width:768px`)와 같은 값이어야
// 한다** — 이 디자인 시스템은 분기가 하나이고 `max-width` 분기를 금지한다(UT-BP). 프로토타입은
// 900 이었지만 그러면 768~900 구간에서 덱이 고정된 채 접히지 않아 화면 절반을 먹는다.
export const DESKTOP_MIN = 768;

// ── 접힘의 네 규칙 ──────────────────────────────────────────────────────────
//
// 스크롤을 내리면 검색·조건 덱이 **한 줄(minibar)** 로 접히고, 맨 위로 돌아오면 펼쳐진다.
// 순진하게 구현하면 문턱 근처에서 무한 토글이 난다. 네 가지가 함께 있어야 조용하다:
//
//   ① `html { overflow-anchor: none }` — 브라우저의 스크롤 앵커링을 끈다. 켜져 있으면 브라우저도
//      우리도 같은 스크롤을 보정해 두 번 움직인다(CSS 쪽에 있다).
//   ② 접힘·펼침으로 **바뀐 높이만큼 스크롤을 직접 보정**해 화면 내용이 제자리에 남게 한다.
//   ③ 그 보정이 만든 scroll 이벤트는 **한 번 무시**한다(`suppress`). 안 그러면 보정이 또 판정을
//      부르고, 그 판정이 또 보정한다.
//   ④ 접힘 문턱을 「덱 위쪽 + 펼친 높이 + 8px」 밖에 둔다. 보정으로 되돌아간 위치(문턱 − 높이차)가
//      펼침 문턱(덱 위쪽 + 8px)보다 **항상 아래**여야 하기 때문이다. 이 여유가 없으면 접자마자
//      펼침 문턱 안으로 들어가 진동한다.
//
// `win` 을 주입받는 이유는 이 네 규칙을 DOM 없이 테스트하기 위해서다(가짜 window 로 느린 스크롤·
// 문턱 왕복·보정 후 위치·모바일 해제를 전부 검사한다).

const noopController = {
  measure() {}, onScroll() {}, setCollapsed() {}, setOpen() {},
  isCollapsed: () => false, isOpen: () => false, destroy() {}, ok: false,
};

function heightOf(node) {
  const rect = node && typeof node.getBoundingClientRect === 'function' ? node.getBoundingClientRect() : null;
  return rect ? rect.height || 0 : 0;
}

/**
 * 덱 접힘 배선. 반환 = 컨트롤러(`measure`·`onScroll`·`setCollapsed`·`setOpen`·`destroy`).
 * 요소가 하나라도 없으면 아무것도 하지 않는 컨트롤러를 돌려준다(마크업이 바뀌어도 페이지는 산다).
 *
 * @param {object}  o
 * @param {Element} o.wrap        `position:sticky` 인 덱 바깥 상자 — `collapsed`·`open` class 를 받는다
 * @param {Element} o.anchorEl    덱이 놓인 자리(문턱 계산 기준). 보통 덱을 감싼 섹션
 * @param {Element} o.minibar     접혔을 때 보이는 한 줄
 * @param {Element} [o.expandBtn] 한 줄에서 「검색·조건 바꾸기」(없으면 임시 펼침 기능이 없다)
 * @param {Element} [o.collapseBtn] 임시로 펼친 상태에서 「접기」
 * @param {Window}  [o.win]       주입점(테스트용 가짜 window)
 * @param {number}  [o.minWidth]  이 폭 미만에서는 고정도 접힘도 없다(기본 768 = CSS 분기)
 * @param {Element} [o.headerEl]  사이트 헤더. 주면 그 높이를 **실측**해 `wrap.style.top` 에 적는다
 */
export function initDeckCollapse({
  wrap, anchorEl, minibar, expandBtn, collapseBtn, win = globalThis,
  minWidth = DESKTOP_MIN, headerEl = null,
} = {}) {
  // 덱이 서려면 이 넷이 있어야 한다. `expandBtn`·`collapseBtn` 은 **선택**이다 — 접힌 한 줄이
  // 펼친 덱과 같은 것을 말하는 화면(모드 A 「복지 비교」)에는 임시로 펼칠 이유가 없고, 없는
  // 컨트롤을 위해 쓰이지 않는 버튼을 마크업에 심는 편이 더 나쁘다. find 는 둘 다 넘긴다.
  if (!wrap || !anchorEl || !minibar || !win) return noopController;

  let anchorTop = 0; // 덱 위쪽의 문서 절대 좌표
  let expandedH = 0; // 펼친 덱의 높이(접힌 동안에는 마지막으로 잰 값을 유지한다)
  let suppress = 0; // 우리가 만든 스크롤 이벤트를 무시할 횟수(위 ③)
  let ticking = false;

  const isCollapsed = () => wrap.classList.contains('collapsed');
  const isOpen = () => wrap.classList.contains('open');

  /** 문턱을 다시 잰다. 조건이 바뀌어 덱 높이가 달라질 때마다(= 매 렌더) 호출한다. */
  function measure() {
    // 헤더 높이는 **잰다**. 토큰(`--header-h:57px`)은 한 줄 헤더의 값이라 360px 에서 두 줄(97px)이
    // 되는 순간 거짓이 되고, 그 거짓은 "버튼이 안 눌린다"로만 드러난다(증상이 원인을 안 가리킨다).
    if (headerEl) {
      const h = heightOf(headerEl);
      if (h > 0 && wrap.style) wrap.style.top = `${h}px`;
    }
    anchorTop = anchorEl.getBoundingClientRect().top + win.scrollY;
    if (!isCollapsed()) expandedH = heightOf(wrap);
  }

  /**
   * 높이 변화만큼 스크롤을 보정하고, 그 보정이 만들 scroll 이벤트 1회를 예약 무시한다.
   *
   * ⚠ 예약해 둔 무시가 **쓰이지 않고 남는 경우**가 있다: 문서 끝이라 더 스크롤할 곳이 없거나
   * 보정값이 반올림돼 0px 이면 브라우저는 scroll 이벤트를 내지 않는다. 그러면 그 무시가 다음
   * **사용자** 스크롤 판정을 한 번 삼켜 접힘이 한 박자 늦는다. 그래서 두 겹으로 막는다:
   * ① 스크롤이 실제로 안 움직였으면 바로 되돌리고 ② 그래도 남으면 300ms 뒤에 0 으로 턴다.
   */
  function compensate(delta) {
    if (!delta) return;
    const before = win.scrollY;
    suppress += 1;
    win.scrollBy(0, delta);
    if (win.scrollY === before && suppress > 0) suppress -= 1;
    else scheduleSuppressReset();
  }

  let resetTimer = null;
  function scheduleSuppressReset() {
    if (typeof win.setTimeout !== 'function') return;
    if (resetTimer != null && typeof win.clearTimeout === 'function') win.clearTimeout(resetTimer);
    resetTimer = win.setTimeout(() => { suppress = 0; resetTimer = null; }, 300);
  }

  function setCollapsed(on) {
    if (on === isCollapsed()) return;
    const before = heightOf(wrap);
    wrap.classList.toggle('collapsed', on);
    wrap.classList.remove('open'); // 임시로 펼쳐 둔 상태는 상태 전환과 함께 걷는다
    if (collapseBtn) collapseBtn.hidden = true;
    minibar.hidden = !on;
    if (expandBtn) expandBtn.setAttribute('aria-expanded', 'false');
    // 덱 **위쪽보다 아래**를 보고 있을 때만 보정한다 — 맨 위에서는 아래 내용이 올라오는 게 자연스럽다
    if (win.scrollY > anchorTop) compensate(heightOf(wrap) - before);
  }

  /** 접힌 상태에서 덱을 임시로 펼친다(스크롤 위치는 그대로 두고 내용만 밀어낸다). */
  function setOpen(on) {
    if (!isCollapsed() || !expandBtn) return; // 펼치기 컨트롤이 없는 덱에는 '임시로 펼침'이 없다
    const before = heightOf(wrap);
    wrap.classList.toggle('open', on);
    if (collapseBtn) collapseBtn.hidden = !on;
    expandBtn.setAttribute('aria-expanded', on ? 'true' : 'false');
    compensate(heightOf(wrap) - before);
  }

  /** 좁은 화면에서는 고정도 접힘도 없다 — 덱이 그냥 문서의 일부다(CSS 와 같은 경계). */
  function releaseForMobile() {
    if (!isCollapsed() && !isOpen()) return;
    wrap.classList.remove('collapsed', 'open');
    if (collapseBtn) collapseBtn.hidden = true;
    minibar.hidden = true;
    if (expandBtn) expandBtn.setAttribute('aria-expanded', 'false');
  }

  function evaluate() {
    if (suppress > 0) { suppress -= 1; return; } // 우리가 만든 스크롤(위 ③)
    if (win.innerWidth < minWidth) { releaseForMobile(); return; }
    const y = win.scrollY;
    if (!isCollapsed() && y > anchorTop + expandedH + 8) setCollapsed(true);
    else if (isCollapsed() && y <= anchorTop + 8) setCollapsed(false);
  }

  function onScroll() {
    if (ticking) return;
    ticking = true;
    const run = () => { ticking = false; evaluate(); };
    if (typeof win.requestAnimationFrame === 'function') win.requestAnimationFrame(run);
    else run();
  }

  const onResize = () => { measure(); onScroll(); };
  const onExpand = () => setOpen(true);
  const onCollapse = () => setOpen(false);

  win.addEventListener('scroll', onScroll, { passive: true });
  win.addEventListener('resize', onResize);
  if (expandBtn) expandBtn.addEventListener('click', onExpand);
  if (collapseBtn) collapseBtn.addEventListener('click', onCollapse);
  measure();
  onScroll();

  return {
    measure,
    onScroll,
    setCollapsed,
    setOpen,
    isCollapsed,
    isOpen,
    ok: true,
    destroy() {
      if (resetTimer != null && typeof win.clearTimeout === 'function') win.clearTimeout(resetTimer);
      win.removeEventListener('scroll', onScroll);
      win.removeEventListener('resize', onResize);
      if (expandBtn) expandBtn.removeEventListener('click', onExpand);
      if (collapseBtn) collapseBtn.removeEventListener('click', onCollapse);
    },
  };
}
