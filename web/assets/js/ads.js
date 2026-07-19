// web/assets/js/ads.js — 광고·제휴·동의 오케스트레이터(SP-ADS-3~9, FR-70~79).
// 부수효과 O(DOM/네트워크). adsConfig.js·dom.js(escapeHtml/safeUrl/el)·store.js(store)만 import.
// app.js·calc.js·리포트 모듈 import 0(호출은 상위에서 주입) — SP-ADS-1.2 비순환 의존 규칙.
import {
  adsConfig, isPlaceholder, SLOT_ID_MAP, SLOT_RESERVE, AD_LABEL_TEXT,
} from './adsConfig.js';
import { escapeHtml, safeUrl, el } from './dom.js';
import { store } from './store.js';

// ── SP-ADS-3.1 page_type 게이팅 결정(순수, node:test 대상) ─────────────────
// 배치 표(FRD 09 정본)와 1:1. 표 외 위치·개수 추가 금지.
export const PAGE_TYPES = ['landing', 'company', 'combo', 'input', 'result', 'policy'];

export function adPolicy(pageType) {
  switch (pageType) {
    case 'landing': return { auto: 'ON',  manual: ['content_bottom'],                affiliate: 'optional' };
    case 'company': return { auto: 'ON',  manual: ['content_mid', 'content_bottom'], affiliate: 'on' };
    case 'combo':   return { auto: 'ON',  manual: ['content_mid', 'content_bottom'], affiliate: 'on' };
    case 'result':  return { auto: 'OFF', manual: ['report_bottom'],                 affiliate: 'optional' };
    case 'input':   return { auto: 'OFF', manual: [],                                affiliate: 'none' };   // 무광고 강제(Tier-0 UT-ADS-GATE-1)
    case 'policy':  return { auto: 'OFF', manual: [],                                affiliate: 'none' };
    default:        return { auto: 'OFF', manual: [],                                affiliate: 'none' };   // 판별 실패=안전 기본값(INV-ADS)
  }
}

// 위치→슬롯 id 매핑. 매핑 없으면 null(슬롯 미렌더). 슬롯 id는 AD_SLOT에서만(HTML 하드코딩 0).
export function resolveSlotId(pageType, position) {
  const key = (SLOT_ID_MAP[pageType] || {})[position];
  return key ? adsConfig.AD_SLOT[key] : null;
}

// ── SP-ADS-3.2 페이지 유형 판별 ─────────────────────────────────────────────
// 정적 페이지: <body data-page-type="company">에서 읽음(SP-ADS-9). SPA: 호출부가 명시 인자 전달.
export function detectPageType() {
  const t = (document.body && document.body.dataset && document.body.dataset.pageType) || null;
  return PAGE_TYPES.includes(t) ? t : 'default';   // 미상 → 'default'(무광고)
}

// ── SP-ADS-7.1 동의 상태 저장(localStorage 우선·쿠키 폴백) ─────────────────
const CONSENT_KEY = 'loupit.adConsent';
const CONSENT_V = 1;

// 순수 파서(node:test 대상): 봉투 검증. 손상·버전불일치 → null
export function parseConsent(env) {
  if (env && env.v === CONSENT_V && typeof env.personalized === 'boolean') return env.personalized;
  return null;
}

// 1st-party 쿠키 헬퍼(localStorage 불가 시 폴백, CS-5)
function readCookie(name) {
  if (typeof document === 'undefined' || !document.cookie) return null;
  const escaped = name.replace(/([.$?*|{}()[\]\\/+^])/g, '\\$1');
  const match = document.cookie.match(new RegExp('(?:^|;\\s*)' + escaped + '=([^;]*)'));
  return match ? decodeURIComponent(match[1]) : null;
}
function writeCookie(name, value, days) {
  if (typeof document === 'undefined') return;
  const maxAge = days * 24 * 60 * 60;
  document.cookie = name + '=' + encodeURIComponent(value) + '; max-age=' + maxAge + '; path=/; SameSite=Lax';
}

// 반환: true(개인화 동의) | false(거부) | null(미선택)
export function getConsent() {
  const parsed = parseConsent(store.get(CONSENT_KEY));        // store = SP-FE-10 localStorage 래퍼(우선)
  if (parsed !== null) return parsed;
  const c = readCookie(CONSENT_KEY);                           // 폴백: 1st-party 쿠키
  if (c === 'p') return true;
  if (c === 'n') return false;
  return null;
}
export function setConsent(personalized) {
  const ok = store.set(CONSENT_KEY, { v: CONSENT_V, personalized: !!personalized, ts: Date.now() });
  if (!ok) writeCookie(CONSENT_KEY, personalized ? 'p' : 'n', 365);   // localStorage 불가 시 쿠키(CS-5)
}
export function isPersonalized() { return getConsent() === true; }

