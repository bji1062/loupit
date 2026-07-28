// web/assets/js/auth-dom.test.js — SC14 참여 4화면 DOM 배선 통합 테스트(SP-FE).
// 실제 login/mypage/verify/edits **HTML 파일**을 jsdom 에 올리고 init*Page() 를 직접 호출해,
// (a) HTML 의 id 집합과 JS 가 찾는 id 가 실제로 맞는지, (b) 상태 전환·오류 처리 배선이
// 의도대로 도는지 검증한다. 네트워크는 globalThis.fetch 목(api.js 무수정)으로 대체한다.
//
// ⚠️ import 시점엔 globalThis.document 가 없어야 한다(각 모듈의 자동 초기화 가드가 발동하지
// 않도록) — 정적 import 는 테스트 본문보다 먼저 평가되므로 이 파일에선 안전하다.
import test, { describe, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { JSDOM } from 'jsdom';

import { initLoginPage } from './login.js';
import { initMypage } from './mypage.js';
import { initVerifyPage } from './verify.js';
import { initEditsPage, PAGE_LIMIT } from './edits.js';

// ── 화면 마운트: 실 HTML → jsdom, 전역 document·location 주입 ────────────────
function mountPage(file, url) {
  const html = readFileSync(new URL('../../' + file, import.meta.url), 'utf8');
  const dom = new JSDOM(html, { url });
  globalThis.document = dom.window.document;
  globalThis.location = { href: url, search: '' }; // 모듈은 bare `location` 사용 → 이 스텁이 잡힌다
  globalThis.confirm = () => true;
  globalThis.alert = () => {};
  return dom;
}

// ── fetch 목: [method, 경로조각, 응답|(n)=>응답] 규칙을 순서대로 매칭 ─────────
function mockApi(rules) {
  const calls = [];
  const hits = new Map();
  globalThis.fetch = async (url, opts = {}) => {
    const method = opts.method || 'GET';
    const path = String(url).replace('/api/v1', '');
    calls.push({ method, path, opts });
    for (const [i, [m, frag, resp]] of rules.entries()) {
      if (m === method && path.includes(frag)) {
        const n = (hits.get(i) || 0) + 1; hits.set(i, n);
        const r = typeof resp === 'function' ? resp(n) : resp;
        if (r.delayMs) await new Promise((res) => setTimeout(res, r.delayMs)); // 레이스 재현용 지연
        const body = r.body === undefined ? '' : JSON.stringify(r.body);
        return {
          ok: r.status >= 200 && r.status < 300,
          status: r.status,
          text: async () => body,          // apiSend 경로
          json: async () => r.body,        // apiFetch(익명 GET) 경로
        };
      }
    }
    throw new Error('unmocked request: ' + method + ' ' + path);
  };
  return calls;
}

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const $ = (id) => globalThis.document.getElementById(id);
const submit = (dom, id) => $(id).dispatchEvent(new dom.window.Event('submit', { cancelable: true, bubbles: true }));

// 화면들은 1초 주기 카운트다운 인터벌을 건다. 어서션이 실패해 정지 경로에 도달하지 못하면 그
// 인터벌이 이벤트 루프를 붙잡아 러너가 기본 타임아웃(5분)까지 매달린다 → 인터벌을 추적해 정리한다.
let openIntervals = [];
const realSetInterval = globalThis.setInterval;
beforeEach(() => {
  openIntervals = [];
  globalThis.setInterval = (fn, ms, ...rest) => {
    const id = realSetInterval(fn, ms, ...rest);
    openIntervals.push(id);
    return id;
  };
});

afterEach(() => {
  for (const id of openIntervals) clearInterval(id);
  globalThis.setInterval = realSetInterval;
  delete globalThis.document; delete globalThis.location;
  delete globalThis.confirm; delete globalThis.alert;
});

// ── 로그인 화면 ───────────────────────────────────────────────────────────────
describe('login.html + initLoginPage', () => {
  let dom;
  beforeEach(() => { dom = mountPage('login.html', 'https://beta.loupit.co/login'); });

  test('무세션 진입 → 이메일 단계 → 코드 단계 → 완료(닉네임·신규 안내)', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 401, body: { detail: '로그인이 필요합니다.' } }],
      ['POST', '/members/login-code', { status: 204 }],
      ['POST', '/members/login', { status: 200, body: { nickname: '직장인-378575', is_new: true } }],
    ]);
    initLoginPage();
    await tick();
    assert.equal($('step-email').hidden, false, '401 → 이메일 단계 노출');

    $('email').value = 'e2e@example.com';
    submit(dom, 'step-email');
    await tick();
    assert.equal($('step-code').hidden, false, '코드 단계로 전환');
    assert.equal($('sent-to').textContent, 'e2e@example.com');
    assert.match($('login-timer').textContent, /코드 유효시간 5:00/);
    assert.equal(JSON.parse(calls[1].opts.body).email, 'e2e@example.com');

    $('code').value = '123456';
    submit(dom, 'step-code');
    await tick();
    assert.equal($('step-done').hidden, false, '완료 단계로 전환');
    assert.equal($('nickname').textContent, '직장인-378575');
    assert.match($('done-sub').textContent, /새 계정/);
    assert.equal($('login-timer').textContent, '', '완료 시 카운트다운 정지');
  });

  test('코드 불일치(401) → 친절 메시지, 코드 단계 유지(재입력 가능)', async () => {
    mockApi([
      ['GET', '/members/me', { status: 401, body: {} }],
      ['POST', '/members/login-code', { status: 204 }],
      ['POST', '/members/login', { status: 401, body: { detail: '코드가 일치하지 않습니다.' } }],
    ]);
    initLoginPage();
    await tick();
    $('email').value = 'e2e@example.com';
    submit(dom, 'step-email');
    await tick();
    $('code').value = '000000';
    submit(dom, 'step-code');
    await tick();
    assert.equal($('step-code').hidden, false, '재입력을 위해 코드 단계 유지');
    assert.match($('auth-error').textContent, /일치하지 않아요/);
    assert.equal($('auth-error').hidden, false);
    $('change-btn').click(); // 카운트다운 정지(테스트 종료 시 타이머 잔류 방지)
  });

  test('형식 위반 이메일은 네트워크 호출 없이 거부', async () => {
    const calls = mockApi([['GET', '/members/me', { status: 401, body: {} }]]);
    initLoginPage();
    await tick();
    $('email').value = 'not-an-email';
    submit(dom, 'step-email');
    await tick();
    assert.match($('auth-error').textContent, /이메일 형식/);
    assert.equal(calls.filter((c) => c.path.includes('login-code')).length, 0);
  });

  test('코드 다시 받기 → 재요청·입력칸 비움·카운트다운 재시작', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 401, body: {} }],
      ['POST', '/members/login-code', { status: 204 }],
    ]);
    initLoginPage();
    await tick();
    $('email').value = 'e2e@example.com';
    submit(dom, 'step-email');
    await tick();
    $('code').value = '111111';
    $('resend-btn').click();
    await tick();
    assert.equal(calls.filter((c) => c.path.includes('login-code')).length, 2, '새 코드 재요청');
    assert.equal($('code').value, '', '옛 코드가 남아 제출되면 401 로 원인을 오해한다');
    assert.match($('login-timer').textContent, /5:00/, '유효시간 재시작');
    assert.equal($('auth-error').hidden, true);
    $('change-btn').click(); // 카운트다운 정지
  });

  test('유효 세션으로 진입 → 바로 완료 화면(이미 로그인 감지)', async () => {
    mockApi([['GET', '/members/me', { status: 200, body: { nickname: '직장인-1', status: 'active', verifications: [] } }]]);
    initLoginPage();
    await tick();
    assert.equal($('step-done').hidden, false);
    assert.equal($('nickname').textContent, '직장인-1');
    assert.match($('done-sub').textContent, /다시 오신/);
  });
});

