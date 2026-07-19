// web/assets/js/ads.test.js — SP-ADS-3~7 광고·제휴·동의 오케스트레이터 단위 테스트.
// 근거: SPEC/08-광고-제휴-통합.md §SP-ADS-3~7·10, TASK/08-광고제휴.md T-08.1·3·6·7.
// 순수 서브셋(adPolicy·resolveSlotId·filterAffiliate·buildAffiliateAttrs·parseConsent)은
// 브라우저 없이 테스트. document/window/fetch가 필요한 경로(getConsent 쿠키 폴백·
// applyConsentSignal·loadAffiliate)는 최소 in-memory 목으로 검증한다.
// DOM 렌더(mountManualSlot·renderAffiliateCard·initConsentBanner 등)는 SP-ADS-1.2에 따라
// 수동 브라우저 체크리스트(MB-ADS-*)로 검증하며 여기서는 다루지 않는다.
import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

import {
  PAGE_TYPES, adPolicy, resolveSlotId, detectPageType, mountAds,
  filterAffiliate, buildAffiliateAttrs, loadAffiliate,
  parseConsent, getConsent, setConsent, isPersonalized, applyConsentSignal,
  initConsentBanner,
} from './ads.js';
import { adsConfig } from './adsConfig.js';
import { JSDOM } from 'jsdom';

const HERE = dirname(fileURLToPath(import.meta.url));
const ADS_URL = pathToFileURL(join(HERE, 'ads.js')).href;

// ── 최소 브라우저 전역 스텁 ──────────────────────────────────────────────
// dom.js safeUrl()이 상대 URL 폴백 시 참조하는 location(dom.test.js와 동일 패턴).
globalThis.location = { origin: 'https://loupit.example' };

// in-memory localStorage 목(store.js 대응, store.test.js와 동일 패턴).
class FakeLocalStorage {
  constructor() { this._data = new Map(); }
  getItem(key) { return this._data.has(key) ? this._data.get(key) : null; }
  setItem(key, value) { this._data.set(key, String(value)); }
  removeItem(key) { this._data.delete(key); }
  clear() { this._data.clear(); }
}
globalThis.localStorage = new FakeLocalStorage();

// document.cookie 목(1st-party 쿠키 폴백 CS-5 전용 최소 저장소, 단일 키만 다룸).
function makeCookieJar() {
  let jar = {};
  return {
    get cookie() { return Object.entries(jar).map(([k, v]) => k + '=' + v).join('; '); },
    set cookie(str) {
      const pair = String(str).split(';')[0];
      const eq = pair.indexOf('=');
      if (eq < 0) return;
      jar[pair.slice(0, eq).trim()] = pair.slice(eq + 1);
    },
    _clear() { jar = {}; },
    body: { dataset: {} },
  };
}
globalThis.document = makeCookieJar();

// window === globalThis: applyConsentSignal의 window.adsbygoogle 참조 지원.
globalThis.window = globalThis;

beforeEach(() => {
  globalThis.localStorage.clear();
  globalThis.document._clear();
  globalThis.document.body = { dataset: {} };
  delete globalThis.adsbygoogle;
});

// ── T-08.1.1: ads.js 공개 심볼 존재(구조 스모크) ────────────────────────────
describe('T-08.1.1 ads.js 모듈 골격·공개 심볼 스모크', () => {
  test('공개 심볼 전량 export', () => {
    assert.deepEqual(PAGE_TYPES, ['landing', 'company', 'combo', 'input', 'result', 'policy']);
    for (const fn of [
      mountAds, adPolicy, filterAffiliate, resolveSlotId, loadAffiliate,
      initConsentBanner, getConsent, setConsent, isPersonalized, parseConsent,
      detectPageType, buildAffiliateAttrs,
    ]) assert.equal(typeof fn, 'function');
  });
});

