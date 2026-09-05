// web/test/tokens.test.js — SP-DS(디자인 토큰) 계약 테스트. 근거: SPEC/10-디자인-토큰.md §11(SP-DS-11),
// TASK/10-디자인토큰.md T-10.1~T-10.10. styles.css :root를 정적 파싱해 토큰 존재·대비 AA·광고 라벨·
// 리터럴 색 금지·font-display를 검증한다(브라우저 렌더 없는 텍스트 수준 검증, SP-ARCH §9 node:test 정합).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  hexToRgb,
  parseColor,
  relLuminance,
  contrastRatio,
  composite,
  resolveOpaque,
  parseTokens,
  splitTopLevelBlocks,
  stripComments,
} from './util/contrast.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const CSS_PATH = join(HERE, '..', 'assets', 'css', 'styles.css');
const cssText = existsSync(CSS_PATH) ? readFileSync(CSS_PATH, 'utf8') : '';

// 대비 하한(ACC-1·ACC-2, NFR15)
const AA_BODY = 4.5;
const AA_LARGE = 3;

// 배지·광고 슬롯의 반투명(-dim) 배경을 합성할 기준 배경(가정: 기본 표면 --bg-1).
// SPEC은 "-dim 합성 후 배경"이라고만 명시하고 구체 backdrop을 못 박지 않아, 컴포넌트가
// 가장 흔히 얹히는 표면(별칭 --surface = --bg-1)을 기준으로 삼는다(임의 결정, 대비 테스트로 보증).
const BADGE_BACKDROP_TOKEN = '--bg-1';

// ── T-10.1.1: contrast.mjs 유틸 자체 단위 테스트 ──────────────────────────────
describe('T-10.1.1 contrast.mjs 유틸 자체 테스트', () => {
  test('hexToRgb: #000000/#ffffff 대비 21:1(±0.01)', () => {
    const ratio = contrastRatio('#000000', '#ffffff');
    assert.ok(Math.abs(ratio - 21) < 0.01, `기대 21, 실제 ${ratio}`);
  });

  test('contrastRatio: 대칭(색A,색B)==(색B,색A)', () => {
    const r1 = contrastRatio('#0d0f12', '#f2f4f7');
    const r2 = contrastRatio('#f2f4f7', '#0d0f12');
    assert.equal(r1, r2);
  });

  test('contrastRatio: #0d0f12/#f2f4f7 ≈ 17.4', () => {
    const ratio = contrastRatio('#0d0f12', '#f2f4f7');
    assert.ok(Math.abs(ratio - 17.4) < 0.3, `기대 ≈17.4, 실제 ${ratio}`);
  });

  test('parseColor: rgb(r g b / a) 공백+슬래시 문법 파싱', () => {
    const c = parseColor('rgb(76 141 255 / .16)');
    assert.equal(c.r, 76);
    assert.equal(c.g, 141);
    assert.equal(c.b, 255);
    assert.ok(Math.abs(c.a - 0.16) < 1e-9);
  });

  test('composite: 반투명 fg를 backdrop 위에 합성 후 대비 산출', () => {
    const bg0 = hexToRgb('#0d0f12');
    const blueDim = parseColor('rgb(76 141 255 / .16)');
    const composited = composite(blueDim, bg0);
    // 합성 결과는 backdrop보다 밝아야 함(파랑 틴트가 섞임)
    assert.ok(relLuminance(composited) > relLuminance(bg0));
    // resolveOpaque 헬퍼도 동일하게 동작
    const viaHelper = resolveOpaque('rgb(76 141 255 / .16)', bg0);
    assert.ok(Math.abs(viaHelper.r - composited.r) < 1e-9);
  });

  test('parseTokens: var(--x) 별칭 재귀 해석', () => {
    const sample = `:root { --a:#112233; --b:var(--a); --c:var(--b); }`;
    const tokens = parseTokens(sample);
    assert.equal(tokens.get('--a'), '#112233');
    assert.equal(tokens.get('--b'), '#112233');
    assert.equal(tokens.get('--c'), '#112233');
  });

  test('splitTopLevelBlocks: 중첩 @media 블록도 하나의 최상위 블록으로 취급', () => {
    const sample = `:root{--x:1px;} @media (min-width: 768px) { .a { color:red; } }`;
    const blocks = splitTopLevelBlocks(sample);
    assert.equal(blocks.length, 2);
    assert.match(blocks[1].selector, /@media/);
  });

  test('stripComments: 블록 주석 제거', () => {
    const sample = `/* note { odd brace */ :root{--x:1px;}`;
    const stripped = stripComments(sample);
    assert.ok(!stripped.includes('/*'));
    assert.match(stripped, /:root\{--x:1px;\}/);
  });
});

