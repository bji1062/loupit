// web/assets/js/community.test.js — SC15 커뮤니티 화면(SP-COMM-8, CM-9) 단위·부팅 테스트.
// 순수 함수(라우터·쿼리·포맷·초안·오류 문구)는 DOM 없이, 렌더(XSS)·부팅 스모크는 jsdom 으로.
// fetch 는 FRD/14 응답 형식 그대로 스텁한다 — 실 네트워크 0.
//
// ⚠ 모듈 import 시점엔 `document` 가 없어야 자동 초기화가 돌지 않는다(community.js·authnav.js 모두
//   가드가 있다). 그래서 jsdom 전역은 각 테스트 안에서 `loadShell()` 로 세운다.
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { JSDOM, VirtualConsole } from 'jsdom';

import { ApiError } from './api.js';
import {
  CATEGORIES, CATEGORY_LABELS, SORTS, PAGE_LIMIT, COMMENT_LIMIT, TITLE_MAX, BODY_MAX, COMMENT_MAX,
  routeFor, listQueryFrom, listUrl, fmtDate, fmtCount, isVerifiedFor, loginHref, uiAuthState,
  DRAFT_TTL_MS, draftKey, draft, nextAfterOf, itemsOf, errorMessageFor,
  renderListRow, renderPostView, renderComment, initCommunity,
} from './community.js';

const HERE = dirname(fileURLToPath(import.meta.url));
// 셸은 공개 전엔 staging/, 공개(T-14.7 `git mv`) 후엔 web/community/ 에 있다 — 둘 다 찾는다.
const SHELL_CANDIDATES = [
  join(HERE, '../../../staging/community/index.html'),
  join(HERE, '../../community/index.html'),
];
const SHELL_PATH = SHELL_CANDIDATES.find((p) => existsSync(p));
const SHELL = readFileSync(SHELL_PATH, 'utf8');

function loadShell(url = 'https://loupit.example/community/') {
  // jsdom 은 window.scrollTo 를 "Not implemented" 로 콘솔에 찍는다 — 실패가 아니라 소음이라 가상 콘솔로 흡수.
  const virtualConsole = new VirtualConsole();
  const dom = new JSDOM(SHELL, { url, pretendToBeVisual: true, virtualConsole });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  globalThis.location = dom.window.location;
  globalThis.history = dom.window.history;
  globalThis.localStorage = dom.window.localStorage;
  globalThis.sessionStorage = dom.window.sessionStorage;
  return dom;
}

// ── fetch 스텁: apiFetch(json())·apiSend(text()) 둘 다 만족 ──
let calls;
function stubFetch(handler) {
  calls = [];
  globalThis.fetch = async (url, opts) => {
    calls.push({ url, opts });
    const r = handler(url, opts) || { status: 404, json: { detail: 'not found' } };
    const txt = r.json === undefined ? '' : JSON.stringify(r.json);
    return {
      ok: r.status >= 200 && r.status < 300, status: r.status,
      headers: { get: () => null }, json: async () => r.json, text: async () => txt,
    };
  };
}
const path = (url) => new URL('http://x' + url).pathname;

// FRD-121 목록 항목 / FRD-122 상세 / FRD-123 댓글 픽스처
const post = (i, extra = {}) => ({
  post_id: i, category: 'free', title: '글 ' + i, nickname: '직장인-' + i, verified_comp_nm: null, comp: null,
  like_cnt: i, comment_cnt: 0, created_at: '2026-08-27T01:02:03Z', edited: false, ...extra,
});
const detail = (i, extra = {}) => ({
  ...post(i), body: '첫 줄\n둘째 줄', updated_at: '2026-08-27T01:02:03Z', is_mine: false, liked: false, ...extra,
});
const comment = (i, extra = {}) => ({
  comment_id: i, nickname: '댓글러-' + i, verified_comp_nm: null, body: '댓글 ' + i, deleted: false, is_mine: false,
  created_at: '2026-08-27T02:00:00Z', ...extra,
});

const tick = () => new Promise((r) => setTimeout(r, 0));
async function settle(n = 6) { for (let i = 0; i < n; i++) await tick(); }

// ── 상수 ──
describe('상수 — 카테고리·정렬·한도(FRD/14·PLAN D-4)', () => {
  test('카테고리 5탭(전체=빈 코드) · 라벨', () => {
    assert.deepEqual(CATEGORIES.map((c) => c.code), ['', 'notice', 'free', 'career', 'suggestion']);
    assert.deepEqual(CATEGORIES.map((c) => c.label), ['전체', '공지', '자유', '이직 고민', '건의사항']);
    assert.equal(CATEGORY_LABELS.career, '이직 고민');
  });
  test('정렬 3종 · 조회순 없음(조회수 미수집)', () => {
    assert.deepEqual(SORTS.map((s) => s.code), ['latest', 'comments', 'likes']);
    assert.ok(!SORTS.some((s) => /view|조회/.test(s.code + s.label)));
  });
  test('한도 = 서버 계약(제목 100·본문 5000·댓글 1000) · 페이지 20·댓글 50', () => {
    assert.equal(TITLE_MAX, 100); assert.equal(BODY_MAX, 5000); assert.equal(COMMENT_MAX, 1000);
    assert.equal(PAGE_LIMIT, 20); assert.equal(COMMENT_LIMIT, 50);
  });
});

