"""generator/charts.py — 지표 그래프 정적 SVG(순수 함수, SP-MET-9).

빌드 시점에 좌표를 계산해 HTML 에 박는다 — 페이지는 JS 없이 그려지고 색인된다(NFR24).
`treemap.py` 와 같은 계약이고 이유도 같다: **렌더러는 파이썬 하나뿐이다.** JS 로 한 벌 더 그리면
단위·결측·부호 규칙이 두 언어로 갈라지고, 갈라진 판정은 반드시 어긋난다(배지 함정 — 판정이 네
렌더러로 흩어져 GNB 검색 페이지만 조용히 틀린 배지를 달고 있었다).

**막대와 선은 축 규칙이 다르다.** 막대는 길이가 곧 크기라 0 기준선을 고정한다(축을 자르면 길이가
거짓말을 한다 — 근속·직원 수가 평평해 보이는 건 그게 사실이기 때문이다). 선은 위치가 값이라
데이터 범위에 맞춰도 되지만, 그 대가로 **실제 최댓값·최솟값을 눈금에 반드시 적는다**. 안 적으면
같은 데이터를 더 극적으로 보이게 만드는 속임수가 된다.

**결측(None)은 잇지 않는다.** 선은 구간을 끊고 막대는 자리를 비운다. 0 으로 그리면 "그 해 매출 0원"
이라는 없는 사실을 그리는 것이다(금융업은 매출 계정 자체가 없다 — SP-MET-2).

색·치수는 **CSS 클래스로만** 준다: `bar pos`·`bar neg`·`lp`·`ar-pos`·`ar-neg`·`ax`·`gl`·`yt`·`yr`.
⚠ SVG 프레젠테이션 속성(fill·stroke·opacity)에 `var(--x)` 를 쓰지 마라 — 브라우저에 따라 **조용히
무시**되어 검은 도형만 남는다(실측). ⚠ 여기서 새 클래스를 만들지도 마라: CSS 는 `web/assets/css`
소유라 목록 밖 클래스는 스타일 없이 나가고, 다크 테마에서 검은 글자는 곧 안 보이는 글자다.
그래서 결측 표시·직접 라벨도 새 이름을 만들지 않고 눈금 텍스트(`yt`)와 같은 옷을 입는다.

좌표계: viewBox `0 0 272 120`. 본체 104 아래 16 은 연도 라벨 줄, 위 16 은 직접 라벨, 아래 20 은
음수 막대 자리, 선 그래프만 왼쪽 38 을 눈금 텍스트에 내준다. 값의 단위 환산과 포맷은 호출자 몫이다
(`fmt` 하나로 받는다 — 금액 단위는 회사당 하나여야 세 그래프를 나란히 읽을 수 있다, SP-MET-10).
"""
from __future__ import annotations

import re
from collections.abc import Callable
from html import escape

W = 272  # viewBox 폭 — 카드가 넓어져도 svg 는 CSS 가 width:100% 로 늘린다
H = 104  # 그래프 본체 높이
PAD_T = 16  # 위 여백 — 첫 유효값 직접 라벨이 잘리지 않을 만큼
PAD_B = 20  # 아래 여백 — 음수 막대가 내려갈 자리
PAD_L = 38  # 선 그래프 왼쪽 눈금 텍스트 자리(막대는 눈금이 없어 0 에서 시작한다)
LABEL_H = 16  # 본체 아래 연도 라벨 줄
GAP_WIDE, GAP_TIGHT = 7, 3
TIGHT_FROM = 8  # 막대가 8개부터 간격을 줄이고 연도는 격년으로 — 기본이 11개년(2015~2025)이다
MIN_BAR = 2.0  # 0 에 가까운 값도 2px 는 그린다. 안 그리면 '0' 과 '결측' 이 눈으로 같아진다
# 막대 최대 폭. 연도가 2~4개뿐인 회사(공시 시작이 늦은 곳)에서 칸을 꽉 채우면 막대가 아니라
# **덩어리**가 되어 두 해의 차이가 눈에서 사라진다(실측: 2개년이면 한 개가 132px). 5개년부터는
# 자연 폭이 48.8px 라 이 상한에 닿지 않는다 — 즉 긴 계열의 그림은 바뀌지 않는다.
# ⚠ 좁힌 막대는 **자기 칸 안에서 가운데**에 둔다. 왼쪽으로 붙이면 연도 라벨(칸 중앙)과 어긋난다.
MAX_BAR = 56.0
RADIUS = 4.0
# 눈금 라벨 최소 세로 간격(px). 글자 크기가 9px 이라 이보다 가까우면 두 라벨이 겹쳐 읽힌다.
LABEL_GAP = 8.0

