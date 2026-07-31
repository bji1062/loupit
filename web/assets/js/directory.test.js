// web/assets/js/directory.test.js — 등록 회사 디렉토리(카운트→가나다순 목록→복지 펼침) 테스트.
// 순수(sortCompanies·benefitLine·rowMeta) + jsdom DOM(카운트 렌더·패널 토글·상세 링크).
// 데이터는 부팅 REF(companies[].benefits) 재사용 — 네트워크 0(SP-FE-5 번들 소비만).

// ── dom.js가 document를 참조하므로 최소 전역 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import { readdirSync, readFileSync } from 'node:fs';

import { sortCompanies, benefitLine, rowMeta, mountDirectory, slugOf, companyHref } from './directory.js';

function comp(id, nm, benefits = []) {
  return { comp_id: id, comp_eng_nm: 'co' + id, comp_nm: nm, comp_tp_cd: 'large', industry_nm: 'IT', benefits };
}
const BEN_MEAL = { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: 120, benefit_ctgr_cd: 'perks', qual_yn: false, amt_source: 'stated', badge_cd: 'official' };
const BEN_QUAL = { benefit_cd: 'culture', benefit_nm: '수평 문화', benefit_amt: null, benefit_ctgr_cd: 'work_env', qual_yn: true, amt_source: 'none', badge_cd: 'est' };

function refState() {
  return {
    REF: {
      company_types: [], benefit_presets: {},
      companies: [
        comp(1, '현대모비스', [BEN_MEAL]),
        comp(2, '가나다상사', [BEN_MEAL, BEN_QUAL]),
        comp(3, '네이버', []),
      ],
    },
  };
}

// ── 순수: sortCompanies — 한국어 가나다순 정렬(원본 불변) ────────────────────
describe('sortCompanies', () => {
  test('comp_nm 가나다순 정렬', () => {
    const sorted = sortCompanies(refState().REF.companies);
    assert.deepEqual(sorted.map((c) => c.comp_nm), ['가나다상사', '네이버', '현대모비스']);
  });

  test('원본 배열 순서 불변(사본 정렬)', () => {
    const companies = refState().REF.companies;
    sortCompanies(companies);
    assert.equal(companies[0].comp_nm, '현대모비스');
  });

  test('손상 입력 → []', () => {
    assert.deepEqual(sortCompanies(null), []);
    assert.deepEqual(sortCompanies('x'), []);
  });
});

// ── 순수: benefitLine — 복지 1건 표기 문자열 ────────────────────────────────
describe('benefitLine', () => {
  test('금액 복지 → "식대 — 연 120만원"', () => {
    assert.equal(benefitLine(BEN_MEAL), '식대 — 연 120만원');
  });

  test('정성 복지(금액 없음) → 이름만', () => {
    assert.equal(benefitLine(BEN_QUAL), '수평 문화');
  });
});

// ── 순수: rowMeta — 목록 행 보조 정보 ──────────────────────────────────────
describe('rowMeta', () => {
  test('업종 · 복지 N개', () => {
    assert.equal(rowMeta(comp(1, '가', [BEN_MEAL, BEN_QUAL])), 'IT · 복지 2개');
  });
  test('복지 0개면 개수를 적지 않는다', () => {
    assert.equal(rowMeta(comp(1, '가', [])), 'IT');
  });
  test('업종 없음 → 복지 수만', () => {
    assert.equal(rowMeta({ industry_nm: null, benefits: [BEN_MEAL] }), '복지 1개');
  });
  test('손상 입력 → 빈 문자열(무크래시)', () => {
    assert.equal(rowMeta(null), '');
    assert.equal(rowMeta({}), '');
  });
});

// ── DOM: mountDirectory(jsdom) ──────────────────────────────────────────────
function loadDom() {
  const dom = new JSDOM(
    '<main><section id="view-search"><h2>비교할 두 직장을 선택하세요</h2><div id="company-directory"></div></section></main>',
    { url: 'https://loupit.example/', pretendToBeVisual: true },
  );
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  return dom;
}