// ── routeFor ──
describe('routeFor — pathname → 화면', () => {
  test('/community/ · /community → list', () => {
    assert.deepEqual(routeFor('/community/'), { view: 'list' });
    assert.deepEqual(routeFor('/community'), { view: 'list' });
  });
  test('/community/write → write', () => { assert.deepEqual(routeFor('/community/write'), { view: 'write' }); });
  test('/community/{id} (양의 정수) → detail, 끝 슬래시 허용', () => {
    assert.deepEqual(routeFor('/community/12'), { view: 'detail', id: 12 });
    assert.deepEqual(routeFor('/community/12/'), { view: 'detail', id: 12 });
  });
  test('/community/{id}/edit → edit', () => { assert.deepEqual(routeFor('/community/12/edit'), { view: 'edit', id: 12 }); });
  test('그 외(0·음수·문자·깊은 경로·빈값) → list', () => {
    for (const p of ['/community/0', '/community/-1', '/community/abc', '/community/12/x', '/community/1.5', '/', '', undefined]) {
      assert.equal(routeFor(p).view, 'list', `p=${String(p)}`);
    }
  });
});

// ── 목록 쿼리 ──
describe('listQueryFrom / listUrl — ?category=&sort= 왕복', () => {
  test('유효 값은 그대로, 모르는 값·빈값은 기본값(전체·최신)', () => {
    assert.deepEqual(listQueryFrom('?category=career&sort=likes'), { category: 'career', sort: 'likes' });
    assert.deepEqual(listQueryFrom('?category=xxx&sort=views'), { category: '', sort: 'latest' });
    assert.deepEqual(listQueryFrom(''), { category: '', sort: 'latest' });
    assert.deepEqual(listQueryFrom(undefined), { category: '', sort: 'latest' });
  });
  test('기본값은 URL 에 붙이지 않는다(새로고침 보존용 최소 URL)', () => {
    assert.equal(listUrl('', 'latest'), '/community/');
    assert.equal(listUrl('free', 'latest'), '/community/?category=free');
    assert.equal(listUrl('', 'comments'), '/community/?sort=comments');
    assert.equal(listUrl('notice', 'likes'), '/community/?category=notice&sort=likes');
  });
});

// ── 포맷·판정 ──
describe('fmtDate / fmtCount / isVerifiedFor / loginHref / uiAuthState', () => {
  test('fmtDate: ISO → YYYY-MM-DD, 이상값은 빈 문자열', () => {
    assert.equal(fmtDate('2026-08-27T01:02:03Z'), '2026-08-27');
    assert.equal(fmtDate('2026-08-27 01:02:03'), '2026-08-27');
    assert.equal(fmtDate(null), ''); assert.equal(fmtDate('bad'), '');
  });
  test('fmtCount: 천단위 · null/음수/NaN → 0', () => {
    assert.equal(fmtCount(1234), '1,234'); assert.equal(fmtCount(0), '0');
    assert.equal(fmtCount(null), '0'); assert.equal(fmtCount(-3), '0'); assert.equal(fmtCount('x'), '0');
  });
  test('재직자 배지: verified_comp_nm 이 회사 태그 comp_nm 과 같을 때만', () => {
    assert.equal(isVerifiedFor(post(1, { verified_comp_nm: 'A사', comp: { comp_id: 1, comp_nm: 'A사', slug: 'a' } })), true);
    assert.equal(isVerifiedFor(post(1, { verified_comp_nm: 'B사', comp: { comp_id: 1, comp_nm: 'A사', slug: 'a' } })), false);
    assert.equal(isVerifiedFor(post(1, { verified_comp_nm: 'A사', comp: null })), false);
    assert.equal(isVerifiedFor(post(1, { verified_comp_nm: null, comp: { comp_id: 1, comp_nm: 'A사', slug: 'a' } })), false);
    assert.equal(isVerifiedFor(null), false);
  });
  test('loginHref: next 를 인코딩해 /login?next= 로', () => {
    assert.equal(loginHref('/community/write'), '/login?next=%2Fcommunity%2Fwrite');
    assert.equal(loginHref('/community/7'), '/login?next=%2Fcommunity%2F7');
  });
  test('uiAuthState: 판단 보류(null)는 anon 으로 표시(쓰기 버튼은 로그인 링크)', () => {
    assert.equal(uiAuthState(null), 'anon'); assert.equal(uiAuthState('off'), 'off');
    assert.equal(uiAuthState('member'), 'member'); assert.equal(uiAuthState('anon'), 'anon');
  });
});

