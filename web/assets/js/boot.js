// web/assets/js/boot.js — reference/all 로드·shape 검증(SP-FE-5, FR-02·E1, SP-API-9, NFR3·26).
// 부팅당 정확히 1회 호출(B-1). 손상 번들은 부팅 오류로 전이(FR-E1).
import { getReference } from './api.js';

export async function loadReference() {
  const ref = await getReference(); // api.js: apiFetch('/reference/all')
  assertRefShape(ref);
  return ref;
}

// 최상위 3키(company_types[]·benefit_presets{}·companies[]) 검증. 실패 시 throw(REF_SHAPE).
export function assertRefShape(ref) {
  const ok = !!ref
    && Array.isArray(ref.company_types)
    && ref.benefit_presets != null && typeof ref.benefit_presets === 'object' && !Array.isArray(ref.benefit_presets)
    && Array.isArray(ref.companies);
  if (!ok) throw new Error('REF_SHAPE'); // 손상 번들 → 부팅 오류로 전이(FR-E1)
  return true;
}
