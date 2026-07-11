// web/test/util/contrast.mjs — WCAG 2.x 상대휘도·대비비 계산 유틸 + styles.css :root 토큰 파서.
// import 전용(자체 테스트 파일 아님, node --test 대상 아님). 소비처: web/test/tokens.test.js.
// 근거: SP-DS-11.1(SPEC/10-디자인-토큰.md), TASK/10 T-10.1.1. 팔레트 값은 여기 하드코딩하지 않고
// styles.css :root를 parseTokens()로 파싱해 주입한다(SP-DS-11.1).

const HEX_RE = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;
// rgb(r g b / a) — CSS4 공백+슬래시 문법(styles.css --*-dim 관례)
const RGB_SPACE_RE = /^rgba?\(\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*(?:\/\s*([\d.]+%?))?\s*\)$/;
// rgb(r, g, b, a) — 구식 콤마 문법(호환)
const RGB_COMMA_RE = /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+%?))?\s*\)$/;

function clamp01(x) {
  return Math.min(1, Math.max(0, x));
}

/** '#rgb'/'#rrggbb'/'#rrggbbaa' → {r,g,b,a}(0-255, a는 0-1) */
export function hexToRgb(hex) {
  const m = HEX_RE.exec(String(hex).trim());
  if (!m) throw new Error(`hexToRgb: 잘못된 hex 색상 "${hex}"`);
  let h = m[1];
  if (h.length === 3 || h.length === 4) {
    h = h
      .split('')
      .map((c) => c + c)
      .join('');
  }
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  const a = h.length === 8 ? parseInt(h.slice(6, 8), 16) / 255 : 1;
  return { r, g, b, a };
}

function parsePercentOrNum(s, fallback = 1) {
  if (s === undefined || s === null) return fallback;
  if (s.endsWith('%')) return parseFloat(s) / 100;
  return parseFloat(s);
}

/** '#hex' | 'rgb(r g b / a)' | 'rgb(r,g,b,a)' → {r,g,b,a}(0-255, a는 0-1) */
export function parseColor(value) {
  const v = String(value).trim();
  if (v.startsWith('#')) return hexToRgb(v);
  let m = RGB_SPACE_RE.exec(v);
  if (m) {
    return {
      r: parseFloat(m[1]),
      g: parseFloat(m[2]),
      b: parseFloat(m[3]),
      a: parsePercentOrNum(m[4], 1),
    };
  }
  m = RGB_COMMA_RE.exec(v);
  if (m) {
    return {
      r: parseFloat(m[1]),
      g: parseFloat(m[2]),
      b: parseFloat(m[3]),
      a: parsePercentOrNum(m[4], 1),
    };
  }
  throw new Error(`parseColor: 지원하지 않는 색상 형식 "${value}"`);
}

function toColor(c) {
  if (typeof c === 'string') return parseColor(c);
  if (c && typeof c === 'object' && 'r' in c && 'g' in c && 'b' in c) return c;
  throw new Error('toColor: 지원하지 않는 색상 입력');
}

