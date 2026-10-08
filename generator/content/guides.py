"""generator/content/guides.py — 가이드 글 목록 정본 (SP-GUIDE-8, 2026-10-08).

`/guide` 목록 페이지가 이 튜플 하나에서 카드를 만든다. **다음 판(또는 새 글)이 늘면 여기 한 줄**이다 — 새 판은 새 스냅숏 파일
(`generator/data/guide/report-<판>.json`) + `REPORT_EDITIONS` 맨 앞에 한 줄 + 판별 문안(`content/guide_report_editions.py` 에 새 판 키) + 테스트 해시 한 줄.

규칙: 최신 먼저. 숫자를 문장에 박지 않는다(카드 설명의 숫자는 각 글의 스냅숏에서 채운다).
"""
from __future__ import annotations

LIST_H1 = "가이드"
LIST_TITLE = "가이드"  # <title> 은 접미(` | jobcho.wiki`)를 페이지 모듈이 붙인다
LIST_LEAD = "잡초위키 데이터로만 쓸 수 있는 글을 모아 둡니다."

LIST_ROUTE = "/guide"
LIST_PATH = "guide.html"

# A편 「복지 공개 현황」 판 — 최신 먼저. 판마다 스냅숏 JSON 이 있어야 한다.
REPORT_EDITIONS: tuple[str, ...] = ("2026-10",)

# D편 「데이터 안내」 — 고정 글 하나.
DATA_ROUTE = "/about/data"
DATA_CARD_DESC = "어디서 가져오고, 어떻게 나누고, 언제 다시 확인하는지 적어 둡니다."


def report_route(edition: str) -> str:
    return f"/guide/report-{edition}"


def report_path(edition: str) -> str:
    return f"guide/report-{edition}.html"