describe('mountDirectory — 카운트·패널 토글·상세 링크', () => {
  beforeEach(() => loadDom());

  test('카운트 버튼 "등록된 회사 수: 3" 렌더, 패널 초기 접힘', () => {
    mountDirectory(refState());
    const btn = document.querySelector('.dir-count');
    assert.ok(btn, '카운트 버튼 렌더');
    assert.match(btn.textContent, /등록된 회사 수/);
    assert.match(btn.textContent, /3/);
    assert.equal(btn.getAttribute('aria-expanded'), 'false');
    assert.equal(document.querySelector('.dir-panel').hidden, true);
  });

  test('카운트 클릭 → 패널 펼침(가나다순 3행), 재클릭 → 접힘', () => {
    mountDirectory(refState());
    const btn = document.querySelector('.dir-count');
    btn.dispatchEvent(new window.Event('click', { bubbles: true }));
    const panel = document.querySelector('.dir-panel');
    assert.equal(panel.hidden, false);
    assert.equal(btn.getAttribute('aria-expanded'), 'true');
    const names = [...document.querySelectorAll('.dir-comp .dir-comp-nm')].map((e) => e.textContent);
    assert.deepEqual(names, ['가나다상사', '네이버', '현대모비스'], '가나다순');
    btn.dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(panel.hidden, true);
  });

  // 2026-07-31: 아코디언(복지 펼침) 폐지 → 행 자체가 정적 상세 페이지 링크다.
  // 복지를 그리는 화면을 셋에서 줄이고, 유입을 광고가 붙은 정적 페이지로 보낸다.
  test('행이 정적 상세 페이지 링크다(아코디언 없음)', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const rows = [...document.querySelectorAll('.dir-comp')];
    assert.equal(rows.length, 3);
    for (const r of rows) assert.equal(r.tagName, 'A', '행은 링크여야 한다');
    assert.deepEqual(rows.map((r) => r.getAttribute('href')), ['/company/co2', '/company/co3', '/company/co1']);
    assert.equal(document.querySelector('.dir-benefits'), null, '복지 아코디언은 더 이상 렌더되지 않는다');
    assert.equal(document.querySelector('.badge'), null, '요약 배지도 사라졌다(상세가 소유)');
  });

  test('행 보조 정보 = 업종 · 복지 수(세어서 나오는 사실만)', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const metas = [...document.querySelectorAll('.dir-comp-meta')].map((e) => e.textContent);
    assert.deepEqual(metas, ['IT · 복지 2개', 'IT', 'IT · 복지 1개'], '복지 0개면 개수를 적지 않는다');
  });

  test('slug 를 만들 수 없는 회사 → 링크 대신 평문(404 로 가는 링크를 만들지 않는다)', () => {
    const st = refState();
    st.REF.companies[0].comp_eng_nm = '___';
    mountDirectory(st);
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const plain = document.querySelector('.dir-comp-plain');
    assert.ok(plain, '평문 행');
    assert.equal(plain.tagName, 'SPAN');
    assert.equal(plain.getAttribute('href'), null);
    assert.equal(document.querySelectorAll('.dir-comp[href]').length, 2);
  });

  test('안내 문구가 실제 동작(이동)을 말한다', () => {
    mountDirectory(refState());
    assert.match(document.querySelector('.dir-hint').textContent, /이동합니다/);
  });

  test('REF 없음/회사 0 → 카운트 미렌더(no-op)', () => {
    mountDirectory({ REF: null });
    assert.equal(document.querySelector('.dir-count'), null);
    mountDirectory({ REF: { companies: [] } });
    assert.equal(document.querySelector('.dir-count'), null);
  });

  test('host 부재(다른 페이지) → no-op', () => {
    document.getElementById('company-directory').remove();
    assert.doesNotThrow(() => mountDirectory(refState()));
  });
});

