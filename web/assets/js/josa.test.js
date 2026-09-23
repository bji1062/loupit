// web/assets/js/josa.test.js — 회사 이름 조사·숫자 표기(이직 계산기 문장 재료).
import test from 'node:test';
import assert from 'node:assert/strict';
import { finalSound, josa, withJosa, fmt, fmtSigned, fmtPct } from './josa.js';

test('JOSA-1: 한글 받침', () => {
  assert.equal(withJosa('카카오', '이/가'), '카카오가');
  assert.equal(withJosa('삼성전자', '은/는'), '삼성전자는');
  assert.equal(withJosa('현대건설', '은/는'), '현대건설은');
  assert.equal(withJosa('현대건설', '로/으로'), '현대건설로', 'ㄹ 받침은 로');
  assert.equal(withJosa('셀트리온', '로/으로'), '셀트리온으로');
  assert.equal(withJosa('카카오', '와/과'), '카카오와');
  assert.equal(withJosa('기아', '을/를'), '기아를');
});

test('JOSA-2: 영문 이름은 읽는 소리로(등록 회사 실측)', () => {
  assert.equal(withJosa('NAVER', '은/는'), 'NAVER는', '네이버');
  assert.equal(withJosa('HMM', '이/가'), 'HMM이', '에이치엠엠');
  assert.equal(withJosa('KT', '은/는'), 'KT는');
  assert.equal(withJosa('S-Oil', '로/으로'), 'S-Oil로', '에스오일 — ㄹ');
  assert.equal(withJosa('LS ELECTRIC', '이/가'), 'LS ELECTRIC이', '일렉트릭');
  assert.equal(withJosa('JYP Ent.', '은/는'), 'JYP Ent.는', '엔터');
  assert.equal(withJosa('엔씨소프트(NC)', '은/는'), '엔씨소프트(NC)는', '괄호 밖 이름을 따른다');
  assert.equal(withJosa('LIG디펜스앤에어로스페이스(구 LIG넥스원)', '이/가'), 'LIG디펜스앤에어로스페이스(구 LIG넥스원)가');
  assert.equal(withJosa('삼성E&A', '은/는'), '삼성E&A는');
  assert.equal(finalSound(''), '');
  assert.equal(josa('카카오', '없는조사'), '');
});

test('JOSA-3: 숫자 — 유니코드 빼기·천 단위', () => {
  assert.equal(fmt(-2211), '−2,211');
  assert.equal(fmt(9950.4), '9,950');
  assert.equal(fmtSigned(900), '+900');
  assert.equal(fmtSigned(-932), '−932');
  assert.equal(fmtSigned(0), '0');
  assert.equal(fmtPct(0.15), '+15.0%');
  assert.equal(fmtPct(-0.2222), '−22.2%');
  assert.equal(fmtPct(null), '');
});
