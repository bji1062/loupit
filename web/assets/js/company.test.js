// web/assets/js/company.test.js — 회사 복지 페이지(GNB 검색 직행 뷰) 테스트.
// 순수(findCompanies·groupBenefitsByCategory) + jsdom DOM(상세/후보목록/무결과 3상태 렌더).
// 데이터는 부팅 REF(companies[].benefits) 재사용 — 네트워크 0.

// ── dom.js가 document를 참조하므로 최소 전역 세팅(jsdom이 뒤에서 교체) ──
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, createElement() { return {}; } };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import { findCompanies, groupBenefitsByCategory, renderCompanyView } from './company.js';

function ben(cd, nm, amt, ctgr, over = {}) {
  return { benefit_cd: cd, benefit_nm: nm, benefit_amt: amt, benefit_ctgr_cd: ctgr, qual_yn: amt == null, amt_source: amt == null ? 'none' : 'stated', badge_cd: 'official', ...over };
}
const SAMSUNG = {
  comp_id: 1, comp_nm: '삼성전자', comp_eng_nm: 'samsung_elec', comp_tp_cd: 'large', industry_nm: '반도체', aliases: ['삼전'],
  benefits: [
    ben('meal', '식대', 240, 'perks'),
    ben('bus', '통근버스', 120, 'perks', { badge_cd: 'est' }),
    ben('health', '건강검진', 60, 'health'),
    ben('daycare', '사내 어린이집', null, 'family'),
  ],
};
const SAMSUNG_SDI = { comp_id: 2, comp_nm: '삼성SDI', comp_eng_nm: 'samsung_sdi', comp_tp_cd: 'large', industry_nm: '배터리', aliases: [], benefits: [ben('meal', '식대', 100, 'perks')] };
const NAVER = { comp_id: 3, comp_nm: '네이버', comp_eng_nm: 'naver', comp_tp_cd: 'large', industry_nm: 'IT', aliases: ['네이버(주)'], benefits: [] };
const ALL = [SAMSUNG, SAMSUNG_SDI, NAVER];

// ── 순수: findCompanies — 완전일치 우선, 부분·별칭·영문 매칭 ────────────────
describe('findCompanies', () => {
  test('완전일치 1개 → 그 회사만', () => {
    const out = findCompanies(ALL, '삼성전자');
    assert.equal(out.length, 1);
    assert.equal(out[0].comp_id, 1);
  });

  test('부분일치 여러 개 → 가나다순(ko 콜레이션: 한글이 라틴보다 앞) 목록', () => {
    const out = findCompanies(ALL, '삼성');
    assert.deepEqual(out.map((c) => c.comp_nm), ['삼성전자', '삼성SDI']);
  });

  test('별칭·영문 식별자 매칭', () => {
    assert.equal(findCompanies(ALL, '삼전')[0].comp_id, 1);
    assert.equal(findCompanies(ALL, 'naver')[0].comp_id, 3);
  });

  test('공백 트림·무결과 → []', () => {
    assert.deepEqual(findCompanies(ALL, '  없는회사  '), []);
    assert.deepEqual(findCompanies(null, '삼성'), []);
    assert.deepEqual(findCompanies(ALL, ''), []);
  });
});

// ── 순수: groupBenefitsByCategory — 9종 고정 순서·빈 카테고리 생략·소계 ─────
describe('groupBenefitsByCategory', () => {
  test('카테고리 고정 순서 그룹 + 소계 + 전체 합계', () => {
    const g = groupBenefitsByCategory(SAMSUNG.benefits);
    assert.deepEqual(g.groups.map((x) => x.ctgr), ['health', 'family', 'perks'], '9종 순서(health<family<perks), 빈 카테고리 생략');
    const perks = g.groups.find((x) => x.ctgr === 'perks');
    assert.equal(perks.sum, 360, 'perks 소계 240+120');
    assert.equal(perks.items.length, 2);
    assert.equal(g.total, 420, '전체 합계(정성 제외)');
  });

  test('미지 카테고리 → perks 정규화, 정성은 소계 미포함', () => {
    const g = groupBenefitsByCategory([ben('x', '이상복지', 10, 'unknown'), ben('q', '정성복지', null, 'unknown')]);
    assert.equal(g.groups.length, 1);
    assert.equal(g.groups[0].ctgr, 'perks');
    assert.equal(g.groups[0].sum, 10);
    assert.equal(g.groups[0].items.length, 2);
  });

  test('빈 입력 → groups [], total 0', () => {
    assert.deepEqual(groupBenefitsByCategory([]), { groups: [], total: 0 });
    assert.deepEqual(groupBenefitsByCategory(null), { groups: [], total: 0 });
  });
});

// ── DOM: renderCompanyView 3상태 ────────────────────────────────────────────
function loadDom() {
  const dom = new JSDOM('<main><section id="view-company"><div id="company-page"></div></section></main>', { url: 'https://loupit.example/', pretendToBeVisual: true });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  return dom;
}

