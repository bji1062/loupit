// web/assets/js/verify.js — SC14 재직 인증 화면 로직(SP-FE). 회사 검색·선택 → 회사 이메일
// 도메인 자동 인증(코드) → 미등록 회사는 수동 승인 요청 폴백. 세션 필요. 사용자/회사명은
// textContent로만 삽입(XSS 안전). api.js의 credentialed·GET 헬퍼만 쓴다.
//
// 순수 로직(검증·카운트다운·오류 분류)은 export 하고, DOM 배선은 `initVerifyPage()` 안에서만
// 한다 — 화면 루트(#verify-card)가 있을 때만 초기화하므로 node:test import 시 부작용 0.

import {
  getMe, searchCompanies, requestEmployCode, verifyEmployment, submitEmployRequest, ApiError,
} from './api.js';

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// 코드 유효시간(서버 login_code_ttl_min=5분과 일치). 만료 시 재발송 유도.
export const CODE_TTL_SEC = 300;
// 서버 재전송 쿨다운(config.mail_resend_cooldown_sec)과 같은 값 — 이 창 안의 재요청은 서버가
// **무발송**으로 흡수하는데 응답은 균일 204라 클라이언트가 구분할 수 없다. 같은 주소로 다시
// 누르면 "새 코드가 곧 온다"는 잘못된 기대(+새 5:00 카운트다운)를 주므로 클라가 먼저 막는다.
export const RESEND_COOLDOWN_SEC = 60;

// ── 순수: 입력 형식(서버가 최종 판정 — 여기선 왕복 낭비를 줄이는 사전 확인) ──
export function isValidEmail(v) { return EMAIL_RE.test(String(v == null ? '' : v).trim()); }
export function isValidCode(v) { return /^[0-9]{6}$/.test(String(v == null ? '' : v).trim()); }

// ── 순수: 남은 초 → 표시 텍스트·만료 여부 ──
export function countdownText(remain) {
  if (remain <= 0) return { text: '코드가 만료됐어요 — ‘인증 코드 받기’를 다시 눌러주세요.', expired: true };
  return { text: `코드 유효시간 ${Math.floor(remain / 60)}:${String(remain % 60).padStart(2, '0')}`, expired: false };
}

// ── 순수: 같은 주소 재발송까지 남은 초(0이면 지금 보낼 수 있음) ──
export function resendWaitSec(lastSentMs, nowMs, cooldownSec = RESEND_COOLDOWN_SEC) {
  if (!lastSentMs) return 0;
  const elapsed = Math.floor((nowMs - lastSentMs) / 1000);
  return elapsed >= cooldownSec ? 0 : cooldownSec - elapsed;
}

