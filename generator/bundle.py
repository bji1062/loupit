"""generator/bundle.py — 번들 단일 소스 소비 (SP-GEN-1.2).

런타임 API(`server/routers/reference.py`)와 **동일 함수**
`build_reference_bundle`을 호출한다(SP-API-7 단일 소스, 재정의 금지).
시그니처는 async이므로 빌드타임은 `asyncio.run`으로 구동한다. 테스트는
`load_bundle_json`으로 dict를 직접 주입한다(DB 무경유).

재무(SP-FIN-4, 2026-08-27)와 직원 현황(SP-MET-8, 2026-08-28)은 **번들 dict 밖**에서
`generator/finance.py::load_finance` · `generator/employ.py::load_employ` 로 같은 커넥션에서 함께
읽는다 — 번들에 키를 더하면 런타임 API 응답·Pydantic 화이트리스트·클라이언트 정규화가 같이
움직인다(함정 (55)). `--bundle-json` 의 짝은 `--finance-json`·`--employ-json`.

⚠ 셋을 **한 커넥션**에서 읽는 이유는 같은 시점의 DB 를 보기 위해서다. 수집기가 도는 중에 빌드가
겹치면 재무는 새 연도, 직원은 옛 연도인 페이지가 나오고 그건 아무 에러도 남기지 않는다.
"""
from __future__ import annotations

import asyncio
import json

from generator.employ import load_employ
from generator.employ import normalize as employ_normalize
from generator.finance import load_finance
from server.config import get_settings
from server.services.reference import build_reference_bundle


async def _load_async(with_metrics: bool = False):
    import aiomysql  # 지연 import — DB 미경유 테스트 경로에서 불필요한 의존 회피

    s = get_settings()
    conn = await aiomysql.connect(
        host=s.db_host,
        port=s.db_port,
        user=s.db_user,
        password=s.db_password,
        db=s.db_name,
        charset="utf8mb4",
        cursorclass=aiomysql.DictCursor,
    )
    try:
        bundle = await build_reference_bundle(conn)  # 최상위 3키(INV-2)
        if not with_metrics:
            return bundle
        finance = await load_finance(conn)  # 같은 커넥션 — 번들과 같은 시점의 DB 를 본다
        employ = await load_employ(conn)
        return bundle, finance, employ
    finally:
        conn.close()


def load_bundle() -> dict:
    """빌드타임 진입(DB 조회). 반환 = {company_types[], benefit_presets{}, companies[…]}."""
    return asyncio.run(_load_async())


def load_bundle_with_metrics() -> tuple[dict, dict, dict]:
    """번들 + 회사별 재무 + 회사별 직원 현황 — build.py 의 DB 경로. 번들 dict 는 위와 동일하다.

    반환 `(bundle, finance, employ)`. 셋 다 **한 커넥션·한 시점**이다(모듈 머리말 참고).
    """
    return asyncio.run(_load_async(with_metrics=True))


def load_bundle_json(path: str) -> dict:
    """사전 덤프된 번들 JSON 로드 — DB 없이 렌더(CI·오프라인·재현)."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_finance_json(path: str) -> dict[int, dict]:
    """사전 덤프된 재무 JSON 로드(`--finance-json`). JSON 은 키를 문자열로 떨어뜨리므로 int 로 되돌린다."""
    with open(path, encoding="utf-8") as f:
        return {int(k): v for k, v in json.load(f).items()}


def load_employ_json(path: str) -> dict[int, dict[int, dict]]:
    """사전 덤프된 직원 현황 JSON 로드(`--employ-json`).

    재무는 한 겹이라 `int(k)` 한 번이면 됐지만 직원 현황은 **두 겹**(comp_id → 연도)이다. 바깥만
    되돌리면 연도가 문자열로 남아 정렬이 사전순이 되고 전년 대비가 조용히 사라진다 —
    되돌리는 규칙은 `employ.normalize` 하나뿐이므로 여기서도 그것을 부른다.
    """
    with open(path, encoding="utf-8") as f:
        return employ_normalize(json.load(f))
