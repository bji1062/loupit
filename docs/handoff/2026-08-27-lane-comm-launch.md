# 세션 기록 — 2026-08-27 · 관제 · 커뮤니티 공개 PR (T-14.7)

브랜치 `lane/comm-launch`(worktree `/home/ubuntu/loupit-wt/launch`, `lane/comm-frontend` 위). 계획 §5 **PR-5 후반(공개)**.
머지 순서: PR-1(gnb) → PR-5(front, staging) → **PR-4(comm-backend, 마이그레이션 선행)** → 이 PR.

## 한 일

| # | 조치 | 어디 |
|---|---|---|
| 1 | `git mv staging/community web/community` — 셸 공개 | `web/community/index.html` |
| 2 | `GNB_TABS` 에 `("커뮤니티", "/community/")`(홈 다음) + 수기 셸 7개 같은 줄 + 커뮤니티 셸을 동기화 대상에 편입 | `generator/content/nav.py` · `web/*.html`·`compare/index.html` · `test_gnb_tabs.py` |
| 3 | 정책 문안 **P10(커뮤니티 게시물 정보)**·**T6(게시물 책임·금지행위·임시조치 §44-2·이용허락)** — M9 조건 항목. T2 에 "커뮤니티 쓰기도 같은 로그인" + 소셜 피드 정의(팔로우·타임라인) | `generator/content/policy.py` · `test_policy_m9.py`(PM1·PM8 갱신, PM16~18 신설) |
| 4 | `/community/` 를 허용 정적 라우트·sitemap 추가 항목에 | `test_links.py` · `generator/config.py` · `test_sitemap_robots.py`(extra 경로를 정본에서 읽도록) |
| 5 | nginx prod·beta 대칭 블록(`= /community` 301 · `^~ /community/` try_files 폴백) — **수동 배치 필요**(함정 ⑭). 문법: 래퍼로 `nginx -t` 통과 | `infra/nginx/loupit.conf` · `loupit-beta.conf` |

## 검증
생성기 **242 → 245**(PM16~18 신규, 회귀 0) · 프론트 **780** 무변경. `nginx -t`(scratch 래퍼, worktree conf) syntax ok.

## 배포 절차 (관제 — 이 PR 머지 후)
1. `mysql … LOUPIT < db/migrations/20260827_add_community.sql`(prod) + `loupit_beta` 동일 — **API 재시작보다 먼저**(M9 ON 이라 라우트가 즉시 살아난다).
2. 프로덕션 `git pull --ff-only` → `/etc/nginx/sites-available/loupit.conf`·`loupit-beta.conf` 에 블록 반영 → `sudo nginx -t && sudo systemctl reload nginx`.
3. `python3 -m generator.build`(헤더 탭·정책 P10·T6·sitemap) → `sudo systemctl restart loupit-api loupit-beta-api`.
4. 스모크: `/community/` 200 · `/community/999999` 셸 200 · `/api/v1/posts` 200 `{items:[],next_before:null}` · 쓰기 401/403 · `/privacy#p10` · `/terms#t6`.

## 남긴 것
- `/members/me` 프로브가 커뮤니티 페이지에서 2회(authnav.js + community.js) — 무해, 정리 후보.
- 커뮤니티 본문은 JS 렌더라 색인 기대 없음(1차). 허브 `/community/` 만 sitemap.