// ── T-08.3.1: adPolicy 배치 표 게이팅 (UT-ADS-GATE-1~5) ─────────────────────
describe('T-08.3.1 adPolicy 배치 표 게이팅 (UT-ADS-GATE-1~5)', () => {
  test('UT-ADS-GATE-1 [Tier-0]: input → 무광고 강제(auto OFF·manual[]·affiliate none)', () => {
    assert.deepEqual(adPolicy('input'), { auto: 'OFF', manual: [], affiliate: 'none' });
  });

  test('UT-ADS-GATE-2: result → manual 정확히 1(report_bottom), auto OFF', () => {
    const p = adPolicy('result');
    assert.deepEqual(p.manual, ['report_bottom']);
    assert.equal(p.manual.length, 1);
    assert.equal(p.auto, 'OFF');
  });

  test('UT-ADS-GATE-3: company·combo → manual 2슬롯, auto ON, affiliate on', () => {
    for (const t of ['company', 'combo']) {
      const p = adPolicy(t);
      assert.deepEqual(p.manual, ['content_mid', 'content_bottom']);
      assert.equal(p.auto, 'ON');
      assert.equal(p.affiliate, 'on');
    }
  });

  test('UT-ADS-GATE-4: landing → auto ON, manual=[content_bottom], affiliate optional', () => {
    const p = adPolicy('landing');
    assert.equal(p.auto, 'ON');
    assert.deepEqual(p.manual, ['content_bottom']);
    assert.equal(p.affiliate, 'optional');
  });

  test('UT-ADS-GATE-5: policy·미상값·undefined → 전부 무광고 폴백(안전 기본값)', () => {
    for (const t of ['policy', 'zzz', undefined]) {
      assert.deepEqual(adPolicy(t), { auto: 'OFF', manual: [], affiliate: 'none' });
    }
  });
});

// ── T-08.3.2: resolveSlotId 위치→슬롯 id 매핑 (UT-ADS-SLOT-1) ───────────────
describe('T-08.3.2 resolveSlotId (UT-ADS-SLOT-1)', () => {
  test('UT-ADS-SLOT-1: (result,report_bottom) → adsConfig.AD_SLOT.result_bottom / (input,x) → null', () => {
    assert.equal(resolveSlotId('result', 'report_bottom'), adsConfig.AD_SLOT.result_bottom);
    assert.equal(resolveSlotId('input', 'x'), null);
  });

  test('resolveSlotId: company content_mid/content_bottom 매핑 정합', () => {
    assert.equal(resolveSlotId('company', 'content_mid'), adsConfig.AD_SLOT.company_mid);
    assert.equal(resolveSlotId('company', 'content_bottom'), adsConfig.AD_SLOT.company_bottom);
  });

  test('resolveSlotId: 매핑 없는 (pageType,position) 조합 → null(슬롯 미렌더)', () => {
    assert.equal(resolveSlotId('zzz', 'content_mid'), null);
    assert.equal(resolveSlotId('landing', 'content_mid'), null);   // landing엔 content_mid 미정의(배치 표)
  });
});

// ── T-08.3.3(보너스 스모크): detectPageType body[data-page-type] 판별 ───────
describe('detectPageType body[data-page-type] 판별(보너스 스모크, MB-ADS 주 검증)', () => {
  test('PAGE_TYPES 소속 값 → 그대로 반환', () => {
    globalThis.document.body.dataset.pageType = 'company';
    assert.equal(detectPageType(), 'company');
  });

  test('미상 값·미부착 → "default"(무광고 폴백)', () => {
    globalThis.document.body.dataset.pageType = 'not-a-real-type';
    assert.equal(detectPageType(), 'default');
    delete globalThis.document.body.dataset.pageType;
    assert.equal(detectPageType(), 'default');
  });
});

// ── mountAds 게이팅 즉시 반환(G-2) — DOM/네트워크 미접근 확인 ───────────────
describe('mountAds 게이팅 즉시 반환(G-2)', () => {
  test('input/policy/미상 page_type → 즉시 반환(DOM 0 접근, 예외 없음)', () => {
    const noQuerySelectorRoot = {};   // querySelector 없음 — 접근 시 즉시 throw로 드러남
    for (const t of ['input', 'policy', 'zzz']) {
      assert.doesNotThrow(() => mountAds(t, noQuerySelectorRoot));
    }
  });
});

