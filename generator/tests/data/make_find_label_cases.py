#!/usr/bin/env python3
"""복지검색 대표 이름 공유 픽스처(`find_label_cases.json`)를 실서빙 번들에서 다시 뽑는다.

왜: 파이썬(정적 표, `generator/pages/find.py`)과 JS(칩, `web/assets/js/find.js`)가 코드 사전을 각자
만든다. 이 픽스처는 실데이터의 코드→이름 빈도표와 그때 나오는 대표 이름·별칭·카테고리 순서를 담아
두 구현을 **같은 기대값**으로 잰다(`generator/tests/test_find_page.py` · `web/assets/js/find.test.js`).
회사·복지가 크게 바뀌면(웨이브·재수집) 이 스크립트로 다시 뽑는다 — 손으로 고치지 마라.

사용:
    python3 generator/tests/data/make_find_label_cases.py              # 서빙 DB 에서 번들 조회(읽기 전용)
    python3 generator/tests/data/make_find_label_cases.py bundle.json  # 사전 덤프한 번들 JSON 에서

뽑은 뒤 `git diff` 로 **label 이 바뀐 코드를 눈으로 본다.** 한 회사의 표기가 여러 회사의 이름이 됐으면
`LABEL_OVERRIDE`(find.py · find.js 둘 다)에 일반명을 넣고 다시 뽑는다(2026-09-26 retirement_support 선례).
기대값은 파이썬 구현으로 계산한다 — JS 가 다르게 나오면 find.test.js 가 빨개진다(그게 이 픽스처의 목적이다).
"""
from __future__ import annotations

import datetime
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from generator.bundle import load_bundle, load_bundle_json  # noqa: E402
from generator.pages import find  # noqa: E402

OUT = Path(__file__).resolve().parent / "find_label_cases.json"
NOTE = (
    "실서빙 번들에서 뽑은 코드→이름 빈도표와 그때 나오는 대표 이름·별칭 순서. 파이썬(정적 표)과 JS(칩)가 "
    "코드 사전을 각자 만들기 때문에 **같은 픽스처로 양쪽을 재는 것**이 이 파일의 목적이다. "
    "generator/tests/test_find_page.py 와 web/assets/js/find.test.js 가 함께 읽는다. 번들이 크게 바뀌면 "
    "generator/tests/data/make_find_label_cases.py 로 다시 뽑아라 — 손으로 고치지 마라. `category_order` 는 "
    "카테고리 안 표시 순서(보유 회사 수 내림차순 → 라벨) — 정적 표와 칩 줄이 **같은 순서**여야 한다는 약속이다. "
    "⚠ `label` 칸 중 `LABEL_OVERRIDE` 에 있는 코드는 override 값이다 — override 를 더하거나 고치면 이 스크립트로 "
    "다시 뽑는다(대표 이름이 바뀐 코드는 git diff 로 확인)."
)


def build(bundle: dict) -> dict:
    companies = bundle["companies"]
    names: dict[str, Counter] = {}
    rows = 0
    for c in companies:
        for b in c.get("benefits") or []:
            if not b.get("benefit_cd"):
                continue
            rows += 1
            names.setdefault(b["benefit_cd"], Counter())[b.get("benefit_nm")] += 1
    codes = find.derive_codes(companies)
    assert sorted(codes) == sorted(names), "derive_codes 와 빈도표의 코드 집합이 다르다"

    by_cat: dict[str, list] = {}
    for info in codes.values():
        by_cat.setdefault(info["ctgr"], []).append(info)
    category_order = {
        key: [i["code"] for i in sorted(by_cat[key], key=lambda i: (-i["count"], i["label"]))]
        for key in find.CATEGORY_ORDER
        if key in by_cat
    }
    out_codes = {}
    for code in sorted(codes):
        info = codes[code]
        out_codes[code] = {
            "names": dict(sorted(names[code].items(), key=lambda kv: (-kv[1], str(kv[0])))),
            "ctgr": info["ctgr"],
            "label": info["label"],
            "aliases": info["aliases"],
        }
    today = datetime.date.today().isoformat()
    return {
        "note": NOTE,
        "source": f"reference/all {today} · 회사 {len(companies)} · 복지 {rows}행 · 코드 {len(out_codes)}종",
        "category_order": category_order,
        "codes": out_codes,
    }


def main(argv: list[str]) -> None:
    bundle = load_bundle_json(argv[0]) if argv else load_bundle()
    data = build(bundle)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} — {data['source']}")


if __name__ == "__main__":
    main(sys.argv[1:])