describe('renderCompanyView — 상세/후보목록/무결과', () => {
  beforeEach(() => loadDom());
  const mount = () => document.getElementById('company-page');

  test('매칭 1개 → 회사 헤더 + 카테고리 섹션 + 소계·합계 + 배지 + CTA', () => {
    renderCompanyView({ term: '삼성전자', matches: [SAMSUNG] }, mount(), {});
    const text = mount().textContent;
    assert.match(text, /삼성전자/);
    assert.match(text, /반도체/);
    assert.match(text, /복리후생/, '카테고리 라벨');
    assert.match(text, /건강/, '카테고리 라벨');
    assert.match(text, /식대/);
    assert.match(text, /연 240만원/);
    assert.match(text, /사내 어린이집/);
    assert.match(text, /360만원/, 'perks 소계');
    assert.match(text, /420만원/, '복지 총가치 합계');
    assert.ok(mount().querySelector('.badge-official'), '공식 배지');
    assert.ok(mount().querySelector('.badge-est'), '추정 배지');
    assert.ok(mount().querySelector('.cp-compare-cta'), '비교 시작 CTA');
  });

  test('CTA 클릭 → deps.onCompare(company) 호출', () => {
    const picked = [];
    renderCompanyView({ term: '삼성전자', matches: [SAMSUNG] }, mount(), { onCompare: (c) => picked.push(c) });
    mount().querySelector('.cp-compare-cta').dispatchEvent(new window.Event('click', { bubbles: true }));
    assert.equal(picked.length, 1);
    assert.equal(picked[0].comp_id, 1);
  });

  test('매칭 여러 개 → 후보 목록, 클릭 시 상세 재렌더', () => {
    renderCompanyView({ term: '삼성', matches: [SAMSUNG_SDI, SAMSUNG] }, mount(), {});
    const rows = mount().querySelectorAll('.cp-cand');
    assert.equal(rows.length, 2, '후보 2개');
    rows[1].dispatchEvent(new window.Event('click', { bubbles: true })); // 삼성전자
    assert.match(mount().textContent, /연 240만원/, '클릭 → 상세 전환');
  });

  test('무결과 → 안내 문구', () => {
    renderCompanyView({ term: '없는회사', matches: [] }, mount(), {});
    assert.match(mount().textContent, /없는회사/);
    assert.match(mount().textContent, /검색 결과가 없습니다/);
  });

  test('복지 0개 회사 → "등록된 복지 정보가 없습니다"', () => {
    renderCompanyView({ term: '네이버', matches: [NAVER] }, mount(), {});
    assert.match(mount().textContent, /등록된 복지 정보가 없습니다/);
  });
});

// ── 배지 계보(2026-07-31) — 이 화면이 계보 도입 때 빠져 있었다 ────────────────
// 렌더러를 셋으로 세다 넷째(이 화면)를 놓쳐, 재직자 편집이 시작되면 같은 복지가
// 정적 페이지·디렉터리와 **다른 배지**를 달게 돼 있었다. 여기서 계약을 고정한다.
describe('renderCompanyView — 배지 계보 4종(정적 페이지와 같은 판정)', () => {
  beforeEach(() => loadDom());
  const mount = () => document.getElementById('company-page');
  const NOW = Date.parse('2026-07-31T00:00:00Z');

  function withBenefits(benefits) {
    return { ...SAMSUNG, benefits };
  }

  test('재직자 등록 / 공식·재직자 수정 / 공식 을 각각 구분해 표시', () => {
    renderCompanyView({ term: 'x', matches: [withBenefits([
      ben('a', '카페', 10, 'perks', { edit_origin: 'member' }),
      ben('b', '기숙사', 20, 'perks', { edit_origin: 'edited' }),
      ben('c', '식대', 30, 'perks', { edit_origin: 'seed' }),
    ])] }, mount(), {}, NOW);
    const text = mount().textContent;
    assert.ok(mount().querySelector('.badge-member'), '재직자 등록 배지');
    assert.ok(mount().querySelector('.badge-edited'), '공식·재직자 수정 배지');
    assert.ok(mount().querySelector('.badge-official'), '공식 배지');
    assert.match(text, /재직자 등록/);
    assert.match(text, /공식·재직자 수정/, '상세 화면은 정적 페이지와 같은 전체 문구를 쓴다');
  });

  test('edit_origin 이 badge_cd 를 이긴다(추정이어도 재직자 등록이면 계보 우선)', () => {
    renderCompanyView({ term: 'x', matches: [withBenefits([
      ben('a', '카페', 10, 'perks', { badge_cd: 'est', edit_origin: 'member' }),
    ])] }, mount(), {}, NOW);
    assert.ok(mount().querySelector('.badge-member'));
    assert.equal(mount().querySelector('.badge-est'), null);
  });

  test('만료가 최우선 — 상세 화면이므로 만료를 표시한다(요약인 디렉터리와 다른 점)', () => {
    renderCompanyView({ term: 'x', matches: [withBenefits([
      ben('a', '카페', 10, 'perks', { edit_origin: 'member', expires_dtm: '2026-01-01T00:00:00Z' }),
    ])] }, mount(), {}, NOW);
    assert.ok(mount().querySelector('.badge-stale'), '만료 배지(정적 템플릿과 같은 stale 클래스)');
    assert.match(mount().textContent, /만료·재확인 필요/);
  });
});
