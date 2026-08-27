# 세션 기록 — 2026-08-26 · 레인 C(생성기/검색노출) · 404 noindex

브랜치 `lane/seo-404-noindex`. `docs/HANDOFF-2026-07-30.md` §5-a 의 미해소분
("404 페이지에 noindex 가 없고 자기 canonical 이 있다. 색인 대상이 될 수 있다")을 닫는다.

## 한 일

404 를 색인 대상에서 뺐다. **셋이 한 묶음**이라 하나만 해서는 나머지가 그 신호를 되돌린다.

| # | 조치 | 어디 |
|---|---|---|
| 1 | `<meta name="robots" content="noindex, follow">` 방출 | `pages/policy.py::_render_404` → `partials/_head_meta.html` |
| 2 | **자기 canonical 제거**(`canonical=None`) | 같은 곳 |
| 3 | `in_sitemap=False` | 이미 그랬음 — 확인만 하고 테스트로 못박음 |

`follow` 는 남겼다 — 크롤러가 오류 페이지의 홈·비교 링크로 빠져나가는 편이 낫다(관례).

**자기 canonical 은 왜 빼는가.** `/404` 는 서빙되는 라우트가 아니라 nginx `error_page`
본문이다. 즉 그 URL 자체가 404 를 반환한다. 404 를 가리키는 canonical 은 (a) 죽은 링크이고
— 2026-07-30 링크 전수 감사가 잡은 **내부 404 1건이 정확히 이것**이다 — (b) noindex 와
충돌하는 신호다. 둘 다 없애는 게 맞다.

`og:url` 은 **남겼다**. 색인 지시가 아니라 공유 카드용 메타이고, `infra/verify/link-audit.py`
의 `ATTR_RE` 는 `href|src|action` 만 수집하므로 감사 대상도 아니다(`content=` 속성).
즉 감사의 잔여 1건은 canonical 제거만으로 0 이 된다.

## 어떻게 검증했나 — 양방향

이 대역의 **유일한 실질 위험은 전역 오염**이다. `_head_meta.html` 은 전 페이지가 공유하는
partial 이라, 거기 붙인 noindex 가 회사·조합·정책까지 번지면 검색 유입이 통째로 사라진다.
그래서 TDD 로 **두 방향을 다** 세웠다(`generator/tests/test_seo_meta.py`, +6):

- `test_404_page_has_noindex_robots_meta` — 404 에 robots 메타 **정확히 1개**, `noindex` 포함
- `test_404_page_has_no_self_canonical` — 404 에 canonical **0개**
- `test_404_page_is_excluded_from_sitemap` — `in_sitemap is False`
- `test_content_pages_have_no_robots_meta` — 회사·회사인덱스·조합·정책 전 페이지에 robots 메타 0
- `test_content_pages_never_contain_noindex` — `noindex` **문자열** 자체가 콘텐츠 HTML 에 부재(태그 형태 무관)
- `test_indexable_pages_keep_exactly_one_self_canonical` — 색인 대상 전 페이지가 자기 URL canonical 을 **여전히 1개** 유지

마지막 것이 핵심 가드다. canonical 을 조건부로 바꾸는 순간 "조건이 헐거우면 콘텐츠
페이지의 canonical 이 조용히 사라진다"는 새 실패 모드가 생긴다 — 조합 A-B/B-A 중복 귀속이
거기 걸려 있어서 즉시 색인 문제가 된다. 그래서 없앤 쪽(404)만이 아니라 **남긴 쪽도** 센다.

RED 확인: 구현 전 6개 중 2개(404 robots·404 canonical)가 실패하고 나머지 4개(가드)는
통과했다 — 가드는 처음부터 끝까지 초록이어야 맞다. 구현 후 전부 통과.

`_all_indexable_pages` 는 `test_links._build_all_pages` 와 같이 프로덕션 배선
(`combo_pairs` 전달)을 그대로 쓴다. 안 넘기면 회사 페이지의 `/vs/` 링크가 방출되지 않아
사각지대가 생긴다(2026-07-19 검수에서 이미 한 번 물린 자리).

## 테스트

생성기 **230 → 236 통과**(신규 6, 회귀 0). 롤업 `task_progress.py --check` 일치.
프론트·백엔드는 이 브랜치가 건드리지 않았다(CI 가 담당).

## 알게 된 것

- `_head_meta.html` 은 **회사·조합·정책·404 가 전부 공유**한다. "404 만 고치는" 변경이
  물리적으로 존재하지 않는다 — 전 페이지에 닿는 파일에 조건을 거는 것뿐이다.
  → `docs/PITFALLS/_incoming/shared-head-meta-partial-is-site-wide.md`
- `render.py` 는 `StrictUndefined` 다. 그래서 canonical 조건은 `is defined` 없이
  `{% if canonical %}` 로 뒀다 — 아예 안 넘기면 렌더가 죽는 편이 맞다(조용한 공란 금지).
  반대로 `robots` 는 넘기는 쪽이 404 하나뿐이라 `is defined and robots` 로 옵트인.
- `trim_blocks`/`lstrip_blocks` 때문에 조건부 태그가 앞 태그와 **한 줄에 붙어** 나온다.
  유효한 HTML 이고 파싱·테스트·SEO 에 영향 없다. 생성물 diff 만 조금 지저분하다.

## 남긴 것 (미결)

- **`X-Robots-Tag` 헤더는 손대지 않았다.** meta 태그는 HTML 을 파싱하는 크롤러에만 닿는다.
  nginx `error_page` 응답에 헤더로도 거는 편이 더 두텁지만 그건 `infra/` — **레인 D** 다.
  이 레인은 서버 무접촉이라 하지 않았다. 실익은 작다(404 본문은 어차피 HTML).
- `STATE.md` 「운영 미결」 행의 `404 noindex` 항목은 **이 PR 이 머지된 뒤** 지운다.
  STATE.md 는 핫스팟이라 이 브랜치에서 건드리지 않았다.
