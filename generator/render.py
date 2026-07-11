"""generator/render.py — Jinja2 Environment (SP-GEN-4.1).

autoescape=True(NFR21)·StrictUndefined(누락 변수=렌더 오류)·표시 필터 등록.
"""
from __future__ import annotations

import os

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

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
    return env
