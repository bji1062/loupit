// web/assets/js/community.js — SC15 커뮤니티 화면(SP-COMM-8, FRD/14, T-14.6.2~14.6.5).
// 셸(community/index.html) 하나 위에서 `location.pathname` 으로 목록·상세·작성·수정 4화면을 가른다.
// 열람은 익명(목록 apiFetch), 상세·댓글은 credentialed GET(is_mine·liked), 쓰기는 세션+CSRF(apiSend).
// 렌더는 전부 `textContent`/`createElement`(dom.js `el`) — 제목·본문·닉네임·회사명은 사용자 입력이라
// 표시 계층 이스케이프가 방어선이다(NFR21). innerHTML 은 어디에도 없다.
//
// 순수 함수(라우터·쿼리·포맷·초안·오류 문구·렌더러)는 export 하고, 배선은 `initCommunity()` 안에서만
// 한다 — 셸 루트(#community-view)가 있을 때만 자동 초기화하므로 node:test import 시 부작용 0.

import {
  listPosts, getPost, getComments, createPost, updatePost, deletePost, createComment, deleteComment,
  toggleLike, submitReport, searchCompanies, getMe, ApiError,
} from './api.js';
// 로그인 상태 판정은 헤더 진입점과 **같은 3분기**를 쓴다(404=off / 401=anon / 200=member).
import { authStateFrom, OFF_CACHE_KEY } from './authnav.js';
import { el } from './dom.js';
import { store } from './store.js';

export const BASE = '/community/';

// 카테고리(PLAN D-4 확정): `전체`는 카테고리가 아니라 목록 필터(빈 코드). 공지는 운영자만 쓴다(서버 403).
export const CATEGORIES = [
  { code: '', label: '전체' },
  { code: 'notice', label: '공지' },
  { code: 'free', label: '자유' },
  { code: 'career', label: '이직 고민' },
  { code: 'suggestion', label: '건의사항' },
];
export const CATEGORY_LABELS = Object.fromEntries(CATEGORIES.filter((c) => c.code).map((c) => [c.code, c.label]));
// 정렬 3종 — 조회순은 없다(조회수를 수집하지 않는다: 봇 트래픽이 실사용의 수백 배라 거짓 숫자가 된다).
export const SORTS = [
  { code: 'latest', label: '최신' },
  { code: 'comments', label: '댓글' },
  { code: 'likes', label: '좋아요' },
];
export const PAGE_LIMIT = 20;      // 목록 한 페이지(키셋 `before`)
export const COMMENT_LIMIT = 50;   // 댓글 한 페이지(키셋 `after`, 아래로 자란다)
// 입력 한도 = 서버 계약(FR-124·127·130). 클라이언트는 maxlength·카운터로 미리 막고, 최종 판정은 서버 422.
export const TITLE_MAX = 100;
export const BODY_MAX = 5000;
export const COMMENT_MAX = 1000;
export const REPORT_DETAIL_MAX = 300;
export const REPORT_REASONS = [
  { code: 'spam', label: '스팸·광고' },
  { code: 'abuse', label: '욕설·비방' },
  { code: 'privacy', label: '개인정보 노출' },
  { code: 'other', label: '기타' },
];

// ── 순수: pathname → 화면. 모르는 경로는 전부 목록(막다른 화면을 만들지 않는다) ──
export function routeFor(pathname) {
  const p = String(pathname || '');
  if (p === '/community' || p === '/community/') return { view: 'list' };
  if (p === '/community/write' || p === '/community/write/') return { view: 'write' };
  let m = /^\/community\/([1-9][0-9]*)\/?$/.exec(p);
  if (m) return { view: 'detail', id: Number(m[1]) };
  m = /^\/community\/([1-9][0-9]*)\/edit\/?$/.exec(p);
  if (m) return { view: 'edit', id: Number(m[1]) };
  return { view: 'list' };
}

// ── 순수: 목록 쿼리(?category=&sort=) 왕복 — 새로고침·뒤로가기에서 필터가 보존된다 ──
export function listQueryFrom(search) {
  let p;
  try { p = new URLSearchParams(search || ''); } catch { p = new URLSearchParams(); }
  const cat = p.get('category') || '';
  const sort = p.get('sort') || 'latest';
  return {
    category: CATEGORY_LABELS[cat] ? cat : '',
    sort: SORTS.some((s) => s.code === sort) ? sort : 'latest',
  };
}
export function listUrl(category, sort) {
  const p = new URLSearchParams();
  if (category) p.set('category', category);
  if (sort && sort !== 'latest') p.set('sort', sort);
  const q = p.toString();
  return BASE + (q ? '?' + q : '');
}

