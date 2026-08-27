# 세션 기록 — 2026-08-27 · 관제 · 커뮤니티 + 회사정보 탭 계획·범위 개정

브랜치 `lane/docs-sc15-community-scope`(이 문서군) + `lane/gnb-company-info-tab`(PR-1 코드).
요청: "prober.kr 처럼 상단에 커뮤니티를 만들고, PLAN-회사정보-확장 을 확인해 커뮤니티 옆에 회사정보 탭도 신설".

## 한 일

1. **벤치마크 실측** — prober.kr 은 SPA 라 HTML 만으론 안 보인다. 번들(957KB)에서 라우트·문자열을 뽑아
   탭(홈·커뮤니티·한국주식·경제캘린더·부동산)과 커뮤니티 구조(카테고리·정렬 4종·댓글/대댓글·좋아요/싫어요·
   글쓰기 로그인 필수)를 확인했다. 계획 §0.
2. **계획** `docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md` — 결정 4건을 사용자가 확정:
   SC15 신설 / 쓰기=로그인 / DART 키는 세션에 전달 / 카테고리 `전체(필터)·공지(운영자)·자유·이직 고민·건의사항`.
3. **범위 개정 문서군** — PRD/04 SC15 신설 + SC10 '소셜피드' 정의 확정(팔로우·타임라인·개인화 피드) ·
   SPEC/01 INV-1 개정(공개 GET +3, 커뮤니티 쓰기 열거) · SPEC/04 전역 불변식 문단 ·
   USECASE/10(UC-80~87) · FRD/14(FR-120~133) · SPEC/14 SP-COMM · SPEC/15 SP-FIN · TASK/14(30)·TASK/15(10) ·
   인덱스 4종 · 롤업 재집계(324→364) · STATE.md 2행.
4. **PR-1(회사정보 탭)** 은 별도 기록 `2026-08-27-lane-gnb-company-info-tab.md`.

## 알게 된 것

- **PRD 가 커뮤니티를 막고 있었다.** SC10 "소셜피드 영구 제외"는 커뮤니티의 이웃이라 그냥 만들면 문서가
  허위가 된다(함정 (61) 계열). 정의를 좁혀(피드 ≠ 게시판) SC15 로 들였다 — 2026-07-14·07-21 개정과 같은 절차.
- **`gh` 가 호스트에 없고 토큰도 없다.** 세션은 브랜치 푸시까지만 할 수 있고 PR 생성은 사람 몫이다
  (STATE "세션은 PR 을 안 올린다"의 실체). 푸시 출력의 `pull/new/<branch>` 링크로 만든다.
- **프로덕션 작업트리가 origin/main 보다 1커밋(#9, 문서) 뒤다.** `git pull --ff-only` 는 라이브 `web/` 을
  바꾸므로 코드 PR 머지 후 배포 절차와 함께 한다.
- 헤더가 두 종류(초록 gnb / 생성기 partial)라 "상단 탭 하나 추가"가 파일 8개 + 동기화 테스트 1개다.
- 커뮤니티 **조회수는 두지 않기로** 했다 — 봇이 실사용의 수백 배라(`GET /` 1,875~11,036 vs 실세션 1~4)
  조회수는 즉시 거짓 숫자가 된다(함정 (57) 계열).

## 남긴 것 (미결)

- **PR 생성**: `lane/docs-sc15-community-scope` · `lane/gnb-company-info-tab` 둘 다 푸시됨, PR 은 사람이.
- **DART 키** 수령 → `server/.env` `DART_API_KEY`(chown ubuntu 유지) → T-15.1/15.3.
- **워크트리 정리**: `/home/ubuntu/loupit-wt/{docs,gnb}` — 머지 후 `git worktree remove`.
- 머지 후 관제 정리: PR-1 머지 시 T-14.0.1 `[v]` + 롤업 · STATE 행 갱신 · 프로덕션 `git pull` + 재생성.

## 추가 — 레인 실행·통합·서빙 적재 (같은 날 후반)

- 에이전트 3레인(fin·comm·front)을 각자 worktree 에서 병렬로 돌렸다. 도중 **월 사용 한도**로 셋 다 중단됐다가
  충전 후 같은 이름으로 재개(transcript 이어짐) — 미커밋 상태였던 fin 도 그대로 이어서 끝냈다.
- worktree 에는 `.gitignore` 대상인 `server/.env` 가 딸려오지 않아 conftest 가 `KeyError: DB_HOST` 를 낸다 —
  **테스트 전용 최소 env**(DB 4키 + `DB_NAME=loupit_test` + CI 플래그, pepper·SMTP 없음)를 관제가 놓았다.
- 공개 PR(`lane/comm-launch`)은 관제가 직접: 탭·정책 P10/T6·`git mv`·nginx 블록·sitemap(`extra_sitemap_paths`).
- **통합 브랜치 `lane/integration-2026-08-27`** = 6레인 머지(충돌 1건 `server/config.py` — 두 레인이 같은 자리에
  필드 추가, 둘 다 유지) + TASK 마커·롤업·STATE. 백엔드 671 · 생성기 280 · 프론트 780.
- **서빙 DB 적재**: `load_corp`(법인 100·매핑 101) → `dart_finance --base-year 2025 --years 5`(1,000회 호출,
  2,829행, 결측 14) → 결측 hint 대로 4사 `FS_DIV_CD='OFS'` 후 부분 재수집(51행, rc 0). 남은 결측 2건은 정당.
  scratch 렌더로 삼성전자 실적 5개년·증감률 확인, 두께 중앙값 1,402 → 1,610자(목표 1,900 에는 못 미침 —
  표는 글자 수가 적다. 뉴스(5단계)나 설명문이 있어야 더 는다).
