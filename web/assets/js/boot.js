// web/assets/js/boot.js — 참조 데이터 로드·shape 검증(SP-FE-5, FR-02·E1, SP-API-9, NFR3·26).
// 부팅당 정확히 1회 호출(B-1). 손상 번들은 부팅 오류로 전이(FR-E1).
import { getReference, getReferenceIndex } from './api.js';

// 번들 전체(`/reference/all`) — /find(복지검색)가 쓴다. 비교 화면의 폴백이기도 하다.
export async function loadReference() {
  const ref = await getReference(); // api.js: apiFetch('/reference/all')
  assertRefShape(ref);
  return ref;
}

// 비교 화면 부팅(2026-10-22): 가벼운 목록(`/reference/index`) 하나. 복지 행(상세)은 회사를 고르는 순간
// company-store.js 가 그 회사만 받는다. 404·네트워크 오류·손상(배포 순간 — git pull 로 JS 는 즉시 바뀌는데
// API 재시작이 몇 초 늦다 — 과 장애 대비)이면 `/reference/all` 로 **한 번** 되돌아간다 — 그러면 모든 회사가
// 이미 상세를 가진 예전 부팅이 되고 추가 요청은 0이다.
export async function loadReferenceIndex({ indexFn = getReferenceIndex, allFn = loadReference } = {}) {
  try {
    const ref = await indexFn();
    assertRefShape(ref);
    return ref;
  } catch {
    return allFn();
  }
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
