# 웨이브 7 운영 반영 리허설 (2026-10-14)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 새 시드 load.py (마이그레이션 없음). run.sh · cmp.py(결과 cmp.out)
- 결과: 총 복지 행 4,355 · 회사 195 (감사 SD-4 · SD-3 과 같음)
- 22사: 새 시드와 전 필드(명칭·금액·카테고리·NOTE·정성여부·서술·SORT) 불일치 0 · 행 수 = 시드 행 수(564) · 배지 전부 official · 금액 출처 stated 1(교보증권) / estimated 6 / none 557 (감사 §3-0 과 같음)
- 웨이브 6 13사(운영 DB 에는 아직 없음): 새 시드와 불일치 0 · 행 321
- 나머지 160사: 행 3,470 → 3,470 (사라짐 0 · 생김 0) · 내용 변화 0 · 확인일 · 만료 변화 0
- TCOMPANY: 22사 CAREERS_BENEFIT_URL 22/22 · WORK_STYLE_VAL 조건 칩 4사(HK이노엔 · 교보증권 remote 조건부 / 하나머티리얼즈 부서별 / 롯데렌탈 자녀돌봄)가 감사 §11 · SI-13c 와 일치
- 적재 통계: stated 58 · estimated 403 · none 3892 · verified 885 · corp_mapped 194 · member_restored 2
- 적재 로그 경고: `meta fallback` 다수(기존 성격) · `[load_corp] UNMAPPED 건너뜀: CJ올리브영`(기존) · `[load_corp] ⚠ comp_id 드리프트 96건`(기존 성격) — 그 밖 0
- corp: TCOMPANY_CORP 194 · TCORP 193 · 22사 TCORP.CORP_NM = 표시명 22/22 · 금융사 2(교보증권 · 코리안리)는 financial / CFS, 나머지 20사 general / CFS
