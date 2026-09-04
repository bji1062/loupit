"""지표 그래프 SVG (`generator/charts.py`, SP-MET-9) — 축·부호·결측 불변식.

그래프는 빌드 시점에 좌표가 확정되므로 "제대로 그려졌는가"를 브라우저 없이 **좌표로 잰다**.
여기서 지키는 것은 보기 좋음이 아니라 **거짓말을 하지 않는가**다:
0 기준선이 값에 따라 움직이지 않는가 · 음수가 기준선 아래로 가는가 · 없는 해를 이어 그리지 않는가 ·
축을 좁힌 꺾은선이 실제 최댓값·최솟값을 눈금으로 적는가. 셋 다 **에러 없이 틀린 그림**이 되는
종류라(이 프로젝트의 반복 함정) 사람이 눈으로 보는 검증에 맡기지 않는다.
"""
from __future__ import annotations

import re

import pytest

from generator.charts import H, MAX_BAR, PAD_B, PAD_L, PAD_T, W, bar_svg, line_svg

YEARS_11 = list(range(2015, 2026))
FMT = lambda v: f"{v:,.0f}억원"  # noqa: E731 — 테스트용 최소 포맷(실제는 카드가 단위를 정한다)

_ATTR = re.compile(r'([\w:-]+)="([^"]*)"')
_EL = re.compile(r'<([A-Za-z]+)((?:\s+[\w:-]+="[^"]*")*)\s*/?>')
_TEXT = re.compile(r"<text([^>]*)>([^<]*)</text>")


def _els(svg: str, cls: str | None = None, tag: str | None = None) -> list[dict]:
    """`class` 토큰이 전부 들어있는 요소의 속성 사전 목록(문서 순서)."""
    want = set(cls.split()) if cls else set()
    out = []
    for m in _EL.finditer(svg):
        attrs = dict(_ATTR.findall(m.group(2)))
        if tag and m.group(1) != tag:
            continue
        if want and not want <= set(attrs.get("class", "").split()):
            continue
        out.append(attrs)
    return out


def _texts(svg: str, cls: str) -> list[str]:
    want = set(cls.split())
    return [
        txt
        for attrs, txt in _TEXT.findall(svg)
        if want <= set(dict(_ATTR.findall(attrs)).get("class", "").split())
    ]


def _points(d: str) -> list[tuple[float, float]]:
    """내가 내보내는 path 문법(M·L·V·H·Q·Z)만 읽는 최소 파서 → 지나간 점 목록.

    Q 의 제어점은 버리고 끝점만 센다(제어점은 사각형 모서리 밖으로 나가지 않으므로 부호 판정에
    영향을 주지 않는다).
    """
    toks = re.findall(r"[MLVHQZ]|-?\d+(?:\.\d+)?", d)
    pts: list[tuple[float, float]] = []
    x = y = 0.0
    i = 0
    while i < len(toks):
        c, i = toks[i], i + 1
        if c in "ML":
            x, y, i = float(toks[i]), float(toks[i + 1]), i + 2
        elif c == "V":
            y, i = float(toks[i]), i + 1
        elif c == "H":
            x, i = float(toks[i]), i + 1
        elif c == "Q":
            x, y, i = float(toks[i + 2]), float(toks[i + 3]), i + 4
        elif c == "Z":
            continue
        pts.append((x, y))
    return pts


def _baseline(svg: str) -> float:
    (ax,) = _els(svg, cls="ax")
    return float(ax["y1"])


# ── 막대: 0 기준선 고정 ──────────────────────────────────────────────────────


@pytest.mark.parametrize(
    "values,expect",
    [
        ([100, 120, 140], float(H - PAD_B)),  # 양수만 → 기준선은 바닥
        ([-100, -120], float(PAD_T)),  # 음수만 → 기준선은 천장
        ([-10, 10], PAD_T + (H - PAD_T - PAD_B) / 2),  # 대칭 → 한가운데
    ],
)
def test_bar_baseline_is_pinned_to_zero_not_to_the_data(values, expect):
    """축을 데이터 범위로 좁히지 않는다 — 막대는 길이가 곧 크기다."""
    svg = bar_svg(values, list(range(2020, 2020 + len(values))), FMT, "u1")
    assert _baseline(svg) == pytest.approx(expect, abs=0.05)


