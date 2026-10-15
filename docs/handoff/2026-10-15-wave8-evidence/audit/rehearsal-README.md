# 웨이브 8 운영 반영 리허설 (2026-10-15)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 새 시드 load.py (마이그레이션 없음). run.sh · cmp.py(결과 cmp.out)
- 결과: 총 복지 행 4,897 · 회사 218 (감사 SD-4 · SD-3 과 같음)
- 23사: 새 시드와 전 필드 불일치 0 · 행 수 = 시드 행 수(542) · 배지 전부 official · 금액 출처 stated 4 / estimated 12 / none 526
- 대기분 웨이브 6 · 7 35사(운영 DB 에는 아직 없음): 새 시드와 불일치 0 · 행 885
- 나머지 운영 160사: 행 3,470 → 3,470 (사라짐 0 · 생김 0) · 확인일 · 만료 변화 0 · 내용 변화 86행 = 웨이브 7 코퍼스 정리(서술 「항목명 그대로」 84행 + HL만도 2행) — 이번 웨이브 밖 대기분
- TCOMPANY: 23사 CAREERS_BENEFIT_URL 23/23 · WORK_STYLE_VAL 조건 칩 5사(포스코DX · 한국카본 · 한화투자증권 · DL이앤씨 · NICE평가정보) = 감사 §11 · SI-13c
- corp: TCOMPANY_CORP 217 · TCORP 216 · 23사 TCORP.CORP_NM = 표시명 22/23 (에스에프에이만 DART 명 SFA — 의도) · 금융 3사 financial / CFS
- 적재 로그 경고: meta fallback 다수(기존 성격) · UNMAPPED CJ올리브영(기존) · comp_id 드리프트 119건(기존 성격) — 그 밖 0
