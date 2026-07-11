"""generator/pages/sitemap.py — sitemap.xml·robots.txt (사이트 전역, SP-GEN-9)."""
from __future__ import annotations

from generator.config import CFG
from generator.context import Page


def render_sitemap(env, urls: list[str], lastmod: str, cfg=CFG) -> Page:
    """전 URL(회사+조합+정책+랜딩) → sitemap.xml (NFR9). 중복 URL 0."""
    seen = sorted(set(urls))
    xml = env.get_template("sitemap.xml").render(urls=seen, lastmod=lastmod)
    return Page(
        path="sitemap.xml",
        url=f"{cfg.site_origin}/sitemap.xml",
        html=xml,
        title="",
        description="",
        in_sitemap=False,
        content_type="application/xml; charset=utf-8",
    )


def render_robots(cfg=CFG) -> Page:
    """`Sitemap:` 라인 필수(NFR10). 읽기전용 API는 색인 대상 아님."""
    body = (
        "User-agent: *\n"
        "Allow: /\n"
        "Disallow: /api/\n"
        f"Sitemap: {cfg.site_origin}/sitemap.xml\n"
    )
    return Page(
        path="robots.txt",
        url=f"{cfg.site_origin}/robots.txt",
        html=body,
        title="",
        description="",
        in_sitemap=False,
        content_type="text/plain; charset=utf-8",
    )
