// web/assets/js/marks.js — 행 표시(SP-MARK, 2026-10) 클라이언트 사본. `legal.js`(2026-09-23)를 대체한다.
//
// 정본은 `generator/data/row_marks.json`(판정)과 `generator/marks.py`(라벨 · 문구)다. 이 목록은 그 파일의
// (회사 영문명, 항목코드, 항목명, kind) 4튜플을 그대로 옮긴 것이고, `generator/tests/test_row_marks_client_copy.py` 가
// 둘이 갈리면 빌드를 깨뜨린다 — 정본을 고칠 때 여기도 같이 고쳐라(참조 번들에는 표식이 없어 SPA 가 스스로 알 길이 이것뿐이다).
//
// 범위 표시(집계 제외): legal 「법정」 · work_edu 「업무 교육」 — 행을 지우지 않는다. 목록에 표시를 달아 남기고 비교 ·
// 집계(짝짓기 · 항목 수 · 합계)에서만 뺀다. 판정을 3튜플로 하는 이유 — 같은 코드에 표시 행과 진짜 복지 행이 섞여 있다.
// 계보 표시(집계 포함): 「검색 요약」 — `badge_src_cd === 'ai_parse'`(근거 URL 없는 회사). 집계에서 빼지 않는다(2a).

export const ROW_MARKS = Object.freeze([
  ['kt', 'parenting', '출산/육아 지원', 'legal'],
  ['samsung_card', 'parenting', '육아휴직·모성보호제도', 'legal'],
  ['silicon2', 'parenting', '출산휴가/육아휴직', 'legal'],
  ['alteogen', 'edu_support', '신입사원 교육', 'work_edu'],
  ['isens', 'edu_support', '교육 프로그램', 'work_edu'],
  ['samsung_card', 'edu_support', 'Job master 양성과정', 'work_edu'],
]);

// 라벨 · 문구는 generator/marks.py KINDS 와 같은 글자다(대조 테스트가 막는다). 순서 = 화면 순서.
export const MARK = Object.freeze({
  legal: Object.freeze({
    label: '법정',
    title: '근로기준법 등이 모든 회사에 강제하는 제도입니다. 복지 항목 수에서 제외됩니다.',
    phrase: '법으로 모든 회사에 정해진 제도만 적힌 항목',
  }),
  work_edu: Object.freeze({
    label: '업무 교육',
    title: '회사가 업무를 맡기려고 여는 교육(신입 입문·직무 필수·승진자 리더십)만 적힌 항목입니다. 복지 항목 수에서 제외됩니다.',
    phrase: '회사가 업무를 맡기려고 여는 교육만 적힌 항목',
  }),
});

export const SUMMARY_SRC_CD = 'ai_parse';
export const SUMMARY = Object.freeze({
  label: '검색 요약',
  title: '회사 공식 원문을 찾지 못해 검색 AI 요약을 근거로 한 항목입니다. 복지 항목 수에는 셉니다.',
});

const KEYS = new Map(ROW_MARKS.map((r) => [r.slice(0, 3).join('\u0000'), r[3]]));

/** 이 복지 행의 표시 kind — `'legal' | 'work_edu' | null`. generator/marks.py `row_mark` 와 같은 판정. */
export function rowMark(compEngNm, b) {
  if (!b) return null;
  return KEYS.get([compEngNm || '', b.benefit_cd || '', b.benefit_nm || ''].join('\u0000')) || null;
}

/** 회사의 복지 목록에서 표시 행(법정 · 업무 교육)을 뺀 것 — generator/marks.py `countable` 과 같다. 검색 요약 행은 남는다. */
export function countable(company) {
  const eng = company && company.comp_eng_nm;
  return ((company && company.benefits) || []).filter((b) => !rowMark(eng, b));
}

/** 검색 요약 행인가(계보 표시 — 집계에는 든다). */
export function isSummary(b) { return !!b && b.badge_src_cd === SUMMARY_SRC_CD; }
