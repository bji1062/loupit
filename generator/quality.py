"""generator/quality.py — 페이지 본문 분량 측정·얇은 페이지 판정 (SP-GEN-13).

**왜 있는가**: 2026-07-21 AdSense 심사가 "가치 없는 콘텐츠"로 반려됐다. 실측상
회사 페이지 95개 중 23개가 본문 1,000자 미만이었고(`docs/HANDOFF-2026-07-19.md`
§G-1), 그 24%가 사이트 전체 평균 품질을 끌어내리고 있었다.

**왜 고정 목록이 아닌가**: 제외 대상을 상수로 박으면 데이터가 보강돼도 그 페이지는
영영 색인 밖에 남는다. 빌드타임에 실측해 판정하면 Track D(데이터 확충)가 진행되는
만큼 **코드 변경 0으로** 색인에 자동 복귀한다. 임계 판정은 그래서 상태가 아니라
파생값이다.

측정법은 §G-1 이 쓴 것과 **같아야 한다** — 그래야 그때 남긴 수치(중앙 1,279자 등)와
지금 산출물을 직접 비교할 수 있다.
"""
from __future__ import annotations

import re

# 본문이 아닌 요소: 스크립트·스타일·주석. 제거 순서가 중요하다 —
# 주석 안에 `</script>` 가 들어 있어도 각 패턴이 독립적으로 비탐욕 매칭한다.
_DROP_BLOCKS = (
    re.compile(r"<script\b.*?</script>", re.S | re.I),
    re.compile(r"<style\b.*?</style>", re.S | re.I),
    re.compile(r"<!--.*?-->", re.S),
)
_TAG = re.compile(r"<[^>]+>")
_WS = re.compile(r"\s+")


def visible_text(html: str) -> str:
    """HTML → 눈에 보이는 본문 텍스트 (§G-1 측정법).

    태그를 지우고 남은 텍스트만 센다. 속성값(`alt`·`title` 등)은 태그와 함께
    사라지는데, 이는 의도다 — 심사관이 읽는 것은 본문이지 마크업이 아니다.
    """
    for pat in _DROP_BLOCKS:
        html = pat.sub("", html)
    return _WS.sub(" ", _TAG.sub(" ", html)).strip()


def visible_text_len(html: str) -> int:
    """`visible_text` 의 글자 수. 임계 판정의 단일 기준."""
    return len(visible_text(html))


def is_thin(html: str, min_chars: int) -> bool:
    """본문이 임계 미달인가. `min_chars <= 0` 이면 판정 자체를 끈다."""
    if min_chars <= 0:
        return False
    return visible_text_len(html) < min_chars


def render_with_thin_policy(tpl, min_chars: int, **kwargs) -> tuple[str, bool]:
    """임계 판정을 적용해 렌더한다 → `(html, noindex)`.

    2패스인 이유: `noindex` 메타는 산출 HTML 안에 들어가야 하는데, 그 판정은
    렌더 결과를 봐야만 내릴 수 있다. 1패스로 하려면 본문 길이를 렌더 전에
    추정해야 하고 그 추정은 반드시 템플릿과 어긋난다. 2패스는 결정적이고,
    메타 한 줄은 `visible_text_len` 에 잡히지 않으므로 재측정도 안정적이다.
    """
    html = tpl.render(**kwargs, noindex=False)
    if not is_thin(html, min_chars):
        return html, False
    return tpl.render(**kwargs, noindex=True), True
