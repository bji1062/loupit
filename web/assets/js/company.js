// web/assets/js/company.js — 회사 복지 페이지(SPA #company 뷰, GNB 검색 직행).
//
// GNB 검색 제출 → findCompanies(REF) → renderCompanyView: 매칭 1개면 회사 상세
// (복지를 9카테고리 고정 순서로 그룹, 소계·총가치·공식/추정 배지), 여러 개면 후보
// 목록, 0개면 안내. 데이터는 부팅 참조 번들 재사용 — 추가 네트워크 0.
// 나무위키 "검색 → 문서 직행" UX 대응(2026-07-16). 실패·host 부재 무해(throw 없음).
import { el } from './dom.js';
import { benefitLine } from './directory.js';

// 9카테고리 표시 라벨 — report.js CATEGORY_LABEL과 동일 어휘(화면 간 용어 일관성).
const CATEGORY_LABEL = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};

// ── 순수: 회사 검색 — comp_nm 완전일치 우선, 부분·별칭·영문 포함(가나다순) ────
export function findCompanies(companies, term) {
  const t = String(term || '').trim();
  if (!Array.isArray(companies) || !t) return [];
  const lower = t.toLowerCase();
  const exact = companies.filter((c) => c.comp_nm === t);
  if (exact.length) return exact;
  return companies
    .filter((c) => String(c.comp_nm || '').includes(t)
      || (Array.isArray(c.aliases) && c.aliases.some((a) => String(a).includes(t)))
      || String(c.comp_eng_nm || '').toLowerCase().includes(lower))
    .sort((a, b) => String(a.comp_nm).localeCompare(String(b.comp_nm), 'ko'));
}

// ── 순수: 카테고리별 그룹 — 9종 고정 순서, 빈 카테고리 생략, 소계·총합(정성 제외) ──
export function groupBenefitsByCategory(benefits) {
  const cats = Object.keys(CATEGORY_LABEL);
  const norm = (c) => (cats.includes(c) ? c : 'perks'); // 미지 카테고리 → perks(엔진 규칙 동일)
  const byCat = new Map();
  for (const b of (benefits || [])) {
    const c = norm(b.benefit_ctgr_cd);
    if (!byCat.has(c)) byCat.set(c, []);
    byCat.get(c).push(b);
  }
  const groups = [];
  let total = 0;
  for (const c of cats) {
    const items = byCat.get(c);
    if (!items || !items.length) continue;
    const sum = items.reduce((acc, b) => acc + ((!b.qual_yn && b.benefit_amt != null) ? b.benefit_amt : 0), 0);
    total += sum;
    groups.push({ ctgr: c, label: CATEGORY_LABEL[c], items, sum });
  }
  return { groups, total };
}

function badgeFor(b) { // directory.js 배지 관례와 동일(공식/추정)
  if (b.badge_cd === 'official') return el('span', { class: 'badge badge-official', text: '공식' });
  return el('span', { class: 'badge badge-est', text: '추정' });
}

function metaChips(company) {
  const wrap = el('div', { class: 'cp-meta' });
  for (const txt of [company.industry_nm].filter(Boolean)) {
    wrap.append(el('span', { class: 'chip', text: txt }));
  }
  return wrap;
}

// 회사 상세(카테고리별 복지)
function renderDetail(company, mountEl, deps) {
  mountEl.replaceChildren();
  const page = el('div', { class: 'cp-page' });

  const head = el('div', { class: 'cp-head' });
  head.append(el('h2', { class: 'cp-nm', text: company.comp_nm }));
  head.append(metaChips(company));
  page.append(head);

  const { groups, total } = groupBenefitsByCategory(company.benefits);
  if (!groups.length) {
    page.append(el('p', { class: 'cp-empty', text: '등록된 복지 정보가 없습니다.' }));
  } else {
    for (const g of groups) {
      const sec = el('section', { class: 'cp-cat', 'data-ctgr': g.ctgr });
      const h = el('div', { class: 'cp-cat-head' });
      h.append(el('h3', { class: 'cp-cat-nm', text: g.label }));
      if (g.sum > 0) h.append(el('span', { class: 'cp-cat-sum', text: '연 ' + g.sum + '만원' }));
      sec.append(h);
      const ul = el('ul', { class: 'cp-ben-list' });
      for (const b of g.items) {
        const li = el('li', { class: 'cp-ben-row' });
        li.append(el('span', { class: 'cp-ben-nm', text: benefitLine(b) })); // "이름 — 연 N만원"/정성은 이름만
        li.append(badgeFor(b));
        ul.append(li);
      }
      sec.append(ul);
      page.append(sec);
    }
    const totalRow = el('p', { class: 'cp-total' });
    totalRow.append(el('span', { text: '복지 총가치(금액 환산 합계): ' }));
    totalRow.append(el('strong', { class: 'cp-total-amt', text: '연 ' + total + '만원' }));
    page.append(totalRow);
    page.append(el('p', { class: 'cp-note', text: '정성 복지(금액 환산 불가)는 합계에 포함되지 않습니다. 추정 금액은 배지로 표기됩니다.' }));
  }

  const actions = el('div', { class: 'cp-actions' });
  const cta = el('button', { type: 'button', class: 'btn cp-compare-cta', text: '이 회사와 비교 시작' });
  cta.addEventListener('click', () => { if (typeof deps.onCompare === 'function') deps.onCompare(company); });
  actions.append(cta);
  actions.append(el('a', { class: 'cp-home', href: '/', text: '← 대문으로' }));
  page.append(actions);

  mountEl.append(page);
  return mountEl;
}

// ── 렌더: 3상태(상세 / 후보 목록 / 무결과) ──────────────────────────────────
export function renderCompanyView(result, mountEl, deps = {}) {
  if (!mountEl) return null;
  const { term = '', matches = [] } = result || {};

  if (matches.length === 1) return renderDetail(matches[0], mountEl, deps);

  mountEl.replaceChildren();
  if (!matches.length) {
    const box = el('div', { class: 'cp-page' });
    box.append(el('h2', { class: 'cp-nm', text: '회사 검색' }));
    box.append(el('p', { class: 'cp-empty', text: '"' + term + '" 검색 결과가 없습니다. 회사명을 다시 확인해주세요.' }));
    box.append(el('a', { class: 'cp-home', href: '/', text: '← 대문으로' }));
    mountEl.append(box);
    return mountEl;
  }

  // 여러 개 매칭 → 후보 목록(클릭 시 상세로 재렌더)
  const box = el('div', { class: 'cp-page' });
  box.append(el('h2', { class: 'cp-nm', text: '"' + term + '" 검색 결과 ' + matches.length + '개' }));
  const ul = el('ul', { class: 'cp-cand-list' });
  for (const c of matches) {
    const li = el('li', {});
    const btn = el('button', { type: 'button', class: 'cp-cand' });
    btn.append(el('span', { class: 'cp-cand-nm', text: c.comp_nm }));
    if (c.industry_nm) btn.append(el('span', { class: 'cp-cand-meta', text: c.industry_nm }));
    btn.addEventListener('click', () => renderDetail(c, mountEl, deps));
    li.append(btn);
    ul.append(li);
  }
  box.append(ul);
  mountEl.append(box);
  return mountEl;
}
