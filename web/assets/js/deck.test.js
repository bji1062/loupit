// web/assets/js/deck.test.js — 덱 접힘 컨트롤러의 **일반화분**(SP-CMP-8).
//
// 접힘 왕복·스크롤 보정·진동 억제 13건은 `find.test.js` 에 그대로 있다 — 옮기지 않았다.
// 그쪽이 `find.js` 에서 가져오고 `find.js` 는 이 파일을 재수출하므로, 그 13건이 계속 초록인 것이
// 「분리가 아무것도 바꾸지 않았다」의 증거다. 여기서는 분리하며 **새로 생긴 것**만 잰다:
//
//   ① `find.js` 의 이름과 `deck.js` 의 이름이 같은 함수인가(재수출이 사본이 아니라 같은 것인가)
//   ② `minWidth` — 접힘 경계가 옵션인가(하드코딩 768 이 남아 있으면 다른 화면이 다른 폭을 못 쓴다)
//   ③ `headerEl` — 헤더 높이를 **실측**해 `style.top` 에 적는가. `--header-h:57px` 토큰은 한 줄
//      헤더의 값이라 360px 에서 두 줄(97px)이 되면 거짓이 되고, 그 거짓은 "미니바 버튼이 안
//      눌린다"로만 드러난다(styles.css:1145-1148 이 「되돌릴 길 없는 상태」로 기록해 둔 그것).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { initDeckCollapse, DESKTOP_MIN } from './deck.js';
import { initDeckCollapse as reexported, DESKTOP_MIN as reexportedMin } from './find.js';

// find.test.js 의 가짜 노드·가짜 window 와 같은 모양이다(같은 계약을 재는 도구라 같아야 한다).
function fakeClassList() {
  const set = new Set();
  return {
    add: (c) => set.add(c),
    remove: (...cs) => cs.forEach((c) => set.delete(c)),
    contains: (c) => set.has(c),
    toggle: (c, on) => (on ? set.add(c) : set.delete(c)),
  };
}

function fakeNode({ height = () => 0, top = () => 0, withStyle = false } = {}) {
  const node = {
    classList: fakeClassList(),
    hidden: false,
    attrs: {},
    handlers: {},
    setAttribute(k, v) { node.attrs[k] = String(v); },
    getAttribute(k) { return node.attrs[k] ?? null; },
    addEventListener(t, fn) { (node.handlers[t] = node.handlers[t] || []).push(fn); },
    removeEventListener(t, fn) { node.handlers[t] = (node.handlers[t] || []).filter((f) => f !== fn); },
    click() { (node.handlers.click || []).forEach((f) => f()); },
    getBoundingClientRect: () => ({ height: height(node), top: top(node) }),
  };
  if (withStyle) node.style = {};
  return node;
}

function fakeWin({ innerWidth = 1200 } = {}) {
  const win = {
    scrollY: 0,
    innerWidth,
    handlers: {},
    addEventListener(t, fn) { (win.handlers[t] = win.handlers[t] || []).push(fn); },
    removeEventListener(t, fn) { win.handlers[t] = (win.handlers[t] || []).filter((f) => f !== fn); },
    requestAnimationFrame(fn) { fn(); return 1; },
    emit(t) { (win.handlers[t] || []).forEach((f) => f()); },
    scrollTo(y) { win.scrollY = Math.max(0, y); win.emit('scroll'); },
    scrollBy(_x, dy) { win.scrollTo(win.scrollY + dy); },
  };
  return win;
}

/** 덱 하나 + 가짜 window. `opts` 는 그대로 컨트롤러에 넘어간다(minWidth·headerEl 검사용). */
function env({ innerWidth = 1200, expandedH = 200, collapsedH = 48, anchorTop = 300, ...opts } = {}) {
  const win = fakeWin({ innerWidth });
  const wrap = fakeNode({
    withStyle: true,
    height: (n) => (n.classList.contains('collapsed') ? collapsedH : expandedH),
  });
  const anchorEl = fakeNode({ top: () => anchorTop - win.scrollY });
  const minibar = fakeNode();
  minibar.hidden = true;
  const expandBtn = fakeNode();
  const collapseBtn = fakeNode();
  const ctl = initDeckCollapse({ wrap, anchorEl, minibar, expandBtn, collapseBtn, win, ...opts });
  return { win, wrap, anchorEl, minibar, expandBtn, collapseBtn, ctl, anchorTop, expandedH };
}

describe('SP-CMP-8 덱 분리 — 재수출', () => {
  test('find.js 의 이름은 deck.js 의 같은 함수다(사본이 아니다)', () => {
    // 사본이면 한쪽만 고친 날 "find 는 고쳐졌는데 비교는 옛 동작"이 된다 — 렌더러 둘 함정의 축소판.
    assert.equal(reexported, initDeckCollapse);
    assert.equal(reexportedMin, DESKTOP_MIN);
  });

  test('경계 기본값은 CSS 의 유일한 분기와 같은 768 이다', () => {
    assert.equal(DESKTOP_MIN, 768);
  });
});

describe('SP-CMP-8 minWidth — 접힘 경계는 옵션이다', () => {
  test('기본값에서는 768 미만이 모바일(고정도 접힘도 없다)', () => {
    const e = env({ innerWidth: 700 });
    e.win.scrollTo(e.anchorTop + e.expandedH + 200);
    assert.equal(e.ctl.isCollapsed(), false, '좁은 화면에서 접혔다');
  });

  test('minWidth 를 낮추면 그 폭부터 접힌다 — 하드코딩 768 이 남아 있으면 이 케이스가 깨진다', () => {
    const e = env({ innerWidth: 700, minWidth: 480 });
    e.win.scrollTo(e.anchorTop + e.expandedH + 200);
    assert.equal(e.ctl.isCollapsed(), true);
  });

  test('minWidth 를 올리면 그 아래는 모바일로 풀린다(접힌 상태도 해제된다)', () => {
    const e = env({ innerWidth: 1200, minWidth: 1400 });
    e.win.scrollTo(e.anchorTop + e.expandedH + 200);
    assert.equal(e.ctl.isCollapsed(), false);
    assert.equal(e.minibar.hidden, true, '모바일 해제인데 한 줄이 남았다');
  });
});

describe('SP-CMP-8 headerEl — 헤더 높이는 토큰이 아니라 실측이다', () => {
  test('헤더를 주면 그 높이가 sticky top 이 된다', () => {
    const header = fakeNode({ height: () => 97 }); // 360px 폭에서 GNB 가 두 줄로 꺾인 실측값
    const e = env({ headerEl: header });
    assert.equal(e.wrap.style.top, '97px');
  });

  test('헤더가 자라면 다시 잴 때 따라간다 — 회전·폰트 로드 뒤에도 묻히지 않는다', () => {
    let h = 57;
    const header = fakeNode({ height: () => h });
    const e = env({ headerEl: header });
    assert.equal(e.wrap.style.top, '57px');
    h = 97;
    e.ctl.measure();
    assert.equal(e.wrap.style.top, '97px');
  });

  test('헤더를 안 주면 style 에 손대지 않는다 — CSS 토큰(--header-h)이 그대로 산다', () => {
    const e = env();
    assert.equal(e.wrap.style.top, undefined);
  });

  test('높이 0(아직 레이아웃 전)이면 적지 않는다 — 0px 를 적으면 헤더 밑으로 들어간다', () => {
    const header = fakeNode({ height: () => 0 });
    const e = env({ headerEl: header });
    assert.equal(e.wrap.style.top, undefined);
  });
});
