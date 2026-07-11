// web/assets/js/dom.js — 렌더 안전 유틸(SP-FE-9.1·9.2, FR-45, NFR21).
// 순수 + 브라우저 표준 API만 사용(다른 앱 모듈 import 0) — SP-FE-1.2 규칙2, 단위 테스트 가능.
// 데이터를 보간한 innerHTML 직접 삽입 금지. 모든 데이터 값은 이스케이프 또는 textContent로만 삽입한다.

// & < > " ' 치환(XSS 방지 최소 이스케이프, NFR21).
export function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// 안전 DOM 빌더: 텍스트는 textContent, 속성은 setAttribute(자동 이스케이프).
// html 옵션은 데이터 보간 innerHTML 경로를 원천 차단하기 위해 항상 예외를 던진다(R-2).
export function el(tag, opts = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(opts)) {
    if (k === 'text') node.textContent = v;                // ★데이터는 항상 textContent
    else if (k === 'html') throw new Error('el(): raw html 금지');   // 데이터 보간 innerHTML 차단
    else if (k === 'class') node.className = v;
    else if (v != null) node.setAttribute(k, v);
  }
  for (const c of children) node.append(c);
  return node;
}

// 태그드 템플릿: 정적 부분은 그대로, 보간값은 자동 escapeHtml → innerHTML에 안전 사용.
export function h(strings, ...values) {
  return strings.reduce((acc, s, i) => acc + s + (i < values.length ? escapeHtml(values[i]) : ''), '');
}

// 스킴 화이트리스트(http/https만) — 그 외(javascript: 등)·파싱 실패는 null(R-3).
export function safeUrl(u) {
  try {
    const url = new URL(u, location.origin);
    return (url.protocol === 'http:' || url.protocol === 'https:') ? url.href : null;
  } catch {
    return null;
  }
}