# id 로 새는 문자를 애초에 막는다. uid 는 호출자(카드 키)가 주는 값이고 `url(#…)` 안으로 들어간다.
_UID_RE = re.compile(r"^[A-Za-z0-9_-]+$")


def _check(values: list, years: list, uid: str) -> None:
    """계약 위반은 조용히 넘기지 않는다 — 빈 SVG 로 나가면 화면에서 '데이터가 없구나'로 읽힌다.

    길이가 어긋난 채 그리면 2019년 값에 2021년 라벨이 붙어도 아무도 모른다(에러 없이 틀린 그림이
    이 프로젝트의 반복 함정이다). `uid` 는 막대에서는 쓰이지 않지만 **똑같이 검사한다**: 두 함수는
    호출부에서 같은 자리에 나란히 놓이므로(SP-MET-10 막대/선 토글) 시그니처가 갈리면 분기가 생기고,
    분기는 언젠가 한쪽만 고쳐진다.
    """
    if len(values) != len(years):
        raise ValueError(f"values({len(values)}) 와 years({len(years)}) 의 길이가 다르다")
    if not _UID_RE.match(uid or ""):
        raise ValueError(f"uid 는 [A-Za-z0-9_-]+ 여야 한다(id 주입 차단): {uid!r}")


def _n(v: float) -> str:
    """좌표 → 소수 1자리 문자열. 회사 페이지 하나에 SVG 가 12벌이라 자릿수가 곧 전송량이다."""
    s = f"{v:.1f}"
    return s[:-2] if s.endswith(".0") else s


def _label(fmt: Callable[[float], str], v: float) -> str:
    """텍스트 노드용 — `fmt` 결과를 이스케이프하고 하이픈을 진짜 마이너스(−)로 바꾼다.

    `fmt` 는 호출자 코드다. 결과를 그대로 이어 붙이면 생성기에서 유일하게 autoescape 밖인 이 구간이
    이스케이프 구멍이 된다(`render.py` 는 autoescape=True, NFR21). 마이너스 기호를 살리는 이유는
    부호를 **색으로만** 말하지 않기 위해서다 — 색각 이상에서 빨강·초록이 같아 보이면 남는 단서는
    기준선 위아래와 이 기호뿐이다(SP-MET-9).
    """
    return escape(str(fmt(v)), quote=False).replace("-", "−")


def _yy(year) -> str:
    """연도 → 두 자리("2025"→"25"). 네 자리를 11개 넣으면 272px 안에서 겹친다."""
    s = escape(str(year), quote=False)
    return s[2:] if len(s) == 4 and s.isdigit() else s


def _year_shown(i: int, n: int) -> bool:
    """이 자리에 연도 라벨을 그리는가 — 8개 이상이면 격년 + 마지막(마지막은 언제나 적는다)."""
    return i == n - 1 or n < TIGHT_FROM or i % 2 == 0


def _open(years: list) -> str:
    """`<svg>` 여는 태그 — 스크린리더용 이름은 기간으로 말한다(숫자 낭독은 표가 대신한다)."""
    span = f"{years[0]}–{years[-1]}" if len(years) > 1 else f"{years[0]}"
    return f'<svg viewBox="0 0 {W} {H + LABEL_H}" role="img" aria-label="{escape(span)} 연도별 추이">'


def _year_text(i: int, n: int, cx: float, years: list) -> str:
    return (
        f'<text class="yr{" last" if i == n - 1 else ""}" x="{_n(cx)}" y="{H + 8}"'
        f' text-anchor="middle">{_yy(years[i])}</text>'
    )


def _bar_d(x: float, y: float, w: float, h: float, r: float, up: bool) -> str:
    """막대 하나의 path — **기준선에서 먼 끝만** 둥글다.

    네 귀퉁이를 다 둥글리면 기준선에 닿는 변이 떠 보여 0 이 어디인지 흐려진다. 위로 자란 막대는
    위 두 귀퉁이만, 아래로 내려간 막대는 아래 두 귀퉁이만 둥글린다.
    두 경우 모두 **첫 점이 기준선 위**다 — 테스트는 이 불변식으로 0 고정을 잰다.
    """
    if up:
        return (
            f"M{_n(x)} {_n(y + h)} V{_n(y + r)} Q{_n(x)} {_n(y)} {_n(x + r)} {_n(y)} "
            f"H{_n(x + w - r)} Q{_n(x + w)} {_n(y)} {_n(x + w)} {_n(y + r)} V{_n(y + h)} Z"
        )
    return (
        f"M{_n(x)} {_n(y)} V{_n(y + h - r)} Q{_n(x)} {_n(y + h)} {_n(x + r)} {_n(y + h)} "
        f"H{_n(x + w - r)} Q{_n(x + w)} {_n(y + h)} {_n(x + w)} {_n(y + h - r)} V{_n(y)} Z"
    )


