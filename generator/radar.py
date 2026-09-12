"""generator/radar.py — 복지 9카테고리 레이더(정적 SVG, 순수 함수).

`charts.py` 와 **같은 계약**이다: 좌표를 빌드 시점에 계산해 HTML 에 박는다.

🚨 **이 계약은 2026-09-12 에 한 번 깨졌다.** 모드 A 「복지 비교」(SPEC 19 SP-CMP-4)는 브라우저
도구라 좌표를 런타임에 그려야 한다 — `web/assets/js/radar.js` 가 그 포트다. 렌더러가 둘이면 축
규칙·결측 처리가 두 언어로 갈라지고, 갈라진 판정은 반드시 어긋난다(배지 함정). 그래서 셋을 못
박았다:

  ① `/vs` 정적 3쪽은 **Python** 이 굽는다(`radar_pair_svg`). 그 페이지에 JS 는 0 이다.
  ② `radar.js` 는 **좌표 계산만** 옮기고, 골든 픽스처(`tests/data/radar_pair_cases.json`)가 같은
     입력에서 `points` 문자열의 **바이트 일치**를 고정한다. 어긋나면 빌드가 아니라 테스트가 잡는다.
     ⚠ `.1f` 는 파이썬이 짝수 쪽으로, JS `toFixed` 가 위로 반올림한다 — 값이 정확히 x.25 일 때만
     갈리고(151.25 → 151.2 vs 151.3), 그 케이스가 픽스처에 들어 있다.
  ③ **결측 표기는 함수 하나**(`fmt`)에서 나온다. 0 은 어디서나 「등록 없음」이고 숫자 0 을 쓰지
     않는다 — 스키마에 「이 회사에 이 제도가 없다」를 적는 곳이 없어서, 0 을 「없음」으로 읽히게
     두면 그림이 거짓 진술이 된다(SP-CMP-3).

축은 카테고리 **정본 순서**(`pages/company.CATEGORY_ORDER`)로 12시부터 시계방향 9등분이고,
값은 **그 카테고리의 복지 항목 수**다(금액이 아니다 — 금액은 표가 말한다). 축 최댓값은 등록
회사 전체의 카테고리별 최댓값이라 회사가 바뀌어도 눈금이 같은 뜻을 갖는다.

회색 점선은 **등록 회사 평균**이다. 이 선이 있어야 "6항목"이 많은지 적은지를 말할 수 있다 —
없으면 모든 회사가 자기 모양만 보여 주고 끝난다.

색·치수는 **CSS 클래스로만** 준다(`rd-*`, `web/assets/css/styles.css` 소유 — `rd-hit`·`rd-hitc`·`rd-hv` 는 호버 라벨):
⚠ SVG 프레젠테이션 속성에 `var(--x)` 를 쓰면 브라우저에 따라 조용히 무시된다(charts.py 실측).
"""
from __future__ import annotations

import math
from html import escape

CX, CY, R = 200.0, 200.0, 130.0
LABEL_R = R + 22  # 축 라벨 반지름 — 꼭짓점 바깥
VIEWBOX = "0 34 400 330"  # 라벨 실측 범위로 잘라 위아래 여백을 줄인다(overflow:visible 로 넘침 허용)
RINGS = (2, 4, 6, 8)  # 눈금 고리 — 이 값이 곧 "항목 수"다

# 쌍(겹침) 전용 화면 상자. 기하 상수(CX·CY·R·LABEL_R·RINGS)는 **그대로 두고** 프로덕션 viewBox
# 에 오른쪽 +16(「근무환경」 라벨 폭)·아래 +26(판독 띠)만 더한다 — 두 그림이 같은 자리·같은 눈금을
# 쓰는 것이 이 화면의 존재 이유라 좌표를 건드리면 안 된다.
VIEWBOX_PAIR = "0 34 416 356"
PAIR_W = 416.0          # 판독 띠 rect 의 폭이자 가운데 정렬 기준(PAIR_W / 2)
BAND_RECT_Y = 369.0     # 띠 배경 rect 의 위쪽 — `:has()` 없는 브라우저에서도 기본 글과 안 겹친다
BAND_H = 18.0
BAND_TEXT_Y = 381.0
# 히트 부채꼴: 반지름 r×1.16(꼭짓점보다 조금 넘겨 가장자리를 잡는다) · 폭 40°(=축 간격 40° 전부).
HIT_R_MUL = 1.16
HIT_HALF_DEG = 20.0
HIT_STEP_DEG = 10.0
# 띠의 기본 글 — **사용 안내만** 적는다. 「4 대 1」 같은 집계를 두면 항목 수가 점수판이 된다(D-6).
BAND_DEFAULT = "축 위에 올리거나 Tab 으로 옮기면 두 회사 값 · 중심 = 등록 없음"


