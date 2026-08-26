# staging/ — 미완성 화면 대기실

`web/` 는 곧 **라이브 도크루트**다(prod·beta nginx 둘 다 `root .../web`). 거기에 파일을
넣는 순간 프로덕션에 200 으로 공개된다 — "화면은 뜨는데 아무것도 동작하지 않는" 반배포
사고가 실제로 있었다(loupit.conf 133행 주석, 함정 ⑭ 계열).

그래서 **만들다 만 페이지·자산은 여기에 둔다.** 이 폴더는 도크루트 밖이라 nginx 설정을
하나도 바꾸지 않아도 손님에게 절대 보이지 않는다.

- 공개 스위치는 이동 한 줄이다: `git mv staging/새화면.html web/새화면.html`
  (필요하면 같은 PR 에서 nginx 클린 URL 블록도 함께 — release.sh 는 conf 를 배포하지
  않으므로(함정 ⑭) conf 변경은 서버 수동 배치가 따로 필요하다.)
- 라이브 전 미리보기가 필요하면 beta vhost 에 `location ^~ /staging/` 를 한 번만 추가
  (`infra/beta-test/login-test.html` 전례와 같은 패턴).
- 테스트(`*.test.js`)는 여기 두지 않는다 — 러너 글롭이 `web/**` 라 잡히지 않는다.
  테스트는 처음부터 `web/` 에, 페이지만 여기서 대기.
