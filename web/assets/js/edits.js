// web/assets/js/edits.js — SC14 복지 편집 이력(공개·익명, FR-110). 나무위키식 before→after 이력.
// 로그인 불필요(익명 GET). 편집자는 닉네임만 노출(이메일·ID 미노출). 회사는 ?comp=<id> 로 지정,
// 없으면 회사 검색으로 이동. 모든 사용자 데이터(닉네임·편집 사유·복지명·비고)는 textContent 로만
// 삽입한다(XSS 안전 — 편집 사유는 서버가 데이터로 그대로 반환하므로 표시 계층 이스케이프가 방어선).

import { getEdits, getCompany, searchCompanies, ApiError } from './api.js';

export const EDIT_TYPE_LABELS = { create: '등록', update: '수정', delete: '삭제' };
// 9카테고리 표시 라벨 — company.js·report.js·edit.js 와 동일 어휘.
export const CATEGORY_LABELS = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가',
  health: '건강', family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};
const PAGE_LIMIT = 100; // 커서(EDIT_LOG_ID) 미노출 계약이라 최신 N건만(그 이상은 안내).

// ── 순수: 금액 표시 ──
function fmtAmt(v) {
  if (v == null || v === '') return '미기재';
  return Number(v).toLocaleString('ko-KR') + '만원';
}

// 스냅샷 필드 → 표시 규격(키, 라벨, 포맷터).
const DIFF_SPEC = [
  ['benefit_nm', '복지명', (v) => (v == null || v === '' ? '—' : String(v))],
  ['benefit_ctgr_cd', '카테고리', (v) => CATEGORY_LABELS[v] || v || '—'],
  ['benefit_amt', '금액', (v) => fmtAmt(v)],
  ['qual_yn', '정성 여부', (v) => (v ? '정성' : '정량')],
  ['note_ctnt', '비고', (v) => (v == null || v === '' ? '—' : String(v))],
];

// create/delete 에서 "값이 있는 필드"만 노출할지 판정(불필요한 기본값 노이즈 억제).
function meaningful(key, v) {
  if (v == null || v === '') return false;
  if (key === 'qual_yn') return v === true; // 정량(false)은 create/delete 에서 생략
  return true;
}

// ── 순수: before→after 필드 차이. update=변경 필드만, create=신규 값, delete=삭제 전 값 ──
// 반환: [{ label, from, to }]. from==null → 추가(create), to==null → 제거(delete).
export function diffFields(before, after) {
  const b = before || {}, a = after || {};
  const rows = [];
  for (const [key, label, fmt] of DIFF_SPEC) {
    if (before && after) {
      if (String(b[key]) !== String(a[key])) rows.push({ label, from: fmt(b[key]), to: fmt(a[key]) });
    } else if (after) {
      if (meaningful(key, a[key])) rows.push({ label, from: null, to: fmt(a[key]) });
    } else if (before) {
      if (meaningful(key, b[key])) rows.push({ label, from: fmt(b[key]), to: null });
    }
  }
  return rows;
}

// ── 순수: dtm(ISO, 서버 UTC) → 'YYYY-MM-DD HH:MM' ──
export function fmtDtm(iso) {
  const s = String(iso || '');
  const m = /^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2})/.exec(s);
  return m ? `${m[1]} ${m[2]}` : s.slice(0, 16);
}

