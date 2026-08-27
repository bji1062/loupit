// web/assets/js/api.test.js — SP-FE-6 읽기 전용 API 클라이언트 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-6, TASK/06-프론트엔드.md T-06.6.1·6.2.
// global fetch 목(in-memory) — 실 네트워크 미사용.
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  apiFetch, ApiError, getReference, searchCompanies, getCompany, API_BASE,
  getBenefitsForEdit, createBenefit, updateBenefit, getEdits,
  requestLoginCode, requestEmployCode, login,
  listPosts, getPost, getComments, createPost, updatePost, deletePost,
  createComment, deleteComment, toggleLike, submitReport,
} from './api.js';

// ── fetch 스파이(호출 인자 기록) ────────────────────────────────────────────
let calls;
function mockFetchOk(json) {
  calls = [];
  globalThis.fetch = async (url, opts) => {
    calls.push({ url, opts });
    return { ok: true, status: 200, json: async () => json };
  };
}
function mockFetchStatus(status) {
  calls = [];
  globalThis.fetch = async (url, opts) => {
    calls.push({ url, opts });
    return { ok: false, status, json: async () => ({}) };
  };
}

beforeEach(() => { calls = []; });

// ── T-06.6.1: apiFetch 전송 계약·ApiError·타임아웃/abort·무인증 ────────────
describe('T-06.6.1 apiFetch 전송 계약', () => {
  test('200 응답 → json 반환, GET·API_BASE 경로 조립', async () => {
    mockFetchOk({ hello: 'world' });
    const out = await apiFetch('/reference/all');
    assert.deepEqual(out, { hello: 'world' });
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, API_BASE + '/reference/all');
    assert.equal(calls[0].opts.method, 'GET');
  });

  test('요청 헤더에 Authorization/Cookie 부재, Accept:application/json만', () => {
    mockFetchOk({});
    return apiFetch('/x').then(() => {
      const headers = calls[0].opts.headers;
      assert.equal(headers.Accept, 'application/json');
      assert.equal(headers.Authorization, undefined);
      assert.equal(headers.Cookie, undefined);
    });
  });

  test('스크래핑 방어: X-Loupit-Client 헤더를 반드시 보낸다(제거 시 nginx 게이트로 앱 전체 죽음)', () => {
    mockFetchOk({});
    return apiFetch('/x').then(() => {
      assert.equal(calls[0].opts.headers['X-Loupit-Client'], 'web',
        '이 헤더가 빠지면 데이터 GET이 전부 403 — reference/all·검색·상세 전멸');
    });
  });

  test('credentials: "omit" 전송(자격증명 미전송, NFR16)', async () => {
    mockFetchOk({});
    await apiFetch('/x');
    assert.equal(calls[0].opts.credentials, 'omit');
  });

  test('비-200 → ApiError(status,path) throw', async () => {
    mockFetchStatus(404);
    await assert.rejects(() => apiFetch('/companies/999'), (err) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 404);
      assert.equal(err.path, '/companies/999');
      return true;
    });
  });

  test('timeout 경과 시 내부 AbortController가 abort된다', async () => {
    calls = [];
    let capturedSignal;
    globalThis.fetch = (url, opts) => {
      capturedSignal = opts.signal;
      return new Promise(() => {}); // 영구 대기(실 fetch가 abort로 reject하는 상황을 모사)
    };
    apiFetch('/slow', { timeout: 5 }); // 완료 대기하지 않음(신호만 검증)
    await new Promise((r) => setTimeout(r, 30));
    assert.equal(capturedSignal.aborted, true);
  });

  test('외부 signal.abort → 내부 ctrl도 abort(경합 취소 연결)', async () => {
    let capturedSignal;
    globalThis.fetch = (url, opts) => {
      capturedSignal = opts.signal;
      return new Promise(() => {});
    };
    const outer = new AbortController();
    apiFetch('/x', { signal: outer.signal });
    outer.abort();
    await new Promise((r) => setTimeout(r, 0));
    assert.equal(capturedSignal.aborted, true);
  });

  test('쓰기 헬퍼(post/put/delete) 미노출(INV-1)', async () => {
    const mod = await import('./api.js');
    assert.equal(mod.post, undefined);
    assert.equal(mod.put, undefined);
    assert.equal(mod.del, undefined);
    assert.equal(mod.remove, undefined);
  });
});

