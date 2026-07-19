// web/assets/js/directory.js — 등록 회사 디렉토리(검색 카드 우측 상단 카운트 → 전체 목록).
//
// "등록된 회사 수: N" 버튼을 검색 카드에 렌더하고, 클릭 시 REF.companies를 가나다순으로
// 펼쳐 보여준다. 목록에서 회사를 클릭하면 그 회사의 복지가 아코디언으로 펼쳐진다(한 번에
// 하나만). 데이터는 부팅 참조 번들(REF) 재사용 — 추가 네트워크 0(SP-FE-5 소비만).
// 위젯 실패·host 부재는 비교 툴에 무해해야 한다(throw 없음).
import { el } from './dom.js';

// ── 순수: 한국어 가나다순 정렬(사본 — 원본 REF 불변) ────────────────────────
export function sortCompanies(companies) {
  if (!Array.isArray(companies)) return [];
  return [...companies].sort((a, b) => String(a.comp_nm).localeCompare(String(b.comp_nm), 'ko'));
}

// ── 순수: 복지 1건 표기(금액 있으면 "이름 — 연 N만원", 정성은 이름만) ────────
export function benefitLine(b) {
  const amt = (b && b.benefit_amt != null) ? ' — 연 ' + b.benefit_amt + '만원' : '';
  return (b ? b.benefit_nm : '') + amt;
}

// ── 순수: comp_eng_nm → 회사 상세 페이지 slug (FR-51) ────────────────────────
// ⚠ 정본은 generator/slug.py `slug_of()` — 정적 페이지 경로를 만드는 쪽이 소유한다.
// REF 번들이 slug를 싣지 않아 여기서 같은 규칙을 미러링하며, 실데이터 95개사 전량이
// 양쪽에서 일치함을 directory.test.js가 검증한다(드리프트 시 테스트 실패).
export function slugOf(compEngNm) {
  const s = String(compEngNm || '').trim().toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/-{2,}/g, '-')
    .replace(/^-+|-+$/g, '');
  return s || null;                       // 빈 slug → 링크 미생성(무크래시)
}

export function companyHref(compEngNm) {
  const s = slugOf(compEngNm);
  return s ? '/company/' + s : null;
}

function badgeFor(b) {
  // 기존 배지 체계(SP-DS .badge-official/.badge-est) 재사용 — 출처 신뢰도 정직 표기(FR-05)
  if (b.badge_cd === 'official') return el('span', { class: 'badge badge-official', text: '공식' });
  return el('span', { class: 'badge badge-est', text: '추정' });
}

function benefitsPanel(company) {
  const box = el('div', { class: 'dir-benefits' });
  box.hidden = true;
  const items = Array.isArray(company.benefits) ? company.benefits : [];
  if (!items.length) {
    box.append(el('p', { class: 'dir-ben-empty', text: '등록된 복지 정보가 없습니다.' }));
  } else {
    const ul = el('ul', { class: 'dir-ben-list' });
    for (const b of items) {
      const li = el('li', { class: 'dir-ben-row' });
      li.append(el('span', { class: 'dir-ben-nm', text: benefitLine(b) }));
      li.append(badgeFor(b));
      ul.append(li);
    }
    box.append(ul);
  }
  // 정적 상세 페이지 진입점(2026-07-19 고아 페이지 해소): 회사 95·조합 3 페이지로
  // 가는 내부 링크가 사이트 전체에 0건이라 sitemap 외 도달 경로가 없었다. 상세에는
  // 출처·확인일·만료 배지 등 이 패널에 없는 정보가 있다.
  const href = companyHref(company.comp_eng_nm);
  if (href) {
    box.append(el('a', { class: 'dir-detail-link', href, text: company.comp_nm + ' 상세 보기 →' }));
  }
  return box;
}

function companyRow(company, onToggle) {
  const li = el('li', { class: 'dir-row' });
  const btn = el('button', { type: 'button', class: 'dir-comp', 'aria-expanded': 'false' });
  btn.append(el('span', { class: 'dir-comp-nm', text: company.comp_nm }));
  const meta = [company.industry_nm].filter(Boolean).join(' · ');
  if (meta) btn.append(el('span', { class: 'dir-comp-meta', text: meta }));
  const ben = benefitsPanel(company);
  btn.addEventListener('click', () => onToggle(btn, ben));
  li.append(btn, ben);
  return li;
}

// ── 마운트: #company-directory(검색 카드 내) — REF 기반, 항상 무해 ───────────
export function mountDirectory(state) {
  const host = (typeof document !== 'undefined' && document.getElementById)
    ? document.getElementById('company-directory') : null;
  if (!host) return null;
  const companies = sortCompanies(state && state.REF && state.REF.companies);
  if (!companies.length) return null; // 참조 없음 → 미노출(부팅 오류와 동일 무해 원칙)

  host.replaceChildren();
  const count = el('button', { type: 'button', class: 'dir-count', 'aria-expanded': 'false' });
  count.append(el('span', { text: '등록된 회사 수: ' }));
  count.append(el('strong', { class: 'dir-count-n', text: String(companies.length) }));
  host.append(count);

  const panel = el('div', { class: 'dir-panel' });
  panel.hidden = true;
  panel.append(el('p', { class: 'dir-hint', text: '가나다순 전체 목록 — 회사를 누르면 복지가 펼쳐집니다.' }));
  const list = el('ol', { class: 'dir-list' });

  let openBen = null; // 아코디언: 한 번에 한 회사만 펼침
  let openBtn = null;
  function toggle(btn, ben) {
    const willOpen = ben.hidden;
    if (openBen && openBen !== ben) {
      openBen.hidden = true;
      if (openBtn) openBtn.setAttribute('aria-expanded', 'false');
    }
    ben.hidden = !willOpen;
    btn.setAttribute('aria-expanded', String(willOpen));
    openBen = willOpen ? ben : null;
    openBtn = willOpen ? btn : null;
  }
  for (const c of companies) list.append(companyRow(c, toggle));
  panel.append(list);
  host.append(panel);

  function resetAccordion() { // 재클릭 = 새로고침: 펼쳐진 복지 전부 접힘
    if (openBen) openBen.hidden = true;
    if (openBtn) openBtn.setAttribute('aria-expanded', 'false');
    openBen = null;
    openBtn = null;
  }
  count.addEventListener('click', () => {
    panel.hidden = !panel.hidden;
    count.setAttribute('aria-expanded', String(!panel.hidden));
    resetAccordion(); // 열든 닫든 목록은 항상 초기 상태로
  });
  return { count: companies.length };
}
