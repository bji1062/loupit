// web/assets/js/verify.test.js — SC14 재직 인증 화면 순수 로직 단위 테스트(SP-FE).
// DOM 배선(initVerifyPage)은 #verify-card 존재 시에만 실행되므로 import 부작용 0.
// 겹치는 상태코드(401=세션만료|코드불일치, 409=이미인증|이메일선점)를 프로브 컨텍스트로
// 풀어내는 계약이 핵심 — 같은 코드 재시도로 오해 401 을 유발하지 않는지 회귀 고정한다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  CODE_TTL_SEC, RESEND_COOLDOWN_SEC, isValidEmail, isValidCode, countdownText,
  resendWaitSec, sendOutcome, verifyOutcome, renderCompanyItem,
} from './verify.js';

class FakeEl {
  constructor(tag) { this.tagName = tag; this.className = ''; this.textContent = ''; this.children = []; }
  append(...nodes) { this.children.push(...nodes); }
}
const fakeDoc = { createElement: (t) => new FakeEl(t) };
function allText(node) {
  const out = node.textContent ? [node.textContent] : [];
  for (const c of node.children) out.push(...allText(c));
  return out;
}

const e = (s) => new ApiError(s, '/employment/verify');

describe('입력 형식', () => {
  test('회사 이메일 형식', () => {
    assert.equal(isValidEmail('hong@samsung.com'), true);
    assert.equal(isValidEmail(' hong@samsung.com '), true);
    assert.equal(isValidEmail('hong@samsung'), false);
    assert.equal(isValidEmail(''), false);
  });
  test('6자리 코드', () => {
    assert.equal(isValidCode('341110'), true);
    assert.equal(isValidCode('34111'), false);
    assert.equal(isValidCode('34111a'), false);
  });
});

describe('countdownText', () => {
  test('TTL 5분 · m:ss · 만료 안내', () => {
    assert.equal(CODE_TTL_SEC, 300);
    assert.equal(countdownText(300).text, '코드 유효시간 5:00');
    assert.equal(countdownText(5).text, '코드 유효시간 0:05');
    assert.equal(countdownText(0).expired, true);
    assert.match(countdownText(0).text, /인증 코드 받기/);
  });
});

describe('sendOutcome — 코드 발송 실패 분류', () => {
  test('409 → 수동 승인 폴백(오류 아님)', () => {
    const o = sendOutcome(e(409));
    assert.equal(o.kind, 'manual');
    assert.equal(o.msg, '');
  });
  // ── P1-4: 같은 409 인데 뜻이 다르다 — detail 로 갈라야 한다 ──
  test('409 mail_suppressed → 반송 안내(수동 승인 흐름으로 오독 금지)', () => {
    const o = sendOutcome(new ApiError(409, '/employment/verify-code', { detail: 'mail_suppressed' }));
    assert.notEqual(o.kind, 'manual', '반송을 수동 승인으로 오독하면 오지 않을 승인을 기다린다');
    assert.match(o.msg, /반송/);
    assert.doesNotMatch(o.msg, /잠시 후/);
  });
  test('409 manual_required(detail 명시) → 기존 수동 승인 폴백 유지', () => {
    const o = sendOutcome(new ApiError(409, '/employment/verify-code', { detail: 'manual_required' }));
    assert.equal(o.kind, 'manual');
  });
  test('422 → 도메인 불일치 안내', () => { assert.match(sendOutcome(e(422)).msg, /도메인/); });
  test('401 → 이 경로엔 코드 대조가 없으므로 세션 만료로 단정', () => {
    const o = sendOutcome(e(401));
    assert.equal(o.kind, 'session');
    assert.match(o.msg, /로그인/);
  });
  test('429 → 빈도 안내', () => { assert.match(sendOutcome(e(429)).msg, /잦아요/); });
  // ── 적대검토 ③: 엣지가 준 대기 초를 숫자로 노출, 없으면 폴백 ──
  test('429 + Retry-After 20 → "20초 뒤에"', () => {
    const o = sendOutcome(new ApiError(429, '/employment/verify-code', null, 20));
    assert.equal(o.kind, 'error');
    assert.match(o.msg, /20초 뒤에/);
  });
  test('429 + Retry-After 없음 → "잠시 후" 폴백(숫자 없음)', () => {
    assert.match(sendOutcome(e(429)).msg, /잠시 후/);
    assert.doesNotMatch(sendOutcome(e(429)).msg, /\d+초/);
  });
  test('그 외·비 ApiError → 발송 실패', () => {
    assert.match(sendOutcome(e(500)).msg, /발송에 실패/);
    assert.match(sendOutcome(new Error('net')).msg, /발송에 실패/);
  });
});

describe('resendWaitSec — 서버 재전송 쿨다운(무발송·균일 204)을 클라가 먼저 막는다', () => {
  const T = 1_000_000;
  test('발송 이력 없음 → 즉시 가능', () => { assert.equal(resendWaitSec(null, T), 0); });
  test('쿨다운 중 → 남은 초', () => {
    assert.equal(resendWaitSec(T, T + 1000), RESEND_COOLDOWN_SEC - 1);
    assert.equal(resendWaitSec(T, T + 59_000), 1);
  });
  test('쿨다운 경과 → 0', () => {
    assert.equal(resendWaitSec(T, T + 60_000), 0);
    assert.equal(resendWaitSec(T, T + 120_000), 0);
  });
  test('서버 config(mail_resend_cooldown_sec=60)와 같은 값', () => { assert.equal(RESEND_COOLDOWN_SEC, 60); });
});

