"""generator/content/nav.py — 전역 상단 탭(GNB) 정본 (2026-08-27).

상단 탭은 **모든 헤더**에 같은 순서로 실려야 한다. 2026-09-01 부로 헤더는 한 종류다 —
초록 gnb(`data-global class="gnb"` + `.brand` 로고):
  · 수기 셸 8개(web/index.html·compare·community·login·mypage·verify·edit·edits)
  · 생성기 `partials/_header.html`(회사·회사인덱스·히트맵·조합·정책·404 전 페이지)
그전엔 생성기만 `.site-logo` 텍스트 헤더를 내서 **메뉴로 오갈 때 헤더가 바뀌고 로고가
사라졌다**(사용자 신고). 마크업 동일성은 `generator/tests/test_header_markup.py` 가 지킨다.

수기 셸은 생성기를 거치지 않는 하드코딩 HTML 이라 이 상수를 import 할 수 없다.
그래서 `generator/tests/test_gnb_tabs.py` 가 **문자열로 동기화를 검증**한다
(`test_authnav.py`·`test_footer_links.py` 와 같은 방식). 여기 항목을 바꾸면 셸 7개도 함께 고쳐라 —
안 고치면 그 테스트가 빨개진다(드리프트를 조용히 두지 않는다).

탭 순서는 홈 다음에 **찾는 도구**(복지로 찾기·회사정보·히트맵), 마지막이 커뮤니티다.
2026-09-06 에 「복지로 찾기」를 홈 옆에 넣으면서 커뮤니티를 끝으로 옮겼다 — 새 탭이 이 사이트의
핵심 동선(복지 → 회사 → 비교)의 입구이고, 커뮤니티는 그 동선 밖의 별도 구획이기 때문이다.
그전 순서는 prober.kr 벤치마크(홈 바로 옆에 주요 구획)를 따랐다 — `docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md` §3-1.
`커뮤니티` 탭은 커뮤니티가 실제로 열리는 PR(lane/comm-launch, 2026-08-27)에서 추가했다 — 죽은 탭 금지 규약 그대로.
"""
from __future__ import annotations

# (라벨, href). href 가 탭의 식별자다 — `nav_active` 는 이 href 로 현재 탭을 가리킨다.
GNB_TABS: tuple[tuple[str, str], ...] = (
    ("홈", "/"),
    # 탭 라벨만 「복지찾기」(4자)다 — 페이지 h1·title·SPEC 이름은 「복지로 찾기」. 5자 라벨은
    # 익명·M9 ON(현재 prod)에서 360~400px 헤더를 두 줄 97px 로 만들었다(main 은 57px, 헤드리스 실측
    # 2026-09-06): 탭 폭이 +71px 늘어 「로그인」이 둘째 줄로 밀린다. 갤럭시(360)·아이폰(390) 익명
    # 방문자의 **전 페이지** 헤더가 40px 자라는 값이라 라벨을 줄이는 쪽을 택했다.
    ("복지찾기", "/find"),  # SP-FIND(2026-09-06) — 생성 페이지 find.html, nginx = /find
    ("회사정보", "/companies"),
    ("히트맵", "/heatmap"),  # SP-HEAT(2026-08-27) — 생성 페이지 heatmap.html, nginx = /heatmap
    ("커뮤니티", "/community/"),  # SC15(2026-08-27) — 셸 web/community/index.html, nginx ^~ /community/
)

GNB_TAB_HREFS: frozenset[str] = frozenset(h for _, h in GNB_TABS)
