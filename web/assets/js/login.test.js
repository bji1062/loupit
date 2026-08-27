// web/assets/js/login.test.js — SC14 로그인 화면 순수 로직 단위 테스트(SP-FE).
// DOM 배선(initLoginPage)은 #step-email 존재 시에만 실행되므로 node:test 환경에서 import 부작용 0
// (jsdom 미설치 트리에서도 그대로 돈다 — 자족 테스트).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  CODE_TTL_SEC, isValidEmail, isValidCode, countdownText, messageFor, doneSubText,
  throttleMessage, safeNext, nextFromSearch, doneLinkFor,
} from './login.js';

describe('isValidEmail', () => {
  test('정상 이메일 → true', () => {
    assert.equal(isValidEmail('you@example.com'), true);
    assert.equal(isValidEmail('hong.gil+tag@corp.co.kr'), true);
  });
  test('앞뒤 공백은 트림 후 판정', () => { assert.equal(isValidEmail('  you@example.com  '), true); });
  test('@·점 없음·공백 포함·빈값 → false', () => {
    assert.equal(isValidEmail('you.example.com'), false);
    assert.equal(isValidEmail('you@example'), false);
    assert.equal(isValidEmail('you @example.com'), false);
    assert.equal(isValidEmail(''), false);
    assert.equal(isValidEmail(null), false);
    assert.equal(isValidEmail(undefined), false);
  });
});

describe('isValidCode', () => {
  test('6자리 숫자만 통과(트림 허용)', () => {
    assert.equal(isValidCode('123456'), true);
    assert.equal(isValidCode(' 123456 '), true);
  });
  test('길이·문자 위반 → false', () => {
    assert.equal(isValidCode('12345'), false);
    assert.equal(isValidCode('1234567'), false);
    assert.equal(isValidCode('12345a'), false);
    assert.equal(isValidCode(''), false);
    assert.equal(isValidCode(null), false);
  });
});

describe('countdownText', () => {
  test('서버 코드 TTL(5분)과 동일한 시작값', () => { assert.equal(CODE_TTL_SEC, 300); });
  test('남은 초 → m:ss', () => {
    assert.deepEqual(countdownText(300), { text: '코드 유효시간 5:00', expired: false });
    assert.equal(countdownText(61).text, '코드 유효시간 1:01');
    assert.equal(countdownText(9).text, '코드 유효시간 0:09');
  });
  test('0·음수 → 만료 안내 + expired', () => {
    const z = countdownText(0);
    assert.equal(z.expired, true);
    assert.match(z.text, /만료/);
    assert.equal(countdownText(-5).expired, true);
  });
});

describe('messageFor', () => {
  const e = (s) => new ApiError(s, '/x');
  test('발송 단계: 422 형식·429 빈도', () => {
    assert.match(messageFor(e(422), 'send'), /이메일 형식/);
    assert.match(messageFor(e(429), 'send'), /잦아요/);
  });
  test('로그인 단계: 401 불일치·410 만료·429 시도초과·422 형식', () => {
    assert.match(messageFor(e(401), 'login'), /일치하지 않아요/);
    assert.match(messageFor(e(410), 'login'), /만료/);
    assert.match(messageFor(e(429), 'login'), /너무 많아요/);
    assert.match(messageFor(e(422), 'login'), /6자리/);
  });
  test('로그인 401 은 세션이 아니라 코드 불일치로 안내한다(로그인 라우트는 세션 무관)', () => {
    assert.doesNotMatch(messageFor(e(401), 'login'), /로그인이 만료|다시 로그인/);
  });
  test('미분류 상태코드 → 일반 안내', () => { assert.match(messageFor(e(500), 'login'), /문제가 발생/); });
  test('비 ApiError(네트워크) → 네트워크 안내', () => {
    assert.match(messageFor(new Error('net'), 'login'), /네트워크/);
  });
  test('원문(코드·이메일)을 메시지에 반향하지 않는다(NFR31)', () => {
    const err = new ApiError(401, '/members/login', { detail: 'code 123456 for a@b.com' });
    const msg = messageFor(err, 'login');
    assert.doesNotMatch(msg, /123456|a@b\.com/);
  });

  // ── 적대검토 ③: 엣지 429 는 대기 초를 숫자로, 앱 429 는 그대로 ──
  test('발송 429 + Retry-After 20 → 초를 숫자로 노출', () => {
    const err = new ApiError(429, '/members/login-code', null, 20);
    assert.match(messageFor(err, 'send'), /20초 뒤에/);
  });
  // ── P1-4: 반송 이력 주소(409 mail_suppressed) ──
  test('발송 409 mail_suppressed → 반송 안내 + 다른 주소 유도', () => {
    const err = new ApiError(409, '/members/login-code', { detail: 'mail_suppressed' });
    const msg = messageFor(err, 'send');
    assert.match(msg, /반송/, '반송 사실을 알려야 한다');
    assert.match(msg, /다른 이메일|다른 주소/, '해결 행동(다른 주소)을 제시해야 한다');
    // **"잠시 후 다시" 는 거짓 안내다** — 반송 주소는 기다린다고 풀리지 않는다.
    assert.doesNotMatch(msg, /잠시 후/);
  });
  test('발송 409 이지만 다른 detail → 일반 문구(과잉 단정 금지)', () => {
    const msg = messageFor(new ApiError(409, '/members/login-code', { detail: 'other' }), 'send');
    assert.doesNotMatch(msg, /반송/);
  });

  test('발송 429 + Retry-After 없음 → 기존 "잠시 후" 폴백', () => {
    assert.match(messageFor(e(429), 'send'), /잠시 후/);
    assert.doesNotMatch(messageFor(e(429), 'send'), /\d+초/);
  });
  test('로그인 단계 429(앱 시도 상한)는 retryAfter 가 있어도 초를 붙이지 않는다', () => {
    // 이 429 는 "기다리면 풀린다"가 아니라 "새 코드를 받아야 한다"라 뜻이 다르다.
    // 엣지가 붙인 값이 어쩌다 실려도 안내가 오염되면 안 된다.
    const err = new ApiError(429, '/members/login', null, 20);
    assert.match(messageFor(err, 'login'), /새 코드/);
    assert.doesNotMatch(messageFor(err, 'login'), /\d+초/);
  });
});

