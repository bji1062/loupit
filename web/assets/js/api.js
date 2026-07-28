// web/assets/js/api.js — 읽기 전용 API 클라이언트(SP-FE-6, FR-02, SP-API-9~13, NFR16·NFR20, INV-1·INV-4).
// 인증 헤더·쿠키 미부착, GET 전용(쓰기 헬퍼 미노출). 동일 오리진(API_BASE='/api/v1').
// 브라우저 표준 fetch/AbortController만 사용(다른 앱 모듈 import 0).

export const API_BASE = '/api/v1';
const DEFAULT_TIMEOUT = 8000; // ms

// 메일 발송(로그인 코드·재직 코드) 전용 타임아웃 — 적대검토 ⑤(2026-07-28).
// 이 두 호출만 요청 안에 **SMTP 실왕복**이 들어간다. 기본 8s 는 nginx `proxy_read_timeout 15s`
// 보다 짧아서, 제공자가 느릴 때 **서버가 정상 204 를 만드는 도중에 브라우저가 먼저 abort** 했다
// → 사용자는 "네트워크 오류예요"를 보는데 메일은 실제로 발송된 상태가 된다(그리고 재클릭해도
// 앱 쿨다운 60초에 걸려 아무 일도 안 일어난다). smtplib 의 timeout 은 대화 전체가 아니라
// **개별 소켓 연산** 상한이라 총 소요가 `_SMTP_TIMEOUT_SEC`(8s) 를 넘는 것은 정상 범위다.
// ⚠ 기준은 `proxy_read_timeout`(15s) **혼자가 아니다**(적대검토 2026-07-28 정정). 엣지의 최악
// 예산은 `proxy_connect_timeout 3s` + `proxy_read_timeout 15s` = **18s** 이고, 브라우저 타이머는
// fetch 호출 즉시(= DNS·TCP·TLS 전) 시작한다. 20s 로 잡으면 클라이언트 셋업이 2s 만 걸려도
// 브라우저가 먼저 끊어, 고치려던 증상이 느린 회선에서 그대로 남는다. 25s = 18s + 7s 여유.
// 그래도 **실체감 상한은 엣지의 18s** 다 — 이 값은 "엣지가 항상 먼저 끊는다"를 보장할 뿐
// 사용자를 25초 기다리게 하지 않는다.
// 구조 가드: server/tests/test_mail_config_gate.py MG-8 이 이 값 > connect+read 를 강제한다.
const MAIL_TIMEOUT = 25000; // ms

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
    if (!res.ok) throw new ApiError(res.status, path, undefined, retryAfterSec(res)); // 4xx/5xx → 구조화 오류
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

// ── 순수: 응답의 `Retry-After` 를 초(정수)로 — 없거나 못 읽으면 null ──
// nginx 메일 리밋의 429 만 이 헤더를 싣는다(conf.d/loupit-limits.conf 의 `map $status`).
// RFC 9110 은 delta-seconds 와 HTTP-date 두 형식을 허용하나 우리 엣지는 항상 delta-seconds 다 —
// 숫자로 안 읽히는 값은 억지 해석 대신 null 로 떨어뜨려 UI 가 숫자 없는 기존 문구로 폴백하게 한다.
// **앱이 내는 429**(로그인 시도 상한·재직 시도 상한·일일 편집 상한)는 이 헤더가 없어 항상 null 이다
// — 그쪽 대기시간은 20초가 아니므로 숫자를 붙이면 거짓말이 된다. 이 구분이 설계의 핵심이다.
// (테스트 목처럼 `headers` 가 없는 응답 객체도 안전하게 null.)
function retryAfterSec(res) {
  const raw = res && res.headers && typeof res.headers.get === 'function'
    ? res.headers.get('Retry-After') : null;
  if (raw == null) return null;
  // delta-seconds 는 **10진 정수** 다(RFC 9110 §10.2.3). `Number()` 로 느슨하게 받으면
  // `0x14`·`1e30`·`+20`·`.5` 같은 값까지 숫자로 통과해 계약보다 넓어진다 — 우리 엣지는 정수만
  // 보내므로 애초에 정규식으로 좁힌다(그 밖은 HTTP-date 포함 전부 null → UI 가 기존 문구로 폴백).
  const s = String(raw).trim();
  if (!/^[0-9]+$/.test(s)) return null;
  const n = Number(s);
  return Number.isSafeInteger(n) ? n : null;
}

export class ApiError extends Error {
  constructor(status, path, data, retryAfter = null) {
    super('API ' + status + ' ' + path);
    this.name = 'ApiError';
    this.status = status;
    this.path = path;
    this.data = data; // 오류 응답 본문({detail:...} 등) — 있으면 UI 메시지에 활용
    this.retryAfter = retryAfter; // 429 재시도 대기(초) 또는 null. 숫자가 있을 때만 UI 가 노출한다.
  }
}

