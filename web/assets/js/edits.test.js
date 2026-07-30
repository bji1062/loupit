// web/assets/js/edits.test.js — SC14 공개 편집 이력 순수 로직 + 렌더 XSS 안전 단위 테스트(SP-FE).
// jsdom 없이 최소 document 스텁으로 renderEntry 의 textContent-only 삽입을 검증한다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import { EDIT_TYPE_LABELS, PAGE_LIMIT, companyBackHref, diffFields, fmtDtm, renderEntry, nextCursor, hasMore } from './edits.js';

// ── 최소 in-memory document 스텁(renderEntry 전용) ──────────────────────────
class FakeEl {
  constructor(tag) { this.tagName = tag; this.className = ''; this.textContent = ''; this.children = []; }
  append(...nodes) { this.children.push(...nodes); }
}
const fakeDoc = { createElement: (t) => new FakeEl(t) };

// 트리의 모든 textContent 를 모은다(렌더 안전성 검사용).
function allText(node) {
  if (typeof node === 'string') return [node];
  const out = node.textContent ? [node.textContent] : [];
  for (const c of node.children) out.push(...allText(c));
  return out;
}

describe('EDIT_TYPE_LABELS', () => {
  test('create/update/delete 한글 라벨', () => {
    assert.equal(EDIT_TYPE_LABELS.create, '등록');
    assert.equal(EDIT_TYPE_LABELS.update, '수정');
    assert.equal(EDIT_TYPE_LABELS.delete, '삭제');
  });
});

describe('fmtDtm', () => {
  test('ISO(T) → YYYY-MM-DD HH:MM', () => { assert.equal(fmtDtm('2026-07-24T06:17:39'), '2026-07-24 06:17'); });
  test('공백 구분 → 동일', () => { assert.equal(fmtDtm('2026-07-24 06:17:39'), '2026-07-24 06:17'); });
  test('이상값 → 앞 16자 폴백', () => { assert.equal(fmtDtm('bad'), 'bad'); });
});

describe('diffFields', () => {
  test('등록(before=null): 값 있는 필드만, from=null', () => {
    const rows = diffFields(null, { benefit_nm: '식대', benefit_ctgr_cd: 'compensation', benefit_amt: 220, qual_yn: false, note_ctnt: '' });
    const labels = rows.map((r) => r.label);
    assert.deepEqual(labels, ['복지명', '카테고리', '금액']); // qual_yn=false·note 공백 생략
    assert.ok(rows.every((r) => r.from === null));
    assert.equal(rows.find((r) => r.label === '카테고리').to, '보상');
    assert.equal(rows.find((r) => r.label === '금액').to, '220만원');
  });

  test('수정: 변경된 필드만 from→to', () => {
    const before = { benefit_nm: '식대', benefit_amt: 200, qual_yn: false, benefit_ctgr_cd: 'compensation', note_ctnt: null };
    const after = { benefit_nm: '식대', benefit_amt: 300, qual_yn: false, benefit_ctgr_cd: 'compensation', note_ctnt: null };
    const rows = diffFields(before, after);
    assert.equal(rows.length, 1);
    assert.deepEqual(rows[0], { label: '금액', from: '200만원', to: '300만원' });
  });

  test('수정: 금액→정성 전환 시 금액·정성여부 2필드', () => {
    const before = { benefit_nm: 'a', benefit_amt: 200, qual_yn: false, benefit_ctgr_cd: 'health', note_ctnt: null };
    const after = { benefit_nm: 'a', benefit_amt: null, qual_yn: true, benefit_ctgr_cd: 'health', note_ctnt: null };
    const labels = diffFields(before, after).map((r) => r.label);
    assert.deepEqual(labels.sort(), ['금액', '정성 여부']);
  });

  test('삭제(after=null): 값 있는 필드, to=null', () => {
    const rows = diffFields({ benefit_nm: '식대', benefit_amt: 220, qual_yn: false, benefit_ctgr_cd: 'compensation', note_ctnt: null }, null);
    assert.ok(rows.length >= 1);
    assert.ok(rows.every((r) => r.to === null));
  });
});

