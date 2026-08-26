# db/seed/legacy200/ — 200-seed 동봉 위치 (⚠ 현재 비어 있음 — 서버에서 복사 필요)

시드 파이프라인(`load.py` → `company_meta.build_company_meta`)의 **입력 데이터**인
KOSPI/KOSDAQ 200개 회사 메타 4파일이 지금까지 배포 호스트의 레거시 리포
(`/home/ubuntu/job_change/server/seed/`)에만 존재했다 — 저장소엔 한 번도 커밋된 적이
없어, fresh clone·CI 에서 백엔드 시드 테스트 67개가 `FileNotFoundError` 로 전멸했다
(함정 74 '서버 유령' 부류의 두 번째 실증, 2026-08-26 CI 첫 실행에서 검출).

**서버에서 한 번만 실행하고 커밋하라:**

```bash
cp /home/ubuntu/job_change/server/seed/companies_kospi_1.py \
   /home/ubuntu/job_change/server/seed/companies_kospi_2.py \
   /home/ubuntu/job_change/server/seed/companies_kosdaq_1.py \
   /home/ubuntu/job_change/server/seed/companies_kosdaq_2.py \
   db/seed/legacy200/
git add db/seed/legacy200/ && git commit && git push
```

- 내용은 큐레이션된 공개 데이터(회사명·별칭·업종)다 — 비밀 없음, 보존 대상(README §데이터 보존).
- `company_meta._resolve_seed200_dir()` 가 **이 디렉터리를 레거시 경로보다 우선**한다.
  4파일이 모두 있으면 자동 채택, 없으면 종전 절대경로 폴백(서버 동작 불변).
- 명시 지정이 필요하면 `LOUPIT_SEED200_DIR=<경로>` 환경변수.