// ── 순수: 포맷·판정 ──
export function fmtDate(iso) {
  const m = /^(\d{4}-\d{2}-\d{2})/.exec(String(iso || ''));
  return m ? m[1] : '';
}
export function fmtCount(n) {
  const v = Number(n);
  return Number.isFinite(v) && v > 0 ? Math.floor(v).toLocaleString('ko-KR') : '0';
}
// "재직자" 배지 = 글쓴이의 재직 인증 회사가 **이 글에 태그된 회사**일 때만. 다른 회사 재직자는 배지 없음
// (배지는 "이 회사 이야기를 그 회사 사람이 한다"는 뜻이지 일반 신분 표시가 아니다).
export function isVerifiedFor(post) {
  return !!(post && post.verified_comp_nm && post.comp && post.comp.comp_nm === post.verified_comp_nm);
}
export function loginHref(path) { return '/login?next=' + encodeURIComponent(path); }
// 프로브 판단 보류(null: 네트워크 실패 등)는 anon 으로 표시한다 — 쓰기 버튼이 로그인 링크가 되는 쪽이
// 아예 사라지는 쪽보다 낫다(열람은 어차피 영향 없음). off 만 쓰기 UI 를 감춘다.
export function uiAuthState(state) { return state === 'off' || state === 'member' ? state : 'anon'; }
// 회사 태그 링크는 정적 회사 페이지(`/company/{slug}`)다. 슬러그가 계약 밖 문자열이면 링크를 만들지
// 않는다(404 로 가는 링크보다 링크 없음이 낫다 — edits.js 의 같은 판단).
export function companyTagHref(slug) {
  return typeof slug === 'string' && /^[a-z0-9][a-z0-9-]*$/i.test(slug) ? '/company/' + slug : null;
}

// ── 초안(localStorage, 화면별 키, 24h) — store.js inputDraft 와 같은 규약 ──
// 작성 중 회사 페이지를 보러 가거나 로그인하러 갔다 와도 입력이 남는다. TTL 을 두는 이유도 같다:
// 초안은 "방금 하던 것"이지 보관물이 아니다.
export const DRAFT_TTL_MS = 24 * 60 * 60 * 1000;
const DRAFT_V = 1;
export function draftKey(view, id) {
  return 'loupit.community.draft:' + (view === 'edit' ? 'edit:' + id : 'write');
}
function hasDraftContent(d) {
  if (!d || typeof d !== 'object') return false;
  return !!(String(d.title || '').trim() || String(d.body || '').trim() || d.comp);
}
export const draft = {
  save(key, data, now = Date.now()) {
    if (!hasDraftContent(data)) { store.remove(key); return false; } // 빈 초안은 지운다(낡은 것이 되살아나지 않게)
    return store.set(key, { v: DRAFT_V, savedAt: now, draft: data });
  },
  load(key, now = Date.now()) {
    const env = store.get(key);
    if (!env || env.v !== DRAFT_V || typeof env.savedAt !== 'number' || !env.draft) { store.remove(key); return null; }
    if (now - env.savedAt > DRAFT_TTL_MS) { store.remove(key); return null; }
    return hasDraftContent(env.draft) ? env.draft : null;
  },
  clear(key) { store.remove(key); },
};

// ── 순수: 댓글 응답 봉투 — `{items, next_after}` 가 계약이지만 키가 없을 때도 죽지 않는다 ──
export function itemsOf(data) {
  if (Array.isArray(data)) return data;
  return data && Array.isArray(data.items) ? data.items : [];
}
export function nextAfterOf(data, limit) {
  if (data && !Array.isArray(data) && Object.prototype.hasOwnProperty.call(data, 'next_after')) {
    return data.next_after == null ? null : data.next_after;
  }
  const items = itemsOf(data);
  if (!items.length || items.length < limit) return null;
  const last = items[items.length - 1];
  return last && last.comment_id != null ? last.comment_id : null;
}

// ── 순수: ApiError → 문구. 서버 422 detail 은 노출하지 않는다(NFR31) — 한도를 우리가 안다 ──
export function errorMessageFor(err, phase, extra = {}) {
  if (!(err instanceof ApiError)) return '네트워크 오류예요. 잠시 후 다시 시도해주세요.';
  const s = err.status;
  if (s === 401) return '로그인이 필요해요.';
  if (s === 403) return phase === 'post' && extra.category === 'notice' ? '공지는 운영자만 쓸 수 있어요.' : '권한이 없어요.';
  if (s === 404) return '삭제되었거나 숨겨진 글입니다.';
  if (s === 409) return phase === 'report' ? '이미 신고했어요.' : '이미 처리된 요청이에요.';
  if (s === 422) {
    if (phase === 'comment') return '댓글은 1~1,000자예요.';
    if (phase === 'report') return '설명은 300자까지예요.';
    return '제목은 1~100자, 본문은 1~5,000자이고 링크는 3개까지 넣을 수 있어요.';
  }
  if (s === 429) return '오늘 쓸 수 있는 한도를 넘었어요. 내일 다시 시도해주세요.';
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}

