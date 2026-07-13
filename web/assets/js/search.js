// web/assets/js/search.js — 검색 오케스트레이션(디바운스·경합·후보 렌더, SP-FE-7, FR-10~13, SP-API-10).
// 설계 메모: inputs.js와 동일하게(SP-FE-1.2 규칙3) App.state는 함수 인자로 받는다(순환 import 회피).
import { el } from './dom.js';
import { searchCompanies } from './api.js';
import { selectCompany, clearSlot } from './inputs.js';

export const DEBOUNCE_MS = 300; // 레거시 doSearch 이식값(FR-10)

// 기업유형 코드 → 표시 라벨(SP-DB-2 COMP_TP_NM 정본). 검색 결과(5필드)는 comp_tp_cd만 포함.
const TYPE_LABELS = {
  large: '대기업', mid: '중견기업', startup: '스타트업',
  foreign: '외국계', public: '공기업', freelance: '프리랜서',
};
export function typeLabel(compTpCd) { return TYPE_LABELS[compTpCd] || '기타'; }

// ── SP-FE-7.2 결정적 정렬·dedup(FR-11·12) ───────────────────────────────────
export function rank(it, nq) {
  const n = (it.comp_nm || '').toLowerCase();
  if (n === nq) return 0; // 완전일치
  if (n.startsWith(nq)) return 1; // 정식명 접두
  return 2; // 그외
}

export function sortCandidates(items, q) { // 서버 순서에 의존하지 않음(FR-12 R3)
  const nq = (q || '').toLowerCase();
  return items.slice().sort((x, y) => (
    rank(x, nq) - rank(y, nq) // 1 완전일치 <2 접두 <3 그외
    || x.comp_nm.length - y.comp_nm.length // 4 길이 오름차순
    || x.comp_nm.localeCompare(y.comp_nm, 'ko') // 5 가나다(ko)
  ));
}

export function dedupById(items) { // comp_id 방어적 dedup(FR-11 R3, 선순위 보존)
  const seen = new Set();
  const out = [];
  for (const it of items) {
    if (!seen.has(it.comp_id)) { seen.add(it.comp_id); out.push(it); }
  }
  return out;
}

// ── 검색 상태 헬퍼(state.ui.searchState) ───────────────────────────────────
export function setSearchState(state, slot, s) {
  state.ui.searchState[slot] = s;
  // UI 반영 훅(선택) — ui.js mountUI가 셸 메시지 토글용으로 주입. 미주입(단위 테스트)이면 무시.
  if (state.ui && typeof state.ui.onSearchState === 'function') state.ui.onSearchState(slot, s);
}
export function closeCandidates(state, slot) { setSearchState(state, slot, 'idle'); }

// ── SP-FE-7.1 디바운스·빈쿼리 가드(S-1·S-2) ─────────────────────────────────
export function onSearchInput(state, slot, raw, hooks = {}) {
  const q = raw.trim();
  clearTimeout(state.ui.searchTimers[slot]); // 슬롯 독립 타이머 리셋
  if (q.length < 1) { closeCandidates(state, slot); return; } // 빈/공백 → 패널 닫고 미호출(FR-10 R1)
  setSearchState(state, slot, 'loading'); // "검색 중…"
  state.ui.searchTimers[slot] = setTimeout(() => runSearch(state, slot, q, hooks), DEBOUNCE_MS);
}

// ── SP-FE-7.1 경합 폐기·무결과/오류 구분(S-1·S-3) ───────────────────────────
export async function runSearch(state, slot, q, hooks = {}) {
  const { searchCompaniesFn = searchCompanies, onRendered } = hooks;
  if (state.ui.searchAborts[slot]) state.ui.searchAborts[slot].abort(); // 이전 요청 취소
  const ctrl = new AbortController();
  state.ui.searchAborts[slot] = ctrl;
  try {
    const items = await searchCompaniesFn(q, { signal: ctrl.signal });
    if (state.ui.searchAborts[slot] !== ctrl) return; // 최신 아니면 폐기(경합)
    const sorted = sortCandidates(dedupById(items), q);
    if (sorted.length) {
      renderCandidates(state, slot, sorted, q, hooks);
      if (typeof onRendered === 'function') onRendered(sorted);
    } else {
      setSearchState(state, slot, 'empty'); // FR-13 무결과
    }
  } catch (err) {
    if (ctrl.signal.aborted) return; // 취소는 무시(경합)
    // 오류 ≠ 무결과(FR-13 R1). 우선 REF 번들 폴백 매칭 시도(FR-E2).
    bundleFallbackSearch(state, slot, q, hooks);
  }
}

// ── SP-FE-7.3 후보 렌더(안전, S-4·S-6) ──────────────────────────────────────
export function renderCandidates(state, slot, items, q, hooks = {}) {
  const { doc = (typeof document !== 'undefined' ? document : undefined) } = hooks;
  if (doc) {
    const list = doc.getElementById('cand-' + slot);
    if (list) {
      list.replaceChildren(); // 기존 제거
      for (const it of items.slice(0, 20)) { // 20건 상한(FR-11 R2·FR-12 R5)
        const li = el('li', { class: 'cand', role: 'option', tabindex: '0' });
        li.append(el('span', { class: 'cand-nm', text: it.comp_nm })); // textContent(NFR21)
        li.append(el('span', { class: 'cand-meta', text: typeLabel(it.comp_tp_cd) + ' · ' + (it.industry_nm || '') }));
        li.addEventListener('click', () => selectCompany(state, slot, it.comp_id, hooks));
        li.addEventListener('keydown', (e) => { if (e.key === 'Enter') selectCompany(state, slot, it.comp_id, hooks); });
        list.append(li);
      }
    }
  }
  setSearchState(state, slot, 'results');
}

// ── T-06.7.6 bundleFallbackSearch — 검색 API 실패 시 REF 번들 폴백(UT-SEARCH-FB-1, FR-E2) ──
// 네트워크 무의존(NFR26)·읽기전용·무전송(INV-4). comp_nm/comp_eng_nm/aliases 대상 완전·접두·부분 일치.
export function bundleFallbackSearch(state, slot, q, hooks = {}) {
  const companies = (state.REF && state.REF.companies) || [];
  const nq = q.toLowerCase();
  const matches = companies.filter((c) => {
    const nm = (c.comp_nm || '').toLowerCase();
    const eng = (c.comp_eng_nm || '').toLowerCase();
    const aliasHit = Array.isArray(c.aliases) && c.aliases.some((a) => (a || '').toLowerCase().includes(nq));
    return nm.includes(nq) || eng.includes(nq) || aliasHit;
  });
  const sorted = sortCandidates(dedupById(matches), q);
  if (sorted.length) {
    renderCandidates(state, slot, sorted, q, hooks);
  } else {
    setSearchState(state, slot, 'error');
  }
  return sorted;
}

// 재노출(SP-FE-1.1 공개 심볼표: search.js가 selectCompany·clearSlot도 노출).
export { selectCompany, clearSlot };
