// web/assets/js/find-notes.js — 복지검색 설명 저장소 (2026-10-22, /find 경량화).
//
// 부팅은 설명 없는 가벼운 묶음(`/reference/find`)만 받는다. 결과 행의 한 줄 설명(`benefitNote`)은 ① 조건 없음 화면의 회사마다 금액 큰
// 3개 행 — 묶음의 `top_notes` 로 부팅 때 이미 채워 둔다 ② 고른 코드의 행 — 그 코드를 **고를 때** `/reference/notes/{code}` 로 받는다.
// 받은 설명은 같은 회사 행 객체에 `qual_desc_ctnt` · `note_ctnt` 로 써 넣어 `benefitNote(b)` 가 그대로 돈다.
//
// 상태는 행 자체가 말한다(`qual_desc_ctnt` 키가 있으면 ok) — 폴백 부팅(`/reference/all`)의 행은 처음부터 키를 가져 저장소 없이도 ok 다.
// 🚨 실패한 코드는 `failed` 로 두고 **자동으로 다시 받지 않는다**(렌더가 부를 때마다 무한 반복 금지) — 사용자가 그 코드를 다시 누르거나
// 「다시 시도」를 누를 때만 다시 받는다. 같은 코드를 동시에 두 번 받지 않는다(진행 중 약속 공유).
import { getReferenceNotes } from './api.js';

export const NOTE_LOADING = '설명 불러오는 중…';
export const NOTE_FAILED = '설명을 불러오지 못했습니다';
export const NOTE_RETRY = '다시 시도';

/** 가벼운 묶음인가(번들 전체가 아니라). 저장소가 필요한 쪽은 이쪽뿐이다. */
export function isLightRef(ref) { return !!ref && Array.isArray(ref.top_notes); }

const hasNote = (b) => Object.prototype.hasOwnProperty.call(b, 'qual_desc_ctnt');

function setNote(b, n) {
  b.qual_desc_ctnt = n ? n.qual_desc_ctnt ?? null : null;
  b.note_ctnt = n ? n.note_ctnt ?? null : null;
}

/**
 * `ref`(가벼운 묶음)의 설명 저장소. `top_notes` 는 만들 때 바로 반영한다.
 *   · `state(b)`            'ok' | 'loading' | 'failed'
 *   · `ensure(codes, {retry})`  아직 안 받은 코드만 병렬로 받는다(약속 반환 — 던지지 않는다). `retry` 면 실패한 코드도 다시.
 *   · `track(span, b, render)`  설명 칸을 등록 — 도착하면 `render(span, b)` 로 그 칸만 다시 그린다(목록 전체를 갈지 않는다)
 *   · `ensureTracked()`     화면에 붙은 칸 중 `loading` 인 코드를 받는다(조건 없음 3개가 묶음과 어긋난 드문 경우의 안전판)
 */
export function createNoteStore(ref, { fetchFn = getReferenceNotes } = {}) {
  const rowsByCode = new Map(); // 코드 → [{comp_id, b}]
  const byKey = new Map(); //      `${comp_id}\u0000${코드}` → b
  for (const c of ref.companies || []) {
    for (const b of c.benefits || []) {
      if (!rowsByCode.has(b.benefit_cd)) rowsByCode.set(b.benefit_cd, []);
      rowsByCode.get(b.benefit_cd).push({ comp_id: c.comp_id, b });
      byKey.set(`${c.comp_id}\u0000${b.benefit_cd}`, b);
    }
  }
  for (const t of ref.top_notes || []) {
    const b = byKey.get(`${t.comp_id}\u0000${t.benefit_cd}`);
    if (b) setNote(b, t);
  }

  const done = new Set(); //     코드 전체를 받은 코드
  const failed = new Set(); //   마지막 시도가 실패한 코드
  const inflight = new Map(); // 코드 → 약속
  const tracked = new Map(); //  설명 칸 → {b, render}

  function state(b) {
    if (hasNote(b)) return 'ok';
    return failed.has(b.benefit_cd) ? 'failed' : 'loading';
  }

  function refreshTracked() {
    for (const [span, t] of [...tracked]) {
      if (!span.isConnected) { tracked.delete(span); continue; }
      t.render(span, t.b);
      if (state(t.b) === 'ok') tracked.delete(span);
    }
  }

  function fetchCode(code) {
    const p = (async () => {
      try {
        const res = await fetchFn(code);
        const byComp = new Map(((res && res.notes) || []).map((n) => [n.comp_id, n]));
        // 응답에 없는 회사의 그 코드 행은 「설명 없음」으로 ok(`—`). 응답의 모르는 comp_id 는 그냥 무시된다.
        for (const { comp_id, b } of rowsByCode.get(code)) setNote(b, byComp.get(comp_id));
        done.add(code);
        failed.delete(code);
      } catch {
        failed.add(code);
      } finally {
        inflight.delete(code);
      }
      refreshTracked();
    })();
    inflight.set(code, p);
    return p;
  }

  function ensure(codes, { retry = false } = {}) {
    const jobs = [];
    for (const code of new Set(codes || [])) {
      if (!rowsByCode.has(code) || done.has(code)) continue; // 모르는 코드 · 이미 받은 코드
      if (inflight.has(code)) { jobs.push(inflight.get(code)); continue; }
      if (failed.has(code) && !retry) continue; // 자동 재시도 금지
      failed.delete(code);
      jobs.push(fetchCode(code));
    }
    return Promise.all(jobs).then(() => undefined);
  }

  function track(span, b, render) {
    if (state(b) !== 'ok') tracked.set(span, { b, render });
  }

  function ensureTracked() {
    const codes = [];
    for (const [span, t] of tracked) if (span.isConnected && state(t.b) === 'loading') codes.push(t.b.benefit_cd);
    return ensure(codes);
  }

  return { state, ensure, track, ensureTracked, refreshTracked, isDone: (code) => done.has(code) };
}