// ── 렌더러(순수: 입력 → 요소. 이벤트는 ctx 콜백으로만) ───────────────────────
function companyNode(comp) {
  if (!comp || !comp.comp_nm) return null;
  const href = companyTagHref(comp.slug);
  return href ? el('a', { class: 'cm-comp', href, text: comp.comp_nm })
    : el('span', { class: 'cm-comp-text', text: comp.comp_nm });
}
function metaNodes(post) {
  const out = [el('span', { class: 'cm-nick', text: post.nickname || '(탈퇴)' })];
  if (isVerifiedFor(post)) out.push(el('span', { class: 'cm-badge', text: '재직자' }));
  const comp = companyNode(post.comp);
  if (comp) out.push(comp);
  out.push(el('time', { class: 'cm-date', datetime: post.created_at || '', text: fmtDate(post.created_at) }));
  return out;
}

/** 목록 행. 조회수 없음(수집하지 않는다). */
export function renderListRow(post) {
  const li = el('li', { class: 'cm-row' });
  li.append(el('span', { class: 'cm-cat', text: CATEGORY_LABELS[post.category] || post.category || '' }));
  li.append(el('a', { class: 'cm-title', href: BASE + post.post_id, text: post.title || '' }));
  const meta = el('span', { class: 'cm-meta' }, ...metaNodes(post));
  meta.append(el('span', { class: 'cm-cnt', text: '댓글 ' + fmtCount(post.comment_cnt) }));
  meta.append(el('span', { class: 'cm-cnt', text: '좋아요 ' + fmtCount(post.like_cnt) }));
  li.append(meta);
  return li;
}

/** 신고 버튼 + 인라인 폼(사유 4종 + 설명 300자). 202 → 접수 문구, 409 → 이미 신고. member 전용. */
function reportControl(ctx, targetType, targetId) {
  const wrap = el('div', { class: 'cm-report-wrap' });
  const btn = el('button', { type: 'button', class: 'cm-link cm-report', text: '신고' });
  const slot = el('div', { class: 'cm-report-slot' });
  btn.addEventListener('click', () => {
    if (slot.querySelector('form')) { slot.textContent = ''; return; } // 토글 닫기
    slot.textContent = '';
    slot.append(reportForm(targetType, targetId, slot));
  });
  wrap.append(btn, slot);
  return wrap;
}
function reportForm(targetType, targetId, slot) {
  const form = el('form', { class: 'cm-report-form', novalidate: '' });
  const sel = el('select', { name: 'reason', 'aria-label': '신고 사유' });
  for (const r of REPORT_REASONS) sel.append(el('option', { value: r.code, text: r.label }));
  const ta = el('textarea', { name: 'detail', maxlength: String(REPORT_DETAIL_MAX), rows: '3', 'aria-label': '신고 설명', placeholder: '설명(선택, 300자까지)' });
  const err = el('p', { class: 'cm-form-error', role: 'alert' }); err.hidden = true;
  const submit = el('button', { type: 'submit', class: 'cm-btn cm-btn--sm', text: '신고하기' });
  const cancel = el('button', { type: 'button', class: 'cm-link', text: '취소' });
  cancel.addEventListener('click', () => { slot.textContent = ''; });
  const row = el('div', { class: 'cm-form-row' }, submit, cancel);
  form.append(sel, ta, err, row);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    err.hidden = true; submit.disabled = true;
    try {
      await submitReport({ target_type: targetType, target_id: targetId, reason: sel.value, detail: ta.value.trim() });
      slot.textContent = '';
      slot.append(el('p', { class: 'cm-report-ok', role: 'status', text: '접수됐습니다. 운영자가 확인할게요.' }));
    } catch (er) {
      err.textContent = errorMessageFor(er, 'report'); err.hidden = false; submit.disabled = false;
    }
  });
  return form;
}

/**
 * 상세 본문. ctx.auth: member → 좋아요 버튼·신고·(본인) 수정/삭제 / anon → 좋아요는 로그인 링크 /
 * off → 쓰기 UI 없음(M9 꺼진 배포엔 커뮤니티 라우트도 없다 — 방어적).
 */