// ── 키셋 페이징(사용자 결정 2026-07-25: edit_id 노출 + before 커서) ─────────────
describe('nextCursor / hasMore', () => {
  const page = (ids) => ids.map((id) => ({ edit_id: id, nickname: 'n', edit_type: 'update', dtm: '2026-01-01T00:00:00' }));

  test('다음 커서 = 마지막(가장 오래된) 행의 edit_id', () => {
    assert.equal(nextCursor(page([812, 811, 810])), 810);
  });
  test('빈 페이지·미정의 → null(더 요청하지 않음)', () => {
    assert.equal(nextCursor([]), null);
    assert.equal(nextCursor(null), null);
    assert.equal(nextCursor(undefined), null);
  });
  test('edit_id 없는 응답(구 서버) → null 로 안전 폴백', () => {
    assert.equal(nextCursor([{ nickname: 'n' }]), null);
  });
  test('상한만큼 꽉 찼을 때만 더 보기', () => {
    assert.equal(hasMore(page(Array.from({ length: PAGE_LIMIT }, (_, i) => i + 1))), true);
    assert.equal(hasMore(page([1, 2, 3])), false);
    assert.equal(hasMore([]), false);
    assert.equal(hasMore(null), false);
  });
  test('limit 을 명시하면 그 값 기준', () => {
    assert.equal(hasMore(page([1, 2]), 2), true);
    assert.equal(hasMore(page([1]), 2), false);
  });
  test('페이지 크기는 서버 상한(200) 이내', () => { assert.ok(PAGE_LIMIT >= 1 && PAGE_LIMIT <= 200); });
});

describe('renderEntry — textContent-only(XSS 안전)', () => {
  test('악성 닉네임·편집 사유·복지명이 텍스트로만 삽입(스크립트 미실행)', () => {
    const evil = '<img src=x onerror=alert(1)>';
    const li = renderEntry(fakeDoc, {
      nickname: evil, edit_type: 'update', edit_note: '</script><b>x</b>',
      before: { benefit_nm: '식대' }, after: { benefit_nm: '<script>bad()</script>' }, dtm: '2026-07-24T00:00:00',
    });
    const texts = allText(li);
    // 원문이 textContent 값으로 보존됨(=innerHTML 파싱 아님)
    assert.ok(texts.includes(evil), '닉네임 원문이 textContent 로 보존되어야 함');
    assert.ok(texts.some((t) => t.includes('</script><b>x</b>')), '편집 사유 원문 보존');
    assert.ok(texts.some((t) => t.includes('<script>bad()</script>')), '복지명 원문 보존');
    assert.ok(texts.includes('수정'), '편집 유형 라벨');
  });

  test('편집 사유 없으면 사유 노드 생략', () => {
    const li = renderEntry(fakeDoc, { nickname: '직장인-1', edit_type: 'create', after: { benefit_nm: '식대', benefit_amt: 220 }, dtm: '2026-01-01T00:00:00' });
    const hasNote = li.children.some((c) => c.className === 'log-note');
    assert.equal(hasNote, false);
  });
});

describe('companyBackHref — 편집 이력 → 회사 상세 링크 (2026-07-30 결함 수정)', () => {
  // 🚨 원래 이 링크는 `loadHistory` 안에서 **숫자 COMP_ID** 로 만들어져 **항상 404** 였다
  //    (`/company/40`). 정적 회사 페이지 경로는 `comp_eng_nm` 의 슬러그다.
  //    실측: `/company/40` → 404 · `/company/samsung-elec` → 200 · `/company/cj` → 200.
  test('comp_eng_nm 슬러그로 주소를 만든다(밑줄 → 하이픈)', () => {
    assert.equal(companyBackHref({ comp_id: 40, comp_eng_nm: 'samsung_elec' }), '/company/samsung-elec');
    assert.equal(companyBackHref({ comp_id: 1, comp_eng_nm: 'cj' }), '/company/cj');
  });

  test('숫자 COMP_ID 경로는 절대 만들지 않는다(이번 결함 그 자체)', () => {
    for (const c of [{ comp_id: 40, comp_eng_nm: 'samsung_elec' }, { comp_id: 1, comp_eng_nm: 'cj' }]) {
      assert.doesNotMatch(companyBackHref(c) || '', /^\/company\/\d+$/);
    }
  });

  test('슬러그를 못 얻으면 null — 링크를 만들지 않는다', () => {
    // 404 로 가는 링크보다 **링크 없음**이 낫다(막다른 길 금지). 회사명이 '회사 #N' 으로
    // 폴백하는 것과 같은 판단이다. 여기서 숫자 ID 로 폴백하면 결함이 되살아난다.
    assert.equal(companyBackHref(null), null);
    assert.equal(companyBackHref(undefined), null);
    assert.equal(companyBackHref({ comp_id: 3 }), null, 'comp_eng_nm 부재');
    assert.equal(companyBackHref({ comp_id: 3, comp_eng_nm: '' }), null);
    assert.equal(companyBackHref({ comp_id: 3, comp_eng_nm: '   ' }), null);
  });

  test('규칙 소유자는 directory.js 다 — 여기서 다시 구현하지 않는다', async () => {
    const { companyHref } = await import('./directory.js');
    for (const eng of ['cj', 'samsung_elec', 'lg-chem', 'SK_Hynix']) {
      assert.equal(companyBackHref({ comp_eng_nm: eng }), companyHref(eng),
        '슬러그 규칙이 갈라졌다 — 정본은 generator/slug.py, 미러는 directory.js 하나뿐이어야 한다');
    }
  });
});