// ── 순수: 코드 발송(POST /employment/verify-code) 실패 분류 ──
// 이 경로엔 코드 대조가 없어 401 은 세션 만료 한 뜻뿐이다(require_member).
export function sendOutcome(err) {
  const s = err instanceof ApiError ? err.status : 0;
  // ⚠ 409 는 **두 뜻**이다 — `detail` 로 갈라야 한다(2026-07-29, SP-AUTH-16).
  //   manual_required : 도메인 미등록 회사 → 수동 승인 폴백(오류 아님)
  //   mail_suppressed : 이 주소로 보낸 메일이 반송돼 발송을 멈춘 상태 → 다른 주소를 써야 한다
  // 구 판본은 409 를 전부 manual 로 단정했다. 그대로 두면 반송 사용자가 **오지 않을 수동
  // 승인을 무한정 기다린다**. 미지의 409 는 기존 동작(manual)을 유지해 회귀를 만들지 않는다.
  if (s === 409) {
    const detail = err && err.data ? err.data.detail : null;
    if (detail === 'mail_suppressed') {
      return { kind: 'error', msg: '이 주소로 보낸 메일이 반송되고 있어요. 다른 회사 이메일 주소를 사용해주세요.' };
    }
    return { kind: 'manual', msg: '' }; // manual_required — 도메인 미등록 회사
  }
  if (s === 422) return { kind: 'error', msg: '회사 이메일 도메인이 이 회사와 일치하지 않아요.' };
  if (s === 401) return { kind: 'session', msg: '로그인이 만료됐어요. 다시 로그인해주세요.' };
  // 발송 경로의 429 는 **엣지 IP 리밋 한 뜻뿐**이다(앱 핸들러는 204/409/422 만 낸다) →
  // `Retry-After`(nginx map, 20초)를 알면 숫자로 노출한다. 모르면 기존 문구로 폴백(적대검토 ③).
  // ⚠ 아래 verifyOutcome 의 429 는 **앱의 코드 시도 상한**이라 뜻이 달라 초를 붙이지 않는다.
  if (s === 429) {
    // s 는 위에서 `err instanceof ApiError ? err.status : 0` 로 얻었다 → 여기 도달했다면
    // err 는 반드시 ApiError 다(비 ApiError 는 s=0 이라 아래 기본 분기로 간다).
    const ra = err.retryAfter;
    return {
      kind: 'error',
      msg: Number.isFinite(ra) && ra > 0
        ? `요청이 너무 잦아요. ${ra}초 뒤에 다시 시도해주세요.`
        : '요청이 너무 잦아요. 잠시 후 다시 시도해주세요.',
    };
  }
  return { kind: 'error', msg: '코드 발송에 실패했어요. 잠시 후 다시 시도해주세요.' };
}

// ── 순수: 코드 검증(POST /employment/verify) 실패 분류 ──
// `clearCode`=죽은 코드를 입력칸에서 비움, `retryCode`=같은 코드로 재시도가 의미 있는가.
// ⚠️ 겹치는 상태를 풀어준다(UX 폴리시 2026-07-25):
//   ① 401 = 세션 만료(require_member) | 코드 불일치 — 서버 메시지 문자열이 아니라 getMe() 프로브
//      결과로 구분한다. 프로브는 **3값**(`probe`): 'alive'(200) · 'dead'(명시적 401) ·
//      'unknown'(타임아웃·5xx·네트워크). unknown 을 세션 만료로 단정하면 멀쩡한 세션 사용자를
//      /login 으로 축출하므로(회귀), unknown 은 기존 동작(코드 불일치 안내·화면 유지)으로 남긴다.
//   ② 409 = 이미 인증된 회사 | 회사 이메일이 이미 사용됨(`uq_employ_email` 은 **전역** 유니크라
//      내 다른 인증과도 충돌한다 — 예: @samsung.com 으로 삼성전자 인증 후 삼성SDI 시도).
//      "다른 계정이 썼다"고 단정할 수 없으므로 주체를 특정하지 않는 문구를 쓴다.
//   어느 쪽이든 코드는 이미 **소비**됐으므로 재시도하면 401(코드 불일치)이 떠 원인을 오해한다
//   → 코드를 비우고 코드 단계를 닫아 재시도 자체를 막는다.
export function verifyOutcome(err, ctx = {}) {
  const { probe = 'alive', alreadyVerified = false } = ctx;
  const s = err instanceof ApiError ? err.status : 0;
  if (s === 401 && probe === 'dead') {
    return { kind: 'session', msg: '로그인이 만료됐어요. 다시 로그인해주세요.', clearCode: false, retryCode: false };
  }
  if (s === 401) return { kind: 'mismatch', msg: '코드가 일치하지 않아요.', clearCode: false, retryCode: true };
  if (s === 410) return { kind: 'expired', msg: '코드가 만료됐어요. ‘인증 코드 받기’를 다시 눌러주세요.', clearCode: true, retryCode: false };
  if (s === 429) return { kind: 'throttled', msg: '시도가 너무 많아요. ‘인증 코드 받기’로 새 코드를 받아주세요.', clearCode: true, retryCode: false };
  if (s === 409) {
    return alreadyVerified
      ? { kind: 'already_verified', msg: '이미 이 회사 재직 인증이 있어요. 바로 복지를 편집할 수 있어요.', clearCode: true, retryCode: false }
      : { kind: 'email_in_use', msg: '이 회사 이메일은 이미 재직 인증에 사용됐어요 — 한 회사 이메일로는 한 곳만 인증할 수 있어요. 다른 회사 이메일로 인증 코드를 다시 받거나, 아래 수동 승인을 요청해주세요.', clearCode: true, retryCode: false };
  }
  return { kind: 'error', msg: '인증에 실패했어요. 잠시 후 다시 시도해주세요.', clearCode: false, retryCode: true };
}

