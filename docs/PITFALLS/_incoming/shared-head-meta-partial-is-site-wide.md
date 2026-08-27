# `_head_meta.html` 에 SEO 태그를 "한 페이지만" 추가하는 방법은 없다

`generator/templates/partials/_head_meta.html` 은 **회사·회사인덱스·조합·정책·404 가 전부
공유**한다(`base.html` 의 `{% block head %}` 가 무조건 include). 그래서 "404 에만 noindex 를
붙인다"는 작업이 물리적으로는 **전 페이지가 읽는 파일을 고치는 일**이다. 조건을 잘못 걸면
회사·조합·정책까지 `noindex` 가 붙고 — 검색 유입이 수익의 뼈대인 이 서비스에서는 —
사이트가 통째로 색인에서 빠진다. 되돌려도 재색인까지 시간이 걸리는 비대칭 사고다.

**규약: 옵트인으로만 넣어라.** 값을 넘긴 페이지에만 방출되고, 안 넘긴 페이지는 태그 자체가
안 나가야 한다. `base.html` 의 `page_type`(미선언 → 속성 미방출)과 같은 형태다.

```jinja
{% if robots is defined and robots %}<meta name="robots" content="{{ robots }}">
{% endif %}
```

기본값을 `noindex` 로 두거나 무조건 방출하는 순간 사고다.

## 테스트는 반드시 양방향으로

"404 에 noindex 가 있는가" 한 방향만 쓰면 **전역 오염을 못 잡는다** — 전 페이지에 붙어도
그 테스트는 초록이다. 반대 방향("콘텐츠 페이지에는 없는가")이 실제 가드다.

같은 이유로, **태그를 조건부로 바꿀 때는 없앤 쪽만이 아니라 남긴 쪽도 세라.** 404 의
canonical 을 지우려고 `{% if canonical %}` 를 걸면 "조건이 헐거우면 콘텐츠 페이지의
canonical 이 조용히 사라진다"는 새 실패 모드가 생긴다. `generator/tests/test_seo_meta.py`
의 `test_indexable_pages_keep_exactly_one_self_canonical` 이 그 자리를 막는다.

## 곁가지 둘

- `render.py` 는 `StrictUndefined` 다. **항상 넘기는 변수**(canonical)에는 `is defined` 를
  붙이지 마라 — 빠뜨렸을 때 조용한 공란 대신 렌더가 죽는 편이 맞다. 옵트인 변수(robots)에만
  `is defined and X` 를 쓴다.
- `trim_blocks`/`lstrip_blocks` 가 켜져 있어 조건부 태그는 앞 태그와 **한 줄에 붙어** 나온다.
  유효한 HTML 이고 무해하지만, 생성물 diff 를 눈으로 볼 때 놀라지 마라.
