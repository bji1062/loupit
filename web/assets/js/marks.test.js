// web/assets/js/marks.test.js — 행 표시 클라이언트 사본(SP-MARK). 정본 대조는 파이썬 쪽
// (generator/tests/test_row_marks_client_copy.py)이 하고, 여기서는 판정 함수의 계약만 본다.
import test from 'node:test';
import assert from 'node:assert/strict';
import { ROW_MARKS, MARK, SUMMARY, rowMark, countable, isSummary } from './marks.js';

test('MARKS-1: 3튜플이 모두 맞아야 표시 행이다(코드만 같으면 아니다)', () => {
  assert.equal(rowMark('kt', { benefit_cd: 'parenting', benefit_nm: '출산/육아 지원' }), 'legal');
  assert.equal(rowMark('alteogen', { benefit_cd: 'edu_support', benefit_nm: '신입사원 교육' }), 'work_edu');
  assert.equal(rowMark('kt', { benefit_cd: 'parenting', benefit_nm: '육아휴직 2년' }), null, '같은 코드의 진짜 복지는 남는다');
  assert.equal(rowMark('naver', { benefit_cd: 'parenting', benefit_nm: '출산/육아 지원' }), null);
  assert.equal(rowMark(null, null), null);
  assert.equal(rowMark(undefined, { benefit_cd: undefined, benefit_nm: '' }), null);
});

test('MARKS-2: 목록은 동결 · 중복 없음 · 4튜플 · kind 는 MARK 키', () => {
  assert.equal(Object.isFrozen(ROW_MARKS), true);
  const keys = ROW_MARKS.map((r) => r.join('|'));
  assert.equal(new Set(keys).size, keys.length);
  assert.ok(ROW_MARKS.every((r) => r.length === 4 && r[3] in MARK));
  assert.equal(Object.isFrozen(MARK), true);
  assert.deepEqual(Object.keys(MARK), ['legal', 'work_edu']);
  assert.equal(SUMMARY.label, '검색 요약');
});

test('MARKS-3: countable 은 표시 행을 빼고 검색 요약 행은 남긴다(2a)', () => {
  const company = {
    comp_eng_nm: 'alteogen',
    benefits: [
      { benefit_cd: 'edu_support', benefit_nm: '신입사원 교육' },
      { benefit_cd: 'edu_support', benefit_nm: '교육비 지원' },
      { benefit_cd: 'health', benefit_nm: '건강검진', badge_src_cd: 'ai_parse' },
    ],
  };
  assert.deepEqual(countable(company).map((b) => b.benefit_nm), ['교육비 지원', '건강검진']);
  assert.equal(isSummary(company.benefits[2]), true);
  assert.equal(isSummary(company.benefits[0]), false);
  assert.equal(isSummary(null), false);
  assert.deepEqual(countable({}), []);
  assert.deepEqual(countable(null), []);
});
