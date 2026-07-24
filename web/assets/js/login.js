// web/assets/js/login.js — SC14 참여 로그인 화면 로직(SP-FE, 무비밀번호 이메일 코드).
// 익명 열람은 로그인 불필요 — 이 화면은 기여자용이다. 3상태(이메일→코드→완료) 전환 +
// 상태코드→친절 메시지 매핑. api.js의 credentialed apiSend 헬퍼만 쓴다(다른 앱 모듈 import 0).

import { requestLoginCode, login, getMe, logout, ApiError } from './api.js';

const $ = (id) => document.getElementById(id);
const stepEmail = $('step-email');
const stepCode = $('step-code');
const stepDone = $('step-done');
const errBox = $('auth-error');

// 백엔드와 동일한 최소 형식(형식만 — 진짜 검증은 코드 발송). 앞뒤 공백 제거 후 판정.
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
let currentEmail = '';

function show(step) {
  stepEmail.hidden = step !== 'email';
  stepCode.hidden = step !== 'code';
  stepDone.hidden = step !== 'done';
  clearError();
}

function clearError() { errBox.hidden = true; errBox.textContent = ''; }
function showError(msg) { errBox.textContent = msg; errBox.hidden = false; }

// ApiError·네트워크 오류 → 단계별 친절 메시지. 서버는 원문(코드/이메일)을 응답에 넣지 않는다(NFR31).
function messageFor(err, phase) {
  if (!(err instanceof ApiError)) return '네트워크 오류예요. 잠시 후 다시 시도해주세요.';
  const s = err.status;
  if (phase === 'send') {
    if (s === 422) return '이메일 형식을 확인해주세요.';
    if (s === 429) return '요청이 너무 잦아요. 잠시 후 다시 시도해주세요.';
  } else { // 'login'
    if (s === 401) return '코드가 일치하지 않아요. 다시 확인해주세요.';
    if (s === 410) return '코드가 만료됐어요. ‘코드 다시 받기’를 눌러주세요.';
    if (s === 429) return '시도가 너무 많아요. 새 코드를 받아주세요.';
    if (s === 422) return '6자리 숫자 코드를 입력해주세요.';
  }
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}

async function withBusy(btn, label, fn) {
  const orig = btn.textContent;
  btn.disabled = true; btn.textContent = label;
  try { return await fn(); }
  finally { btn.disabled = false; btn.textContent = orig; }
}

// ① 이메일 → 코드 발송
stepEmail.addEventListener('submit', async (e) => {
  e.preventDefault();
  clearError();
  const email = $('email').value.trim();
  if (!EMAIL_RE.test(email)) { showError('이메일 형식을 확인해주세요.'); return; }
  try {
    await withBusy($('send-btn'), '보내는 중…', () => requestLoginCode(email));
    currentEmail = email;
    $('sent-to').textContent = email;
    show('code');
    $('code').focus();
  } catch (err) { showError(messageFor(err, 'send')); }
});

// ② 코드 → 로그인
stepCode.addEventListener('submit', async (e) => {
  e.preventDefault();
  clearError();
  const code = $('code').value.trim();
  if (!/^[0-9]{6}$/.test(code)) { showError('6자리 숫자 코드를 입력해주세요.'); return; }
  try {
    const { data } = await withBusy($('login-btn'), '로그인 중…', () => login(currentEmail, code));
    enterDone(data);
  } catch (err) { showError(messageFor(err, 'login')); }
});

// 코드 다시 받기(쿨다운 중이면 서버가 무발송하나 UI는 동일 — 계정 열거 방지 균일)
$('resend-btn').addEventListener('click', async () => {
  clearError();
  try {
    await withBusy($('resend-btn'), '보내는 중…', () => requestLoginCode(currentEmail));
    showError(''); errBox.hidden = true;
    $('code').value = ''; // 새 코드 발송 → 이전 입력 코드 비움
    $('sent-to').textContent = currentEmail;
    $('code').focus();
  } catch (err) { showError(messageFor(err, 'send')); }
});

$('change-btn').addEventListener('click', () => { $('code').value = ''; show('email'); $('email').focus(); });

$('logout-btn').addEventListener('click', async () => {
  try { await logout(); } catch { /* 이미 만료/폐기여도 UI는 로그아웃 처리 */ }
  $('email').value = ''; $('code').value = '';
  show('email');
});

function enterDone(data) {
  $('nickname').textContent = (data && data.nickname) || '직장인';
  $('done-sub').textContent = data && data.is_new
    ? '새 계정이 만들어졌어요. 닉네임은 마이페이지에서 바꿀 수 있어요.'
    : '다시 오신 걸 환영해요.';
  show('done');
}

// 진입 시 이미 로그인돼 있으면(유효 세션 쿠키) 완료 화면으로.
(async () => {
  try {
    const { data } = await getMe();
    enterDone({ nickname: data && data.nickname, is_new: false });
  } catch { show('email'); } // 401 등 → 로그인 필요
})();
