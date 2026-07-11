// web/assets/js/store.js — localStorage 래퍼 + "최근 비교" 봉투(SP-FE-10, FR-07·43·44, NFR16·17·25).
// 저장소 배관·봉투 무결성·FIFO·시그니처만 소유. 요약 콘텐츠/UI 렌더는 report.js(SP-FE-9.4)가,
// RecentComparison의 input/result 필드 구성은 FR-43(FRD 06)이 소유(경계).

// ── SP-FE-10.1 저수준 래퍼(모든 접근 try/catch로 예외 흡수, L-5) ───────────
export const store = {
  get(key) {
    try {
      const v = localStorage.getItem(key);
      return v == null ? null : JSON.parse(v);
    } catch {
      return null;                                          // 접근 거부·파싱 실패 → null(FR-44)
    }
  },
  set(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch {
      return false;                                          // QuotaExceeded·비활성 → 흡수(FR-44)
    }
  },
  remove(key) {
    try { localStorage.removeItem(key); } catch { /* 흡수 */ }
  },
  available() {
    try {
      const k = '__t';
      localStorage.setItem(k, '1');
      localStorage.removeItem(k);
      return true;
    } catch {
      return false;
    }
  },
};

// ── SP-FE-10.2 "최근 비교" 봉투(FR-43 스키마) ───────────────────────────────
const RECENT_KEY = 'loupit.recentComparisons';
const RECENT_V = 1;                                          // 봉투 스키마 버전(FR-43 R4)
const MAX_RECENT = 10;                                        // FR-43 R1

export const recent = {
  list() {                                                    // 불러오기(손상 폐기)
    const env = store.get(RECENT_KEY);
    if (!isValidEnvelope(env)) { store.remove(RECENT_KEY); return []; }   // R4: 손상/버전불일치 폐기
    return env.items.filter(isValidRecord);                  // 개별 손상 레코드도 무시
  },
  save(record) {                                              // 저장(선두 추가·FIFO·dedup)
    if (!store.available()) return false;                    // FR-44: 저장 불가 시 생략
    const items = recent.list();
    const sig = signatureOf(record);
    const idx = items.findIndex(r => signatureOf(r) === sig);
    if (idx >= 0) items.splice(idx, 1);                       // R3: 동일 시그니처 제거(갱신·선두 이동)
    items.unshift(record);                                    // 신규를 선두
    while (items.length > MAX_RECENT) items.pop();            // R2: 초과 시 말미(가장 오래된) 축출
    return store.set(RECENT_KEY, { v: RECENT_V, items });
  },
  removeById(id) {
    const items = recent.list().filter(r => r.id !== id);
    store.set(RECENT_KEY, { v: RECENT_V, items });
  },
  clear() { store.remove(RECENT_KEY); },                      // 전체 삭제
};

function isValidEnvelope(env) {
  return env && env.v === RECENT_V && Array.isArray(env.items);   // R4: v 불일치 → 무효
}
function isValidRecord(r) {                                  // 필수 필드 검증(없으면 폐기)
  return r && typeof r.id === 'string' && typeof r.savedAt === 'string'
    && r.slots && r.input && r.result;
}
function signatureOf(r) {                                    // R3: 양 슬롯 회사(또는 직접입력) + 핵심 입력
  const sid = s => (r.slots[s] && r.slots[s].comp_id != null ? 'c' + r.slots[s].comp_id : 'direct');
  return sid('a') + '|' + sid('b') + '|' + (r.result.priAxis || '');
}
