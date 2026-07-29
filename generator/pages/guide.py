"""generator/pages/guide.py — 가이드 12편 + 인덱스 렌더 (SP-GEN-15, SC11).

문안은 `generator.content.guides`(SP-CONTENT-2 소유)를, 수치는
`generator.stats`(SP-GEN-14)를 import·소비만 하고 재작성하지 않는다. 본 모듈은
렌더·SEO·canonical·sitemap 엔트리 부여만 소유한다 — `pages/policy.py` 가 정책
문안에 대해 갖는 관계와 정확히 같다.

**왜 신설했는가**: 2026-07-21 AdSense 반려("가치 없는 콘텐츠") 대응.
`docs/HANDOFF-2026-07-19.md` §G-5-2 "편집 콘텐츠 — 애드센스가 실제로 보상하는 유형".
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.guides import (
    GROUP_LABEL,
    GROUP_ORDER,
    GUIDE_INDEX_LEDE,
    GUIDE_INDEX_TITLE,
    build_guide_docs,
    related_for,
)
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.pages.company import _truncate
from generator.quality import render_with_thin_policy
from generator.stats import build_stats


def _seo(title: str, desc: str, url: str, cfg) -> dict:
    full_title = f"{title} | {cfg.site_name}"
    desc = _truncate(desc, cfg.desc_max)
    return {
        "meta_title": full_title,
        "meta_desc": desc,
        "canonical": url,
        "og": {
            "title": full_title,
            "description": desc,
            "type": "article",
            "url": url,
            "image": cfg.site_origin + cfg.default_og_image,
        },
    }


def _article_jsonld(doc, url: str, as_of: str, cfg) -> dict:
    """Article JSON-LD (NFR8).

    `author`/`publisher` 를 사이트 자신으로 두는 것은 사실 기술이다 — 이 글들은
    외부에서 옮겨 온 것이 아니라 이 사이트의 데이터로 여기서 쓴 것이다.
    `dateModified` 는 빌드일이 아니라 데이터 기준일과 같은 값을 쓴다(본문 표기와 일치).
    """
    return {
        "@context": "https://schema.org",
        "@type": "Article",
        "headline": doc.title,
        "description": doc.meta_description,
        "url": url,
        "inLanguage": cfg.lang,
        "dateModified": as_of,
        "author": {"@type": "Organization", "name": cfg.site_name},
        "publisher": {"@type": "Organization", "name": cfg.site_name},
        "isAccessibleForFree": True,
    }


def _render_doc(tpl, doc, docs, as_of: str, cfg) -> Page:
    url = f"{cfg.site_origin}{doc.route}"
    seo = _seo(doc.title, doc.meta_description, url, cfg)
    # 가이드도 임계 판정을 받는다. 자기 콘텐츠라고 예외를 두면 얇은 글을 쓰고도
    # 통과했다고 착각하게 된다 — 판정은 출처가 아니라 분량에만 걸려야 한다.
    html, noindex = render_with_thin_policy(
        tpl,
        cfg.thin_page_min_chars,
        title=doc.title,
        lede=doc.lede,
        sections=doc.sections,
        group_label=GROUP_LABEL[doc.group],
        related=related_for(doc, docs),
        as_of=as_of,
        compare_href=cfg.compare_path,
        jsonld=_article_jsonld(doc, url, as_of, cfg),
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
        in_sitemap=not noindex,
        noindex=noindex,
    )


def _render_index(env, docs, cfg) -> Page:
    url = f"{cfg.site_origin}/guide"
    title = f"{GUIDE_INDEX_TITLE} {len(docs)}편"
    desc = (
        f"잡초가 자체 데이터로 쓴 복지·연봉 분석과 계산·수집 방법론 {len(docs)}편. "
        "카테고리 분포, 업종·기업유형별 비교, 실효연봉 계산식, 불확실성 밴드, "
        "이직 오퍼 체크리스트를 다룹니다."
    )
    seo = _seo(title, desc, url, cfg)
    groups = [
        (g, GROUP_LABEL[g], [d for d in docs if d.group == g])
        for g in GROUP_ORDER
        if any(d.group == g for d in docs)
    ]
    html = env.get_template("guide_index.html").render(
        index_title=title,
        index_lede=GUIDE_INDEX_LEDE,
        groups=groups,
        **seo,
        cfg=cfg,
        footer_links=POLICY_FOOTER_LINKS,
    )
    return Page(
        path="guide.html",
        url=url,
        html=html,
        title=seo["meta_title"],
        description=seo["meta_desc"],
    )


def render_all(env, ctx, cfg=CFG) -> list[Page]:
    """가이드 12편 + 인덱스 1 렌더 (SP-GEN-15).

    수치는 `build_stats(ctx)` 한 번으로 전 문서가 공유한다 — 문서마다 따로 집계하면
    같은 지표가 글마다 미묘하게 달라질 수 있다.
    """
    stats = build_stats(ctx)
    docs = build_guide_docs(stats)
    as_of = ctx.build_now.date().isoformat()
    tpl = env.get_template("guide.html")
    pages = [_render_doc(tpl, d, docs, as_of, cfg) for d in docs]
    pages.append(_render_index(env, docs, cfg))
    return pages
