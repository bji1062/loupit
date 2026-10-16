# 웨이브 11(붙여넣기 1차) 운영 반영 리허설 (2026-10-16)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 paste1 새 시드 load.py (마이그레이션 없음). run.sh · cmp.py(결과 cmp.out)
- 결과: 총 복지 행 5,759 · 회사 257 (감사 SD-4 · SD-3 과 같음)
- 5사: 새 시드와 전 필드 불일치 0 · 행 수 = 시드 행 수(94) · 배지 전부 official · 금액 출처 stated 1(케이뱅크) / estimated 3(한화손해보험 1 · 쎄트렉아이 2) / none 90 (감사 §3 과 같음)
- 대기분 없음. 나머지 운영 252사: 행 5,665 → 5,665 (사라짐 0 · 생김 0) · 확인일 · 만료 변화 0 · 내용 변화 0
- TCOMPANY: 5사 CAREERS_BENEFIT_URL 5/5 · WORK_STYLE_VAL = 감사 §11 (조건 칩 케이뱅크 remote 조건부 1사 · 나머지 맨 칩 값 일치)
- corp: TCOMPANY_CORP 256 · TCORP 255 (감사 FN-1) · 5사 TCORP.CORP_NM = 표시명 5/5 · FS_DIV_CD 전부 CFS(케이뱅크 OFS 전환은 공개 뒤 리드 — 감사 MED-1) · ACCT_SET_CD 케이뱅크 · 한화손해보험 financial
- 적재 로그 경고: meta fallback 다수(기존 성격) · UNMAPPED CJ올리브영(기존) · comp_id 드리프트 158건(웨이브 10 리허설 153건 + 5) — 그 밖 0
