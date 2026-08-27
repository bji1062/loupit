"""generator/sector.py — 히트맵 그룹 기준: KRX 업종 분류 (SP-HEAT-2, 2026-08-27).

**왜 우리 `INDUSTRY_NM` 이 아닌가.** 회사 업종은 67종 자유 텍스트라 1곳짜리 업종이 51개다 —
그대로 묶으면 "같은 업종 안에서 비교"라는 히트맵의 효용이 사라진다(계획 §3 비교판 3종 실측).
임의 대분류는 사람이 정한 매핑이라 검수가 따라붙는다. **거래소 공식 업종 분류**는 종목코드로
자동 매칭되고(102곳 중 100곳), 원 업종은 툴팁·상세에 그대로 남는다. prober.kr 히트맵과 같은 기준.

**정본은 `generator/data/krx_sector.csv`** — `stock_cd, corp_nm, sector_nm, market`. 상장사만 있고
비상장(CJ올리브네트웍스·CJ올리브영)은 `UNLISTED` 그룹으로 간다. 갱신은 수동(분기 1회면 충분 —
업종 재분류는 드물다). DB 컬럼을 두지 않는 이유: 소비처가 이 페이지 하나라 스키마(핫스팟)를
건드릴 이유가 없다 — `combinations.json` 과 같은 빌드타임 파일 정본 관례.
"""
from __future__ import annotations

import csv
from pathlib import Path

SECTOR_CSV = Path(__file__).resolve().parent / "data" / "krx_sector.csv"
UNLISTED = "비상장"


def load_sectors(path: Path = SECTOR_CSV) -> dict[str, str]:
    """`{stock_cd: sector_nm}`. 빈 행·헤더만 있는 파일은 빈 dict(예외 아님 — 히트맵은 전부
    '비상장' 그룹 하나로 그려지고, 그 상태는 테스트가 잡는다)."""
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    with open(path, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            code = (row.get("stock_cd") or "").strip()
            sector = (row.get("sector_nm") or "").strip()
            if code and sector:
                out[code] = sector
    return out


def sector_of(fin: dict | None, sectors: dict[str, str]) -> str:
    """회사의 재무 매핑(`FinanceView`)에서 종목코드를 꺼내 업종을 찾는다. 매핑이 없거나
    비상장(STOCK_CD NULL)·CSV 에 없는 코드는 `비상장`. 추측으로 채우지 않는다."""
    if not fin:
        return UNLISTED
    code = (fin.get("stock_cd") or "").strip()
    return sectors.get(code, UNLISTED) if code else UNLISTED