function srgbChannelToLinear(c255) {
  const c = clamp01(c255 / 255);
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** WCAG 상대휘도 L = 0.2126R + 0.7152G + 0.0722B (sRGB→선형화 후) */
export function relLuminance(rgbLike) {
  const c = toColor(rgbLike);
  const R = srgbChannelToLinear(c.r);
  const G = srgbChannelToLinear(c.g);
  const B = srgbChannelToLinear(c.b);
  return 0.2126 * R + 0.7152 * G + 0.0722 * B;
}

/** 대비비 = (L1+0.05)/(L2+0.05), L1=밝은 쪽. 입력은 색 문자열 또는 {r,g,b} 객체(불투명 가정). */
export function contrastRatio(colorA, colorB) {
  const L1 = relLuminance(toColor(colorA));
  const L2 = relLuminance(toColor(colorB));
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}

/** 반투명 전경(fg, a<1)을 불투명 배경(bg) 위에 알파 합성 → {r,g,b,a:1} */
export function composite(fg, bg) {
  const f = toColor(fg);
  const b = toColor(bg);
  const a = f.a === undefined ? 1 : f.a;
  return {
    r: f.r * a + b.r * (1 - a),
    g: f.g * a + b.g * (1 - a),
    b: f.b * a + b.b * (1 - a),
    a: 1,
  };
}

/** 색 문자열을 backdrop 위에서 불투명화(알파<1이면 합성, 아니면 그대로) → {r,g,b,a:1} */
export function resolveOpaque(colorStr, backdrop) {
  const c = parseColor(colorStr);
  if (c.a === undefined || c.a >= 1) return { ...c, a: 1 };
  return composite(c, backdrop);
}

/** CSS 주석(/* ... *\/) 전부 제거 — 중괄호 균형 파싱 보호용. */
export function stripComments(cssText) {
  return cssText.replace(/\/\*[\s\S]*?\*\//g, '');
}

/**
 * 최상위 규칙 블록으로 분리: [{selector, body, full}], 중첩 { } (예: @media 내부 규칙) 지원.
 * 주석은 사전에 stripComments로 제거된 입력을 기대한다(호출자 책임 아님 — 내부에서 제거).
 */
export function splitTopLevelBlocks(cssText) {
  const css = stripComments(cssText);
  const blocks = [];
  let i = 0;
  const n = css.length;
  while (i < n) {
    const brace = css.indexOf('{', i);
    if (brace === -1) break;
    const selector = css.slice(i, brace).trim();
    let depth = 0;
    let j = brace;
    for (; j < n; j++) {
      if (css[j] === '{') depth++;
      else if (css[j] === '}') {
        depth--;
        if (depth === 0) break;
      }
    }
    const body = css.slice(brace + 1, j);
    blocks.push({ selector, body, full: css.slice(i, j + 1) });
    i = j + 1;
  }
  return blocks;
}

/** 최상위 블록 중 시작 위치가 startRe(마지막 문자가 '{'가 되는 정규식)에 매치하는 첫 블록의 본문을 반환. */
export function extractBlockBody(cssText, startRe) {
  const css = stripComments(cssText);
  const m = startRe.exec(css);
  if (!m) return null;
  const openIdx = m.index + m[0].length - 1; // '{' 위치
  let depth = 0;
  for (let i = openIdx; i < css.length; i++) {
    if (css[i] === '{') depth++;
    else if (css[i] === '}') {
      depth--;
      if (depth === 0) return css.slice(openIdx + 1, i);
    }
  }
  throw new Error('extractBlockBody: 중괄호 불균형');
}

/** 선언 블록 본문을 ';' 기준으로 분리(트림·빈 항목 제거). CSS 커스텀 속성 값엔 리터럴 ';' 없음을 가정. */
export function splitDeclarations(body) {
  return body
    .split(';')
    .map((s) => s.trim())
    .filter(Boolean);
}

/**
 * styles.css 전체 텍스트를 받아 :root { ... } 블록을 파싱하고,
 * --name: value 선언을 var(--other) 별칭까지 재귀 해석한 Map<string,string>으로 반환한다.
 * (하드코딩 금지 — 팔레트/스케일 값은 항상 이 함수로 styles.css에서 뽑아 쓴다, SP-DS-11.1.)
 */
export function parseTokens(cssText) {
  const rootBody = extractBlockBody(cssText, /:root\s*\{/);
  if (rootBody === null) throw new Error('parseTokens: :root 블록을 찾을 수 없음');

  const raw = new Map();
  for (const decl of splitDeclarations(rootBody)) {
    const idx = decl.indexOf(':');
    if (idx === -1) continue;
    const name = decl.slice(0, idx).trim();
    const value = decl.slice(idx + 1).trim();
    if (!name.startsWith('--')) continue;
    raw.set(name, value);
  }

  const resolved = new Map();
  const resolving = new Set();
  const VAR_RE = /var\(\s*(--[a-zA-Z0-9-]+)\s*(?:,[^)]*)?\)/g;

  function resolve(name) {
    if (resolved.has(name)) return resolved.get(name);
    if (!raw.has(name)) throw new Error(`parseTokens: 미정의 토큰 참조 "${name}"`);
    if (resolving.has(name)) throw new Error(`parseTokens: 순환 참조 "${name}"`);
    resolving.add(name);
    const value = raw.get(name).replace(VAR_RE, (_, ref) => resolve(ref));
    resolving.delete(name);
    resolved.set(name, value);
    return value;
  }

  for (const name of raw.keys()) resolve(name);
  return resolved;
}