export function renderPostView(post, ctx) {
  const art = el('article', { class: 'cm-post' });
  const head = el('header', { class: 'cm-post-head' });
  head.append(el('span', { class: 'cm-cat', text: CATEGORY_LABELS[post.category] || post.category || '' }));
  head.append(el('h2', { class: 'cm-post-title', text: post.title || '' }));
  const meta = el('p', { class: 'cm-meta' }, ...metaNodes(post));
  if (post.edited) meta.append(el('span', { class: 'cm-edited', text: '(수정됨)' }));
  head.append(meta);
  art.append(head);
  art.append(el('div', { class: 'cm-body', text: post.body || '' })); // 줄바꿈은 CSS white-space:pre-wrap 이 보존

  const actions = el('div', { class: 'cm-actions' });
  const likeText = '좋아요 ' + fmtCount(post.like_cnt);
  if (ctx.auth === 'member') {
    const btn = el('button', { type: 'button', class: 'cm-like', 'aria-pressed': post.liked ? 'true' : 'false', text: likeText });
    btn.addEventListener('click', () => { if (typeof ctx.onLike === 'function') ctx.onLike(btn); });
    actions.append(btn);
    actions.append(reportControl(ctx, 'post', post.post_id));
    if (post.is_mine) {
      const own = el('span', { class: 'cm-own' });
      own.append(navLink(ctx, { class: 'cm-link cm-edit', href: BASE + post.post_id + '/edit', text: '수정' }));
      const del = el('button', { type: 'button', class: 'cm-link cm-delete', text: '삭제' });
      del.addEventListener('click', () => { if (typeof ctx.onDelete === 'function') ctx.onDelete(del); });
      own.append(del);
      actions.append(own);
    }
  } else if (ctx.auth === 'anon') {
    actions.append(el('a', { class: 'cm-like', href: loginHref(BASE + post.post_id), text: likeText }));
  } else {
    actions.append(el('span', { class: 'cm-like-cnt', text: likeText }));
  }
  art.append(actions);
  return art;
}

/** 댓글 한 건. 삭제 댓글은 자리만("삭제된 댓글입니다"). opts.compNm = 글의 회사 태그명(배지 판정). */
export function renderComment(c, ctx, opts = {}) {
  const li = el('li', { class: 'cm-comment' });
  if (c.deleted || c.body == null) {
    li.append(el('p', { class: 'cm-c-body cm-c-deleted', text: '삭제된 댓글입니다' }));
    return li;
  }
  const head = el('p', { class: 'cm-meta' });
  head.append(el('span', { class: 'cm-nick', text: c.nickname || '(탈퇴)' }));
  if (c.verified_comp_nm && opts.compNm && c.verified_comp_nm === opts.compNm) head.append(el('span', { class: 'cm-badge', text: '재직자' }));
  head.append(el('time', { class: 'cm-date', datetime: c.created_at || '', text: fmtDate(c.created_at) }));
  li.append(head);
  li.append(el('p', { class: 'cm-c-body', text: c.body }));
  if (ctx.auth === 'member') {
    const acts = el('div', { class: 'cm-c-actions' });
    acts.append(reportControl(ctx, 'comment', c.comment_id));
    if (c.is_mine) {
      const del = el('button', { type: 'button', class: 'cm-link cm-c-delete', text: '삭제' });
      del.addEventListener('click', () => { if (typeof ctx.onDeleteComment === 'function') ctx.onDeleteComment(c, li); });
      acts.append(del);
    }
    li.append(acts);
  }
  return li;
}

