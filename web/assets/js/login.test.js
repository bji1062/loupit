// web/assets/js/login.test.js — SC14 로그인 화면 순수 로직 단위 테스트(SP-FE).
// DOM 배선(initLoginPage)은 #step-email 존재 시에만 실행되므로 node:test 환경에서 import 부작용 0
// (jsdom 미설치 트리에서도 그대로 돈다 — 자족 테스트).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  CODE_TTL_SEC, isValidEmail, isValidCode, countdownText, messageFor, doneSubText,
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
});

describe('doneSubText', () => {
  test('신규 계정 안내', () => { assert.match(doneSubText(true), /새 계정/); });
  test('재방문 안내', () => { assert.match(doneSubText(false), /다시 오신/); });
});
