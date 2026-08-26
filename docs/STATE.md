# STATE — 지금 상태 (재개 정본)

> **여기가 유일한 재개 정본이다.** 예전의 "HANDOFF 릴레이"(세션마다 새 파일 + 옛 정본에 강등
> 배너)는 2026-08-26 부로 폐지 — 병렬 세션에서 정본이 둘이 되는 구조였다. 이 파일은 짧은
> 표만 담아 줄 단위 병합이 되고, 세션 기록은 [`docs/handoff/`](handoff/)에 **각자 새 파일로만**
> 쓴다(남의 파일 수정 금지 → 충돌 0).

## 한 눈에 보기

| 구분 | 상태 | 갱신일 |
|---|---|---|
| 서비스 | `jobcho.wiki` 프로덕션 라이브 + `beta.jobcho.wiki` | 2026-07-31 |
| 브랜치 규약 | **main 직접 푸시 금지** — `lane/<분야>-<슬러그>` → PR → CI 3 job green → Squash merge | 2026-08-26 |
| CI | `.github/workflows/ci.yml` — frontend 697 · generator 230(+롤업 `--check`) · backend 540(`loupit_ci`) | 2026-08-26 |
| 데이터 | 회사 102 · 복지 1,465행 · 도메인 100/102 · 업종 102/102 | 2026-07-31 |
| M9(로그인) | prod ON · beta ON | 2026-07-29 |
| 테스트 | 백엔드 540 · sc14 3 · 생성기 230 · 프론트 697 | 2026-08-26 |
| TASK 진행 | [`TASK.md` §4 AUTOGEN 표](TASK.md) — 스크립트 집계(손집계 금지) | 2026-08-26 |
| 함정 로그 | 67건 — [`PITFALLS/INDEX.md`](PITFALLS/INDEX.md). 새 함정은 `PITFALLS/_incoming/` 에 번호 없이 | 2026-08-26 |
| 실트래픽 | ⚠ 실브라우저 세션 하루 고유 IP 2~10 — 병목은 제품이 아니라 유입 | 2026-07-31 |
| 운영 미결 | 서버 밖 백업 자동화 · DMARC 승급 · 도메인 2사 · 404 noindex · ufw · 터치 롤링 오조준 | 2026-07-31 |

> 상세 이력: [HANDOFF-2026-07-31](HANDOFF-2026-07-31.md) (마지막 릴레이 정본) ← 그 이전은 각 문서
> 상단 배너를 따라가라. 함정 ①~(66) 원문도 그 체인에 있다(인덱스: `PITFALLS/INDEX.md`).

## 병렬 작업 규칙 (2026-08-26 도입)

세션(요리사)은 갈래(레인)마다 하나. **동시 최대 3레인.**

| 레인 | 영역 | 주 파일 | 충돌 위험 |
|---|---|---|:-:|
| A 데이터 | 회사·복지·도메인 시드 | `db/seed/benefit/sql/*`(회사당 1파일) | 하 |
| B 프론트 | SPA·접근성·UX | `web/assets/js/*` | **상** |
| C 생성기/SEO | 정적 페이지·sitemap·색인 | `generator/*` | 하 |
| D 인프라 | 백업·방화벽·메일·nginx | `infra/*` | 중(서버 접촉) |

**핫스팟 — 한 시점에 한 레인만 수정**(여러 기능이 공유, 겹치면 반드시 충돌):
`server/main.py` · `server/tests/conftest.py` · `server/tests/test_surface.py` ·
`web/assets/js/app.js` · `web/assets/css/styles.css` · `db/schema.sql` · `infra/deploy/run_tests.sh`

- `db/schema.sql` 변경은 **항상 단독 작업** — `conftest.py TABLE_CREATE_ORDER` ·
  `run_tests.sh` · `db/seed/load.py` 동반 수정 필요(`test_runner_backup.py` 가 일치 강제).
- 미완성 화면은 `staging/`(리포 루트)에 — `web/` 는 곧 라이브 도크루트다.
- 리프 마커를 갱신했으면 `python3 docs/tools/task_progress.py` 실행(롤업 손집계 금지).
- 함정 발견 시 `docs/PITFALLS/_incoming/<슬러그>.md` 에 **번호 없이** 기록.

### 세션 브리프 템플릿

```
레인: <A~D>   브랜치: lane/<분야>-<슬러그>
할 일: <한 문장>
먼저 읽을 것: docs/STATE.md → docs/SPEC/<대역> → docs/TASK/<도메인>
건드려도 되는 파일: <목록>
금지: main 직접 푸시 · 서버 접속 · 핫스팟(위 목록) · 다른 레인 파일
끝나면: PR 생성 → CI 3 job green 확인 → 보고. 함정은 PITFALLS/_incoming/ 에.
```