// ── 내부 링크: 새 문서를 받지 않고 History API 로 화면만 바꾼다(수정키·중클릭은 브라우저에 맡긴다) ──
function navLink(ctx, attrs) {
  const a = el('a', attrs);
  a.addEventListener('click', (e) => {
    if (e.defaultPrevented || e.button || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    if (typeof ctx.navigate !== 'function') return;
    e.preventDefault();
    ctx.navigate(a.getAttribute('href'));
  });
  return a;
}
function counter(len, max) { return fmtCount(len) + ' / ' + fmtCount(max); }
function confirmWith(ctx, msg) {
  const fn = ctx.win && typeof ctx.win.confirm === 'function' ? ctx.win.confirm : null;
  return fn ? fn.call(ctx.win, msg) !== false : true;
}

// ── 화면 1: 목록 ────────────────────────────────────────────────────────────
async function viewList(ctx, seq, q) {
  ctx.doc.title = '커뮤니티 — jobcho.wiki 잡초';
  const sec = el('section', { class: 'cm-list', 'aria-label': '글 목록' });
  const bar = el('div', { class: 'cm-toolbar' });
  const cats = el('nav', { class: 'cm-cats', 'aria-label': '카테고리' });
  for (const c of CATEGORIES) {
    const a = navLink(ctx, { href: listUrl(c.code, q.sort), text: c.label });
    if (c.code === q.category) a.setAttribute('aria-current', 'page');
    cats.append(a);
  }
  const sortWrap = el('label', { class: 'cm-sort' }, '정렬 ');
  const sel = el('select', { 'aria-label': '정렬' });
  for (const s of SORTS) sel.append(el('option', { value: s.code, text: s.label }));
  sel.value = q.sort;
  sel.addEventListener('change', () => ctx.navigate(listUrl(q.category, sel.value)));
  sortWrap.append(sel);
  bar.append(cats, sortWrap);
  if (ctx.auth === 'member') bar.append(navLink(ctx, { class: 'cm-btn cm-write', href: BASE + 'write', text: '글쓰기' }));
  else if (ctx.auth === 'anon') bar.append(el('a', { class: 'cm-btn cm-write', href: loginHref(BASE + 'write'), text: '글쓰기' }));

  const ul = el('ul', { class: 'cm-rows' });
  const empty = el('p', { class: 'cm-empty', text: '아직 글이 없어요. 첫 글을 남겨보세요.' }); empty.hidden = true;
  const err = el('p', { class: 'cm-error', role: 'alert' }); err.hidden = true;
  const errMsg = el('span');
  const retry = el('button', { type: 'button', text: '다시 시도' });
  err.append(errMsg, ' ', retry);
  const more = el('button', { type: 'button', class: 'cm-btn cm-btn--ghost cm-more', text: '더 보기' }); more.hidden = true;
  sec.append(bar, ul, empty, err, more);
  ctx.root.append(sec);

  let cursor = null;
  async function load(before) {
    err.hidden = true; more.disabled = true; retry.disabled = true;
    try {
      const data = await listPosts({ category: q.category, sort: q.sort, limit: PAGE_LIMIT, before });
      if (seq !== ctx.seq) return;
      for (const p of itemsOf(data)) {
        const li = renderListRow(p);
        const a = li.querySelector('a.cm-title');
        a.addEventListener('click', (e) => {
          if (e.button || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
          e.preventDefault(); ctx.navigate(a.getAttribute('href'));
        });
        ul.append(li);
      }
      cursor = data && data.next_before != null ? data.next_before : null;
      empty.hidden = ul.children.length > 0;
      more.hidden = cursor == null;
    } catch {
      if (seq !== ctx.seq) return;
      errMsg.textContent = before ? '다음 글을 불러오지 못했어요.' : '글 목록을 불러오지 못했어요.';
      err.hidden = false;
    } finally {
      more.disabled = false; retry.disabled = false;
    }
  }
  retry.addEventListener('click', () => load(cursor));
  more.addEventListener('click', () => load(cursor));
  await load(null);
}

// ── 화면 2: 상세 + 댓글 ─────────────────────────────────────────────────────
async function viewDetail(ctx, seq, id) {
  const wrap = el('div', { class: 'cm-detail' });
  wrap.append(navLink(ctx, { class: 'cm-back', href: BASE, text: '← 목록' }));
  ctx.root.append(wrap);

  let post;
  try {
    post = await getPost(id);
  } catch (e) {
    if (seq !== ctx.seq) return;
    if (e instanceof ApiError && e.status === 404) {
      ctx.doc.title = '글을 찾을 수 없어요 — 커뮤니티 — jobcho.wiki 잡초';
      wrap.append(el('p', { class: 'cm-notfound', text: '삭제되었거나 숨겨진 글입니다.' }));
      wrap.append(navLink(ctx, { class: 'cm-btn cm-btn--ghost', href: BASE, text: '목록으로' }));
      return;
    }
    const err = el('p', { class: 'cm-error', role: 'alert', text: '글을 불러오지 못했어요. ' });
    const retry = el('button', { type: 'button', text: '다시 시도' });
    retry.addEventListener('click', () => renderRoute(ctx));
    err.append(retry); wrap.append(err);
    return;
  }
  if (seq !== ctx.seq) return;
  ctx.doc.title = (post.title || '글') + ' — 커뮤니티 — jobcho.wiki 잡초';

  const status = el('p', { class: 'cm-error', role: 'alert' }); status.hidden = true;
  const fail = (msg) => { status.textContent = msg; status.hidden = false; };

  const pctx = {
    ...ctx,
    onLike: async (btn) => {
      btn.disabled = true; status.hidden = true;
      try {
        const { data } = await toggleLike(id);
        btn.setAttribute('aria-pressed', data && data.liked ? 'true' : 'false');
        btn.textContent = '좋아요 ' + fmtCount(data && data.like_cnt);
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) { ctx.win.location.href = loginHref(BASE + id); return; }
        fail(errorMessageFor(e, 'like'));
      } finally { btn.disabled = false; }
    },
    onDelete: async (btn) => {
      if (!confirmWith(ctx, '이 글을 삭제할까요? 되돌릴 수 없어요.')) return;
      btn.disabled = true; status.hidden = true;
      try { await deletePost(id); draft.clear(draftKey('edit', id)); ctx.navigate(BASE, { replace: true }); }
      catch (e) { fail(errorMessageFor(e, 'delete')); btn.disabled = false; }
    },
    onDeleteComment: async (c, li) => {
      if (!confirmWith(ctx, '이 댓글을 삭제할까요?')) return;
      status.hidden = true;
      try {
        await deleteComment(id, c.comment_id);
        li.replaceWith(renderComment({ ...c, deleted: true, body: null }, pctx));
        commentCnt = Math.max(0, commentCnt - 1); h.textContent = '댓글 ' + fmtCount(commentCnt);
      } catch (e) { fail(errorMessageFor(e, 'delete')); }
    },
  };
  wrap.append(renderPostView(post, pctx), status);

  // 댓글: 오래된 순, `after` 커서로 아래로 이어 받는다.
  const compNm = post.comp && post.comp.comp_nm;
  let commentCnt = Number(post.comment_cnt) || 0;
  const csec = el('section', { class: 'cm-comments', 'aria-label': '댓글' });
  const h = el('h3', { text: '댓글 ' + fmtCount(commentCnt) });
  const ul = el('ul', { class: 'cm-comment-list' });
  const cerr = el('p', { class: 'cm-error', role: 'alert' }); cerr.hidden = true;
  const more = el('button', { type: 'button', class: 'cm-btn cm-btn--ghost cm-c-more', text: '댓글 더 보기' }); more.hidden = true;
  csec.append(h, ul, cerr, more);
  let lastId = null, cursor = null;
  async function loadComments(after) {
    cerr.hidden = true; more.disabled = true;
    try {
      const data = await getComments(id, after, COMMENT_LIMIT);
      if (seq !== ctx.seq) return;
      const items = itemsOf(data);
      for (const c of items) ul.append(renderComment(c, pctx, { compNm }));
      if (items.length) lastId = items[items.length - 1].comment_id;
      cursor = nextAfterOf(data, COMMENT_LIMIT);
      more.hidden = cursor == null;
    } catch {
      if (seq !== ctx.seq) return;
      cerr.textContent = '댓글을 불러오지 못했어요.'; cerr.hidden = false;
    } finally { more.disabled = false; }
  }
  more.addEventListener('click', () => loadComments(cursor));

  if (ctx.auth === 'member') {
    const form = el('form', { class: 'cm-comment-form', novalidate: '' });
    const ta = el('textarea', { name: 'body', maxlength: String(COMMENT_MAX), rows: '3', 'aria-label': '댓글 입력', placeholder: '댓글을 남겨보세요(1,000자까지)' });
    const cnt = el('span', { class: 'cm-counter', text: counter(0, COMMENT_MAX) });
    const ferr = el('p', { class: 'cm-form-error', role: 'alert' }); ferr.hidden = true;
    const submit = el('button', { type: 'submit', class: 'cm-btn cm-btn--sm', text: '댓글 등록' });
    ta.addEventListener('input', () => { cnt.textContent = counter(ta.value.length, COMMENT_MAX); });
    form.append(ta, cnt, ferr, submit);
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      ferr.hidden = true;
      const body = ta.value.trim();
      if (!body) { ferr.textContent = '댓글 내용을 입력해주세요.'; ferr.hidden = false; return; }
      submit.disabled = true;
      try {
        await createComment(id, body);
        ta.value = ''; cnt.textContent = counter(0, COMMENT_MAX);
        commentCnt += 1; h.textContent = '댓글 ' + fmtCount(commentCnt);
        await loadComments(lastId); // 마지막으로 본 댓글 뒤(after)만 받아 붙인다 — 새 댓글이 아래에 나타난다
      } catch (er) {
        if (er instanceof ApiError && er.status === 401) { ctx.win.location.href = loginHref(BASE + id); return; }
        ferr.textContent = errorMessageFor(er, 'comment'); ferr.hidden = false;
      } finally { submit.disabled = false; }
    });
    csec.append(form);
  } else if (ctx.auth === 'anon') {
    const p = el('p', { class: 'cm-hint' }, '댓글을 남기려면 ');
    p.append(el('a', { href: loginHref(BASE + id), text: '로그인' }), '이 필요해요.');
    csec.append(p);
  }
  wrap.append(csec);
  await loadComments(null);
}

