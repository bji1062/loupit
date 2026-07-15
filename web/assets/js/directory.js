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
    return box;
  }
  const ul = el('ul', { class: 'dir-ben-list' });
  for (const b of items) {
    const li = el('li', { class: 'dir-ben-row' });
    li.append(el('span', { class: 'dir-ben-nm', text: benefitLine(b) }));
    li.append(badgeFor(b));
    ul.append(li);
  }
  box.append(ul);
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

  count.addEventListener('click', () => {
    panel.hidden = !panel.hidden;
    count.setAttribute('aria-expanded', String(!panel.hidden));
  });
  return { count: companies.length };
}