def test_bar_every_bar_starts_on_the_baseline():
    """양수든 음수든 첫 점이 기준선 위 — 막대가 0 에서 자란다는 뜻이다."""
    svg = bar_svg([30, -20, 5], [2023, 2024, 2025], FMT, "u1")
    y0 = _baseline(svg)
    for bar in _els(svg, cls="bar"):
        assert _points(bar["d"])[0][1] == pytest.approx(y0, abs=0.05)


def test_bar_length_is_proportional_to_value():
    """값이 두 배면 길이도 두 배(축을 자르면 깨지는 성질이다)."""
    svg = bar_svg([50, 100], [2024, 2025], FMT, "u1")
    y0 = _baseline(svg)
    tops = [min(y for _, y in _points(b["d"])) for b in _els(svg, cls="bar")]
    assert (y0 - tops[1]) == pytest.approx(2 * (y0 - tops[0]), abs=0.05)


def test_bar_negative_hangs_below_the_baseline():
    """부호는 색이 아니라 **방향**으로도 말한다(색각 이상에서도 읽혀야 한다)."""
    svg = bar_svg([40, -25], [2024, 2025], FMT, "u1")
    y0 = _baseline(svg)
    (pos,) = _els(svg, cls="bar pos")
    (neg,) = _els(svg, cls="bar neg")
    assert all(y <= y0 + 0.05 for _, y in _points(pos["d"]))
    assert all(y >= y0 - 0.05 for _, y in _points(neg["d"]))
    assert max(y for _, y in _points(neg["d"])) > y0  # 실제로 내려갔는가


def test_bar_zero_is_drawn_as_a_stub_not_as_nothing():
    """0 은 값이다. 안 그리면 결측과 눈으로 같아진다."""
    svg = bar_svg([0, 100], [2024, 2025], FMT, "u1")
    assert len(_els(svg, cls="bar")) == 2


# ── 막대: 결측은 자리를 비운다 ───────────────────────────────────────────────


def test_bar_leaves_the_missing_slot_empty_and_says_so():
    values = [10, None, 30]
    svg = bar_svg(values, [2023, 2024, 2025], FMT, "u1")
    assert len(_els(svg, cls="bar")) == 2  # 결측 자리에 막대가 없다
    assert "—" in _texts(svg, "yt")  # 비었다고 말한다(빈칸은 '안 그려졌나'로 읽힌다)


def test_bar_missing_does_not_shift_the_other_bars():
    """결측은 자리를 **비우는** 것이지 앞당기는 게 아니다 — 연도 라벨과 어긋나면 조용히 틀린다."""
    full = bar_svg([10, 20, 30], [2023, 2024, 2025], FMT, "u1")
    holed = bar_svg([10, None, 30], [2023, 2024, 2025], FMT, "u1")
    x_full = [_points(b["d"])[0][0] for b in _els(full, cls="bar")]
    x_holed = [_points(b["d"])[0][0] for b in _els(holed, cls="bar")]
    assert x_holed == [x_full[0], x_full[2]]


def _bar_box(bar: dict) -> tuple[float, float]:
    """막대의 (왼쪽 x, 폭)."""
    xs = [x for x, _ in _points(bar["d"])]
    return min(xs), max(xs) - min(xs)


def test_bar_short_series_is_capped_so_it_stays_a_bar_not_a_slab():
    """연도가 2개면 칸이 132px 다 — 꽉 채우면 두 해의 차이가 덩어리에 묻혀 눈에서 사라진다.

    좁힌 막대는 **칸 중앙**에 둔다: 왼쪽으로 붙이면 칸 중앙에 찍히는 연도 라벨과 어긋나고,
    그건 2024 값 위에 2025 라고 적히는 것과 같은 종류의 조용한 거짓이다.
    """
    svg = bar_svg([100, 110], [2024, 2025], FMT, "u1")
    boxes = [_bar_box(b) for b in _els(svg, cls="bar")]
    assert all(w <= MAX_BAR + 0.05 for _, w in boxes)
    label_xs = [float(a["x"]) for a in _els(svg, cls="yr", tag="text")]
    assert [round(x + w / 2, 1) for x, w in boxes] == [round(x, 1) for x in label_xs]