// ── 상세 페이지 링크(2026-07-19 고아 페이지 해소) ───────────────────────────
// REF 번들이 slug를 싣지 않아 slugOf가 generator/slug.py 규칙을 미러링한다.
// 아래 테스트가 규칙 일치·유일성을 커밋된 시드 SQL 95개사로 실검증한다.
describe('회사 상세 링크(slugOf·companyHref)', () => {
  beforeEach(() => loadDom());   // DOM 케이스는 위 블록과 동일한 jsdom 셸을 쓴다

  test('slug 규칙: 소문자·비영숫자→하이픈·연속축약·양끝제거', () => {
    assert.equal(slugOf('samsung_elec'), 'samsung-elec');
    assert.equal(slugOf('sk_hynix'), 'sk-hynix');
    assert.equal(slugOf('cj'), 'cj');
    assert.equal(slugOf('HMM'), 'hmm');
    assert.equal(slugOf('a__b'), 'a-b');
    assert.equal(slugOf('_lead_trail_'), 'lead-trail');
  });

  test('빈·무효 입력 → null(링크 미생성, 무크래시)', () => {
    for (const v of ['', '   ', '___', null, undefined]) assert.equal(slugOf(v), null);
    assert.equal(companyHref(''), null);
    assert.equal(companyHref('naver'), '/company/naver');
  });

  test('실데이터 95개사: slug 패턴 적합 + 유일(경로 충돌 0)', () => {
    const dir = new URL('../../../db/seed/benefit/sql/', import.meta.url);
    const files = readdirSync(dir).filter((f) => f.endsWith('.sql'));
    assert.ok(files.length >= 90, `시드 SQL ${files.length}개(≥90 기대)`);
    const slugs = new Set();
    for (const f of files) {
      const sql = readFileSync(new URL(f, dir), 'utf8');
      const m = sql.match(/COMP_ENG_NM\s*=\s*'([^']+)'/);
      if (!m) continue;
      const s = slugOf(m[1]);
      assert.ok(s && /^[a-z0-9]+(-[a-z0-9]+)*$/.test(s), `${m[1]} → ${s} 패턴 불일치`);
      assert.ok(!slugs.has(s), `slug 충돌: ${s}`);
      slugs.add(s);
    }
    assert.ok(slugs.size >= 90, `추출 slug ${slugs.size}개`);
  });

  // 2026-07-31: 링크가 아코디언 안쪽이 아니라 **행 자체**가 됐다(아코디언 폐지).
  test('행 링크가 정적 페이지 경로 규칙을 따른다', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    for (const a of document.querySelectorAll('.dir-comp')) {
      const href = a.getAttribute('href');
      assert.ok(href && href.startsWith('/company/'), href);
      assert.ok(/^\/company\/[a-z0-9]+(-[a-z0-9]+)*$/.test(href), `slug 패턴 불일치: ${href}`);
    }
  });

  test('복지 0건 회사도 상세로 갈 수 있다(진입 자체를 막지 않는다)', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const naver = [...document.querySelectorAll('.dir-comp')].find((a) => a.textContent.includes('네이버'));
    assert.equal(naver.getAttribute('href'), '/company/co3');
  });

  test('comp_eng_nm 부재 → 링크 미생성(무크래시)', () => {
    const state = { REF: { companies: [{ comp_id: 9, comp_nm: '무영문사', benefits: [] }] } };
    assert.doesNotThrow(() => mountDirectory(state));
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(document.querySelector('.dir-comp[href]'), null);
    assert.ok(document.querySelector('.dir-comp-plain'), '링크 대신 평문으로 남는다');
  });
});


// ⓘ 출처 계보 배지 테스트는 여기서 사라졌다(2026-07-31): 디렉터리가 복지를 그리지 않으므로
// 배지도 그리지 않는다. 판정 자체는 `badge.test.js`, 표시는 회사 페이지·비교 리포트가 소유한다.
