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

// ── 입력 초안(2026-07-31) — "작성 중"을 페이지 이동·새로고침에서 지킨다 ──────
// 계기: 회사 복지를 보러 가면(헤더 검색·디렉터리) **전체 페이지 이동**이라 입력하던
// 연봉·상승률이 통째로 날아간다. '최근 비교'(위)는 **완료된** 리포트만 담으므로
// 작성 중 상태를 지켜 주지 못한다.
// 저장 범위는 처리방침 P2 가 이미 선언한 그대로다 — "비교 입력값(연봉·통근시간·복지
// 선택 등)은 브라우저 localStorage 에만 저장되며 서버로 전송되지 않는다".
// 서버 전송 경로가 없으므로 문안 변경이 필요 없다(수집 시점을 바꾼 익명 쌍 로그와 다르다).
//
// TTL 을 두는 이유: 초안은 "방금 하던 것"을 잇기 위한 것이지 보관물이 아니다. 2주 전
// 입력이 말없이 되살아나면 사용자는 그것이 자기 값인지조차 판단할 수 없다.
const DRAFT_KEY = 'loupit.inputDraft';
const DRAFT_V = 1;
export const DRAFT_TTL_MS = 24 * 60 * 60 * 1000; // 24시간

export const inputDraft = {
  // snapshot 은 순수 데이터(app.js snapshotInput 이 만든다 — 이 모듈은 배관만 소유).
  // 빈 초안은 저장하지 않고 **지운다**: "새 비교" 로 상태를 비운 뒤 페이지를 떠나면
  // 낡은 초안이 남아 다음 방문에 되살아난다.
  save(snapshot, now = Date.now()) {
    if (!store.available()) return false;
    if (!snapshot || !hasAnyInput(snapshot)) { store.remove(DRAFT_KEY); return false; }
    return store.set(DRAFT_KEY, { v: DRAFT_V, savedAt: now, draft: snapshot });
  },
  load(now = Date.now()) {
    const env = store.get(DRAFT_KEY);
    if (!env || env.v !== DRAFT_V || !env.draft || typeof env.savedAt !== 'number') {
      store.remove(DRAFT_KEY); return null;                  // 손상·버전불일치 → 폐기
    }
    if (now - env.savedAt > DRAFT_TTL_MS) { store.remove(DRAFT_KEY); return null; } // 만료
    return hasAnyInput(env.draft) ? env.draft : null;
  },
  clear() { store.remove(DRAFT_KEY); },
};

// 되살릴 가치가 있는 내용이 하나라도 있는가(전부 비면 초안이 아니다).
export function hasAnyInput(d) {
  if (!d || typeof d !== 'object') return false;
  const slots = d.slots || {};
  for (const s of ['a', 'b']) {
    const v = slots[s];
    if (v && (Number.isInteger(v.comp_id) || typeof v.comp_tp_cd === 'string')) return true;
  }
  const sal = (d.salS && d.salS.a) || {};
  if (sal.low != null || sal.high != null) return true;
  if (d.selectedRate != null) return true;
  const cmt = d.cmtS || {};
  return cmt.a != null || cmt.b != null;
}

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
