# STATE — 지금 상태 (재개 정본)

> **여기가 유일한 재개 정본이다.** 예전의 "HANDOFF 릴레이"(세션마다 새 파일 + 옛 정본에 강등
> 배너)는 2026-08-26 부로 폐지 — 병렬 세션에서 정본이 둘이 되는 구조였다. 이 파일은 짧은
> 표만 담아 줄 단위 병합이 되고, 세션 기록은 [`docs/handoff/`](handoff/)에 **각자 새 파일로만**
> 쓴다(남의 파일 수정 금지 → 충돌 0).

## 한 눈에 보기

| 구분 | 상태 | 갱신일 |
|---|---|---|
| 서비스 | `jobcho.wiki` 프로덕션 라이브 + `beta.jobcho.wiki` | 2026-07-31 |
| 브랜치 규약 | **main 직접 푸시 금지 — 잠금 적용·실증 완료**(직접 push 시 `GH013` 거부). `lane/<분야>-<슬러그>` → PR → CI 3 job green → Squash merge. 예외자 없음(bypass 목록 비어 있음) | 2026-08-26 |
| CI | `.github/workflows/ci.yml` — frontend 705 · generator 236 ×2(빈 env + **운영 env 주입**, +롤업 `--check`) · backend 560(`loupit_ci`). **3종 모두 머지 필수 검사**, 전체 약 1분. `up-to-date` 요구 켜짐 → 머지는 직렬(auto-merge 권장). ⚠ 생성기를 두 번 도는 이유: 러너의 빈 env 하나만 재현하면 CI 초록이 배포 초록을 뜻하지 않는다(함정 0079 실증) | 2026-08-27 |
| 데이터 | 회사 102 · 복지 1,465행 · 도메인 100/102 · 업종 102/102 | 2026-07-31 |
| M9(로그인) | prod ON · beta ON | 2026-07-29 |
| 테스트 | 백엔드 560 · sc14 3 · 생성기 236 · 프론트 705 — **전부 실측**(`--collect-only -m "not sc14"` · `node --test`). 이전 표의 540 은 낡은 값이었다 | 2026-08-27 |
| TASK 진행 | [`TASK.md` §4 AUTOGEN 표](TASK.md) — 스크립트 집계(손집계 금지). 14·15 도메인 추가로 계 324→**364** | 2026-08-27 |
| 함정 로그 | 79건 — [`PITFALLS/INDEX.md`](PITFALLS/INDEX.md). 새 함정은 `PITFALLS/_incoming/` 에 번호 없이 | 2026-08-27 |
| 회사 재무(신규 축) | DART 연동 3테이블(TCORP·TCOMPANY_CORP·TCORP_FINANCE)·corp_code 102 매칭 — [계획](PLAN-회사정보-확장-2026-08-21.md)·수집 미완. **리프는 [TASK/15](TASK/15-회사정보.md)(10)** · SPEC [SP-FIN](SPEC/15-회사정보-재무.md) · ⚠ `DART_API_KEY` 미보유(사용자 전달 대기) | 2026-08-27 |
| **커뮤니티·상단 탭(SC15 신설)** | 2026-08-27 결정 4건 확정 — [계획](PLAN-커뮤니티-회사정보탭-2026-08-27.md) §1. PRD SC15(소셜피드≠게시판)·INV-1 개정·USECASE 10·FRD 14·SPEC 14([SP-COMM](SPEC/14-커뮤니티.md))·TASK 14(30 리프). **PR-1 회사정보 탭** = `lane/gnb-company-info-tab`(생성기 242·프론트 705 green, **PR 생성 대기** — 호스트에 `gh` 없음). 다음: PR-2 재무(키 대기)·PR-3 스키마(단독)·PR-4 서버·PR-5 프론트+공개(staging→git mv+nginx) | 2026-08-27 |
| 릴리스 게이트 | **서빙 무접촉 — 호출자까지 실증 완료.** `run_tests.sh` 는 `loupit_test` 만 쓰고, `release.sh` 는 `env -u DB_NAME` 으로 서빙 이름을 지워 넘긴다(가드: `test_release_does_not_leak_serving_db_name_into_gate`). ⚠ **시드 변경은 릴리스로 서빙에 반영되지 않는다** — 구 판본의 재시드 부작용이 사라졌다. 별도 `LOUPIT_ALLOW_FRESH=1 python3 db/seed/load.py --fresh` 필요 | 2026-08-27 |
| 실트래픽 | ⚠ 실브라우저 세션 하루 고유 IP 2~10 — 병목은 제품이 아니라 유입 | 2026-07-31 |
| 운영 미결 | 서버 밖 백업 자동화 · DMARC 승급 · ufw · 덕산 그룹공용 도메인 판단(보류 유지, 2026-08-27 결정) | 2026-08-27 |