def bar_svg(values: list[float | None], years: list[int], fmt: Callable[[float], str], uid: str) -> str:
    """막대 그래프 SVG 문자열. 값이 하나도 없으면 **빈 문자열**(호출자가 '없다'고 말할 자리를 만든다).

    축은 0 을 반드시 품는다(`hi=max(…,0)`·`lo=min(…,0)`). 축을 데이터 범위로 좁히면 1% 차이가
    두 배 길이로 보인다 — 막대에서 그건 눈금 없는 거짓말이다.
    `uid` 는 쓰지 않는다(막대에는 id 로 참조하는 요소가 없다). 그래도 받는 이유는 `_check` 주석 참고.
    """
    _check(values, years, uid)
    finite = [float(v) for v in values if v is not None]
    if not finite:
        return ""
    n = len(values)
    hi, lo = max(finite + [0.0]), min(finite + [0.0])
    span = (hi - lo) or 1.0
    plot_h = H - PAD_T - PAD_B
    y0 = PAD_T + (hi / span) * plot_h  # 0 기준선
    gap = GAP_TIGHT if n >= TIGHT_FROM else GAP_WIDE
    slot = (W - gap * (n - 1)) / n
    bw = min(slot, MAX_BAR)
    inset = (slot - bw) / 2  # 칸 중앙 정렬 — 칸 중심(=연도 라벨 위치)은 그대로다
    first = next(i for i, v in enumerate(values) if v is not None)

    out = [_open(years), f'<line class="ax" x1="0" y1="{_n(y0)}" x2="{W}" y2="{_n(y0)}"/>']
    for i, v in enumerate(values):
        x = i * (slot + gap) + inset
        cx = x + bw / 2
        if v is None:
            # 자리를 비우되 **비었다고 말한다.** 그냥 공백이면 "안 그려졌나"로 읽히고,
            # 0 높이 막대로 그리면 없는 0 을 지어내는 것이다.
            out.append(f'<text class="yt" x="{_n(cx)}" y="{_n(y0 - 5)}" text-anchor="middle">—</text>')
        else:
            h = max(MIN_BAR, abs(v) / span * plot_h)
            up = v >= 0
            y = y0 - h if up else y0  # 음수는 기준선 아래로 — 방향이 부호를 말한다
            r = min(RADIUS, h, bw / 2)  # 막대가 낮거나 얇으면 라운드가 막대를 삼킨다
            out.append(f'<path class="bar {"pos" if up else "neg"}" d="{_bar_d(x, y, bw, h, r, up)}"/>')
            if i == first:
                # 첫 유효값에만 직접 라벨. 눈금이 없는 그래프라 어딘가 한 곳은 숫자를 적어야
                # 길이를 값으로 바꿔 읽을 수 있다(최신값은 카드 큰 숫자가 이미 말한다).
                ly = max(9.0, y - 4) if up else min(H - 2.0, y + h + 9)
                out.append(f'<text class="yt" x="{_n(cx)}" y="{_n(ly)}" text-anchor="middle">{_label(fmt, v)}</text>')
        if _year_shown(i, n):
            out.append(_year_text(i, n, cx, years))
    out.append("</svg>")
    return "".join(out)