describe('verifyOutcome — 401 의 두 뜻을 프로브로 구분', () => {
  test('프로브 alive → 코드 불일치(같은 코드 재입력 재시도 허용)', () => {
    const o = verifyOutcome(e(401), { probe: 'alive' });
    assert.equal(o.kind, 'mismatch');
    assert.match(o.msg, /일치하지 않아요/);
    assert.equal(o.retryCode, true);
    assert.equal(o.clearCode, false);
  });
  test('프로브 dead(명시적 401) → 세션 만료 안내(로그인 유도, 재시도 무의미)', () => {
    const o = verifyOutcome(e(401), { probe: 'dead' });
    assert.equal(o.kind, 'session');
    assert.match(o.msg, /로그인이 만료/);
    assert.equal(o.retryCode, false);
  });
  test('회귀: 프로브 unknown(타임아웃·5xx·네트워크)은 세션 만료로 단정하지 않는다 — 멀쩡한 세션을 /login 으로 축출 금지', () => {
    const o = verifyOutcome(e(401), { probe: 'unknown' });
    assert.equal(o.kind, 'mismatch', '프로브 실패는 세션 사망의 증거가 아니다');
    assert.equal(o.retryCode, true, '화면을 유지해 재입력할 수 있어야 함');
  });
  test('프로브 컨텍스트 미제공 시 기본값은 alive(=코드 불일치)', () => {
    assert.equal(verifyOutcome(e(401)).kind, 'mismatch');
  });
});

describe('verifyOutcome — 409 의 두 뜻을 프로브로 구분(UX 폴리시 2026-07-25)', () => {
  test('내 인증 목록에 그 회사 있음 → 이미 인증(성공 상태 안내)', () => {
    const o = verifyOutcome(e(409), { probe: 'alive', alreadyVerified: true });
    assert.equal(o.kind, 'already_verified');
    assert.match(o.msg, /이미 이 회사 재직 인증/);
  });
  test('없음 → 이 회사 이메일이 이미 사용됨(다른 이메일·수동 승인 유도)', () => {
    const o = verifyOutcome(e(409), { probe: 'alive', alreadyVerified: false });
    assert.equal(o.kind, 'email_in_use');
    assert.match(o.msg, /다른 회사 이메일/);
    assert.match(o.msg, /수동 승인/);
  });
  test('회귀: 이메일 충돌의 주체를 단정하지 않는다 — uq_employ_email 은 전역 유니크라 내 다른 인증과도 부딪힌다(@samsung.com 으로 삼성전자 인증 후 삼성SDI 시도)', () => {
    const o = verifyOutcome(e(409), { probe: 'alive', alreadyVerified: false });
    assert.doesNotMatch(o.msg, /다른 계정/, '"다른 계정이 썼다"고 단정하면 자기 충돌 사용자에게 거짓말이 된다');
  });
  test('회귀: 409 뒤 같은 코드 재시도를 막는다 — 코드는 이미 소비돼 재시도 시 오해 401(코드 불일치)이 뜬다', () => {
    for (const alreadyVerified of [true, false]) {
      const o = verifyOutcome(e(409), { probe: 'alive', alreadyVerified });
      assert.equal(o.retryCode, false, '코드 입력 단계를 닫아 재시도를 막아야 함');
      assert.equal(o.clearCode, true, '소비된 코드를 입력칸에서 비워야 함');
    }
  });
});

describe('verifyOutcome — 만료·시도초과·기타', () => {
  test('410 → 만료(코드 비움·재시도 차단)', () => {
    const o = verifyOutcome(e(410), { probe: 'alive' });
    assert.equal(o.kind, 'expired');
    assert.equal(o.clearCode, true);
    assert.equal(o.retryCode, false);
    assert.match(o.msg, /인증 코드 받기/);
  });
  test('429 → 시도 초과(새 코드 유도)', () => {
    const o = verifyOutcome(e(429), { probe: 'alive' });
    assert.equal(o.kind, 'throttled');
    assert.equal(o.clearCode, true);
    assert.equal(o.retryCode, false);
  });
  test('500·비 ApiError → 일반 실패(재시도 허용)', () => {
    assert.equal(verifyOutcome(e(500), { probe: 'alive' }).kind, 'error');
    const o = verifyOutcome(new Error('net'));
    assert.equal(o.kind, 'error');
    assert.equal(o.retryCode, true);
  });
  test('메시지에 코드 원문·이메일을 반향하지 않는다(NFR31)', () => {
    const err = new ApiError(401, '/employment/verify', { detail: 'code 341110 hong@samsung.com' });
    for (const ctx of [{ probe: 'alive' }, { probe: 'dead' }, { probe: 'unknown' }]) {
      assert.doesNotMatch(verifyOutcome(err, ctx).msg, /341110|hong@samsung\.com/);
    }
  });
});

describe('renderCompanyItem — textContent-only(XSS 안전)', () => {
  test('회사명·업종이 텍스트로만 삽입', () => {
    const evil = '<img src=x onerror=alert(1)>';
    const li = renderCompanyItem(fakeDoc, { comp_id: 1, comp_nm: evil, industry_nm: '<b>반도체</b>' });
    const texts = allText(li);
    assert.ok(texts.includes(evil), '원문이 textContent 로 보존(=innerHTML 파싱 아님)');
    assert.ok(texts.includes('<b>반도체</b>'));
    assert.equal(li.tabIndex, 0); // 키보드 선택 가능
  });
  test('업종 없으면 업종 노드 생략', () => {
    const li = renderCompanyItem(fakeDoc, { comp_id: 1, comp_nm: '삼성전자' });
    assert.equal(li.children.length, 0);
  });
});