// ── 화면 3·4: 작성 / 수정 ───────────────────────────────────────────────────
async function viewForm(ctx, seq, r) {
  const mode = r.view; const id = r.id;
  const here = mode === 'edit' ? BASE + id + '/edit' : BASE + 'write';
  ctx.doc.title = (mode === 'edit' ? '글 수정' : '글쓰기') + ' — 커뮤니티 — jobcho.wiki 잡초';
  const wrap = el('div', { class: 'cm-formwrap' });
  ctx.root.append(wrap);

  if (ctx.auth === 'off') {
    wrap.append(el('p', { class: 'cm-notfound', text: '지금은 글을 쓸 수 없어요.' }));
    wrap.append(navLink(ctx, { class: 'cm-btn cm-btn--ghost', href: BASE, text: '목록으로' }));
    return;
  }
  if (ctx.auth !== 'member') {
    const card = el('div', { class: 'cm-card' });
    card.append(el('p', { text: '글과 댓글을 쓰려면 로그인이 필요해요. 둘러보기는 로그인 없이 그대로예요.' }));
    card.append(el('a', { class: 'cm-btn cm-login', href: loginHref(here), text: '로그인하고 계속' }));
    card.append(navLink(ctx, { class: 'cm-link', href: BASE, text: '목록으로' }));
    wrap.append(card);
    return;
  }

  let base = { category: 'free', title: '', body: '', comp: null };
  if (mode === 'edit') {
    let post;
    try { post = await getPost(id); } catch (e) {
      if (seq !== ctx.seq) return;
      wrap.append(el('p', { class: 'cm-notfound', text: errorMessageFor(e, 'load') }));
      wrap.append(navLink(ctx, { class: 'cm-btn cm-btn--ghost', href: BASE, text: '목록으로' }));
      return;
    }
    if (seq !== ctx.seq) return;
    if (!post.is_mine) {
      wrap.append(el('p', { class: 'cm-notfound', text: '본인 글만 수정할 수 있어요.' }));
      wrap.append(navLink(ctx, { class: 'cm-btn cm-btn--ghost', href: BASE + id, text: '글로 돌아가기' }));
      return;
    }
    base = {
      category: post.category, title: post.title || '', body: post.body || '',
      comp: post.comp ? { comp_id: post.comp.comp_id, comp_nm: post.comp.comp_nm } : null,
    };
  }
  const key = draftKey(mode, id);
  const saved = draft.load(key);
  const init = saved ? { ...base, ...saved } : base;
  if (mode === 'edit') init.category = base.category; // 수정은 카테고리를 받지 않는다(FR-125) — 잠근다
  wrap.append(el('h2', { class: 'cm-form-title', text: mode === 'edit' ? '글 수정' : '글쓰기' }));
  wrap.append(buildForm(ctx, { mode, id, init, key, here }));
}

