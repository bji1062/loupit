// web/assets/js/api.js — 읽기 전용 API 클라이언트(SP-FE-6, FR-02, SP-API-9~13, NFR16·NFR20, INV-1·INV-4).
// 인증 헤더·쿠키 미부착, GET 전용(쓰기 헬퍼 미노출). 동일 오리진(API_BASE='/api/v1').
// 브라우저 표준 fetch/AbortController만 사용(다른 앱 모듈 import 0).

export const API_BASE = '/api/v1';
const DEFAULT_TIMEOUT = 8000; // ms

// GET 전용 얇은 클라이언트. 타임아웃·경합취소(AbortController)·무인증 전송.
export async function apiFetch(path, { signal, timeout = DEFAULT_TIMEOUT } = {}) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  if (signal) signal.addEventListener('abort', () => ctrl.abort()); // 외부 취소(경합 폐기) 연결
  try {
    const res = await fetch(API_BASE + path, {
      method: 'GET', // 쓰기 메서드 없음(NFR20)
      headers: {
        Accept: 'application/json', // Authorization/Cookie 미부착(NFR16)
        // 스크래핑 방어(2026-07-21): 데이터 GET 엔드포인트는 nginx가 이 헤더를 요구한다.
        // 맨 curl은 헤더가 없어 403 → "1회 호출 = 600KB 전체" 벌크 덤프를 차단한다.
        // same-origin이라 CORS preflight 없음. 비밀값이 아니라(공개 JS에 노출) 게으른
        // 스크래퍼 차단용 — 정직한 한계는 nginx conf·robots에 문서화.
        'X-Loupit-Client': 'web',
      },
      credentials: 'omit', // 자격증명 미전송
      signal: ctrl.signal,
    });
    if (!res.ok) throw new ApiError(res.status, path); // 4xx/5xx → 구조화 오류
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

export class ApiError extends Error {
  constructor(status, path) {
    super('API ' + status + ' ' + path);
    this.name = 'ApiError';
    this.status = status;
    this.path = path;
  }
}

// 3종 GET 소비(health 제외). 쓰기 헬퍼(post/put/delete) 미제공(INV-1).
export const getReference = (opt) => apiFetch('/reference/all', opt);
export const searchCompanies = (q, opt) => apiFetch('/companies/search?q=' + encodeURIComponent(q), opt);
export const getCompany = (id, opt) => apiFetch('/companies/' + encodeURIComponent(id), opt);