// ── 초안(localStorage 24h) ──
describe('draft — 화면별 키·24h 만료', () => {
  beforeEach(() => { loadShell(); });
  test('키: write / edit:{id}', () => {
    assert.equal(draftKey('write'), 'loupit.community.draft:write');
    assert.equal(draftKey('edit', 12), 'loupit.community.draft:edit:12');
  });
  test('저장 → 복원(24h 이내)', () => {
    const k = draftKey('write');
    assert.equal(draft.save(k, { category: 'free', title: '제목', body: '본문', comp: null }, 1000), true);
    assert.deepEqual(draft.load(k, 1000 + DRAFT_TTL_MS), { category: 'free', title: '제목', body: '본문', comp: null });
  });
  test('24h 경과 → null + 저장소에서 삭제', () => {
    const k = draftKey('edit', 3);
    draft.save(k, { title: 't', body: 'b' }, 1000);
    assert.equal(draft.load(k, 1000 + DRAFT_TTL_MS + 1), null);
    assert.equal(localStorage.getItem(k), null);
  });
  test('빈 초안(제목·본문 공백)은 저장하지 않고 기존 것을 지운다', () => {
    const k = draftKey('write');
    draft.save(k, { title: 't', body: '' }, 1000);
    assert.equal(draft.save(k, { title: '  ', body: '', comp: null }, 2000), false);
    assert.equal(draft.load(k, 2000), null);
  });
  test('손상 봉투 → null + 삭제', () => {
    const k = draftKey('write');
    localStorage.setItem(k, '{"v":9,"draft":{"title":"x"}}');
    assert.equal(draft.load(k), null);
    assert.equal(localStorage.getItem(k), null);
  });
  test('DRAFT_TTL_MS = 24시간', () => { assert.equal(DRAFT_TTL_MS, 24 * 60 * 60 * 1000); });
});

// ── 댓글 커서 ──
describe('nextAfterOf / itemsOf — 댓글 응답 봉투', () => {
  test('next_after 키가 있으면 그 값(null 포함)이 정답', () => {
    assert.equal(nextAfterOf({ items: [comment(1)], next_after: 7 }, 50), 7);
    assert.equal(nextAfterOf({ items: [comment(1)], next_after: null }, 1), null);
  });
  test('키가 없으면: 꽉 찬 페이지일 때만 마지막 comment_id, 아니면 null', () => {
    assert.equal(nextAfterOf({ items: [comment(1), comment(2)] }, 2), 2);
    assert.equal(nextAfterOf({ items: [comment(1)] }, 2), null);
    assert.equal(nextAfterOf([comment(1), comment(2)], 2), 2);
    assert.equal(nextAfterOf(null, 2), null);
  });
  test('itemsOf: 배열·{items} 모두 배열로', () => {
    assert.deepEqual(itemsOf([1]), [1]); assert.deepEqual(itemsOf({ items: [2] }), [2]); assert.deepEqual(itemsOf(null), []);
  });
});

// ── 오류 문구 ──
describe('errorMessageFor — 상태코드 → 문구(원문 반향 없음)', () => {
  const e = (s, data) => new ApiError(s, '/posts', data);
  test('네트워크', () => { assert.match(errorMessageFor(new Error('net'), 'post'), /네트워크/); });
  test('401 → 로그인 안내', () => { assert.match(errorMessageFor(e(401), 'post'), /로그인/); });
  test('403 공지 → 운영자 안내 · 그 외 403 → 권한', () => {
    assert.match(errorMessageFor(e(403), 'post', { category: 'notice' }), /공지는 운영자만/);
    assert.match(errorMessageFor(e(403), 'post', { category: 'free' }), /권한/);
    assert.match(errorMessageFor(e(403), 'delete'), /권한/);
  });
  test('404 → 삭제·숨김 안내', () => { assert.match(errorMessageFor(e(404), 'load'), /삭제되었거나 숨겨진/); });
  test('409 신고 → 이미 신고', () => { assert.match(errorMessageFor(e(409), 'report'), /이미 신고했어요/); });
  test('422 → 입력 경계 안내(단계별 한도)', () => {
    assert.match(errorMessageFor(e(422), 'post'), /100|5,000|링크/);
    assert.match(errorMessageFor(e(422), 'comment'), /1,000/);
    assert.match(errorMessageFor(e(422), 'report'), /300/);
  });
  test('429 → 일일 상한 안내', () => { assert.match(errorMessageFor(e(429), 'post'), /오늘|한도/); });
  test('원문을 반향하지 않는다(NFR31)', () => {
    assert.doesNotMatch(errorMessageFor(e(422, { detail: [{ msg: 'secret-token-xyz' }] }), 'post'), /secret-token/);
  });
});