def fmt(v) -> str:
    """항목 수 → 사람이 읽는 말. **0 은 「등록 없음」이다**(SP-CMP-3).

    숫자 0 을 화면에 쓰지 않는 이유: 우리 스키마에는 긍정 행만 있어서 「이 회사에 이 제도가 없다」
    를 적을 자리가 없다. 0 은 「우리가 등록하지 않았다」일 뿐인데 「0개 = 없다」로 읽힌다. 임의 쌍에서
    한쪽만 있는 행이 합집합의 중앙 71.4% 라, 이 한 낱말을 틀리면 화면 대부분이 거짓이 된다.

    이 함수가 **하나**인 것이 계약이다 — 판독문·aria-label·표·막대 라벨이 전부 여기서 나온다.
    """
    return "등록 없음" if not v else f"{v}항목"


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
    # 꼭짓점 호버: 지름 4 짜리 점은 마우스를 올리기 어렵다 — 투명 r=14 히트 원을 얹고, 그 위에
    # 즉시 뜨는 CSS 라벨(`rd-hit:hover .rd-hv`)을 둔다. JS 0.
    # 마지막에 그려 최상단에서 포인터를 받는다(SVG 호버는 최상단 페인트 요소가 받는다).
    hits = ""
    for i, (v, lb, a) in enumerate(zip(counts, labels, avgs)):
        px, py = _pt(i, v, n, rmax)
        # 0 은 「0항목」이 아니라 「등록 없음」이다 — 비교 화면과 **같은 낱말**로 적는다(SP-CMP-3).
        # 상세와 비교가 결측을 다르게 부르면 같은 회사가 두 화면에서 다른 말을 하게 된다.
        text = f"{escape(lb)} {fmt(v)} · 평균 {a:.1f}"
        # 히트 그룹은 **탭으로도 닿는다**(`tabindex="0"` + 축별 aria-label). 마우스만 가진 장치를
        # 전제한 호버 전용 라벨은 값을 키보드·보조기기 사용자에게서 통째로 감춘다.
        # <title> 은 두지 않는다 — `role="img"` 아래라 보조기기에 안 읽히고(값은 aria-label 이 이미
        # 전부 말한다), 네이티브 툴팁의 1초 지연이 "안 되는 것"으로 보고된 그 경험을 되풀이한다.
        hits += (f'<g class="rd-hit" tabindex="0" role="img" aria-label="{text}">'
                 f'<circle class="rd-hitc" cx="{px:.1f}" cy="{py:.1f}" r="14"></circle>'
                 f'<text class="rd-hv" x="{px:.1f}" y="{py - 12:.1f}" text-anchor="middle">{text}</text></g>')
    # 스크린리더·이미지 검색이 읽는 설명. 숫자를 그대로 적는다 — 그림을 못 보는 사람에게 "그래프"
    # 라고만 말하는 것은 아무것도 말하지 않는 것이다.
    # 그림을 못 보는 사람에게도 **점선의 뜻**까지 준다 — 값만 읽어 주면 "많은지 적은지"를 여전히
    # 모른다(그 판단이 이 그래프의 존재 이유다).
    desc = " · ".join(f"{escape(lb)} {fmt(c)}(평균 {a:.1f})" for lb, c, a in zip(labels, counts, avgs))
    who = f"{escape(comp_nm)} " if comp_nm else ""
    return (
        f'<svg class="rd" viewBox="{VIEWBOX}" role="img" '
        f'aria-label="{who}카테고리별 복지 항목 수 — {escape(desc)}">'
        f"{rings}{axes}{ticks}"
        # 평균 점선을 **회사 도형 뒤에** 그린다. 앞서 그리면 18% 채움 아래로 들어가 대비가 2.7:1 로
        # 떨어지고(WCAG 1.4.11 은 3:1), 하필 평균을 넘는 회사일수록 점선이 통째로 채움 안에 잠긴다.
        f'<polygon class="rd-you" points="{_poly(counts, rmax)}"></polygon>'
        f'<polygon class="rd-avg" points="{_poly(avgs, rmax)}"></polygon>'
        f"{dots}{lbs}{hits}</svg>"
    )


