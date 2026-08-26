# 🚨 생성물 무시 패턴이 소스까지 먹으면, 그 파일은 서버에만 존재하는 유령이 된다

`.gitignore` 의 `sitemap.xml`(생성물 무시용 베어 패턴)이 소스 템플릿
`generator/templates/sitemap.xml` 까지 매치했다. 결과: 템플릿이 **한 번도
커밋된 적 없이** 배포 호스트 디스크에만 존재했고, fresh clone(새 세션·CI)
에서는 `TemplateNotFound` 로 생성기 테스트 13개가 깨지고 실빌드도 불능이었다.
서버 한 곳에서만 일하는 동안에는 절대 드러나지 않는 부류의 결함이다.

- **탐지**: 새 환경에서 전체 스위트를 돌리는 것 자체가 탐지기다(CI 도입 첫날 발견).
  의심되면 `git check-ignore -v <소스경로>` 로 어떤 패턴이 먹었는지 즉시 확인.
- **수정**: 템플릿 복원 + `.gitignore` 에 `!generator/templates/sitemap.xml` 예외(`d8139be`).
- **교훈**: 생성물 무시는 베어 이름(`sitemap.xml`)이 아니라 **출력 경로 앵커**
  (`/web/dist` 처럼)로 걸어라. 베어 패턴은 트리 전체의 동명 파일을 전부 먹는다.
- **관련**: 함정 ⑭(release.sh 는 conf 를 배포하지 않는다)와 같은 과 — "서버와
  저장소가 같은 내용이라는 믿음"이 검증 없이 유지되는 지점들.

## 두 번째 실증 (같은 날, 같은 부류): 시드 입력이 레거시 리포 절대경로였다

`db/seed/company_meta.py` 가 200-seed 4파일을 `/home/ubuntu/job_change/server/seed`
(배포 호스트의 레거시 리포)에서 직접 읽었다 — 시드 파이프라인의 **입력 데이터가
저장소 밖**이라, CI 첫 실행에서 백엔드 시드 테스트 67개가 `FileNotFoundError` 로
전멸했다. 수정: 해석 순서를 `LOUPIT_SEED200_DIR` env → 리포 동봉 `db/seed/legacy200/`
→ 레거시 폴백으로 바꾸고, 동봉 절차를 `legacy200/README.md` 에 남겼다(서버에서 4파일
복사·커밋 1회 필요).

**부류의 정의가 넓어졌다**: "서버에만 있는 파일"은 gitignore 오매치만이 아니라
**절대경로 참조**로도 생긴다. 새 코드가 `/home/ubuntu/...` 를 읽는 순간 그 파일은
유령 후보다 — fresh clone 에서 전체 스위트를 돌리는 것(=CI)이 유일한 탐지기다.