// ── 렌더(jsdom) ──
describe('renderListRow — 행 마크업·XSS·조회수 부재', () => {
  beforeEach(() => { loadShell(); });
  test('카테고리 라벨·제목 링크·닉네임·날짜·댓글·좋아요 — 조회수 문자열 없음', () => {
    const li = renderListRow(post(7, { category: 'career', comment_cnt: 3, like_cnt: 12 }));
    assert.equal(li.tagName, 'LI');
    assert.equal(li.querySelector('.cm-cat').textContent, '이직 고민');
    const a = li.querySelector('a.cm-title');
    assert.equal(a.getAttribute('href'), '/community/7');
    assert.equal(a.textContent, '글 7');
    assert.equal(li.querySelector('.cm-nick').textContent, '직장인-7');
    assert.equal(li.querySelector('time').textContent, '2026-08-27');
    assert.match(li.textContent, /댓글\s*3/); assert.match(li.textContent, /좋아요\s*12/);
    assert.doesNotMatch(li.textContent, /조회/);
    assert.equal(li.querySelector('.cm-badge'), null, '재직 아니면 배지 없음');
    assert.equal(li.querySelector('a.cm-comp'), null, '회사 태그 없으면 링크 없음');
  });
  test('재직자 배지 + 회사 태그 링크(/company/{slug})', () => {
    const li = renderListRow(post(1, { verified_comp_nm: 'A사', comp: { comp_id: 1, comp_nm: 'A사', slug: 'a-corp' } }));
    assert.equal(li.querySelector('.cm-badge').textContent, '재직자');
    assert.equal(li.querySelector('a.cm-comp').getAttribute('href'), '/company/a-corp');
    assert.equal(li.querySelector('a.cm-comp').textContent, 'A사');
  });
  test('XSS: 제목·닉네임·회사명은 텍스트로 남고 img 요소가 생기지 않는다', () => {
    const li = renderListRow(post(2, {
      title: '<img src=x onerror=alert(1)>', nickname: '<script>1</script>',
      comp: { comp_id: 1, comp_nm: '<b>x</b>', slug: 'x' },
    }));
    assert.equal(li.querySelector('img'), null); assert.equal(li.querySelector('script'), null); assert.equal(li.querySelector('b'), null);
    assert.equal(li.querySelector('a.cm-title').textContent, '<img src=x onerror=alert(1)>');
  });
  test('슬러그가 이상하면(경로 이탈) 회사 링크를 만들지 않는다', () => {
    const li = renderListRow(post(3, { comp: { comp_id: 1, comp_nm: 'A', slug: '../x' } }));
    assert.equal(li.querySelector('a.cm-comp'), null);
    assert.match(li.textContent, /A/);
  });
});

describe('renderPostView — 상세', () => {
  beforeEach(() => { loadShell('https://loupit.example/community/7'); });
  const ctx = (auth) => ({ auth, doc: document, navigate() {} });
  test('제목·카테고리·닉네임·날짜·본문(줄바꿈 보존)·좋아요 수', () => {
    const v = renderPostView(detail(7, { like_cnt: 4 }), ctx('member'));
    assert.equal(v.querySelector('.cm-post-title').textContent, '글 7');
    assert.equal(v.querySelector('.cm-cat').textContent, '자유');
    assert.equal(v.querySelector('.cm-body').textContent, '첫 줄\n둘째 줄');
    assert.equal(v.querySelector('.cm-edited'), null);
    assert.match(v.querySelector('.cm-like').textContent, /4/);
  });
  test('edited → "(수정됨)"', () => {
    assert.equal(renderPostView(detail(7, { edited: true }), ctx('member')).querySelector('.cm-edited').textContent, '(수정됨)');
  });
  test('XSS: 제목·본문에 img 가 생기지 않는다', () => {
    const v = renderPostView(detail(7, { title: '<img src=x onerror=alert(1)>', body: '<img src=x onerror=alert(2)>' }), ctx('anon'));
    assert.equal(v.querySelector('img'), null);
    assert.equal(v.querySelector('.cm-body').textContent, '<img src=x onerror=alert(2)>');
  });
  test('anon: 좋아요는 /login?next= 링크, off: 쓰기 UI 자체 없음, member: 버튼', () => {
    const anon = renderPostView(detail(7), ctx('anon'));
    assert.equal(anon.querySelector('a.cm-like').getAttribute('href'), '/login?next=%2Fcommunity%2F7');
    const off = renderPostView(detail(7), ctx('off'));
    assert.equal(off.querySelector('.cm-like'), null); assert.equal(off.querySelector('.cm-report'), null);
    const mem = renderPostView(detail(7), ctx('member'));
    assert.equal(mem.querySelector('button.cm-like').tagName, 'BUTTON');
    assert.equal(mem.querySelector('button.cm-like').getAttribute('aria-pressed'), 'false');
    assert.ok(mem.querySelector('.cm-report'));
  });
  test('liked → aria-pressed=true', () => {
    assert.equal(renderPostView(detail(7, { liked: true }), ctx('member')).querySelector('button.cm-like').getAttribute('aria-pressed'), 'true');
  });
  test('본인 글(is_mine)만 수정·삭제 버튼', () => {
    const mine = renderPostView(detail(7, { is_mine: true }), ctx('member'));
    assert.equal(mine.querySelector('a.cm-edit').getAttribute('href'), '/community/7/edit');
    assert.ok(mine.querySelector('button.cm-delete'));
    const other = renderPostView(detail(7), ctx('member'));
    assert.equal(other.querySelector('a.cm-edit'), null); assert.equal(other.querySelector('button.cm-delete'), null);
  });
});

