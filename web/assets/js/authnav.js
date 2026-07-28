// web/assets/js/authnav.js — 전역 헤더의 로그인 진입점(SP-AUTH·SP-FE, SC14).
//
// ── 왜 정적 링크가 아니라 런타임 프로브인가 (2026-07-28) ──────────────────────
// 생성 페이지(web/dist/*)는 **prod 와 beta 가 같은 바이트를 서빙**한다 — beta 체크아웃의
// `web/dist` 가 프로덕션 `web/dist` 로 가는 심링크다. 그래서 "beta 에만 로그인 버튼"을
// 빌드 시점에 만드는 것이 **원리적으로 불가능**하다(생성기에 M9 플래그를 넣어도 산출물이 하나다).
// 반면 API 는 호스트마다 다르게 답하므로 **브라우저에서는 갈라낼 수 있다**:
//
//     GET /members/me →  404  M9 꺼짐(라우터 미등록)   → 진입점 숨김   (현재 prod)
//                        401  켜짐·비로그인            → "로그인"      (현재 beta)
//                        200  로그인됨                 → 닉네임        → /mypage
//
// 부수 효과가 본질적 장점이다: prod 에서 M9 를 켜는 순간 **정적물 재배포 없이** 진입점이
// 저절로 나타난다. 반대로 지금은 prod 에 링크가 새어나가지 않는다 — prod 는 로그인 페이지를
// nginx 가 404 로 막고 있고(`loupit.conf` M9 차단 블록), 라이브 정책 문안이 "로그인 없음"을
// 선언 중이라 **깨진 진입점 노출은 고지 위반**이 된다.
//
// ── 제약 준수 ────────────────────────────────────────────────────────────────
// · 본문 표시를 막지 않는다(NFR12·24): 슬롯은 마크업에서 `hidden` 이고, 프로브가 성공했을
//   때만 채워진다. 네트워크 실패·타임아웃은 **조용히 무시**한다 — 열람은 로그인과 무관하다.
// · 닉네임은 `textContent` 로만 넣는다(XSS). `innerHTML` 을 쓰지 않는다.
// · INV-1 은 **익명 API 표면**에 대한 불변식이고(SPEC/04), 여기서 새 라우트를 만들지 않는다.
//   `/members/me` 는 SC14 가 이미 소유한 기존 엔드포인트다.

import { getMe, ApiError } from './api.js';

// M9 자체가 꺼져 있다는 사실은 **배포 속성**이라 세션 내내 변하지 않는다 → 그것만 캐시한다.
// 로그인 여부는 캐시하지 않는다: 로그아웃한 뒤에도 닉네임이 남아 보이는 편이 그 반대보다 나쁘다.
export const OFF_CACHE_KEY = 'loupit.m9off';

/** 프로브 결과 → 표시 상태. `off` | `anon` | `member` */
export function authStateFrom(result, error) {
  if (error) {
    if (error instanceof ApiError || typeof error?.status === 'number') {
      if (error.status === 404) return 'off';   // 라우터 미등록 = M9 꺼짐
      if (error.status === 401) return 'anon';  // 켜짐, 세션 없음
    }
    return null; // 네트워크·타임아웃·그 외 → 판단 보류(슬롯 그대로 숨김)
  }
  return result?.data?.nickname ? 'member' : 'anon';
}

/** 상태 → 링크 목적지·라벨. 순수 함수(테스트 대상). */
export function navTargetFor(state, nickname) {
  if (state === 'member') return { href: '/mypage', label: nickname };
  if (state === 'anon') return { href: '/login', label: '로그인' };
  return null; // off·판단보류 → 노출하지 않는다
}

/** 슬롯에 반영. doc 을 인자로 받아 jsdom 테스트에서 전역 없이 검증 가능하게 한다. */
export function applyAuthNav(doc, state, nickname) {
  const el = doc?.querySelector('[data-authnav]');
  if (!el) return false;
  const target = navTargetFor(state, nickname);
  if (!target) { el.hidden = true; return false; }
  el.setAttribute('href', target.href);
  const label = el.querySelector('[data-authnav-label]');
  if (label) label.textContent = target.label; // XSS: 닉네임은 textContent 로만
  el.hidden = false;
  return true;
}

/** 세션 캐시 접근. sessionStorage 가 막힌 환경(사파리 프라이빗 등)에서도 죽지 않는다. */
function cachedOff(store) {
  try { return store?.getItem(OFF_CACHE_KEY) === '1'; } catch { return false; }
}
function rememberOff(store) {
  try { store?.setItem(OFF_CACHE_KEY, '1'); } catch { /* 무시 */ }
}

/**
 * 헤더 진입점 초기화. 슬롯이 없거나 M9 가 꺼진 것이 이미 확인됐으면 네트워크를 타지 않는다.
 * 로그인 화면 자신에는 "로그인" 버튼을 띄우지 않는다(자기 링크라 혼란).
 */
export async function initAuthNav({ doc = globalThis.document, store = globalThis.sessionStorage,
                                    path = globalThis.location?.pathname } = {}) {
  if (!doc?.querySelector('[data-authnav]')) return null;
  if (path === '/login') return null;
  if (cachedOff(store)) return 'off';        // prod 에선 세션당 요청 0회로 수렴한다

  let state = null, nickname = '';
  try {
    const res = await getMe();
    state = authStateFrom(res, null);
    nickname = res?.data?.nickname || '';
  } catch (err) {
    state = authStateFrom(null, err);
  }
  if (state === 'off') rememberOff(store);
  applyAuthNav(doc, state, nickname);
  return state;
}

// 자동 초기화 가드 — 슬롯이 있는 실제 페이지에서만 돈다(node:test import 부작용 0).
if (typeof document !== 'undefined' && document.querySelector('[data-authnav]')) {
  initAuthNav();
}