// ── 마이페이지 ────────────────────────────────────────────────────────────────
describe('mypage.html + initMypage', () => {
  let dom;
  beforeEach(() => { dom = mountPage('mypage.html', 'https://beta.loupit.co/mypage'); });

  test('내 정보·재직 인증 목록 렌더(편집 링크 포함)', async () => {
    mockApi([['GET', '/members/me', { status: 200, body: {
      nickname: '직장인-378575', status: 'active',
      verifications: [{ comp_id: 40, comp_nm: '삼성전자', expires_dtm: '2027-07-25T13:14:43' }],
    } }]]);
    initMypage();
    await tick();
    assert.equal($('profile').hidden, false);
    assert.equal($('vrf-card').hidden, false);
    assert.equal($('account-card').hidden, false);
    assert.equal($('need-login').hidden, true);
    assert.equal($('nickname').textContent, '직장인-378575');
    assert.equal($('status').textContent, '정상');
    const items = $('vrf-list').querySelectorAll('li');
    assert.equal(items.length, 1);
    assert.match(items[0].textContent, /삼성전자/);
    assert.match(items[0].textContent, /만료 2027-07-25/);
    assert.equal(items[0].querySelector('a').getAttribute('href'), '/edit?comp=40');
    assert.equal($('vrf-empty').hidden, true);
  });

  test('재직 인증 0건 → 안내 문구', async () => {
    mockApi([['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }]]);
    initMypage();
    await tick();
    assert.equal($('vrf-empty').hidden, false);
    assert.equal($('vrf-list').querySelectorAll('li').length, 0);
  });

  test('무세션 → 로그인 유도 카드만', async () => {
    mockApi([['GET', '/members/me', { status: 401, body: {} }]]);
    initMypage();
    await tick();
    assert.equal($('need-login').hidden, false);
    assert.equal($('profile').hidden, true);
  });

  test('닉네임 변경 성공 → 새 닉네임 반영 + 성공 문구(빈 상자 아님)', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: '직장인-1', status: 'active', verifications: [] } }],
      ['PUT', '/members/me', { status: 200, body: { nickname: '새닉네임', status: 'active', verifications: [] } }],
    ]);
    initMypage();
    await tick();
    $('edit-nick').click();
    $('nick-input').value = '새닉네임';
    $('save-nick').click();
    await tick();
    assert.equal($('nickname').textContent, '새닉네임');
    assert.equal($('nick-edit').hidden, true);
    assert.equal($('nick-ok').hidden, false);
    assert.match($('nick-ok').textContent, /변경했어요/, '성공 안내가 비어 있으면 안 됨(clr 이 정적 문구를 지운다)');
  });

  test('탈퇴 — confirm 취소면 요청 0건 · 실패면 안내·버튼 복구 · 성공이면 알림 후 홈 이동', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      ['DELETE', '/members/me', (n) => (n === 1 ? { status: 500, body: { detail: 'x' } } : { status: 204 })],
    ]);
    initMypage();
    await tick();

    globalThis.confirm = () => false;
    $('withdraw-btn').click();
    await tick();
    assert.equal(calls.filter((c) => c.method === 'DELETE').length, 0, '확인 거부 시 계정을 지우면 안 됨');

    globalThis.confirm = () => true;
    $('withdraw-btn').click();
    await tick();
    assert.match($('account-err').textContent, /실패/);
    assert.equal($('withdraw-btn').disabled, false, '실패 시 재시도 가능하게 복구');

    let alerted = false; globalThis.alert = () => { alerted = true; };
    $('withdraw-btn').click();
    await tick();
    assert.equal(alerted, true);
    assert.equal(globalThis.location.href, '/');
  });

  test('로그아웃 → 세션 폐기 요청 후 /login 이동(요청 실패해도 이동)', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      ['POST', '/members/logout', { status: 500, body: { detail: 'x' } }],
    ]);
    initMypage();
    await tick();
    $('logout-btn').click();
    await tick();
    assert.equal(calls.filter((c) => c.path.includes('logout')).length, 1);
    assert.equal(globalThis.location.href, '/login', '서버가 실패해도 클라이언트는 로그아웃 처리');
  });

  test('금칙어 닉네임은 서버 호출 없이 거부, 중복(409)은 서버 메시지 매핑', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: '직장인-1', status: 'active', verifications: [] } }],
      ['PUT', '/members/me', { status: 409, body: { detail: '이미 사용 중인 닉네임입니다.' } }],
    ]);
    initMypage();
    await tick();
    $('edit-nick').click();
    assert.equal($('nick-edit').hidden, false);
    assert.equal($('nick-input').value, '직장인-1', '현재 닉네임 프리필');

    $('nick-input').value = '관리자';
    $('save-nick').click();
    await tick();
    assert.match($('nick-err').textContent, /사용할 수 없는/);
    assert.equal(calls.filter((c) => c.method === 'PUT').length, 0, '클라 검증 단계에서 차단');

    $('nick-input').value = '중복닉네임';
    $('save-nick').click();
    await tick();
    assert.match($('nick-err').textContent, /이미 사용 중/);
    assert.equal($('nick-edit').hidden, false, '실패 시 편집 상태 유지');
    assert.equal($('save-nick').disabled, false, '버튼 잠금 해제');
  });
});