describe('renderComment — 댓글', () => {
  beforeEach(() => { loadShell(); });
  const ctx = (auth) => ({ auth, doc: document });
  test('본문·닉네임·날짜 · 재직자 배지', () => {
    const li = renderComment(comment(1, { verified_comp_nm: 'A사' }), ctx('anon'), { compNm: 'A사' });
    assert.equal(li.querySelector('.cm-c-body').textContent, '댓글 1');
    assert.equal(li.querySelector('.cm-nick').textContent, '댓글러-1');
    assert.equal(li.querySelector('.cm-badge').textContent, '재직자');
  });
  test('삭제 댓글 → "삭제된 댓글입니다" 자리만', () => {
    const li = renderComment(comment(2, { body: null, deleted: true, nickname: '누구' }), ctx('member'), {});
    assert.equal(li.querySelector('.cm-c-body').textContent, '삭제된 댓글입니다');
    assert.equal(li.querySelector('.cm-nick'), null);
    assert.equal(li.querySelector('button.cm-c-delete'), null);
  });
  test('XSS: 본문 img 미생성 · 본인 댓글만 삭제 버튼 · member 만 신고', () => {
    const li = renderComment(comment(3, { body: '<img src=x onerror=alert(1)>', is_mine: true }), ctx('member'), {});
    assert.equal(li.querySelector('img'), null);
    assert.ok(li.querySelector('button.cm-c-delete'));
    assert.ok(li.querySelector('.cm-report'));
    const anon = renderComment(comment(3, { is_mine: false }), ctx('anon'), {});
    assert.equal(anon.querySelector('button.cm-c-delete'), null);
    assert.equal(anon.querySelector('.cm-report'), null);
  });
});