> 상세 이력: [HANDOFF-2026-08-21](HANDOFF-2026-08-21.md) (마지막 릴레이 정본) ← 그 이전은 각 문서
> 상단 배너를 따라가라. 함정 ①~(73) 원문도 그 체인에 있다(인덱스: `PITFALLS/INDEX.md`).

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

### 1차 실전 결과 (2026-08-27) — 3레인 동시, 사고 0

A·B·C 를 동시에 돌려 PR #3·#4·#5 를 전부 머지했다. **충돌 0건 · CI 재실행 실패 0건.**
파일 격리가 설계대로 작동했다(세 레인의 변경 파일이 하나도 겹치지 않음, 핫스팟 무접촉).
운용에서 배운 것:

- **세션은 PR 을 안 올린다.** 셋 다 커밋·푸시까지만 하고 멈췄다. 브리프의 "끝나면 PR
  생성"은 지시로 부족하다 — 사람이(또는 관제 세션이) 대신 올릴 각오를 하고 시작하라.
- **머지는 직렬이다.** `up-to-date` 요구 때문에 앞 PR 이 머지될 때마다 뒤 PR 은
  브랜치 최신화 → CI 재실행(약 1분)을 거친다. 3건에 약 5분. 이건 비용이 아니라
  "머지된 main 에서 실제로 초록"임을 매번 확인하는 값이다.
- **레인이 목표를 못 채울 수 있고, 그게 정답일 때가 있다.** 레인 A 는 도메인 2사를
  채우라는 지시를 받고 **한 건도 안 채웠다**(근거 불충분 + 그룹 공용 도메인 위험).
  추측으로 채웠으면 엉뚱한 사람이 재직 인증됐다. 브리프의 "금지" 항목이 일한 것이다.
- **세션 생성 시 `permission_mode`** — 1차에서 레인 C 가 셋업 도구(`Register Repo Root`)
  승인 대기로 멈춰 있었다. 다음 배치부터는 셋업 계열 도구를 미리 승인해 세션을 만든다.
  `bypassPermissions` 는 쓰지 않는다 — 서버 접속·main 푸시 금지가 승인 게이트에 걸려 있다.
- **격리 계약은 호출자까지 검증하라.** `run_tests.sh` 만 격리했더니 `release.sh` 가
  `DB_NAME=LOUPIT` 을 물려줘 계약이 무효였다(함정 0075). 파일 하나에 새긴 계약은
  그 파일을 부르는 모든 곳도 같은 가드에 넣어야 성립한다.
- **CI 초록 ≠ 배포 초록.** 위 3레인 PR 은 전부 CI 초록이었는데 첫 릴리스는 두 단계에서
  연달아 막혔다(0075 `[1/5]`, 0079 `[2/5]`). 둘 다 **CI 러너와 배포 호스트의 env 가
  달라서** 생긴 일이다 — 리포가 초록이어도 배포는 처음 돌려봐야 안다. 병렬 배치를
  머지한 날은 **반드시 릴리스까지 돌려서** 닫아라. 지금은 생성기 스위트를 env 주입으로
  한 번 더 돌려 이 축을 CI 안으로 끌어왔다.

### 세션 브리프 템플릿

```
레인: <A~D>   브랜치: lane/<분야>-<슬러그>
할 일: <한 문장>
먼저 읽을 것: docs/STATE.md → docs/SPEC/<대역> → docs/TASK/<도메인>
건드려도 되는 파일: <목록>
금지: main 직접 푸시 · 서버 접속 · 핫스팟(위 목록) · 다른 레인 파일
끝나면: PR 생성 → CI 3 job green 확인 → 보고. 함정은 PITFALLS/_incoming/ 에.
      목표를 못 채우는 게 옳다고 판단되면 채우지 말고 근거를 남겨라(레인 A 선례).
```

머지 후 정리(관제 쪽이 한다): `python3 docs/tools/pitfalls.py --assign` 으로 `_incoming/`
번호 부여 · `python3 docs/tools/task_progress.py` 로 롤업 재집계 · 이 파일 갱신.
