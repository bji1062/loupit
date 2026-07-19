// web/assets/js/directory.test.js — 등록 회사 디렉토리(카운트→가나다순 목록→복지 펼침) 테스트.
// 순수(sortCompanies·benefitLine) + jsdom DOM(카운트 렌더·패널 토글·아코디언).
// 데이터는 부팅 REF(companies[].benefits) 재사용 — 네트워크 0(SP-FE-5 번들 소비만).

// ── dom.js가 document를 참조하므로 최소 전역 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import { readdirSync, readFileSync } from 'node:fs';

import { sortCompanies, benefitLine, mountDirectory, slugOf, companyHref } from './directory.js';

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

describe('mountDirectory — 카운트·패널 토글·복지 아코디언', () => {
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

  test('회사 클릭 → 복지 목록 펼침(배지 포함), 다른 회사 클릭 → 이전 것 접힘', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const rows = document.querySelectorAll('.dir-comp');
    rows[0].dispatchEvent(new window.Event('click', { bubbles: true })); // 가나다상사(복지 2)
    const open = document.querySelector('.dir-benefits:not([hidden])');
    assert.ok(open, '복지 패널 펼침');
    assert.match(open.textContent, /식대/);
    assert.match(open.textContent, /120만원/);
    assert.match(open.textContent, /수평 문화/);
    assert.ok(open.querySelector('.badge-official'), '공식 배지');
    // 다른 회사 클릭 → 이전 것 접히고 새 것만 열림
    rows[2].dispatchEvent(new window.Event('click', { bubbles: true })); // 현대모비스
    const opens = document.querySelectorAll('.dir-benefits:not([hidden])');
    assert.equal(opens.length, 1);
    assert.match(opens[0].textContent, /식대/);
  });

  test('카운트 재클릭(닫기→열기) → 펼쳐진 복지 초기화(전부 접힘)', () => {
    mountDirectory(refState());
    const count = document.querySelector('.dir-count');
    count.dispatchEvent(new window.Event('click', { bubbles: true })); // 열기
    const rows = document.querySelectorAll('.dir-comp');
    rows[0].dispatchEvent(new window.Event('click', { bubbles: true })); // 복지 펼침
    assert.ok(document.querySelector('.dir-benefits:not([hidden])'), '펼침 상태 전제');
    count.dispatchEvent(new window.Event('click', { bubbles: true })); // 닫기 → 초기화
    count.dispatchEvent(new window.Event('click', { bubbles: true })); // 다시 열기
    assert.equal(document.querySelectorAll('.dir-benefits:not([hidden])').length, 0, '복지 전부 접힘');
    const expanded = [...document.querySelectorAll('.dir-comp')].filter((b) => b.getAttribute('aria-expanded') === 'true');
    assert.equal(expanded.length, 0, 'aria-expanded 전부 false');
  });

  test('복지 없는 회사 → "등록된 복지 정보가 없습니다"', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const rows = document.querySelectorAll('.dir-comp');
    rows[1].dispatchEvent(new window.Event('click', { bubbles: true })); // 네이버(복지 0)
    const open = document.querySelector('.dir-benefits:not([hidden])');
    assert.match(open.textContent, /등록된 복지 정보가 없습니다/);
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

  test('복지 패널에 상세 링크 렌더(정적 페이지 진입점)', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const rows = document.querySelectorAll('.dir-comp');
    rows[0].dispatchEvent(new window.Event('click', { bubbles: true }));
    const link = document.querySelector('.dir-benefits:not([hidden]) .dir-detail-link');
    assert.ok(link, '상세 링크 미렌더');
    assert.ok(link.getAttribute('href').startsWith('/company/'), link.getAttribute('href'));
    assert.match(link.textContent, /상세 보기/);
  });

  test('복지 0건 회사도 상세 링크는 제공', () => {
    mountDirectory(refState());
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    const rows = document.querySelectorAll('.dir-comp');
    rows[1].dispatchEvent(new window.Event('click', { bubbles: true })); // 네이버(복지 0)
    const open = document.querySelector('.dir-benefits:not([hidden])');
    assert.match(open.textContent, /등록된 복지 정보가 없습니다/);
    assert.ok(open.querySelector('.dir-detail-link'), '복지 0건이어도 링크 제공');
  });

  test('comp_eng_nm 부재 → 링크 미생성(무크래시)', () => {
    const state = { REF: { companies: [{ comp_id: 9, comp_nm: '무영문사', benefits: [] }] } };
    assert.doesNotThrow(() => mountDirectory(state));
    document.querySelector('.dir-count').dispatchEvent(new window.Event('click', { bubbles: true }));
    document.querySelector('.dir-comp').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(document.querySelector('.dir-detail-link'), null);
  });
});
