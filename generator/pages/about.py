"""generator/pages/about.py — `/about`·`/contact` 렌더 (SP-GEN-16).

문안은 `generator.content.about`(SP-CONTENT-3 소유)을 import·소비만 하고
재작성하지 않는다. 본 모듈은 렌더·SEO·canonical·sitemap 엔트리만 소유한다 —
`pages/policy.py` 가 정책 문안에 대해 갖는 관계와 같다.

**왜 신설했는가**: 2026-07-29 이전까지 사이트에 소개·문의 페이지가 없었다.
연락처는 정책 페이지 안쪽 블록에만 있었고 운영 주체를 밝히는 페이지는 아예 없어,
광고 심사와 검색 양쪽에서 신뢰 근거를 확인할 수 없는 상태였다.
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.about import build_about_docs
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.pages.company import _truncate
from generator.pages.policy import _correction_href


def _seo(doc, url: str, cfg) -> dict:
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


def render_all(env, ctx, cfg=CFG) -> list[Page]:
    """소개·문의 2종 렌더. 둘 다 `in_sitemap=True` — 신뢰 페이지는 색인돼야 값어치가 있다.

    임계 판정(SP-GEN-13)을 적용하지 않는 이유는 정책 페이지와 같다: 이 페이지들은
    분량으로 존재를 정당화하는 문서가 아니라 있어야만 하는 문서다.
    """
    tpl = env.get_template("about.html")
    pages: list[Page] = []
    for doc in build_about_docs(cfg):
        url = f"{cfg.site_origin}{doc.route}"
        seo = _seo(doc, url, cfg)
        html = tpl.render(
            title=doc.title,
            lede=doc.lede,
            sections=doc.sections,
            related=doc.related,
            policy_contact=cfg.policy_contact,
            contact_href=_correction_href(cfg.policy_contact),
            last_modified=cfg.policy_last_modified,
            **seo,
            cfg=cfg,
            footer_links=POLICY_FOOTER_LINKS,
        )
        pages.append(
            Page(
                path=doc.filename,
                url=url,
                html=html,
                title=seo["meta_title"],
                description=seo["meta_desc"],
            )
        )
    return pages
