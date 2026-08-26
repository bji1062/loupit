# 2026-08-26 — 병렬 개발 체제 부트스트랩

## 한 일 (커밋 순)
- 세션 런타임 락(`.claude/scheduled_tasks.lock`) git 추적 해제 — 병렬 세션 더티/충돌 원인.
- **sitemap 템플릿 복원** — `.gitignore` 의 생성물 패턴이 소스 템플릿까지 먹어
  한 번도 커밋된 적이 없었다(함정 74). fresh clone 에서 생성기 13개 실패 → 230 green.
- **CI 신설**(`.github/workflows/ci.yml`) — frontend 697 / generator 230+롤업체크 /
  backend 540(mysql 서비스, `loupit_ci`). `pydantic-settings` 를 requirements 에 등재(잠복 실의존).
- **TASK 롤업 자동화**(`docs/tools/task_progress.py` + TASK.md AUTOGEN 표) —
  손집계 드리프트 실측(문서 255 vs 마커 267 완료).
- **함정 로그 개편**(`docs/tools/pitfalls.py` + `PITFALLS/INDEX.md` + `_incoming/`) —
  전역 카운터 제거, 기존 66개 원문 불변·스캔 인덱스만.
- **STATE.md 신설** — HANDOFF 릴레이 폐지, 재개 정본 단일화 + 병렬 작업 규칙.
- `run_tests.sh` 를 `loupit_test` 전용으로(서빙 무접촉) · `staging/` 신설.

## 알게 된 것
- 실측 진행: 완료 267 / 진행 28 / 미착수 29 (총 324).
- 서버에서만 일하면 "서버에만 있는 파일"을 영영 모른다 — CI 첫 도입이 곧 탐지기였다.

## 남긴 것
- 브랜치 보호 설정(웹 UI, CI 머지 후) · 서버에서 run_tests.sh 무접촉 검증 ·
  기존 운영 미결 6건(STATE.md 표).
