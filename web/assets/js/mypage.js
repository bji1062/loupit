// web/assets/js/mypage.js — SC14 마이페이지 로직(SP-FE). 내 정보·닉네임 변경·재직 인증 목록·
// 로그아웃·탈퇴. 세션 필요 — 미로그인(401) 시 로그인 유도. 사용자 데이터는 textContent로만
// 삽입(XSS 방지). api.js의 credentialed 헬퍼만 쓴다.
//
// 순수 로직(닉네임 검증·메시지·날짜·항목 렌더)은 export 하고, DOM 배선은 `initMypage()` 안에서만
// 한다 — 화면 루트(#profile)가 있을 때만 초기화하므로 node:test import 시 부작용 0.

import { getMe, updateNickname, logout, withdraw, ApiError } from './api.js';

// 백엔드 NicknameUpdateIn과 동일한 형식/금칙어(클라 사전 확인 — 서버가 최종 판정 409/422).
const NICK_RE = /^[0-9A-Za-z가-힣_\- ]{2,20}$/;
const BANNED = ['관리자', '운영자', '운영진', 'admin', 'administrator', 'loupit', '루핏'];

// ── 순수: 닉네임 사전 검증 — 통과 시 null, 아니면 오류 메시지 ──
export function validateNickname(nick) {
  const v = String(nick == null ? '' : nick).trim();
  if (!NICK_RE.test(v)) return '2~20자의 한글·영문·숫자·_- 만 가능해요.';
  if (BANNED.some((b) => v.toLowerCase().replace(/\s/g, '').includes(b))) return '사용할 수 없는 닉네임이에요.';
  return null;
}

// ── 순수: 닉네임 변경 실패 메시지(409 중복·422 형식/금칙어) ──
export function nickErrorMessage(err) {
  const s = err instanceof ApiError ? err.status : 0;
  if (s === 409) return '이미 사용 중인 닉네임이에요.';
  if (s === 422) return '사용할 수 없는 닉네임이에요(형식·금칙어).';
  return '변경에 실패했어요. 잠시 후 다시 시도해주세요.';
}

// ── 순수: ISO → 'YYYY-MM-DD' ──
export function fmtDate(iso) { return String(iso == null ? '' : iso).slice(0, 10); }

// ── 순수: 계정 상태 표시 라벨 ──
export function statusLabel(status) { return status === 'active' ? '정상' : (status || '정상'); }

// ── 순수: 재직 인증 1건 → <li>(전부 textContent — XSS 안전). document 주입. ──
export function renderVrfItem(doc, v) {
  const li = doc.createElement('li');
  const c = doc.createElement('span');
  c.className = 'vrf-comp';
  c.textContent = v.comp_nm || ('회사 ' + v.comp_id); // textContent = XSS 안전
  const e = doc.createElement('span');
  e.className = 'vrf-exp';
  e.textContent = v.expires_dtm ? ('만료 ' + fmtDate(v.expires_dtm)) : '무기한';
  const edit = doc.createElement('a'); // 재직 인증한 회사 → 복지 편집 진입
  edit.className = 'auth-link'; edit.href = '/edit?comp=' + encodeURIComponent(v.comp_id);
  edit.textContent = '복지 편집 →';
  li.append(c, e, edit);
  return li;
}

// ── 이하 DOM 배선(브라우저 전용) ──
export function initMypage() {
  const $ = (id) => document.getElementById(id);

  function setErr(el, msg) { el.textContent = msg; el.hidden = false; }
  function clr(...els) { for (const el of els) { el.hidden = true; el.textContent = ''; } }

  function renderVrf(list) {
    const ul = $('vrf-list'), empty = $('vrf-empty');
    ul.textContent = '';
    if (!list || !list.length) { empty.hidden = false; return; }
    empty.hidden = true;
    for (const v of list) ul.append(renderVrfItem(document, v));
  }

  function render(data) {
    $('nickname').textContent = data.nickname || '직장인';
    $('status').textContent = statusLabel(data.status);
    renderVrf(data.verifications);
    for (const id of ['profile', 'vrf-card', 'account-card']) $(id).hidden = false;
    $('need-login').hidden = true;
  }

  // ── 닉네임 변경 ──
  $('edit-nick').addEventListener('click', () => {
    clr($('nick-ok'), $('nick-err'));
    $('nick-input').value = $('nickname').textContent;
    $('nick-edit').hidden = false;
    $('nick-input').focus();
  });
  $('cancel-nick').addEventListener('click', () => { $('nick-edit').hidden = true; clr($('nick-err')); });

  $('save-nick').addEventListener('click', async () => {
    clr($('nick-ok'), $('nick-err'));
    const nick = $('nick-input').value.trim();
    const invalid = validateNickname(nick);
    if (invalid) { setErr($('nick-err'), invalid); return; }
    const btn = $('save-nick'); btn.disabled = true;
    try {
      const { data } = await updateNickname(nick);
      $('nickname').textContent = data.nickname;
      $('nick-edit').hidden = true;
      // 문구를 매번 넣는다 — clr()이 textContent 를 비우므로 정적 HTML 문구에 기대면 빈 상자만 뜬다.
      $('nick-ok').textContent = '닉네임을 변경했어요.';
      $('nick-ok').hidden = false;
    } catch (err) {
      setErr($('nick-err'), nickErrorMessage(err));
    } finally { btn.disabled = false; }
  });

  // ── 로그아웃 ──
  $('logout-btn').addEventListener('click', async () => {
    try { await logout(); } catch { /* 이미 만료여도 진행 */ }
    location.href = '/login';
  });

  // ── 탈퇴 ──
  $('withdraw-btn').addEventListener('click', async () => {
    clr($('account-err'));
    if (!confirm('정말 탈퇴하시겠어요?\n로그인 이메일은 삭제되고, 편집 이력의 닉네임은 남습니다.')) return;
    const btn = $('withdraw-btn'); btn.disabled = true;
    try {
      await withdraw();
      alert('탈퇴가 완료됐어요. 이용해 주셔서 감사합니다.');
      location.href = '/';
    } catch {
      setErr($('account-err'), '탈퇴 처리에 실패했어요. 잠시 후 다시 시도해주세요.');
      btn.disabled = false;
    }
  });

  // 진입: 세션 확인 → 내 정보 렌더 or 로그인 유도
  (async () => {
    try {
      const { data } = await getMe();
      render(data);
    } catch {
      $('need-login').hidden = false; // 401 등
    }
  })();
}

// 브라우저에서 마이페이지 루트가 있을 때만 초기화(node:test 로 순수 함수만 import 시 부작용 0).
if (typeof document !== 'undefined' && typeof document.getElementById === 'function'
    && document.getElementById('profile')) {
  initMypage();
}
