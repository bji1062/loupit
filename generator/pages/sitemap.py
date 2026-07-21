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
    """`Sitemap:` 라인 필수(NFR10). 읽기전용 API는 색인 대상 아님.

    스크래핑 방어 Layer D(2026-07-21): honor-system이라 정직한 봇만 따르지만 공짜·무해다.
    공격적 SEO 스크래퍼(Ahrefs/Semrush/MJ12 등)에 전면 Disallow를 명시하고, 기본 봇에는
    Crawl-delay로 대량 크롤을 완화한다. 검색·AdSense 크롤러는 규칙 미적용(자기 규칙 우선)이라
    무영향 — 실제 차단은 nginx Layer B(UA)가 담당하고 robots는 선언적 보조다.
    """
    aggressive = [
        "AhrefsBot", "SemrushBot", "MJ12bot", "DotBot", "BLEXBot",
        "DataForSeoBot", "PetalBot", "SerpstatBot", "MegaIndex",
    ]
    blocks = [
        "# 공격적 SEO·데이터 스크래퍼 — 전면 차단(nginx Layer B가 실제 강제)",
        *[f"User-agent: {b}\nDisallow: /" for b in aggressive],
        "",
        "# 그 외 전체 — API만 제외, 대량 크롤 완화",
        "User-agent: *",
        "Allow: /",
        "Disallow: /api/",
        "Crawl-delay: 2",
        "",
        f"Sitemap: {cfg.site_origin}/sitemap.xml",
        "",
    ]
    body = "\n".join(blocks)
    return Page(
        path="robots.txt",
        url=f"{cfg.site_origin}/robots.txt",
        html=body,
        title="",
        description="",
        in_sitemap=False,
        content_type="text/plain; charset=utf-8",
    )
