// web/assets/js/badge.js — 배지 계보(출처) 판정 **클라이언트 정본**.
//
// 정본의 정본은 `generator/format.py badge_state()` 다. 우선순위·라벨 어휘를 여기서
// 미러링하고, 클라이언트의 네 렌더러가 **전부 이 함수 하나만** 쓴다.
//
// 우선순위(높은 것이 이긴다):
//   1. 만료      — expires_dtm < now. 신선도가 최우선(누가 넣었든 오래된 값은 오래된 값)
//   2. 재직자 등록 — edit_origin='member'. 원래 없던 항목을 재직자가 더했다
//   3. 공식·재직자 수정 — edit_origin='edited'. 공식 값을 재직자가 고쳤다
//   4. 공식      — 편집 이력 없음(시드 원본 = 회사 공식 페이지)
//   5. 추정      — 그 외
//
// ⚠ 2·3 의 '재직자'는 수사가 아니다 — 복지 편집은 `require_employment` 게이트 뒤라
//   그 회사 재직 인증을 통과한 사람만 쓸 수 있다.
//
// 🚨 왜 모듈로 뗐나(2026-07-31): 배지를 출처 계보로 바꿀 때 렌더러가 셋이라고 세고
//    `company.js`(GNB 검색 → 회사 복지 페이지)를 빠뜨렸다. 그 화면만 계보를 모른 채
//    '공식/추정' 2종에 머물러, 재직자가 편집을 시작하면 **같은 복지가 화면마다 다른 출처**
//    를 달게 돼 있었다. 판정을 복사하지 말고 이 함수를 import 하라.

// 만료를 CSS·정적 템플릿에서는 `stale` 이라 부른다(`_badge.html` 의 `badge-{{code}}`).
// 의미상의 종류(kind)와 클래스 접미(suffix)를 분리해 어휘 차이를 여기서 흡수한다.
const CLASS_SUFFIX = {
  expired: 'stale', member: 'member', edited: 'edited', official: 'official', est: 'est',
};

// 상세 화면(정적 회사 페이지·SPA 회사 복지 페이지) — generator/format.py 와 같은 문구.
export const BADGE_LABEL_FULL = {
  expired: '만료·재확인 필요', member: '재직자 등록', edited: '공식·재직자 수정',
  official: '공식', est: '추정',
};

// 좁은 표(비교 리포트 밴드·디렉터리 요약) — 폭이 없어 'edited' 만 줄인다.
export const BADGE_LABEL_SHORT = {
  expired: '만료', member: '재직자 등록', edited: '공식·수정', official: '공식', est: '추정',
};

/**
 * 배지 종류를 판정한다. 순수 함수 — now 를 주입해 결정성을 보장한다.
 *
 * withExpiry=false 는 **요약 화면 전용**이다(디렉터리 패널). 만료·확인일은 상세가
 * 소유한다는 기존 결정을 끄되, 그것을 침묵이 아니라 **인자로 드러내기 위해** 둔다.
 */
export function badgeKind(item, { now = Date.now(), withExpiry = true } = {}) {
  const b = item || {};
  if (withExpiry && b.expires_dtm != null) {
    const t = Date.parse(b.expires_dtm);
    if (!Number.isNaN(t) && t < now) return 'expired'; // 파싱 불가 → 만료 아님(무크래시)
  }
  if (b.edit_origin === 'member') return 'member';
  if (b.edit_origin === 'edited') return 'edited';
  return b.badge_cd === 'official' ? 'official' : 'est';
}

/** 단일대시 규약(`badge badge-official`) — 정적 템플릿·디렉터리·회사 페이지 공용. */
export function badgeClass(kind) { return 'badge badge-' + (CLASS_SUFFIX[kind] || 'est'); }

/** 이중대시 규약(`badge badge--official`) — 비교 리포트 전용(styles.css 가 양쪽 다 갖는다). */
export function badgeClassBem(kind) { return 'badge badge--' + kind; }
