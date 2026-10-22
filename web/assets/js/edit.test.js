// web/assets/js/edit.test.js — SC14 복지 편집 폼 순수 로직 단위 테스트(SP-FE).
// DOM 배선(initEditPage)은 #edit-card 존재 시에만 실행되므로 node:test 환경에서 import 부작용 0.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { ApiError } from './api.js';
import {
  CATEGORY_LABELS, parseAmount, validateForm, buildPayload, fmtAmount, benefitErrorMessage, pickCompany, pickBenefit,
  filterCodes, requestSentMessage, requestStatusView, pendingUpdateIds, CODE_RESULT_LIMIT,
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
  // 2026-10-21: 새 항목은 표준 항목을 고르거나(benefit_cd) 「찾는 항목이 없어요」(no_code)를 눌러야 한다. 영문 코드·카테고리 입력은 없다.
  const okCreate = { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: '220', qual: false };
  test('정상 등록(항목 고름) → null', () => { assert.equal(validateForm('create', okCreate), null); });
  test('항목도 안 고르고 「없어요」도 안 눌렀으면 → 오류', () => {
    assert.match(validateForm('create', { ...okCreate, benefit_cd: '' }), /목록에서 골라/);
    assert.match(validateForm('create', { ...okCreate, benefit_cd: undefined }), /목록에서 골라/);
  });
  test('「찾는 항목이 없어요」(코드 없음)면 이름만으로 통과 → null', () => {
    assert.equal(validateForm('create', { ...okCreate, benefit_cd: '', no_code: true }), null);
  });
  test('이름 공백 → 오류', () => { assert.match(validateForm('create', { ...okCreate, benefit_nm: '  ' }), /이름/); });
  test('비정성인데 금액이 비숫자 → 오류', () => { assert.match(validateForm('create', { ...okCreate, benefit_amt: 'x' }), /금액/); });
  test('정성이면 금액 검증 생략 → null', () => { assert.equal(validateForm('create', { ...okCreate, qual: true, benefit_amt: 'x' }), null); });
  test('수정은 항목 선택 불필요(대상이 정해져 있다) → null', () => {
    assert.equal(validateForm('update', { benefit_nm: '식대', benefit_amt: '300', qual: false }), null);
  });
});

