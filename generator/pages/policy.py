"""generator/pages/policy.py — 정책 4종·404 렌더·병합 (SP-GEN-1.1·4.2, SP-POL 소비).

문안(sections·title·meta_description 등)은 `generator.content.policy`
(SP-POL 소유, T-09.1~09.6)를 import·소비만 하고 재작성하지 않는다. 본
모듈은 렌더·SEO·canonical·sitemap 엔트리 부여만 소유한다(T-07.8.2).
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.policy import DRAFT_BANNER, POLICY_FOOTER_LINKS, build_policy_docs
from generator.context import Page
from generator.pages.company import _truncate

_CORRECTION_SCHEMES = ("mailto:", "http://", "https://")


def _correction_href(contact: str) -> str | None:
    """정정·문의 연락처 스킴 분기 (T-09.7.1) — mailto:/http:/https:만 링크화.

    `@` 포함 텍스트는 `mailto:` 링크로, 그 외(플레이스홀더 등)는 링크 없이
    텍스트만 노출한다(스킴 화이트리스트, NFR21).
    """
    if not contact:
        return None
    if contact.startswith(_CORRECTION_SCHEMES):
        return contact
    if "@" in contact:
        return f"mailto:{contact}"
    return None


def _policy_seo(doc, url: str, cfg) -> dict:
    """정책 문서 → SEO 뷰모델(title 접미·description 절단, SP-GEN-6 정합)."""
    title = f"{doc.title} | {cfg.site_name}"
    desc = _truncate(doc.meta_description, cfg.desc_max)
    return {
        "meta_title": title,
        "meta_desc": desc,
        "canonical": url,
        "og": {
            "title": title,
            "description": desc,
            "type": "website",
            "url": url,
            "image": cfg.site_origin + cfg.default_og_image,
        },
    }


def _render_policy_doc(tpl, doc, cfg) -> Page:
    url = f"{cfg.site_origin}{doc.route}"
    seo = _policy_seo(doc, url, cfg)
    html = tpl.render(
        title=doc.title,
        draft=doc.draft,
        draft_banner=DRAFT_BANNER,
        sections=doc.sections,
        show_correction=doc.show_correction,
        policy_contact=cfg.policy_contact,
        policy_contact_href=_correction_href(cfg.policy_contact),
        ads_none=doc.ads_none,
        related=doc.related,
        last_modified=cfg.policy_last_modified,
        **seo,
        cfg=cfg,
        footer_links=POLICY_FOOTER_LINKS,
    )
    return Page(
        path=doc.filename,
        url=url,
        html=html,
        title=seo["meta_title"],
        description=seo["meta_desc"],
    )


def _render_404(tpl404, cfg) -> Page:
    url = f"{cfg.site_origin}/404"
    title = f"페이지를 찾을 수 없습니다 | {cfg.site_name}"
    desc = "요청하신 페이지를 찾을 수 없습니다. 다른 회사나 조합을 검색해 보세요."
    og = {
        "title": title,
        "description": desc,
        "type": "website",
        "url": url,
        "image": cfg.site_origin + cfg.default_og_image,
    }
    html = tpl404.render(
        meta_title=title,
        meta_desc=desc,
        canonical=url,
        og=og,
        cfg=cfg,
        footer_links=POLICY_FOOTER_LINKS,
    )
    return Page(
        path="404.html",
        url=url,
        html=html,
        title=title,
        description=desc,
        in_sitemap=False,
    )


def render_all(env, ctx) -> list[Page]:
    """정책 4종 + 404 렌더 (T-07.8.2). 정책 4종은 `in_sitemap=True`(기본값)."""
    docs = build_policy_docs(CFG)
    tpl = env.get_template("policy.html")
    pages = [_render_policy_doc(tpl, doc, CFG) for doc in docs]
    tpl404 = env.get_template("404.html")
    pages.append(_render_404(tpl404, CFG))
    return pages
