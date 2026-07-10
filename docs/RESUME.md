# RESUME — 작업 재개 가이드

> **다른 PC/새 세션에서 이 프로젝트를 이어받는 사람(또는 AI)을 위한 인수인계 문서.** 이 파일 하나만 읽으면 지금까지의 맥락·규칙·다음 할 일을 파악할 수 있다. 최종 업데이트: 2026-07-10 (SPEC 6단계 완료 시점).

## 0. 한 줄 요약

**loupit** = 기존 `job_change`("직장 선택 OS")를 **로그인 제거 + 광고(AdSense·제휴) 수익 모델**로 재설계하는 프로젝트. 현재 **8단계 문서 파이프라인 중 6단계(SPEC)까지 완료**, 다음은 **7단계 TASK**.

## 1. 지금 어디까지 왔나

```
1 PRD ✅  2 USECASE ✅  3 FRD ✅  4 FLOW ✅  5 WIREFRAME ✅  6 SPEC ✅
7 TASK ⬅ 다음 할 일   8 구현(TDD) ⬜
```

| 단계 | 문서 | 상태 | 규모 |
| --- | --- | --- | --- |
| 1 | [PRD.md](PRD.md) + PRD/ | ✅ | 10개 파일, 요구사항 ID G/F/MON/NFR/D/AS/R |
| 2 | [USECASE.md](USECASE.md) + USECASE/ | ✅ | 8개 파일, 44개 UC, F1~F8 커버리지 |
| 3 | [FRD.md](FRD.md) + FRD/ | ✅ | 12개 파일, 97개 FR |
| 4 | [FLOW.md](FLOW.md) + FLOW/ | ✅ | 8개 파일, 43화면/29플로우 (Mermaid) |
| 5 | [WIREFRAME.md](WIREFRAME.md) + WIREFRAME/ | ✅ | 8개 파일, 34개 SCR (ASCII 와이어) |
| 6 | [SPEC.md](SPEC.md) + SPEC/ | ✅ | 12개 파일, SP-* 구현 계약 |
| — | [RESEARCH.md](RESEARCH.md) + RESEARCH/ | ✅ | 복지 데이터 수집·스크래핑 전략 |
| 7 | TASK.md + TASK/ | ⬜ **다음** | SPEC → 구현 작업 계획(계층·진행상태) |
| 8 | 구현 | ⬜ | TASK를 구현할 스킬 생성 후 실행 |

**git**: 모든 진행분 커밋·push 완료. 리모트 `git@github.com:bji1062/loupit.git` (SSH). 작업 트리 clean.

## 2. 다음 할 일 (7단계 TASK)

원래 지시(8단계 프로세스 中 7):
> `docs/SPEC.md`를 구현하기 위한 구체적인 작업 계획을 `docs/TASK.md`에 작성한다. 작업 단계는 계층구조로 나누고, 하나의 세부 작업 단계에서는 최소한의 작은 독립적 기능만 구현한다. 작업 단계별 진행상태(`- [ ]`/`- [-]`/`- [v]`)도 관리할 수 있도록 항목을 추가한다.

이후 8단계: `docs/TASK.md`를 구현할 스킬 생성 후 실행.

## 3. 반드시 지킬 규칙 (사용자 지시)

1. **문서 위치**: 모든 문서는 `docs/`에. 각 `docs/<NAME>.md`는 **요약+참조목록만 담는 얇은 인덱스**, 상세는 `docs/<NAME>/<항목>.md`로 분리. (예: `docs/TASK.md` 얇게 + `docs/TASK/<항목>.md` 상세)
2. **결정 처리**: 애매하거나 결정이 필요하면 **임의 판단 금지, 항상 질문(AskUserQuestion)으로 확인** 후 진행.
3. **TDD 필수**: 모든 코드는 red-green-refactor. 새 모듈·공개함수·라우트는 테스트 우선. **TASK 항목 완료(`- [v]`) 기준 = 구현 + 테스트 통과 둘 다**. 한쪽만이면 진행중(`- [-]`).
4. **언어**: UI/콘텐츠 한국어, 코드(변수/함수) 영어.

## 4. 절대 잊으면 안 되는 확정 결정

