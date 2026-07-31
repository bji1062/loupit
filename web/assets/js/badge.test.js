// web/assets/js/badge.test.js — 배지 계보 판정 정본 테스트.
// 근거: generator/format.py `badge_state()` 와 **같은 우선순위**여야 한다
// (만료 → 재직자 등록 → 공식·재직자 수정 → 공식 → 추정).
// 이 파일이 클라이언트 네 렌더러(비교 리포트·디렉터리·회사 페이지·정적 페이지 대응)의
// 공통 계약을 고정한다 — 렌더러마다 판정을 복사하던 구조가 실제로 한 화면을 빠뜨렸다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import {
  badgeKind, badgeClass, badgeClassBem, BADGE_LABEL_FULL, BADGE_LABEL_SHORT,
} from './badge.js';

const NOW = Date.parse('2026-07-31T00:00:00Z');
const PAST = '2026-01-01T00:00:00Z';
const FUTURE = '2027-09-30T00:00:00Z';

describe('badgeKind — 우선순위(만료 > member > edited > official > est)', () => {
  test('만료가 최우선 — 재직자가 등록했어도 오래된 값은 만료다', () => {
    assert.equal(badgeKind({ expires_dtm: PAST, edit_origin: 'member', badge_cd: 'official' }, { now: NOW }), 'expired');
    assert.equal(badgeKind({ expires_dtm: PAST, edit_origin: 'edited' }, { now: NOW }), 'expired');
  });

  test('member > edited > official', () => {
    assert.equal(badgeKind({ edit_origin: 'member', badge_cd: 'official' }, { now: NOW }), 'member');
    assert.equal(badgeKind({ edit_origin: 'edited', badge_cd: 'official' }, { now: NOW }), 'edited');
    assert.equal(badgeKind({ edit_origin: 'seed', badge_cd: 'official' }, { now: NOW }), 'official');
  });

  test('그 외는 추정', () => {
    assert.equal(badgeKind({ badge_cd: 'est' }, { now: NOW }), 'est');
    assert.equal(badgeKind({}, { now: NOW }), 'est');
    assert.equal(badgeKind(null, { now: NOW }), 'est');
  });

  test('미래 만료일은 만료가 아니다', () => {
    assert.equal(badgeKind({ expires_dtm: FUTURE, badge_cd: 'official' }, { now: NOW }), 'official');
  });

  test('파싱 불가한 만료일은 만료로 치지 않는다(무크래시)', () => {
    assert.equal(badgeKind({ expires_dtm: '언젠가', badge_cd: 'official' }, { now: NOW }), 'official');
  });

  test('withExpiry:false(요약 화면) — 만료를 보지 않고 계보만 본다', () => {
    assert.equal(badgeKind({ expires_dtm: PAST, edit_origin: 'member' }, { now: NOW, withExpiry: false }), 'member');
    assert.equal(badgeKind({ expires_dtm: PAST, badge_cd: 'official' }, { now: NOW, withExpiry: false }), 'official');
  });
});

describe('클래스·라벨 규약', () => {
  test('단일대시 규약은 정적 템플릿과 같은 어휘(만료=stale)', () => {
    assert.equal(badgeClass('expired'), 'badge badge-stale');
    assert.equal(badgeClass('member'), 'badge badge-member');
    assert.equal(badgeClass('official'), 'badge badge-official');
  });

  test('이중대시 규약(비교 리포트)', () => {
    assert.equal(badgeClassBem('expired'), 'badge badge--expired');
    assert.equal(badgeClassBem('member'), 'badge badge--member');
  });

  test('두 라벨 세트가 같은 종류 집합을 덮는다', () => {
    assert.deepEqual(Object.keys(BADGE_LABEL_FULL).sort(), Object.keys(BADGE_LABEL_SHORT).sort());
  });

  test('상세 라벨은 generator/format.py 문구와 일치한다(화면 간 용어 표류 방지)', () => {
    const py = readFileSync(new URL('../../../generator/format.py', import.meta.url), 'utf8');
    for (const label of ['만료·재확인 필요', '재직자 등록', '공식·재직자 수정']) {
      assert.ok(py.includes(`"${label}"`), `generator/format.py 에 "${label}" 이 없다 — 어휘가 갈렸다`);
      assert.ok(Object.values(BADGE_LABEL_FULL).includes(label));
    }
  });
});