def _sector(i: int, n: int) -> str:
    """축 i 를 덮는 **부채꼴** 히트 영역의 points. 중심 + 호 위 5점(−20°·−10°·0°·+10°·+20°).

    왜 부채꼴인가: 값이 0 이면 꼭짓점이 중심에 겹쳐 아홉 개가 같은 자리에 쌓인다 — 점 히트로는
    「등록 없음」인 축을 가리킬 수 없다. 축 전체를 덮으면 값과 무관하게 그 축을 잡는다.
    """
    a0 = -math.pi / 2 + 2 * math.pi * i / n
    r = R * HIT_R_MUL
    pts = [f"{CX:.1f},{CY:.1f}"]
    deg = -HIT_HALF_DEG
    while deg <= HIT_HALF_DEG + 1e-9:
        a = a0 + math.radians(deg)
        pts.append(f"{CX + r * math.cos(a):.1f},{CY + r * math.sin(a):.1f}")
        deg += HIT_STEP_DEG
    return " ".join(pts)


def _readout(lb: str, a: int, b: int, avg: float, a_nm: str, b_nm: str) -> str:
    """축 하나의 판독문. 문형이 **하나**라 판독 띠·aria-label·그림 전체 설명이 갈리지 않는다.

    둘 다 0 일 때 두 번 「등록 없음」이라 적지 않는 이유는 읽어 주는 쪽이다 — 스크린리더가
    "카카오 등록 없음 · 네이버 등록 없음"을 두 번 말하는 것보다 "양쪽 등록 없음"이 짧고 정확하다.
    """
    if not a and not b:
        return f"{lb} — 양쪽 등록 없음 · 평균 {avg:.1f}"
    return f"{lb} — {a_nm} {fmt(a)} · {b_nm} {fmt(b)} · 평균 {avg:.1f}"