// 로더 실행 전 비개인화 신호 세팅(FR-79): 미동의/거부 → requestNonPersonalizedAds=1
// export: 공개 심볼표(SP-ADS-1.1)는 "대표" 목록이며 단위 테스트 가능성을 위해 공개한다.
export function applyConsentSignal() {
  const ab = (window.adsbygoogle = window.adsbygoogle || []);
  ab.requestNonPersonalizedAds = isPersonalized() ? 0 : 1;
}

// ── SP-ADS-4.1 자동광고 로더·활성화(DOM/네트워크, 수동 브라우저 검증 대상) ──
const LOADER_ID = 'adsbygoogle-loader';
const LOADER_SRC = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';

function ensureLoader() {
  if (isPlaceholder(adsConfig.AD_CLIENT)) return;                 // 승인 전: 로더 미주입(C-3·A-3)
  if (document.getElementById(LOADER_ID)) return;                 // 1회만(G-5)
  const s = document.createElement('script');
  s.id = LOADER_ID;
  s.async = true;
  s.crossOrigin = 'anonymous';
  s.src = LOADER_SRC + '?client=' + encodeURIComponent(adsConfig.AD_CLIENT);   // client id는 adsConfig에서만(A-2)
  document.head.appendChild(s);
}

function enableAutoAds() {
  if (!adsConfig.AUTO_ADS || isPlaceholder(adsConfig.AD_CLIENT)) return;
  if (adsConfig.DENY_FALLBACK === 'suppress' && !isPersonalized()) return;   // 거부·미선택 시 미노출 폴백(CS-4·SP-ADS-7.3)
  // 자동광고는 AdSense 대시보드 사이트 설정 + 로더 스크립트로 활성화된다.
  // 비개인화 신호는 applyConsentSignal()가 로더 실행 전에 window.adsbygoogle에 세팅한다(A-5).
}

// ── SP-ADS-5.1 수동 광고 슬롯 렌더(DOM, 수동 브라우저 검증 대상) ───────────
function mountManualSlot(root, pageType, position) {
  const host = root.querySelector('[data-ad-position="' + position + '"]');   // SP-ADS-9 계약 위치
  if (!host) return;                                                          // 위치 없으면 미렌더(무크래시)
  const slotId = resolveSlotId(pageType, position);

  // 승인 전(placeholder)·슬롯 미상·거부폴백(suppress)에는 빈 "광고" 점선 박스를 노출하지 않는다(#12):
  // 실 client id 주입 전까지 랜딩에 내용 없는 광고 자리가 상시 보이던 함정 제거 — host를 비우고 hidden.
  if (isPlaceholder(adsConfig.AD_CLIENT) || !slotId
      || (adsConfig.DENY_FALLBACK === 'suppress' && !isPersonalized())) {
    host.replaceChildren();
    host.hidden = true;
    return;
  }

  // 실 client id 주입 후: "광고" 라벨 + 예약 높이 박스(CLS) 렌더. 색/여백은 SP-DSN(.ad-slot*).
  const reserve = SLOT_RESERVE[position] || { mobile: 250, desktop: 250 };
  host.hidden = false;
  host.replaceChildren();
  host.append(el('span', { class: 'ad-label', text: AD_LABEL_TEXT }));        // FR-76: 은폐 금지·textContent
  const box = el('div', {
    class: 'ad-slot ad-slot--' + position.replace(/_/g, '-'),
    'data-reserve-mobile': String(reserve.mobile),
    'data-reserve-desktop': String(reserve.desktop),
  });
  host.append(box);

  // AdSense 수동 유닛: <ins class="adsbygoogle"> 삽입 후 push
  const ins = document.createElement('ins');
  ins.className = 'adsbygoogle';
  ins.style.display = 'block';
  ins.setAttribute('data-ad-client', adsConfig.AD_CLIENT);
  ins.setAttribute('data-ad-slot', slotId);
  ins.setAttribute('data-ad-format', 'auto');
  ins.setAttribute('data-full-width-responsive', 'true');
  box.append(ins);
  try { (window.adsbygoogle = window.adsbygoogle || []).push({}); } catch { /* 미노출 폴백, 레이아웃 유지(M-4) */ }
}

