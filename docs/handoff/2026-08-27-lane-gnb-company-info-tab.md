# 세션 기록 — 2026-08-27 · 레인 C+B(생성기/프론트) · 상단 탭 "회사정보"

브랜치 `lane/gnb-company-info-tab`. `docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md` §5 **PR-1**.
prober.kr 처럼 상단에 구획 탭을 두는 첫걸음 — **회사정보 탭(→ `/companies`)** 만 넣는다.
커뮤니티 탭은 커뮤니티가 실제로 열리는 PR 에서 넣는다(죽은 탭 금지).

## 한 일

| # | 조치 | 어디 |
|---|---|---|
| 1 | 탭 정본 상수 `GNB_TABS = (홈 /, 회사정보 /companies)` | `generator/content/nav.py`(신설) |
| 2 | 생성기 헤더가 상수를 순회 렌더 + `aria-current="page"` | `render.py`(env 전역 `gnb_tabs`·`nav_active`) · `partials/_header.html` |
| 3 | 회사 상세·회사 인덱스 = 회사정보 탭 소속(`nav_active="/companies"`) | `pages/company.py` · `pages/company_index.py` |
| 4 | 수기 셸 7개 gnb 에 같은 탭(랜딩만 홈 활성). 로그인 계열의 "← 비교하러 가기"는 홈 탭이 대체, verify/edit 의 "← 마이페이지"는 유지 | `web/index.html`·`compare/index.html`·`login`·`mypage`·`verify`·`edit`·`edits.html` |
| 5 | 현재 탭 스타일 — `header nav a[aria-current="page"]` 풀색 밑줄 | `web/assets/css/styles.css`(핫스팟, 이 레인만) |
| 6 | 인덱스 제목·h1 을 탭 이름과 맞춤: "회사정보 — 등록 회사 N곳" | `companies.html` · `company_index.py` |
| 7 | 동기화 계약 테스트 6종 | `generator/tests/test_gnb_tabs.py`(신설) |

## 왜 이렇게

- **정본이 하나여야 한다.** 헤더가 두 종류(초록 gnb 수기 셸 / 생성기 partial)라 한쪽에만 넣으면
  페이지를 오갈 때 탭이 나타났다 사라진다. 수기 셸은 상수를 import 할 수 없어
  `test_authnav.py`·`test_footer_links.py` 와 같은 **문자열 동기화 검증**을 택했다.
- **env 전역으로 실었다.** `_header.html` 은 base 를 상속하는 전 페이지가 공유한다. 렌더 호출마다
  탭을 넘기면 한 곳만 빠뜨려도 `StrictUndefined` 가 빌드를 죽인다. 현재 탭만 페이지가 override.
- **`aria-current` 를 정본으로.** 활성 클래스를 따로 두면 스크린리더 상태와 시각 상태가 갈라질 수
  있다. 속성 셀렉터 하나로 둘을 묶었다.
- 로고(`.brand`·`.site-logo`)도 `/` 를 가리키지만 탭이 아니다 — 테스트가 이를 걸러낸다(첫 RED 원인).

## 검증

생성기 **236 → 242**(신규 6, 회귀 0) · 프론트 **705**(무변경, 회귀 0). 백엔드는 무접촉(CI 가 확인).
RED 확인: 구현 전 6개 중 4개 실패(생성 페이지 탭·셸 탭·aria-current 2종), 상수 형식·죽은 탭 가드 2개는
처음부터 초록 — 가드는 처음부터 끝까지 초록이어야 맞다.

## 남긴 것

- 탭 활성 스타일의 **육안 확인은 머지·배포 후** 라이브에서(격리 worktree 라 브라우저 미리보기 생략).
- `/companies` 는 아직 복지 목록이다. 재무 열(PR-2)이 얹혀야 "회사정보" 라는 이름값을 한다.
- 커뮤니티 탭은 `GNB_TABS` 에 한 줄 + 셸 7개 한 줄씩 — 테스트가 빠뜨린 곳을 잡는다.
