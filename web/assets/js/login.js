// web/assets/js/login.js — SC14 참여 로그인 화면 로직(SP-FE, 무비밀번호 이메일 코드).
// 익명 열람은 로그인 불필요 — 이 화면은 기여자용이다. 3상태(이메일→코드→완료) 전환 +
// 상태코드→친절 메시지 매핑. api.js의 credentialed apiSend 헬퍼만 쓴다(다른 앱 모듈 import 0).
//
// 순수 로직(형식 검증·메시지·카운트다운)은 export 하고, DOM 배선은 `initLoginPage()` 안에서만
// 한다 — 화면 루트(#step-email)가 있을 때만 초기화하므로 node:test import 시 부작용 0.

import { requestLoginCode, login, getMe, logout, ApiError } from './api.js';

// 백엔드와 동일한 최소 형식(형식만 — 진짜 검증은 코드 발송). 앞뒤 공백 제거 후 판정.
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// 코드 유효시간 카운트다운(서버 login_code_ttl_min=5분과 일치). 만료 시 재발송 유도.
export const CODE_TTL_SEC = 300;

export function isValidEmail(v) { return EMAIL_RE.test(String(v == null ? '' : v).trim()); }
export function isValidCode(v) { return /^[0-9]{6}$/.test(String(v == null ? '' : v).trim()); }

// ── 순수: 남은 초 → 표시 텍스트·만료 여부 ──
export function countdownText(remain) {
  if (remain <= 0) return { text: '코드가 만료됐어요 — ‘코드 다시 받기’를 눌러주세요.', expired: true };
  return { text: `코드 유효시간 ${Math.floor(remain / 60)}:${String(remain % 60).padStart(2, '0')}`, expired: false };
}

// ── 순수: 429 대기 안내 — 초를 알면 숫자로, 모르면 기존 문구 ──
// `err.retryAfter` 는 nginx 메일 리밋의 `Retry-After` 헤더뿐이다(api.js 참조). 값을 모를 때
// "잠시 후"로 폴백하는 게 핵심 — 실제 대기가 20초인데 무한정 안내를 하면 사용자는 연타한다.
// 연타가 excess 를 더 올리지는 않지만(nginx 는 거부 시 커밋하지 않는다 — 실측), **풀리는 토큰을
// 즉시 먹어치워** 정작 확인할 때마다 계속 429 를 보게 되고 공유 버킷의 다른 경로까지 굶는다
// (적대검토 ③, 근거는 SP-INFRA-3.4.6).
export function throttleMessage(retryAfter) {
  return Number.isFinite(retryAfter) && retryAfter > 0
    ? `요청이 너무 잦아요. ${retryAfter}초 뒤에 다시 시도해주세요.`
    : '요청이 너무 잦아요. 잠시 후 다시 시도해주세요.';
}

// ── 순수: ApiError·네트워크 오류 → 단계별 친절 메시지 ──
// 서버는 원문(코드/이메일)을 응답에 넣지 않는다(NFR31). 로그인 경로의 401 은 세션이 아니라
// **코드 불일치** 한 뜻뿐이다(로그인 자체가 세션 없이 부르는 라우트).
export function messageFor(err, phase) {
  if (!(err instanceof ApiError)) return '네트워크 오류예요. 잠시 후 다시 시도해주세요.';
  const s = err.status;
  if (phase === 'send') {
    if (s === 422) return '이메일 형식을 확인해주세요.';
    // 409 mail_suppressed — 이 주소로 보낸 메일이 반송된 이력이 있어 발송을 멈춘 상태다
    // (SP-AUTH-16). **"잠시 후 다시"는 거짓 안내다**: 기다린다고 풀리지 않고, 사용자가 할 수
    // 있는 유일한 행동은 다른 주소를 쓰는 것이다. 이걸 일반 오류로 흘리면 그 사용자는 영영
    // 로그인하지 못한 채 이유도 모른다(P1-4 가 지목한 공백).
    if (s === 409 && err.data && err.data.detail === 'mail_suppressed') {
      return '이 주소로 보낸 메일이 반송되고 있어요. 다른 이메일 주소를 사용해주세요.';
    }
    // 발송 경로의 429 는 **엣지 IP 리밋 한 뜻뿐**이다 — 앱 핸들러(`POST /members/login-code`)는
    // 계정 열거 차단을 위해 균일 204 만 낸다. 그래서 여기서만 초를 노출할 수 있다.
    if (s === 429) return throttleMessage(err.retryAfter);
  } else { // 'login'
    if (s === 401) return '코드가 일치하지 않아요. 다시 확인해주세요.';
    if (s === 410) return '코드가 만료됐어요. ‘코드 다시 받기’를 눌러주세요.';
    // ⚠ 여기 429 는 **앱의 코드 시도 상한**이라 뜻이 다르다: 기다린다고 풀리지 않고 새 코드가
    //   필요하다. `Retry-After` 도 없다(엣지가 아니라 앱이 낸 429). 초를 붙이면 거짓 안내다.
    if (s === 429) return '시도가 너무 많아요. 새 코드를 받아주세요.';
    if (s === 422) return '6자리 숫자 코드를 입력해주세요.';
  }
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}

// ── 순수: 로그인 완료 안내문(신규 계정 여부) ──
export function doneSubText(isNew) {
  return isNew
    ? '새 계정이 만들어졌어요. 닉네임은 마이페이지에서 바꿀 수 있어요.'
    : '다시 오신 걸 환영해요.';
}

