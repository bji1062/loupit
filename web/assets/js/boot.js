// web/assets/js/boot.js — 참조 데이터 로드·shape 검증(SP-FE-5, FR-02·E1, SP-API-9, NFR3·26).
// 부팅당 정확히 1회 호출(B-1). 손상 번들은 부팅 오류로 전이(FR-E1).
import { ApiError, getReference, getReferenceFind, getReferenceIndex } from './api.js';

// 번들 전체(`/reference/all`) — /find(복지검색)가 쓴다. 비교 화면의 폴백이기도 하다.
export async function loadReference() {
  const ref = await getReference(); // api.js: apiFetch('/reference/all')
  assertRefShape(ref);
  return ref;
}

// 비교 화면 부팅(2026-10-22): 가벼운 목록(`/reference/index`) 하나. 복지 행(상세)은 회사를 고르는 순간
// company-store.js 가 그 회사만 받는다. 404·네트워크 오류·손상(배포 순간 — git pull 로 JS 는 즉시 바뀌는데
// API 재시작이 몇 초 늦다)에만 `/reference/all` 로 **한 번** 되돌아간다 — 404 와 네트워크 오류(응답 없음)만이다.
// 429 · 5xx · 시간 초과 · 손상은 되돌아가지 않고 기존 부팅 오류로 간다(과부하 때 4.6MB 를 더 요청하면 악화시킨다).
// 폴백 부팅은 모든 회사가 이미 상세를 가진 예전 부팅이라 추가 요청은 0이다.
export async function loadReferenceIndex({ indexFn = getReferenceIndex, allFn = loadReference } = {}) {
  try {
    const ref = await indexFn();
    assertRefShape(ref);
    return ref;
  } catch (err) {
    if (!isMissingOrOffline(err)) throw err;
    return allFn();
  }
}

// 복지검색 부팅(2026-10-22): 설명 없는 가벼운 묶음(`/reference/find`) 하나. 설명은 find-notes.js 가 `top_notes`(회사마다 금액 큰 3개 행)로
// 먼저 채우고, 그 밖은 고른 코드마다 받는다. 폴백 규칙은 `loadReferenceIndex` 와 같다 — 404 · 네트워크 오류(응답 없음)에만
// `/reference/all` 로 **한 번** 되돌아간다(배포 순간 JS 는 즉시 바뀌는데 API 재시작이 몇 초 늦다). 429 · 5xx · 시간 초과 · 손상은 기존 부팅 오류로 간다.
// 폴백 부팅은 모든 행이 설명을 이미 가져 설명 요청이 0이다.
export async function loadFindBundle({ findFn = getReferenceFind, allFn = loadReference } = {}) {
  try {
    const ref = await findFn();
    assertFindShape(ref);
    return ref;
  } catch (err) {
    if (!isMissingOrOffline(err)) throw err;
    return allFn();
  }
}

// 404(ApiError) 또는 응답이 없는 네트워크 오류(fetch 의 TypeError). 시간 초과(AbortError)는 아니다.
function isMissingOrOffline(err) {
  if (err instanceof ApiError) return err.status === 404;
  return !!err && err.name === 'TypeError';
}

// 최상위 3키(company_types[]·benefit_presets{}·companies[]) 검증. 실패 시 throw(REF_SHAPE).
// 가벼운 목록은 눈금 통계(category_stats)를 더 싣는다 — 있으면 모양도 본다(없으면 번들 꼴).
export function assertRefShape(ref) {
  const ok = !!ref
    && Array.isArray(ref.company_types)
    && ref.benefit_presets != null && typeof ref.benefit_presets === 'object' && !Array.isArray(ref.benefit_presets)
    && Array.isArray(ref.companies)
    && (ref.category_stats === undefined || isStatsShape(ref.category_stats));
  if (!ok) throw new Error('REF_SHAPE'); // 손상 번들 → 부팅 오류로 전이(FR-E1)
  return true;
}

function isStatsShape(s) {
  return !!s && typeof s === 'object' && Number.isInteger(s.total) && Number.isInteger(s.rmax)
    && s.sums != null && typeof s.sums === 'object' && !Array.isArray(s.sums);
}

// 복지검색 가벼운 묶음 검증 — 최상위 3키(company_types[]·companies[]·top_notes[]), 회사마다 benefits[]. 번들 검증(assertRefShape)은
// `benefit_presets` 를 요구해 그대로 쓰지 못한다. 실패 시 throw(REF_SHAPE).
export function assertFindShape(ref) {
  const ok = !!ref
    && Array.isArray(ref.company_types)
    && Array.isArray(ref.top_notes)
    && Array.isArray(ref.companies)
    && ref.companies.every((c) => !!c && Array.isArray(c.benefits));
  if (!ok) throw new Error('REF_SHAPE'); // 손상 묶음 → 부팅 오류로 전이(FR-E1)
  return true;
}
