// web/assets/js/edit.test.js — SC14 복지 편집 폼 순수 로직 단위 테스트(SP-FE).
// DOM 배선(initEditPage)은 #edit-card 존재 시에만 실행되므로 node:test 환경에서 import 부작용 0.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  CATEGORY_LABELS, parseAmount, validateForm, buildPayload, fmtAmount, benefitErrorMessage, pickCompany,
} from './edit.js';

describe('parseAmount', () => {
  test('정수 문자열 → 정수', () => { assert.equal(parseAmount('220'), 220); assert.equal(parseAmount('0'), 0); });
  test('공백 트림', () => { assert.equal(parseAmount(' 5 '), 5); });
  test('빈칸·비숫자·음수·소수 → null', () => {
    assert.equal(parseAmount(''), null);
    assert.equal(parseAmount('abc'), null);
    assert.equal(parseAmount('-3'), null);
    assert.equal(parseAmount('3.5'), null);
    assert.equal(parseAmount(null), null);
    assert.equal(parseAmount(undefined), null);
  });
});

describe('validateForm', () => {
  const okCreate = { benefit_cd: 'meal', benefit_nm: '식대', benefit_ctgr_cd: 'compensation', benefit_amt: '220', qual: false };
  test('정상 등록 → null', () => { assert.equal(validateForm('create', okCreate), null); });
  test('이름 공백 → 오류', () => { assert.match(validateForm('create', { ...okCreate, benefit_nm: '  ' }), /이름/); });
  test('잘못된 복지 코드 → 오류', () => {
    assert.match(validateForm('create', { ...okCreate, benefit_cd: 'M' }), /코드/); // 1자·대문자
    assert.match(validateForm('create', { ...okCreate, benefit_cd: '9meal' }), /코드/); // 첫 글자 숫자
  });
  test('카테고리 미선택 → 오류', () => { assert.match(validateForm('create', { ...okCreate, benefit_ctgr_cd: '' }), /카테고리/); });
  test('비정성인데 금액이 비숫자 → 오류', () => { assert.match(validateForm('create', { ...okCreate, benefit_amt: 'x' }), /금액/); });
  test('정성이면 금액 검증 생략 → null', () => { assert.equal(validateForm('create', { ...okCreate, qual: true, benefit_amt: 'x' }), null); });
  test('수정은 코드·카테고리 불검증(base_dtm 만) → null', () => {
    assert.equal(validateForm('update', { benefit_nm: '식대', benefit_amt: '300', qual: false }), null);
  });
});

describe('buildPayload', () => {
  test('등록: 코드 소문자·카테고리 포함, base_dtm 없음', () => {
    const b = buildPayload('create', { benefit_cd: ' MEAL ', benefit_nm: ' 식대 ', benefit_ctgr_cd: 'compensation', benefit_amt: '220', qual: false, edit_note: '추가' });
    assert.deepEqual(b, { benefit_nm: '식대', qual_yn: false, benefit_amt: 220, edit_note: '추가', benefit_cd: 'meal', benefit_ctgr_cd: 'compensation' });
  });
  test('정성: benefit_amt 키 자체 생략, qual_yn true', () => {
    const b = buildPayload('create', { benefit_cd: 'gym', benefit_nm: '헬스', benefit_ctgr_cd: 'health', benefit_amt: '999', qual: true });
    assert.equal(b.qual_yn, true);
    assert.equal('benefit_amt' in b, false);
  });
  test('금액 미기재(빈칸)면 benefit_amt 생략(none)', () => {
    const b = buildPayload('create', { benefit_cd: 'meal', benefit_nm: '식대', benefit_ctgr_cd: 'compensation', benefit_amt: '', qual: false });
    assert.equal('benefit_amt' in b, false);
  });
  test('수정: base_dtm 포함, 코드·카테고리 제외', () => {
    const b = buildPayload('update', { benefit_nm: '식대', benefit_amt: '300', qual: false, base_dtm: '2026-01-01T00:00:01:abc' });
    assert.equal(b.base_dtm, '2026-01-01T00:00:01:abc');
    assert.equal('benefit_cd' in b, false);
    assert.equal('benefit_ctgr_cd' in b, false);
    assert.equal(b.benefit_amt, 300);
  });
  test('빈 비고·사유는 생략', () => {
    const b = buildPayload('update', { benefit_nm: 'n', qual: false, note_ctnt: '   ', edit_note: '', base_dtm: 'x' });
    assert.equal('note_ctnt' in b, false);
    assert.equal('edit_note' in b, false);
  });
});

describe('fmtAmount', () => {
  test('정성 → 정성', () => { assert.equal(fmtAmount({ qual_yn: true, benefit_amt: 5 }), '정성'); });
  test('금액 null → 미기재', () => { assert.equal(fmtAmount({ qual_yn: false, benefit_amt: null }), '금액 미기재'); });
  test('금액 → 천단위 콤마+만원', () => { assert.equal(fmtAmount({ qual_yn: false, benefit_amt: 1200 }), '1,200만원'); });
});

describe('benefitErrorMessage', () => {
  const e = (s) => new ApiError(s, '/x');
  test('401 → 로그인 신호', () => { assert.equal(benefitErrorMessage(e(401), 'create'), '__login__'); });
  test('403 → 재직 안내', () => { assert.match(benefitErrorMessage(e(403), 'create'), /재직/); });
  test('409 등록 → 코드 중복 안내', () => { assert.match(benefitErrorMessage(e(409), 'create'), /등록된 복지 코드/); });
  test('409 수정 → 선점 신호', () => { assert.equal(benefitErrorMessage(e(409), 'update'), '__conflict__'); });
  test('429 → 한도 안내', () => { assert.match(benefitErrorMessage(e(429), 'create'), /초과/); });
  test('422 → 정성/금액 안내', () => { assert.match(benefitErrorMessage(e(422), 'create'), /정성|금액/); });
  test('404 → 목록 새로고침 안내', () => { assert.match(benefitErrorMessage(e(404), 'update'), /찾을 수 없|새로고침/); });
  test('비 ApiError → 일반 실패', () => { assert.match(benefitErrorMessage(new Error('net'), 'create'), /실패/); });
});

describe('CATEGORY_LABELS', () => {
  test('9종 카테고리', () => { assert.equal(Object.keys(CATEGORY_LABELS).length, 9); });
});

describe('pickCompany', () => {
  const A = { comp_id: 10, comp_nm: '삼성전자' };
  const B = { comp_id: 20, comp_nm: 'SK하이닉스' };
  test('?comp 일치 → 그 회사 자동 선택(다회사여도)', () => {
    assert.deepEqual(pickCompany([A, B], 20), { mode: 'single', company: B });
  });
  test('?comp 없고 1곳 → 자동 선택', () => {
    assert.deepEqual(pickCompany([A], null), { mode: 'single', company: A });
  });
  test('?comp 없고 여러 곳 → select(multi)', () => {
    assert.deepEqual(pickCompany([A, B], null), { mode: 'multi', company: null });
  });
  test('?comp 불일치(미보유 회사) → multi 로 폴백(자동 선택 안 함)', () => {
    assert.deepEqual(pickCompany([A, B], 999), { mode: 'multi', company: null });
  });
  test('빈 목록 → multi', () => {
    assert.deepEqual(pickCompany([], null), { mode: 'multi', company: null });
  });
});