def test_bar_long_series_is_untouched_by_the_cap():
    """11개년(기본)은 자연 폭이 상한보다 좁다 — 상한이 긴 계열의 그림을 바꾸면 안 된다."""
    svg = bar_svg([100] * 11, YEARS_11, FMT, "u1")
    boxes = [_bar_box(b) for b in _els(svg, cls="bar")]
    assert boxes[0][0] == 0.0, "왼쪽 여백이 생기면 상한이 잘못 걸린 것이다"
    assert all(w < MAX_BAR for _, w in boxes)


def test_bar_labels_the_first_valid_value():
    """눈금이 없는 그래프라 한 곳은 숫자를 적어야 길이를 값으로 바꿔 읽는다."""
    svg = bar_svg([None, 1234, 5678], [2023, 2024, 2025], FMT, "u1")
    assert FMT(1234) in _texts(svg, "yt")
    assert FMT(5678) not in _texts(svg, "yt")  # 최신값은 카드의 큰 숫자가 말한다


def test_bar_year_labels_thin_out_when_there_are_many_bars():
    many = bar_svg([1] * 11, YEARS_11, FMT, "u1")
    few = bar_svg([1] * 5, YEARS_11[-5:], FMT, "u1")
    assert _texts(many, "yr") == ["15", "17", "19", "21", "23", "25"]  # 격년 + 마지막
    assert _texts(few, "yr") == ["21", "22", "23", "24", "25"]  # 7개 이하는 전부
    assert _texts(many, "yr last") == ["25"]


# ── 꺾은선: 축을 좁히는 대신 눈금을 적는다 ───────────────────────────────────


def test_line_ticks_are_the_real_max_and_min():
    """축을 데이터 범위에 맞췄으면 그 범위를 **숫자로** 적어야 한다(안 적으면 속임수다)."""
    svg = line_svg([120, 90, 305, 210], [2022, 2023, 2024, 2025], FMT, "u1")
    assert set(_texts(svg, "yt")) == {FMT(305), FMT(90)}
    assert len(_els(svg, cls="gl")) == 2  # 눈금선도 두 줄


def test_line_tick_is_single_when_the_series_is_flat():
    svg = line_svg([70, 70, 70], [2023, 2024, 2025], FMT, "u1")
    assert _texts(svg, "yt") == [FMT(70)]  # 나눗셈이 죽지도, 없는 폭을 지어내지도 않는다


def test_line_includes_zero_and_draws_the_zero_line_when_negative():
    svg = line_svg([-40, 60], [2024, 2025], FMT, "u1")
    ticks = _texts(svg, "yt")
    assert "0" in ticks and "−40억원" in ticks  # 하이픈이 아니라 진짜 마이너스
    y0 = _baseline(svg)
    (lp,) = _els(svg, cls="lp")
    ys = [y for _, y in _points(lp["d"])]
    assert min(ys) < y0 < max(ys)  # 음수 점은 0 선 아래, 양수 점은 위


def test_line_without_negatives_has_no_zero_line():
    """0 이 범위 밖이면 0 선을 긋지 않는다 — 없는 기준선은 축을 오해하게 만든다."""
    assert _els(line_svg([100, 130], [2024, 2025], FMT, "u1"), cls="ax") == []


def test_line_breaks_the_path_at_missing_years():
    """빈 해를 직선으로 가로지르면 없는 값을 지어내는 것이다."""
    svg = line_svg([10, 20, None, 40, 50], list(range(2021, 2026)), FMT, "u1")
    paths = _els(svg, cls="lp")
    assert len(paths) == 2  # 구간이 끊겼다
    gap_x = PAD_L + 2 * (W - PAD_L) / 4
    for p in paths:
        assert all(abs(x - gap_x) > 0.05 for x, _ in _points(p["d"]))


