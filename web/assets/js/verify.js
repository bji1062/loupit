// web/assets/js/verify.js — SC14 재직 인증 화면 로직(SP-FE). 회사 검색·선택 → 회사 이메일
// 도메인 자동 인증(코드) → 미등록 회사는 수동 승인 요청 폴백. 세션 필요. 사용자/회사명은
// textContent로만 삽입(XSS 안전). api.js의 credentialed·GET 헬퍼만 쓴다.

import {
  getMe, searchCompanies, requestEmployCode, verifyEmployment, submitEmployRequest, ApiError,
} from './api.js';

const $ = (id) => document.getElementById(id);
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

let selected = null; // {comp_id, comp_nm}

// 코드 유효시간 카운트다운(서버 login_code_ttl_min=5분과 일치). 만료 시 재발송 유도.
const CODE_TTL_SEC = 300;
let timerId = null;
function startTimer(elId) {
  clearInterval(timerId);
  const el = $(elId); el.classList.remove('expired');
  let remain = CODE_TTL_SEC;
  const tick = () => {
    if (remain <= 0) {
      clearInterval(timerId);
      el.textContent = '코드가 만료됐어요 — ‘인증 코드 받기’를 다시 눌러주세요.';
      el.classList.add('expired');
      return;
    }
    el.textContent = `코드 유효시간 ${Math.floor(remain / 60)}:${String(remain % 60).padStart(2, '0')}`;
    remain -= 1;
  };
  tick();
  timerId = setInterval(tick, 1000);
}
function stopTimer(elId) { clearInterval(timerId); const el = $(elId); if (el) { el.textContent = ''; el.classList.remove('expired'); } }

function setErr(msg) { const e = $('verify-err'); e.textContent = msg; e.hidden = false; }
function clrMsg() { $('verify-err').hidden = true; $('verify-ok').hidden = true; }

async function withBusy(btn, label, fn) {
  const orig = btn.textContent; btn.disabled = true; btn.textContent = label;
  try { return await fn(); } finally { btn.disabled = false; btn.textContent = orig; }
}

// ── 회사 검색(디바운스 + 최신 요청만 반영) ──
let searchSeq = 0, searchTimer = null;
$('comp-search').addEventListener('input', () => {
  clearTimeout(searchTimer);
  const q = $('comp-search').value.trim();
  const results = $('comp-results');
  if (!q) { results.hidden = true; results.textContent = ''; return; }
  searchTimer = setTimeout(async () => {
    const seq = ++searchSeq;
    try {
      const rows = await searchCompanies(q);
      if (seq !== searchSeq) return; // 오래된 응답 폐기
      renderResults(rows);
    } catch { /* 검색 실패는 조용히(재입력 유도) */ }
  }, 250);
});

function renderResults(rows) {
  const ul = $('comp-results');
  ul.textContent = '';
  if (!rows || !rows.length) { ul.hidden = true; return; }
  for (const r of rows) {
    const li = document.createElement('li');
    li.tabIndex = 0;
    li.textContent = r.comp_nm; // textContent = XSS 안전
    if (r.industry_nm) {
      const ind = document.createElement('span'); ind.className = 'ind'; ind.textContent = r.industry_nm;
      li.append(ind);
    }
    const pick = () => selectCompany(r);
    li.addEventListener('click', pick);
    li.addEventListener('keydown', (e) => { if (e.key === 'Enter') pick(); });
    ul.append(li);
  }
  ul.hidden = false;
}

function selectCompany(r) {
  selected = { comp_id: r.comp_id, comp_nm: r.comp_nm };
  $('comp-name').textContent = r.comp_nm;
  $('comp-selected').hidden = false;
  $('comp-results').hidden = true;
  $('comp-search').hidden = true;
  $('email-step').hidden = false;
  $('code-step').hidden = true;
  $('manual-step').hidden = true;
  clrMsg();
  $('comp-email').focus();
}

$('comp-change').addEventListener('click', () => {
  selected = null;
  $('comp-selected').hidden = true;
  $('comp-search').hidden = false; $('comp-search').value = ''; $('comp-search').focus();
  $('email-step').hidden = true; $('code-step').hidden = true; $('manual-step').hidden = true;
  stopTimer('emp-timer');
  clrMsg();
});

