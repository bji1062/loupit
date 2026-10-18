# 웨이브 12 운영 반영 리허설 (2026-10-18)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 wave12 새 시드 load.py (마이그레이션 없음). run.sh · cmp.py(결과 cmp.out)
- 결과: 총 복지 행 6,215 · 회사 275 (감사 SD-4 · SD-3 과 같음)
- 18사: 새 시드와 전 필드 불일치 0 · 행 수 = 시드 행 수(456) · 배지 전부 official · 금액 출처 stated 1(동아에스티) / estimated 4(DB하이텍 · KG모빌리티 · SM엔터테인먼트 · 넥센타이어) / none 451 (감사 §3 과 같음)
- 대기분 없음. 나머지 운영 257사: 행 5,759 → 5,759 (사라짐 0 · 생김 0) · 확인일 · 만료 변화 0 · 내용 변화 0 · TCOMPANY 기존 257사 변화 0
- TCOMPANY: 18사 CAREERS_BENEFIT_URL 18/18 https · WORK_STYLE_VAL = 감사 §11 (조건 칩 매일유업 flex 조건부 · 대상 flex 부서별 2사)
- 메일: 전용 14 + 롯데 그룹 줄(롯데하이마트) = 15행
- corp: TCOMPANY_CORP 274 · TCORP 273 (감사 FN-1) · TCORP.CORP_NM = 표시명 17/18 + SM엔터테인먼트 「에스엠」 · FS_DIV_CD 전부 CFS(롯데하이마트 OFS 전환은 공개 뒤 리드 — 감사 MED-1) · ACCT_SET_CD 18/18 general
- 적재 로그 경고: meta fallback 다수(기존 성격) · UNMAPPED CJ올리브영(기존) · comp_id 드리프트 176건(웨이브 11 리허설 158건 + 18) — 그 밖 0
