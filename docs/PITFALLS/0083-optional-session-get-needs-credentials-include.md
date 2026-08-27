# "익명 GET" 이라도 응답에 회원 필드가 있으면 credentials:'omit' 으로 부르면 안 된다

**발견**: 2026-08-27 레인 B(커뮤니티 프론트) — `getPost`·`getComments` 를 지시대로 `apiFetch`(익명) 로 짜다가.
**증상(예방)**: 본인 글인데 수정·삭제 버튼이 영영 안 뜨고, 좋아요를 눌러도 눌린 상태가 복원되지 않는다.
테스트는 전부 초록이다 — 픽스처가 `is_mine:true` 를 그냥 돌려주기 때문에.

## 무엇이 잘못됐나

FRD/14 FR-122·123 은 상세·댓글 GET 을 **익명 경로**로 정의하면서도 `is_mine`·`liked` 를 싣는다 —
"세션 쿠키가 **동봉되면** 읽는다(`optional_member`, 401 안 냄)". 그런데 `api.js` 의 `apiFetch` 는
`credentials:'omit'` 이 계약이다(INV-1: 익명 표면은 무쿠키). 이 둘을 그대로 붙이면 브라우저가
쿠키를 **절대 보내지 않으므로** 서버는 항상 비회원으로 판정하고, 회원 필드는 항상 false 다.
서버도 옳고 클라이언트도 옳은데 조합이 틀린다.

## 교훈

- 응답 계약에 **"세션이 있을 때만 참"인 필드**가 있으면 그 GET 은 익명 GET 이 아니다. 무쿠키
  `apiFetch` 가 아니라 credentialed `apiSend('GET', …)` 로 불러야 한다(`getBenefitsForEdit` 전례).
  세션이 없어도 서버가 401 을 내지 않으니 익명 열람은 그대로다.
- 픽스처가 `is_mine:true` 를 돌려주는 테스트는 이 구간을 검증하지 못한다. 전송 옵션
  (`credentials:'include'`)을 **직접** 단정하라 — `api.test.js` "getPost → credentialed" 가 그 가드다.
- 문서 지시("열람 3종 = apiFetch")와 응답 계약이 어긋나면 계약이 이긴다. 지시는 요약이고 계약은 정본이다.
