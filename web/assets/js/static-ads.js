// web/assets/js/static-ads.js — 정적 페이지(회사·조합·정책·404) 광고·동의 진입점(SP-ADS-9).
// app.js는 SPA 셸(랜딩·비교툴) 전용이라 정적 페이지에 싣지 않는다 — 본문은 JS 없이
// 완성되고(NFR24·INV-3) 이 스크립트는 동의 배너와 광고 오케스트레이션만 배선한다.
// 게이팅은 mountAds()가 <body data-page-type>으로 스스로 판별(SP-ADS-3.2) — company/combo는
// 수동 2슬롯+제휴, policy·미상은 전부 무광고. 승인 전(placeholder client)에는 mountManualSlot이
// 호스트를 비우고 숨겨 빈 '광고' 박스를 노출하지 않는다(감사 #12).
import { mountAds, initConsentBanner } from './ads.js';

export function bootStaticAds() {
  try { initConsentBanner(); } catch { /* 동의 배너 실패 무손상 */ }
  try { mountAds(); } catch { /* 광고 실패 무손상(MON6) */ }
}

if (typeof document !== 'undefined' && typeof document.addEventListener === 'function') {
  document.addEventListener('DOMContentLoaded', () => bootStaticAds());
}