// ── 순수: 회사 검색 결과 1건 → <li>(전부 textContent — XSS 안전). document 주입. ──
export function renderCompanyItem(doc, r) {
  const li = doc.createElement('li');
  li.tabIndex = 0;
  li.textContent = r.comp_nm; // textContent = XSS 안전
  if (r.industry_nm) {
    const ind = doc.createElement('span'); ind.className = 'ind'; ind.textContent = r.industry_nm;
    li.append(ind);
  }
  return li;
}

// ── 이하 DOM 배선(브라우저 전용) ──
export function initVerifyPage() {
  const $ = (id) => document.getElementById(id);

  let selected = null;              // {comp_id, comp_nm}
  let timerId = null;
  const sentAt = new Map();         // '회사|이메일' → 마지막 발송 시각(ms) — 클라 쿨다운

  function startTimer(elId) {
    clearInterval(timerId);
    const el = $(elId); el.classList.remove('expired');
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
  function stopTimer(elId) {
    clearInterval(timerId);
    const el = $(elId);
    if (el) { el.textContent = ''; el.classList.remove('expired'); }
  }

  function setErr(msg) { const e = $('verify-err'); e.textContent = msg; e.hidden = false; }
  function setOk(msg) { const e = $('verify-ok'); e.textContent = msg; e.hidden = false; }
  function clrMsg() { $('verify-err').hidden = true; $('verify-ok').hidden = true; }

  async function withBusy(btn, label, fn) {
    const orig = btn.textContent; btn.disabled = true; btn.textContent = label;
    try { return await fn(); } finally { btn.disabled = false; btn.textContent = orig; }
  }

  // 401·409 의 겹친 뜻을 푸는 프로브 — 세션 생존 + 이 회사 인증 보유를 서버에 되묻는다.
  // 결과는 3값: 'alive'(200) · 'dead'(프로브가 **명시적 401**) · 'unknown'(그 외 실패).
  // unknown 을 'dead' 로 뭉뚱그리면 일시 장애 때 정상 세션 사용자를 /login 으로 쫓아낸다.
  async function probeSession(compId) {
    try {
      const { data } = await getMe();
      const vrf = (data && data.verifications) || [];
      return { probe: 'alive', alreadyVerified: vrf.some((v) => v.comp_id === compId) };
    } catch (err) {
      const dead = err instanceof ApiError && err.status === 401;
      return { probe: dead ? 'dead' : 'unknown', alreadyVerified: false };
    }
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
      const li = renderCompanyItem(document, r);
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

  const sendKey = (compId, email) => compId + '|' + email.toLowerCase();

  // ── ② 회사 이메일 → 코드 발송(도메인 판정) ──
  $('emp-send').addEventListener('click', async () => {
    clrMsg();
    const target = selected; // 요청 중 '변경' 클릭으로 selected 가 바뀌어도 이 클릭의 대상은 고정
    if (!target) { setErr('회사를 먼저 선택해주세요.'); return; }
    const email = $('comp-email').value.trim();
    if (!isValidEmail(email)) { setErr('이메일 형식을 확인해주세요.'); return; }
    // 서버 쿨다운 창(무발송·균일 204) 안이면 클라가 먼저 막는다 — 오지 않을 코드를 기다리게 하지 않는다.
    const wait = resendWaitSec(sentAt.get(sendKey(target.comp_id, email)), Date.now());
    if (wait > 0) {
      setErr(`방금 이 주소로 코드를 보냈어요. 받은 코드를 입력하거나 ${wait}초 뒤에 다시 요청해주세요.`);
      // "받은 코드를 입력하라"고 안내하면서 입력칸이 없으면 안내가 자기모순이다. 평시엔 이미
      // 보이므로 no-op 이고, '변경' → 같은 회사 재선택으로 code-step 이 닫힌 경로에서만 실효가 있다.
      // 타이머는 건드리지 않는다 — 남은 TTL 은 원 발송 시각 기준이라 여기서 5:00 으로 되감으면 거짓말이다.
      $('code-step').hidden = false; $('emp-code').focus();
      return;
    }
    try {
      await withBusy($('emp-send'), '보내는 중…', () => requestEmployCode(target.comp_id, email));
      // 발송은 실제로 일어났으니 쿨다운 기록은 **가드보다 먼저** 남긴다(재클릭 억제는 유지).
      sentAt.set(sendKey(target.comp_id, email), Date.now());
      // ⚠ 최신성 가드 — 응답을 기다리는 사이 사용자가 '변경'을 눌렀거나 다른 회사를 골랐으면
      //   이 늦은 성공으로 화면을 되살리지 않는다. `withBusy` 는 인자로 받은 emp-send 만 잠그므로
      //   '변경' 버튼은 대기 중에도 눌린다 — 그때 selected=null 로 회사 컨텍스트가 지워지는데,
      //   가드가 없으면 code-step·5:00 타이머·포커스가 되살아나 **회사 없는 코드 입력 화면**이
      //   그려진다(#code-step 은 #email-step 의 형제라 함께 숨겨지지 않는다). 그 상태로 '인증하기'를
      //   누르면 "회사를 먼저 선택해주세요."가 떠 사용자는 영문을 모른다.
      //   기존에도 있던 레이스지만 창이 프론트 abort 상한과 같아서(구 8s → 지금 엣지 15s) 이번
      //   MAIL_TIMEOUT 상향이 노출 시간을 약 2배로 넓혔다 — 그래서 여기서 함께 닫는다.
      //   (동류 결함이 docs/AUDIT-2026-07-17.md 의 inputs.js 지적으로 이미 등재돼 있다.)
      if (selected !== target) return;
      $('emp-code').value = ''; // 새 코드 발송 → 이전 입력 코드 비움(혼동 방지)
      $('code-step').hidden = false; $('manual-step').hidden = true; $('emp-code').focus();
      startTimer('emp-timer'); // 유효시간 카운트다운 시작
    } catch (err) {
      const { kind, msg } = sendOutcome(err);
      if (selected !== target) return;   // 늦은 실패도 마찬가지 — 남의 화면에 오류를 뿌리지 않는다
      if (kind === 'manual') { // 도메인 미등록 → 수동 승인 폴백
        $('manual-step').hidden = false; $('code-step').hidden = true; stopTimer('emp-timer');
        return;
      }
      if (kind === 'session') { setErr(msg); location.href = '/login'; return; }
      setErr(msg);
    }
  });

  // ── ③ 코드 검증 → 인증 생성 ──
  // 버튼은 프로브(getMe)까지 **잠근 채** 유지한다 — 프로브 대기 중 재클릭하면 이미 소비된 코드로
  // 두 번째 요청이 나가 401(코드 불일치)이 뜨고, 그 메시지가 정확한 안내를 덮어쓴다.
  $('emp-verify').addEventListener('click', async () => {
    clrMsg();
    const target = selected; // 진행 중 '변경' 클릭에도 안전한 스냅샷
    if (!target) { setErr('회사를 먼저 선택해주세요.'); return; }
    const email = $('comp-email').value.trim();
    const code = $('emp-code').value.trim();
    if (!isValidCode(code)) { setErr('6자리 숫자 코드를 입력해주세요.'); return; }
    const btn = $('emp-verify');
    const orig = btn.textContent;
    btn.disabled = true; btn.textContent = '인증 중…';
    try {
      await verifyEmployment(target.comp_id, email, code);
      showSuccess(target);
    } catch (err) {
      const status = err instanceof ApiError ? err.status : 0;
      // 401(세션 만료 vs 코드 불일치)·409(이미 인증 vs 이메일 사용됨)만 서버에 되묻는다.
      let ctx = {};
      if (status === 401 || status === 409) {
        btn.textContent = '확인 중…';           // 프로브 구간에도 잠금 유지(재클릭 차단)
        ctx = await probeSession(target.comp_id);
      }
      const out = verifyOutcome(err, ctx);
      if (out.clearCode) $('emp-code').value = '';       // 소비·만료된 코드 잔류 방지
      if (!out.retryCode) { $('code-step').hidden = true; stopTimer('emp-timer'); } // 같은 코드 재시도 차단(→ 오해 401 예방)
      if (status === 409) sentAt.delete(sendKey(target.comp_id, email)); // 코드가 소비됐으므로 재발송 허용
      if (out.kind === 'session') { setErr(out.msg); location.href = '/login'; return; }
      if (out.kind === 'already_verified') { // 실패가 아니라 이미 달성된 상태 — 편집으로 안내
        $('email-step').hidden = true; $('manual-step').hidden = true;
        showAlreadyVerified(out.msg, target);
        return;
      }
      setErr(out.msg);
    } finally {
      btn.disabled = false; btn.textContent = orig;
    }
  });

  // ── ④ 수동 승인 요청(도메인 미등록 폴백) ──
  $('manual-send').addEventListener('click', async () => {
    clrMsg();
    const target = selected;
    if (!target) { setErr('회사를 먼저 선택해주세요.'); return; }
    const evidence = $('evidence').value.trim();
    if (evidence.length < 1) { setErr('재직 증빙을 입력해주세요.'); return; }
    try {
      await withBusy($('manual-send'), '보내는 중…', () => submitEmployRequest(target.comp_id, evidence));
      $('manual-step').hidden = true;
      setOk('재직 증빙을 접수했어요. 운영자 확인 후 인증됩니다(보통 하루 이내).');
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) setErr('이미 대기 중인 요청이 있어요.');
      else setErr('요청에 실패했어요. 잠시 후 다시 시도해주세요.');
    }
  });

  // 복지 편집 진입 링크(해당 회사로).
  function editLink(doc, compId) {
    const a = doc.createElement('a');
    a.href = compId != null ? ('/edit?comp=' + encodeURIComponent(compId)) : '/edit';
    a.textContent = '복지 편집하러 가기 →'; a.className = 'auth-link';
    return a;
  }

  function showSuccess(target) {
    stopTimer('emp-timer');
    for (const id of ['email-step', 'code-step', 'manual-step']) $(id).hidden = true;
    const ok = $('verify-ok');
    ok.textContent = '✅ ';
    const s = document.createElement('strong'); s.textContent = target.comp_nm; ok.append(s);
    ok.append(' 재직 인증 완료! 이제 이 회사 복지를 편집할 수 있어요. ');
    ok.append(editLink(document, target.comp_id));
    ok.hidden = false;
  }

  // 이미 인증돼 있던 경우(409 + 프로브 확인) — 오류가 아니라 안내 + 편집 링크.
  function showAlreadyVerified(msg, target) {
    const ok = $('verify-ok');
    ok.textContent = msg + ' ';
    ok.append(editLink(document, target.comp_id));
    ok.hidden = false;
  }

  // 진입: 세션 확인
  (async () => {
    try { await getMe(); $('verify-card').hidden = false; }
    catch { $('need-login').hidden = false; }
  })();
}

// 브라우저에서 재직 인증 화면 루트가 있을 때만 초기화(node:test 로 순수 함수만 import 시 부작용 0).
if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('verify-card')) {
  initVerifyPage();
}
