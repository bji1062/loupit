# 웨이브 5 운영 반영 리허설 (2026-10-10)

- 운영 참조 9테이블 읽기 전용 덤프 → loupit_test(그 스키마 테이블만 비움) → 워크트리 새 시드 load.py (마이그레이션 없음). 스크립트 run.sh · 대조 cmp.py
- 결과: 총 복지 행 3,472 · 회사 160 (둘 다 기대와 같음)
- 13사: 새 시드와 전 필드(명칭·금액·카테고리·NOTE·정성여부·서술·SORT) 불일치 0 · 행 수 = 시드 행 수(293) · 배지 전부 official · 금액 출처 stated 0 / estimated 4(오뚜기 1 · 한온시스템 1 · ISC 1 · 코스맥스 1) / none 289 (감사 §3과 같음)
- 나머지 147사: 행 3,179 → 3,179 (사라짐 0 · 생김 0) · 내용 변화 0 · 확인일 · 만료 변화 0
- TCOMPANY: 13사 CAREERS_BENEFIT_URL · WORK_STYLE_VAL 은 out/company-after.tsv (오리온 cond remote 조건부 · 감사 §11 과 일치) · 13사 밖 변화 0
- 적재 통계: stated 56 · estimated 395 · none 3019 · verified 293 · corp_mapped 159 · member_restored 2
- 적재 로그 경고 줄: `meta fallback`(200-seed 미매칭 — 자기명 별칭만 시드) 다수(기존 회사 포함, 13사 모두 해당) · `[load_corp] UNMAPPED 건너뜀: CJ올리브영`(기존) · `[load_corp] ⚠ comp_id 드리프트 61건`(기존 성격) — 그 밖 경고 0
- corp 확인(load_corp.py 별도 실행, OpenDART 호출 없음): TCOMPANY_CORP 159 · TCORP 158 · KCC TCORP.CORP_NM 케이씨씨 · 코오롱인더스트리 코오롱인더 · 현대해상 financial (오뚜기 general)