def test_line_isolated_point_is_drawn_but_not_connected():
    svg = line_svg([10, None, 40], [2023, 2024, 2025], FMT, "u1")
    assert _els(svg, cls="lp", tag="path") == []  # 이을 상대가 없다
    assert len(_els(svg, cls="lp", tag="circle")) == 2


def test_line_area_is_split_by_sign_with_clip_paths():
    """면적은 한 벌만 그리고 clipPath 로 0 선 위/아래를 갈라 두 번 칠한다."""
    svg = line_svg([-30, 50], [2024, 2025], FMT, "u1")
    (pos,) = _els(svg, cls="ar-pos")
    (neg,) = _els(svg, cls="ar-neg")
    assert pos["d"] == neg["d"]
    assert pos["clip-path"] == "url(#u1a)" and neg["clip-path"] == "url(#u1b)"


def test_uid_reaches_the_clip_path_ids():
    """카드가 6장이라 id 가 겹치면 **다른 카드의 클립**이 걸려 면적이 통째로 사라진다."""
    svg = line_svg([10, 20], [2024, 2025], FMT, "op-income")
    ids = [a["id"] for a in _els(svg, tag="clipPath")]
    assert ids == ["op-incomea", "op-incomeb"]
    assert "url(#op-incomea)" in svg and "url(#op-incomeb)" in svg


# ── 공통 계약 ────────────────────────────────────────────────────────────────


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_all_missing_renders_nothing(fn):
    """한 칸도 없으면 빈 그래프가 아니라 **빈 문자열** — 카드가 '없다'고 말할 자리를 만든다."""
    assert fn([None, None, None], [2023, 2024, 2025], FMT, "u1") == ""
    assert fn([], [], FMT, "u1") == ""


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_no_css_var_in_svg_attributes(fn):
    """SVG 프레젠테이션 속성의 `var(--x)` 는 브라우저에 따라 조용히 무시된다(실측).

    색은 전부 CSS 클래스로만 준다 — 여기서 어기면 검은 도형이 남는다.
    """
    svg = fn([10, -20, None, 30], [2022, 2023, 2024, 2025], FMT, "u1")
    assert "var(--" not in svg
    # 유일 허용 예외: 히트 칸의 `fill="transparent"` — 색이 아니라 포인터 수신 장치다
    # (none 은 포인터를 못 받고, 클래스를 새로 만들면 목록 밖 클래스 금지 규칙에 걸린다).
    for attr in ("stroke=", "opacity=", "style="):
        assert attr not in svg
    assert svg.count("fill=") == svg.count('fill="transparent"')


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_hover_columns_cover_every_year_with_native_tooltips(fn):
    """마우스를 대면 숫자가 나온다(SP-MET-9 툴팁) — JS 0 이므로 SVG 네이티브 `<title>` 로.

    값이 아니라 **칸**에 단다: 2px 스텁·결측 해도 호버가 잡혀야 하고, 결측은 "값 없음"이라고
    말한다. 칸은 이어 붙어 사각지대가 없고, 맨 마지막에 그려져 호버를 받는다(최상단 페인트)."""
    svg = fn([10, None, 30], [2023, 2024, 2025], FMT, "u1")
    hit_re = re.compile(
        rf'<rect x="([\d.]+)" y="0" width="([\d.]+)" height="{H}" fill="transparent">'
        r"<title>([^<]*)</title></rect>"
    )
    hits = list(hit_re.finditer(svg))
    assert [m.group(3) for m in hits] == ["2023년 10억원", "2024년 값 없음", "2025년 30억원"]
    body_last = max(svg.rindex('class="bar') if fn is bar_svg else svg.rindex('class="lp'),
                    svg.rindex('class="yr'))
    assert svg.index(hits[0].group(0)) > body_last, "히트 칸이 본체보다 먼저 그려지면 호버를 뺏긴다"
    xs = [float(m.group(1)) for m in hits]
    ws = [float(m.group(2)) for m in hits]
    assert xs[0] in (0.0, float(PAD_L))  # 막대는 0, 선은 눈금 자리 뒤부터
    assert abs(xs[-1] + ws[-1] - W) < 0.11
    for a in range(len(hits) - 1):
        assert abs(xs[a] + ws[a] - xs[a + 1]) < 0.11, "칸 사이가 벌어지면 그 자리는 툴팁이 없다"


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_hover_tooltip_escapes_fmt_output(fn):
    """title 텍스트도 fmt(호출자 코드) 경유라 이스케이프 구간이다."""
    svg = fn([5], [2025], lambda v: "<b>&x", "u1")
    assert "<title>2025년 &lt;b&gt;&amp;x</title>" in svg


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_fmt_output_is_escaped(fn):
    """`fmt` 는 호출자 코드다 — 생성기에서 유일하게 autoescape 밖인 구간이라 여기서 막는다."""
    svg = fn([5], [2025], lambda v: '<script>&"x"', "u1")
    assert "<script>" not in svg
    assert "&lt;script&gt;&amp;" in svg


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_length_mismatch_and_bad_uid_fail_loudly(fn):
    """조용한 실패 금지 — 라벨이 한 칸 밀린 그림은 에러 없이 틀린 그림이 된다."""
    with pytest.raises(ValueError):
        fn([1, 2], [2025], FMT, "u1")
    with pytest.raises(ValueError):
        fn([1], [2025], FMT, 'u1" onload="x')
    with pytest.raises(ValueError):
        fn([1], [2025], FMT, "")


