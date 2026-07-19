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

const BANNER = '<div id="consent-banner" hidden>'
  + '<button type="button" data-consent="grant">동의</button>'
  + '<button type="button" data-consent="deny">거부</button></div>';

function companyPage() {
  return '<body data-page-type="company">'
    + '<div data-ad-position="content_mid"></div>'
    + '<div data-ad-position="content_bottom"></div>'
    + '<div data-affiliate-host></div>'
    + BANNER + '</body>';
}

describe('SP-ADS-9 정적 페이지 부트(static-ads.js)', () => {
  test('회사 페이지: 첫 방문 → 배너 노출 + placeholder 슬롯 억제(빈 박스 0)', () => {
    withDom(companyPage(), (dom) => {
      bootStaticAds();
      const d = dom.window.document;
      assert.equal(d.getElementById('consent-banner').hidden, false, '첫 방문 배너 노출');
      for (const pos of ['content_mid', 'content_bottom']) {
        const host = d.querySelector(`[data-ad-position="${pos}"]`);
        assert.equal(host.hidden, true, `${pos}: 승인 전 hidden(#12)`);
        assert.equal(host.children.length, 0, `${pos}: 광고 박스 미생성`);
      }
      assert.equal(d.querySelector('.ad-slot'), null, '.ad-slot 렌더 0(빈 점선 박스 금지)');
    });
  });

  test('기존 동의 결정 존재 → 배너 hidden 유지(CS-2)', () => {
    withDom(companyPage(), (dom) => {
      setConsent(false);            // 이 JSDOM의 쿠키/스토리지에 결정 기록
      bootStaticAds();
      assert.equal(dom.window.document.getElementById('consent-banner').hidden, true);
    });
  });

  test('배너의 동의 클릭 → 배너 숨김(결정 저장 경로 배선)', () => {
    withDom(companyPage(), (dom) => {
      bootStaticAds();
      const d = dom.window.document;
      d.querySelector('[data-consent="grant"]').click();
      assert.equal(d.getElementById('consent-banner').hidden, true, '클릭 후 숨김');
    });
  });

  test('policy 페이지: 무광고 게이팅 — 호스트 무접촉, 배너는 노출', () => {
    withDom('<body data-page-type="policy"><div data-ad-position="content_mid"></div>' + BANNER + '</body>', (dom) => {
      bootStaticAds();
      const d = dom.window.document;
      const host = d.querySelector('[data-ad-position="content_mid"]');
      assert.equal(host.hidden, false, 'policy는 mountAds 조기 반환 — 호스트 무접촉');
      assert.equal(d.getElementById('consent-banner').hidden, false, '배너는 페이지 유형 무관 노출');
    });
  });

  test('page-type 부재(404 등) → default 무광고·무크래시', () => {
    withDom('<body>' + BANNER + '</body>', (dom) => {
      assert.doesNotThrow(() => bootStaticAds());
      assert.equal(dom.window.document.getElementById('consent-banner').hidden, false);
    });
  });

  test('배너 마크업 부재 페이지에서도 무크래시', () => {
    withDom('<body data-page-type="company"></body>', () => {
      assert.doesNotThrow(() => bootStaticAds());
    });
  });
});
