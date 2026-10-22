// web/assets/js/edit.js — SC14 복지 편집 폼(SP-FE, FR-108·109). 재직 인증한 회사의 복지 등록·수정을
// **요청**한다(2026-10-21: 바로 반영되지 않고 운영자가 확인한 뒤 반영 — 서버가 202 로 답한다).
// 세션+재직 게이트(미보유 시 로그인/인증 유도). 배지는 서버가 'verified'로 강제하므로 사용자가 지정하지
// 않는다(표시만). 새 항목은 영문 코드를 직접 치지 않고 표준 항목 목록(GET /benefit-codes)에서 이름·별칭으로
// 검색해 고른다 — 목록에 없으면 이름만 적어 보낸다(운영자가 승인 때 항목을 고른다). base_dtm(낙관동시성
// 토큰)·benefit_id 는 편집용 조회로 부트스트랩하고, 선점 수정(409)은 최신 행으로 폼을 갱신해 재조정을 유도한다.
// 모든 사용자/회사 데이터는 textContent 로만 삽입한다(XSS 안전). api.js 헬퍼만 쓴다.

import {
  getMe, getBenefitsForEdit, getBenefitCodes, createBenefit, updateBenefit, ApiError,
} from './api.js';

// 9카테고리 표시 라벨 — company.js·report.js CATEGORY_LABEL과 동일 어휘(화면 간 용어 일관성).
export const CATEGORY_LABELS = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};
export const CATEGORY_ORDER = Object.keys(CATEGORY_LABELS);

// 후보 목록 상한 — 폰 화면에서 한 번에 훑을 만큼.
export const CODE_RESULT_LIMIT = 12;

// ── 순수: 금액 파싱 — 빈칸/비숫자 → null(=금액 미기재, 서버는 amt_source=none 처리) ──
export function parseAmount(v) {
  if (v === undefined || v === null) return null;
  const s = String(v).trim();
  if (s === '' || !/^\d+$/.test(s)) return null;
  return parseInt(s, 10);
}

// ── 순수: 제출 전 클라 검증(서버가 최종 판정 422·409) — 오류 메시지 or null ──
// 새 항목은 표준 항목을 골랐거나(benefit_cd) 「찾는 항목이 없어요」를 눌렀어야(no_code) 한다.
export function validateForm(mode, f) {
  const name = (f.benefit_nm || '').trim();
  if (mode === 'create' && !(f.benefit_cd || '').trim() && !f.no_code) {
    return '어떤 복지인지 목록에서 골라주세요. 없으면 「찾는 항목이 없어요」를 눌러주세요.';
  }
  if (!name) return '회사에서 부르는 이름을 입력해주세요.';
  if (name.length > 100) return '이름은 100자 이내로 입력해주세요.';
  const qual = !!f.qual;
  if (!qual) {
    const raw = String(f.benefit_amt == null ? '' : f.benefit_amt).trim();
    if (raw !== '' && parseAmount(raw) === null) return '금액은 0 이상의 숫자(만원)로 입력해주세요.';
  }
  if ((f.note_ctnt || '').length > 200) return '비고는 200자 이내로 입력해주세요.';
  if ((f.edit_note || '').length > 500) return '편집 사유는 500자 이내로 입력해주세요.';
  return null;
}

// ── 순수: 요청 본문 조립. 등록=고른 항목 코드(없으면 키 생략 = 「목록에 없음」), 수정=base_dtm 포함 ──
// 카테고리는 보내지 않는다(승인 때 항목 코드에서 정해진다). 정성(qual)이면 금액 필드 자체를 보내지 않아
// 서버가 amt=null·amt_source=none 으로 강제한다.
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
    const cd = (f.benefit_cd || '').trim().toLowerCase();
    if (cd) body.benefit_cd = cd; // 코드 없는 요청 = 목록에 없음
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

// ── 순수: 제출 성공 문구 — 반영 시점을 약속하지 않는다(운영자가 확인하는 시간은 정해져 있지 않다) ──
export function requestSentMessage(mode) {
  return mode === 'create'
    ? '확인 요청을 보냈어요. 운영자가 확인하면 사이트에 반영돼요.'
    : '수정 요청을 보냈어요. 운영자가 확인하면 반영돼요.';
}