// ── 재직 인증 화면 (UX 폴리시 회귀: 409 뒤 재시도 → 오해 401 차단) ──────────────
describe('verify.html + initVerifyPage', () => {
  let dom;
  beforeEach(() => { dom = mountPage('verify.html', 'https://beta.loupit.co/verify'); });

  // 회사 검색 → 선택 → 코드 발송까지 진행(코드 입력 단계 노출 상태로 만든다).
  async function reachCodeStep() {
    $('comp-search').value = '삼성';
    $('comp-search').dispatchEvent(new dom.window.Event('input', { bubbles: true }));
    await tick(320); // 디바운스 250ms + 응답
    const li = $('comp-results').querySelector('li');
    assert.ok(li, '검색 결과 렌더');
    li.click();
    assert.equal($('email-step').hidden, false);
    $('comp-email').value = 'hong@samsung.com';
    $('emp-send').click();
    await tick();
    assert.equal($('code-step').hidden, false, '코드 입력 단계 노출');
    $('emp-code').value = '341110';
  }

  const SEARCH_OK = ['GET', '/companies/search', { status: 200, body: [{ comp_id: 40, comp_nm: '삼성전자', industry_nm: '반도체' }] }];
  const SEND_OK = ['POST', '/employment/verify-code', { status: 204 }];

  // ── 늦은 발송 응답 레이스(적대검토 2026-07-28) ──────────────────────────────
  // `withBusy` 는 인자로 받은 `emp-send` 만 잠근다 → 대기 중에도 '변경' 버튼은 눌린다.
  // 그때 회사 컨텍스트가 지워지는데, 늦게 도착한 204 가 `code-step` 을 되살리면
  // **회사 없는 코드 입력 화면**이 그려진다(#code-step 은 #email-step 의 형제라 함께 안 숨는다).
  // 기존에도 있던 레이스지만 MAIL_TIMEOUT 20s 상향이 노출 창을 넓혀(구 8s → 엣지 15s) 함께 닫았다.
  test('발송 대기 중 회사 "변경" → 늦은 204 가 코드 단계를 되살리지 않는다', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK,
      ['POST', '/employment/verify-code', { status: 204, delayMs: 120 }], // 느린 SMTP 모사
    ]);
    initVerifyPage();
    await tick();
    $('comp-search').value = '삼성';
    $('comp-search').dispatchEvent(new dom.window.Event('input', { bubbles: true }));
    await tick(320);
    $('comp-results').querySelector('li').click();
    $('comp-email').value = 'hong@samsung.com';
    $('emp-send').click();               // 응답 전(120ms) 에…
    await tick(20);
    assert.equal($('comp-change').disabled, false, '전제: 대기 중에도 변경 버튼은 눌린다');
    $('comp-change').click();            // …사용자가 회사를 바꾼다
    assert.equal($('code-step').hidden, true, '변경 직후엔 코드 단계가 닫혀 있다');
    await tick(200);                     // 늦은 204 도착
    assert.equal($('code-step').hidden, true, '늦은 204 가 코드 단계를 되살리면 안 된다');
    assert.equal($('comp-selected').hidden, true, '회사 컨텍스트는 지워진 채로 유지');
    assert.equal($('emp-timer').textContent, '', '5:00 타이머가 되살아나면 안 된다');
    assert.notEqual(globalThis.document.activeElement && globalThis.document.activeElement.id,
      'emp-code', '사라진 입력칸으로 포커스를 끌고 가면 안 된다');
  });

  test('쿨다운 안내는 입력칸과 함께 뜬다(안내가 자기모순이면 안 된다)', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK, SEND_OK,
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();               // 1차 발송 성공 → sentAt 기록
    $('comp-change').click();            // 코드 단계가 닫힌다
    assert.equal($('code-step').hidden, true);
    $('comp-search').value = '삼성';
    $('comp-search').dispatchEvent(new dom.window.Event('input', { bubbles: true }));
    await tick(320);
    $('comp-results').querySelector('li').click();   // 같은 회사 재선택
    $('comp-email').value = 'hong@samsung.com';
    $('emp-send').click();               // 60초 쿨다운에 걸린다
    await tick();
    assert.match($('verify-err').textContent, /받은 코드를 입력/, '쿨다운 안내');
    assert.equal($('code-step').hidden, false, '"코드를 입력하라"면서 입력칸이 없으면 안 된다');
  });

  test('도메인 자동 인증 성공(201) → 완료 안내 + 복지 편집 링크', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 201, body: { comp_id: 40, method: 'domain' } }],
    ]);
    initVerifyPage();
    await tick();
    assert.equal($('verify-card').hidden, false);
    await reachCodeStep();
    $('emp-verify').click();
    await tick();
    assert.equal($('verify-ok').hidden, false);
    assert.match($('verify-ok').textContent, /삼성전자/);
    assert.match($('verify-ok').textContent, /재직 인증 완료/);
    assert.equal($('verify-ok').querySelector('a').getAttribute('href'), '/edit?comp=40');
    assert.equal($('code-step').hidden, true);
    assert.equal($('emp-timer').textContent, '', '완료 시 카운트다운 정지');
  });

  test('회귀: 409(회사 이메일 선점) → 코드칸 비움·코드 단계 닫힘 → 같은 코드 재시도로 오해 401 불가', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 409, body: { detail: '이미 사용된 회사 이메일입니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick();

    assert.match($('verify-err').textContent, /다른 회사 이메일/, '원인에 맞는 안내');
    assert.doesNotMatch($('verify-err').textContent, /일치하지 않아요/, '코드 불일치로 오인 금지');
    assert.equal($('emp-code').value, '', '소비된 코드 비움');
    assert.equal($('code-step').hidden, true, '코드 단계를 닫아 재시도(→오해 401) 차단');
    assert.equal($('emp-timer').textContent, '', '카운트다운 정지');
    assert.equal($('email-step').hidden, false, '다른 회사 이메일로 재시도할 수 있게 이메일 단계 유지');
    // 409 원인 규명을 위해 세션·인증 보유를 서버에 되물었다(문자열 매칭 아님)
    assert.equal(calls.filter((c) => c.path.includes('/members/me')).length, 2);
  });

  test('409 + 이미 그 회사 인증 보유 → 오류가 아니라 “이미 인증” 안내 + 편집 링크', async () => {
    mockApi([
      ['GET', '/members/me', (n) => (n === 1
        ? { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }
        : { status: 200, body: { nickname: 'n', status: 'active', verifications: [{ comp_id: 40, comp_nm: '삼성전자' }] } })],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 409, body: { detail: '이미 인증된 회사입니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick();
    assert.equal($('verify-ok').hidden, false);
    assert.match($('verify-ok').textContent, /이미 이 회사 재직 인증/);
    assert.equal($('verify-ok').querySelector('a').getAttribute('href'), '/edit?comp=40');
    assert.equal($('verify-err').hidden, true, '오류로 표시하지 않음');
    assert.equal($('code-step').hidden, true);
  });

  test('401 + 세션 죽음 → 세션 만료 안내 + /login 이동(코드 불일치로 오인 금지)', async () => {
    mockApi([
      ['GET', '/members/me', (n) => (n === 1
        ? { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }
        : { status: 401, body: { detail: '로그인이 필요합니다.' } })],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 401, body: { detail: '코드가 일치하지 않습니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick();
    assert.match($('verify-err').textContent, /로그인이 만료/);
    assert.equal(globalThis.location.href, '/login');
    assert.equal($('code-step').hidden, true);
  });

  test('401 + 세션 생존 → 코드 불일치(코드 단계 유지·코드 보존해 재입력)', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 401, body: { detail: '코드가 일치하지 않습니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick();
    assert.match($('verify-err').textContent, /일치하지 않아요/);
    assert.equal($('code-step').hidden, false, '재입력 가능하게 유지');
    assert.equal($('emp-code').value, '341110', '입력 코드 보존');
    assert.notEqual(globalThis.location.href, '/login');
    $('comp-change').click(); // 카운트다운 정지
  });

  test('회귀: 프로브가 실패(5xx)해도 세션 만료로 단정하지 않는다 — 화면 유지·코드 재입력 가능', async () => {
    mockApi([
      ['GET', '/members/me', (n) => (n === 1
        ? { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }
        : { status: 502, body: { detail: 'bad gateway' } })],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 401, body: { detail: '코드가 일치하지 않습니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick();
    assert.match($('verify-err').textContent, /일치하지 않아요/, '프로브 실패는 세션 사망의 증거가 아니다');
    assert.notEqual(globalThis.location.href, '/login', '멀쩡한 세션 사용자를 로그인으로 축출 금지');
    assert.equal($('code-step').hidden, false, '입력한 회사·이메일·코드 단계 보존');
    $('comp-change').click(); // 카운트다운 정지
  });

  test('회귀: 프로브 대기 중 재클릭이 막힌다 — 안 막으면 소비된 코드로 두 번째 요청이 나가 오해 401 이 안내를 덮어쓴다', async () => {
    const calls = mockApi([
      ['GET', '/members/me', (n) => (n === 1
        ? { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }
        : { status: 200, body: { nickname: 'n', status: 'active', verifications: [] }, delayMs: 120 })],
      SEARCH_OK, SEND_OK,
      ['POST', '/employment/verify', { status: 409, body: { detail: '이미 사용된 회사 이메일입니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep();
    $('emp-verify').click();
    await tick(30); // 프로브 진행 중
    assert.equal($('emp-verify').disabled, true, '프로브 구간에도 버튼 잠금 유지');
    assert.equal($('emp-verify').textContent, '확인 중…');
    $('emp-verify').click();               // 비활성 버튼 클릭 = 무시돼야 함
    await tick(200);
    assert.equal(calls.filter((c) => c.path.endsWith('/employment/verify')).length, 1, '중복 인증 요청 없음');
    assert.match($('verify-err').textContent, /이미 재직 인증에 사용/, '정확한 안내가 살아남음');
    assert.doesNotMatch($('verify-err').textContent, /일치하지 않아요/);
    assert.equal($('emp-verify').disabled, false, '처리 후 버튼 복구');
  });

  test('같은 주소로 곧바로 재발송 → 서버 쿨다운(무발송)을 클라가 먼저 막고 안내', async () => {
    const calls = mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK, SEND_OK,
    ]);
    initVerifyPage();
    await tick();
    await reachCodeStep(); // 1회 발송됨
    const sent1 = calls.filter((c) => c.path.includes('verify-code')).length;
    $('emp-send').click();
    await tick();
    assert.equal(calls.filter((c) => c.path.includes('verify-code')).length, sent1, '쿨다운 중엔 요청 자체를 보내지 않음');
    assert.match($('verify-err').textContent, /초 뒤에 다시 요청/, '오지 않을 코드를 기다리게 하지 않음');
    $('comp-change').click();
  });

  test('발송 단계 401(세션 만료) → 안내 후 /login 이동', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK,
      ['POST', '/employment/verify-code', { status: 401, body: { detail: '로그인이 필요합니다.' } }],
    ]);
    initVerifyPage();
    await tick();
    $('comp-search').value = '삼성';
    $('comp-search').dispatchEvent(new dom.window.Event('input', { bubbles: true }));
    await tick(320);
    $('comp-results').querySelector('li').click();
    $('comp-email').value = 'hong@samsung.com';
    $('emp-send').click();
    await tick();
    assert.match($('verify-err').textContent, /로그인이 만료/);
    assert.equal(globalThis.location.href, '/login');
    assert.equal($('code-step').hidden, true);
  });

  test('도메인 미등록(409 manual_required, 발송 단계) → 수동 승인 폼 노출 → 접수 안내', async () => {
    mockApi([
      ['GET', '/members/me', { status: 200, body: { nickname: 'n', status: 'active', verifications: [] } }],
      SEARCH_OK,
      ['POST', '/employment/verify-code', { status: 409, body: { detail: 'manual_required' } }],
      ['POST', '/employment/requests', { status: 202, body: { status: 'pending' } }],
    ]);
    initVerifyPage();
    await tick();
    $('comp-search').value = '삼성';
    $('comp-search').dispatchEvent(new dom.window.Event('input', { bubbles: true }));
    await tick(320);
    $('comp-results').querySelector('li').click();
    $('comp-email').value = 'hong@unknown-domain.com';
    $('emp-send').click();
    await tick();
    assert.equal($('manual-step').hidden, false, '수동 승인 폴백 노출');
    assert.equal($('code-step').hidden, true);
    assert.equal($('verify-err').hidden, true, '오류로 표시하지 않음(폴백 경로)');

    $('evidence').value = '재직증명서 링크';
    $('manual-send').click();
    await tick();
    assert.equal($('manual-step').hidden, true);
    assert.match($('verify-ok').textContent, /접수했어요/);
  });
});

// ── 공개 편집 이력 (키셋 페이징: edit_id + before 커서, 사용자 결정 2026-07-25) ──
describe('edits.html + initEditsPage', () => {
  beforeEach(() => {
    mountPage('edits.html', 'https://beta.loupit.co/edits?comp=40');
    globalThis.location.search = '?comp=40';
  });

  // 최신순 페이지 생성(edit_id 내림차순).
  const page = (startId, n) => Array.from({ length: n }, (_, i) => ({
    edit_id: startId - i, nickname: '직장인-' + (i % 3), edit_type: 'update',
    before: { benefit_nm: '식대', benefit_amt: 200, qual_yn: false, benefit_ctgr_cd: 'compensation' },
    after: { benefit_nm: '식대', benefit_amt: 220, qual_yn: false, benefit_ctgr_cd: 'compensation' },
    edit_note: '금액 정정', dtm: '2026-07-25T13:16:20',
  }));

  test('첫 페이지가 꽉 차면 더 보기 노출 → 클릭 시 before 커서로 이어 붙임(중복 0)', async () => {
    const full = page(1000, PAGE_LIMIT);          // 상한만큼 = 다음 페이지 가능성
    const tail = page(1000 - PAGE_LIMIT, 3);      // 마지막 페이지(상한 미달)
    const calls = mockApi([
      ['GET', 'before=', { status: 200, body: tail }],   // 커서 있는 요청이 먼저 매칭돼야 한다
      ['GET', '/edits', { status: 200, body: full }],
      ['GET', '/companies/40', { status: 200, body: { comp_id: 40, comp_nm: '삼성전자' } }],
    ]);
    initEditsPage();
    await tick();
    assert.match($('comp-title').textContent, /삼성전자 편집 이력/);
    assert.equal($('comp-title').hidden, false);
    assert.equal($('company-link').getAttribute('href'), '/company/40');
    assert.equal($('edit-log').querySelectorAll('li.log-entry').length, PAGE_LIMIT);
    assert.equal($('edits-more').hidden, false, '상한만큼 받았으면 더 보기 노출');
    assert.equal(calls[0].path.includes('before'), false, '첫 요청엔 커서 없음');

    $('edits-more').click();
    await tick();
    const moreCall = calls.find((c) => c.path.includes('before='));
    assert.ok(moreCall, '커서 요청 발생');
    assert.match(moreCall.path, new RegExp('before=' + (1000 - PAGE_LIMIT + 1)), '마지막 행 edit_id 를 커서로 사용');
    assert.equal($('edit-log').querySelectorAll('li.log-entry').length, PAGE_LIMIT + 3, '이어 붙임(교체 아님)');
    assert.equal($('edits-more').hidden, true, '상한 미달 페이지 → 더 보기 감춤');
  });

  test('첫 페이지가 상한 미달이면 더 보기 없음', async () => {
    mockApi([
      ['GET', '/edits', { status: 200, body: page(50, 2) }],
      ['GET', '/companies/40', { status: 200, body: { comp_id: 40, comp_nm: '삼성전자' } }],
    ]);
    initEditsPage();
    await tick();
    assert.equal($('edit-log').querySelectorAll('li.log-entry').length, 2);
    assert.equal($('edits-more').hidden, true);
  });

  test('이력 0건 → 빈 안내(제목은 노출)', async () => {
    mockApi([
      ['GET', '/edits', { status: 200, body: [] }],
      ['GET', '/companies/40', { status: 200, body: { comp_id: 40, comp_nm: '삼성전자' } }],
    ]);
    initEditsPage();
    await tick();
    assert.equal($('edits-empty').hidden, false);
    assert.equal($('edits-more').hidden, true);
  });

  test('미존재 회사(404) → 제목·링크 미노출 + 안내', async () => {
    mockApi([['GET', '/edits', { status: 404, body: { detail: '회사를 찾을 수 없습니다.' } }]]);
    initEditsPage();
    await tick();
    assert.match($('edits-status').textContent, /찾을 수 없어요/);
    assert.equal($('comp-title').hidden, true, '모순 화면 방지');
    assert.equal($('company-link').hidden, true);
  });

  test('페이지를 두 번 이어 받아도 커서가 계속 전진(중복 0) → 마지막 페이지에서 끝 안내·포커스 이동', async () => {
    const p1 = page(1000, PAGE_LIMIT);
    const p2 = page(1000 - PAGE_LIMIT, PAGE_LIMIT);
    const p3 = page(1000 - 2 * PAGE_LIMIT, 2);
    const calls = mockApi([
      ['GET', 'before=', (n) => ({ status: 200, body: n === 1 ? p2 : p3 })],
      ['GET', '/edits', { status: 200, body: p1 }],
      ['GET', '/companies/40', { status: 200, body: { comp_id: 40, comp_nm: '삼성전자' } }],
    ]);
    initEditsPage();
    await tick();
    $('edits-more').click();
    await tick();
    assert.equal($('edits-more').hidden, false, '2페이지도 꽉 찼으면 계속 노출');
    assert.equal($('edits-end').hidden, true);

    $('edits-more').focus();
    $('edits-more').click();
    await tick();
    const cursors = calls.filter((c) => c.path.includes('before=')).map((c) => Number(/before=(\d+)/.exec(c.path)[1]));
    assert.equal(cursors.length, 2);
    assert.ok(cursors[1] < cursors[0], '커서가 더 오래된 쪽으로 전진(같은 페이지 반복 아님)');
    const ids = [...$('edit-log').querySelectorAll('li.log-entry')];
    assert.equal(ids.length, PAGE_LIMIT * 2 + 2, '세 페이지가 모두 누적');
    assert.equal($('edits-more').hidden, true);
    assert.equal($('edits-end').hidden, false, '마지막 페이지 안내');
    assert.equal(globalThis.document.activeElement, $('edits-end'), '사라진 버튼에서 포커스 유실 방지');
  });

  test('첫 로드 실패(500) → 재시도 안내(404 와 구분)', async () => {
    mockApi([['GET', '/edits', { status: 500, body: { detail: 'boom' } }]]);
    initEditsPage();
    await tick();
    assert.match($('edits-status').textContent, /불러오지 못했어요/);
    assert.doesNotMatch($('edits-status').textContent, /찾을 수 없어요/);
    assert.equal($('comp-title').hidden, true);
  });

  test('더 보기 실패 → 버튼 되돌리고 안내(이미 받은 목록 보존)', async () => {
    const full = page(1000, PAGE_LIMIT);
    mockApi([
      ['GET', 'before=', { status: 500, body: { detail: 'x' } }],
      ['GET', '/edits', { status: 200, body: full }],
      ['GET', '/companies/40', { status: 200, body: { comp_id: 40, comp_nm: '삼성전자' } }],
    ]);
    initEditsPage();
    await tick();
    $('edits-more').click();
    await tick();
    assert.equal($('edits-more').hidden, false);
    assert.equal($('edits-more').disabled, false, '재시도 가능하게 되돌림');
    assert.equal($('edits-more').textContent, '더 보기');
    assert.match($('edits-status').textContent, /다음 이력을 불러오지 못했어요/);
    assert.equal($('edit-log').querySelectorAll('li.log-entry').length, PAGE_LIMIT, '기존 목록 보존');
  });

  test('?comp 없으면 회사 검색 픽커 → 선택 시 그 회사 이력으로 이동', async () => {
    globalThis.location.search = '';
    mockApi([['GET', '/companies/search', { status: 200, body: [{ comp_id: 41, comp_nm: 'SK하이닉스' }] }]]);
    initEditsPage();
    await tick();
    assert.equal($('pick-card').hidden, false);
    $('pick-search').value = 'SK';
    $('pick-search').dispatchEvent(new globalThis.document.defaultView.Event('input', { bubbles: true }));
    await tick(320);
    const li = $('pick-results').querySelector('li');
    assert.ok(li);
    assert.equal(li.textContent, 'SK하이닉스');
    li.click();
    assert.equal(globalThis.location.href, '/edits?comp=41');
  });
});
