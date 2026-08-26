#!/usr/bin/env python3
"""docs/tools/pitfalls.py — 함정 로그 인덱스·번호 부여.

문제: 함정 번호가 전역 단일 카운터(①~(66))라 병렬 세션 둘이 동시에 발견하면
둘 다 다음 번호를 쓴다. 기존 66개는 6개 HANDOFF 파일에 흩어져 있고 본문
곳곳이 번호로 상호참조하므로 **원문 이동·재번호는 금지**다.

구조:
- 기존 ①~(66): HANDOFF 원문에 그대로 둔다. 이 스크립트는 읽기만 한다.
- 신규: 세션은 번호 없이 docs/PITFALLS/_incoming/<슬러그>.md 에 쓴다.
  머지 후 `--assign` 이 다음 번호를 부여해 docs/PITFALLS/NNNN-<슬러그>.md 로
  옮긴다. 번호 부여가 머지 후 단일 지점이라 충돌이 구조적으로 불가능하다.
- docs/PITFALLS/INDEX.md: 기존+신규 전체 인덱스(자동 생성).

사용:
    python3 docs/tools/pitfalls.py            # INDEX.md 재생성
    python3 docs/tools/pitfalls.py --assign   # _incoming 번호 부여 후 INDEX 재생성
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
PIT = DOCS / "PITFALLS"
INCOMING = PIT / "_incoming"
INDEX = PIT / "INDEX.md"

# 함정 대역 소유 파일 (재개 정본 릴레이가 확정한 정본 위치 — 원문 불변)
LEGACY = [
    ("HANDOFF-2026-07-27-B.md", "§5", 1, 13),
    ("HANDOFF-2026-07-28.md", "§4", 14, 19),
    ("HANDOFF-2026-07-29.md", "§4", 20, 27),
    ("HANDOFF-2026-07-29-B.md", "§4", 28, 43),
    ("HANDOFF-2026-07-30.md", "§4", 44, 56),
    ("HANDOFF-2026-07-31.md", "§4", 57, 66),
    ("HANDOFF-2026-08-21.md", "§4", 67, 73),
]

def _circled_to_int(ch: str) -> int | None:
    o = ord(ch)
    if 0x2460 <= o <= 0x2473:  # ①~⑳
        return o - 0x2460 + 1
    if 0x3251 <= o <= 0x325F:  # ㉑~㉟
        return o - 0x3251 + 21
    if 0x32B1 <= o <= 0x32BF:  # ㊱~㊿
        return o - 0x32B1 + 36
    return None

_ENTRY = re.compile(r"^\s*(?:[-*]\s*)?(?:\*\*)?(?:🚨\s*)?([①-⑳㉑-㉟㊱-㊿]|\((\d{1,3})\))\s*(?:🚨\s*)?(.*)")

def _clean(text: str, limit: int = 90) -> str:
    text = re.sub(r"\*\*|`", "", text).strip().rstrip("*").strip()
    text = text.replace("|", "\\|")
    return text[: limit - 1] + "…" if len(text) > limit else text

def scan_legacy() -> dict[int, tuple[str, str]]:
    """번호 → (요약, 파일#섹션). 소유 대역 밖 번호(재게재 사본·상호참조)는 무시."""
    found: dict[int, tuple[str, str]] = {}
    for fname, section, lo, hi in LEGACY:
        path = DOCS / fname
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            m = _ENTRY.match(line)
            if not m:
                continue
            num = int(m.group(2)) if m.group(2) else _circled_to_int(m.group(1))
            if num is None or not (lo <= num <= hi) or num in found:
                continue
            found[num] = (_clean(m.group(3)), f"{fname} {section}")
    return found

def scan_new() -> dict[int, tuple[str, str]]:
    found: dict[int, tuple[str, str]] = {}
    for path in sorted(PIT.glob("[0-9][0-9][0-9][0-9]-*.md")):
        num = int(path.name[:4])
        first = next(
            (l.lstrip("# ").strip() for l in path.read_text(encoding="utf-8").splitlines() if l.strip()),
            path.stem,
        )
        found[num] = (_clean(first), f"PITFALLS/{path.name}")
    return found

def assign() -> None:
    legacy, new = scan_legacy(), scan_new()
    next_num = max([*legacy, *new], default=0) + 1
    for path in sorted(INCOMING.glob("*.md")):
        dest = PIT / f"{next_num:04d}-{path.name}"
        path.rename(dest)
        print(f"[pitfalls] 번호 부여: {path.name} → {dest.name}")
        next_num += 1

def render_index() -> str:
    legacy, new = scan_legacy(), scan_new()
    merged = {**legacy, **new}
    lines = [
        "# 함정 인덱스 (자동 생성 — `python3 docs/tools/pitfalls.py`)",
        "",
        "기존 ①~(66)의 **정본은 각 HANDOFF 원문**이다(상호참조 보존을 위해 이동 금지). "
        "이 파일은 찾아가는 지도일 뿐이다. 새 함정은 번호 없이 `_incoming/` 에 쓰고, "
        "머지 후 `--assign` 으로 번호를 받는다 — 그래서 병렬 세션끼리 번호가 겹칠 수 없다.",
        "",
        "| # | 요약 | 위치 |",
        "|--:|---|---|",
    ]
    for num in sorted(merged):
        summary, where = merged[num]
        lines.append(f"| {num} | {summary} | {where} |")
    pending = sorted(p.name for p in INCOMING.glob("*.md"))
    lines += ["", f"**번호 대기(_incoming): {len(pending)}건**"]
    lines += [f"- {n}" for n in pending]
    lines.append("")
    return "\n".join(lines)

def main() -> int:
    INCOMING.mkdir(parents=True, exist_ok=True)
    if "--assign" in sys.argv:
        assign()
    INDEX.write_text(render_index(), encoding="utf-8")
    legacy, new = scan_legacy(), scan_new()
    print(f"[pitfalls] INDEX.md 갱신 — 기존 {len(legacy)} + 신규 {len(new)}")
    missing = [n for n in range(1, max(legacy, default=0)) if n not in legacy and n not in new]
    if missing:
        print(f"[pitfalls] ⚠ 스캔 누락 의심 번호: {missing}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
