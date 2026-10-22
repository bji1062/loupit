#!/usr/bin/env python3
"""히트맵 「서버 그림 = 브라우저 그림」 대조 픽스처(`heatmap_panel_cases.json`)를 만든다.

왜: 첫 화면에는 복지 지도만 Jinja(`_hm_maps.html`)로 굽고, 나머지 패널은 데이터 파일을 `heatmap.js buildMaps`
가 DOM 으로 다시 그린다. 둘이 따로 자라 갈라지면 같은 지도가 탭에 따라 다르게 보인다. 이 픽스처는 작은
번들 한 벌에서 「Jinja 가 구운 패널 마크업(`html`)」과 「같은 패널의 데이터 파일(`data`)」을 함께 담아
두 쪽이 같은 기대값을 재게 한다 — 파이썬(`generator/tests/test_heatmap.py`: 픽스처가 지금 템플릿·`panel_data` 와
같은가)과 JS(`web/assets/js/heatmap.test.js`: 데이터로 그린 결과가 `html` 과 같은가)가 함께 읽는다.
템플릿 · panel_data · buildMaps 중 하나를 바꾸면 이 스크립트로 다시 뽑는다 — 손으로 고치지 마라.

사용:
    python3 generator/tests/data/make_heatmap_cases.py
"""
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from generator.context import build_context  # noqa: E402
from generator.pages import heatmap  # noqa: E402
from generator.render import make_env  # noqa: E402
from generator.tests.fixtures import FAKE_BUNDLE, FAKE_FINANCE  # noqa: E402

OUT = Path(__file__).resolve().parent / "heatmap_panel_cases.json"
SECTORS = {"005930": "전기·전자", "035420": "IT 서비스", "035760": "오락·문화"}  # test_heatmap.py 와 같은 표
NOTE = (
    "heatmap.js buildMaps(데이터 파일)이 _hm_maps.html(Jinja)과 같은 마크업을 그리는지 재는 픽스처. 패널마다 "
    "`html`(Jinja 가 구운 지도 마크업) · `data`(heatmap.panel_data 가 낸 데이터 파일). generator/tests/test_heatmap.py 와 "
    "web/assets/js/heatmap.test.js 가 함께 읽는다. 템플릿·panel_data·buildMaps 를 바꾸면 "
    "generator/tests/data/make_heatmap_cases.py 로 다시 뽑아라 — 손으로 고치지 마라."
)


def build_cases() -> dict:
    ctx = build_context(copy.deepcopy(FAKE_BUNDLE), finance=copy.deepcopy(FAKE_FINANCE))
    view = heatmap.build_view(ctx, SECTORS)
    macro = make_env().get_template("_hm_maps.html").module.maps
    panels = []
    for m in view["modes"]:
        for p in m["panels"]:
            panels.append({"mode": m["key"], "panel": p["key"], "html": str(macro(p)), "data": heatmap.panel_data(p)})
    # 합성 패널 하나: 가짜 번들의 그룹은 전부 넓어서 「좁은 그룹」(narrow)·비상장·큰 좌표가 안 나온다 — 무게를 크게
    # 갈라 그 분기를 픽스처에 싣는다(JS 가 이 분기를 빼먹어도 위 실제 패널만으로는 안 잡힌다).
    cs = ctx.companies
    items = [{"c": cs[0], "sector": "큰 그룹", "weight": 1000, "cls": "s-stated", "anchor": "b-meal", "sub": "100만원", "tip": "큰 칸 · 100만원 · 회사 공식 수치"},
             {"c": cs[1], "sector": "작은 그룹", "weight": 3, "cls": "s-est", "anchor": "", "sub": "3만원", "tip": "작은 칸"},
             {"c": cs[2 % len(cs)], "sector": heatmap.UNLISTED, "weight": 1, "cls": "s-qual", "anchor": "", "sub": "금액 없음", "tip": "최소 칸 \"따옴표\" & <꺾쇠>"}]
    syn = {"key": "synthetic", "layouts": heatmap._panel_layouts(items, ctx)}
    panels.append({"mode": "x", "panel": "synthetic", "html": str(macro(syn)), "data": heatmap.panel_data(syn)})
    return {"_note": NOTE, "panels": panels}


if __name__ == "__main__":
    OUT.write_text(json.dumps(build_cases(), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(build_cases()['panels'])} 패널")
