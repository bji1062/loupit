// web/assets/js/api.test.js — SP-FE-6 읽기 전용 API 클라이언트 단위 테스트.
// 근거: SPEC/06-프론트엔드-구조.md §SP-FE-6, TASK/06-프론트엔드.md T-06.6.1·6.2.
// global fetch 목(in-memory) — 실 네트워크 미사용.
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  apiFetch, ApiError, getReference, searchCompanies, getCompany, API_BASE,
  getBenefitsForEdit, createBenefit, updateBenefit, getEdits,
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
});
