// web/assets/js/legal.js — 법정 행(SP-LEGAL-5) 클라이언트 사본 · 이직 계산기 전용(2026-09-23).
//
// 정본은 `generator/data/legal_rows.json` 이다. 이 목록은 그 파일의 (회사 영문명, 항목코드, 항목명) 3튜플을
// 그대로 옮긴 것이고, `generator/tests/test_legal_rows_client_copy.py` 가 둘이 갈리면 빌드를 깨뜨린다 —
// 정본을 고칠 때 여기도 같이 고쳐라(참조 번들에는 법정 표식이 없어 계산기가 스스로 알 길이 이것뿐이다).
//
// 규칙은 생성기와 같다: 행을 지우지 않는다. 계산기는 「법정」 배지를 달아 목록에 남기고, 비교·집계
// (짝짓기·항목 수·합계)에서만 뺀다. 판정을 3튜플로 하는 이유 — 같은 코드(parenting·leave_general)에
// 법정 행과 진짜 복지 행이 섞여 있다(코드만 보면 멀쩡한 복지가 빠진다).

export const LEGAL_ROWS = Object.freeze([
  ['classys', 'parenting', '산전후휴가/육아휴직'],
  ['eo_technics', 'parenting', '출산/육아 지원'],
  ['hanwha_systems', 'parenting', '출산휴가/아빠휴가'],
  ['hanwha_aerospace', 'parenting', '아빠휴가'],
  ['hyundai_steel', 'parenting', '출산/육아'],
  ['kakao_bank', 'parenting', '임신/출산/육아 제도'],
  ['kt', 'parenting', '출산/육아 지원'],
  ['nepes', 'birthday_leave', '생일 연차 휴식'],
  ['nepes', 'leave_general', '연차촉진제도'],
  ['pharma_research', 'refresh_leave', 'Refresh 휴가'],
  ['rainbow_robotics', 'parenting', '육아휴직'],
  ['samsung_card', 'parenting', '육아휴직·모성보호제도'],
  ['silicon2', 'parenting', '출산휴가/육아휴직'],
]);

const KEYS = new Set(LEGAL_ROWS.map((r) => r.join('\u0000')));

/** 이 복지 행이 「법정 제도만」인가 — generator/legal.py `is_legal_row` 와 같은 판정. */
export function isLegalRow(compEngNm, benefitCd, benefitNm) {
  return KEYS.has([compEngNm || '', benefitCd || '', benefitNm || ''].join('\u0000'));
}