def radar_pair_svg(counts_a: list[int], counts_b: list[int], avgs: list[float], labels: list[str],
                   rmax: float, a_nm: str = "", b_nm: str = "") -> str:
    """두 회사를 **겹친** 9각형 (SP-CMP-4). `radar_svg` 와 같은 기하·같은 눈금·같은 축 순서다.

    회사 상세에서 본 모양을 기억한 채 비교로 넘어오면 같은 자리에서 상대가 보인다 — 그래서
    도형을 새로 발명하지 않고 두 장 겹친다. 눈금(고리 2·4·6·8)은 **등록 회사 전체의 카테고리별
    최댓값**이라 쌍마다 다시 잡지 않는다: 쌍마다 잡으면 도형 크기가 거짓말을 한다.

    색·표식은 **슬롯**을 따른다(A 초록·원 / B 파랑·네모). dataviz 의 「색은 개체를 따른다」에 대한
    의도적 예외다 — 모드 B 의 계산 계약(「연봉은 A, 상승률은 B」)이 슬롯에 걸려 있다.

    겹친 넓이를 점수로 바꾸는 문장은 어디에도 두지 않는다(D-6). 겹친 곳은 「두 회사 모두 그 수까지
    등록된 범위」이지 **같은 항목이라는 뜻이 아니다** — 같은 항목은 「공통 N」과 항목 대조표의 몫이다.
    """
    n = len(counts_a)
    if n != len(counts_b) or n != len(avgs) or n != len(labels) or n < 3:
        raise ValueError(
            f"radar_pair_svg: 길이 불일치 a={len(counts_a)} b={len(counts_b)} "
            f"avgs={len(avgs)} labels={len(labels)}"
        )
    rmax = float(max(rmax, max(counts_a, default=0), max(counts_b, default=0), 1))

    rings = "".join(
        f'<polygon class="rdp-ring" points="{_poly([k] * n, rmax)}"></polygon>'
        for k in RINGS if k <= rmax
    )
    axes = "".join(
        f'<line class="rdp-ax" x1="{CX:.0f}" y1="{CY:.0f}" '
        f'x2="{_pt(i, rmax, n, rmax)[0]:.1f}" y2="{_pt(i, rmax, n, rmax)[1]:.1f}"></line>'
        for i in range(n)
    )
    ticks = "".join(
        f'<text class="rdp-tick" x="{CX + 6:.0f}" y="{CY - R * k / rmax + 4:.1f}">{k}</text>'
        for k in RINGS if k <= rmax
    )

    lbs = ""
    for i, text in enumerate(labels):
        a = -math.pi / 2 + 2 * math.pi * i / n
        lx, ly = CX + LABEL_R * math.cos(a), CY + LABEL_R * math.sin(a)
        anchor = "middle" if abs(math.cos(a)) < 0.25 else ("start" if math.cos(a) > 0 else "end")
        dy = 5 if abs(math.sin(a)) < 0.3 else (11 if math.sin(a) > 0 else -1)
        lbs += (f'<text class="rdp-lb" x="{lx:.1f}" y="{ly + dy:.1f}" text-anchor="{anchor}">'
                f"{escape(text)}</text>")

    # 표식: B 는 네모(9×9), A 는 원(r=5). **같은 값이면 A 원을 속 빈 링으로** 얹어 네모가 비친다 —
    # 꽉 찬 원이 네모를 통째로 덮으면 색 외의 두 번째 채널(모양)이 겹칠 때마다 사라진다.
    marks_b = "".join(
        f'<rect class="rdp-db" x="{_pt(i, v, n, rmax)[0] - 4.5:.1f}" '
        f'y="{_pt(i, v, n, rmax)[1] - 4.5:.1f}" width="9" height="9"></rect>'
        for i, v in enumerate(counts_b)
    )
    marks_a = ""
    for i, v in enumerate(counts_a):
        px, py = _pt(i, v, n, rmax)
        tie = " rdp-tie" if counts_a[i] == counts_b[i] else ""
        marks_a += f'<circle class="rdp-da{tie}" cx="{px:.1f}" cy="{py:.1f}" r="5"></circle>'

    a_who, b_who = escape(a_nm), escape(b_nm)
    # 히트 그룹은 `aria-hidden` 밖에 둔다 — 그림 전체는 한 덩어리로 읽히고(role="group" + 요약),
    # 축 아홉 개는 탭으로 하나씩 짚을 수 있다.
    hits = ""
    for i in range(n):
        line = _readout(escape(labels[i]), counts_a[i], counts_b[i], avgs[i], a_who, b_who)
        ax, ay = _pt(i, rmax, n, rmax)
        hits += (
            f'<g class="rdp-hit" tabindex="0" role="img" aria-label="{line}">'
            f'<polygon class="rdp-hitc" points="{_sector(i, n)}"></polygon>'
            f'<line class="rdp-hl" x1="{CX:.0f}" y1="{CY:.0f}" x2="{ax:.1f}" y2="{ay:.1f}"></line>'
            f'<rect class="rdp-hvbg" x="0" y="{BAND_RECT_Y:.0f}" width="{PAIR_W:.0f}" height="{BAND_H:.0f}"></rect>'
            f'<text class="rdp-hv" x="{PAIR_W / 2:.0f}" y="{BAND_TEXT_Y:.0f}" text-anchor="middle">{line}</text></g>'
        )

    desc = " · ".join(
        f"{escape(lb)} {a_who} {fmt(ca)}·{b_who} {fmt(cb)}(평균 {av:.1f})"
        for lb, ca, cb, av in zip(labels, counts_a, counts_b, avgs)
    )
    return (
        f'<svg class="rdp" viewBox="{VIEWBOX_PAIR}" role="group" '
        f'aria-label="{a_who}·{b_who} 카테고리별 복지 항목 수 — {desc}. '
        f'같은 숫자가 아래 「카테고리별」 표에 있다">'
        f'<g aria-hidden="true">'
        f"{rings}{axes}{ticks}"
        # B → A → 평균 순. 평균 점선이 맨 위라야 14% 채움 두 장(겹친 곳 26%) 아래로 잠기지 않는다
        # (단일 레이더가 18% 채움에서 같은 이유로 점선을 뒤에 그린다).
        f'<polygon class="rdp-b" points="{_poly(counts_b, rmax)}"></polygon>'
        f'<polygon class="rdp-a" points="{_poly(counts_a, rmax)}"></polygon>'
        f'<polygon class="rdp-avg" points="{_poly(avgs, rmax)}"></polygon>'
        f"{marks_b}{marks_a}{lbs}"
        f'<text class="rdp-hv0" x="{PAIR_W / 2:.0f}" y="{BAND_TEXT_Y:.0f}" text-anchor="middle">'
        f'{escape(BAND_DEFAULT)}</text>'
        f"</g>{hits}</svg>"
    )
