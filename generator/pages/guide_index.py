"""generator/pages/guide_index.py — 가이드 목록 `/guide` (SP-GUIDE-8, 2026-10-08, 리드 판정 (86)).

카드는 `generator/content/guides.py` 의 글 목록(최신 먼저)에서 만든다. 카드 제목 · 설명의 숫자는 각 글의 정본에서 채운다
(A편 = 고정판 스냅숏, D편 = 글 제목 상수). 무광고 · sitemap 포함 · 탭 「가이드」 활성.
"""
from __future__ import annotations

from generator.config import CFG
from generator.content import about_data as D
from generator.content import guide_report as TR
from generator.content import guides as G
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.pages import guide_report


def cards() -> list[dict]:
    out = []
    for ed in G.REPORT_EDITIONS:
        s = guide_report.facts_for(ed)
        v = guide_report.values(s)
        out.append({"href": G.report_route(ed), "title": TR.H1.format(**v), "desc": TR.CARD_DESC.format(**v)})
    out.append({"href": G.DATA_ROUTE, "title": D.H1, "desc": G.DATA_CARD_DESC})
    return out


def render(env, ctx=None, cfg=CFG) -> Page:
    url = f"{cfg.site_origin}{G.LIST_ROUTE}"
    title = f"{G.LIST_TITLE} | {cfg.site_name}"
    desc = G.LIST_LEAD
    html = env.get_template("guide_index.html").render(
        view={"h1": G.LIST_H1, "lead": G.LIST_LEAD, "cards": cards()},
        meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active=G.LIST_ROUTE,
    )
    return Page(path=G.LIST_PATH, url=url, html=html, title=title, description=desc)
