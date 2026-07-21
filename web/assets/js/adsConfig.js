// web/assets/js/adsConfig.js — 설정 단일 진실(SP-ADS-2, FR-70). 승인 후 이 파일만 치환.
// import 0(순수 상수·순수 판별 함수) — SP-ADS-1.2 비순환 의존 규칙.

export const AD_CLIENT_PLACEHOLDER = 'ca-pub-XXXXXXXXXXXXXXXX';   // ca-pub- + 16자리
export const AD_SLOT_PLACEHOLDER   = 'XXXXXXXXXX';                // 10자리 슬롯 id

export const adsConfig = {
  // 승인 전: 플레이스홀더 유지 → 실제 광고 스크립트 미주입, 예약 슬롯만 렌더(MON18·FR-74)
  AD_CLIENT: 'ca-pub-6009927622334159',      // 2026-07-21 발급 게시자 ID(공개값). isPlaceholder=false
                                             // → ads.js가 로더 주입(심사 전 배선, §B-3 단계 2).
                                             // ⚠ 실광고는 애드센스 승인 후에야 서빙됨(Google 서버 통제).
  AUTO_ADS: true,                            // ON 페이지 자동광고 스니펫 사용(MON3)
  // 미동의/거부 폴백 정책(FR-79): 'nonpersonalized'(기본) | 'suppress'(광고 미노출)
  DENY_FALLBACK: 'nonpersonalized',
  AD_SLOT: {                                 // 수동 슬롯 식별자(FR-72). 초기 전부 플레이스홀더
    landing_bottom: AD_SLOT_PLACEHOLDER,
    company_mid:    AD_SLOT_PLACEHOLDER,
    company_bottom: AD_SLOT_PLACEHOLDER,
    combo_mid:      AD_SLOT_PLACEHOLDER,
    combo_bottom:   AD_SLOT_PLACEHOLDER,
    result_bottom:  AD_SLOT_PLACEHOLDER,
  },
};

// (page_type, position) → AD_SLOT 키 매핑. 배치 표(정본)와 1:1(FR-72·FR-73)
export const SLOT_ID_MAP = {
  landing: { content_bottom: 'landing_bottom' },
  company: { content_mid: 'company_mid', content_bottom: 'company_bottom' },
  combo:   { content_mid: 'combo_mid',   content_bottom: 'combo_bottom' },
  result:  { report_bottom: 'result_bottom' },
};

// 예약 높이 규격(CLS, FR-74). 색·여백은 SP-DSN; 여기서는 min-height 하한만 계약
export const SLOT_RESERVE = {               // px, {mobile, desktop}
  content_mid:    { mobile: 280, desktop: 280 },
  content_bottom: { mobile: 250, desktop: 250 },
  report_bottom:  { mobile: 250, desktop: 250 },
};

export const AD_LABEL_TEXT = '광고';        // 공정위 표기(FR-76). 대체: '유료 광고'

// 승인 전 판별: client id에 플레이스홀더 문자('X')가 남아 있으면 미승인 취급
export function isPlaceholder(id) { return !id || /X{4,}/i.test(id); }