// ── T-06.6.2: 엔드포인트 래퍼 getReference·searchCompanies·getCompany ──────
describe('T-06.6.2 엔드포인트 래퍼', () => {
  test('getReference → /reference/all 호출', async () => {
    mockFetchOk({ company_types: [] });
    await getReference();
    assert.equal(calls[0].url, API_BASE + '/reference/all');
  });

  test('searchCompanies → q를 encodeURIComponent로 인코딩해 경로 조립', async () => {
    mockFetchOk([]);
    await searchCompanies('삼성 전자&x');
    assert.equal(calls[0].url, API_BASE + '/companies/search?q=' + encodeURIComponent('삼성 전자&x'));
  });

  test('getCompany → id를 encodeURIComponent로 인코딩해 경로 조립', async () => {
    mockFetchOk({});
    await getCompany('a/b');
    assert.equal(calls[0].url, API_BASE + '/companies/' + encodeURIComponent('a/b'));
  });

  test('무결과(200 [])와 오류(비200)를 호출부가 구분 가능', async () => {
    mockFetchOk([]);
    const empty = await searchCompanies('없는회사');
    assert.deepEqual(empty, []);

    mockFetchStatus(500);
    await assert.rejects(() => searchCompanies('x'), ApiError);
  });
});

// ── SC14 참여(복지 편집) 헬퍼 — apiSend(credentialed·CSRF) / apiFetch(익명) ─────
describe('SC14 참여 헬퍼', () => {
  let sendCalls;
  // apiSend 는 res.text()로 본문을 읽는다(204/JSON/오류 envelope 안전). text() 지원 목.
  function mockSend(status, json) {
    sendCalls = [];
    globalThis.fetch = async (url, opts) => {
      sendCalls.push({ url, opts });
      return { ok: status >= 200 && status < 300, status, text: async () => JSON.stringify(json) };
    };
  }

  test('createBenefit → POST, credentials:include, X-Loupit-Client, JSON 본문', async () => {
    mockSend(201, { benefit: { benefit_id: 5 }, benefits: [] });
    const { status, data } = await createBenefit(10, { benefit_cd: 'meal', benefit_nm: '식대' });
    assert.equal(status, 201);
    assert.equal(sendCalls[0].url, API_BASE + '/companies/10/benefits');
    assert.equal(sendCalls[0].opts.method, 'POST');
    assert.equal(sendCalls[0].opts.credentials, 'include'); // 익명 GET(omit)과 대비
    assert.equal(sendCalls[0].opts.headers['X-Loupit-Client'], 'web'); // CSRF
    assert.equal(JSON.parse(sendCalls[0].opts.body).benefit_cd, 'meal');
    assert.equal(data.benefit.benefit_id, 5);
  });

  test('updateBenefit → PUT /companies/{c}/benefits/{id}', async () => {
    mockSend(200, { benefit: {}, benefits: [] });
    await updateBenefit(10, 7, { base_dtm: 'x', benefit_nm: 'n', qual_yn: false });
    assert.equal(sendCalls[0].opts.method, 'PUT');
    assert.equal(sendCalls[0].url, API_BASE + '/companies/10/benefits/7');
  });

  test('getBenefitsForEdit → GET credentialed(편집용 조회)', async () => {
    mockSend(200, { benefits: [] });
    await getBenefitsForEdit(10);
    assert.equal(sendCalls[0].opts.method, 'GET');
    assert.equal(sendCalls[0].url, API_BASE + '/companies/10/benefits');
    assert.equal(sendCalls[0].opts.credentials, 'include');
  });

  test('updateBenefit 409(선점) → ApiError.data 에 current_benefit 보존', async () => {
    mockSend(409, { current_benefit: { benefit_id: 7 }, benefits: [] });
    await assert.rejects(() => updateBenefit(10, 7, { base_dtm: 'old', benefit_nm: 'n', qual_yn: false }), (err) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 409);
      assert.equal(err.data.current_benefit.benefit_id, 7); // 폼 재조정에 필요
      return true;
    });
  });

  test('getEdits → 익명 GET(credentials:omit)·limit 쿼리', async () => {
    const seen = [];
    globalThis.fetch = async (url, opts) => { seen.push({ url, opts }); return { ok: true, status: 200, json: async () => [] }; };
    await getEdits(10, 50);
    assert.equal(seen[0].opts.method, 'GET');
    assert.equal(seen[0].opts.credentials, 'omit'); // 익명(무쿠키)
    assert.equal(seen[0].url, API_BASE + '/companies/10/edits?limit=50');
  });

  test('getEdits(before) → 키셋 커서 쿼리 부착, 미지정 시 before 파라미터 없음', async () => {
    const seen = [];
    globalThis.fetch = async (url, opts) => { seen.push({ url, opts }); return { ok: true, status: 200, json: async () => [] }; };
    await getEdits(10, 50, 812);
    assert.equal(seen[0].url, API_BASE + '/companies/10/edits?limit=50&before=812');
    await getEdits(10, 50, null);
    assert.equal(seen[1].url.includes('before'), false); // 첫 페이지엔 커서 없음
  });
});

