# 웨이브 5 통합 계약 v2 (W-3 · Sonnet · 판단 없음) — 2026-10-10

**너의 역할:** 감사(`W5/audit/integration-audit.md` §5 · §9)가 이미 확정한 조치를 수집본 N파일에 **행 단위로 그대로 집행**해 최종 시드를 쓴다. 코딩 작업이고 판단은 하지 않는다(사용자 지시 2026-10-01 모델 분업 — 생각 · 검증 Opus, 코드 · SQL 작성 Sonnet).
- 아래 경우에만 그 파일을 손대지 말고 「보류」로 보고한다: 조치끼리 충돌할 때 · §5 의 문장이 둘 이상으로 읽힐 때 · 점검이 계약에 없는 이유로 깨질 때. **계약에 없는 해결책을 만들지 않는다.** 목록에 없는 개선 · 정리 · 문구 다듬기도 하지 않는다(W4 통합 계약 · R-1 통합 계약).
- 「리드 판정 필요」로 남은 것은 집행하지 않고 보고한다.

`W5` = `/home/ubuntu/loupit-evidence/2026-10-10-wave5`. `<WORKTREE>` = 리드가 프롬프트로 주는 git worktree 의 절대경로(예: `/home/ubuntu/loupit/.claude/worktrees/wave5`). 아래의 모든 `<WORKTREE>` 를 그 경로로 바꿔 읽는다.

## 쓰는 곳 — worktree 의 시드 폴더만

- **출력:** `<WORKTREE>/db/seed/benefit/sql/<파일명>.sql` N개(새 파일 — 파일명은 수집본과 같다. 목록은 리드 프롬프트와 감사 §0).
- 🚨 **본체 체크아웃 `/home/ubuntu/loupit` 의 파일은 고치지 않는다.** 본체의 `web/assets` 는 라이브 docroot 다(저장 = 즉시 운영 — 2026-07-20 사고). 모든 쓰기는 `<WORKTREE>` 안의 시드 폴더에만.
- **건드리지 않는 것**(전부 리드가 한다): worktree 의 다른 파일(테스트 핀 · `company_registrations.json` · `corp_code_map.csv` · `krx_sector.csv` · `company_meta.py` 별칭 · `company_email_domain.sql` · `generator/data/benefit_pages/*.json` · `row_marks.json` · 어휘표) · 기존 코퍼스 147파일 · git commit · push · 테스트 게이트 실행. 리드가 별도 계약으로 이 중 일부를 맡기면 그 계약을 따른다.
- **금지:** 운영 DB · `loupit_test` 접속 · 수집본(`W5/collect/`) 수정 · 모의본(`W5/audit/sim/`) 수정.

## 입력

| 무엇 | 경로 |
|---|---|
| 수집본(읽기만 — 출발점) | `W5/collect/<파일명>.sql` |
| **조치 정본** | `W5/audit/integration-audit.md` §5(회사별 조치 · 헤더 한 줄 · 추가 튜플) · §9(대체 문안) |
| 참고만(집행하지 않음) | `W5/verify/<파일명>.verify.md` — 감사가 기각한 검증 권고는 집행하지 않는다 |
| 형식 정본 | `W5/_COLLECT-CONTRACT.md` §2(머리말 · 다섯 문장 · 행 · SORT · 따옴표 · 필드 길이) |
| 감사 모의본(비교용 — 아래 6 이후에만 연다) | `W5/audit/sim/<파일명>.sql` |

## 집행 규칙

1. **적힌 것만 바꾼다.** 필드 교체 · 재코딩 · 삭제 · 병합 · 추가는 §5 에 적힌 대로. 적히지 않은 필드는 수집본의 글자 그대로 둔다(R-1 통합 계약 1).
   - 특히 금액 행 NOTE 의 「추정」 · 「환산」 · 식대 꼬리 `(하루 N끼 × 1끼 12,000원 × 연 240일 추정)` 는 그대로 둔다. 빠지면 적재 때 「회사 공식 수치」로 올라간다(`derive_amt_source`).
   - 「(그룹 통합 채용 기준)」 · 「○○그룹 공통 문구」 · 「(○○컴퍼니 공통 채용 기준)」 각주는 귀속의 전제라 **절대 지우지 않는다**(W4 통합 계약 4).
