"""비교 로그·트렌딩 라우터 (INV-1 개정 2026-07-14 — "실시간 비교 TOP 10").

- POST /comparisons/log: 익명 회사쌍 로그 1행. 저장은 comp_id 쌍 + 시각뿐 —
  사용자 식별자·IP·연봉 등 입력값은 받지도 저장하지도 않는다(FR-07 예외 한정).
  직접 입력 모드(comp_id 없음) 비교는 클라이언트가 전송 자체를 하지 않는다.
- GET /comparisons/trending: 최근 7일 쌍별 COUNT 상위 10. 인메모리 TTL 캐시
  (60s, reference/all과 동일 패턴)로 DB 반복 조회를 차단한다.

`server.database`는 모듈 참조로 호출한다(monkeypatch 테스트 가능성 —
companies.py와 동일 임의결정, SP-API-14.1).
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request, Response

from server import database
from server.config import get_settings
from server.models.comparison import CompareLogIn, TrendingResponse

router = APIRouter(tags=["comparisons"])

_CACHE_KEY = "comparisons_trending"

_SQL_PAIR_EXISTS = "SELECT COMP_ID AS comp_id FROM TCOMPANY WHERE COMP_ID IN (%s, %s)"

# 윈도우·상한은 settings(trending_window_days·trending_limit)에서 주입 —
# SQL 텍스트에는 %s 바인딩만 둔다(원시 SQL 규약, SP-API-3).
_SQL_TRENDING = """
  SELECT l.A_COMP_ID AS a_comp_id, ca.COMP_NM AS a_comp_nm,
         l.B_COMP_ID AS b_comp_id, cb.COMP_NM AS b_comp_nm,
         COUNT(*) AS cnt
    FROM TCOMPARE_LOG l
    JOIN TCOMPANY ca ON ca.COMP_ID = l.A_COMP_ID
    JOIN TCOMPANY cb ON cb.COMP_ID = l.B_COMP_ID
   WHERE l.INS_DTM >= NOW() - INTERVAL %s DAY
   GROUP BY l.A_COMP_ID, l.B_COMP_ID, ca.COMP_NM, cb.COMP_NM
   ORDER BY cnt DESC, MAX(l.INS_DTM) DESC
   LIMIT %s"""


@router.post("/comparisons/log", status_code=204)
async def log_comparison(body: CompareLogIn) -> Response:
    rows = await database.fetch_all(_SQL_PAIR_EXISTS, (body.a, body.b))
    found = {r["comp_id"] for r in rows}
    if found != {body.a, body.b}:  # 미등록 comp_id → 로그 거부(FK 오류를 404로 선제 변환)
        raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")
    await database.insert_compare_log(body.a, body.b)
    return Response(status_code=204, headers={"Cache-Control": "no-store"})


@router.api_route("/comparisons/trending", methods=["GET", "HEAD"], response_model=TrendingResponse)
async def trending_comparisons(request: Request, response: Response) -> dict:
    s = get_settings()
    cache = request.app.state.trending_cache

    async def _build():  # 캐시 미스(dogpile 락 하) 1회만 집계 조회
        return await database.fetch_all(_SQL_TRENDING, (s.trending_window_days, s.trending_limit))

    # 60s 만료 경계 동시요청의 중복 집계를 asyncio.Lock 이중검사로 억제(low#2).
    # 집계 0건([])도 캐시된다(빈 목록은 위젯이 숨김 처리 — 오류 아님).
    items = await cache.get_or_set(_CACHE_KEY, _build)
    response.headers["Cache-Control"] = s.trending_cache_control
    return {"items": items}
