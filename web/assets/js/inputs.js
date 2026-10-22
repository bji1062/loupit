// web/assets/js/inputs.js — 회사 선택 반영·정규화·프리셋 채움·근무형태 초기화
// (SP-FE-8, FR-14~17·21·23, FR-D8·D7·D11, FR-06).
//
// 설계 메모(SP-FE-1.2 규칙3 적용): "상태는 app.js가 단일 소유하고 다른 모듈은 함수 인자 또는
// App 네임스페이스로 접근한다"의 두 옵션 중 **함수 인자** 방식을 택한다. app.js를 import하면
// (app.js가 이미 inputs.js를 import하므로) 순환 import가 발생해 SP-FE-1.2 규칙4를 위반한다.
// 따라서 본 모듈의 함수는 App.state(또는 그 슬라이스)를 첫 인자로 받는다 — app.js가 호출 시
// App.state를 그대로 넘긴다. 순수성이 높아져 단위 테스트도 App 전역 스텁 없이 가능하다.
import { getReferenceCompany } from './api.js';
import { hasDetail, loadDetail, bumpSlot, seqSnapshot, seqCurrent } from './company-store.js';

const CTGR9 = new Set([
  'compensation', 'flexibility', 'work_env', 'time_off',
  'health', 'family', 'growth', 'leisure', 'perks',
]);
const AMT3 = new Set(['stated', 'estimated', 'none']);

// ── SP-FE-8.2 normalizeCompany·normalizeBenefit(FR-D8.2) ───────────────────
// API/번들/프리셋 회사 객체를 동일 shape로 통일.
export function normalizeCompany(raw) {
  raw = raw || {};
  return {
    comp_id: raw.comp_id ?? null,
    comp_nm: raw.comp_nm || '',
    comp_eng_nm: raw.comp_eng_nm || '',
    comp_tp_cd: raw.comp_tp_cd || null,
    industry_nm: raw.industry_nm || null,
    logo_nm: raw.logo_nm || null,
    work_style_val: raw.work_style_val || null, // {remote,flex,unlimitedPTO,refreshLeave,overtime,cond?}
    aliases: Array.isArray(raw.aliases) ? raw.aliases : [],
    benefits: (Array.isArray(raw.benefits) ? raw.benefits : []).map(normalizeBenefit),
  };
}

export function normalizeBenefit(b) {
  b = b || {};
  const qual = !!b.qual_yn; // 불리언 강제(FR-D8.2)
  return {
    benefit_cd: b.benefit_cd,
    benefit_nm: b.benefit_nm || '',
    benefit_amt: qual ? null : (b.benefit_amt ?? null), // 정성이면 금액 없음
    benefit_ctgr_cd: CTGR9.has(b.benefit_ctgr_cd) ? b.benefit_ctgr_cd : 'perks', // 미상→perks
    badge_cd: b.badge_cd === 'official' ? 'official' : 'est', // 미상→est
    amt_source: AMT3.has(b.amt_source) ? b.amt_source : (qual ? 'none' : 'estimated'), // 금액 신뢰도(밴드용)
    qual_yn: qual,
    qual_desc_ctnt: b.qual_desc_ctnt || null,
    note_ctnt: b.note_ctnt || null,
    verified_dtm: b.verified_dtm || null,
    expires_dtm: b.expires_dtm || null,
    badge_src_cd: b.badge_src_cd || null,
    badge_src_url_ctnt: b.badge_src_url_ctnt || null,
    // 🚨 출처 계보(2026-07-31). 이 한 줄이 없어서 **비교 리포트의 배지 계보가 죽어 있었다**:
    // report.js 는 edit_origin 을 제대로 읽는데, 여기 화이트리스트에 없어 REF → matched →
    // benS 로 내려가는 길에 필드가 사라졌다(항상 '공식'/'추정'). 서버에서 겪은 함정 (55)
    // (Pydantic 이 모르는 필드를 조용히 떨군다)와 **같은 실패가 클라이언트에서 반복**됐다.
    // 테스트는 renderBands 에 값을 직접 주입해 이 구간을 건너뛰어 전부 초록이었다(함정 (54)).
    // → inputs.test.js 가 "REF 가 주는 필드는 정규화를 통과한다"를 모델 파일에서 읽어 강제한다.
    edit_origin: b.edit_origin || 'seed',
    // 런타임 전용(FR-D8.1) — fill 단계에서 부여
    checked: undefined,
    value_source: undefined, // 프로버넌스: real|preset|user
  };
}

// ── SP-FE-8.3 fillBenefits·initWsState·clearSlot ────────────────────────────
// state = App.state(호출부 주입). 회사/프리셋/빈 3분기(FR-21·FR-06).
export function fillBenefits(state, slot) {
  if (state.matched[slot]) {
    // 회사 지정(UC-14): 실데이터, 전부 체크·real
    state.benS[slot] = state.matched[slot].benefits.map((b) => ({ ...b, checked: true, value_source: 'real' }));
  } else if (state.chosenType[slot]) {
    // 직접입력+유형(UC-15): 프리셋 복사(FR-06)
    const presets = (state.REF && state.REF.benefit_presets && state.REF.benefit_presets[state.chosenType[slot]]) || [];
    state.benS[slot] = presets.map((p) => ({
      ...normalizeBenefit(p),
      checked: !!p.default_checked_yn, // 초기 체크 = DEFAULT_CHECKED_YN
      value_source: 'preset',
    }));
  } else {
    state.benS[slot] = []; // 빈 상태(사용자 직접 추가)
  }
}