2. **추가 행은 §5 가 준 VALUES 튜플을 글자 그대로** 넣는다. SORT 도 준 값. 그 밖의 새 행은 금지다(MISSED 도 §5 가 튜플이나 「병합」으로 준 것만).
3. **삭제는 튜플을 통째로 뺀다.** SORT 를 다시 매기지 않는다(구멍 허용). 마지막 행의 `,` / `;` 처리로 문법을 깨지 않는다. 빈 줄을 남기지 않는다.
4. **병합**은 남는 행의 서술에 §5 가 준 원문 구절을 덧붙인다(구분은 「, 」 또는 「 · 」 — 「/」 금지). 「 — 」 꼬리는 서술 맨 끝 **하나**만 남게 한다(SI-11).
5. **재코딩**은 코드 · 카테고리 · SORT 를 §5 가 준 값으로 함께 옮긴다(카테고리별 10단위 섹션).
6. **AMT NULL** 은 §5 가 준 모양대로: 금액 `NULL` · `QUAL_YN TRUE` · 서술을 NOTE 에서 QUAL_DESC 로 옮긴 새 글자 · NOTE `NULL`.
7. **따옴표를 새로 넣지 않는다.** 홑 · 겹따옴표 모두 금지(주석 포함 — 분할기가 주석을 모른다). 아포스트로피가 필요하면 U+2019 ’.
8. **헤더:** 머리말의 `-- 참고:` 블록 끝(닫는 `-- ━━━` 줄 바로 위)에 §5 가 준 한 줄(`-- 검증 · 감사 판정 반영(<날짜>): …`)을 붙인다. `-- 출처: AI 파싱 (…)` · `-- URL: …` 두 줄과 나머지 주석 줄은 그대로 둔다(백필 정규식이 읽는다).
9. **독립 집행.** `W5/audit/sim/`(감사 모의본)은 N파일을 다 쓰고 아래 점검 (a)~(e) 를 마친 **뒤에만** 연다. 먼저 열어 베끼지 않는다 — §5 의 **글**과 감사의 **모델**이 같은 결과를 내는지 두 번 독립으로 집행해 보는 단계다(R-1 통합 계약 6).

## 점검 (다 쓴 뒤 순서대로 — 결과 줄을 보고에 붙인다)

- **(a) 행 점검** — `python3 /home/ubuntu/loupit-evidence/2026-10-10-wave5/_row_check.py <WORKTREE>/db/seed/benefit/sql/<파일명>.sql … --corpus <WORKTREE>/db/seed/benefit/sql` → `총 오류 0`. (분할기 5문장 · 셋째 문장 UPDATE · 머리말 두 줄 · slug · 표시명 충돌 0 · 카테고리 = 어휘표 · 코드 · SORT 중복 0 · 금액 행 모양 · 금액 출처 예측 · SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 · 따옴표.) `[확인]` 줄은 감사 §3 · §11 표와 같은지 본다.
- **(b) 필드 길이** — `python3 /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py <N파일>` → `0 violations`.
- **(c) 법정 문구 스캔** — `python3 /home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/_legal_scan.py <N파일>` → 총 행 · 검출 · 면제 수가 감사 §5 「검산」의 기대값과 같아야 한다.
- **(d) 행 수** — 회사별 행 수가 감사 §0 의 최종 열과 같아야 한다. 금액 출처 예측(stated / estimated 수)이 감사 §3 표와 같아야 한다.
- **(e) 감사 모델 대조** — `python3 /home/ubuntu/loupit-evidence/2026-10-10-wave5/audit/_audit.py check-seed <WORKTREE>/db/seed/benefit/sql` → 형식 문제 0 · 불일치 0. 불일치가 나오면 §5 를 다시 읽는다 — 네 집행이 틀렸으면 고친다. §5 의 글과 모델이 어긋나 보이면 고치지 말고 둘 다 「보류」에 적는다.
- **(f) 모의본 비교** — 이제 `diff /home/ubuntu/loupit-evidence/2026-10-10-wave5/audit/sim/<파일명>.sql <WORKTREE>/db/seed/benefit/sql/<파일명>.sql`. 주석 줄 위치와 빈 줄 말고 차이가 있으면 전부 보고한다.
- **(g) 범위** — `git -C <WORKTREE> status --short` 에 이번 N개 새 시드 파일만 보여야 한다(`??` N줄). 다른 줄이 있으면 보고한다.

## 보고 (최종 응답은 짧게)

- 회사별 최종 행 수 표와 합계(감사 §0 과 대조)
- 점검 (a)~(g) 결과 줄
- 보류 목록(없으면 「없음」) · 리드 판정 필요(없으면 「없음」)
- `git -C <WORKTREE> status --short` 출력
