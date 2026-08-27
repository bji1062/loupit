"""generator/treemap.py — squarified treemap 배치(순수 함수, SP-HEAT-3).

빌드 시점에 배치를 계산해 HTML 에 %-좌표로 박는다 — 페이지는 JS 없이 그려지고 색인된다(NFR24).
알고리즘은 Bruls·Huizing·van Wijk 의 squarify: 가중치 내림차순으로 행을 채우며 행의 최악 종횡비가
나빠지기 직전에 행을 확정한다. 두 단계 중첩: 그룹(업종) → 그룹 안 회사.

좌표계: 컨테이너를 (0,0)-(W,H) 로 두고 모든 값은 같은 단위(호출자가 % 로 해석). 결과는
`(obj, x, y, w, h)`. 가중치 0 이하는 배치하지 않는다(면적 0 은 그릴 수 없다 — 호출자가 걸러 말한다).
"""
from __future__ import annotations

from dataclasses import dataclass


def squarify(items: list[tuple[float, object]], x: float, y: float, w: float, h: float) -> list[tuple]:
    """`items=[(weight, obj)]` → `[(obj, x, y, w, h)]`. 면적은 가중치에 정확히 비례한다."""
    items = [it for it in items if it[0] > 0]
    items.sort(key=lambda t: -t[0])
    total = sum(t[0] for t in items)
    out: list[tuple] = []
    if total <= 0 or w <= 0 or h <= 0:
        return out
    scale = w * h / total
    scaled = [(a * scale, o) for a, o in items]

    def worst(row, side):
        s = sum(a for a, _ in row)
        mx = max(a for a, _ in row)
        mn = min(a for a, _ in row)
        return max(side * side * mx / (s * s), s * s / (side * side * mn))

    def layout(row, x, y, w, h):
        s = sum(a for a, _ in row)
        if w >= h:  # 세로 열을 왼쪽에
            cw = s / h
            cy = y
            for a, o in row:
                ch = a / cw
                out.append((o, x, cy, cw, ch))
                cy += ch
            return x + cw, y, w - cw, h
        rh = s / w  # 가로 행을 위에
        cx = x
        for a, o in row:
            cw = a / rh
            out.append((o, cx, y, cw, rh))
            cx += cw
        return x, y + rh, w, h - rh

    row: list = []
    while scaled:
        side = min(w, h)
        it = scaled[0]
        if not row or worst(row + [it], side) <= worst(row, side):
            row.append(it)
            scaled.pop(0)
        else:
            x, y, w, h = layout(row, x, y, w, h)
            row = []
    if row:
        layout(row, x, y, w, h)
    return out


@dataclass(frozen=True)
class Group:
    name: str
    x: float
    y: float
    w: float
    h: float
    count: int


@dataclass(frozen=True)
class Tile:
    obj: object
    x: float
    y: float
    w: float
    h: float


def nested_layout(
    groups: dict[str, list[tuple[float, object]]],
    width: float,
    height: float,
    *,
    pad: float = 0.3,
    head: float = 2.0,
) -> tuple[list[Group], list[Tile]]:
    """`{그룹명: [(weight, obj)]}` → (그룹 사각형, 회사 타일). 그룹 면적 = 가중치 합.

    그룹 안쪽에 `pad` 여백과 위쪽 `head`(그룹 이름 줄)를 두고 회사를 다시 squarify 한다.
    아주 작은 그룹은 여백·머리줄을 줄여 **회사 타일이 사라지지 않게** 한다(면적이 음수가 되면
    그 회사는 조용히 빠진다 — 첫 목업에서 실제로 15곳이 사라졌다).
    """
    gitems = [(sum(wt for wt, _ in members), name) for name, members in groups.items() if members]
    heads: list[Group] = []
    tiles: list[Tile] = []
    for name, gx, gy, gw, gh in squarify(gitems, 0, 0, width, height):
        members = groups[name]
        heads.append(Group(name, gx, gy, gw, gh, len(members)))
        p = min(pad, gw * 0.05, gh * 0.05)
        hd = min(head, gh * 0.35)
        inner = squarify(members, gx + p, gy + p + hd, gw - 2 * p, gh - 2 * p - hd)
        for obj, tx, ty, tw, th in inner:
            tiles.append(Tile(obj, tx, ty, tw, th))
    return heads, tiles