function buildForm(ctx, { mode, id, init, key, here }) {
  const form = el('form', { class: 'cm-form', novalidate: '' });
  // 필드 = div > label[for] + 컨트롤(+ 카운터·후보 목록). label 로 감싸지 않는 이유: 회사 후보 `ul` 을
  // label 안에 두면 후보 클릭이 label 활성화(입력 포커스)로도 번진다.
  const field = (labelText, control, extra) => {
    const wrap = el('div', { class: 'cm-field' });
    wrap.append(el('label', { class: 'cm-field-label', for: control.id, text: labelText }), control);
    if (extra) wrap.append(extra);
    return wrap;
  };
  // 카테고리 — 공지도 목록에 둔다. 운영자가 아니면 서버가 403 → "공지는 운영자만 쓸 수 있어요".
  const sel = el('select', { name: 'category', id: 'cm-f-category' });
  for (const c of CATEGORIES) if (c.code) sel.append(el('option', { value: c.code, text: c.label }));
  sel.value = init.category || 'free';
  if (mode === 'edit') sel.disabled = true;
  // 제목·본문 + 카운터
  const titleIn = el('input', { name: 'title', id: 'cm-f-title', type: 'text', maxlength: String(TITLE_MAX), autocomplete: 'off', required: '' });
  titleIn.value = init.title || '';
  const titleCnt = el('span', { class: 'cm-counter', 'data-for': 'title', text: counter(titleIn.value.length, TITLE_MAX) });
  const bodyIn = el('textarea', { name: 'body', id: 'cm-f-body', maxlength: String(BODY_MAX), rows: '12', required: '' });
  bodyIn.value = init.body || '';
  const bodyCnt = el('span', { class: 'cm-counter', 'data-for': 'body', text: counter(bodyIn.value.length, BODY_MAX) });
  // 회사 태그(선택): 등록 회사 검색 → 선택 → 칩. 해제 가능.
  let comp = init.comp && Number.isInteger(init.comp.comp_id) ? { comp_id: init.comp.comp_id, comp_nm: String(init.comp.comp_nm || '') } : null;
  const compIn = el('input', { name: 'comp', id: 'cm-f-comp', type: 'text', autocomplete: 'off', placeholder: '회사명 검색(선택)' });
  const results = el('ul', { class: 'cm-comp-results', role: 'listbox', 'aria-label': '회사 후보' }); results.hidden = true;
  const chipWrap = el('div', { class: 'cm-comp-chipwrap' });
  const errBox = el('p', { class: 'cm-form-error', role: 'alert' }); errBox.hidden = true;

  const snapshot = () => ({ category: sel.value, title: titleIn.value, body: bodyIn.value, comp });
  const persist = () => { draft.save(key, snapshot()); };
  function renderChip() {
    chipWrap.textContent = '';
    if (comp) {
      const chip = el('span', { class: 'cm-comp-chip', text: comp.comp_nm + ' ' });
      const x = el('button', { type: 'button', class: 'cm-chip-x', 'aria-label': '회사 태그 해제', text: '×' });
      x.addEventListener('click', () => { comp = null; renderChip(); persist(); });
      chip.append(x);
      chipWrap.append(chip);
      compIn.hidden = true;
    } else compIn.hidden = false;
  }
  renderChip();
  let seq = 0, timer = null;
  compIn.addEventListener('input', () => {
    clearTimeout(timer);
    const q = compIn.value.trim();
    if (!q) { results.hidden = true; results.textContent = ''; return; }
    timer = setTimeout(async () => {
      const s = ++seq;
      try {
        const rows = await searchCompanies(q);
        if (s !== seq) return;
        results.textContent = '';
        if (!rows || !rows.length) { results.hidden = true; return; }
        for (const r of rows) {
          const li = el('li', { role: 'option', tabindex: '0', text: r.comp_nm });
          if (r.industry_nm) li.append(el('span', { class: 'ind', text: r.industry_nm }));
          const pick = () => { comp = { comp_id: r.comp_id, comp_nm: r.comp_nm }; compIn.value = ''; results.hidden = true; results.textContent = ''; renderChip(); persist(); };
          li.addEventListener('click', pick);
          li.addEventListener('keydown', (e) => { if (e.key === 'Enter') pick(); });
          results.append(li);
        }
        results.hidden = false;
      } catch { /* 검색 실패는 조용히 — 태그는 선택 사항 */ }
    }, 250);
  });
  titleIn.addEventListener('input', () => { titleCnt.textContent = counter(titleIn.value.length, TITLE_MAX); persist(); });
  bodyIn.addEventListener('input', () => { bodyCnt.textContent = counter(bodyIn.value.length, BODY_MAX); persist(); });
  sel.addEventListener('change', persist);

  const submit = el('button', { type: 'submit', class: 'cm-btn', text: mode === 'edit' ? '수정' : '등록' });
  const cancel = navLink(ctx, { class: 'cm-link', href: mode === 'edit' ? BASE + id : BASE, text: '취소' });
  form.append(
    field('카테고리', sel),
    field('제목', titleIn, titleCnt),
    field('본문', bodyIn, bodyCnt),
    field('회사 태그', compIn, results), chipWrap,
    errBox,
    el('div', { class: 'cm-form-row' }, submit, cancel),
  );
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errBox.hidden = true; errBox.textContent = '';
    const title = titleIn.value.trim(), body = bodyIn.value.trim();
    if (!title || !body) { errBox.textContent = '제목과 본문을 입력해주세요.'; errBox.hidden = false; return; }
    submit.disabled = true;
    try {
      let postId = id;
      const comp_id = comp ? comp.comp_id : null;
      if (mode === 'edit') await updatePost(id, { title, body, comp_id });
      else { const { data } = await createPost({ category: sel.value, title, body, comp_id }); postId = data && data.post_id; }
      draft.clear(key); // 성공했을 때만 — 실패하면 초안이 남아 다시 시도할 수 있다
      ctx.navigate(BASE + postId);
    } catch (err) {
      errBox.textContent = errorMessageFor(err, 'post', { category: sel.value });
      if (err instanceof ApiError && err.status === 401) errBox.append(' ', el('a', { href: loginHref(here), text: '로그인하기' }));
      errBox.hidden = false;
      submit.disabled = false;
    }
  });
  return form;
}

