"""SP-API-1 + SP-AUTH-1 라우터 서브패키지.

익명 읽기(SP-API): health·reference·companies·trending.
참여(SC14, SP-AUTH-1): member·employment·benefit_edit (M9 표면 세그먼트 등록).

auth/oauth/profiler/comparisons/admin/landing 라우터는 영구 제외(레거시 델타) —
로그인 라우터 파일명 `auth` 는 금지하고 `member.py` 를 쓴다(T10).

운영(SP-AUTH-19, 2026-07-30): `console.py`(SSH 터널 전용 운영 콘솔). **`admin` 이라는 이름은
쓰지 않는다** — 그 라우터를 제거했다는 기록과 어긋나고, 경로 이름 하나로 봇의 스캔 목록에
들어간다. 이름이 다른 것은 우연이 아니라 계약이다(test_package 가 강제).
"""