// ── SP-ADS-6 제휴 affiliate.json 로드·필터·렌더 ─────────────────────────────
let _affiliateCache = null;
export async function loadAffiliate() {
  if (_affiliateCache) return _affiliateCache;
  try {
    const res = await fetch('/assets/v2/data/affiliate.json', { credentials: 'omit' }); // 동일 오리진·무자격증명(v2 세대 — no-cache 재검증)
    const data = await res.json();
    _affiliateCache = (data && Array.isArray(data.items)) ? data : { version: 1, items: [] };
  } catch { _affiliateCache = { version: 1, items: [] }; }                              // 실패 → 빈 목록(무크래시, AF-7)
  return _affiliateCache;
}

// 순수 필터(node:test 대상): active && page_types 포함 && input/policy 아님 && url 스킴 유효
export function filterAffiliate(items, pageType) {
  if (pageType === 'input' || pageType === 'policy') return [];        // 게이팅(FR-73)
  const seen = new Set();
  return (items || []).filter(it => {
    if (!it || it.active !== true) return false;
    if (!Array.isArray(it.page_types) || !it.page_types.includes(pageType)) return false;
    if (it.page_types.includes('input') || it.page_types.includes('policy')) return false; // 위반 항목 배제
    if (typeof it.label !== 'string' || it.label.trim() === '') return false;
    if (safeUrl(it.url) == null) return false;                          // http/https만(NFR21)
    if (typeof it.id !== 'string' || seen.has(it.id)) return false;     // id 중복 배제
    seen.add(it.id);
    return true;
  });
}

// 순수 속성 빌더(node:test 대상): 광고성·안전 링크 속성(FR-77)
export function buildAffiliateAttrs(url) {
  return { href: safeUrl(url), rel: 'sponsored nofollow noopener', target: '_blank' };
}

async function mountAffiliate(root, pageType) {
  const host = root.querySelector('[data-affiliate-host]');            // SP-ADS-9 계약 위치
  if (!host) return;
  const { items } = await loadAffiliate();
  const list = filterAffiliate(items, pageType);
  host.replaceChildren();
  if (list.length === 0) return;                                       // 해당 없음 → 컴포넌트 미노출
  for (const it of list) host.append(renderAffiliateCard(it));
}

function renderAffiliateCard(it) {
  const card = el('div', { class: 'affiliate-card' });
  card.append(el('span', { class: 'ad-label', text: AD_LABEL_TEXT }));           // FR-76
  card.append(el('div', { class: 'affiliate-label', text: it.label }));          // 이스케이프(textContent)
  if (it.desc) card.append(el('div', { class: 'affiliate-desc', text: it.desc }));// null이면 생략
  const attrs = buildAffiliateAttrs(it.url);
  const a = el('a', { class: 'affiliate-cta', href: attrs.href, rel: attrs.rel, target: attrs.target, text: '바로가기 →' });
  card.append(a);
  return card;
}

// ── SP-ADS-7.2 동의 배너 배선(DOM, 수동 브라우저 검증 대상) ────────────────
// 배너 마크업(SCR-61)은 셸/정적 페이지가 방출(SP-ADS-9). 본 함수는 로직만.
export function initConsentBanner() {
  const banner = document.getElementById('consent-banner');
  if (!banner) return;
  if (getConsent() !== null) { banner.hidden = true; return; }        // 이미 결정 → 미노출(재방문, CS-2)
  banner.hidden = false;                                              // 첫 방문 → 노출
  banner.querySelector('[data-consent="grant"]')?.addEventListener('click', () => decideConsent(true));
  banner.querySelector('[data-consent="deny"]')?.addEventListener('click', () => decideConsent(false));
}
function decideConsent(personalized) {
  setConsent(personalized);
  const banner = document.getElementById('consent-banner');
  if (banner) banner.hidden = true;
  // 이번 세션 광고는 이미 비개인화로 로드됨. 개인화 전환은 다음 로드에 적용(FR-79 재방문 적용).
}

// ── SP-ADS-3.3 마운트 오케스트레이터 ────────────────────────────────────────
export function mountAds(pageType = detectPageType(), root = document) {
  const policy = adPolicy(pageType);
  // input·policy·default: 자동·수동·제휴 전부 0 마운트(게이팅 자체 차단, MON8, G-2)
  if (policy.auto === 'OFF' && policy.manual.length === 0 && policy.affiliate === 'none') return;

  applyConsentSignal();                                  // 비개인화 신호를 로더 실행 전에 세팅(FR-79)
  const needLoader = policy.auto === 'ON' || policy.manual.length > 0;
  if (needLoader) ensureLoader();                        // 승인 전(isPlaceholder)엔 no-op(예약만)
  if (policy.auto === 'ON') enableAutoAds();

  for (const position of policy.manual) mountManualSlot(root, pageType, position);
  if (policy.affiliate !== 'none') mountAffiliate(root, pageType);
}