// ── 순수: 상태코드 → 친절 메시지. 서버는 원문(코드/금액)을 반향하지 않는다(NFR31). ──
// 409 는 두 가지다: 같은 대상에 이미 확인 대기 중인 요청(서버 문구에 「대기」) / 그 회사에 이미 있는 항목(등록) /
// 선점 수정(수정, 현재 행 동봉 → '__conflict__').
export function benefitErrorMessage(err, mode) {
  const s = err instanceof ApiError ? err.status : 0;
  if (s === 401) return '__login__'; // 세션 만료 → 로그인 이동 신호
  if (s === 403) return '이 회사의 재직 인증이 없거나 만료됐어요. 재직 인증을 먼저 해주세요.';
  if (s === 409) {
    const detail = err && err.data && typeof err.data.detail === 'string' ? err.data.detail : '';
    if (detail.includes('대기')) return '이미 확인 대기 중인 요청이 있어요. 운영자가 확인할 때까지 기다려주세요.';
    return mode === 'create'
      ? '이미 이 회사에 있는 항목이에요. 목록에서 그 항목의 수정을 요청해주세요.'
      : '__conflict__'; // 선점 수정 — 호출부가 현재 행으로 폼 갱신
  }
  if (s === 429) return '오늘 이 회사에 보낼 수 있는 요청 수를 초과했어요. 내일 다시 시도해주세요.';
  if (s === 422) return '입력값을 확인해주세요(정성 복지는 금액을 가질 수 없어요).';
  if (s === 404) return '복지 항목을 찾을 수 없어요. 목록을 새로고침해주세요.';
  return '요청을 보내지 못했어요. 잠시 후 다시 시도해주세요.';
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

// ── 순수: `?benefit=<코드>` 로 지목된 복지 고르기 ────────────────────────────
// 회사 페이지 복지 원장의 각 행이 `/edit?comp=&benefit=` 로 **그 항목을 지목**해 보낸다
// (SP-GEN-5.6). 코드는 회사 안에서 UNIQUE 라 하나만 맞는다. 없으면 null — 목록만 보여 준다
// (남의 회사 코드·오타·삭제된 항목 어느 쪽이든 화면이 죽지 않는다).
// 새 항목을 고른 코드가 이 회사에 이미 있는지 볼 때도 같은 함수를 쓴다(→ 「그 항목 수정 요청하기」).
export function pickBenefit(benefits, cd) {
  const want = String(cd || '').trim().toLowerCase();
  if (!want) return null;
  return (benefits || []).find((b) => String(b.benefit_cd || '').toLowerCase() === want) || null;
}

// ── 순수: 표준 항목 검색 — 이름(label)·별칭(aliases)에서 찾는다(영문 코드는 보지 않는다) ──
// 공백은 무시하고 대소문자를 가리지 않는다. 정렬: 이름이 검색어로 시작 > 이름에 포함 > 별칭에만 포함, 같은 등급은
// 원래 순서(카테고리 순). 빈 검색어는 후보 없음.
export function filterCodes(codes, query, limit = CODE_RESULT_LIMIT) {
  const norm = (v) => String(v || '').toLowerCase().replace(/\s+/g, '');
  const q = norm(query);
  if (!q) return [];
  const scored = [];
  (codes || []).forEach((c, i) => {
    const label = norm(c.label);
    let rank = -1;
    if (label.startsWith(q)) rank = 0;
    else if (label.includes(q)) rank = 1;
    else if ((c.aliases || []).some((a) => norm(a).includes(q))) rank = 2;
    if (rank >= 0) scored.push({ rank, i, c });
  });
  scored.sort((x, y) => x.rank - y.rank || x.i - y.i);
  return scored.slice(0, limit).map((x) => x.c);
}

// ── 순수: 내 요청 한 줄의 표시 — 확인 대기 / 반영됨 / 반영 안 됨(사유) ──
export function requestStatusView(req) {
  const kind = req && req.type === 'update' ? '수정' : '등록';
  const st = req && req.status;
  if (st === 'approved') return { kind, label: '반영됨', cls: 'approved', note: '' };
  if (st === 'rejected') {
    const why = req.decide_note ? String(req.decide_note) : '';
    return { kind, label: '반영 안 됨', cls: 'rejected', note: why ? '사유: ' + why : '' };
  }
  return { kind, label: '확인 대기', cls: 'pending', note: '' };
}

// ── 순수: 확인 대기 중인 수정이 있는 복지 id 집합 — 목록에 「수정 확인 대기」를 달 때 쓴다 ──
export function pendingUpdateIds(requests) {
  const ids = new Set();
  for (const r of requests || []) {
    if (r && r.type === 'update' && r.status === 'pending' && r.benefit_id != null) ids.add(r.benefit_id);
  }
  return ids;
}

// ── 이하 DOM 배선(브라우저 전용) — 편집 폼 루트가 있을 때만 초기화(테스트 import 안전) ──
export function initEditPage() {
  const $ = (id) => document.getElementById(id);
  const state = {
    comp_id: null, comp_nm: '', benefits: new Map(), requests: [], mode: 'create', editingId: null,
    prefillDone: false,
    codes: null, codesFailed: false,   // 표준 항목 목록(처음 새 항목 폼을 열 때 한 번 받는다)
    picked: null, noCode: false,       // 새 항목: 고른 표준 항목 / 「찾는 항목이 없어요」 선택
    autoName: '',                      // 항목을 고를 때 채워 준 이름 — 사용자가 고치면 덮어쓰지 않는다
  };

  const compParam = () => {
    const m = /[?&]comp=(\d+)/.exec(location.search);
    return m ? parseInt(m[1], 10) : null;
  };
  // 회사 페이지 원장이 지목해 보낸 복지 코드. 소문자·숫자·_- 만 받는다(주소창 잡음 차단).
  const benefitParam = () => {
    const m = /[?&]benefit=([A-Za-z0-9_-]{1,30})/.exec(location.search);
    return m ? m[1] : null;
  };

  function setErr(msg) { const e = $('form-err'); e.textContent = msg; e.hidden = !msg; }
  function setOk(msg) { const e = $('edit-ok'); e.textContent = msg; e.hidden = !msg; }
  async function withBusy(btn, label, fn) {
    const orig = btn.textContent; btn.disabled = true; btn.textContent = label;
    try { return await fn(); } finally { btn.disabled = false; btn.textContent = orig; }
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
      state.requests = (data && data.requests) || [];
      state.benefits.clear();
      for (const b of benefits) state.benefits.set(b.benefit_id, b);
      renderBenefitList(listEl, benefits);
      renderRequests($('req-list'), state.requests);
      emptyEl.hidden = benefits.length > 0;
      // 지목된 항목이 있으면 그 수정 폼을 **첫 로드에 한 번만** 연다. 저장 후 재로드에서도 열면
      // 방금 닫은 폼이 되살아난다(사용자가 끝냈다고 말한 것을 되돌리는 셈이다).
      // ⚠ `?comp` 이 **지금 선택된 회사와 같을 때만** 연다. 다르면(내 인증 회사가 하나뿐이라
      // 폴백된 경우 등) 남의 회사 링크가 내 회사의 같은 코드 항목 수정 폼을 열어 버린다 —
      // `meal`·`health_check` 처럼 거의 모든 회사가 쓰는 코드라 오작동이 상시 발생한다.
      if (!state.prefillDone) {
        state.prefillDone = true;
        if (compParam() === state.comp_id) {
          const target = pickBenefit(benefits, benefitParam());
          if (target) openForm('update', target);
        }
      }
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) { location.href = '/login'; return; }
      if (err instanceof ApiError && err.status === 403) { showNeedVerify(); return; }
      emptyEl.hidden = false; emptyEl.textContent = '복지 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  function renderBenefitList(listEl, benefits) {
    listEl.textContent = '';
    const waiting = pendingUpdateIds(state.requests);
    for (const b of benefits) {
      const li = document.createElement('li'); li.className = 'ben-row';
      const main = document.createElement('div'); main.className = 'ben-main';
      const nm = document.createElement('span'); nm.className = 'ben-nm'; nm.textContent = b.benefit_nm; // XSS 안전
      const meta = document.createElement('span'); meta.className = 'ben-meta';
      meta.textContent = (CATEGORY_LABELS[b.benefit_ctgr_cd] || b.benefit_ctgr_cd) + ' · ' + fmtAmount(b);
      main.append(nm, meta);
      const badge = document.createElement('span'); badge.className = 'ben-badge';
      badge.textContent = waiting.has(b.benefit_id) ? '수정 확인 대기' : '✓ 재직자 확인';
      if (waiting.has(b.benefit_id)) badge.classList.add('ben-badge--wait');
      const btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'auth-link'; btn.textContent = '수정 요청';
      btn.addEventListener('click', () => openForm('update', b));
      li.append(main, badge, btn);
      listEl.append(li);
    }
  }

  // 내 요청: 확인 대기 / 반영됨 / 반영 안 됨(사유). 요청이 없으면 절 자체를 숨긴다.
  function renderRequests(listEl, requests) {
    listEl.textContent = '';
    $('req-section').hidden = !requests.length;
    for (const r of requests) {
      const v = requestStatusView(r);
      const li = document.createElement('li'); li.className = 'ben-row';
      const main = document.createElement('div'); main.className = 'ben-main';
      const nm = document.createElement('span'); nm.className = 'ben-nm'; nm.textContent = r.benefit_nm; // XSS 안전
      const meta = document.createElement('span'); meta.className = 'ben-meta';
      meta.textContent = v.kind + ' 요청' + (v.note ? ' · ' + v.note : '');   // 사유는 운영자 입력 — textContent
      main.append(nm, meta);
      const badge = document.createElement('span'); badge.className = 'ben-badge ben-badge--' + v.cls;
      badge.textContent = v.label;
      li.append(main, badge);
      listEl.append(li);
    }
  }

  // ── 새 항목: 표준 항목 검색 고르기 ──────────────────────────────────────────────
  async function ensureCodes() {
    if (state.codes || state.codesFailed) return;
    try {
      const data = await getBenefitCodes();
      state.codes = (data && data.codes) || [];
    } catch {
      state.codesFailed = true;
      $('code-hint').textContent = '항목 목록을 불러오지 못했어요. 아래 「찾는 항목이 없어요」로 이름만 적어 보낼 수 있어요.';
    }
  }

  function renderCodeResults() {
    const results = $('code-results'), search = $('f-search');
    results.textContent = '';
    const found = state.picked || state.noCode ? [] : filterCodes(state.codes, search.value);
    for (const c of found) {
      const li = document.createElement('li'); li.tabIndex = 0; li.setAttribute('role', 'option');
      li.textContent = c.label;                                   // XSS 안전
      const ind = document.createElement('span'); ind.className = 'ind';
      ind.textContent = CATEGORY_LABELS[c.ctgr] || c.ctgr;
      li.append(ind);
      const go = () => pickCode(c);
      li.addEventListener('click', go);
      li.addEventListener('keydown', (e) => { if (e.key === 'Enter') go(); });
      results.append(li);
    }
    results.hidden = !found.length;
    search.setAttribute('aria-expanded', String(!!found.length));
    const q = search.value.trim();
    if (!state.codesFailed && !state.picked && !state.noCode) {
      $('code-hint').textContent = !q ? '이름을 입력하면 후보가 나와요. 맞는 항목을 눌러 고르세요.'
        : (found.length ? '맞는 항목을 눌러 고르세요.' : '맞는 항목이 없어요. 다른 낱말로 찾거나 아래 「찾는 항목이 없어요」를 눌러주세요.');
    }
  }

  // 항목을 고른다 — 이름 칸에 대표 이름을 채워 주되(고칠 수 있다), 그 회사에 이미 있는 항목이면 수정으로 안내한다.
  function pickCode(c) {
    state.picked = c; state.noCode = false;
    $('f-search').value = '';
    $('code-picked-label').textContent = c.label;
    $('code-picked').hidden = false;
    const nameEl = $('f-name');
    if (!nameEl.value.trim() || nameEl.value === state.autoName) { nameEl.value = c.label; state.autoName = c.label; }
    const exists = pickBenefit([...state.benefits.values()], c.code);
    $('code-exists').hidden = !exists;
    $('form-submit').disabled = !!exists;
    $('code-none').hidden = true;
    $('code-hint').textContent = '';
    renderCodeResults();
  }

  function clearPick() {
    state.picked = null; state.noCode = false;
    $('code-picked').hidden = true; $('code-exists').hidden = true; $('code-none').hidden = false;
    $('form-submit').disabled = false;
    $('f-search').disabled = false;
    renderCodeResults();
    $('f-search').focus();
  }

  function pickNone() {
    state.picked = null; state.noCode = true;
    $('f-search').value = '';
    $('code-picked-label').textContent = '목록에 없는 항목 — 이름만 보내요. 운영자가 맞는 항목을 골라 반영해요.';
    $('code-picked').hidden = false; $('code-exists').hidden = true; $('code-none').hidden = true;
    $('code-hint').textContent = '';
    renderCodeResults();
    $('f-name').focus();
  }

  // 등록/수정 폼 열기. update=기존 값 프리필·항목 고정, create=빈 폼 + 항목 검색.
  function openForm(mode, benefit) {
    state.mode = mode; state.editingId = mode === 'update' ? benefit.benefit_id : null;
    setErr(''); setOk(''); $('conflict-note').hidden = true;
    $('form-title').textContent = mode === 'create' ? '새 복지 등록 요청' : '복지 수정 요청';
    $('form-submit').textContent = mode === 'create' ? '등록 요청 보내기' : '수정 요청 보내기';
    $('form-submit').disabled = false;
    const isCreate = mode === 'create';
    $('f-pick-wrap').hidden = !isCreate;
    $('f-ctgr-fixed-wrap').hidden = isCreate;
    if (isCreate) {
      state.picked = null; state.noCode = false; state.autoName = '';
      $('f-search').value = ''; $('f-name').value = '';
      $('code-picked').hidden = true; $('code-exists').hidden = true; $('code-none').hidden = false;
      $('f-amt').value = ''; $('f-qual').checked = false; $('f-note').value = ''; $('f-editnote').value = '';
      renderCodeResults();
      ensureCodes().then(renderCodeResults);
    } else {
      $('f-name').value = benefit.benefit_nm || '';
      $('f-ctgr-fixed').textContent = CATEGORY_LABELS[benefit.benefit_ctgr_cd] || benefit.benefit_ctgr_cd;
      $('f-code-fixed').textContent = benefit.benefit_nm;   // 고정 안내에는 영문 코드 대신 이름을 보인다
      $('f-qual').checked = !!benefit.qual_yn;
      $('f-amt').value = benefit.qual_yn || benefit.benefit_amt == null ? '' : String(benefit.benefit_amt);
      $('f-note').value = benefit.note_ctnt || '';
      $('f-editnote').value = '';
    }
    syncQual();
    $('benefit-form').hidden = false;
    $('new-benefit').hidden = true;
    (isCreate ? $('f-search') : $('f-name')).focus();
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
      benefit_cd: state.picked ? state.picked.code : '', no_code: state.noCode,
      benefit_nm: $('f-name').value, benefit_amt: $('f-amt').value,
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
    const sentMode = state.mode;
    try {
      if (sentMode === 'create') {
        await withBusy($('form-submit'), '보내는 중…', () => createBenefit(state.comp_id, body));
      } else {
        await withBusy($('form-submit'), '보내는 중…', () => updateBenefit(state.comp_id, state.editingId, body));
      }
      setOk(requestSentMessage(sentMode));
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
    $('conflict-note').textContent = '다른 사람이 먼저 이 복지를 수정했어요. 최신 내용으로 갱신했어요 — 확인 후 다시 요청해주세요.';
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
  $('f-search').addEventListener('input', renderCodeResults);
  $('code-clear').addEventListener('click', clearPick);
  $('code-none').addEventListener('click', pickNone);
  // 이미 있는 항목을 골랐을 때: 그 항목의 수정 요청 폼으로 옮겨 간다.
  $('code-goto-edit').addEventListener('click', () => {
    const exists = state.picked ? pickBenefit([...state.benefits.values()], state.picked.code) : null;
    if (exists) openForm('update', exists);
  });

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