describe('throttleMessage(③ 대기 초 안내)', () => {
  test('양수 → "N초 뒤에"', () => { assert.equal(throttleMessage(20), '요청이 너무 잦아요. 20초 뒤에 다시 시도해주세요.'); });
  test('null·undefined·0·음수·NaN → "잠시 후" 폴백', () => {
    for (const v of [null, undefined, 0, -1, NaN, Infinity, '20']) {
      assert.match(throttleMessage(v), /잠시 후/, `v=${String(v)}`);
      assert.doesNotMatch(throttleMessage(v), /\d+초/, `v=${String(v)}`);
    }
  });
});

describe('doneSubText', () => {
  test('신규 계정 안내', () => { assert.match(doneSubText(true), /새 계정/); });
  test('재방문 안내', () => { assert.match(doneSubText(false), /다시 오신/); });
});

// ── SC15 커뮤니티 진입(T-14.6.6): `?next=` 는 same-origin 절대 경로만 ──
// 열린 리다이렉트가 되는 순간 로그인 화면이 피싱 도구가 된다. 허용 규칙은 **화이트리스트**다:
// `/` 로 시작 · `//` 로 시작하지 않음 · `http`·`javascript:`·`\` 를 포함하지 않음.
describe('safeNext — next 허용/거부 매트릭스', () => {
  test('same-origin 절대 경로 → 그대로', () => {
    assert.equal(safeNext('/community/write'), '/community/write');
    assert.equal(safeNext('/community/12'), '/community/12');
    assert.equal(safeNext('/community/?category=free&sort=likes'), '/community/?category=free&sort=likes');
  });
  test('프로토콜 상대(//evil)·절대 URL·javascript:·백슬래시 → null', () => {
    for (const v of ['//evil', '//evil.com/x', 'https://evil', 'http://evil', '/x?u=https://evil',
      'javascript:alert(1)', '/a\\b', '\\\\evil', '/javascript:alert(1)']) {
      assert.equal(safeNext(v), null, `v=${v}`);
    }
  });
  test('상대 경로·빈값·비문자열·제어문자·공백 → null', () => {
    for (const v of ['community/write', '', null, undefined, 12, '/a\nb', '/a b', '/a ']) {
      assert.equal(safeNext(v), null, `v=${String(v)}`);
    }
  });
});

describe('nextFromSearch / doneLinkFor', () => {
  test('?next= 를 읽어 검증한다(디코딩 포함)', () => {
    assert.equal(nextFromSearch('?next=%2Fcommunity%2Fwrite'), '/community/write');
    assert.equal(nextFromSearch('?next=//evil'), null);
    assert.equal(nextFromSearch(''), null);
    assert.equal(nextFromSearch(undefined), null);
  });
  test('next 있으면 "돌아가기"(next 로), 없으면 기존 마이페이지 링크', () => {
    assert.deepEqual(doneLinkFor('/community/write'), { href: '/community/write', label: '돌아가기' });
    assert.deepEqual(doneLinkFor(null), { href: '/mypage', label: '마이페이지로 가기' });
  });
});