def line_svg(values: list[float | None], years: list[int], fmt: Callable[[float], str], uid: str) -> str:
    """꺾은선 그래프 SVG 문자열. 값이 하나도 없으면 빈 문자열.

    축을 데이터 범위에 맞추는 대신 **실제 최댓값·최솟값을 눈금 텍스트로 적는다**(SP-MET-9).
    음수가 있으면 0 을 범위에 넣고 0 선을 그어, 부호를 색이 아니라 위치로도 말한다.
    면적은 한 벌만 그려 clipPath 로 0 선 위/아래를 갈라 두 번 칠한다 — 부호가 섞인 구간에서
    path 를 쪼개면 교차점을 우리가 계산해야 하고, 그 계산이 틀리면 조용히 색만 어긋난다.
    `uid` 는 그 clipPath id 의 접두사다. 한 페이지에 카드가 6장이라 겹치면 **다른 카드의 클립**이
    걸려 면적이 통째로 사라진다.
    """
    _check(values, years, uid)
    finite = [float(v) for v in values if v is not None]
    if not finite:
        return ""
    n = len(values)
    hi, lo = max(finite), min(finite)
    if lo < 0:  # 음수가 있으면 0 을 반드시 품는다 — 0 선이 기준을 말한다
        hi, lo = max(hi, 0.0), min(lo, 0.0)
    if hi == lo:  # 전 구간이 같은 값이면 폭이 0 이라 나눗셈이 죽는다. 5%(값이 0 이면 1)만 벌린다
        e = abs(hi) * 0.05 or 1.0
        hi, lo = hi + e, lo - e
    pad = (hi - lo) * 0.12
    top, bot = hi + pad, lo - pad
    if lo >= 0 and bot < 0:  # 양수만인 계열을 0 밑까지 벌리지 않는다(없는 적자 구간으로 읽힌다)
        bot = 0.0

    plot_h, plot_w = H - PAD_T - PAD_B, W - PAD_L
    span = top - bot

    def yy(v: float) -> float:
        return PAD_T + (top - v) / span * plot_h

    def xx(i: int) -> float:
        return PAD_L + (plot_w / 2 if n == 1 else i * plot_w / (n - 1))

    has_zero = bot < 0 < top
    zero_y = yy(0.0) if has_zero else yy(bot)  # 0 이 범위 밖이면 면적은 바닥에서 올라온다

    out = [
        _open(years),
        "<defs>",
        f'<clipPath id="{uid}a"><rect x="0" y="0" width="{W}" height="{_n(zero_y)}"/></clipPath>',
        f'<clipPath id="{uid}b"><rect x="0" y="{_n(zero_y)}" width="{W}" height="{_n(H - zero_y)}"/></clipPath>',
        "</defs>",
    ]

    # 눈금 라벨은 전부 같은 x·같은 앵커에 찍힌다 — y 가 가까우면 글자가 겹쳐 **둘 다 못 읽는다**.
    # 최댓값·최솟값은 SPEC 이 "반드시 적는다"고 못박은 것이므로 먼저 자리를 잡고(SP-MET-9),
    # 0 라벨은 그 자리와 겹치면 생략한다. 0 **선**은 그대로 긋는다 — 기준을 말하는 것은 선이고,
    # 그 위치의 숫자는 최솟값 라벨이 이미 말하고 있다(소폭 적자 한 해가 섞이면 실제로 겹친다:
    # 영업이익 [43.6, 35.9, −0.5, 26.9, 51.6] 에서 −0.5 와 0 이 0.2px 차이였다, 2026-08-28).
    drawn: list[float] = []

    def _tick(y: float, text: str, cls: str) -> None:
        out.append(f'<line class="{cls}" x1="{PAD_L}" y1="{_n(y)}" x2="{W}" y2="{_n(y)}"/>')
        if any(abs(y - d) < LABEL_GAP for d in drawn):
            return
        drawn.append(y)
        out.append(f'<text class="yt" x="{PAD_L - 5}" y="{_n(y + 3)}" text-anchor="end">{text}</text>')

    dmax, dmin = max(finite), min(finite)
    for tv in [dmax] if dmax == dmin else [dmax, dmin]:
        _tick(yy(tv), _label(fmt, tv), "gl")
    if has_zero:
        _tick(zero_y, "0", "ax")

    # 결측에서 구간을 끊는다 — 빈 해를 직선으로 가로지르면 없는 값을 지어내는 것이다.
    segs: list[list[int]] = []
    cur: list[int] = []
    for i, v in enumerate(values):
        if v is None:
            if cur:
                segs.append(cur)
            cur = []
        else:
            cur.append(i)
    if cur:
        segs.append(cur)

    for seg in segs:
        pts = " L".join(f"{_n(xx(i))} {_n(yy(float(values[i])))}" for i in seg)
        if len(seg) > 1:
            area = f"M{_n(xx(seg[0]))} {_n(zero_y)} L{pts} L{_n(xx(seg[-1]))} {_n(zero_y)} Z"
            out.append(f'<path class="ar-pos" d="{area}" clip-path="url(#{uid}a)"/>')
            out.append(f'<path class="ar-neg" d="{area}" clip-path="url(#{uid}b)"/>')
            out.append(f'<path class="lp" d="M{pts}"/>')
        else:
            # 앞뒤가 결측이라 혼자 남은 해. 선으로는 그릴 수 없으니 점을 찍되 목록 밖 클래스를
            # 만들지 않는다 — `lp` 는 fill:none 이라 테두리만 있는 점이 된다.
            i = seg[0]
            out.append(f'<circle class="lp" cx="{_n(xx(i))}" cy="{_n(yy(float(values[i])))}" r="2.5"/>')

    for i in range(n):
        if _year_shown(i, n):
            out.append(_year_text(i, n, xx(i), years))
    out.append("</svg>")
    return "".join(out)