// ── T-08.6.1: affiliate.json 스키마(실파일 로드) (UT-ADS-CONFIG-1) ──────────
describe('T-08.6.1 affiliate.json 스키마 (UT-ADS-CONFIG-1)', () => {
  test('UT-ADS-CONFIG-1: 실파일 로드·파싱 → 스키마 정합', () => {
    const raw = readFileSync(join(HERE, '..', 'data', 'affiliate.json'), 'utf8');
    const data = JSON.parse(raw);
    assert.ok(Number.isInteger(data.version) && data.version >= 1, 'version은 1 이상 정수');
    assert.ok(Array.isArray(data.items), 'items는 배열');

    const seen = new Set();
    const KEBAB = /^[a-z0-9]+(-[a-z0-9]+)*$/;
    const ALLOWED_PAGE_TYPES = new Set(['landing', 'company', 'combo', 'result']);
    for (const it of data.items) {
      assert.equal(typeof it.id, 'string');
      assert.match(it.id, KEBAB, `id '${it.id}'는 kebab-case`);
      assert.ok(!seen.has(it.id), `id 중복: ${it.id}`);
      seen.add(it.id);
      assert.equal(typeof it.label, 'string');
      assert.notEqual(it.label.trim(), '');
      assert.match(it.url, /^https?:\/\//, `url '${it.url}'은 http/https 스킴`);
      assert.ok(Array.isArray(it.page_types));
      for (const pt of it.page_types) assert.ok(ALLOWED_PAGE_TYPES.has(pt), `page_types 금지값 '${pt}'(input/policy 불가)`);
      assert.equal(typeof it.active, 'boolean');
    }
  });
});

// ── T-08.6.2: filterAffiliate 순수 필터 (UT-ADS-FILTER-1~4) ─────────────────
describe('T-08.6.2 filterAffiliate (UT-ADS-FILTER-1~4)', () => {
  const FIXTURE = [
    { id: 'a1', label: '이력서 첨삭', url: 'https://x.co/a', desc: null, page_types: ['company', 'combo'], active: true },
    { id: 'a2', label: '비활성 항목', url: 'https://x.co/b', page_types: ['company'], active: false },
    { id: 'a3', label: '다른 페이지', url: 'https://x.co/c', page_types: ['landing'], active: true },
  ];

  test('UT-ADS-FILTER-1: active===true && page_types.includes(company) 항목만', () => {
    const out = filterAffiliate(FIXTURE, 'company');
    assert.deepEqual(out.map(i => i.id), ['a1']);
  });

  test('UT-ADS-FILTER-2: input·policy → [](게이팅, 항목이 있어도)', () => {
    assert.deepEqual(filterAffiliate(FIXTURE, 'input'), []);
    assert.deepEqual(filterAffiliate(FIXTURE, 'policy'), []);
  });

  test('UT-ADS-FILTER-3: url 스킴 위반(javascript:) → 제외(safeUrl null)', () => {
    const items = [{ id: 'x', label: 'x', url: 'javascript:alert(1)', page_types: ['company'], active: true }];
    assert.deepEqual(filterAffiliate(items, 'company'), []);
  });

  test('UT-ADS-FILTER-4: 동일 id 2건(선입 유지·후속 배제) / 빈 label → 제외', () => {
    const dup = [
      { id: 'dup', label: 'A', url: 'https://x.co/1', page_types: ['company'], active: true },
      { id: 'dup', label: 'B', url: 'https://x.co/2', page_types: ['company'], active: true },
    ];
    const out = filterAffiliate(dup, 'company');
    assert.equal(out.length, 1);
    assert.equal(out[0].label, 'A');

    const blank = [{ id: 'b1', label: '   ', url: 'https://x.co/1', page_types: ['company'], active: true }];
    assert.deepEqual(filterAffiliate(blank, 'company'), []);
  });

  test('filterAffiliate: page_types에 input/policy 혼입된 항목은 배제(스키마 위반 방어)', () => {
    const bad = [{ id: 'bad', label: 'x', url: 'https://x.co/1', page_types: ['company', 'input'], active: true }];
    assert.deepEqual(filterAffiliate(bad, 'company'), []);
  });
});

// ── T-08.6.3: buildAffiliateAttrs 광고성·안전 링크 속성 (UT-ADS-REL-1·2) ────
describe('T-08.6.3 buildAffiliateAttrs (UT-ADS-REL-1·2)', () => {
  test('UT-ADS-REL-1: https URL → rel에 sponsored/nofollow/noopener 포함, target=_blank, href=원 URL', () => {
    const attrs = buildAffiliateAttrs('https://x.co/a');
    assert.match(attrs.rel, /sponsored/);
    assert.match(attrs.rel, /nofollow/);
    assert.match(attrs.rel, /noopener/);
    assert.equal(attrs.target, '_blank');
    assert.equal(attrs.href, 'https://x.co/a');
  });

  test('UT-ADS-REL-2: ftp:// → href===null(스킴 위반)', () => {
    assert.equal(buildAffiliateAttrs('ftp://x').href, null);
  });
});

// ── T-08.6.4: loadAffiliate fetch 목·캐시·손상/실패 폴백 ────────────────────
// 모듈 로컬 캐시(_affiliateCache)가 프로세스 수명 동안 유지되므로, 시나리오별로
// 쿼리스트링을 달리해 독립 모듈 인스턴스를 동적 import하여 캐시 오염을 피한다.
describe('T-08.6.4 loadAffiliate (fetch 목)', () => {
  test('정상 JSON 응답 → 그대로 반환', async () => {
    globalThis.fetch = async () => ({ json: async () => ({ version: 1, items: [{ id: 'x' }] }) });
    const mod = await import(ADS_URL + '?case=ok');
    assert.deepEqual(await mod.loadAffiliate(), { version: 1, items: [{ id: 'x' }] });
  });

  test('fetch reject(네트워크 실패) → {version:1,items:[]} 폴백(AF-7, 무크래시)', async () => {
    globalThis.fetch = async () => { throw new Error('network fail'); };
    const mod = await import(ADS_URL + '?case=fail-reject');
    assert.deepEqual(await mod.loadAffiliate(), { version: 1, items: [] });
  });

  test('손상 JSON(items 배열 아님) → {version:1,items:[]} 폴백', async () => {
    globalThis.fetch = async () => ({ json: async () => ({ version: 1, items: 'not-array' }) });
    const mod = await import(ADS_URL + '?case=fail-shape');
    assert.deepEqual(await mod.loadAffiliate(), { version: 1, items: [] });
  });

  test('모듈 캐시: 두 번째 호출은 fetch 재호출 없이 캐시 반환', async () => {
    let calls = 0;
    globalThis.fetch = async () => { calls++; return { json: async () => ({ version: 1, items: [] }) }; };
    const mod = await import(ADS_URL + '?case=cache');
    await mod.loadAffiliate();
    await mod.loadAffiliate();
    assert.equal(calls, 1);
  });
});

// ── T-08.7.1: parseConsent 순수 봉투 파서 (UT-ADS-CONSENT-1) ────────────────
describe('T-08.7.1 parseConsent (UT-ADS-CONSENT-1)', () => {
  test('UT-ADS-CONSENT-1: v/personalized 정상 → true / v 불일치 → null / 빈 객체 → null / null → null', () => {
    assert.equal(parseConsent({ v: 1, personalized: true }), true);
    assert.equal(parseConsent({ v: 2, personalized: true }), null);
    assert.equal(parseConsent({}), null);
    assert.equal(parseConsent(null), null);
  });

  test('parseConsent: personalized가 boolean 아니면 손상 취급 → null', () => {
    assert.equal(parseConsent({ v: 1, personalized: 'true' }), null);
  });
});

// ── T-08.7.2: getConsent·setConsent·isPersonalized 상태 저장 ────────────────
describe('T-08.7.2 getConsent·setConsent·isPersonalized (localStorage 우선·쿠키 폴백)', () => {
  test('setConsent(true) → getConsent()===true, isPersonalized()===true', () => {
    setConsent(true);
    assert.equal(getConsent(), true);
    assert.equal(isPersonalized(), true);
  });

  test('setConsent(false) → getConsent()===false, isPersonalized()===false', () => {
    setConsent(false);
    assert.equal(getConsent(), false);
    assert.equal(isPersonalized(), false);
  });

  test('아무 상태 없음(첫 방문) → getConsent()===null(미선택)', () => {
    assert.equal(getConsent(), null);
  });

  test('localStorage 저장 성공 시 쿠키에는 기록하지 않음(CS-1: 저장 경로 단일)', () => {
    setConsent(true);
    assert.equal(globalThis.document.cookie.includes('loupit.adConsent'), false);
  });

  test('localStorage 실패(QuotaExceeded 등) → 쿠키 폴백(p/n)에서 getConsent 성립(CS-5)', () => {
    const origSetItem = globalThis.localStorage.setItem.bind(globalThis.localStorage);
    globalThis.localStorage.setItem = () => { throw new Error('QuotaExceededError(mock)'); };
    setConsent(true);
    assert.ok(globalThis.document.cookie.includes('loupit.adConsent=p'));
    assert.equal(getConsent(), true);
    globalThis.localStorage.setItem = origSetItem;
  });

  test('서버 전송 경로 없음(INV-4): setConsent/getConsent는 fetch를 호출하지 않음', () => {
    let fetchCalled = false;
    const origFetch = globalThis.fetch;
    globalThis.fetch = () => { fetchCalled = true; throw new Error('네트워크 호출 금지'); };
    setConsent(true);
    getConsent();
    assert.equal(fetchCalled, false);
    globalThis.fetch = origFetch;
  });
});

// ── T-08.7.3: applyConsentSignal 비개인화 신호(로더 실행 전 세팅) ──────────
describe('T-08.7.3 applyConsentSignal (window.adsbygoogle 비개인화 신호)', () => {
  test('동의(personalized=true) → requestNonPersonalizedAds===0', () => {
    setConsent(true);
    applyConsentSignal();
    assert.equal(globalThis.window.adsbygoogle.requestNonPersonalizedAds, 0);
  });

  test('거부(personalized=false) → requestNonPersonalizedAds===1', () => {
    setConsent(false);
    applyConsentSignal();
    assert.equal(globalThis.window.adsbygoogle.requestNonPersonalizedAds, 1);
  });

  test('미선택(null, 첫 방문) → 비개인화 폴백(===1, FR-79)', () => {
    applyConsentSignal();
    assert.equal(globalThis.window.adsbygoogle.requestNonPersonalizedAds, 1);
  });
});

// ── #12: mountAds 수동 슬롯 렌더 — 승인 전 빈 "광고" 점선 박스 억제(jsdom) ──────
describe('#12 mountAds 슬롯 렌더 — placeholder 빈 광고 박스 억제', () => {
  const savedDoc = globalThis.document;
  const savedWin = globalThis.window;
  function withDom(html, fn) {
    const dom = new JSDOM(html);
    globalThis.document = dom.window.document;
    globalThis.window = dom.window;
    try { fn(dom); } finally { globalThis.document = savedDoc; globalThis.window = savedWin; }
  }

  test('placeholder client(기본) → content_bottom 컨테이너 hidden·빈(.ad-slot 미생성)', () => {
    withDom('<div data-ad-position="content_bottom"></div>', (dom) => {
      mountAds('landing', dom.window.document);
      const host = dom.window.document.querySelector('[data-ad-position="content_bottom"]');
      assert.equal(host.children.length, 0, '승인 전 광고 박스 미생성');
      assert.equal(host.hidden, true, '빈 컨테이너 hidden(빈 점선박스 노출 방지)');
    });
  });

  test('실 client id 주입 시 → .ad-slot 렌더·hidden 해제', () => {
    const savedClient = adsConfig.AD_CLIENT;
    const savedSlot = adsConfig.AD_SLOT.landing_bottom;
    adsConfig.AD_CLIENT = 'ca-pub-1234567890123456';
    adsConfig.AD_SLOT.landing_bottom = '1234567890';
    try {
      withDom('<div data-ad-position="content_bottom"></div>', (dom) => {
        mountAds('landing', dom.window.document);
        const host = dom.window.document.querySelector('[data-ad-position="content_bottom"]');
        assert.equal(host.hidden, false, '실 광고 시 컨테이너 표시');
        assert.ok(host.querySelector('.ad-slot'), '.ad-slot 박스 렌더');
      });
    } finally {
      adsConfig.AD_CLIENT = savedClient;
      adsConfig.AD_SLOT.landing_bottom = savedSlot;
    }
  });
});
