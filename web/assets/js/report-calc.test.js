// web/assets/js/report-calc.test.js — 이직 계산기 결과 화면(SP-FE-14, 2026-09-23 개편) jsdom 테스트.
// 근거: IMPL-BRIEF §3(문구 규칙 — 테스트로 박아라)·§2(결정 5·6)·§4(기존 동작) + FINAL-DESIGN §8-3 ⓔ·ⓕ·ⓒ(DOM).
// 엔진 값은 calc.test.js 가 잰다 — 여기는 **화면이 무엇을 말하고 무엇을 말하지 않는가**다.
globalThis.window = { addEventListener() {}, removeEventListener() {} };
globalThis.document = { addEventListener() {}, removeEventListener() {}, getElementById() { return null; }, querySelector() { return null; }, createElement() { return {}; } };
globalThis.history = { pushState() {}, replaceState() {} };
globalThis.location = { hash: '', search: '' };

import test, { describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { JSDOM } from 'jsdom';

import { compare } from './calc.js';
import { renderReport } from './report.js';
import { BLOCK_ORDER, headlineText } from './report-calc.js';
import { normalizeCompany, fillBenefits, blankWs } from './inputs.js';
import { createInitialState, runReport } from './app.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const G = JSON.parse(readFileSync(join(HERE, '../../test/fixtures/calc-golden-naver-kakao.json'), 'utf8'));
const SHELL = readFileSync(join(HERE, '../../compare/index.html'), 'utf8');
const NOW = new Date('2026-09-22T00:00:00+09:00').getTime();

function loadShell() {
  const dom = new JSDOM(SHELL, { url: 'https://loupit.example/compare/', pretendToBeVisual: true });
  globalThis.document = dom.window.document;
  globalThis.window = dom.window;
  globalThis.history = dom.window.history;
  globalThis.location = dom.window.location;
  dom.window.document.getElementById('app').hidden = false;
  return dom;
}

const items = (c) => c.benefits.map((b) => ({ ...b, checked: true }));
const WS = () => ({
  a: { ot: 'mid', hours: 45, wage: 'separate', remote: false, flex: true },
  b: { ot: 'high', hours: 54, wage: 'inclusive', remote: false, flex: true },
});
function goldenEngineState(over = {}) {
  return {
    salStr: '6000-6000', selectedRate: 15, benS: { a: items(G.naver), b: items(G.kakao) }, wsState: WS(),
    com: { a: 40, b: 60 }, commuteIn: { a: 40, b: 60 }, tenureYears: 3, curPri: 'salary', curSacrifice: null,
    matched: { a: G.naver, b: G.kakao }, ...over,
  };
}
function render(st, axis = 'salary', extra = {}) {
  const r = compare(st, NOW);
  const mount = document.getElementById('report-body');
  renderReport(r, mount, {
    benS: st.benS, matched: st.matched, now: NOW, axis, recent: false,
    input: { salA: r.a.salRange.mid, rate: st.selectedRate, ws: st.wsState, commute: st.commuteIn, tenureYears: st.tenureYears },
    ...extra,
  });
  return { r, mount };
}
// 블록을 전부 펼친 채로 본 화면 전체 글자 + aria-label.
function allText(mount) {
  for (const d of mount.querySelectorAll('details')) d.open = true;
  const labels = [...mount.querySelectorAll('[aria-label]')].map((n) => n.getAttribute('aria-label')).join(' ');
  return mount.textContent + ' ' + labels;
}
const txt = (mount, sel) => { const n = mount.querySelector(sel); return n ? n.textContent.replace(/\s+/g, ' ').trim() : ''; };

// 여러 조건 — 문구 규칙은 골든 쌍 하나가 아니라 갈래마다 지켜져야 한다.
function scenarios() {
  const base = goldenEngineState();
  const wageUnknown = goldenEngineState({ wsState: { ...WS(), b: { ot: 'high', hours: 54, wage: null } } });
  const noHours = goldenEngineState({ wsState: { a: { wage: 'separate' }, b: { wage: 'inclusive' } }, commuteIn: { a: null, b: null }, tenureYears: null });
  const lateral = goldenEngineState({ selectedRate: 0 });
  const swapped = goldenEngineState({ benS: { a: items(G.kakao), b: items(G.naver) }, matched: { a: G.kakao, b: G.naver }, selectedRate: -5 });
  const unsure = goldenEngineState({ selectedRate: 36.85, wsState: { a: { hours: 45, wage: 'inclusive' }, b: { hours: 45, wage: 'inclusive' } } });
  return { base, wageUnknown, noHours, lateral, swapped, unsure };
}

describe('RC-1 골든 쌍 — 목업 v2 문장', () => {
  beforeEach(() => loadShell());

  test('연봉 축: 배지·헤드라인·인상률·근거 칩·뒤집는 조건 줄·타일 3칸', () => {
    const { mount } = render(goldenEngineState());
    assert.equal(txt(mount, '.calc-vd-top .calc-bd'), '연봉은 오르지만 총보상은 줄어듭니다');
    assert.equal(txt(mount, '.calc-hl'), '입력하신 조건으로 계산하면, 연봉은 15% 올라 6,900만원이 되지만 복지와 야근수당 차이 때문에 총보상은 오히려 연 2,211만원 줄어듭니다.');
    assert.match(txt(mount, '.calc-rates'), /연봉 인상률\s*\+15\.0%.*총보상 증감률\s*−22\.2%/);
    assert.match(txt(mount, '.calc-evid'), /연봉 \+900.*복지 −2,179 \(그중 856은 카카오 금액 미등록\).*야근수당 −932/);
    assert.match(txt(mount, '.calc-line-warn'), /입력하신 대로 카카오가 포괄임금제라면 야근수당이 따로 없습니다\. 만약 야근수당을 따로 준다면 결론이 바뀌어 카카오가 연 791만원 더 많아집니다\./);
    const tiles = [...mount.querySelectorAll('.calc-tile')].map((t) => t.textContent);
    assert.equal(tiles.length, 3);
    assert.match(tiles[0], /약 −2,211만원.*범위 −2,663 ~ −1,759 · 한 달로 치면 −184만원/);
    assert.match(tiles[1], /야근수당을 빼고 보면 −14\.2%/);
    assert.match(tiles[2], /27,561원.*42,521 → 27,561원 \(−35%\)/);
  });

  test('워라밸 축: 시간 → 결론은 회사 이름으로(「NAVER가 낫습니다」)', () => {
    const { mount } = render(goldenEngineState(), 'wlb');
    assert.equal(txt(mount, '.calc-vd-top .calc-bd'), '워라밸로 보면 · NAVER가 낫습니다');
    assert.equal(txt(mount, '.calc-hl'), '입력하신 야근 시간대로라면 카카오에서는 일주일에 9시간(1년이면 468시간, 약 59일치) 더 일하고, 출퇴근에도 1년에 160시간을 더 씁니다. 시간으로 보면 NAVER가 낫습니다.');
    assert.match(mount.querySelector('.calc-vd').textContent, /NAVER에 남는다고 손해 보는 돈도 없습니다 — 총보상도 NAVER가 연 2,211만원 많습니다\./);
    assert.match(txt(mount, '.calc-tiles'), /\+468시간.*약 59일치.*\+160시간.*NAVER 3 : 카카오 1.*NAVER 쪽 2개는 근속 연수를 채워야 받음/);
  });

  test('복지 축: 등록 금액 판정 + 한쪽만 금액 등록 고지(항상) + 연봉 상쇄 줄', () => {
    const { mount } = render(goldenEngineState(), 'benefits');
    assert.equal(txt(mount, '.calc-hl'), '등록된 복지 금액으로 보면 NAVER가 낫습니다. 1년 복지 금액이 3,018만원에서 839만원으로, 2,179만원(±452) 줄어듭니다. NAVER에만 금액이 등록된 4건을 빼고 계산해도 1,323만원(±355) 줄어들어 결론은 같습니다.');
    assert.match(txt(mount, '.calc-line-must'), /카카오에도 비슷한 제도가 있는데 금액이 등록되어 있지 않습니다\. 이 4개가 차이의 39%\(856만원\)를 차지합니다\./);
    assert.match(mount.querySelector('.calc-vd').textContent, /1,279만원이 모자랍니다/);
  });

  test('축마다 L1 블록이 다르다(펼침) · L2 는 접힘 · L3 는 비교표·자료', () => {
    for (const axis of ['salary', 'wlb', 'benefits']) {
      const { mount } = render(goldenEngineState(), axis);
      const l1 = [...mount.querySelectorAll('.calc-l1 > details')];
      assert.deepEqual(l1.map((d) => d.id.replace('calc-b-', '')), BLOCK_ORDER[axis].l1, axis);
      assert.ok(l1.every((d) => d.open), axis + ' L1 펼침');
      assert.ok([...mount.querySelectorAll('.calc-l2 > details')].every((d) => !d.open), axis + ' L2 접힘');
      assert.deepEqual([...mount.querySelectorAll('.calc-l3 > details')].map((d) => d.id), ['calc-b-contrast', 'calc-b-basis']);
    }
  });

  test('보조 행: 다른 두 축을 한 줄씩', () => {
    const { mount } = render(goldenEngineState(), 'salary');
    assert.match(txt(mount, '.calc-aux'), /워라밸로 보면 — 입력하신 야근 시간대로라면 카카오에서 주 9시간 더 일하고, 통근도 1년에 160시간 더.*복지로 보면 — 1년 복지 금액 3,018 → 839만원/);
  });

  test('조건 줄 + 「조건 고치기」 → onEdit', () => {
    let edited = 0;
    const { mount } = render(goldenEngineState(), 'salary', { onEdit: () => { edited += 1; } });
    assert.match(txt(mount, '.calc-cond').replace(/\s*·\s*/g, ' · '), /NAVER → 카카오 · 연봉 6,000만원 · 상승률 \+15% · 야근 보통\(비포괄\) → 잦음\(포괄\) · 통근 40 → 60분 · 근속 3년/);
    mount.querySelector('.calc-cond-edit').click();
    assert.equal(edited, 1);
  });
});

describe('RC-2 문구 회귀(ⓔ·ⓕ) — 모든 갈래·모든 블록 펼침', () => {
  beforeEach(() => loadShell());
  const FORBIDDEN = ['사라짐', '사라져', '없어집니다', '총연봉', '실수령', '95%', '가족까지 확대'];
  // 개발 용어 — 사용자에게 보이는 글자·aria-label 에 나오면 안 된다(IMPL-BRIEF §3). 「실효 총보상」은 지표명(결정 7)이다.
  const DEV = ['판정', '정성', '혼합', 'diff', '대조표', '덩이', '4분해', '감도', '앵커', '밴드', '플래그', '격리', '원문', '리셋', '명목', '실효 인상률', 'L1', 'L2', 'L3', '시나리오', 'undefined', 'NaN', '[object'];

  test('금지어·개발 용어 0건, 「신뢰구간」은 「통계적 신뢰구간이 아닙니다」 안에서만', () => {
    for (const [name, st] of Object.entries(scenarios())) {
      for (const axis of ['salary', 'wlb', 'benefits']) {
        const { mount } = render(st, axis);
        const t = allText(mount);
        for (const w of FORBIDDEN) assert.ok(!t.includes(w), `${name}/${axis}: 금지어 「${w}」`);
        for (const w of DEV) assert.ok(!t.includes(w), `${name}/${axis}: 개발 용어 「${w}」`);
        assert.ok(!/폭(?!넓)/.test(t.replace(/오차 폭/g, '')), `${name}/${axis}: 「폭」`);
        assert.equal(t.replace(/통계적 신뢰구간이 아닙니다/g, '').includes('신뢰구간'), false, `${name}/${axis}: 신뢰구간`);
      }
    }
  });

  test('ⓕ 임금 형태(포괄·비포괄)를 말하는 문장은 「입력하신」 또는 가정형 — 회사 사실처럼 단정하지 않는다', () => {
    const SENT = '.calc-hl, .calc-line, .calc-help, .calc-blk-t, .calc-wagecases-h, .calc-sens-sub, .calc-cap li, .calc-ghost, .calc-nego';
    for (const [name, st] of Object.entries(scenarios())) {
      for (const axis of ['salary', 'wlb', 'benefits']) {
        const { mount } = render(st, axis);
        for (const d of mount.querySelectorAll('details')) d.open = true;
        for (const n of mount.querySelectorAll(SENT)) {
          const s = n.textContent;
          if (!/포괄/.test(s)) continue;
          assert.match(s, /입력하신|(이|라)면|준다면/, `${name}/${axis}: 「${s.slice(0, 60)}…」`);
          assert.doesNotMatch(s, /(는|은) 포괄임금이라/, `${name}/${axis}: 회사 사실 주어`);
        }
      }
    }
  });

  test('금액 없는 칸은 「금액 미등록」 — 「—」「0」으로 찍지 않는다', () => {
    const { mount } = render(goldenEngineState(), 'benefits');
    for (const d of mount.querySelectorAll('details')) d.open = true;
    for (const td of mount.querySelectorAll('td')) assert.notEqual(td.textContent.trim(), '—');
    const noAmt = [...mount.querySelectorAll('.calc-noamt')];
    assert.ok(noAmt.length > 0);
    assert.ok(noAmt.every((n) => n.textContent === '금액 미등록'));
  });

  test('카테고리 라벨은 사이트 정본(복리후생) · 생활·편의 겹침은 「비슷함」이고 +112 는 어디에도 없다', () => {
    const { mount } = render(goldenEngineState(), 'benefits');
    const t = allText(mount);
    assert.match(t, /복리후생은 비슷함/);
    assert.ok(!t.includes('+112'));
    assert.ok(!/(?<![\d,])(−5일|96만원)/.test(t), '법정 연차 환산 숫자 없음(결정 3)');
    assert.ok(!/법정 연차[^(]*\d+일/.test(t), '법정 연차는 「계산하지 않은 것」에만');
  });
});

describe('RC-3 판단하기 어려움 · 야근수당 미선택 · 시간 미입력', () => {
  beforeEach(() => loadShell());

  test('ⓒ unsure 티어: 판정 카드·첫 타일·보조 줄에 총보상 차액 숫자가 없다', () => {
    const st = scenarios().unsure;
    const { r, mount } = render(st, 'salary');
    assert.equal(r.axes.salary.tier, 'unsure', '사전조건: 오차 범위 안');
    const d = Math.abs(r.deltas.totalDiff).toLocaleString('ko-KR');
    assert.ok(Math.abs(r.deltas.totalDiff) >= 10, '사전조건: 숫자가 두 자리 이상이라 검사가 의미 있다');
    assert.equal(txt(mount, '.calc-vd-top .calc-bd'), '판단하기 어렵습니다');
    assert.ok(!txt(mount, '.calc-vd').includes(d), '판정 카드에 차액');
    assert.ok(!txt(mount, '.calc-tile').includes(d), '첫 타일에 차액');
    const { mount: m2 } = render(st, 'wlb');
    assert.ok(!txt(m2, '.calc-aux').includes(d), '보조 줄에 차액');
    assert.ok(!headlineText(r, { matched: st.matched, input: {} }, 'salary').includes(d), '낭독 줄에 차액');
  });

  test('야근수당 미선택(결정 4) — 포괄이면 / 비포괄이면 나란히, 결론이 갈리면 「야근수당에 따라」', () => {
    const { mount } = render(scenarios().wageUnknown, 'salary');
    assert.equal(txt(mount, '.calc-vd-top .calc-bd'), '야근수당에 따라 결론이 달라집니다');
    const cases = [...mount.querySelectorAll('.calc-wagecases-list li')].map((li) => li.textContent);
    assert.equal(cases.length, 2);
    assert.match(cases.join(' | '), /카카오가 포괄이면 → 총보상 연 2,211만원 감소 \| 카카오가 비포괄이면 → 총보상 연 791만원 증가/);
    assert.match(txt(mount, '.calc-wagecases-h'), /입력하신 조건에 카카오의 야근수당 여부/);
  });

  test('주 근무시간 미입력 — 시간당·야근수당은 계산하지 않았다고 말한다', () => {
    const { mount } = render(scenarios().noHours, 'salary');
    assert.match(txt(mount, '.calc-vd'), /입력하신 조건에 주 근무시간이 없어, 야근수당과 시간당 총보상은 계산하지 않았습니다/);
    assert.match(txt(mount, '.calc-tiles'), /시간당 총보상\s*계산하지 않음/);
    const { mount: m2 } = render(scenarios().noHours, 'wlb');
    assert.equal(txt(m2, '.calc-vd-top .calc-bd'), '워라밸로 보면 · 가리기 어렵습니다');
  });

  test('근속 미입력 — 받는 중/아직 판정 없이 조건만, 넣으라는 안내', () => {
    const { mount } = render(goldenEngineState({ tenureYears: null }), 'salary');
    const ledger = mount.querySelector('#calc-b-ledger');
    ledger.open = true;
    assert.match(txt(ledger, 'summary'), /근속 연수에 따라 받는 복지 — NAVER 3개 · 카카오 0개/);
    assert.ok(!ledger.textContent.includes('받는 중'));
    assert.match(ledger.textContent, /근속 연수를 넣으면 지금 받고 있는 것과 아직 아닌 것을 갈라 드립니다/);
  });
});

describe('RC-4 출처 계보 배지 · 출처 URL 비노출(옛 renderBands 계약 이식)', () => {
  beforeEach(() => loadShell());
  const mk = (cd, over) => ({ benefit_cd: cd, benefit_nm: cd + '항목', benefit_amt: 100, benefit_ctgr_cd: 'perks', qual_yn: false, amt_source: 'stated', badge_cd: 'official', checked: true, expires_dtm: null, ...over });
  function lineageState(a) {
    return goldenEngineState({ benS: { a, b: [] }, matched: { a: { comp_nm: 'A사', comp_eng_nm: 'a' }, b: { comp_nm: 'B사', comp_eng_nm: 'b' } } });
  }
  const badgeOf = (mount, nm) => {
    for (const d of mount.querySelectorAll('details')) d.open = true;
    const row = [...mount.querySelectorAll('.calc-drow')].find((r) => r.querySelector('.calc-dnm').textContent.startsWith(nm));
    return row.querySelector('.badge');
  };

  test('공식·추정은 금액 신뢰도(amt_source) · 재직자 수정·등록이 이기고 · 만료가 가장 앞선다', () => {
    const { mount } = render(lineageState([
      mk('s', { amt_source: 'stated' }), mk('e', { amt_source: 'estimated' }),
      mk('ed', { edit_origin: 'edited' }), mk('mb', { edit_origin: 'member' }),
      mk('ex', { edit_origin: 'member', expires_dtm: '2000-01-01T00:00:00Z' }),
    ]), 'benefits');
    assert.equal(badgeOf(mount, 's항목').textContent, '공식');
    assert.equal(badgeOf(mount, 'e항목').textContent, '추정');
    assert.equal(badgeOf(mount, 'ed항목').textContent, '공식·수정');
    assert.equal(badgeOf(mount, 'mb항목').className, 'badge badge--member');
    assert.equal(badgeOf(mount, 'ex항목').textContent, '만료', '신선도가 최우선');
  });

  test('출처 URL 은 어떤 형태로도 렌더되지 않는다', () => {
    const st = lineageState([mk('u1', { badge_src_url_ctnt: 'https://x.co/a' }), mk('u2', { badge_src_url_ctnt: 'javascript:alert(1)' })]);
    assert.ok(st.benS.a.some((i) => i.badge_src_url_ctnt.startsWith('https://')), '자기검증 — 표본이 URL 을 담고 있다');
    const { mount } = render(st, 'salary');
    const t = allText(mount);
    assert.ok(!t.includes('x.co') && !t.includes('javascript:'));
    assert.equal(mount.querySelectorAll('a[href^="http"], a[href^="javascript"]').length, 0);
  });

  test('실경로 — REF → normalizeCompany → fillBenefits → compare → 화면까지 계보가 살아온다', () => {
    const state = {
      REF: { company_types: [], benefit_presets: {}, companies: [] }, matched: { a: null, b: null }, benS: { a: [], b: [] },
      wsState: { a: blankWs(), b: blankWs() }, chosenType: { a: null, b: null }, inputMode: { a: 'company', b: 'company' },
    };
    state.matched.a = normalizeCompany({ comp_id: 1, comp_nm: '삼성전자', comp_eng_nm: 'samsung_elec', benefits: [mk('cafe', { benefit_nm: '카페', edit_origin: 'member' })] });
    state.matched.b = normalizeCompany({ comp_id: 2, comp_nm: 'SK하이닉스', comp_eng_nm: 'sk_hynix', benefits: [] });
    fillBenefits(state, 'a');
    fillBenefits(state, 'b');
    const st = goldenEngineState({ benS: state.benS, matched: state.matched });
    const { mount } = render(st, 'benefits');
    assert.equal(badgeOf(mount, '카페').textContent, '재직자 등록', 'edit_origin 이 정규화에서 사라지면 「공식」이 나온다');
  });
});

describe('RC-5 상호작용 — 축 전환 · 행별 「빼고 다시 계산」(결정 5·6, app.runReport 경유)', () => {
  let dom;
  beforeEach(() => { dom = loadShell(); });

  function appState() {
    const s = createInitialState();
    s.REF = { companies: [G.naver, G.kakao], company_types: [], benefit_presets: {} };
    s.matched.a = normalizeCompany(G.naver);
    s.matched.b = normalizeCompany(G.kakao);
    fillBenefits(s, 'a');
    fillBenefits(s, 'b');
    s.salS.a = { low: 6000, high: 6000 };
    s.selectedRate = 15;
    s.wsState = WS();
    s.cmtS = { a: 40, b: 60 };
    s.tenureYears = 3;
    return s;
  }
  const run = (s) => runReport({ state: s, save: false, compareFn: (st) => compare(st, NOW) });

  test('세그먼트 → 재계산 없이 축 전환 · curPri 동기 · 낭독 줄은 결론 한 줄', () => {
    const s = appState();
    let calls = 0;
    runReport({ state: s, save: false, compareFn: (st) => { calls += 1; return compare(st, NOW); } });
    const before = calls;
    document.getElementById('calc-out-wlb').click();
    assert.equal(calls, before, '축 전환은 다시 계산하지 않는다(세 축 미리 계산)');
    assert.equal(s.curPri, '워라밸');
    assert.equal(document.querySelector('.calc-vd').getAttribute('data-axis'), 'wlb');
    assert.equal(document.getElementById('calc-out-wlb').getAttribute('aria-checked'), 'true');
    assert.equal(document.activeElement.id, 'calc-out-wlb');
    const live = document.getElementById('calc-live');
    assert.equal(live.getAttribute('aria-live'), 'polite');
    assert.match(live.textContent, /^워라밸로 보면: 입력하신 야근 시간대로라면/);
    assert.ok(!document.getElementById('report-body').contains(live), '낭독 영역은 다시 그리는 본문 밖');
    document.getElementById('calc-out-benefits').dispatchEvent(new dom.window.KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
    assert.equal(s.curPri, '워라밸', '방향키 왼쪽 = 이전 축(복지 → 워라밸)');
  });

  test('비교표 행 스위치 → checked=false → compare 재실행 → 리포트 전체 반영 + 상단 알림 · 모두 되돌리기', () => {
    const s = appState();
    run(s);
    const sw = document.getElementById('calc-sw-a-stock_grant');
    assert.ok(sw, '금액 있는 행마다 스위치');
    assert.equal(sw.getAttribute('aria-pressed'), 'false');
    sw.click();
    assert.equal(s.benS.a.find((b) => b.benefit_cd === 'stock_grant').checked, false, '엔진 checked 계약에 되쓴다');
    assert.match(document.querySelector('.calc-excl').textContent, /1건을 빼고 다시 계산한 결과입니다/);
    assert.match(document.querySelector('.calc-hl').textContent, /연 1,211만원 줄어듭니다/, '결론 문장까지 다시 계산');
    assert.equal(document.getElementById('calc-sw-a-stock_grant').getAttribute('aria-pressed'), 'true');
    assert.match(document.getElementById('calc-recalc').textContent, /1건 뺌 · NAVER 1,000만원/);
    assert.match(document.getElementById('calc-recalc').textContent, /결론 그대로/);
    document.getElementById('calc-excl-reset').click();
    assert.equal(s.benS.a.every((b) => b.checked), true);
    assert.equal(document.querySelector('.calc-excl'), null);
  });

  test('한쪽만 금액 등록 칸의 「이 4건을 빼고 다시 계산」 — 같은 상태를 공유한다', () => {
    const s = appState();
    run(s);
    document.getElementById('calc-iso-btn').click();
    const offs = s.benS.a.filter((b) => !b.checked).map((b) => b.benefit_cd).sort();
    assert.deepEqual(offs, ['club', 'discount', 'self_development', 'work_tools']);
    assert.match(document.querySelector('.calc-hl').textContent, /연 1,355만원 줄어듭니다/);
    assert.equal(document.getElementById('calc-iso-btn').getAttribute('aria-pressed'), 'true');
    assert.match(document.getElementById('calc-iso-btn').textContent, /다시 넣기/);
    const sw = document.getElementById('calc-sw-a-club');
    assert.equal(sw.getAttribute('aria-pressed'), 'true', '비교표 스위치도 같은 상태');
    document.getElementById('calc-iso-btn').click();
    assert.equal(s.benS.a.every((b) => b.checked), true);
  });

  test('비교표 필터 — 달라지는 것만(기본)은 같은 금액·둘 다 금액 미등록 행을 숨긴다', () => {
    const s = appState();
    run(s);
    const hidden = [...document.querySelectorAll('.calc-ct tbody tr.calc-hidden-row')];
    assert.ok(hidden.some((tr) => tr.getAttribute('data-same') === '1'));
    assert.ok(hidden.some((tr) => tr.getAttribute('data-sec') === '4'));
    document.getElementById('calc-ctf-all').click();
    assert.equal(document.querySelectorAll('.calc-ct tbody tr.calc-hidden-row').length, 0);
    assert.equal(s.ui.reportView.ctFilter, 'all', '다시 그려도 유지되게 상태에 남긴다');
  });

  test('법정 행 — 목록에는 「법정」 표시로 남고 비교(짝짓기·항목 수)에서 빠진다(SP-LEGAL-5)', () => {
    const s = appState();
    s.matched.a = normalizeCompany({ ...G.naver, comp_eng_nm: 'kt', comp_nm: 'KT', benefits: [...G.naver.benefits, { benefit_cd: 'parenting2', benefit_nm: '출산/육아 지원', benefit_ctgr_cd: 'family', qual_yn: true, amt_source: 'none', badge_cd: 'official' }] });
    // KT 의 법정 행은 (kt, parenting, 출산/육아 지원) — 코드도 맞춘다
    s.matched.a.benefits = s.matched.a.benefits.map((b) => (b.benefit_cd === 'parenting2' ? { ...b, benefit_cd: 'parenting' } : b)).filter((b, i, arr) => !(b.benefit_cd === 'parenting' && b.benefit_nm !== '출산/육아 지원' && arr.some((x) => x.benefit_cd === 'parenting' && x.benefit_nm === '출산/육아 지원')));
    fillBenefits(s, 'a');
    const r = run(s);
    assert.equal(r.pairs.legal.a.length, 1);
    const diffs = document.getElementById('calc-b-diffs');
    diffs.open = true;
    assert.match(diffs.textContent, /법으로 모든 회사에 정해진 제도만 적혀 있어 비교에서 뺀 항목: 법정 출산\/육아 지원\(KT\)/);
    assert.equal(r.axes.benefits.counts.a, G.naver.benefits.length - 1 + 0, '항목 수에서 빠진다(원래 parenting 을 법정 행이 대신)');
    assert.equal(s.benS.a.find((b) => b.benefit_cd === 'parenting').checked, true, 'App.state 는 건드리지 않는다(복사본에만 표시)');
  });
});

describe('RC-6 배포 간극 — 옛 셸 헤딩', () => {
  beforeEach(() => loadShell());
  test('옛 「비교 리포트」 헤딩을 만나면 목업의 제목·공식으로 바꾼다', () => {
    const h2 = document.querySelector('#view-report h2');
    h2.textContent = '비교 리포트';
    render(goldenEngineState());
    assert.match(h2.textContent, /^비교 결과 실효 총보상 = 연봉 \+ 복지 환산 가치 \+ 야근수당$/);
  });
});
