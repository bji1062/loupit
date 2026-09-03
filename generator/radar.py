"""generator/radar.py — 복지 9카테고리 레이더(정적 SVG, 순수 함수).

`charts.py` 와 **같은 계약**이다: 좌표를 빌드 시점에 계산해 HTML 에 박는다. JS 로 한 벌 더
그리지 않는다 — 렌더러가 둘이면 축 규칙·결측 처리가 두 언어로 갈라지고, 갈라진 판정은 반드시
어긋난다(배지 함정).

축은 카테고리 **정본 순서**(`pages/company.CATEGORY_ORDER`)로 12시부터 시계방향 9등분이고,
값은 **그 카테고리의 복지 항목 수**다(금액이 아니다 — 금액은 표가 말한다). 축 최댓값은 등록
회사 전체의 카테고리별 최댓값이라 회사가 바뀌어도 눈금이 같은 뜻을 갖는다.

회색 점선은 **등록 회사 평균**이다. 이 선이 있어야 "6항목"이 많은지 적은지를 말할 수 있다 —
없으면 모든 회사가 자기 모양만 보여 주고 끝난다.

색·치수는 **CSS 클래스로만** 준다(`rd-*`, `web/assets/css/styles.css` 소유):
⚠ SVG 프레젠테이션 속성에 `var(--x)` 를 쓰면 브라우저에 따라 조용히 무시된다(charts.py 실측).
"""
from __future__ import annotations

import math
from html import escape

CX, CY, R = 200.0, 200.0, 130.0
LABEL_R = R + 22  # 축 라벨 반지름 — 꼭짓점 바깥
VIEWBOX = "0 34 400 330"  # 라벨 실측 범위로 잘라 위아래 여백을 줄인다(overflow:visible 로 넘침 허용)
RINGS = (2, 4, 6, 8)  # 눈금 고리 — 이 값이 곧 "항목 수"다


def _pt(i: int, v: float, n: int, rmax: float) -> tuple[float, float]:
    """축 i(12시부터 시계방향)의 값 v 좌표. rmax 가 0 이면 중심점(전 회사 복지 0 = 불가능하지만 무크래시)."""
    a = -math.pi / 2 + 2 * math.pi * i / n
    r = 0.0 if rmax <= 0 else R * (v / rmax)
    return CX + r * math.cos(a), CY + r * math.sin(a)


def _poly(values, rmax: float) -> str:
    n = len(values)
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in (_pt(i, v, n, rmax) for i, v in enumerate(values)))


def radar_svg(counts: list[int], avgs: list[float], labels: list[str], rmax: float,
              comp_nm: str = "") -> str:
    """9각형 SVG 문자열. `counts`·`avgs`·`labels` 는 **같은 길이**(카테고리 정본 순서)여야 한다.

    길이가 어긋난 채 그리면 '건강' 자리에 '가족' 값이 찍혀도 아무도 모른다 — 에러 없이 틀린
    그림이 이 프로젝트의 반복 함정이라 계약 위반은 조용히 넘기지 않는다(charts.`_check` 와 같은 이유).
    """
    n = len(counts)
    if n != len(avgs) or n != len(labels) or n < 3:
        raise ValueError(f"radar_svg: 길이 불일치 counts={len(counts)} avgs={len(avgs)} labels={len(labels)}")
    rmax = float(max(rmax, max(counts, default=0), 1))

    rings = "".join(
        f'<polygon class="rd-ring" points="{_poly([k] * n, rmax)}"></polygon>'
        for k in RINGS if k <= rmax
    )
    ticks = "".join(
        f'<text class="rd-tick" x="{CX + 6:.0f}" y="{CY - R * k / rmax + 4:.1f}">{k}</text>'
        for k in RINGS if k <= rmax
    )
    axes = "".join(
        f'<line class="rd-ax" x1="{CX:.0f}" y1="{CY:.0f}" '
        f'x2="{_pt(i, rmax, n, rmax)[0]:.1f}" y2="{_pt(i, rmax, n, rmax)[1]:.1f}"></line>'
        for i in range(n)
    )

    lbs = ""
    for i, text in enumerate(labels):
        a = -math.pi / 2 + 2 * math.pi * i / n
        lx, ly = CX + LABEL_R * math.cos(a), CY + LABEL_R * math.sin(a)
        anchor = "middle" if abs(math.cos(a)) < 0.25 else ("start" if math.cos(a) > 0 else "end")
        dy = 5 if abs(math.sin(a)) < 0.3 else (11 if math.sin(a) > 0 else -1)
        lbs += (f'<text class="rd-lb" x="{lx:.1f}" y="{ly + dy:.1f}" text-anchor="{anchor}">'
                f"{escape(text)}</text>")

    dots = "".join(
        f'<circle class="rd-dot" cx="{_pt(i, v, n, rmax)[0]:.1f}" cy="{_pt(i, v, n, rmax)[1]:.1f}" r="4"></circle>'
        for i, v in enumerate(counts)
    )
    # 스크린리더·이미지 검색이 읽는 설명. 숫자를 그대로 적는다 — 그림을 못 보는 사람에게 "그래프"
    # 라고만 말하는 것은 아무것도 말하지 않는 것이다.
    desc = " · ".join(f"{escape(lb)} {c}" for lb, c in zip(labels, counts))
    who = f"{escape(comp_nm)} " if comp_nm else ""
    return (
        f'<svg class="rd" viewBox="{VIEWBOX}" role="img" '
        f'aria-label="{who}카테고리별 복지 항목 수 — {escape(desc)}">'
        f"{rings}{axes}{ticks}"
        f'<polygon class="rd-avg" points="{_poly(avgs, rmax)}"></polygon>'
        f'<polygon class="rd-you" points="{_poly(counts, rmax)}"></polygon>'
        f"{dots}{lbs}</svg>"
    )
