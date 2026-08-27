"""generator/content/nav.py — 전역 상단 탭(GNB) 정본 (2026-08-27).

상단 탭은 **두 종류의 헤더**에 같은 순서로 실려야 한다:
  · 초록 gnb — 수기 셸 7개(web/index.html·compare/index.html·login·mypage·verify·edit·edits)
  · 단순 헤더 — 생성기 `partials/_header.html`(회사·조합·정책·404 전 페이지)

수기 셸은 생성기를 거치지 않는 하드코딩 HTML 이라 이 상수를 import 할 수 없다.
그래서 `generator/tests/test_gnb_tabs.py` 가 **문자열로 동기화를 검증**한다
(`test_authnav.py`·`test_footer_links.py` 와 같은 방식). 여기 항목을 바꾸면 셸 7개도 함께 고쳐라 —
안 고치면 그 테스트가 빨개진다(드리프트를 조용히 두지 않는다).

탭 순서는 prober.kr 벤치마크(홈 바로 옆에 주요 구획)를 따른다 — `docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md` §3-1.
`커뮤니티` 탭은 **커뮤니티가 실제로 열리는 PR 에서** 추가한다(죽은 탭 금지).
"""
from __future__ import annotations

# (라벨, href). href 가 탭의 식별자다 — `nav_active` 는 이 href 로 현재 탭을 가리킨다.
GNB_TABS: tuple[tuple[str, str], ...] = (
    ("홈", "/"),
    ("회사정보", "/companies"),
)

GNB_TAB_HREFS: frozenset[str] = frozenset(h for _, h in GNB_TABS)