// ── 라우팅·부팅 ──────────────────────────────────────────────────────────────
// 화면 전환마다 seq 를 올린다 — 이전 화면의 늦은 응답이 새 화면에 끼어들지 않게(경합 폐기).
async function renderRoute(ctx) {
  const seq = ++ctx.seq;
  const loc = ctx.win.location;
  const r = routeFor(loc.pathname);
  ctx.root.textContent = '';
  if (r.view === 'list') return viewList(ctx, seq, listQueryFrom(loc.search));
  if (r.view === 'detail') return viewDetail(ctx, seq, r.id);
  return viewForm(ctx, seq, r);
}

// 헤더(authnav.js)와 같은 프로브. M9 꺼짐이 세션 캐시에 있으면 요청 없이 off.
async function probeAuth(win) {
  try { if (win && win.sessionStorage && win.sessionStorage.getItem(OFF_CACHE_KEY) === '1') return { state: 'off', nickname: '' }; } catch { /* 무시 */ }
  try {
    const res = await getMe();
    return { state: authStateFrom(res, null), nickname: (res && res.data && res.data.nickname) || '' };
  } catch (err) {
    return { state: authStateFrom(null, err), nickname: '' };
  }
}

/** 부팅. 셸 루트(#community-view)가 없으면 아무것도 하지 않는다. 테스트에서 doc/win 을 주입한다. */
export async function initCommunity({ doc = globalThis.document, win = globalThis.window } = {}) {
  const root = doc && doc.getElementById && doc.getElementById('community-view');
  if (!root) return null;
  const ctx = { doc, win, root, auth: 'anon', nickname: '', seq: 0 };
  const probe = await probeAuth(win);
  ctx.auth = uiAuthState(probe.state); ctx.nickname = probe.nickname;
  ctx.navigate = (href, { replace = false } = {}) => {
    try { win.history[replace ? 'replaceState' : 'pushState']({}, '', href); }
    catch { win.location.href = href; return; } // History API 불가 → 전체 이동으로 폴백
    renderRoute(ctx);
    try { win.scrollTo(0, 0); } catch { /* jsdom 등 */ }
  };
  win.addEventListener('popstate', () => renderRoute(ctx));
  await renderRoute(ctx);
  return ctx;
}

if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('community-view')) {
  initCommunity();
}
