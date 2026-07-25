// web/assets/js/mypage.test.js — SC14 마이페이지 순수 로직 + 렌더 XSS 안전 단위 테스트(SP-FE).
// DOM 배선(initMypage)은 #profile 존재 시에만 실행되므로 import 부작용 0. jsdom 없이
// 최소 document 스텁으로 renderVrfItem 의 textContent-only 삽입을 검증한다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  validateNickname, nickErrorMessage, fmtDate, statusLabel, renderVrfItem,
} from './mypage.js';

// ── 최소 in-memory document 스텁 ─────────────────────────────────────────────
class FakeEl {
  constructor(tag) { this.tagName = tag; this.className = ''; this.textContent = ''; this.href = ''; this.children = []; }
  append(...nodes) { this.children.push(...nodes); }
}
const fakeDoc = { createElement: (t) => new FakeEl(t) };
function allText(node) {
  if (typeof node === 'string') return [node];
  const out = node.textContent ? [node.textContent] : [];
  for (const c of node.children) out.push(...allText(c));
  return out;
}

describe('validateNickname', () => {
  test('정상(한글·영문·숫자·_-·공백 2~20자) → null', () => {
    assert.equal(validateNickname('직장인-378575'), null);
    assert.equal(validateNickname('gil dong_2'), null);
    assert.equal(validateNickname('가나'), null);
  });
  test('앞뒤 공백은 트림 후 판정', () => { assert.equal(validateNickname('  닉네임  '), null); });
  test('길이 위반 → 형식 안내', () => {
    assert.match(validateNickname('a'), /2~20자/);
    assert.match(validateNickname('가'.repeat(21)), /2~20자/);
    assert.match(validateNickname(''), /2~20자/);
    assert.match(validateNickname(null), /2~20자/);
  });
  test('허용 외 문자 → 형식 안내', () => {
    assert.match(validateNickname('닉네임!'), /2~20자/);
    assert.match(validateNickname('<script>'), /2~20자/);
    assert.match(validateNickname('닉@네임'), /2~20자/);
  });
  test('금칙어 → 사용 불가 안내(대소문자·공백 우회 차단)', () => {
    assert.match(validateNickname('관리자'), /사용할 수 없는/);
    assert.match(validateNickname('Admin'), /사용할 수 없는/);
    assert.match(validateNickname('ADMINISTRATOR'), /사용할 수 없는/);
    assert.match(validateNickname('루 핏'), /사용할 수 없는/);   // 공백 제거 후 '루핏'
    assert.match(validateNickname('우리 운영자'), /사용할 수 없는/);
  });
});

describe('nickErrorMessage', () => {
  const e = (s) => new ApiError(s, '/members/me');
  test('409 → 중복 안내', () => { assert.match(nickErrorMessage(e(409)), /이미 사용 중/); });
  test('422 → 형식·금칙어 안내', () => { assert.match(nickErrorMessage(e(422)), /형식·금칙어/); });
  test('그 외·비 ApiError → 일반 실패', () => {
    assert.match(nickErrorMessage(e(500)), /실패/);
    assert.match(nickErrorMessage(new Error('net')), /실패/);
  });
});

describe('fmtDate', () => {
  test('ISO → YYYY-MM-DD', () => { assert.equal(fmtDate('2027-07-25T13:14:43'), '2027-07-25'); });
  test('null·undefined → 빈 문자열', () => {
    assert.equal(fmtDate(null), '');
    assert.equal(fmtDate(undefined), '');
  });
});

describe('statusLabel', () => {
  test('active → 정상', () => { assert.equal(statusLabel('active'), '정상'); });
  test('그 외는 원문, 빈값은 정상', () => {
    assert.equal(statusLabel('withdrawn'), 'withdrawn');
    assert.equal(statusLabel(undefined), '정상');
  });
});

describe('renderVrfItem — textContent-only(XSS 안전)', () => {
  test('회사명·만료일·편집 링크 구성', () => {
    const li = renderVrfItem(fakeDoc, { comp_id: 40, comp_nm: '삼성전자', expires_dtm: '2027-07-25T13:14:43' });
    const texts = allText(li);
    assert.ok(texts.includes('삼성전자'));
    assert.ok(texts.includes('만료 2027-07-25'));
    const link = li.children.find((c) => c.tagName === 'a');
    assert.equal(link.href, '/edit?comp=40');
    assert.match(link.textContent, /복지 편집/);
  });
  test('만료일 없으면 무기한', () => {
    const li = renderVrfItem(fakeDoc, { comp_id: 1, comp_nm: 'A', expires_dtm: null });
    assert.ok(allText(li).includes('무기한'));
  });
  test('회사명 없으면 회사 ID 폴백', () => {
    const li = renderVrfItem(fakeDoc, { comp_id: 7, expires_dtm: null });
    assert.ok(allText(li).includes('회사 7'));
  });
  test('악성 회사명이 텍스트로만 삽입(스크립트 미실행)', () => {
    const evil = '<img src=x onerror=alert(1)>';
    const li = renderVrfItem(fakeDoc, { comp_id: 2, comp_nm: evil, expires_dtm: null });
    assert.ok(allText(li).includes(evil), '원문이 textContent 로 보존되어야 함(=innerHTML 파싱 아님)');
  });
  test('comp_id 는 링크에 인코딩되어 들어간다', () => {
    const li = renderVrfItem(fakeDoc, { comp_id: 'a b&c', comp_nm: 'X', expires_dtm: null });
    const link = li.children.find((c) => c.tagName === 'a');
    assert.equal(link.href, '/edit?comp=a%20b%26c');
  });
});
