"""generator/render.py — Jinja2 Environment (SP-GEN-4.1).

autoescape=True(NFR21)·StrictUndefined(누락 변수=렌더 오류)·표시 필터 등록.
"""
from __future__ import annotations

import os

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

from generator.content.nav import GNB_TABS
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
    # 전역 상단 탭(2026-08-27, content/nav.py 정본). 전역으로 두는 이유: `_header.html` 은
    # base 를 상속하는 모든 페이지가 공유하는데, 렌더 호출마다 탭을 실어 나르면 한 곳만
    # 빠뜨려도 StrictUndefined 가 빌드를 죽인다. 현재 탭(`nav_active`)만 페이지가 override 한다.
    env.globals["gnb_tabs"] = GNB_TABS
    env.globals["nav_active"] = None
    return env
