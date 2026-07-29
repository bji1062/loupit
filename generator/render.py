"""generator/render.py — Jinja2 Environment (SP-GEN-4.1).

autoescape=True(NFR21)·StrictUndefined(누락 변수=렌더 오류)·표시 필터 등록.
"""
from __future__ import annotations

import os

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

from generator.content.policy import SITE_NAV_LINKS
from generator.format import badge_state, iso_date, jsonld_dumps, krw_manwon, work_style_label

_DEFAULT_TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "templates")


def make_env(templates_dir: str = _DEFAULT_TEMPLATES_DIR) -> Environment:
    """Jinja2 Environment 생성 — autoescape·StrictUndefined·필터 등록."""
    env = Environment(
        loader=FileSystemLoader(templates_dir),
        autoescape=select_autoescape(["html", "xml"], default_for_string=True),  # NFR21
        trim_blocks=True,
        lstrip_blocks=True,
        undefined=StrictUndefined,  # 누락 변수 = 렌더 오류(조용한 공란 금지)
    )
    env.filters["krw"] = krw_manwon
    env.filters["badge"] = badge_state
    env.filters["jsonld"] = jsonld_dumps
    env.filters["isodate"] = iso_date
    env.filters["ws_label"] = work_style_label
    # 사이트 탐색 링크는 페이지별 데이터가 아니라 전역 상수라 globals 로 둔다.
    # 렌더 인자로 돌리면 페이지 타입이 늘 때마다 8개 호출부에 같은 줄을 추가해야 하고,
    # 하나만 빠뜨리면 그 페이지 푸터에서 조용히 링크가 사라진다(StrictUndefined 가
    # 잡아 주긴 하지만, 애초에 빠뜨릴 수 없게 두는 편이 낫다).
    # `footer_links`(정책 4종)는 기존 계약(PC-5)이라 그대로 인자로 남긴다.
    env.globals["site_nav_links"] = SITE_NAV_LINKS
    return env
