"""loupit 읽기 전용 API 서버 패키지 (SP-API-1).

레거시 델타: job_change/server의 auth·oauth·profiler·comparisons·admin·landing
라우터, JWT/SMTP 설정, 인증 미들웨어는 전부 제거됐다. 로그인/회원/프로파일러/
서버측 사용자 쓰기는 영구 제외(INV-1·INV-4, NFR16·NFR20).
"""
