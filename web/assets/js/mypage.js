// web/assets/js/mypage.js — SC14 마이페이지 로직(SP-FE). 내 정보·닉네임 변경·재직 인증 목록·
// 로그아웃·탈퇴. 세션 필요 — 미로그인(401) 시 로그인 유도. 사용자 데이터는 textContent로만
// 삽입(XSS 방지). api.js의 credentialed 헬퍼만 쓴다.

import { getMe, updateNickname, logout, withdraw, ApiError } from './api.js';

const $ = (id) => document.getElementById(id);

// 백엔드 NicknameUpdateIn과 동일한 형식/금칙어(클라 사전 확인 — 서버가 최종 판정 409/422).
const NICK_RE = /^[0-9A-Za-z가-힣_\- ]{2,20}$/;
const BANNED = ['관리자', '운영자', '운영진', 'admin', 'administrator', 'loupit', '루핏'];

function fmtDate(iso) { return String(iso).slice(0, 10); } // 'YYYY-MM-DD'
function setErr(el, msg) { el.textContent = msg; el.hidden = false; }
function clr(...els) { for (const el of els) { el.hidden = true; el.textContent = ''; } }

function renderVrf(list) {
  const ul = $('vrf-list'), empty = $('vrf-empty');
  ul.textContent = '';
  if (!list || !list.length) { empty.hidden = false; return; }
  empty.hidden = true;
  for (const v of list) {
    const li = document.createElement('li');
    const c = document.createElement('span');
    c.className = 'vrf-comp';
    c.textContent = v.comp_nm || ('회사 ' + v.comp_id); // textContent = XSS 안전
    const e = document.createElement('span');
    e.className = 'vrf-exp';
    e.textContent = v.expires_dtm ? ('만료 ' + fmtDate(v.expires_dtm)) : '무기한';
    li.append(c, e);
    ul.append(li);
  }
}

function render(data) {
  $('nickname').textContent = data.nickname || '직장인';
  $('status').textContent = data.status === 'active' ? '정상' : (data.status || '정상');
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
  if (!NICK_RE.test(nick)) { setErr($('nick-err'), '2~20자의 한글·영문·숫자·_- 만 가능해요.'); return; }
  if (BANNED.some((b) => nick.toLowerCase().replace(/\s/g, '').includes(b))) {
    setErr($('nick-err'), '사용할 수 없는 닉네임이에요.'); return;
  }
  const btn = $('save-nick'); btn.disabled = true;
  try {
    const { data } = await updateNickname(nick);
    $('nickname').textContent = data.nickname;
    $('nick-edit').hidden = true;
    $('nick-ok').hidden = false;
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) setErr($('nick-err'), '이미 사용 중인 닉네임이에요.');
    else if (err instanceof ApiError && err.status === 422) setErr($('nick-err'), '사용할 수 없는 닉네임이에요(형식·금칙어).');
    else setErr($('nick-err'), '변경에 실패했어요. 잠시 후 다시 시도해주세요.');
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