// ── 순수: `?next=` 되돌아갈 곳(T-14.6.6, SC15) — same-origin **절대 경로**만 ──
// 커뮤니티가 "로그인하고 돌아오기"(`/login?next=/community/write`)를 쓴다. 이 값이 열린
// 리다이렉트가 되는 순간 로그인 화면이 피싱 도구가 된다(`/login?next=https://evil` 로 코드
// 입력을 유도한 뒤 가짜 사이트로 보내는 식). 그래서 **허용 규칙만** 적고 나머지는 전부 버린다:
// `/` 로 시작 · `//` 로 시작하지 않음(프로토콜 상대 URL) · `http`·`javascript:`·`\` 를 어디에도
// 포함하지 않음(브라우저가 `\` 를 `/` 로 정규화한다) · 공백·제어문자 없음. 거부 시 null = 기존 동작.
export function safeNext(raw) {
  if (typeof raw !== 'string' || !raw) return null;
  if (!raw.startsWith('/') || raw.startsWith('//')) return null;
  if (/http|javascript:|\\/i.test(raw)) return null;
  if (/[\s\u0000-\u001f\u007f]/.test(raw)) return null;
  return raw;
}
export function nextFromSearch(search) {
  try { return safeNext(new URLSearchParams(search || '').get('next')); } catch { return null; }
}
// 완료 화면의 큰 버튼: next 가 있으면 "돌아가기"(그리로), 없으면 기존 마이페이지.
export function doneLinkFor(next) {
  return next ? { href: next, label: '돌아가기' } : { href: '/mypage', label: '마이페이지로 가기' };
}

// ── 이하 DOM 배선(브라우저 전용) ──
export function initLoginPage() {
  const $ = (id) => document.getElementById(id);
  const stepEmail = $('step-email');
  const stepCode = $('step-code');
  const stepDone = $('step-done');
  const errBox = $('auth-error');
  // `?next=` 는 진입 시 한 번만 읽어 검증한다. 완료 화면 링크는 마크업(login.html 의 a.auth-btn)
  // 을 그대로 두고 여기서 href·라벨만 바꾼다 — 셸을 안 건드리는 편이 공개 절차와 분리된다.
  const next = nextFromSearch(typeof location !== 'undefined' ? location.search : '');
  const doneLink = stepDone && stepDone.querySelector('a.auth-btn');
  if (doneLink) { const t = doneLinkFor(next); doneLink.setAttribute('href', t.href); doneLink.textContent = t.label; }

  let currentEmail = '';
  let timerId = null;

  function startTimer() {
    clearInterval(timerId);
    const el = $('login-timer'); el.classList.remove('expired');
    let remain = CODE_TTL_SEC;
    const tick = () => {
      const { text, expired } = countdownText(remain);
      el.textContent = text;
      if (expired) { clearInterval(timerId); el.classList.add('expired'); return; }
      remain -= 1;
    };
    tick();
    timerId = setInterval(tick, 1000);
  }
  function stopTimer() {
    clearInterval(timerId);
    const el = $('login-timer');
    if (el) { el.textContent = ''; el.classList.remove('expired'); }
  }

  function show(step) {
    stepEmail.hidden = step !== 'email';
    stepCode.hidden = step !== 'code';
    stepDone.hidden = step !== 'done';
    clearError();
  }

  function clearError() { errBox.hidden = true; errBox.textContent = ''; }
  function showError(msg) { errBox.textContent = msg; errBox.hidden = false; }

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
    if (!isValidEmail(email)) { showError('이메일 형식을 확인해주세요.'); return; }
    try {
      await withBusy($('send-btn'), '보내는 중…', () => requestLoginCode(email));
      currentEmail = email;
      $('sent-to').textContent = email;
      show('code');
      $('code').focus();
      startTimer();
    } catch (err) { showError(messageFor(err, 'send')); }
  });

  // ② 코드 → 로그인
  stepCode.addEventListener('submit', async (e) => {
    e.preventDefault();
    clearError();
    const code = $('code').value.trim();
    if (!isValidCode(code)) { showError('6자리 숫자 코드를 입력해주세요.'); return; }
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
      $('code').value = ''; // 새 코드 발송 → 이전 입력 코드 비움
      $('sent-to').textContent = currentEmail;
      $('code').focus();
      startTimer();
    } catch (err) { showError(messageFor(err, 'send')); }
  });

  $('change-btn').addEventListener('click', () => { stopTimer(); $('code').value = ''; show('email'); $('email').focus(); });

  $('logout-btn').addEventListener('click', async () => {
    try { await logout(); } catch { /* 이미 만료/폐기여도 UI는 로그아웃 처리 */ }
    $('email').value = ''; $('code').value = '';
    show('email');
  });

  function enterDone(data) {
    stopTimer();
    $('nickname').textContent = (data && data.nickname) || '직장인';
    $('done-sub').textContent = doneSubText(!!(data && data.is_new));
    show('done');
  }

  // 진입 시 이미 로그인돼 있으면(유효 세션 쿠키) 완료 화면으로.
  (async () => {
    try {
      const { data } = await getMe();
      enterDone({ nickname: data && data.nickname, is_new: false });
    } catch { show('email'); } // 401 등 → 로그인 필요
  })();
}

// 브라우저에서 로그인 화면 루트가 있을 때만 초기화(node:test 로 순수 함수만 import 시 부작용 0).
if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('step-email')) {
  initLoginPage();
}