// ── ② 회사 이메일 → 코드 발송(도메인 판정) ──
$('emp-send').addEventListener('click', async () => {
  clrMsg();
  const email = $('comp-email').value.trim();
  if (!EMAIL_RE.test(email)) { setErr('이메일 형식을 확인해주세요.'); return; }
  try {
    await withBusy($('emp-send'), '보내는 중…', () => requestEmployCode(selected.comp_id, email));
    $('emp-code').value = ''; // 새 코드 발송 → 이전 입력 코드 비움(혼동 방지)
    $('code-step').hidden = false; $('manual-step').hidden = true; $('emp-code').focus();
    startTimer('emp-timer'); // 유효시간 카운트다운 시작
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) { // manual_required — 도메인 미등록
      $('manual-step').hidden = false; $('code-step').hidden = true;
    } else if (err instanceof ApiError && err.status === 422) {
      setErr('회사 이메일 도메인이 이 회사와 일치하지 않아요.');
    } else if (err instanceof ApiError && err.status === 401) {
      location.href = '/login';
    } else setErr('코드 발송에 실패했어요. 잠시 후 다시 시도해주세요.');
  }
});

// ── ③ 코드 검증 → 인증 생성 ──
$('emp-verify').addEventListener('click', async () => {
  clrMsg();
  const email = $('comp-email').value.trim();
  const code = $('emp-code').value.trim();
  if (!/^[0-9]{6}$/.test(code)) { setErr('6자리 숫자 코드를 입력해주세요.'); return; }
  try {
    await withBusy($('emp-verify'), '인증 중…', () => verifyEmployment(selected.comp_id, email, code));
    showSuccess(selected.comp_nm);
  } catch (err) {
    const s = err instanceof ApiError ? err.status : 0;
    if (s === 401) setErr('코드가 일치하지 않아요.');
    else if (s === 410) setErr('코드가 만료됐어요. ‘인증 코드 받기’를 다시 눌러주세요.');
    else if (s === 429) setErr('시도가 너무 많아요. 코드를 다시 받아주세요.');
    else if (s === 409) setErr('이미 인증됐거나, 다른 계정이 사용한 회사 이메일이에요.');
    else setErr('인증에 실패했어요. 잠시 후 다시 시도해주세요.');
  }
});

// ── ④ 수동 승인 요청(도메인 미등록 폴백) ──
$('manual-send').addEventListener('click', async () => {
  clrMsg();
  const evidence = $('evidence').value.trim();
  if (evidence.length < 1) { setErr('재직 증빙을 입력해주세요.'); return; }
  try {
    await withBusy($('manual-send'), '보내는 중…', () => submitEmployRequest(selected.comp_id, evidence));
    $('manual-step').hidden = true;
    const ok = $('verify-ok');
    ok.textContent = '재직 증빙을 접수했어요. 운영자 확인 후 인증됩니다(보통 하루 이내).';
    ok.hidden = false;
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) setErr('이미 대기 중인 요청이 있어요.');
    else setErr('요청에 실패했어요. 잠시 후 다시 시도해주세요.');
  }
});

function showSuccess(compNm) {
  stopTimer('emp-timer');
  for (const id of ['email-step', 'code-step', 'manual-step']) $(id).hidden = true;
  const ok = $('verify-ok');
  ok.textContent = '✅ ';
  const s = document.createElement('strong'); s.textContent = compNm; ok.append(s);
  ok.append(' 재직 인증 완료! 이제 이 회사 복지를 편집할 수 있어요. ');
  const a = document.createElement('a');
  a.href = selected ? ('/edit?comp=' + encodeURIComponent(selected.comp_id)) : '/edit';
  a.textContent = '복지 편집하러 가기 →'; a.className = 'auth-link';
  ok.append(a);
  ok.hidden = false;
}

// 진입: 세션 확인
(async () => {
  try { await getMe(); $('verify-card').hidden = false; }
  catch { $('need-login').hidden = false; }
})();