// ── T-10.1.2: styles.css 구조 스모크 ──────────────────────────────────────
describe('T-10.1.2 styles.css 구조 스모크', () => {
  test('파일 존재', () => {
    assert.ok(existsSync(CSS_PATH), `styles.css 없음: ${CSS_PATH}`);
  });

  test(':root 파싱 성립(parseTokens 무크래시)', () => {
    assert.doesNotThrow(() => parseTokens(cssText));
    const tokens = parseTokens(cssText);
    assert.ok(tokens.size > 0);
  });

  test('@font-face 블록 정확히 1개', () => {
    const matches = cssText.match(/@font-face\s*\{/g) || [];
    assert.equal(matches.length, 1);
  });

  test('box-sizing:border-box 리셋 존재', () => {
    const blocks = splitTopLevelBlocks(cssText);
    const resetBlock = blocks.find((b) => /\*::before/.test(b.selector) && /\*::after/.test(b.selector));
    assert.ok(resetBlock, 'box-sizing 리셋 셀렉터 없음');
    assert.match(resetBlock.body, /box-sizing\s*:\s*border-box/);
  });
});

// ── UT-TOKEN-EXIST: 필수 토큰 집합 존재 (T-10.10.1) ─────────────────────────
describe('UT-TOKEN-EXIST', () => {
  const REQUIRED_TOKENS = [
    // 배경/텍스트
    '--bg-0', '--bg-1', '--bg-2', '--bg-3', '--bg-4',
    '--t1', '--t2', '--t3', '--t4',
    // 액센트 원시 + dim
    '--blue', '--amber', '--green', '--red', '--purple', '--gold',
    '--blue-dim', '--amber-dim', '--green-dim', '--red-dim', '--purple-dim', '--gold-dim',
    // 시맨틱 별칭
    '--accent', '--accent-ink', '--link', '--positive', '--negative', '--warning', '--brand-axis',
    '--text', '--text-muted', '--surface', '--surface-raised', '--border', '--border-strong',
    '--focus', '--focus-width', '--focus-offset',
    // 배지·밴드·광고
    '--badge-official-fg', '--badge-official-bg', '--badge-est-fg', '--badge-est-bg',
    '--badge-expired-fg', '--badge-expired-bg', '--badge-qual-fg', '--badge-qual-bg',
    '--band-label-fg', '--band-expired-fg',
    '--ad-label-fg', '--ad-label-fs', '--ad-slot-bg', '--ad-slot-border',
    // 타이포
    '--font-sans', '--fs-ad', '--fs-xs', '--fs-sm', '--fs-base', '--fs-lg',
    '--fs-h3', '--fs-h2', '--fs-h1', '--fs-display',
    '--lh-tight', '--lh-base', '--lh-snug', '--ls-tight',
    '--fw-regular', '--fw-medium', '--fw-semibold', '--fw-bold',
    // 간격·컨테이너
    '--sp-1', '--sp-2', '--sp-3', '--sp-4', '--sp-5', '--sp-6', '--sp-7', '--sp-8',
    '--container-max', '--gutter-mobile', '--gutter-desktop', '--tap-min',
    // 반경·테두리·엘리베이션
    '--r-xs', '--r-sm', '--r-md', '--r-lg', '--r-pill', '--bw', '--border-color',
    '--shadow-1', '--shadow-2',
    // 모션
    '--dur-fast', '--dur-base', '--dur-slow', '--ease-out', '--ease-inout', '--ease-standard',
    // 브레이크포인트
    '--bp-desktop',
  ];

  const tokens = parseTokens(cssText);

  test(`필수 토큰 ${REQUIRED_TOKENS.length}개 누락 0`, () => {
    const missing = REQUIRED_TOKENS.filter((name) => !tokens.has(name));
    assert.deepEqual(missing, [], `누락 토큰: ${missing.join(', ')}`);
  });
});

// ── UT-CONTRAST-BODY: 본문 대비 (T-10.2.1) ─────────────────────────────────
describe('UT-CONTRAST-BODY', () => {
  const tokens = parseTokens(cssText);
  const bodyTexts = ['--t1', '--t2', '--t3'];
  const backgrounds = ['--bg-0', '--bg-1', '--bg-2'];

  for (const t of bodyTexts) {
    for (const bg of backgrounds) {
      test(`${t} on ${bg} ≥ ${AA_BODY}:1`, () => {
        const ratio = contrastRatio(tokens.get(t), tokens.get(bg));
        assert.ok(ratio >= AA_BODY, `${t} on ${bg} = ${ratio.toFixed(2)} < ${AA_BODY}`);
      });
    }
  }
});

// ── UT-CONTRAST-T4: --t4 가드 (T-10.2.1) ────────────────────────────────────
describe('UT-CONTRAST-T4', () => {
  const tokens = parseTokens(cssText);

  test('--t4 on --bg-0: 3:1 ≤ 대비 < 4.5:1(대형/비텍스트 한정, 본문 금지)', () => {
    const ratio = contrastRatio(tokens.get('--t4'), tokens.get('--bg-0'));
    assert.ok(ratio >= AA_LARGE, `--t4 on --bg-0 = ${ratio.toFixed(2)} < ${AA_LARGE}`);
    assert.ok(ratio < AA_BODY, `--t4 on --bg-0 = ${ratio.toFixed(2)} — 본문 하한(4.5) 이상이면 --t4 가드 무의미`);
  });

  test('회귀 가드: --text/--text-muted가 --t4로 매핑되면 실패', () => {
    assert.notEqual(tokens.get('--text'), tokens.get('--t4'), '--text가 --t4(저대비)로 매핑됨');
    assert.notEqual(tokens.get('--text-muted'), tokens.get('--t4'), '--text-muted가 --t4(저대비)로 매핑됨');
  });
});

// ── UT-CONTRAST-ACCENT-TXT (T-10.2.2) ───────────────────────────────────────
describe('UT-CONTRAST-ACCENT-TXT', () => {
  const tokens = parseTokens(cssText);
  const accents = ['--blue', '--amber', '--green', '--red', '--purple', '--gold'];

  for (const name of accents) {
    test(`${name} on --bg-0 ≥ ${AA_BODY}:1(텍스트/아이콘 사용 가능)`, () => {
      const ratio = contrastRatio(tokens.get(name), tokens.get('--bg-0'));
      assert.ok(ratio >= AA_BODY, `${name} on --bg-0 = ${ratio.toFixed(2)} < ${AA_BODY}`);
    });
  }
});

// ── UT-CONTRAST-FILL (T-10.2.3, 규칙 A1) ────────────────────────────────────
describe('UT-CONTRAST-FILL', () => {
  const tokens = parseTokens(cssText);
  const accents = ['--blue', '--amber', '--green', '--red', '--purple', '--gold'];

  for (const name of accents) {
    test(`${name} 채움 + --accent-ink 텍스트 ≥ ${AA_BODY}:1(흰 텍스트 대비 미달 회귀 방지)`, () => {
      const ratio = contrastRatio(tokens.get('--accent-ink'), tokens.get(name));
      assert.ok(ratio >= AA_BODY, `--accent-ink on ${name} = ${ratio.toFixed(2)} < ${AA_BODY}`);
    });
  }
});

// ── UT-BADGE-CONTRAST (T-10.3.1) ────────────────────────────────────────────
describe('UT-BADGE-CONTRAST', () => {
  const tokens = parseTokens(cssText);
  const backdrop = parseColor(tokens.get(BADGE_BACKDROP_TOKEN));
  const badges = [
    ['--badge-official-fg', '--badge-official-bg'],
    ['--badge-est-fg', '--badge-est-bg'],
    ['--badge-expired-fg', '--badge-expired-bg'],
    ['--badge-qual-fg', '--badge-qual-bg'],
  ];

  for (const [fgName, bgName] of badges) {
    test(`${fgName} on ${bgName}(${BADGE_BACKDROP_TOKEN} 위 합성) ≥ ${AA_BODY}:1`, () => {
      const fg = resolveOpaque(tokens.get(fgName), backdrop);
      const bg = resolveOpaque(tokens.get(bgName), backdrop);
      const ratio = contrastRatio(fg, bg);
      assert.ok(ratio >= AA_BODY, `${fgName}/${bgName} = ${ratio.toFixed(2)} < ${AA_BODY}`);
    });
  }
});

// ── UT-AD-LABEL (T-10.3.2, 릴리스 게이트) ───────────────────────────────────
describe('UT-AD-LABEL', () => {
  const tokens = parseTokens(cssText);

  test('--ad-label-fg on --ad-slot-bg ≥ 4.5:1(은폐 아님)', () => {
    const ratio = contrastRatio(tokens.get('--ad-label-fg'), tokens.get('--ad-slot-bg'));
    assert.ok(ratio >= AA_BODY, `--ad-label-fg on --ad-slot-bg = ${ratio.toFixed(2)} < ${AA_BODY}`);
  });

  test('--ad-label-fg ≠ --t4(은폐 회귀 방지, 규칙 AD1)', () => {
    assert.notEqual(tokens.get('--ad-label-fg'), tokens.get('--t4'));
  });

  test('--ad-label-fs ≥ 11px(SP-ADS-5.2 하한)', () => {
    const px = parseFloat(tokens.get('--ad-label-fs'));
    assert.ok(px >= 11, `--ad-label-fs = ${px}px < 11px`);
  });
});

// ── UT-TYPE-SCALE (T-10.4.2) ────────────────────────────────────────────────
describe('UT-TYPE-SCALE', () => {
  const tokens = parseTokens(cssText);
  const scaleOrder = ['--fs-ad', '--fs-xs', '--fs-sm', '--fs-base', '--fs-lg', '--fs-h3', '--fs-h2', '--fs-h1'];

  test('엄격 증가: --fs-ad < --fs-xs < --fs-sm < --fs-base < --fs-lg < --fs-h3 < --fs-h2 < --fs-h1', () => {
    const values = scaleOrder.map((name) => parseFloat(tokens.get(name)));
    for (let i = 1; i < values.length; i++) {
      assert.ok(
        values[i] > values[i - 1],
        `${scaleOrder[i - 1]}(${values[i - 1]}) >= ${scaleOrder[i]}(${values[i]}) — 단조 증가 위반`
      );
    }
  });

  test('--fs-base === 16px', () => {
    assert.equal(tokens.get('--fs-base'), '16px');
  });

  test('--fs-xs === 13px', () => {
    assert.equal(tokens.get('--fs-xs'), '13px');
  });
});

// ── UT-FONT-DISPLAY (T-10.4.1, 릴리스 게이트) ───────────────────────────────
describe('UT-FONT-DISPLAY', () => {
  const fontFaceBody = (() => {
    const blocks = splitTopLevelBlocks(cssText);
    const b = blocks.find((blk) => /@font-face/.test(blk.selector));
    return b ? b.body : '';
  })();

  test('@font-face 블록 존재', () => {
    assert.ok(fontFaceBody.length > 0, '@font-face 블록을 찾을 수 없음');
  });

  test('font-display: swap 존재(NFR5)', () => {
    assert.match(fontFaceBody, /font-display\s*:\s*swap/);
  });

  test('src가 self-host /assets/v2/fonts/…woff2 경로(캐시버스팅 v2 세대)', () => {
    assert.match(fontFaceBody, /src\s*:\s*url\(['"]?\/assets\/v2\/fonts\/[^)'"]+\.woff2['"]?\)/);
  });

  test('외부 CDN URL 0개(http(s):// 부재)', () => {
    const externalUrls = fontFaceBody.match(/url\(\s*['"]?https?:\/\//gi) || [];
    assert.equal(externalUrls.length, 0, `외부 CDN URL 발견: ${externalUrls.join(', ')}`);
  });
});

// ── UT-SPACING (T-10.5.1·10.5.2) ────────────────────────────────────────────
describe('UT-SPACING', () => {
  const tokens = parseTokens(cssText);
  const spacingOrder = ['--sp-1', '--sp-2', '--sp-3', '--sp-4', '--sp-5', '--sp-6', '--sp-7', '--sp-8'];

  test('--sp-1..8: 4px 배수', () => {
    for (const name of spacingOrder) {
      const px = parseFloat(tokens.get(name));
      assert.equal(px % 4, 0, `${name} = ${px}px — 4px 배수 아님`);
    }
  });

  test('--sp-1..8: 단조 증가', () => {
    const values = spacingOrder.map((name) => parseFloat(tokens.get(name)));
    for (let i = 1; i < values.length; i++) {
      assert.ok(values[i] > values[i - 1], `${spacingOrder[i - 1]} >= ${spacingOrder[i]}`);
    }
  });

  test('--sp-4 === 16px(모바일 거터)', () => {
    assert.equal(tokens.get('--sp-4'), '16px');
  });

  test('--gutter-desktop === 24px', () => {
    assert.equal(tokens.get('--gutter-desktop'), '24px');
  });

  test('--container-max === 1400px(2026-07-16 개정 — 나무위키 대문급 광폭)', () => {
    assert.equal(tokens.get('--container-max'), '1400px');
  });

  test('--tap-min === 44px', () => {
    assert.equal(tokens.get('--tap-min'), '44px');
  });
});

// ── UT-BP (T-10.7.1) ─────────────────────────────────────────────────────────
describe('UT-BP', () => {
  const tokens = parseTokens(cssText);

  test('--bp-desktop === 768px', () => {
    assert.equal(tokens.get('--bp-desktop'), '768px');
  });

  test('사용 min-width 미디어쿼리는 768px 단일 분기(중간 분기 0)', () => {
    const stripped = stripComments(cssText);
    const matches = [...stripped.matchAll(/min-width\s*:\s*([\d.]+)px/g)].map((m) => parseFloat(m[1]));
    const offBreakpoints = matches.filter((px) => px !== 768);
    assert.deepEqual(offBreakpoints, [], `768 아닌 min-width 분기 발견: ${offBreakpoints.join(', ')}`);
  });

  // 분기가 하나라는 말은 **방향도 하나**라는 뜻이다. `max-width` 를 한 줄 섞으면 같은 폭이
  // 두 규칙에 걸려(768 정확히) 어느 쪽이 이기는지를 파일 순서가 정하게 된다 — 그때부터
  // "모바일 우선"이라는 규약은 읽는 사람의 기억에만 남는다.
  test('max-width 미디어쿼리 0건 — 접고 펴는 방향은 언제나 모바일 기본 → 768 확장', () => {
    const stripped = stripComments(cssText);
    // 프렐류드 안의 `max-width` 만 본다 — `.sc-left { max-width:520px }` 같은 **속성**은
    // 분기가 아니다(이 구분을 안 하면 테스트가 정상 레이아웃을 잡는다).
    const found = [...stripped.matchAll(/@media[^{]*max-width[^{]*/g)].map((m) => m[0].trim());
    assert.deepEqual(found, [], `max-width 분기 발견: ${found.join(', ')}`);
  });
});

// ── UT-SC-LENS (2026-09-04, SP-GEN-5.7) ─────────────────────────────────────
// 카드 접기와 출처 렌즈의 **CSS 쪽 계약**. 둘 다 JS 가 죽어도 화면이 성립해야 하고,
// 렌즈는 어떤 상태에서도 행을 **숨기지 않아야** 한다(숨기면 본문이 DOM 에서 빠진다).
describe('UT-SC-LENS', () => {
  const blocks = splitTopLevelBlocks(cssText);
  const desktop = blocks.find((b) => /@media\s*\(\s*min-width\s*:\s*768px\s*\)/.test(b.selector));

  test('카드 행 목록은 기본(모바일)에서 접히고 768 분기에서 펴진다', () => {
    // 접기는 `.sc-rows`(카드 행 목록 전용 클래스)에만 건다 — `/assets/v2/` 가 작업트리를
    // 그대로 서빙해 CSS 가 HTML 보다 먼저 라이브가 되는 저장소라, 구 마크업이 새 규칙에
    // 걸리면 배포 사이 구간에서 화면이 깨진다.
    const base = blocks.find((b) => b.selector === '.sc-rows');
    assert.ok(base, '.sc-rows 규칙이 없다');
    assert.match(base.body, /display\s*:\s*none/);
    assert.ok(desktop, '768 분기 블록이 없다');
    assert.match(desktop.body, /\.sc-rows\s*\{[^}]*display\s*:\s*block/);
  });

  test('접힌 폭의 힌트 문장과 펼친 폭의 힌트 문장이 서로 배타적으로 뜬다', () => {
    const wide = blocks.find((b) => b.selector === '.sc-hint-wide');
    assert.ok(wide && /display\s*:\s*none/.test(wide.body), '.sc-hint-wide 기본 숨김이 없다');
    assert.match(desktop.body, /\.sc-hint-narrow\s*\{[^}]*display\s*:\s*none/);
    assert.match(desktop.body, /\.sc-hint-wide\s*\{[^}]*display\s*:\s*inline/);
  });

  test('🚨 렌즈는 어떤 상태에서도 행을 숨기지 않는다 — 감쇠(opacity)와 띠만 쓴다', () => {
    const lensRules = splitTopLevelBlocks(cssText).filter((b) => b.selector.includes('[data-lens-on'));
    assert.ok(lensRules.length >= 6, `렌즈 상태 규칙이 너무 적다(${lensRules.length})`);
    for (const r of lensRules) {
      if (/\[data-lens[~\]]/.test(r.selector)) {
        assert.doesNotMatch(r.body, /display\s*:\s*none|visibility\s*:\s*hidden/,
          `행을 숨기는 렌즈 규칙: ${r.selector}`);
      }
    }
  });

  test('렌즈 상태 규칙은 생성기의 통 6종을 모두 덮는다(company.py::LENS_BUCKETS)', () => {
    const stripped = stripComments(cssText);
    for (const key of ['stated', 'est', 'qual', 'blank', 'edited', 'expired']) {
      assert.ok(stripped.includes(`[data-lens-on="${key}"]`), `${key} 렌즈 규칙이 없다`);
      assert.ok(stripped.includes(`[data-lens~="${key}"]`), `${key} 행 선택자가 없다`);
    }
  });
});

// ── UT-TABLE-SCROLL (2026-09-05, SPEC 10 MD-4) ──────────────────────────────
// 7열 표(재무 11개년·회사 인덱스)는 390px 를 넘긴다. 넘침을 **표 자신의 상자**에 가두지
// 않으면 페이지가 통째로 가로로 팬된다(실측 390px: 회사 상세 110/113 페이지 +21~143px,
// /companies +63px). 반대로 body{overflow-x:hidden} 으로 덮으면 오른쪽 열을 영원히 못 본다.
describe('UT-TABLE-SCROLL', () => {
  const blocks = splitTopLevelBlocks(cssText);

  test('.table-scroll 이 최상위(비 @media) 규칙으로 overflow-x:auto 를 갖는다', () => {
    // 모바일 기본에서 이미 스크롤 상자여야 한다 — 768 분기 안에만 두면 정작 밀리는 폭에서 무효다.
    const rule = blocks.find((b) => b.selector === '.table-scroll');
    assert.ok(rule, '.table-scroll 규칙이 없다');
    assert.match(rule.body, /overflow-x\s*:\s*auto/);
  });

  test('폐기된 -webkit-overflow-scrolling 을 쓰지 않는다', () => {
    // iOS 13 이후 무의미하고, 있으면 "이걸 붙여야 스크롤된다"는 오해를 다음 사람에게 남긴다.
    assert.doesNotMatch(stripComments(cssText), /-webkit-overflow-scrolling/);
  });

  test('🚨 html/body 를 overflow-x:hidden 으로 덮지 않는다 — 그건 열을 감추는 것이다', () => {
    const stripped = stripComments(cssText);
    for (const sel of ['html', 'body']) {
      const m = [...stripped.matchAll(new RegExp(`(^|[},])\\s*${sel}\\s*\\{([^}]*)\\}`, 'g'))];
      for (const hit of m) {
        assert.doesNotMatch(hit[2], /overflow(-x)?\s*:\s*(hidden|clip)/,
          `${sel} 에 가로 넘침 은폐 규칙: ${hit[2].trim()}`);
      }
    }
  });
});

// ── UT-GNB-NOWRAP (2026-09-05, SPEC 10 MD-4 / NFR13) ────────────────────────
// 전역 헤더는 **모든 페이지**에 있고 CSS 는 머지 즉시 라이브다 — 여기가 무너지면 사이트
// 전체의 첫 화면이 무너진다. 실측(프로덕션, iPhone Safari UA): 320px 에서 '커뮤니티'·
// '회사정보'가 한 글자씩 4줄로 서고 헤더가 107px(360px 84px · 390px 62px). 가로로 넘친 게
// 아니라 세로로 꺾인 것이었다 — CJK 는 글자 사이 어디서나 꺾이고, flex 기본 shrink:1 이
// 링크를 한 글자 폭까지 줄여 그 꺾임을 강제한다. **둘 다** 막아야 낫는다.
describe('UT-GNB-NOWRAP', () => {
  const blocks = splitTopLevelBlocks(cssText);
  const desktop = blocks.find((b) => /^@media/.test(b.selector) && /min-width/.test(b.selector));
  const navSel = /header\[data-global\]\s*nav/;

  test('GNB 링크는 nowrap 이면서 축소되지 않는다 — 한쪽만으로는 꺾임이 안 멈춘다', () => {
    // white-space 만 걸면 flex 가 링크를 1글자 폭으로 줄여 놓고 nowrap 이 넘치게 만들고,
    // 축소만 막으면 CJK 가 여전히 글자 사이에서 꺾인다. 그래서 한 규칙에서 둘을 함께 본다.
    const rule = blocks.find((b) => /^header\s+nav\s*>\s*a$/.test(b.selector.trim()));
    assert.ok(rule, 'header nav > a 규칙이 없다 — GNB 라벨 꺾임 방어가 통째로 빠졌다');
    assert.match(rule.body, /white-space\s*:\s*nowrap/);
    assert.match(rule.body, /flex\s*:\s*0\s+0\s+auto/, 'flex-shrink 를 0 으로 묶지 않았다');
  });

  test('모바일 기본의 GNB 는 항목 단위로 줄을 바꾼다(안전판) — 768 에서 한 줄로 되돌린다', () => {
    // 안전판이 없으면 총 필요 폭이 뷰포트를 넘는 순간(320px + 로그인 진입점) 링크가 겹치거나
    // 잘린다. 반대로 768 이상에서 줄이 바뀌면 그건 레이아웃이 아니라 버그라 nowrap 으로 못박는다.
    const base = blocks.find((b) => navSel.test(b.selector) && /display\s*:\s*flex/.test(b.body));
    assert.ok(base, 'GNB nav 의 flex 컨테이너 규칙을 못 찾았다');
    assert.match(base.body, /flex-wrap\s*:\s*wrap/);
    assert.ok(desktop, '768 분기 블록이 없다');
    const restored = [...desktop.body.matchAll(/([^{}]+)\{([^}]*)\}/g)]
      .find(([, sel]) => navSel.test(sel));
    assert.ok(restored, '768 에서 GNB nav 를 되돌리는 규칙이 없다');
    assert.match(restored[2], /flex-wrap\s*:\s*nowrap/);
  });

  test('워드마크는 좁은 폭에서 접히고 768 에서 되돌아온다 — 영영 사라지면 안 된다', () => {
    // 로고 마크(img)와 접근성 이름(텍스트 노드)은 그대로 두고 **글자만** 접는 방식이라,
    // 되돌리는 쪽을 빠뜨리면 데스크톱에서도 브랜드가 사라진 채로 배포된다.
    const brand = blocks.find((b) => /(^|,)\s*\.brand\s*(,|$)/.test(b.selector) && /font-size/.test(b.body));
    assert.ok(brand, '.brand 규칙을 못 찾았다');
    assert.match(brand.body, /font-size\s*:\s*0\b/);
    const restored = [...desktop.body.matchAll(/([^{}]+)\{([^}]*)\}/g)]
      .find(([, sel]) => /(^|,)\s*\.brand\s*(,|$)/.test(sel));
    assert.ok(restored, '768 에서 .brand 글자 크기를 되돌리는 규칙이 없다');
    assert.match(restored[2], /font-size\s*:\s*var\(--fs-/);
  });

  test('🚨 GNB 를 가로 스크롤/클리핑 상자로 만들지 않는다 — 로그인 진입점과 포커스 링이 잘린다', () => {
    // 표(UT-TABLE-SCROLL)와 반대 결론이다: 표는 넘침을 자기 상자에 가두는 게 맞지만, 헤더는
    // 항상 통째로 보여야 하는 것이라 넘치면 **줄을 바꿔야** 한다. overflow 상자는 덤으로
    // 포커스 링(outline-offset 2px)까지 잘라 키보드 사용자에게서 현재 위치를 뺏는다.
    for (const b of blocks) {
      if (!navSel.test(b.selector) && !/^header\b/.test(b.selector.trim())) continue;
      assert.doesNotMatch(b.body, /overflow(-x|-y)?\s*:\s*(auto|scroll|hidden|clip)/,
        `헤더 규칙에 넘침 상자: ${b.selector} { ${b.body.trim()} }`);
    }
  });
});

// ── UT-REDUCED-MOTION (T-10.8.2) ────────────────────────────────────────────
describe('UT-REDUCED-MOTION', () => {
  test('@media (prefers-reduced-motion: reduce) 블록 존재', () => {
    assert.match(stripComments(cssText), /@media\s*\(\s*prefers-reduced-motion\s*:\s*reduce\s*\)/);
  });
});

// ── UT-NO-LITERAL (T-10.10.2, 릴리스 게이트) ────────────────────────────────
describe('UT-NO-LITERAL', () => {
  test(':root/@font-face/@media 제외 컴포넌트 규칙에 색 리터럴(#hex, rgb() ) 직접 등장 0', () => {
    const blocks = splitTopLevelBlocks(cssText);
    const componentBlocks = blocks.filter(
      (b) => !/^:root/.test(b.selector) && !/@font-face/.test(b.selector) && !/@media/.test(b.selector)
    );
    const violations = [];
    const COLOR_LITERAL_RE = /#[0-9a-fA-F]{3,8}\b|rgb\(/g;
    for (const b of componentBlocks) {
      const found = b.body.match(COLOR_LITERAL_RE);
      if (found) violations.push(`${b.selector}: ${found.join(', ')}`);
    }
    assert.deepEqual(violations, [], `리터럴 색 위반: ${violations.join(' | ')}`);
  });
});

// ── UT-LIGHT-DEFAULT (T-10.2.1) — 사용자 결정(2026-07-13): 시안 A(라이트) 채택 ──
describe('UT-LIGHT-DEFAULT', () => {
  const tokens = parseTokens(cssText);

  test('--bg-0 밝기 > --t1 밝기(라이트 배경·어두운 텍스트)', () => {
    const lBg = relLuminance(parseColor(tokens.get('--bg-0')));
    const lText = relLuminance(parseColor(tokens.get('--t1')));
    assert.ok(lBg > lText, `--bg-0 휘도(${lBg}) <= --t1 휘도(${lText}) — 라이트 기본 위반`);
  });

  test('data-theme 미부착 = 라이트(활성 [data-theme] 셀렉터 규칙 없음; 다크는 후속 훅)', () => {
    const stripped = stripComments(cssText);
    assert.ok(!/\[\s*data-theme\s*=/.test(stripped), '활성 [data-theme=...] 규칙 발견 — 현재는 라이트 단일, 다크는 훅 주석만');
  });
});