// ── 적대검토 ③: 429 Retry-After → ApiError.retryAfter ────────────────────────
// nginx 메일 리밋(`rate=3r/m`)의 실제 대기는 20초인데 그 값이 응답에 없어 프론트가 "잠시 후"
// 라는 무한정 안내밖에 못 냈다. 엣지가 헤더를 싣고(conf.d/loupit-limits.conf 의 map),
// 여기서 그 값을 구조화해 UI 로 넘긴다. **헤더가 없으면 반드시 null** 이어야 한다 —
// 앱이 내는 429(로그인 시도 상한 등)에 20초를 붙이면 거짓 안내가 되기 때문이다.
describe('429 Retry-After 파싱(ApiError.retryAfter)', () => {
  // apiSend 경로 목: headers.get 을 가진 최소 Response 흉내.
  function mockSendWithHeaders(status, headerMap) {
    globalThis.fetch = async () => ({
      ok: status >= 200 && status < 300,
      status,
      headers: { get: (k) => (k.toLowerCase() === 'retry-after' ? (headerMap['retry-after'] ?? null) : null) },
      text: async () => '',
    });
  }

  test('429 + Retry-After: 20 → retryAfter === 20', async () => {
    mockSendWithHeaders(429, { 'retry-after': '20' });
    await assert.rejects(() => requestLoginCode('a@b.co'), (err) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 429);
      assert.equal(err.retryAfter, 20);
      return true;
    });
  });

  test('429 인데 헤더 없음(앱 발급 429) → retryAfter === null', async () => {
    mockSendWithHeaders(429, {});
    await assert.rejects(() => login('a@b.co', '123456'), (err) => {
      assert.equal(err.retryAfter, null); // "20초 뒤" 안내가 붙으면 안 되는 경로
      return true;
    });
  });

  // delta-seconds = 10진 정수(RFC 9110 §10.2.3). 그 밖은 **전부 null** — `Number()` 로 느슨하게
  // 받으면 `0x14`(→20)·`1e30`·`+20`·`.5` 같은 값이 숫자로 통과해 계약보다 넓어진다.
  test('정수가 아닌 값은 전부 null(억지 해석 금지)', async () => {
    const nonInteger = [
      'Wed, 21 Oct 2015 07:28:00 GMT', '', '  ', 'soon', '-5', 'NaN',
      '0.5', '.5', '+20', '0x14', '1e30', '20s', ' 20 x', 'Infinity',
    ];
    for (const raw of nonInteger) {
      mockSendWithHeaders(429, { 'retry-after': raw });
      await assert.rejects(() => requestLoginCode('a@b.co'), (err) => {
        assert.equal(err.retryAfter, null, `raw=${JSON.stringify(raw)} → null 이어야 함`);
        return true;
      });
    }
  });

  test('앞뒤 공백이 있는 정수는 받는다(헤더 파싱 관용 범위)', async () => {
    mockSendWithHeaders(429, { 'retry-after': ' 20 ' });
    await assert.rejects(() => requestLoginCode('a@b.co'), (err) => {
      assert.equal(err.retryAfter, 20);
      return true;
    });
  });

  test('headers 자체가 없는 응답(익명 apiFetch 목 포함)에도 안전하게 null', async () => {
    mockFetchStatus(429); // headers 프로퍼티 없음
    await assert.rejects(() => apiFetch('/reference/all'), (err) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.retryAfter, null);
      return true;
    });
  });

  test('ApiError 4번째 인자 미지정 시 기본 null(구 호출부 하위호환)', () => {
    assert.equal(new ApiError(500, '/x').retryAfter, null);
  });
});