def test_line_zero_label_is_dropped_when_it_would_sit_on_the_minimum():
    """눈금 라벨은 전부 같은 x·같은 앵커에 찍힌다 — y 가 가까우면 두 글자가 겹쳐 **둘 다 못 읽는다**.

    소폭 적자가 한 해 섞이면 실제로 일어난다: 영업이익 [43.6, 35.9, −0.5, 26.9, 51.6] 에서
    −0.5 와 0 의 라벨이 0.2px 차이였다(2026-08-28). 최댓값·최솟값은 SPEC 이 반드시 적으라고 한
    것이므로 먼저 자리를 잡고, 0 라벨을 생략한다. **0 선은 그대로 긋는다** — 기준을 말하는 것은 선이다.
    """
    svg = line_svg([43.6, 35.9, -0.5, 26.9, 51.6], list(range(2021, 2026)), FMT, "u1")
    ys = [float(a["y"]) for a in _els(svg, cls="yt", tag="text")]
    assert len(ys) == 2, "최댓값·최솟값 둘만 남는다(0 라벨은 최솟값과 겹쳐 생략)"
    assert all(abs(a - b) >= 8.0 for i, a in enumerate(ys) for b in ys[i + 1:])
    assert len(_els(svg, cls="ax")) == 1, "0 선 자체는 남는다"


def test_line_zero_label_survives_when_it_is_far_from_the_extremes():
    """겹치지 않으면 0 라벨은 그대로 나온다 — 규칙이 0 라벨을 통째로 없애 버리면 안 된다."""
    svg = line_svg([100, -100], [2024, 2025], FMT, "u1")
    assert "0" in _texts(svg, "yt")
    assert len(_els(svg, cls="yt", tag="text")) == 3  # 최대·최소·0


@pytest.mark.parametrize("fn", [bar_svg, line_svg])
def test_hover_columns_also_draw_an_instant_css_label(fn):
    """네이티브 <title> 만으로는 부족했다(2026-09-04 실사용 보고: 1초 지연·터치 불가) — 같은 문구를
    칸 호버에 즉시 그리는 `hv` 라벨이 **칸마다 하나**, **title 과 같은 글자**로 있어야 한다.
    글자가 두 곳에서 따로 만들어지면 언젠가 한쪽만 고쳐진다."""
    svg = fn([10, None, 30], [2023, 2024, 2025], FMT, "u1")
    cols = re.findall(r'<g class="hc"><rect [^>]*><title>([^<]*)</title></rect>'
                      r'<text class="hv" x="([\d.]+)" y="10" text-anchor="middle">([^<]*)</text></g>', svg)
    assert [c[0] for c in cols] == ["2023년 10억원", "2024년 값 없음", "2025년 30억원"]
    assert all(c[0] == c[2] for c in cols), "호버 라벨과 title 문구가 다르다"
    assert "pointer-events" not in svg and "style=" not in svg  # 표현은 CSS 가(클래스 목록 규칙)
