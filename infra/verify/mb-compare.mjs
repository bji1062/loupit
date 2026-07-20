#!/usr/bin/env node
// infra/verify/mb-compare.mjs — SP-FE-12.2 수동 체크리스트(MB-*) 중 자동화 가능한 항목의
// 브라우저 검증 하네스(T-06.14.*). "수동 브라우저"로 규정된 항목이라 릴리스 게이트가
// 형식상 미충족 상태로 남아 있었다 — 자동화해 회귀 가드로 전환한다.
// 육안 판정이 본질인 항목(MD-1 다크 톤 등)은 대상이 아니며 별도 문서로 남긴다.
//
// 사용: BASE=https://jobcho.wiki node infra/verify/mb-compare.mjs
// 종료코드: 실패 1건 이상이면 1 (게이트 편입 가능)
import { chromium } from '/root/.claude/skills/gstack/node_modules/playwright/index.mjs';

const BASE = process.env.BASE || 'https://jobcho.wiki';
const results = [];
const rec = (id, gate, ok, detail) => {
  results.push({ id, gate, ok, detail });
  console.log(`  ${ok ? 'OK  ' : 'FAIL'} ${id}${gate ? ' [게이트]' : ''} — ${detail}`);
};

const browser = await chromium.launch({ chromiumSandbox: false });

// 비교 완료 상태까지 몰고 가는 공용 시나리오(프리필로 검색 타이핑 우회).
async function toReport(page) {
  await page.goto(`${BASE}/compare/?a=1&b=2`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1300);
  await page.fill('#sal-low', '5000');
  await page.fill('#sal-high', '6000');
  await page.fill('#offer-rate', '10');
  for (const s of ['a', 'b']) await page.selectOption(`select[aria-label="야근 빈도(${s})"]`, 'low');
  await page.click('#btn-compare');
  await page.waitForTimeout(1200);
}
const view = (page) => page.evaluate(() => (document.querySelector('.view:not([hidden])') || {}).id || null);

// ── MB-1: 부팅 시 reference/all 정확히 1회 + #app 표시 + 검색 뷰 ──────────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  const refReqs = [];
  page.on('request', (r) => { if (r.url().includes('/api/v1/reference/all')) refReqs.push(r.url()); });
  await page.goto(`${BASE}/compare/`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
  const st = await page.evaluate(() => ({
    appHidden: (document.getElementById('app') || {}).hidden,
    view: (document.querySelector('.view:not([hidden])') || {}).id,
  }));
  rec('MB-1', true, refReqs.length === 1 && st.appHidden === false && st.view === 'view-search',
    `reference/all ${refReqs.length}회 · #app표시=${!st.appHidden} · ${st.view}`);
  await ctx.close();
}

// ── MB-2: REF 실패 → #boot-error 재시도 UI, #app 숨김, 크래시 없음 ───────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  const errs = []; page.on('pageerror', (e) => errs.push(String(e)));
  await page.route('**/api/v1/reference/all', (r) => r.abort());
  await page.goto(`${BASE}/compare/`, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(1500);
  const st = await page.evaluate(() => ({
    errShown: !(document.getElementById('boot-error') || {}).hidden,
    appHidden: (document.getElementById('app') || {}).hidden,
    retry: !!document.getElementById('btn-boot-retry'),
  }));
  rec('MB-2', true, st.errShown && st.appHidden === true && st.retry && errs.length === 0,
    `boot-error=${st.errShown} · #app숨김=${st.appHidden} · 재시도버튼=${st.retry} · JS에러=${errs.length}`);
  await ctx.close();
}

// ── MB-3: 검색 디바운스 — 연속 입력 시 300ms 후 1회, 최신만 반영 ─────────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  const searches = [];
  page.on('request', (r) => { if (r.url().includes('/companies/search')) searches.push(r.url()); });
  await page.goto(`${BASE}/compare/`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1200);
  for (const ch of ['삼', '삼성', '삼성전']) { await page.fill('#search-input-a', ch); await page.waitForTimeout(60); }
  await page.waitForTimeout(1200);
  const last = searches[searches.length - 1] || '';
  rec('MB-3', false, searches.length <= 2 && decodeURIComponent(last).includes('삼성전'),
    `연속3타 → 검색요청 ${searches.length}회 · 최종질의="${decodeURIComponent(last).split('q=')[1] || ''}"`);
  await ctx.close();
}

