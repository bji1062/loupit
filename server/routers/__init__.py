"""SP-API-1 + SP-AUTH-1 라우터 서브패키지.

익명 읽기(SP-API): health·reference·companies·trending.
참여(SC14, SP-AUTH-1): member·employment·benefit_edit (M9 표면 세그먼트 등록).

auth/oauth/profiler/comparisons/admin/landing 라우터는 영구 제외(레거시 델타) —
로그인 라우터 파일명 `auth` 는 금지하고 `member.py` 를 쓴다(T10).
"""