// ── 순수: 한 이력 항목을 <li> 로 렌더(전부 textContent — XSS 안전). document 주입 필요. ──
export function renderEntry(doc, item) {
  const li = doc.createElement('li'); li.className = 'log-entry';
  const head = doc.createElement('div'); head.className = 'log-head';
  const nick = doc.createElement('span'); nick.className = 'log-nick'; nick.textContent = item.nickname || '(탈퇴)';
  const type = doc.createElement('span');
  const t = item.edit_type;
  type.className = 'log-type log-type--' + (EDIT_TYPE_LABELS[t] ? t : 'update');
  type.textContent = EDIT_TYPE_LABELS[t] || t;
  const dtm = doc.createElement('span'); dtm.className = 'log-dtm'; dtm.textContent = fmtDtm(item.dtm);
  head.append(nick, type, dtm);
  li.append(head);

  if (item.edit_note) {
    const note = doc.createElement('p'); note.className = 'log-note';
    note.textContent = '“' + item.edit_note + '”'; // textContent = 스크립트 미실행(AH3)
    li.append(note);
  }

  const rows = diffFields(item.before, item.after);
  if (rows.length) {
    const ul = doc.createElement('ul'); ul.className = 'log-diff';
    for (const r of rows) {
      const row = doc.createElement('li');
      const dl = doc.createElement('span'); dl.className = 'dl'; dl.textContent = r.label;
      row.append(dl);
      if (r.from != null && r.to != null) {
        const from = doc.createElement('span'); from.className = 'dv from'; from.textContent = r.from;
        const arw = doc.createElement('span'); arw.className = 'arw'; arw.textContent = '→';
        const to = doc.createElement('span'); to.className = 'dv to'; to.textContent = r.to;
        row.append(from, arw, to);
      } else if (r.from == null) {
        const to = doc.createElement('span'); to.className = 'dv to'; to.textContent = r.to;
        row.append(to);
      } else {
        const from = doc.createElement('span'); from.className = 'dv from strike'; from.textContent = r.from;
        row.append(from);
      }
      ul.append(row);
    }
    li.append(ul);
  }
  return li;
}

// ── 이하 DOM 배선(브라우저 전용) ──
export function initEditsPage() {
  const $ = (id) => document.getElementById(id);

  const compParam = () => {
    const m = /[?&]comp=(\d+)/.exec(location.search);
    return m ? parseInt(m[1], 10) : null;
  };

  function fail(msg) { $('edits-status').textContent = msg; $('edits-status').hidden = false; }

  async function loadHistory(compId) {
    // 이력을 먼저 확보(회사 유효성 겸용) — 404·오류면 제목·링크를 노출하지 않는다(모순 화면 방지).
    let items;
    try {
      items = await getEdits(compId, PAGE_LIMIT);
    } catch (err) {
      if (err instanceof ApiError && err.status === 404) { fail('그 회사를 찾을 수 없어요. 주소를 확인해주세요.'); return; }
      fail('편집 이력을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    }
    // 성공 후에만 제목·회사 링크 노출. 회사명은 공개 상세에서(실패해도 폴백 유지).
    let compNm = '회사 #' + compId;
    try { const c = await getCompany(compId); if (c && c.comp_nm) compNm = c.comp_nm; } catch { /* 폴백 유지 */ }
    $('comp-title').textContent = compNm + ' 편집 이력';
    $('comp-title').hidden = false;
    const backLink = $('company-link');
    backLink.href = '/company/' + encodeURIComponent(compId); // 공개 상세로(있으면)
    backLink.hidden = false;
    const listEl = $('edit-log');
    listEl.textContent = '';
    if (!items.length) { $('edits-empty').hidden = false; return; }
    for (const it of items) listEl.append(renderEntry(document, it));
    listEl.hidden = false;
    if (items.length >= PAGE_LIMIT) { $('edits-more').hidden = false; }
  }

  // ?comp 없을 때: 회사 검색으로 이력 페이지 이동.
  function setupPicker() {
    $('pick-card').hidden = false;
    let seq = 0, timer = null;
    $('pick-search').addEventListener('input', () => {
      clearTimeout(timer);
      const q = $('pick-search').value.trim();
      const results = $('pick-results');
      if (!q) { results.hidden = true; results.textContent = ''; return; }
      timer = setTimeout(async () => {
        const s = ++seq;
        try {
          const rows = await searchCompanies(q);
          if (s !== seq) return;
          results.textContent = '';
          if (!rows || !rows.length) { results.hidden = true; return; }
          for (const r of rows) {
            const li = document.createElement('li'); li.tabIndex = 0; li.setAttribute('role', 'option');
            li.textContent = r.comp_nm;
            const go = () => { location.href = '/edits?comp=' + encodeURIComponent(r.comp_id); };
            li.addEventListener('click', go);
            li.addEventListener('keydown', (e) => { if (e.key === 'Enter') go(); });
            results.append(li);
          }
          results.hidden = false;
        } catch { /* 조용히 */ }
      }, 250);
    });
  }

  const comp = compParam();
  if (comp) loadHistory(comp); else setupPicker();
}

if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('edits-main')) {
  initEditsPage();
}