describe('buildPayload', () => {
  test('등록: 고른 코드는 소문자로, 카테고리는 보내지 않는다, base_dtm 없음', () => {
    const b = buildPayload('create', { benefit_cd: ' MEAL ', benefit_nm: ' 식대 ', benefit_amt: '220', qual: false, edit_note: '추가' });
    assert.deepEqual(b, { benefit_nm: '식대', qual_yn: false, benefit_amt: 220, edit_note: '추가', benefit_cd: 'meal' });
    assert.equal('benefit_ctgr_cd' in b, false);
  });
  test('코드 없는 요청(목록에 없음): benefit_cd 키 자체가 없다', () => {
    const b = buildPayload('create', { benefit_cd: '', no_code: true, benefit_nm: '특이한 복지', qual: true });
    assert.deepEqual(b, { benefit_nm: '특이한 복지', qual_yn: true });
    assert.equal('benefit_cd' in b, false);
  });
  test('정성: benefit_amt 키 자체 생략, qual_yn true', () => {
    const b = buildPayload('create', { benefit_cd: 'gym', benefit_nm: '헬스', benefit_amt: '999', qual: true });
    assert.equal(b.qual_yn, true);
    assert.equal('benefit_amt' in b, false);
  });
  test('금액 미기재(빈칸)면 benefit_amt 생략(none)', () => {
    const b = buildPayload('create', { benefit_cd: 'meal', benefit_nm: '식대', benefit_amt: '', qual: false });
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
  test('409 등록 → 이미 있는 항목(수정 요청 안내)', () => { assert.match(benefitErrorMessage(e(409), 'create'), /이미 이 회사에 있는 항목/); });
  test('409 수정 → 선점 신호', () => { assert.equal(benefitErrorMessage(e(409), 'update'), '__conflict__'); });
  test('409 + 서버 문구에 「대기」 → 확인 대기 중 안내(등록·수정 모두, 선점 신호가 아니다)', () => {
    const waiting = new ApiError(409, '/x', { detail: '이미 확인 대기 중인 요청이 있습니다.' });
    assert.match(benefitErrorMessage(waiting, 'create'), /확인 대기 중/);
    assert.match(benefitErrorMessage(waiting, 'update'), /확인 대기 중/);
  });
  test('429 → 한도 안내(요청 수)', () => { assert.match(benefitErrorMessage(e(429), 'create'), /요청 수를 초과/); });
  test('422 → 정성/금액 안내', () => { assert.match(benefitErrorMessage(e(422), 'create'), /정성|금액/); });
  test('404 → 목록 새로고침 안내', () => { assert.match(benefitErrorMessage(e(404), 'update'), /찾을 수 없|새로고침/); });
  test('비 ApiError → 일반 실패', () => { assert.match(benefitErrorMessage(new Error('net'), 'create'), /보내지 못했어요/); });
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

describe('pickBenefit — 회사 페이지 원장이 지목한 항목', () => {
  const list = [
    { benefit_id: 1, benefit_cd: 'meal', benefit_nm: '구내식당' },
    { benefit_id: 2, benefit_cd: 'welfare_point', benefit_nm: '복지포인트' },
  ];
  test('코드가 맞으면 그 행', () => { assert.equal(pickBenefit(list, 'welfare_point').benefit_id, 2); });
  test('대소문자 무시(주소창에서 대문자로 와도 찾는다)', () => { assert.equal(pickBenefit(list, 'MEAL').benefit_id, 1); });
  test('없는 코드·빈 값·목록 없음 → null(목록만 보여 준다)', () => {
    assert.equal(pickBenefit(list, 'nope'), null);
    assert.equal(pickBenefit(list, ''), null);
    assert.equal(pickBenefit(list, null), null);
    assert.equal(pickBenefit(null, 'meal'), null);
  });
  test('코드 없는 행이 섞여 있어도 죽지 않는다', () => {
    assert.equal(pickBenefit([{ benefit_id: 9 }, ...list], 'meal').benefit_id, 1);
  });
});

describe('requestSentMessage — 제출 뒤 문구(걸리는 시간을 약속하지 않는다)', () => {
  test('등록 요청', () => {
    assert.equal(requestSentMessage('create'), '확인 요청을 보냈어요. 운영자가 확인하면 사이트에 반영돼요.');
  });
  test('수정 요청', () => {
    assert.equal(requestSentMessage('update'), '수정 요청을 보냈어요. 운영자가 확인하면 반영돼요.');
  });
  test('시간 약속(곧·바로·시간 안에·일 이내)이 없다', () => {
    for (const m of ['create', 'update']) assert.doesNotMatch(requestSentMessage(m), /곧|바로|시간 안|일 이내|분 안/);
  });
});

describe('filterCodes — 표준 항목 검색(이름·별칭)', () => {
  const CODES = [
    { code: 'meal', label: '구내식당·식대 지원', ctgr: 'compensation', aliases: ['사내식당', '점심 제공'] },
    { code: 'welfare_point', label: '복지포인트', ctgr: 'compensation', aliases: ['선택적 복지', 'Welfare Point'] },
    { code: 'commute_subsidy', label: '통근버스·출퇴근 지원', ctgr: 'compensation', aliases: ['통근 버스'] },
    { code: 'gym', label: '피트니스센터 지원', ctgr: 'health', aliases: ['헬스장 이용'] },
  ];
  test('빈 검색어 → 후보 없음', () => {
    assert.deepEqual(filterCodes(CODES, ''), []);
    assert.deepEqual(filterCodes(CODES, '   '), []);
    assert.deepEqual(filterCodes(null, '식대'), []);
  });
  test('이름에 포함', () => { assert.deepEqual(filterCodes(CODES, '식대').map((c) => c.code), ['meal']); });
  test('별칭으로도 찾는다(이름엔 없는 낱말)', () => {
    assert.deepEqual(filterCodes(CODES, '헬스장').map((c) => c.code), ['gym']);
    assert.deepEqual(filterCodes(CODES, '점심').map((c) => c.code), ['meal']);
  });
  test('공백·대소문자를 가리지 않는다', () => {
    assert.deepEqual(filterCodes(CODES, '복지 포인트').map((c) => c.code), ['welfare_point']);
    assert.deepEqual(filterCodes(CODES, 'welfarepoint').map((c) => c.code), ['welfare_point']);
    assert.deepEqual(filterCodes(CODES, '통근 버스').map((c) => c.code), ['commute_subsidy']);
  });
  test('이름이 검색어로 시작 > 이름에 포함 > 별칭에만 포함 순서', () => {
    const list = [
      { code: 'a', label: '건강검진 지원', ctgr: 'health', aliases: ['지원금 안내'] },
      { code: 'b', label: '학자금 지원', ctgr: 'growth', aliases: [] },
      { code: 'c', label: '지원금 제도', ctgr: 'perks', aliases: [] },
    ];
    assert.deepEqual(filterCodes(list, '지원금').map((c) => c.code), ['c', 'a']);
    assert.deepEqual(filterCodes(list, '지원').map((c) => c.code), ['c', 'a', 'b']);
  });
  test('영문 코드는 검색 대상이 아니다', () => {
    assert.deepEqual(filterCodes(CODES, 'commute_subsidy'), []);
    assert.deepEqual(filterCodes(CODES, 'gym'), []);
  });
  test('상한을 넘기지 않는다', () => {
    const many = Array.from({ length: 40 }, (_, i) => ({ code: 'c' + i, label: '복지 ' + i, ctgr: 'perks', aliases: [] }));
    assert.equal(filterCodes(many, '복지').length, CODE_RESULT_LIMIT);
    assert.equal(filterCodes(many, '복지', 3).length, 3);
  });
});

describe('requestStatusView — 내 요청 표시', () => {
  test('확인 대기', () => {
    assert.deepEqual(requestStatusView({ type: 'create', status: 'pending' }),
      { kind: '등록', label: '확인 대기', cls: 'pending', note: '' });
  });
  test('반영됨', () => {
    assert.deepEqual(requestStatusView({ type: 'update', status: 'approved' }),
      { kind: '수정', label: '반영됨', cls: 'approved', note: '' });
  });
  test('반영 안 됨 + 사유', () => {
    assert.deepEqual(requestStatusView({ type: 'create', status: 'rejected', decide_note: '공식 자료가 필요해요' }),
      { kind: '등록', label: '반영 안 됨', cls: 'rejected', note: '사유: 공식 자료가 필요해요' });
  });
  test('반영 안 됨 + 사유 없음 → 사유 줄 없음', () => {
    assert.equal(requestStatusView({ type: 'create', status: 'rejected', decide_note: null }).note, '');
  });
});

describe('pendingUpdateIds — 「수정 확인 대기」 표시 대상', () => {
  test('확인 대기 중인 수정의 복지 id 만', () => {
    const ids = pendingUpdateIds([
      { type: 'update', status: 'pending', benefit_id: 11 },
      { type: 'update', status: 'rejected', benefit_id: 12 },
      { type: 'create', status: 'pending', benefit_id: null },
      { type: 'update', status: 'approved', benefit_id: 13 },
    ]);
    assert.deepEqual([...ids], [11]);
  });
  test('없거나 null 이어도 죽지 않는다', () => {
    assert.equal(pendingUpdateIds(null).size, 0);
    assert.equal(pendingUpdateIds([]).size, 0);
  });
});
