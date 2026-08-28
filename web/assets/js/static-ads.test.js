// web/assets/js/static-ads.test.js — 정적 페이지 광고·동의 진입점(SP-ADS-9) 단위 테스트.
// 근거: SPEC/08-광고-제휴-통합.md SP-ADS-9(정적 배선), 감사 #12(빈 광고 박스·동의 미배선).
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

import { bootStaticAds } from './static-ads.js';
import { setConsent } from './ads.js';

// ads.test.js #12 블록과 동일 패턴: 테스트별 JSDOM 격리 + 전역 복원.
// 동의 저장 경로: node에 전역 localStorage가 없어 store.set이 쿠키 폴백으로 빠지는데
// JSDOM 기본 URL(about:blank)은 쿠키를 버린다 — 테스트별 fresh 스텁 + 실 URL로 격리.
class FakeLocalStorage {
  constructor() { this._m = new Map(); }
  getItem(k) { return this._m.has(k) ? this._m.get(k) : null; }
  setItem(k, v) { this._m.set(k, String(v)); }
  removeItem(k) { this._m.delete(k); }
}
const savedDoc = globalThis.document;
const savedWin = globalThis.window;
const savedLS = globalThis.localStorage;
function withDom(html, fn) {
  const dom = new JSDOM(html, { url: 'https://jobcho.test/' });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  globalThis.localStorage = new FakeLocalStorage();
  try { fn(dom); } finally {
    globalThis.document = savedDoc;
    globalThis.window = savedWin;
    globalThis.localStorage = savedLS;
  }
}

function companyPage() {
  return '<body data-page-type="company">'
    + '<div data-ad-position="content_mid"></div>'
    + '<div data-ad-position="content_bottom"></div>'
    + '<div data-affiliate-host></div></body>';
}

describe('SP-ADS-9 정적 페이지 부트(static-ads.js)', () => {
  // 동의 배너는 2026-08-28 제거됐다(SP-ADS-7) — 광고는 항상 비개인화로 요청하므로 물을 것이 없고,
  // 자체 UI 는 구글 인증 CMP 가 아니다. 부트는 광고 마운트만 한다.
  test('회사 페이지: placeholder 슬롯 억제(빈 박스 0) — 배너 없이', () => {
    withDom(companyPage(), (dom) => {
      bootStaticAds();
      const d = dom.window.document;
      assert.equal(d.getElementById('consent-banner'), null, '동의 배너 마크업 부재');
      for (const pos of ['content_mid', 'content_bottom']) {
        const host = d.querySelector(`[data-ad-position="${pos}"]`);
        assert.equal(host.hidden, true, `${pos}: 승인 전 hidden(#12)`);
        assert.equal(host.children.length, 0, `${pos}: 광고 박스 미생성`);
      }
      assert.equal(d.querySelector('.ad-slot'), null, '.ad-slot 렌더 0(빈 점선 박스 금지)');
    });
  });

  test('광고 로더에 비개인화 신호를 세팅한다(동의 UI 부재 → 항상 1)', () => {
    withDom(companyPage(), (dom) => {
      bootStaticAds();
      assert.equal(dom.window.adsbygoogle?.requestNonPersonalizedAds, 1);
    });
  });

  test('policy 페이지: 무광고 게이팅 — 호스트 무접촉', () => {
    withDom('<body data-page-type="policy"><div data-ad-position="content_mid"></div></body>', (dom) => {
      bootStaticAds();
      const host = dom.window.document.querySelector('[data-ad-position="content_mid"]');
      assert.equal(host.hidden, false, 'policy는 mountAds 조기 반환 — 호스트 무접촉');
    });
  });

  test('page-type 부재(404 등) → default 무광고·무크래시', () => {
    withDom('<body></body>', () => {
      assert.doesNotThrow(() => bootStaticAds());
    });
  });
});

