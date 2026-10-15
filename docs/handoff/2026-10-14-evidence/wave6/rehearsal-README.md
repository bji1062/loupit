# 웨이브 6 운영 반영 리허설 (2026-10-14)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 새 시드 load.py (마이그레이션 없음). 스크립트 run.sh · 대조 cmp.py(결과 cmp.out)
- 결과: 총 복지 행 3,791 · 회사 173 (둘 다 기대와 같음)
- 13사: 새 시드와 전 필드(명칭·금액·카테고리·NOTE·정성여부·서술·SORT) 불일치 0 · 행 수 = 시드 행 수(321) · 배지 전부 official · 금액 출처 stated 1(현대위아) / estimated 2(빙그레 · SFA반도체) / none 318 (감사 §3-0과 같음)
- 나머지 160사: 행 3,470 → 3,470 (사라짐 0 · 생김 0) · 내용 변화 0 · 확인일 · 만료 변화 0
- TCOMPANY: 13사 CAREERS_BENEFIT_URL · WORK_STYLE_VAL 은 out/company-after.tsv (대웅 cond flex+remote 조건부 · 에스원 cond remote 조건부 · 현대위아 remote 맨 칩 · 감사 §11 과 일치) · 13사 밖 변화 0
- 적재 통계: stated 57 · estimated 397 · none 3335 · verified 321 · corp_mapped 172 · member_restored 2
- 적재 로그 경고 줄: `meta fallback`(200-seed 미매칭 — 자기명 별칭만 시드) 다수(기존 회사 포함, 13사 모두 해당) · `[load_corp] UNMAPPED 건너뜀: CJ올리브영`(기존) · `[load_corp] ⚠ comp_id 드리프트 74건`(기존 성격) — 그 밖 경고 0
- corp 확인(load_corp.py 별도 실행, OpenDART 호출 없음): TCOMPANY_CORP 172 · TCORP 171 · 13사 TCORP.CORP_NM = 표시명(DART 정식명) 13/13 · 전부 general / CFS
