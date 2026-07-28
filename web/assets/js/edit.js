// web/assets/js/edit.js — SC14 복지 편집 폼(SP-FE, FR-108·109). 재직 인증한 회사의 복지를
// 등록·수정한다. 세션+재직 게이트(미보유 시 로그인/인증 유도). 배지는 서버가 'verified'로
// 강제하므로 사용자가 지정하지 않는다(표시만). base_dtm(낙관동시성 토큰)·benefit_id 는 편집용
// 조회로 부트스트랩하고, 선점 수정(409)은 최신 행으로 폼을 갱신해 재조정을 유도한다.
// 모든 사용자/회사 데이터는 textContent 로만 삽입한다(XSS 안전). api.js 헬퍼만 쓴다.

import {
  getMe, getBenefitsForEdit, createBenefit, updateBenefit, ApiError,
} from './api.js';

// 9카테고리 표시 라벨 — company.js·report.js CATEGORY_LABEL과 동일 어휘(화면 간 용어 일관성).
export const CATEGORY_LABELS = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};
export const CATEGORY_ORDER = Object.keys(CATEGORY_LABELS);
// 백엔드 BenefitCreateIn._BENEFIT_CD_RE 와 동일(소문자·숫자·_ 2~30자, 첫 글자 소문자).
const BENEFIT_CD_RE = /^[a-z][a-z0-9_]{1,29}$/;

// ── 순수: 금액 파싱 — 빈칸/비숫자 → null(=금액 미기재, 서버는 amt_source=none 처리) ──
export function parseAmount(v) {
  if (v === undefined || v === null) return null;
  const s = String(v).trim();
  if (s === '' || !/^\d+$/.test(s)) return null;
  return parseInt(s, 10);
}

// ── 순수: 제출 전 클라 검증(서버가 최종 판정 422·409) — 오류 메시지 or null ──
export function validateForm(mode, f) {
  const name = (f.benefit_nm || '').trim();
  if (!name) return '복지 이름을 입력해주세요.';
  if (name.length > 100) return '복지 이름은 100자 이내로 입력해주세요.';
  if (mode === 'create') {
    const cd = (f.benefit_cd || '').trim().toLowerCase();
    if (!BENEFIT_CD_RE.test(cd)) return '복지 코드는 소문자·숫자·_ 2~30자, 첫 글자는 소문자여야 해요(예: meal, welfare_point).';
    if (!CATEGORY_LABELS[f.benefit_ctgr_cd]) return '카테고리를 선택해주세요.';
  }
  const qual = !!f.qual;
  if (!qual) {
    const raw = String(f.benefit_amt == null ? '' : f.benefit_amt).trim();
    if (raw !== '' && parseAmount(raw) === null) return '금액은 0 이상의 숫자(만원)로 입력해주세요.';
  }
  if ((f.note_ctnt || '').length > 200) return '비고는 200자 이내로 입력해주세요.';
  if ((f.edit_note || '').length > 500) return '편집 사유는 500자 이내로 입력해주세요.';
  return null;
}

// ── 순수: 요청 본문 조립. 등록=코드·카테고리 포함, 수정=base_dtm 포함(코드·카테고리 불변) ──
// 정성(qual)이면 금액 필드 자체를 보내지 않아 서버가 amt=null·amt_source=none 으로 강제한다.
export function buildPayload(mode, f) {
  const qual = !!f.qual;
  const body = { benefit_nm: (f.benefit_nm || '').trim(), qual_yn: qual };
  if (!qual) {
    const amt = parseAmount(f.benefit_amt);
    if (amt !== null) body.benefit_amt = amt; // 미기재는 키 생략(none)
  }
  const note = (f.note_ctnt || '').trim();
  if (note) body.note_ctnt = note;
  const editNote = (f.edit_note || '').trim();
  if (editNote) body.edit_note = editNote;
  if (mode === 'create') {
    body.benefit_cd = (f.benefit_cd || '').trim().toLowerCase();
    body.benefit_ctgr_cd = f.benefit_ctgr_cd;
  } else {
    body.base_dtm = f.base_dtm;
  }
  return body;
}

