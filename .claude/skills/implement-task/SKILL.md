---
name: implement-task
description: loupit docs/TASK 작업계획(286 리프)을 빌드순서(M0~M8)대로 TDD(red-green-refactor)로 구현하는 8단계 실행 스킬. 다음 리프 선택 → RED → GREEN → REFACTOR → 진행마커 갱신, 결정게이트(DG-1~4) 확인, Tier-0 게이트·범위 불변식 준수. loupit 코드를 실제로 짤 때 사용.
---

# implement-task — loupit TASK 실행 스킬 (8단계 구현)

## 목적
`docs/TASK/`(00 빌드순서 + 01~12 도메인 = 286 리프)를 **실제 코드 + 통과하는 테스트**로 구현한다. 작업 단위 = 리프(`T-nn.g.i`). **완료(DoD) = 구현 + 대응 테스트 green 둘 다**(SP-TEST-1). 한쪽만이면 진행 중.

## 0. 매 실행 오리엔테이션
1. `docs/TASK/00-빌드순서-마일스톤.md` 정독 — 현재 마일스톤·의존 DAG·크리티컬 패스·Tier-0 맵·결정게이트.
2. `docs/TASK.md` 진행 롤업 확인(어디까지 됐나).
3. 대상 도메인 `docs/TASK/NN-*.md`에서 다음 `- [ ]` 리프 선택. **빌드순서 준수** — 선행 의존이 완료(`- [v]`)된 리프만 착수.
4. 필요 시 해당 `docs/SPEC/NN-*.md`의 SP-N 계약(시그니처·수식·DDL·케이스)을 정본으로 참조.

## 1. 리프 실행 사이클 (red-green-refactor)
각 리프마다:
- **선결정 확인**: 리프/마일스톤에 DG(결정게이트)가 걸려 있으면 **먼저 AskUserQuestion으로 확정**(임의판단 금지). 미해소면 착수 금지, 리프는 `- [ ]` 유지.
- **RED**: 리프의 "테스트"에 명시된 케이스 ID를 **먼저** 작성(경계·0나눗셈·오류 경로 포함). 러너 실행 → **실패 확인**(미구현).
- **GREEN**: 리프의 "구현" 계약(파일·시그니처·수식·DDL)대로 **최소 구현**. 러너 → 대상 스위트 green.
- **REFACTOR**: 동작 불변으로 정리(중복 제거·명명·순수성). 러너 재실행 green 유지.
- **마커 갱신**: 리프 `- [ ]`→`- [v]`(구현+테스트 green 둘 다) 또는 `- [-]`(한쪽만/차단). 파일 상단 "진행 요약" 카운트 + `docs/TASK.md` §2·§4 롤업 동기 갱신.

## 2. 테스트 러너 (SP-TEST-2)
| 계층 | 명령 | 전제 |
| --- | --- | --- |
| 백엔드(API·스키마·시드) | `python -m pytest server/tests/ -q` | DB 필요분은 `loupit_test` MySQL; API 계약만은 monkeypatch(무 DB) |
| 계산·프론트·광고·토큰·메타 | `node --test web/` | node ≥18, `web/package.json` type:module |
| 생성물·정책 | `python -m pytest generator/tests/ -q` | fake 번들(무 DB) |
| 통합 스모크 | `bash infra/deploy/smoke.sh` | 로컬 전체 스택 |
| 설정 문법 | `nginx -t -c infra/nginx/loupit.conf` | nginx |
| 집계 게이트 | `bash infra/deploy/run_tests.sh` | 릴리스 게이트(로컬, CI 없음) |

## 3. 마일스톤·게이트 (00 소유)
- 순서: **M0 스캐폴드 → M1 데이터(DB→SEED) → {M2 API ∥ M3 엔진} → M4 광고·정책 → M5 정적생성 → M6 프론트 → M7 인프라·집계 → M8 하드닝·릴리스**.
- 마일스톤 완료 시 해당 계층 게이트(run_tests.sh 서브셋) green 확인 후 다음 마일스톤 진입.
- **Tier-0 27 리프(00 §5)는 어느 것도 깨지면 안 됨** — 깨지면 즉시 회귀 우선 수정.
- 마일스톤 상태 마커(00 §1 · TASK.md §3) 갱신.

## 4. 결정 게이트 (DG-1~4, 00 §4 — 착수 전 AskUserQuestion)
- **DG-1**(OI-3): 카테고리별 만료 TTL 값 → M1 시드 백필·M3 만료 밴드.
- **DG-2**(OI-6): `amt_source` 백필 판별 규칙(`(추정)`→stated/estimated) → M1 백필.
- **DG-3**: 엔씨소프트 시드 메타(200 밖) → M1 회사 매핑.
- **DG-4**: RESEARCH §8 기타 + 로컬(MySQL 인증 플러그인 `cryptography` 포함 여부 · `/health` 레디니스 503) → M0/M2.

## 5. 범위 불변식 (위반 금지 — INV)
- 로그인/회원/프로파일러/서버 측 사용자 쓰기 **부재**(INV-1·4). 비교 계산 **100% 클라이언트**. 회사 등록 **~96(≠200)**(INV-6). DEC-2 밴드 **stated±5%/estimated±20%/만료+15%**(INV-5). 프론트↔API **동일 오리진**·앱/DB 미노출(INV-7). 밴드는 금액 신뢰도 기준(배지와 디커플링, INV-5).

## 6. 규약
- **언어**: UI/콘텐츠 한국어, 코드(식별자·함수·파일명) 영어.
- **버전**: SP-ARCH-7 pin 준수(무빌드 프론트·인증 라이브러리 금지: `python-jose`·`passlib`·SMTP·OAuth).
- **커밋**: 논리 단위 또는 마일스톤 완료 시. 메시지 끝 `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. push는 사용자 관행(확정 시 push).
- **보고**: 장시간 실행 중 ~5분마다 진행률 보고(사용자 선호).
- **재이식 소스**: `/home/ubuntu/job_change`(복지 SQL 96개 `server/seed/benefit/sql/`, 비교 알고리즘 원형 `app.js`) — 코드는 새로 작성하되 데이터·수식 원형 참고. 데이터는 보존.
