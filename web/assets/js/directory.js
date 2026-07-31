// web/assets/js/directory.js — 등록 회사 디렉토리(검색 카드 우측 상단 카운트 → 전체 목록).
//
// "등록된 회사 수: N" 버튼을 검색 카드에 렌더하고, 클릭 시 REF.companies를 가나다순으로
// 펼쳐 보여준다. 목록의 회사를 누르면 **정적 상세 페이지로 이동**한다.
// 데이터는 부팅 참조 번들(REF) 재사용 — 추가 네트워크 0(SP-FE-5 소비만).
// 위젯 실패·host 부재는 비교 툴에 무해해야 한다(throw 없음).
//
// ── 아코디언을 걷어낸 이유(2026-07-31) ──────────────────────────────────────
// 같은 회사의 복지를 그리는 화면이 셋이었다: 이 아코디언(요약) · GNB 검색의 SPA 상세 ·
// 정적 `/company/<slug>`. 그런데 **가장 많이 보여주고 광고가 붙은 것은 정적 페이지**인데
// (확인일·만료·근무형태·관련 회사 링크·광고 2슬롯) 유입은 거기로 가지 않았다. 2026-07-19 에
// 고아 페이지를 고치려고 넣은 `상세 보기 →` 링크는 아코디언을 두 번 펼쳐야 나오는 자리라
// 사실상 묻혀 있었다. 디렉터리는 이제 **찾기만** 하고, 읽기는 상세가 맡는다.
// ⚠ 행 클릭 = 전체 페이지 이동이라 비교 입력이 날아갈 수 있다 → app.js 입력 초안(inputDraft)이
//   그 손실을 막는다. 초안 배선을 걷어내면 이 목록이 사용자 입력을 지우게 된다.
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

// ── 순수: 행 보조 정보("반도체 · 복지 12개") — 찾을 때 실제로 쓸모 있는 값만 ──
// 복지 수는 세어서 나오는 사실이라 과장이 없다(금액 합계 같은 추정치를 여기 넣지 마라).
export function rowMeta(company) {
  const n = Array.isArray(company && company.benefits) ? company.benefits.length : 0;
  return [company && company.industry_nm, n > 0 ? '복지 ' + n + '개' : '']
    .filter(Boolean).join(' · ');
}

function companyRow(company) {
  const li = el('li', { class: 'dir-row' });
  const href = companyHref(company.comp_eng_nm);
  // slug 를 만들 수 없는 회사(영문 식별자 부재)는 **링크를 만들지 않는다** — 404 로 가는
  // 링크는 링크 없는 것보다 나쁘다(출처 아웃링크를 내린 것과 같은 판단).
  const node = href ? el('a', { class: 'dir-comp', href })
    : el('span', { class: 'dir-comp dir-comp-plain' });
  node.append(el('span', { class: 'dir-comp-nm', text: company.comp_nm }));
  const meta = rowMeta(company);
  if (meta) node.append(el('span', { class: 'dir-comp-meta', text: meta }));
  li.append(node);
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
  panel.append(el('p', {
    class: 'dir-hint',
    text: '가나다순 전체 목록 — 회사를 누르면 복지 상세 페이지로 이동합니다.',
  }));
  const list = el('ol', { class: 'dir-list' });
  for (const c of companies) list.append(companyRow(c));
  panel.append(list);
  host.append(panel);

  count.addEventListener('click', () => {
    panel.hidden = !panel.hidden;
    count.setAttribute('aria-expanded', String(!panel.hidden));
  });
  return { count: companies.length };
}