// ── 순수: 복지 1건의 금액 표시 문자열 ──
export function fmtAmount(b) {
  if (b && b.qual_yn) return '정성';
  if (!b || b.benefit_amt == null) return '금액 미기재';
  return b.benefit_amt.toLocaleString('ko-KR') + '만원';
}

// ── 순수: 상태코드 → 친절 메시지. 서버는 원문(코드/금액)을 반향하지 않는다(NFR31). ──
export function benefitErrorMessage(err, mode) {
  const s = err instanceof ApiError ? err.status : 0;
  if (s === 401) return '__login__'; // 세션 만료 → 로그인 이동 신호
  if (s === 403) return '이 회사의 재직 인증이 없거나 만료됐어요. 재직 인증을 먼저 해주세요.';
  if (s === 409) {
    return mode === 'create'
      ? '이미 등록된 복지 코드예요. 다른 코드를 쓰거나 기존 항목을 수정해주세요.'
      : '__conflict__'; // 선점 수정 — 호출부가 현재 행으로 폼 갱신
  }
  if (s === 429) return '오늘 이 회사에 남길 수 있는 편집 수를 초과했어요. 내일 다시 시도해주세요.';
  if (s === 422) return '입력값을 확인해주세요(정성 복지는 금액을 가질 수 없어요).';
  if (s === 404) return '복지 항목을 찾을 수 없어요. 목록을 새로고침해주세요.';
  return '저장에 실패했어요. 잠시 후 다시 시도해주세요.';
}

// ── 순수: 재직 회사 선택 결정 — ?comp 매칭 우선, 없으면 1곳 자동 / 여러 곳 select ──
// 반환 {mode:'single'|'multi', company}. single=자동 선택 회사(match 또는 유일), multi=사용자 선택 필요(null).
export function pickCompany(verifications, compParamId) {
  const list = verifications || [];
  const match = compParamId ? list.find((v) => v.comp_id === compParamId) : null;
  if (match) return { mode: 'single', company: match };
  if (list.length === 1) return { mode: 'single', company: list[0] };
  return { mode: 'multi', company: null };
}