// 3종 GET 소비(health 제외). 익명 열람 전용(무쿠키·무인증, INV-1).
export const getReference = (opt) => apiFetch('/reference/all', opt);
export const searchCompanies = (q, opt) => apiFetch('/companies/search?q=' + encodeURIComponent(q), opt);
export const getCompany = (id, opt) => apiFetch('/companies/' + encodeURIComponent(id), opt);

// ── 참여(기여) 전송 헬퍼 — SP-FE(T-13.14.1), SC14 ────────────────────────────
// 익명 apiFetch(GET·credentials:'omit')와 대비: 세션 쿠키 송수신(credentials:'include') +
// 커스텀 헤더 X-Loupit-Client(CSRF, FR-113·SP-AUTH-12). 로그인·재직인증·복지편집 등 상태변경 전용.
// same-origin(/api/v1)이라 CORS preflight 없음. 쿠키는 서버가 Set-Cookie(HttpOnly·Secure·Lax·
// Path=/api/v1)로 관리 — JS는 쿠키를 읽지 않는다(XSS 탈취 방지, NFR16).
export async function apiSend(method, path, body, { timeout = DEFAULT_TIMEOUT } = {}) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  try {
    const headers = { Accept: 'application/json', 'X-Loupit-Client': 'web' };
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const res = await fetch(API_BASE + path, {
      method,
      headers,
      credentials: 'include', // 세션 쿠키 송수신(익명 apiFetch는 omit)
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: ctrl.signal,
    });
    let data = null;
    const txt = await res.text(); // 204(무본문)·JSON·오류 envelope 모두 안전 처리
    if (txt) { try { data = JSON.parse(txt); } catch { data = txt; } }
    if (!res.ok) throw new ApiError(res.status, path, data, retryAfterSec(res));
    return { status: res.status, data };
  } finally {
    clearTimeout(timer);
  }
}

// 무비밀번호 로그인·계정(SP-AUTH-5·6). 코드는 서버가 이메일(운영)·로그(개발)로 전달.
// ⚠ 메일 발송 2종만 MAIL_TIMEOUT(20s) — 나머지는 기본 8s 그대로다(위 상수 주석 참조).
export const requestLoginCode = (email) =>
  apiSend('POST', '/members/login-code', { email }, { timeout: MAIL_TIMEOUT });
export const login = (email, code) => apiSend('POST', '/members/login', { email, code });
export const getMe = () => apiSend('GET', '/members/me'); // credentialed(세션 쿠키)
export const logout = () => apiSend('POST', '/members/logout');
export const updateNickname = (nickname) => apiSend('PUT', '/members/me', { nickname }); // 409 중복·422 형식/금칙어
export const withdraw = () => apiSend('DELETE', '/members/me'); // 탈퇴: 이메일 파기·닉네임/이력 존치

// 재직 인증(SP-AUTH-7·8). 도메인 자동 인증 + 미등록 회사 수동 승인 폴백.
export const requestEmployCode = (comp_id, company_email) => // 204 / 409 manual_required / 422 불일치
  apiSend('POST', '/employment/verify-code', { comp_id, company_email }, { timeout: MAIL_TIMEOUT });
export const verifyEmployment = (comp_id, company_email, code) =>
  apiSend('POST', '/employment/verify', { comp_id, company_email, code }); // 201 / 401·410·429 / 409 중복
export const submitEmployRequest = (comp_id, evidence) =>
  apiSend('POST', '/employment/requests', { comp_id, evidence }); // 202 pending / 409 중복 대기

// 복지 편집(SP-AUTH-9·10, FR-108~110). 등록·수정·편집용 조회는 세션+재직 게이트(credentialed+CSRF);
// 편집용 조회 응답은 base_dtm(낙관동시성 토큰)·benefit_id(PUT 대상 PK)를 행마다 동봉한다.
// 편집 이력 조회는 익명 공개 GET(무쿠키 apiFetch — 스크래핑 방어 헤더만 부착).
export const getBenefitsForEdit = (comp_id) =>
  apiSend('GET', '/companies/' + encodeURIComponent(comp_id) + '/benefits'); // 401 무세션 / 403 재직 미보유
export const createBenefit = (comp_id, body) =>
  apiSend('POST', '/companies/' + encodeURIComponent(comp_id) + '/benefits', body); // 201 / 409 코드중복 / 429 상한 / 422
export const updateBenefit = (comp_id, benefit_id, body) =>
  apiSend('PUT', '/companies/' + encodeURIComponent(comp_id) + '/benefits/' + encodeURIComponent(benefit_id), body); // 200 / 409 선점(현재행 동봉) / 404 / 429 / 422
// 편집 이력: 익명 공개 GET · 404 미존재 회사. `before`=키셋 커서(그 edit_id 보다 오래된 페이지).
export const getEdits = (comp_id, limit = 50, before = null, opt) =>
  apiFetch('/companies/' + encodeURIComponent(comp_id) + '/edits?limit=' + encodeURIComponent(limit)
    + (before ? '&before=' + encodeURIComponent(before) : ''), opt);
