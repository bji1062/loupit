// web/assets/js/company-store.js — 회사 상세(복지 행) 저장소 (2026-10-22, 비교 화면 경량화).
//
// 부팅은 복지 행이 없는 가벼운 목록(`/reference/index`)만 받는다. 복지 행(상세)은 화면이 그 회사를 **쓰는 순간**
// `/reference/companies/{id}` 로 한 곳씩 받아 같은 REF 회사 객체에 합친다 — 다른 모듈이 쥔 참조가 그대로 상세를 본다.
//
// 🚨 이 파일이 지키는 것: 상세 없는 회사 객체를 `normalizeCompany → fillBenefits` 에 넘기면 「복지 0개 회사」로
// **조용히** 그려진다. 상세가 필요한 동기 지점은 전부 `hasDetail` 로 확인하고, 없으면 먼저 `ensureCompanies` 로 받는다.
// `/reference/all` 로 부팅했으면 모든 회사가 이미 상세를 가져 요청은 0이다.
import { getReferenceCompany } from './api.js';

// 「상세 있음」 = 복지 배열이 있다(빈 배열도 상세다 — 가벼운 목록에는 이 키가 아예 없다).
export function hasDetail(c) { return !!c && Array.isArray(c.benefits); }

// state 별 진행 중 요청: 같은 id 를 동시에 두 번 받지 않는다(약속 공유). 끝나면(성공이든 실패든) 지운다 —
// 실패는 기억하지 않아 다음에 다시 시도한다.
const _inflight = new WeakMap();

/**
 * 회사 하나의 상세를 받아 REF 의 그 회사 객체에 합치고 그 객체를 돌려준다(이미 상세가 있으면 요청 0).
 * REF 에 없는 id 는 받은 객체를 그대로 돌려준다(옛 폴백 — 검색 API 가 번들보다 새로울 때).
 * 실패하면 던진다(상태를 바꾸지 않는다).
 */
export function loadDetail(state, compId, fetchFn = getReferenceCompany) {
  const known = ((state && state.REF && state.REF.companies) || []).find((c) => c.comp_id === compId);
  if (known && hasDetail(known)) return Promise.resolve(known);
  let bag = _inflight.get(state);
  if (!bag) { bag = new Map(); _inflight.set(state, bag); }
  const key = String(compId);
  if (bag.has(key)) return bag.get(key);
  const p = (async () => {
    const detail = await fetchFn(compId);
    if (!detail || typeof detail !== 'object') throw new Error('COMPANY_SHAPE');
    if (!known) return detail;
    // 합치기 전에 모양을 본다: 복지 배열이 없거나 다른 회사면 합치지 않는다(합치면 「상세 있음」으로 오판된다).
    if (!Array.isArray(detail.benefits) || (detail.comp_id != null && detail.comp_id !== known.comp_id)) {
      throw new Error('COMPANY_SHAPE');
    }
    Object.assign(known, detail);
    return known;
  })().finally(() => { bag.delete(key); });
  bag.set(key, p);
  return p;
}

/**
 * 여러 회사의 상세를 **병렬**로 받는다. 던지지 않는다 — 받지 못한 id 목록을 돌려준다(빈 배열이면 전부 성공).
 * REF 에 없는 id 는 건너뛴다(없는 회사는 예전처럼 조용히 빠진다).
 */
export async function ensureCompanies(state, ids, fetchFn = getReferenceCompany) {
  const known = new Set(((state && state.REF && state.REF.companies) || []).map((c) => c.comp_id));
  const want = [...new Set((ids || []).filter((id) => Number.isInteger(id) && known.has(id)))];
  const done = await Promise.allSettled(want.map((id) => loadDetail(state, id, fetchFn)));
  return want.filter((_, i) => done[i].status === 'rejected');
}
