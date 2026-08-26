# db/seed/legacy200/ — 별칭 승계 소스 동봉 위치 (⚠ 현재 비어 있음 — 서버 1회 작업 필요)

시드 파이프라인(`load.py` → `company_meta.build_company_meta`)의 별칭 승계 입력이
지금까지 **은퇴한 레거시 리포**(`/home/ubuntu/job_change/server/seed/`)의 200-seed
4파일이었다 — 저장소에 커밋된 적이 없어 fresh clone·CI 에서 백엔드 시드 테스트 67개가
`FileNotFoundError` 로 전멸했다(함정 74 '서버 유령' 부류, 2026-08-26 CI 첫 실행 검출).

파이프라인이 그 파일들에서 실제로 쓰는 필드는 **name·aliases 둘뿐**이고, 그 정보의
현행 정본은 서빙 DB(TCOMPANY + TCOMPANY_ALIAS)다. 그래서 job_change 없이 복구한다.

**서버(`/home/ubuntu/loupit`)에서 한 번만:**

```bash
python3 db/seed/legacy200/export_from_db.py     # 서빙 DB 읽기만 → seed200.py 생성
git add db/seed/legacy200/seed200.py
git commit -m "data: 별칭 승계 소스 동봉(seed200.py) — 서빙 DB 도출, job_change 은퇴"
git push origin claude/service-intro-document-gdyrf2
```

- 커밋되면 `company_meta` 가 **이 동봉본을 최우선 채택**하고, job_change 는 어떤
  경로에서도 더는 필요 없다(레거시 폴백은 도달 불능 코드로 남는다).
- 별칭 추가·수정은 이 파일 직접 편집이 아니라 override(`company_meta.py`) 또는
  DB 갱신 후 재도출로 한다(파일 머리말 참조).
- (대안) 만약 job_change 디렉터리가 아직 남아 있다면 원본 4파일
  (`companies_{kospi,kosdaq}_{1,2}.py`)을 여기 복사해도 동작하지만, **도출 방식을
  권장한다** — DB 쪽이 그간의 수동 별칭 추가까지 반영된 최신본이다.