- **로그인/회원/인증/OAuth/JWT/이메일인증/소셜피드 = 전면 제거.** 사용자별 서버 저장 없음. 사용자 데이터는 브라우저 **localStorage에만**.
- **프로파일러(가치관 진단 설문→페르소나) = 영구 제외.** 우선순위는 사용자가 직접 선택(연봉/워라밸/복지/브랜드).
- **회사 등록 = 복지 데이터가 있는 ~96개만** (KOSPI/KOSDAQ 200개 전체 아님). 예외: **엔씨소프트 포함**(복지 있음), **CJ→CJ올리브네트웍스로 등록**(계열사 실데이터).
- **백엔드 = 슬림 읽기 전용 FastAPI + MySQL** (쓰기·인증 없음). 참조 테이블 5개: TCOMPANY_TYPE/TCOMPANY/TCOMPANY_ALIAS/TCOMPANY_BENEFIT/TBENEFIT_PRESET.
- **TBENEFIT_PRESET = 회사페이지 폴백 아님.** 비교 툴 **직접입력 모드**(등록 밖 회사)의 유형 기반 기본복지 템플릿용.
- **비교 계산 = 100% 클라이언트 사이드.** 서버는 참조 데이터만 제공.
- **수익화 = AdSense(자동+수동) + 제휴(affiliate.json).** 배치 = **콘텐츠 페이지 위주**, **비교 입력 화면 무광고 강제**, 결과 하단 1개. "광고" 표기(공정위).
- **SEO 핵심**: 회사 상세 ~96개 + 인기 비교 조합 페이지를 빌드타임 정적 생성.
- **DEC-2 (복지 데이터 신뢰도)**: 96개는 출처=`official`(공식 페이지 기반)로 인정하되, **추정 금액은 `amt_source=estimated`로 정직 표기**. 불확실성 밴드는 금액 기준: stated ±5% / estimated ±20% / 만료 +15%.
- **디자인 접근(옵션1)**: SPEC은 **디자인 토큰만**(색·타입·간격 CSS 변수). 비주얼 polish는 **개발 후 실제 앱(styles.css)에서** 반복. hi-fi 시안 없음.

## 5. 기존 자산 위치 (참고·재사용)

- 원본 프로젝트: `/home/ubuntu/job_change` (코드는 새로 작성, 데이터는 보존)
- 복지 데이터: `job_change/server/seed/benefit/sql/*.sql` (96개 gold set)
- 회사 시드: `job_change/server/seed/companies_kospi_1~2.py`, `companies_kosdaq_1~2.py` (200개 메타 — 여기서 96개 매칭)
- 스크래퍼 재사용: `job_change/server/tools/discover_and_scrape.py`, `scrape_benefits.py`, `.claude/skills/parse-benefits/`
- 복지 9카테고리 분석: `job_change/benefit.md`
- 기존 비교 알고리즘 원형: `job_change/app.js` (compare/calc/getWSHours/getOTPay 등 — SPEC 05가 이식 명세)

## 6. 다른 PC에서 시작하는 법

```bash
git clone git@github.com:bji1062/loupit.git   # SSH 키가 GitHub에 등록돼 있어야 함
cd loupit
```
그다음 Claude에게: **"docs/RESUME.md 읽고 7단계 TASK부터 이어서 진행해줘."**

주의: 이전 세션 AI의 로컬 메모리는 넘어오지 않지만, 이 RESUME.md + `docs/` + git 로그로 맥락 복원 가능. RESEARCH 전략의 미결 이슈(OI-3 TTL 값 확정, OI-6 amt_source 백필 규칙 등)는 `docs/RESEARCH/benefit-scraping.md §8` 참고 — 구현 단계에서 결정 필요.

## 7. 미결 결정 (구현 전 확인 필요)

- OI-3: 카테고리별 만료 TTL 값 확정 (RESEARCH §4.3)
- OI-6: `amt_source` 백필 판별 규칙 (기존 `'(추정)'` 표기 → stated/estimated)
- 엔씨소프트 시드 메타(200 목록 밖) 확보 방법
- 그 외 RESEARCH §8 OI-4/5/7