function proposeRemote(remote) { return remote; }
function proposeFlex(flex) { return flex; }

// 회사 지정 시 work_style_val로 근무형태 제안(FR-23). 야근·임금유형은 사용자 입력(미선택).
export function initWsState(state, slot) {
  const matched = state.matched[slot];
  const ws = matched && matched.work_style_val;
  state.wsState[slot] = {
    ot: null,
    wage: null,
    remote: ws && ws.remote ? proposeRemote(ws.remote) : null,
    flex: ws && ws.flex ? proposeFlex(ws.flex) : null,
  };
}

export function blankWs() { return { ot: null, wage: null, remote: null, flex: null }; }

// 슬롯 해제(FR-15) — 초기값 복귀.
export function clearSlot(state, slot, reflectSlotLabel) {
  bumpSlot(state, slot); // 받는 중이던 이 슬롯의 선택 응답은 낡았다
  state.matched[slot] = null;
  state.benS[slot] = [];
  state.wsState[slot] = blankWs();
  state.chosenType[slot] = null;
  state.inputMode[slot] = 'company';
  if (typeof reflectSlotLabel === 'function') reflectSlotLabel(slot, '');
}

// ── SP-FE-8.1 selectCompany·sameCompanyGuard(FR-14·15·16, FR-D7·D11) ───────
// notify/reflectSlotLabel/closeCandidates/maybeAdvance는 호출부(search.js/app.js)가 주입하는 선택적 콜백.
export function sameCompanyGuard(state, slot, compId, notify) {
  const other = slot === 'a' ? 'b' : 'a';
  if (state.matched[other] && state.matched[other].comp_id === compId) {
    if (typeof notify === 'function') notify('두 직장은 서로 다른 회사여야 합니다. 다른 회사를 선택하세요.');
    return true; // 반영 보류(상태 미변경)
  }
  return false;
}

export async function selectCompany(state, slot, compId, hooks = {}) {
  const { notify, reflectSlotLabel, closeCandidates, maybeAdvance, showSlotError, getCompanyFn = getReferenceCompany } = hooks;
  bumpSlot(state, slot); // 이 호출을 이 슬롯의 최신으로 등록(연타 폴백 방어, #9)
  const snap = seqSnapshot(state); // 받는 동안 이 슬롯이나 쌍이 다시 바뀌면 응답을 버린다(검토 M1)
  let raw = (state.REF && state.REF.companies || []).find((c) => c.comp_id === compId); // REF 인라인 우선(호출 0)
  if (!raw || !hasDetail(raw)) { // 가벼운 목록(복지 행 없음)이거나 REF 밖 → 상세 API(FR-D7). 같은 회사 동시 요청은 하나로 합쳐진다
    try {
      raw = await loadDetail(state, compId, getCompanyFn); // 받으면 REF 의 그 객체에 합쳐진다
    } catch {
      if (!seqCurrent(state, snap, [slot])) return false; // 이미 낡은 호출의 실패는 말하지 않는다
      // 세 번째 인자 = 어느 회사였는지 — 슬롯이 「<회사명> 정보를 불러오지 못했습니다」 + 그 회사 다시 받기를 보여 준다
      if (typeof showSlotError === 'function') showSlotError(slot, '회사 정보를 불러올 수 없습니다.', { compId, compNm: raw ? raw.comp_nm : '' });
      return false; // FR-D11: 미선택 유지
    }
    if (!seqCurrent(state, snap, [slot])) return false; // 더 최신 선택이 진행됨 → 늦은 응답 폐기(#9)
  }
  if (sameCompanyGuard(state, slot, compId, notify)) return false; // 양 슬롯 동일 회사 방지(FR-15)

  state.matched[slot] = normalizeCompany(raw); // 정규화(FR-D8.2)
  state.inputMode[slot] = 'company';
  state.chosenType[slot] = null;
  fillBenefits(state, slot); // benS 초기화(FR-21)
  initWsState(state, slot); // wsState 초기화(FR-23)
  if (typeof reflectSlotLabel === 'function') reflectSlotLabel(slot, state.matched[slot].comp_nm);
  if (typeof closeCandidates === 'function') closeCandidates(slot);
  if (typeof maybeAdvance === 'function') maybeAdvance();
  return true;
}

// ── T-06.8.5 setDirectType — 직접입력 모드 유형 선택(FR-17) ─────────────────
export function setDirectType(state, slot, compTpCd) {
  bumpSlot(state, slot);
  state.inputMode[slot] = 'direct';
  state.matched[slot] = null; // 회사와 상태 구분(N-4)
  state.chosenType[slot] = compTpCd;
  fillBenefits(state, slot); // 프리셋 채움
  initWsState(state, slot); // matched null→ws 미제안
}
