// web/assets/js/categories.js — 복지 카테고리 9종의 순서·라벨.
//
// **정본은 `generator/pages/company.py::CATEGORY_ORDER` / `CATEGORY_LABEL`** 이고 이 파일은 그
// 미러다(번들이 카테고리 라벨을 싣지 않는다 — 회사 페이지·히트맵과 같은 이유). 드리프트는
// `find.test.js` 가 company.py 를 읽어 문자열로 잡는다.
//
// 따로 뺀 이유는 하나다: 「복지검색」과 「복지 비교」가 같은 순서를 써야 하는데, 비교 화면이 이
// 두 상수 때문에 `find.js`(약 950줄) 전체를 받아 갈 이유는 없다. `find.js` 는 같은 이름을
// 재수출하므로 그쪽 호출부·테스트는 손대지 않았다.
export const CATEGORY_ORDER = [
  'compensation', 'flexibility', 'work_env', 'time_off', 'health', 'family', 'growth', 'leisure', 'perks',
];
export const CATEGORY_LABEL = {
  compensation: '보상', flexibility: '유연성', work_env: '근무환경', time_off: '휴가', health: '건강',
  family: '가족', growth: '성장', leisure: '여가', perks: '복리후생',
};