// ── 적대검토 ⑤: 메일 발송만 타임아웃 20s(엣지 proxy_read_timeout 15s 보다 길게) ──
// 8s 기본값은 nginx 15s 보다 짧아, 제공자가 느릴 때 **서버가 정상 204 를 만드는 도중** 브라우저가
// 먼저 abort 했다 → "네트워크 오류예요"인데 메일은 실제로 나간 상태. 20s 면 엣지가 항상 먼저
// 끊어 브라우저는 확정 상태코드를 받는다. 실제 대기를 재우지 않고 **스케줄된 지연값**을 관측한다.
describe('메일 발송 호출의 타임아웃(⑤)', () => {
  async function captureDelays(fn) {
    const delays = [];
    const realSetTimeout = globalThis.setTimeout;
    globalThis.setTimeout = (cb, ms, ...rest) => { delays.push(ms); return realSetTimeout(cb, ms, ...rest); };
    // ⚠ try/finally 여야 한다 — `fn()` 이 **동기 throw** 하면 Promise 체인이 만들어지기 전이라
    //   .finally 로는 원복이 유실되고, 전역 setTimeout 패치가 이후 테스트로 새어 나간다.
    try { await fn(); } finally { globalThis.setTimeout = realSetTimeout; }
    return delays;
  }
  const okSend = () => { globalThis.fetch = async () => ({ ok: true, status: 204, headers: { get: () => null }, text: async () => '' }); };

  test('requestLoginCode → 25000ms', async () => {
    okSend();
    const delays = await captureDelays(() => requestLoginCode('a@b.co'));
    assert.ok(delays.includes(25000), `기대 25000, 관측 ${JSON.stringify(delays)}`);
  });

  test('requestEmployCode → 25000ms', async () => {
    okSend();
    const delays = await captureDelays(() => requestEmployCode(10, 'a@corp.co'));
    assert.ok(delays.includes(25000), `기대 25000, 관측 ${JSON.stringify(delays)}`);
  });

  test('메일이 아닌 호출은 기본 8000ms 유지(전역 상향이 아님)', async () => {
    okSend();
    const delays = await captureDelays(() => login('a@b.co', '123456'));
    assert.ok(delays.includes(8000), `기대 8000, 관측 ${JSON.stringify(delays)}`);
    assert.equal(delays.includes(25000), false);
  });
});