// ── 부팅 스모크(셸 + fetch 스텁) ──
describe('initCommunity — 부팅 스모크', () => {
  test('셸에 광고 유형 미선언 · h1 정적 · authnav 슬롯 · 모듈 스크립트', () => {
    const dom = loadShell();
    const d = dom.window.document;
    assert.equal(d.body.getAttribute('data-page-type'), null, 'data-page-type 미선언 = 광고 0');
    assert.equal(d.querySelector('main#community h1').textContent, '커뮤니티');
    assert.ok(d.querySelector('[data-authnav][hidden]'));
    assert.ok(d.querySelector('header nav a[aria-current="page"][href="/community/"]'));
    assert.ok(d.querySelector('script[type="module"][src="/assets/v2/js/community.js"]'));
    assert.ok(d.querySelector('script[type="module"][src="/assets/v2/js/authnav.js"]'));
    assert.ok(d.querySelector('link[rel="stylesheet"][href="/assets/v2/css/community.css"]'));
    assert.equal(d.querySelector('meta[name="robots"]'), null, 'noindex 를 붙이지 않는다');
    assert.ok(d.querySelector('noscript'));
  });

  test('목록: anon(401) → 행 3개 + 글쓰기 버튼은 /login?next=', async () => {
    loadShell('https://loupit.example/community/?category=free');
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 401, json: { detail: 'unauthorized' } };
      if (path(url) === '/api/v1/posts') return { status: 200, json: { items: [post(1), post(2), post(3)], next_before: null } };
      return null;
    });
    await initCommunity();
    await settle();
    const rows = document.querySelectorAll('#community-view li.cm-row');
    assert.equal(rows.length, 3);
    assert.equal(document.querySelector('a.cm-write').getAttribute('href'), '/login?next=%2Fcommunity%2Fwrite');
    assert.equal(document.querySelector('.cm-cats a[aria-current="page"]').textContent, '자유');
    assert.equal(document.querySelector('.cm-more').hidden, true, 'next_before null → 더 보기 없음');
    const listCall = calls.find((c) => path(c.url) === '/api/v1/posts');
    assert.equal(new URL('http://x' + listCall.url).searchParams.get('category'), 'free');
  });

  test('목록: member(200) → 글쓰기 버튼은 /community/write · off(404) → 쓰기 버튼 없음', async () => {
    loadShell();
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 200, json: { nickname: '직장인-1' } };
      if (path(url) === '/api/v1/posts') return { status: 200, json: { items: [], next_before: null } };
      return null;
    });
    await initCommunity();
    await settle();
    assert.equal(document.querySelector('a.cm-write').getAttribute('href'), '/community/write');
    assert.equal(document.querySelector('.cm-empty').hidden, false, '빈 상태 문구');

    loadShell();
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 404, json: { detail: 'nf' } };
      if (path(url) === '/api/v1/posts') return { status: 200, json: { items: [post(1)], next_before: null } };
      return null;
    });
    await initCommunity();
    await settle();
    assert.equal(document.querySelector('a.cm-write'), null, 'M9 꺼짐 → 쓰기 UI 숨김');
  });

  test('목록 오류 → 재시도 버튼, 누르면 다시 요청', async () => {
    loadShell();
    let fail = true;
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 401, json: {} };
      if (path(url) === '/api/v1/posts') return fail ? { status: 500, json: {} } : { status: 200, json: { items: [post(1)], next_before: null } };
      return null;
    });
    await initCommunity();
    await settle();
    const retry = document.querySelector('.cm-error button');
    assert.ok(retry); assert.equal(document.querySelector('.cm-error').hidden, false);
    fail = false;
    retry.click();
    await settle();
    assert.equal(document.querySelectorAll('li.cm-row').length, 1);
    assert.equal(document.querySelector('.cm-error').hidden, true);
  });

  test('더 보기: next_before 로 다음 페이지를 이어 붙인다', async () => {
    loadShell();
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 401, json: {} };
      if (path(url) === '/api/v1/posts') {
        const before = new URL('http://x' + url).searchParams.get('before');
        return before ? { status: 200, json: { items: [post(1)], next_before: null } }
          : { status: 200, json: { items: [post(3), post(2)], next_before: 2 } };
      }
      return null;
    });
    await initCommunity();
    await settle();
    const more = document.querySelector('.cm-more');
    assert.equal(more.hidden, false);
    more.click();
    await settle();
    assert.equal(document.querySelectorAll('li.cm-row').length, 3);
    assert.equal(more.hidden, true);
  });

  test('행 제목 클릭 → pushState 로 상세 전환, popstate 로 목록 복귀', async () => {
    loadShell();
    stubFetch((url) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 401, json: {} };
      if (p === '/api/v1/posts') return { status: 200, json: { items: [post(5)], next_before: null } };
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5) };
      if (p === '/api/v1/posts/5/comments') return { status: 200, json: { items: [comment(1)], next_after: null } };
      return null;
    });
    await initCommunity();
    await settle();
    document.querySelector('a.cm-title').click();
    await settle();
    assert.equal(location.pathname, '/community/5');
    assert.equal(document.querySelector('.cm-post-title').textContent, '글 5');
    assert.equal(document.querySelectorAll('li.cm-comment').length, 1);
    assert.match(document.title, /글 5/);
    history.back();
    await settle(10);
    assert.equal(location.pathname, '/community/');
    assert.ok(document.querySelector('li.cm-row'));
  });

  test('상세(member): 댓글 폼·카운터, 작성 → POST 후 새 댓글이 붙는다', async () => {
    loadShell('https://loupit.example/community/5');
    let posted = false;
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5, { is_mine: true, liked: true, like_cnt: 1 }) };
      if (p === '/api/v1/posts/5/comments' && opts.method === 'POST') { posted = true; return { status: 201, json: { comment_id: 9 } }; }
      if (p === '/api/v1/posts/5/comments') {
        const after = new URL('http://x' + url).searchParams.get('after');
        return after ? { status: 200, json: { items: [comment(9, { is_mine: true })], next_after: null } }
          : { status: 200, json: { items: [comment(1)], next_after: null } };
      }
      return null;
    });
    await initCommunity();
    await settle();
    const ta = document.querySelector('.cm-comment-form textarea');
    assert.ok(ta);
    assert.equal(ta.getAttribute('maxlength'), '1000');
    ta.value = '새 댓글'; ta.dispatchEvent(new window.Event('input', { bubbles: true }));
    assert.match(document.querySelector('.cm-comment-form .cm-counter').textContent, /4\s*\/\s*1,000/);
    document.querySelector('.cm-comment-form').dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.equal(posted, true);
    assert.equal(document.querySelectorAll('li.cm-comment').length, 2);
    assert.ok(document.querySelector('a.cm-edit'), '본인 글 → 수정 링크');
  });

  test('상세: 좋아요 토글 → 응답으로 버튼 갱신', async () => {
    loadShell('https://loupit.example/community/5');
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5, { liked: false, like_cnt: 1 }) };
      if (p === '/api/v1/posts/5/like' && opts.method === 'PUT') return { status: 200, json: { liked: true, like_cnt: 2 } };
      if (p === '/api/v1/posts/5/comments') return { status: 200, json: { items: [], next_after: null } };
      return null;
    });
    await initCommunity();
    await settle();
    const btn = document.querySelector('button.cm-like');
    btn.click();
    await settle();
    assert.equal(btn.getAttribute('aria-pressed'), 'true');
    assert.match(btn.textContent, /2/);
  });

  test('상세 404 → "삭제되었거나 숨겨진 글입니다" + 목록 링크', async () => {
    loadShell('https://loupit.example/community/404');
    stubFetch((url) => {
      if (path(url) === '/api/v1/members/me') return { status: 401, json: {} };
      return { status: 404, json: { detail: 'nf' } };
    });
    await initCommunity();
    await settle();
    assert.match(document.querySelector('#community-view').textContent, /삭제되었거나 숨겨진 글입니다/);
    assert.ok(document.querySelector('#community-view a[href="/community/"]'));
  });

  test('신고: 202 → "접수됐습니다", 409 → "이미 신고했어요"', async () => {
    loadShell('https://loupit.example/community/5');
    let reportStatus = 202;
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5) };
      if (p === '/api/v1/posts/5/comments') return { status: 200, json: { items: [], next_after: null } };
      if (p === '/api/v1/reports' && opts.method === 'POST') {
        const b = JSON.parse(opts.body);
        assert.deepEqual(b, { target_type: 'post', target_id: 5, reason: 'abuse', detail: '설명' });
        return { status: reportStatus, json: reportStatus === 202 ? { report_id: 1 } : { detail: 'dup' } };
      }
      return null;
    });
    await initCommunity();
    await settle();
    document.querySelector('.cm-post .cm-report').click();
    const form = document.querySelector('.cm-post form.cm-report-form');
    assert.ok(form);
    assert.equal(form.querySelectorAll('select option').length, 4);
    assert.equal(form.querySelector('textarea').getAttribute('maxlength'), '300');
    form.querySelector('select').value = 'abuse';
    form.querySelector('textarea').value = '설명';
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.match(document.querySelector('.cm-post').textContent, /접수됐습니다/);

    // 두 번째: 409
    reportStatus = 409;
    document.querySelector('.cm-post .cm-report').click();
    const form2 = document.querySelector('.cm-post form.cm-report-form');
    form2.querySelector('select').value = 'abuse'; form2.querySelector('textarea').value = '설명';
    form2.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.match(document.querySelector('.cm-post').textContent, /이미 신고했어요/);
  });

  test('작성(anon) → 로그인 카드, 링크는 /login?next=%2Fcommunity%2Fwrite', async () => {
    loadShell('https://loupit.example/community/write');
    stubFetch((url) => (path(url) === '/api/v1/members/me' ? { status: 401, json: {} } : null));
    await initCommunity();
    await settle();
    assert.equal(document.querySelector('form.cm-form'), null);
    assert.equal(document.querySelector('#community-view a.cm-login').getAttribute('href'), '/login?next=%2Fcommunity%2Fwrite');
  });

  test('작성(member): 카운터·초안 저장·제출 성공 → 초안 삭제 + 상세로', async () => {
    loadShell('https://loupit.example/community/write');
    let created = null;
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/companies/search') return { status: 200, json: [{ comp_id: 3, comp_nm: 'A사', comp_tp_cd: 'large', industry_nm: 'IT' }] };
      if (p === '/api/v1/posts' && opts.method === 'POST') { created = JSON.parse(opts.body); return { status: 201, json: { post_id: 42 } }; }
      if (p === '/api/v1/posts/42') return { status: 200, json: detail(42, { title: '새 글', is_mine: true }) };
      if (p === '/api/v1/posts/42/comments') return { status: 200, json: { items: [], next_after: null } };
      return null;
    });
    await initCommunity();
    await settle();
    const form = document.querySelector('form.cm-form');
    assert.ok(form);
    assert.ok(form.querySelector('select[name="category"] option[value="notice"]'), '공지 옵션 포함(서버 403 로 안내)');
    const title = form.querySelector('input[name="title"]');
    const body = form.querySelector('textarea[name="body"]');
    assert.equal(title.getAttribute('maxlength'), '100'); assert.equal(body.getAttribute('maxlength'), '5000');
    title.value = '새 글'; title.dispatchEvent(new window.Event('input', { bubbles: true }));
    body.value = '본문'; body.dispatchEvent(new window.Event('input', { bubbles: true }));
    assert.match(form.querySelector('.cm-counter[data-for="title"]').textContent, /3\s*\/\s*100/);
    // 초안이 저장됐다
    assert.deepEqual(draft.load(draftKey('write')), { category: 'free', title: '새 글', body: '본문', comp: null });
    // 회사 태그 검색 → 선택
    const comp = form.querySelector('input[name="comp"]');
    comp.value = 'A'; comp.dispatchEvent(new window.Event('input', { bubbles: true }));
    await new Promise((r) => setTimeout(r, 320));
    await settle();
    const opt = form.querySelector('.cm-comp-results li');
    assert.ok(opt, '검색 결과');
    opt.click();
    assert.match(form.querySelector('.cm-comp-chip').textContent, /A사/);
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.deepEqual(created, { category: 'free', title: '새 글', body: '본문', comp_id: 3 });
    assert.equal(draft.load(draftKey('write')), null, '제출 성공 → 초안 삭제');
    assert.equal(location.pathname, '/community/42');
    assert.equal(document.querySelector('.cm-post-title').textContent, '새 글');
  });

  test('작성: 초안이 있으면 복원 · 공지 403 → 운영자 안내 · 401 → 로그인 링크', async () => {
    loadShell('https://loupit.example/community/write');
    localStorage.setItem(draftKey('write'), JSON.stringify({ v: 1, savedAt: Date.now(), draft: { category: 'notice', title: '복원', body: '본문', comp: { comp_id: 3, comp_nm: 'A사' } } }));
    let status = 403;
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts' && opts.method === 'POST') return { status, json: { detail: 'x' } };
      return null;
    });
    await initCommunity();
    await settle();
    const form = document.querySelector('form.cm-form');
    assert.equal(form.querySelector('input[name="title"]').value, '복원');
    assert.equal(form.querySelector('select[name="category"]').value, 'notice');
    assert.match(form.querySelector('.cm-comp-chip').textContent, /A사/);
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.match(form.querySelector('.cm-form-error').textContent, /공지는 운영자만/);
    status = 401;
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.equal(form.querySelector('.cm-form-error a').getAttribute('href'), '/login?next=%2Fcommunity%2Fwrite');
    assert.notEqual(draft.load(draftKey('write')), null, '실패 시 초안은 남는다');
  });

  test('수정(member, 본인): getPost 로 채우고 카테고리 잠금 · PUT 후 상세로', async () => {
    loadShell('https://loupit.example/community/5/edit');
    let put = null;
    stubFetch((url, opts) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts/5' && opts.method === 'PUT') { put = JSON.parse(opts.body); return { status: 200, json: { post_id: 5, updated_at: 'x' } }; }
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5, { is_mine: true, category: 'career', comp: { comp_id: 2, comp_nm: 'B사', slug: 'b' } }) };
      if (p === '/api/v1/posts/5/comments') return { status: 200, json: { items: [], next_after: null } };
      return null;
    });
    await initCommunity();
    await settle();
    const form = document.querySelector('form.cm-form');
    assert.equal(form.querySelector('input[name="title"]').value, '글 5');
    assert.equal(form.querySelector('textarea[name="body"]').value, '첫 줄\n둘째 줄');
    const sel = form.querySelector('select[name="category"]');
    assert.equal(sel.value, 'career'); assert.equal(sel.disabled, true);
    assert.match(form.querySelector('.cm-comp-chip').textContent, /B사/);
    form.querySelector('.cm-comp-chip button').click(); // 회사 태그 해제
    assert.equal(form.querySelector('.cm-comp-chip'), null);
    form.dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    await settle();
    assert.deepEqual(put, { title: '글 5', body: '첫 줄\n둘째 줄', comp_id: null });
    assert.equal(location.pathname, '/community/5');
  });

  test('수정(타인 글) → 안내 + 상세 링크, 폼 없음', async () => {
    loadShell('https://loupit.example/community/5/edit');
    stubFetch((url) => {
      const p = path(url);
      if (p === '/api/v1/members/me') return { status: 200, json: { nickname: '나' } };
      if (p === '/api/v1/posts/5') return { status: 200, json: detail(5, { is_mine: false }) };
      return null;
    });
    await initCommunity();
    await settle();
    assert.equal(document.querySelector('form.cm-form'), null);
    assert.match(document.querySelector('#community-view').textContent, /본인 글만/);
    assert.ok(document.querySelector('#community-view a[href="/community/5"]'));
  });
});
