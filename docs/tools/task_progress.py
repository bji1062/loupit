#!/usr/bin/env python3
"""docs/tools/task_progress.py — TASK 진행 롤업 자동 집계.

문제: docs/TASK.md §4 롤업을 사람이 세서 문장으로 적었고, 단독 작업에서도
이미 드리프트가 났다(문서 255 vs 실측 262). 병렬 세션에서는 같은 문단을
동시에 고쳐 병합 불능이 된다.

해결: 이 스크립트가 docs/TASK/NN-*.md 의 진행 마커(`- [ ]`/`- [-]`/`- [v]`)를
직접 세어 docs/TASK.md 의 AUTOGEN 블록(표)을 다시 쓴다. 사람은 리프 마커만
갱신하고 롤업은 절대 손으로 세지 않는다.

사용:
    python3 docs/tools/task_progress.py           # TASK.md AUTOGEN 블록 갱신
    python3 docs/tools/task_progress.py --check   # 어긋나면 exit 1 (CI 용)

집계 규칙:
- 대상: docs/TASK/01~99-*.md (00-빌드순서는 마일스톤 마커라 리프 집계에서 제외)
- 마커는 행 시작(들여쓰기 허용)의 `- [ ]` / `- [-]` / `- [v]` 만 센다.
- 인용 블록(>)·코드펜스 안 마커는 세지 않는다(문서 속 예시 오집계 방지).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TASK_DIR = ROOT / "docs" / "TASK"
TASK_MD = ROOT / "docs" / "TASK.md"

BEGIN = "<!-- AUTOGEN:progress (docs/tools/task_progress.py — 손으로 고치지 마라) -->"
END = "<!-- /AUTOGEN:progress -->"

_MARKER = re.compile(r"^\s*- \[( |-|v)\]")
_FENCE = re.compile(r"^\s*```")


def count_file(path: Path) -> dict[str, int]:
    todo = wip = done = 0
    in_fence = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if _FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence or line.lstrip().startswith(">"):
            continue
        m = _MARKER.match(line)
        if not m:
            continue
        c = m.group(1)
        if c == " ":
            todo += 1
        elif c == "-":
            wip += 1
        else:
            done += 1
    return {"done": done, "wip": wip, "todo": todo}


def collect() -> list[tuple[str, dict[str, int]]]:
    rows = []
    for path in sorted(TASK_DIR.glob("[0-9][0-9]-*.md")):
        if path.name.startswith("00-"):
            continue  # 마일스톤 문서 — 리프 아님
        rows.append((path.name, count_file(path)))
    return rows


def render_block(rows: list[tuple[str, dict[str, int]]]) -> str:
    total = {"done": 0, "wip": 0, "todo": 0}
    lines = [
        BEGIN,
        "| 파일 | 완료 | 진행 | 미착수 | 계 |",
        "|---|---:|---:|---:|---:|",
    ]
    for name, c in rows:
        n = c["done"] + c["wip"] + c["todo"]
        for k in total:
            total[k] += c[k]
        lines.append(f"| {name} | {c['done']} | {c['wip']} | {c['todo']} | {n} |")
    n = total["done"] + total["wip"] + total["todo"]
    lines.append(
        f"| **합계** | **{total['done']}** | **{total['wip']}** | **{total['todo']}** | **{n}** |"
    )
    lines.append(END)
    return "\n".join(lines)


def main() -> int:
    check = "--check" in sys.argv
    rows = collect()
    block = render_block(rows)
    text = TASK_MD.read_text(encoding="utf-8")

    if BEGIN not in text or END not in text:
        print(f"[task-progress] {TASK_MD} 에 AUTOGEN 마커가 없다 — 블록을 먼저 넣어라.")
        return 1

    new_text = re.sub(
        re.escape(BEGIN) + r".*?" + re.escape(END), block, text, count=1, flags=re.S
    )
    if check:
        if new_text != text:
            print("[task-progress] ❌ 롤업이 실측과 다르다. `python3 docs/tools/task_progress.py` 로 갱신하라.")
            return 1
        print("[task-progress] ✅ 롤업이 실측과 일치한다.")
        return 0

    if new_text != text:
        TASK_MD.write_text(new_text, encoding="utf-8")
        print("[task-progress] 갱신 완료.")
    else:
        print("[task-progress] 변경 없음.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