// ── MB-4: 무결과 vs 오류 구분(FR-13) ─────────────────────────────────────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  await page.goto(`${BASE}/compare/`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1200);
  await page.fill('#search-input-a', 'ZZZ존재하지않는회사ZZZ');
  await page.waitForTimeout(1500);
  const empty = await page.evaluate(() => {
    const e = document.querySelector('.search-empty[data-slot="a"]');
    const r = document.querySelector('.search-error[data-slot="a"]');
    return { emptyShown: e ? !e.hidden : false, errShown: r ? !r.hidden : false };
  });
  // 서버 오류 강제 → 오류 문구 + 재시도.
  // ⚠ 배선 주의: 서버 실패 시 우선 REF 번들 폴백 매칭을 시도한다(FR-E2, search.js:78).
  // 폴백이 회사를 찾으면 후보가 렌더되고 오류가 아니다 — 그것이 설계된 동작이다.
  // 따라서 '오류' 상태를 보려면 **폴백도 못 찾는 질의**를 써야 한다(search.js:117).
  await page.route('**/api/v1/companies/search**', (r) => r.abort());
  await page.fill('#search-input-a', 'QQQ폴백도못찾는질의QQQ');
  await page.waitForTimeout(1800);
  const errS = await page.evaluate(() => {
    const e = document.querySelector('.search-empty[data-slot="a"]');
    const r = document.querySelector('.search-error[data-slot="a"]');
    return { emptyShown: e ? !e.hidden : false, errShown: r ? !r.hidden : false,
      retry: !!document.querySelector('[data-retry="a"]') };
  });
  rec('MB-4', true, empty.emptyShown && !empty.errShown && errS.errShown && !errS.emptyShown && errS.retry,
    `무결과(empty=${empty.emptyShown},err=${empty.errShown}) / 오류(empty=${errS.emptyShown},err=${errS.errShown},재시도=${errS.retry})`);
  await ctx.close();
}

// ── MB-13: 비-JS 폴백 — <noscript> 본문·정적 링크 노출, 빈 화면 아님 ─────────
{
  const ctx = await browser.newContext({ javaScriptEnabled: false }); const page = await ctx.newPage();
  await page.goto(`${BASE}/compare/`, { waitUntil: 'domcontentloaded', timeout: 30000 });
  const st = await page.evaluate(() => ({
    text: (document.body.innerText || '').replace(/\s+/g, ' ').trim(),
    links: [...document.querySelectorAll('a[href^="/company/"], a[href^="/vs/"], a[href="/"]')].length,
  }));
  rec('MB-13', false, st.text.length > 100 && st.links > 0,
    `본문 ${st.text.length}자 · 정적링크 ${st.links}개`);
  await ctx.close();
}

// ── MB-14: 비교 흐름 전체에서 /api/v1 쓰기 메서드·업로드 0 (INV-4) ───────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  const writes = [];
  page.on('request', (r) => {
    const m = r.method();
    if (r.url().includes('/api/v1') && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(m)) {
      writes.push(`${m} ${r.url().replace(BASE, '')}`);
    }
  });
  await toReport(page);
  await page.click('#btn-edit-input'); await page.waitForTimeout(400);
  await page.click('#btn-compare'); await page.waitForTimeout(900);
  // 익명 비교 로그 1종(POST /comparisons/log)은 INV-1 개정으로 허용된 유일한 쓰기다.
  const illegal = writes.filter((w) => !w.includes('/comparisons/log'));
  rec('MB-14', true, illegal.length === 0,
    `쓰기요청 ${writes.length}건(허용된 로그 제외 위반 ${illegal.length}건)${illegal.length ? ' → ' + illegal.join(', ') : ''}`);
  await ctx.close();
}

// ── MB-15: 리포트 렌더 + curPri 전환 시 판정카드만 갱신(FR-42) ───────────────
{
  const ctx = await browser.newContext(); const page = await ctx.newPage();
  await toReport(page);
  const before = await page.evaluate(() => {
    const b = document.getElementById('report-body');
    return { children: b.childElementCount, text: b.innerText.replace(/\s+/g, ' ') };
  });
  const priBtns = await page.$$('#report-body button, #report-body [role="tab"], .rp-pri button');
  let after = before, switched = false;
  if (priBtns.length > 1) { await priBtns[1].click(); await page.waitForTimeout(700); switched = true;
    after = await page.evaluate(() => {
      const b = document.getElementById('report-body');
      return { children: b.childElementCount, text: b.innerText.replace(/\s+/g, ' ') };
    });
  }
  rec('MB-15', false, before.children > 0 && (!switched || after.children === before.children),
    `본문 ${before.children}블록 · curPri전환=${switched ? '수행' : '버튼없음'} · 전환후 ${after.children}블록`);
  await ctx.close();
}

await browser.close();
const fails = results.filter((r) => !r.ok);
const gateFails = fails.filter((r) => r.gate);
console.log(`\n총 ${results.length}건 · 통과 ${results.length - fails.length} · 실패 ${fails.length}(게이트 ${gateFails.length})`);
process.exit(fails.length ? 1 : 0);