// ── SC15 커뮤니티 헬퍼(T-14.6.1, FRD/14) — 목록은 익명 apiFetch, 상세·댓글·쓰기는 credentialed apiSend ──
describe('SC15 커뮤니티 헬퍼', () => {
  let seen;
  // 목록은 apiFetch(res.json), 나머지는 apiSend(res.text) — 둘 다 지원하는 목.
  function mock(status, json) {
    seen = [];
    globalThis.fetch = async (url, opts) => {
      seen.push({ url, opts });
      const txt = json === undefined ? '' : JSON.stringify(json);
      return { ok: status >= 200 && status < 300, status, json: async () => json, text: async () => txt };
    };
  }
  const q = (i = 0) => new URL('http://x' + seen[i].url).searchParams;

  test('listPosts() 기본 → GET /posts?sort=latest&limit=20, 익명(credentials:omit)', async () => {
    mock(200, { items: [], next_before: null });
    const out = await listPosts();
    assert.deepEqual(out, { items: [], next_before: null });
    assert.equal(seen[0].opts.method, 'GET');
    assert.equal(seen[0].opts.credentials, 'omit');
    assert.equal(seen[0].opts.headers['X-Loupit-Client'], 'web');
    assert.ok(seen[0].url.startsWith(API_BASE + '/posts?'));
    assert.equal(q().get('sort'), 'latest');
    assert.equal(q().get('limit'), '20');
    assert.equal(q().get('category'), null, '전체(빈 카테고리)는 파라미터를 붙이지 않는다');
    assert.equal(q().get('before'), null);
  });

  test('listPosts({category, sort, before}) → 세 파라미터 모두 부착·인코딩', async () => {
    mock(200, { items: [], next_before: null });
    await listPosts({ category: 'career', sort: 'likes', before: 77, limit: 50 });
    assert.equal(q().get('category'), 'career');
    assert.equal(q().get('sort'), 'likes');
    assert.equal(q().get('before'), '77');
    assert.equal(q().get('limit'), '50');
  });

  test('getPost → GET /posts/{id} credentialed(is_mine·liked 는 쿠키가 있어야 참) + 본문만 반환', async () => {
    mock(200, { post_id: 3, title: 't', is_mine: true, liked: false });
    const post = await getPost(3);
    assert.equal(seen[0].url, API_BASE + '/posts/3');
    assert.equal(seen[0].opts.method, 'GET');
    assert.equal(seen[0].opts.credentials, 'include');
    assert.equal(seen[0].opts.headers['X-Loupit-Client'], 'web');
    assert.equal(post.is_mine, true);
    assert.equal(post.title, 't');
  });

  test('getPost 404 → ApiError(404)', async () => {
    mock(404, { detail: 'not found' });
    await assert.rejects(() => getPost(9), (err) => err instanceof ApiError && err.status === 404);
  });

  test('getComments(id) → GET /posts/{id}/comments?limit=50 credentialed · after 는 있을 때만', async () => {
    mock(200, { items: [], next_after: null });
    await getComments(3);
    assert.ok(seen[0].url.startsWith(API_BASE + '/posts/3/comments?'));
    assert.equal(q().get('limit'), '50');
    assert.equal(q().get('after'), null);
    assert.equal(seen[0].opts.credentials, 'include');
    mock(200, { items: [], next_after: null });
    await getComments(3, 12, 20);
    assert.equal(q().get('after'), '12');
    assert.equal(q().get('limit'), '20');
  });

  test('createPost → POST /posts JSON 본문·credentials:include·CSRF 헤더', async () => {
    mock(201, { post_id: 5 });
    const { status, data } = await createPost({ category: 'free', title: 't', body: 'b', comp_id: null });
    assert.equal(status, 201);
    assert.equal(data.post_id, 5);
    assert.equal(seen[0].url, API_BASE + '/posts');
    assert.equal(seen[0].opts.method, 'POST');
    assert.equal(seen[0].opts.credentials, 'include');
    assert.equal(seen[0].opts.headers['X-Loupit-Client'], 'web');
    assert.equal(seen[0].opts.headers['Content-Type'], 'application/json');
    assert.deepEqual(JSON.parse(seen[0].opts.body), { category: 'free', title: 't', body: 'b', comp_id: null });
  });

  test('updatePost → PUT /posts/{id} (category 없이) · deletePost → DELETE /posts/{id}', async () => {
    mock(200, { post_id: 5, updated_at: 'x' });
    await updatePost(5, { title: 't2', body: 'b2', comp_id: 1 });
    assert.equal(seen[0].opts.method, 'PUT');
    assert.equal(seen[0].url, API_BASE + '/posts/5');
    assert.equal(JSON.parse(seen[0].opts.body).category, undefined);
    mock(204);
    const r = await deletePost(5);
    assert.equal(seen[0].opts.method, 'DELETE');
    assert.equal(seen[0].url, API_BASE + '/posts/5');
    assert.equal(r.status, 204);
  });

  test('createComment → POST /posts/{id}/comments {body} · deleteComment → DELETE …/comments/{cid}', async () => {
    mock(201, { comment_id: 9 });
    await createComment(5, '댓글');
    assert.equal(seen[0].opts.method, 'POST');
    assert.equal(seen[0].url, API_BASE + '/posts/5/comments');
    assert.deepEqual(JSON.parse(seen[0].opts.body), { body: '댓글' });
    mock(204);
    await deleteComment(5, 9);
    assert.equal(seen[0].opts.method, 'DELETE');
    assert.equal(seen[0].url, API_BASE + '/posts/5/comments/9');
  });

  test('toggleLike → PUT /posts/{id}/like 무본문 · 응답 {liked, like_cnt}', async () => {
    mock(200, { liked: true, like_cnt: 4 });
    const { data } = await toggleLike(5);
    assert.equal(seen[0].opts.method, 'PUT');
    assert.equal(seen[0].url, API_BASE + '/posts/5/like');
    assert.equal(seen[0].opts.body, undefined);
    assert.deepEqual(data, { liked: true, like_cnt: 4 });
  });

  test('submitReport → POST /reports 4필드 · 409 중복은 ApiError 로 구분', async () => {
    mock(202, { report_id: 1 });
    const { status } = await submitReport({ target_type: 'post', target_id: 5, reason: 'spam', detail: '' });
    assert.equal(status, 202);
    assert.equal(seen[0].url, API_BASE + '/reports');
    assert.deepEqual(JSON.parse(seen[0].opts.body), { target_type: 'post', target_id: 5, reason: 'spam', detail: '' });
    mock(409, { detail: 'duplicate' });
    await assert.rejects(() => submitReport({ target_type: 'post', target_id: 5, reason: 'spam', detail: '' }),
      (err) => err instanceof ApiError && err.status === 409);
  });
});