// ── 이하 DOM 배선(브라우저 전용) — 편집 폼 루트가 있을 때만 초기화(테스트 import 안전) ──
export function initEditPage() {
  const $ = (id) => document.getElementById(id);
  const state = { comp_id: null, comp_nm: '', benefits: new Map(), mode: 'create', editingId: null };

  const compParam = () => {
    const m = /[?&]comp=(\d+)/.exec(location.search);
    return m ? parseInt(m[1], 10) : null;
  };

  function setErr(msg) { const e = $('form-err'); e.textContent = msg; e.hidden = !msg; }
  function setOk(msg) { const e = $('edit-ok'); e.textContent = msg; e.hidden = !msg; }
  async function withBusy(btn, label, fn) {
    const orig = btn.textContent; btn.disabled = true; btn.textContent = label;
    try { return await fn(); } finally { btn.disabled = false; btn.textContent = orig; }
  }

  // 카테고리 select 채우기(등록용)
  function fillCategories() {
    const sel = $('f-ctgr'); sel.textContent = '';
    const ph = document.createElement('option');
    ph.value = ''; ph.textContent = '카테고리 선택'; ph.disabled = true; ph.selected = true;
    sel.append(ph);
    for (const cd of CATEGORY_ORDER) {
      const o = document.createElement('option'); o.value = cd; o.textContent = CATEGORY_LABELS[cd]; sel.append(o);
    }
  }

  // 재직 회사 선택 UI 구성. 1곳이면 자동 선택, 여러 곳이면 select.
  function setupCompanyPicker(verifications) {
    const sel = $('comp-select'), single = $('comp-single');
    const { mode, company } = pickCompany(verifications, compParam());
    if (mode === 'single') {
      single.textContent = company.comp_nm || ('회사 ' + company.comp_id);
      single.hidden = false; sel.hidden = true;
      selectCompany(company.comp_id, company.comp_nm);
    } else {
      sel.textContent = '';
      const ph = document.createElement('option');
      ph.value = ''; ph.textContent = '재직 인증한 회사 선택'; ph.disabled = true; ph.selected = true;
      sel.append(ph);
      for (const v of verifications) {
        const o = document.createElement('option');
        o.value = String(v.comp_id); o.textContent = v.comp_nm || ('회사 ' + v.comp_id); sel.append(o);
      }
      sel.hidden = false; single.hidden = true;
      sel.addEventListener('change', () => {
        const v = verifications.find((x) => String(x.comp_id) === sel.value);
        if (v) selectCompany(v.comp_id, v.comp_nm);
      });
    }
  }

  async function selectCompany(compId, compNm) {
    state.comp_id = compId; state.comp_nm = compNm || ('회사 ' + compId);
    closeForm();
    const link = $('history-link');
    link.href = '/edits?comp=' + encodeURIComponent(compId); link.hidden = false;
    $('list-section').hidden = false;
    await loadBenefits();
  }

  async function loadBenefits() {
    const listEl = $('benefit-list'), emptyEl = $('benefit-empty');
    listEl.textContent = ''; emptyEl.hidden = true;
    emptyEl.textContent = '아직 등록된 복지가 없어요. 첫 복지를 등록해보세요.'; // 이전 오류 문구 잔류 방지(재로드 0건)
    try {
      const { data } = await getBenefitsForEdit(state.comp_id);
      const benefits = (data && data.benefits) || [];
      state.benefits.clear();
      for (const b of benefits) state.benefits.set(b.benefit_id, b);
      renderBenefitList(listEl, benefits);
      emptyEl.hidden = benefits.length > 0;
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) { location.href = '/login'; return; }
      if (err instanceof ApiError && err.status === 403) { showNeedVerify(); return; }
      emptyEl.hidden = false; emptyEl.textContent = '복지 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  function renderBenefitList(listEl, benefits) {
    listEl.textContent = '';
    for (const b of benefits) {
      const li = document.createElement('li'); li.className = 'ben-row';
      const main = document.createElement('div'); main.className = 'ben-main';
      const nm = document.createElement('span'); nm.className = 'ben-nm'; nm.textContent = b.benefit_nm; // XSS 안전
      const meta = document.createElement('span'); meta.className = 'ben-meta';
      meta.textContent = (CATEGORY_LABELS[b.benefit_ctgr_cd] || b.benefit_ctgr_cd) + ' · ' + fmtAmount(b);
      main.append(nm, meta);
      const badge = document.createElement('span'); badge.className = 'ben-badge'; badge.textContent = '✓ 재직자 확인';
      const btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'auth-link'; btn.textContent = '수정';
      btn.addEventListener('click', () => openForm('update', b));
      li.append(main, badge, btn);
      listEl.append(li);
    }
  }

  // 등록/수정 폼 열기. update=기존 값 프리필·코드/카테고리 고정, create=빈 폼.
  function openForm(mode, benefit) {
    state.mode = mode; state.editingId = mode === 'update' ? benefit.benefit_id : null;
    setErr(''); setOk(''); $('conflict-note').hidden = true;
    $('form-title').textContent = mode === 'create' ? '새 복지 등록' : '복지 수정';
    $('form-submit').textContent = mode === 'create' ? '등록' : '수정 저장';
    const isCreate = mode === 'create';
    $('f-code-wrap').hidden = !isCreate;
    $('f-ctgr-wrap').hidden = !isCreate;
    $('f-ctgr-fixed-wrap').hidden = isCreate;
    if (isCreate) {
      $('f-code').value = ''; $('f-ctgr').value = ''; $('f-name').value = '';
      $('f-amt').value = ''; $('f-qual').checked = false; $('f-note').value = ''; $('f-editnote').value = '';
    } else {
      $('f-name').value = benefit.benefit_nm || '';
      $('f-ctgr-fixed').textContent = CATEGORY_LABELS[benefit.benefit_ctgr_cd] || benefit.benefit_ctgr_cd;
      $('f-code-fixed').textContent = benefit.benefit_cd;
      $('f-qual').checked = !!benefit.qual_yn;
      $('f-amt').value = benefit.qual_yn || benefit.benefit_amt == null ? '' : String(benefit.benefit_amt);
      $('f-note').value = benefit.note_ctnt || '';
      $('f-editnote').value = '';
    }
    syncQual();
    $('benefit-form').hidden = false;
    $('new-benefit').hidden = true;
    $('f-name').focus();
  }

  function closeForm() {
    $('benefit-form').hidden = true; $('new-benefit').hidden = false;
    state.mode = 'create'; state.editingId = null; setErr('');
  }

  // 정성 체크 시 금액칸 비활성(상호배타 — 서버도 422로 강제).
  function syncQual() {
    const qual = $('f-qual').checked;
    const amt = $('f-amt');
    amt.disabled = qual; if (qual) amt.value = '';
    $('f-amt-wrap').classList.toggle('is-disabled', qual);
  }

  function readForm() {
    return {
      benefit_cd: $('f-code').value, benefit_nm: $('f-name').value,
      benefit_ctgr_cd: $('f-ctgr').value, benefit_amt: $('f-amt').value,
      qual: $('f-qual').checked, note_ctnt: $('f-note').value, edit_note: $('f-editnote').value,
      base_dtm: state.editingId ? (state.benefits.get(state.editingId) || {}).base_dtm : undefined,
    };
  }

  async function submitForm() {
    setErr(''); setOk(''); $('conflict-note').hidden = true;
    const f = readForm();
    const invalid = validateForm(state.mode, f);
    if (invalid) { setErr(invalid); return; }
    const body = buildPayload(state.mode, f);
    try {
      if (state.mode === 'create') {
        await withBusy($('form-submit'), '등록 중…', () => createBenefit(state.comp_id, body));
        setOk('새 복지를 등록했어요.');
      } else {
        await withBusy($('form-submit'), '저장 중…', () => updateBenefit(state.comp_id, state.editingId, body));
        setOk('복지를 수정했어요.');
      }
      closeForm();
      await loadBenefits();
    } catch (err) {
      const msg = benefitErrorMessage(err, state.mode);
      if (msg === '__login__') { location.href = '/login'; return; }
      if (msg === '__conflict__') { await handleConflict(err); return; }
      setErr(msg);
    }
  }

  // 선점 수정(409): 서버가 current_benefit(새 base_dtm)·benefits 동봉 → 폼·목록을 최신으로 갱신.
  async function handleConflict(err) {
    const cur = err.data && err.data.current_benefit;
    if (cur) {
      state.benefits.set(cur.benefit_id, cur);
      // 폼을 최신 서버 값으로 갱신(사용자 입력은 유지하지 않고 최신 확인 후 재편집 유도).
      openForm('update', cur);
    }
    if (err.data && Array.isArray(err.data.benefits)) {
      for (const b of err.data.benefits) state.benefits.set(b.benefit_id, b);
      renderBenefitList($('benefit-list'), err.data.benefits);
    }
    $('conflict-note').hidden = false;
    $('conflict-note').textContent = '다른 사람이 먼저 이 복지를 수정했어요. 최신 내용으로 갱신했어요 — 확인 후 다시 저장해주세요.';
  }

  function showNeedVerify() {
    for (const id of ['edit-card']) $(id).hidden = true;
    $('need-verify').hidden = false;
  }

  // 배선
  $('f-qual').addEventListener('change', syncQual);
  $('new-benefit').addEventListener('click', () => openForm('create'));
  $('form-cancel').addEventListener('click', closeForm);
  $('benefit-form').addEventListener('submit', (e) => { e.preventDefault(); submitForm(); });
  fillCategories();

  // 진입: 세션·재직 확인
  (async () => {
    try {
      const { data } = await getMe();
      const vrf = (data && data.verifications) || [];
      if (!vrf.length) { $('need-verify').hidden = false; return; }
      $('edit-card').hidden = false;
      setupCompanyPicker(vrf);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) { $('need-login').hidden = false; return; }
      $('need-login').hidden = false;
    }
  })();
}

// 브라우저에서 편집 폼 루트가 있을 때만 초기화(node:test 로 순수 함수만 import 시 부작용 없음).
if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('edit-card')) {
  initEditPage();
}
