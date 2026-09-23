// web/assets/js/josa.js — 회사 이름 뒤 조사(은/는·이/가·을/를·와/과·로/으로)와 숫자 표기(2026-09-23, 이직 계산기).
// 순수 모듈(다른 앱 모듈 import 0). 계산기 문장은 회사 이름으로 부른다(「이직 후보」가 아니라 「카카오」) —
// 이름이 150개라 받침을 손으로 맞출 수 없다. 영문 이름은 **읽는 소리**로 판정한다(NAVER=네이버 → 는).

// 영문 약어는 글자 이름으로 읽는다 — 받침으로 끝나는 글자는 L(엘)·M(엠)·N(엔)·R(알)뿐이다.
const LETTER_FINAL = { L: 'ㄹ', M: 'ㅁ', N: 'ㄴ', R: 'ㄹ' };
// 낱자가 아니라 단어로 읽히는 이름(현재 등록 회사 실측).
const WORD_FINAL = { NAVER: '', ELECTRIC: 'ㄱ', OIL: 'ㄹ', ENT: '' };
const DIGIT_FINAL = ['ㅇ', 'ㄹ', '', 'ㅁ', '', '', 'ㄱ', 'ㄹ', 'ㄹ', '']; // 영·일·이·삼·사·오·육·칠·팔·구

/** 마지막 소리의 받침 — '' 이면 받침 없음, 'ㄹ' 은 로/으로 에서 받침 없음 취급. */
export function finalSound(word) {
  let w = String(word || '').trim();
  w = w.replace(/\s*\([^()]*\)\s*$/, ''); // 「엔씨소프트(NC)」 → 괄호 밖 이름을 따른다
  w = w.replace(/[^0-9A-Za-z가-힣]+$/, '');
  if (!w) return '';
  const ch = w[w.length - 1];
  const code = ch.charCodeAt(0);
  if (code >= 0xac00 && code <= 0xd7a3) {
    const jong = (code - 0xac00) % 28;
    if (jong === 0) return '';
    return jong === 8 ? 'ㄹ' : 'ㅇ'; // 받침의 종류는 로/으로 에서 ㄹ 만 따로 본다
  }
  if (/[0-9]/.test(ch)) return DIGIT_FINAL[Number(ch)];
  const m = w.match(/[A-Za-z]+$/);
  if (m) {
    const token = m[0].toUpperCase();
    if (Object.prototype.hasOwnProperty.call(WORD_FINAL, token)) return WORD_FINAL[token];
    return LETTER_FINAL[token[token.length - 1]] || '';
  }
  return '';
}

const PAIRS = { '은/는': ['은', '는'], '이/가': ['이', '가'], '을/를': ['을', '를'], '와/과': ['과', '와'], '로/으로': ['으로', '로'] };

/** 조사만 — josa('NAVER', '은/는') === '는'. */
export function josa(word, pair) {
  const p = PAIRS[pair];
  if (!p) return '';
  const f = finalSound(word);
  if (pair === '로/으로') return f && f !== 'ㄹ' ? p[0] : p[1];
  return f ? p[0] : p[1];
}

/** 이름 + 조사 — withJosa('카카오', '이/가') === '카카오가'. */
export function withJosa(word, pair) { return String(word || '') + josa(word, pair); }

// ── 숫자 — 음수는 목업처럼 유니코드 빼기(−), 천 단위 쉼표 ────────────────────
const MINUS = '−';

/** 정수 표기(반올림, 부호는 음수만). */
export function fmt(n) {
  const v = Math.round(Number(n) || 0);
  return (v < 0 ? MINUS : '') + Math.abs(v).toLocaleString('ko-KR');
}

/** 부호 붙인 정수(+900 / −2,211 / 0). */
export function fmtSigned(n) {
  const v = Math.round(Number(n) || 0);
  return (v > 0 ? '+' : '') + fmt(v);
}

/** 비율 → 부호 붙인 퍼센트(소수 digits 자리). 0.152 → '+15.2%'. */
export function fmtPct(ratio, digits = 1) {
  if (ratio == null || !Number.isFinite(ratio)) return '';
  const v = Number((ratio * 100).toFixed(digits));
  return (v > 0 ? '+' : v < 0 ? MINUS : '') + Math.abs(v).toFixed(digits) + '%';
}
